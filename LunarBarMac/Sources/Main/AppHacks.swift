//
//  Bundle+Extension.swift
//  LunarBarMac
//
//  Created by cyan on 6/13/25.
//

import Foundation

#if BUILD_WITH_SDK_26_OR_LATER

extension Bundle {
  @MainActor static let swizzleInfoDictionaryOnce: () = {
    guard #available(macOS 26.0, *), AppPreferences.General.classicInterface else {
      return
    }

    Bundle.exchangeInstanceMethods(
      originalSelector: #selector(getter: infoDictionary),
      swizzledSelector: #selector(getter: swizzled_infoDictionary)
    )
  }()

  @objc var swizzled_infoDictionary: [String: Any]? {
    var dict = self.swizzled_infoDictionary
    dict?["UIDesignRequiresCompatibility"] = true

    return dict
  }
}

#endif // BUILD_WITH_SDK_26_OR_LATER
