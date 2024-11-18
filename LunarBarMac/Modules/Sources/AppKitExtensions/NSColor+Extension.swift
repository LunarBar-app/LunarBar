//
//  NSColor+Extension.swift
//
//  Created by cyan on 12/17/22.
//

import AppKit

public extension NSColor {
  static var highlightedBackground: NSColor {
    NSColor(name: nil) {
      ($0.isDarkMode ? NSColor.white : NSColor.black).withAlphaComponent(0.06)
    }
  }

  @MainActor
  func resolvedColor(with appearance: NSAppearance = NSApp.effectiveAppearance) -> NSColor {
    var cgColor: CGColor?
    appearance.performAsCurrentDrawingAppearance {
      cgColor = self.cgColor
    }

    return NSColor(cgColor: cgColor ?? self.cgColor) ?? self
  }
}
