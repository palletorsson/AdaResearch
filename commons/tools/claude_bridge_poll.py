"""Claude Bridge — PC-side helper for VR communication.

Commands:
  python claude_bridge_poll.py interact "Walk to the station" [--screenshot] [--no-wait] [--timeout 60]
  python claude_bridge_poll.py look                           # screenshot only, no message
  python claude_bridge_poll.py send "message"                 # send only, no wait
  python claude_bridge_poll.py poll [--timeout 60]            # poll only (uses last sent ID)
  python claude_bridge_poll.py screenshot [--save path.png]
  python claude_bridge_poll.py voice

All commands output JSON to stdout and log to stderr.
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

_message_id_file = TEMP_DIR / "claude_bridge_msg_id.txt"


# ── helpers ──────────────────────────────────────────────────────────────────

def _get_next_id() -> int:
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


def _out(data: dict) -> None:
    """Print JSON result to stdout."""
    print(json.dumps(data))


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


# ── core operations ─────────────────────────────────────────────────────────

def send_message(text: str, msg_id: int = -1) -> int:
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
    if warn_user:
        send_message("Taking screenshot in 2 sec...", msg_id=_get_current_id())
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

    SCREENSHOTS_DIR.mkdir(exist_ok=True)
    ts = time.strftime("%Y%m%d_%H%M%S")
    dest = str(SCREENSHOTS_DIR / f"vr_{ts}.png")
    if save_path:
        dest = save_path
    shutil.copy(local, dest)
    print(f"[bridge] Screenshot saved: {dest}", file=sys.stderr)

    send_message("Screenshot saved!", msg_id=_get_current_id())
    return dest


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

    send_message("Receiving voice message...", msg_id=_get_current_id())

    local_wav = str(TEMP_DIR / "claude_voice.wav")
    if not adb_pull(f"{BRIDGE_PATH}/voice.wav", local_wav):
        print("[bridge] Failed to pull voice.wav", file=sys.stderr)
        return None

    wav_size = Path(local_wav).stat().st_size
    print(f"[bridge] Voice WAV pulled ({wav_size} bytes)", file=sys.stderr)

    adb_rm(f"{BRIDGE_PATH}/voice_ready.json")

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


def poll(message_id: int = -1, timeout: int = 120, interval: float = 2.0) -> tuple[str | None, str | None]:
    """Poll for response. Returns (response_type, response_text)."""
    if message_id < 0:
        message_id = _get_current_id()
    start = time.time()
    print(f"[bridge] Polling for response (id={message_id}, timeout={timeout}s)...", file=sys.stderr)

    while time.time() - start < timeout:
        voice = check_voice(message_id)
        if voice is not None:
            return ("voice", voice)

        inbox = check_inbox(message_id)
        if inbox is not None:
            send_message("Claude live!", msg_id=_get_current_id())
            return ("button", inbox)

        time.sleep(interval)

    print("[bridge] Timeout", file=sys.stderr)
    return (None, None)


# ── high-level commands ──────────────────────────────────────────────────────

def interact(text: str = None, screenshot: bool = False, no_wait: bool = False,
             timeout: int = 120) -> dict:
    """Unified interaction: send → poll → optional screenshot. Returns result dict."""
    result = {
        "status": "ok",
        "message_id": None,
        "sent": text,
        "response_type": None,
        "response": None,
        "screenshot": None,
    }

    # Send message if provided
    if text:
        msg_id = send_message(text)
        result["message_id"] = msg_id
    else:
        result["message_id"] = _get_current_id()

    # Fire-and-forget
    if no_wait and not screenshot:
        return result

    # Poll for response
    if not no_wait:
        resp_type, resp_text = poll(timeout=timeout)
        result["response_type"] = resp_type
        result["response"] = resp_text
        if resp_type is None:
            result["status"] = "timeout"

    # Screenshot
    if screenshot:
        path = take_screenshot(warn_user=True)
        result["screenshot"] = path
        if path is None:
            result["status"] = "screenshot_failed" if result["status"] == "ok" else result["status"]

    return result


def look() -> dict:
    """Screenshot only — no message, no wait."""
    path = take_screenshot(warn_user=True)
    return {
        "status": "ok" if path else "screenshot_failed",
        "screenshot": path,
    }


# ── CLI ──────────────────────────────────────────────────────────────────────

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Claude Bridge helper")
    sub = parser.add_subparsers(dest="command")

    # interact (primary command)
    p_interact = sub.add_parser("interact", help="Send + poll + optional screenshot")
    p_interact.add_argument("text", nargs="?", default=None, help="Message to send")
    p_interact.add_argument("--screenshot", action="store_true", help="Take screenshot after response")
    p_interact.add_argument("--no-wait", action="store_true", help="Fire-and-forget, don't poll")
    p_interact.add_argument("--timeout", type=int, default=120)

    # look (screenshot shorthand)
    sub.add_parser("look", help="Take screenshot only")

    # send
    p_send = sub.add_parser("send", help="Send message to VR (no wait)")
    p_send.add_argument("text", help="Message text")

    # poll
    p_poll = sub.add_parser("poll", help="Poll for user response")
    p_poll.add_argument("--message-id", type=int, default=-1)
    p_poll.add_argument("--timeout", type=int, default=120)

    # screenshot
    p_ss = sub.add_parser("screenshot", help="Take VR screenshot")
    p_ss.add_argument("--save", help="Save path", default=None)
    p_ss.add_argument("--no-warn", action="store_true", help="Skip 2s warning")

    # voice
    p_voice = sub.add_parser("voice", help="Pull and transcribe voice")
    p_voice.add_argument("--message-id", type=int, default=-1)

    args = parser.parse_args()

    if args.command == "interact":
        result = interact(args.text, args.screenshot, args.no_wait, args.timeout)
        _out(result)

    elif args.command == "look":
        _out(look())

    elif args.command == "send":
        msg_id = send_message(args.text)
        _out({"status": "ok", "message_id": msg_id})

    elif args.command == "poll":
        msg_id = args.message_id if args.message_id >= 0 else _get_current_id()
        resp_type, resp_text = poll(msg_id, args.timeout)
        if resp_type is None:
            _out({"status": "timeout", "response_type": None, "response": None})
            sys.exit(1)
        _out({"status": "ok", "response_type": resp_type, "response": resp_text})

    elif args.command == "screenshot":
        path = take_screenshot(args.save, warn_user=not args.no_warn)
        if path is None:
            _out({"status": "screenshot_failed", "screenshot": None})
            sys.exit(1)
        _out({"status": "ok", "screenshot": path})

    elif args.command == "voice":
        mid = args.message_id if args.message_id >= 0 else _get_current_id()
        transcript = check_voice(mid)
        if transcript is None:
            _out({"status": "no_voice", "response": None})
            sys.exit(1)
        _out({"status": "ok", "response_type": "voice", "response": transcript})

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
