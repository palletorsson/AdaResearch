# Claude Bridge — Godot ↔ Claude Code HTTP Bridge

Lightweight HTTP server enabling real-time communication between a running Godot session and Claude Code.

## Files

| File | Role |
|------|------|
| `server.py` | HTTP server on `localhost:9876` — receives Godot messages, serves them to Claude |
| `ClaudeBridge.gd` | Godot-side client that POSTs messages to the bridge server |

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/message` | Godot sends a message (`{"text": "..."}`) |
| GET | `/messages` | Claude reads all unread messages |
| GET | `/messages/latest` | Claude reads the latest message |
| POST | `/clear` | Clear the inbox |
| GET | `/status` | Health check |

## Usage

```bash
python tools/claude_bridge/server.py   # Start bridge server
```
