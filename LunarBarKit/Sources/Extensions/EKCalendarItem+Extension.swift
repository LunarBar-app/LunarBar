//
//  EKCalendarItem+Extension.swift
//
//  Created by cyan on 12/26/23.
//

import EventKit

public extension EKCalendarItem {
  var isAllDayItem: Bool {
    if let event = self as? EKEvent {
      return event.isAllDay
    }

    if let reminder = self as? EKReminder, let date = reminder.dueDateComponents {
      return date.hour == nil && date.minute == nil && date.second == nil
    }

    Logger.assertFail("Invalid item is returned")
    return false
  }

  var startOfItem: Date? {
    if let event = self as? EKEvent {
      return event.startDate
    }

    if let reminder = self as? EKReminder {
      return reminder.alarms?.compactMap { $0.absoluteDate }.min() ?? endOfItem
    }

    Logger.assertFail("Invalid item is returned")
    return nil
  }

  var endOfItem: Date? {
    if let event = self as? EKEvent {
      return event.endDate
    }

    if let reminder = self as? EKReminder, let components = reminder.dueDateComponents {
      return Calendar.solar.date(from: components)
    }

    Logger.assertFail("Invalid item is returned")
    return nil
  }

  /**
   Evaluate if the startDate and endDate of an event has overlaps with the input dates.

   Basically used to determine if an event should be displayed on a given date.
   */
  func overlaps(startOfDay: Date, endOfDay: Date) -> Bool {
    guard let startOfItem, let endOfItem else {
      Logger.log(.error, "Missing startDate and endDate from EKCalendarItem")
      return false
    }

    let rangeOfItem = startOfItem...endOfItem
    let rangeOfDay = startOfDay...endOfDay

    return rangeOfItem.overlaps(rangeOfDay)
  }
}

public extension [EKCalendarItem] {
  var oldestToNewest: [Self.Element] {
    sorted { lhs, rhs in
      (lhs.startOfItem ?? .distantPast) < (rhs.startOfItem ?? .distantPast)
    }
  }
}
