#!/bin/bash
set -e
PROMPT_INPUT="$1"
INDEX="$2"

if [ -z "$PROMPT_INPUT" ]; then
  PROMPT_INPUT="Generate one and only one tranquil, hyperrealistic natural scene..."
fi

ACCESS_TOKEN=$(gcloud auth print-access-token)
LOCATION="us-central1"
GEMINI_MODEL="gemini-2.0-flash-lite-001"

mkdir -p output

cat >output/gemini_prompt_request_$INDEX.json <<EOF
{
  "contents": [
    {
      "role": "user",
      "parts": [
        { "text": "Input: ${PROMPT_INPUT}\\n\\nCreate two creative prompts based on the above input, for:\\n1. An image generation AI...\\n2. A music generation AI..." }
      ]
    }
  ]
}
EOF

curl -s -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/publishers/google/models/${GEMINI_MODEL}:generateContent" \
  -d @output/gemini_prompt_request_$INDEX.json \
  -o output/gemini_prompts_response_$INDEX.json

RAW=$(jq -r '.candidates[0].content.parts[0].text' output/gemini_prompts_response_$INDEX.json || echo "")

IMAGE_PROMPT=$(echo "$RAW" | grep -E '^Image Prompt:' | sed 's/^Image Prompt:[[:space:]]*//')
MUSIC_PROMPT=$(echo "$RAW" | grep -E '^Music Prompt:' | sed 's/^Music Prompt:[[:space:]]*//')

echo "$IMAGE_PROMPT" > output/image_prompt_$INDEX.txt
echo "$MUSIC_PROMPT" > output/music_prompt_$INDEX.txt
