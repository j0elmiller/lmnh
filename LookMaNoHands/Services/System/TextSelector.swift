import AppKit
import ApplicationServices

@MainActor
final class TextSelector {

    func getSelectedText() -> String? {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedElement: CFTypeRef?
        let focusResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard focusResult == .success, let element = focusedElement else {
            return nil
        }

        var selectedText: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(
            element as! AXUIElement,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )

        guard textResult == .success, let text = selectedText as? String else {
            return nil
        }

        return text.isEmpty ? nil : text
    }
}
