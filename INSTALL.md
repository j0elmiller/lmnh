# Installing Look Ma No Hands

A tiny bit of extra effort is needed because this app isn't signed through
Apple's paid notarization program. It's the same app — macOS just needs a
nudge to let you open it.

## 1. Install

Drag **Look Ma No Hands.app** from the DMG into the **Applications** folder.

## 2. Let macOS trust the app

Open **Terminal** (Applications > Utilities > Terminal, or Spotlight "Terminal"),
paste this one line, and press Return:

```
xattr -dr com.apple.quarantine /Applications/LookMaNoHands.app
```

This removes the "downloaded from the internet" flag that macOS adds to
unsigned apps. You only need to do it once.

## 3. Launch

Open the app from **Launchpad**, **Spotlight** ("Look Ma"), or the Applications
folder. An icon will appear in your menu bar (top-right of the screen).

## 4. Grant permissions

The app will walk you through this on first launch:

- **Microphone** — for speech-to-text dictation.
- **Accessibility** — so it can read text you've selected in other apps and
  type dictated text into focused text fields.

After granting Accessibility, **quit and relaunch** the app once — macOS
requires this for the permission to take effect.

## Using it

- **Option + Space** — start/stop dictation (or press-and-hold, configurable in Settings)
- **Option + S** — read selected text aloud
- Menu bar icon — click for quick access and Settings

## Troubleshooting

**"Look Ma No Hands is damaged and can't be opened"**
You missed step 2 — run the `xattr` command and try again.

**Dictation says "STT model not loaded yet"**
Give it a few seconds after launch — the models are loading from inside the
app bundle.

**TTS / "Read Selection" doesn't work**
Make sure Accessibility permission is granted (System Settings > Privacy &
Security > Accessibility) and that LookMaNoHands is **on** in the list.
If you still have issues, try removing LookMaNoHands from the list and
re-adding it with the `+` button.
