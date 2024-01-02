// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "LunarBarKit",
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
  ],
  products: [
    .library(
      name: "LunarBarKit",
      targets: ["LunarBarKit"]
    ),
  ],
  dependencies: [
    .package(path: "../LunarBarTools"),
  ],
  targets: [
    .target(
      name: "LunarBarKit",
      path: "Sources",
      resources: [
        .process("LunarCalendar/Resources"),
      ],
      plugins: [
        .plugin(name: "SwiftLint", package: "LunarBarTools"),
      ]
    ),

    .testTarget(
      name: "LunarBarKitTests",
      dependencies: ["LunarBarKit"],
      path: "Tests",
      plugins: [
        .plugin(name: "SwiftLint", package: "LunarBarTools"),
      ]
    ),
  ]
)
