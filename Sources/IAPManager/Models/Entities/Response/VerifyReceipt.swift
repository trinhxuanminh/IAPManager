//
//  File.swift
//  
//
//  Created by Trịnh Xuân Minh on 27/03/2025.
//

import Foundation

public struct VerifyReceipt: Codable {
  let status: Int?
  let environment: String?
  let receipt: Receipt?
  let latestReceiptInfo: [InAppPurchase]?
  let latestReceipt: String?
  let pendingRenewalInfo: [RenewalInfo]?
  
  enum CodingKeys: String, CodingKey {
    case status
    case environment
    case receipt
    case latestReceiptInfo = "latest_receipt_info"
    case latestReceipt = "latest_receipt"
    case pendingRenewalInfo = "pending_renewal_info"
  }
}
