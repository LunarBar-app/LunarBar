//
//  RuntimeTests.swift
//  LunarBarMacTests
//
//  Created by cyan on 11/15/24.
//

import XCTest
@testable import LunarBar

final class RuntimeTests: XCTestCase {
  func testExistenceOfImageTintColor() {
    testExistenceOfSelector(object: NSImage(), selector: "_setTintColor:")
  }

  @MainActor
  func testExistenceOfShouldHideAnchor() {
    let popover = NSPopover()
    popover.setValue(true, forKey: "shouldHideAnchor")
    testExistenceOfSelector(object: popover, selector: "shouldHideAnchor")
  }
}

private extension RuntimeTests {
  func testExistenceOfSelector(object: AnyObject, selector: String) {
    XCTAssert(object.responds(to: sel_getUid(selector)), "Missing \(selector) in \(object.self)")
  }
}
