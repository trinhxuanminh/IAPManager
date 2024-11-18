//
//  BaseProduct.swift
//  
//
//  Created by Trịnh Xuân Minh on 18/11/2024.
//

import Foundation

public protocol BaseProduct {
  var id: String { get }
  var title: String { get }
  var value: [String: Any]? { get }
}
