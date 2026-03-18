#!/usr/bin/env python3
"""
Test script for AIAssistantPanel file-based protocol.
Simulates the external AI agent side of the HITL roundtrip.

Protocol files (in ~/Library/Application Support/Godot/app_userdata/Ada Research Zero One/):
- ai_state.json: Written by Godot, contains live state snapshot
- ai_chat.json: Written by Godot when user sends a message
- ai_response.json: Written by AI agent, read by Godot

Usage:
  python3 test_ai_protocol.py --watch   # Watch for chat messages and respond
  python3 test_ai_protocol.py --test    # Create test response file
  python3 test_ai_protocol.py --status  # Show current state
"""

import json
import os
import sys
import time
from pathlib import Path
from datetime import datetime

# Godot user:// path on macOS
USER_DIR = Path.home() / "Library/Application Support/Godot/app_userdata/Ada Research Zero One"

STATE_PATH = USER_DIR / "ai_state.json"
CHAT_PATH = USER_DIR / "ai_chat.json"
RESPONSE_PATH = USER_DIR / "ai_response.json"


def read_json(path: Path):
    if not path.exists():
        return None
    try:
        with open(path) as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        print(f"  [error reading {path.name}: {e}]")
        return None


def write_response(text: str, changes: list = None):
    """Write a response file that Godot will read and display."""
    response = {
        "role": "assistant",
        "text": text,
        "timestamp": datetime.now().isoformat(),
        "changes": changes or []
    }
    USER_DIR.mkdir(parents=True, exist_ok=True)
    with open(RESPONSE_PATH, 'w') as f:
        json.dump(response, f, indent=2)
    print(f"[wrote response to {RESPONSE_PATH.name}]")


def show_status():
    """Show current protocol state."""
    print(f"\n=== AIAssistantPanel Protocol Status ===")
    print(f"User dir: {USER_DIR}")
    print(f"Dir exists: {USER_DIR.exists()}")
    print()

    # State file
    print("--- ai_state.json ---")
    state = read_json(STATE_PATH)
    if state:
        print(f"  timestamp: {state.get('timestamp', '?')}")
        print(f"  song: {state.get('song_name', 'none')} ({state.get('song_id', '?')})")
        print(f"  section: {state.get('section', 'none')}")
        print(f"  position: bar {state.get('bar', '?')}, beat {state.get('beat', '?')}")
        print(f"  playing: {state.get('playing', False)}")
        print(f"  bpm: {state.get('bpm', '?')}")
        track = state.get('selected_track', {})
        if track:
            print(f"  track: {track.get('name', '?')} (index {track.get('index', '?')})")
        notes = state.get('selected_notes', [])
        print(f"  selected notes: {len(notes)}")
    else:
        print("  [not found or empty]")
    print()

    # Chat file
    print("--- ai_chat.json ---")
    chat = read_json(CHAT_PATH)
    if chat:
        messages = chat.get('messages', [])
        print(f"  total messages: {len(messages)}")
        if messages:
            last = messages[-1]
            print(f"  last message: [{last.get('role', '?')}] {last.get('text', '')[:50]}...")
    else:
        print("  [not found or empty]")
    print()

    # Response file
    print("--- ai_response.json ---")
    if RESPONSE_PATH.exists():
        resp = read_json(RESPONSE_PATH)
        if resp:
            print(f"  pending response: {resp.get('text', '')[:50]}...")
        else:
            print("  [exists but unreadable]")
    else:
        print("  [not present - ready for new response]")
    print()


def watch_and_respond():
    """Watch for new chat messages and auto-respond."""
    print(f"Watching {CHAT_PATH} for new messages...")
    print("Press Ctrl+C to stop\n")

    last_msg_count = 0
    chat = read_json(CHAT_PATH)
    if chat:
        last_msg_count = len(chat.get('messages', []))

    while True:
        try:
            chat = read_json(CHAT_PATH)
            if chat:
                messages = chat.get('messages', [])
                if len(messages) > last_msg_count:
                    # New message(s)
                    for msg in messages[last_msg_count:]:
                        if msg.get('role') == 'user':
                            text = msg.get('text', '')
                            state = msg.get('state_snapshot', {})
                            print(f"\n[New message] {text}")
                            print(f"  context: song={state.get('song_id', '?')}, bar={state.get('bar', '?')}")

                            # Generate response
                            response_text = generate_response(text, state)
                            write_response(response_text)
                    last_msg_count = len(messages)

            time.sleep(1)
        except KeyboardInterrupt:
            print("\nStopped watching.")
            break


def generate_response(user_text: str, state: dict) -> str:
    """Generate a simple response based on user message and state."""
    text_lower = user_text.lower()
    song = state.get('song_id', 'the song')
    track = state.get('selected_track', {}).get('name', 'this track')

    if 'darker' in text_lower or 'warmer' in text_lower:
        return f"I'll adjust {track} to be darker. Try lowering the filter cutoff to around 600 Hz and adding some subtle saturation."
    elif 'brighter' in text_lower:
        return f"To brighten {track}, I'd suggest opening the filter cutoff to 2.5 kHz and adding a touch of high-shelf EQ."
    elif 'louder' in text_lower or 'quieter' in text_lower:
        return f"I can help with the levels. What's your target relative volume for {track}?"
    elif 'bass' in text_lower:
        return f"For the bass in {song}, consider: tighter attack (10-20ms), controlled sustain, and a subtle low-pass around 800 Hz."
    elif 'help' in text_lower or 'what can' in text_lower:
        return "I can help you adjust sounds, suggest changes to the mix, and describe what parameters to tweak. Try asking things like 'make the bass darker' or 'brighten the lead'."
    else:
        return f"I hear you! For {track}, what specific quality would you like to change? (e.g., darker, brighter, more punch)"


def create_test_response():
    """Create a test response file."""
    write_response(
        "Test response from AI protocol script. If you see this in the Godot panel, the roundtrip works!",
        changes=[
            {"file": "test.json", "description": "Test change entry"}
        ]
    )


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(0)

    cmd = sys.argv[1]
    if cmd == '--status':
        show_status()
    elif cmd == '--test':
        create_test_response()
    elif cmd == '--watch':
        watch_and_respond()
    else:
        print(f"Unknown command: {cmd}")
        print(__doc__)
