//
//  DateRefreshTimer.swift
//  LunarBarMac
//
//  Created by cyan on 6/4/25.
//

import Foundation

/**
 A refresh timer that updates at intervals matching the granularity of a date format string.

 Automatically determines update frequency based on whether the format includes seconds, minutes, or hours,
 and schedules updates aligned to natural time boundaries (e.g., on the minute or hour).

 Assign a `dateFormat` string to start the timer. Set `dateFormat` to `nil` to stop it.
 */
final class DateRefreshTimer {
  var dateFormat: String? {
    didSet {
      stopTicking()
      startTicking()
    }
  }

  deinit {
    stopTicking()
  }

  init(onTick: @escaping (() -> Void)) {
    self.onTick = onTick
  }

  private var timer: Timer?
  private var onTick: (() -> Void)
}

// MARK: - Private

private extension DateRefreshTimer {
  func startTicking() {
    guard let dateFormat else {
      return
    }

    guard let granularity = Granularity.from(dateFormat: dateFormat) else {
      return
    }

    guard let fireDate = granularity.nextFireDate else {
      return
    }

    timer = Timer(
      fireAt: fireDate,
      interval: granularity.tickInterval,
      target: self,
      selector: #selector(handleTick),
      userInfo: nil,
      repeats: true
    )

    if let timer = timer {
      RunLoop.main.add(timer, forMode: .common)
    }

    onTick()
  }

  func stopTicking() {
    timer?.invalidate()
    timer = nil
  }

  @objc func handleTick() {
    onTick()
  }
}

private enum Granularity: CaseIterable {
  case second
  case minute
  case hour

  static func from(dateFormat: String) -> Self? {
    let formatter = DateFormatter()
    formatter.dateFormat = dateFormat
    formatter.locale = Locale(identifier: "en_US_POSIX") // For stable granularity detection

    let now = Date.now
    let text = formatter.string(from: now)

    // Find out the first granularity that produces different formatted dates
    let granularity = Self.allCases.first {
      let later = now.addingTimeInterval($0.tickInterval)
      return formatter.string(from: later) != text
    }

    if dateFormat.contains(/\{\{(.*?)\}\}/) {
      // Update at least hourly for dynamic expressions like {{expr}}
      return granularity ?? .hour
    }

    return granularity
  }

  var tickInterval: TimeInterval {
    switch self {
    case .second: return 1
    case .minute: return 60
    case .hour: return 3600
    }
  }

  var nextFireDate: Date? {
    Calendar.solar.nextDate(
      after: Date.now,
      matching: {
        switch self {
        case .second: return DateComponents(nanosecond: 0)
        case .minute: return DateComponents(second: 0)
        case .hour: return DateComponents(minute: 0, second: 0)
        }
      }(),
      matchingPolicy: .nextTime
    )
  }
}
