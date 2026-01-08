import argparse
import mimetypes
import os
import struct
from google import genai
from google.genai import types

def parse_audio_mime_type(mime_type: str) -> dict[str, int]:
    bits_per_sample = 16
    rate = 24000
    parts = (mime_type or "").split(";")
    for p in parts:
        p = p.strip()
        if p.lower().startswith("rate="):
            try:
                rate = int(p.split("=", 1)[1])
            except Exception:
                pass
        if p.lower().startswith("audio/l"):
            try:
                bits_per_sample = int(p.split("l", 1)[1])
            except Exception:
                pass
    return {"bits_per_sample": bits_per_sample, "rate": rate}

def convert_to_wav(audio_data: bytes, mime_type: str) -> bytes:
    params = parse_audio_mime_type(mime_type)
    bits_per_sample = params["bits_per_sample"]
    sample_rate = params["rate"]
    num_channels = 1
    data_size = len(audio_data)
    bytes_per_sample = bits_per_sample // 8
    block_align = num_channels * bytes_per_sample
    byte_rate = sample_rate * block_align
    chunk_size = 36 + data_size

    header = struct.pack(
        "<4sI4s4sIHHIIHH4sI",
        b"RIFF", chunk_size, b"WAVE",
        b"fmt ", 16, 1,
        num_channels, sample_rate, byte_rate, block_align, bits_per_sample,
        b"data", data_size
    )
    return header + audio_data

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="in_file", required=True)
    ap.add_argument("--out", dest="out_wav", required=True)
    ap.add_argument("--voice", default="Sadachbia")
    ap.add_argument("--project", required=True)
    ap.add_argument("--location", default="us-central1")
    ap.add_argument("--model", default="gemini-2.5-pro-preview-tts")
    args = ap.parse_args()

    with open(args.in_file, "r", encoding="utf-8") as f:
        text = f.read().strip()

    # Vertex AI client via ADC (GOOGLE_APPLICATION_CREDENTIALS)
    client = genai.Client(vertexai=True, project=args.project, location=args.location)  # [web:215]

    contents = [types.Content(role="user", parts=[types.Part.from_text(text=text)])]

    config = types.GenerateContentConfig(
        response_modalities=["AUDIO"],  # [web:163]
        speech_config=types.SpeechConfig(
            voice_config=types.VoiceConfig(
                prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name=args.voice)
            )
        ),
    )

    audio_bytes = None
    audio_mime = None

    for chunk in client.models.generate_content_stream(model=args.model, contents=contents, config=config):
        cand = (chunk.candidates or [None])[0]
        if not cand or not cand.content or not cand.content.parts:
            continue
        part0 = cand.content.parts[0]
        if getattr(part0, "inline_data", None) and part0.inline_data.data:
            audio_bytes = part0.inline_data.data
            audio_mime = part0.inline_data.mime_type
            break

    if not audio_bytes:
        raise RuntimeError("No audio returned.")

    # Ensure WAV container
    ext = mimetypes.guess_extension(audio_mime or "")
    if ext != ".wav":
        audio_bytes = convert_to_wav(audio_bytes, audio_mime or "audio/L16;rate=24000")

    os.makedirs(os.path.dirname(args.out_wav) or ".", exist_ok=True)
    with open(args.out_wav, "wb") as f:
        f.write(audio_bytes)

    print(f"Wrote: {args.out_wav}")

if __name__ == "__main__":
    main()
