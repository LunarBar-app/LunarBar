//
//  SMAppService+Extension.swift
//
//  Created by cyan on 12/25/23.
//

import ServiceManagement

public extension SMAppService {
  var isEnabled: Bool {
    status == .enabled
  }

  func toggle() throws {
    isEnabled ? try unregister() : try register()
  }
}
