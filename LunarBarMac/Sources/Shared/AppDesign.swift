//
//  AppDesign.swift
//  LunarBarMac
//
//  Created by cyan on 6/13/25.
//

import AppKit

@MainActor
enum AppDesign {
  static var increaseContrast: Bool {
    NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
  }

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

final class PopoverContentView: NSView {
  var onAppearanceChange: (() -> Void)?

  override func viewDidChangeEffectiveAppearance() {
    super.viewDidChangeEffectiveAppearance()
    onAppearanceChange?()
  }
}

// MARK: - Extensions

extension NSViewController {
  func applyMaterial(_ material: NSVisualEffectView.Material) {
    self.material = material
    updateMaterialTint()
  }

  func updateMaterialTint() {
    // Appearance can change before the popover has a window and its effect view
    guard view.window != nil, let effectView = visualEffectView else {
      return
    }

    let appearance = view.effectiveAppearance
    let tintColor: NSColor? = {
      // Increased accessibility
      if effectView.material == .windowBackground {
        return .windowBackgroundColor.resolvedColor(with: appearance).withAlphaComponent(0.75)
      }

      // Readability is really bad in macOS 27 with dark mode
      if #available(macOS 27, *), appearance.isDarkMode {
        return .black.withAlphaComponent(0.25)
      }

      return nil
    }()

    effectView.enumerateDescendants { (glassView: NSGlassEffectView) in
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
  static var secondaryDateLabel: NSColor {
    NSColor(name: nil) {
      NSColor(white: $0.isDarkMode ? 0.75 : 0.3, alpha: 1)
    }
  }

  static var highlightedBackground: NSColor {
    let alpha: Double = AppPreferences.Accessibility.reduceTransparency ? 0.10 : 0.06
    return NSColor(name: nil) {
      ($0.isDarkMode ? Self.white : Self.black).withAlphaComponent(alpha)
    }
  }
}
