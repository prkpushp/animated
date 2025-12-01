import os
import sys
import requests
import re

OUTPUT_FILE = "hindi_output.txt"


def extract_video_id(url):
    match = re.search(r"v=([a-zA-Z0-9_-]{11})", url)
    return match.group(1) if match else None


def main():
    youtube_url = os.getenv("YOUTUBE_URL")

    if not youtube_url:
        print("❌ YOUTUBE_URL not provided.")
        sys.exit(1)

    video_id = extract_video_id(youtube_url)
    print(f"📌 Video ID: {video_id}")

    API = f"https://yt-api.org/api/transcript?url={youtube_url}"
    print("🌐 Fetching transcript using yt-api.org...")

    try:
        response = requests.get(API, timeout=20)
        data = response.json()
    except Exception as e:
        print(f"❌ Network/API error: {e}")
        sys.exit(1)

    if data.get("status") != "ok":
        print("⚠️ Transcript not available.")
        print("API message:", data.get("message"))
        sys.exit(1)

    transcript = data.get("transcript")
    if not transcript:
        print("⚠️ Empty transcript returned.")
        sys.exit(1)

    # Save to file
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(transcript)

    print(f"✅ Saved transcript → {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
