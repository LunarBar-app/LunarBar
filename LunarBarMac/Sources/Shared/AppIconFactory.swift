//
//  AppIconFactory.swift
//  LunarBarMac
//
//  Created by cyan on 1/8/24.
//

import AppKit

@MainActor
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

    let currentDay = Calendar.solar.component(.day, from: .now)
    let labelFont = NSFont.boldSystemFont(ofSize: Constants.fontSize)

    // The width can be calculated precisely with an attributed string
    let textWidth = NSAttributedString(
      string: String(currentDay),
      attributes: [.font: labelFont]
    ).size().width

    // The height may contain unpredictable spacing and it's normalized in the actual rendering result
    //
    // We don't have a good way to calculate the optimized height, here we pre-define all values.
    let textHeight: Double = {
      if #available(macOS 15.0, *) {
        // [macOS 15] The issue is resolved in macOS Sequoia
        return 8.5
      }

      let values = [9.5, 8.5, 9, 9, 8.5, 9, 9.5, 8.5, 9, 9.5]
      if currentDay >= 10 {
        return max(values[currentDay / 10], values[currentDay % 10])
      } else {
        return values[currentDay]
      }
    }()

    // Create the path from text and make sure it's optically aligned
    let textPath = NSBezierPath.from(text: String(currentDay), font: labelFont, isFlipped: isFlipped)
    let transform = AffineTransform(
      translationByX: (bounds.width - textWidth) * 0.5,
      byY: (bounds.height - textHeight) * 0.5
    )

    textPath.transform(using: transform)
    textPath.append(NSBezierPath(rect: bounds))

    let shapeLayer = CAShapeLayer()
    shapeLayer.path = textPath.cgPath

    layer?.mask = shapeLayer
    layer?.cornerCurve = .continuous
    layer?.cornerRadius = Constants.cornerRadius
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var isFlipped: Bool {
    // [macOS 15] It seems flipping the coordinate system is no longer needed
    if #available(macOS 15.0, *) {
      return false
    }

    return true
  }
}
