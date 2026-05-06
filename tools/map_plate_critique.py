#!/usr/bin/env python
"""map_plate_critique.py — Vision-critique a map as a "plate" against an edge.

The cheapest possible auto-research loop step: render a map at 5 iso angles,
hand them to a vision model alongside the edge's text + visual seeds, get
back a structured critique with a 1-5 score and concrete revision hints.

Pipeline:
  1. Run capture_multi_angle.gd in map mode to produce
     user://multi_shots/<MapName>/{above,front,left,right,back}.png
  2. Load the relevant edge section from doc/EDGES_OF_ALGORITHM.md
  3. Load the relevant edge section from doc/EDGES_OF_ALGORITHM_VISUAL_SEEDS.md
  4. Optionally load blurb/intent for the map (if present)
  5. Single Claude API call with all 5 images + cached prompt
  6. Save JSON report to doc/reports/plate_critique_<map>_<edge>.json

Usage:
  python tools/map_plate_critique.py --map=Fold_Theatre --edge=F
  python tools/map_plate_critique.py --map=Fold_Theatre --edge=F --no-capture
  python tools/map_plate_critique.py --map=Fold_Theatre --edge=F --model=claude-sonnet-4-5

Requires: ANTHROPIC_API_KEY env var. SDK pinned at >=0.49.

Cost note: ~5 images of 640x640 PNG ≈ 6-8K vision tokens + ~3K cached text tokens
≈ $0.02-0.04 per critique on Sonnet. Twenty critiques ≈ $0.50.
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

# We invoke the local `claude` CLI (subscription-auth) instead of the SDK
# so this works with whatever auth Claude Code already has set up. No
# ANTHROPIC_API_KEY required.
CLAUDE_BIN = shutil.which("claude") or "claude"

REPO = Path(__file__).resolve().parent.parent
DOC_EDGES = REPO / "doc" / "EDGES_OF_ALGORITHM.md"
DOC_SEEDS = REPO / "doc" / "EDGES_OF_ALGORITHM_VISUAL_SEEDS.md"
REPORTS_DIR = REPO / "doc" / "reports"
RUNTIME_FLAGS = REPO / "ada_run" / "runtime_flags.json"
GODOT_EXE = os.environ.get(
    "GODOT_EXE",
    "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe",
)
CAPTURE_SCRIPT = "res://commons/testing/capture_multi_angle.gd"
ANGLES = ["above", "front", "left", "right", "back"]
DEFAULT_MODEL = "claude-sonnet-4-5"


# ───────────────────────────────────────────────────────────────────────
# Doc parsing — extract one edge section from the structured markdown.
# ───────────────────────────────────────────────────────────────────────

def extract_edge_section(doc_path: Path, edge_letter: str) -> str:
    """Pull the `## X. ...` section through to the next `## Y.`"""
    if not doc_path.exists():
        return ""
    raw = doc_path.read_text(encoding="utf-8")
    # Match "## A. Title" through to next "## B." or end-of-file.
    pattern = rf"^## {re.escape(edge_letter)}\.\s.*?(?=^## [A-M]\.|^---\s*$|\Z)"
    m = re.search(pattern, raw, re.MULTILINE | re.DOTALL)
    return m.group(0).strip() if m else ""


def find_user_data_dir() -> Path:
    """Locate Godot's user:// directory for this project."""
    appdata = os.environ.get("APPDATA")
    if appdata:
        candidate = Path(appdata) / "Godot" / "app_userdata" / "Ada Research Zero One"
        if candidate.exists():
            return candidate
    # Fallback: linux/mac style (rare for this project)
    for p in [
        Path.home() / ".local/share/godot/app_userdata/Ada Research Zero One",
        Path.home() / "Library/Application Support/Godot/app_userdata/Ada Research Zero One",
    ]:
        if p.exists():
            return p
    raise RuntimeError("Could not locate Godot user data dir for Ada Research Zero One")


# ───────────────────────────────────────────────────────────────────────
# Capture — invoke Godot headless to render the 5 angles.
# ───────────────────────────────────────────────────────────────────────

def _set_biome_flag(enabled: bool) -> dict | None:
    """Flip biome_enabled in ada_run/runtime_flags.json; return prior state for restoration.
    GridSystem reads this at map-load time, so the change takes effect immediately
    on the next map load done by the capture script."""
    if not RUNTIME_FLAGS.exists():
        return None
    try:
        prev = json.loads(RUNTIME_FLAGS.read_text(encoding="utf-8"))
    except Exception:
        return None
    new = dict(prev)
    new["biome_enabled"] = enabled
    RUNTIME_FLAGS.write_text(json.dumps(new, indent=2) + "\n", encoding="utf-8")
    return prev


