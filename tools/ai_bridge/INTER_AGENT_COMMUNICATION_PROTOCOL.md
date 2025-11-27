# INTER-AGENT COMMUNICATION PROTOCOL (IACP) v2.1
# "The File-Based Bridge"

**Version History:**
- v2.0: File-based bridge implementation
- v2.1: Added file locking enforcement, approval mechanisms, chat log management, conflict resolution

## 1. Objective
To facilitate **Generative Play** between multiple autonomous AI agents working on the Ada Research codebase simultaneously. This protocol defines how agents should announce intentions, lock resources, share discoveries, and coordinate decisions using a shared state file.

## 2. The Shared State
*   **File:** `tools/ai_bridge/bridge_state.json`
*   **Format:** JSON
*   **Structure:**
    ```json
    {
        "metadata": { "version": "1.0", "last_updated": "ISO-8601" },
        "world_state": {
            "current_sequence_focus": "SequenceName",
            "locked_files": [],
            "active_agents": [],
            "pending_approvals": []
        },
        "task_board": [],
        "chat_log": [],
        "chat_archive": []
    }
    ```

## 3. How to Communicate

### A. Joining (Handshake)
1.  Read `bridge_state.json`.
2.  Add your entry to the `active_agents` array:
    ```json
    {
        "name": "Agent-YourName",
        "role": "Your Role",
        "status": "Active",
        "last_seen": "ISO-8601 Timestamp",
        "capabilities": ["metadata_repair", "tutorial_writing", "etc"]
    }
    ```
3.  Post a greeting message to `chat_log`.
4.  Write the file back.

### B. Chat & Announcements
1.  Read `bridge_state.json`.
2.  Append a new object to the `chat_log` array:
    ```json
    {
        "timestamp": "ISO-8601 Timestamp",
        "sender": "Agent-Name",
        "message": "Your message here",
        "type": "announcement|question|response|approval_request|approval_response"
    }
    ```
3.  Write the file back.

**Message Types:**
- `announcement`: General status updates
- `question`: Asking other agents for input
- `response`: Replying to a question
- `approval_request`: Requesting permission to proceed
- `approval_response`: Approving or rejecting a request

### C. File Locking (MANDATORY for edits)

**When to Lock:**
- Editing map_data.json files
- Editing map_sequences.json
- Editing tutorial_text.json
- Any file that another agent might access

**Lock Protocol:**
1.  **Before editing:**
    ```json
    "locked_files": [
        {
            "file": "commons/maps/Noise_Columns/map_data.json",
            "locked_by": "Agent-Beta",
            "locked_at": "ISO-8601",
            "reason": "Metadata repair"
        }
    ]
    ```
2.  Perform your edits.
3.  **Immediately after editing:**
    - Remove your lock from `locked_files` array
    - Post completion message to `chat_log`

**Lock Conflicts:**
- If file is already locked, post a message asking when it will be free
- DO NOT edit locked files
- Locks older than 30 minutes can be considered stale (post inquiry first)

### D. Batch Operations

For batch edits (multiple files), you can:
1. **Option A: Individual locks** - Lock each file as you edit it
2. **Option B: Sequence lock** - Lock entire sequence:
    ```json
    {
        "file": "sequence:Noise",
        "locked_by": "Agent-Beta",
        "locked_at": "ISO-8601",
        "reason": "Batch metadata standardization",
        "estimated_duration": "15 minutes"
    }
    ```

**Batch Reporting:**
- Post start message with list of files
- Post progress updates every 3-5 files
- Post completion summary with findings

## 4. Approval & Voting Mechanisms

### A. Requesting Approval

When you need permission to proceed with significant changes:

1. Add to `pending_approvals`:
    ```json
    {
        "id": "approval_001",
        "requester": "Agent-Beta",
        "action": "Reorder Noise sequence in map_sequences.json",
        "rationale": "Align with pedagogical arc Foundation → Types → Critical",
        "impact": "Changes map order, affects user learning progression",
        "proposed_changes": "Move Noise_One from position 2 to position 5",
        "requested_at": "ISO-8601",
        "votes": {},
        "status": "pending"
    }
    ```

2. Post `approval_request` message to chat_log referencing the approval ID

### B. Responding to Approvals

1. Read `pending_approvals` array
2. Add your vote:
    ```json
    "votes": {
        "Agent-Alpha": {"vote": "approve", "comment": "Sound reasoning"},
        "Agent-Beta": {"vote": "approve", "comment": "Proposing agent"}
    }
    ```
3. Update status based on votes:
    - All agents approve → `"status": "approved"`
    - Any agent rejects → `"status": "needs_discussion"`
    - Timeout (24h) → `"status": "expired"`

### C. Proceeding After Approval

- **Approved:** Lock files, make changes, post completion message
- **Needs Discussion:** Post clarifying message, revise proposal
- **Expired:** Resubmit or abandon

## 5. Chat Log Management

### A. Archiving

When `chat_log` exceeds 20 messages:
1. Move oldest 10 messages to `chat_archive`
2. Preserve archive structure:
    ```json
    "chat_archive": [
        {
            "session": "2025-11-27",
            "messages": [ /* archived messages */ ]
        }
    ]
    ```

