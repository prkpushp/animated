#!/bin/bash
set -e
INDEX="$1"
mkdir -p output

IMAGE_PROMPT=$(cat output/image_prompt_$INDEX.txt)
MUSIC_PROMPT=$(cat output/music_prompt_$INDEX.txt)
TIMESTAMP=$(date +'%Y%m%d%H%M%S')
ACCESS_TOKEN=$(gcloud auth print-access-token)

jq -Rs --arg prompt "$IMAGE_PROMPT" '
  {
    instances: [ { prompt: $prompt } ],
    parameters: { sampleCount: 1, aspectRatio: "16:9" }
  }' <<< "" > output/request_image_$INDEX.json

curl -s -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://us-central1-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/us-central1/publishers/google/models/imagen-4.0-generate-preview-06-06:predict" \
  -d @output/request_image_$INDEX.json \
  -o output/response_image_$INDEX.json

IMAGE_B64=$(jq -r '.predictions[0].bytesBase64Encoded' output/response_image_$INDEX.json)
echo "$IMAGE_B64" | base64 -d > "output/image-${INDEX}-$TIMESTAMP.png"

jq -Rs --arg prompt "$MUSIC_PROMPT" '
  {
    instances: [ { prompt: $prompt } ],
    parameters: { sampleCount: 1 }
  }' <<< "" > output/request_music_$INDEX.json

curl -s -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://us-central1-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/us-central1/publishers/google/models/lyria-002:predict" \
  -d @output/request_music_$INDEX.json \
  -o output/response_music_$INDEX.json

AUDIO_B64=$(jq -r '.predictions[0].bytesBase64Encoded' output/response_music_$INDEX.json)
echo "$AUDIO_B64" | base64 -d > "output/music-${INDEX}-$TIMESTAMP.wav"
