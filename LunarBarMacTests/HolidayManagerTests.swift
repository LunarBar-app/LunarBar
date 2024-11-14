//
//  HolidayManagerTests.swift
//  LunarBarMacTests
//
//  Created by cyan on 2023/12/29.
//

import XCTest
@testable import LunarBar

@MainActor
final class HolidayManagerTests: XCTestCase {
  func testDataOf2024() {
    let manager = HolidayManager.default
    XCTAssertEqual(manager.typeOf(year: 2024, monthDay: "0101"), .holiday)
    XCTAssertEqual(manager.typeOf(year: 2024, monthDay: "0204"), .workday)
  }

  func testUserDefinedData() {
    let manager = HolidayManager.default
    let directory = URL.documentsDirectory.appending(path: "Holidays", directoryHint: .isDirectory)

    try? FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: false
    )

    try? JSONSerialization.data(withJSONObject: ["2025": ["0101": 2]]).write(
      to: directory.appending(path: "custom.json", directoryHint: .notDirectory),
      options: .atomic
    )

    manager.reloadUserDefinedFiles()
    XCTAssertEqual(manager.userDefinedFiles, ["custom.json"])
    XCTAssertEqual(manager.typeOf(year: 2025, monthDay: "0101"), .holiday)
  }
}
