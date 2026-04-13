import SwiftUI
import Observation

@Observable
@MainActor
final class AppState {
    // MARK: - Recording State
    var isRecording = false
    var isTranscribing = false
    var lastTranscription: String?

    // MARK: - TTS State
    var isSpeaking = false

    // MARK: - Model State
    var sttModelLoaded = false
    var ttsModelLoaded = false
    var isLoadingModels = false
    var modelLoadProgress: Double = 0

    // MARK: - Permissions
    var micPermissionGranted = false
    var accessibilityPermissionGranted = false

    // MARK: - Errors
    var errorMessage: String?

    // MARK: - Settings
    var sttModelName = "openai_whisper-base"
    var dictationMode: DictationMode = .toggle

    // MARK: - First Launch
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    // MARK: - Services
    let audioRecorder = AudioRecorder()
    let transcriptionEngine = TranscriptionEngine()
    let speechEngine = SpeechEngine()
    let textInjector = TextInjector()
    let textSelector = TextSelector()
    let permissionManager = PermissionManager()

    // MARK: - Overlay
    private var _overlayController: RecordingOverlayController?
    var overlayController: RecordingOverlayController {
        if let existing = _overlayController { return existing }
        let controller = RecordingOverlayController(appState: self)
        _overlayController = controller
        return controller
    }

    // MARK: - Menu Bar Icon
    var menuBarIcon: String {
        if isRecording { return "mic.fill" }
        if isTranscribing { return "ellipsis.circle" }
        if isSpeaking { return "speaker.wave.2.fill" }
        if !micPermissionGranted || !accessibilityPermissionGranted {
            return "exclamationmark.triangle"
        }
        return "mic.circle"
    }

    func checkPermissions() {
        micPermissionGranted = permissionManager.hasMicrophonePermission
        accessibilityPermissionGranted = permissionManager.hasAccessibilityPermission
    }

    // MARK: - Dictation Flow
    func toggleDictation() async {
        if isRecording {
            await stopDictation()
        } else {
            await startDictation()
        }
    }

    func startDictation() async {
        guard sttModelLoaded else {
            errorMessage = "STT model not loaded yet"
            return
        }
        guard micPermissionGranted else {
            errorMessage = "Microphone permission required"
            return
        }

        isRecording = true
        errorMessage = nil
        overlayController.show()
        audioRecorder.startRecording()
    }

    func stopDictation() async {
        isRecording = false
        isTranscribing = true

        do {
            let audioSamples = audioRecorder.stopRecording()
            guard !audioSamples.isEmpty else {
                isTranscribing = false
                overlayController.dismiss()
                return
            }

            let text = try await transcriptionEngine.transcribe(audioSamples: audioSamples)
            lastTranscription = text

            if !text.isEmpty {
                textInjector.inject(text: text)
            }
        } catch {
            errorMessage = "Transcription failed: \(error.localizedDescription)"
        }

        isTranscribing = false
        overlayController.dismiss()
    }

    // MARK: - TTS Flow
    func toggleReading() async {
        if isSpeaking {
            speechEngine.stop()
            isSpeaking = false
            return
        }

        guard let selectedText = textSelector.getSelectedText(), !selectedText.isEmpty else {
            errorMessage = "No text selected"
            return
        }

        isSpeaking = true
        errorMessage = nil

        do {
            try await speechEngine.speak(text: selectedText)
        } catch {
            errorMessage = "TTS failed: \(error.localizedDescription)"
        }

        isSpeaking = false
    }

    // MARK: - Model Loading
    func loadModels() async {
        isLoadingModels = true

        do {
            try await transcriptionEngine.loadModel(named: sttModelName)
            sttModelLoaded = true
        } catch {
            errorMessage = "Failed to load STT model: \(error.localizedDescription)"
        }

        do {
            try await speechEngine.loadModel()
            ttsModelLoaded = true
        } catch {
            errorMessage = "Failed to load TTS model: \(error.localizedDescription)"
        }

        isLoadingModels = false
    }
}

enum DictationMode: String, CaseIterable {
    case toggle = "Toggle"
    case pushToTalk = "Push to Talk"
}
