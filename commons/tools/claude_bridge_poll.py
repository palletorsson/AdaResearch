"""Claude Bridge — PC-side helper for VR communication.

Commands:
  python claude_bridge_poll.py send "Walk to the pattern maker station"
  python claude_bridge_poll.py poll [--message-id 3] [--timeout 60]
  python claude_bridge_poll.py screenshot [--save path.png]
  python claude_bridge_poll.py voice [--message-id 3]

All commands send acknowledgment messages to the user's VR hand panel.
"""
import sys
import time
import json
import subprocess
import tempfile
import shutil
import os
from pathlib import Path

BRIDGE_PATH = "/sdcard/Android/data/com.example.adaresearchzeroone/files/claude_bridge"
SCREEN_PATH = "/sdcard/claude_bridge/screen.png"
TEMP_DIR = Path(tempfile.gettempdir())
SCREENSHOTS_DIR = Path(__file__).parent / "bridge_screenshots"
TRANSCRIBE_SCRIPT = Path(__file__).parent / "transcribe_voice.py"
OUTBOX_LOCAL = TEMP_DIR / "claude_outbox.json"

# Tracks current message ID across calls in same process
_message_id_file = TEMP_DIR / "claude_bridge_msg_id.txt"


def _get_next_id() -> int:
    """Increment and return the next message ID."""
    current = 0
    if _message_id_file.exists():
        try:
            current = int(_message_id_file.read_text().strip())
        except ValueError:
            pass
    next_id = current + 1
    _message_id_file.write_text(str(next_id))
    return next_id


def _get_current_id() -> int:
    if _message_id_file.exists():
        try:
            return int(_message_id_file.read_text().strip())
        except ValueError:
            pass
    return 0


def _adb(*args) -> subprocess.CompletedProcess:
    env = {**os.environ, "MSYS_NO_PATHCONV": "1"}
    return subprocess.run(
        ["adb", *args],
        capture_output=True, text=True, env=env
    )


def adb_pull(remote: str, local: str) -> bool:
    return _adb("pull", remote, local).returncode == 0


def adb_push(local: str, remote: str) -> bool:
    return _adb("push", local, remote).returncode == 0


def adb_rm(remote: str) -> None:
    _adb("shell", f"rm -f {remote}")


def send_message(text: str, msg_id: int = -1) -> int:
    """Send a message to VR hand panel. Returns the message ID."""
    if msg_id < 0:
        msg_id = _get_next_id()
    payload = {"id": msg_id, "text": text}
    OUTBOX_LOCAL.write_text(json.dumps(payload))
    ok = adb_push(str(OUTBOX_LOCAL), f"{BRIDGE_PATH}/outbox.json")
    if ok:
        print(f"[bridge] Sent #{msg_id}: {text[:80]}", file=sys.stderr)
    else:
        print(f"[bridge] FAILED to push message #{msg_id}", file=sys.stderr)
    return msg_id


def take_screenshot(save_path: str = None, warn_user: bool = True) -> str | None:
    """Take a VR screenshot. Optionally warns user first. Returns local path."""
    if warn_user:
        send_message("Taking screenshot in 2 sec...")
        time.sleep(2)

    r = _adb("shell", f"screencap -p {SCREEN_PATH}")
    if r.returncode != 0:
        print("[bridge] screencap failed", file=sys.stderr)
        return None

    local = str(TEMP_DIR / "vr_latest.png")
    if not adb_pull(SCREEN_PATH, local):
        print("[bridge] pull screenshot failed", file=sys.stderr)
        return None

    size = Path(local).stat().st_size
    if size < 100000:
        print(f"[bridge] Screenshot too small ({size} bytes) — Quest may be sleeping", file=sys.stderr)
        return None

    # Save with timestamp
    if save_path:
        shutil.copy(local, save_path)
        print(f"[bridge] Screenshot saved: {save_path}", file=sys.stderr)
    else:
        SCREENSHOTS_DIR.mkdir(exist_ok=True)
        ts = time.strftime("%Y%m%d_%H%M%S")
        dest = SCREENSHOTS_DIR / f"vr_{ts}.png"
        shutil.copy(local, str(dest))
        print(f"[bridge] Screenshot saved: {dest}", file=sys.stderr)

    print(f"[bridge] Screenshot OK ({size} bytes)", file=sys.stderr)
    send_message("Screenshot saved!")
    return local


