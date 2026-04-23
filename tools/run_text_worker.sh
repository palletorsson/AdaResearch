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

FILE="critical.md"
MODEL="sonnet"
ATTEMPTS=2
TIMEOUT_SECONDS=900
SLEEP_BETWEEN=2.0
DRY_RUN=0
LIST_MAPS=0
SHARD_INDEX=""
SHARD_COUNT=""
START=""
END=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file) FILE="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --attempts) ATTEMPTS="$2"; shift 2 ;;
    --timeout-s) TIMEOUT_SECONDS="$2"; shift 2 ;;
    --sleep-between) SLEEP_BETWEEN="$2"; shift 2 ;;
    --shard-index) SHARD_INDEX="$2"; shift 2 ;;
    --shard-count) SHARD_COUNT="$2"; shift 2 ;;
    --start) START="$2"; shift 2 ;;
    --end) END="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --list-maps) LIST_MAPS=1; shift ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

ARGS=(
  "${SCRIPT_DIR}/claude_cli_rewriter.py"
  --file "$FILE"
  --model "$MODEL"
  --attempts "$ATTEMPTS"
  --timeout-s "$TIMEOUT_SECONDS"
  --sleep-between "$SLEEP_BETWEEN"
)

if [[ $DRY_RUN -eq 1 ]]; then
  ARGS+=(--dry-run)
fi

if [[ $LIST_MAPS -eq 1 ]]; then
  ARGS+=(--list-maps)
fi

if [[ -n "$SHARD_INDEX" || -n "$SHARD_COUNT" ]]; then
  if [[ -z "$SHARD_INDEX" || -z "$SHARD_COUNT" ]]; then
    echo "Both --shard-index and --shard-count are required together." >&2
    exit 2
  fi
  ARGS+=(--shard-index "$SHARD_INDEX" --shard-count "$SHARD_COUNT")
else
  if [[ -n "$START" ]]; then
    ARGS+=(--start "$START")
  fi
  if [[ -n "$END" ]]; then
    ARGS+=(--end "$END")
  fi
fi

cd "$REPO_ROOT"
"$PYTHON_BIN" "${ARGS[@]}"
