# Contributing to Look Ma No Hands

Thanks for your interest in improving this project. This guide covers everything you need to get a local dev build running, where common changes live, and how to submit your work.

End users looking for install instructions should see [INSTALL.md](INSTALL.md) instead.

## Prerequisites

- **macOS 15.0 or newer**
- **Apple Silicon Mac** (WhisperKit and Kokoro CoreML models target the ANE)
- **Xcode 16+** (Swift 6 toolchain)
- Optional Homebrew tools, only needed for specific workflows:
  - `xcodegen` — required if you edit `project.yml` or need to regenerate `.xcodeproj`
  - `create-dmg` — required to run `scripts/release.sh`
  - `huggingface-cli` — used by `scripts/populate-models.sh` to fetch models

```bash
brew install xcodegen create-dmg huggingface-cli
```

## Quick start

```bash
git clone https://github.com/j0elmiller/lmnh.git
cd lmnh
xcodebuild -project LookMaNoHands.xcodeproj -scheme LookMaNoHands -configuration Debug build
```

The `.xcodeproj` is checked in, so this works from a fresh clone without XcodeGen. Open `LookMaNoHands.xcodeproj` in Xcode to run and debug the app normally.

On first launch the onboarding wizard will ask for **microphone** and **accessibility** permissions. Accessibility requires a quit-and-relaunch after granting to take effect.

## Regenerating the Xcode project

`project.yml` is the source of truth for the Xcode project configuration; `.xcodeproj` is a generated artifact that's committed so casual contributors don't need XcodeGen.

Regenerate when:

- You changed `project.yml` (added a source folder, package dep, build setting, etc.)
- Your local `.xcodeproj` got into a weird state and you want a clean slate

```bash
xcodegen generate
```

Commit the regenerated `.xcodeproj` alongside your `project.yml` change.

## Preparing models for release builds

Debug builds run fine without any models bundled — the app will download them from Hugging Face at runtime via WhisperKit and FluidAudio.

For release builds (`scripts/release.sh`) the models must be pre-staged in `LookMaNoHands/Resources/Models/` so the DMG ships self-contained:

```bash
./scripts/populate-models.sh
./scripts/release.sh
```

The populate script fetches the Whisper base model and Kokoro TTS model into the paths `release.sh` expects. It's safe to re-run — it skips what's already present.

## Project layout

The source tree is described in the [README](README.md#architecture). In short:

```
LookMaNoHands/
  App/        # @main, AppState (central @Observable state)
  Services/   # Audio capture, STT, TTS, text injection, permissions
  UI/         # Menu bar, onboarding, recording overlay, settings
```

### Where common changes go

| Change | Where to look |
|---|---|
| Global hotkeys | [`LookMaNoHands/App/AppState.swift`](LookMaNoHands/App/AppState.swift) (KeyboardShortcuts registration) |
| Menu bar icons | [`LookMaNoHands/Resources/Assets.xcassets/MenuIcon*.imageset/`](LookMaNoHands/Resources/Assets.xcassets/) |
| Permission flows | [`LookMaNoHands/Services/System/PermissionManager.swift`](LookMaNoHands/Services/System/PermissionManager.swift) |
| STT / transcription | [`LookMaNoHands/Services/STT/TranscriptionEngine.swift`](LookMaNoHands/Services/STT/TranscriptionEngine.swift) |
| TTS / reading aloud | [`LookMaNoHands/Services/TTS/SpeechEngine.swift`](LookMaNoHands/Services/TTS/SpeechEngine.swift) |
| Text injection | [`LookMaNoHands/Services/System/TextInjector.swift`](LookMaNoHands/Services/System/TextInjector.swift) |
| Settings UI | [`LookMaNoHands/UI/SettingsView.swift`](LookMaNoHands/UI/SettingsView.swift) |
| Onboarding wizard | [`LookMaNoHands/UI/OnboardingView.swift`](LookMaNoHands/UI/OnboardingView.swift) |
| Release packaging | [`scripts/release.sh`](scripts/release.sh) |

## Code style

There's no formatter wired up yet. Match the surrounding style of the file you're editing:

- Swift 6 strict concurrency — engines use the `@unchecked Sendable` pattern where needed; don't loosen it without a good reason
- 4-space indentation
- Prefer `@Observable` and value types over reference types and `ObservableObject`
- SwiftUI views are organized top-down, with private computed helpers at the bottom

## Commit style

Look at `git log` for the pattern. In short:

- Short imperative subject line ("Add X", "Fix Y", "Update Z"), under ~72 chars
- Capitalize the first word, no trailing period
- **No em-dashes** (use `-` or `--`)
- Body paragraphs only when the change benefits from explanation

## Pull requests

1. Open an issue first if you're proposing something non-trivial (new feature, refactor, behavior change). Small fixes and doc tweaks don't need one.
2. Keep PRs focused — one topic per PR. Split mechanical renames from behavior changes.
3. In the description: explain the user-visible change and how you verified it.
4. Include screenshots or a short GIF for any UI change.
5. Make sure the Debug build passes locally before pushing. CI will run the same check against `macos-15`.
6. It's fine to push work-in-progress as a draft PR — it exposes it to CI and lets reviewers weigh in early.

## Filing issues

- **Bugs** — use the bug report template. Include your macOS version, app version, steps to reproduce, and any relevant `Console.app` output filtered for "LookMaNoHands".
- **Feature requests** — use the feature request template. Describe the problem before the solution.
- **Security reports** — do *not* open a public issue. See [SECURITY.md](SECURITY.md).

## Code of Conduct

All participation is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating you agree to uphold it.

## License

By contributing you agree that your contributions will be licensed under the [MIT License](LICENSE).
