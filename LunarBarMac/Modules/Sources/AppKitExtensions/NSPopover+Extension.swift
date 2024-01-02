//
//  NSPopover+Extension.swift
//
//  Created by cyan on 12/27/23.
//

import AppKit

public extension NSPopover {
  var reduceTransparency: Bool {
    get {
      visualEffectView?.material == .windowBackground
    }
    set {
      visualEffectView?.material = newValue ? .windowBackground : .popover
    }
  }
}

// MARK: - Private

private extension NSPopover {
  var visualEffectView: NSVisualEffectView? {
    guard let rootView = contentViewController?.view.rootView else {
      assertionFailure("Failed to get rootView from: \(self)")
      return nil
    }

    guard let effectView = rootView.firstDescendant(where: { $0 is NSVisualEffectView }) else {
      assertionFailure("Failed to get effectView from: \(self)")
      return nil
    }

    return effectView as? NSVisualEffectView
  }
}
