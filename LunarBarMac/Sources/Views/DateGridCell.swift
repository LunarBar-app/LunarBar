//
//  DateGridCell.swift
//  LunarBarMac
//
//  Created by cyan on 12/22/23.
//

import AppKit
import AppKitControls
import EventKit
import LunarBarKit

/**
 Grid cell that draws a day, including its solar date and lunar date and decorating views.

 Example: 22 初十
 */
final class DateGridCell: NSCollectionViewItem {
  static let reuseIdentifier = NSUserInterfaceItemIdentifier("DateGridCell")

  // The current represented object, mainly used to reveal the date later
  private var cellDate: Date?

  private let containerView: CustomButton = {
    let button = CustomButton()
    button.setAccessibilityElement(true)
    button.setAccessibilityRole(.button)
    button.setAccessibilityHelp(Localized.UI.accessibilityClickToRevealDate)

    return button
  }()

  private let solarLabel: TextLabel = {
    let label = TextLabel()
    label.textColor = Colors.primaryLabel
    label.font = .mediumSystemFont(ofSize: Constants.solarFontSize)
    label.setAccessibilityHidden(true)

    return label
  }()

  private let lunarLabel: TextLabel = {
    let label = TextLabel()
    label.textColor = Colors.primaryLabel
    label.font = .mediumSystemFont(ofSize: Constants.lunarFontSize)
    label.setAccessibilityHidden(true)

    return label
  }()

  private let eventView: EventView = {
    let view = EventView()
    view.setAccessibilityHidden(true)

    return view
  }()

  private let focusRingView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.isHidden = true
    view.setAccessibilityHidden(true)

    view.layer?.borderWidth = Constants.focusRingBorderWidth
    view.layer?.cornerRadius = Constants.focusRingCornerRadius
    view.layer?.cornerCurve = .continuous

    return view
  }()

  private let holidayView: NSImageView = {
    let view = NSImageView(image: Constants.holidayViewImage)
    view.isHidden = true
    view.setAccessibilityHidden(true)

    return view
  }()
}

// MARK: - Life Cycle

extension DateGridCell {
  override func loadView() {
    // Required prior to macOS Sonoma
    view = NSView(frame: .zero)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setUp()
  }

  override func viewDidLayout() {
    super.viewDidLayout()
    containerView.frame = view.bounds
    focusRingView.layer?.borderColor = Colors.controlAccent.cgColor
  }
}

// MARK: - Updating

extension DateGridCell {
  func update(cellDate: Date, monthDate: Date?, monthEvents: [EKEvent]?, lunarInfo: LunarInfo?) {
    self.cellDate = cellDate

    let currentDate = Date.now
    let solarComponents = Calendar.solar.dateComponents([.year, .month, .day], from: cellDate)
    let lunarComponents = Calendar.lunar.dateComponents([.year, .month, .day], from: cellDate)
    let lastDayOfLunarYear = Calendar.lunar.lastDayOfYear(from: cellDate)
    let isLeapLunarMonth = Calendar.lunar.isLeapMonth(from: cellDate)

    let solarMonthDay = solarComponents.fourDigitsMonthDay
    let lunarMonthDay = lunarComponents.fourDigitsMonthDay

    let holidayType = HolidayManager.default.typeOf(
      year: solarComponents.year ?? 0, // It's too broken to have year as nil
      monthDay: solarMonthDay
    )

    // Solar day label
    if let day = solarComponents.day {
      solarLabel.stringValue = String(day)
    } else {
      Logger.assertFail("Failed to get solar day from date: \(cellDate)")
    }

    // Lunar day label
    if let day = lunarComponents.day {
      if day == 1, let month = lunarComponents.month {
        // The Chinese character "月" will shift the layout slightly to the left,
        // add a "thin space" to make it optically centered.
        lunarLabel.stringValue = "\u{2009}" + AppLocalizer.chineseMonth(of: month - 1, isLeap: isLeapLunarMonth)
      } else {
        lunarLabel.stringValue = AppLocalizer.chineseDay(of: day - 1)
      }
    } else {
      Logger.assertFail("Failed to get lunar day from date: \(cellDate)")
    }

    // Prefer solar term over normal lunar day
    if let solarTerm = lunarInfo?.solarTerms[solarMonthDay] {
      lunarLabel.stringValue = AppLocalizer.solarTerm(of: solarTerm)
    }

    // Prefer lunar holiday over solar term
    if let lunarHoliday = AppLocalizer.lunarFestival(of: lunarMonthDay) {
      lunarLabel.stringValue = lunarHoliday
    }

    // Chinese New Year's Eve, the last day of the lunar year, not necessarily a certain date
    if let lastDayOfLunarYear, Calendar.lunar.isDate(cellDate, inSameDayAs: lastDayOfLunarYear) {
      lunarLabel.stringValue = Localized.Calendar.chineseNewYearsEve
    }

    // Show the focus ring only for today
    let isDateToday = Calendar.solar.isDate(cellDate, inSameDayAs: currentDate)
    focusRingView.isHidden = !isDateToday

    // Dim dates and decorating views
    if let monthDate, Calendar.solar.month(from: monthDate) == solarComponents.month {
      if Calendar.solar.isDateInWeekend(cellDate) && !isDateToday {
        solarLabel.alphaValue = AlphaLevels.secondary
      } else {
        solarLabel.alphaValue = AlphaLevels.primary
      }

      // Intentional, secondary alpha is used only for labels at weekends
      eventView.alphaValue = AlphaLevels.primary
    } else {
      solarLabel.alphaValue = AlphaLevels.tertiary
      eventView.alphaValue = AlphaLevels.tertiary
    }

    lunarLabel.alphaValue = solarLabel.alphaValue
    holidayView.alphaValue = eventView.alphaValue

    // Filter out events that is in the cellDate, we batch query because of performance concerns
    eventView.updateEvents(monthEvents?.filter {
      $0.overlaps(
        startOfDay: Calendar.solar.startOfDay(for: cellDate),
        endOfDay: Calendar.solar.endOfDay(for: cellDate)
      )
    } ?? [])

    // Bookmark for holiday plans
    switch holidayType {
    case .none:
      holidayView.isHidden = true
      holidayView.contentTintColor = nil
    case .workday:
      holidayView.isHidden = false
      holidayView.contentTintColor = Colors.systemOrange
    case .holiday:
      holidayView.isHidden = false
      holidayView.contentTintColor = Colors.systemTeal
    }

    // More info, set it as the tooltip
    containerView.toolTip = {
      var components: [String] = []
      // E.g. [Holiday]
      if let holidayLabel = AppLocalizer.holidayLabel(of: holidayType) {
        components.append(holidayLabel)
      }

      // Formatted lunar date, e.g., 癸卯年冬月十五 (leading numbers are removed to be concise)
      let lunarDate = Constants.lunarDateFormatter.string(from: cellDate)
      components.append(lunarDate.replacing(/^(\d+)/, with: ""))

      // Date ruler, e.g., "(10 days ago)" when hovering over a cell
      if let daysBetween = Calendar.solar.daysBetween(from: currentDate, to: cellDate) {
        if daysBetween == 0 {
          components.append(Localized.Calendar.todayLabel)
        } else {
          let format = daysBetween > 0 ? Localized.Calendar.daysLaterFormat : Localized.Calendar.daysAgoFormat
          components.append(String.localizedStringWithFormat(format, abs(daysBetween)))
        }
      }

      return components.joined()
    }()

    // Combine all visually available information to get the accessibility label
    containerView.setAccessibilityLabel([
      solarLabel.stringValue,
      lunarLabel.stringValue,
      containerView.toolTip,
      eventView.isHidden ? nil : Localized.UI.accessibilityHasCalendarEvents,
    ].compactMap { $0 }.joined(separator: " "))
  }
}

