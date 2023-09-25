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
    Glassfy.permissions { [weak self] permissions, error in
      guard let self = self else {
        return
      }
      guard error == nil else {
        print(error as Any)
        errored?()
        return
      }
      guard
        let permissions,
        let permissionKey,
        let permission = permissions[permissionKey],
        permission.isValid
      else {
        print("API:Not premium!")
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
      errored?()
      return
    }
    self.isLoading = true
    Glassfy.purchase(sku: product) { [weak self] transaction, error in
      guard let self = self else {
        return
      }
      guard error == nil else {
        print(error as Any)
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
    self.isLoading = true
    Glassfy.restorePurchases { [weak self] permissions, error in
      guard let self = self else {
        return
      }
      guard error == nil else {
        print(error as Any)
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
    Glassfy.offerings { [weak self] offers, error in
      guard let self = self else {
        return
      }
      guard error == nil else {
        print(error as Any)
        return
      }
      guard
        let offers,
        let offeringKey,
        let offering = offers[offeringKey]
      else {
        return
      }
      self.products = offering.skus
      retrieveInfoActions.forEach { $0() }
      retrieveInfoActions.removeAll()
    }
  }

  private func purchared() {
    self.isPremium = true
  }
  
  private func priceFormatter(locale: Locale) -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.locale = locale
    formatter.numberStyle = .currency
    return formatter
  }
}
