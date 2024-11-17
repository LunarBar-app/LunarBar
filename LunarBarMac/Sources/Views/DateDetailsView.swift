//
//  DateDetailsView.swift
//  LunarBarMac
//
//  Created by cyan on 2024/11/16.
//

import AppKit
import SwiftUI
import EventKit
import LunarBarKit

/**
 Details view to show date info and Calendar events.
 */
struct DateDetailsView: View {
  private let title: String
  private let events: [EKCalendarItem]

  var body: some View {
    VStack(spacing: 0) {
      Text(title)
        .font(.system(size: Constants.fontSize, weight: .medium))
        .frame(height: Constants.rowHeight)
        .padding(.horizontal, Constants.smallPadding)

      if !events.isEmpty {
        Divider()
      }

      ForEach(0..<events.count, id: \.self) { index in
        let event = events[index]
        HStack {
          Circle()
            .fill(Color(event.calendar.color))
            .frame(width: Constants.dotSize, height: Constants.dotSize)
          Text(event.title)
            .font(.system(size: Constants.fontSize))
            .frame(maxWidth: .infinity, alignment: .leading)
            .strikethrough(event.isCompletedItem)
          Spacer(minLength: Constants.smallPadding * 3)
          Text(event.labelOfDates)
            .font(.system(size: Constants.fontSize))
            .frame(alignment: .trailing)
            .fixedSize()
        }
        .frame(height: Constants.rowHeight)

        if index < events.count - 1 {
          Divider()
        }
      }
      .padding(.horizontal, Constants.smallPadding)
    }
  }

  static func createPopover(title: String, events: [EKCalendarItem]) -> NSPopover {
    let popover = NSPopover()
    popover.behavior = .applicationDefined
    popover.animates = false
    popover.contentViewController = DateDetailsHostVC(rootView: Self(
      title: title,
      events: events
    ))

    return popover
  }
}

// MARK: - Private

private final class DateDetailsHostVC: NSViewController {
  private let contentView: NSView

  init(rootView: DateDetailsView) {
    self.contentView = NSHostingView(rootView: rootView)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    view = NSView()
    view.addSubview(contentView)

    contentView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      contentView.topAnchor.constraint(equalTo: view.topAnchor),
      contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  override func viewWillAppear() {
    super.viewWillAppear()
    material = AppPreferences.Accessibility.popoverMaterial
  }

  override func viewDidLayout() {
    super.viewDidLayout()

    var contentSize = contentView.fittingSize
    contentSize.width = min(Constants.maximumWidth, contentSize.width)
    preferredContentSize = contentSize
  }
}

private extension EKCalendarItem {
  var isCompletedItem: Bool {
    (self as? EKReminder)?.isCompleted == true
  }

  var labelOfDates: String {
    guard !isAllDayItem else {
      // all-day
      return Localized.Calendar.allDayLabel
    }

    guard let startOfItem, let endOfItem else {
      Logger.assertFail("Missing start or end date")
      return ""
    }

    if startOfItem == endOfItem {
      // 12:00
      return Constants.dateFormatter.string(from: startOfItem)
    }

    // 12:00 - 13:30
    return "\(Constants.dateFormatter.string(from: startOfItem)) - \(Constants.dateFormatter.string(from: endOfItem))"
  }
}

private enum Constants {
  static let fontSize: Double = 12
  static let dotSize: Double = 6
  static let rowHeight: Double = 28
  static let smallPadding: Double = 8
  static let maximumWidth: Double = 280
  static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter
  }()
}
