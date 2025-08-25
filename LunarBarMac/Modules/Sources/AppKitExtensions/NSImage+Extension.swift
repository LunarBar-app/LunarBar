//
//  NSImage+Extension.swift
//
//  Created by cyan on 1/15/23.
//

import AppKit

public extension NSImage {
  var asTemplate: NSImage {
    self.isTemplate = true
    return self
  }

  static func with(
    symbolName: String,
    pointSize: Double,
    weight: NSFont.Weight = .regular,
    accessibilityLabel: String? = nil
  ) -> NSImage {
    let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityLabel)
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)

    guard let image = image?.withSymbolConfiguration(config) else {
      assertionFailure("Failed to create image with symbol \"\(symbolName)\"")
      return NSImage()
    }

    return image
  }

  static func with(text: String, font: NSFont) -> NSImage {
    let attributes: [NSAttributedString.Key: Any] = [.font: font]
    let string = NSAttributedString(string: text, attributes: attributes)
    let size = string.size()

    guard let bitmap = NSBitmapImageRep(size: size) else {
      // Fallback, not rendering scale aware
      return NSImage(size: size, flipped: false) { _ in
        string.draw(at: .zero)
        return true
      }
    }

    let context = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context

    string.draw(at: .zero)
    NSGraphicsContext.restoreGraphicsState()

    let image = NSImage(size: size)
    image.addRepresentation(bitmap)
    return image
  }

  @MainActor
  static func with(
    cellColor: NSColor,
    borderColor: NSColor? = nil,
    borderWidth: Double,
    size: CGSize,
    cornerRadius: Double
  ) -> NSImage? {
    let view = NSView(frame: CGRect(origin: .zero, size: size))
    view.layerBackgroundColor = cellColor
    view.layer?.cornerCurve = .continuous
    view.layer?.cornerRadius = cornerRadius

    if let borderColor {
      view.layer?.masksToBounds = true
      view.layer?.borderWidth = borderWidth
      view.layer?.borderColor = borderColor.cgColor
    }

    return view.snapshotImage
  }

  func resized(with size: CGSize) -> NSImage {
    let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    guard let representation = bestRepresentation(for: frame, context: nil, hints: nil) else {
      return self
    }

    let image = NSImage(size: size, flipped: false) { _ in
      representation.draw(in: frame)
    }

    return isTemplate ? image.asTemplate : image
  }

  func setTintColor(_ tintColor: NSColor?) {
    guard let tintColor, responds(to: sel_getUid("_setTintColor:")) else {
      return assertionFailure("Missing _setTintColor(_:) to change the tint color")
    }

    perform(sel_getUid("_setTintColor:"), with: tintColor)
  }
}
