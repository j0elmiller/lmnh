import Foundation

/// Single source of truth for model locations inside the app bundle and on
/// disk. Used by STT/TTS engines to load bundled models and by the onboarding
/// UI to skip the "download" step when a release DMG ships with models.
///
/// The directory layout inside `Contents/Resources/`:
///
///   Models/
///     whisperkit/<model-name>/       -- WhisperKit model folder (mlmodelcs + tokenizer)
///     fluidaudio/Models/kokoro/      -- mirrors FluidAudio's `~/.cache` layout
///                                       so `seedKokoroCacheIfNeeded` can
///                                       straight-copy it.
enum BundledModels {
    /// Returns the bundled WhisperKit folder for `name` if it contains a
    /// usable model (config.json present), else nil. Engines pass the result
    /// to `WhisperKitConfig.modelFolder` to skip the Hugging Face download.
    static func whisperFolder(named name: String) -> URL? {
        guard let folder = Bundle.main.resourceURL?
            .appendingPathComponent("Models/whisperkit/\(name)") else { return nil }
        let sentinel = folder.appendingPathComponent("config.json")
        return FileManager.default.fileExists(atPath: sentinel.path) ? folder : nil
    }

    /// Source for seeding the FluidAudio Kokoro cache, if bundled. nil in dev
    /// builds where models aren't shipped.
    static var kokoroSource: URL? {
        guard let folder = Bundle.main.resourceURL?
            .appendingPathComponent("Models/fluidaudio/Models/kokoro") else { return nil }
        return FileManager.default.fileExists(atPath: folder.path) ? folder : nil
    }

    /// Destination FluidAudio hard-codes for Kokoro assets. Internal call
    /// sites in FluidAudio ignore any `directory:` override and read from
    /// here directly, so `SpeechEngine` seeds it on first launch.
    static var kokoroCacheDestination: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cache/fluidaudio/Models/kokoro")
    }
}
