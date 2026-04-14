import AppKit
import ApplicationServices
import Carbon.HIToolbox
import os

private let logger = Logger(subsystem: "dev.lookmanohands.app", category: "TextSelector")

@MainActor
final class TextSelector {

    func getSelectedText() async -> String? {
        if let text = getSelectedTextViaAccessibility() {
            return text
        }

        // Clipboard fallback only works if accessibility is granted
        // (CGEvent posting requires it too)
        guard AXIsProcessTrusted() else { return nil }

        logger.info("AX selected text failed, trying clipboard fallback")
        return await getSelectedTextViaClipboard()
    }

    // MARK: - AX API (primary)

    private func getSelectedTextViaAccessibility() -> String? {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedElement: CFTypeRef?
        let focusResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard focusResult == .success, let element = focusedElement else {
            logger.warning("Failed to get focused element (AXError \(focusResult.rawValue))")
            return nil
        }

        var selectedText: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(
            element as! AXUIElement,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )

        guard textResult == .success, let text = selectedText as? String else {
            logger.info("Failed to read selected text attribute (AXError \(textResult.rawValue))")
            return nil
        }

        if text.isEmpty {
            logger.debug("Selected text is empty")
            return nil
        }

        logger.info("Got selected text via AX (\(text.count) chars)")
        return text
    }

    // MARK: - Clipboard fallback

    private func getSelectedTextViaClipboard() async -> String? {
        let pasteboard = NSPasteboard.general

        // Save current clipboard contents
        let savedItems = pasteboard.pasteboardItems?.compactMap { item -> [NSPasteboard.PasteboardType: Data]? in
            var dict: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    dict[type] = data
                }
            }
            return dict.isEmpty ? nil : dict
        } ?? []

        // Clear clipboard and simulate Cmd+C
        pasteboard.clearContents()

        let cKeyCode = CGKeyCode(kVK_ANSI_C)
        let source = CGEventSource(stateID: .hidSystemState)
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: cKeyCode, keyDown: true),
           let keyUp = CGEvent(keyboardEventSource: source, virtualKey: cKeyCode, keyDown: false) {
            keyDown.flags = .maskCommand
            keyUp.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        }

        // Wait for clipboard to update
        try? await Task.sleep(for: .milliseconds(100))

        let copiedText = pasteboard.string(forType: .string)

        // Restore original clipboard contents
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

        guard let text = copiedText, !text.isEmpty else {
            logger.info("Clipboard fallback: no text copied")
            return nil
        }

        logger.info("Got selected text via clipboard fallback (\(text.count) chars)")
        return text
    }
}
