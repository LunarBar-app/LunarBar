//
//  EKEventTests.swift
//
//  Created by cyan on 12/29/23.
//

import LunarBarKit
import EventKit
import XCTest

final class EKEventTests: XCTestCase {
  func testOverlaps() {
    XCTAssertTrue({
      let event = EKEvent(eventStore: EKEventStore())
      event.startDate = Date.now
      event.endDate = event.startDate.addingTimeInterval(60 * 60)
      return event.overlaps(startOfDay: .now, endOfDay: .now.addingTimeInterval(10))
    }())

    XCTAssertFalse({
      let event = EKEvent(eventStore: EKEventStore())
      event.startDate = Date.now.addingTimeInterval(-24 * 60 * 60)
      event.endDate = event.startDate.addingTimeInterval(60 * 60)
      return event.overlaps(startOfDay: .now, endOfDay: .now.addingTimeInterval(10))
    }())
  }
}
