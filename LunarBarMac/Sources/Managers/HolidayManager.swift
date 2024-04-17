//
//  HolidayManager.swift
//  LunarBarMac
//
//  Created by cyan on 12/24/23.
//

import AppKit
import LunarBarKit

enum HolidayType: Int {
  case workday = 1
  case holiday = 2
}

/**
 For public holidays.
 */
@MainActor
final class HolidayManager {
  static let `default` = HolidayManager()

  private var defaultData = [FileType]()
  private var cachedData = [FileType]()
  private var userDefinedData = [FileType]()

  private init() {
    if let defaultDirectory, let data = contentsOf(directory: defaultDirectory) {
      defaultData = data
    } else {
      Logger.assertFail("Failed to load default holidays")
    }

    ensureDirectory(cachesDirectory)
    ensureDirectory(userDefinedDirectory)

    reloadCachedFiles()
    reloadUserDefinedFiles()
  }

  var defaultsEnabled = AppPreferences.Calendar.defaultHolidays

  var userDefinedFiles: [String] {
    guard let files = try? FileManager.default.contentsOfDirectory(atPath: userDefinedDirectory.path()) else {
      return []
    }

    return files.filter { URL(filePath: $0).pathExtension.lowercased() == Constants.fileExtension }
  }

  func reloadCachedFiles() {
    if let data = contentsOf(directory: cachesDirectory) {
      cachedData = data
    } else {
      Logger.assertFail("Failed to load cached holidays")
    }
  }

  func reloadUserDefinedFiles() {
    if let data = contentsOf(directory: userDefinedDirectory) {
      userDefinedData = data
    } else {
      Logger.assertFail("Failed to load user-defined holidays")
    }
  }

  func openUserDefinedDirectory() {
    NSWorkspace.shared.open(userDefinedDirectory)
  }

  func typeOf(year: Int, monthDay: String) -> HolidayType? {
    // Order matters, prefer user-defined over default
    let allData = [
      userDefinedData,
      defaultsEnabled ? (defaultData + cachedData) : [],
    ].flatMap { $0 }

    for data in allData {
      if let value = data[String(year)]?[monthDay], let type = HolidayType(rawValue: value) {
        return type
      }
    }

    return nil
  }

  nonisolated func fetchDefaultHolidays() async {
    guard let url = URL(string: Constants.endpoint) else {
      return Logger.assertFail("Failed to create the URL: \(Constants.endpoint)")
    }

    guard let (data, response) = try? await URLSession.shared.data(from: url) else {
      return Logger.log(.error, "Failed to reach out to the server")
    }

    guard let status = (response as? HTTPURLResponse)?.statusCode, status == 200 else {
      return Logger.log(.error, "Failed to get the update")
    }

    guard let contents = try? JSONSerialization.jsonObject(with: data), contents is FileType else {
      return Logger.log(.error, "Invalid online data is found")
    }

    Logger.log(.info, "Successfully fetched default holidays")

    do {
      try await data.write(
        to: cachesDirectory.appending(
          path: url.lastPathComponent,
          directoryHint: .notDirectory
        ),
        options: .atomic
      )

      await reloadCachedFiles()
    } catch {
      Logger.log(.error, error.localizedDescription)
    }
  }
}

// MARK: - Private

// E.g., ["2024": ["0101": 2, "0204": 1, ... ]]
private typealias FileType = [String: [String: Int]]

private extension HolidayManager {
  enum Constants {
    static let directoryName = "Holidays"
    static let fileExtension = "json"
    static let endpoint = "https://github.com/LunarBar-app/Holidays/raw/main/mainland-china.json"
  }

  var defaultDirectory: URL? {
    Bundle.main.url(forResource: Constants.directoryName, withExtension: nil)
  }

  var cachesDirectory: URL {
    URL.cachesDirectory.appending(path: Constants.directoryName, directoryHint: .isDirectory)
  }

  var userDefinedDirectory: URL {
    URL.documentsDirectory.appending(path: Constants.directoryName, directoryHint: .isDirectory)
  }

  func ensureDirectory(_ directory: URL) {
    guard !FileManager.default.fileExists(atPath: directory.path()) else {
      return
    }

    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
    } catch {
      Logger.log(.error, error.localizedDescription)
    }
  }

  func contentsOf(directory: URL) -> [FileType]? {
    guard let files = try? FileManager.default.contentsOfDirectory(atPath: directory.path()) else {
      Logger.log(.error, "Failed to get contents from directory: \(directory)")
      return nil
    }

    return files.compactMap {
      contentsOf(file: directory.appending(
        path: $0,
        directoryHint: .notDirectory
      ))
    }
  }

  func contentsOf(file url: URL) -> FileType? {
    // Basically to filter out unexpected files, e.g., .DS_Store
    guard url.pathExtension.lowercased() == Constants.fileExtension else {
      return nil
    }

    guard let data = try? Data(contentsOf: url) else {
      Logger.log(.error, "Failed to read file: \(url)")
      return nil
    }

    guard let contents = try? JSONSerialization.jsonObject(with: data) as? FileType else {
      Logger.log(.error, "Failed to decode the data file")
      return nil
    }

    return contents
  }
}
