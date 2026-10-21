//
//  RuntimeTests.swift
//  LunarBarMacTests
//
//  Created by cyan on 11/15/24.
//

import XCTest
import AppKitControls
@testable import LunarBar

final class RuntimeTests: XCTestCase {
  @MainActor
  func testImageButtonStateBackground() async throws {
    let button = ImageButton(
      symbolName: "circle",
      sizeDelta: 1,
      cornerRadius: 4,
      highlightColorProvider: { .selectedControlColor },
      accessibilityLabel: "Actions"
    )

    let background = try XCTUnwrap(button.subviews.first)
    XCTAssertEqual(background.alphaValue, 0)

    button.state = .on
    try await Task.sleep(for: .milliseconds(250))
    XCTAssertEqual(background.alphaValue, 1, accuracy: 0.01)
    XCTAssertEqual(button.alphaValue, 1)

    button.onMouseHover?(false)
    try await Task.sleep(for: .milliseconds(250))
    XCTAssertEqual(background.alphaValue, 1, accuracy: 0.01)

    button.state = .off
    try await Task.sleep(for: .milliseconds(250))
    XCTAssertEqual(background.alphaValue, 0, accuracy: 0.01)

    button.isHighlighted = true
    try await Task.sleep(for: .milliseconds(250))
    XCTAssertEqual(background.alphaValue, 1, accuracy: 0.01)
    XCTAssertEqual(button.alphaValue, 0.6)

    button.onMouseHover?(true)
    button.isHighlighted = false
    try await Task.sleep(for: .milliseconds(250))
    XCTAssertEqual(background.alphaValue, 1, accuracy: 0.01)
    XCTAssertEqual(button.alphaValue, 1)

    // Deselecting must discard stale hover
    button.state = .on
    button.state = .off
    try await Task.sleep(for: .milliseconds(250))
    XCTAssertEqual(background.alphaValue, 0, accuracy: 0.01)
  }

  @MainActor
  func testImageButtonRestoresHoverWhenDeselected() async throws {
    class Window: NSWindow {
      var pointerLocation = CGPoint.zero

      override var mouseLocationOutsideOfEventStream: NSPoint {
        pointerLocation
      }
    }

    let window = Window(
      contentRect: CGRect(x: 0, y: 0, width: 100, height: 100),
      styleMask: .borderless,
      backing: .buffered,
      defer: false
    )

    let button = ImageButton(
      symbolName: "circle",
      sizeDelta: 1,
      cornerRadius: 4,
      highlightColorProvider: { .selectedControlColor },
      accessibilityLabel: "Actions"
    )

    let contentView = try XCTUnwrap(window.contentView)
    contentView.addSubview(button)
    button.setFrameOrigin(CGPoint(x: 10, y: 10))
    let background = try XCTUnwrap(button.subviews.first)

    button.state = .on
    window.pointerLocation = CGPoint(x: 20, y: 20)
    button.state = .off
    try await Task.sleep(for: .milliseconds(250))
    XCTAssertEqual(background.alphaValue, 1, accuracy: 0.01)

    button.state = .on
    window.pointerLocation = CGPoint(x: 90, y: 90)
    button.state = .off
    try await Task.sleep(for: .milliseconds(250))
    XCTAssertEqual(background.alphaValue, 0, accuracy: 0.01)
  }

  @MainActor
  func testActionsButtonMenuPresentationState() throws {
    class Delegate: HeaderViewDelegate {
      var presentedButton: ImageButton?

      func headerView(_ sender: HeaderView, moveTo date: Date) {}
      func headerView(_ sender: HeaderView, moveBy offset: Int) {}

      func headerView(_ sender: HeaderView, showActionsMenu sourceView: NSView) {
        presentedButton = sourceView as? ImageButton
        XCTAssertEqual(presentedButton?.state, .on)
      }
    }

    let header = HeaderView()
    let delegate = Delegate()
    header.delegate = delegate
    let button = try XCTUnwrap(header.subviews.compactMap { $0 as? ImageButton }.first {
      $0.accessibilityLabel() == Localized.UI.buttonTitleShowActions
    })

    XCTAssertTrue(button.sendAction(button.action, to: button.target))
    XCTAssertIdentical(delegate.presentedButton, button)
    XCTAssertEqual(button.state, .off)
  }

  @MainActor
  func testMenuImageVisibility() {
    let item = NSMenuItem(title: "Calendar")
    let image = NSImage()
    item.image = image
    item.ensureImageVisibility()

    XCTAssertIdentical(item.image, image)
    if #available(macOS 27.0, *) {
      XCTAssertEqual(item.preferredImageVisibility, .visible)
    }
  }

  func testExistenceOfImageTintColor() {
    testExistenceOfSelector(object: NSImage(), selector: "_setTintColor:")
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
