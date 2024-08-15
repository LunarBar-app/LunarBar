//
//  CustomButton.swift
//
//  Created by cyan on 12/25/23.
//

import AppKit

/**
 Like UIButton in UIKit, supports custom highlight states.

 It has a configurable `hitTestInsets` to make the hitTest rect larger.
 */
public class CustomButton: NSButton {
  public var hitTestInsets: CGPoint = .zero

  private var trackingArea: NSTrackingArea?

  override public var isHighlighted: Bool {
    didSet {
      alphaValue = isHighlighted ? 0.6 : 1.0
    }
  }

  public init() {
    super.init(frame: .zero)
    title = ""
    imagePosition = .imageOnly
    isBordered = false
    focusRingType = .none
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func updateTrackingAreas() {
    super.updateTrackingAreas()

    if let trackingArea {
      removeTrackingArea(trackingArea)
    }

    trackingArea = {
      let trackingArea = NSTrackingArea(
        rect: bounds,
        options: [.activeAlways, .mouseEnteredAndExited],
        owner: self
      )

      addTrackingArea(trackingArea)
      return trackingArea
    }()
  }

  override public func mouseDown(with event: NSEvent) {
    isHighlighted = true
  }

  override public func mouseUp(with event: NSEvent) {
    isHighlighted = false

    if isMouseWithinBounds(event: event) {
      _ = sendAction(action, to: target)
    }
  }

  override public func mouseDragged(with event: NSEvent) {
    isHighlighted = isMouseWithinBounds(event: event)
  }

  override public func hitTest(_ point: CGPoint) -> NSView? {
    hitTestRect.contains(point) ? self : super.hitTest(point)
  }
}

// MARK: - Private

private extension CustomButton {
  var hitTestRect: CGRect {
    frame.insetBy(dx: hitTestInsets.x, dy: hitTestInsets.y)
  }

  func isMouseWithinBounds(event: NSEvent) -> Bool {
    let point = convert(event.locationInWindow, from: nil)
    let bounds = CGRect(origin: hitTestInsets, size: hitTestRect.size)
    return isMousePoint(point, in: bounds)
  }
}
