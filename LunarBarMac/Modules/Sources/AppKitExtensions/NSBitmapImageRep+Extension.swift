//
//  NSBitmapImageRep+Extension.swift
//
//  Created by cyan on 7/6/25.
//

import AppKit

public extension NSBitmapImageRep {
  convenience init?(size: CGSize, scale: Double = NSScreen.preferredScale) {
    self.init(
      bitmapDataPlanes: nil,
      pixelsWide: Int(size.width * scale),
      pixelsHigh: Int(size.height * scale),
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bytesPerRow: 0,
      bitsPerPixel: 0
    )

    self.size = size
  }
}

// MARK: - Internal

package extension NSScreen {
  /// Preferred rendering scale based on all screens.
  @usableFromInline static var preferredScale: Double {
    max(2.0, screens.map(\.backingScaleFactor).max() ?? 2.0)
  }
}
