"""tools/window_clusterer.py — Phase B of the timeline-driven map system.

Reads timeline.json, clusters sorted artifacts into windows = maps. Each
window respects:
  - sequence boundary (artifacts from different sequences → different maps)
  - cap on artifacts per map (default 6)
  - cap on total footprint per map (default 60 cells)

For each window: emit (id, sequence, phase, t_range, artifacts, proposed_size).
The proposed_size is sized to fit the window's total footprint plus walkable
clearance — feeds directly into grow_map.py's bounding box.

Run:
  python tools/window_clusterer.py
  python tools/window_clusterer.py --max-artifacts=8 --max-footprint=72
  python tools/window_clusterer.py --include-non-spine    # also window non-spine sequences

Output:
  doc/placement_research/windows.json
  doc/placement_research/windows.svg
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from collections import defaultdict
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
TIMELINE_PATH = ROOT / "doc" / "placement_research" / "timeline.json"
REGISTRY_DIR = ROOT / "commons" / "artifacts" / "registry"
OUT_DIR = ROOT / "doc" / "placement_research"
WINDOW_OVERRIDES_PATH = OUT_DIR / "window_overrides.json"

PHASE_COLORS = {
    "F_order":      "#3A7BFF",
    "oscillation":  "#7DFFA8",
    "E_entropy":    "#F4A261",
    "lambda_edge":  "#E63946",
    "integration":  "#9B5DE5",
    "relation":     "#FBE38A",
    "synthesis":    "#FFFFFF",
}


# ─────────────────────────────────────────────────────────────────────
# Footprint lookup
# ─────────────────────────────────────────────────────────────────────

def load_footprints() -> dict[str, int]:
    """Build {lookup_name: footprint_cells} from the registry."""
    out: dict[str, int] = {}
    def walk(node):
        if isinstance(node, dict):
            if "lookup_name" in node:
                sn = node.get("spatial_needs") or {}
                out[node["lookup_name"]] = int(sn.get("footprint_cells", 1))
            for v in node.values():
                walk(v)
        elif isinstance(node, list):
            for v in node:
                walk(v)
    for f in REGISTRY_DIR.glob("*.json"):
        try:
            with open(f, "r", encoding="utf-8") as fp:
                walk(json.load(fp))
        except (json.JSONDecodeError, OSError):
            continue
    return out


# ─────────────────────────────────────────────────────────────────────
# Window clustering — greedy with sequence-boundary respect
# ─────────────────────────────────────────────────────────────────────

def cluster_windows(timeline: dict, footprints: dict[str, int],
                    max_artifacts: int = 6, max_footprint: int = 60,
                    include_non_spine: bool = False,
                    overrides: dict[str, dict] | None = None) -> list[dict]:
    """Walk sorted-by-t artifacts, group into windows respecting sequence
    boundaries + caps."""
    positions = timeline["positions"]
    seq_positions = timeline["sequence_positions"]

    # Group artifacts by sequence
    by_seq: dict[str, list[tuple[float, str]]] = defaultdict(list)
    for name, info in positions.items():
        s = info["sequence"]
        if s == "unplaced":
            continue
        if not include_non_spine and not seq_positions.get(s, {}).get("in_spine"):
            continue
        by_seq[s].append((info["t"], name))

    # Sort by t within each sequence
    for s in by_seq:
        by_seq[s].sort()

    # Order sequences by their spine order
    seq_order = sorted(
        by_seq.keys(),
        key=lambda s: (
            0 if seq_positions.get(s, {}).get("in_spine") else 1,
            seq_positions.get(s, {}).get("order", 999),
        ),
    )

    windows: list[dict] = []
    for s in seq_order:
        artifacts = by_seq[s]
        info = seq_positions.get(s, {})
        phase = info.get("phase", "synthesis")
        current: list[tuple[float, str, int]] = []
        current_footprint = 0
        window_index = 0
        for (t, name) in artifacts:
            fp = footprints.get(name, 1)
            # Check if adding this artifact would exceed caps
            if current and (
                len(current) >= max_artifacts
                or current_footprint + fp > max_footprint
            ):
                windows.append(_make_window(s, phase, window_index, current, overrides))
                window_index += 1
                current = []
                current_footprint = 0
            current.append((t, name, fp))
            current_footprint += fp
        if current:
            windows.append(_make_window(s, phase, window_index, current))

    return windows


def load_window_overrides() -> dict[str, dict]:
    """Load manual window-size overrides. Format:
       { "primitives_w0": {"width": 12, "depth": 8, "max_height": 3}, ... }
    Keys starting with '_' are ignored (notes)."""
    if not WINDOW_OVERRIDES_PATH.exists():
        return {}
    try:
        with open(WINDOW_OVERRIDES_PATH, "r", encoding="utf-8") as f:
            raw = json.load(f)
        out: dict[str, dict] = {}
        for k, v in raw.items():
            if k.startswith("_"): continue
            if isinstance(v, dict):
                clean = {kk: int(vv) for kk, vv in v.items()
                         if kk in ("width", "depth", "max_height") and isinstance(vv, (int, float))}
                if clean:
                    out[k] = clean
        return out
    except (json.JSONDecodeError, OSError, ValueError):
        return {}


def _make_window(sequence: str, phase: str, idx: int,
                 artifacts: list[tuple[float, str, int]],
                 overrides: dict[str, dict] | None = None) -> dict:
    """Build a window dict from its artifacts list. Applies size override
    if window_id is in overrides."""
    total_fp = sum(fp for _, _, fp in artifacts)
    n = len(artifacts)
    # Default bounding box: sized to fit total footprint + walkable clearance
    target_cells = max(36, int(total_fp * 4))
    w = max(6, int(math.ceil(math.sqrt(target_cells * 1.5))))
    d = max(5, int(math.ceil(target_cells / w)))
    proposed = {"width": w, "depth": d, "max_height": 3}
    window_id = f"{sequence}_w{idx}"
    override_applied = False
    if overrides and window_id in overrides:
        override = overrides[window_id]
        proposed = {
            "width":      max(5, override.get("width", w)),
            "depth":      max(4, override.get("depth", d)),
            "max_height": max(2, override.get("max_height", 3)),
        }
        override_applied = True
    return {
        "id":          window_id,
        "sequence":    sequence,
        "phase":       phase,
        "t_min":       round(min(t for t, _, _ in artifacts), 4),
        "t_max":       round(max(t for t, _, _ in artifacts), 4),
        "t_mean":      round(sum(t for t, _, _ in artifacts) / n, 4),
        "n_artifacts": n,
        "total_footprint": total_fp,
        "proposed_size":   proposed,
        "size_override":   override_applied,
        "artifacts": [
            {"name": name, "t": round(t, 4), "footprint": fp}
            for (t, name, fp) in artifacts
        ],
    }


# ─────────────────────────────────────────────────────────────────────
# SVG rendering
# ─────────────────────────────────────────────────────────────────────

def render_windows_svg(windows: list[dict], timeline: dict) -> str:
    canvas_w = 1800
    row_h = 36
    margin_l = 180; margin_r = 40
    margin_t = 100
    plot_w = canvas_w - margin_l - margin_r

    seqs = sorted({w["sequence"] for w in windows},
                  key=lambda s: timeline["sequence_positions"].get(s, {}).get("order", 999))
    canvas_h = margin_t + len(seqs) * row_h + 120

    parts = [f'<rect width="{canvas_w}" height="{canvas_h}" fill="#0A0A0E"/>']
    parts.append(f'<text x="{margin_l - 160}" y="36" font-family="ui-monospace,monospace" '
                 f'font-size="22" font-weight="700" fill="#FFFFFF">'
                 f'Windows — artifacts grouped into maps</text>')
    parts.append(f'<text x="{margin_l - 160}" y="60" font-family="ui-monospace,monospace" '
                 f'font-size="11" fill="#9090A0">'
                 f'{len(windows)} windows · {sum(w["n_artifacts"] for w in windows)} artifacts placed · '
                 f'each rectangle = one proposed map · width ∝ t-range · height fixed per sequence row</text>')

    # Phase backdrop (light bands behind the entire plot)
    phase_order = ["F_order", "oscillation", "E_entropy", "lambda_edge",
                   "integration", "relation", "synthesis"]
    for i, phase in enumerate(phase_order):
        t_lo = i / len(phase_order); t_hi = (i + 1) / len(phase_order)
        x1 = margin_l + plot_w * t_lo
        x2 = margin_l + plot_w * t_hi
        col = PHASE_COLORS[phase]
        parts.append(f'<rect x="{x1}" y="{margin_t - 20}" '
                     f'width="{x2 - x1}" height="{canvas_h - margin_t - 80}" '
                     f'fill="{col}" fill-opacity="0.04"/>')
        parts.append(f'<text x="{(x1 + x2) / 2}" y="{margin_t - 26}" '
                     f'font-family="ui-monospace,monospace" font-size="12" '
                     f'font-weight="600" fill="{col}" text-anchor="middle">{phase}</text>')

    # Per-sequence row
    for ri, seq in enumerate(seqs):
        y = margin_t + ri * row_h
        # Row label
        info = timeline["sequence_positions"].get(seq, {})
        phase = info.get("phase", "?")
        seq_windows = [w for w in windows if w["sequence"] == seq]
        n_artifacts = sum(w["n_artifacts"] for w in seq_windows)
        parts.append(f'<text x="{margin_l - 8}" y="{y + row_h/2 + 4}" '
                     f'font-family="ui-monospace,monospace" font-size="11" '
                     f'fill="#E8E8EE" text-anchor="end">{seq}</text>')
        parts.append(f'<text x="{margin_l - 8}" y="{y + row_h/2 + 16}" '
                     f'font-family="ui-monospace,monospace" font-size="9" '
                     f'fill="#9090A0" text-anchor="end">'
                     f'{len(seq_windows)} maps · {n_artifacts} arts</text>')

        # Row baseline
        parts.append(f'<line x1="{margin_l}" y1="{y + row_h - 4}" '
                     f'x2="{margin_l + plot_w}" y2="{y + row_h - 4}" '
                     f'stroke="#222" stroke-width="0.5"/>')

        # Windows for this sequence
        for w in seq_windows:
            x1 = margin_l + plot_w * w["t_min"]
            x2 = margin_l + plot_w * w["t_max"]
            # Minimum visible width
            box_w = max(8, x2 - x1)
            col = PHASE_COLORS.get(w["phase"], "#888")
            # Window rectangle
            parts.append(f'<rect x="{x1}" y="{y + 4}" width="{box_w}" height="{row_h - 12}" '
                         f'fill="{col}" fill-opacity="0.4" stroke="{col}" stroke-width="1.5" rx="3"/>')
            # Artifact count + footprint inside
            cx = x1 + box_w / 2
            parts.append(f'<text x="{cx}" y="{y + 17}" '
                         f'font-family="ui-monospace,monospace" font-size="10" '
                         f'font-weight="700" fill="#FFFFFF" text-anchor="middle">'
                         f'{w["n_artifacts"]}</text>')
            parts.append(f'<text x="{cx}" y="{y + 28}" '
                         f'font-family="ui-monospace,monospace" font-size="8" '
                         f'fill="#FFFFFF" text-anchor="middle" fill-opacity="0.8">'
                         f'{w["proposed_size"]["width"]}×{w["proposed_size"]["depth"]}</text>')

            # Dots for individual artifacts inside (small)
            for a in w["artifacts"]:
                ax = margin_l + plot_w * a["t"]
                parts.append(f'<circle cx="{ax}" cy="{y + row_h - 4}" r="1.8" '
                             f'fill="#FFFFFF" fill-opacity="0.7"/>')

    # Footer stats
    footer_y = canvas_h - 60
    total_arts = sum(w["n_artifacts"] for w in windows)
    total_fp = sum(w["total_footprint"] for w in windows)
    avg_arts = total_arts / max(1, len(windows))
    parts.append(f'<text x="{margin_l - 160}" y="{footer_y}" '
                 f'font-family="ui-monospace,monospace" font-size="12" '
                 f'fill="#E8E8EE">'
                 f'TOTAL: {len(windows)} windows · {total_arts} artifacts · '
                 f'{total_fp} footprint cells · '
                 f'avg {avg_arts:.1f} artifacts/window</text>')

    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{canvas_w}" height="{canvas_h}" '
            f'viewBox="0 0 {canvas_w} {canvas_h}">{"".join(parts)}</svg>')


# ─────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--max-artifacts", type=int, default=6)
    p.add_argument("--max-footprint", type=int, default=60)
    p.add_argument("--include-non-spine", action="store_true",
                   help="also window artifacts in non-spine sequences")
    args = p.parse_args()

    if not TIMELINE_PATH.exists():
        print(f"timeline.json not found — run tools/timeline_solver.py first")
        return

    with open(TIMELINE_PATH, "r", encoding="utf-8") as f:
        timeline = json.load(f)

    print(f"loading footprints from registry...")
    footprints = load_footprints()
    print(f"  {len(footprints)} artifacts with footprint_cells")

    overrides = load_window_overrides()
    if overrides:
        print(f"  {len(overrides)} manual window-size overrides loaded")

    print(f"clustering ({args.max_artifacts} max artifacts/window, "
          f"{args.max_footprint} max footprint)...")
    windows = cluster_windows(timeline, footprints,
                                max_artifacts=args.max_artifacts,
                                max_footprint=args.max_footprint,
                                include_non_spine=args.include_non_spine,
                                overrides=overrides)
    print(f"  {len(windows)} windows produced")

    # Stats per sequence
    by_seq: dict[str, list[dict]] = defaultdict(list)
    for w in windows:
        by_seq[w["sequence"]].append(w)
    print()
    print("per-sequence window count:")
    spine_order = sorted(by_seq.keys(),
                         key=lambda s: timeline["sequence_positions"].get(s, {}).get("order", 999))
    for s in spine_order:
        seq_windows = by_seq[s]
        info = timeline["sequence_positions"].get(s, {})
        in_spine = info.get("in_spine", False)
        n_total = sum(w["n_artifacts"] for w in seq_windows)
        avg_size = sum(w["total_footprint"] for w in seq_windows) / max(1, len(seq_windows))
        spine_tag = "SPINE" if in_spine else "branch"
        print(f"  {s:25} {spine_tag:6}  {len(seq_windows):3} maps  "
              f"{n_total:4} artifacts  avg footprint {avg_size:5.1f}")

    # Save JSON
    out = {
        "params": {
            "max_artifacts_per_window":  args.max_artifacts,
            "max_footprint_per_window":  args.max_footprint,
            "include_non_spine":          args.include_non_spine,
        },
        "n_windows":          len(windows),
        "n_artifacts_placed": sum(w["n_artifacts"] for w in windows),
        "windows":            windows,
    }
    json_path = OUT_DIR / "windows.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(out, f, indent=2)
    print(f"\nwrote {json_path}")

    # SVG
    svg = render_windows_svg(windows, timeline)
    svg_path = OUT_DIR / "windows.svg"
    svg_path.write_text(svg, encoding="utf-8")
    print(f"wrote {svg_path}")

    # Mirror to encyclopedia public
    enc_public = ROOT.parent / "ada_encyclopedia" / "public" / "blog" / "2026-05-15-the-map-is-the-walk"
    if enc_public.exists():
        (enc_public / "windows.svg").write_text(svg, encoding="utf-8")
        print(f"also wrote {enc_public.relative_to(ROOT.parent)}/windows.svg")


if __name__ == "__main__":
    main()
