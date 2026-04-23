#!/usr/bin/env python
"""
text_fixer.py — auto-research loop for map text files.

The analog of pipe_fixer.py, but the substrate is prose + code instead of
pixels. For each (map, file_role) combination, compute objective scores
(word count, code ratio, caption length, paragraph length, forbidden words)
and grounding (code references against real GDScript). If the composite
score is below threshold, iterate through (rule_set × objective × provider)
variations by calling Writer Pro's /api/rule-flow/execute, score each
result, and keep the best.

The closed loop that the text generator currently lacks — text_metrics and
code_grounding_validator provide the feedback signal; this script uses it
to drive regeneration.

Usage::

    # dry-run: show which maps/files would be processed
    python tools/text_fixer.py --dry-run --file tutorial.md

    # fix one map, one file
    python tools/text_fixer.py --map Array_Patterns --file tutorial.md

    # fix all spine maps for a given file role
    python tools/text_fixer.py --file tutorial.md

    # limit to N maps for bounded testing
    python tools/text_fixer.py --file tutorial.md --limit 5

    # see what variations this would try
    python tools/text_fixer.py --variations

Requires Writer Pro running at http://localhost:3002 with ADA_RESEARCH_PATH
pointed at this repo.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

import urllib.request
import urllib.error

REPO = Path(__file__).resolve().parent.parent
TOOLS = REPO / "tools"
LOG_FILE = TOOLS / "text_fixer_log.json"
BASELINE_DIR = REPO / "doc"

WRITER_PRO = os.environ.get("WRITER_PRO_URL", "http://localhost:3002")

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

# Import the two scorers as libraries
sys.path.insert(0, str(TOOLS))
import text_metrics  # noqa: E402
import code_grounding_validator as cgv  # noqa: E402


# ── Variation search space ──────────────────────────────────────────────
# Ordered by expected payoff. First attempt is the role's default.

VARIATIONS_PER_ROLE: dict[str, list[dict[str, Any]]] = {
    "tutorial.md": [
        {"label": "default",          "ruleSetId": "code_first_tutorial",
         "pathId": "technical", "objectiveId": "code_first", "provider": "claude"},
        {"label": "stricter_code",    "ruleSetId": "code_first_tutorial",
         "pathId": "technical", "objectiveId": "code_first", "provider": "claude",
         "directionText": "Make the code density higher. Prose must only caption; nothing should explain what the code does in words."},
        {"label": "codex_provider",   "ruleSetId": "code_first_tutorial",
         "pathId": "technical", "objectiveId": "code_first", "provider": "codex"},
        {"label": "teach_emphasis",   "ruleSetId": "code_first_tutorial",
         "pathId": "technical", "objectiveId": "teaching", "provider": "claude"},
    ],
    "technical.md": [
        {"label": "default",          "ruleSetId": "critical_technical",
         "pathId": "technical", "objectiveId": "code_grounding", "provider": "claude"},
        {"label": "step_flow",        "ruleSetId": "critical_technical",
         "pathId": "technical", "objectiveId": "step_flow", "provider": "claude"},
        {"label": "artifact_first",   "ruleSetId": "artifact_first",
         "pathId": "technical", "objectiveId": "code_grounding", "provider": "claude"},
    ],
    "critical.md": [
        {"label": "default",          "ruleSetId": "critical_technical",
         "pathId": "critical", "objectiveId": "conceptual", "provider": "claude"},
        {"label": "argument",         "ruleSetId": "critical_technical",
         "pathId": "critical", "objectiveId": "argument", "provider": "claude"},
        {"label": "tension",          "ruleSetId": "critical_technical",
         "pathId": "critical", "objectiveId": "tension", "provider": "claude"},
    ],
    "blurb.md": [
        {"label": "default",          "ruleSetId": "artifact_first",
         "pathId": "general", "objectiveId": "vivid", "provider": "claude"},
        {"label": "compression",      "ruleSetId": "artifact_first",
         "pathId": "general", "objectiveId": "compression", "provider": "claude"},
    ],
    "summary.md": [
        {"label": "default",          "ruleSetId": "critical_technical",
         "pathId": "general", "objectiveId": "compression", "provider": "claude"},
    ],
    "intent.md": [
        {"label": "default",          "ruleSetId": "artifact_first",
         "pathId": "general", "objectiveId": "synthesis", "provider": "claude"},
    ],
}


# ── Composite scorer ────────────────────────────────────────────────────

# Weights to combine text_metrics (objective) and code_grounding (honesty).
# Higher = better. Range roughly 0..1.

def composite_score(map_name: str, file_role: str,
                    text_path: Path) -> dict[str, Any]:
    """Return {metrics, grounding, composite, status}."""
    if not text_path.exists():
        return {
            "exists": False, "status": "missing",
            "metrics_pass": False, "grounding_ratio": 0.0,
            "composite": 0.0,
        }

    # text_metrics
    m_result = text_metrics.score_file(text_path)
    metrics_pass = m_result["evaluation"]["status"] == "pass"
    metrics_failures = len(m_result["evaluation"]["failures"])

    # code_grounding — only meaningful for files with code
    has_code = m_result["metrics"]["code_blocks"] > 0
    if has_code:
        g_result = cgv.score_text(
            text_path.read_text(encoding="utf-8", errors="replace"),
            map_name,
        )
        grounding = g_result["overall_grounding_ratio"]
        unknown_count = g_result["totals"]["UNKNOWN"]
    else:
        grounding = 1.0  # nothing to verify
        unknown_count = 0

    # Composite: 0 = bad, 1 = pass all. Equal weight objective + grounding.
    objective_score = 1.0 if metrics_pass else max(0.0, 1.0 - metrics_failures * 0.15)
    composite = 0.5 * objective_score + 0.5 * grounding

    if metrics_pass and grounding >= 0.9:
        status = "pass"
    elif composite < 0.5:
        status = "fail"
    else:
        status = "warn"

    return {
        "exists": True,
        "status": status,
        "metrics_pass": metrics_pass,
        "metrics_failures": metrics_failures,
        "metrics_failure_list": m_result["evaluation"]["failures"],
        "word_count": m_result["metrics"]["word_count"],
        "code_ratio": m_result["metrics"]["code_ratio"],
        "code_blocks": m_result["metrics"]["code_blocks"],
        "grounding_ratio": grounding,
        "unknown_references": unknown_count,
        "composite": round(composite, 3),
    }


# ── Writer Pro interaction ──────────────────────────────────────────────

# ── Rule routing: failure pattern → theorist directives ────────────────
# The populate prompt is generic per-file-role. When a file fails specific
# metrics, we inject supplementary directives drawn from the curriculum's
# theoretical commitments. Each directive is written in the voice of the
# theorist's central concept — not a quote, a compressed operational rule.
#
# Keys are the failure-tag prefixes returned by text_metrics.evaluate_thresholds.
# Values are directive strings that will be concatenated into directionText.

FAILURE_DIRECTIVES: dict[str, str] = {
    "max_paragraph_sentences": (
        "BARTHES + PLATEAUS — paragraph length. Break every paragraph longer "
        "than three sentences. Prefer fragments over continuous explanation. "
        "If you can cut the connective 'and so', 'thus', 'therefore', cut it. "
        "The reader finds the rhythm; the author does not impose it."
    ),
    "paragraphs_max": (
        "BARTHES — too many paragraphs. Prose is not a list. Consolidate "
        "adjacent paragraphs that say one thing. Keep only the paragraph breaks "
        "that carry a real shift in thought."
    ),
    "word_count_min": (
        "TECHNICAL — the text is too short. Expand by grounding each concept "
        "in a concrete operation from one of the listed artifacts: name the "
        "function, name the variable, show what changes when it runs. No "
        "generic padding."
    ),
    "word_count_max": (
        "AGAMBEN — remove everything whose removal does not destroy an argument. "
        "The reader does not need connective tissue they can supply themselves."
    ),
    "code_ratio_min": (
        "ARTIFACT + HARAWAY — more code, less prose about code. Every prose "
        "paragraph must be replaced with the actual GDScript it describes or "
        "cut entirely. Situated knowledge means showing the mechanism, not "
        "glossing it."
    ),
    "code_ratio_max": (
        "CRITICAL — too much code, too little argument. Keep only the code "
        "blocks that carry teaching weight. Add one short paragraph of "
        "conceptual framing per section."
    ),
    "forbidden_words": (
        "VOICE — strip AI-register vocabulary on sight. No 'delves', 'tapestry', "
        "'fascinating', 'comprehensive', 'furthermore', 'moreover', 'landscape of', "
        "'navigating', 'intricate', 'essence of'. Replace with a concrete verb."
    ),
    "caption_max_words": (
        "WITTGENSTEIN — every caption is an imperative of fifteen words or fewer. "
        "If the caption cannot be spoken as a command, rewrite it until it can."
    ),
    "captions_missing": (
        "VALIDATION — every code block must be preceded by exactly one caption "
        "line. No naked code blocks. The caption is the teaching."
    ),
}

# Baseline directives per file role, always included when fixing that role.
FILE_ROLE_BASELINE: dict[str, str] = {
    "technical.md": (
        "HARAWAY — this tutorial is situated. Every function, variable, and "
        "behavior described must exist in one of the listed artifacts. Cite the "
        "function by name. If you cannot point to the real code, do not invent "
        "an API: name the absence instead ('this map does not yet visualize X')."
    ),
    "tutorial.md": (
        "HARAWAY + AHMED — code-first, situated. Each block cites a real export, "
        "function, or signal from a listed artifact. The caption orients the "
        "reader toward what the block does, not what the concept is."
    ),
    "critical.md": (
        "BARAD + AHMED — critical reflection must anchor in a specific scene or "
        "artifact named in map_data.json. Abstraction without anchor is not "
        "criticism, it is drift. Keep the theoretical tension visible."
    ),
    "blurb.md": (
        "AHMED — orientation in two or three short paragraphs. What does the "
        "learner encounter? What crack does the encounter open? Name the "
        "artifact. Do not describe 'the map' in the abstract."
    ),
}


def extract_failure_tags(metrics_result: dict[str, Any]) -> list[str]:
    """Given a text_metrics evaluation, return the list of failure tag keys
    that we have routing directives for."""
    if not metrics_result.get("exists", False):
        return []
    failures = metrics_result.get("metrics_failure_list") or metrics_result.get(
        "evaluation", {}).get("failures", [])
    tags: list[str] = []
    for f in failures:
        key = str(f).split(":")[0].strip()
        if key in FAILURE_DIRECTIVES and key not in tags:
            tags.append(key)
    # Low grounding is not a metrics failure, it comes from the grounding scorer
    if metrics_result.get("grounding_ratio", 1.0) < 0.8:
        if "low_grounding" not in tags:
            tags.append("low_grounding")
    return tags


def build_direction_text(file_role: str, failure_tags: list[str]) -> str:
    """Compose a directionText payload from baseline + routed directives."""
    chunks: list[str] = []
    base = FILE_ROLE_BASELINE.get(file_role)
    if base:
        chunks.append(base)
    # Special-case low_grounding — uses the baseline grounding directive
    routed = [t for t in failure_tags if t in FAILURE_DIRECTIVES]
    for tag in routed:
        chunks.append(FAILURE_DIRECTIVES[tag])
    if "low_grounding" in failure_tags:
        chunks.append(
            "HARAWAY — the previous draft referenced functions and classes that "
            "do not exist in any listed artifact. Do not invent APIs. If an "
            "artifact has no GDScript for a concept, name that gap explicitly "
            "instead of describing a non-existent interface."
        )
    return "\n\n".join(chunks)


# ── Rate-limit detection ────────────────────────────────────────────────
# Anthropic API has burst limits. When hit, populate's LLM call throws fast,
# the SSE stream closes without a progress 'done' event, and our caller
# sees `no done event in stream` in ~1.5-2s. Track this pattern across
# sequential calls and back off exponentially when it recurs.

_fast_fail_streak = 0
_rate_limit_pause_s = 600  # 10 min initial pause


def record_call_result(elapsed_s: float, had_done_event: bool) -> None:
    """Update rate-limit streak counter after each populate call."""
    global _fast_fail_streak, _rate_limit_pause_s
    is_fast_failure = elapsed_s < 5.0 and not had_done_event
    if is_fast_failure:
        _fast_fail_streak += 1
    else:
        _fast_fail_streak = 0
        _rate_limit_pause_s = 600  # reset back to 10 min on recovery


def should_pause_for_rate_limit() -> int:
    """Return seconds to sleep if we've hit a rate limit, else 0."""
    global _rate_limit_pause_s
    if _fast_fail_streak >= 3:
        pause = _rate_limit_pause_s
        # Exponential backoff: next pause is longer
        _rate_limit_pause_s = min(_rate_limit_pause_s * 2, 3600)  # cap at 1h
        return pause
    return 0


