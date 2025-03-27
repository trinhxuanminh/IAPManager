//
//  File.swift
//  
//
//  Created by Trịnh Xuân Minh on 26/03/2025.
//

import Foundation

enum APIError: Error {
  case invalidRequest
  case invalidResponse
  case jsonEncodingError
  case jsonDecodingError
  case notInternet
  case anyError
}
