//
//  LunarCalendar.swift
//
//  Created by cyan on 12/22/23.
//

import Foundation

/**
 The utility to get lunar calendar information from pre-defined data.

 For example, solar terms are hard to be precise if we compute them using formulas.
 */
public final class LunarCalendar {
  public static let `default` = LunarCalendar()

  /**
   Four digits month and day to its solar term index.

   Example: ["0106": 22].
   */
  private typealias SolarTerms = [String: Int]

  /**
   The table that contains lunar information from 1901 to 2100, it only has solar terms for now.

   Example: ["1901": ["0106": 22]], Jan 6th, 1901 is Xiaohan (小寒).
   */
  private let allData: [String: SolarTerms]? = {
    guard let url = Bundle.module.url(forResource: "data", withExtension: "json") else {
      fatalError("Missing data.json to continue")
    }

    guard let data = try? Data(contentsOf: url) else {
      fatalError("Failed to read data.json as Data")
    }

    guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: [String]] else {
      fatalError("Invalid pre-defined data.json")
    }

    // Reduce the data from indices (array) to key values (hash table) to have O(1) lookup complexity
    return dict.reduce(into: [String: SolarTerms]()) { result, item in
      result[item.key] = item.value.reduce(into: SolarTerms()) {
        // firstIndex is O(n), that's why we transform the data from indices to key values
        $0[$1] = item.value.firstIndex(of: $1)
      }
    }
  }()

  public func info(of year: Int) -> LunarInfo? {
    guard let solarTerms = allData?[String(year)] as? SolarTerms else {
      Logger.log(.info, "Missing solar terms for year: \(year)")
      return nil
    }

    Logger.assert(solarTerms.count == 24, "Invalid data for year \(year) is found")
    return LunarInfo(solarTerms: solarTerms)
  }

  private init() {}
}
