# IAPManager

A package to help support the implementation of purchase on your **iOS** app.
- For Swift 5.5, Xcode 13.0 (macOS Monterey) or later.
- Support for apps from iOS 15.0 or newer.

## Type
- Consumable
- Non-Consumable
- Non-Renewing Subscription
- Auto-Renewing Subscription

## Installation

### Swift Package Manager

The Swift Package Manager is a tool for managing the distribution of **Swift** code. To use `IAPManager` with Swift Package Manger, add it to dependencies in your `Package.swift`.
```swift
  dependencies: [
    .package(url: "https://github.com/trinhxuanminh/IAPManager.git")
]
```

## Get started
Make sure you have created products on `AppStoreConnect`.

## Demo
Refer to the following [Demo project](https://github.com/trinhxuanminh/DemoIAPManager/tree/develop/1.3.0) to implement the purchase.

## Usage
Firstly, import `IAPManager`.
```swift
import IAPManager
```

### 1. Parameter setting

#### initialize()
Initialize, provide the permission, process unfinished transactions.

##### Parameters:
- permissions: access to unlock features.
```swift
IAPManager.shared.initialize(permissions: [BasePermission])
```

### 2. Control

#### purchase()
This function will return valid product type, product and permissions to perform the functions of unlocking and handling consumables.
```swift
IAPManager.shared.purchase(_ product: BaseProduct) async throws -> (product: BaseProduct, permissions: [BasePermission])
```
```swift
func unlock(permissions: [BasePermission]) {
  for permission in permissions {
    switch permission as! AppPermission {
    case .premium:
      self.isPremium = true
    case .skin:
      self.onwerSkin = true
    }
  }
}
```
```swift
func consumable(product: BaseProduct) {
  switch product as! AppProduct {
  case .skip5Ads:
    guard let value = product.value, let number = value["ads"] as? Int else {
      return
    }
    self.credit += number
  default:
    return
  }
}
```
```swift
func purchase(product: AppProduct) {
  Task {
    do {
      let result = try await IAPManager.shared.purchase(product)
      switch result.product.productType {
      case .consumable:
        PermissionManager.shared.consumable(product: result.product)
      default:
        PermissionManager.shared.unlock(permissions: result.permissions)
      }
    } catch let error {
      switch error as? IAPManager.PurchaseError {
      default:
        print("Purchase:", product, error)
      }
    }
  }
}
```

#### verify()
This function will return valid permissions to perform unlocking functions.
```swift
IAPManager.shared.verify() async throws -> [BasePermission]
```
```swift
func verify() {
  Task {
    do {
      let permissions = try await IAPManager.shared.verify()
      PermissionManager.shared.unlock(permissions: permissions)
    } catch let error {
      print("Verify:", error)
    }
  }
}
```

#### restore()
This function is to restore purchased subscriptions.
```swift
IAPManager.shared.restore() async throws -> [BasePermission]
```
```swift
func restore() {
  Task {
    do {
      let permissions = try await IAPManager.shared.restore()
      PermissionManager.shared.unlock(permissions: permissions)
    } catch let error {
      print("Restore:", error)
    }
  }
}
```

#### historys()
This function will return the purchase history.
```swift
IAPManager.shared.historys() async -> [Transaction]
```

#### retrieveInfo()
This function returns product information.
```swift
IAPManager.shared.retrieveInfo(product: BaseProduct) async throws -> Product
```

#### getPriceLocale()
This function returns the product price according to locale.
```swift
IAPManager.shared.getPriceLocale(product: Product) -> String?
```

## License
### [ProX Global](https://proxglobal.com)
### Copyright (c) Trịnh Xuân Minh 2023 [@trinhxuanminh](minhtx@proxglobal.com)
