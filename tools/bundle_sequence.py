#!/usr/bin/env python
"""
bundle_sequence.py — concatenate a sequence's text files into one document.

Reads the curriculum spine, finds which maps belong to a sequence, and
emits all of their target-role text files (technical.md, critical.md,
etc.) as one continuous chapter with unambiguous map boundaries. Pair
with split_sequence.py to write back after editing.

Saves tokens when editing via an LLM: one Read of the bundle replaces
N Reads of individual files; small Edits against the bundle emit only
deltas instead of full Write bodies.

Usage::

    # Full bundle: every map in the sequence
    python tools/bundle_sequence.py --sequence primitives --file technical.md \\
        --out doc/_bundles/primitives_technical.md

    # Only maps that currently fail text_metrics thresholds
    python tools/bundle_sequence.py --sequence primitives --file technical.md \\
        --only-failing --out doc/_bundles/primitives_technical.md

    # With diagnostic comments per failing map
    python tools/bundle_sequence.py --sequence primitives --file technical.md \\
        --diff-mode --out doc/_bundles/primitives_technical.md

    # Include intent + blurb as context for each map (more tokens, better edits)
    python tools/bundle_sequence.py --sequence primitives --file technical.md \\
        --with-context --out doc/_bundles/primitives_technical.md

Bundle format::

    <<<ADA_BUNDLE>>>
    sequence: primitives
    file: technical.md
    maps: 12
    created: 2026-04-23T10:15:00
    <<</ADA_BUNDLE>>>

    <<<MAP: Point_One>>>
    # FAILURE: max_paragraph_sentences=10 (need ≤8), word_count_min=1083
    # INTENT: first instantiated point; position without extension
    # BLURB: "Before the point, infrastructure..."

    # Point One
    ...map's technical.md content...

    <<<MAP: Point_Line>>>
    ...
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
MAPS = REPO / "commons" / "maps"
SPINE_FILE = MAPS / "curriculum_spine.json"
SEQ_DIR = MAPS / "sequences"
TOOLS = REPO / "tools"

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

sys.path.insert(0, str(TOOLS))
import text_metrics  # noqa: E402


MARKER_START = "<<<ADA_BUNDLE>>>"
MARKER_END = "<<</ADA_BUNDLE>>>"
MAP_MARKER_RE = "<<<MAP: {name}>>>"


def load_sequence_maps(seq_id: str) -> list[str]:
    """Return the ordered map names in a sequence."""
    seq_path = SEQ_DIR / f"{seq_id}.json"
    if not seq_path.exists():
        raise SystemExit(f"Sequence file not found: {seq_path}")
    try:
        data = json.loads(seq_path.read_text(encoding="utf-8"))
    except Exception as e:
        raise SystemExit(f"Failed to parse {seq_path}: {e}")
    # Sequence JSON shapes vary: either {sequences: {seq_id: {maps: [...]}}}
    # or {maps: [...]}
    seq_data = data
    if isinstance(data.get("sequences"), dict):
        seq_data = data["sequences"].get(seq_id, data)
    maps = seq_data.get("maps", [])
    names: list[str] = []
    for m in maps:
        if isinstance(m, dict):
            n = m.get("map") or m.get("name")
            if n:
                names.append(n)
        elif isinstance(m, str):
            names.append(m)
    return names


def list_all_sequences() -> list[str]:
    """Return the 19 spine sequence ids in curriculum order."""
    if not SPINE_FILE.exists():
        return []
    spine = json.loads(SPINE_FILE.read_text(encoding="utf-8"))
    seqs = spine.get("spine", {}).get("sequences", [])
    out: list[str] = []
    for s in seqs:
        sid = s.get("name") or s.get("id")
        if sid:
            out.append(sid)
    return out


def read_text(path: Path, max_chars: int = 0) -> str:
    if not path.exists():
        return ""
    try:
        t = path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return ""
    if max_chars and len(t) > max_chars:
        return t[:max_chars] + "\n[... truncated ...]"
    return t


def score_file(map_name: str, file_role: str) -> dict[str, Any] | None:
    """Score a single map's file via text_metrics. Returns None if file absent."""
    path = MAPS / map_name / file_role
    if not path.exists():
        return None
    return text_metrics.score_file(path)


def map_section_header(
    map_name: str,
    file_role: str,
    score: dict[str, Any] | None,
    diff_mode: bool,
    with_context: bool,
) -> str:
    """Return the comment block that precedes each map's content."""
    lines: list[str] = []
    lines.append(MAP_MARKER_RE.format(name=map_name))

    if diff_mode and score and score.get("evaluation"):
        ev = score["evaluation"]
        if ev.get("status") == "fail":
            failures = ev.get("failures", [])
            lines.append(f"# FAILURE: {'; '.join(failures)}")
        else:
            lines.append(f"# STATUS: pass")
    elif score is None:
        lines.append(f"# STATUS: missing (file does not exist)")

    if with_context:
        intent = read_text(MAPS / map_name / "intent.md", max_chars=600)
        if intent:
            first_lines = [
                ln for ln in intent.splitlines() if ln.strip()
            ][:4]
            if first_lines:
                lines.append("# INTENT: " + " | ".join(first_lines))
        blurb = read_text(MAPS / map_name / "blurb.md", max_chars=400)
        if blurb:
            b1 = blurb.strip().replace("\n", " ")
            if len(b1) > 220:
                b1 = b1[:220] + "…"
            lines.append(f"# BLURB: {b1}")

    lines.append("")  # blank line before content
    return "\n".join(lines)


