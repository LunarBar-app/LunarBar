//
//  AppLocalizer.swift
//  LunarBarMac
//
//  Created by cyan on 12/28/23.
//

import Foundation

enum AppLocalizer {
  static func solarTerm(of index: Int) -> String {
    Localized.Calendar.solarTerms[index]
  }

  static func chineseMonth(of index: Int, isLeap: Bool) -> String {
    let nameOfMonth = Localized.Calendar.chineseMonths[index]
    return isLeap ? (Localized.Calendar.chineseLeapMonth + nameOfMonth) : nameOfMonth
  }

  static func chineseDay(of index: Int) -> String {
    Localized.Calendar.chineseDays[index]
  }

  static func lunarFestival(of key: String) -> String? {
    Localized.Calendar.lunarFestivals[key]
  }

  static func holidayLabel(of type: HolidayType?) -> String? {
    let middleDot = " · "

    switch type {
    case .none:
      return nil
    case .workday:
      return Localized.Calendar.workdayLabel + middleDot
    case .holiday:
      return Localized.Calendar.holidayLabel + middleDot
    }
  }
}
