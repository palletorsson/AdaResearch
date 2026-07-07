"""tools/mine_level_patterns.py — quantitative comparison of Ada maps vs. VGLC Mario.

For each corpus (set of levels), extract:
  - entity_spacing:    gaps between consecutive entities along the walk axis
  - lane_distribution: which perpendicular "lane" (top/mid/bottom) entities live in
  - density_curve:     entity density along normalized walk position
  - breathing_runs:    lengths of empty stretches along the walk

Then compare distributions side-by-side. The question: does Ada's primitives /
transformation / wavefunctions / randomness style match Miyamoto's Mario design
language? (Hypothesis: yes — both are scroll-format corridors with paced beats.)

Run:
  python tools/mine_level_patterns.py
"""
from __future__ import annotations

import json
import re
import sys
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
VGLC_SMB = ROOT / "external" / "vglc" / "smb"
ADA_MAPS = ROOT / "commons" / "maps"
OUT_DIR = ROOT / "doc" / "placement_research"

# ── Mario tile legend (VGLC) ──
# Player walks left→right. Walk axis = columns, perpendicular = rows.
# "Entity" = anything the player can interact with or that is a placement
# decision. Excludes background air (-) and uniform ground (X) when X
# extends as the full ground floor.
MARIO_ENTITY_CHARS = {"?", "Q", "S", "E", "o", "<", ">", "[", "]", "B", "b", "F"}
MARIO_AIR = "-"
MARIO_GROUND = "X"


@dataclass
class LevelStats:
    name:             str
    walk_length:      int            # cells along walk axis
    perp_length:      int            # cells perpendicular
    n_entities:       int
    n_distinct_types: int
    spacing:          list[int]      # consecutive-entity gaps along walk
    lane_dist:        list[int]      # entities per perpendicular bin
    density_curve:    list[int]      # entities per walk-axis bucket (10 buckets)
    breathing_runs:   list[int]      # lengths of empty stretches along walk
    entity_counts:    dict[str, int] = field(default_factory=dict)


# ─────────────────────────────────────────────────────────────────────
# Mario loader (VGLC)
# ─────────────────────────────────────────────────────────────────────

def load_mario(path: Path) -> LevelStats:
    """Mario walks left→right. Walk axis = columns (length=W). Perp = rows (length=14)."""
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines:
        return LevelStats(path.stem, 0, 0, 0, 0, [], [], [], [])
    H = len(lines)
    W = max(len(l) for l in lines)

    # Pad to rectangular
    grid = [list(l.ljust(W, MARIO_AIR)) for l in lines]

    # For each column, identify entities (any char in MARIO_ENTITY_CHARS).
    # We aggregate "entity at column c" as 1 if any entity char in that column.
    col_has_entity: list[bool] = [False] * W
    entity_counts: Counter[str] = Counter()
    lane_per_entity: list[int] = []   # row of each entity (for lane distribution)

    for r in range(H):
        for c in range(W):
            ch = grid[r][c]
            if ch in MARIO_ENTITY_CHARS:
                col_has_entity[c] = True
                entity_counts[ch] += 1
                lane_per_entity.append(r)

    # Spacing along walk: gaps between consecutive entity columns
    entity_cols = [c for c, b in enumerate(col_has_entity) if b]
    spacing = [entity_cols[i+1] - entity_cols[i] for i in range(len(entity_cols)-1)]

    # Density curve: 10 buckets along W
    n_buckets = 10
    density_curve = [0] * n_buckets
    for c in entity_cols:
        b = min(n_buckets - 1, int(c * n_buckets / max(1, W)))
        density_curve[b] += 1

    # Breathing-room runs: lengths of consecutive False in col_has_entity
    runs: list[int] = []
    cur = 0
    for b in col_has_entity:
        if b:
            if cur > 0: runs.append(cur)
            cur = 0
        else:
            cur += 1
    if cur > 0: runs.append(cur)

    # Lane distribution: bin rows into 4 bands (sky, upper, lower, ground)
    n_lanes = 4
    lane_dist = [0] * n_lanes
    for r in lane_per_entity:
        lane = min(n_lanes - 1, int(r * n_lanes / max(1, H)))
        lane_dist[lane] += 1

    return LevelStats(
        name=path.stem,
        walk_length=W,
        perp_length=H,
        n_entities=sum(entity_counts.values()),
        n_distinct_types=len(entity_counts),
        spacing=spacing,
        lane_dist=lane_dist,
        density_curve=density_curve,
        breathing_runs=runs,
        entity_counts=dict(entity_counts),
    )


