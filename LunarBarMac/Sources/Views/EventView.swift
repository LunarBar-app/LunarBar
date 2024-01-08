//
//  EventView.swift
//  LunarBarMac
//
//  Created by cyan on 12/24/23.
//

import AppKit
import EventKit

/**
 UI component to draw Calendar events as dots.
 */
final class EventView: NSStackView {
  init() {
    super.init(frame: .zero)
    spacing = Constants.spacing
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func updateEvents(_ events: [EKEvent]) {
    isHidden = events.isEmpty
    removeArrangedSubviews()

    // Only show up to three dots due to limited space
    events.prefix(Constants.eventLimit).forEach {
      let dotView = DotView()
      dotView.layerBackgroundColor = $0.calendar?.color ?? Colors.controlAccent
      addArrangedSubview(dotView)
    }
  }
}

// MARK: - Private

private extension EventView {
  enum Constants {
    static let spacing: Double = 2
    static let eventLimit = 3
  }
}

private class DotView: NSView {
  enum Constants {
    static let dotSize: Double = 4
  }

  init() {
    super.init(frame: .zero)
    wantsLayer = true
    clipsToBounds = true
    layer?.cornerRadius = Constants.dotSize * 0.5
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: CGSize {
    CGSize(width: Constants.dotSize, height: Constants.dotSize)
  }
}
