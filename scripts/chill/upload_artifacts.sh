#!/bin/bash
set -e

# Arguments
RUN_ID="${GITHUB_RUN_ID:-manual}"
RUN_NUMBER="${GITHUB_RUN_NUMBER:-manual}"
ARTIFACT_SUFFIX="${1:-default}"

# Upload image, music, and video artifacts
echo "📦 Uploading image, music, and video artifacts..."
gh release upload "media-output-${RUN_ID}-${RUN_NUMBER}-${ARTIFACT_SUFFIX}" output/*.png output/*.wav output/*.mp4 --clobber || echo "Skipped if not in release context."

# Upload complete output folder + SEO + videos
echo "📦 Uploading complete output + raw content..."
gh release upload "media-output-all-${RUN_ID}-${RUN_NUMBER}-${ARTIFACT_SUFFIX}" output/** output/raw_content.txt --clobber || echo "Skipped if not in release context."
