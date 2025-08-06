#!/bin/bash
set -e

PROMPT_INPUT="$1"
ARG_INPUT="$2"

for i in 900 3600 14400; do
  echo "=============================="
  echo "🔁 Repetition $i of 3"
  echo "=============================="

  bash scripts/chill/generate_prompts.sh "$PROMPT_INPUT"
  bash scripts/chill/generate_media.sh
  bash scripts/make_video.sh $i
  bash scripts/chill/upload_artifacts.sh
done

