//
//  AppDesign.swift
//  LunarBarMac
//
//  Created by cyan on 6/13/25.
//

import AppKit

@MainActor
enum AppDesign {
  static var contentMargin: Double {
    4 * AppPreferences.General.contentScale.rawValue
  }

  static var cellRectInset: Double {
    AppPreferences.General.contentScale.rawValue
  }

  static var cellCornerRadius: Double {
    7
  }

  static var menuIconSize: Double {
    17
  }
}

// MARK: - Extensions

extension NSViewController {
  func applyMaterial(_ material: NSVisualEffectView.Material) {
    self.material = material

    let tintColor: NSColor = material == .windowBackground ? .windowBackgroundColor : .clear
    visualEffectView?.enumerateDescendants { (glassView: NSGlassEffectView) in
      glassView.tintColor = tintColor
    }
  }
}

extension NSPopover {
  func applyMaterial(_ material: NSVisualEffectView.Material) {
    contentViewController?.applyMaterial(material)
  }
}

@MainActor
extension NSColor {
  static var highlightedBackground: NSColor {
    let alpha: Double = AppPreferences.Accessibility.reduceTransparency ? 0.10 : 0.06
    return NSColor(name: nil) {
      ($0.isDarkMode ? Self.white : Self.black).withAlphaComponent(alpha)
    }
  }
}
