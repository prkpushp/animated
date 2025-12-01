import os
import sys
import re
import whisper
import yt_dlp
from youtube_transcript_api import (
    YouTubeTranscriptApi,
    TranscriptsDisabled,
    NoTranscriptFound,
)

OUTPUT_FILE = "hindi_output.txt"
AUDIO_FILE = "audio.mp3"


# Extract YouTube video ID
def extract_video_id(url):
    match = re.search(r"v=([a-zA-Z0-9_-]{11})", url)
    return match.group(1) if match else None


# SAFE yt-dlp download (Android client bypass)
def download_audio(url):
    print("🎧 Downloading audio for Whisper...")

    opts = {
        "format": "bestaudio/best",
        "outtmpl": "audio",
        "postprocessors": [
            {
                "key": "FFmpegExtractAudio",
                "preferredcodec": "mp3",
                "preferredquality": "192",
            }
        ],
        "extractor_args": {
            "youtube": {
                "player_client": ["android"],
                "player_skip": ["webpage"],
                "no_initial_data": "true",
            }
        },
        "quiet": False,
    }

    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            ydl.download([url])
        print("✅ Audio downloaded")
        return True
    except Exception as e:
        print(f"❌ Error downloading audio: {e}")
        return False


def main():
    url = os.getenv("YOUTUBE_URL")
    if not url:
        print("❌ YOUTUBE_URL not set")
        sys.exit(1)

    video_id = extract_video_id(url)
    print(f"📌 Extracted Video ID: {video_id}")
    print("📥 Attempting to fetch YouTube transcript...")

    transcript_text = None

    # 1️⃣ Try transcript first
    try:
        try:
            transcript = YouTubeTranscriptApi.get_transcript(
                video_id, languages=['hi', 'hi-IN']
            )
            print("✅ Found Hindi transcript")

        except NoTranscriptFound:
            print("⚠️ Hindi not available. Trying English...")
            transcript = YouTubeTranscriptApi.get_transcript(
                video_id, languages=['en']
            )
            print("⚡ Using English auto transcript")

        transcript_text = " ".join([item["text"] for item in transcript])

    except TranscriptsDisabled:
        print("⚠️ No transcript available → Falling back to Whisper")
    except Exception as e:
        print(f"⚠️ Transcript error: {e} → Falling back to Whisper")

    # 2️⃣ If transcript available → save & exit
    if transcript_text:
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            f.write(transcript_text)
        print(f"✅ Saved transcript → {OUTPUT_FILE}")
        return

    # 3️⃣ Transcript NOT available → run Whisper
    print("🎤 Starting Whisper transcription...")

    if not download_audio(url):
        sys.exit(1)

    print("🧠 Loading Whisper model (small)...")
    model = whisper.load_model("small")

    result = model.transcribe(AUDIO_FILE, language="hi")
    text = result["text"].strip()

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(text)

    print(f"✅ Whisper transcription saved → {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
