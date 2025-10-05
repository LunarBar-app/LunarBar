//
//  AppMainVC+Menu.swift
//  LunarBarMac
//
//  Created by cyan on 12/28/23.
//

import AppKit
import AppKitControls
import AppKitExtensions
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

    menu.addItem(menuItemOpenDateTime)

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
  enum Constants {
    @MainActor static let menuIconSize: Double = AppDesign.menuIconSize
  }

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

    // Quick picker that supports 12 years around the current year
    for year in (current - 6)...(current + 6) {
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

    menu.addSeparator()

    // Full-fledged picker that supports any year
    menu.addItem({ [weak self] in
      let picker = NSDatePicker()
      if #available(macOS 26.0, *) {
        picker.prefersCompactControlSizeMetrics = true
      }

      picker.locale = Locale(identifier: Localized.General.locale)
      picker.isBezeled = false
      picker.isBordered = false
      picker.datePickerStyle = .textFieldAndStepper
      picker.datePickerElements = .yearMonth
      picker.translatesAutoresizingMaskIntoConstraints = false
      picker.dateValue = self?.monthDate ?? .now
      picker.sizeToFit()

      picker.addAction { [weak picker] in
        guard let date = picker?.dateValue else {
          return
        }

        self?.updateCalendar(targetDate: date)
      }

      let wrapper = NSView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: picker.frame.height)))
      wrapper.autoresizingMask = .width
      wrapper.addSubview(picker)

      NSLayoutConstraint.activate([
        picker.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
        picker.centerYAnchor.constraint(equalTo: wrapper.centerYAnchor),
      ])

      // Inside a submenu to avoid keyboard navigation conflicts
      let menu = NSMenu()
      menu.addItem({
        let item = NSMenuItem()
        item.view = wrapper

        return item
      }())

      let item = NSMenuItem(title: Localized.UI.menuTitleEnterMonth)
      item.submenu = menu
      return item
    }())

    let item = NSMenuItem(title: Localized.UI.menuTitleGotoMonth)
    item.submenu = menu
    return item
  }

  var menuItemAppearance: NSMenuItem {
    let menu = NSMenu()

    // Option to use the "legacy" design
    if #available(macOS 26.0, *) {
      menu.addItem({
        let item = NSMenuItem(title: Localized.UI.menuTitleClassicInterface)
        item.image = .with(symbolName: Icons.mustacheFill, pointSize: Constants.menuIconSize)
        item.setOn(AppPreferences.General.classicInterface)

        item.addAction {
          AppPreferences.General.classicInterface.toggle()
        }

        return item
      }())

      menu.addSeparator()
    }

    // Icon styles
    menu.addItem({
      let item = NSMenuItem(title: Localized.UI.menuTitleMenuBarIcon)
      item.isEnabled = false

      if #available(macOS 26.0, *) {
        // To improve the text alignment
        item.image = .with(symbolName: Icons.menubarRectangle, pointSize: Constants.menuIconSize)
      }

      return item
    }())

    menu.addItem(createDateIconItem(
      style: .filled,
      title: Localized.UI.menuTitleFilledDate,
      isOn: AppPreferences.General.menuBarIcon == .filledDate,
      action: AppPreferences.General.menuBarIcon = .filledDate,
    ))

    menu.addItem(createDateIconItem(
      style: .outlined,
      title: Localized.UI.menuTitleOutlinedDate,
      isOn: AppPreferences.General.menuBarIcon == .outlinedDate,
      action: AppPreferences.General.menuBarIcon = .outlinedDate,
    ))

    menu.addItem({
      let item = NSMenuItem(title: Localized.UI.menuTitleCalendarIcon)
      item.image = AppIconFactory.createCalendarIcon(pointSize: Constants.menuIconSize)
      item.setOn(AppPreferences.General.menuBarIcon == .calendar)

      item.addAction {
        AppPreferences.General.menuBarIcon = .calendar
      }

      return item
    }())

    menu.addItem(createCustomIconItem(
      item: {
        let item = NSMenuItem(title: Localized.UI.menuTitleSystemSymbol)
        item.image = .with(symbolName: Icons.gear, pointSize: Constants.menuIconSize)
        item.setOn(AppPreferences.General.menuBarIcon == .systemSymbol)
        return item
      }(),
      alert: {
        let alert = NSAlert()
        alert.messageText = Localized.UI.alertMessageSetSymbolName
        alert.addButton(withTitle: Localized.UI.alertButtonTitleApplyChanges)
        alert.addButton(withTitle: Localized.General.cancel)
        return alert
      }(),
      explanation: Localized.UI.alertExplanationSetSymbolName,
      initialValue: AppPreferences.General.systemSymbolName,
    ) { symbolName in
      guard NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) != nil else {
        return false
      }

      AppPreferences.General.systemSymbolName = symbolName
      AppPreferences.General.menuBarIcon = .systemSymbol
      return true
    })

    menu.addItem(createCustomIconItem(
      item: {
        let item = NSMenuItem(title: Localized.UI.menuTitleCustomFormat)
        item.image = .with(symbolName: Icons.wandAndSparkles, pointSize: Constants.menuIconSize)
        item.setOn(AppPreferences.General.menuBarIcon == .custom)
        return item
      }(),
      alert: {
        let alert = NSAlert()
        alert.messageText = Localized.UI.alertMessageSetDateFormat
        alert.addButton(withTitle: Localized.UI.alertButtonTitleApplyChanges)
        alert.addButton(withTitle: Localized.General.cancel)
        return alert
      }(),
      explanation: Localized.UI.alertExplanationSetDateFormat,
      initialValue: AppPreferences.General.customDateFormat,
    ) { dateFormat in
      guard !dateFormat.isEmpty else {
        return false
      }

      AppPreferences.General.customDateFormat = dateFormat
      AppPreferences.General.menuBarIcon = .custom
      return true
    })

    menu.addSeparator()

    // Dark mode preferences
    menu.addItem(withTitle: Localized.UI.menuTitleColorScheme).isEnabled = false
    [
      (Localized.UI.menuTitleSystem, Appearance.system),
      (Localized.UI.menuTitleLight, Appearance.light),
      (Localized.UI.menuTitleDark, Appearance.dark),
    ].forEach { (title: String, appearance: Appearance) in
      menu.addItem(withTitle: title) { [weak self] in
        self?.updateAppearance(appearance)
      }
      .setOn(AppPreferences.General.appearance == appearance)
    }

    menu.addSeparator()

    // Content scale preferences
    menu.addItem(withTitle: Localized.UI.menuTitleContentScale).isEnabled = false
    [
      (Localized.UI.menuTitleScaleDefault, ContentScale.default),
      (Localized.UI.menuTitleScaleCompact, ContentScale.compact),
      (Localized.UI.menuTitleScaleRoomy, ContentScale.roomy),
    ].forEach { (title: String, scale: ContentScale) in
      menu.addItem(withTitle: title) { [weak self] in
        AppPreferences.General.contentScale = scale
        self?.closePopover()

        if let delegate = NSApp.delegate as? AppDelegate {
          delegate.openPanel()
        } else {
          Logger.assertFail("Unexpected app delegate: \(String(describing: NSApp.delegate))")
        }
      }
      .setOn(AppPreferences.General.contentScale == scale)
    }

    menu.addSeparator()

    // Accessibility options
    menu.addItem(withTitle: Localized.UI.menuTitleReduceMotion) { [weak self] in
      AppPreferences.Accessibility.reduceMotion.toggle()
      self?.popover?.animates = !AppPreferences.Accessibility.reduceMotion
    }
    .setOn(AppPreferences.Accessibility.reduceMotion)

    menu.addItem(withTitle: Localized.UI.menuTitleReduceTransparency) { [weak self] in
      AppPreferences.Accessibility.reduceTransparency.toggle()
      self?.popover?.applyMaterial(AppPreferences.Accessibility.popoverMaterial)
    }
    .setOn(AppPreferences.Accessibility.reduceTransparency)

    menu.addSeparator()

    menu.addItem({
      let item = NSMenuItem(title: Localized.UI.menuTitlePinOnTop)
      item.addAction { [weak self] in
        self?.togglePinnedOnTop()
      }

      // Just a hint here, event is handled using NSEvent.addLocalMonitor
      item.keyEquivalent = "p"
      item.keyEquivalentModifierMask = []

      item.setOn(pinnedOnTop)
      return item
    }())

    let item = NSMenuItem(title: Localized.UI.menuTitleAppearance)
    item.submenu = menu
    return item
  }

  var menuItemCalendars: NSMenuItem {
    let menu = NSMenu()
    menu.autoenablesItems = false

    let calendars = CalendarManager.default.allCalendars()
    let remindersIndex = calendars.firstIndex { $0.allowedEntityTypes.contains(.reminder) }
    let identifiers = Set(calendars.map { $0.calendarIdentifier })

    for (index, calendar) in calendars.enumerated() {
      let calendarID = calendar.calendarIdentifier
      let item = NSMenuItem(title: calendar.title)
      item.setOn(!AppPreferences.Calendar.hiddenCalendars.contains(calendarID))

      item.addAction { [weak self] in
        AppPreferences.Calendar.hiddenCalendars.toggle(calendarID)
        self?.reloadCalendar()
      }

      if let color = calendar.color {
        item.image = .with(
          cellColor: color,
          borderColor: color.darkerColor(),
          borderWidth: view.hairlineWidth,
          size: CGSize(width: 12, height: 12),
          cornerRadius: 3
        )
      }

      if remindersIndex == index {
        menu.addItem(.separator())
      }

      item.isEnabled = true
      menu.addItem(item)
    }

    menu.addSeparator()

    if CalendarManager.default.authorizationStatus(for: .reminder) == .notDetermined {
      menu.addItem(withTitle: Localized.UI.menuTitleShowReminders) {
        Task {
          await CalendarManager.default.requestAccessIfNeeded(type: .reminder)
        }
      }
      menu.addSeparator()
    }

    menu.addItem(withTitle: Localized.UI.menuTitleSelectAll) { [weak self] in
      AppPreferences.Calendar.hiddenCalendars.removeAll()
      self?.reloadCalendar()
    }.isEnabled = !AppPreferences.Calendar.hiddenCalendars.isEmpty

    menu.addItem(withTitle: Localized.UI.menuTitleDeselectAll) { [weak self] in
      AppPreferences.Calendar.hiddenCalendars = identifiers
      self?.reloadCalendar()
    }.isEnabled = AppPreferences.Calendar.hiddenCalendars != identifiers

    menu.addSeparator()
    menu.addItem(withTitle: Localized.UI.menuTitlePrivacySettings) { [weak self] in
      self?.closePopover()
      NSWorkspace.shared.safelyOpenURL(string: "x-apple.systempreferences:com.apple.preference.security")
    }

    let item = NSMenuItem(title: Localized.UI.menuTitleCalendars)
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

    menu.addItem(withTitle: Localized.UI.menuTitleOpenDirectory) { [weak self] in
      self?.closePopover()
      HolidayManager.default.openUserDefinedDirectory()
    }

    menu.addItem(withTitle: Localized.UI.menuTitleCustomizationTips) { [weak self] in
      self?.closePopover()
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

  var menuItemOpenDateTime: NSMenuItem {
    let item = NSMenuItem(title: Localized.UI.menuTitleOpenDateTime)
    item.addAction { [weak self] in
      self?.closePopover()
      NSWorkspace.shared.safelyOpenURL(string: "x-apple.systempreferences:com.apple.preference.datetime")
    }

    return item
  }

  var menuItemAboutLunarBar: NSMenuItem {
    let item = NSMenuItem(title: Localized.UI.menuTitleAboutLunarBar)
    item.addAction { [weak self] in
      self?.closePopover()
      NSApp.orderFrontStandardAboutPanel()
    }

    return item
  }

  var menuItemGitHub: NSMenuItem {
    let item = NSMenuItem(title: Localized.UI.menuTitleGitHub)
    item.addAction { [weak self] in
      self?.closePopover()
      NSWorkspace.shared.safelyOpenURL(string: "https://github.com/LunarBar-app/LunarBar")
    }

    return item
  }

  var menuItemCheckForUpdates: NSMenuItem {
    let item = NSMenuItem(title: Localized.UI.menuTitleCheckForUpdates)
    item.addAction { [weak self] in
      Task {
        self?.closePopover()
        await AppUpdater.checkForUpdates(explicitly: true)
      }
    }

    return item
  }

  var menuItemQuitLunarBar: NSMenuItem {
    let item = NSMenuItem(title: Localized.UI.menuTitleQuitLunarBar, action: nil, keyEquivalent: "q")
    item.keyEquivalentModifierMask = .command
    item.addAction {
      NSApp.terminate(nil)
    }

    return item
  }

  func createDateIconItem(
    style: DateIconStyle,
    title: String,
    isOn: Bool,
    action: @autoclosure @escaping () -> Void
  ) -> NSMenuItem {
    let item = NSMenuItem(title: title)
    item.setOn(isOn)
    item.addAction(action)

    if let image = AppIconFactory.createDateIcon(style: style) {
      item.image = image.resized(with: CGSize(width: 16.8, height: 12)) // 1.4:1
    } else {
      Logger.assertFail("Failed to create the icon")
    }

    return item
  }

  func createCustomIconItem(
    item: NSMenuItem,
    alert: NSAlert,
    explanation: String,
    initialValue: String?,
    commitChange: @escaping (String) -> Bool
  ) -> NSMenuItem {
    let inputField = EditableTextField(frame: CGRect(x: 0, y: 0, width: 256, height: 22))
    inputField.cell?.usesSingleLineMode = true
    inputField.cell?.lineBreakMode = .byTruncatingTail
    inputField.stringValue = initialValue ?? ""

    let textView = NSTextView.markdownView(
      with: explanation,
      contentWidth: inputField.frame.width
    )

    textView.frame = CGRect(
      origin: CGPoint(x: 0, y: inputField.frame.height + 15), // Spacing between two fields
      size: textView.frame.size
    )

    let wrapper = NSView(frame: {
      var rect = textView.frame
      rect.size.height += textView.frame.minY // Text view height and the spacing
      return rect
    }())

    wrapper.addSubview(textView)
    wrapper.addSubview(inputField)
    alert.accessoryView = wrapper
    alert.layout()

    func showAlert() {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        inputField.window?.makeFirstResponder(inputField)
      }

      guard alert.runModal() == .alertFirstButtonReturn else {
        return
      }

      guard !commitChange(inputField.stringValue) else {
        return
      }

      // Failed to commit the change
      NSSound.beep()
      showAlert()
    }

    item.addAction(showAlert)
    return item
  }

  func reloadCalendar() {
    updateCalendar(targetDate: monthDate)
  }

  func closePopover() {
    popover?.close()
  }
}
