//
//  File 2.swift
//  
//
//  Created by Trịnh Xuân Minh on 27/03/2025.
//

import Foundation

struct InAppPurchase: Codable {
  let quantity: Int
  let productID: String
  let transactionID: String
  let originalTransactionID: String
  let purchaseDate: String
  let purchaseDateMS: String
  let purchaseDatePST: String
  let originalPurchaseDate: String
  let originalPurchaseDateMS: String
  let originalPurchaseDatePST: String
  let expiresDate: String
  let expiresDateMS: String
  let expiresDatePST: String
  let webOrderLineItemID: Int
  let isTrialPeriod: Bool
  let isInIntroOfferPeriod: Bool
  let inAppOwnershipType: String
  let subscriptionGroupIdentifier: String?
  
  enum CodingKeys: String, CodingKey {
    case quantity
    case productID = "product_id"
    case transactionID = "transaction_id"
    case originalTransactionID = "original_transaction_id"
    case purchaseDate = "purchase_date"
    case purchaseDateMS = "purchase_date_ms"
    case purchaseDatePST = "purchase_date_pst"
    case originalPurchaseDate = "original_purchase_date"
    case originalPurchaseDateMS = "original_purchase_date_ms"
    case originalPurchaseDatePST = "original_purchase_date_pst"
    case expiresDate = "expires_date"
    case expiresDateMS = "expires_date_ms"
    case expiresDatePST = "expires_date_pst"
    case webOrderLineItemID = "web_order_line_item_id"
    case isTrialPeriod = "is_trial_period"
    case isInIntroOfferPeriod = "is_in_intro_offer_period"
    case inAppOwnershipType = "in_app_ownership_type"
    case subscriptionGroupIdentifier = "subscription_group_identifier"
  }
}
