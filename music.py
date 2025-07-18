import os
import torch
import scipy.io.wavfile as wavfile
from audiocraft.models import MusicGen
from huggingface_hub import login

prompt = os.getenv("INPUT_PROMPT")
hf_token = os.getenv("HF_TOKEN")

print("🎵 Generating music for prompt:", prompt)

# Authenticate with Hugging Face
login(token=hf_token)

# Load model and generate music
device = "cuda" if torch.cuda.is_available() else "cpu"
model = MusicGen.get_pretrained("facebook/musicgen-medium")
model.set_generation_params(duration=30)

waveform = model.generate([prompt], device=device)[0]
waveform = (waveform * 32767).astype("int16")  # Convert float32 to PCM16
wavfile.write("output/music.wav", model.sample_rate, waveform)
print("✅ Saved: output/music.wav")
