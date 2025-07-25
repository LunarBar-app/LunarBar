//
//  AppDelegate.swift
//  LunarBarMac
//
//  Created by cyan on 12/21/23.
//

import AppKit
import LunarBarKit

class AppDelegate: NSObject, NSApplicationDelegate {
  private lazy var statusItem: NSStatusItem = {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    item.autosaveName = Bundle.main.bundleName
    item.behavior = .terminationOnRemoval

    return item
  }()

  private weak var presentedPopover: NSPopover?
  private var dateRefreshTimer: DateRefreshTimer?
  private var popoverClosedTime: TimeInterval = 0

  func applicationDidFinishLaunching(_ notification: Notification) {
    // We rely on tooltips to display information, change the initial delay to 1s to be faster
    UserDefaults.standard.setValue(1000, forKey: "NSInitialToolTipDelay")

    // Prepare public holiday data
    _ = HolidayManager.default

    // Update the icon and attach it to the menu bar
    updateMenuBarIcon()
    statusItem.isVisible = true

    // Repeated refresh based on the date format granularity
    dateRefreshTimer = DateRefreshTimer { [weak self] in self?.updateMenuBarIcon() }
    updateDateRefreshTimer()

    // Observe events that do not require a specific window
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
      if event.keyCode == .kVK_ANSI_Q && event.deviceIndependentFlags == .command {
        NSApp.terminate(nil)
        return nil
      }

      if event.keyCode == .kVK_ANSI_W && event.deviceIndependentFlags == .command {
        event.window?.close()
        return nil
      }

      return event
    }

    // We don't rely on the button's target-action,
    // because we want to keep the button highlighted when the popover is shown.
    NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
      if let self, self.shouldOpenPanel(for: event) {
        self.openPanel()
        return nil
      }

      return event
    }

    // Observe clicks outside the app
    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
      guard let popover = self?.presentedPopover else {
        return
      }

      // When the app is activated, clicking on other status items would not always close ours
      if popover.isShown && popover.behavior != .applicationDefined {
        popover.close()
      }
    }

    Task {
      await CalendarManager.default.requestAccessIfNeeded(type: .event)
      await CalendarManager.default.preload(date: .now)

      // We don't even have a main window, open the panel for initial launch
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        guard AppPreferences.General.initialLaunch else {
          return
        }

        self.openPanel()
        AppPreferences.General.initialLaunch = false
      }
    }

    let silentlyCheckUpdates: @Sendable () -> Void = {
      Task {
        await AppUpdater.checkForUpdates(explicitly: false)
      }

      Task {
        await HolidayManager.default.fetchDefaultHolidays()
      }
    }

    // Check for updates on launch with a delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: silentlyCheckUpdates)

    // Check for updates on a weekly basis, for users who never quit apps
    Timer.scheduledTimer(withTimeInterval: 7 * 24 * 60 * 60, repeats: true) { _ in
      silentlyCheckUpdates()
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(calendarDayDidChange(_:)),
      name: .NSCalendarDayChanged,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(windowDidUpdate(_:)),
      name: NSWindow.didUpdateNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(windowDidResignKey(_:)),
      name: NSWindow.didResignKeyNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(menuBarIconDidChange(_:)),
      name: .menuBarIconDidChange,
      object: nil
    )
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    // These events are sent whenever the Finder reactivates an already running application because someone double-clicked it again or used the dock to activate it.
    openPanel()
    return false
  }

  @MainActor
  func updateMenuBarIcon(needsLayout: Bool = false) {
    switch AppPreferences.General.menuBarIcon {
    case .calendar:
      statusItem.button?.image = AppIconFactory.createCalendarIcon()
    case .filledDate:
      statusItem.button?.image = AppIconFactory.createDateIcon(style: .filled)
    case .outlinedDate:
      statusItem.button?.image = AppIconFactory.createDateIcon(style: .outlined)
    case .custom:
      statusItem.button?.image = AppIconFactory.createCustomIcon()
    }

    let accessibilityLabel = AppPreferences.General.menuBarIcon == .custom ? customDateText() : "LunarBar"
    statusItem.button?.setAccessibilityLabel(accessibilityLabel)

    // The popover position will be slightly moved without this trick
    if needsLayout {
      presentedPopover?.close()
      statusItem.button?.superview?.needsLayout = true
    }

    updateTooltip()
  }

  @MainActor
  func updateDateRefreshTimer() {
    if AppPreferences.General.menuBarIcon == .custom {
      dateRefreshTimer?.dateFormat = AppPreferences.General.customDateFormat
    } else {
      dateRefreshTimer?.dateFormat = nil
    }
  }

  @MainActor
  func updateTooltip() {
    let currentDate = Date.now
    statusItem.button?.toolTip = [
      DateFormatter.fullDate.string(from: currentDate),
      DateFormatter.lunarDate.string(from: currentDate).removingLeadingDigits,
    ].joined(separator: "\n\n")
  }

  @MainActor
  func openPanel() {
    guard let sender = statusItem.button else {
      return Logger.assertFail("Missing source view to proceed")
    }

    let popover = AppMainVC.createPopover()
    popover.delegate = self
    popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
    presentedPopover = popover

    // Ensure the app is activated and the window is key and ordered front
    NSApp.activate(ignoringOtherApps: true)
    popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)

    // Keep the button highlighted to mimic the system behavior
    sender.highlight(true)

    // Clear the tooltip to prevent overlap
    sender.toolTip = nil
  }
}

// MARK: - NSPopoverDelegate

extension AppDelegate: NSPopoverDelegate {
  func popoverWillClose(_ notification: Notification) {
    popoverClosedTime = Date.timeIntervalSinceReferenceDate
  }
}

// MARK: - Private

@MainActor
private extension AppDelegate {
  // periphery:ignore:parameters notification
  @objc func calendarDayDidChange(_ notification: Notification) {
    DispatchQueue.main.async {
      self.updateMenuBarIcon()
    }
  }

  // periphery:ignore:parameters notification
  @objc func windowDidUpdate(_ notification: Notification) {
    guard let window = notification.object as? NSWindow, window.className == "NSToolTipPanel" else {
      return
    }

    guard presentedPopover == nil else {
      return
    }

    // Tooltip from the status bar sometimes has incorrect appearance
    window.appearance = NSApp.effectiveAppearance
  }

  // periphery:ignore:parameters notification
  @objc func windowDidResignKey(_ notification: Notification) {
    guard (notification.object as? NSWindow)?.contentViewController is AppMainVC else {
      return
    }

    // Cancel the highlight when the popover window is no longer the key window
    statusItem.button?.highlight(false)
    updateTooltip()
  }

  // periphery:ignore:parameters notification
  @objc func menuBarIconDidChange(_ notification: Notification) {
    updateMenuBarIcon()
  }

  func shouldOpenPanel(for event: NSEvent) -> Bool {
    guard event.window == statusItem.button?.window else {
      // The click was outside the status window
      return false
    }

    guard !event.modifierFlags.contains(.command) else {
      // Holding the command key usually means the icon is being dragged
      return false
    }

    // Measure the absolute value, taking system clock or time zone changes into account
    guard abs(Date.timeIntervalSinceReferenceDate - popoverClosedTime) > 0.1 else {
      // The click was to close the popover
      return false
    }

    // Prevent multiple popovers, e.g., when pin on top is enabled
    if let popover = presentedPopover, popover.isShown {
      // Just think of it as a "pin on top" cancellation
      popover.behavior = .transient
      popover.close()
      return false
    }

    return true
  }
}
