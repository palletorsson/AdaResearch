#!/usr/bin/env python
"""
direct_api_rewriter.py — rewrite map text files via direct Anthropic API.

Bypasses both Writer Pro's CLI-subprocess path (which eats Claude Code
Max-plan quota) and inline-conversation rewriting (which burns the same
quota in one session). This script calls the Anthropic API directly using
an ANTHROPIC_API_KEY, billed as regular token usage — roughly $0.003 per
blurb at Sonnet pricing, $0.015 per technical/critical.

Same scoring integration as text_fixer.py: text_metrics + code_grounding.
Same safety semantics: restore original if composite doesn't improve.

Usage::

    # one file
    python tools/direct_api_rewriter.py --map Array_Patterns --file critical.md

    # all failing critical.md
    python tools/direct_api_rewriter.py --file critical.md

    # all failing blurb.md (if we add any)
    python tools/direct_api_rewriter.py --file blurb.md

    # dry-run: plan without calling API
    python tools/direct_api_rewriter.py --file critical.md --dry-run

    # cap for bounded runs
    python tools/direct_api_rewriter.py --file critical.md --limit 5

    # model choice (default sonnet for quality/cost balance)
    python tools/direct_api_rewriter.py --file critical.md --model claude-haiku-4-5

Requires: ANTHROPIC_API_KEY in env, anthropic python SDK (pip install anthropic).
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
TOOLS = REPO / "tools"
MAPS = REPO / "commons" / "maps"
LOG_FILE = TOOLS / "direct_api_rewriter_log.json"

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

sys.path.insert(0, str(TOOLS))
import text_metrics  # noqa: E402
import code_grounding_validator as cgv  # noqa: E402

try:
    import anthropic
except ImportError:
    print("ERROR: anthropic SDK not installed.\n"
          "  pip install anthropic", file=sys.stderr)
    sys.exit(1)


# ── Per-role prompt templates ───────────────────────────────────────────
# Compressed versions of Writer Pro's populate prompts, tuned for direct-API
# single-shot generation. No self-eval chain — we score with Python afterward.

SYSTEM_PROMPT = """You are writing map text for Ada Research — a VR curriculum where \
algorithms are taught through walkable spatial encounters. Voice rules:

- Compressed, declarative, no promotional register
- Show the mechanism, then name the meaning
- Ground every abstraction in a specific artifact the learner touches
- No AI-register vocabulary: no "delves", "tapestry", "fascinating", \
"comprehensive", "furthermore", "moreover", "in addition", "landscape of", \
"navigating", "intricate", "essence of"
- Paragraphs under 4 sentences for prose text, unlimited only inside code blocks
- Output ONLY the markdown body. No commentary. No "here is the text". No headers \
re-announcing the file role.

When you receive artifacts listed in the context, treat their exports, functions, \
and class_names as real. Cite them by name. Do not invent APIs that aren't in the \
listed artifact source.
"""

FILE_SPECS = {
    "blurb.md": """Write a BLURB for this map. 50-150 words. 1-3 short paragraphs of raw prose.

- Do NOT include any heading or title line
- Open with what the concept IS (functional: the learner knows what they encounter)
- Close with what it MEANS (the ontological crack, the line of flight)
- Ground in 2-4 specific artifacts — what the learner sees, touches, manipulates
- No bullet points, no headers, no titles

Output ONLY the blurb text.""",

    "critical.md": """Write a CRITICAL reflection for this map. 500-1500 words.

