//
//  HeaderView.swift
//  LunarBarMac
//
//  Created by cyan on 12/21/23.
//

import AppKit
import AppKitControls
import LunarBarKit

protocol HeaderViewDelegate: AnyObject {
  func headerView(_ sender: HeaderView, moveTo date: Date)
  func headerView(_ sender: HeaderView, moveBy offset: Int)
  func headerView(_ sender: HeaderView, showActionsMenu sourceView: NSView)
}

/**
 Calendar header, showing the date and a few buttons for navigation.

 Example: [ Dec 2023    < O > ]
 */
final class HeaderView: NSView {
  weak var delegate: HeaderViewDelegate?

  private let dateLabel: TextLabel = {
    let label = TextLabel()
    label.textColor = Colors.primaryLabel
    label.font = .monospacedDigitSystemFont(ofSize: Constants.dateFontSize, weight: .medium)

    return label
  }()

  private lazy var nextButton: ImageButton = {
    let button = ImageButton(
      symbolName: Icons.chevronForward,
      tintColor: Colors.primaryLabel,
      accessibilityLabel: Localized.UI.buttonTitleNextMonth
    )

    button.addAction { [weak self] in
      guard let self else {
        return
      }

      delegate?.headerView(self, moveBy: 1)
    }

    button.toolTip = Localized.UI.buttonTitleNextMonth + " ▶"
    return button
  }()

  private lazy var actionsButton: ImageButton = {
    let button = ImageButton(
      symbolName: Icons.circle,
      tintColor: Colors.primaryLabel,
      accessibilityLabel: Localized.UI.buttonTitleShowActions
    )

    button.addAction { [weak self] in
      guard let self else {
        return
      }

      self.delegate?.headerView(self, showActionsMenu: actionsButton)
    }

    return button
  }()

  private lazy var previousButton: ImageButton = {
    let button = ImageButton(
      symbolName: Icons.chevronBackward,
      tintColor: Colors.primaryLabel,
      accessibilityLabel: Localized.UI.buttonTitlePreviousMonth
    )

    button.addAction { [weak self] in
      guard let self else {
        return
      }

      delegate?.headerView(self, moveBy: -1)
    }

    button.toolTip = "◀ " + Localized.UI.buttonTitlePreviousMonth
    return button
  }()

  init() {
    super.init(frame: .zero)

    dateLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(dateLabel)
    NSLayoutConstraint.activate([
      dateLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.smallPadding),
      dateLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])

    nextButton.translatesAutoresizingMaskIntoConstraints = false
    addSubview(nextButton)
    NSLayoutConstraint.activate([
      nextButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.mediumPadding),
      nextButton.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])

    actionsButton.translatesAutoresizingMaskIntoConstraints = false
    addSubview(actionsButton)
    NSLayoutConstraint.activate([
      actionsButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -Constants.mediumPadding),
      actionsButton.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])

    previousButton.translatesAutoresizingMaskIntoConstraints = false
    addSubview(previousButton)
    NSLayoutConstraint.activate([
      previousButton.trailingAnchor.constraint(equalTo: actionsButton.leadingAnchor, constant: -Constants.mediumPadding),
      previousButton.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func mouseUp(with event: NSEvent) {
    super.mouseUp(with: event)

    // Hidden way to goto today
    if dateLabel.frame.contains(convert(event.locationInWindow, from: nil)) {
      delegate?.headerView(self, moveTo: .now)
    }
  }
}

// MARK: - Updating

extension HeaderView {
  func updateCalendar(date: Date) {
    dateLabel.stringValue = Constants.dateFormatter.string(from: date)
  }
}

// MARK: - Private

private extension HeaderView {
  enum Constants {
    static let dateFontSize: Double = FontSizes.large
    static let smallPadding: Double = 9
    static let mediumPadding: Double = 12

    static let dateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.locale = .autoupdatingCurrent

      // E.g., Dec 2023 in en-US, 2023年12月 in zh-Hans
      formatter.setLocalizedDateFormatFromTemplate("MMM y")
      return formatter
    }()
  }
}
