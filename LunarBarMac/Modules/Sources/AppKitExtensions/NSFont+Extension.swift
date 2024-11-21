//
//  NSFont+Extension.swift
//
//  Created by cyan on 12/21/23.
//

import AppKit

public extension NSFont {
  static func mediumSystemFont(ofSize fontSize: Double) -> NSFont {
    .systemFont(ofSize: fontSize, weight: .medium)
  }
}
