//
//  NSWindow+Extension.swift
//
//  Created by cyan on 8/31/25.
//

import AppKit

public extension NSWindow {
  func fadeIn(duration: TimeInterval = 0.2, completion: (@Sendable () -> Void)? = nil) {
    fade(from: 0, to: 1, completion: completion)
  }

  func fadeOut(duration: TimeInterval = 0.2, completion: (@Sendable () -> Void)? = nil) {
    fade(from: 1, to: 0, completion: completion)
  }
}

// MARK: - Private

private extension NSWindow {
  func fade(
    from startAlpha: Double,
    to endAlpha: Double,
    duration: TimeInterval = 0.2,
    completion: (@Sendable () -> Void)? = nil
  ) {
    alphaValue = startAlpha
    NSAnimationContext.runAnimationGroup { context in
      context.duration = duration
      animator().alphaValue = endAlpha
    } completionHandler: {
      completion?()
    }
  }
}
