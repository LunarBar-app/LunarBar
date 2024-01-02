//
//  NSWorkspace+Extension.swift
//
//  Created by cyan on 2023/12/31.
//

import AppKit

public extension NSWorkspace {
  @discardableResult
  func safelyOpenURL(string: String) -> Bool {
    guard let url = URL(string: string) else {
      assertionFailure("Failed to create the URL: \(string)")
      return false
    }

    return open(url)
  }
}
