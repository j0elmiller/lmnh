import SwiftUI

struct RecordingOverlay: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 12) {
            // Pulsing mic indicator
            Image(systemName: appState.isTranscribing ? "ellipsis.circle.fill" : "mic.fill")
                .font(.title2)
                .foregroundStyle(appState.isTranscribing ? .orange : .red)
                .symbolEffect(.pulse, isActive: appState.isRecording)

            if appState.isTranscribing {
                Text("Transcribing...")
                    .font(.body)
                    .foregroundStyle(.primary)
            } else {
                // Simple audio level bars
                WaveformView()
                    .frame(width: 60, height: 24)

                Text("Listening...")
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
    }
}

struct WaveformView: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(.red.opacity(0.8))
                    .frame(width: 4)
                    .frame(height: animating ? CGFloat.random(in: 8...24) : 8)
                    .animation(
                        .easeInOut(duration: 0.3)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

// MARK: - Overlay Window Controller

@MainActor
final class RecordingOverlayController {
    private var window: NSPanel?
    private var appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func show() {
        guard window == nil else { return }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 250, height: 60),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hasShadow = false

        let hostingView = NSHostingView(
            rootView: RecordingOverlay()
                .environment(appState)
        )
        panel.contentView = hostingView

        // Position near top center of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 125
            let y = screenFrame.maxY - 80
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFrontRegardless()
        self.window = panel
    }

    func dismiss() {
        window?.close()
        window = nil
    }
}
