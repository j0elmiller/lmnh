#!/usr/bin/env bash
#
# Pre-stages CoreML models into LookMaNoHands/Resources/Models/ so that
# scripts/release.sh can build a self-contained DMG.
#
# Debug builds DO NOT need this — WhisperKit and FluidAudio will fall back
# to downloading from Hugging Face on first launch when models aren't
# bundled. This script is only needed for release packaging.
#
# Prerequisites:
#   - huggingface-cli   (brew install huggingface-cli)
#
# Usage:
#   ./scripts/populate-models.sh              # fetches default: whisper-base + kokoro
#   WHISPER_MODEL=openai_whisper-small ./scripts/populate-models.sh
#
# Skips any download whose target folder already exists. Re-run anytime.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

MODELS_DIR="$ROOT/LookMaNoHands/Resources/Models"
WHISPER_MODEL="${WHISPER_MODEL:-openai_whisper-base}"

WHISPER_REPO="argmaxinc/whisperkit-coreml"
WHISPER_DEST="$MODELS_DIR/whisperkit/$WHISPER_MODEL"
WHISPER_SENTINEL="$WHISPER_DEST/AudioEncoder.mlmodelc/coremldata.bin"

KOKORO_REPO="FluidInference/kokoro-82m-coreml"
KOKORO_DEST="$MODELS_DIR/fluidaudio/Models/kokoro"
KOKORO_SENTINEL="$KOKORO_DEST/kokoro_21_5s.mlmodelc/coremldata.bin"

if ! command -v huggingface-cli >/dev/null 2>&1; then
  echo "ERROR: huggingface-cli is not installed."
  echo "       Install it with: brew install huggingface-cli"
  exit 1
fi

mkdir -p "$MODELS_DIR"

echo "==> Whisper model: $WHISPER_MODEL"
if [[ -f "$WHISPER_SENTINEL" ]]; then
  echo "    Already present, skipping."
else
  mkdir -p "$WHISPER_DEST"
  # --include restricts the download to just the model variant we want —
  # the repo hosts every Whisper size in separate subfolders.
  huggingface-cli download "$WHISPER_REPO" \
    --include "$WHISPER_MODEL/*" \
    --local-dir "$MODELS_DIR/whisperkit/_staging"
  # Flatten the downloaded folder up one level so the layout matches what
  # release.sh and BundledModels.whisperFolder expect.
  rsync -a "$MODELS_DIR/whisperkit/_staging/$WHISPER_MODEL/" "$WHISPER_DEST/"
  rm -rf "$MODELS_DIR/whisperkit/_staging"
  if [[ ! -f "$WHISPER_SENTINEL" ]]; then
    echo "ERROR: download finished but sentinel missing: $WHISPER_SENTINEL"
    exit 1
  fi
  echo "    Installed to $WHISPER_DEST"
fi

echo "==> Kokoro TTS model"
if [[ -f "$KOKORO_SENTINEL" ]]; then
  echo "    Already present, skipping."
else
  mkdir -p "$KOKORO_DEST"
  huggingface-cli download "$KOKORO_REPO" \
    --local-dir "$KOKORO_DEST"
  if [[ ! -f "$KOKORO_SENTINEL" ]]; then
    echo "ERROR: download finished but sentinel missing: $KOKORO_SENTINEL"
    echo "       The FluidInference/kokoro-82m-coreml repo layout may have changed."
    exit 1
  fi
  echo "    Installed to $KOKORO_DEST"
fi

echo
echo "Done. Models are staged in $MODELS_DIR"
echo "Next: ./scripts/release.sh"