def call_populate(map_name: str, file_role: str,
                  direction_text: str | None = None,
                  timeout: int = 300) -> dict[str, Any]:
    """POST /api/maps/populate — regenerate the file from the map's artifacts.

    Populate is simpler and more reliable than /api/rule-flow/execute:
    it uses the 6-layer prompt assembly (metadata + artifacts + GDScript
    source + sequence context + blurb + file spec) and writes the result
    directly. No rule-set iteration; we get one shot per call. text_fixer's
    variation strategy is reduced to: generate once, score, keep if better.

    Returns {status: 'ok'|'error', preview?, word_count?} — the SSE stream
    is read through completion."""
    # NOTE: populate preserves non-scaffold files by design. Callers must
    # delete the target file first to force regeneration.
    payload: dict[str, Any] = {
        "fileType": file_role,
        "mapNames": [map_name],
        "skipScaffold": True,  # process missing + scaffold files (default)
    }
    if direction_text:
        payload["directionText"] = direction_text
    url = f"{WRITER_PRO}/api/maps/populate"
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            body = r.read().decode("utf-8")
        # Parse SSE stream; keep the last 'progress' event with status='done'
        # or any 'error' event.
        last_progress: dict[str, Any] = {}
        for event_block in body.split("\n\n"):
            if not event_block.strip():
                continue
            event_type = ""
            data_line = ""
            for line in event_block.splitlines():
                if line.startswith("event:"):
                    event_type = line[len("event:"):].strip()
                elif line.startswith("data:"):
                    data_line = line[len("data:"):].strip()
            if not data_line:
                continue
            try:
                ev = json.loads(data_line)
            except Exception:
                continue
            if event_type == "progress" and ev.get("status") == "done":
                last_progress = ev
            elif event_type == "error":
                return {"error": ev.get("error", "unknown"),
                        "error_map": ev.get("mapName")}
        if last_progress:
            return {
                "status": "ok",
                "preview": last_progress.get("preview", "")[:200],
                "word_count": last_progress.get("wordCount"),
            }
        return {"error": "no done event in stream"}
    except urllib.error.HTTPError as e:
        return {"error": f"HTTP {e.code}", "body": e.read().decode("utf-8")[:500]}
    except Exception as e:
        return {"error": str(e)}


