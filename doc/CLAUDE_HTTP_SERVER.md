# Claude HTTP Server

Tiny LAN HTTP wrapper around `claude -p` for helper machines.

Default mode is `readonly`.

API:

- `GET /status`
- `POST /ask`
- `GET /context`
- `POST /context`
- `DELETE /context`

Auth:

- `Authorization: Bearer <token>`

Request body:

```json
{
  "question": "List the spine sequence names"
}
```

Context-rich request body:

```json
{
  "question": "Which file should I edit next and why?",
  "context": {
    "task": "Finish distributed critical.md rewriting across helper machines",
    "current_findings": [
      "blurb.md is already at 100% pass",
      "critical.md is the current target",
      "grounded files should be skipped"
    ],
    "relevant_files": [
      "tools/claude_cli_rewriter.py",
      "doc/TEXT_WORKER_SETUP.md"
    ],
    "notes": "Assume the helper machine has a synced clone of AdaResearch_46."
  },
  "cwd": "C:/Users/palle/Documents/GitHub/AdaResearch_46"
}
```

Response body:

```json
{
  "ok": true,
  "answer": "...",
  "elapsed_s": 2.4,
  "model": "sonnet"
}
```

Saved-context API:

```json
{
  "context": {
    "task": "Distribute text rewriting to helper machines",
    "current_goal": "Use remote Claude when local quota is exhausted",
    "notes": [
      "The helper machine has its own synced clone",
      "Grounded files should be skipped"
    ]
  },
  "source": "local-codex-session"
}
```

## Start the server

Recommended: set the token in an environment variable so it does not appear in process lists.

Windows:

```powershell
$env:CLAUDE_HTTP_TOKEN = "your-long-random-token"
.\tools\run_claude_http_server.ps1 -Port 8766 -Token "your-long-random-token"
```

Mac:

```bash
chmod +x tools/run_claude_http_server.sh
export CLAUDE_HTTP_TOKEN="your-long-random-token"
./tools/run_claude_http_server.sh --port 8766 --token "your-long-random-token"
```

Direct Python:

```bash
export CLAUDE_HTTP_TOKEN="your-long-random-token"
python tools/claude_http_server.py --host 0.0.0.0 --port 8766
```

If `--token` is omitted, the server generates one for that process and prints it on startup.

## Modes

`readonly` is the default and recommended mode.

- uses `--permission-mode plan`
- fixes the available tools to `Read, Glob, Grep, WebFetch, WebSearch`
- rejects caller-supplied `add_dirs`
- rejects caller-supplied `system_prompt`

Explicit full-access mode:

```bash
export CLAUDE_HTTP_TOKEN="your-long-random-token"
python tools/claude_http_server.py \
  --host 0.0.0.0 \
  --port 8766 \
  --mode full \
  --permission-mode bypassPermissions \
  --allow-request-add-dirs \
  --allow-request-system-prompt
```

## PowerShell client example

```powershell
$token = "ba22d61d11dc2260633c3c44440ae213eb6565db964481db95e72e7fc5dd25fd"
$body = @{ question = "List the spine sequence names" } | ConvertTo-Json

Invoke-RestMethod -Uri http://192.168.0.112:8766/ask `
  -Method Post `
  -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" } `
  -Body $body
```

## PowerShell example with context

```powershell
$token = "ba22d61d11dc2260633c3c44440ae213eb6565db964481db95e72e7fc5dd25fd"
$body = @{
  question = "Given this task state, what should the helper machine work on next?"
  context = @{
    task = "Distribute AdaResearch text editing across LAN helper machines"
    current_goal = "Use remote Claude Code when local quota is exhausted"
    relevant_files = @(
      "tools/claude_cli_rewriter.py",
      "doc/TEXT_WORKER_SETUP.md"
    )
    notes = @(
      "The helper machine has its own clone and its own Claude quota",
      "Do not assume access to this chat history unless included here"
    )
  }
  cwd = "C:\Users\palle\Documents\GitHub\AdaResearch_46"
} | ConvertTo-Json -Depth 8

Invoke-RestMethod -Uri http://192.168.0.112:8766/ask `
  -Method Post `
  -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" } `
  -Body $body
```

## Save session context once, then ask repeatedly

```powershell
$token = "ba22d61d11dc2260633c3c44440ae213eb6565db964481db95e72e7fc5dd25fd"

$contextBody = @{
  context = @{
    task = "Use helper machines for Claude Code overflow work"
    repo = "AdaResearch_46"
    current_goal = "Route bounded repo questions to remote /ask"
    important_files = @(
      "tools/claude_cli_rewriter.py",
      "doc/TEXT_WORKER_SETUP.md",
      "tools/claude_http_server.py"
    )
    constraints = @(
      "Do not assume hidden chat memory",
      "Prefer grounded answers from repo files",
      "Ask for clarification only if the prompt is ambiguous"
    )
  }
  source = "local-session-summary"
} | ConvertTo-Json -Depth 8

Invoke-RestMethod -Uri http://192.168.0.112:8766/context `
  -Method Post `
  -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" } `
  -Body $contextBody

$askBody = @{
  question = "What should this helper machine work on next?"
} | ConvertTo-Json

Invoke-RestMethod -Uri http://192.168.0.112:8766/ask `
  -Method Post `
  -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" } `
  -Body $askBody
```

## Read or clear saved context

```powershell
Invoke-RestMethod -Uri http://192.168.0.112:8766/context `
  -Method Get `
  -Headers @{ Authorization = "Bearer $token" }

Invoke-RestMethod -Uri http://192.168.0.112:8766/context `
  -Method Delete `
  -Headers @{ Authorization = "Bearer $token" }
```

## curl example

```bash
curl -X POST http://192.168.0.112:8766/ask \
  -H "Authorization: Bearer your-long-random-token" \
  -H "Content-Type: application/json" \
  -d '{"question":"List the spine sequence names"}'
```

## Notes

- The server runs `claude -p` in the repo root, so Claude can inspect the local clone on that machine.
- The helper machine does not inherit this chat session automatically.
- `POST /context` gives you a way to serialize a session summary once and have future `/ask` requests include it by default.
- `context` can be a string, list, or object. The server serializes it into the prompt before the question.
- `/ask` uses saved context by default. Pass `"use_saved_context": false` if you want a one-off stateless request.
- `cwd` lets you choose the working directory for the remote Claude run, as long as it stays inside an allowed directory.
- Request-level `add_dirs` and `system_prompt` are disabled by default. They are only available in explicit full-access mode.
- Read-only mode is the safe default. Use full mode only on a trusted LAN and only when you intentionally want remote editing/execution.
- Keep the token private. Anyone with the token can query that machine's Claude session.
- Prefer one repo clone per machine. Do not point multiple machines at the same writable working tree.
