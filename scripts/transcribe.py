import os
import sys
import whisper
import yt_dlp

# Get URL from environment variable
YOUTUBE_URL = os.getenv("YOUTUBE_URL")
AUDIO_BASE_NAME = "audio"
AUDIO_FILE = f"{AUDIO_BASE_NAME}.mp3"
OUTPUT_FILE = "hindi_output.txt"
COOKIES_FILE = "cookies.txt"

def download_audio(url):
    print(f"🎬 Downloading audio from: {url}")
    
    # yt-dlp options for best audio quality converted to mp3
    ydl_opts = {
        'format': 'bestaudio/best',
        'outtmpl': AUDIO_BASE_NAME,
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'mp3',
            'preferredquality': '192',
        }],
        'quiet': False,
        'no_warnings': True,
    }

    # Check for cookies file to bypass bot detection
    if os.path.exists(COOKIES_FILE):
        print(f"🍪 Found {COOKIES_FILE}, using for authentication.")
        ydl_opts['cookiefile'] = COOKIES_FILE
    else:
        print(f"⚠️ {COOKIES_FILE} not found. Proceeding without authentication (may fail for some videos).")

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

    # 1. Download Audio
    if not download_audio(YOUTUBE_URL):
        sys.exit(1)

    # 2. Transcribe
    print("🧠 Transcribing Hindi audio -> text (this may take a moment)...")
    try:
        # 'small' is a good balance for CPU runners. Use 'tiny' for faster testing.
        model = whisper.load_model("small")
        
        if not os.path.exists(AUDIO_FILE):
             print(f"❌ Error: Audio file {AUDIO_FILE} not found.")
             sys.exit(1)

        result = model.transcribe(AUDIO_FILE, language="hi")
        hindi_text = result["text"].strip()

        # 3. Save Output
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            f.write(hindi_text)
        
        print(f"✅ Saved Hindi transcript -> {OUTPUT_FILE}")

    except Exception as e:
        print(f"❌ Error during transcription: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
