//
//  String+Extension.swift
//
//  Created by cyan on 2024/11/14.
//

import Foundation

public extension String {
  var removingLeadingDigits: String {
    replacing(/^(\d+)/, with: "")
  }
}
