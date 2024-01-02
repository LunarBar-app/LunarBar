//
//  DateComponents+Extension.swift
//
//  Created by cyan on 12/23/23.
//

import Foundation

public extension DateComponents {
  var fourDigitsMonthDay: String {
    String(format: "%02d%02d", month ?? 0, day ?? 0)
  }
}
