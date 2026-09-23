"""Narrate a captured Ada Research edition with Google Gemini TTS.

Credentials are entered locally and protected with Windows DPAPI, outside Git.
No key is ever accepted as a command-line argument. `plan` makes no API calls.
"""
from __future__ import annotations

import argparse
import base64
from concurrent.futures import ThreadPoolExecutor
import hashlib
import io
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import wave

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_BUNDLE = ROOT / "doc/book/iterations/2026-09-21-primitives-audiobook"
MODEL = "gemini-3.1-flash-tts-preview"
VOICE = "Sulafat"
ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/interactions"
RATE = 24000
DIRECTION = (
    "Synthesize speech for an audiobook. Read only the transcript below, exactly as written. "
    "Use a warm, thoughtful, curious voice, speaking to one listener. "
    "Read in clear English at an unhurried, natural pace, around 145 words per minute. "
    "Let questions remain open. Leave a small breath between paragraphs. "
    "Articulate the spoken code clearly. No music, additional commentary or sound effects. "
    "Do not read these instructions or the transcript label aloud.\n\nTRANSCRIPT:\n"
)


def credential_path():
    local = os.environ.get("LOCALAPPDATA")
    if not local:
        raise RuntimeError("Windows LOCALAPPDATA is unavailable; use GEMINI_API_KEY instead.")
    return Path(local) / "AdaResearch/speech/gemini-key.dpapi"


def setup_key(gui=False):
    import win32crypt
    if gui:
        import tkinter as tk
        from tkinter import messagebox, simpledialog
        window = tk.Tk()
        window.withdraw()
        value = simpledialog.askstring(
            "Ada Research — Google speech setup",
            "Paste the Gemini API key from Google AI Studio here.\n\n"
            "It will be encrypted for your Windows account, outside the project.\n"
            "Saving the key makes no request to Google and creates no charges.",
            show="*", parent=window,
        )
    else:
        import getpass
        value = getpass.getpass("Gemini API key (hidden): ")
    if not value:
        if gui:
            window.destroy()
        print("Setup cancelled. No key saved.")
        return
    value = value.strip()
    if len(value) < 20 or any(c.isspace() for c in value):
        if gui:
            messagebox.showerror("Key not saved", "That does not look like a complete API key.", parent=window)
            window.destroy()
        raise RuntimeError("Key not saved: paste only the complete API key.")
    blob = win32crypt.CryptProtectData(value.encode(), "Ada Research Gemini speech", None, None, None, 0)
    path = credential_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(".tmp")
    temporary.write_bytes(blob)
    temporary.replace(path)
    del value
    if gui:
        messagebox.showinfo("Google speech key saved", "Saved locally, encrypted. Tell Codex: key saved.\n\n"
                            "The connection and voice still need a sample test.", parent=window)
        window.destroy()
    print("Key saved locally with Windows encryption. No API call made.")


def load_key():
    for name in ("GEMINI_API_KEY", "GOOGLE_API_KEY"):
        if os.environ.get(name):
            return os.environ[name].strip()
    path = credential_path()
    if not path.is_file():
        raise RuntimeError("Google key not configured. Run: python tools/google_audiobook.py setup --gui")
    import win32crypt
    return win32crypt.CryptUnprotectData(path.read_bytes(), None, None, None, 0)[1].decode()


def read_edition(bundle):
    edition = json.loads((bundle / "narration.json").read_text(encoding="utf-8"))
    for source in edition["sources"]:
        snapshot = bundle / "source" / (source["map"] + ".md")
        if not snapshot.exists():
            snapshot = bundle / "source" / source["map"] / "final.md"
        if not snapshot.exists() or hashlib.sha256(snapshot.read_bytes()).hexdigest() != source["sha256"]:
            raise RuntimeError("Captured source missing or changed: " + source["map"])
    return edition


def split_text(segments, limit=280):
    """Keep paragraph boundaries where possible; preserve every word in order."""
    chunks, current, words = [], [], 0
    for segment in segments:
        text = segment["text"].strip()
        if not text:
            continue
        pieces = [text]
        if len(text.split()) > limit:
            tokens = text.split()
            pieces = [" ".join(tokens[i:i + limit]) for i in range(0, len(tokens), limit)]
        for piece in pieces:
            count = len(piece.split())
            if current and words + count > limit:
                chunks.append("\n\n".join(current))
                current, words = [], 0
            current.append(piece)
            words += count
    if current:
        chunks.append("\n\n".join(current))
    original = " ".join(s["text"] for s in segments).split()
    assert " ".join(chunks).split() == original, "Chunking lost or reordered text"
    return chunks


