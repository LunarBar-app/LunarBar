//
//  DateFormatterTests.swift
//  LunarBarMacTests
//
//  Created by cyan on 1/23/24.
//

import XCTest
@testable import LunarBar

final class DateFormatterTests: XCTestCase {
  func testLunarDateFormatting() {
    let formatter = DateFormatter.lunarDate
    formatter.locale = Locale(identifier: "zh-Hans")
    XCTAssertFalse(formatter.string(from: .now).matches(of: /^(\d+).+/).isEmpty)

    formatter.locale = Locale(identifier: "zh-Hant")
    XCTAssertFalse(formatter.string(from: .now).matches(of: /^(\d+).+/).isEmpty)
  }
}
