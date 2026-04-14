import Foundation
import AVFoundation
import FluidAudio
import os

private let logger = Logger(subsystem: "dev.lookmanohands.app", category: "SpeechEngine")

final class SpeechEngine: NSObject, @unchecked Sendable {
    private var ttsManager: KokoroTtsManager?
    private var player: AVAudioPlayer?
    private var cancelled = false
    private var finishContinuation: CheckedContinuation<Void, Never>?

    var isLoaded: Bool { ttsManager != nil }

    func loadModel() async throws {
        logger.info("Initializing Kokoro TTS...")
        try seedKokoroCacheIfNeeded()
        let manager = KokoroTtsManager()
        try await manager.initialize()
        ttsManager = manager
        logger.info("Kokoro TTS ready")
    }

    /// Copies bundled Kokoro models into FluidAudio's hard-coded cache dir on
    /// first launch. FluidAudio's internal call sites ignore any `directory:`
    /// override, so seeding the cache is the simplest way to ship
    /// fully-offline. No-op on subsequent launches, and no-op if the app was
    /// built without bundled models (dev builds, etc.).
    private func seedKokoroCacheIfNeeded() throws {
        let dest = BundledModels.kokoroCacheDestination
        if FileManager.default.fileExists(atPath: dest.path) { return }
        guard let src = BundledModels.kokoroSource else {
            logger.info("No bundled Kokoro payload found — will download on first init")
            return
        }

        logger.info("Seeding Kokoro cache from bundle -> \(dest.path)")
        try FileManager.default.createDirectory(
            at: dest.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.copyItem(at: src, to: dest)
    }

    func speak(text: String, voice: String, speed: Float) async throws {
        guard let ttsManager else {
            throw SpeechError.modelNotLoaded
        }

        cancelled = false

        let audioData = try await ttsManager.synthesize(
            text: text,
            voice: voice,
            voiceSpeed: speed
        )

        guard !cancelled else { return }

        let newPlayer = try AVAudioPlayer(data: audioData)
        newPlayer.delegate = self
        player = newPlayer

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            finishContinuation = continuation
            newPlayer.play()
        }

        player = nil
    }

    func stop() {
        cancelled = true
        player?.stop()
        player = nil
        resumeFinish()
    }

    func unloadModel() {
        ttsManager = nil
    }

    private func resumeFinish() {
        if let continuation = finishContinuation {
            finishContinuation = nil
            continuation.resume()
        }
    }
}

extension SpeechEngine: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        resumeFinish()
    }
}

enum SpeechError: LocalizedError {
    case modelNotLoaded

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Text-to-speech model is not loaded"
        }
    }
}
