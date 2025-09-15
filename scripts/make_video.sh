#!/bin/bash
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

echo "🎬 Creating video directly with audio..."
ffmpeg -y -loop 1 -i "$IMAGE" -stream_loop -1 -i "$AUDIO" \
  -t $DURATION \
  -vf "fade=t=in:st=0:d=3,fade=t=out:st=$(($DURATION - 3)):d=3),format=yuv420p" \
  -af "afade=t=in:st=0:d=3,afade=t=out:st=$(($DURATION - 3)):d=3)" \
  -c:v libx264 -preset ultrafast -crf 25 -pix_fmt yuv420p \
  -c:a aac -b:a 192k \
  -movflags +faststart "$OUTPUT"

echo "✅ Done! Video saved as: $OUTPUT"