def _restore_flags(prev: dict | None) -> None:
    if prev is None:
        return
    try:
        RUNTIME_FLAGS.write_text(json.dumps(prev, indent=2) + "\n", encoding="utf-8")
    except Exception as e:
        print(f"[plate_critique] WARN: could not restore runtime_flags.json: {e}")


def run_capture(map_name: str, biome: bool = False) -> Path:
    """Run capture_multi_angle.gd; return the directory holding 5 PNGs.

    By default disables the biome so the map's structure (the actual plate)
    isn't obscured by foliage and critters. Pass biome=True to capture the
    populated world instead.
    """
    user_dir = find_user_data_dir()
    out_dir_user = "user://plate_critique_shots"
    cmd = [
        GODOT_EXE,
        "--path", str(REPO),
        "--xr-mode", "off",
        "--no-window",
        "--script", CAPTURE_SCRIPT,
        "--",
        f"--mode=map",
        f"--target={map_name}",
        f"--out={out_dir_user}",
    ]
    print(f"[plate_critique] capturing 5 angles of {map_name} (biome={'on' if biome else 'off'})...")
    prev_flags = None
    if not biome:
        prev_flags = _set_biome_flag(False)
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=180,
                              encoding="utf-8", errors="replace")
    finally:
        _restore_flags(prev_flags)
    if proc.returncode != 0:
        print(f"[plate_critique] capture FAILED rc={proc.returncode}")
        print(proc.stderr[-800:])
        raise SystemExit(1)
    shots_dir = user_dir / "plate_critique_shots" / map_name
    if not shots_dir.exists():
        # Fallback: capture script may have used multi_shots default.
        shots_dir = user_dir / "multi_shots" / map_name
    if not shots_dir.exists():
        raise SystemExit(f"[plate_critique] shots dir missing: {shots_dir}")
    return shots_dir


def gather_shots(shots_dir: Path) -> dict[str, Path]:
    """Return {angle: path} for the angles that exist."""
    result: dict[str, Path] = {}
    for angle in ANGLES:
        p = shots_dir / f"{angle}.png"
        if p.exists():
            result[angle] = p
    return result


# ───────────────────────────────────────────────────────────────────────
# Map metadata — pull blurb/intent if present so the critic has context.
# ───────────────────────────────────────────────────────────────────────

def gather_map_context(map_name: str) -> dict[str, str]:
    """Read map_data.json description + any blurb.md / intent.md."""
    map_dir = REPO / "commons" / "maps" / map_name
    out: dict[str, str] = {}
    md_path = map_dir / "map_data.json"
    if md_path.exists():
        try:
            md = json.loads(md_path.read_text(encoding="utf-8"))
            info = md.get("map_info", {})
            out["title"] = info.get("title", map_name)
            out["description"] = info.get("description", "")
            dims = info.get("dimensions", {})
            out["dimensions"] = f"{dims.get('width', '?')}×{dims.get('depth', '?')}"
        except Exception as e:
            out["error"] = f"could not parse map_data.json: {e}"
    for fname in ("blurb.md", "intent.md", "technical.md"):
        f = map_dir / fname
        if f.exists():
            out[fname.replace(".md", "")] = f.read_text(encoding="utf-8")[:2000]
    return out


# ───────────────────────────────────────────────────────────────────────
# Prompt + API call
# ───────────────────────────────────────────────────────────────────────

SYSTEM_PROMPT = """You are an expert critic for the Ada Research VR project.

The project's late-spine maps are designed to be **plates in Ada's own Codex** —
Haeckel-style diagrams that teach a specific "edge of algorithm" through visual
grammar alone, without naming the edge in text. The map should *be* the argument;
spatial position must carry claim. The diagram itself is the teaching.

Your job: look at five iso views of one map and judge whether it works as a
plate for the named edge. Be specific, concrete, and constructive. The author
will use your hints to revise the map.

Always respond with a single JSON object — no preamble, no commentary outside
the JSON. The JSON schema:

{
  "score": <integer 1-5; 1 = does not teach the edge at all, 5 = exemplary plate>,
  "verdict": "<one short phrase: 'works', 'partial', 'misreads', etc.>",
  "paragraph": "<3-5 sentence critical analysis of the plate as plate>",
  "strengths": ["<what works visually>", ...],
  "weaknesses": ["<what undermines the edge's teaching>", ...],
  "next_gen_hints": [
    "<concrete actionable revision: 'move teaching artifact toward path centre'>",
    "<another concrete revision>",
    ...
  ],
  "edge_reads_as": "<which edge (A-M) the plate currently reads as, or 'unclear'>"
}

Score rubric:
  5 — The plate reads as the edge from any angle. Visual grammar is unmistakable.
  4 — Reads as the edge from most angles. Minor occlusion or framing issues.
  3 — Reads as the edge if you know what to look for. Mixed signals.
  2 — Reads as a different edge or as ambiguous geometry.
  1 — Reads as nothing in particular. No legible argument.
"""


