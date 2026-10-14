//
//  AppPreferencesTests.swift
//  LunarBarMacTests
//
//  Created by cyan on 12/31/23.
//

import AppKit
import XCTest
@testable import LunarBar

@MainActor
final class AppPreferencesTests: XCTestCase {
  func testSetEncodingDecoding() {
    AppPreferences.Mocked.setObjects.removeAll()
    XCTAssertEqual(AppPreferences.Mocked.setObjects, Set())

    AppPreferences.Mocked.setObjects.insert("Foo")
    AppPreferences.Mocked.setObjects.insert("Bar")
    XCTAssertEqual(AppPreferences.Mocked.setObjects, Set(["Foo", "Bar"]))

    AppPreferences.Mocked.setObjects.toggle("Foo")
    XCTAssertEqual(AppPreferences.Mocked.setObjects, Set(["Bar"]))
  }

  func testDateStylesPersistIndependently() throws {
    let defaults = UserDefaults.standard
    let weekdayKey = "calendar.weekday-date-style"
    let weekendKey = "calendar.weekend-date-style"
    let previousWeekday = defaults.object(forKey: weekdayKey)
    let previousWeekend = defaults.object(forKey: weekendKey)
    defer {
      defaults.set(previousWeekday, forKey: weekdayKey)
      defaults.set(previousWeekend, forKey: weekendKey)
    }

    defaults.removeObject(forKey: weekdayKey)
    defaults.removeObject(forKey: weekendKey)
    XCTAssertEqual(AppPreferences.Calendar.weekdayDateStyle, DateFontStyle())
    XCTAssertEqual(AppPreferences.Calendar.weekendDateStyle, DateFontStyle())

    let color = try XCTUnwrap(DateFontColor(color: .systemRed))
    let weekendStyle = DateFontStyle(color: color, isBold: true)
    AppPreferences.Calendar.weekendDateStyle = weekendStyle
    XCTAssertEqual(AppPreferences.Calendar.weekdayDateStyle, DateFontStyle())

    let savedData = try XCTUnwrap(defaults.data(forKey: weekendKey))
    XCTAssertEqual(try JSONDecoder().decode(DateFontStyle.self, from: savedData), weekendStyle)

    AppPreferences.Calendar.weekdayDateStyle = DateFontStyle(isBold: true)
    AppPreferences.Calendar.weekendDateStyle = DateFontStyle()
    XCTAssertTrue(AppPreferences.Calendar.weekdayDateStyle.isBold)
    XCTAssertNil(AppPreferences.Calendar.weekdayDateStyle.color)
    XCTAssertEqual(AppPreferences.Calendar.weekendDateStyle, DateFontStyle())

    defaults.set(Data("invalid".utf8), forKey: weekendKey)
    XCTAssertEqual(AppPreferences.Calendar.weekendDateStyle, DateFontStyle())
  }

