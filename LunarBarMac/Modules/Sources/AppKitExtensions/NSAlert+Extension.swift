//
//  NSAlert+Extension.swift
//
//  Created by cyan on 12/3/23.
//

import AppKit

public extension NSAlert {
  /**
   Drop-in replacement for `informativeText` with Markdown support.
   */
  var markdownBody: String? {
    get {
      objc_getAssociatedObject(self, &AssociatedObjects.markdownBody) as? String
    }
    set {
      objc_setAssociatedObject(
        self,
        &AssociatedObjects.markdownBody,
        newValue,
        objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )

      updateAccessoryView(with: newValue ?? "")
    }
  }
}

// MARK: - Private

private extension NSAlert {
  private enum AssociatedObjects {
    @MainActor static var markdownBody: UInt8 = 0
  }

  private enum Constants {
    static let contentWidth: Double = 220
    static let contentPadding: Double = 10
  }

  func updateAccessoryView(with markdown: String) {
    let textView = NSTextView.markdownView(
      with: markdown,
      contentWidth: Constants.contentWidth,
      contentPadding: Constants.contentPadding
    )

    let wrapper = NSView(frame: textView.frame.insetBy(dx: -Constants.contentPadding, dy: 0))
    wrapper.addSubview(textView)
    accessoryView = wrapper
    layout()
  }
}
