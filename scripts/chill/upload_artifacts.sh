#!/bin/bash
set -e
INDEX="$1"
echo "Uploading artifacts for run $INDEX..."

# Use GitHub Action artifact upload tool
gh run upload-artifact \
  --name "media-output-$INDEX" \
  output/image-$INDEX-*.png output/music-$INDEX-*.wav || true
