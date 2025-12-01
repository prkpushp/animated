import os
import sys
from youtube_transcript_api import YouTubeTranscriptApi, TranscriptsDisabled
import re

OUTPUT_FILE = "hindi_output.txt"

def extract_video_id(url):
    match = re.search(r"v=([a-zA-Z0-9_-]{11})", url)
    return match.group(1) if match else None

def main():
    youtube_url = os.getenv("YOUTUBE_URL")
    if not youtube_url:
        print("❌ Error: YOUTUBE_URL is not set.")
        sys.exit(1)

    video_id = extract_video_id(youtube_url)
    if not video_id:
        print("❌ Unable to extract video ID.")
        sys.exit(1)

    print(f"📌 Extracted Video ID: {video_id}")
    print("📥 Fetching YouTube transcript (Hindi preferred)…")

    try:
        # Try Hindi first
        transcript_list = YouTubeTranscriptApi.get_transcript(video_id, languages=['hi', 'hi-IN'])

    except TranscriptsDisabled:
        print("❌ This video has no transcripts enabled.")
        sys.exit(1)

    except Exception as e:
        print(f"❌ Error fetching transcript: {e}")
        sys.exit(1)

    # Combine transcript text
    hindi_text = " ".join(item['text'] for item in transcript_list)

    # Save
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(hindi_text)

    print(f"✅ Saved Hindi transcript → {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
