//
//  AppDesign.swift
//  LunarBarMac
//
//  Created by cyan on 6/13/25.
//

import AppKit

@MainActor
enum AppDesign {
  /**
    Returns `true` to adopt the new design language in macOS Tahoe.
   */
  static var modernStyle: Bool {
    guard isMacOSTahoe else {
      return false
    }

  #if BUILD_WITH_SDK_26_OR_LATER
    return !AppPreferences.General.classicInterface
  #else
    // defaults write app.cyan.lunarbar com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck -bool true
    return UserDefaults.standard.bool(forKey: "com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck")
  #endif
  }

  static var contentMargin: Double {
    (modernStyle ? 4 : 2) * AppPreferences.General.contentScale.rawValue
  }

  static var cellCornerRadius: Double {
    modernStyle ? 7 : 4
  }

  static var menuIconSize: Double {
    isMacOSTahoe ? 17 : 14
  }

  private static var isMacOSTahoe: Bool {
    guard #available(macOS 26.0, *) else {
      return false
    }

    return true
  }
}

// MARK: - Extensions

extension NSViewController {
  func applyMaterial(_ material: NSVisualEffectView.Material) {
    self.material = material

    guard #available(macOS 26.0, *), AppDesign.modernStyle else {
      return
    }

    let tintColor: NSColor = material == .windowBackground ? .windowBackgroundColor : .clear
    visualEffectView?.enumerateDescendants { (effectView: NSView) in
    #if BUILD_WITH_SDK_26_OR_LATER
      (effectView as? NSGlassEffectView)?.tintColor = tintColor
    #else
      let setter = sel_getUid("setTintColor:")
      if effectView.responds(to: setter) {
        effectView.perform(setter, with: tintColor)
      }
    #endif
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
      ($0.isDarkMode ? NSColor.white : NSColor.black).withAlphaComponent(alpha)
    }
  }
}
