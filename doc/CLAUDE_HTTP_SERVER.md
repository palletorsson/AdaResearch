# Claude HTTP Server

Tiny LAN HTTP wrapper around `claude -p` for helper machines.

API:

- `GET /status`
- `POST /ask`

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
  "cwd": "C:/Users/palle/Documents/GitHub/AdaResearch_46",
  "add_dirs": [
    "C:/Users/palle/Documents/GitHub/AdaResearch_46"
  ]
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

## Start the server

Windows:

```powershell
.\tools\run_claude_http_server.ps1 -Port 8766 -Token "your-long-random-token"
```

Mac:

```bash
chmod +x tools/run_claude_http_server.sh
./tools/run_claude_http_server.sh --port 8766 --token "your-long-random-token"
```

Direct Python:

```bash
python tools/claude_http_server.py --host 0.0.0.0 --port 8766 --token "your-long-random-token"
```

If `--token` is omitted, the server generates one for that process and prints it on startup.

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
  add_dirs = @("C:\Users\palle\Documents\GitHub\AdaResearch_46")
} | ConvertTo-Json -Depth 8

Invoke-RestMethod -Uri http://192.168.0.112:8766/ask `
  -Method Post `
  -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" } `
  -Body $body
```

## curl example

```bash
curl -X POST http://192.168.0.112:8766/ask \
  -H "Authorization: Bearer your-long-random-token" \
  -H "Content-Type: application/json" \
  -d '{"question":"List the spine sequence names"}'
```

## Notes

- The server runs `claude -p` in the repo root, so Claude can inspect and edit the local clone on that machine.
- The helper machine does not inherit this chat session automatically. If you want relevant answers, include `context` in the request.
- `context` can be a string, list, or object. The server serializes it into the prompt before the question.
- `cwd` lets you choose the working directory for the remote Claude run, as long as it stays inside an allowed directory.
- `add_dirs` lets you grant the remote Claude access to additional repo roots for that request.
- Default permission mode is `bypassPermissions` so requests do not block on interactive approval.
- Keep the token private. Anyone with the token can ask that machine's Claude session to inspect or modify the repo.
- Prefer one repo clone per machine. Do not point multiple machines at the same writable working tree.
