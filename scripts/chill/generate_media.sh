#!/bin/bash
set -e

mkdir -p output
TIMESTAMP=$(date +'%Y%m%d%H%M%S')
ACCESS_TOKEN=$(gcloud auth print-access-token)
IMAGE_PROMPT=$(cat output/image_prompt.txt)
MUSIC_PROMPT=$(cat output/music_prompt.txt)
PROJECT_ID=$(jq -r .project_id < "$GOOGLE_APPLICATION_CREDENTIALS")


if [ -z "$IMAGE_PROMPT" ] || [ -z "$MUSIC_PROMPT" ]; then
  echo "❌ One of the prompts is empty. Aborting."
  exit 1
fi

echo "🖼 Generating image with prompt:"
echo "$IMAGE_PROMPT"

jq -Rs --arg prompt "$IMAGE_PROMPT" '
  {
    instances: [ { prompt: $prompt } ],
    parameters: { sampleCount: 1, aspectRatio: "16:9" }
  }' <<< "" > request_image.json

curl -s -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://us-central1-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/us-central1/publishers/google/models/imagen-4.0-generate-preview-06-06:predict" \
  -d @request_image.json \
  -o response_image.json

IMAGE_B64=$(jq -r '.predictions[0].bytesBase64Encoded' response_image.json)
if [ "$IMAGE_B64" != "null" ] && [ -n "$IMAGE_B64" ]; then
  echo "$IMAGE_B64" | base64 -d > "output/image-$TIMESTAMP.png"
else
  echo "❌ Image generation failed."
  cat response_image.json
  exit 1
fi

echo "🎵 Generating music with prompt:"
echo "$MUSIC_PROMPT"

jq -Rs --arg prompt "$MUSIC_PROMPT" '
  {
    instances: [ { prompt: $prompt } ],
    parameters: { sampleCount: 1 }
  }' <<< "" > request_music.json

curl -s -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://us-central1-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/us-central1/publishers/google/models/lyria-002:predict" \
  -d @request_music.json \
  -o response_music.json

AUDIO_B64=$(jq -r '.predictions[0].bytesBase64Encoded' response_music.json)
if [ "$AUDIO_B64" != "null" ] && [ -n "$AUDIO_B64" ]; then
  echo "$AUDIO_B64" | base64 -d > "output/music-$TIMESTAMP.wav"
else
  echo "❌ Lyria rejected prompt. Retrying..."

  jq -Rs --arg prompt "A calming soundscape for deep sleep and relaxation, featuring soft ambient textures, gentle water sounds, and subtle Tibetan bowls in slow tempo." '
    {
      instances: [ { prompt: $prompt } ],
      parameters: { sampleCount: 1 }
    }' <<< "" > request_music_retry.json

  curl -s -X POST \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    "https://us-central1-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/us-central1/publishers/google/models/lyria-002:predict" \
    -d @request_music_retry.json \
    -o response_music_retry.json

  AUDIO_B64=$(jq -r '.predictions[0].bytesBase64Encoded' response_music_retry.json)
  if [ "$AUDIO_B64" != "null" ] && [ -n "$AUDIO_B64" ]; then
    echo "$AUDIO_B64" | base64 -d > "output/music-$TIMESTAMP.wav"
  else
    echo "❌ Still failed."
    cat response_music_retry.json
    exit 1
  fi
fi
