//
//  RuntimeTests.swift
//  LunarBarMacTests
//
//  Created by cyan on 11/15/24.
//

import XCTest
@testable import AppKitControls
@testable import LunarBar

final class RuntimeTests: XCTestCase {
  @MainActor
  func testCustomButtonNativeTracking() async throws {
    let button = TrackingButton()
    button.frame = CGRect(x: 20, y: 20, width: 40, height: 40)

    let root = NSView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    root.addSubview(button)

    let window = makeButtonTestWindow(contentView: root)
    defer { window.close() }

    var actions = 0
    button.addAction {
      XCTAssertFalse(button.isHighlighted)
      XCTAssertEqual(button.alphaValue, 1)
      actions += 1
    }

    let inside = CGPoint(x: 40, y: 40)
    let outside = CGPoint(x: 90, y: 90)

    var isHovered = false
    button.onMouseHover = { isHovered = $0 }
    button.onMouseHover?(true)
    window.pointerLocation = inside

    try await sendMouseEvents([
      (.leftMouseDown, inside),
      (.leftMouseDragged, outside),
      (.leftMouseDragged, inside),
      (.leftMouseUp, inside),
    ], to: window)

    XCTAssertEqual(actions, 1)
    XCTAssertTrue(button.highlightedAlphas.contains(0.6))
    XCTAssertFalse(button.isHighlighted)
    XCTAssertEqual(button.alphaValue, 1)
    XCTAssertTrue(isHovered)

    window.pointerLocation = outside
    try await sendMouseEvents([
      (.leftMouseDown, inside),
      (.leftMouseDragged, outside),
      (.leftMouseUp, outside),
    ], to: window)

    XCTAssertEqual(actions, 1)
    XCTAssertFalse(button.isHighlighted)
    XCTAssertFalse(isHovered)

    // An inside activation must not imply hover when the mouse is elsewhere
    try await sendMouseEvents([(.leftMouseDown, inside), (.leftMouseUp, inside)], to: window)
    XCTAssertEqual(actions, 2)
    XCTAssertFalse(isHovered)

    button.isEnabled = false
    try await sendMouseEvents([(.leftMouseDown, inside), (.leftMouseUp, inside)], to: window)
    XCTAssertEqual(actions, 2)
    XCTAssertFalse(button.isHighlighted)

    button.isEnabled = true
    button.performClick(nil)
    XCTAssertEqual(actions, 3)

    _ = button.accessibilityPerformPress()
    XCTAssertEqual(actions, 4)
    XCTAssertFalse(button.isHighlighted)
    XCTAssertEqual(button.alphaValue, 1)
  }

  @MainActor
  func testImageButtonMouseExitAfterClick() async throws {
    let button = ImageButton(
      symbolName: "circle",
      sizeDelta: 1,
      cornerRadius: 4,
      highlightColorProvider: { .selectedControlColor },
      accessibilityLabel: "Actions"
    )

    let background = try XCTUnwrap(button.subviews.first)
    button.frame.origin = CGPoint(x: 20, y: 20)

    let root = NSView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    root.addSubview(button)

    let window = makeButtonTestWindow(contentView: root)
    defer { window.close() }

    button.addAction {}
    button.onMouseHover?(true)

    let point = CGPoint(x: 30, y: 30)
    try await sendMouseEvents([(.leftMouseDown, point), (.leftMouseUp, point)], to: window)
    button.onMouseHover?(false)

    try await Task.sleep(for: .milliseconds(250))
    XCTAssertFalse(button.isHighlighted)
    XCTAssertEqual(button.state, .off)
    XCTAssertEqual(background.alphaValue, 0, accuracy: 0.01)
  }

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
  @MainActor
  private final class TrackingWindow: NSWindow {
    var pointerLocation = CGPoint.zero

    override var mouseLocationOutsideOfEventStream: NSPoint {
      pointerLocation
    }
  }

  @MainActor
  private final class TrackingButton: CustomButton {
    var highlightedAlphas = [CGFloat]()

    override var isHighlighted: Bool {
      didSet {
        if isHighlighted {
          highlightedAlphas.append(alphaValue)
        }
      }
    }
  }

  @MainActor
  private func makeButtonTestWindow(contentView: NSView) -> TrackingWindow {
    let window = TrackingWindow(
      contentRect: contentView.bounds,
      styleMask: .borderless,
      backing: .buffered,
      defer: false
    )

    window.isReleasedWhenClosed = false
    window.contentView = contentView
    window.orderFront(nil)
    return window
  }

  @MainActor
  func makeMouseEvent(_ type: NSEvent.EventType, at point: CGPoint, to window: NSWindow) throws -> NSEvent {
    try XCTUnwrap(NSEvent.mouseEvent(
      with: type,
      location: point,
      modifierFlags: [],
      timestamp: ProcessInfo.processInfo.systemUptime,
      windowNumber: window.windowNumber,
      context: nil,
      eventNumber: 0,
      clickCount: 1,
      pressure: type == .leftMouseUp ? 0 : 1
    ))
  }

  @MainActor
  func sendMouseEvents(_ events: [(NSEvent.EventType, CGPoint)], to window: NSWindow) async throws {
    for (type, point) in events {
      NSApp.postEvent(try makeMouseEvent(type, at: point, to: window), atStart: false)
    }

    try await Task.sleep(for: .milliseconds(150))
  }

  func testExistenceOfSelector(object: AnyObject, selector: String) {
    XCTAssert(object.responds(to: sel_getUid(selector)), "Missing \(selector) in \(object.self)")
  }
}
