import os
import torch
import numpy as np
import scipy.io.wavfile as wavfile
import subprocess
from audiocraft.models import MusicGen
from huggingface_hub import login

prompt = os.getenv("INPUT_PROMPT", "chill lofi with rain")
hf_token = os.getenv("HF_TOKEN", "")

print(f"🎵 Generating music for prompt: {prompt}")

# Authenticate with Hugging Face
login(token=hf_token)

# Load model
model = MusicGen.get_pretrained("facebook/musicgen-medium")
model.set_generation_params(duration=30)

# Generate waveform
waveform = model.generate([prompt])[0]

# Convert to NumPy and fix shape
waveform = waveform.detach().cpu().numpy()
if waveform.ndim > 1:
    waveform = waveform[0]  # mono
waveform = np.clip(waveform * 32767, -32768, 32767).astype(np.int16)

# Write .wav file
sample_rate = int(model.sample_rate)
wav_path = "output/music.wav"
mp3_path = "output/music.mp3"

wavfile.write(wav_path, sample_rate, waveform)
print(f"✅ WAV file saved: {wav_path}")

# Convert to MP3 using ffmpeg
try:
    subprocess.run(
        ["ffmpeg", "-y", "-i", wav_path, "-codec:a", "libmp3lame", "-b:a", "192k", mp3_path],
        check=True
    )
    print(f"🎧 MP3 file saved: {mp3_path}")
except subprocess.CalledProcessError as e:
    print("❌ MP3 conversion failed:", e)
