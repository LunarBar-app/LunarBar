//
//  ScalableView.swift
//  LunarBarMac
//
//  Created by cyan on 11/20/24.
//

import AppKit

/**
 Scalable wrapper to easily scale subviews.

 Views and constraints must be added to the `container` to be scalable.
 */
final class ScalableView: NSScrollView {
  let container = NSView()

  init() {
    super.init(frame: .zero)
    drawsBackground = false
    backgroundColor = .clear

    documentView = container
    documentView?.translatesAutoresizingMaskIntoConstraints = false

    hasVerticalScroller = false
    hasHorizontalScroller = false
    verticalScrollElasticity = .none
    horizontalScrollElasticity = .none
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func scrollWheel(with event: NSEvent) {
    // no-op
  }
}

extension NSView {
  func addScalableView(_ scalableView: ScalableView, scale: Double) {
    let wrapper = scalableView
    let container = scalableView.container

    wrapper.magnification = scale
    wrapper.translatesAutoresizingMaskIntoConstraints = false
    addSubview(wrapper)

    NSLayoutConstraint.activate([
      // The wrapper is always full size
      wrapper.leadingAnchor.constraint(equalTo: leadingAnchor),
      wrapper.trailingAnchor.constraint(equalTo: trailingAnchor),
      wrapper.topAnchor.constraint(equalTo: topAnchor),
      wrapper.bottomAnchor.constraint(equalTo: bottomAnchor),
      // The container is scaled and possibly clipped
      container.leadingAnchor.constraint(equalTo: leadingAnchor),
      container.bottomAnchor.constraint(equalTo: bottomAnchor),
      container.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0 / scale),
      container.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1.0 / scale),
    ])
  }
}
