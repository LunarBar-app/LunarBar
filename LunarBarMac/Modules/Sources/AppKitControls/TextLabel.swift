//
//  TextLabel.swift
//
//  Created by cyan on 12/19/22.
//

import AppKit

/**
 Like UILabel in UIKit, used to display read-only text, not editable.
 */
public final class TextLabel: NSTextField {
  public init() {
    super.init(frame: .zero)
    setAccessibilityRole(.staticText)

    backgroundColor = .clear
    isBordered = false
    isEditable = false
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
