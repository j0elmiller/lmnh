<p align="center">
  <img src="icon.png" width="128" height="128" alt="Look Ma No Hands">
</p>

<h1 align="center">Look Ma No Hands</h1>

<p align="center">
  System-wide dictation and text-to-speech for macOS, running entirely on your Mac.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2015%2B-blue" alt="macOS 15+">
  <img src="https://img.shields.io/badge/swift-6.0-orange" alt="Swift 6">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License">
  <a href="https://www.buymeacoffee.com/lmnh"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" height="20" alt="Buy Me a Coffee"></a>
</p>

---

A native macOS menu bar app that replaces cloud-based dictation and text-to-speech services with open-source models running 100% on-device. No subscriptions, no data leaving your Mac.

## Features

- **Speech-to-Text**: Press `Option + Space` to dictate anywhere. Your speech is transcribed locally using [WhisperKit](https://github.com/argmaxinc/WhisperKit) and injected at the cursor.
- **Text-to-Speech**: Select text in any app and press `Option + S` to hear it read aloud using on-device TTS.
- **Fully Local**: All models run on Apple Silicon via CoreML. Nothing is sent to the cloud.
- **System-Wide**: Works in any app with global hotkeys and accessibility-based text injection.

## Requirements

- macOS 15.0+
- Apple Silicon Mac

## Getting Started

1. Clone and build:
   ```bash
   git clone git@github.com:j0elmiller/lmnh.git
   cd lmnh
   xcodebuild -project LookMaNoHands.xcodeproj -scheme LookMaNoHands -configuration Debug
   ```

2. On first launch, the onboarding wizard will guide you through:
   - Granting **microphone** permission
   - Enabling **accessibility** access in System Settings
   - Downloading the speech models (~150 MB)

3. Use it:
   | Shortcut | Action |
   |---|---|
   | `Option + Space` | Toggle dictation (speak to type) |
   | `Option + S` | Read selected text aloud |

4. Read the menu bar icon. The icon is a simplified `mnh` monogram (mic on the left, speaker on the right). The mic stays the same across all states; the speaker side and any accent marks change to show what the app is doing, so you can tell state at a glance without opening the popover:

   | Icon | State | What it means |
   |---|---|---|
   | <img src="LookMaNoHands/Resources/Assets.xcassets/MenuIconIdle.imageset/MenuIconIdle.svg" alt="Idle" width="24" height="24"> | **Idle** | Ready to go. Models are loaded and both mic + accessibility permissions are granted. |
   | <img src="LookMaNoHands/Resources/Assets.xcassets/MenuIconRecording.imageset/MenuIconRecording.svg" alt="Recording" width="24" height="24"> | **Recording** | Actively capturing mic audio. Start speaking, then press `Option + Space` again to stop (or release in push-to-talk mode). |
   | <img src="LookMaNoHands/Resources/Assets.xcassets/MenuIconTranscribing.imageset/MenuIconTranscribing.svg" alt="Transcribing" width="24" height="24"> | **Transcribing** | Recording stopped; WhisperKit is converting audio into text and injecting it at the cursor. |
   | <img src="LookMaNoHands/Resources/Assets.xcassets/MenuIconSpeaking.imageset/MenuIconSpeaking.svg" alt="Speaking" width="24" height="24"> | **Speaking** | Reading selected text aloud via TTS. Press `Option + S` again to stop. |
   | <img src="LookMaNoHands/Resources/Assets.xcassets/MenuIconWarning.imageset/MenuIconWarning.svg" alt="Warning" width="24" height="24"> | **Warning** | A required permission is missing (microphone or accessibility). Open the popover and re-run onboarding or the relevant System Settings pane to resolve. |

   The icons are rendered as template images, so macOS tints them to match your menu bar (light, dark, or Reduce Transparency).

## Architecture

Pure Swift/SwiftUI menu bar app with three dependencies:

| Dependency | Purpose |
|---|---|
| [WhisperKit](https://github.com/argmaxinc/WhisperKit) | On-device speech-to-text (Whisper via CoreML) |
| [TTSKit](https://github.com/argmaxinc/WhisperKit) | On-device text-to-speech |
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) | Global hotkey registration |

```
LookMaNoHands/
  App/
    LookMaNoHandsApp.swift    # @main, MenuBarExtra
    AppState.swift             # Central @Observable state
  Services/
    Audio/AudioRecorder.swift  # AVAudioEngine mic capture
    STT/TranscriptionEngine.swift
    TTS/SpeechEngine.swift
    System/
      TextInjector.swift       # AX + clipboard text injection
      TextSelector.swift       # AX selected text extraction
      PermissionManager.swift  # Mic + accessibility checks
  UI/
    MenuBarView.swift          # Menu bar dropdown
    OnboardingView.swift       # First-launch wizard
    RecordingOverlay.swift     # Floating pill during dictation
    SettingsView.swift         # Preferences window
```

## Support

If this app saves you the cost of a Wispr/Speechify subscription and you'd like to toss a few bucks my way, I'd appreciate it, but it's entirely optional. The app is and will stay free and open-source.

<p align="center">
  <a href="https://www.buymeacoffee.com/lmnh"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" height="50" alt="Buy Me a Coffee"></a>
</p>

## License

MIT
