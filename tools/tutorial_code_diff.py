#!/usr/bin/env python
"""
tutorial_code_diff.py — diff each spine map's tutorial.md against the codebase.

For every `tutorial.md` across the 179 spine maps, parse the fenced `gdscript`
blocks, extract declared symbols (class_name, func signatures, @export vars,
preload paths), and check whether each symbol is present as a definition
somewhere in `commons/`. Produce a per-map divergence count.

The texts were written as a proposal against the implementation. This tool
tells you where the proposal lies hardest.

Usage::

    # full report
    python tools/tutorial_code_diff.py

    # single map (verbose, prints each symbol)
    python tools/tutorial_code_diff.py --map Chamber_QFEP --verbose

    # json dump
    python tools/tutorial_code_diff.py --format json > doc/reports/TUTORIAL_CODE_DIFF.json

    # markdown sorted by divergence (worst first)
    python tools/tutorial_code_diff.py --format markdown > doc/reports/TUTORIAL_CODE_DIFF.md

Outputs four categories per map:
    class_name: declared in tutorial, defined in code?
    func:       declared in tutorial, defined in code?
    @export:    declared in tutorial, defined in code?
    preload:    path referenced in tutorial, file exists?

Zero network calls, pure-regex parsing. Fast on the whole spine.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
MAPS = REPO / "commons" / "maps"
COMMONS = REPO / "commons"
SPINE_FILE = MAPS / "curriculum_spine.json"
SEQUENCES_DIR = MAPS / "sequences"

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass


# ── Spine loader (copy of text_metrics.load_spine_map_names) ────────────

def load_spine_map_names() -> list[tuple[str, str]]:
    """Return ordered [(sequence_id, map_name), ...] across the spine."""
    if not SPINE_FILE.exists():
        return []
    spine = json.loads(SPINE_FILE.read_text(encoding="utf-8"))
    out: list[tuple[str, str]] = []
    for seq in spine.get("spine", {}).get("sequences", []):
        seq_id = seq.get("name") or seq.get("id")
        if not seq_id:
            continue
        seq_path = SEQUENCES_DIR / f"{seq_id}.json"
        if not seq_path.exists():
            continue
        try:
            data = json.loads(seq_path.read_text(encoding="utf-8"))
        except Exception:
            continue
        seq_data = data.get("sequences", {}).get(seq_id) if isinstance(data.get("sequences"), dict) else data
        maps = seq_data.get("maps", []) if isinstance(seq_data, dict) else []
        for m in maps:
            name = m.get("map") if isinstance(m, dict) else m
            if name:
                out.append((seq_id, name))
    return out


# ── GDScript symbol extraction from fenced tutorial blocks ──────────────

FENCE_RE = re.compile(r"```gdscript\n(.*?)```", re.DOTALL)
CLASS_NAME_RE = re.compile(r"^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)", re.MULTILINE)
FUNC_RE = re.compile(r"^\s*func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(", re.MULTILINE)
EXPORT_RE = re.compile(r"^\s*@export\s+var\s+([A-Za-z_][A-Za-z0-9_]*)", re.MULTILINE)
PRELOAD_RE = re.compile(r'preload\(\s*"(res://[^"]+)"\s*\)')


@dataclass
class Symbols:
    class_names: set[str] = field(default_factory=set)
    funcs: set[str] = field(default_factory=set)
    exports: set[str] = field(default_factory=set)
    preloads: set[str] = field(default_factory=set)

    def extend(self, other: "Symbols") -> None:
        self.class_names |= other.class_names
        self.funcs |= other.funcs
        self.exports |= other.exports
        self.preloads |= other.preloads


# Built-in Godot virtuals and common overrides — not expected to exist as
# unique definitions anywhere specific; they're legitimate overrides.
BUILTIN_FUNCS = {
    "_ready", "_init", "_process", "_physics_process", "_input",
    "_unhandled_input", "_enter_tree", "_exit_tree", "_draw", "_notification",
    "_integrate_forces",
}


def extract_symbols_from_tutorial(path: Path) -> Symbols:
    if not path.exists():
        return Symbols()
    text = path.read_text(encoding="utf-8")
    s = Symbols()
    for block in FENCE_RE.findall(text):
        s.class_names |= set(CLASS_NAME_RE.findall(block))
        s.funcs |= set(FUNC_RE.findall(block))
        s.exports |= set(EXPORT_RE.findall(block))
        s.preloads |= set(PRELOAD_RE.findall(block))
    s.funcs -= BUILTIN_FUNCS
    return s


# ── Codebase index — build once, query many ─────────────────────────────

@dataclass
class CodeIndex:
    class_names: set[str] = field(default_factory=set)
    funcs_by_file: dict[str, set[str]] = field(default_factory=dict)
    exports_by_file: dict[str, set[str]] = field(default_factory=dict)
    all_funcs: set[str] = field(default_factory=set)
    all_exports: set[str] = field(default_factory=set)

    def has_class(self, name: str) -> bool:
        return name in self.class_names

    def has_func(self, name: str) -> bool:
        return name in self.all_funcs

    def has_export(self, name: str) -> bool:
        return name in self.all_exports


def build_code_index(roots: list[Path]) -> CodeIndex:
    idx = CodeIndex()
    for root in roots:
        if not root.exists():
            continue
        for gd in root.rglob("*.gd"):
            try:
                text = gd.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                continue
            cls = set(CLASS_NAME_RE.findall(text))
            fns = set(FUNC_RE.findall(text))
            exps = set(EXPORT_RE.findall(text))
            idx.class_names |= cls
            idx.funcs_by_file[str(gd)] = fns
            idx.exports_by_file[str(gd)] = exps
            idx.all_funcs |= fns
            idx.all_exports |= exps
    return idx


# ── Per-map diff ────────────────────────────────────────────────────────

CHAMBER_PREFIX = "Chamber_"


def is_chamber(map_name: str) -> bool:
    """Chamber_* maps are test harnesses, not shipped content."""
    return map_name.startswith(CHAMBER_PREFIX)


@dataclass
class MapDiff:
    sequence: str
    map: str
    tutorial_exists: bool
    class_names: dict[str, list[str]] = field(default_factory=dict)
    funcs: dict[str, list[str]] = field(default_factory=dict)
    exports: dict[str, list[str]] = field(default_factory=dict)
    preloads: dict[str, list[str]] = field(default_factory=dict)

    @property
    def divergence_count(self) -> int:
        return (
            len(self.class_names.get("missing", []))
            + len(self.funcs.get("missing", []))
            + len(self.exports.get("missing", []))
            + len(self.preloads.get("missing", []))
        )

    @property
    def declared_count(self) -> int:
        return (
            len(self.class_names.get("present", [])) + len(self.class_names.get("missing", []))
            + len(self.funcs.get("present", [])) + len(self.funcs.get("missing", []))
            + len(self.exports.get("present", [])) + len(self.exports.get("missing", []))
            + len(self.preloads.get("present", [])) + len(self.preloads.get("missing", []))
        )


def diff_map(sequence: str, map_name: str, idx: CodeIndex) -> MapDiff:
    tut = MAPS / map_name / "tutorial.md"
    d = MapDiff(sequence=sequence, map=map_name, tutorial_exists=tut.exists())
    if not tut.exists():
        return d
    syms = extract_symbols_from_tutorial(tut)

    def split(declared: set[str], check) -> dict[str, list[str]]:
        present, missing = [], []
        for name in sorted(declared):
            (present if check(name) else missing).append(name)
        return {"present": present, "missing": missing}

    d.class_names = split(syms.class_names, idx.has_class)
    d.funcs = split(syms.funcs, idx.has_func)
    d.exports = split(syms.exports, idx.has_export)
    d.preloads = split(
        syms.preloads,
        lambda p: (REPO / p.removeprefix("res://")).exists(),
    )
    return d


# ── Output formatters ───────────────────────────────────────────────────

def summary_dict(diffs: list[MapDiff]) -> dict[str, Any]:
    total_declared = sum(d.declared_count for d in diffs)
    total_div = sum(d.divergence_count for d in diffs)
    return {
        "maps": len(diffs),
        "total_declared_symbols": total_declared,
        "total_divergences": total_div,
        "match_ratio": round(
            (total_declared - total_div) / max(total_declared, 1), 3
        ),
    }


def _rank_table(rows: list[MapDiff], limit: int = 40) -> None:
    print("| Map | Declared | Missing | class_name | func | @export | preload |")
    print("|---|---:|---:|---:|---:|---:|---:|")
    shown = 0
    for d in rows:
        if d.divergence_count == 0:
            continue
        print(
            f"| {d.map} | {d.declared_count} | {d.divergence_count} "
            f"| {len(d.class_names.get('missing', []))} "
            f"| {len(d.funcs.get('missing', []))} "
            f"| {len(d.exports.get('missing', []))} "
            f"| {len(d.preloads.get('missing', []))} |"
        )
        shown += 1
        if shown >= limit:
            break


def print_markdown(diffs: list[MapDiff]) -> None:
    content = [d for d in diffs if not is_chamber(d.map)]
    chambers = [d for d in diffs if is_chamber(d.map)]

    all_summary = summary_dict(diffs)
    content_summary = summary_dict(content)
    chamber_summary = summary_dict(chambers)

    print("# Tutorial ↔ Code Divergence Report\n")
    print("Chambers (Chamber_*) are test harnesses, not shipped content — their")
    print("mechanics will migrate into regular sequence maps. They appear in a")
    print("separate section below; the primary ranking covers content maps only.\n")

    print("## Overall summary\n")
    print(f"| Set | Maps | Declared | Missing | Match |")
    print(f"|---|---:|---:|---:|---:|")
    print(
        f"| **Content** | {content_summary['maps']} | {content_summary['total_declared_symbols']} "
        f"| {content_summary['total_divergences']} | **{content_summary['match_ratio'] * 100:.1f}%** |"
    )
    print(
        f"| Chambers | {chamber_summary['maps']} | {chamber_summary['total_declared_symbols']} "
        f"| {chamber_summary['total_divergences']} | {chamber_summary['match_ratio'] * 100:.1f}% |"
    )
    print(
        f"| All | {all_summary['maps']} | {all_summary['total_declared_symbols']} "
        f"| {all_summary['total_divergences']} | {all_summary['match_ratio'] * 100:.1f}% |"
    )
    print()

    print("## Content maps — top divergences (worst first)\n")
    _rank_table(sorted(content, key=lambda d: -d.divergence_count))

    clean_content = [d.map for d in content if d.divergence_count == 0 and d.tutorial_exists]
    print(f"\n## Content maps with zero divergence ({len(clean_content)})\n")
    for name in clean_content:
        print(f"- {name}")

    print("\n## Chambers (informational — not a worklist)\n")
    _rank_table(sorted(chambers, key=lambda d: -d.divergence_count), limit=40)


def print_verbose_map(d: MapDiff) -> None:
    print(f"\n# {d.map} ({d.sequence})")
    if not d.tutorial_exists:
        print("  no tutorial.md")
        return
    print(f"  declared={d.declared_count}  missing={d.divergence_count}")
    for label, data in [
        ("class_name", d.class_names),
        ("func", d.funcs),
        ("@export", d.exports),
        ("preload", d.preloads),
    ]:
        present = data.get("present", [])
        missing = data.get("missing", [])
        if not (present or missing):
            continue
        print(f"  {label}:")
        for p in present:
            print(f"    ✓ {p}")
        for m in missing:
            print(f"    ✗ {m}")


# ── CLI ─────────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--map", help="Diff a single map and print verbose")
    ap.add_argument("--verbose", action="store_true", help="Print per-symbol detail")
    ap.add_argument(
        "--format",
        choices=["markdown", "json", "summary"],
        default="markdown",
        help="Output format for full-spine run",
    )
    ap.add_argument(
        "--include-chambers",
        action="store_true",
        help="Include Chamber_* maps in the primary ranking (default: separate section)",
    )
    args = ap.parse_args()

    print("Indexing codebase…", file=sys.stderr)
    idx = build_code_index([COMMONS])
    print(
        f"  classes={len(idx.class_names)}  funcs={len(idx.all_funcs)}  exports={len(idx.all_exports)}",
        file=sys.stderr,
    )

    if args.map:
        # locate sequence for this map
        seq = ""
        for s, m in load_spine_map_names():
            if m == args.map:
                seq = s
                break
        d = diff_map(seq, args.map, idx)
        if args.format == "json":
            print(json.dumps(asdict(d), indent=2))
        else:
            print_verbose_map(d)
        return 0

    spine = load_spine_map_names()
    diffs = [diff_map(seq, name, idx) for seq, name in spine]

    if args.format == "summary":
        content = [d for d in diffs if not is_chamber(d.map)]
        chambers = [d for d in diffs if is_chamber(d.map)]
        print(json.dumps({
            "content": summary_dict(content),
            "chambers": summary_dict(chambers),
            "all": summary_dict(diffs),
        }, indent=2))
    elif args.format == "json":
        out = {
            "summary_all": summary_dict(diffs),
            "summary_content": summary_dict([d for d in diffs if not is_chamber(d.map)]),
            "summary_chambers": summary_dict([d for d in diffs if is_chamber(d.map)]),
            "maps": [dict(asdict(d), is_chamber=is_chamber(d.map)) for d in diffs],
        }
        print(json.dumps(out, indent=2))
    else:
        print_markdown(diffs)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
