//
//  NSObject+Extension.swift
//
//  Created by cyan on 6/13/25.

import Foundation

public extension NSObject {
  /// Exchange two instance methods during runtime.
  static func exchangeInstanceMethods(originalSelector: Selector, swizzledSelector: Selector) {
    exchangeImplementations(
      originalSelector: originalSelector,
      originalMethod: class_getInstanceMethod(Self.self, originalSelector),
      swizzledSelector: swizzledSelector,
      swizzledMethod: class_getInstanceMethod(Self.self, swizzledSelector)
    )
  }
}

// MARK: - Private

private extension NSObject {
  /// Exchange two implementations during runtime.
  static func exchangeImplementations(
    originalSelector: Selector,
    originalMethod: Method?,
    swizzledSelector: Selector,
    swizzledMethod: Method?
  ) {
    let type = Self.self
    guard let originalMethod else {
      Logger.assertFail("Failed to swizzle: \(type), missing original method")
      return
    }

    guard let swizzledMethod else {
      Logger.assertFail("Failed to swizzle: \(type), missing swizzled method")
      return
    }

    if class_addMethod(type, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod)) {
      class_replaceMethod(type, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
    } else {
      method_exchangeImplementations(originalMethod, swizzledMethod)
    }
  }
}
