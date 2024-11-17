//
//  Unchecked.swift
//  LunarBarMac
//
//  Created by cyan on 4/17/24.
//

import AppKit
import EventKit

extension EKCalendar: @unchecked @retroactive Sendable {}
extension EKEventStore: @unchecked @retroactive Sendable {}
extension NSImage: @unchecked @retroactive Sendable {}
