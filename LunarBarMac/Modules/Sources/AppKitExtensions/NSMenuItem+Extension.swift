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
}