// MARK: - Private

private extension DateGridCell {
  enum Constants {
    static let solarFontSize: Double = FontSizes.regular
    static let lunarFontSize: Double = FontSizes.small
    static let eventViewHeight: Double = 10
    static let focusRingBorderWidth: Double = 2
    static let focusRingCornerRadius: Double = 4
    static let holidayViewImage: NSImage = .with(symbolName: Icons.bookmarkFill, pointSize: 9)

    static let lunarDateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.calendar = Calendar.lunar
      formatter.dateStyle = .long
      formatter.timeStyle = .none

      // Always use Chinese for lunar dates,
      // the English version of the Heavenly Stems and Earthly Branches is strange
      if Locale.autoupdatingCurrent.language.languageCode == "en" {
        formatter.locale = Locale(identifier: "zh-Hans")
      }

      return formatter
    }()
  }

  func setUp() {
    view.addSubview(containerView)
    containerView.addAction { [weak self] in
      self?.revealDateInCalendar()
    }

    solarLabel.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(solarLabel)
    NSLayoutConstraint.activate([
      solarLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      solarLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
    ])

    lunarLabel.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(lunarLabel)
    NSLayoutConstraint.activate([
      lunarLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      lunarLabel.topAnchor.constraint(equalTo: solarLabel.bottomAnchor),
    ])

    eventView.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(eventView)
    NSLayoutConstraint.activate([
      eventView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      eventView.topAnchor.constraint(equalTo: lunarLabel.bottomAnchor),
      eventView.heightAnchor.constraint(equalToConstant: Constants.eventViewHeight),
    ])

    focusRingView.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(focusRingView)
    NSLayoutConstraint.activate([
      focusRingView.topAnchor.constraint(equalTo: containerView.topAnchor),
      focusRingView.bottomAnchor.constraint(equalTo: eventView.bottomAnchor),
      focusRingView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

      // Here we need to make sure the focus ring is wider than both labels
      focusRingView.widthAnchor.constraint(
        greaterThanOrEqualTo: solarLabel.widthAnchor,
        constant: Constants.focusRingBorderWidth
      ),
      focusRingView.widthAnchor.constraint(
        greaterThanOrEqualTo: lunarLabel.widthAnchor,
        constant: Constants.focusRingBorderWidth
      ),
    ])

    holidayView.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(holidayView)
    NSLayoutConstraint.activate([
      holidayView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: -3.5),
      holidayView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -1.5),
      holidayView.widthAnchor.constraint(equalToConstant: holidayView.frame.width),
      holidayView.heightAnchor.constraint(equalToConstant: holidayView.frame.height),
    ])
  }

  func revealDateInCalendar() {
    guard let cellDate else {
      return Logger.assertFail("Missing cellDate to continue")
    }

    // Order out the window because activating another app doesn't dismiss the popover
    view.window?.orderOut(nil)
    CalendarManager.default.revealDateInCalendar(cellDate)
  }
}
