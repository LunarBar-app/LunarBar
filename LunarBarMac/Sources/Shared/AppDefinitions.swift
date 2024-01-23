//
//  AppDefinitions.swift
//  LunarBarMac
//
//  Created by cyan on 12/21/23.
//

import AppKit
import LunarBarKit

/**
 To make localization work, always use `String(localized:comment:)` directly and add to this file.

 Besides, we use `string catalogs` to do the translation work:
 https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog
 */
enum Localized {
  // swiftlint:disable:next type_name
  enum UI {
    // General
    static let buttonTitleNextMonth = String(localized: "Next Month", comment: "[Button] Move to the next month")
    static let buttonTitlePreviousMonth = String(localized: "Previous Month", comment: "[Button] Move to the previous month")
    static let buttonTitleShowActions = String(localized: "Show Actions", comment: "[Button] Show actions as a popup menu")

    // Menu
    static let menuTitleGotoToday = String(localized: "Today", comment: "[Menu] Move to today")
    static let menuTitleGotoMonth = String(localized: "Go to Month", comment: "[Menu] Select year and month")
    static let menuTitleAppearance = String(localized: "Appearance", comment: "[Menu] Change dark mode preference")
    static let menuTitleCalendarIcon = String(localized: "Calendar Icon", comment: "[Menu] Use a calendar icon as the menu bar icon")
    static let menuTitleCurrentDate = String(localized: "Current Date", comment: "[Menu] Use the current date as the menu bar icon")
    static let menuTitleSystem = String(localized: "System", comment: "[Menu] Follow the system appearance")
    static let menuTitleLight = String(localized: "Light", comment: "[Menu] Use the light appearance")
    static let menuTitleDark = String(localized: "Dark", comment: "[Menu] Use the dark appearance")
    static let menuTitleReduceMotion = String(localized: "Reduce Motion", comment: "[Menu] Disable animations when presenting the calendar popover")
    static let menuTitleReduceTransparency = String(localized: "Reduce Transparency", comment: "[Menu] Reduce transparency of the calendar panel")
    static let menuTitleFloatOnTop = String(localized: "Float on Top", comment: "[Menu] Float the popover on top")
    static let menuTitleCalendars = String(localized: "Calendars", comment: "[Menu] Show or hide system calendars")
    static let menuTitlePublicHolidays = String(localized: "Public Holidays", comment: "[Menu] Public holidays")
    static let menuTitleDefaultHolidays = String(localized: "Default (Mainland China)", comment: "[Menu] Default public holidays (Mainland China)")
    static let menuTitleFetchUpdates = String(localized: "Fetch Updates...", comment: "[Menu] Fetch public holiday updates")
    static let menuTitleOpenDirectory = String(localized: "Open Directory", comment: "[Menu] Open the directory of user-defined holidays")
    static let menuTitleCustomizationTips = String(localized: "Customization Tips", comment: "[Menu] View tips of customizing public holidays")
    static let menuTitleReloadCustomizations = String(localized: "Reload Customizations", comment: "[Menu] Reload customized public holidays")
    static let menuTitleLaunchAtLogin = String(localized: "Launch at Login", comment: "[Menu] Automatically start the app at login")
    static let menuTitleAboutLunarBar = String(localized: "About LunarBar", comment: "[Menu] Open the standard about panel")
    static let menuTitleGitHub = String(localized: "GitHub", comment: "[Menu] Open the LunarBar repository on GitHub")
    static let menuTitleCheckForUpdates = String(localized: "Check for Updates...", comment: "[Menu] Check for new versions")
    static let menuTitleQuitLunarBar = String(localized: "Quit LunarBar", comment: "[Menu] Quit the app")

    // Accessibility
    static let accessibilityWeekdayArea = String(localized: "Weekday symbol area", comment: "[AX] Indicate the current group is for weekday symbols")
    static let accessibilityDateGridArea = String(localized: "Date grid area", comment: "[AX] Indicate the current group is for date grids")
    static let accessibilityHasCalendarEvents = String(localized: "has calendar events", comment: "[AX] Indicate the focused date has events in the Calendar app")
    static let accessibilityEnterToSelectDates = String(localized: "Enter to select dates", comment: "[AX] Tell the user to enter the current collection to select dates")
    static let accessibilityClickToRevealDate = String(localized: "Click to reveal the date in Calendar", comment: "[AX] Tell the user to click the grid to reveal the selected date in the Calendar app")
  }