def build_user_message(edge_letter: str, edge_text: str, seed_text: str,
                       map_ctx: dict, shot_paths: dict[str, Path]) -> list[dict]:
    """Build the user-message content blocks. Cacheable text first, then images."""
    parts: list[dict] = []

    # Cacheable: the edge specification + visual seeds. Same across every map
    # critique that targets the same edge. cache_control on the last text
    # block of this group breaks the cache boundary correctly.
    parts.append({
        "type": "text",
        "text": f"# Edge {edge_letter} — Specification\n\n{edge_text}",
    })
    parts.append({
        "type": "text",
        "text": f"# Edge {edge_letter} — Visual Seeds (cousin descriptions)\n\n{seed_text}",
        "cache_control": {"type": "ephemeral"},
    })

    # Per-map context (varies, not cached).
    ctx_lines = [f"# Map under critique\n"]
    if "title" in map_ctx:
        ctx_lines.append(f"**Title:** {map_ctx['title']}")
    if "dimensions" in map_ctx:
        ctx_lines.append(f"**Dimensions:** {map_ctx['dimensions']}")
    if "description" in map_ctx and map_ctx["description"]:
        ctx_lines.append(f"**Description:** {map_ctx['description']}")
    for k in ("blurb", "intent", "technical"):
        if k in map_ctx:
            ctx_lines.append(f"\n## {k}.md\n\n{map_ctx[k]}")
    parts.append({"type": "text", "text": "\n".join(ctx_lines)})

    # Images — five angles of the same map.
    for angle in ANGLES:
        if angle not in shot_paths:
            continue
        img_bytes = shot_paths[angle].read_bytes()
        parts.append({
            "type": "image",
            "source": {
                "type": "base64",
                "media_type": "image/png",
                "data": base64.standard_b64encode(img_bytes).decode("ascii"),
            },
        })
        parts.append({"type": "text", "text": f"^ Angle: **{angle}**"})

    # The actual question.
    parts.append({
        "type": "text",
        "text": (
            f"Critique this map as a plate for edge {edge_letter}. "
            "Score, verdict, paragraph, strengths, weaknesses, next_gen_hints, "
            "edge_reads_as. JSON only."
        ),
    })
    return parts


def call_critic(model: str, edge_letter: str, edge_text: str,
                seed_text: str, map_ctx: dict, shot_paths: dict[str, Path]) -> dict:
    """Invoke `claude -p` with a critique prompt + image file paths.

    The prompt tells Claude to Read each PNG from disk and respond with a
    single JSON object matching the schema below. No SDK calls; no API key
    needed; uses whatever auth Claude Code already has.
    """
    # Build the prompt: edge spec + visual seeds + map context + image paths.
    angle_lines = []
    for angle in ANGLES:
        if angle in shot_paths:
            angle_lines.append(f"  - **{angle}**: {shot_paths[angle].as_posix()}")
    angle_block = "\n".join(angle_lines)

    ctx_lines = []
    if "title" in map_ctx:
        ctx_lines.append(f"**Title:** {map_ctx['title']}")
    if "dimensions" in map_ctx:
        ctx_lines.append(f"**Dimensions:** {map_ctx['dimensions']}")
    if "description" in map_ctx and map_ctx["description"]:
        ctx_lines.append(f"**Description:** {map_ctx['description']}")
    for k in ("blurb", "intent", "technical"):
        if k in map_ctx:
            ctx_lines.append(f"\n## {k}.md\n\n{map_ctx[k]}")
    map_ctx_text = "\n".join(ctx_lines) if ctx_lines else "(no map metadata)"

    prompt = f"""{SYSTEM_PROMPT}

# Edge {edge_letter} — Specification

{edge_text}

# Edge {edge_letter} — Visual Seeds (cousin descriptions)

{seed_text}

# Map under critique

{map_ctx_text}

# Images to read (use the Read tool on each)

{angle_block}

Read all five images, then respond with the JSON object described in the
system prompt above. JSON only — no preamble, no commentary. Wrap the JSON
in a single ```json fenced block so I can extract it cleanly."""

    print(f"[plate_critique] calling {model} via `claude -p` with {len(shot_paths)} images...")

    cmd = [
        CLAUDE_BIN,
        "-p",
        prompt,
        "--allowedTools", "Read",
        "--model", model,
        "--output-format", "text",
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=180,
                          encoding="utf-8", errors="replace")
    if proc.returncode != 0:
        print(f"[plate_critique] claude CLI FAILED rc={proc.returncode}")
        print(proc.stderr[-800:])
        return {"model": model, "error": "claude_cli_failed",
                "stderr": proc.stderr[-800:], "critique": {}}

    raw = proc.stdout.strip()
    # Pull JSON out of ```json ... ``` fences (preferred) or as last { ... }.
    fence = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", raw, re.DOTALL)
    if fence:
        json_str = fence.group(1)
    else:
        # Fallback: find the last balanced JSON object in the output.
        match = re.search(r"(\{[\s\S]*\})\s*$", raw)
        json_str = match.group(1) if match else raw
    try:
        parsed = json.loads(json_str)
    except json.JSONDecodeError as e:
        print(f"[plate_critique] WARN: model output is not valid JSON ({e})")
        parsed = {"raw_response": raw, "parse_error": str(e)}
    return {"model": model, "critique": parsed, "raw": raw[:2000]}


