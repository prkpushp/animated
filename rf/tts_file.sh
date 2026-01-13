#!/usr/bin/env bash
set -euo pipefail

IN="${1:?Usage: $0 rf/input/tax.txt rf/input/voiceover.wav}"
OUT="${2:?Usage: $0 rf/input/tax.txt rf/input/voiceover.wav}"

CHUNK_DIR="$(mktemp -d)"
trap 'rm -rf "$CHUNK_DIR"' EXIT

# Keep under 4000 bytes; leave headroom for punctuation/newlines.
MAX_BYTES="${MAX_BYTES:-3000}"

# 1) Split into <= MAX_BYTES chunks (byte-budgeted)
i=0
buf=""
while IFS= read -r line || [[ -n "$line" ]]; do
  candidate="${buf}${line}"$'\n'
  if (( $(printf %s "$candidate" | wc -c) > MAX_BYTES )); then
    printf "%s" "$buf" > "$CHUNK_DIR/chunk_$(printf %04d $i).txt"
    i=$((i+1))
    buf="${line}"$'\n'
  else
    buf="$candidate"
  fi
done < "$IN"
printf "%s" "$buf" > "$CHUNK_DIR/chunk_$(printf %04d $i).txt"

# 2) Synthesize each chunk
n=0
for f in "$CHUNK_DIR"/chunk_*.txt; do
  n=$((n+1))
  text="$(cat "$f")"
  rf/tts.sh "$text" "$CHUNK_DIR/chunk_$(printf %04d $n).wav"
done

# 3) Concatenate WAVs
ls "$CHUNK_DIR"/chunk_*.wav | awk '{print "file \x27"$0"\x27"}' > "$CHUNK_DIR/list.txt"
ffmpeg -y -f concat -safe 0 -i "$CHUNK_DIR/list.txt" -c copy "$OUT"

ls -lh "$OUT"