  enum Calendar {
    static let chineseNewYearsEve = String(localized: "New Year's Eve", comment: "Chinese traditional festival")
    static let chineseLeapMonth = String(localized: "Leap Month", comment: "Prefix for a Chinese leap month")
    static let daysAgoFormat = String(localized: " (%lld day ago)", comment: "Label format for dates in the past, e.g., (10 days ago)")
    static let daysLaterFormat = String(localized: " (%lld day later)", comment: "Label format for dates in the future, e.g., (10 days later)")
    static let todayLabel = String(localized: " (today)", comment: "Label for today")
    static let workdayLabel = String(localized: "[Workday] ", comment: "Label for workdays")
    static let holidayLabel = String(localized: "[Holiday] ", comment: "Label for holidays")

    /// https://en.wikipedia.org/wiki/Solar_term
    static let solarTerms = [
      String(localized: "Lichun", comment: "The 1st solar term, always in Chinese"),
      String(localized: "Yushui", comment: "The 2nd solar term, always in Chinese"),
      String(localized: "Jingzhe", comment: "The 3rd solar term, always in Chinese"),
      String(localized: "Chunfen", comment: "The 4th solar term, always in Chinese"),
      String(localized: "Qingming", comment: "The 5th solar term, always in Chinese"),
      String(localized: "Guyu", comment: "The 6th solar term, always in Chinese"),
      String(localized: "Lixia", comment: "The 7th solar term, always in Chinese"),
      String(localized: "Xiaoman", comment: "The 8th solar term, always in Chinese"),
      String(localized: "Mangzhong", comment: "The 9th solar term, always in Chinese"),
      String(localized: "Xiazhi", comment: "The 10th solar term, always in Chinese"),
      String(localized: "Xiaoshu", comment: "The 11th solar term, always in Chinese"),
      String(localized: "Dashu", comment: "The 12th solar term, always in Chinese"),
      String(localized: "Liqiu", comment: "The 13th solar term, always in Chinese"),
      String(localized: "Chushu", comment: "The 14th solar term, always in Chinese"),
      String(localized: "Bailu", comment: "The 15th solar term, always in Chinese"),
      String(localized: "Qiufen", comment: "The 16th solar term, always in Chinese"),
      String(localized: "Hanlu", comment: "The 17th solar term, always in Chinese"),
      String(localized: "Shuangjiang", comment: "The 18th solar term, always in Chinese"),
      String(localized: "Lidong", comment: "The 19th solar term, always in Chinese"),
      String(localized: "Xiaoxue", comment: "The 20th solar term, always in Chinese"),
      String(localized: "Daxue", comment: "The 21st solar term, always in Chinese"),
      String(localized: "Dongzhi", comment: "The 22nd solar term, always in Chinese"),
      String(localized: "Xiaohan", comment: "The 23rd solar term, always in Chinese"),
      String(localized: "Dahan", comment: "The 24th solar term, always in Chinese"),
    ]

    static let chineseMonths = [
      String(localized: "MONTH_01", comment: "The 1st Chinese month, always in Chinese"),
      String(localized: "MONTH_02", comment: "The 2nd Chinese month, always in Chinese"),
      String(localized: "MONTH_03", comment: "The 3rd Chinese month, always in Chinese"),
      String(localized: "MONTH_04", comment: "The 4th Chinese month, always in Chinese"),
      String(localized: "MONTH_05", comment: "The 5th Chinese month, always in Chinese"),
      String(localized: "MONTH_06", comment: "The 6th Chinese month, always in Chinese"),
      String(localized: "MONTH_07", comment: "The 7th Chinese month, always in Chinese"),
      String(localized: "MONTH_08", comment: "The 8th Chinese month, always in Chinese"),
      String(localized: "MONTH_09", comment: "The 9th Chinese month, always in Chinese"),
      String(localized: "MONTH_10", comment: "The 10th Chinese month, always in Chinese"),
      String(localized: "MONTH_11", comment: "The 11th Chinese month, always in Chinese"),
      String(localized: "MONTH_12", comment: "The 12th Chinese month, always in Chinese"),
    ]