# ─────────────────────────────────────────────────────────────────────
# Ada loader (map_data.json)
# ─────────────────────────────────────────────────────────────────────

TOKEN_RE = re.compile(r"^([a-zA-Z_][a-zA-Z0-9_]*)")


def load_ada_map(map_name: str) -> LevelStats | None:
    """Ada walks spawn→teleporter (usually vertical, depth axis = walk)."""
    p = ADA_MAPS / map_name / "map_data.json"
    if not p.exists(): return None
    try:
        with open(p, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (json.JSONDecodeError, OSError):
        return None
    dim = data.get("map_info", {}).get("dimensions", {})
    W = int(dim.get("width", 0) or 0)
    D = int(dim.get("depth", 0) or 0)
    if W == 0 or D == 0: return None
    util = data.get("layers", {}).get("utilities", []) or []
    inter = data.get("layers", {}).get("interactables", []) or []

    # Find spawn + teleporter
    sp_r = te_r = None
    for r, row in enumerate(util):
        for c, tok in enumerate(row):
            if not isinstance(tok, str): continue
            t = tok.strip()
            if t.startswith("sp"): sp_r = r
            elif t == "t": te_r = r
    # Walk axis = depth (rows). For consistency with Mario (left→right),
    # we orient the walk so spawn is at position 0 and teleporter at end.
    flip = False
    if sp_r is not None and te_r is not None and sp_r > te_r:
        flip = True

    # Entities: interactables. Each non-empty cell counts as 1.
    row_has_entity: list[bool] = [False] * D
    entity_counts: Counter[str] = Counter()
    col_per_entity: list[int] = []   # column = perpendicular axis (lane)

    for r in range(D):
        for c in range(W):
            if r >= len(inter): break
            tok = inter[r][c] if c < len(inter[r]) else ""
            if not isinstance(tok, str) or not tok.strip(): continue
            m = TOKEN_RE.match(tok.strip())
            if not m: continue
            row_has_entity[r] = True
            entity_counts[m.group(1)] += 1
            col_per_entity.append(c)

    # Orient: if flipped, reverse
    if flip:
        row_has_entity = list(reversed(row_has_entity))

    # Spacing along walk
    entity_rows = [r for r, b in enumerate(row_has_entity) if b]
    spacing = [entity_rows[i+1] - entity_rows[i] for i in range(len(entity_rows)-1)]

    # Density curve: 10 buckets along walk (D)
    n_buckets = 10
    density_curve = [0] * n_buckets
    for r in entity_rows:
        b = min(n_buckets - 1, int(r * n_buckets / max(1, D)))
        density_curve[b] += 1

    # Breathing runs
    runs: list[int] = []
    cur = 0
    for b in row_has_entity:
        if b:
            if cur > 0: runs.append(cur)
            cur = 0
        else:
            cur += 1
    if cur > 0: runs.append(cur)

    # Lane distribution: bin columns into 4 bands (left, left-mid, right-mid, right)
    n_lanes = 4
    lane_dist = [0] * n_lanes
    for c in col_per_entity:
        lane = min(n_lanes - 1, int(c * n_lanes / max(1, W)))
        lane_dist[lane] += 1

    return LevelStats(
        name=map_name,
        walk_length=D,
        perp_length=W,
        n_entities=sum(entity_counts.values()),
        n_distinct_types=len(entity_counts),
        spacing=spacing,
        lane_dist=lane_dist,
        density_curve=density_curve,
        breathing_runs=runs,
        entity_counts=dict(entity_counts),
    )


# ─────────────────────────────────────────────────────────────────────
# Aggregate across a corpus
# ─────────────────────────────────────────────────────────────────────

@dataclass
class CorpusStats:
    name:                str
    n_levels:            int
    total_entities:      int
    mean_walk_length:    float
    mean_perp_length:    float
    mean_aspect:         float
    spacing_pool:        list[int]
    lane_pool:           list[float]    # normalized 0..1 lane percentages combined
    density_pool:        list[float]    # mean density curve (normalized)
    breathing_pool:      list[int]


def summarize_corpus(name: str, levels: list[LevelStats]) -> CorpusStats:
    spacing_pool = []
    breathing_pool = []
    walks = []
    perps = []
    for L in levels:
        spacing_pool.extend(L.spacing)
        breathing_pool.extend(L.breathing_runs)
        walks.append(L.walk_length)
        perps.append(L.perp_length)
    # Lane distribution averaged across levels (percentage)
    lane_pool = [0.0, 0.0, 0.0, 0.0]
    for L in levels:
        total = sum(L.lane_dist)
        if total > 0:
            for i, v in enumerate(L.lane_dist):
                lane_pool[i] += v / total
    lane_pool = [v / max(1, len(levels)) for v in lane_pool]
    # Density curve averaged (normalized per level)
    density_pool = [0.0] * 10
    for L in levels:
        total = sum(L.density_curve)
        if total > 0:
            for i, v in enumerate(L.density_curve):
                density_pool[i] += v / total
    density_pool = [v / max(1, len(levels)) for v in density_pool]

    return CorpusStats(
        name=name,
        n_levels=len(levels),
        total_entities=sum(L.n_entities for L in levels),
        mean_walk_length=sum(walks) / max(1, len(walks)),
        mean_perp_length=sum(perps) / max(1, len(perps)),
        mean_aspect=sum(w/max(1,p) for w,p in zip(walks, perps)) / max(1, len(walks)),
        spacing_pool=spacing_pool,
        lane_pool=lane_pool,
        density_pool=density_pool,
        breathing_pool=breathing_pool,
    )


def quartiles(xs: list[int]) -> tuple[float, float, float, float, float]:
    if not xs: return (0, 0, 0, 0, 0)
    s = sorted(xs)
    n = len(s)
    return (
        s[0],
        s[n // 4],
        s[n // 2],
        s[3 * n // 4],
        s[-1],
    )


# ─────────────────────────────────────────────────────────────────────
# Print comparison
# ─────────────────────────────────────────────────────────────────────

def print_corpus_summary(c: CorpusStats) -> None:
    sp = quartiles(c.spacing_pool)
    br = quartiles(c.breathing_pool)
    print(f"=== {c.name} · {c.n_levels} levels · {c.total_entities} entities ===")
    print(f"  mean walk: {c.mean_walk_length:.1f}  mean perp: {c.mean_perp_length:.1f}  mean aspect: {c.mean_aspect:.1f}")
    print(f"  spacing along walk: min/q1/med/q3/max = "
          f"{sp[0]}/{sp[1]}/{sp[2]}/{sp[3]}/{sp[4]}")
    print(f"  breathing runs:     min/q1/med/q3/max = "
          f"{br[0]}/{br[1]}/{br[2]}/{br[3]}/{br[4]}")
    print(f"  lane distribution (4 bands, perp): "
          f"{[round(v, 2) for v in c.lane_pool]}")
    print(f"  density curve (10 buckets, walk axis):")
    max_d = max(c.density_pool) if c.density_pool else 1
    for i, v in enumerate(c.density_pool):
        bar_len = int(v / max(1e-9, max_d) * 30)
        print(f"    bucket {i}: {'█' * bar_len} {v:.3f}")
    print()


# ─────────────────────────────────────────────────────────────────────
# SVG comparison
# ─────────────────────────────────────────────────────────────────────

def render_comparison_svg(corpora: list[CorpusStats], out_path: Path) -> None:
    W = 1400
    H = 800
    parts = [f'<rect width="{W}" height="{H}" fill="#0A0A0E"/>']
    parts.append(f'<text x="24" y="36" font-family="ui-monospace" font-size="20" '
                 f'font-weight="700" fill="#FFFFFF">Level pattern comparison — Ada vs. Mario</text>')

    colors = ["#7DFFA8", "#E63946", "#F4A261", "#9B5DE5", "#FBE38A"]

    # Density curve (10 buckets along walk)
    panel_y = 70
    panel_h = 200
    parts.append(f'<text x="24" y="{panel_y + 12}" font-family="ui-monospace" font-size="13" '
                 f'fill="#E8E8EE" font-weight="600">density curve along walk (normalized)</text>')
    parts.append(f'<text x="24" y="{panel_y + 28}" font-family="ui-monospace" font-size="10" '
                 f'fill="#9090A0">x = walk progress · y = % of entities in that bucket</text>')
    plot_x = 80
    plot_y = panel_y + 40
    plot_w = W - plot_x - 200
    plot_h = panel_h - 50
    parts.append(f'<rect x="{plot_x}" y="{plot_y}" width="{plot_w}" height="{plot_h}" '
                 f'fill="#101015" stroke="#2A2A33"/>')
    max_d = max((max(c.density_pool) for c in corpora if c.density_pool), default=0.25)
    for ci, c in enumerate(corpora):
        col = colors[ci % len(colors)]
        # Polyline of density curve
        if not c.density_pool: continue
        pts = []
        for i, v in enumerate(c.density_pool):
            x = plot_x + plot_w * (i + 0.5) / 10
            y = plot_y + plot_h - (v / max_d) * plot_h
            pts.append(f"{x:.1f},{y:.1f}")
        parts.append(f'<polyline points="{" ".join(pts)}" fill="none" stroke="{col}" '
                     f'stroke-width="2.5"/>')
        # Legend marker
        ly = plot_y + 16 + ci * 18
        parts.append(f'<rect x="{plot_x + plot_w + 16}" y="{ly}" width="14" height="14" '
                     f'fill="{col}"/>')
        parts.append(f'<text x="{plot_x + plot_w + 36}" y="{ly + 11}" '
                     f'font-family="ui-monospace" font-size="11" fill="#E8E8EE">'
                     f'{c.name} ({c.n_levels})</text>')

    # Lane distribution (perpendicular)
    panel_y = 300
    panel_h = 180
    parts.append(f'<text x="24" y="{panel_y + 12}" font-family="ui-monospace" font-size="13" '
                 f'fill="#E8E8EE" font-weight="600">lane distribution (perpendicular to walk)</text>')
    parts.append(f'<text x="24" y="{panel_y + 28}" font-family="ui-monospace" font-size="10" '
                 f'fill="#9090A0">how entities spread across 4 perpendicular bands</text>')
    bar_y = panel_y + 50
    bar_h = 100
    bar_w_each = 80
    n_lanes = 4
    group_w = bar_w_each * len(corpora) + 20
    for lane in range(n_lanes):
        gx = 100 + lane * (group_w + 30)
        parts.append(f'<text x="{gx + group_w / 2}" y="{bar_y + bar_h + 14}" '
                     f'font-family="ui-monospace" font-size="11" fill="#9090A0" '
                     f'text-anchor="middle">band {lane}</text>')
        for ci, c in enumerate(corpora):
            if not c.lane_pool: continue
            v = c.lane_pool[lane] if lane < len(c.lane_pool) else 0
            h = v * bar_h
            x = gx + ci * bar_w_each
            col = colors[ci % len(colors)]
            parts.append(f'<rect x="{x}" y="{bar_y + bar_h - h}" width="{bar_w_each - 4}" '
                         f'height="{h}" fill="{col}" fill-opacity="0.8"/>')
            parts.append(f'<text x="{x + (bar_w_each - 4) / 2}" y="{bar_y + bar_h - h - 4}" '
                         f'font-family="ui-monospace" font-size="9" fill="#E8E8EE" '
                         f'text-anchor="middle">{v:.2f}</text>')

    # Stats summary table at bottom
    panel_y = 510
    parts.append(f'<text x="24" y="{panel_y + 12}" font-family="ui-monospace" font-size="13" '
                 f'fill="#E8E8EE" font-weight="600">summary</text>')
    parts.append(f'<text x="80" y="{panel_y + 38}" font-family="ui-monospace" font-size="11" '
                 f'fill="#9090A0">corpus</text>')
    parts.append(f'<text x="320" y="{panel_y + 38}" font-family="ui-monospace" font-size="11" '
                 f'fill="#9090A0">levels</text>')
    parts.append(f'<text x="420" y="{panel_y + 38}" font-family="ui-monospace" font-size="11" '
                 f'fill="#9090A0">entities</text>')
    parts.append(f'<text x="530" y="{panel_y + 38}" font-family="ui-monospace" font-size="11" '
                 f'fill="#9090A0">mean walk</text>')
    parts.append(f'<text x="650" y="{panel_y + 38}" font-family="ui-monospace" font-size="11" '
                 f'fill="#9090A0">mean perp</text>')
    parts.append(f'<text x="770" y="{panel_y + 38}" font-family="ui-monospace" font-size="11" '
                 f'fill="#9090A0">aspect</text>')
    parts.append(f'<text x="860" y="{panel_y + 38}" font-family="ui-monospace" font-size="11" '
                 f'fill="#9090A0">spacing med</text>')
    parts.append(f'<text x="990" y="{panel_y + 38}" font-family="ui-monospace" font-size="11" '
                 f'fill="#9090A0">breath med</text>')
    for ci, c in enumerate(corpora):
        y = panel_y + 60 + ci * 22
        col = colors[ci % len(colors)]
        sp = quartiles(c.spacing_pool)
        br = quartiles(c.breathing_pool)
        parts.append(f'<rect x="60" y="{y - 12}" width="14" height="14" fill="{col}"/>')
        parts.append(f'<text x="80" y="{y}" font-family="ui-monospace" font-size="12" '
                     f'fill="#E8E8EE">{c.name}</text>')
        parts.append(f'<text x="320" y="{y}" font-family="ui-monospace" font-size="11" '
                     f'fill="#E8E8EE">{c.n_levels}</text>')
        parts.append(f'<text x="420" y="{y}" font-family="ui-monospace" font-size="11" '
                     f'fill="#E8E8EE">{c.total_entities}</text>')
        parts.append(f'<text x="530" y="{y}" font-family="ui-monospace" font-size="11" '
                     f'fill="#E8E8EE">{c.mean_walk_length:.1f}</text>')
        parts.append(f'<text x="650" y="{y}" font-family="ui-monospace" font-size="11" '
                     f'fill="#E8E8EE">{c.mean_perp_length:.1f}</text>')
        parts.append(f'<text x="770" y="{y}" font-family="ui-monospace" font-size="11" '
                     f'fill="#E8E8EE">{c.mean_aspect:.2f}</text>')
        parts.append(f'<text x="860" y="{y}" font-family="ui-monospace" font-size="11" '
                     f'fill="#E8E8EE">{sp[2]}</text>')
        parts.append(f'<text x="990" y="{y}" font-family="ui-monospace" font-size="11" '
                     f'fill="#E8E8EE">{br[2]}</text>')

    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
           f'viewBox="0 0 {W} {H}">{"".join(parts)}</svg>')
    out_path.write_text(svg, encoding="utf-8")


# ─────────────────────────────────────────────────────────────────────
# Sequence map lists
# ─────────────────────────────────────────────────────────────────────

ADA_SEQUENCES = {
    "ada_primitives":     ["Point_One", "Point_Line", "Point_Lines", "Point_Trace",
                            "Point_Line_Grid", "Point_Triangle", "Point_Triangle_Context",
                            "Primitives_Polythedra", "Primitives_Ignorance",
                            "Primitives_Portals", "Primitives_Melencolia"],
    "ada_transformation": ["Trans_Introduction", "Trans_Translation",
                            "Trans_AxisDecomposition", "Trans_Rotation",
                            "Trans_RotationSpectacle", "Trans_Scale", "Trans_Pit"],
    "ada_wavefunctions":  ["WaveFunctions_Intro", "WaveFunctions_Pendulum",
                            "WaveFunctions_Unit_Circle", "WaveFunctions_Sine_Space",
                            "WaveFunctions_3D_Wave_Propagation",
                            "WaveFunctions_TrigWalkingPath"],
    "ada_randomness":     ["Random_Definition", "Random_Remove", "Random_Cubes",
                            "Random_Walk", "Random_Gaussian", "Random_Mushrooms",
                            "Random_Space_Geometry", "Random_Pheromone"],
}


def main():
    print("loading levels…")
    # Mario corpus
    mario_levels = []
    for p in sorted(VGLC_SMB.glob("mario-*.txt")):
        L = load_mario(p)
        if L.n_entities > 0:
            mario_levels.append(L)
            print(f"  mario  {L.name:18}  {L.walk_length:4}×{L.perp_length:2}  "
                  f"{L.n_entities:4} entities  {L.n_distinct_types} types")

    # Ada corpora — one per sequence
    ada_corpora_by_seq: dict[str, list[LevelStats]] = {}
    for seq_name, maps in ADA_SEQUENCES.items():
        ls = []
        for m in maps:
            L = load_ada_map(m)
            if L and L.n_entities > 0:
                ls.append(L)
                print(f"  ada    {L.name:35}  {L.walk_length:4}×{L.perp_length:2}  "
                      f"{L.n_entities:4} entities  {L.n_distinct_types} types")
        ada_corpora_by_seq[seq_name] = ls

    print()
    # Summarize each
    mario_c = summarize_corpus("mario_smb", mario_levels)
    ada_all_levels = [L for ls in ada_corpora_by_seq.values() for L in ls]
    ada_all_c = summarize_corpus("ada_all_authored", ada_all_levels)
    seq_corpora = {name: summarize_corpus(name, ls) for name, ls in ada_corpora_by_seq.items()}

    print_corpus_summary(mario_c)
    print_corpus_summary(ada_all_c)
    for c in seq_corpora.values():
        print_corpus_summary(c)

    # Write JSON
    out_json = OUT_DIR / "level_patterns.json"
    out = {
        "mario_smb": vars(mario_c),
        "ada_all_authored": vars(ada_all_c),
    }
    for name, c in seq_corpora.items():
        out[name] = vars(c)
    with open(out_json, "w", encoding="utf-8") as f:
        json.dump(out, f, indent=2, default=lambda o: str(o))
    print(f"wrote {out_json}")

    # Two SVGs: ada_all vs mario, and per-sequence vs mario
    render_comparison_svg([mario_c, ada_all_c], OUT_DIR / "patterns_ada_vs_mario.svg")
    print(f"wrote {OUT_DIR / 'patterns_ada_vs_mario.svg'}")

    render_comparison_svg(
        [mario_c] + list(seq_corpora.values()),
        OUT_DIR / "patterns_per_sequence.svg",
    )
    print(f"wrote {OUT_DIR / 'patterns_per_sequence.svg'}")


if __name__ == "__main__":
    main()
