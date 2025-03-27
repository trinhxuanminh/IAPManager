//
//  File.swift
//  
//
//  Created by Trịnh Xuân Minh on 26/03/2025.
//

import Foundation

struct VerifyReceiptBody: Codable {
  let receipt: String
  let sharedSecret: String
  let excludeOldTransactions: Bool
  
  enum CodingKeys: String, CodingKey {
    case receipt = "receipt-data"
    case sharedSecret = "password"
    case excludeOldTransactions = "exclude-old-transactions"
  }
}
