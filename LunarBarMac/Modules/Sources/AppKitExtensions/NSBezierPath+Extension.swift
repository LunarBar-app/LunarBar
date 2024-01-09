//
//  NSBezierPath+Extension.swift
//
//  Created by cyan on 2024/1/8.
//

import AppKit

public extension NSBezierPath {
  /**
   Backward compatibility of `cgPath`.

   Mostly stole from https://stackoverflow.com/a/39385101 to be removed once we target macOS 15.
   */
  var toCGPath: CGPath {
    if #available(macOS 14.0, *) {
      return cgPath
    }

    let path = CGMutablePath()
    var points = [CGPoint](repeating: .zero, count: 3)

    for index in 0..<elementCount {
      let type = element(at: index, associatedPoints: &points)
      switch type {
      case .moveTo: path.move(to: points[0])
      case .lineTo: path.addLine(to: points[0])
      case .curveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
      case .closePath: path.closeSubpath()
      default: fatalError("Unknown element \(type)")
      }
    }

    return path
  }

  /**
   Backward compatibility of `NSBezierPath(cgPath:)`.

   Mostly stole from https://stackoverflow.com/a/49011112 to be removed once we target macOS 15.
   */
  static func from(cgPath: CGPath) -> NSBezierPath {
    if #available(macOS 14.0, *) {
      return NSBezierPath(cgPath: cgPath)
    }

    let path = NSBezierPath()
    cgPath.applyWithBlock { (pointer: UnsafePointer<CGPathElement>) in
      let element = pointer.pointee
      let points = element.points

      switch element.type {
      case .moveToPoint:
        path.move(to: points.pointee)
      case .addLineToPoint:
        path.line(to: points.pointee)
      case .addQuadCurveToPoint:
        let qp0 = path.currentPoint
        let qp1 = points.pointee
        let qp2 = points.successor().pointee
        let m = 2.0 / 3.0

        let cp1 = CGPoint(
          x: qp0.x + ((qp1.x - qp0.x) * m),
          y: qp0.y + ((qp1.y - qp0.y) * m)
        )

        let cp2 = CGPoint(
          x: qp2.x + ((qp1.x - qp2.x) * m),
          y: qp2.y + ((qp1.y - qp2.y) * m)
        )

        path.curve(to: qp2, controlPoint1: cp1, controlPoint2: cp2)
      case .addCurveToPoint:
        let cp1 = points.pointee
        let cp2 = points.advanced(by: 1).pointee
        let target = points.advanced(by: 2).pointee

        path.curve(
          to: points.advanced(by: 2).pointee,
          controlPoint1: cp1,
          controlPoint2: cp2
        )
      case .closeSubpath:
        path.close()
      @unknown default:
        fatalError("Unknown type \(element.type)")
      }
    }

    return path
  }

  /**
   Create bezier path from text with specified font.

   Mostly learned from https://github.com/jrturton/NSString-Glyphs converted to AppKit with Swift.
   */
  static func from(text: String, font: NSFont) -> NSBezierPath {
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

    let bezierPath = NSBezierPath.from(cgPath: letterPaths)

    // The path is upside down, transform the coordinate system
    bezierPath.transform(using: AffineTransform(scaleByX: 1.0, byY: -1.0))
    bezierPath.transform(using: AffineTransform(translationByX: 0, byY: letterPaths.boundingBox.height))

    return bezierPath
  }
}
