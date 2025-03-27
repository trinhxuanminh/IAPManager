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
    case notPayment
    case notAvailable
    case unverified
    case userCancelled
    case unknown
  }
  
  @Published public private(set) var isPurchasing = false
  private var permissions = [BasePermission]()
  private var products: [String: SKProduct] = [:]
  private var productRequest: SKProductsRequest?
  private var updatedTransaction: UpdatedTransaction?
  
  public func initialize(products: [BaseProduct], permissions: [BasePermission]) {
    self.permissions = permissions
    SKPaymentQueue.default().add(self)
    observeTransactions()
    fetch(products)
  }
  
  public func purchase(_ product: BaseProduct) async throws -> (product: BaseProduct, permissions: [BasePermission]) {
    guard SKPaymentQueue.canMakePayments() else {
      throw PurchaseError.notPayment
    }
    guard let skProduct = products[product.id] else {
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
            let permissions = self.handleTransaction(transaction)
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
            let permissions = self.handleTransaction(transaction)
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
  
  public func verify(sharedSecret: String) async throws {
    let verifyReceipt = try await verifyReceipt(sharedSecret)
    print("[IAPManager]", verifyReceipt)
  }

  public func historys() async -> [SKPaymentTransaction] {
    return await withCheckedContinuation { continuation in
      var transactionsHistory: [SKPaymentTransaction] = []
      var isResumed = false
      
      self.updatedTransaction = { transactions in
        guard !isResumed else {
          return
        }
        
        for transaction in transactions {
          switch transaction.transactionState {
          case .purchased, .restored:
            transactionsHistory.append(transaction)
          default:
            break
          }
        }
        isResumed = true
        continuation.resume(returning: transactionsHistory)
      }
      SKPaymentQueue.default().restoreCompletedTransactions()
    }
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
      self.products[product.productIdentifier] = product
    }
  }
}

extension IAPManager: SKPaymentTransactionObserver {
  public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    updatedTransaction?(transactions)
  }
}

extension IAPManager {
  private func handleTransaction(_ transaction: SKPaymentTransaction) -> [BasePermission] {
    return permissions.filter { permission in
      return permission.products.contains { product in
        return product.id == transaction.payment.productIdentifier
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
