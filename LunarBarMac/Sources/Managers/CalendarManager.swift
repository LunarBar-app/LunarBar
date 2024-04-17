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

  func requestAccessIfNeeded() async {
    guard authorizationStatus == .notDetermined else {
      return
    }

    do {
      let result: Bool
      if #available(macOS 14.0, *) {
        result = try await eventStore.requestFullAccessToEvents()
      } else {
        result = try await eventStore.requestAccess(to: .event)
      }

      Logger.log(.info, "Result of the event access request: \(result)")
    } catch {
      Logger.log(.error, error.localizedDescription)
    }

    eventStore = EKEventStore()
  }

  func allCalendars() -> [EKCalendar] {
    guard hasReadAccess else {
      return []
    }

    return eventStore.calendars(for: .event)
  }

  func events(from startDate: Date, to endDate: Date, hiddenCalendars: Set<String>) -> [EKEvent] {
    guard hasReadAccess else {
      return []
    }

    let calendars = allCalendars().filter {
      !hiddenCalendars.contains($0.calendarIdentifier)
    }

    // EventKit searches all calendars when calendars is empty
    guard !calendars.isEmpty else {
      return []
    }

    let predicate = eventStore.predicateForEvents(
      withStart: startDate,
      end: endDate,
      calendars: calendars
    )

  #if DEBUG
    let perfStartTime = Date.timeIntervalSinceReferenceDate
  #endif

    let events = eventStore.events(matching: predicate)

  #if DEBUG
    let perfEndTime = Date.timeIntervalSinceReferenceDate
    Logger.log(.info, "Time used querying \(events.count) events: \(perfEndTime - perfStartTime)")
  #endif

    return events
  }

  func revealDateInCalendar(_ date: Date) {
    Task {
      // Requires Calendar access to locate the specified date
      await requestAccessIfNeeded()

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

  var hasReadAccess: Bool {
    if #available(macOS 14.0, *) {
      authorizationStatus == .fullAccess
    } else {
      authorizationStatus == .authorized
    }
  }

  var authorizationStatus: EKAuthorizationStatus {
    EKEventStore.authorizationStatus(for: .event)
  }
}
