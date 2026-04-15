# Security Policy

Thanks for helping keep Look Ma No Hands safe.

## Scope

Look Ma No Hands is a non-sandboxed native macOS app that:

- Captures microphone audio for on-device speech-to-text
- Uses the Accessibility API to read selected text from the focused app
- Injects dictated text into the focused text field via synthetic keyboard events and the clipboard
- Downloads CoreML models from Hugging Face on first run (when not bundled)

Anything touching those surfaces is in scope. Particularly of interest:

- Unintended data exfiltration (mic audio, selected text, injected text)
- Ways a malicious input could escape the transcription or TTS pipeline
- Clipboard leakage (we use the clipboard briefly during injection and restore the prior value — bugs in that flow are interesting)
- Model-loading paths that could be tricked into loading untrusted code
- Accessibility permission misuse

Out of scope:

- Issues that require a local attacker who already has the ability to run code as your user
- Reports that boil down to "macOS itself prompted for a permission" — that's expected
- Findings in upstream dependencies (WhisperKit, FluidAudio, KeyboardShortcuts); please report those to the respective projects

## Reporting a vulnerability

**Please do not open a public GitHub issue for security reports.**

Use GitHub's private vulnerability reporting:

1. Go to the [Security tab](https://github.com/j0elmiller/lmnh/security) of the repository
2. Click **Report a vulnerability**
3. Fill in the form with steps to reproduce, impact, and any suggested mitigation

If you can't use GitHub's form for any reason, send a direct message to [@j0elmiller](https://github.com/j0elmiller) on GitHub asking for a secure channel.

## What to expect

This is a solo-maintained project, so timelines are best-effort:

- I'll acknowledge your report within a few days
- I'll follow up with an assessment and a rough timeline for a fix
- Once a fix ships, I'll credit you in the release notes unless you'd prefer to stay anonymous

Please give me a reasonable window to fix the issue before any public disclosure.
