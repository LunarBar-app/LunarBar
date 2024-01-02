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
  private var monthEvents: [EKEvent]?
  private var lunarInfo: LunarInfo?
  private var dataSource: NSCollectionViewDiffableDataSource<Section, Date>?

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

    dataSource = NSCollectionViewDiffableDataSource<Section, Date>(collectionView: collectionView) { [weak self] (collectionView: NSCollectionView, indexPath: IndexPath, date: Date) -> NSCollectionViewItem? in
      let cell = collectionView.makeItem(withIdentifier: DateGridCell.reuseIdentifier, for: indexPath)
      if let cell = cell as? DateGridCell {
        cell.update(
          cellDate: date,
          monthDate: self?.monthDate,
          monthEvents: self?.monthEvents,
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

    self.monthDate = monthDate
    self.lunarInfo = lunarInfo

    // Get events for the entire month because batch query is faster
    self.monthEvents = {
      guard let startDate = allDates.first, let endDate = allDates.last else {
        Logger.assertFail("Missing any dates from: \(monthDate)")
        return nil
      }

      return CalendarManager.default.events(
        from: Calendar.solar.startOfDay(for: startDate),
        to: Calendar.solar.endOfDay(for: endDate),
        hiddenCalendars: AppPreferences.Calendar.hiddenCalendars
      )
    }()

    Logger.log(.info, "Reloading dateGridView: \(allDates.count) items")
    reloadData(allDates: allDates)
  }
}

// MARK: - Private

private extension DateGridView {
  enum Section {
    case dates
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

  func reloadData(allDates: [Date]) {
    var snapshot = NSDiffableDataSourceSnapshot<Section, Date>()
    snapshot.appendSections([Section.dates])
    snapshot.appendItems(allDates)

    dataSource?.apply(snapshot, animatingDifferences: false)
  }
}
