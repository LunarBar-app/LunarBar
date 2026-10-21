//
//  CustomButton.swift
//
//  Created by cyan on 12/25/23.
//

import AppKit

/**
 A button that dims while pressed and supports mouse-hover callbacks.

 AppKit handles activation for mouse, touch, keyboard, and accessibility input.
 */
public class CustomButton: NSButton {
  public var hitTestInsets: CGPoint = .zero
  public var onMouseHover: ((_ isHovered: Bool) -> Void)?

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

    addTarget(
      self,
      action: #selector(trackingInside),
      for: [.trackingBegan, .trackingEntered]
    )

    addTarget(
      self,
      action: #selector(trackingOutside),
      for: .trackingExited
    )

    addTarget(
      self,
      action: #selector(trackingEnded),
      for: [.trackingEndedInside, .trackingEndedOutside, .trackingCancelled]
    )
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
        // The rect is slightly smaller to prevent two adjacent views from being hovered simultaneously
        rect: hoverRect,
        options: [.activeAlways, .mouseEnteredAndExited],
        owner: self
      )

      addTrackingArea(trackingArea)
      return trackingArea
    }()
  }

  override public func mouseEntered(with event: NSEvent) {
    super.mouseEntered(with: event)
    onMouseHover?(true)
  }

  override public func mouseExited(with event: NSEvent) {
    super.mouseExited(with: event)
    onMouseHover?(false)
  }

  override public func sendAction(_ action: Selector?, to target: Any?) -> Bool {
    // Clear the selected and pressed appearance before the action opens a menu or dialog
    state = .off
    isHighlighted = false

    return super.sendAction(action, to: target)
  }

  override public func hitTest(_ point: CGPoint) -> NSView? {
    hitTestRect.contains(point) ? self : super.hitTest(point)
  }
}

// MARK: - Private

private extension CustomButton {
  var hoverRect: CGRect {
    bounds.insetBy(dx: 0.5, dy: 0.5)
  }

  var hitTestRect: CGRect {
    frame.insetBy(dx: hitTestInsets.x, dy: hitTestInsets.y)
  }

  @objc func trackingInside() {
    isHighlighted = true
  }

  @objc func trackingOutside() {
    isHighlighted = false
    onMouseHover?(false)
  }

  @objc func trackingEnded() {
    isHighlighted = false

    guard let window, window.isVisible, !isHiddenOrHasHiddenAncestor else {
      onMouseHover?(false)
      return
    }

    // Restore hover from the mouse position, not the touch or release location
    let point = convert(window.mouseLocationOutsideOfEventStream, from: nil)
    onMouseHover?(isMousePoint(point, in: hoverRect))
  }
}