def build_bundle(
    sequence_id: str,
    file_role: str,
    only_failing: bool,
    diff_mode: bool,
    with_context: bool,
) -> tuple[str, dict[str, Any]]:
    """Return (bundle_text, stats_dict). Loads the sequence's maps."""
    map_names = load_sequence_maps(sequence_id)
    if not map_names:
        raise SystemExit(f"No maps found in sequence {sequence_id}")
    return build_bundle_from_list(
        sequence_id, file_role, map_names,
        only_failing=only_failing, diff_mode=diff_mode, with_context=with_context,
    )


def build_bundle_from_list(
    sequence_label: str,
    file_role: str,
    map_names: list[str],
    only_failing: bool,
    diff_mode: bool,
    with_context: bool,
) -> tuple[str, dict[str, Any]]:
    """Bundle an arbitrary list of maps. Used by --maps / --maps-file."""
    if not map_names:
        raise SystemExit("No maps provided to bundle")

    included: list[str] = []
    skipped_passing: list[str] = []
    sections: list[str] = []

    for name in map_names:
        path = MAPS / name / file_role
        score = score_file(name, file_role)

        if only_failing and score and score.get("evaluation", {}).get("status") == "pass":
            skipped_passing.append(name)
            continue

        content = read_text(path)
        header = map_section_header(name, file_role, score, diff_mode, with_context)
        if not content and not only_failing:
            # File missing — include the header but mark it
            sections.append(header + "[empty — file does not yet exist]\n")
        elif content:
            sections.append(header + content.rstrip() + "\n")
        else:
            # only_failing set and file missing — include as target for generation
            sections.append(header + "[empty — to generate]\n")
        included.append(name)

    # Front matter
    fm_lines = [
        MARKER_START,
        f"sequence: {sequence_label}",
        f"file: {file_role}",
        f"maps: {len(included)}",
        f"skipped_passing: {len(skipped_passing)}",
        f"created: {time.strftime('%Y-%m-%dT%H:%M:%S')}",
        f"only_failing: {str(only_failing).lower()}",
        f"diff_mode: {str(diff_mode).lower()}",
        f"with_context: {str(with_context).lower()}",
        MARKER_END,
        "",
    ]

    body = "\n".join(sections)
    bundle = "\n".join(fm_lines) + "\n" + body

    stats = {
        "sequence": sequence_label,
        "file": file_role,
        "total_maps_in_sequence": len(map_names),
        "included": included,
        "skipped_passing": skipped_passing,
        "char_count": len(bundle),
        "approx_tokens": len(bundle) // 4,  # rough heuristic
    }
    return bundle, stats


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sequence",
                    help="Sequence id (e.g. primitives, cellularautomata). "
                         "Omit if using --maps or --maps-file.")
    ap.add_argument("--maps",
                    help="Comma-separated map names (alternative to --sequence)")
    ap.add_argument("--maps-file",
                    help="Path to newline-separated map list (alternative to --sequence)")
    ap.add_argument("--file",
                    help="File role (blurb.md, technical.md, critical.md, ...)")
    ap.add_argument("--out",
                    help="Output bundle path (.md recommended)")
    ap.add_argument("--only-failing", action="store_true",
                    help="Skip maps whose file currently passes text_metrics")
    ap.add_argument("--diff-mode", action="store_true",
                    help="Include # FAILURE comment per failing map")
    ap.add_argument("--with-context", action="store_true",
                    help="Include intent.md and blurb.md excerpts per map")
    ap.add_argument("--list-sequences", action="store_true",
                    help="Print the 19 spine sequence ids and exit")
    args = ap.parse_args()

    if args.list_sequences:
        for s in list_all_sequences():
            print(s)
        return 0

    if not args.file or not args.out:
        ap.error("--file and --out are required (unless --list-sequences)")

    if args.sequence:
        label = args.sequence
        map_names = load_sequence_maps(args.sequence)
    elif args.maps:
        label = "custom"
        map_names = [m.strip() for m in args.maps.split(",") if m.strip()]
    elif args.maps_file:
        label = Path(args.maps_file).stem
        map_names = [ln.strip() for ln in
                     Path(args.maps_file).read_text(encoding="utf-8").splitlines()
                     if ln.strip() and not ln.startswith("#")]
    else:
        ap.error("Provide --sequence, --maps, or --maps-file")
        return 2

    bundle, stats = build_bundle_from_list(
        label, args.file, map_names,
        only_failing=args.only_failing,
        diff_mode=args.diff_mode,
        with_context=args.with_context,
    )

    out = Path(args.out)
    if not out.is_absolute():
        out = (REPO / out).resolve()
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(bundle, encoding="utf-8")

    print(f"Bundled {len(stats['included'])}/{stats['total_maps_in_sequence']} "
          f"maps from {stats['sequence']} → {out.relative_to(REPO) if REPO in out.parents else out}")
    print(f"  included: {', '.join(stats['included'][:6])}"
          f"{'...' if len(stats['included']) > 6 else ''}")
    if stats['skipped_passing']:
        print(f"  skipped passing: {len(stats['skipped_passing'])}")
    print(f"  size: {stats['char_count']:,} chars (~{stats['approx_tokens']:,} tokens)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
