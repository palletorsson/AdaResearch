---
name: pickup
description: Resume work from past sessions — including ones started under the other Claude subscription. Reads session titles, finds the relevant ones, recovers the reasoning behind past decisions, and reports where the work stands. Triggers - "pickup", "pick up the work", "what was I doing", "continue from last session", "catch me up", "what happened in the other account".
---

# Pickup — resume work that a previous session started

## When to Use

- Switching accounts because one subscription ran out of usage, and this session needs the
  history the other one built up
- "What was I doing on the museum work?" / "catch me up" / "continue from last session"
- Any time work seems to have prior context that is not in this conversation

## Arguments

`/pickup <topic or session title>` — the usual form. Anything after the command is the topic:
`/pickup Artifact DNA auto-research optimization`, `/pickup the museum corridor`, `/pickup
spatial pipeline`. Treat it as a search phrase, not an exact string; titles get shortened and
forked sessions carry a `(fork)` suffix.

`/pickup` with no argument — report the last handful of sessions by title and ask which one.

If the argument names a session almost exactly, go straight to step 3 for that session and
skip the survey. If it matches several (forks, or a topic worked across sessions), read the
**most recent** one first, then the others only if the picture is incomplete.

## The thing to understand first

Palle works from two Claude accounts. **Transcripts are shared; the sidebars are not.**
Every session ever run writes to `~/.claude/projects/<encoded-cwd>/<session_id>.jsonl`, which
carries no account marker at all. Each account's app sidebar, though, lists only the
conversations that account started. Measured 2026-08-13 on the Ada project: 101 conversations
on disk, 6 listed in one sidebar, 12 in the other, **83 in neither**.

So: never conclude the work is missing because it is not listed. Ask the archive.

## How It Works

The `context-manager` MCP server is registered at user scope and reads the shared store, so
it works under either account and needs no web server running.

### 1. See what exists

```
list_sessions(project="C--Users-palle-Documents-GitHub-AdaResearch-46", sort="newest", limit=30)
```

**Read the `title` field, not `first_message`.** Most sessions open with identical
boilerplate — five different July conversations all begin "There are a lot of systems or
parts under current development…". The titles are what distinguish them.

Worktree sessions live in sibling project dirs. If a topic seems absent, also try
`list_projects()` and check `…AdaResearch-46--claude-worktrees-*`.

### 2. Narrow to the topic

```
search_sessions(project=…, query="<topic>")
```

Matches titles and message text. Prefer two or three strong candidates over ten weak ones.

Search on the distinctive word, not the whole title — `"museum"` beats `"the endless museum
corridor"`, `"spatial pipeline"` beats `"Spatial iteration pipeline consolidation work"`.
Titles are remembered approximately.

### 3. Read what happened

```
read_session_turns(session_id, per_page=25)
```

For a long session, read the summary first: `GET /api/sessions/{id}/summary` via the API, or
just read the last few turns — the outcome is usually at the end.

### 4. Recover why, not just what

```
read_session_reasoning(session_id)
```

This is the part that used to be thrown away. It holds the alternatives that were weighed,
the constraints discovered, and the things deliberately *not* done. A resumed session that
skips this will cheerfully redo work that a past session already rejected for a good reason.

### 5. Report before acting

Tell Palle, in a few lines:

- which sessions you read, **by title**, with dates
- where the work actually stands — done, in progress, blocked
- what the past session decided *against*, and why (this comes from step 4)
- the next concrete step, and what it depends on

Then stop and let him steer. Do not start editing on the strength of an archive read.

## Also worth checking

- `~/.claude/projects/<encoded>/memory/MEMORY.md` — the durable index; loads automatically
  and is account-independent
- `git log --oneline -15` — what actually landed, as opposed to what was discussed
- `ada_run/desktop_feedback.md` — VR session notes, if the work is map or artifact related

## Done When

Palle knows where the work stands and what the next step is, sourced from named sessions
rather than guesswork — and no code has been changed yet.