  func testWeekendIsSaturdayAndSundayAcrossLocalesAndWeekStarts() throws {
    for locale in ["zh_CN", "en_US", "ar_SA"] {
      for firstWeekday in [1, 2, 7] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: locale)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Shanghai"))
        calendar.firstWeekday = firstWeekday
        for day in 12...18 {
          let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: day)))
          XCTAssertEqual(DateFontStyle.isWeekend(date, calendar: calendar), day >= 17)
        }
      }
    }
  }

  func testDateColorsRoundTripAndDefaultFollowsAppearance() throws {
    let original = NSColor(srgbRed: 0.2, green: 0.4, blue: 0.8, alpha: 0.5)
    let stored = try XCTUnwrap(DateFontColor(color: original))
    let restored = try JSONDecoder().decode(DateFontColor.self, from: JSONEncoder().encode(stored))
    XCTAssertEqual(restored.nsColor.redComponent, 0.2, accuracy: 0.001)
    XCTAssertEqual(restored.nsColor.greenComponent, 0.4, accuracy: 0.001)
    XCTAssertEqual(restored.nsColor.blueComponent, 0.8, accuracy: 0.001)
    XCTAssertEqual(restored.nsColor.alphaComponent, 1)
    XCTAssertEqual(DateFontStyle().textColor, NSColor.labelColor)
    XCTAssertTrue(NSFontManager.shared.traits(of: DateFontStyle(isBold: true).font(ofSize: 14)).contains(.boldFontMask))
    XCTAssertFalse(NSFontManager.shared.traits(of: DateFontStyle().font(ofSize: 14)).contains(.boldFontMask))
  }

  func testDateFontControlsSaveIndependentlyAndNotify() throws {
    try preservingDateStyles {
      let controller = DateFontSettingsController.shared
      defer {
        controller.close()
        NSColorPanel.shared.orderOut(nil)
      }
      let content = try XCTUnwrap(controller.window?.contentView)
      let controls = descendants(of: content)
      let buttons = controls.compactMap { $0 as? NSButton }
      let boldButtons = buttons.filter { $0.action.map(NSStringFromSelector) == "changeBold" }
      XCTAssertEqual(boldButtons.count, 2)
      XCTAssertTrue(boldButtons.allSatisfy { $0.title == Localized.DateFonts.bold })
      XCTAssertFalse(buttons.contains { $0.action.map(NSStringFromSelector) == "changeSystemColor" })

      let rows = controls.compactMap { $0 as? NSBox }
      let weekdayRow = try XCTUnwrap(rows.first { $0.title == Localized.DateFonts.weekdays })
      let weekendRow = try XCTUnwrap(rows.first { $0.title == Localized.DateFonts.weekends })
      let weekdayWell = try XCTUnwrap(descendants(of: weekdayRow).compactMap { $0 as? NSColorWell }.first)
      let weekendWell = try XCTUnwrap(descendants(of: weekendRow).compactMap { $0 as? NSColorWell }.first)
      let weekdayBold = try XCTUnwrap(descendants(of: weekdayRow).compactMap { $0 as? NSButton }.first { $0.title == Localized.DateFonts.bold })
      let weekendBold = try XCTUnwrap(descendants(of: weekendRow).compactMap { $0 as? NSButton }.first { $0.title == Localized.DateFonts.bold })
      let restore = try XCTUnwrap(buttons.first { $0.title == Localized.DateFonts.restoreDefaults })
      try sendAction(restore)
      XCTAssertTrue(weekdayWell.isEnabled)
      XCTAssertTrue(weekendWell.isEnabled)

      let recorder = DateStyleChangeRecorder()
      NotificationCenter.default.addObserver(
        recorder,
        selector: #selector(DateStyleChangeRecorder.receive(_:)),
        name: .calendarDateStyleDidChange,
        object: nil
      )
      defer { NotificationCenter.default.removeObserver(recorder) }

      weekdayWell.color = NSColor(srgbRed: 0.9, green: 0.1, blue: 0.2, alpha: 1)
      let weekdayColor = try XCTUnwrap(DateFontColor(color: weekdayWell.color))
      try sendAction(weekdayWell)
      XCTAssertEqual(recorder.count, 1)
      XCTAssertEqual(AppPreferences.Calendar.weekdayDateStyle, DateFontStyle(color: weekdayColor))
      XCTAssertEqual(AppPreferences.Calendar.weekendDateStyle, DateFontStyle())

      weekdayBold.state = .on
      try sendAction(weekdayBold)
      XCTAssertEqual(recorder.count, 2)
      XCTAssertEqual(AppPreferences.Calendar.weekdayDateStyle, DateFontStyle(color: weekdayColor, isBold: true))

      weekendWell.color = NSColor(srgbRed: 0.1, green: 0.4, blue: 0.9, alpha: 1)
      let weekendColor = try XCTUnwrap(DateFontColor(color: weekendWell.color))
      try sendAction(weekendWell)
      weekendBold.state = .on
      try sendAction(weekendBold)
      XCTAssertEqual(recorder.count, 4)
      XCTAssertEqual(AppPreferences.Calendar.weekendDateStyle, DateFontStyle(color: weekendColor, isBold: true))
      XCTAssertEqual(AppPreferences.Calendar.weekdayDateStyle, DateFontStyle(color: weekdayColor, isBold: true))

      try sendAction(restore)
      XCTAssertEqual(recorder.count, 5)
      XCTAssertEqual(AppPreferences.Calendar.weekdayDateStyle, DateFontStyle())
      XCTAssertEqual(AppPreferences.Calendar.weekendDateStyle, DateFontStyle())
      XCTAssertEqual(weekdayBold.state, .off)
      XCTAssertEqual(weekendBold.state, .off)
      XCTAssertTrue(weekdayWell.isEnabled)
      XCTAssertTrue(weekendWell.isEnabled)
    }
  }

  func testExistingDateCellUpdatesStyleWithoutReloadingDate() throws {
    try preservingDateStyles {
      AppPreferences.Calendar.weekdayDateStyle = DateFontStyle()
      AppPreferences.Calendar.weekendDateStyle = DateFontStyle()
      let calendar = Calendar(identifier: .gregorian)
      let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 12, hour: 12)))
      let cell = DateGridCell()
      _ = cell.view
      cell.updateViews(cellDate: date, cellEvents: [], monthDate: date, lunarInfo: nil)
      let labels = descendants(of: cell.view).compactMap { $0 as? NSTextField }
      let solar = try XCTUnwrap(labels.first { $0.stringValue == "12" })
      let lunar = try XCTUnwrap(labels.first { $0 !== solar })
      let lunarText = lunar.stringValue
      let lunarFont = lunar.font
      let lunarColor = lunar.textColor

      let color = try XCTUnwrap(DateFontColor(color: .systemRed))
      AppPreferences.Calendar.weekdayDateStyle = DateFontStyle(color: color, isBold: true)
      cell.updateDateStyle()
      cell.updateOpacity(monthDate: date)
      XCTAssertEqual(solar.textColor, color.nsColor)
      XCTAssertTrue(NSFontManager.shared.traits(of: try XCTUnwrap(solar.font)).contains(.boldFontMask))
      XCTAssertEqual(solar.alphaValue, AlphaLevels.primary)
      XCTAssertEqual(solar.stringValue, "12")
      XCTAssertEqual(lunar.stringValue, lunarText)
      XCTAssertEqual(lunar.font, lunarFont)
      XCTAssertEqual(lunar.textColor, lunarColor)

      AppPreferences.Calendar.weekdayDateStyle = DateFontStyle()
      cell.updateDateStyle()
      XCTAssertEqual(solar.textColor, NSColor.labelColor)
      XCTAssertFalse(NSFontManager.shared.traits(of: try XCTUnwrap(solar.font)).contains(.boldFontMask))
      XCTAssertEqual(solar.stringValue, "12")
    }
  }

  private func preservingDateStyles(_ body: () throws -> Void) rethrows {
    let defaults = UserDefaults.standard
    let weekdayKey = "calendar.weekday-date-style"
    let weekendKey = "calendar.weekend-date-style"
    let weekday = defaults.object(forKey: weekdayKey)
    let weekend = defaults.object(forKey: weekendKey)
    defer {
      defaults.set(weekday, forKey: weekdayKey)
      defaults.set(weekend, forKey: weekendKey)
    }
    try body()
  }

  private func descendants(of view: NSView) -> [NSView] {
    [view] + view.subviews.flatMap { descendants(of: $0) }
  }

  private func sendAction(_ control: NSControl) throws {
    XCTAssertTrue(control.isEnabled)
    let action = try XCTUnwrap(control.action)
    XCTAssertTrue(NSApp.sendAction(action, to: control.target, from: control))
  }
}

// MARK: - Private

@MainActor
private final class DateStyleChangeRecorder: NSObject {
  var count = 0

  @objc func receive(_ notification: Notification) {
    count += 1
  }
}

private extension AppPreferences {
  enum Mocked {
    @Storage(key: "mocked.set-objects", defaultValue: Set())
    static var setObjects: Set<String>
  }
}
