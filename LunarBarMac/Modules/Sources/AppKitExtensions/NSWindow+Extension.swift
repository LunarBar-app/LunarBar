//
//  NSWindow+Extension.swift
//
//  Created by cyan on 8/31/25.
//

import AppKit

public extension NSWindow {
  func fadeIn(duration: TimeInterval = 0.2) {
    alphaValue = 0
    NSAnimationContext.runAnimationGroup {
      $0.duration = duration
      animator().alphaValue = 1
    }
  }
}
