// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PayblastPurchases",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(name: "PayblastPurchases", targets: ["PayblastPurchases"]),
    ],
    targets: [
        .target(name: "PayblastPurchases"),
        .testTarget(name: "PayblastPurchasesTests", dependencies: ["PayblastPurchases"]),
    ]
)
