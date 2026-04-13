import SwiftUI
import KeyboardShortcuts

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status
            statusSection

            Divider()

            // Actions
            actionButtons

            Divider()

            // Last transcription
            if let text = appState.lastTranscription {
                lastTranscriptionSection(text)
                Divider()
            }

            // Errors
            if let error = appState.errorMessage {
                errorSection(error)
                Divider()
            }

            // Footer
            footerSection
        }
        .padding(12)
        .frame(width: 300)
        .task {
            appState.checkPermissions()
            if !appState.hasCompletedOnboarding {
                openWindow(id: "onboarding")
            }
            if !appState.sttModelLoaded || !appState.ttsModelLoaded {
                await appState.loadModels()
            }
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.headline)
            Spacer()
        }
    }

    private var statusColor: Color {
        if appState.isRecording { return .red }
        if appState.isTranscribing { return .orange }
        if appState.isSpeaking { return .blue }
        if appState.isLoadingModels { return .yellow }
        if appState.sttModelLoaded && appState.ttsModelLoaded { return .green }
        return .gray
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
                    KeyboardShortcuts.Recorder(for: .toggleDictation)
                        .fixedSize()
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
                    KeyboardShortcuts.Recorder(for: .readSelection)
                        .fixedSize()
                }
            }
            .disabled(!appState.ttsModelLoaded)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Last Transcription

    private func lastTranscriptionSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
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
            .foregroundStyle(.blue)
        }
    }

    // MARK: - Error

    private func errorSection(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            if !appState.micPermissionGranted || !appState.accessibilityPermissionGranted {
                Button("Grant Permissions") {
                    if !appState.micPermissionGranted {
                        Task { _ = await appState.permissionManager.requestMicrophonePermission() }
                    }
                    if !appState.accessibilityPermissionGranted {
                        appState.permissionManager.requestAccessibilityPermission()
                    }
                    appState.checkPermissions()
                }
                .font(.caption)
            }

            Spacer()

            SettingsLink {
                Text("Settings")
            }
            .font(.caption)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.caption)
        }
    }
}
