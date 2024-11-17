//
//  NSEvent+Extension.swift
//
//
//  Created by cyan on 1/2/24.
//

import AppKit

public extension NSEvent {
  var deviceIndependentFlags: NSEvent.ModifierFlags {
    modifierFlags.intersection(.deviceIndependentFlagsMask)
  }
}
