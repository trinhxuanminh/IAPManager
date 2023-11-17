//
//  IAPManager.swift
//  IAPManager
//
//  Created by Trịnh Xuân Minh on 25/09/2023.
//

import Foundation
import Combine
import Glassfy

public class IAPManager {
  public static var shared = IAPManager()
  
  public typealias Handler = (() -> Void)
  public typealias OfferingsCompletion = (([Glassfy.Offering]) -> Void)
  public typealias PermissionCompletion = (([Glassfy.Permission]) -> Void)
  public typealias RetrieveInfoCompletion = ((Glassfy.Sku) -> Void)

  @Published public private(set) var isLoading = false

  public func initialize(apiKey: String) {
    Glassfy.initialize(apiKey: apiKey, watcherMode: false)
  }
  
  public func offerings(completion: @escaping OfferingsCompletion, errored: Handler? = nil) {
    print("IAPManager: Start fetch offerings!")
    Glassfy.offerings { offerings, error in
      guard error == nil else {
        print("IAPManager: Offerings fetch failed! - \(String(describing: error))")
        errored?()
        return
      }
      guard let offerings else {
        print("IAPManager: Offerings fetch failed!")
        errored?()
        return
      }
      completion(offerings.all)
    }
  }

  public func verify(completion: @escaping PermissionCompletion, errored: Handler? = nil) {
    print("IAPManager: Start verify!")
    Glassfy.permissions { permissions, error in
      guard error == nil else {
        print("IAPManager: Verify failed! - \(String(describing: error))")
        errored?()
        return
      }
      guard let permissions else {
        print("IAPManager: Permissions fetch failed!")
        errored?()
        return
      }
      let vaildPermissions = permissions.all.filter { $0.isValid }
      completion(vaildPermissions)
    }
  }

  public func retrieveInfo(skuId: String, completion: @escaping RetrieveInfoCompletion, errored: Handler? = nil) {
    print("IAPManager: Start retrieve info!")
    Glassfy.sku(id: skuId) { sku, error in
      guard error == nil, let sku else {
        print("IAPManager: SKU fetch failed! - \(String(describing: error))")
        errored?()
        return
      }
      completion(sku)
    }
  }

  public func purchase(skuId: String, completion: @escaping PermissionCompletion, errored: Handler? = nil) {
    print("IAPManager: Start purchase!")
    self.isLoading = true
    retrieveInfo(skuId: skuId) { sku in
      Glassfy.purchase(sku: sku) { [weak self] transaction, error in
        guard let self = self else {
          return
        }
        guard error == nil else {
          print("IAPManager: Purchase failed! - \(String(describing: error))")
          self.isLoading = false
          errored?()
          return
        }
        guard let transaction else {
          print("IAPManager: Purchase failed!")
          self.isLoading = false
          errored?()
          return
        }
        self.isLoading = false
        let vaildPermissions = transaction.permissions.all.filter { $0.isValid }
        completion(vaildPermissions)
      }
    } errored: {
      self.isLoading = false
      errored?()
    }
  }

  public func restore(completion: @escaping PermissionCompletion, errored: Handler? = nil) {
    print("IAPManager: Start restore!")
    self.isLoading = true
    Glassfy.restorePurchases { [weak self] permissions, error in
      guard let self = self else {
        return
      }
      guard error == nil else {
        print("IAPManager: Restore failed! - \(String(describing: error))")
        self.isLoading = false
        errored?()
        return
      }
      guard let permissions else {
        print("IAPManager: Restore failed!")
        self.isLoading = false
        errored?()
        return
      }
      self.isLoading = false
      let vaildPermissions = permissions.all.filter { $0.isValid }
      completion(vaildPermissions)
    }
  }
  
  public func getPriceLocale(sku: Glassfy.Sku) -> String? {
    let product = sku.product
    return priceFormatter(locale: product.priceLocale).string(from: product.price)
  }
}

extension IAPManager {
  private func priceFormatter(locale: Locale) -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.locale = locale
    formatter.numberStyle = .currency
    return formatter
  }
}
