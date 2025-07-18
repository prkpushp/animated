import os
import torch
import numpy as np
import scipy.io.wavfile as wavfile
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

# Convert tensor to numpy and ensure shape (samples, ) or (samples, 1)
waveform = waveform.detach().cpu().numpy()

# Ensure waveform is mono (1D)
if waveform.ndim > 1:
    waveform = waveform[0]  # take first channel

# Normalize and cast to int16
waveform = np.clip(waveform * 32767, -32768, 32767).astype(np.int16)

# Fix sample rate and output path
sample_rate = int(model.sample_rate)
output_path = "output/music.wav"

# Final write
wavfile.write(output_path, sample_rate, waveform)
print(f"✅ Saved to: {output_path}")
