//
//  Bundle+Extension.swift
//
//  Created by cyan on 12/21/23.
//

import Foundation

public extension Bundle {
  var bundleName: String? {
    infoDictionary?[kCFBundleNameKey as String] as? String
  }

  var shortVersionString: String? {
    infoDictionary?["CFBundleShortVersionString"] as? String
  }
}
