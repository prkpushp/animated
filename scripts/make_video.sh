#!/bin/bash
set -e

DATE=$(date +"%d%m%y")
HOUR=$(date -u +"%H")
EPOCH_TIME=$(date +%s)

IMAGE=$(ls -t output/*.png | head -n 1)
AUDIO=$(ls -t output/*.wav | head -n 1)
OUTPUT="output/${EPOCH_TIME}.mp4"
DURATION=${1:-3600}

if [ ! -f "$IMAGE" ]; then
  echo "❌ Image file not found: $IMAGE"
  exit 1
fi

if [ ! -f "$AUDIO" ]; then
  echo "❌ Audio file not found: $AUDIO"
  exit 1
fi

echo "🎞️ Creating video directly with FFmpeg (no temp files)..."

# Key optimizations:
# 1. Avoid separate temp encodes — merge video/audio in one pass.
# 2. Use -shortest only when needed.
# 3. Use ultrafast preset & tune stillimage for static content.
# 4. Use filter_complex for fade and looping inline.

ffmpeg -y \
  -loop 1 -framerate 1 -t $DURATION -i "$IMAGE" \
  -stream_loop -1 -i "$AUDIO" \
  -t $DURATION \
  -filter_complex "[0:v]fade=t=in:st=0:d=3,fade=t=out:st=$(($DURATION - 3)):d=3,format=yuv420p[v]; \
                   [1:a]afade=t=in:st=0:d=3,afade=t=out:st=$(($DURATION - 3)):d=3[a]" \
  -map "[v]" -map "[a]" \
  -preset ultrafast -tune stillimage \
  -c:v libx264 -pix_fmt yuv420p \
  -c:a aac -b:a 192k \
  -movflags +faststart \
  "$OUTPUT"

echo "✅ Done! Video saved as: $OUTPUT"
