//
//  CalendarManager.swift
//  LunarBarMac
//
//  Created by cyan on 12/24/23.
//

import Foundation
import EventKit
import LunarBarKit

/**
 For the native Calendar app.
 */
@MainActor
final class CalendarManager {
  static let `default` = CalendarManager()

  private var eventStore = EKEventStore()

  func authorizationStatus(for type: EKEntityType) -> EKAuthorizationStatus {
    EKEventStore.authorizationStatus(for: type)
  }

  func requestAccessIfNeeded(type: EKEntityType) async {
    guard authorizationStatus(for: type) == .notDetermined else {
      return
    }

    let request = type == .reminder ? eventStore.requestFullAccessToReminders : eventStore.requestFullAccessToEvents
    Logger.assert(type == .event || type == .reminder, "Invalid type: \(type) of access to request for")

    do {
      let result = try await request()
      Logger.log(.info, "Result of the event access request: \(result)")
    } catch {
      Logger.log(.error, error.localizedDescription)
    }

    eventStore = EKEventStore()
  }

  func allCalendars() -> [EKCalendar] {
    var calendars = [EKCalendar]()
    if hasReadAccess(for: .event) {
      calendars.append(contentsOf: eventStore.calendars(for: .event))
    }

    if hasReadAccess(for: .reminder) {
      calendars.append(contentsOf: eventStore.calendars(for: .reminder))
    }

    return calendars
  }

  func items(for type: EKEntityType, from startDate: Date, to endDate: Date) async throws -> [EKCalendarItem] {
    guard hasReadAccess(for: type) else {
      return []
    }

    let hidden = AppPreferences.Calendar.hiddenCalendars
    let calendars = allCalendars().filter { !hidden.contains($0.calendarIdentifier) }

    // EventKit searches all calendars when calendars is empty
    guard !calendars.isEmpty else {
      return []
    }

  #if DEBUG
    let perfStartTime = Date.timeIntervalSinceReferenceDate
  #endif

    let events = try await {
      switch type {
      case .event:
        return try await eventStore.events(from: startDate, to: endDate, calendars: calendars)
      case .reminder:
        return try await eventStore.reminders(from: startDate, to: endDate, calendars: calendars)
      default:
        Logger.assertFail("Invalid type: \(type) of items to fetch for")
        return []
      }
    }()

  #if DEBUG
    let perfEndTime = Date.timeIntervalSinceReferenceDate
    Logger.log(.info, "Time used querying \(events.count) events: \(perfEndTime - perfStartTime)")
  #endif

    return events
  }

  func revealDateInCalendar(_ date: Date) {
    Task {
      // Requires Calendar access to locate the specified date
      await requestAccessIfNeeded(type: .event)

      let source =
      """
      tell application "Calendar"
        activate
        switch view to day view
        view calendar at date "\(Constants.scriptingDateFormatter.string(from: date))"
      end tell
      """

      DispatchQueue.global(qos: .userInitiated).async {
        var error: NSDictionary?
        let script = NSAppleScript(source: source)
        script?.executeAndReturnError(&error)

        if let error {
          Logger.log(.error, String(describing: error))
        } else {
        #if DEBUG
          Logger.log(.debug, "Successfully revealed the date")
        #endif
        }
      }
    }
  }

  private init() {}
}

// MARK: - Private

private extension CalendarManager {
  enum Constants {
    static let scriptingDateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateStyle = .full
      formatter.timeStyle = .none

      return formatter
    }()
  }

  func hasReadAccess(for type: EKEntityType) -> Bool {
    authorizationStatus(for: type) == .fullAccess
  }
}
