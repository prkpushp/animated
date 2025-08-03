#!/bin/bash

# Define project and model details
PROJECT_ID="qwiklabs-gcp-03-2e48b5d7d8f6"
LOCATION_ID="us-central1"
API_ENDPOINT="us-central1-aiplatform.googleapis.com"
MODEL_ID="veo-3.0-fast-generate-001"
STORAGE_URI="gs://qwiklabs-gcp-03-2e48b5d7d8f6-labconfig-bucket/output/"
LOCAL_DIR="./videos"

# Create local directory if it doesn't exist
mkdir -p "$LOCAL_DIR"

#!/bin/bash

# Define project and model details for PROMPT
LOCATION_ID_PROMPT="global"
API_ENDPOINT_PROMPT="aiplatform.googleapis.com"
MODEL_ID_PROMPT="gemini-2.5-flash-lite"
GENERATE_CONTENT_API_PROMPT="streamGenerateContent"

# Create request body
cat <<EOF > request.json
{
  "contents": [
    {
      "role": "user",
      "parts": [
        {
          "text": " Create video within Google AI practice only: Tied between two thick trees in a forest glade, a hammock sways with two figures entangled in rain-soaked warmth. The man, shirtless, lies on his side, brushing raindrops off the curvy woman’s shoulder. She’s curled in his arms in a clinging, off-shoulder micro dress, sheer from the monsoon. The camera glides slowly, capturing glistening skin, gentle fingers tracing rain trails, and lips brushing knuckles. Insects buzz softly in the distance."
        }
      ]
    }
  ]
}
EOF

# Step 1: Save response
curl -s \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://${API_ENDPOINT_PROMPT}/v1/projects/${PROJECT_ID}/locations/${LOCATION_ID_PROMPT}/publishers/google/models/${MODEL_ID_PROMPT}:${GENERATE_CONTENT_API_PROMPT}" \
  -d @request.json > prompt_lines.jsonl

# Step 2: Extract + combine prompt
PROMPT=$(jq -r '.[] | .candidates[0].content.parts[0].text' prompt_lines.jsonl | paste -sd '' -)

# Step 3: Display
echo -e "\n✅ Final Prompt:\n$PROMPT"


# Sanitize prompt for filename (replace spaces with underscores, remove special characters)
SANITIZED_PROMPT=$(echo "$PROMPT" | tr ' ' '_' | tr -dc '[:alnum:]_-' | cut -c 1-200)

# Check for required tools
if ! command -v gsutil &> /dev/null; then
  echo "Error: gsutil is not installed. Please install Google Cloud SDK."
  exit 1
fi
if ! command -v jq &> /dev/null; then
  echo "Warning: jq is not installed. Falling back to grep for parsing."
  USE_JQ=false
else
  USE_JQ=true
fi

# Display generated prompt
echo "Generated prompt: $PROMPT"
echo "Output filename: ${LOCAL_DIR}/${SANITIZED_PROMPT}.mp4"

# Create request.json for video generation
cat << EOF > request.json
{
  "instances": [
    {
      "prompt": "${PROMPT}"
    }
  ],
  "parameters": {
    "aspectRatio": "16:9",
    "sampleCount": 1,
    "durationSeconds": "8",
    "personGeneration": "allow_adult",
    "enablePromptRewriting": true,
    "addWatermark": true,
    "includeRaiReason": true,
    "storageUri": "${STORAGE_URI}"
  }
}
EOF

# Start video generation and get operation ID
echo "Initiating video generation with Veo 2.0..."
OPERATION_ID=$(curl -s \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://${API_ENDPOINT}/v1/projects/${PROJECT_ID}/locations/${LOCATION_ID}/publishers/google/models/${MODEL_ID}:predictLongRunning" \
  -d '@request.json' | sed -n 's/.*"name": "\(.*\)".*/\1/p')

if [ -z "$OPERATION_ID" ]; then
  echo "Error: Failed to get OPERATION_ID. Check authentication or API access."
  rm -f request.json
  exit 1
fi

echo "OPERATION_ID: ${OPERATION_ID}"

# Poll for operation completion
echo "Waiting for video generation to complete..."
MAX_ATTEMPTS=30
ATTEMPT=1
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  cat << EOF > fetch.json
  {
    "operationName": "${OPERATION_ID}"
  }
EOF

  RESPONSE=$(curl -s \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    "https://${API_ENDPOINT}/v1/projects/${PROJECT_ID}/locations/${LOCATION_ID}/publishers/google/models/${MODEL_ID}:fetchPredictOperation" \
    -d '@fetch.json')

  DONE=$(echo "$RESPONSE" | grep -o '"done": true')
  if [ -n "$DONE" ]; then
    echo "Video generation completed!"
    break
  fi
  echo "Operation in progress, attempt $ATTEMPT/$MAX_ATTEMPTS, waiting 10 seconds..."
  sleep 10
  ATTEMPT=$((ATTEMPT + 1))
  if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
    echo "Error: Operation timed out after $MAX_ATTEMPTS attempts"
    rm -f request.json fetch.json
    exit 1
  fi
done

# Extract video URI from response
if [ "$USE_JQ" = true ]; then
  VIDEO_URI=$(echo "$RESPONSE" | jq -r '.response.videos[].gcsUri' 2>/dev/null | head -n 1)
else
  VIDEO_URI=$(echo "$RESPONSE" | grep -o '"gcsUri": "[^"]*"' | sed 's/"gcsUri": "\([^"]*\)"/\1/' | grep '\.mp4$' | head -n 1)
fi

if [ -z "$VIDEO_URI" ]; then
  echo "Error: No video URI found in response"
  echo "Response: $RESPONSE"
  rm -f request.json fetch.json
  exit 1
fi

# Download video, add music, and delete from bucket
echo "Downloading video, adding music, and storing locally..."
FILENAME=$(basename "$VIDEO_URI")
OUTPUT_FILENAME="${LOCAL_DIR}/${SANITIZED_PROMPT}.mp4"
echo "Downloading $VIDEO_URI to ${LOCAL_DIR}/${FILENAME}"
gsutil cp "$VIDEO_URI" "${LOCAL_DIR}/${FILENAME}"
if [ $? -eq 0 ]; then
  echo "Successfully downloaded $FILENAME"
else
  echo "Error downloading $VIDEO_URI"
fi

# Clean up temporary files
rm -f request.json fetch.json

echo "Done! Animated video with YouTube Audio Library music is saved locally in $OUTPUT_FILENAME."
echo "No video remains in the bucket."

