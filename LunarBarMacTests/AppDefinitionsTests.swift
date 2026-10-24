//
//  AppDefinitionsTests.swift
//  LunarBarMacTests
//
//  Created by cyan on 12/31/23.
//

import AppKit
import EventKit
import LunarBarKit
import XCTest
@testable import LunarBar

final class AppDefinitionsTests: XCTestCase {
  @MainActor
  func testDesignMetrics() {
    let scale = AppPreferences.General.contentScale.rawValue
    XCTAssertEqual(AppDesign.contentMargin, 4 * scale)
    XCTAssertEqual(AppDesign.cellRectInset, scale)
    XCTAssertEqual(AppDesign.cellCornerRadius, 7)
    XCTAssertEqual(AppDesign.menuIconSize, 17)
  }

  @MainActor
  func testDateContrastAndRestoration() throws {
    let monthDate = try XCTUnwrap(Calendar.solar.date(from: DateComponents(year: 2024, month: 2, day: 1)))
    let dates = try XCTUnwrap(Calendar.solar.allDatesFillingMonth(from: monthDate))
    let cell = DateGridCell()

    for date in dates + [.now] {
      cell.updateViews(cellDate: date, cellEvents: [], monthDate: monthDate, lunarInfo: nil)
      var labels: [NSTextField] = []
      cell.view.enumerateDescendants { (label: NSTextField) in
        labels.append(label)
      }

      XCTAssertEqual(labels.count, 2)
      let events: EventView = try XCTUnwrap(cell.view.firstDescendant())
      let holiday: NSImageView = try XCTUnwrap(cell.view.firstDescendant())
      let isCurrentMonth = Calendar.solar.month(from: date) == Calendar.solar.month(from: monthDate)
      let isToday = Calendar.solar.isDateInToday(date)

      for increased in [false, true, false] {
        cell.updateAppearance(monthDate: monthDate, increaseContrast: increased)
        let standardAlpha = isCurrentMonth
          ? (Calendar.solar.isDateInWeekend(date) && !isToday ? AlphaLevels.secondary : AlphaLevels.primary)
          : AlphaLevels.tertiary

        for label in labels {
          XCTAssertEqual(label.alphaValue, increased ? AlphaLevels.primary : standardAlpha)
          XCTAssertEqual(
            label.textColor?.resolvedColor(with: cell.view.effectiveAppearance),
            (increased && !isCurrentMonth && !isToday ? NSColor.secondaryDateLabel : Colors.primaryLabel)
              .resolvedColor(with: cell.view.effectiveAppearance)
          )
        }

        let markerAlpha = increased || isCurrentMonth ? AlphaLevels.primary : AlphaLevels.tertiary
        XCTAssertEqual(events.alphaValue, markerAlpha)
        XCTAssertEqual(holiday.alphaValue, markerAlpha)

        var outlinedViews: [NSView] = []
        cell.view.enumerateDescendants { (view: NSView) in
          if let width = view.layer?.borderWidth, width > 0 {
            outlinedViews.append(view)
          }
        }

        XCTAssertEqual(outlinedViews.compactMap { $0.layer?.borderWidth }.sorted(), increased ? [1, 2] : [2])
        let todayOutline = try XCTUnwrap(outlinedViews.first { $0.layer?.borderWidth == 2 })
        XCTAssertEqual(todayOutline.isHidden, !isToday)
        XCTAssertEqual(
          todayOutline.layer?.borderColor,
          Colors.controlAccent.resolvedColor(with: cell.view.effectiveAppearance).cgColor
        )
      }
    }
  }

  @MainActor
  func testWeekdayContrastAndRestoration() {
    let view = WeekdayView()
    for increased in [false, true, false] {
      view.updateAppearance(increaseContrast: increased)
      XCTAssertEqual(view.arrangedSubviews.count, Calendar.solar.numberOfDaysInWeek)

      for (index, label) in view.arrangedSubviews.enumerated() {
        let expected = !increased && Calendar.solar.weekendIndices.contains(index)
          ? AlphaLevels.secondary : AlphaLevels.primary
        XCTAssertEqual(label.alphaValue, expected)
      }
    }
  }

  @MainActor
  func testEventDotPreservesCalendarColorAcrossAppearances() throws {
    let store = EKEventStore()
    let calendar = EKCalendar(for: .event, eventStore: store)
    calendar.cgColor = NSColor.yellow.cgColor

    let event = EKEvent(eventStore: store)
    event.calendar = calendar

    let view = EventView()
    view.updateEvents([event])

    let dot = try XCTUnwrap(view.arrangedSubviews.first)
    let originalColor = try XCTUnwrap(dot.layer?.backgroundColor)
    let borderColor = try XCTUnwrap(NSColor(cgColor: originalColor)).darkerColor()

    for name in [
      NSAppearance.Name.aqua, .darkAqua,
      .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua,
    ] {
      view.appearance = try XCTUnwrap(NSAppearance(named: name))
      dot.layoutSubtreeIfNeeded()
      XCTAssertEqual(dot.layer?.backgroundColor, originalColor)
      XCTAssertEqual(dot.layer?.borderWidth, CGFloat(dot.hairlineWidth))
      XCTAssertEqual(
        dot.layer?.borderColor,
        borderColor.resolvedColor(with: dot.effectiveAppearance).cgColor
      )
    }
  }