    static let chineseDays = [
      String(localized: "DAY_01", comment: "Day 1, always in Chinese"),
      String(localized: "DAY_02", comment: "Day 2, always in Chinese"),
      String(localized: "DAY_03", comment: "Day 3, always in Chinese"),
      String(localized: "DAY_04", comment: "Day 4, always in Chinese"),
      String(localized: "DAY_05", comment: "Day 5, always in Chinese"),
      String(localized: "DAY_06", comment: "Day 6, always in Chinese"),
      String(localized: "DAY_07", comment: "Day 7, always in Chinese"),
      String(localized: "DAY_08", comment: "Day 8, always in Chinese"),
      String(localized: "DAY_09", comment: "Day 9, always in Chinese"),
      String(localized: "DAY_10", comment: "Day 10, always in Chinese"),
      String(localized: "DAY_11", comment: "Day 11, always in Chinese"),
      String(localized: "DAY_12", comment: "Day 12, always in Chinese"),
      String(localized: "DAY_13", comment: "Day 13, always in Chinese"),
      String(localized: "DAY_14", comment: "Day 14, always in Chinese"),
      String(localized: "DAY_15", comment: "Day 15, always in Chinese"),
      String(localized: "DAY_16", comment: "Day 16, always in Chinese"),
      String(localized: "DAY_17", comment: "Day 17, always in Chinese"),
      String(localized: "DAY_18", comment: "Day 18, always in Chinese"),
      String(localized: "DAY_19", comment: "Day 19, always in Chinese"),
      String(localized: "DAY_20", comment: "Day 20, always in Chinese"),
      String(localized: "DAY_21", comment: "Day 21, always in Chinese"),
      String(localized: "DAY_22", comment: "Day 22, always in Chinese"),
      String(localized: "DAY_23", comment: "Day 23, always in Chinese"),
      String(localized: "DAY_24", comment: "Day 24, always in Chinese"),
      String(localized: "DAY_25", comment: "Day 25, always in Chinese"),
      String(localized: "DAY_26", comment: "Day 26, always in Chinese"),
      String(localized: "DAY_27", comment: "Day 27, always in Chinese"),
      String(localized: "DAY_28", comment: "Day 28, always in Chinese"),
      String(localized: "DAY_29", comment: "Day 29, always in Chinese"),
      String(localized: "DAY_30", comment: "Day 30, always in Chinese"),
    ]

    static let lunarFestivals = [
      // Chinese New Year's Eve is not here because it is dynamically determined
      "0101": String(localized: "Spring Festival", comment: "Chinese traditional festival"),
      "0115": String(localized: "Lantern Festival", comment: "Chinese traditional festival"),
      "0202": String(localized: "Longtaitou Festival", comment: "Chinese traditional festival"),
      "0505": String(localized: "Dragon Boat Festival", comment: "Chinese traditional festival"),
      "0707": String(localized: "Qixi Festival", comment: "Chinese traditional festival"),
      "0715": String(localized: "Ghost Festival", comment: "Chinese traditional festival"),
      "0815": String(localized: "Mid-Autumn Festival", comment: "Chinese traditional festival"),
      "0909": String(localized: "Double Ninth Festival", comment: "Chinese traditional festival"),
      "1001": String(localized: "Winter Clothes Day", comment: "Chinese traditional festival"),
      "1015": String(localized: "Xiayuan Festival", comment: "Chinese traditional festival"),
      "1208": String(localized: "Laba Festival", comment: "Chinese traditional festival"),
    ]
  }
}

// Icon set used in the app: https://developer.apple.com/sf-symbols/
//
// Note: double check availability and deployment target before adding new icons
enum Icons {
  static let bookmarkFill = "bookmark.fill"
  static let calendar = "calendar"
  static let chevronBackward = "chevron.backward"
  static let chevronForward = "chevron.forward"
  static let circle = "circle"
}

enum Colors {
  static let controlAccent: NSColor = .controlAccentColor
  static let darkGray: NSColor = .darkGray
  static let primaryLabel: NSColor = .labelColor
  static let systemTeal: NSColor = .systemTeal
  static let systemOrange: NSColor = .systemOrange
}

enum FontSizes {
  static let small: Double = 9
  static let regular: Double = 14
  static let large: Double = 19
}

enum AlphaLevels {
  static let primary: Double = 1.0
  static let secondary: Double = 0.7
  static let tertiary: Double = 0.4
}

// Getting these codes seems to require the use of Carbon.framework, but it is deprecated
extension UInt16 {
  static let kVK_ANSI_Q: UInt16 = 0x0C
  static let kVK_ANSI_W: UInt16 = 0x0D
  static let kVK_Space: UInt16 = 0x31
  static let kVK_LeftArrow: UInt16 = 0x7B
  static let kVK_RightArrow: UInt16 = 0x7C
}
