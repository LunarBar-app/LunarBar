//
//  NSStackView+Extension.swift
//
//  Created by cyan on 12/27/23.
//

import AppKit

public extension NSStackView {
  func removeArrangedSubviews() {
    arrangedSubviews.forEach {
      removeArrangedSubview($0)
      NSLayoutConstraint.deactivate($0.constraints)
      $0.removeFromSuperview()
    }
  }
}
