//
//  WeekdayView.swift
//  LunarBarMac
//
//  Created by cyan on 12/21/23.
//

import AppKit
import AppKitControls
import LunarBarKit

/**
 Weekday symbols, showing the shortest representation of each weekday.

 Example: [ S M T W T F S ]
 */
final class WeekdayView: NSStackView {
  init() {
    super.init(frame: .zero)
    distribution = .fillEqually
    spacing = 0

    setAccessibilityElement(true)
    setAccessibilityRole(.group)
    setAccessibilityLabel(Localized.UI.accessibilityWeekdayArea)

    let shortSymbols = Calendar.solar.orderedVeryShortWeekdaySymbols
    let fullSymbols = Calendar.solar.orderedWeekdaySymbols
    let weekendIndices = Calendar.solar.weekendIndices

    Logger.assert(shortSymbols.count == fullSymbols.count, "Invalid weekday symbols")
    Logger.assert(weekendIndices.count == 2, "Invalid weekend indices")

    for index in 0..<shortSymbols.count {
      let label = TextLabel()
      label.alignment = .center
      label.textColor = Colors.primaryLabel
      label.font = .mediumSystemFont(ofSize: Constants.fontSize)
      label.stringValue = shortSymbols[index]

      label.alphaValue = weekendIndices.contains(index) ? AlphaLevels.secondary : AlphaLevels.primary
      label.setAccessibilityLabel(fullSymbols[index])

      addArrangedSubview(label)
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - Private

private extension WeekdayView {
  enum Constants {
    static let fontSize: Double = FontSizes.regular
  }
}
