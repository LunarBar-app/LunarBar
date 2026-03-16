//
//  AppIconFactory.swift
//  LunarBarMac
//
//  Created by cyan on 1/8/24.
//

import AppKit
@preconcurrency import JavaScriptCore
import LunarBarKit

extension Notification.Name {
  static let menuBarIconDidChange = Notification.Name("MenuBarIconDidChange")
}

@MainActor
func customDateText() -> String? {
  guard let dateFormat = AppPreferences.General.customDateFormat, !dateFormat.isEmpty else {
    return nil
  }

  let formatter = DateFormatter()
  formatter.dateFormat = JSEvaluator.resolve(input: dateFormat)
  return formatter.string(from: Date.now)
}

@MainActor
enum DateIconStyle {
  case filled
  case outlined
}

@MainActor
enum AppIconFactory {
  private enum Constants {
    static let defaultIconSize: Double = 16
  }

  static func createDateIcon(style: DateIconStyle) -> NSImage? {
    DateIconView(style: style).snapshotImage?.asTemplate
  }

  static func createCalendarIcon(pointSize: Double = Constants.defaultIconSize) -> NSImage? {
    createSystemSymbol(named: Icons.calendar, pointSize: pointSize)
  }

  static func createSystemIcon(pointSize: Double = Constants.defaultIconSize) -> NSImage? {
    createSystemSymbol(named: AppPreferences.General.systemSymbolName, pointSize: pointSize)
  }

  static func createCustomIcon() -> NSImage? {
    guard let text = customDateText() else {
      return .with(symbolName: Icons.exclamationmarkTriangle, pointSize: 15)
    }

    let image: NSImage = .with(text: text, font: .menuBarMonospacedDigitFont)
    return image.asTemplate
  }

  private static func createSystemSymbol(named symbolName: String?, pointSize: Double) -> NSImage? {
    guard let symbolName else {
      return nil
    }

    return .with(symbolName: symbolName, pointSize: pointSize).asTemplate
  }
}

// MARK: - Private

private class DateIconView: NSView {
  private enum Constants {
    static let iconSize = CGSize(width: 21, height: 15)
    static let fontSize: Double = 12
    static let textHeight: Double = 8.5
    static let cornerRadius: Double = 2.5
    static let borderWidth: Double = 2.0
  }

  private var currentDay: Int {
    Calendar.solar.component(.day, from: .now)
  }

  private let style: DateIconStyle

  init(style: DateIconStyle) {
    self.style = style
    super.init(frame: CGRect(origin: .zero, size: Constants.iconSize))

    wantsLayer = true
    layer?.cornerCurve = .continuous
    layer?.cornerRadius = Constants.cornerRadius

    if style == .filled {
      renderFilledIcon()
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var isFlipped: Bool {
    false
  }

  override func draw(_ dirtyRect: CGRect) {
    super.draw(dirtyRect)

    if style == .outlined {
      renderOutlinedIcon()
    }
  }

  private func renderFilledIcon() {
    // Resolve the color because .black doesn't work well with NSMenuItem, even when the image is template
    let tintColor: NSColor = NSApp.effectiveAppearance.isDarkMode ? .white : .black
    layerBackgroundColor = tintColor

    let currentDay = self.currentDay
    let labelFont = NSFont.boldSystemFont(ofSize: Constants.fontSize)

    // Calculate the rendering width using an attributed string
    let textWidth = NSAttributedString(
      string: String(currentDay),
      attributes: [.font: labelFont]
    ).size().width

    // Create the path from text and make sure it's optically aligned
    let textPath = NSBezierPath.from(text: String(currentDay), font: labelFont, isFlipped: isFlipped)
    let transform = AffineTransform(
      translationByX: (bounds.width - textWidth) * 0.5,
      byY: (bounds.height - Constants.textHeight) * 0.5
    )

    textPath.transform(using: transform)
    textPath.append(NSBezierPath(rect: bounds))

    let shapeLayer = CAShapeLayer()
    shapeLayer.path = textPath.cgPath
    layer?.mask = shapeLayer
  }

  private func renderOutlinedIcon() {
    let radius = Constants.cornerRadius
    let border = NSBezierPath(roundedRect: bounds, xRadius: radius, yRadius: radius)
    border.lineWidth = Constants.borderWidth
    border.stroke()

    let attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: Constants.fontSize),
      .foregroundColor: NSColor.black,
    ]

    let label = String(currentDay)
    let size = label.size(withAttributes: attributes)
    let rect = CGRect(
      x: bounds.midX - size.width * 0.5,
      y: bounds.midY - size.height * 0.5,
      width: size.width,
      height: size.height
    )

    label.draw(in: rect, withAttributes: attributes)
  }
}

