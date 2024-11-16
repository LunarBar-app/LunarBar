//
//  HeaderView.swift
//  LunarBarMac
//
//  Created by cyan on 12/21/23.
//

import AppKit
import AppKitControls
import LunarBarKit

@MainActor
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

  private var previousDate: Date = .distantPast

  init() {
    super.init(frame: .zero)

    dateLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(dateLabel)
    NSLayoutConstraint.activate([
      dateLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.datePadding),
      dateLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])

    nextButton.translatesAutoresizingMaskIntoConstraints = false
    addSubview(nextButton)
    NSLayoutConstraint.activate([
      nextButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.buttonPadding),
      nextButton.centerYAnchor.constraint(equalTo: centerYAnchor),
      nextButton.widthAnchor.constraint(equalToConstant: nextButton.frame.width),
      nextButton.heightAnchor.constraint(equalToConstant: nextButton.frame.height),
    ])

    actionsButton.translatesAutoresizingMaskIntoConstraints = false
    addSubview(actionsButton)
    NSLayoutConstraint.activate([
      actionsButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor),
      actionsButton.centerYAnchor.constraint(equalTo: centerYAnchor),
      actionsButton.widthAnchor.constraint(equalToConstant: actionsButton.frame.width),
      actionsButton.heightAnchor.constraint(equalToConstant: actionsButton.frame.height),
    ])

    previousButton.translatesAutoresizingMaskIntoConstraints = false
    addSubview(previousButton)
    NSLayoutConstraint.activate([
      previousButton.trailingAnchor.constraint(equalTo: actionsButton.leadingAnchor),
      previousButton.centerYAnchor.constraint(equalTo: centerYAnchor),
      previousButton.widthAnchor.constraint(equalToConstant: previousButton.frame.width),
      previousButton.heightAnchor.constraint(equalToConstant: previousButton.frame.height),
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
  enum ButtonIdentifier {
    case previous
    case actions
    case next
  }

  func updateCalendar(date: Date) {
    dateLabel.stringValue = Constants.dateFormatter.string(from: date)

    if !AppPreferences.Accessibility.reduceMotion, previousDate != .distantPast,
       !Calendar.solar.isDate(previousDate, inSameMonthAs: date) {
      let transition = CATransition()
      transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      transition.type = .push
      transition.subtype = previousDate < date ? .fromBottom : .fromTop
      transition.duration = 0.25

      dateLabel.wantsLayer = true
      dateLabel.layer?.add(transition, forKey: "pushEffect")
    }

    previousDate = date
  }

  func showClickEffect(for identifier: ButtonIdentifier) {
    guard !AppPreferences.Accessibility.reduceMotion else {
      return
    }

    let button = {
      switch identifier {
      case .previous: return previousButton
      case .actions: return actionsButton
      case .next: return nextButton
      }
    }()

    button.setAlphaValue(0.6) {
      button.setAlphaValue(1)
    }
  }
}

// MARK: - Private

private extension HeaderView {
  enum Constants {
    static let dateFontSize: Double = FontSizes.large
    static let datePadding: Double = 9
    static let buttonPadding: Double = 6
    static let dateFormatter: DateFormatter = .localizedMonth
  }
}
