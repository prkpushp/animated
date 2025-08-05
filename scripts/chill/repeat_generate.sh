#!/bin/bash
set -e

PROMPT_INPUT="$1"
ARG_INPUT="$2"

for i in 900 3600 14400; do
  echo "=============================="
  echo "🔁 Repetition $i of 3"
  echo "=============================="

  bash scripts/generate_prompts.sh "$PROMPT_INPUT"
  bash scripts/generate_media.sh
  bash scripts/make_video.sh "$ARG_INPUT"
done

