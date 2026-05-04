#!/usr/bin/env python3
"""Extract map grammar from the corpus.

Two grammars are at work in Ada Research:

1. The *formal* grammar in `commons/artifacts/grammar_operations.json` —
   19 form_types and ~50 operations gated by sequence order. This is the
   curriculum's promise: the player learns one operation per sequence.

2. The *latent* grammar in the 791 existing maps — patterns the authors
   actually used (corridor widths, room shapes, plinth placements,
   symmetries). This script mines (2) and aligns each finding to (1).

Output:
    doc/MAP_GRAMMAR.md          — human-readable report
    doc/reports/map_grammar.json — machine-readable findings
"""
from __future__ import annotations

import json
from collections import Counter, defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MAPS_DIR = REPO / "commons" / "maps"
GRAMMAR_OPS = REPO / "commons" / "artifacts" / "grammar_operations.json"
REPORT_MD = REPO / "doc" / "MAP_GRAMMAR.md"
REPORT_JSON = REPO / "doc" / "reports" / "map_grammar.json"

# Skip 3x3 windows that contain ONLY voids — they aren't structure.
def is_interesting(window: tuple[int, ...]) -> bool:
    return any(v >= 1 for v in window)


def cell_height(cell) -> int:
    if isinstance(cell, int): return cell
    if isinstance(cell, str):
        try: return int(cell)
        except Exception: return 0
    return 0


def load_formal_grammar() -> dict:
    if not GRAMMAR_OPS.exists():
        return {}
    return json.loads(GRAMMAR_OPS.read_text(encoding="utf-8", errors="replace"))


def map_signature(structure: list[list]) -> dict:
    """Distill a single map down to: size, height histogram, symmetry
    booleans, corridor-width estimate, room-count estimate."""
    rows = len(structure)
    cols = max((len(r) for r in structure), default=0)
    if rows == 0 or cols == 0:
        return {"rows": 0, "cols": 0, "heights": {}, "symmetries": []}
    grid = [[cell_height(structure[r][c]) if c < len(structure[r]) else 0
             for c in range(cols)] for r in range(rows)]

    # Height histogram.
    hist: Counter[int] = Counter()
    for row in grid:
        for v in row: hist[v] += 1

    # Symmetry detection — exact match within a small tolerance.
    def sym_score(a, b) -> float:
        if not a or not b: return 0.0
        same = sum(1 for r in range(len(a))
                   for c in range(len(a[0]))
                   if a[r][c] == b[r][c])
        return same / (len(a) * len(a[0]))

    h_flip = [list(reversed(row)) for row in grid]
    v_flip = list(reversed(grid))
    rot180 = [list(reversed(row)) for row in reversed(grid)]
    syms = {
        "horizontal_flip": round(sym_score(grid, h_flip), 3),
        "vertical_flip": round(sym_score(grid, v_flip), 3),
        "rotate_180": round(sym_score(grid, rot180), 3),
    }

    # Corridor-width estimate: average run-length of consecutive walkable
    # cells (h>=1) per row, capped at the row width.
    runs: list[int] = []
    for row in grid:
        run = 0
        for v in row:
            if v >= 1:
                run += 1
            else:
                if run > 0: runs.append(run)
                run = 0
        if run > 0: runs.append(run)
    avg_run = (sum(runs) / len(runs)) if runs else 0.0

    # 3x3 height patterns (for n-gram mining outside this fn).
    return {
        "rows": rows, "cols": cols,
        "heights": dict(hist),
        "symmetries": syms,
        "avg_walkable_run": round(avg_run, 2),
        "n_runs": len(runs),
    }


def collect_3x3_patterns(structure: list[list], counter: Counter) -> None:
    rows = len(structure)
    cols = max((len(r) for r in structure), default=0)
    if rows < 3 or cols < 3: return
    grid = [[cell_height(structure[r][c]) if c < len(structure[r]) else 0
             for c in range(cols)] for r in range(rows)]
    for r in range(rows - 2):
        for c in range(cols - 2):
            window = tuple(grid[r + dr][c + dc]
                           for dr in range(3) for dc in range(3))
            if is_interesting(window):
                counter[window] += 1


