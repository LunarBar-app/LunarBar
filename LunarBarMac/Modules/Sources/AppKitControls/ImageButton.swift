//
//  ImageButton.swift
//
//  Created by cyan on 12/21/23.
//

import AppKit
import AppKitExtensions

/**
 Button with an image as its content.

 Its hitTest rect is larger than it looks, since generally image buttons are too small.
 */
public final class ImageButton: CustomButton {
  private let highlightView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.alphaValue = 0
    view.layer?.cornerCurve = .continuous

    return view
  }()

  // The color should be lazily calculated
  private let highlightColorProvider: () -> NSColor

  public init(
    symbolName: String,
    sizeDelta: Double,
    cornerRadius: Double,
    highlightColorProvider: @escaping (() -> NSColor),
    tintColor: NSColor? = nil,
    accessibilityLabel: String
  ) {
    self.highlightColorProvider = highlightColorProvider
    super.init()

    contentTintColor = tintColor
    toolTip = accessibilityLabel

    highlightView.layer?.cornerRadius = cornerRadius
    highlightView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(highlightView)

    let iconSize = Constants.iconSize + sizeDelta
    let iconImage = NSImage.with(symbolName: symbolName, pointSize: iconSize, weight: .semibold)
    iconImage.setTintColor(tintColor)

    let iconView = NSImageView(image: iconImage)
    iconView.sizeToFit()
    iconView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(iconView)

    NSLayoutConstraint.activate([
      iconView.leadingAnchor.constraint(equalTo: leadingAnchor),
      iconView.trailingAnchor.constraint(equalTo: trailingAnchor),
      iconView.topAnchor.constraint(equalTo: topAnchor),
      iconView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    let buttonSize = Constants.buttonSize + sizeDelta
    setFrameSize(CGSize(width: buttonSize, height: buttonSize))

    onMouseHover = { [weak self] isHovered in
      self?.highlightView.setAlphaValue(isHovered ? 1 : 0)
    }
  }

  override public func layout() {
    super.layout()

    highlightView.layerBackgroundColor = highlightColorProvider()
    highlightView.frame = bounds.insetBy(
      dx: Constants.highlightViewInset,
      dy: Constants.highlightViewInset
    )
  }

  override public func accessibilityLabel() -> String? {
    toolTip
  }
}

// MARK: - Private

private extension ImageButton {
  enum Constants {
    static let iconSize: Double = 14
    static let buttonSize: Double = 27
    static let highlightViewInset: Double = 2
  }
}