- Start with "# {MapDisplayName} - Critical Notes" heading
- Conceptual, theoretical framing with explicit argumentative movement
- Anchor every abstraction in a specific artifact, scene, or mechanic from the map
- Maintain conceptual precision and argumentative tension — do not collapse contradictions \
into generic summary
- Use 3-6 second-level headings (##) to structure the argument
- Keep paragraphs under 8 sentences
- QFEP connections should emerge through the argument, not be stated as theory overlay
- Name the theorists whose concepts genuinely organize the argument (Haraway, Ahmed, \
Barad, Barthes, Foucault, Heidegger, Merleau-Ponty, etc.) — but only when their concept \
is doing work in the reading, not as name-dropping

Output ONLY the markdown body starting with the heading.""",

    "summary.md": """Write a SUMMARY for this map. 180-450 words. Structured with subheadings.

- Start with "# {MapDisplayName} - Summary" heading
- Overview / Spatial Layout / Key Elements / Atmosphere / Learning Sequence / \
Design Intent / Connection to Sequence — these are the typical sections; use what fits
- Accessible but not dumbed down
- Ground in the specific artifacts and what they demonstrate
- Reference QFEP framework where natural
- Connections to previous and next maps in the sequence

Output ONLY the markdown body.""",

    "technical.md": """Write a TECHNICAL TUTORIAL for this map. 1500-3000 words.

- Start with "# {MapDisplayName}" heading
- 4-8 sections with ## subheadings, each teaching one concept
- Real GDScript code from the listed artifact sources (not pseudocode)
- Show code first, then explain what it means
- Connect to previous map: "In {previous map} we saw X. Now..."
- Set up next map where natural
- End with "## Possible Artifacts" ONLY if there are genuine gaps in the current set

Output ONLY the markdown body starting with the heading.""",
}


# ── Context assembly (mirrors Writer Pro's 6-layer assembly, trimmed) ──

def load_registry() -> dict[str, dict[str, Any]]:
    """Flatten commons/artifacts/registry/*.json into {lookup_name: meta}."""
    reg = {}
    reg_dir = REPO / "commons" / "artifacts" / "registry"
    for p in reg_dir.glob("*.json"):
        try:
            d = json.loads(p.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = d.get("artifacts", d) if isinstance(d, dict) else {}
        if not isinstance(arts, dict):
            continue
        for name, meta in arts.items():
            if isinstance(meta, dict):
                key = meta.get("lookup_name") or name
                reg[key] = meta
    return reg


_registry_cache: dict[str, dict[str, Any]] | None = None


def registry() -> dict[str, dict[str, Any]]:
    global _registry_cache
    if _registry_cache is None:
        _registry_cache = load_registry()
    return _registry_cache


def get_map_artifacts(map_name: str) -> list[str]:
    """Unique artifact lookup names used by a map."""
    p = MAPS / map_name / "map_data.json"
    if not p.exists():
        return []
    try:
        d = json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return []
    layers = d.get("layers", {})
    inter = layers.get("interactables", [])
    arts: set[str] = set()

    def walk(obj: Any) -> None:
        if isinstance(obj, str):
            s = obj.strip()
            if s and s not in (" ", "empty"):
                arts.add(s.split(":")[0])
        elif isinstance(obj, list):
            for it in obj:
                walk(it)
        elif isinstance(obj, dict):
            for v in obj.values():
                walk(v)

    walk(inter)
    return sorted(arts)


def read_file_or_empty(path: Path, max_chars: int = 0) -> str:
    if not path.exists():
        return ""
    try:
        txt = path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return ""
    if max_chars and len(txt) > max_chars:
        return txt[:max_chars] + "\n[... truncated ...]"
    return txt


def get_artifact_source_excerpt(meta: dict[str, Any],
                                max_chars: int = 2500) -> str:
    """Return the .gd source for an artifact, truncated."""
    scene = meta.get("scene") or meta.get("tscn") or ""
    if scene.startswith("res://"):
        scene = scene[len("res://"):]
    if not scene:
        return ""
    scene_path = REPO / scene
    gd_path = scene_path.with_suffix(".gd")
    if not gd_path.exists():
        return ""
    return read_file_or_empty(gd_path, max_chars=max_chars)


def build_context(map_name: str, file_role: str) -> str:
    """Assemble the context block for a map — trimmed from Writer Pro's 6-layer."""
    parts: list[str] = []
    parts.append(f"# Map: {map_name}")

    # Map metadata
    md_path = MAPS / map_name / "map_data.json"
    if md_path.exists():
        try:
            md = json.loads(md_path.read_text(encoding="utf-8"))
            mi = md.get("map_info", {})
            if mi.get("name"):
                parts.append(f"Display name: {mi['name']}")
            if mi.get("description"):
                parts.append(f"Description: {mi['description']}")
            if mi.get("difficulty"):
                parts.append(f"Difficulty: {mi['difficulty']}")
            objs = mi.get("learning_objectives", [])
            if objs:
                parts.append(f"Learning objectives: {'; '.join(objs)}")
        except Exception:
            pass

    # Intent.md is a compact author-statement of what the map is about
    intent = read_file_or_empty(MAPS / map_name / "intent.md", max_chars=2000)
    if intent:
        parts.append("\n## Intent (author's statement)")
        parts.append(intent)

    # Existing blurb provides tonal anchor
    if file_role != "blurb.md":
        blurb = read_file_or_empty(MAPS / map_name / "blurb.md", max_chars=1500)
        if blurb:
            parts.append("\n## Existing Blurb (for tonal consistency)")
            parts.append(blurb)

    # Artifacts + source (for technical/critical/tutorial that cite code)
    artifacts = get_map_artifacts(map_name)
    if artifacts:
        parts.append(f"\n## Artifacts in this map ({len(artifacts)})")
        reg = registry()
        include_source = file_role in ("technical.md", "tutorial.md")
        for art in artifacts:
            meta = reg.get(art)
            if not meta:
                parts.append(f"- {art} (not in registry)")
                continue
            desc = meta.get("description", "")[:200]
            parts.append(f"\n### {art}")
            if desc:
                parts.append(desc)
            if include_source:
                src = get_artifact_source_excerpt(meta, max_chars=1800)
                if src:
                    parts.append("```gdscript\n" + src + "\n```")

    # Existing file content, so regeneration can preserve what's working
    existing = read_file_or_empty(MAPS / map_name / file_role, max_chars=4000)
    if existing:
        parts.append(f"\n## Current {file_role} (replace this, preserve voice)")
        parts.append(existing)

    return "\n".join(parts)


# ── API call ────────────────────────────────────────────────────────────

_client: "anthropic.Anthropic | None" = None


def client() -> "anthropic.Anthropic":
    global _client
    if _client is None:
        api_key = os.environ.get("ANTHROPIC_API_KEY")
        if not api_key:
            print("ERROR: ANTHROPIC_API_KEY not set in environment.",
                  file=sys.stderr)
            sys.exit(2)
        _client = anthropic.Anthropic(api_key=api_key)
    return _client


def call_api(
    map_name: str,
    file_role: str,
    model: str,
    max_tokens: int = 4000,
) -> dict[str, Any]:
    """Single-shot generation via Anthropic API. Returns {text, usage} or {error}."""
    spec = FILE_SPECS.get(file_role)
    if not spec:
        return {"error": f"No spec for {file_role}"}

    display_name = map_name.replace("_", " ")
    spec_text = spec.replace("{MapDisplayName}", display_name)

    ctx = build_context(map_name, file_role)
    user_prompt = f"{ctx}\n\n---\n\n# Task\n\n{spec_text}"

    try:
        t0 = time.time()
        resp = client().messages.create(
            model=model,
            max_tokens=max_tokens,
            system=SYSTEM_PROMPT,
            messages=[{"role": "user", "content": user_prompt}],
        )
        elapsed = time.time() - t0
        text = "".join(
            block.text for block in resp.content
            if hasattr(block, "text")
        )
        return {
            "text": text,
            "usage": {
                "input_tokens": resp.usage.input_tokens,
                "output_tokens": resp.usage.output_tokens,
            },
            "elapsed_s": round(elapsed, 1),
            "stop_reason": resp.stop_reason,
        }
    except anthropic.RateLimitError as e:
        return {"error": f"rate_limit: {str(e)[:200]}"}
    except anthropic.APIError as e:
        return {"error": f"api_error: {str(e)[:200]}"}
    except Exception as e:
        return {"error": f"other: {type(e).__name__}: {str(e)[:200]}"}


# ── Scoring (same as text_fixer) ───────────────────────────────────────

def composite_score(map_name: str, file_role: str,
                    text_path: Path) -> dict[str, Any]:
    if not text_path.exists():
        return {"exists": False, "status": "missing", "composite": 0.0}
    m_result = text_metrics.score_file(text_path)
    metrics_pass = m_result["evaluation"]["status"] == "pass"
    metrics_failures = len(m_result["evaluation"]["failures"])
    has_code = m_result["metrics"]["code_blocks"] > 0
    if has_code:
        g = cgv.score_text(
            text_path.read_text(encoding="utf-8", errors="replace"),
            map_name,
        )
        grounding = g["overall_grounding_ratio"]
        unknowns = g["totals"]["UNKNOWN"]
    else:
        grounding = 1.0
        unknowns = 0
    objective = 1.0 if metrics_pass else max(0.0, 1.0 - metrics_failures * 0.15)
    composite = 0.5 * objective + 0.5 * grounding
    return {
        "exists": True,
        "metrics_pass": metrics_pass,
        "metrics_failures": metrics_failures,
        "metrics_failure_list": m_result["evaluation"]["failures"],
        "word_count": m_result["metrics"]["word_count"],
        "code_blocks": m_result["metrics"]["code_blocks"],
        "code_ratio": m_result["metrics"]["code_ratio"],
        "grounding_ratio": grounding,
        "unknown_references": unknowns,
        "composite": round(composite, 3),
    }


# ── Per-map loop ────────────────────────────────────────────────────────

def fix_one(
    map_name: str,
    file_role: str,
    model: str,
    dry_run: bool = False,
    min_composite: float = 0.85,
) -> dict[str, Any]:
    text_path = MAPS / map_name / file_role
    initial = composite_score(map_name, file_role, text_path)

    result: dict[str, Any] = {
        "map": map_name,
        "file": file_role,
        "model": model,
        "initial": initial,
        "attempts": [],
        "action": "skip",
    }

    # Skip files that already pass
    if initial.get("metrics_pass") and initial.get("grounding_ratio", 0.0) >= 0.9:
        result["action"] = "skip_ok"
        return result

    # Protect high-grounding files from regeneration damage (same guard as text_fixer)
    has_real_code = initial.get("code_blocks", 0) > 0
    if (has_real_code
            and initial.get("grounding_ratio", 0.0) >= 0.9
            and initial.get("composite", 0.0) >= 0.75):
        result["action"] = "skip_grounded"
        return result

    if dry_run:
        result["action"] = "would_fix"
        return result

    # Backup
    original_text = text_path.read_text(encoding="utf-8", errors="replace") if text_path.exists() else ""
    best_text = original_text
    best_score = initial.get("composite", 0.0) if initial["exists"] else 0.0
    best_label = "initial"

    MAX_ATTEMPTS = 2
    for attempt in range(1, MAX_ATTEMPTS + 1):
        print(f"  [attempt {attempt}] {model}", end=" ... ", flush=True)
        response = call_api(map_name, file_role, model)
        if "error" in response:
            print(f"error: {response['error'][:80]}")
            result["attempts"].append({
                "label": f"api_{attempt}",
                "status": "error",
                "error": response["error"],
            })
            # Rate limit — stop trying this file
            if "rate_limit" in response["error"]:
                break
            continue

        # Write + score
        text_path.write_text(response["text"], encoding="utf-8")
        score = composite_score(map_name, file_role, text_path)
        usage = response.get("usage", {})
        in_tok = usage.get("input_tokens", 0)
        out_tok = usage.get("output_tokens", 0)
        # Sonnet 4.5 pricing: $3/MTok in, $15/MTok out
        cost_usd = (in_tok * 3 + out_tok * 15) / 1_000_000
        print(f"composite={score['composite']:.2f} "
              f"(wc={score.get('word_count','?')} "
              f"g={score.get('grounding_ratio',0):.2f}) "
              f"${cost_usd:.3f} ({response['elapsed_s']}s)")

        result["attempts"].append({
            "label": f"api_{attempt}",
            "status": "ok",
            "composite": score["composite"],
            "elapsed_s": response["elapsed_s"],
            "input_tokens": in_tok,
            "output_tokens": out_tok,
            "cost_usd": round(cost_usd, 4),
            "metrics_pass": score["metrics_pass"],
            "grounding_ratio": score["grounding_ratio"],
        })
        if score["composite"] > best_score:
            best_score = score["composite"]
            best_label = f"api_{attempt}"
            best_text = text_path.read_text(encoding="utf-8", errors="replace")
        if score["composite"] >= min_composite:
            break

    # Write best / restore original
    if best_label != "initial":
        text_path.write_text(best_text, encoding="utf-8")
        result["action"] = "fixed" if best_score > initial.get("composite", 0.0) else "no_improvement"
    else:
        if original_text:
            text_path.write_text(original_text, encoding="utf-8")
        result["action"] = "no_improvement"
    result["best"] = {"label": best_label, "composite": best_score}
    return result


# ── Queue ──────────────────────────────────────────────────────────────

def load_queue(file_role: str, only_failing: bool = True) -> list[str]:
    """Get the list of spine maps that need this file role fixed."""
    baseline = REPO / "doc" / "text_metrics_baseline.json"
    if not baseline.exists():
        print("ERROR: doc/text_metrics_baseline.json missing. "
              "Run: python tools/text_metrics.py --spine --format json > doc/text_metrics_baseline.json",
              file=sys.stderr)
        sys.exit(3)
    d = json.loads(baseline.read_text(encoding="utf-8"))
    names: list[str] = []
    for m in d.get("maps", []):
        for f in m.get("files", []):
            if f["role"] != file_role:
                continue
            if only_failing and f["status"] != "fail":
                continue
            if not only_failing and f["status"] in ("pass", "missing"):
                continue
            names.append(m["map"])
            break
    return names


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


# ── CLI ─────────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", help="Single map name")
    ap.add_argument("--file", default="critical.md",
                    help="File role to process (default critical.md)")
    ap.add_argument("--dry-run", action="store_true",
                    help="Plan without calling API")
    ap.add_argument("--limit", type=int, default=0,
                    help="Cap number of maps processed (0 = all)")
    ap.add_argument("--model", default="claude-sonnet-4-5",
                    help="Anthropic model (default claude-sonnet-4-5)")
    ap.add_argument("--min-composite", type=float, default=0.85,
                    help="Threshold to stop iterating (default 0.85)")
    ap.add_argument("--sleep-between", type=float, default=2.0,
                    help="Seconds to sleep between maps (polite rate limiting)")
    args = ap.parse_args()

    if args.map:
        maps = [args.map]
    else:
        maps = load_queue(args.file)

    if not maps:
        print(f"No {args.file} files to process.", file=sys.stderr)
        return 0

    if args.limit:
        maps = maps[:args.limit]

    print(f"Processing {len(maps)} × {args.file} with {args.model}")
    print(f"{'DRY RUN — no API calls' if args.dry_run else 'LIVE — billed to ANTHROPIC_API_KEY'}")
    print()

    t0 = time.time()
    results: list[dict[str, Any]] = []
    total_cost = 0.0
    for i, m in enumerate(maps, 1):
        print(f"[{i}/{len(maps)}] {m} / {args.file}")
        r = fix_one(m, args.file, args.model,
                    dry_run=args.dry_run,
                    min_composite=args.min_composite)
        results.append(r)
        for a in r.get("attempts", []):
            total_cost += a.get("cost_usd", 0.0)
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
              f"— total API cost ${total_cost:.3f}, {elapsed:.1f}s")
        save_log(results, {
            "timestamp": int(time.time()),
            "file_role": args.file,
            "model": args.model,
            "maps_processed": len(results),
            "total_cost_usd": round(total_cost, 4),
            "elapsed_s": round(elapsed, 1),
        })
        print(f"log: {LOG_FILE.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