### B. Searching Archives

Use chat_log for recent activity, chat_archive for history.

## 6. The Rules of Engagement

1.  **Read Before Write:** Always read the latest state before making decisions.

2.  **The Vector Sum Rule:** If Agent A proposes a "Technical" implementation and Agent B proposes a "Critical" critique, the final result *must* include both.

3.  **Task Board:** Use the `task_board` to claim work:
    - Change status from `"open"` to `"in_progress"` when claiming
    - Update `"progress"` field regularly
    - Change to `"completed"` when done

4.  **Respect Locks:** Never edit locked files. If urgent, negotiate in chat_log.

5.  **Flag Issues:** Use clear markers (⚠️, 🚨, CRITICAL:) for important findings.

6.  **Batch Operations:** For 5+ file edits, use sequence locks and progress updates.

7.  **Approval Required For:**
    - Changing map_sequences.json order
    - Deleting maps or tutorials
    - Architectural changes affecting multiple sequences
    - Adding new artifacts to grid_artifacts.json

8.  **Autonomous Work Allowed:**
    - Metadata repairs (name, description, learning_objectives)
    - Adding missing clipboard links
    - Fixing typos in tutorials
    - Creating new tutorial content (post announcement first)

## 7. Conflict Resolution

**If agents disagree:**

1. **Level 1: Discussion**
   - Post concerns to chat_log
   - Allow 2-3 message exchange
   - Seek compromise

2. **Level 2: Voting**
   - Create approval request with both options
   - Agents vote for preferred approach
   - Majority wins

3. **Level 3: User Escalation**
   - Post message: `"ESCALATION NEEDED: [brief description]"`
   - User makes final decision
   - Both agents implement user's choice

## 8. Agent Status Codes

**Agent Status Values:**
- `"Active"` - Currently working
- `"Monitoring"` - Watching chat_log, ready to respond
- `"Idle"` - Online but not engaged
- `"Offline"` - Session ended
- `"Waiting"` - Blocked on approval or lock

**Update your status** when it changes.

## 9. Session Management

### A. Starting a Session
1. Read bridge_state.json
2. Update your `last_seen` timestamp
3. Change status from "Offline" to "Active"
4. Post session start message

### B. Ending a Session
1. Complete or hand off all in-progress tasks
2. Release all file locks
3. Post session summary message
4. Change status to "Offline"
5. Update final `last_seen` timestamp

### C. Resuming a Session
1. Read chat_log to catch up
2. Update `last_seen` timestamp
3. Resume work on your tasks

## 10. Instructions for the User (The Router)

**Single-Agent Sessions:**
- Agent has direct file access, updates bridge_state.json directly

**Multi-Agent Sessions (different Claude instances):**
1. **Agent A (Primary):** Has direct file access
2. **Agent B (Secondary):** User copies bridge_state.json to Agent B's session
3. **Agent B Response:** Outputs JSON changes, user pastes into file OR asks Agent A to apply

**Multi-Agent Sessions (same codebase, parallel):**
- Each agent must respect locks strictly
- User monitors for deadlocks or conflicts

*The file is the single source of truth.*

## 11. Best Practices

✅ **DO:**
- Post before starting major work
- Lock files during edits
- Update progress regularly
- Flag unexpected findings
- Archive chat when long
- Respect other agents' locks
- Seek approval for big changes

❌ **DON'T:**
- Edit locked files
- Make breaking changes without approval
- Leave stale locks (>30 min)
- Skip progress updates in batch work
- Assume consensus without checking
- Delete other agents' work without discussion

## 12. Example Workflows

### Example 1: Metadata Repair (Autonomous)

```
1. Post: "Starting metadata repair on Noise_Voxel"
2. Lock: "commons/maps/Noise_Voxel/map_data.json"
3. Edit file
4. Unlock file
5. Post: "Noise_Voxel complete. Changed category to 'noise'"
```

### Example 2: Sequence Reordering (Requires Approval)

```
1. Post approval request with proposed new order
2. Wait for votes
3. If approved:
   - Lock: "commons/maps/map_sequences.json"
   - Edit file
   - Unlock file
   - Post: "Sequence reordered successfully"
4. If rejected:
   - Revise proposal based on feedback
   - Resubmit
```

### Example 3: Batch Processing

```
1. Post: "Batch processing 7 maps. ETA 15 min"
2. Lock: "sequence:Noise"
3. Process each map, flagging issues
4. Post progress: "3/7 complete"
5. Post progress: "7/7 complete"
6. Unlock sequence
7. Post summary with findings
```

---

## Changelog

**v2.1 (2025-11-27)**
- Added file locking enforcement guidelines
- Added approval/voting mechanism
- Added chat log archiving (20 message threshold)
- Added conflict resolution protocol
- Added agent status codes
- Added session management
- Added batch operation guidelines
- Added best practices and example workflows

**v2.0 (Initial)**
- File-based bridge implementation
- Basic chat_log and task_board
- File locking concept introduced
