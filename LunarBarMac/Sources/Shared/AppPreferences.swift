//
//  AppPreferences.swift
//  LunarBarMac
//
//  Created by cyan on 12/25/23.
//

import AppKit

/**
 UserDefaults wrapper with handy getters and setters.
 */
enum AppPreferences {
  enum General {
    @Storage(key: "general.initial-launch", defaultValue: true)
    static var initialLaunch: Bool

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
  }
}

// MARK: - Types

enum Appearance: Codable {
  case system
  case light
  case dark

  func resolved(with appearance: NSAppearance = NSApp.effectiveAppearance) -> NSAppearance? {
    switch self {
    case .system:
      return nil
    case .light:
      return NSAppearance(named: appearance.resolvedName(isDarkMode: false))
    case .dark:
      return NSAppearance(named: appearance.resolvedName(isDarkMode: true))
    }
  }
}

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
