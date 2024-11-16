//
//  NSPopover+Extension.swift
//
//  Created by cyan on 12/27/23.
//

import AppKit

public extension NSPopover {
  var material: NSVisualEffectView.Material {
    get {
      contentViewController?.material ?? .popover
    }
    set {
      contentViewController?.material = newValue
    }
  }
}
