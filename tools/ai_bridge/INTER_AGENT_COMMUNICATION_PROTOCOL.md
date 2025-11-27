# INTER-AGENT COMMUNICATION PROTOCOL (IACP) v1.0
# "The Collided IQ Protocol"

## 1. Objective
To facilitate **Generative Play** between multiple autonomous AI agents working on the Ada Research codebase simultaneously. This protocol defines how agents should announce intentions, lock resources, and share discoveries.

## 2. Connection
*   **Server:** `tools/ai_bridge/server.py`
*   **Port:** 65432 (TCP)
*   **Format:** JSON over Socket

## 3. Message Types

### A. Handshake
When joining the session:
```json
{
    "type": "AGENT_HELLO",
    "name": "Claude-Alpha",
    "role": "Noise Sequence Architect"
}
```

### B. State Updates (The "Truth")
When modifying the world (e.g., editing `map_sequences.json`):
```json
{
    "type": "UPDATE_STATE",
    "data": {
        "current_sequence": "Noise",
        "locked_files": ["commons/maps/map_sequences.json"]
    }
}
```

### C. Discovery / Handoff
When finding an artifact that belongs to another agent's domain:
```json
{
    "type": "CHAT",
    "content": "ALERT: I found 'cave_system.tscn' in the Randomness folder. It appears to be orphaned. Assigning to Procedural Generation agent."
}
```

## 4. The Rules of Engagement

1.  **The Hub Rule:** Do not modify `Lab/map_data_init.json` without consensus. This is the shared spawn point.
2.  **The Overwrite Rule:** If you see `locked_files` in the state, do not touch those files until the lock is released.
3.  **The Vector Sum Rule:** If Agent A proposes a "Technical" implementation and Agent B proposes a "Critical" critique, the final result *must* include both (e.g., via `Point_Context` paired maps).

## 5. How to "Play" via Proxy
Since AI agents cannot natively run sockets, the **User** acts as the biological router:
1.  User runs `server.py`.
2.  User copies "CHAT" JSON outputs from Agent A.
3.  User pastes them into Agent B's context.
4.  Agent B responds with JSON.
5.  User pastes JSON back to Agent A.

*This manual routing IS the "Human-in-the-loop" verification step.*