def check_inbox(message_id: int) -> str | None:
    local = str(TEMP_DIR / "claude_inbox.json")
    if not adb_pull(f"{BRIDGE_PATH}/inbox.json", local):
        return None
    try:
        data = json.loads(Path(local).read_text())
        if data.get("id") == message_id:
            return data.get("text", "done")
    except (json.JSONDecodeError, KeyError):
        pass
    return None


def check_voice(message_id: int) -> str | None:
    local_ready = str(TEMP_DIR / "claude_voice_ready.json")
    if not adb_pull(f"{BRIDGE_PATH}/voice_ready.json", local_ready):
        return None
    try:
        data = json.loads(Path(local_ready).read_text())
        if data.get("status") != "ready":
            return None
        if data.get("id", -1) != message_id and message_id >= 0:
            return None
    except (json.JSONDecodeError, KeyError):
        return None

    # Acknowledge to user
    send_message("Receiving voice message...", msg_id=_get_current_id())

    # Pull WAV
    local_wav = str(TEMP_DIR / "claude_voice.wav")
    if not adb_pull(f"{BRIDGE_PATH}/voice.wav", local_wav):
        print("[bridge] Failed to pull voice.wav", file=sys.stderr)
        return None

    wav_size = Path(local_wav).stat().st_size
    print(f"[bridge] Voice WAV pulled ({wav_size} bytes)", file=sys.stderr)

    adb_rm(f"{BRIDGE_PATH}/voice_ready.json")

    # Transcribe
    send_message("Transcribing...", msg_id=_get_current_id())
    result = subprocess.run(
        [sys.executable, str(TRANSCRIBE_SCRIPT), local_wav],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"[bridge] Transcription error: {result.stderr}", file=sys.stderr)
        return None

    transcript = result.stdout.strip()
    if transcript:
        print(f"[bridge] Transcribed: {transcript}", file=sys.stderr)
    return transcript if transcript else None


def poll(message_id: int = -1, timeout: int = 120, interval: float = 2.0) -> str | None:
    """Poll for response. Sends acknowledgments to VR."""
    start = time.time()
    print(f"[bridge] Polling for response (id={message_id}, timeout={timeout}s)...", file=sys.stderr)

    last_inbox_id = None

    while time.time() - start < timeout:
        # Check voice first
        voice = check_voice(message_id)
        if voice is not None:
            return voice

        # Check button confirm
        inbox = check_inbox(message_id)
        if inbox is not None and inbox != last_inbox_id:
            # Acknowledge the confirm
            send_message("Claude live!", msg_id=_get_current_id())
            return inbox

        time.sleep(interval)

    print("[bridge] Timeout", file=sys.stderr)
    return None


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Claude Bridge helper")
    sub = parser.add_subparsers(dest="command")

    # send
    p_send = sub.add_parser("send", help="Send message to VR")
    p_send.add_argument("text", help="Message text")

    # poll
    p_poll = sub.add_parser("poll", help="Poll for user response")
    p_poll.add_argument("--message-id", type=int, default=-1)
    p_poll.add_argument("--timeout", type=int, default=120)
    p_poll.add_argument("--interval", type=float, default=2.0)

    # screenshot
    p_ss = sub.add_parser("screenshot", help="Take VR screenshot")
    p_ss.add_argument("--save", help="Save path", default=None)
    p_ss.add_argument("--no-warn", action="store_true", help="Skip 2s warning")

    # voice (one-shot: pull + transcribe)
    p_voice = sub.add_parser("voice", help="Pull and transcribe voice")
    p_voice.add_argument("--message-id", type=int, default=-1)

    args = parser.parse_args()

    if args.command == "send":
        msg_id = send_message(args.text)
        print(msg_id)

    elif args.command == "poll":
        resp = poll(args.message_id, args.timeout, args.interval)
        if resp is None:
            sys.exit(1)
        print(resp)

    elif args.command == "screenshot":
        path = take_screenshot(args.save, warn_user=not args.no_warn)
        if path is None:
            sys.exit(1)
        print(path)

    elif args.command == "voice":
        transcript = check_voice(args.message_id)
        if transcript is None:
            print("No voice message ready", file=sys.stderr)
            sys.exit(1)
        print(transcript)

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
