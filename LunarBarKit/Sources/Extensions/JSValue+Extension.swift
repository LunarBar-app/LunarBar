//
//  JSValue+Extension.swift
//
//  Created by cyan on 3/22/26.
//

import Foundation
import JavaScriptCore

public extension JSValue {
  func safelyToDate(fallback: Date = .now) -> Date {
    guard isDate && !isNull && !isUndefined else {
      return fallback
    }

    return toDate() ?? fallback
  }
}
