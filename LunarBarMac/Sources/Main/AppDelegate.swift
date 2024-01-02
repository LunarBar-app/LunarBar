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
    item.button?.image = .with(symbolName: Icons.calendar, pointSize: 16)

    // Responds to mouseDown instead of mouseUp to mimic system items
    item.button?.sendAction(on: .leftMouseDown)
    item.button?.addAction { [weak self] in
      self?.openPanel()
    }

    return item
  }()

  func applicationDidFinishLaunching(_ notification: Notification) {
    // Prepare public holiday data
    _ = HolidayManager.default

    // Attach the status item to menu bar
    statusItem.isVisible = true

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
}

// MARK: - Private

private extension AppDelegate {
  @objc func windowDidResignKey(_ notification: Notification) {
    guard (notification.object as? NSWindow)?.contentViewController is AppMainVC else {
      return
    }

    statusItem.button?.highlight(false)
  }

  func openPanel() {
    // Prevent multiple popovers, e.g., when float on top is enabled
    guard NSApp.windows.allSatisfy({ !($0.contentViewController is AppMainVC) }) else {
      return Logger.log(.info, "Trying to present multiple popovers")
    }

    guard let sender = statusItem.button else {
      return Logger.assertFail("Missing source view to proceed")
    }

    let popover = AppMainVC.createPopover()
    popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
    popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)

    // Popover steals the highlighted state, highlight it in the next runloop to mimic the system
    RunLoop.main.perform {
      sender.highlight(true)
    }
  }
}
