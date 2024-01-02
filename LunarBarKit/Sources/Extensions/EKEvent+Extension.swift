//
//  EKEvent+Extension.swift
//
//  Created by cyan on 12/26/23.
//

import EventKit

public extension EKEvent {
  /**
   Evaluate if the startDate and endDate of an event has overlaps with the input dates.

   Basically used to determine if an event should be displayed on a given date.
   */
  func overlaps(startOfDay: Date, endOfDay: Date) -> Bool {
    guard let startOfEvent = startDate, let endOfEvent = endDate else {
      Logger.log(.error, "Missing startDate and endDate from EKEvent")
      return false
    }

    let rangeOfEvent = startOfEvent...endOfEvent
    let rangeOfDay = startOfDay...endOfDay

    return rangeOfEvent.overlaps(rangeOfDay)
  }
}
