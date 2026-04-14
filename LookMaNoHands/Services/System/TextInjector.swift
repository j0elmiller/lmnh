import AppKit
import Carbon.HIToolbox
import os

private let logger = Logger(subsystem: "dev.lookmanohands.app", category: "TextInjector")

@MainActor
final class TextInjector {

    func inject(text: String) {
        guard AXIsProcessTrusted() else {
            logger.warning("Accessibility not granted, prompting user")
            let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            return
        }

        if insertViaAccessibility(text: text) {
            return
        }

        logger.info("AX insertion failed, falling back to clipboard paste")
        injectViaClipboard(text: text)
    }

    private func insertViaAccessibility(text: String) -> Bool {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedRef: CFTypeRef?
        let focusErr = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedRef
        )
        guard focusErr == .success, let focused = focusedRef else {
            return false
        }

        let result = AXUIElementSetAttributeValue(
            focused as! AXUIElement,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )
        return result == .success
    }

    private func injectViaClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        let savedItems = pasteboard.pasteboardItems?.compactMap { item -> [NSPasteboard.PasteboardType: Data]? in
            var dict: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    dict[type] = data
                }
            }
            return dict.isEmpty ? nil : dict
        } ?? []

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        let vKeyCode: CGKeyCode = CGKeyCode(kVK_ANSI_V)
        let source = CGEventSource(stateID: .hidSystemState)
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
           let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) {
            keyDown.flags = .maskCommand
            keyUp.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            pasteboard.clearContents()
            let items = savedItems.map { itemDict -> NSPasteboardItem in
                let item = NSPasteboardItem()
                for (type, data) in itemDict {
                    item.setData(data, forType: type)
                }
                return item
            }
            if !items.isEmpty {
                pasteboard.writeObjects(items)
            }
        }
    }
}
