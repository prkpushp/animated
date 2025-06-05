#!/bin/bash

# Define project and model details
PROJECT_ID="gothic-envelope-458808-h6"
LOCATION_ID="us-central1"
API_ENDPOINT="us-central1-aiplatform.googleapis.com"
MODEL_ID="veo-2.0-generate-001"
STORAGE_URI="gs://helloranjan1/output/"
AUDIO_FILE="background_music.mp3"
LOCAL_DIR="./videos"

# Create local directory if it doesn't exist
mkdir -p "$LOCAL_DIR"

# List of animals with descriptions
ANIMALS=(
  "orange tabby cat with big, sparkly eyes and exaggerated whiskers"
  "tiny mouse with oversized, floppy ears and a twitchy tail"
  "panda with a bouncy, roly-poly body"
  "fox with a fluffy, bouncy tail and a mischievous, toothy grin"
  "rabbit with a twitchy nose, long, floppy ears, and springy legs"
  "hamster with round, chubby cheeks and tiny, wiggly paws"
  "small pug dog with big, googly eyes and a wagging, curly tail"
  "platypus with a shiny bill and quirky, waddling gait"
  "small, expressive chameleon with googly eyes and a curly tail"
  "pink, tiny piglet with a curly tail and bouncy steps"
  "lion cub with a fluffy, spiky mane and playful pounces"
  "tiger cub with bold stripes and a swishing, energetic tail"
  "penguin with a wobbly walk and shiny, flapping flippers"
  "koala with fuzzy ears and a sleepy, cuddly demeanor"
  "polar bear cub with snowy fur and clumsy, tumbling rolls"
  "hedgehog with spiky, colorful quills and a curious sniff"
  "baby elephant with a flapping trunk and wobbly, big feet"
  "red panda with a fluffy, striped tail and nimble climbs"
  "alpaca or llama with a poofy, woolly coat and a sassy strut"
  "duckling with fluffy feathers and a quacking, splashing hop"
  "seal pup with shiny, slippery fur and playful, rolling dives"
  "otter with a sleek, twirling body and a cheeky, splashing spin"
  "tiny, smiley tortoise with a shiny shell and slow, goofy steps"
  "fluffy yellow ball chick with a chirpy bounce and tiny wings"
  "squirrel with a bushy, twitchy tail and quick, darting leaps"
  "deer fawn with big, shiny eyes and delicate, skipping steps"
  "floppy-eared beagle type dog with a wagging tail and bouncy bounds"
  "round, bubbly goldfish with shimmering fins and a pop-eyed stare"
  "owl chick with fluffy, round feathers and wide, blinking eyes"
  "gecko with sticky toes and a flicking, animated tongue"
)

# Arrays for elaborative prompt components
SETTINGS=(
  "sunlit meadow with wildflowers and buzzing bees"
  "misty jungle clearing with dangling vines"
  "sandy beach with crashing waves and seagull cries"
  "lush forest with towering trees and dappled sunlight"
  "rocky mountain slope under a vibrant blue sky"
  "neon-lit cyberpunk city with flickering holograms"
  "whimsical enchanted forest with glowing mushrooms"
  "snowy tundra with swirling snowflakes"
  "bustling cartoon village with colorful houses"
  "starlit desert with cacti and a glowing moon"
)
ACTION_STYLES=(
  "cartoonishly brawling with exaggerated punches"
  "fiercely chasing with comical trips and tumbles"
  "darting and dodging with zany, stretchy moves"
  "tumbling and sparring with bouncy, springy leaps"
  "leaping and tussling with wild, loony spins"
  "spinning and flipping with over-the-top flair"
  "clashing playfully with goofy, wobbly stumbles"
  "swinging and swiping with animated, stretchy limbs"
)
ATMOSPHERES=(
  "under a golden sunset with warm, rosy hues"
  "with leaves swirling in a playful breeze"
  "beneath a starry sky with twinkling constellations"
  "in the glow of dawn with soft, pastel colors"
  "amidst a gentle mist with shimmering droplets"
  "with glowing fireflies dancing in the air"
  "under a rainbow arch with sparkling light"
  "with dramatic thunderclouds and flashing lightning"
)
VISUAL_STYLES=(
  "in a colorful 2D cartoon style with bold outlines"
  "with Pixar-like charm and vibrant textures"
  "in a vibrant 3D anime style with shiny effects"
  "with hand-drawn sketchbook charm and wobbly lines"
  "in a retro 8-bit pixel art style with quirky charm"
  "with a claymation-like bounce and squishy shapes"
)

# Randomly select prompt components
SELECTED_ANIMALS=($(printf "%s\n" "${ANIMALS[@]}" | shuf -n 2))
ANIMAL1="${SELECTED_ANIMALS[0]}"
ANIMAL2="${SELECTED_ANIMALS[1]}"
SETTING=$(printf "%s\n" "${SETTINGS[@]}" | shuf -n 1)
ACTION_STYLE=$(printf "%s\n" "${ACTION_STYLES[@]}" | shuf -n 1)
ATMOSPHERE=$(printf "%s\n" "${ATMOSPHERES[@]}" | shuf -n 1)
VISUAL_STYLE=$(printf "%s\n" "${VISUAL_STYLES[@]}" | shuf -n 1)

# Construct elaborative prompt for animated characters
PROMPT="In a ${SETTING}, an animated Disney Pixar 3D Style ${ANIMAL1} ${ACTION_STYLE} an animated ${ANIMAL2}, their exaggerated expressions and movements vivid ${ATMOSPHERE}, rendered ${VISUAL_STYLE}"

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
