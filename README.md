# IAPManager

A package to help support the implementation of purchase on your **iOS** app.
- For Swift 5.3, Xcode 12.5 (macOS Big Sur) or later.
- Support for apps from iOS 13.0 or newer.

## Type
- Consumable
- Non-Consumable
- Non-Renewing Subscription
- Auto-Renewing Subcription

## Installation

### Swift Package Manager

The Swift Package Manager is a tool for managing the distribution of **Swift** code. To use `IAPManager` with Swift Package Manger, add it to dependencies in your `Package.swift`.
```swift
  dependencies: [
    .package(url: "https://github.com/trinhxuanminh/IAPManager.git")
]
```

## Get started
Make sure you have created products on `AppStoreConnect` & `Glassfy`.

## Usage
Firstly, import `IAPManager`.
```swift
import IAPManager
```

### 1. Parameter setting

#### initialize()
Initialize, fetch available products.

##### Parameters:
- apiKey: Glassfy access key.
```swift
IAPManager.shared.initialize(apiKey: String)
```

### 2. Control

#### offerings()
This function will return available groups and products.
```swift
IAPManager.shared.offerings(completion: @escaping OfferingsCompletion, errored: Handler? = nil)
```

#### verify()
This function will return valid permissions to perform unlocking functions.
```swift
IAPManager.shared.verify(completion: @escaping PermissionCompletion, errored: Handler? = nil)
```

#### retrieveInfo()
This function returns product information.
```swift
IAPManager.shared.retrieveInfo(skuId: String, completion: @escaping RetrieveInfoCompletion, errored: Handler? = nil)
```

#### getPriceLocale()
This function returns the product price according to locale.
```swift
IAPManager.shared.getPriceLocale(product: Glassfy.Sku) -> String?
```

#### purchase()
This function will return valid permissions and products to perform the functions of unlocking and handling consumables.
```swift
IAPManager.shared.purchase(skuId: String, completion: @escaping PurchaseCompletion, errored: Handler? = nil)
```
```swift
func unlock(_ permissions: [Glassfy.Permission]) {
  for permission in permissions {
    switch permission.permissionId {
    case "premium":
      self.isPremium = true
      AdMobManager.shared.upgradePremium()
    case "background":
      print("Unlock background remover feature")
    default:
      print("Permission not handled")
    }
  }
}
```
```swift
func consumable(_ sku: Glassfy.Sku) {
  switch sku.skuId {
  case "big_gem":
    print("Add: \(sku.extravars["gems"])")
  default:
    print("Sku not handled")
  }
}
```

#### restore()
This function is to restore purchased subscriptions.
```swift
IAPManager.shared.restore(completion: @escaping PermissionCompletion, errored: Handler? = nil)
```

#### historys()
This function will return the purchase history.
```swift
IAPManager.shared.historys(completion: @escaping HistoryCompletion, errored: Handler? = nil)
```

## License
### [ProX Global](https://proxglobal.com)
### Copyright (c) Trịnh Xuân Minh 2023 [@trinhxuanminh](minhtx@proxglobal.com)
