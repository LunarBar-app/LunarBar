//
//  NSView+Extension.swift
//
//  Created by cyan on 12/16/22.
//

import AppKit

public extension NSView {
  /// Like backgroundColor in UIKit.
  var layerBackgroundColor: NSColor? {
    get {
      guard wantsLayer, let cgColor = layer?.backgroundColor else {
        return nil
      }

      return NSColor(cgColor: cgColor)
    }
    set {
      wantsLayer = true
      layer?.backgroundColor = newValue?.resolvedColor(with: effectiveAppearance).cgColor
    }
  }

  /// Returns the farthest parent of the current view.
  var rootView: NSView? {
    var node: NSView? = self
    while node?.superview != nil {
      node = node?.superview
    }

    return node
  }

  /// Returns the first descendant that matches a predicate, self is included.
  func firstDescendant<T: NSView>(where: ((T) -> Bool)? = nil) -> T? {
    var stack = [self]
    while !stack.isEmpty {
      let node = stack.removeLast()
      if let view = node as? T, `where`?(view) ?? true {
        return view
      }

      // Depth-first search
      stack.append(contentsOf: node.subviews)
    }

    return nil
  }
}
