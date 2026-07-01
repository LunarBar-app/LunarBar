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

  @MainActor
  func testExistenceOfVisualEffectView() {
    class ContentViewController: NSViewController {
      override func loadView() {
        view = NSView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
      }
    }

    let window = NSWindow()
    window.makeKeyAndOrderFront(nil)

    guard let contentView = window.contentView else {
      XCTAssert(false, "Missing contentView in NSWindow")
      return
    }

    let popover = NSPopover()
    popover.contentViewController = ContentViewController(nibName: nil, bundle: nil)
    popover.show(
      relativeTo: CGRect(x: 0, y: 0, width: 1, height: 1),
      of: contentView,
      preferredEdge: .maxX
    )

    let expectation = XCTestExpectation()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      expectation.fulfill()
    }

    wait(for: [expectation])
    let effectView = popover.contentViewController?.visualEffectView
    XCTAssertEqual(effectView?.className, "NSPopoverFrame")
  }
}

private extension RuntimeTests {
  func testExistenceOfSelector(object: AnyObject, selector: String) {
    XCTAssert(object.responds(to: sel_getUid(selector)), "Missing \(selector) in \(object.self)")
  }
}
