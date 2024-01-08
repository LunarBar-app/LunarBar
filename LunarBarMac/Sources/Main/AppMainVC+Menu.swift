//
//  AppMainVC+Menu.swift
//  LunarBarMac
//
//  Created by cyan on 12/28/23.
//

import AppKit
import LunarBarKit
import ServiceManagement

extension AppMainVC {
  func showActionsMenu(sourceView: NSView) {
    let menu = NSMenu()
    menu.addItem(menuItemGotoToday)
    menu.addItem(menuItemDatePicker)

    menu.addSeparator()

    menu.addItem(menuItemAppearance)
    menu.addItem(menuItemCalendars)
    menu.addItem(menuItemPublicHolidays)
    menu.addItem(menuItemLaunchAtLogin)

    menu.addSeparator()

    menu.addItem(menuItemAboutLunarBar)
    menu.addItem(menuItemGitHub)
    menu.addItem(menuItemCheckForUpdates)

    menu.addSeparator()

    menu.addItem(menuItemQuitLunarBar)

    Logger.log(.info, "Presenting the actions menu")
    menu.popUp(positioning: nil, at: CGPoint(x: 0, y: sourceView.frame.maxY), in: sourceView)
  }
}

// MARK: - Private

private extension AppMainVC {
  var menuItemGotoToday: NSMenuItem {
    let item = NSMenuItem(title: Localized.UI.menuTitleGotoToday, action: nil, keyEquivalent: " ")
    item.keyEquivalentModifierMask = []
    item.addAction { [weak self] in
      self?.updateCalendar()
    }

    return item
  }

  var menuItemDatePicker: NSMenuItem {
    let menu = NSMenu()
    let current = Calendar.solar.year(from: monthDate)

    // Generate 20 years before and after the current year
    for year in (current - 10)...(current + 10) {
      let item = menu.addItem(withTitle: String(year))
      item.submenu = NSMenu()

      // Insert each month as a submenu
      for (month, title) in Calendar.solar.monthSymbols.enumerated() {
        item.submenu?.addItem(withTitle: title) {
          guard let date = DateComponents(
            calendar: Calendar.solar,
            year: year,
            month: month + 1 // Index is zero-based but month number is human friendly
          ).date else {
            return Logger.assertFail("Failed to generate date for: \(year), \(month)")
          }

          self.updateCalendar(targetDate: date)
        }
      }
    }

    let item = NSMenuItem(title: Localized.UI.menuTitleGotoDate)
    item.submenu = menu
    return item
  }

  var menuItemAppearance: NSMenuItem {
    let menu = NSMenu()
    let current = AppPreferences.General.appearance

    // Dark mode preference

    menu.addItem(withTitle: Localized.UI.menuTitleSystem) { [weak self] in
      self?.updateAppearance(.system)
    }
    .setOn(current == .system)

    menu.addItem(withTitle: Localized.UI.menuTitleLight) { [weak self] in
      self?.updateAppearance(.light)
    }
    .setOn(current == .light)

    menu.addItem(withTitle: Localized.UI.menuTitleDark) { [weak self] in
      self?.updateAppearance(.dark)
    }
    .setOn(current == .dark)

    menu.addSeparator()

    // Accessibility options

    menu.addItem(withTitle: Localized.UI.menuTitleReduceMotion) { [weak self] in
      AppPreferences.Accessibility.reduceMotion.toggle()
      self?.popover?.animates = !AppPreferences.Accessibility.reduceMotion
    }
    .setOn(AppPreferences.Accessibility.reduceMotion)

    menu.addItem(withTitle: Localized.UI.menuTitleReduceTransparency) { [weak self] in
      AppPreferences.Accessibility.reduceTransparency.toggle()
      self?.popover?.reduceTransparency = AppPreferences.Accessibility.reduceTransparency
    }
    .setOn(AppPreferences.Accessibility.reduceTransparency)

    menu.addSeparator()

    menu.addItem(withTitle: Localized.UI.menuTitleFloatOnTop) { [weak self] in
      self?.floatOnTop.toggle()
      self?.popover?.behavior = self?.floatOnTop == true ? .applicationDefined : .transient
    }
    .setOn(floatOnTop)

    let item = NSMenuItem(title: Localized.UI.menuTitleAppearance)
    item.submenu = menu
    return item
  }

