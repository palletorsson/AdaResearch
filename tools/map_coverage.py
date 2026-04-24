#!/usr/bin/env python
"""
map_coverage.py — join spine map placements against artifact documentation.

For every map in the 19 spine sequences:

  1. Read map_data.json and extract artifact tokens from the interactables layer.
  2. Join each token against doc/reports/ARTIFACT_DOC_INDEX.json (built by
     tools/artifact_doc_index.py).
  3. Extract text signals: backticked tokens appearing in blurb.md and summary.md.
  4. Compute coverage fields:
       - load-bearing artifacts placed (non-atmospheric)
       - documented / undocumented placed artifacts
       - mentioned in text / silent reinforcement / silent undocumented
       - text-orphan mentions (text backticks a token that's not placed)
  5. Emit markdown + JSON reports.

Run:
    python tools/map_coverage.py                  # full report
    python tools/map_coverage.py --map Point_One  # single map detail
    python tools/map_coverage.py --format summary
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
SPINE_FILE = MAPS / "curriculum_spine.json"
SEQUENCES_DIR = MAPS / "sequences"
REPORTS = REPO / "doc" / "reports"
INDEX_PATH = REPORTS / "ARTIFACT_DOC_INDEX.json"

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass


# ── Spine walker ────────────────────────────────────────────────────────

def load_spine() -> list[tuple[str, str]]:
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


# ── Token extraction ───────────────────────────────────────────────────

def extract_placed_tokens(map_name: str) -> tuple[list[str], dict[str, int]]:
    """Return (unique token list, token → placement count)."""
    path = MAPS / map_name / "map_data.json"
    counts: dict[str, int] = {}
    if not path.exists():
        return [], counts
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return [], counts
    rows = data.get("layers", {}).get("interactables", [])
    if not isinstance(rows, list):
        return [], counts
    for row in rows:
        if not isinstance(row, list):
            continue
        for cell in row:
            if not isinstance(cell, str):
                continue
            c = cell.strip()
            if not c:
                continue
            name = c.split(":")[0].strip()
            if name:
                counts[name] = counts.get(name, 0) + 1
    return sorted(counts.keys()), counts


BACKTICK_RE = re.compile(r"`([A-Za-z_][A-Za-z0-9_]*)`")


def extract_text_mentions(map_name: str) -> dict[str, list[str]]:
    """Return { role: [backticked tokens] } across the six text files."""
    out: dict[str, list[str]] = {}
    for role in ("blurb.md", "summary.md", "intent.md", "critical.md", "technical.md", "tutorial.md"):
        p = MAPS / map_name / role
        if not p.exists():
            continue
        try:
            text = p.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        # Strip fenced code blocks so we only pick prose backticks
        text_no_code = re.sub(r"```.*?```", "", text, flags=re.DOTALL)
        hits = BACKTICK_RE.findall(text_no_code)
        if hits:
            out[role] = sorted(set(hits))
    return out


# ── Index loader ───────────────────────────────────────────────────────

@dataclass
class IndexEntry:
    token: str
    registry: str
    header_kind: str
    is_atmospheric: bool
    script_exists: bool
    scene_exists: bool
    script_path: str = ""
    atmospheric_reason: str = ""


def load_index() -> dict[str, IndexEntry]:
    if not INDEX_PATH.exists():
        print(
            f"ERROR: {INDEX_PATH.relative_to(REPO)} not found. "
            f"Run: python tools/artifact_doc_index.py",
            file=sys.stderr,
        )
        sys.exit(2)
    data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    entries: dict[str, IndexEntry] = {}
    for raw in data.get("entries", []):
        tok = raw.get("token")
        if not tok:
            continue
        entries[tok] = IndexEntry(
            token=tok,
            registry=raw.get("registry", ""),
            header_kind=raw.get("header_kind", "none"),
            is_atmospheric=raw.get("is_atmospheric", False),
            script_exists=raw.get("script_exists", False),
            scene_exists=raw.get("scene_exists", False),
            script_path=raw.get("script_path", ""),
            atmospheric_reason=raw.get("atmospheric_reason", ""),
        )
    return entries


# ── Coverage model ─────────────────────────────────────────────────────

@dataclass
class MapCoverage:
    sequence: str
    map: str
    placed_tokens: list[str] = field(default_factory=list)
    unregistered_tokens: list[str] = field(default_factory=list)
    atmospheric_placed: list[str] = field(default_factory=list)
    load_bearing: list[str] = field(default_factory=list)
    documented: list[str] = field(default_factory=list)  # identity or prose
    identity_docs: list[str] = field(default_factory=list)
    undocumented: list[str] = field(default_factory=list)  # placeholder or none
    missing_script: list[str] = field(default_factory=list)
    missing_scene: list[str] = field(default_factory=list)
    mentioned_in_text: list[str] = field(default_factory=list)  # backticked somewhere
    silent_reinforcement: list[str] = field(default_factory=list)
    silent_undocumented: list[str] = field(default_factory=list)
    text_orphans: list[str] = field(default_factory=list)  # backticked but not placed
    text_mentions_by_role: dict[str, list[str]] = field(default_factory=dict)

    @property
    def coverage_score(self) -> float:
        """Fraction of load-bearing tokens that are either documented or mentioned."""
        if not self.load_bearing:
            return 1.0
        good = set(self.documented) | set(self.mentioned_in_text)
        good &= set(self.load_bearing)
        return round(len(good) / len(self.load_bearing), 3)

    @property
    def doc_coverage(self) -> float:
        """Fraction of load-bearing tokens that have identity or prose headers."""
        if not self.load_bearing:
            return 1.0
        return round(len(self.documented) / len(self.load_bearing), 3)


def diff_map(sequence: str, map_name: str, index: dict[str, IndexEntry]) -> MapCoverage:
    cov = MapCoverage(sequence=sequence, map=map_name)
    tokens, _counts = extract_placed_tokens(map_name)
    cov.placed_tokens = tokens
    for t in tokens:
        idx = index.get(t)
        if idx is None:
            cov.unregistered_tokens.append(t)
            continue
        if not idx.scene_exists:
            cov.missing_scene.append(t)
            continue
        if not idx.script_exists:
            cov.missing_script.append(t)
        if idx.is_atmospheric:
            cov.atmospheric_placed.append(t)
            continue
        cov.load_bearing.append(t)
        if idx.header_kind in ("identity", "prose", "registry"):
            cov.documented.append(t)
            if idx.header_kind == "identity":
                cov.identity_docs.append(t)
        else:
            cov.undocumented.append(t)

    mentions = extract_text_mentions(map_name)
    cov.text_mentions_by_role = mentions
    all_mentioned = set()
    for role_tokens in mentions.values():
        all_mentioned.update(role_tokens)
    # Restrict mentions-of-interest to registered artifact tokens — backticked
    # words that aren't artifact tokens (e.g. `gdscript` keywords) don't count.
    mentioned_registered = [t for t in sorted(all_mentioned) if t in index]
    cov.mentioned_in_text = [t for t in mentioned_registered if t in cov.load_bearing]

    placed_set = set(cov.load_bearing) | set(cov.atmospheric_placed)
    cov.silent_reinforcement = sorted(
        t for t in cov.documented if t not in all_mentioned
    )
    cov.silent_undocumented = sorted(
        t for t in cov.undocumented if t not in all_mentioned
    )
    # Text orphan: backticked in text, registered as artifact, but not placed
    # in this map's interactables layer (load-bearing OR atmospheric).
    cov.text_orphans = sorted(
        t for t in mentioned_registered if t not in placed_set
    )
    return cov


# ── Output ─────────────────────────────────────────────────────────────

def summarize(coverages: list[MapCoverage]) -> dict[str, Any]:
    total_maps = len(coverages)
    perfect = sum(1 for c in coverages if c.coverage_score >= 0.999)
    zero_load_bearing = sum(1 for c in coverages if not c.load_bearing)
    avg_score = sum(c.coverage_score for c in coverages) / max(total_maps, 1)
    avg_doc = sum(c.doc_coverage for c in coverages) / max(total_maps, 1)
    total_load = sum(len(c.load_bearing) for c in coverages)
    total_doc = sum(len(c.documented) for c in coverages)
    total_undoc = sum(len(c.undocumented) for c in coverages)
    total_mentioned = sum(len(c.mentioned_in_text) for c in coverages)
    total_silent_reinf = sum(len(c.silent_reinforcement) for c in coverages)
    total_silent_undoc = sum(len(c.silent_undocumented) for c in coverages)
    total_orphans = sum(len(c.text_orphans) for c in coverages)
    total_unreg = sum(len(c.unregistered_tokens) for c in coverages)
    return {
        "maps": total_maps,
        "perfect_coverage": perfect,
        "maps_with_no_placements": zero_load_bearing,
        "avg_coverage_score": round(avg_score, 3),
        "avg_doc_coverage": round(avg_doc, 3),
        "totals": {
            "load_bearing_placements": total_load,
            "documented_placements": total_doc,
            "undocumented_placements": total_undoc,
            "mentioned_in_text": total_mentioned,
            "silent_reinforcement": total_silent_reinf,
            "silent_undocumented": total_silent_undoc,
            "text_orphans": total_orphans,
            "unregistered_tokens": total_unreg,
        },
    }


def print_markdown(coverages: list[MapCoverage], summary: dict[str, Any]) -> None:
    t = summary["totals"]
    print("# Map Coverage Report\n")
    print("Joining spine map placements against `ARTIFACT_DOC_INDEX.json`.\n")
    print(f"- Maps scanned: **{summary['maps']}**")
    print(f"- Maps with perfect coverage (score = 1.0): **{summary['perfect_coverage']}**")
    print(f"- Maps with no load-bearing placements: **{summary['maps_with_no_placements']}**")
    print(f"- Average coverage score: **{summary['avg_coverage_score'] * 100:.1f}%**")
    print(f"  (documented-or-mentioned / load-bearing)")
    print(f"- Average doc-only coverage: **{summary['avg_doc_coverage'] * 100:.1f}%**\n")

    print("## Placement totals\n")
    print(f"- Load-bearing placements across all maps: **{t['load_bearing_placements']}**")
    print(f"- Documented placements: **{t['documented_placements']}**")
    print(f"- Undocumented placements (placeholder / none): **{t['undocumented_placements']}**")
    print(f"- Placements mentioned by backtick in any text: **{t['mentioned_in_text']}**")
    print(f"- Silent reinforcement (documented, not mentioned): **{t['silent_reinforcement']}**")
    print(f"- Silent undocumented (not documented, not mentioned — concerning): **{t['silent_undocumented']}**")
    print(f"- Text orphans (backticked but not placed): **{t['text_orphans']}**")
    print(f"- Unregistered placed tokens: **{t['unregistered_tokens']}**\n")

    # Coverage < 1.0, worst first
    troubled = [c for c in coverages if c.coverage_score < 1.0 and c.load_bearing]
    troubled.sort(key=lambda c: (c.coverage_score, -len(c.load_bearing)))

    if troubled:
        print("## Maps with incomplete coverage (worst first)\n")
        print("| Map | Placed | Documented | Mentioned | Silent-undoc | Score |")
        print("|---|---:|---:|---:|---:|---:|")
        for c in troubled[:50]:
            print(
                f"| {c.map} | {len(c.load_bearing)} | {len(c.documented)} "
                f"| {len(c.mentioned_in_text)} | {len(c.silent_undocumented)} "
                f"| {c.coverage_score * 100:.0f}% |"
            )

    # Text orphans are a different kind of issue — text promises things not placed
    with_orphans = [c for c in coverages if c.text_orphans]
    if with_orphans:
        with_orphans.sort(key=lambda c: -len(c.text_orphans))
        print(f"\n## Maps with text orphans — text backticks artifacts not placed ({len(with_orphans)})\n")
        for c in with_orphans[:30]:
            print(f"- **{c.map}** → {', '.join('`' + t + '`' for t in c.text_orphans[:8])}")
            if len(c.text_orphans) > 8:
                print(f"  (+{len(c.text_orphans) - 8} more)")

    # Maps with unregistered tokens
    with_unreg = [c for c in coverages if c.unregistered_tokens]
    if with_unreg:
        print(f"\n## Maps with unregistered placed tokens ({len(with_unreg)})\n")
        for c in with_unreg[:30]:
            print(f"- **{c.map}** → {', '.join('`' + t + '`' for t in c.unregistered_tokens[:8])}")


def print_map_detail(c: MapCoverage) -> None:
    print(f"\n# {c.map} ({c.sequence})")
    print(f"  coverage score: {c.coverage_score * 100:.0f}%  (doc-only: {c.doc_coverage * 100:.0f}%)")
    print(f"  placed tokens: {len(c.placed_tokens)}  load-bearing: {len(c.load_bearing)}  atmospheric: {len(c.atmospheric_placed)}")
    if c.unregistered_tokens:
        print(f"  unregistered: {c.unregistered_tokens}")
    if c.missing_scene:
        print(f"  missing scene: {c.missing_scene}")
    if c.missing_script:
        print(f"  missing script: {c.missing_script}")
    print()
    print("  load-bearing placements:")
    for t in c.load_bearing:
        flags = []
        if t in c.identity_docs:
            flags.append("identity")
        elif t in c.documented:
            flags.append("prose")
        else:
            flags.append("UNDOCUMENTED")
        if t in c.mentioned_in_text:
            flags.append("mentioned")
        elif t in c.documented:
            flags.append("silent-reinforcement")
        else:
            flags.append("silent-UNDOC")
        print(f"    {t:45s} [{', '.join(flags)}]")
    if c.atmospheric_placed:
        print(f"\n  atmospheric (filtered): {c.atmospheric_placed}")
    if c.text_orphans:
        print(f"\n  text orphans (backticked, not placed): {c.text_orphans}")
    if c.text_mentions_by_role:
        print("\n  text mentions by role:")
        for role, toks in c.text_mentions_by_role.items():
            print(f"    {role}: {toks}")


# ── CLI ────────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--map", help="Inspect a single map")
    ap.add_argument(
        "--format",
        choices=["markdown", "json", "summary"],
        default="markdown",
    )
    ap.add_argument("--out-dir", default=str(REPORTS))
    args = ap.parse_args()

    index = load_index()

    if args.map:
        seq = ""
        for s, m in load_spine():
            if m == args.map:
                seq = s
                break
        cov = diff_map(seq, args.map, index)
        if args.format == "json":
            print(json.dumps(asdict(cov), indent=2))
        else:
            print_map_detail(cov)
        return 0

    spine = load_spine()
    coverages = [diff_map(seq, name, index) for seq, name in spine]
    summary = summarize(coverages)

    if args.format == "summary":
        print(json.dumps(summary, indent=2))
        return 0
    if args.format == "json":
        print(json.dumps({
            "summary": summary,
            "maps": [asdict(c) for c in coverages],
        }, indent=2))
        return 0

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "MAP_COVERAGE.json").write_text(
        json.dumps({
            "summary": summary,
            "maps": [asdict(c) for c in coverages],
        }, indent=2),
        encoding="utf-8",
    )
    print_markdown(coverages, summary)
    print(f"\n_JSON sidecar: {(out_dir / 'MAP_COVERAGE.json').relative_to(REPO)}_", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