# ── Per-file loop ───────────────────────────────────────────────────────

def fix_one(map_name: str, file_role: str, dry_run: bool = False,
            min_composite: float = 0.85, save_intermediate: bool = False
            ) -> dict[str, Any]:
    """Try variations until composite ≥ min_composite or options exhausted."""
    text_path = REPO / "commons" / "maps" / map_name / file_role
    initial = composite_score(map_name, file_role, text_path)

    result = {
        "map": map_name,
        "file": file_role,
        "initial": initial,
        "variations_tried": [],
        "best": None,
        "action": "skip",
    }

    if initial["status"] == "pass":
        result["action"] = "skip_ok"
        return result

    # Protect high-grounding files from regeneration damage.
    # If the existing text cites real code correctly (grounding ≥ 0.9),
    # populate's from-scratch regeneration is likely to erode that ground
    # truth even when the metrics directive is correct. Those files need
    # REWRITE tooling (not yet available) — not regeneration.
    #
    # Only applies to files that actually have code to ground against. Files
    # without fenced code blocks get a synthetic grounding of 1.0 that
    # should not gate regeneration (blurb, summary, most critical, most intent).
    has_real_code = initial.get("code_blocks", 0) > 0
    if (has_real_code
            and initial.get("grounding_ratio", 0.0) >= 0.9
            and initial.get("composite", 0.0) >= 0.75):
        result["action"] = "skip_grounded"
        return result

    if dry_run:
        result["action"] = "would_fix"
        return result

    # Backup original in case nothing improves
    original_text = text_path.read_text(encoding="utf-8", errors="replace") if text_path.exists() else ""
    best_score = initial["composite"] if initial["exists"] else 0.0
    best_label = "initial"
    best_text = original_text

    # Compute failure-routed direction text on first pass. If baseline
    # populate doesn't improve, retry with routed directives.
    failure_tags = extract_failure_tags(initial)
    routed_direction = build_direction_text(file_role, failure_tags)
    print(f"  routed tags: {failure_tags if failure_tags else '(none)'}")

    # Populate-based strategy: one shot per file. The populate endpoint
    # preserves non-scaffold files, so we delete the target first to force
    # regeneration. If the first regeneration doesn't beat the baseline,
    # retry once (up to 2 attempts). The populate prompt is already tuned
    # per file role in api/maps/populate/route.ts.
    MAX_ATTEMPTS = 2
    for attempt in range(1, MAX_ATTEMPTS + 1):
        # Delete file to force populate to regenerate it
        if text_path.exists():
            text_path.unlink()
        # Attempt 1: no directives, let the generic prompt produce its best.
        # Attempt 2: inject routed directives to correct attempt 1's specific
        # failures. This gives populate two chances with increasing guidance.
        use_direction = routed_direction if attempt > 1 else None
        label = f"populate_{attempt}" + ("_routed" if use_direction else "")
        print(f"  [attempt {attempt}] populate"
              f"{' (+ routed direction)' if use_direction else ''}",
              end=" ... ", flush=True)
        t0 = time.time()
        response = call_populate(map_name, file_role, direction_text=use_direction)
        elapsed = time.time() - t0
        had_done = "error" not in response
        record_call_result(elapsed, had_done)
        pause_s = should_pause_for_rate_limit()
        if pause_s:
            print(f"\n  [rate-limit] {_fast_fail_streak} fast failures — "
                  f"pausing {pause_s}s", flush=True)
            time.sleep(pause_s)
        if "error" in response:
            print(f"error: {str(response['error'])[:80]} ({elapsed:.1f}s)")
            result["variations_tried"].append({
                "label": label, "status": "error",
                "error": str(response["error"]), "elapsed_s": round(elapsed, 1),
            })
            continue

        # Score the (now rewritten) file
        score = composite_score(map_name, file_role, text_path)
        print(f"composite={score['composite']:.2f} "
              f"(wc={score.get('word_count', '?')} "
              f"cr={score.get('code_ratio', 0.0):.2f} "
              f"g={score.get('grounding_ratio', 0.0):.2f}) "
              f"({elapsed:.1f}s)")
        result["variations_tried"].append({
            "label": label, "status": "ok",
            "composite": score["composite"], "elapsed_s": round(elapsed, 1),
            "metrics_pass": score["metrics_pass"],
            "grounding_ratio": score["grounding_ratio"],
            "routed_tags": failure_tags if use_direction else [],
        })
        if score["composite"] > best_score:
            best_score = score["composite"]
            best_label = label
            best_text = text_path.read_text(encoding="utf-8", errors="replace")
        if score["composite"] >= min_composite:
            break

    # Restore best
    if best_label != "initial":
        text_path.write_text(best_text, encoding="utf-8")
        result["action"] = "fixed" if best_score > initial["composite"] else "no_improvement"
    else:
        # No attempt beat the original — restore original
        if original_text:
            text_path.write_text(original_text, encoding="utf-8")
        result["action"] = "no_improvement"

    result["best"] = {"label": best_label, "composite": best_score}
    return result


