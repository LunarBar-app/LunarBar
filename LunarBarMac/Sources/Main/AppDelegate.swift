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
  private var popoverClosedTime: TimeInterval = 0

  func applicationDidFinishLaunching(_ notification: Notification) {
    // Prepare public holiday data
    _ = HolidayManager.default

    // Update the icon and attach it to the menu bar
    updateMenuBarIcon()
    statusItem.isVisible = true

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
      await CalendarManager.default.requestAccessIfNeeded()

      // We don't even have a main window, open the panel for initial launch
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        guard AppPreferences.General.initialLaunch else {
          return
        }

        self.openPanel()
        AppPreferences.General.initialLaunch = false
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      Task {
        await AppUpdater.checkForUpdates(explicitly: false)
      }

      Task {
        await HolidayManager.default.fetchDefaultHolidays()
      }
    }

    // Check for updates on a weekly basis, for users who never quit apps
    Timer.scheduledTimer(withTimeInterval: 7 * 24 * 60 * 60, repeats: true) { _ in
      Task {
        await AppUpdater.checkForUpdates(explicitly: false)
      }
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(calendarDayDidChange(_:)),
      name: .NSCalendarDayChanged,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(windowDidResignKey(_:)),
      name: NSWindow.didResignKeyNotification,
      object: nil
    )
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    // These events are sent whenever the Finder reactivates an already running application because someone double-clicked it again or used the dock to activate it.
    openPanel()
    return false
  }

  func updateMenuBarIcon() {
    switch AppPreferences.General.menuBarIcon {
    case .calendar:
      statusItem.button?.image = AppIconFactory.createCalendarIcon()
    case .date:
      statusItem.button?.image = AppIconFactory.createDateIcon()
    }
  }
}

// MARK: - NSPopoverDelegate

extension AppDelegate: NSPopoverDelegate {
  func popoverWillClose(_ notification: Notification) {
    popoverClosedTime = Date.timeIntervalSinceReferenceDate
  }
}

// MARK: - Private

private extension AppDelegate {
  // periphery:ignore:parameters notification
  @objc func calendarDayDidChange(_ notification: Notification) {
    DispatchQueue.main.async {
      self.updateMenuBarIcon()
    }

    // The user may have taken a time machine by changing the time zone
    popoverClosedTime = 0
  }

  @objc func windowDidResignKey(_ notification: Notification) {
    guard (notification.object as? NSWindow)?.contentViewController is AppMainVC else {
      return
    }

    // Cancel the highlight when the popover window is no longer the key window
    statusItem.button?.highlight(false)
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

    guard Date.timeIntervalSinceReferenceDate - popoverClosedTime > 0.1 else {
      // The click was to close the popover
      return false
    }

    // Prevent multiple popovers, e.g., when float on top is enabled
    if let popover = presentedPopover, popover.isShown {
      // Just think of it as a "float on top" cancellation
      popover.behavior = .transient
      popover.close()
      return false
    }

    return true
  }

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
  }
}
