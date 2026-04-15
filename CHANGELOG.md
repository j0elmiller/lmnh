# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `LICENSE` (MIT) so the license badge in the README is backed by an actual file
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md` for community hygiene
- GitHub issue and pull request templates
- GitHub Actions CI that builds the Debug configuration on every PR
- Dependabot configuration for Swift Package Manager and GitHub Actions updates
- `scripts/populate-models.sh` to pre-stage the Whisper and Kokoro models before a release build

## [0.1.0] - 2026-04-14

Initial release. First public DMG shared with friends and family.

### Added
- Menu bar app scaffold (`MenuBarExtra`) with idle / recording / transcribing / speaking / warning icon states
- Speech-to-text via WhisperKit, bound to `Option + Space`
- Text-to-speech via FluidAudio's Kokoro, bound to `Option + S` for selected text
- Onboarding wizard that walks through microphone and accessibility permissions and loads models
- Settings window (hotkeys, STT model selection, TTS voice selection)
- Recording overlay pill shown while dictating
- Release script that builds a hardened-runtime-signed DMG with models bundled

[Unreleased]: https://github.com/j0elmiller/lmnh/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/j0elmiller/lmnh/releases/tag/v0.1.0
