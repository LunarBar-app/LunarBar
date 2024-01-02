//
//  DateComponentsTests.swift
//
//  Created by cyan on 2023/12/29.
//

import LunarBarKit
import XCTest

final class DateComponentsTests: XCTestCase {
  func testFourDigitsMonthDay() {
    XCTAssertEqual({
      var components = DateComponents()
      components.month = 2
      components.day = 25

      return components
    }().fourDigitsMonthDay, "0225")

    XCTAssertEqual({
      var components = DateComponents()
      components.month = 12
      components.day = 5

      return components
    }().fourDigitsMonthDay, "1205")
  }
}
