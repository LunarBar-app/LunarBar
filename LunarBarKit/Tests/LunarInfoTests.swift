//
//  LunarInfoTests.swift
//
//  Created by cyan on 2023/12/29.
//

import LunarBarKit
import XCTest

final class LunarInfoTests: XCTestCase {
  func testSolarTermsFormat() {
    for year in 1901...2100 {
      let solarTerms = LunarCalendar.default.info(of: year)?.solarTerms
      XCTAssertEqual(solarTerms?.count, 24)

      let keys = solarTerms?.map { $0.key }
      keys?.forEach { key in
        XCTAssertEqual(key.count, 4)
      }

      let indices = solarTerms?.map { $0.value }.sorted()
      XCTAssertEqual(indices, Array(0...23))
    }
  }
}
