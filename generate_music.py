from google.cloud import aiplatform

import os

prompt = os.getenv("MUSIC_PROMPT", "A calm, cinematic ambient soundtrack with rain")

# Initialize Vertex AI
aiplatform.init(project="omega-episode-454707-j5", location="us-central1")

model = aiplatform.GenerativeModel(model_name="models/lyria")  # Lyria 2 assumed as 'lyria'

response = model.generate_content(prompt)

audio_bytes = response.candidates[0].audio  # May vary based on actual API return

# Ensure output directory exists
os.makedirs("output", exist_ok=True)

# Write output to file
with open("output/music.mp3", "wb") as f:
    f.write(audio_bytes)
