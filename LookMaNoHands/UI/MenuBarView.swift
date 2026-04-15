import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            statusSection
            Divider()
            actionButtons
            Divider()
            lastTranscriptionSection
            errorSection
            footerSection
        }
        .padding(Theme.padding)
        .frame(width: Theme.popoverWidth)
    }

    // MARK: - Status

    private var statusSection: some View {
        HStack {
            statusIndicator
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.headline)
            Spacer()
        }
    }

    // Ready state paints the indicator with the brand gradient so the popover
    // carries a visual tie-in to the app icon. Active states keep distinct hues
    // for at-a-glance feedback.
    @ViewBuilder
    private var statusIndicator: some View {
        if isReady {
            Circle().fill(LinearGradient.brand)
        } else {
            Circle().fill(statusColor)
        }
    }

    private var isReady: Bool {
        !appState.isRecording
            && !appState.isTranscribing
            && !appState.isSpeaking
            && !appState.isLoadingModels
            && appState.sttModelLoaded
            && appState.ttsModelLoaded
    }

    private var statusColor: Color {
        if appState.isRecording { return .stateRecording }
        if appState.isTranscribing { return .stateTranscribing }
        if appState.isSpeaking { return .stateSpeaking }
        if appState.isLoadingModels { return .stateLoading }
        if appState.sttModelLoaded && appState.ttsModelLoaded { return .stateReady }
        return .stateIdle
    }

    private var statusText: String {
        if appState.isRecording { return "Recording..." }
        if appState.isTranscribing { return "Transcribing..." }
        if appState.isSpeaking { return "Speaking..." }
        if appState.isLoadingModels { return "Loading models..." }
        if appState.sttModelLoaded && appState.ttsModelLoaded { return "Ready" }
        return "Setup needed"
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                Task { await appState.toggleDictation() }
            } label: {
                HStack {
                    Image(systemName: appState.isRecording ? "stop.circle.fill" : "mic.fill")
                    Text(appState.isRecording ? "Stop Dictation" : "Start Dictation")
                    Spacer()
                    Text("Option+Space")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(!appState.sttModelLoaded || appState.isTranscribing)

            Button {
                Task { await appState.toggleReading() }
            } label: {
                HStack {
                    Image(systemName: appState.isSpeaking ? "stop.circle.fill" : "speaker.wave.2.fill")
                    Text(appState.isSpeaking ? "Stop Reading" : "Read Selection")
                    Spacer()
                    Text("Option+S")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(!appState.ttsModelLoaded)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Last Transcription (stable tree – use opacity to hide)

    private var lastTranscriptionSection: some View {
        let text = appState.lastTranscription ?? ""
        let visible = !text.isEmpty
        return VStack(alignment: .leading, spacing: 4) {
            Divider()
            Text("Last transcription:")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.body)
                .lineLimit(3)
                .textSelection(.enabled)
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }
            .font(.caption)
            .buttonStyle(.plain)
            .foregroundStyle(Color.stateSpeaking)
        }
        .opacity(visible ? 1 : 0)
        .frame(height: visible ? nil : 0)
        .clipped()
    }

    // MARK: - Error (stable tree – use opacity to hide)

    private var errorSection: some View {
        let error = appState.errorMessage ?? ""
        let visible = !error.isEmpty
        return HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.stateLoading)
            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .opacity(visible ? 1 : 0)
        .frame(height: visible ? nil : 0)
        .clipped()
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Spacer()
            Button("Settings") {
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
                // In LSUIElement + MenuBarExtra apps, the popover dismissing
                // hands focus back to whatever app was previously frontmost,
                // so the Settings window ends up buried. Defer to the next
                // runloop tick (after the popover has dismissed) and force
                // the window above everything else.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    NSApp.activate(ignoringOtherApps: true)
                    if let settings = NSApp.windows.first(where: {
                        $0.identifier?.rawValue == "com_apple_SwiftUI_Settings_window"
                    }) {
                        settings.makeKeyAndOrderFront(nil)
                        settings.orderFrontRegardless()
                    }
                }
            }
            .font(.caption)
            Button("Quit") { NSApplication.shared.terminate(nil) }.font(.caption)
        }
    }
}
