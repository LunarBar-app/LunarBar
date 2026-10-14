//
//  DateFontSettingsController.swift
//  LunarBarMac
//
//  Created by Codex on 10/14/26.
//

import AppKit

/// A separate window keeps color picking independent of the transient calendar popover.
@MainActor
final class DateFontSettingsController: NSWindowController, NSWindowDelegate {
  static let shared = DateFontSettingsController()

  private let weekdayRow = DateFontSettingsRow(title: Localized.DateFonts.weekdays, previewText: "12")
  private let weekendRow = DateFontSettingsRow(title: Localized.DateFonts.weekends, previewText: "13")

  private init() {
    let window = NSWindow(
      contentRect: CGRect(x: 0, y: 0, width: 520, height: 320),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    window.title = Localized.DateFonts.windowTitle
    window.isReleasedWhenClosed = false

    super.init(window: window)

    window.delegate = self
    configureContent()
    configureActions()
    window.center()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("DateFontSettingsController does not support coder initialization")
  }

  func show() {
    reloadStyles()
    showWindow(nil)
    window?.makeKeyAndOrderFront(nil)
    NSApp.activate()
  }

  func windowWillClose(_ notification: Notification) {
    weekdayRow.deactivateColorWell()
    weekendRow.deactivateColorWell()
  }

  private func configureContent() {
    guard let contentView = window?.contentView else {
      return
    }

    let explanation = NSTextField(wrappingLabelWithString: Localized.DateFonts.explanation)
    explanation.font = .systemFont(ofSize: NSFont.systemFontSize)
    explanation.textColor = .secondaryLabelColor

    let restore = NSButton(title: Localized.DateFonts.restoreDefaults, target: self, action: #selector(restoreDefaults))
    restore.bezelStyle = .rounded

    let close = NSButton(title: Localized.DateFonts.close, target: self, action: #selector(closeSettings))
    close.bezelStyle = .rounded
    close.keyEquivalent = "\r"

    let spacer = NSView()
    spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

    let buttons = NSStackView(views: [restore, spacer, close])
    buttons.orientation = .horizontal
    buttons.alignment = .centerY
    buttons.spacing = 12

    let stack = NSStackView(views: [explanation, weekdayRow.view, weekendRow.view, buttons])
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
      stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
      explanation.widthAnchor.constraint(equalTo: stack.widthAnchor),
      weekdayRow.view.widthAnchor.constraint(equalTo: stack.widthAnchor),
      weekendRow.view.widthAnchor.constraint(equalTo: stack.widthAnchor),
      buttons.widthAnchor.constraint(equalTo: stack.widthAnchor),
    ])
  }

  private func configureActions() {
    weekdayRow.onChange = { [weak self] style in
      AppPreferences.Calendar.weekdayDateStyle = style
      self?.notifyStyleChange()
    }
    weekendRow.onChange = { [weak self] style in
      AppPreferences.Calendar.weekendDateStyle = style
      self?.notifyStyleChange()
    }
  }

  private func reloadStyles() {
    weekdayRow.reload(AppPreferences.Calendar.weekdayDateStyle)
    weekendRow.reload(AppPreferences.Calendar.weekendDateStyle)
  }

  @objc private func restoreDefaults() {
    weekdayRow.deactivateColorWell()
    weekendRow.deactivateColorWell()
    AppPreferences.Calendar.weekdayDateStyle = DateFontStyle()
    AppPreferences.Calendar.weekendDateStyle = DateFontStyle()
    reloadStyles()
    notifyStyleChange()
  }

  private func notifyStyleChange() {
    NotificationCenter.default.post(name: .calendarDateStyleDidChange, object: nil)
  }

  @objc private func closeSettings() {
    close()
  }
}

@MainActor
private final class DateFontSettingsRow: NSObject {
  let view = NSBox()
  var onChange: ((DateFontStyle) -> Void)?

  private let colorWell = NSColorWell()
  private let bold = NSButton(checkboxWithTitle: Localized.DateFonts.bold, target: nil, action: nil)
  private let preview: NSTextField
  private var style = DateFontStyle()

  init(title: String, previewText: String) {
    preview = NSTextField(labelWithString: previewText)

    super.init()

    view.title = title
    view.titleFont = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
    view.contentViewMargins = CGSize(width: 12, height: 10)

    colorWell.target = self
    colorWell.action = #selector(changeColor)
    colorWell.colorWellStyle = .expanded
    colorWell.isContinuous = true
    colorWell.supportsAlpha = false
    colorWell.setAccessibilityLabel(Localized.DateFonts.color)
    bold.target = self
    bold.action = #selector(changeBold)

    preview.alignment = .center
    preview.setAccessibilityLabel(Localized.DateFonts.preview)

    let colorLabel = NSTextField(labelWithString: Localized.DateFonts.color)
    let spacer = NSView()
    spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

    let stack = NSStackView(views: [colorLabel, colorWell, bold, spacer, preview])
    stack.orientation = .horizontal
    stack.alignment = .centerY
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    if let contentView = view.contentView {
      contentView.addSubview(stack)
      NSLayoutConstraint.activate([
        stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        stack.topAnchor.constraint(equalTo: contentView.topAnchor),
        stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      ])
    }

    NSLayoutConstraint.activate([
      view.heightAnchor.constraint(equalToConstant: 84),
      colorWell.widthAnchor.constraint(equalToConstant: 64),
      colorWell.heightAnchor.constraint(equalToConstant: 28),
      preview.widthAnchor.constraint(equalToConstant: 44),
    ])
  }

  func reload(_ style: DateFontStyle) {
    self.style = style
    colorWell.color = style.textColor
    colorWell.isEnabled = true
    bold.state = style.isBold ? .on : .off
    preview.font = style.font(ofSize: FontSizes.large)
    preview.textColor = style.textColor
  }

  func deactivateColorWell() {
    if colorWell.isActive {
      colorWell.deactivate()
      NSColorPanel.shared.orderOut(nil)
    }
  }

  @objc private func changeColor() {
    guard let color = DateFontColor(color: colorWell.color) else {
      return
    }

    style.color = color
    commit()
  }

  @objc private func changeBold() {
    style.isBold = bold.state == .on
    commit()
  }

  private func commit() {
    reload(style)
    onChange?(style)
  }
}
