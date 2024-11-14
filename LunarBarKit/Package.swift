// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "LunarBarKit",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
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
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency")
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
