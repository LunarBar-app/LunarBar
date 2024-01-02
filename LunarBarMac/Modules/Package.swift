// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Modules",
  platforms: [
    .macOS(.v13),
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
      plugins: [
        .plugin(name: "SwiftLint", package: "LunarBarTools"),
      ]
    ),
    .target(
      name: "AppKitExtensions",
      path: "Sources/AppKitExtensions",
      plugins: [
        .plugin(name: "SwiftLint", package: "LunarBarTools"),
      ]
    ),
  ]
)
