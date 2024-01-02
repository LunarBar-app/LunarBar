//
//  Calendar+Extension.swift
//
//  Created by cyan on 12/21/23.
//

import Foundation

public extension Calendar {
  /// Returns a gregorian calendar, use Calendar.autoupdatingCurrent when possible.
  ///
  /// We must use a gregorian calendar to represent the solar system,
  /// if the current calendar is gregorian, we should use it instead of creating a gregorian calendar,
  /// the reason is that the first weekday of a calendar can be customized.
  static var solar: Calendar {
    let current = autoupdatingCurrent
    if current.identifier == .gregorian {
      return current
    }

    return Self(identifier: .gregorian)
  }

  /// Returns a lunar calendar, basically the Chinese calendar.
  static let lunar = Self(identifier: .chinese)

  /**
   In most calendars, this should be just 7, but this is not always true.
   */
  var numberOfDaysInWeek: Int {
    weekdaySymbols.count
  }

  /**
   Always fill the calendar with 42 dates, even for months with fewer days like February.
   */
  var numberOfRowsInMonth: Int {
    6
  }

  /**
   Basically `veryShortStandaloneWeekdaySymbols`, takes `firstWeekday` into account.
   */
  var orderedVeryShortWeekdaySymbols: [String] {
    orderedWeekdaySymbols(veryShortStandaloneWeekdaySymbols)
  }

  /**
   Basically `standaloneWeekdaySymbols`, takes `firstWeekday` into account.
   */
  var orderedWeekdaySymbols: [String] {
    orderedWeekdaySymbols(standaloneWeekdaySymbols)
  }

  /**
   Indices of weekends, taking **firstWeekday** into account.

   Possible results:

   ```swift
   [6, 0], // S M T W T F S
   [5, 6], // M T W T F S S
   [4, 5], // T W T F S S M
   [3, 4], // W T F S S M T
   [2, 3], // T F S S M T W
   [1, 2], // F S S M T W T
   [0, 1], // S S M T W T F
   ```
   */
  var weekendIndices: [Int] {
    [
      (numberOfDaysInWeek - firstWeekday),
      (numberOfDaysInWeek - firstWeekday + 1) % numberOfDaysInWeek,
    ]
  }

  /**
   Returns all dates by filling the calendar, leading and trailing dates are included.

   Note, this function takes **first weekday** into account.
   */
  func allDatesFillingMonth(from date: Date) -> [Date]? {
    guard let startDate = startDateFillingMonth(from: date) else {
      return nil
    }

    // Depending on the first weekday, the number of days in a month may vary,
    // but we always need 42 items to create the calendar.
    let numberOfDays = numberOfDaysInWeek * numberOfRowsInMonth
    let allDates = (0..<numberOfDays).compactMap {
      self.date(byAdding: .day, value: $0, to: startDate)
    }

    Logger.assert(allDates.count == numberOfDays, "It should always return 42 dates")
    return allDates
  }

  func startOfMonth(from date: Date) -> Date? {
    self.date(from: dateComponents([.year, .month], from: date))
  }

  func endOfMonth(from date: Date) -> Date? {
    guard let startOfMonth = startOfMonth(from: date) else {
      return nil
    }

    return self.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)
  }

  func endOfDay(for date: Date) -> Date {
    var components = DateComponents()
    components.day = 1
    components.second = -1

    return self.date(byAdding: components, to: startOfDay(for: date)) ?? date
  }

  func daysBetween(from startDate: Date, to endDate: Date) -> Int? {
    dateComponents([.day], from: startOfDay(for: startDate), to: startOfDay(for: endDate)).day
  }

  func lastDayOfYear(from date: Date) -> Date? {
    guard let newYear = self.date(from: DateComponents(year: year(from: date) + 1, month: 1, day: 1)) else {
      return nil
    }

    return self.date(byAdding: .day, value: -1, to: newYear)
  }

  func isLeapMonth(from date: Date) -> Bool {
  #if swift(<5.9.2)
    // Pending Xcode 15.1 on GitHub
    return false
  #else
    guard #available(macOS 14, *) else {
      return false
    }

    // Interesting, the first `isLeapMonth` is macOS 14 only but the second is not
    return dateComponents([.isLeapMonth], from: date).isLeapMonth ?? false
  #endif
  }

  func year(from date: Date) -> Int {
    component(.year, from: date)
  }

  func month(from date: Date) -> Int {
    component(.month, from: date)
  }
}

// MARK: - Private

private extension Calendar {
  /**
   Properties like weekdaySymbols don't reflect changes to firstWeekday, this method reorders them.
   */
  func orderedWeekdaySymbols(_ symbols: [String]) -> [String] {
    Array(symbols[(firstWeekday - 1)..<symbols.count] + symbols[0..<(firstWeekday - 1)])
  }

  /**
   The start date of the current month by filling the calendar, leading dates in previous month are included.

   Note, this function takes **first weekday** into account.
   */
  func startDateFillingMonth(from date: Date) -> Date? {
    guard let startOfMonth = startOfMonth(from: date) else {
      Logger.assertFail("Failed to get the start of month for: \(date)")
      return nil
    }

    let weekday = component(.weekday, from: startOfMonth)
    let extraDays = (numberOfDaysInWeek - firstWeekday + weekday) % numberOfDaysInWeek
    return self.date(byAdding: .day, value: -extraDays, to: startOfMonth)
  }
}