# ───────────────────────────────────────────────────────────────────────
# Main
# ───────────────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(description="Vision-critique a map plate against an edge.")
    ap.add_argument("--map", required=True, help="Map lookup_name (e.g. Fold_Theatre)")
    ap.add_argument("--edge", required=True, help="Edge letter A-M (e.g. F)")
    ap.add_argument("--model", default=DEFAULT_MODEL, help=f"Anthropic model (default: {DEFAULT_MODEL})")
    ap.add_argument("--no-capture", action="store_true",
                    help="Skip the Godot capture step; reuse existing shots.")
    ap.add_argument("--with-biome", action="store_true",
                    help="Capture WITH biome (foliage + critters). Default is biome off "
                         "so the map's structure reads cleanly as a plate.")
    ap.add_argument("--shots-dir", default=None,
                    help="Override shots dir (default: user://plate_critique_shots/<map>)")
    args = ap.parse_args()

    edge = args.edge.upper()
    if edge not in list("ABCDEFGHIJKLM"):
        print(f"ERROR: --edge must be one of A-M, got {edge}")
        sys.exit(1)

    # 1. Capture (or reuse).
    if args.shots_dir:
        shots_dir = Path(args.shots_dir)
    elif args.no_capture:
        user_dir = find_user_data_dir()
        for cand in [user_dir / "plate_critique_shots" / args.map,
                     user_dir / "multi_shots" / args.map]:
            if cand.exists():
                shots_dir = cand
                break
        else:
            print("ERROR: --no-capture but no existing shots dir")
            sys.exit(1)
    else:
        shots_dir = run_capture(args.map, biome=args.with_biome)

    shots = gather_shots(shots_dir)
    if not shots:
        print(f"ERROR: no PNGs found in {shots_dir}")
        sys.exit(1)
    print(f"[plate_critique] found shots: {sorted(shots.keys())}")

    # 2 + 3. Edge spec + visual seeds.
    edge_text = extract_edge_section(DOC_EDGES, edge)
    seed_text = extract_edge_section(DOC_SEEDS, edge)
    if not edge_text:
        print(f"ERROR: edge {edge} not found in {DOC_EDGES}")
        sys.exit(1)
    print(f"[plate_critique] loaded edge spec ({len(edge_text)} chars)"
          f" + visual seeds ({len(seed_text)} chars)")

    # 4. Map context.
    map_ctx = gather_map_context(args.map)

    # 5. Critic call via local `claude` CLI (uses whatever auth Claude Code has).
    result = call_critic(args.model, edge, edge_text, seed_text, map_ctx, shots)

    # 6. Save report + print summary.
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    out_path = REPORTS_DIR / f"plate_critique_{args.map}_{edge}.json"
    payload = {
        "map": args.map,
        "edge": edge,
        "shots": {a: str(p.relative_to(shots_dir.parent.parent)) if shots_dir.parent.parent in p.parents else str(p) for a, p in shots.items()},
        "result": result,
    }
    out_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(f"[plate_critique] wrote {out_path}")

    crit = result.get("critique", {})
    if isinstance(crit, dict) and "score" in crit:
        print()
        print(f"  score:        {crit.get('score')}/5")
        print(f"  verdict:      {crit.get('verdict')}")
        print(f"  reads as:     edge {crit.get('edge_reads_as')}")
        print(f"  paragraph:    {crit.get('paragraph', '')[:280]}")
        hints = crit.get("next_gen_hints", [])
        if hints:
            print(f"  hints:")
            for h in hints[:5]:
                print(f"    - {h}")
    usage = result.get("usage", {})
    print(f"\n  tokens: in={usage.get('input_tokens')} out={usage.get('output_tokens')}"
          f" cache_create={usage.get('cache_creation_input_tokens', 0)}"
          f" cache_read={usage.get('cache_read_input_tokens', 0)}")


if __name__ == "__main__":
    main()
