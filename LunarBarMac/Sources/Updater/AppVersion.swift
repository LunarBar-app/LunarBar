//
//  AppVersion.swift
//  LunarBarMac
//
//  Created by cyan on 12/25/23.
//

import Foundation

/**
 [GitHub Releases API](https://api.github.com/repos/LunarBar-app/LunarBar/releases/latest)
 */
struct AppVersion: Decodable {
  let name: String
  let body: String
  let htmlUrl: String
}
