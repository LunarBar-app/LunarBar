//
//  AppIconFactory.swift
//  LunarBarMac
//
//  Created by cyan on 2024/1/8.
//

import AppKit

enum AppIconFactory {
  static func createCalendarIcon(pointSize: Double = 16) -> NSImage {
    .with(symbolName: Icons.calendar, pointSize: pointSize).asTemplate
  }

  static func createDateIcon() -> NSImage? {
    DateIconView().snapshotImage?.asTemplate
  }
}

// MARK: - Private

private class DateIconView: NSView {
  private enum Constants {
    static let iconSize = CGSize(width: 20, height: 14)
    static let fontSize: Double = 12
    static let cornerRadius: Double = 2.5
  }

  init() {
    super.init(frame: CGRect(origin: .zero, size: Constants.iconSize))

    // Resolve the color because .black doesn't work well with NSMenuItem, even when the image is template
    let tintColor: NSColor = NSApp.effectiveAppearance.isDarkMode ? .white : .black
    layerBackgroundColor = tintColor

    let currentDate = String(Calendar.solar.component(.day, from: .now))
    let labelFont = NSFont.boldSystemFont(ofSize: Constants.fontSize)
    let textSize = NSAttributedString(string: currentDate, attributes: [.font: labelFont]).size()

    // Create the path from text and make sure it's optically aligned
    let textPath = NSBezierPath.from(text: currentDate, font: labelFont)
    textPath.transform(using: .init(translationByX: (bounds.width - textSize.width) * 0.5, byY: 2.4))
    textPath.append(NSBezierPath(rect: bounds))

    let shapeLayer = CAShapeLayer()
    shapeLayer.path = textPath.toCGPath

    layer?.mask = shapeLayer
    layer?.cornerCurve = .continuous
    layer?.cornerRadius = Constants.cornerRadius
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var isFlipped: Bool {
    true
  }
}
