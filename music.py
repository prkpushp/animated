import os
import torch
import numpy as np
import soundfile as sf
from audiocraft.models import MusicGen
from huggingface_hub import login

prompt = os.getenv("INPUT_PROMPT", "ambient meditation")
hf_token = os.getenv("HF_TOKEN", "")

print(f"🎵 Generating music for prompt: {prompt}")

# Login
login(token=hf_token)

# Load model
model = MusicGen.get_pretrained("facebook/musicgen-medium")
model.set_generation_params(duration=30)

# Generate music
waveform = model.generate([prompt])[0]

# Convert to NumPy int16
waveform = (waveform * 32767).cpu().numpy().astype("int16")

# Normalize shape
if waveform.ndim > 2:
    waveform = waveform.squeeze()
if waveform.ndim == 2 and waveform.shape[0] == 1:
    waveform = waveform[0]

# Save as WAV using soundfile
output_path = "output/music.wav"
sf.write(output_path, waveform, int(model.sample_rate), subtype="PCM_16")
print(f"✅ Saved to {output_path}")
