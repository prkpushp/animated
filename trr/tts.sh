#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   export PROJECT_ID="your-gcp-project-id"
#   export MODEL_NAME="gemini-2.5-flash-tts"     # default
#   export VOICE_NAME="K"                    # default (known to work for many)
#   ./tts.sh "Hello world" [out.wav]
#
# Auth:
#   Uses ADC via: gcloud auth application-default print-access-token
#   (Works with GOOGLE_APPLICATION_CREDENTIALS or gcloud ADC login.) [web:268]

: "${PROJECT_ID:?Set PROJECT_ID (e.g., export PROJECT_ID=modern-bolt-478009-a0)}"

TEXT="${1:?Usage: $0 'text to speak' [out.wav]}"
OUT="${2:-out.wav}"

MODEL_NAME="${MODEL_NAME:-gemini-2.5-pro-preview-tts}"   # Gemini-TTS model name [web:220]
VOICE_NAME="${VOICE_NAME:-Sadachbia}"                   # Change if needed

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# Gemini-TTS supports input.prompt; non-Gemini voices do not. [web:220]
if [[ "$MODEL_NAME" == gemini-* ]]; then
  REQ="$(jq -n \
    --arg prompt "Read aloud in a warm and friendly tone:" \
    --arg text "$TEXT" \
    --arg voice "$VOICE_NAME" \
    --arg model "$MODEL_NAME" \
    '{
      input: { prompt: $prompt, text: $text },
      voice: { languageCode: "en-us", name: $voice, model_name: $model },
      audioConfig: { audioEncoding: "LINEAR16" }
    }')"
else
  REQ="$(jq -n \
    --arg text "$TEXT" \
    --arg voice "$VOICE_NAME" \
    '{
      input: { text: $text },
      voice: { languageCode: "en-us", name: $voice },
      audioConfig: { audioEncoding: "LINEAR16" }
    }')"
fi

# Call Cloud Text-to-Speech synthesize endpoint. [web:271]
curl -sS -X POST \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "x-goog-user-project: ${PROJECT_ID}" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d "$REQ" \
  "https://texttospeech.googleapis.com/v1/text:synthesize" \
  > "$tmp"

# Fail fast if API returned an error. [web:271]
if jq -e '.error' "$tmp" >/dev/null; then
  echo "TTS API error:"
  jq '.error' "$tmp"
  exit 1
fi

AUDIO_B64="$(jq -r '.audioContent // empty' "$tmp")"
if [[ -z "${AUDIO_B64//[[:space:]]/}" ]]; then
  echo "No audioContent in response. Full response:"
  cat "$tmp"
  exit 1
fi

echo "$AUDIO_B64" | base64 -d > "$OUT"

ls -lh "$OUT"
file "$OUT" || true
echo "Saved: $OUT"