  @MainActor
  func testContrastNotificationPreservesDisplayedMonth() throws {
    let originalAppearance = NSApp.appearance
    defer { NSApp.appearance = originalAppearance }
    let controller = AppMainVC()
    controller.loadViewIfNeeded()

    let weekdays: WeekdayView = try XCTUnwrap(controller.view.firstDescendant())
    weekdays.updateAppearance(increaseContrast: !AppDesign.increaseContrast)

    let date = try XCTUnwrap(Calendar.solar.date(from: DateComponents(year: 2024, month: 2, day: 1)))
    controller.monthDate = date

    NSWorkspace.shared.notificationCenter.post(
      name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
      object: NSWorkspace.shared
    )

    XCTAssertEqual(controller.monthDate, date)
    for (index, label) in weekdays.arrangedSubviews.enumerated() {
      let expected = !AppDesign.increaseContrast && Calendar.solar.weekendIndices.contains(index)
        ? AlphaLevels.secondary : AlphaLevels.primary
      XCTAssertEqual(label.alphaValue, expected)
    }
  }

  @MainActor
  func testHighContrastTextRatios() throws {
    for name in [
      NSAppearance.Name.aqua, .darkAqua,
      .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua,
    ] {
      let appearance = try XCTUnwrap(NSAppearance(named: name))
      let background = try XCTUnwrap(
        NSColor.windowBackgroundColor.resolvedColor(with: appearance).usingColorSpace(.sRGB)
      )

      for color in [Colors.primaryLabel, .secondaryDateLabel] {
        let foreground = try XCTUnwrap(color.resolvedColor(with: appearance).usingColorSpace(.sRGB))
        let alpha = foreground.alphaComponent
        let textLuminance = luminance(
          red: foreground.redComponent * alpha + background.redComponent * (1 - alpha),
          green: foreground.greenComponent * alpha + background.greenComponent * (1 - alpha),
          blue: foreground.blueComponent * alpha + background.blueComponent * (1 - alpha)
        )

        let backgroundLuminance = luminance(
          red: background.redComponent, green: background.greenComponent, blue: background.blueComponent
        )

        let ratio = (max(textLuminance, backgroundLuminance) + 0.05)
          / (min(textLuminance, backgroundLuminance) + 0.05)
        XCTAssertGreaterThanOrEqual(ratio, 4.5, "\(name.rawValue): \(color)")
      }
    }
  }

  private func luminance(red: CGFloat, green: CGFloat, blue: CGFloat) -> CGFloat {
    func linearize(_ component: CGFloat) -> CGFloat {
      component <= 0.04045 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
    }

    return linearize(red) * 0.2126 + linearize(green) * 0.7152 + linearize(blue) * 0.0722
  }
}

// MARK: - Calendar Symbols

extension AppDefinitionsTests {
  func testSolarTerms() {
    XCTAssertEqual(
      Localized.Calendar.solarTerms,
      [
        "立春",
        "雨水",
        "惊蛰",
        "春分",
        "清明",
        "谷雨",
        "立夏",
        "小满",
        "芒种",
        "夏至",
        "小暑",
        "大暑",
        "立秋",
        "处暑",
        "白露",
        "秋分",
        "寒露",
        "霜降",
        "立冬",
        "小雪",
        "大雪",
        "冬至",
        "小寒",
        "大寒",
      ],
      "Should be in Chinese when the locale is default"
    )
  }

  func testChineseMonths() {
    XCTAssertEqual(
      Localized.Calendar.chineseMonths,
      [
        "正月",
        "二月",
        "三月",
        "四月",
        "五月",
        "六月",
        "七月",
        "八月",
        "九月",
        "十月",
        "冬月",
        "腊月",
      ],
      "Should be in Chinese when the locale is default"
    )
  }

  func testChineseDays() {
    XCTAssertEqual(
      Localized.Calendar.chineseDays,
      [
        "初一",
        "初二",
        "初三",
        "初四",
        "初五",
        "初六",
        "初七",
        "初八",
        "初九",
        "初十",
        "十一",
        "十二",
        "十三",
        "十四",
        "十五",
        "十六",
        "十七",
        "十八",
        "十九",
        "二十",
        "廿一",
        "廿二",
        "廿三",
        "廿四",
        "廿五",
        "廿六",
        "廿七",
        "廿八",
        "廿九",
        "三十",
      ],
      "Should be in Chinese when the locale is default"
    )
  }

  func testLunarFestivals() {
    let festivals = Localized.Calendar.lunarFestivals
    let keys = festivals.map { $0.key }.sorted()

    XCTAssertEqual(
      keys.compactMap { festivals[$0] },
      [
        "春节",
        "元宵",
        "龙抬头",
        "端午",
        "七夕",
        "中元节",
        "中秋",
        "重阳",
        "寒衣节",
        "下元节",
        "腊八",
      ],
      "Should be in Chinese when the locale is default"
    )
  }
}
