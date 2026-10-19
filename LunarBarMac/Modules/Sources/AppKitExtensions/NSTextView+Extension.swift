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
    fontSize: Double = 12
  ) -> NSTextView {
    let textView = NSTextView()
    textView.textContainer?.lineFragmentPadding = 0
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
    textView.frame = CGRect(origin: .zero, size: contentSize)
    textView.sizeToFit()
    return textView
  }
}
