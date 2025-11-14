import os, subprocess, re
import whisper
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

YOUTUBE_URL = os.getenv("YOUTUBE_URL", "https://www.youtube.com/watch?v=8SRe1bNO38E")
AUDIO_FILE = "audio.m4a"
OUTPUT_FILE = "hindi_output.txt"

def download_audio(url, out):
    subprocess.run(["yt-dlp", "-x", "--audio-format", "m4a", "-o", out, url], check=True)

def translate(text, tok, model, max_chars=1500):
    parts, cur, count = [], [], 0
    for para in re.split(r'(\n\n+)', text):
        if count + len(para) > max_chars and cur:
            parts.append("".join(cur)); cur=[]; count=0
        cur.append(para); count += len(para)
    if cur: parts.append("".join(cur))

    out = []
    for chunk in parts:
        inputs = tok(chunk, return_tensors="pt", truncation=True, max_length=1024)
        ids = model.generate(**inputs, max_length=1024)
        out.append(tok.decode(ids[0], skip_special_tokens=True))
    return "\n".join(out)

def main():
    print("Downloading audio…")
    download_audio(YOUTUBE_URL, AUDIO_FILE)

    print("Transcribing audio with Whisper…")
    model = whisper.load_model("small")
    result = model.transcribe(AUDIO_FILE, language="en")
    english_text = result["text"].strip()

    print("Translating to Hindi…")
    tok = AutoTokenizer.from_pretrained("Helsinki-NLP/opus-mt-en-hi")
    mdl = AutoModelForSeq2SeqLM.from_pretrained("Helsinki-NLP/opus-mt-en-hi")
    hindi_text = translate(english_text, tok, mdl)

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(hindi_text)

    print(f"✅ Saved Hindi text → {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
