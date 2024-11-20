//
//  AppPreferences.swift
//  LunarBarMac
//
//  Created by cyan on 12/25/23.
//

import AppKit
import LunarBarKit

/**
 UserDefaults wrapper with handy getters and setters.
 */
enum AppPreferences {
  enum General {
    @Storage(key: "general.initial-launch", defaultValue: true)
    static var initialLaunch: Bool

    @Storage(key: "general.menu-bar-icon", defaultValue: .date)
    static var menuBarIcon: MenuBarIcon {
      didSet {
        guard let delegate = NSApp.delegate as? AppDelegate else {
          return Logger.assertFail("Unexpected NSApp.delegate was found")
        }

        delegate.updateMenuBarIcon(needsLayout: true)
      }
    }

    @Storage(key: "general.appearance", defaultValue: .system)
    static var appearance: Appearance
  }

  enum Calendar {
    @Storage(key: "calendar.hidden-calendars", defaultValue: Set())
    static var hiddenCalendars: Set<String>

    @Storage(key: "calendar.default-holidays", defaultValue: true)
    static var defaultHolidays: Bool {
      didSet {
        HolidayManager.default.defaultsEnabled = defaultHolidays
      }
    }
  }

  enum Accessibility {
    @Storage(key: "accessibility.reduce-motion", defaultValue: false)
    static var reduceMotion: Bool

    @Storage(key: "accessibility.reduce-transparency", defaultValue: false)
    static var reduceTransparency: Bool

    @MainActor static var popoverMaterial: NSVisualEffectView.Material {
      reduceTransparency ? .windowBackground : .menu
    }
  }
}

// MARK: - Types

enum MenuBarIcon: Codable {
  case calendar
  case date
}

enum Appearance: Codable {
  case light
  case dark
  case system

  @MainActor
  func resolved(with appearance: NSAppearance = NSApp.effectiveAppearance) -> NSAppearance? {
    switch self {
    case .light:
      return NSAppearance(named: appearance.resolvedName(isDarkMode: false))
    case .dark:
      return NSAppearance(named: appearance.resolvedName(isDarkMode: true))
    case .system:
      return nil
    }
  }
}

@MainActor
@propertyWrapper
struct Storage<T: Codable> {
  private let key: String
  private let defaultValue: T

  init(key: String, defaultValue: T) {
    self.key = key
    self.defaultValue = defaultValue
  }

  var wrappedValue: T {
    get {
      guard let data = UserDefaults.standard.object(forKey: key) as? Data else {
        return defaultValue
      }

      let value = try? Coders.decoder.decode(T.self, from: data)
      return value ?? defaultValue
    }
    set {
      let data = try? Coders.encoder.encode(newValue)
      UserDefaults.standard.set(data, forKey: key)
    }
  }
}

private enum Coders {
  static let encoder = JSONEncoder()
  static let decoder = JSONDecoder()
}
