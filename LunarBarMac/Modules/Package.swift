// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Modules",
  platforms: [
    .macOS(.v26),
  ],
  products: [
    .library(
      name: "AppKitControls",
      targets: ["AppKitControls"]
    ),
    .library(
      name: "AppKitExtensions",
      targets: ["AppKitExtensions"]
    ),
  ],
  dependencies: [
    .package(path: "../LunarBarTools"),
  ],
  targets: [
    .target(
      name: "AppKitControls",
      dependencies: ["AppKitExtensions"],
      path: "Sources/AppKitControls",
      swiftSettings: [
        .unsafeFlags(["-Osize"], .when(configuration: .release)),
      ],
      plugins: [
        .plugin(name: "SwiftLint", package: "LunarBarTools"),
      ]
    ),
    .target(
      name: "AppKitExtensions",
      path: "Sources/AppKitExtensions",
      swiftSettings: [
        .unsafeFlags(["-Osize"], .when(configuration: .release)),
      ],
      plugins: [
        .plugin(name: "SwiftLint", package: "LunarBarTools"),
      ]
    ),
  ]
)
