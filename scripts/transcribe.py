import os
import sys
import re
from youtube_transcript_api import YouTubeTranscriptApi, TranscriptsDisabled, NoTranscriptFound

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
        print("❌ Could not extract video ID from URL.")
        sys.exit(1)

    print(f"📌 Extracted Video ID: {video_id}")
    print("📥 Fetching transcript (Hindi preferred)…")

    transcript_data = None

    try:
        # Try Hindi first (works across ALL versions)
        try:
            transcript_data = YouTubeTranscriptApi.get_transcript(
                video_id, languages=['hi', 'hi-IN']
            )
            print("✅ Found Hindi transcript")

        except NoTranscriptFound:
            print("⚠️ No Hindi transcript. Trying auto-generated English…")

            try:
                transcript_data = YouTubeTranscriptApi.get_transcript(
                    video_id, languages=['en']
                )
                print("⚡ Found English auto transcript")
            except Exception:
                print("❌ No transcripts available at all.")
                sys.exit(1)

    except TranscriptsDisabled:
        print("❌ Transcripts disabled for this video.")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error fetching transcript: {e}")
        sys.exit(1)

    # Combine text from transcript
    final_text = " ".join(entry["text"] for entry in transcript_data)

    # Save output
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(final_text)

    print(f"✅ Saved transcript → {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
