# Claude-VR Bridge

Real-time communication system between Claude Code (PC) and the user in VR (Quest standalone via USB adb).

## What It Does

Claude sends text messages that appear on the user's left hand in VR. The user responds by pressing a controller button or speaking. Claude can take screenshots from the Quest to see what the user sees, evaluate the scene, and respond with guidance.

This creates a live feedback loop: Claude observes, instructs, the user acts, Claude evaluates.

## Architecture

```
PC (Claude Code)                          Quest (Godot VR)
────────────────                          ────────────────
1. Write outbox.json
2. adb push outbox.json  ─────────────→   ClaudeBridge.gd polls every 1s
                                          Shows message on LEFT HAND panel
                                          User reads, acts in VR...
                                          Presses X (confirm) or B (voice)
3. adb pull inbox.json   ←─────────────   Writes inbox.json
4. adb screencap         ←─────────────   Screenshot of VR view
5. Claude evaluates screenshot
6. Next message → back to 1
```

## Files

| File | Purpose |
|------|---------|
| `commons/tools/ClaudeBridge.gd` | Godot autoload — left-hand console, message display, voice recording |
| `commons/tools/claude_bridge_poll.py` | PC-side helper — send, poll, screenshot, voice commands |
| `commons/tools/transcribe_voice.py` | OpenAI Whisper transcription for voice messages |
| `commons/tools/bridge_screenshots/` | Timestamped VR screenshots |

## File Exchange

All files live at `/sdcard/Android/data/com.example.adaresearchzeroone/files/claude_bridge/` on Quest.

**outbox.json** (Claude → VR):
```json
{"id": 3, "text": "Try pressing the blue palette button."}
```

**inbox.json** (VR → Claude):
```json
{"id": 3, "text": "done", "timestamp": "2026-03-05T10:00:05"}
```

**voice_ready.json** (VR → Claude, when voice recorded):
```json
{"id": 3, "status": "ready", "bytes": 548908, "duration": 3.09}
```

## PC-Side Usage

The `claude_bridge_poll.py` script handles all PC-side operations. All commands return JSON.

### Primary: `interact` (one command per cycle)

```bash
# Send message + wait for user response (button or voice)
python claude_bridge_poll.py interact "Walk to the pattern maker station"

# Send message + wait + take screenshot after response
python claude_bridge_poll.py interact "What do you see?" --screenshot

# Fire-and-forget (no wait for response)
python claude_bridge_poll.py interact "Looking good!" --no-wait

# Just take a screenshot, no message
python claude_bridge_poll.py look
```

Returns structured JSON:
```json
{"status": "ok", "message_id": 12, "sent": "Walk to the station",
 "response_type": "voice", "response": "I see the pattern maker",
 "screenshot": "C:/.../bridge_screenshots/vr_20260305_100000.png"}
```

### Low-level commands

```bash
python claude_bridge_poll.py send "message"        # send only
python claude_bridge_poll.py poll --timeout 120     # poll only (auto uses last ID)
python claude_bridge_poll.py screenshot             # screenshot only
python claude_bridge_poll.py voice                  # pull + transcribe voice
```

## VR-Side Behavior

### Left Hand Console
- Dark background panel attached to left hand (like WristStatsDisplay on right hand)
- Shows last 8 messages with timestamps (e.g. `[10:32] Walk to the station`)
- Also displays map name and XP stats at the top
- Position: `(-0.02, 0.08, 0.05)` relative to LeftHand

### User Input
- **X button (left controller)**: Confirm/acknowledge — writes `inbox.json` with `"done"`
- **B button (right controller)**: Push-to-talk voice recording
  - Hold B to record, release to stop
  - Console shows "Recording... Xs" with live elapsed time (orange text)
  - On release: shows "Recorded X.Xs" briefly
  - Saves WAV to bridge directory + writes `voice_ready.json` flag
  - PC pulls WAV via adb, transcribes with Whisper API

### Acknowledgment Messages
When Claude acts, the user sees confirmation on their hand:
- User presses X → "Claude live!"
- Voice message received → "Receiving voice message..."
- Before screenshot → "Taking screenshot in 2 sec..."
- After screenshot → "Screenshot saved!"

## Voice Pipeline

```
Quest (B button held)
  → AudioEffectRecord captures mic input
  → Saves voice.wav to bridge directory
  → Writes voice_ready.json flag

PC (claude_bridge_poll.py poll)
  → adb pull voice_ready.json (detects ready flag)
  → adb pull voice.wav
  → transcribe_voice.py → OpenAI Whisper API
  → Returns transcript text
```

The Whisper API key is read automatically from the oversight_light project's SQLite database.

## Desktop Fallback

When not running on Android, ClaudeBridge uses `user://claude_bridge/` paths instead of `/sdcard/`. This allows testing the message display and input flow in the Godot editor without a Quest connected.

## Known Limitations

- Quest screencap returns a black frame when the headset proximity sensor isn't triggered (headset off head)
- Voice recording requires the Quest microphone permission
- adb connection requires USB cable (no wireless adb tested yet)
- Stereo screenshots are captured (left+right eye side by side) — Claude reads both but the content is the same
