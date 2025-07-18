import os
import torch
import numpy as np
import scipy.io.wavfile as wavfile
from audiocraft.models import MusicGen
from huggingface_hub import login

prompt = os.getenv("INPUT_PROMPT")
hf_token = os.getenv("HF_TOKEN")

print("🎵 Generating music for prompt:", prompt)

# Authenticate with Hugging Face
login(token=hf_token)

# Load model and generate
model = MusicGen.get_pretrained("facebook/musicgen-medium")
model.set_generation_params(duration=30)

# Generate waveform
waveform = model.generate([prompt])[0]
waveform = (waveform * 32767).cpu().numpy().astype("int16")

# Write .wav file
wavfile.write("output/music.wav", model.sample_rate, waveform)
print("✅ Saved: output/music.wav")
