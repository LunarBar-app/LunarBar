//
//  NSTextView+Extension.swift
//
//  Created by cyan on 6/18/25.
//

import AppKit

public extension NSTextView {
  static func markdownView(
    with markdown: String,
    contentWidth: Double,
    contentPadding: Double = 0,
    fontSize: Double = 11
  ) -> NSTextView {
    let textView = NSTextView()
    textView.font = .systemFont(ofSize: fontSize)
    textView.drawsBackground = false
    textView.isEditable = false

    if let data = markdown.data(using: .utf8), let string = try? NSAttributedString(markdown: data, options: .init(allowsExtendedAttributes: true, interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
      textView.textStorage?.setAttributedString(string)
    } else {
      textView.string = markdown
    }

    textView.textStorage?.addAttribute(
      .foregroundColor,
      value: NSColor.labelColor,
      range: NSRange(location: 0, length: textView.attributedString().length)
    )

    let contentSize = CGSize(width: contentWidth, height: 0)
    textView.frame = CGRect(origin: CGPoint(x: contentPadding, y: 0), size: contentSize)
    textView.sizeToFit()
    return textView
  }
}
