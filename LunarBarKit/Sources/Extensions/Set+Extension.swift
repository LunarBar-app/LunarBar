//
//  Set+Extension.swift
//
//  Created by cyan on 12/31/23.
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
