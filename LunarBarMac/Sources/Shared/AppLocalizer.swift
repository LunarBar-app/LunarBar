//
//  AppLocalizer.swift
//  LunarBarMac
//
//  Created by cyan on 12/28/23.
//

import Foundation
import LunarBarKit

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

  /**
   Returns the best lunar day label for a given date.

   Priority: New Year's Eve > festival > solar term > month name (on 1st) > day name.
   */
  static func lunarDayLabel(for date: Date) -> String {
    let lunarComponents = Calendar.lunar.dateComponents([.month, .day], from: date)
    let solarComponents = Calendar.solar.dateComponents([.year, .month, .day], from: date)

    let month = lunarComponents.month ?? 1
    let day = lunarComponents.day ?? 1
    let isLeap = Calendar.lunar.isLeapMonth(from: date)

    let solarMonthDay = solarComponents.fourDigitsMonthDay
    let lunarMonthDay = lunarComponents.fourDigitsMonthDay
    let year = solarComponents.year ?? 0

    // Chinese New Year's Eve
    if let lastDay = Calendar.lunar.lastDayOfYear(from: date),
       Calendar.lunar.isDate(date, inSameDayAs: lastDay) {
      return Localized.Calendar.chineseNewYearsEve
    }

    if let festival = lunarFestival(of: lunarMonthDay) {
      return festival
    }

    if let termIndex = LunarCalendar.default.info(of: year)?.solarTerms[solarMonthDay] {
      return solarTerm(of: termIndex)
    }

    // Show month name on the 1st day of each lunar month
    if day == 1 {
      return chineseMonth(of: month - 1, isLeap: isLeap)
    }

    return chineseDay(of: day - 1)
  }
}
