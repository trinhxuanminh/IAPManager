// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "IAPManager",
  platforms: [.iOS(.v15)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "IAPManager",
      targets: ["IAPManager"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),,
    .package(url: "https://github.com/firebase/firebase-ios-sdk", revision: "11.9.0"),
    .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework", revision: "6.16.0"),
    .package(url: "https://github.com/AppsFlyerSDK/appsflyer-apple-purchase-connector.git", branch: "qa-6.16.0-sk2")
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "IAPManager",
      dependencies: [
        .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
        .product(name: "AppsFlyerLib", package: "AppsFlyerFramework"),
        .product(name: "PurchaseConnector", package: "appsflyer-apple-purchase-connector")
      ]
    )
  ]
)