def decode_audio(response):
    if response.get("status") != "completed":
        raise RuntimeError("Google did not complete the audio. No partial track accepted.")
    pcm = bytearray()
    for step in response.get("steps", []):
        if step.get("type") != "model_output":
            continue
        for part in step.get("content", []):
            if part.get("type") != "audio" or not part.get("data"):
                continue
            raw = base64.b64decode(part["data"], validate=True)
            mime = part.get("mime_type", "audio/l16;rate=24000").lower()
            if raw.startswith(b"RIFF"):
                with wave.open(io.BytesIO(raw), "rb") as stream:
                    if (stream.getnchannels(), stream.getsampwidth(), stream.getframerate()) != (1, 2, RATE):
                        raise RuntimeError("Unexpected WAV format from Google.")
                    raw = stream.readframes(stream.getnframes())
            elif mime.startswith(("audio/l16", "audio/pcm")):
                rate_match = re.search(r"rate=(\d+)", mime)
                if rate_match and int(rate_match[1]) != RATE:
                    raise RuntimeError("Unexpected PCM sample rate from Google.")
                # Gemini's documented TTS output is little-endian, 16-bit mono PCM.
            else:
                raise RuntimeError("Unexpected audio encoding from Google.")
            pcm.extend(raw)
    if len(pcm) < RATE or len(pcm) % 2:
        raise RuntimeError("Google returned no usable audio. No output saved.")
    return bytes(pcm)


def write_wav(path, pcm):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(".partial")
    with wave.open(str(temporary), "wb") as stream:
        stream.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        stream.writeframes(pcm)
    temporary.replace(path)


def synthesize(text, key, model, voice, cache):
    import requests
    prompt = DIRECTION + text
    digest = hashlib.sha256(json.dumps([model, voice, prompt], ensure_ascii=False).encode()).hexdigest()
    output = cache / (digest + ".wav")
    if output.exists():
        with wave.open(str(output), "rb") as stream:
            if stream.getnframes() < RATE // 2:
                raise RuntimeError("Cached audio is incomplete.")
        return output
    payload = {"model": model, "input": prompt, "store": False,
               "response_format": {"type": "audio"},
               "generation_config": {"speech_config": [{"voice": voice}]}}
    for attempt in range(3):
        try:
            response = requests.post(ENDPOINT, json=payload,
                                     headers={"x-goog-api-key": key, "Api-Revision": "2026-05-20"},
                                     timeout=(20, 240), allow_redirects=False)
        except requests.RequestException:
            raise RuntimeError("Connection interrupted. No automatic retry; rerun to resume cached chunks.") from None
        if response.status_code in (500, 502, 503, 504) and attempt < 2:
            time.sleep(3 * (attempt + 1))
            continue
        if response.status_code != 200:
            hints = {400: "Check model availability or the API key configuration in AI Studio.",
                     401: "The key was not accepted.",
                     402: "Prepayment credits are depleted. Open Google AI Studio billing; no audio generated.",
                     403: "Check this key's Gemini API access in AI Studio.",
                     404: "The requested model or endpoint is unavailable.",
                     429: "Quota reached. Saved chunks are kept; retry later or check the project's quota."}
            raise RuntimeError(f"Google HTTP {response.status_code}. " + hints.get(response.status_code, "Request failed."))
        try:
            result = response.json()
        except ValueError:
            raise RuntimeError("Google returned an unreadable response.") from None
        pcm = decode_audio(result)
        # A coarse truncation guard; listening is still required for fidelity.
        duration = len(pcm) / (RATE * 2)
        expected = len(text.split())
        if expected > 30 and not expected / 6 < duration < expected * 2:
            raise RuntimeError("Audio duration is implausible for this passage; inspect a sample before continuing.")
        write_wav(output, pcm)
        output.with_suffix(".json").write_text(json.dumps({"model": model, "voice": voice,
            "text_sha256": hashlib.sha256(text.encode()).hexdigest(), "words": expected,
            "seconds": duration, "usage": result.get("usage"), "listening_checked": False}, indent=2), encoding="utf-8")
        return output
    raise RuntimeError("Google speech request did not succeed.")


