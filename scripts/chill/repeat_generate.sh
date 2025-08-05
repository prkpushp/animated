#!/bin/bash
set -e

PROMPT_INPUT="$1"
ARG_INPUT="$2"

for i in 900 3600 14400; do
  echo "🌀 Run #$i of 3"

  echo "🔹 [1/$i] Generate prompts..."
  bash chill/scripts/generate_prompts.sh "$PROMPT_INPUT" "$i"

  echo "🔹 [2/$i] Generate image and music..."
  bash chill/scripts/generate_media.sh "$i"

  echo "🔹 [3/$i] Upload image and music..."
  bash chill/scripts/upload_artifacts.sh "$i"

  echo "🔹 [4/$i] Run make_video.sh with arg: $ARG_INPUT"
  bash chill/scripts/make_video.sh "$i"
done
