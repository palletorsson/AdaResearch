---
name: ada-task-manager
description: Manages Ada Research tasks via the local project server — view tasks, report work, mark done, add memories. Run with 'plan' to see all tasks, 'done TASK_ID' to complete, 'report' to submit session work.
argument-hint: "[plan/done/report/add/memory]"
allowed-tools: Bash, Read, Write, Grep, Glob
---

# Ada Task Manager

You interact with the Ada Research project management server at `http://192.168.0.112:3001` to view tasks, report completed work, and manage project state.

## Server API

Base URL: `http://192.168.0.112:3001`
Project ID: `ada-research-46`

## Commands

Based on `$ARGUMENTS`:

### `plan` (default)
Fetch and display all tasks. Organize by priority and suggest what to work on next.

```bash
curl -s http://192.168.0.112:3001/api/projects/ada-research-46 | python -m json.tool
```

Show tasks grouped by status (To Do / In Progress / Done / Blocked). For To Do items, suggest a work order based on dependencies and impact.

### `done TASK_ID`
Mark a specific task as completed.

```bash
curl -s -X PUT http://192.168.0.112:3001/api/tasks/TASK_ID \
  -H "Content-Type: application/json" -d '{"status": "done"}'
```

### `report`
Submit a work report for the current session. Gather what was accomplished by reviewing recent file changes, then submit:

```bash
curl -s -X POST http://192.168.0.112:3001/api/projects/ada-research-46/report \
  -H "Content-Type: application/json" \
  -d '{
    "tasks_completed": ["TASK_ID1", "TASK_ID2"],
    "tasks_created": [{"title": "New task description", "priority": "medium"}],
    "memories": [{"type": "discovery", "content": "What was learned"}],
    "session": {"summary": "Brief summary of work done", "notes": "Detailed notes"}
  }'
```

Before submitting, show the user what will be reported and ask for confirmation.

### `add TITLE`
Create a new task:

```bash
curl -s -X POST http://192.168.0.112:3001/api/projects/ada-research-46/report \
  -H "Content-Type: application/json" \
  -d '{
    "tasks_created": [{"title": "TITLE", "priority": "medium"}]
  }'
```

### `memory TYPE: CONTENT`
Add a memory/note to the project. Types: `note`, `decision`, `discovery`, `context`.

```bash
curl -s -X POST http://192.168.0.112:3001/api/projects/ada-research-46/memory \
  -H "Content-Type: application/json" \
  -d '{"type": "TYPE", "content": "CONTENT"}'
```

### `start TASK_ID`
Mark a task as in-progress:

```bash
curl -s -X PUT http://192.168.0.112:3001/api/tasks/TASK_ID \
  -H "Content-Type: application/json" -d '{"status": "in_progress"}'
```

## Planning Mode

When called with `plan` or no arguments:

1. Fetch all project data from the server
2. Display tasks organized by status
3. Check memories for recent context
4. Suggest a prioritized work plan considering:
   - Tasks that unblock other tasks
   - Tasks related to the current work area
   - Quick wins vs. deep work
5. Ask the user what they want to tackle

## After Completing Work

When you've finished building/fixing something during a session, proactively suggest running `/ada-task-manager report` to log the work. Include:
- Which task IDs were completed
- Any new tasks discovered during the work
- Key decisions or discoveries as memories

## Important

- The server runs on the local network at `192.168.0.112:3001`
- Always use `curl -s` (silent) to avoid progress bars
- Parse JSON responses to present them clearly
- When marking tasks done, also briefly note what was accomplished
- If the server is unreachable, tell the user and suggest checking if it's running
