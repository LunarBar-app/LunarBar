//
//  DateGridView.swift
//  LunarBarMac
//
//  Created by cyan on 12/21/23.
//

import AppKit
import EventKit
import LunarBarKit

/**
 Grid view to show dates of a month.
 */
final class DateGridView: NSView {
  private var monthDate: Date?
  private var lunarInfo: LunarInfo?
  private var dataSource: NSCollectionViewDiffableDataSource<Section, Model>?

  private let collectionView: NSCollectionView = {
    let view = NSCollectionView()
    view.setAccessibilityElement(true)
    view.setAccessibilityRole(.group)
    view.setAccessibilityLabel(Localized.UI.accessibilityDateGridArea)
    view.setAccessibilityHelp(Localized.UI.accessibilityEnterToSelectDates)
    view.backgroundColors = [.clear]

    return view
  }()

  init() {
    super.init(frame: .zero)

    dataSource = NSCollectionViewDiffableDataSource<Section, Model>(collectionView: collectionView) { [weak self] (collectionView: NSCollectionView, indexPath: IndexPath, object: Model) -> NSCollectionViewItem? in
      let cell = collectionView.makeItem(withIdentifier: DateGridCell.reuseIdentifier, for: indexPath)
      if let cell = cell as? DateGridCell {
        cell.update(
          cellDate: object.date,
          cellEvents: object.events,
          monthDate: self?.monthDate,
          lunarInfo: self?.lunarInfo
        )
      } else {
        Logger.assertFail("Invalid cell type is found: \(cell)")
      }

      return cell
    }

    collectionView.collectionViewLayout = createLayout()
    collectionView.register(DateGridCell.self, forItemWithIdentifier: DateGridCell.reuseIdentifier)
    collectionView.delegate = self
    addSubview(collectionView)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layout() {
    super.layout()
    collectionView.frame = bounds
  }
}

// MARK: - NSCollectionViewDelegate

extension DateGridView: NSCollectionViewDelegate {
  func collectionView(
    _ collectionView: NSCollectionView,
    shouldSelectItemsAt indexPaths: Set<IndexPath>
  ) -> Set<IndexPath> {
    // This is to disable the selection, which can be triggered by VoiceOver
    Set()
  }
}

// MARK: - Updating

extension DateGridView {
  func updateCalendar(date monthDate: Date, lunarInfo: LunarInfo?) {
    guard let allDates = Calendar.solar.allDatesFillingMonth(from: monthDate) else {
      return Logger.assertFail("Failed to generate the calendar")
    }

    guard let startDate = allDates.first, let endDate = allDates.last else {
      return Logger.assertFail("Missing any dates from: \(monthDate)")
    }

    self.monthDate = monthDate
    self.lunarInfo = lunarInfo
    self.reloadData(
      allDates: allDates,
      events: CalendarManager.default.caches(from: startDate, to: endDate)
    )

    Task {
      let items = try await CalendarManager.default.items(from: startDate, to: endDate)
      reloadData(allDates: allDates, events: items)

      if let prevMonth = Calendar.solar.date(byAdding: .day, value: -1, to: startDate) {
        await CalendarManager.default.preload(date: prevMonth)
      }

      if let nextMonth = Calendar.solar.date(byAdding: .day, value: 1, to: endDate) {
        await CalendarManager.default.preload(date: nextMonth)
      }
    }
  }
}

// MARK: - Private

private extension DateGridView {
  enum Section {
    case `default`
  }

  /**
   Returns a 7 (column) * 6 (rows) grid layout for the collection.
   */
  func createLayout() -> NSCollectionViewLayout {
    let item = NSCollectionLayoutItem(
      layoutSize: NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1 / Double(Calendar.solar.numberOfDaysInWeek)),
        heightDimension: .fractionalHeight(1)
      )
    )

    let group = NSCollectionLayoutGroup.horizontal(
      layoutSize: NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1),
        heightDimension: .fractionalHeight(1 / Double(Calendar.solar.numberOfRowsInMonth))
      ),
      subitems: [item]
    )

    let section = NSCollectionLayoutSection(group: group)
    let layout = NSCollectionViewCompositionalLayout(section: section)
    return layout
  }

  @MainActor
  func reloadData(allDates: [Date], events: [EKCalendarItem] = []) {
    var snapshot = NSDiffableDataSourceSnapshot<Section, Model>()
    snapshot.appendSections([Section.default])

    snapshot.appendItems(allDates.map { date in
      Model(date: date, events: events.filter {
        $0.overlaps(
          startOfDay: Calendar.solar.startOfDay(for: date),
          endOfDay: Calendar.solar.endOfDay(for: date)
        )
      }.oldestToNewest)
    })

    let animated = !AppPreferences.Accessibility.reduceMotion
    dataSource?.apply(snapshot, animatingDifferences: animated)
    Logger.log(.info, "Reloaded dateGridView: \(allDates.count) items")

    collectionView.visibleItems()
    .compactMap {
      $0 as? DateGridCell
    }
    .forEach {
      $0.cancelHighlight()
    }
  }
}

private struct Model: Hashable {
  let date: Date
  let events: [EKCalendarItem]

  func hash(into hasher: inout Hasher) {
    hasher.combine(date)
    hasher.combine(events)
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.date == rhs.date && lhs.events == rhs.events
  }
}
