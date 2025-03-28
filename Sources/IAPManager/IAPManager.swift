//
//  IAPManager.swift
//  IAPManager
//
//  Created by Trịnh Xuân Minh on 25/09/2023.
//

import Foundation
import FirebaseAnalytics
import StoreKit

public final class IAPManager {
  public static var shared = IAPManager()
  
  public enum PurchaseError: Error {
    case notInitialized
    case notAvailable
    case unverified
    case userCancelled
    case pending
    case unknown
  }
  
  @Published public private(set) var isPurchasing = false
  private var permissions = [BasePermission]()
  
  public func initialize(permissions: [BasePermission]) {
    print("[IAPManager] Initialized!")
    self.permissions = permissions
    observeTransactions()
  }
  
  public func purchase(_ product: BaseProduct) async throws -> (product: BaseProduct, permissions: [BasePermission]) {
    print("[IAPManager] Purchasing! - \(product)")
    self.isPurchasing = true
    let skProduct = try await retrieveInfo(product: product)
    let result = try await skProduct.purchase()
    
    switch result {
    case .success(let verification):
      print("[IAPManager] Purchased! - \(product)")
      let transaction = try checkVerified(verification)
      
      var permissions = [BasePermission]()
      switch transaction.productType {
      case .autoRenewable, .nonRenewable, .nonConsumable:
        permissions = try getPermission(transaction.productID)
      case .consumable:
        break
      default:
        break
      }
      
      Analytics.logTransaction(transaction)
      await transaction.finish()
      self.isPurchasing = false
      return (product, permissions)
    case .userCancelled:
      print("[IAPManager] User cancelled! - \(product)")
      self.isPurchasing = false
      throw PurchaseError.userCancelled
    case .pending:
      print("[IAPManager] Pending! - \(product)")
      self.isPurchasing = false
      throw PurchaseError.pending
    @unknown default:
      print("[IAPManager] Unknown error! - \(product)")
      self.isPurchasing = false
      throw PurchaseError.unknown
    }
  }
  
  public func verify() async throws -> [BasePermission] {
    print("[IAPManager] Verifying!")
    var resultPermissions = [BasePermission]()
    
    for await verification in Transaction.currentEntitlements {
      let transaction = try checkVerified(verification)
      switch transaction.productType {
      case .autoRenewable, .nonRenewable:
        if let expirationDate = transaction.expirationDate, expirationDate > Date() {
          let permissions = try getPermission(transaction.productID)
          resultPermissions += permissions
        }
      case .nonConsumable:
        let permissions = try getPermission(transaction.productID)
        resultPermissions += permissions
      default:
        break
      }
    }
    print("[IAPManager] Verified!")
    return resultPermissions
  }
  
  public func restore() async throws -> [BasePermission] {
    print("[IAPManager] Restoring!")
    var resultPermissions = [BasePermission]()
    
    for await verification in Transaction.currentEntitlements {
      let transaction = try checkVerified(verification)
      switch transaction.productType {
      case .autoRenewable, .nonRenewable:
        if let expirationDate = transaction.expirationDate, expirationDate > Date() {
          let permissions = try getPermission(transaction.productID)
          resultPermissions += permissions
        }
      case .nonConsumable:
        let permissions = try getPermission(transaction.productID)
        resultPermissions += permissions
      default:
        break
      }
    }
    if permissions.isEmpty {
      print("[IAPManager] Nothing to restore!")
    } else {
      print("[IAPManager] Restored!")
    }
    return resultPermissions
  }
  
  public func history() async -> [Transaction] {
    print("[IAPManager] Retrieving history!")
    var purchaseHistory: [Transaction] = []
    
    for await result in Transaction.all {
      switch result {
      case .verified(let transaction):
        purchaseHistory.append(transaction)
      case .unverified:
        break
      }
    }
    if purchaseHistory.isEmpty {
      print("[IAPManager] No history!")
    } else {
      print("[IAPManager] History returned!")
    }
    return purchaseHistory
  }
  
  public func retrieveInfo(product: BaseProduct) async throws -> Product {
    print("[IAPManager] Getting information! - \(product)")
    let storeProducts = try await Product.products(for: [product.id])
    
    guard let storeProduct = storeProducts.first else {
      throw PurchaseError.notAvailable
    }
    print("[IAPManager] Getting information! - \(product)")
    return storeProduct
  }
  
  public func getPriceLocale(product: Product) -> String? {
    return product.displayPrice
  }
}

extension IAPManager {
  private func checkVerified(_ result: VerificationResult<Transaction>) throws -> Transaction {
    switch result {
    case .unverified:
      throw PurchaseError.unverified
    case .verified(let transaction):
      return transaction
    }
  }
  
  private func getPermission(_ productID: String) throws -> [BasePermission] {
    guard !permissions.isEmpty else {
      print("[IAPManager] Not initialized!")
      throw PurchaseError.notInitialized
    }
    return permissions.filter { permission in
      return permission.products.contains { product in
        return product.id == productID
      }
    }
  }
  
  private func observeTransactions() {
    Task.detached {
      for await verification in Transaction.updates {
        do {
          let transaction = try self.checkVerified(verification)
          await transaction.finish()
        } catch {
          print("[IAPManager] Transaction failed verification: \(error)")
        }
      }
    }
  }
}
