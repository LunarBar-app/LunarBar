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
  private let scalableView = ScalableView()
  private let headerView = HeaderView()
  private let weekdayView = WeekdayView()
  private let dateGridView = DateGridView()

  // Factory function
  static func createPopover() -> NSPopover {
    let popover = NSPopover()
    popover.behavior = .transient
    popover.contentSize = desiredContentSize
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
    view = NSView(frame: CGRect(origin: .zero, size: Self.desiredContentSize))
    view.addScalableView(scalableView, scale: AppPreferences.General.contentScale.rawValue)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setUp()
    observeKeyEvents()
  }

  override func viewWillAppear() {
    super.viewWillAppear()
    material = AppPreferences.Accessibility.popoverMaterial

    updateAppearance()
    updateCalendar()
  }

  // MARK: - Updating

  func updateAppearance(_ appearance: Appearance = AppPreferences.General.appearance) {
    AppPreferences.General.appearance = appearance

    // Override both since in some contexts we don't have a window
    NSApp.appearance = appearance.resolved()
    view.window?.appearance = NSApp.appearance
  }

  func updateCalendar(targetDate: Date = .now) {
    Logger.log(.info, "Updating calendar to target date: \(targetDate)")
    monthDate = targetDate

    let solarYear = Calendar.solar.year(from: targetDate)
    let lunarInfo = LunarCalendar.default.info(of: solarYear)

    headerView.updateCalendar(date: targetDate)
    dateGridView.updateCalendar(date: targetDate, lunarInfo: lunarInfo)
  }

  func updateCalendar(moveBy offset: Int, unit: Calendar.Component) {
    guard let newDate = Calendar.solar.date(byAdding: unit, value: offset, to: monthDate) else {
      return Logger.assertFail("Failed to get date by adding \(offset) \(unit)")
    }

    Logger.log(.info, "Moving the calendar by \(offset) \(unit)")
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
    updateCalendar(moveBy: offset, unit: .month)
  }

  // periphery:ignore:parameters sender
  func headerView(_ sender: HeaderView, showActionsMenu sourceView: NSView) {
    showActionsMenu(sourceView: sourceView)
  }
}

// MARK: - Private

private extension AppMainVC {
  enum Constants {
    static let headerViewHeight: Double = 40
    static let weekdayViewHeight: Double = 17
    static let dateGridViewMarginTop: Double = 10
  }

  @MainActor static var desiredContentSize: CGSize {
    CGSize(
      width: 240 * AppPreferences.General.contentScale.rawValue,
      height: 320 * AppPreferences.General.contentScale.rawValue
    )
  }

  func setUp() {
    let view = scalableView.container
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
      guard let self, self.view.window?.isKeyWindow == true else {
        return event
      }

      switch event.keyCode {
      case .kVK_Space:
        // Space key is occupied by keyboard navigation
        if NSApp.isFullKeyboardAccessEnabled {
          return event
        }

        self.updateCalendar()
        self.headerView.showClickEffect(for: .actions)
        return nil
      case .kVK_Escape:
        if self.dateGridView.cancelHighlight() {
          return nil
        }

        return event
      case .kVK_LeftArrow:
        self.updateCalendar(moveBy: -1, unit: .month)
        self.headerView.showClickEffect(for: .previous)
        return nil
      case .kVK_RightArrow:
        self.updateCalendar(moveBy: 1, unit: .month)
        self.headerView.showClickEffect(for: .next)
        return nil
      case .kVK_UpArrow:
        self.updateCalendar(moveBy: -1, unit: .year)
        return nil
      case .kVK_DownArrow:
        self.updateCalendar(moveBy: 1, unit: .year)
        return nil
      default:
        return event
      }
    }
  }
}
