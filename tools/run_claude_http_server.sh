#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
else
  echo "Neither python3 nor python was found on PATH." >&2
  exit 1
fi

HOST="0.0.0.0"
PORT="8766"
MODEL="sonnet"
TOKEN=""
TIMEOUT_SECONDS="900"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --token) TOKEN="$2"; shift 2 ;;
    --timeout-s) TIMEOUT_SECONDS="$2"; shift 2 ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

ARGS=(
  "${SCRIPT_DIR}/claude_http_server.py"
  --host "$HOST"
  --port "$PORT"
  --repo-root "$REPO_ROOT"
  --model "$MODEL"
  --timeout-s "$TIMEOUT_SECONDS"
)

if [[ -n "$TOKEN" ]]; then
  ARGS+=(--token "$TOKEN")
fi

cd "$REPO_ROOT"
"$PYTHON_BIN" "${ARGS[@]}"
