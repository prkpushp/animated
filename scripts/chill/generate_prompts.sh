#!/bin/bash
set -e

mkdir -p output

PROMPT_INPUT="$1"

if [ -z "$PROMPT_INPUT" ]; then
  PROMPT_INPUT="Generate one and only one tranquil, hyperrealistic natural scene in ultra-high resolution (16K HDR style), ultra green for meditation or relaxation, randomly chosen from a predefined list of peaceful environments (e.g., jungle waterfall, misty pine forest with cabin, mossy riverbank, alpine lake, enchanted fairytale house, serene Japanese garden, cherry blossom grove, snowy cottage, lavender field, canyon spring, or forest trail), using soft natural lighting like sunrise, sunset, or misty glow, emphasizing stillness, peace, and dreamlike serenity without combining multiple scene elements."
fi

ACCESS_TOKEN=$(gcloud auth print-access-token)
LOCATION="us-central1"
GEMINI_MODEL="gemini-2.0-flash-lite-001"

cat >gemini_prompt_request.json <<EOF
{
  "contents": [
    {
      "role": "user",
      "parts": [
        { "text": "Input: ${PROMPT_INPUT}\n\nCreate two creative prompts based on the above input, for:\n1. An image generation AI (describe visual scene, mood, details)\n2. A music generation AI (describe mood, instruments, style, tempo)\nFormat:\nImage Prompt: ...\nMusic Prompt: ..." }
      ]
    }
  ]
}
EOF

curl -s -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/publishers/google/models/${GEMINI_MODEL}:generateContent" \
  -d @gemini_prompt_request.json \
  -o gemini_prompts_response.json

HAS_PROMPT=$(jq '.candidates != null and .candidates[0].content.parts[0].text != null' gemini_prompts_response.json || echo "false")
if [ "$HAS_PROMPT" != "true" ]; then
  GEN_PROMPTS_CONTENT=$(jq -r '.candidates[0].content.parts[0].text // .candidates[0].content.parts[0] // empty' gemini_prompts_response.json)
else
  GEN_PROMPTS_CONTENT=$(jq -r '.candidates[0].content.parts[0].text' gemini_prompts_response.json)
fi

if [ -z "$GEN_PROMPTS_CONTENT" ]; then
  IMAGE_PROMPT="$PROMPT_INPUT"
  MUSIC_PROMPT="$PROMPT_INPUT"
else
  IMAGE_PROMPT=$(echo "$GEN_PROMPTS_CONTENT" | grep -E '^Image Prompt:' | head -n1 | sed 's/^Image Prompt:[[:space:]]*//')
  MUSIC_PROMPT=$(echo "$GEN_PROMPTS_CONTENT" | grep -E '^Music Prompt:' | head -n1 | sed 's/^Music Prompt:[[:space:]]*//')
  if [ -z "$IMAGE_PROMPT" ]; then IMAGE_PROMPT="$PROMPT_INPUT"; fi
  if [ -z "$MUSIC_PROMPT" ]; then MUSIC_PROMPT="$PROMPT_INPUT"; fi
fi

echo "$IMAGE_PROMPT" > output/image_prompt.txt
echo "$MUSIC_PROMPT" > output/music_prompt.txt

cat >gemini_seo_request.json <<EOF
{
  "contents": [
    {
      "role": "user",
      "parts": [
        { "text": "Given this video concept: '${PROMPT_INPUT}', create a JSON object with three fields: 'title' (SEO-optimized YouTube video title), 'description' (SEO-optimized YouTube video description, at least 100 words, engaging, with keywords), and 'hashtags' (an array of 5-10 relevant SEO-optimized hashtags for YouTube, no # symbol, no spaces, just the tag text). Output ONLY the JSON object." }
      ]
    }
  ]
}
EOF

curl -s -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/publishers/google/models/${GEMINI_MODEL}:generateContent" \
  -d @gemini_seo_request.json \
  -o gemini_seo_response.json

RAW_CONTENT=$(jq -r '.candidates[0].content.parts[0].text // .candidates[0].content.parts[0] // empty' gemini_seo_response.json)
echo "$RAW_CONTENT" > output/raw_content.txt

SEO_JSON=$(echo "$RAW_CONTENT" | python3 -c "
import sys, json, re
data = sys.stdin.read()
data = re.sub(r'```[a-zA-Z]*', '', data)
data = re.sub(r'```', '', data).strip()
m = re.search(r'(\{.*?\})', data, re.DOTALL)
if m:
    try:
        obj = json.loads(m.group(1))
        print(json.dumps(obj, indent=2))
    except Exception as e:
        print('{}')
else:
    print('{}')
")
echo "$SEO_JSON" > output/content.json
