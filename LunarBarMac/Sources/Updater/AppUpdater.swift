//
//  AppUpdater.swift
//  LunarBarMac
//
//  Created by cyan on 12/25/23.
//

import AppKit
import LunarBarKit

enum AppUpdater {
  private enum Constants {
    static let endpoint = "https://api.github.com/repos/LunarBar-app/LunarBar/releases/latest"
    static let decoder = {
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      return decoder
    }()
  }

  static func checkForUpdates(explicitly: Bool) async {
    guard let url = URL(string: Constants.endpoint) else {
      return Logger.assertFail("Failed to create the URL: \(Constants.endpoint)")
    }

    guard let (data, response) = try? await URLSession.shared.data(from: url) else {
      return Logger.log(.error, "Failed to reach out to the server")
    }

    guard let status = (response as? HTTPURLResponse)?.statusCode, status == 200 else {
      if explicitly {
        DispatchQueue.main.async {
          presentError()
        }
      }

      return Logger.log(.error, "Failed to get the update")
    }

    guard let version = try? Constants.decoder.decode(AppVersion.self, from: data) else {
      return Logger.log(.error, "Failed to decode the data")
    }

    DispatchQueue.main.async {
      presentUpdate(newVersion: version, explicitly: explicitly)
    }
  }
}

// MARK: - Private

@MainActor
private extension AppUpdater {
  static func presentError() {
    let alert = NSAlert()
    alert.messageText = Localized.Updater.updateFailedTitle
    alert.informativeText = Localized.Updater.updateFailedMessage
    alert.addButton(withTitle: Localized.Updater.checkVersionHistory)
    alert.addButton(withTitle: Localized.Updater.notNow)

    guard alert.runModal() == .alertFirstButtonReturn else {
      return
    }

    NSWorkspace.shared.safelyOpenURL(string: "https://github.com/LunarBar-app/LunarBar/releases")
  }

  static func presentUpdate(newVersion: AppVersion, explicitly: Bool) {
    guard let currentVersion = Bundle.main.shortVersionString else {
      return Logger.assertFail("Invalid current version string")
    }

    // Check if the new version was skipped for implicit updates
    guard explicitly || !AppPreferences.Updater.skippedVersions.contains(newVersion.name) else {
      return
    }

    // Check if the version is different
    guard newVersion.name != currentVersion else {
      return {
        guard explicitly else {
          return
        }

        let alert = NSAlert()
        alert.messageText = Localized.Updater.upToDateTitle
        alert.informativeText = String(format: Localized.Updater.upToDateMessageFormat, currentVersion)
        alert.runModal()
      }()
    }

    let alert = NSAlert()
    alert.messageText = String(format: Localized.Updater.newVersionAvailableTitle, newVersion.name)
    alert.markdownBody = newVersion.body
    alert.addButton(withTitle: Localized.Updater.learnMore)

    if explicitly {
      alert.addButton(withTitle: Localized.Updater.notNow)
    } else {
      alert.addButton(withTitle: Localized.Updater.remindMeLater)
      alert.addButton(withTitle: Localized.Updater.skipThisVersion)
    }

    switch alert.runModal() {
    case .alertFirstButtonReturn: // Learn More
      NSWorkspace.shared.safelyOpenURL(string: newVersion.htmlUrl)
    case .alertThirdButtonReturn: // Skip This Version
      AppPreferences.Updater.skippedVersions.insert(newVersion.name)
    default:
      break
    }
  }
}

// MARK: - Private

private extension Localized {
  enum Updater {
    static let upToDateTitle = String(localized: "You're up-to-date!", comment: "Title for the up-to-date info")
    static let upToDateMessageFormat = String(localized: "LunarBar %@ is currently the latest version.", comment: "Message for the up-to-date info")
    static let newVersionAvailableTitle = String(localized: "LunarBar %@ is available!", comment: "Title for new version available")
    static let updateFailedTitle = String(localized: "Failed to get the update.", comment: "Title for failed to get the update")
    static let updateFailedMessage = String(localized: "Please check your network connection or get the latest release from the version history.", comment: "Message for failed to get the update")
    static let learnMore = String(localized: "Learn More", comment: "Title for the \"Learn More\" button")
    static let notNow = String(localized: "Not Now", comment: "Title for the \"Not Now\" button")
    static let remindMeLater = String(localized: "Remind Me Later", comment: "Title for the \"Remind Me Later\" button")
    static let skipThisVersion = String(localized: "Skip This Version", comment: "Title for the \"Skip This Version\" button")
    static let checkVersionHistory = String(localized: "Check Version History", comment: "Title for the \"Check Version History\" button")
  }
}

private extension AppPreferences {
  enum Updater {
    @Storage(key: "updater.skipped-versions", defaultValue: Set())
    static var skippedVersions: Set<String>
  }
}