def join_wav(parts, output, silence_seconds=0.65):
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(".partial")
    frames = 0
    with wave.open(str(temporary), "wb") as target:
        target.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        for i, path in enumerate(parts):
            with wave.open(str(path), "rb") as source:
                if (source.getnchannels(), source.getsampwidth(), source.getframerate()) != (1, 2, RATE):
                    raise RuntimeError("Incompatible chunk: " + path.name)
                while True:
                    data = source.readframes(RATE * 10)
                    if not data:
                        break
                    target.writeframesraw(data)
                    frames += len(data) // 2
            if i < len(parts) - 1:
                silence = int(RATE * silence_seconds)
                target.writeframesraw(bytes(silence * 2))
                frames += silence
    temporary.replace(output)
    return frames / RATE


def make_mp3(wav, mp3, title):
    import imageio_ffmpeg
    mp3.parent.mkdir(parents=True, exist_ok=True)
    temporary = mp3.with_suffix(".partial.mp3")
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), "-hide_banner", "-loglevel", "error", "-y",
                    "-i", str(wav), "-codec:a", "libmp3lame", "-b:a", "96k",
                    "-metadata", "title=" + title, "-metadata", "artist=Ada Research — Google synthetic narration",
                    str(temporary)], check=True)
    temporary.replace(mp3)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["setup", "status", "plan", "sample", "render"])
    parser.add_argument("--gui", action="store_true", help="Enter the key in a masked local window")
    parser.add_argument("--bundle", type=Path, default=DEFAULT_BUNDLE)
    parser.add_argument("--workers", type=int, choices=(1, 2, 3), default=2)
    parser.add_argument("--voice", default=VOICE)
    parser.add_argument("--model", default=MODEL)
    args = parser.parse_args()
    if args.command == "setup":
        return setup_key(args.gui)
    if args.command == "status":
        present = bool(os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")) or credential_path().is_file()
        print(json.dumps({"key_configured": present, "connection_tested": False}))
        return
    edition = read_edition(args.bundle)
    chapters = edition["chapters"]
    work = [(chapter, split_text(chapter["segments"])) for chapter in chapters]
    if args.command == "plan":
        print(json.dumps({"chapters_including_notes": len(work), "requests": sum(len(chunks) for _, chunks in work),
                          "words": sum(len(chunk.split()) for _, chunks in work for chunk in chunks),
                          "model": args.model, "voice": args.voice, "api_calls": 0}, indent=2))
        return
    key = load_key()
    output = args.bundle / "google" / (args.model + "-" + args.voice)
    if args.command == "sample":
        text = split_text(chapters[0]["segments"], limit=150)[0]
        print("Generating an opening sample with Google speech...", flush=True)
        wav = synthesize(text, key, args.model, args.voice, output / "chunks")
        make_mp3(wav, output / "sample.mp3", "Primitives — opening voice sample")
        print(str(output / "sample.mp3"))
        return
    tracks = []
    for chapter, chunks in work:
        print(f"{chapter['title']}: generating {len(chunks)} passages...", flush=True)
        with ThreadPoolExecutor(max_workers=args.workers) as pool:
            jobs = [pool.submit(synthesize, text, key, args.model, args.voice, output / "chunks") for text in chunks]
            parts = []
            for i, job in enumerate(jobs):
                parts.append(job.result())
                print(f"{chapter['title']}: passage {i + 1}/{len(chunks)} ready", flush=True)
        wav = output / "wav" / (chapter["stem"] + ".wav")
        duration = join_wav(parts, wav)
        mp3 = output / "mp3" / (chapter["stem"] + ".mp3")
        make_mp3(wav, mp3, chapter["title"])
        tracks.append({"title": chapter["title"], "wav": str(wav.relative_to(output)),
                       "mp3": str(mp3.relative_to(output)), "seconds": duration})
        (output / "render.json").write_text(json.dumps({"complete": False, "tracks": tracks}, indent=2), encoding="utf-8")
    combined = output / "wav/primitives-complete.wav"
    duration = join_wav([output / t["wav"] for t in tracks], combined, 2.0)
    make_mp3(combined, output / "primitives-complete.mp3", "Ada Research — Primitives")
    (output / "render.json").write_text(json.dumps({"complete": True, "model": args.model, "voice": args.voice,
        "seconds": duration, "tracks": tracks, "sources": edition["sources"], "listening_checked": False}, indent=2), encoding="utf-8")
    print(str(output / "primitives-complete.mp3"))


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, ValueError, subprocess.CalledProcessError) as error:
        print("Stopped: " + str(error), file=sys.stderr)
        sys.exit(1)
