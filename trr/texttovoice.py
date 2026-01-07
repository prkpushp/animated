import argparse
import mimetypes
import os
import struct
from google import genai
from google.genai import types


def save_binary_file(file_name: str, data: bytes) -> None:
    os.makedirs(os.path.dirname(file_name) or ".", exist_ok=True)
    with open(file_name, "wb") as f:
        f.write(data)
    print(f"File saved to: {file_name}")


def parse_audio_mime_type(mime_type: str) -> dict[str, int]:
    # Defaults if mime params are missing
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
        # Sometimes mime looks like: audio/L16;rate=24000
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
        b"RIFF",
        chunk_size,
        b"WAVE",
        b"fmt ",
        16,
        1,
        num_channels,
        sample_rate,
        byte_rate,
        block_align,
        bits_per_sample,
        b"data",
        data_size,
    )
    return header + audio_data


def tts(text: str, out_wav: str, voice_name: str) -> None:
    # If GEMINI_API_KEY is set, SDK can pick it up automatically. [web:168]
    client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))

    model = "gemini-2.5-pro-preview-tts"

    contents = [
        types.Content(
            role="user",
            parts=[types.Part.from_text(text=text)],
        )
    ]

    config = types.GenerateContentConfig(
        temperature=1,
        response_modalities=["AUDIO"],
        speech_config=types.SpeechConfig(
            voice_config=types.VoiceConfig(
                prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name=voice_name)
            )
        ),
    )

    # Collect first audio chunk that contains inline_data.
    # (Streaming is fine, but we just need the binary.)
    audio_bytes = None
    audio_mime = None

    for chunk in client.models.generate_content_stream(
        model=model,
        contents=contents,
        config=config,
    ):
        cand = (chunk.candidates or [None])[0]
        if not cand or not cand.content or not cand.content.parts:
            continue
        part0 = cand.content.parts[0]
        if getattr(part0, "inline_data", None) and part0.inline_data.data:
            audio_bytes = part0.inline_data.data
            audio_mime = part0.inline_data.mime_type
            break

    if not audio_bytes:
        raise RuntimeError("No audio returned by TTS model.")

    # If mime type isn’t a wav container, wrap to wav
    ext = mimetypes.guess_extension(audio_mime or "")
    if ext != ".wav":
        audio_bytes = convert_to_wav(audio_bytes, audio_mime or "audio/L16;rate=24000")

    save_binary_file(out_wav, audio_bytes)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="in_file", required=True, help="Input text file")
    ap.add_argument("--out", dest="out_wav", required=True, help="Output WAV path")
    ap.add_argument("--voice", dest="voice", default="Sadachbia", help="Prebuilt voice name")
    args = ap.parse_args()

    with open(args.in_file, "r", encoding="utf-8") as f:
        text = f.read().strip()

    # Optional: prepend an instruction like in your example
    text = f"Read aloud in a warm and friendly tone:\n{text}"

    tts(text=text, out_wav=args.out_wav, voice_name=args.voice)


if __name__ == "__main__":
    main()
