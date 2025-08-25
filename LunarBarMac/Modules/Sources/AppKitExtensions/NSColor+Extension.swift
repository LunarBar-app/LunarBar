//
//  NSColor+Extension.swift
//
//  Created by cyan on 12/17/22.
//

import AppKit

public extension NSColor {
  @MainActor
  func resolvedColor(with appearance: NSAppearance = NSApp.effectiveAppearance) -> NSColor {
    var cgColor: CGColor?
    appearance.performAsCurrentDrawingAppearance {
      cgColor = self.cgColor
    }

    return NSColor(cgColor: cgColor ?? self.cgColor) ?? self
  }

  @MainActor
  func darkerColor(with factor: Double = 0.3) -> NSColor {
    guard let color = usingColorSpace(.deviceRGB) else {
      return self
    }

    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var alpha: CGFloat = 0

    color.getHue(
      &hue,
      saturation: &saturation,
      brightness: &brightness,
      alpha: &alpha
    )

    return NSColor(
      hue: hue,
      saturation: saturation,
      brightness: max(brightness - factor, 0),
      alpha: alpha
    )
  }
}
