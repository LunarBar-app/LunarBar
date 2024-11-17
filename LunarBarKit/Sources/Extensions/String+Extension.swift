//
//  String+Extension.swift
//
//  Created by cyan on 11/14/24.
//

import Foundation

public extension String {
  var removingLeadingDigits: String {
    replacing(/^(\d+)/, with: "")
  }
}
