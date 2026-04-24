#!/usr/bin/env python
"""Render MAP_COVERAGE.json as a visual SVG grid.

Each spine map is a small square coloured by its coverage score.
Sequences are stacked as rows with their name on the left and a
map-count badge on the right.

Output: doc/reports/coverage_grid.svg (and an optional --copy-to
for landing the asset in the encyclopedia's public/blog dir).
"""
from __future__ import annotations
import argparse, json, sys, shutil
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
COVERAGE_JSON = REPO / "doc" / "reports" / "MAP_COVERAGE.json"
OUT_PATH = REPO / "doc" / "reports" / "coverage_grid.svg"

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass


def score_fill(score: float) -> str:
    if score >= 0.999: return "#10b981"  # emerald-500
    if score >= 0.9:   return "#84cc16"  # lime-500
    if score >= 0.7:   return "#f59e0b"  # amber-500
    if score >= 0.4:   return "#f97316"  # orange-500
    return "#f43f5e"                      # rose-500


def compute_score(m: dict) -> float:
    lb = m.get("load_bearing", [])
    if not lb: return 1.0
    good = set(m.get("documented", [])) | set(m.get("mentioned_in_text", []))
    good &= set(lb)
    return len(good) / len(lb)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--copy-to", help="Optional path to copy SVG into (e.g. encyclopedia's public/blog)")
    args = ap.parse_args()

    data = json.loads(COVERAGE_JSON.read_text(encoding="utf-8"))
    maps = data["maps"]
    summary = data["summary"]

    # Group by sequence preserving first-appearance order
    seq_order: list[str] = []
    by_seq: dict[str, list[dict]] = {}
    for m in maps:
        s = m["sequence"]
        if s not in by_seq:
            by_seq[s] = []
            seq_order.append(s)
        by_seq[s].append(m)

    cell = 22
    gap = 4
    pad_left = 220
    pad_top = 90
    pad_right = 120
    pad_bottom = 60

    max_maps_in_seq = max(len(v) for v in by_seq.values())
    width = pad_left + max_maps_in_seq * (cell + gap) + pad_right
    height = pad_top + len(seq_order) * (cell + gap) + pad_bottom

    out: list[str] = []
    out.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" '
               f'font-family="ui-monospace,Consolas,monospace" font-size="11">')
    out.append('<style>'
               '.seq{fill:#52525b;font-size:12px;font-weight:600}'
               '.count{fill:#a1a1aa;font-size:10px}'
               '.title{fill:#18181b;font-size:22px;font-weight:700}'
               '.sub{fill:#71717a;font-size:13px}'
               '.legend{fill:#52525b;font-size:11px}'
               'rect.cell{stroke:rgba(0,0,0,0.08);stroke-width:0.5}'
               '</style>')
    out.append('<rect width="100%" height="100%" fill="white"/>')

    # Header
    out.append(f'<text x="{pad_left}" y="34" class="title">'
               f'Map Coverage — {summary["perfect_coverage"]} / {summary["maps"]} perfect</text>')
    out.append(f'<text x="{pad_left}" y="56" class="sub">'
               f'{summary["totals"]["load_bearing_placements"]} load-bearing placements · '
               f'{summary["totals"]["documented_placements"]} documented · '
               f'avg {summary["avg_coverage_score"] * 100:.1f}% coverage</text>')

    # Legend (top right)
    legend_x = width - pad_right + 10
    legend_y = 30
    legend = [
        ("100%", "#10b981"),
        ("90%+", "#84cc16"),
        ("70%+", "#f59e0b"),
        ("40%+", "#f97316"),
        ("<40%", "#f43f5e"),
    ]
    for i, (label, color) in enumerate(legend):
        y = legend_y + i * 16
        out.append(f'<rect x="{legend_x}" y="{y}" width="12" height="12" fill="{color}" rx="2"/>')
        out.append(f'<text x="{legend_x + 18}" y="{y + 10}" class="legend">{label}</text>')

    # Rows
    for i, seq in enumerate(seq_order):
        row_y = pad_top + i * (cell + gap)
        label_y = row_y + cell * 0.72
        out.append(f'<text x="{pad_left - 14}" y="{label_y}" class="seq" text-anchor="end">{seq}</text>')
        rows = by_seq[seq]
        for j, m in enumerate(rows):
            s = compute_score(m)
            x = pad_left + j * (cell + gap)
            fill = score_fill(s)
            title = f"{m['map']} — {int(s * 100)}% coverage, {len(m['load_bearing'])} placed"
            out.append(f'<rect class="cell" x="{x}" y="{row_y}" width="{cell}" height="{cell}" rx="3" fill="{fill}">'
                       f'<title>{title}</title></rect>')
        count_x = pad_left + max_maps_in_seq * (cell + gap) + 6
        out.append(f'<text x="{count_x}" y="{label_y}" class="count">{len(rows)}</text>')

    # Footer — what edges are closed
    footer_y = pad_top + len(seq_order) * (cell + gap) + 28
    out.append(f'<text x="{pad_left}" y="{footer_y}" class="sub">'
               f'TEXT ↔ ARTIFACT · ARTIFACT ↔ MAP · MAP ↔ CONCEPT · all mechanically closed</text>')

    out.append('</svg>')
    svg = "\n".join(out)
    OUT_PATH.write_text(svg, encoding="utf-8")
    print(f"Wrote {OUT_PATH.relative_to(REPO)}  ({len(svg)} chars)")

    if args.copy_to:
        target = Path(args.copy_to)
        if target.is_dir():
            target = target / "coverage_grid.svg"
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy(OUT_PATH, target)
        print(f"Copied to {target}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