def detect_form_type(sig: dict, top_patterns: list[tuple[tuple, int]]) -> list[str]:
    """Heuristic: tag a map with form_type labels from the formal grammar
    based on its signature. A map can carry several form_types — they're
    additive, not exclusive."""
    tags: list[str] = []
    heights = sig.get("heights", {})
    syms = sig.get("symmetries", {})
    avg_run = sig.get("avg_walkable_run", 0)

    # Lattice — high regularity, multiple equal-length runs.
    if sig.get("n_runs", 0) > 8 and abs(avg_run - round(avg_run)) < 0.5:
        tags.append("lattice")
    # Pattern — symmetric.
    if any(v > 0.85 for v in syms.values()):
        tags.append("pattern")
    # Solid — predominantly one walkable height.
    walkable_total = sum(v for h, v in heights.items() if h >= 1)
    if walkable_total > 0:
        biggest = max(((h, v) for h, v in heights.items() if h >= 1),
                      key=lambda x: x[1], default=(0, 0))
        if biggest[1] / walkable_total > 0.85:
            tags.append("solid")
    # Terrain — many distinct heights present.
    distinct = len([h for h, v in heights.items() if h >= 1 and v > 1])
    if distinct >= 3:
        tags.append("terrain")
    return tags


def render_pattern_ascii(pattern: tuple[int, ...]) -> str:
    glyphs = {0: ".", 1: " ", 2: "·", 3: "▫", 4: "█", 5: "▓"}
    return "\n".join(
        "".join(glyphs.get(pattern[r * 3 + c], "?") for c in range(3))
        for r in range(3)
    )


