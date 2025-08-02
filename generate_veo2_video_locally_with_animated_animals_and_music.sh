#!/bin/bash

# Define project and model details
PROJECT_ID="abiding-window-465512-p7"
LOCATION_ID="global"
API_ENDPOINT="aiplatform.googleapis.com"
MODEL_ID="gemini-2.5-flash-lite"
GENERATE_CONTENT_API="streamGenerateContent"

# Create request body
cat <<EOF > request.json
{
  "contents": [
    {
      "role": "user",
      "parts": [
        {
          "text": "Give me only a single, self-contained prompt for a Veo 2 video in Disney-Pixar 3D cartoon style. The prompt should describe a visually captivating and emotionally powerful short scene. Return only the prompt. No explanations, no breakdown, no formatting—just the prompt text."
        }
      ]
    }
  ]
}
EOF

# Save curl response to variable
PROMPT=$(curl -s \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://${API_ENDPOINT}/v1/projects/${PROJECT_ID}/locations/${LOCATION_ID}/publishers/google/models/${MODEL_ID}:${GENERATE_CONTENT_API}" \
  -d @request.json)

# Optional: print the raw JSON
echo "$PROMPT"

# Get only the generated prompt text
PROMPT_TEXT=$(echo "$PROMPT" | jq -r '.candidates[0].content.parts[0].text')

# Print the clean prompt
echo "$PROMPT_TEXT"
