//
//  IAPManager.swift
//  IAPManager
//
//  Created by Trịnh Xuân Minh on 25/09/2023.
//

import Foundation
import StoreKit

public final class IAPManager: NSObject {
  public static let shared = IAPManager()
  
  public enum PurchaseError: Error {
    case notInitialized
    case notPayment
    case notAvailable
    case unverified
    case userCancelled
    case unknown
  }
  
  @Published public private(set) var isPurchasing = false
  private var sharedSecret: String?
  private var products = [BaseProduct]()
  private var permissions = [BasePermission]()
  private var skProducts: [String: SKProduct] = [:]
  private var productRequest: SKProductsRequest?
  private var updatedTransaction: UpdatedTransaction?
  
  public func initialize(sharedSecret: String, products: [BaseProduct], permissions: [BasePermission]) {
    self.sharedSecret = sharedSecret
    self.products = products
    self.permissions = permissions
    SKPaymentQueue.default().add(self)
    observeTransactions()
    fetch(products)
  }
  
  public func purchase(_ product: BaseProduct) async throws -> (product: BaseProduct, permissions: [BasePermission]) {
    guard SKPaymentQueue.canMakePayments() else {
      throw PurchaseError.notPayment
    }
    guard let skProduct = skProducts[product.id] else {
      throw PurchaseError.notAvailable
    }
    
    self.isPurchasing = true
    var isResumed = false
    
    return try await withCheckedThrowingContinuation { continuation in
      self.updatedTransaction = { transactions in
        guard !isResumed else {
          return
        }
      
        for transaction in transactions {
          switch transaction.transactionState {
          case .purchasing:
            print("[IAPManager] Purchasing!")
          case .purchased, .restored:
            print("[IAPManager] Purchased!")
            let permissions = self.getPermission(transaction.payment.productIdentifier)
            SKPaymentQueue.default().finishTransaction(transaction)
            self.isPurchasing = false
            
            isResumed = true
            continuation.resume(returning: (product, permissions))
          case .failed:
            print("[IAPManager] Purchase failed! - \(String(describing: transaction.error?.localizedDescription))")
            SKPaymentQueue.default().finishTransaction(transaction)
            self.isPurchasing = false
            
            if let error = transaction.error as? NSError, error.code == SKError.paymentCancelled.rawValue {
              isResumed = true
              continuation.resume(throwing: PurchaseError.userCancelled)
            } else {
              isResumed = true
              continuation.resume(throwing: PurchaseError.unknown)
            }
          default:
            print("[IAPManager] Purchase deferred!")
            isResumed = true
            continuation.resume(throwing: PurchaseError.unknown)
          }
        }
      }
      let payment = SKPayment(product: skProduct)
      SKPaymentQueue.default().add(payment)
    }
  }
  
  public func restore() async throws -> [BasePermission] {
    self.isPurchasing = true
    var isResumed = false
    
    return try await withCheckedThrowingContinuation { continuation in
      self.updatedTransaction = { transactions in
        guard !isResumed else {
          return
        }
        var resultPermissions = [BasePermission]()

        for transaction in transactions {
          switch transaction.transactionState {
          case .restored:
            print("[IAPManager] Restored: \(transaction.payment.productIdentifier)")
            let permissions = self.getPermission(transaction.payment.productIdentifier)
            resultPermissions += permissions
            SKPaymentQueue.default().finishTransaction(transaction)
          case .failed:
            print("[IAPManager] Restore failed! - \(String(describing: transaction.error?.localizedDescription))")
            SKPaymentQueue.default().finishTransaction(transaction)
            self.isPurchasing = false
            
            isResumed = true
            continuation.resume(throwing: PurchaseError.unknown)
            return
          default:
            break
          }
        }
        self.isPurchasing = false
        
        isResumed = true
        continuation.resume(returning: resultPermissions)
      }
      SKPaymentQueue.default().restoreCompletedTransactions()
    }
  }
  
  public func verify() async throws -> [BasePermission] {
    guard let sharedSecret else {
      throw PurchaseError.notInitialized
    }
    let verifyReceipt = try await verifyReceipt(sharedSecret)
    guard let latestReceiptInfo = verifyReceipt.latestReceiptInfo else {
      return []
    }
    var resultPermissions = [BasePermission]()
    
    for inAppPurchase in latestReceiptInfo {
      guard
        let productID = inAppPurchase.productID,
        let product = products.first(where: { $0.id == productID })
      else {
        break
      }
      
      switch product.productType {
      case .autoRenewable, .nonRenewable:
        guard
          let expiresDateMS = inAppPurchase.expiresDateMS,
          let expiresDateTimeInterval = TimeInterval(expiresDateMS)
        else {
          break
        }
        let expiresDate = Date(timeIntervalSince1970: expiresDateTimeInterval / 1000)
        
        guard expiresDate > Date() else {
          break
        }
        let permissions = getPermission(productID)
        resultPermissions += permissions
      case .nonConsumable:
        let permissions = getPermission(productID)
        resultPermissions += permissions
      default:
        break
      }
    }
    return resultPermissions
  }

  public func historys() async throws -> VerifyReceipt {
    guard let sharedSecret else {
      throw PurchaseError.notInitialized
    }
    return try await verifyReceipt(sharedSecret)
  }
  
  public func retrieveInfo(product: BaseProduct) async throws -> Product {
    let skProducts = try await Product.products(for: [product.id])
    
    guard let skProduct = skProducts.first else {
      throw PurchaseError.notAvailable
    }
    return skProduct
  }
  
  public func getPriceLocale(product: Product) -> String? {
    return product.displayPrice
  }
}

extension IAPManager: SKProductsRequestDelegate {
  public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    for product in response.products {
      self.skProducts[product.productIdentifier] = product
    }
  }
}

extension IAPManager: SKPaymentTransactionObserver {
  public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    updatedTransaction?(transactions)
  }
}

extension IAPManager {
  private func getPermission(_ productID: String) -> [BasePermission] {
    return permissions.filter { permission in
      return permission.products.contains { product in
        return product.id == productID
      }
    }
  }
  
  private func observeTransactions() {
    for transaction in SKPaymentQueue.default().transactions {
      if transaction.transactionState == .purchased || transaction.transactionState == .restored {
        SKPaymentQueue.default().finishTransaction(transaction)
      }
    }
  }
  
  private func fetch(_ products: [BaseProduct]) {
    productRequest?.cancel()
    self.productRequest = SKProductsRequest(productIdentifiers: Set(products.map({ $0.id })))
    productRequest?.delegate = self
    productRequest?.start()
  }
  
  private func verifyReceipt(_ sharedSecret: String) async throws -> VerifyReceipt {
    guard
      let receiptURL = Bundle.main.appStoreReceiptURL,
      let receiptData = try? Data(contentsOf: receiptURL)
    else {
      throw APIError.invalidRequest
    }
    let receiptBase64 = receiptData.base64EncodedString()
    let verifyReceiptBody = VerifyReceiptBody(receipt: receiptBase64,
                                              sharedSecret: sharedSecret,
                                              excludeOldTransactions: true)
    guard let bodyData = try? JSONEncoder().encode(verifyReceiptBody) else {
      throw APIError.jsonEncodingError
    }
    let verifyReceipt: VerifyReceipt = try await APIService().request(from: .verifyReceipt, body: bodyData)
    return verifyReceipt
  }
}
