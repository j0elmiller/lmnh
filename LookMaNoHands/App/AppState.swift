import SwiftUI
import Observation
import KeyboardShortcuts
import os

private let logger = Logger(subsystem: "dev.lookmanohands.app", category: "AppState")
private let hotkeyLogger = Logger(subsystem: "dev.lookmanohands.app", category: "Hotkey")

// Nonisolated global + file-scope function so the closures passed to
// KeyboardShortcuts do NOT inherit @MainActor isolation. This prevents
// the Swift 6 runtime executor check that crashes when Carbon's event
// handler invokes the closure on a background thread.
private nonisolated(unsafe) var _hotkeyAppState: AppState?

private func registerHotkeys() {
    KeyboardShortcuts.onKeyUp(for: .toggleDictation) {
        hotkeyLogger.debug("toggleDictation fired")
        Task { @MainActor in
            await _hotkeyAppState?.toggleDictation()
        }
    }
    KeyboardShortcuts.onKeyUp(for: .readSelection) {
        Task { @MainActor in
            await _hotkeyAppState?.toggleReading()
        }
    }
}

@Observable
final class AppState: @unchecked Sendable {
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

    // MARK: - Services (initialized in @MainActor init)
    let audioRecorder: AudioRecorder
    let transcriptionEngine: TranscriptionEngine
    let speechEngine: SpeechEngine
    let textInjector: TextInjector
    let textSelector: TextSelector
    let permissionManager: PermissionManager

    // MARK: - Overlay
    @ObservationIgnored private var _overlayController: RecordingOverlayController?
    @MainActor var overlayController: RecordingOverlayController {
        if let existing = _overlayController { return existing }
        let controller = RecordingOverlayController()
        _overlayController = controller
        return controller
    }

    // MARK: - Init
    @MainActor init() {
        audioRecorder = AudioRecorder()
        transcriptionEngine = TranscriptionEngine()
        speechEngine = SpeechEngine()
        textInjector = TextInjector()
        textSelector = TextSelector()
        permissionManager = PermissionManager()
        Task { @MainActor [weak self] in
            self?.startupIfNeeded()
        }
    }

    // MARK: - Startup
    private var hasStarted = false

    @MainActor func startupIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true
        logger.info("startupIfNeeded called")
        checkPermissions()

        // Register hotkeys via file-scope nonisolated function so closures
        // don't inherit @MainActor isolation (avoids Carbon thread crash).
        _hotkeyAppState = self
        registerHotkeys()

        if !hasCompletedOnboarding {
            showOnboarding()
        }

        // Only auto-load models if onboarding is already done;
        // otherwise the user triggers download from the onboarding step.
        if hasCompletedOnboarding {
            Task { @MainActor in
                await loadModels()
            }
        }
    }

    // MARK: - Onboarding Window
    @ObservationIgnored var onboardingWindow: NSWindow?

    @MainActor func showOnboarding() {
        guard onboardingWindow == nil else { return }

        // Delay window creation so AppKit/MenuBarExtra has fully initialized.
        // Creating windows + activating during early startup corrupts AppKit's
        // internal window animation state and causes EXC_BAD_ACCESS.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self, self.onboardingWindow == nil else { return }

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 560, height: 550),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Welcome"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(
                rootView: OnboardingView()
                    .environment(self)
            )
            window.center()
            self.onboardingWindow = window
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @MainActor func dismissOnboarding() {
        onboardingWindow?.close()
        onboardingWindow = nil
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

    @MainActor func checkPermissions() {
        micPermissionGranted = permissionManager.hasMicrophonePermission
        accessibilityPermissionGranted = permissionManager.hasAccessibilityPermission
    }

    // MARK: - Dictation Flow
    @MainActor func toggleDictation() async {
        if isRecording {
            await stopDictation()
        } else {
            await startDictation()
        }
    }

    @MainActor func startDictation() async {
        guard sttModelLoaded else {
            errorMessage = "STT model not loaded yet"
            return
        }

        if !micPermissionGranted {
            let granted = await permissionManager.requestMicrophonePermission()
            micPermissionGranted = granted
            guard granted else {
                errorMessage = "Microphone permission required"
                return
            }
        }

        isRecording = true
        errorMessage = nil
        overlayController.show()
        audioRecorder.startRecording()
    }

    @MainActor func stopDictation() async {
        isRecording = false
        isTranscribing = true
        overlayController.updateTranscribing(true)

        do {
            let audioSamples = audioRecorder.stopRecording()
            guard !audioSamples.isEmpty else {
                isTranscribing = false
                overlayController.dismiss()
                return
            }

            var text = try await transcriptionEngine.transcribe(audioSamples: audioSamples)
            if text.trimmingCharacters(in: .whitespacesAndNewlines) == "[BLANK_AUDIO]" {
                text = ""
            }
            lastTranscription = text

            if !text.isEmpty {
                textInjector.inject(text: text)
            }
        } catch {
            logger.error("Transcription failed: \(error.localizedDescription)")
            errorMessage = "Transcription failed: \(error.localizedDescription)"
        }

        isTranscribing = false
        overlayController.dismiss()
    }

    // MARK: - TTS Flow
    @MainActor func toggleReading() async {
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
    @MainActor func loadModels() async {
        guard !isLoadingModels else { return }
        isLoadingModels = true

        async let sttResult: Void = transcriptionEngine.loadModel(named: sttModelName)
        async let ttsResult: Void = speechEngine.loadModel()

        do {
            try await sttResult
            sttModelLoaded = true
        } catch {
            logger.error("STT model failed: \(error.localizedDescription)")
            errorMessage = "Failed to load STT model: \(error.localizedDescription)"
        }

        do {
            try await ttsResult
            ttsModelLoaded = true
        } catch {
            logger.error("TTS model failed: \(error.localizedDescription)")
            errorMessage = "Failed to load TTS model: \(error.localizedDescription)"
        }

        isLoadingModels = false
        logger.info("Models loaded. STT=\(self.sttModelLoaded), TTS=\(self.ttsModelLoaded)")
    }
}

enum DictationMode: String, CaseIterable {
    case toggle = "Toggle"
    case pushToTalk = "Push to Talk"
}
