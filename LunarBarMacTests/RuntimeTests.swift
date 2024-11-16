//
//  RuntimeTests.swift
//  LunarBarMacTests
//
//  Created by cyan on 2024/11/15.
//

import XCTest
@testable import LunarBar

final class RuntimeTests: XCTestCase {
  func testExistenceOfImageTintColor() {
    testExistenceOfSelector(object: NSImage(), selector: "_setTintColor:")
  }
}

private extension RuntimeTests {
  func testExistenceOfSelector(object: AnyObject, selector: String) {
    XCTAssert(object.responds(to: sel_getUid(selector)), "Missing \(selector) in \(object.self)")
  }
}
