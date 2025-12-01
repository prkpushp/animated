name: YouTube → Hindi Transcript

on:
  workflow_dispatch:
    inputs:
      youtube_url:
        description: 'Public YouTube video URL'
        required: true
        default: 'https://www.youtube.com/watch?v=8SRe1bNO38E'

jobs:
  transcribe:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout repo
      uses: actions/checkout@v4

    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.10'

    - name: Create Cookies File
      # Only runs if the secret is set
      if: ${{ secrets.YOUTUBE_COOKIES != '' }}
      run: echo "${{ secrets.YOUTUBE_COOKIES }}" > cookies.txt

    - name: Install dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y ffmpeg
        # Install latest yt-dlp from master to get newest fixes
        pip install -U https://github.com/yt-dlp/yt-dlp/archive/master.zip
        pip install -q openai-whisper torch

    - name: Run Hindi transcription
      env:
        YOUTUBE_URL: ${{ github.event.inputs.youtube_url }}
      run: python scripts/transcribe.py

    - name: Upload Hindi text as artifact
      uses: actions/upload-artifact@v4
      with:
        name: hindi_text
        path: hindi_output.txt
