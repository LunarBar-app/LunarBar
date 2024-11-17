//
//  DateFormatter+Extension.swift
//
//  Created by cyan on 11/14/24.
//

import Foundation

public extension DateFormatter {
  static var fullDate: Self {
    let formatter = Self()
    formatter.dateStyle = .full
    formatter.timeStyle = .none

    return formatter
  }

  static var lunarDate: Self {
    let formatter = Self()
    formatter.calendar = Calendar.lunar
    formatter.dateStyle = .long
    formatter.timeStyle = .none

    // Always use Chinese for lunar dates,
    // the English version of the Heavenly Stems and Earthly Branches is strange
    if Locale.autoupdatingCurrent.language.languageCode == "en" {
      formatter.locale = Locale(identifier: "zh-Hans")
    }

    return formatter
  }

  static var localizedMonth: Self {
    let formatter = Self()
    formatter.locale = .autoupdatingCurrent

    // E.g., Dec 2023 in en-US, 2023年12月 in zh-Hans
    formatter.setLocalizedDateFormatFromTemplate("MMM y")
    return formatter
  }
}
