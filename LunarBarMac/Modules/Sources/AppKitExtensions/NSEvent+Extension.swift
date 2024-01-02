//
//  NSEvent+Extension.swift
//
//
//  Created by cyan on 2024/1/2.
//

import AppKit

public extension NSEvent {
  var deviceIndependentFlags: NSEvent.ModifierFlags {
    modifierFlags.intersection(.deviceIndependentFlagsMask)
  }
}
