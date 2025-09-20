//
//  DateDetailsView.swift
//  LunarBarMac
//
//  Created by cyan on 2024/11/16.
//

import AppKit
import AppKitExtensions
import SwiftUI
import EventKit
import LunarBarKit

/**
 Details view to show date info and Calendar events.
 */
struct DateDetailsView: View {
  private let title: String
  private let events: [EKCalendarItem]
  private let lineWidth: Double

  var body: some View {
    let scale = AppPreferences.General.contentScale.rawValue
    VStack(spacing: 0) {
      Text(title)
        .font(font(weight: .medium, scale: scale))
        .frame(height: Constants.rowHeight * scale)
        .padding(.horizontal, Constants.smallPadding * scale)

      if !events.isEmpty {
        Divider()
      }

      ForEach(0..<min(events.count, Constants.maximumRows), id: \.self) { index in
        let event = events[index]
        let color = event.calendar.color ?? Colors.controlAccent

        HStack {
          Circle()
            .fill(Color(color))
            .strokeBorder(Color(color.darkerColor()), lineWidth: lineWidth)
            .frame(width: Constants.dotSize * scale, height: Constants.dotSize * scale)
          Text(event.title)
            .font(font(weight: .regular, scale: scale))
            .frame(maxWidth: .infinity, alignment: .leading)
            .strikethrough(event.isCompletedItem)
          Spacer(minLength: Constants.largePadding * scale)
          Text(event.labelOfDates)
            .font(font(weight: .regular, scale: scale))
            .frame(alignment: .trailing)
            .fixedSize()
        }
        .frame(height: Constants.rowHeight * scale)

        if index < events.count - 1 {
          Divider()
        }
      }
      .padding(.horizontal, Constants.smallPadding * scale)

      // Indicator for more events
      if events.count > Constants.maximumRows {
        Image(systemName: "ellipsis")
          .foregroundStyle(.secondary)
          .padding(.vertical, 2) // Tiny element, no need to scale
      }
    }
    .frame(minWidth: events.isEmpty ? 0 : 200)
    .padding(AppDesign.contentMargin)
  }

  func font(weight: Font.Weight, scale: Double) -> Font {
    // The minimum acceptable font size for readability is 11 point
    .system(size: max(Constants.fontSize * scale, 11.0), weight: weight)
  }

  static func createPopover(title: String, events: [EKCalendarItem], lineWidth: Double) -> NSPopover {
    let popover = NSPopover()
    popover.behavior = .applicationDefined
    popover.animates = false
    popover.anchorHidden = true
    popover.contentViewController = DateDetailsHostVC(rootView: Self(
      title: title,
      events: events,
      lineWidth: lineWidth
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
    applyMaterial(AppPreferences.Accessibility.popoverMaterial)
  }

  override func viewDidLayout() {
    super.viewDidLayout()

    var contentSize = contentView.fittingSize
    contentSize.width = min(
      Constants.maximumWidth * AppPreferences.General.contentScale.rawValue,
      contentSize.width
    )

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

    // 12:00–13:30
    return "\(Constants.dateFormatter.string(from: startOfItem))–\(Constants.dateFormatter.string(from: endOfItem))"
  }
}

private enum Constants {
  @MainActor static let fontSize: Double = AppDesign.modernStyle ? 12.5 : 12.0
  static let dotSize: Double = 6
  static let rowHeight: Double = 28
  static let smallPadding: Double = 8
  static let largePadding: Double = 24
  static let maximumWidth: Double = 280
  static let maximumRows: Int = 12
  static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter
  }()
}
