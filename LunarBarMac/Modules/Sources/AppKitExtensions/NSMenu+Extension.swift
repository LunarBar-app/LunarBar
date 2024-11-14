//
//  NSMenu+Extension.swift
//
//  Created by cyan on 12/26/22.
//

import AppKit

@MainActor
public extension NSMenu {
  @discardableResult
  func addItem(withTitle string: String, action selector: Selector? = nil) -> NSMenuItem {
    addItem(withTitle: string, action: selector, keyEquivalent: "")
  }

  @discardableResult
  func addItem(withTitle string: String, action: @escaping () -> Void) -> NSMenuItem {
    let item = addItem(withTitle: string, action: nil)
    item.addAction(action)
    return item
  }

  func addSeparator() {
    addItem(.separator())
  }
}
