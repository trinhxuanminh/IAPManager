# IAPManager

A package to help support the implementation of purchase on your **iOS** app.
- For Swift 5.3, Xcode 12.5 (macOS Big Sur) or later.
- Support for apps from iOS 13.0 or newer.

## Type
- Subscription

## Installation

### Swift Package Manager

The Swift Package Manager is a tool for managing the distribution of **Swift** code. To use `AdMobManager` with Swift Package Manger, add it to dependencies in your `Package.swift`.
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
- offeringKey: Offering identifier.
- permissionKey: Permission identifier.
```swift
IAPManager.shared.initialize(apiKey: String, offeringKey: String, permissionKey: String)
```

### 2. Control

#### isPremium
Variable indicating whether the user has purchased a subscription.

#### isLoading
Variable that indicates the system is processing purchase or restore.

#### verify()
This function helps determine whether a user has purchased a subscription or not.
```swift
IAPManager.shared.verify(completed: Handler?, errored: Handler?)
```

#### retrieveInfo()
This function returns product information.
```swift
IAPManager.shared.retrieveInfo(productID: String, completed: @escaping RetrieveInfoHandler)
```

#### getPriceLocale()
This function returns the product price according to locale.
```swift
IAPManager.shared.getPriceLocale(product: Glassfy.Sku) -> String?
```

#### purchase()
This function will display the product purchase popup
```swift
IAPManager.shared.purchase(productID: String, completed: Handler?, errored: Handler?)
```

#### restore()
This function is to restore purchased subscriptions.
```swift
IAPManager.shared.restore(completed: Handler?, nothing: Handler?, errored: Handler?)
```

## License
### [ProX Global](https://proxglobal.com)
### Copyright (c) Trịnh Xuân Minh 2023 [@trinhxuanminh](minhtx@proxglobal.com)
