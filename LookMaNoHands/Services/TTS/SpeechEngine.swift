import Foundation
import TTSKit

final class SpeechEngine: @unchecked Sendable {
    private var ttsKit: TTSKit?

    var isLoaded: Bool { ttsKit != nil }

    func loadModel() async throws {
        ttsKit = try await TTSKit()
    }

    func speak(text: String) async throws {
        guard let ttsKit else {
            throw SpeechError.modelNotLoaded
        }

        _ = try await ttsKit.play(text: text)
    }

    func stop() {
        Task {
            await ttsKit?.audioOutput.stopPlayback()
        }
    }

    func unloadModel() {
        ttsKit = nil
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
