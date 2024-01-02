//
//  NSImage+Extension.swift
//
//  Created by cyan on 1/15/23.
//

import AppKit

public extension NSImage {
  static func with(
    symbolName: String,
    pointSize: Double,
    weight: NSFont.Weight = .regular,
    accessibilityLabel: String? = nil
  ) -> NSImage {
    let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityLabel)
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)

    guard let image = image?.withSymbolConfiguration(config) else {
      assertionFailure("Failed to create image with symbol \"\(symbolName)\"")
      return NSImage()
    }

    return image
  }
}
