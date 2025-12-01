import os
import sys
import requests
import json
import re

OUTPUT_FILE = "hindi_output.txt"

API_URL = "https://everything.subsms.com/api/youtube_transcript?url="


def extract_video_id(url):
    """Extract YouTube video ID for logging/debug."""
    match = re.search(r"v=([a-zA-Z0-9_-]{11})", url)
    return match.group(1) if match else None


def main():
    youtube_url = os.getenv("YOUTUBE_URL")

    if not youtube_url:
        print("❌ Error: YOUTUBE_URL not set.")
        sys.exit(1)

    video_id = extract_video_id(youtube_url)
    print(f"📌 Video ID: {video_id}")
    print("🌐 Fetching transcript using everything.ai...")

    try:
        resp = requests.get(API_URL + youtube_url, timeout=30)
        data = resp.json()

        if data.get("status") == "success":
            text = data.get("transcript", "").strip()

            if not text:
                print("⚠️ Empty transcript returned.")
                sys.exit(1)

            # Save output
            with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
                f.write(text)

            print(f"✅ Transcript saved → {OUTPUT_FILE}")
            return

        else:
            print("⚠️ everything.ai could NOT fetch transcript.")
            print("Message:", data.get("message"))
            sys.exit(1)

    except Exception as e:
        print(f"❌ Error calling everything.ai: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
