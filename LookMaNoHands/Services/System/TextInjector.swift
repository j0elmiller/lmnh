import AppKit
import Carbon.HIToolbox

@MainActor
final class TextInjector {

    func inject(text: String) {
        // Save current clipboard
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

        // Set transcribed text to clipboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Simulate Cmd+V
        simulatePaste()

        // Restore clipboard after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            pasteboard.clearContents()
            for itemDict in savedItems {
                let item = NSPasteboardItem()
                for (type, data) in itemDict {
                    item.setData(data, forType: type)
                }
                pasteboard.writeObjects([item])
            }
        }
    }

    private func simulatePaste() {
        let vKeyCode: CGKeyCode = CGKeyCode(kVK_ANSI_V)

        let source = CGEventSource(stateID: .hidSystemState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgSessionEventTap)
        keyUp.post(tap: .cgSessionEventTap)
    }
}
