//
//  NSBezierPath+Extension.swift
//
//  Created by cyan on 2024/1/8.
//

import AppKit

public extension NSBezierPath {
  /**
   Create bezier path from text with specified font.

   Mostly learned from https://github.com/jrturton/NSString-Glyphs converted to AppKit with Swift.
   */
  static func from(text: String, font: NSFont, isFlipped: Bool = false) -> NSBezierPath {
    let coreTextFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
    let attributedText = NSAttributedString(string: text, attributes: [.font: coreTextFont])

    let glyphRuns = CTLineGetGlyphRuns(CTLineCreateWithAttributedString(attributedText)) as? [CTRun]
    let letterPaths = CGMutablePath()

    glyphRuns?.forEach { run in
      for index in 0..<CTRunGetGlyphCount(run) {
        let range = CFRangeMake(index, 1)
        var glyphs = [CGGlyph](repeating: 0, count: range.length)
        var position = CGPoint()

        CTRunGetGlyphs(run, range, &glyphs)
        CTRunGetPositions(run, range, &position)

        glyphs.compactMap { CTFontCreatePathForGlyph(coreTextFont, $0, nil) }.forEach {
          let transform = CGAffineTransform(translationX: position.x, y: position.y)
          letterPaths.addPath($0, transform: transform)
        }
      }
    }

    let bezierPath = NSBezierPath(cgPath: letterPaths)

    // If the path is upside down, transform the coordinate system
    if isFlipped {
      bezierPath.transform(using: AffineTransform(scaleByX: 1.0, byY: -1.0))
      bezierPath.transform(using: AffineTransform(translationByX: 0, byY: letterPaths.boundingBox.height))
    }

    return bezierPath
  }
}
