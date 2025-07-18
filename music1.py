import os
import torch
from audiocraft.models import MusicGen
from audiocraft.utils.audio import save_wav
from huggingface_hub import login

prompt = os.getenv("INPUT_PROMPT", "chill lofi with rain")
hf_token = os.getenv("HF_TOKEN", "")

print(f"🎵 Generating music for prompt: {prompt}")

login(token=hf_token)
model = MusicGen.get_pretrained("facebook/musicgen-medium")
model.set_generation_params(duration=30)

# Generate waveform (Tensor: [1, samples])
waveform = model.generate([prompt])[0]

# Save using audiocraft's official high-quality export
os.makedirs("output", exist_ok=True)
save_wav(waveform, "output/music.wav", sr=model.sample_rate)

print("✅ WAV saved using MusicGen's native function.")
