//
//  EditableTextField.swift
//
//  Created by cyan on 6/4/25.
//

import AppKit

/**
 A custom `NSTextField` subclass that enables common editing keyboard shortcuts
 in environments without a main menu, such as menu bar or agent-style apps.

 Useful for macOS status bar utilities or headless apps where default responder
 chain behaviors may not be available.
 */
public final class EditableTextField: NSTextField {
  override public func performKeyEquivalent(with event: NSEvent) -> Bool {
    guard event.type == .keyDown, event.modifierFlags.contains(.command) else {
      return super.performKeyEquivalent(with: event)
    }

    switch event.charactersIgnoringModifiers?.lowercased() {
    case "a":
      currentEditor()?.selectAll(nil)
      return true
    case "c":
      currentEditor()?.copy(nil)
      return true
    case "v":
      currentEditor()?.paste(nil)
      return true
    case "x":
      currentEditor()?.cut(nil)
      return true
    case "z":
      if event.modifierFlags.contains(.shift) {
        currentEditor()?.undoManager?.redo()
      } else {
        currentEditor()?.undoManager?.undo()
      }
      return true
    default:
      return super.performKeyEquivalent(with: event)
    }
  }
}
