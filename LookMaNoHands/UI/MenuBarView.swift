import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

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
        .padding(12)
        .frame(width: 280)
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
            .foregroundStyle(.blue)
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
                .foregroundStyle(.yellow)
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
            SettingsLink { Text("Settings") }.font(.caption)
            Button("Quit") { NSApplication.shared.terminate(nil) }.font(.caption)
        }
    }
}
