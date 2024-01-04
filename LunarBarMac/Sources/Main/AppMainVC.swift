//
//  AppMainVC.swift
//  LunarBarMac
//
//  Created by cyan on 12/21/23.
//

import AppKit
import LunarBarKit

/**
 The main view controller that manages all components.
 */
final class AppMainVC: NSViewController {
  // States
  var floatOnTop = false
  var monthDate = Date.now
  weak var popover: NSPopover?

  // Views
  private let headerView = HeaderView()
  private let weekdayView = WeekdayView()
  private let dateGridView = DateGridView()

  // Factory function
  static func createPopover() -> NSPopover {
    let popover = NSPopover()
    popover.behavior = .transient
    popover.contentSize = Constants.contentSize
    popover.animates = !AppPreferences.Accessibility.reduceMotion

    let contentVC = Self()
    contentVC.popover = popover
    popover.contentViewController = contentVC

    return popover
  }
}

// MARK: - Internal

extension AppMainVC {
  override func loadView() {
    // Required prior to macOS Sonoma
    view = NSView(frame: CGRect(origin: .zero, size: Constants.contentSize))
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setUp()
    observeKeyEvents()
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    popover?.reduceTransparency = AppPreferences.Accessibility.reduceTransparency

    updateAppearance()
    updateCalendar()
  }

  // MARK: - Updating

  func updateAppearance(_ appearance: Appearance = AppPreferences.General.appearance) {
    view.window?.appearance = appearance.resolved()
    AppPreferences.General.appearance = appearance
  }

  func updateCalendar(targetDate: Date = .now) {
    Logger.log(.info, "Updating calendar to target date: \(targetDate)")
    monthDate = targetDate

    let solarYear = Calendar.solar.year(from: targetDate)
    let lunarInfo = LunarCalendar.default.info(of: solarYear)

    headerView.updateCalendar(date: targetDate)
    dateGridView.updateCalendar(date: targetDate, lunarInfo: lunarInfo)
  }

  func updateCalendar(moveMonthBy offset: Int) {
    guard let newDate = Calendar.solar.date(byAdding: .month, value: offset, to: monthDate) else {
      return Logger.assertFail("Failed to get date by adding the offset: \(offset)")
    }

    Logger.log(.info, "Moving the calendar by \(offset) month")
    updateCalendar(targetDate: newDate)
  }
}

// MARK: - HeaderViewDelegate

extension AppMainVC: HeaderViewDelegate {
  // periphery:ignore:parameters sender
  func headerView(_ sender: HeaderView, moveTo date: Date) {
    updateCalendar(targetDate: date)
  }

  // periphery:ignore:parameters sender
  func headerView(_ sender: HeaderView, moveBy offset: Int) {
    updateCalendar(moveMonthBy: offset)
  }

  // periphery:ignore:parameters sender
  func headerView(_ sender: HeaderView, showActionsMenu sourceView: NSView) {
    showActionsMenu(sourceView: sourceView)
  }
}

// MARK: - Private

private extension AppMainVC {
  enum Constants {
    static let contentSize = CGSize(width: 240, height: 320)
    static let headerViewHeight: Double = 40
    static let weekdayViewHeight: Double = 17
    static let dateGridViewMarginTop: Double = 10
  }

  func setUp() {
    headerView.delegate = self
    headerView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(headerView)
    NSLayoutConstraint.activate([
      headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      headerView.topAnchor.constraint(equalTo: view.topAnchor),
      headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      headerView.heightAnchor.constraint(equalToConstant: Constants.headerViewHeight),
    ])

    weekdayView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(weekdayView)
    NSLayoutConstraint.activate([
      weekdayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      weekdayView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
      weekdayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      weekdayView.heightAnchor.constraint(equalToConstant: Constants.weekdayViewHeight),
    ])

    dateGridView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(dateGridView)
    NSLayoutConstraint.activate([
      dateGridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      dateGridView.topAnchor.constraint(equalTo: weekdayView.bottomAnchor, constant: Constants.dateGridViewMarginTop),
      dateGridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      dateGridView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  func observeKeyEvents() {
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      guard let self else {
        return event
      }

      switch (event.keyCode, event.deviceIndependentFlags) {
      case (.kVK_ANSI_Q, .command):
        NSApp.terminate(nil)
        return nil
      case (.kVK_Space, _):
        self.updateCalendar()
        return nil
      case (.kVK_LeftArrow, _):
        self.updateCalendar(moveMonthBy: -1)
        return nil
      case (.kVK_RightArrow, _):
        self.updateCalendar(moveMonthBy: 1)
        return nil
      default:
        return event
      }
    }
  }
}
