import os
import torch
import numpy as np
import scipy.io.wavfile as wavfile
from audiocraft.models import MusicGen
from huggingface_hub import login

# Read input prompt and Hugging Face token from environment
prompt = os.getenv("INPUT_PROMPT", "ambient meditation music")
hf_token = os.getenv("HF_TOKEN", "")

print(f"🎵 Generating music for prompt: {prompt}")

# Authenticate with Hugging Face
login(token=hf_token)

# Load the MusicGen model
model = MusicGen.get_pretrained("facebook/musicgen-medium")
model.set_generation_params(duration=30)  # duration in seconds

# Generate music
waveform = model.generate([prompt])[0]

# Convert waveform to 16-bit PCM NumPy array
waveform = (waveform * 32767).cpu().numpy().astype("int16")

# Ensure waveform has correct shape
if waveform.ndim > 2:
    waveform = waveform.squeeze()

# Get sample rate as integer
sample_rate = int(model.sample_rate)

# Write to .wav file
output_path = "output/music.wav"
wavfile.write(output_path, sample_rate, waveform)

print(f"✅ Music saved to {output_path}")
