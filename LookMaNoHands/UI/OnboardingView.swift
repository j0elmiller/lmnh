import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var currentStep = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("Welcome to Look Ma No Hands")
                .font(.title)
                .fontWeight(.bold)

            Text("System-wide dictation and text-to-speech, running entirely on your Mac.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()

            // Steps
            switch currentStep {
            case 0:
                microphoneStep
            case 1:
                accessibilityStep
            case 2:
                modelStep
            default:
                doneStep
            }

            Spacer()

            // Navigation
            HStack {
                if currentStep > 0 {
                    Button("Back") { currentStep -= 1 }
                }
                Spacer()
                if currentStep < 3 {
                    Button("Next") { currentStep += 1 }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") { dismiss() }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(32)
        .frame(width: 500, height: 400)
    }

    // MARK: - Steps

    private var microphoneStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Microphone Access")
                .font(.headline)

            Text("Required for speech-to-text dictation.")
                .foregroundStyle(.secondary)

            if appState.micPermissionGranted {
                Label("Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Grant Permission") {
                    Task {
                        _ = await appState.permissionManager.requestMicrophonePermission()
                        appState.checkPermissions()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var accessibilityStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.raised.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Accessibility Access")
                .font(.headline)

            Text("Required to type text into other apps and read selected text.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if appState.accessibilityPermissionGranted {
                Label("Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Open System Settings") {
                    appState.permissionManager.openAccessibilitySettings()
                }
                .buttonStyle(.bordered)

                Button("Check Again") {
                    appState.checkPermissions()
                }
                .font(.caption)
            }
        }
    }

    private var modelStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "cpu.fill")
                .font(.system(size: 48))
                .foregroundStyle(.purple)

            Text("Download Models")
                .font(.headline)

            Text("Models run locally on your Mac. The base model (~150 MB) is recommended to start.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if appState.sttModelLoaded && appState.ttsModelLoaded {
                Label("Models Ready", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if appState.isLoadingModels {
                ProgressView("Downloading models...")
            } else {
                Button("Download Now") {
                    Task { await appState.loadModels() }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var doneStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("All Set!")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Label("Option + Space to dictate", systemImage: "mic.fill")
                Label("Option + S to read selected text", systemImage: "speaker.wave.2.fill")
            }
            .font(.body)
        }
    }
}