def main() -> int:
    formal = load_formal_grammar()
    form_types = formal.get("form_types", {})
    sequences = formal.get("sequences", {})

    sigs: list[tuple[str, dict, list[str]]] = []
    pattern_counter: Counter = Counter()
    sym_distribution = {"horizontal_flip": [], "vertical_flip": [], "rotate_180": []}
    height_use_total: Counter[int] = Counter()
    form_type_counts: Counter[str] = Counter()

    for map_dir in sorted(MAPS_DIR.iterdir()):
        if not map_dir.is_dir(): continue
        if map_dir.name == "sequences": continue
        md_path = map_dir / "map_data.json"
        if not md_path.exists(): continue
        try:
            data = json.loads(md_path.read_text(encoding="utf-8", errors="replace"))
        except Exception:
            continue
        structure = data.get("layers", {}).get("structure", [])
        if not structure: continue

        sig = map_signature(structure)
        if sig["rows"] == 0: continue
        collect_3x3_patterns(structure, pattern_counter)
        for k in sym_distribution:
            sym_distribution[k].append(sig["symmetries"][k])
        for h, v in sig["heights"].items():
            height_use_total[h] += v
        # We pass empty top_patterns here; tagging only uses sig.
        tags = detect_form_type(sig, [])
        for t in tags: form_type_counts[t] += 1
        sigs.append((map_dir.name, sig, tags))

    # Top n-grams.
    top_patterns = pattern_counter.most_common(20)

    # Average symmetry across the corpus.
    sym_avg = {k: round(sum(v) / len(v), 3) if v else 0.0
               for k, v in sym_distribution.items()}

    # Sequences — operations and form_types in order.
    seq_table: list[tuple[int, str, list[str], list[str]]] = []
    for seq_id, seq in sequences.items():
        order = int(seq.get("order", 999))
        ops = list((seq.get("operations") or {}).keys())
        outputs = sorted({op_def.get("output") for op_def in (seq.get("operations") or {}).values()
                          if op_def.get("output")})
        seq_table.append((order, seq_id, ops, outputs))
    seq_table.sort()

    # ── JSON report ─────────────────────────────────────────────────
    REPORT_JSON.parent.mkdir(parents=True, exist_ok=True)
    REPORT_JSON.write_text(json.dumps({
        "n_maps": len(sigs),
        "height_use_total": {str(k): v for k, v in height_use_total.items()},
        "symmetry_avg": sym_avg,
        "form_type_counts": dict(form_type_counts),
        "top_3x3_patterns": [
            {"pattern": list(p), "count": c} for p, c in top_patterns
        ],
        "formal_grammar_form_types": list(form_types.keys()),
        "formal_grammar_sequences": [
            {"order": o, "id": sid, "ops": ops, "outputs": outs}
            for (o, sid, ops, outs) in seq_table
        ],
    }, indent=2), encoding="utf-8")

    # ── Markdown report ───────────────────────────────────────────────
    lines: list[str] = []
    lines.append("# Map Grammar\n")
    lines.append(f"> Auto-generated from {len(sigs)} maps + the formal grammar in `commons/artifacts/grammar_operations.json`. Run `python tools/extract_map_grammar.py` to refresh.\n\n")

    lines.append("## The two grammars\n\n")
    lines.append("Ada Research carries **two grammars at once**:\n\n")
    lines.append("1. **Formal grammar** — declared in `commons/artifacts/grammar_operations.json` and enforced at runtime by `GrammarOperationsManager`. Each sequence unlocks operations that produce form types. The biome can only manifest forms whose form_type is unlocked at the player's current sequence.\n\n")
    lines.append("2. **Latent grammar** — the patterns the 791 existing maps actually use. Mined from the structure layer: 3×3 height n-grams, symmetries, height histograms, corridor widths.\n\n")
    lines.append("This document brings them into one view so generation strategies (auto-research) can respect both.\n\n")

    lines.append("## Formal grammar — sequence ladder\n\n")
    lines.append("Each row is a sequence. Operations unlock cumulatively; outputs become available form_types from that point on.\n\n")
    lines.append("| order | sequence | operations | outputs |\n|---:|---|---|---|\n")
    for o, sid, ops, outs in seq_table[:25]:
        lines.append(f"| {o} | `{sid}` | {', '.join(f'`{op}`' for op in ops[:6])}{'...' if len(ops)>6 else ''} | {', '.join(f'`{out}`' for out in outs)} |\n")
    if len(seq_table) > 25:
        lines.append(f"| … | _{len(seq_table)-25} more_ | | |\n")
    lines.append("\n")

    lines.append("## Form types declared\n\n")
    for ft, ftd in form_types.items():
        emerges = ftd.get("emerges_in", "?")
        lines.append(f"- **`{ft}`** — {ftd.get('description', '')} *(emerges in `{emerges}`)*\n")
    lines.append("\n")

    lines.append("## Latent grammar — what the corpus actually does\n\n")
    lines.append(f"### Height histogram across all {len(sigs)} maps\n\n")
    total_cells = sum(height_use_total.values())
    lines.append("| height | meaning | cells | % |\n|---:|---|---:|---:|\n")
    meanings = {0: "void", 1: "floor", 2: "wall (h2)", 3: "wall (h3)", 4: "wall (h4)", 5: "pillar (h5)"}
    for h in sorted(height_use_total.keys()):
        v = height_use_total[h]
        pct = (v / total_cells * 100) if total_cells else 0
        lines.append(f"| {h} | {meanings.get(h, '?')} | {v:,} | {pct:.1f}% |\n")
    lines.append("\n")

    lines.append("### Symmetry — average score (1.0 = exact symmetry)\n\n")
    lines.append("| axis | mean | reading |\n|---|---:|---|\n")
    readings = {
        "horizontal_flip": "mirror left↔right",
        "vertical_flip":   "mirror top↔bottom",
        "rotate_180":      "180° rotational",
    }
    for k, v in sym_avg.items():
        lines.append(f"| {k.replace('_', ' ')} | {v} | {readings.get(k, '')} |\n")
    lines.append("\nMost maps are *not* perfectly symmetric — values around 0.5–0.7 indicate partial regularity, not full mirror symmetry.\n\n")

    lines.append("### Form-type tags assigned (heuristic)\n\n")
    lines.append("| form_type | maps tagged |\n|---|---:|\n")
    for ft, c in sorted(form_type_counts.items(), key=lambda x: -x[1]):
        lines.append(f"| `{ft}` | {c} |\n")
    lines.append("\n")

    lines.append("### Top 3×3 height patterns\n\n")
    lines.append("Most-frequent 3×3 windows of structure heights across the corpus. These ARE the recurring motifs — pieces of the latent grammar a strategy could replay.\n\n")
    lines.append("```\n")
    for pat, count in top_patterns[:12]:
        lines.append(f"# count={count}\n")
        lines.append(render_pattern_ascii(pat))
        lines.append("\n\n")
    lines.append("```\n\n")
    lines.append("Glyphs: `.` void, ` ` floor, `·` wall(h2), `▫` wall(h3), `█` wall(h4), `▓` pillar(h5)\n\n")

    lines.append("## Where this leads\n\n")
    lines.append("- A `corpus_grammar` strategy can sample from the top 3×3 patterns + paste them with overlap → maps that *look like* the existing corpus by construction.\n")
    lines.append("- A `gated_grammar` strategy can refuse to use a form_type whose required sequence isn't unlocked yet — keeps generated maps **honest** to the curriculum (the same gating `BiomeRingComponent` applies to foliage).\n")
    lines.append("- The form_type counts above tell you which form_types the corpus is *short on* — places the generative strategies should cover.\n")

    REPORT_MD.write_text("".join(lines), encoding="utf-8")
    print(f"wrote {REPORT_MD.relative_to(REPO)}")
    print(f"wrote {REPORT_JSON.relative_to(REPO)}")
    print(f"\n=== summary ===")
    print(f"  maps analysed:     {len(sigs)}")
    print(f"  height cells:      {sum(height_use_total.values()):,}")
    print(f"  unique 3x3 motifs: {len(pattern_counter):,}")
    print(f"  sym horiz mean:    {sym_avg['horizontal_flip']}")
    print(f"  form_types tagged: {dict(form_type_counts)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
