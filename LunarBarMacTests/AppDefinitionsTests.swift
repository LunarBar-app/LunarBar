//
//  AppDefinitionsTests.swift
//  LunarBarMacTests
//
//  Created by cyan on 2023/12/31.
//

import XCTest
@testable import LunarBar

final class AppDefinitionsTests: XCTestCase {
  func testSolarTerms() {
    XCTAssertEqual(
      Localized.Calendar.solarTerms,
      [
        "立春",
        "雨水",
        "惊蛰",
        "春分",
        "清明",
        "谷雨",
        "立夏",
        "小满",
        "芒种",
        "夏至",
        "小暑",
        "大暑",
        "立秋",
        "处暑",
        "白露",
        "秋分",
        "寒露",
        "霜降",
        "立冬",
        "小雪",
        "大雪",
        "冬至",
        "小寒",
        "大寒",
      ],
      "Should be in Chinese when the locale is default"
    )
  }

  func testChineseMonths() {
    XCTAssertEqual(
      Localized.Calendar.chineseMonths,
      [
        "正月",
        "二月",
        "三月",
        "四月",
        "五月",
        "六月",
        "七月",
        "八月",
        "九月",
        "十月",
        "冬月",
        "腊月",
      ],
      "Should be in Chinese when the locale is default"
    )
  }

  func testChineseDays() {
    XCTAssertEqual(
      Localized.Calendar.chineseDays,
      [
        "初一",
        "初二",
        "初三",
        "初四",
        "初五",
        "初六",
        "初七",
        "初八",
        "初九",
        "初十",
        "十一",
        "十二",
        "十三",
        "十四",
        "十五",
        "十六",
        "十七",
        "十八",
        "十九",
        "二十",
        "廿一",
        "廿二",
        "廿三",
        "廿四",
        "廿五",
        "廿六",
        "廿七",
        "廿八",
        "廿九",
        "三十",
      ],
      "Should be in Chinese when the locale is default"
    )
  }

  func testLunarFestivals() {
    let festivals = Localized.Calendar.lunarFestivals
    let keys = festivals.map { $0.key }.sorted()

    XCTAssertEqual(
      keys.compactMap { festivals[$0] },
      [
        "春节",
        "元宵",
        "龙抬头",
        "端午",
        "七夕",
        "中元节",
        "中秋",
        "重阳",
        "寒衣节",
        "下元节",
        "腊八",
      ],
      "Should be in Chinese when the locale is default"
    )
  }
}
