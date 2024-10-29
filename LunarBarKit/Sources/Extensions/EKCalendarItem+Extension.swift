//
//  EKCalendarItem+Extension.swift
//
//  Created by cyan on 12/26/23.
//

import EventKit

public extension EKCalendarItem {
  /**
   Evaluate if the startDate and endDate of an event has overlaps with the input dates.

   Basically used to determine if an event should be displayed on a given date.
   */
  func overlaps(startOfDay: Date, endOfDay: Date) -> Bool {
    guard let startOfEvent, let endOfEvent else {
      Logger.log(.error, "Missing startDate and endDate from EKCalendarItem")
      return false
    }

    let rangeOfEvent = startOfEvent...endOfEvent
    let rangeOfDay = startOfDay...endOfDay

    return rangeOfEvent.overlaps(rangeOfDay)
  }
}

public extension [EKCalendarItem] {
  var oldestToNewest: [Self.Element] {
    sorted { lhs, rhs in
      (lhs.startOfEvent ?? .distantPast) < (rhs.startOfEvent ?? .distantPast)
    }
  }
}

// MARK: - Private

private extension EKCalendarItem {
  var startOfEvent: Date? {
    if let event = self as? EKEvent {
      return event.startDate
    }

    if let reminder = self as? EKReminder {
      return reminder.alarms?.compactMap { $0.absoluteDate }.min() ?? endOfEvent
    }

    Logger.assertFail("Invalid item is returned")
    return nil
  }

  var endOfEvent: Date? {
    if let event = self as? EKEvent {
      return event.endDate
    }

    if let reminder = self as? EKReminder, let components = reminder.dueDateComponents {
      return Calendar.solar.date(from: components)
    }

    Logger.assertFail("Invalid item is returned")
    return nil
  }
}
