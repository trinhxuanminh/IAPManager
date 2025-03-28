//
//  BaseProduct.swift
//  
//
//  Created by Trịnh Xuân Minh on 18/11/2024.
//

import Foundation
import StoreKit

public protocol BaseProduct {
  var id: String { get }
  var productType: Product.ProductType { get }
  var title: String { get }
  var value: [String: Any]? { get }
}
