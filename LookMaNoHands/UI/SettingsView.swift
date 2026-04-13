import SwiftUI
import KeyboardShortcuts

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
        .frame(width: 450, height: 300)
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
                        .foregroundStyle(appState.micPermissionGranted ? .green : .red)
                }

                HStack {
                    Text("Accessibility")
                    Spacer()
                    Image(systemName: appState.accessibilityPermissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(appState.accessibilityPermissionGranted ? .green : .red)
                    if !appState.accessibilityPermissionGranted {
                        Button("Open Settings") {
                            appState.permissionManager.openAccessibilitySettings()
                        }
                    }
                }
            }
        }
        .padding()
        .onAppear { appState.checkPermissions() }
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
        .padding()
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

                HStack {
                    Text("Status")
                    Spacer()
                    if appState.sttModelLoaded {
                        Text("Loaded").foregroundStyle(.green)
                    } else if appState.isLoadingModels {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Not loaded").foregroundStyle(.secondary)
                    }
                }
            }

            Section("Text-to-Speech") {
                HStack {
                    Text("Status")
                    Spacer()
                    if appState.ttsModelLoaded {
                        Text("Loaded").foregroundStyle(.green)
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
        .padding()
    }
}
