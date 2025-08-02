#!/bin/bash

# Define project and model details
PROJECT_ID="abiding-window-465512-p7"
LOCATION_ID="us-central1"
API_ENDPOINT="us-central1-aiplatform.googleapis.com"
MODEL_ID="veo-2.0-generate-001"
STORAGE_URI="gs://helloranjan1/output/"
AUDIO_FILE=`ls *.mp3| shuf | head -n 1`
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
          "text": "Give me only a single, self-contained prompt for a Veo 2 video in Disney-Pixar 3D cartoon style. The prompt should describe a visually captivating and emotionally powerful short scene. Return only the prompt. No explanations, no breakdown, no formatting—just the prompt text."
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
if ! command -v ffmpeg &> /dev/null; then
  echo "Error: ffmpeg is not installed. Please install ffmpeg to add music."
  echo "Install with: sudo apt-get install ffmpeg (Ubuntu) or brew install ffmpeg (macOS)"
  exit 1
fi
if [ ! -f "$AUDIO_FILE" ]; then
  echo "Error: Audio file '$AUDIO_FILE' not found."
  echo "Please download a royalty-free track from YouTube Audio Library (https://www.youtube.com/audiolibrary)."
  echo "Example: Search for 'cartoon battle music', download a track, and save as '$AUDIO_FILE' in this directory."
  exit 1
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
    "aspectRatio": "9:16",
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
  echo "Adding music from $AUDIO_FILE to $FILENAME..."
  ffmpeg -i "${LOCAL_DIR}/${FILENAME}" -i "$AUDIO_FILE" -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 -shortest -y "$OUTPUT_FILENAME"
  if [ $? -eq 0 ]; then
    echo "Successfully created $OUTPUT_FILENAME with music"
    echo "Note: If required, attribute the music in your project (e.g., 'Music: Cartoon Battle by Doug Maxwell from YouTube Audio Library')"
    rm -f "${LOCAL_DIR}/${FILENAME}" # Remove original video without music
    # Delete video from bucket
    echo "Deleting $VIDEO_URI from bucket..."
    gsutil rm "$VIDEO_URI"
    if [ $? -eq 0 ]; then
      echo "Successfully deleted $VIDEO_URI from bucket"
    else
      echo "Error deleting $VIDEO_URI from bucket"
    fi
  else
    echo "Error adding music to $FILENAME"
  fi
else
  echo "Error downloading $VIDEO_URI"
fi

# Clean up temporary files
rm -f request.json fetch.json

echo "Done! Animated video with YouTube Audio Library music is saved locally in $OUTPUT_FILENAME."
echo "No video remains in the bucket."
