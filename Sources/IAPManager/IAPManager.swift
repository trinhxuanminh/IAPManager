//
//  IAPManager.swift
//  IAPManager
//
//  Created by Trịnh Xuân Minh on 25/09/2023.
//

import Foundation
import StoreKit

public final class IAPManager {
  public static var shared = IAPManager()
  
  public enum PurchaseError: Error {
    case notAvailable
    case unverified
    case userCancelled
    case pending
    case unknown
  }
  
  @Published public private(set) var isPurchasing = false
  private var permissions = [BasePermission]()
  
  public func initialize(permissions: [BasePermission]) {
    self.permissions = permissions
    observeTransactions()
  }
  
  public func purchase(_ product: BaseProduct) async throws -> (type: Product.ProductType, product: BaseProduct, permissions: [BasePermission]) {
    self.isPurchasing = true
    let skProduct = try await retrieveInfo(product: product)
    let result = try await skProduct.purchase()
    
    switch result {
    case .success(let verification):
      let transaction = try await checkVerified(verification)
      let permissions = try await handleTransaction(transaction)
      await transaction.finish()
      self.isPurchasing = false
      return (transaction.productType, product, permissions)
    case .userCancelled:
      self.isPurchasing = false
      throw PurchaseError.userCancelled
    case .pending:
      self.isPurchasing = false
      throw PurchaseError.pending
    @unknown default:
      self.isPurchasing = false
      throw PurchaseError.unknown
    }
  }
  
  public func verify() async throws -> [BasePermission] {
    var resultPermissions = [BasePermission]()
    
    for await verification in Transaction.currentEntitlements {
      let transaction = try await checkVerified(verification)
      if let expirationDate = transaction.expirationDate, expirationDate > Date() {
        let permissions = try await handleTransaction(transaction)
        resultPermissions += permissions
      }
      await transaction.finish()
    }
    return resultPermissions
  }
  
  public func restore() async throws -> [BasePermission] {
    try await verify()
  }
  
  public func historys() async -> [Transaction] {
    var purchaseHistory: [Transaction] = []
    
    for await result in Transaction.all {
      switch result {
      case .verified(let transaction):
        purchaseHistory.append(transaction)
      case .unverified:
        break
      }
    }
    return purchaseHistory
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

extension IAPManager {
  private func checkVerified(_ result: VerificationResult<Transaction>) async throws -> Transaction {
    switch result {
    case .unverified:
      throw PurchaseError.unverified
    case .verified(let transaction):
      return transaction
    }
  }
  
  private func handleTransaction(_ transaction: Transaction) async throws -> [BasePermission] {
    return permissions.filter { permission in
      return permission.products.contains { product in
        return product.id == transaction.productID
      }
    }
  }
  
  private func observeTransactions() {
    Task.detached {
      for await verification in Transaction.updates {
        do {
          let transaction = try await self.checkVerified(verification)
          await transaction.finish()
        } catch {
          print("[IAPManager] Transaction failed verification: \(error)")
        }
      }
    }
  }
}
