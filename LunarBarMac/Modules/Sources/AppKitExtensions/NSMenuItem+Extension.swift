//
//  NSMenuItem+Extension.swift
//
//  Created by cyan on 12/25/22.
//

import AppKit

public extension NSMenuItem {
  convenience init(title: String) {
    self.init(title: title, action: nil, keyEquivalent: "")
  }

  func setOn(_ on: Bool) {
    state = on ? .on : .off
  }

  func ensureImageVisibility() {
    guard #available(macOS 27.0, *) else {
      return
    }

  #if canImport(FoundationModels, _version: 2)
    preferredImageVisibility = .visible
  #else
    let selector = sel_getUid("setPreferredImageVisibility:")
    if responds(to: selector) {
      unsafeBitCast(
        method(for: selector),
        to: (@convention(c) (NSMenuItem, Selector, Int) -> Void).self
      )(self, selector, 1) // .visible
    } else {
      assertionFailure("Missing setPreferredImageVisibility:")
    }
  #endif
  }
}
