import Foundation
import WhisperKit

final class TranscriptionEngine: @unchecked Sendable {
    private var whisperKit: WhisperKit?

    var isLoaded: Bool { whisperKit != nil }

    func loadModel(named modelName: String) async throws {
        // If the model is bundled, load from disk and skip the Hugging Face
        // download. Otherwise fall back to WhisperKit's default hub behavior.
        let bundledFolder = BundledModels.whisperFolder(named: modelName)?.path
        let config = WhisperKitConfig(model: modelName, modelFolder: bundledFolder, load: true)
        whisperKit = try await WhisperKit(config)
    }

    func transcribe(audioSamples: [Float]) async throws -> String {
        guard let whisperKit else {
            throw TranscriptionError.modelNotLoaded
        }

        let results = try await whisperKit.transcribe(audioArray: audioSamples)
        let raw = results.map(\.text).joined(separator: " ")
        return Self.sanitize(raw)
    }

    // Strips Whisper's non-speech annotations ([BLANK_AUDIO], [MUSIC],
    // [INAUDIBLE], [BIRDS CHIRPING], etc.) and any stray special tokens
    // (<|nospeech|>, <|startoftranscript|>, ...) that can leak through.
    static func sanitize(_ raw: String) -> String {
        var cleaned = raw.replacing(/\[[^\]]*\]/, with: "")
        cleaned = cleaned.replacing(/<\|[^|>]*\|>/, with: "")
        cleaned = cleaned.replacing(/\s+/, with: " ")
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func unloadModel() {
        whisperKit = nil
    }
}

enum TranscriptionError: LocalizedError {
    case modelNotLoaded

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Speech recognition model is not loaded"
        }
    }
}
