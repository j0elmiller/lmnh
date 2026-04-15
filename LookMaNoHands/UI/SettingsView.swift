import SwiftUI
import KeyboardShortcuts

private struct VoiceOption: Hashable {
    let id: String
    let label: String
}

private let americanFemaleVoices: [VoiceOption] = [
    .init(id: "af_alloy", label: "Alloy"),
    .init(id: "af_aoede", label: "Aoede"),
    .init(id: "af_bella", label: "Bella"),
    .init(id: "af_heart", label: "Heart"),
    .init(id: "af_jessica", label: "Jessica"),
    .init(id: "af_kore", label: "Kore"),
    .init(id: "af_nicole", label: "Nicole"),
    .init(id: "af_nova", label: "Nova"),
    .init(id: "af_river", label: "River"),
    .init(id: "af_sarah", label: "Sarah"),
    .init(id: "af_sky", label: "Sky"),
]

private let americanMaleVoices: [VoiceOption] = [
    .init(id: "am_adam", label: "Adam"),
    .init(id: "am_echo", label: "Echo"),
    .init(id: "am_eric", label: "Eric"),
    .init(id: "am_fenrir", label: "Fenrir"),
    .init(id: "am_liam", label: "Liam"),
    .init(id: "am_michael", label: "Michael"),
    .init(id: "am_onyx", label: "Onyx"),
    .init(id: "am_puck", label: "Puck"),
    .init(id: "am_santa", label: "Santa"),
]

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            Tab("General", systemImage: "gear") {
                generalSettings
            }

            Tab("Shortcuts", systemImage: "keyboard") {
                shortcutSettings
            }

            Tab("Models", systemImage: "cpu") {
                modelSettings
            }
        }
        .frame(width: 480, height: 480)
    }

    // MARK: - General

    private var generalSettings: some View {
        @Bindable var state = appState
        return Form {
            Picker("Dictation Mode", selection: $state.dictationMode) {
                ForEach(DictationMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }

            Section("Permissions") {
                HStack {
                    Text("Microphone")
                    Spacer()
                    Image(systemName: appState.micPermissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(appState.micPermissionGranted ? Color.stateReady : Color.stateRecording)
                    if !appState.micPermissionGranted {
                        if appState.permissionManager.canPromptForMicrophone {
                            Button("Request Access") {
                                Task {
                                    let granted = await appState.permissionManager.requestMicrophonePermission()
                                    appState.micPermissionGranted = granted
                                }
                            }
                        } else {
                            Button("Open Settings") {
                                appState.permissionManager.openMicrophoneSettings()
                            }
                        }
                    }
                }

                HStack {
                    Text("Accessibility")
                    Spacer()
                    Image(systemName: appState.accessibilityPermissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(appState.accessibilityPermissionGranted ? Color.stateReady : Color.stateRecording)
                    if !appState.accessibilityPermissionGranted {
                        Button("Open Settings") {
                            appState.permissionManager.openAccessibilitySettings()
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { appState.checkPermissions() }
        .task {
            // Keep permission status live while Settings is open so grants
            // made in System Settings are reflected without reopening.
            while !Task.isCancelled {
                appState.checkPermissions()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    // MARK: - Shortcuts

    private var shortcutSettings: some View {
        Form {
            HStack {
                Text("Toggle Dictation")
                Spacer()
                KeyboardShortcuts.Recorder(for: .toggleDictation)
            }

            HStack {
                Text("Read Selection")
                Spacer()
                KeyboardShortcuts.Recorder(for: .readSelection)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Models

    private var modelSettings: some View {
        @Bindable var state = appState
        return Form {
            Section("Speech-to-Text") {
                Picker("Model", selection: $state.sttModelName) {
                    Text("Tiny (~75 MB)").tag("openai_whisper-tiny")
                    Text("Base (~150 MB)").tag("openai_whisper-base")
                    Text("Small (~500 MB)").tag("openai_whisper-small")
                    Text("Medium (~1.5 GB)").tag("openai_whisper-medium")
                    Text("Large V3 (~3 GB)").tag("openai_whisper-large-v3")
                }
                .onChange(of: state.sttModelName) { _, _ in
                    Task { await appState.reloadSTT() }
                }

                HStack {
                    Text("Status")
                    Spacer()
                    if appState.sttModelLoaded {
                        Text("Loaded").foregroundStyle(Color.stateReady)
                    } else if appState.isLoadingModels {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Not loaded").foregroundStyle(.secondary)
                    }
                }
            }

            Section("Text-to-Speech") {
                HStack {
                    Picker("Voice", selection: $state.ttsVoice) {
                        ForEach(americanFemaleVoices, id: \.id) { v in
                            Text("\(v.label) (F)").tag(v.id)
                        }
                        ForEach(americanMaleVoices, id: \.id) { v in
                            Text("\(v.label) (M)").tag(v.id)
                        }
                    }
                    .onChange(of: state.ttsVoice) { _, _ in
                        Task { await appState.previewVoice() }
                    }

                    Button {
                        Task { await appState.previewVoice() }
                    } label: {
                        Image(systemName: appState.isSpeaking ? "stop.fill" : "play.fill")
                    }
                    .buttonStyle(.borderless)
                    .disabled(!appState.ttsModelLoaded)
                    .help("Preview voice")
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Speed")
                        Spacer()
                        Text(String(format: "%.2fx", state.ttsSpeed))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $state.ttsSpeed, in: 0.5...2.0, step: 0.1)
                }

                HStack {
                    Text("Status")
                    Spacer()
                    if appState.ttsModelLoaded {
                        Text("Loaded").foregroundStyle(Color.stateReady)
                    } else if appState.isLoadingModels {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Not loaded").foregroundStyle(.secondary)
                    }
                }
            }

            Button("Reload Models") {
                Task { await appState.loadModels() }
            }
        }
        .formStyle(.grouped)
    }
}
