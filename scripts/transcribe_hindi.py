import os
import subprocess
import whisper

YOUTUBE_URL = os.getenv("YOUTUBE_URL", "https://www.youtube.com/watch?v=8SRe1bNO38E")
COOKIES_FILE = os.getenv("COOKIES_FILE", "cookies.txt")
AUDIO_FILE = "audio.m4a"
OUTPUT_FILE = "hindi_output.txt"


def download_audio(url, out):
    cmd = [
        "yt-dlp",
        "-x",
        "--audio-format", "m4a",
        "--extractor-args", "youtube:player_client=default",
        "-o", out,
        url,
    ]
    if os.path.exists(COOKIES_FILE):
        cmd += ["--cookies", COOKIES_FILE]
        print(f"🍪 Using cookies from {COOKIES_FILE}")
    else:
        print("⚠️ No cookies file found, may fail on restricted videos.")
    subprocess.run(cmd, check=True)


def main():
    print(f"🎬 Downloading audio from: {YOUTUBE_URL}")
    download_audio(YOUTUBE_URL, AUDIO_FILE)

    print("🧠 Transcribing Hindi audio → text...")
    model = whisper.load_model("small")
    result = model.transcribe(AUDIO_FILE, language="hi")
    hindi_text = result["text"].strip()

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(hindi_text)

    print(f"✅ Saved Hindi text → {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