# ── Spine walker ────────────────────────────────────────────────────────

def walk(map_names: list[str], file_role: str, dry_run: bool,
         min_composite: float, limit: int) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    processed = 0
    for m in map_names:
        if limit and processed >= limit:
            break
        text_path = REPO / "commons" / "maps" / m / file_role
        if not text_path.exists():
            continue  # skip missing unless we want to generate new
        print(f"\n{m} / {file_role}")
        r = fix_one(m, file_role, dry_run=dry_run, min_composite=min_composite)
        init = r["initial"]
        if dry_run:
            marker = r["action"]
            print(f"  {marker}: composite={init.get('composite', 0.0):.2f}"
                  f"  metrics_pass={init.get('metrics_pass')}"
                  f"  grounding={init.get('grounding_ratio', 0.0):.2f}")
        results.append(r)
        processed += 1
    return results


def load_spine() -> list[str]:
    return text_metrics.load_spine_map_names()


def save_log(results: list[dict[str, Any]], meta: dict[str, Any]) -> None:
    if not LOG_FILE.exists():
        data = {"runs": []}
    else:
        try:
            data = json.loads(LOG_FILE.read_text(encoding="utf-8"))
        except Exception:
            data = {"runs": []}
    data["runs"].append({"meta": meta, "results": results})
    LOG_FILE.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n",
                        encoding="utf-8")


