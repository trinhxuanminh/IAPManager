//
//  File 2.swift
//  
//
//  Created by Trịnh Xuân Minh on 25/03/2025.
//

import Foundation
import StoreKit

typealias UpdatedTransaction = (([SKPaymentTransaction]) -> Void)
public typealias PurchasedHandler = ((BaseProduct, [BasePermission]) -> Void)
public typealias ErrorHandler = ((Error) -> Void)
