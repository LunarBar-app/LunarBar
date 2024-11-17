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

  private var cellDate: Date?
  private var cellEvents = [EKCalendarItem]()
  private var mainInfo = ""

  private var detailsTask: Task<Void, Never>?
  private weak var detailsPopover: NSPopover?

  private let containerView: CustomButton = {
    let button = CustomButton()
    button.setAccessibilityElement(true)
    button.setAccessibilityRole(.button)
    button.setAccessibilityHelp(Localized.UI.accessibilityClickToRevealDate)

    return button
  }()

  private let highlightView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.alphaValue = 0

    view.layer?.cornerRadius = Constants.highlightViewCornerRadius
    view.layer?.cornerCurve = .continuous

    return view
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
    view.layer?.cornerRadius = Constants.highlightViewCornerRadius
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

    highlightView.layerBackgroundColor = Colors.systemGray.withAlphaComponent(0.15)
    focusRingView.layer?.borderColor = Colors.controlAccent.cgColor
  }
}

// MARK: - Updating

extension DateGridCell {
  func updateViews(
    cellDate: Date,
    cellEvents: [EKCalendarItem],
    monthDate: Date?,
    lunarInfo: LunarInfo?
  ) {
    self.cellDate = cellDate
    self.cellEvents = cellEvents

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

    // Reload event dot views
    eventView.updateEvents(cellEvents)

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

    self.mainInfo = {
      var components: [String] = []
      // E.g. [Holiday]
      if let holidayLabel = AppLocalizer.holidayLabel(of: holidayType) {
        components.append(holidayLabel)
      }

      // Formatted lunar date, e.g., 癸卯年冬月十五 (leading numbers are removed to be concise)
      let lunarDate = Constants.lunarDateFormatter.string(from: cellDate)
      components.append(lunarDate.removingLeadingDigits)

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

    let accessibleDetails = {
      let eventTitles = cellEvents.compactMap { $0.title }

      // Only the main info
      if eventTitles.isEmpty {
        return mainInfo
      }

      // Full version, each trailing line is an event title
      return [mainInfo, eventTitles.joined(separator: "\n")].joined(separator: "\n\n")
    }()

    // Combine all visually available information to get the accessibility label
    containerView.setAccessibilityLabel([
      solarLabel.stringValue,
      lunarLabel.stringValue,
      accessibleDetails,
    ].compactMap { $0 }.joined(separator: " "))
  }

  func updateOpacity(monthDate: Date?) {
    let currentDate = Date.now
    let cellDate = cellDate ?? currentDate

    let solarComponents = Calendar.solar.dateComponents([.month], from: cellDate)
    let isDateToday = Calendar.solar.isDate(cellDate, inSameDayAs: currentDate)

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
  }

  @discardableResult
  func cancelHighlight() -> Bool {
    highlightView.alphaValue = 0
    return dismissDetails()
  }
}

// MARK: - Private

private extension DateGridCell {
  enum Constants {
    static let solarFontSize: Double = FontSizes.regular
    static let lunarFontSize: Double = FontSizes.small
    static let eventViewHeight: Double = 10
    static let focusRingBorderWidth: Double = 2
    static let highlightViewCornerRadius: Double = 4
    static let holidayViewImage: NSImage = .with(symbolName: Icons.bookmarkFill, pointSize: 9)
    static let lunarDateFormatter: DateFormatter = .lunarDate
  }

  func setUp() {
    view.addSubview(containerView)
    containerView.addAction { [weak self] in
      self?.revealDateInCalendar()
    }

    containerView.onMouseHover = { [weak self] isHovered in
      self?.onMouseHover(isHovered)
    }

    highlightView.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(highlightView)

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
      highlightView.topAnchor.constraint(equalTo: containerView.topAnchor),
      highlightView.bottomAnchor.constraint(equalTo: eventView.bottomAnchor),
      highlightView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

      // Here we need to make sure the highlight view is wider than both labels
      highlightView.widthAnchor.constraint(
        greaterThanOrEqualTo: solarLabel.widthAnchor,
        constant: Constants.focusRingBorderWidth
      ),
      highlightView.widthAnchor.constraint(
        greaterThanOrEqualTo: lunarLabel.widthAnchor,
        constant: Constants.focusRingBorderWidth
      ),

      // The focus ring has the same frame as the highlight view
      focusRingView.leadingAnchor.constraint(equalTo: highlightView.leadingAnchor),
      focusRingView.trailingAnchor.constraint(equalTo: highlightView.trailingAnchor),
      focusRingView.topAnchor.constraint(equalTo: highlightView.topAnchor),
      focusRingView.bottomAnchor.constraint(equalTo: highlightView.bottomAnchor),
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

    // Clear states and open the Calendar app
    view.window?.orderOut(nil)
    dismissDetails()
    CalendarManager.default.revealDateInCalendar(cellDate)
  }

  func onMouseHover(_ isHovered: Bool) {
    highlightView.setAlphaValue(isHovered ? 1 : 0)
    dismissDetails()

    guard isHovered else {
      return
    }

    let showDetails = {
      try await Task.sleep(for: .seconds(0.8))
      let popover = DateDetailsView.createPopover(
        title: self.mainInfo,
        events: self.cellEvents
      )

      popover.show(
        relativeTo: self.containerView.bounds,
        of: self.containerView,
        preferredEdge: .maxY
      )

      self.detailsPopover = popover
    }

    detailsTask = Task {
      try? await showDetails()
    }
  }

  @discardableResult
  func dismissDetails() -> Bool {
    let wasOpen = detailsPopover?.isShown == true
    detailsPopover?.close()
    detailsPopover = nil

    detailsTask?.cancel()
    return wasOpen
  }
}
