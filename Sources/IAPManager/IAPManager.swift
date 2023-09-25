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
  public typealias RetrieveInfoHandler = ((Glassfy.Sku?) -> Void)

  @Published public private(set) var isPremium = false
  @Published public private(set) var isLoading = false
  private var products = [Glassfy.Sku]()
  private var retrieveInfoActions = [Handler]()
  private var offeringKey: String?
  private var permissionKey: String?

  public func initialize(apiKey: String, offeringKey: String, permissionKey: String) {
    self.offeringKey = offeringKey
    self.permissionKey = permissionKey
    Glassfy.initialize(apiKey: apiKey, watcherMode: false)
    fetch()
  }

  public func verify(completed: Handler?, errored: Handler?) {
    print("IAPManager: Start verify!")
    Glassfy.permissions { [weak self] permissions, error in
      guard let self = self else {
        return
      }
      guard error == nil else {
        print("IAPManager: Verify failed! - \(String(describing: error))")
        errored?()
        return
      }
      guard
        let permissions,
        let permissionKey,
        let permission = permissions[permissionKey],
        permission.isValid
      else {
        print("IAPManager: Not premium!")
        completed?()
        return
      }
      self.purchared()
      completed?()
    }
  }

  public func retrieveInfo(productID: String, completed: @escaping RetrieveInfoHandler) {
    let retrieveInfoAction: Handler = { [weak self] in
      guard let self = self else {
        return
      }
      let product = self.products.first(where: { $0.product.productIdentifier == productID })
      completed(product)
    }
    if products.isEmpty {
      self.retrieveInfoActions.append(retrieveInfoAction)
    } else {
      retrieveInfoAction()
    }
  }

  public func purchase(productID: String, completed: Handler?, errored: Handler?) {
    guard let product = products.first(where: { $0.product.productIdentifier == productID }) else {
      print("IAPManager: No products!")
      errored?()
      return
    }
    print("IAPManager: Start purchase!")
    self.isLoading = true
    Glassfy.purchase(sku: product) { [weak self] transaction, error in
      guard let self = self else {
        return
      }
      guard error == nil else {
        print("IAPManager: Purchase failed! - \(String(describing: error))")
        self.isLoading = false
        errored?()
        return
      }
      guard
        let transaction,
        let permissionKey,
        let p = transaction.permissions[permissionKey],
        p.isValid
      else {
        print("IAPManager: Purchase failed!")
        self.isLoading = false
        errored?()
        return
      }
      self.isLoading = false
      self.purchared()
      completed?()
    }
  }

  public func restore(completed: Handler?, nothing: Handler?, errored: Handler?) {
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
      guard
        let permissions,
        let permissionKey,
        let permission = permissions[permissionKey],
        permission.isValid
      else {
        print("IAPManager: Restore failed!")
        self.isLoading = false
        nothing?()
        return
      }
      self.isLoading = false
      self.purchared()
      completed?()
    }
  }
  
  public func getPriceLocale(product: Glassfy.Sku) -> String? {
    return priceFormatter(locale: product.product.priceLocale).string(from: product.product.price)
  }
}

extension IAPManager {
  private func fetch() {
    print("IAPManager: Start fetch product!")
    Glassfy.offerings { [weak self] offers, error in
      guard let self = self else {
        return
      }
      guard error == nil else {
        print("IAPManager: Product fetch failed! - \(String(describing: error))")
        return
      }
      guard
        let offers,
        let offeringKey,
        let offering = offers[offeringKey]
      else {
        print("IAPManager: Product fetch failed!")
        return
      }
      self.products = offering.skus
      retrieveInfoActions.forEach { $0() }
      retrieveInfoActions.removeAll()
    }
  }

  private func purchared() {
    print("IAPManager: Premium!")
    self.isPremium = true
  }
  
  private func priceFormatter(locale: Locale) -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.locale = locale
    formatter.numberStyle = .currency
    return formatter
  }
}
