//
//  ImageButton.swift
//
//  Created by cyan on 12/21/23.
//

import AppKit
import AppKitExtensions

/**
 Button with an image as its content.

 Its hitTest rect is larger than it looks, since generally image buttons are too small.
 */
public final class ImageButton: CustomButton {
  public init(symbolName: String, tintColor: NSColor? = nil, accessibilityLabel: String) {
    super.init()
    image = .with(symbolName: symbolName, pointSize: 14, weight: .medium)
    contentTintColor = tintColor
    toolTip = accessibilityLabel
    hitTestInsets = CGPoint(x: -6, y: -6)
  }

  override public func accessibilityLabel() -> String? {
    toolTip
  }
}
