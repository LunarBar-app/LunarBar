//
//  AppPreferencesTests.swift
//  LunarBarMacTests
//
//  Created by cyan on 12/31/23.
//

import XCTest
@testable import LunarBar

@MainActor
final class AppPreferencesTests: XCTestCase {
  func testSetEncodingDecoding() {
    AppPreferences.Mocked.setObjects.removeAll()
    XCTAssertEqual(AppPreferences.Mocked.setObjects, Set())

    AppPreferences.Mocked.setObjects.insert("Foo")
    AppPreferences.Mocked.setObjects.insert("Bar")
    XCTAssertEqual(AppPreferences.Mocked.setObjects, Set(["Foo", "Bar"]))

    AppPreferences.Mocked.setObjects.toggle("Foo")
    XCTAssertEqual(AppPreferences.Mocked.setObjects, Set(["Bar"]))
  }
}

// MARK: - Private

private extension AppPreferences {
  enum Mocked {
    @Storage(key: "mocked.set-objects", defaultValue: Set())
    static var setObjects: Set<String>
  }
}