@MainActor
private enum JSEvaluator {
  // E.g., {{ 1 + 1 }}
  static let pattern = /\{\{(.*?)\}\}/

  static let context: JSContext? = {
    let setTimeout: @convention(block) (JSValue, Int) -> Void = { callback, delay in
      DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) {
        callback.call(withArguments: [])
      }
    }

    let reload: @convention(block) () -> Void = {
      NotificationCenter.default.post(name: .menuBarIconDidChange, object: nil)
    }

    let context = JSContext()
    context?.setObject(setTimeout, forKeyedSubscript: "setTimeout" as NSString)
    context?.setObject(reload, forKeyedSubscript: "reload" as NSString)
    return context
  }()

  /**
   Set lunar calendar variables on the JS context based on the current date.

   Variables: lunarDay, lunarMonth, lunarDate, solarTerm, lunarFestival, holiday, lunarLabel.
   */
  static func setVariables(on context: JSContext, date: Date = .now) {
    let lunarComponents = Calendar.lunar.dateComponents([.month, .day], from: date)
    let solarComponents = Calendar.solar.dateComponents([.year, .month, .day], from: date)

    let month = lunarComponents.month ?? 1
    let day = lunarComponents.day ?? 1
    let isLeap = Calendar.lunar.isLeapMonth(from: date)

    let solarMonthDay = solarComponents.fourDigitsMonthDay
    let lunarMonthDay = lunarComponents.fourDigitsMonthDay
    let year = solarComponents.year ?? 0

    // lunarDay: Chinese day name (e.g., 初十)
    let lunarDayValue = AppLocalizer.chineseDay(of: day - 1)
    context.setObject(lunarDayValue, forKeyedSubscript: "lunarDay" as NSString)

    // lunarMonth: Chinese month name (e.g., 正月), handles leap months
    let lunarMonthValue = AppLocalizer.chineseMonth(of: month - 1, isLeap: isLeap)
    context.setObject(lunarMonthValue, forKeyedSubscript: "lunarMonth" as NSString)

    // lunarDate: Combined month + day (e.g., 正月初一)
    let lunarDateValue = lunarMonthValue + lunarDayValue
    context.setObject(lunarDateValue, forKeyedSubscript: "lunarDate" as NSString)

    // solarTerm: Solar term name if today is one, otherwise empty string
    let solarTermValue: String = {
      if let index = LunarCalendar.default.info(of: year)?.solarTerms[solarMonthDay] {
        return AppLocalizer.solarTerm(of: index)
      }
      return ""
    }()
    context.setObject(solarTermValue, forKeyedSubscript: "solarTerm" as NSString)

    // lunarFestival: Lunar festival name if today is one, otherwise empty string
    let lunarFestivalValue: String = {
      // Chinese New Year's Eve: the last day of the lunar year, dynamically determined
      if let lastDay = Calendar.lunar.lastDayOfYear(from: date),
         Calendar.lunar.isDate(date, inSameDayAs: lastDay) {
        return Localized.Calendar.chineseNewYearsEve
      }
      return AppLocalizer.lunarFestival(of: lunarMonthDay) ?? ""
    }()
    context.setObject(lunarFestivalValue, forKeyedSubscript: "lunarFestival" as NSString)

    // holiday: "workday", "holiday", or empty string based on public holiday data
    let holidayValue: String = {
      switch HolidayManager.default.typeOf(year: year, monthDay: solarMonthDay) {
      case .workday:
        return Localized.Calendar.workdayLabel
      case .holiday:
        return Localized.Calendar.holidayLabel
      case .none:
        return ""
      }
    }()
    context.setObject(holidayValue, forKeyedSubscript: "holiday" as NSString)

    // lunarLabel: Smart composite matching the calendar grid priority chain
    let lunarLabelValue: String = {
      if !lunarFestivalValue.isEmpty {
        return lunarFestivalValue
      }
      if !solarTermValue.isEmpty {
        return solarTermValue
      }
      // Show month name on the 1st day of each lunar month
      if day == 1 {
        return lunarMonthValue
      }
      return lunarDayValue
    }()
    context.setObject(lunarLabelValue, forKeyedSubscript: "lunarLabel" as NSString)
  }

  /**
   Replace all {{expr}} instances with the evaluated result.
   */
  static func resolve(input: String) -> String {
    guard let context else {
      return input
    }

    // Refresh variables to reflect the current date
    setVariables(on: context)

    return input.replacing(pattern) {
      let expr = String($0.1)
      let result = context.evaluateScript(expr).toString()
      return result ?? expr
    }
  }
}
