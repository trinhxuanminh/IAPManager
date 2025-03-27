//
//  File.swift
//  
//
//  Created by Trịnh Xuân Minh on 27/03/2025.
//

import Foundation

struct Receipt: Codable {
  let receiptType: String?
  let adamID: Int?
  let appItemID: Int?
  let bundleID: String?
  let applicationVersion: String?
  let downloadID: Int?
  let versionExternalIdentifier: Int?
  let receiptCreationDate: String?
  let receiptCreationDateMS: String?
  let receiptCreationDatePST: String?
  let requestDate: String?
  let requestDateMS: String?
  let requestDatePST: String?
  let originalPurchaseDate: String?
  let originalPurchaseDateMS: String?
  let originalPurchaseDatePST: String?
  let originalApplicationVersion: String?
  let inApp: [InAppPurchase]?
  
  enum CodingKeys: String, CodingKey {
    case receiptType = "receipt_type"
    case adamID = "adam_id"
    case appItemID = "app_item_id"
    case bundleID = "bundle_id"
    case applicationVersion = "application_version"
    case downloadID = "download_id"
    case versionExternalIdentifier = "version_external_identifier"
    case receiptCreationDate = "receipt_creation_date"
    case receiptCreationDateMS = "receipt_creation_date_ms"
    case receiptCreationDatePST = "receipt_creation_date_pst"
    case requestDate = "request_date"
    case requestDateMS = "request_date_ms"
    case requestDatePST = "request_date_pst"
    case originalPurchaseDate = "original_purchase_date"
    case originalPurchaseDateMS = "original_purchase_date_ms"
    case originalPurchaseDatePST = "original_purchase_date_pst"
    case originalApplicationVersion = "original_application_version"
    case inApp = "in_app"
  }
}
