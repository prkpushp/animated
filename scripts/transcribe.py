import os
import sys
import whisper
import yt_dlp

YOUTUBE_URL = os.getenv("YOUTUBE_URL")
AUDIO_BASE_NAME = "audio"
AUDIO_FILE = f"{AUDIO_BASE_NAME}.mp3"
OUTPUT_FILE = "hindi_output.txt"
COOKIES_FILE = "cookies.txt"


def download_audio(url):
    print(f"🎬 Downloading audio from: {url}")

    ydl_opts = {
        "format": "bestaudio/best",
        "outtmpl": AUDIO_BASE_NAME,
        "postprocessors": [
            {
                "key": "FFmpegExtractAudio",
                "preferredcodec": "mp3",
                "preferredquality": "192",
            }
        ],
        "quiet": False,
        "no_warnings": True,

        # ------------------------------------------------------
        # 🔥 2025: Working YouTube anti-bot + anti-initial-data fix
        # ------------------------------------------------------
        "extractor_args": {
            "youtube": {
                "player_client": ["android", "android_vr"],
                "skip": ["webpage", "dash", "configs"],   # <-- IMPORTANT
                "no_initial_data": "true",                # <-- IMPORTANT
                "retry_download": 3,
            }
        },

        # Force innertube API instead of webpage
        "force_innertube": True,
        "extract_flat": False,
        "youtube_include_dash_manifest": False,
    }

    # Use cookies if available
    if os.path.exists(COOKIES_FILE):
        print("🍪 Using cookies.txt for YouTube authentication.")
        ydl_opts["cookiefile"] = COOKIES_FILE
    else:
        print("⚠️ No cookies.txt found. Proceeding without authentication.")

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])
        print(f"✅ Audio downloaded successfully: {AUDIO_FILE}")
        return True
    except Exception as e:
        print(f"❌ Error downloading audio: {e}")
        return False


def main():
    if not YOUTUBE_URL:
        print("❌ Error: YOUTUBE_URL environment variable is not set.")
        sys.exit(1)

    # Download audio
    if not download_audio(YOUTUBE_URL):
        sys.exit(1)

    print("🧠 Transcribing Hindi audio -> text... (CPU may take time)")

    try:
        model = whisper.load_model("small")

        if not os.path.exists(AUDIO_FILE):
            print(f"❌ Error: Audio file {AUDIO_FILE} not found.")
            sys.exit(1)

        result = model.transcribe(AUDIO_FILE, language="hi")
        hindi_text = result["text"].strip()

        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            f.write(hindi_text)

        print(f"✅ Saved Hindi transcript → {OUTPUT_FILE}")

    except Exception as e:
        print(f"❌ Error during transcription: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
