//
//  File 2.swift
//  
//
//  Created by Trịnh Xuân Minh on 27/03/2025.
//

import Foundation

struct RenewalInfo: Codable {
  let expirationIntent: String?
  let autoRenewProductID: String?
  let isInBillingRetryPeriod: Bool?
  let productID: String?
  let originalTransactionID: String?
  let autoRenewStatus: Bool?
  
  enum CodingKeys: String, CodingKey {
    case expirationIntent = "expiration_intent"
    case autoRenewProductID = "auto_renew_product_id"
    case isInBillingRetryPeriod = "is_in_billing_retry_period"
    case productID = "product_id"
    case originalTransactionID = "original_transaction_id"
    case autoRenewStatus = "auto_renew_status"
  }
}
