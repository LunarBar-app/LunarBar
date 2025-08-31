//
//  NSPopover+Extension.swift
//
//  Created by cyan on 8/31/25.
//

import AppKit

public extension NSPopover {
  var window: NSWindow? {
    contentViewController?.view.window
  }

  var anchorHidden: Bool {
    get {
      (value(forKey: "shouldHideAnchor") as? Bool) == true
    }
    set {
      setValue(newValue, forKey: "shouldHideAnchor")
    }
  }
}
