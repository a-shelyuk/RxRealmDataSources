// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RxRealmDataSources",
    platforms: [.iOS(.v13), .macOS(.v10_13)],
    products: [
        .library(name: "RxRealmDataSources", targets: ["RxRealmDataSources"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift", .upToNextMajor(from: "6.6.0")),
        .package(url: "https://github.com/RxSwiftCommunity/RxRealm.git", .upToNextMajor(from: "5.0.7")),
        .package(url: "https://github.com/RxSwiftCommunity/RxDataSources.git", .upToNextMajor(from: "5.0.2"))
    ],
    targets: [
        .target(
          name: "RxRealmDataSources",
          dependencies: [
            "RxSwift", "RxRealm", "RxDataSources"
          ],
          path: "Pod/Classes")
    ]
)
