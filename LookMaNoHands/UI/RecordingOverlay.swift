import SwiftUI

struct RecordingOverlay: View {
    var isTranscribing: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isTranscribing ? "ellipsis.circle.fill" : "mic.fill")
                .font(.title2)
                .foregroundStyle(isTranscribing ? .orange : .red)

            Text(isTranscribing ? "Transcribing..." : "Listening...")
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(width: 200, height: 44)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
    }
}

// MARK: - Overlay Window Controller

@MainActor
final class RecordingOverlayController {
    private var window: NSPanel?
    private var hostingView: NSHostingView<RecordingOverlay>?

    func show() {
        guard window == nil else { return }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 44),
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

        let hv = NSHostingView(rootView: RecordingOverlay(isTranscribing: false))
        panel.contentView = hv
        self.hostingView = hv

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 100
            let y = screenFrame.maxY - 80
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFrontRegardless()
        self.window = panel
    }

    func updateTranscribing(_ isTranscribing: Bool) {
        hostingView?.rootView = RecordingOverlay(isTranscribing: isTranscribing)
    }

    func dismiss() {
        window?.close()
        window = nil
        hostingView = nil
    }
}