# ── CLI ─────────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", help="Only process this map")
    ap.add_argument("--file", required=False, default="tutorial.md",
                    help="File role (default tutorial.md)")
    ap.add_argument("--dry-run", action="store_true",
                    help="Score everything, fix nothing")
    ap.add_argument("--limit", type=int, default=0,
                    help="Stop after N maps (0 = all)")
    ap.add_argument("--min-composite", type=float, default=0.85,
                    help="Threshold — variations stop when this is reached")
    ap.add_argument("--variations", action="store_true",
                    help="Print the variation table and exit")
    args = ap.parse_args()

    if args.variations:
        print(json.dumps(VARIATIONS_PER_ROLE, indent=2))
        return 0

    # Sanity: Writer Pro reachable
    if not args.dry_run:
        try:
            with urllib.request.urlopen(f"{WRITER_PRO}/api/health", timeout=3) as r:
                r.read()
        except Exception as e:
            print(f"[WARN] Writer Pro not reachable at {WRITER_PRO}: {e}",
                  file=sys.stderr)
            print("  Start it with: cd ada_writer_pro/ada_writer && npm run dev",
                  file=sys.stderr)
            if not args.dry_run:
                return 1

    # Choose map list
    if args.map:
        maps = [args.map]
    else:
        maps = load_spine()
        if not maps:
            print("No spine maps found", file=sys.stderr)
            return 1

    t0 = time.time()
    results = walk(maps, args.file, args.dry_run, args.min_composite, args.limit)
    elapsed = time.time() - t0

    # Summary
    print(f"\n{'-' * 60}")
    if args.dry_run:
        counts: dict[str, int] = {}
        for r in results:
            counts[r["action"]] = counts.get(r["action"], 0) + 1
        print(f"dry-run: {counts.get('would_fix', 0)} would fix,"
              f" {counts.get('skip_ok', 0)} already pass,"
              f" {counts.get('skip_grounded', 0)} grounded (skip),"
              f" {counts.get('missing', 0)} missing"
              f" — {elapsed:.1f}s")
    else:
        counts = {}
        for r in results:
            counts[r["action"]] = counts.get(r["action"], 0) + 1
        print(f"done: {counts.get('fixed', 0)} fixed,"
              f" {counts.get('skip_ok', 0)} already pass,"
              f" {counts.get('skip_grounded', 0)} grounded (skip),"
              f" {counts.get('no_improvement', 0)} stuck"
              f" — {elapsed:.1f}s")
        save_log(results, {
            "timestamp": int(time.time()),
            "file_role": args.file,
            "dry_run": args.dry_run,
            "limit": args.limit,
            "min_composite": args.min_composite,
            "maps_processed": len(results),
            "elapsed_s": round(elapsed, 1),
        })
        print(f"log: {LOG_FILE.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
