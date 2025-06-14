//
//  NSViewController+Extension.swift
//
//  Created by cyan on 11/17/24.
//

import AppKit

public extension NSViewController {
  var material: NSVisualEffectView.Material {
    get {
      visualEffectView?.material ?? .popover
    }
    set {
      visualEffectView?.material = newValue
    }
  }

  var visualEffectView: NSVisualEffectView? {
    guard let rootView = view.rootView else {
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
