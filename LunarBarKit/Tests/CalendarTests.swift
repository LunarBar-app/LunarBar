//
//  CalendarTests.swift
//
//  Created by cyan on 2023/12/29.
//

import LunarBarKit
import XCTest

final class CalendarTests: XCTestCase {
  func testCalendarIdentifier() {
    XCTAssertEqual(Calendar.solar.identifier, .gregorian)
    XCTAssertEqual(Calendar.lunar.identifier, .chinese)
  }

  func testNumberOfDaysInWeek() {
    XCTAssertEqual(Calendar.solar.numberOfDaysInWeek, 7)
    XCTAssertEqual(Calendar.lunar.numberOfDaysInWeek, 7)
  }

  func testWeekdaySymbols() {
    XCTAssertEqual({
      var calendar = Calendar.solar
      calendar.locale = Locale(identifier: "en-US")
      calendar.firstWeekday = 7 // Saturday

      return calendar
    }().orderedVeryShortWeekdaySymbols, ["S", "S", "M", "T", "W", "T", "F"])

    XCTAssertEqual({
      var calendar = Calendar.solar
      calendar.locale = Locale(identifier: "zh-Hans")
      calendar.firstWeekday = 2 // Monday

      return calendar
    }().orderedVeryShortWeekdaySymbols, ["一", "二", "三", "四", "五", "六", "日"])
  }

  func testWeekendIndices() {
    let possibleResults = [
      [6, 0], // S M T W T F S
      [5, 6], // M T W T F S S
      [4, 5], // T W T F S S M
      [3, 4], // W T F S S M T
      [2, 3], // T F S S M T W
      [1, 2], // F S S M T W T
      [0, 1], // S S M T W T F
    ]

    for firstWeekday in 1...7 {
      var calendar = Calendar.solar
      calendar.firstWeekday = firstWeekday
      XCTAssertEqual(calendar.weekendIndices, possibleResults[firstWeekday - 1])
    }
  }

  func testAllDatesFillingMonth() {
    for firstWeekday in 1...7 {
      var calendar = Calendar.solar
      calendar.firstWeekday = firstWeekday

      var components = DateComponents()
      components.year = 2024
      components.month = 2
      components.day = 10

      let monthDate = calendar.date(from: components) ?? .now
      let firstDate = calendar.allDatesFillingMonth(from: monthDate)?.first ?? .now
      XCTAssertEqual(calendar.dateComponents([.weekday], from: firstDate).weekday, firstWeekday)
    }
  }

  func testStartOfMonth() {
    var components = DateComponents()
    components.year = 2024
    components.month = 2
    components.day = 15

    guard let date = Calendar.solar.date(from: components),
          let startOfMonth = Calendar.solar.startOfMonth(from: date) else {
      fatalError("Missing dates")
    }

    XCTAssertEqual(Calendar.solar.component(.day, from: startOfMonth), 1)
  }

  func testEndOfMonth() {
    var components = DateComponents()
    components.year = 2024
    components.month = 2
    components.day = 1

    guard let date = Calendar.solar.date(from: components),
          let endOfMonth = Calendar.solar.endOfMonth(from: date) else {
      fatalError("Missing dates")
    }

    XCTAssertEqual(Calendar.solar.component(.day, from: endOfMonth), 29)
  }

  func testLastDayOfYear() {
    var components = DateComponents()
    components.year = 2024
    components.month = 2
    components.day = 1

    guard let date = Calendar.solar.date(from: components),
          let lastDay = Calendar.solar.lastDayOfYear(from: date) else {
      fatalError("Missing dates")
    }

    XCTAssertEqual(Calendar.solar.component(.month, from: lastDay), 12)
    XCTAssertEqual(Calendar.solar.component(.day, from: lastDay), 31)
  }
}
