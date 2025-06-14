//
//  main.swift
//  LunarBarMac
//
//  Created by cyan on 1/2/24.
//

import AppKit

#if BUILD_WITH_SDK_26_OR_LATER
  Bundle.swizzleInfoDictionaryOnce
#endif

let app = NSApplication.shared
let delegate = AppDelegate()

app.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
