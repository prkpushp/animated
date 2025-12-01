import os
import sys
import re
from youtube_transcript_api import YouTubeTranscriptApi, TranscriptsDisabled, NoTranscriptFound, CouldNotRetrieveTranscript

OUTPUT_FILE = "hindi_output.txt"

def extract_video_id(url):
    match = re.search(r"v=([a-zA-Z0-9_-]{11})", url)
    return match.group(1) if match else None


def main():
    youtube_url = os.getenv("YOUTUBE_URL")
    if not youtube_url:
        print("❌ Error: YOUTUBE_URL is not set.")
        sys.exit(1)

    video_id = extract_video_id(youtube_url)
    if not video_id:
        print("❌ Unable to extract video ID from the URL.")
        sys.exit(1)

    print(f"📌 Extracted Video ID: {video_id}")
    print("📥 Fetching transcript (Hindi preferred)…")

    try:
        transcripts = YouTubeTranscriptApi.list_transcripts(video_id)

        # 1️⃣ Try Hindi transcript
        try:
            transcript = transcripts.find_transcript(['hi', 'hi-IN'])
            print("✅ Found Hindi transcript")
        except NoTranscriptFound:
            print("⚠️ No Hindi transcript found, trying auto-generated captions")

            # 2️⃣ Try auto-generated (usually available)
            try:
                transcript = transcripts.find_manually_created_transcript(['en'])
                print("⚠️ Found English transcript (manual)")
            except:
                transcript = transcripts.find_generated_transcript(['en'])
                print("⚡ Using auto-generated English transcript")

        # Fetch the transcript lines
        text_items = transcript.fetch()

    except TranscriptsDisabled:
        print("❌ This video has no transcripts enabled.")
        sys.exit(1)
    except CouldNotRetrieveTranscript:
        print("❌ YouTube blocked transcript retrieval.")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error fetching transcript: {e}")
        sys.exit(1)

    # Combine all text
    full_text = " ".join(t["text"] for t in text_items)

    # Save output
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(full_text)

    print(f"✅ Saved transcript → {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
