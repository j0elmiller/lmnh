import SwiftUI

// Centralized design tokens so the palette from the app icon (cyan → purple
// gradient, with the `mnh` monogram) is reflected consistently across every
// SwiftUI surface and so state colors are picked in exactly one place.

enum Theme {
    static let padding: CGFloat = 12
    static let cornerRadius: CGFloat = 10
    static let popoverWidth: CGFloat = 280
}

extension Color {
    // Brand — sampled from the app icon gradient
    static let brandCyan = Color(red: 0x6A / 255, green: 0xD4 / 255, blue: 0xF4 / 255)
    static let brandPurple = Color(red: 0x8B / 255, green: 0x5C / 255, blue: 0xF6 / 255)

    // Semantic state colors — keyed to AppState's five states. Using distinct
    // hues for active states keeps glanceable feedback in the menu bar popover.
    static let stateRecording = Color.red
    static let stateTranscribing = Color.orange
    static let stateSpeaking = Color.blue
    static let stateLoading = Color.yellow
    static let stateReady = Color.green
    static let stateIdle = Color.gray
}

extension LinearGradient {
    // Cyan → purple diagonal, mirroring the app icon's gradient direction.
    static let brand = LinearGradient(
        colors: [.brandCyan, .brandPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
