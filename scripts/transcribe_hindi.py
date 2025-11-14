import os
from pytube import YouTube
import whisper

YOUTUBE_URL = os.getenv("YOUTUBE_URL", "https://www.youtube.com/watch?v=8SRe1bNO38E")
AUDIO_FILE = "audio.mp4"   # pytube downloads in mp4 audio container
OUTPUT_FILE = "hindi_output.txt"


def download_audio(url, out):
    yt = YouTube(url)
    stream = yt.streams.filter(only_audio=True).first()
    print(f"🎬 Downloading audio: {yt.title}")
    stream.download(filename=out)
    print("✅ Audio downloaded successfully.")


def main():
    download_audio(YOUTUBE_URL, AUDIO_FILE)

    print("🧠 Transcribing Hindi audio → text...")
    model = whisper.load_model("small")
    result = model.transcribe(AUDIO_FILE, language="hi")
    hindi_text = result["text"].strip()

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(hindi_text)

    print(f"✅ Saved Hindi transcript → {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
