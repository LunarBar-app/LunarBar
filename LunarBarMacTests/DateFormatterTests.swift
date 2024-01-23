//
//  DateFormatterTests.swift
//  LunarBarMacTests
//
//  Created by cyan on 2024/1/23.
//

import XCTest
@testable import LunarBar

final class DateFormatterTests: XCTestCase {
  func testLunarDateFormatting() {
    let formatter = DateFormatter()
    formatter.calendar = Calendar.lunar
    formatter.dateStyle = .long
    formatter.timeStyle = .none

    formatter.locale = Locale(identifier: "zh-Hans")
    XCTAssertFalse(formatter.string(from: .now).matches(of: /^(\d+).+/).isEmpty)

    formatter.locale = Locale(identifier: "zh-Hant")
    XCTAssertFalse(formatter.string(from: .now).matches(of: /^(\d+).+/).isEmpty)
  }
}
