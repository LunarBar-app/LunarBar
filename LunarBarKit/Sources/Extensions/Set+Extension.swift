//
//  Set+Extension.swift
//
//  Created by cyan on 2023/12/31.
//

import Foundation

public extension Set {
  mutating func toggle(_ member: Element) {
    if contains(member) {
      remove(member)
    } else {
      insert(member)
    }
  }
}
