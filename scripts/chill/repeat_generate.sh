#!/bin/bash
set -e

PROMPT_INPUT="$1"
ARG_INPUT="$2"

for i in 1 2 3; do
  echo "🌀 Run #$i of 3"

  echo "🔹 [1/$i] Generate prompts..."
  bash scripts/generate_prompts.sh "$PROMPT_INPUT" "$i"

  echo "🔹 [2/$i] Generate image and music..."
  bash scripts/generate_media.sh "$i"

  echo "🔹 [3/$i] Upload image and music..."
  bash scripts/upload_artifacts.sh "$i"

  echo "🔹 [4/$i] Run make_video.sh with arg: $ARG_INPUT"
  bash scripts/make_video.sh "$ARG_INPUT" "$i"
done
