#!/usr/bin/env python
"""
claude_cli_rewriter.py - rewrite map text files via local Claude Code CLI.

This is the subscription/quota-distributed sibling to direct_api_rewriter.py.
It keeps the same queue selection, text_metrics scoring, grounding guard,
backup/restore semantics, and per-file retry loop, but calls the local
`claude` binary instead of the Anthropic SDK.

Typical use on multiple machines:

    # inspect the failing queue without spending quota
    python tools/claude_cli_rewriter.py --file critical.md --dry-run

    # split by contiguous index range (0-based, inclusive end)
    python tools/claude_cli_rewriter.py --file critical.md --start 0 --end 13
    python tools/claude_cli_rewriter.py --file critical.md --start 14 --end 26

    # or stripe the queue automatically across N workers
    python tools/claude_cli_rewriter.py --file critical.md --shard-count 3 --shard-index 0
    python tools/claude_cli_rewriter.py --file critical.md --shard-count 3 --shard-index 1
    python tools/claude_cli_rewriter.py --file critical.md --shard-count 3 --shard-index 2
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
TOOLS = REPO / "tools"
LOG_FILE = TOOLS / "claude_cli_rewriter_log.json"

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

sys.path.insert(0, str(TOOLS))
import direct_api_rewriter as base  # noqa: E402


def claude_binary() -> str:
    path = shutil.which("claude")
    if not path:
        print("ERROR: `claude` not found on PATH.", file=sys.stderr)
        sys.exit(1)
    return path


def slice_maps(
    maps: list[str],
    start: int,
    end: int | None,
    shard_index: int | None,
    shard_count: int | None,
) -> list[str]:
    if shard_index is not None or shard_count is not None:
        if shard_index is None or shard_count is None:
            print("ERROR: --shard-index and --shard-count must be provided together.",
                  file=sys.stderr)
            sys.exit(2)
        if shard_count <= 0:
            print("ERROR: --shard-count must be > 0.", file=sys.stderr)
            sys.exit(2)
        if shard_index < 0 or shard_index >= shard_count:
            print("ERROR: --shard-index must satisfy 0 <= index < shard-count.",
                  file=sys.stderr)
            sys.exit(2)
        return [m for i, m in enumerate(maps) if i % shard_count == shard_index]

    if start < 0:
        print("ERROR: --start must be >= 0.", file=sys.stderr)
        sys.exit(2)
    if end is not None and end < start:
        print("ERROR: --end must be >= --start.", file=sys.stderr)
        sys.exit(2)

    lo = start
    hi = None if end is None else end + 1
    return maps[lo:hi]


def print_map_list(maps: list[str], file_role: str) -> None:
    for i, map_name in enumerate(maps):
        print(f"{i}\t{map_name}\t{file_role}")


def build_command(prompt: str, model: str, max_budget_usd: float) -> list[str]:
    cmd = [
        claude_binary(),
        "-p",
        "--output-format", "text",
        "--no-session-persistence",
        "--disable-slash-commands",
        "--tools", "",
        "--system-prompt", base.SYSTEM_PROMPT,
    ]
    if model:
        cmd.extend(["--model", model])
    if max_budget_usd > 0:
        cmd.extend(["--max-budget-usd", f"{max_budget_usd:.2f}"])
    cmd.append(prompt)
    return cmd


def call_claude(
    map_name: str,
    file_role: str,
    model: str,
    max_budget_usd: float,
    timeout_s: int,
) -> dict[str, Any]:
    try:
        prompt = base.build_task_prompt(map_name, file_role)
    except ValueError as e:
        return {"error": str(e)}

    cmd = build_command(prompt, model, max_budget_usd)
    t0 = time.time()
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(REPO),
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout_s,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return {"error": f"timeout: exceeded {timeout_s}s"}
    except Exception as e:
        return {"error": f"spawn_error: {type(e).__name__}: {str(e)[:200]}"}

    elapsed = round(time.time() - t0, 1)
    stdout = proc.stdout.replace("\r\n", "\n")
    stderr = proc.stderr.replace("\r\n", "\n")
    if proc.returncode != 0:
        snippet = stderr.strip() or stdout.strip()
        return {
            "error": f"cli_exit_{proc.returncode}: {snippet[:300]}",
            "elapsed_s": elapsed,
        }
    if not stdout.strip():
        snippet = stderr.strip()
        return {
            "error": f"empty_output: {snippet[:300]}",
            "elapsed_s": elapsed,
        }
    return {
        "text": stdout,
        "elapsed_s": elapsed,
        "stdout_chars": len(stdout),
    }


def fix_one(
    map_name: str,
    file_role: str,
    model: str,
    dry_run: bool = False,
    min_composite: float = 0.85,
    max_budget_usd: float = 0.0,
    timeout_s: int = 900,
    attempts: int = 2,
) -> dict[str, Any]:
    text_path = base.MAPS / map_name / file_role
    initial = base.composite_score(map_name, file_role, text_path)

    result: dict[str, Any] = {
        "map": map_name,
        "file": file_role,
        "model": model,
        "initial": initial,
        "attempts": [],
        "action": "skip",
    }

    if initial.get("metrics_pass") and initial.get("grounding_ratio", 0.0) >= 0.9:
        result["action"] = "skip_ok"
        return result

    has_real_code = initial.get("code_blocks", 0) > 0
    if (has_real_code
            and initial.get("grounding_ratio", 0.0) >= 0.9
            and initial.get("composite", 0.0) >= 0.75):
        result["action"] = "skip_grounded"
        return result

    if dry_run:
        result["action"] = "would_fix"
        return result

    original_text = (text_path.read_text(encoding="utf-8", errors="replace")
                     if text_path.exists() else "")
    best_text = original_text
    best_score = initial.get("composite", 0.0) if initial["exists"] else 0.0
    best_label = "initial"

    for attempt in range(1, attempts + 1):
        print(f"  [attempt {attempt}] {model}", end=" ... ", flush=True)
        response = call_claude(
            map_name,
            file_role,
            model,
            max_budget_usd=max_budget_usd,
            timeout_s=timeout_s,
        )
        if "error" in response:
            print(f"error: {response['error'][:120]}")
            result["attempts"].append({
                "label": f"cli_{attempt}",
                "status": "error",
                "error": response["error"],
                "elapsed_s": response.get("elapsed_s", 0.0),
            })
            continue

        text_path.write_text(response["text"], encoding="utf-8")
        score = base.composite_score(map_name, file_role, text_path)
        print(f"composite={score['composite']:.2f} "
              f"(wc={score.get('word_count', '?')} "
              f"g={score.get('grounding_ratio', 0):.2f}) "
              f"{response['elapsed_s']}s")

        result["attempts"].append({
            "label": f"cli_{attempt}",
            "status": "ok",
            "composite": score["composite"],
            "elapsed_s": response["elapsed_s"],
            "stdout_chars": response["stdout_chars"],
            "metrics_pass": score["metrics_pass"],
            "grounding_ratio": score["grounding_ratio"],
        })
        if score["composite"] > best_score:
            best_score = score["composite"]
            best_label = f"cli_{attempt}"
            best_text = text_path.read_text(encoding="utf-8", errors="replace")
        if score["composite"] >= min_composite:
            break

    if best_label != "initial":
        text_path.write_text(best_text, encoding="utf-8")
        result["action"] = ("fixed"
                            if best_score > initial.get("composite", 0.0)
                            else "no_improvement")
    else:
        if original_text:
            text_path.write_text(original_text, encoding="utf-8")
        result["action"] = "no_improvement"
    result["best"] = {"label": best_label, "composite": best_score}
    return result


def save_log(results: list[dict[str, Any]], meta: dict[str, Any]) -> None:
    data: dict[str, Any] = {"runs": []}
    if LOG_FILE.exists():
        try:
            data = json.loads(LOG_FILE.read_text(encoding="utf-8"))
        except Exception:
            pass
    data.setdefault("runs", []).append({"meta": meta, "results": results})
    LOG_FILE.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n",
                        encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", help="Single map name")
    ap.add_argument("--file", default="critical.md",
                    help="File role to process (default critical.md)")
    ap.add_argument("--dry-run", action="store_true",
                    help="Plan without calling Claude")
    ap.add_argument("--limit", type=int, default=0,
                    help="Cap number of maps processed after slicing (0 = all)")
    ap.add_argument("--model", default="sonnet",
                    help="Claude Code model alias/name (default sonnet)")
    ap.add_argument("--min-composite", type=float, default=0.85,
                    help="Threshold to stop iterating (default 0.85)")
    ap.add_argument("--sleep-between", type=float, default=2.0,
                    help="Seconds to sleep between maps")
    ap.add_argument("--start", type=int, default=0,
                    help="0-based start index into the failing queue")
    ap.add_argument("--end", type=int,
                    help="0-based inclusive end index into the failing queue")
    ap.add_argument("--shard-index", type=int,
                    help="Worker index for striped sharding (0-based)")
    ap.add_argument("--shard-count", type=int,
                    help="Total worker count for striped sharding")
    ap.add_argument("--timeout-s", type=int, default=900,
                    help="Per-Claude invocation timeout in seconds")
    ap.add_argument("--attempts", type=int, default=2,
                    help="Max regenerate attempts per map")
    ap.add_argument("--max-budget-usd", type=float, default=0.0,
                    help="Pass through Claude Code print-mode budget cap")
    ap.add_argument("--list-maps", action="store_true",
                    help="Print the selected map list and exit")
    args = ap.parse_args()

    if args.map:
        maps = [args.map]
    else:
        maps = base.load_queue(args.file)
        maps = slice_maps(
            maps,
            start=args.start,
            end=args.end,
            shard_index=args.shard_index,
            shard_count=args.shard_count,
        )

    if args.limit:
        maps = maps[:args.limit]

    if not maps:
        print(f"No {args.file} files to process.", file=sys.stderr)
        return 0

    if args.list_maps:
        print_map_list(maps, args.file)
        return 0

    if not args.dry_run:
        claude_binary()

    print(f"Processing {len(maps)} x {args.file} with {args.model}")
    if args.map:
        print("single-map mode")
    elif args.shard_count is not None:
        print(f"striped shard {args.shard_index}/{args.shard_count}")
    else:
        end_label = args.end if args.end is not None else "end"
        print(f"queue slice: [{args.start}:{end_label}]")
    print("DRY RUN - no Claude calls" if args.dry_run else "LIVE - billed to local Claude Code session")
    print()

    t0 = time.time()
    results: list[dict[str, Any]] = []
    for i, m in enumerate(maps, 1):
        print(f"[{i}/{len(maps)}] {m} / {args.file}")
        r = fix_one(
            m,
            args.file,
            args.model,
            dry_run=args.dry_run,
            min_composite=args.min_composite,
            max_budget_usd=args.max_budget_usd,
            timeout_s=args.timeout_s,
            attempts=args.attempts,
        )
        results.append(r)
        if i < len(maps) and not args.dry_run:
            time.sleep(args.sleep_between)

    elapsed = time.time() - t0
    counts: dict[str, int] = {}
    for r in results:
        counts[r["action"]] = counts.get(r["action"], 0) + 1

    print(f"\n{'-' * 60}")
    if args.dry_run:
        print(f"dry-run: {counts.get('would_fix', 0)} would fix, "
              f"{counts.get('skip_ok', 0)} already pass, "
              f"{counts.get('skip_grounded', 0)} grounded-skip "
              f"({elapsed:.1f}s)")
    else:
        print(f"done: {counts.get('fixed', 0)} fixed, "
              f"{counts.get('skip_ok', 0)} already pass, "
              f"{counts.get('no_improvement', 0)} stuck, "
              f"{counts.get('skip_grounded', 0)} grounded-skip "
              f"({elapsed:.1f}s)")
        save_log(results, {
            "timestamp": int(time.time()),
            "machine": os.environ.get("COMPUTERNAME", ""),
            "file_role": args.file,
            "model": args.model,
            "maps_processed": len(results),
            "elapsed_s": round(elapsed, 1),
        })
        print(f"log: {LOG_FILE.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
