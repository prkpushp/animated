import os
import subprocess
import re
import whisper
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

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
        url
    ]
    if os.path.exists(COOKIES_FILE):
        cmd += ["--cookies", COOKIES_FILE]
        print(f"🍪 Using cookies from {COOKIES_FILE}")
    else:
        print("⚠️ No cookies file found, may fail on restricted videos.")
    subprocess.run(cmd, check=True)


def translate(text, tok, model, max_tokens=512):
    """
    Splits text into smaller chunks that the Marian model can handle.
    Handles large transcripts safely on CPU runners.
    """
    import math

    # Split into sentences or paragraphs to avoid mid-word breaks
    sentences = re.split(r'(?<=[.!?])\s+', text)
    out_chunks = []
    buffer = ""

    for sent in sentences:
        # check token length before adding
        tokens = tok(buffer + " " + sent, return_tensors="pt", truncation=False).input_ids
        if tokens.shape[1] > max_tokens:
            if buffer.strip():
                inputs = tok(buffer.strip(), return_tensors="pt", truncation=True, max_length=max_tokens)
                ids = model.generate(**inputs, max_length=max_tokens)
                out_chunks.append(tok.decode(ids[0], skip_special_tokens=True))
            buffer = sent
        else:
            buffer += " " + sent

    # translate any remainder
    if buffer.strip():
        inputs = tok(buffer.strip(), return_tensors="pt", truncation=True, max_length=max_tokens)
        ids = model.generate(**inputs, max_length=max_tokens)
        out_chunks.append(tok.decode(ids[0], skip_special_tokens=True))

    return "\n".join(out_chunks)



def main():
    print(f"🎬 Downloading audio from: {YOUTUBE_URL}")
    download_audio(YOUTUBE_URL, AUDIO_FILE)

    print("🧠 Transcribing audio with Whisper…")
    model = whisper.load_model("small")
    result = model.transcribe(AUDIO_FILE, language="en")
    english_text = result["text"].strip()

    print("🌐 Translating English → Hindi…")
    tok = AutoTokenizer.from_pretrained("Helsinki-NLP/opus-mt-en-hi")
    mdl = AutoModelForSeq2SeqLM.from_pretrained("Helsinki-NLP/opus-mt-en-hi")
    hindi_text = translate(english_text, tok, mdl)

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(hindi_text)

    print(f"✅ Saved Hindi text → {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
