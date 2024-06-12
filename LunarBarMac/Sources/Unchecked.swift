//
//  Unchecked.swift
//  LunarBarMac
//
//  Created by cyan on 2024/4/17.
//

import AppKit
import EventKit

extension EKEventStore: @unchecked @retroactive Sendable {}
extension NSImage: @unchecked @retroactive Sendable {}
