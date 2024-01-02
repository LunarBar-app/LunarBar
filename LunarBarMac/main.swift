//
//  main.swift
//  LunarBarMac
//
//  Created by cyan on 2024/1/2.
//

import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()

app.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
