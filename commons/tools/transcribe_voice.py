"""Transcribe a WAV file using OpenAI Whisper API.

Usage:
  python transcribe_voice.py <wav_path>
  python transcribe_voice.py  (defaults to /tmp/claude_voice.wav)

Reads the OpenAI API key from the oversight_light project database.
Outputs the transcript text to stdout.
"""
import sys
import json
import sqlite3
import urllib.request
import urllib.error
from pathlib import Path

OVERSIGHT_DB = Path.home() / "Documents/GitHub/oversight_light/data/oversight.db"
WHISPER_URL = "https://api.openai.com/v1/audio/transcriptions"
MODEL = "whisper-1"


def get_api_key() -> str:
    """Read OpenAI API key from oversight_light database."""
    if not OVERSIGHT_DB.exists():
        raise FileNotFoundError(f"Oversight DB not found: {OVERSIGHT_DB}")
    conn = sqlite3.connect(str(OVERSIGHT_DB))
    row = conn.execute("SELECT settings FROM projects LIMIT 1").fetchone()
    conn.close()
    if not row:
        raise ValueError("No project found in oversight DB")
    data = json.loads(row[0])
    key = data.get("openai", {}).get("apiKey", "")
    if not key:
        raise ValueError("No OpenAI API key in oversight settings")
    return key


def transcribe(wav_path: str, api_key: str) -> str:
    """Send WAV to OpenAI Whisper API, return transcript text."""
    wav = Path(wav_path)
    if not wav.exists():
        raise FileNotFoundError(f"WAV not found: {wav_path}")

    # Build multipart/form-data manually (no requests dependency)
    boundary = "----ClaudeBridgeBoundary9876543210"
    body = bytearray()

    # model field
    body += f"--{boundary}\r\n".encode()
    body += b'Content-Disposition: form-data; name="model"\r\n\r\n'
    body += f"{MODEL}\r\n".encode()

    # file field
    body += f"--{boundary}\r\n".encode()
    body += f'Content-Disposition: form-data; name="file"; filename="{wav.name}"\r\n'.encode()
    body += b"Content-Type: audio/wav\r\n\r\n"
    body += wav.read_bytes()
    body += b"\r\n"

    body += f"--{boundary}--\r\n".encode()

    req = urllib.request.Request(
        WHISPER_URL,
        data=bytes(body),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": f"multipart/form-data; boundary={boundary}",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            result = json.loads(resp.read().decode())
            return result.get("text", "")
    except urllib.error.HTTPError as e:
        error_body = e.read().decode() if e.fp else ""
        raise RuntimeError(f"Whisper API error {e.code}: {error_body}")


def main():
    wav_path = sys.argv[1] if len(sys.argv) > 1 else "C:/Users/palle/AppData/Local/Temp/claude_voice.wav"
    api_key = get_api_key()
    transcript = transcribe(wav_path, api_key)
    print(transcript)


if __name__ == "__main__":
    main()
