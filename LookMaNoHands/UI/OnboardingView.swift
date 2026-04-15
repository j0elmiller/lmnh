import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var currentStep = 0
    @State private var accessibilityCheckFailed = false

    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("Welcome to Look Ma No Hands")
                .font(.title)
                .fontWeight(.bold)

            Text("System-wide dictation and text-to-speech,\nrunning entirely on your Mac.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

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
                    Button("Get Started") {
                        appState.hasCompletedOnboarding = true
                        appState.dismissOnboarding()
                    }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(40)
        .frame(width: 560)
        .frame(minHeight: 450)
        .onAppear {
            appState.checkPermissions()
            // Auto-advance past already-granted steps
            if appState.micPermissionGranted && currentStep == 0 {
                currentStep = 1
            }
            if appState.accessibilityPermissionGranted && currentStep == 1 {
                currentStep = 2
            }
            if appState.sttModelLoaded && appState.ttsModelLoaded && currentStep == 2 {
                currentStep = 3
            }
        }
    }

    // MARK: - Steps

    private var microphoneStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(LinearGradient.brand)

            Text("Microphone Access")
                .font(.headline)

            Text("Required for speech-to-text dictation.")
                .foregroundStyle(.secondary)

            if appState.micPermissionGranted {
                Label("Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.stateReady)
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
                .foregroundStyle(LinearGradient.brand)

            Text("Accessibility Access")
                .font(.headline)

            Text("Required to type text into other apps and read selected text.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if appState.accessibilityPermissionGranted {
                Label("Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.stateReady)
            } else {
                Text("Toggle on **LookMaNoHands** in System Settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Open System Settings") {
                    // Trigger the system prompt so the app appears in the list
                    appState.permissionManager.requestAccessibilityPermission()
                }
                .buttonStyle(.bordered)

                Button("I've enabled it") {
                    appState.checkPermissions()
                    accessibilityCheckFailed = !appState.accessibilityPermissionGranted
                }
                .font(.caption)

                if accessibilityCheckFailed {
                    Text("Not detected. If you already toggled it on, try removing LookMaNoHands from the list and re-adding it (use the + button), then click \"I've enabled it\" again.")
                        .font(.caption)
                        .foregroundStyle(Color.stateRecording)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var modelStep: some View {
        let copy: ModelStepCopy = BundledModels.whisperFolder(named: appState.sttModelName) != nil
            ? .bundled
            : .download

        return VStack(spacing: 16) {
            Image(systemName: "cpu.fill")
                .font(.system(size: 48))
                .foregroundStyle(LinearGradient.brand)

            Text(copy.title)
                .font(.headline)

            Text(copy.subtitle)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if appState.sttModelLoaded && appState.ttsModelLoaded {
                Label("Models Ready", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.stateReady)
            } else if appState.isLoadingModels {
                VStack(spacing: 8) {
                    ProgressView()
                    Text(copy.progress)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                if let error = appState.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.stateRecording)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(copy.cta) {
                    appState.errorMessage = nil
                    Task { await appState.loadModels() }
                }
                .buttonStyle(.bordered)
            }
        }
        .task {
            // Auto-kick loading when models are bundled — there's no 1GB
            // download to wait on, so the user shouldn't have to click.
            if copy == .bundled
                && !appState.isLoadingModels
                && !(appState.sttModelLoaded && appState.ttsModelLoaded) {
                await appState.loadModels()
            }
        }
    }

    private var doneStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.stateReady)

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

private enum ModelStepCopy {
    case bundled
    case download

    var title: String {
        switch self {
        case .bundled: "Prepare Models"
        case .download: "Download Models"
        }
    }

    var subtitle: String {
        switch self {
        case .bundled: "Models are bundled with the app — this\nwill only take a moment."
        case .download: "Models run locally on your Mac.\nThe base model (~150 MB) is recommended."
        }
    }

    var progress: String {
        switch self {
        case .bundled: "Preparing models..."
        case .download: "Downloading models..."
        }
    }

    var cta: String {
        switch self {
        case .bundled: "Continue"
        case .download: "Download Now"
        }
    }
}