  var menuItemCalendars: NSMenuItem {
    let menu = NSMenu()
    let calendars = CalendarManager.default.allCalendars()

    calendars.forEach {
      let calendarID = $0.calendarIdentifier
      let item = NSMenuItem(title: $0.title)
      item.setOn(!AppPreferences.Calendar.hiddenCalendars.contains(calendarID))

      item.addAction { [weak self] in
        AppPreferences.Calendar.hiddenCalendars.toggle(calendarID)
        self?.reloadCalendar()
      }

      if let color = $0.color {
        item.image = .with(
          cellColor: $0.color,
          borderColor: Colors.darkGray,
          size: CGSize(width: 12, height: 12),
          cornerRadius: 2
        )
      }

      menu.addItem(item)
    }

    let item = NSMenuItem(title: Localized.UI.menuTitleCalendars)
    item.isHidden = calendars.isEmpty
    item.submenu = menu
    return item
  }

  var menuItemPublicHolidays: NSMenuItem {
    let menu = NSMenu()
    menu.addItem(withTitle: Localized.UI.menuTitleDefaultHolidays) { [weak self] in
      AppPreferences.Calendar.defaultHolidays.toggle()
      self?.reloadCalendar()
    }
    .setOn(AppPreferences.Calendar.defaultHolidays)

    menu.addItem(withTitle: Localized.UI.menuTitleFetchUpdates) { [weak self] in
      Task {
        await HolidayManager.default.fetchDefaultHolidays()
        self?.reloadCalendar()
      }
    }

    menu.addSeparator()

    // User defined, read-only here
    HolidayManager.default.userDefinedFiles.forEach {
      let item = NSMenuItem(title: $0)
      item.isEnabled = false
      item.setOn(true)
      menu.addItem(item)
    }

    menu.addSeparator()

    menu.addItem(withTitle: Localized.UI.menuTitleOpenDirectory) {
      HolidayManager.default.openUserDefinedDirectory()
    }

    menu.addItem(withTitle: Localized.UI.menuTitleCustomizationTips) {
      NSWorkspace.shared.safelyOpenURL(string: "https://github.com/LunarBar-app/Holidays")
    }

    menu.addSeparator()

    menu.addItem(withTitle: Localized.UI.menuTitleReloadCustomizations) { [weak self] in
      HolidayManager.default.reloadUserDefinedFiles()
      self?.reloadCalendar()
    }

    let item = NSMenuItem(title: Localized.UI.menuTitlePublicHolidays)
    item.submenu = menu
    return item
  }

  var menuItemLaunchAtLogin: NSMenuItem {
    let item = NSMenuItem(title: Localized.UI.menuTitleLaunchAtLogin)
    item.setOn(SMAppService.mainApp.isEnabled)

    item.addAction {
      do {
        try SMAppService.mainApp.toggle()
      } catch {
        Logger.log(.error, error.localizedDescription)
      }
    }

    return item
  }

  var menuItemAboutLunarBar: NSMenuItem {
    let item = NSMenuItem(title: Localized.UI.menuTitleAboutLunarBar)
    item.addAction {
      NSApp.orderFrontStandardAboutPanel()
    }

    return item
  }

  var menuItemGitHub: NSMenuItem {
    let item = NSMenuItem(title: Localized.UI.menuTitleGitHub)
    item.addAction {
      NSWorkspace.shared.safelyOpenURL(string: "https://github.com/LunarBar-app/LunarBar")
    }

    return item
  }

  var menuItemCheckForUpdates: NSMenuItem {
    let item = NSMenuItem(title: Localized.UI.menuTitleCheckForUpdates)
    item.addAction {
      Task {
        await AppUpdater.checkForUpdates(explicitly: true)
      }
    }

    return item
  }

  var menuItemQuitLunarBar: NSMenuItem {
    let item = NSMenuItem(title: Localized.UI.menuTitleQuitLunarBar, action: nil, keyEquivalent: "q")
    item.keyEquivalentModifierMask = [.command]
    item.addAction {
      NSApp.terminate(nil)
    }

    return item
  }

  func reloadCalendar() {
    updateCalendar(targetDate: monthDate)
  }
}
