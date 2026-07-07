"""tools/timeline_solver.py — place every artifact at a t-position on the spine.

Phase A of the timeline-driven map system. Reads the spine + sequences + every
artifact in the registry, computes a t-position ∈ [0, 1] per artifact via a
5-term energy gradient, writes a timeline JSON + an SVG visualisation.

The architecture (sketched in /blog/2026-05-15-the-map-is-the-walk follow-up):
  A. timeline_solver   — artifact → t-position           ← THIS FILE
  B. window_clusterer  — t-positions → maps              (next)
  C. map_generator     — windows → grown maps            (next, uses grow_walker)
  D. timeline_editor   — web UI for tweaking             (next)

Five-term energy:
  prereq_order        — pull artifacts AFTER their prerequisites
  sequence_coherence  — same-sequence artifacts cluster
  phase_alignment     — artifact's qfep_term matches phase region at t
  conceptual_proximity — similar @identity → similar t
  density_smoothness  — avoid piles at single t

Run:
  python tools/timeline_solver.py                # solve + write JSON + render SVG
  python tools/timeline_solver.py --iterations=50
  python tools/timeline_solver.py --report       # re-read existing JSON, print stats
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
SPINE_PATH = ROOT / "commons" / "maps" / "curriculum_spine.json"
SEQ_DIR = ROOT / "commons" / "maps" / "sequences"
REGISTRY_DIR = ROOT / "commons" / "artifacts" / "registry"
OUT_DIR = ROOT / "doc" / "placement_research"
PINS_PATH = OUT_DIR / "pins.json"   # {artifact_lookup_name: t_position}
OUT_DIR.mkdir(parents=True, exist_ok=True)

PHASE_ORDER = ["F_order", "oscillation", "E_entropy", "lambda_edge",
                "integration", "relation", "synthesis"]
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
# Data loading
# ─────────────────────────────────────────────────────────────────────

def load_spine() -> dict:
    with open(SPINE_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def load_sequence_membership() -> dict[str, list[str]]:
    """Return {map_name: [sequence_ids]} from all sequence files."""
    out: dict[str, list[str]] = defaultdict(list)
    for sf in SEQ_DIR.glob("*.json"):
        try:
            with open(sf, "r", encoding="utf-8") as f:
                data = json.load(f)
        except (json.JSONDecodeError, OSError):
            continue
        seqs_raw = data.get("sequences") or {}
        # Sequence file shape can be dict {id: seq} OR list [{name|id: ...}]
        if isinstance(seqs_raw, dict):
            iterable = seqs_raw.items()
        elif isinstance(seqs_raw, list):
            iterable = []
            for s in seqs_raw:
                if isinstance(s, dict):
                    sid = s.get("id") or s.get("name") or sf.stem
                    iterable.append((sid, s))
        else:
            iterable = []
        for seq_id, seq in iterable:
            if not isinstance(seq, dict): continue
            for m in (seq.get("maps") or []):
                if isinstance(m, str):
                    out[m].append(seq_id)
                elif isinstance(m, dict):
                    mname = m.get("name") or m.get("map") or m.get("id")
                    if mname:
                        out[mname].append(seq_id)
    return out


def build_artifact_to_sequences() -> dict[str, list[str]]:
    """Walk every map_data.json and build {artifact_lookup_name: [sequences]}
    based on which maps actually USE the artifact in their interactables layer.

    This is the AUTHORITATIVE source — the artifact metadata's `map_sequences`
    field is often stale or missing. The map's interactables are ground truth.
    """
    import re
    TOKEN_RE = re.compile(r"^([a-zA-Z_][a-zA-Z0-9_]*)(?:[:#]|$)")
    map_to_sequences = load_sequence_membership()
    out: dict[str, set[str]] = defaultdict(set)
    maps_dir = ROOT / "commons" / "maps"
    for sub in maps_dir.iterdir():
        if not sub.is_dir(): continue
        md = sub / "map_data.json"
        if not md.exists(): continue
        try:
            with open(md, "r", encoding="utf-8") as f:
                map_data = json.load(f)
        except (json.JSONDecodeError, OSError):
            continue
        inter = (map_data.get("layers") or {}).get("interactables") or []
        seqs = map_to_sequences.get(sub.name, [])
        if not seqs: continue
        for row in inter:
            for tok in row:
                if not isinstance(tok, str) or not tok.strip(): continue
                m = TOKEN_RE.match(tok.strip())
                if m:
                    name = m.group(1)
                    out[name].update(seqs)
    return {k: sorted(v) for k, v in out.items()}


def load_artifacts() -> list[dict]:
    """Flat list of every artifact dict in the registry."""
    out: list[dict] = []
    def walk(node):
        if isinstance(node, dict):
            if "lookup_name" in node and isinstance(node["lookup_name"], str):
                out.append(node)
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
# Initial positioning — sequence-based
# ─────────────────────────────────────────────────────────────────────

def build_sequence_positions(spine: dict, include_branches: bool = True) -> dict[str, dict]:
    """Return {sequence_id: {t_start, t_end, phase, order, in_spine}}.

    Spine sequences occupy [0, 0.94] in their declared order.
    If include_branches: non-spine sequences (from sequence files) get
    positions either:
      (a) inside their parent_sequence's slice (folded — branch t-range
          extends just past the parent's t_end) if the sequence JSON
          declares parent_sequence
      (b) appended in the synthesis tail [0.94, 1.0] alphabetically
    """
    spine_seqs = spine["spine"]["sequences"]
    n = len(spine_seqs)
    SPINE_END = 0.94 if include_branches else 1.0
    out: dict[str, dict] = {}
    for entry in spine_seqs:
        order = entry["order"]
        t_start = (order - 1) * SPINE_END / n
        t_end = order * SPINE_END / n
        out[entry["name"]] = {
            "t_start": t_start, "t_end": t_end,
            "phase": entry["phase"], "order": order,
            "in_spine": True,
            "parent_sequence": None,
        }
    if not include_branches:
        return out

    # Discover all sequences from sequence files, find branches (non-spine)
    spine_names = set(out.keys())
    branch_entries: list[tuple[str, str | None, str | None]] = []  # (name, parent, phase)
    for sf in SEQ_DIR.glob("*.json"):
        try:
            with open(sf, "r", encoding="utf-8") as f:
                data = json.load(f)
        except (json.JSONDecodeError, OSError):
            continue
        seqs_raw = data.get("sequences") or {}
        iterable = seqs_raw.items() if isinstance(seqs_raw, dict) else (
            ((s.get("id") or s.get("name") or sf.stem, s) for s in seqs_raw if isinstance(s, dict))
        )
        for sid, seq in iterable:
            if not isinstance(seq, dict): continue
            if sid in spine_names: continue
            parent = seq.get("parent_sequence")
            phase = seq.get("phase") or seq.get("world_phase") or "synthesis"
            branch_entries.append((sid, parent, phase))

    # Branches with known parents: place adjacent to parent
    branches_by_parent: dict[str, list[str]] = defaultdict(list)
    orphan_branches: list[tuple[str, str]] = []   # (name, phase)
    for (name, parent, phase) in branch_entries:
        if parent and parent in spine_names:
            branches_by_parent[parent].append(name)
        else:
            orphan_branches.append((name, phase))

    # For each parent, sub-divide a tiny slice right after the parent's t_end
    # for its branches
    for parent, names in branches_by_parent.items():
        parent_info = out[parent]
        slice_size = (parent_info["t_end"] - parent_info["t_start"]) * 0.05
        for i, branch in enumerate(sorted(names)):
            t_offset = i / max(1, len(names)) * slice_size
            out[branch] = {
                "t_start": parent_info["t_end"] - slice_size + t_offset,
                "t_end":   parent_info["t_end"] - slice_size + (i + 1) / max(1, len(names)) * slice_size,
                "phase":   parent_info["phase"],
                "order":   parent_info["order"] + 0.1 + i * 0.01,
                "in_spine": False,
                "parent_sequence": parent,
            }

    # Orphan branches: append at [0.94, 1.0] alphabetically
    orphan_branches.sort()
    n_orph = max(1, len(orphan_branches))
    branch_lane_start = SPINE_END
    branch_lane_end = 1.0
    for i, (name, phase) in enumerate(orphan_branches):
        t_start = branch_lane_start + (branch_lane_end - branch_lane_start) * i / n_orph
        t_end = branch_lane_start + (branch_lane_end - branch_lane_start) * (i + 1) / n_orph
        out[name] = {
            "t_start": t_start, "t_end": t_end,
            "phase": phase if phase in PHASE_COLORS else "synthesis",
            "order": 100 + i,
            "in_spine": False,
            "parent_sequence": None,
        }
    return out


def initial_position(artifact: dict, seq_positions: dict[str, dict],
                     map_derived_seqs: dict[str, list[str]]) -> tuple[float, str, str]:
    """Compute initial t for an artifact. Returns (t, sequence_id, phase).

    Sequence membership combines:
      - sequences derived from map usage (authoritative where present)
      - artifact.map_sequences (declared, often stale)
    Then picks the first SPINE sequence from the union, falling back to
    any sequence, then to 'unplaced' at the synthesis end.
    """
    name = artifact["lookup_name"]
    # Combine both signals as a union
    ms: list[str] = list(map_derived_seqs.get(name, []))
    declared = artifact.get("map_sequences") or []
    if isinstance(declared, str):
        declared = [declared]
    for s in declared:
        if s not in ms:
            ms.append(s)
    # Prefer first spine sequence
    chosen: str | None = None
    for s in ms:
        if s in seq_positions and seq_positions[s].get("in_spine"):
            chosen = s; break
    if chosen is None:
        for s in ms:
            if s in seq_positions:
                chosen = s; break
    if chosen and chosen in seq_positions:
        info = seq_positions[chosen]
        h = (hash(name) % 1000) / 1000.0
        t = info["t_start"] + (info["t_end"] - info["t_start"]) * h
        return t, chosen, info.get("phase", "")
    # No spine sequence found — record FIRST non-spine sequence so we at least
    # know what bucket it's in, even though we can't place it on the spine
    if ms:
        h = (hash(name) % 1000) / 1000.0
        return 0.97 + 0.03 * h, ms[0], "synthesis"
    # Truly unplaced: no sequence at all
    h = (hash(name) % 1000) / 1000.0
    return 0.97 + 0.03 * h, "unplaced", "synthesis"


# ─────────────────────────────────────────────────────────────────────
# Energy function — five terms
# ─────────────────────────────────────────────────────────────────────

def compute_energy(positions: dict[str, float],
                   artifacts: list[dict],
                   seq_positions: dict[str, dict],
                   seq_of: dict[str, str]) -> dict[str, float]:
    """Compute the five energy components for the current state."""
    by_seq: dict[str, list[float]] = defaultdict(list)
    by_phase: dict[str, list[float]] = defaultdict(list)
    for a in artifacts:
        name = a["lookup_name"]
        if name not in positions: continue
        t = positions[name]
        s = seq_of.get(name, "unplaced")
        if s in seq_positions:
            by_seq[s].append(t)
            by_phase[seq_positions[s]["phase"]].append(t)

    # 1. sequence_coherence — variance within each sequence
    e_seq = 0.0
    for s, ts in by_seq.items():
        if len(ts) < 2: continue
        mean = sum(ts) / len(ts)
        var = sum((t - mean) ** 2 for t in ts) / len(ts)
        # Compare with target band — sequences should fit in their slot
        info = seq_positions.get(s, {})
        band = info.get("t_end", 1.0) - info.get("t_start", 0.0)
        e_seq += var / max(0.001, band ** 2)
    e_seq /= max(1, len(by_seq))

    # 2. phase_alignment — artifact's phase matches t-region
    e_phase = 0.0
    for a in artifacts:
        name = a["lookup_name"]
        if name not in positions: continue
        t = positions[name]
        s = seq_of.get(name, "unplaced")
        info = seq_positions.get(s)
        if info:
            ideal_t = (info["t_start"] + info["t_end"]) / 2
            e_phase += (t - ideal_t) ** 2
    e_phase /= max(1, len(artifacts))

    # 3. density_smoothness — penalty for piles
    sorted_pos = sorted(positions.values())
    e_smooth = 0.0
    for i in range(1, len(sorted_pos)):
        gap = sorted_pos[i] - sorted_pos[i - 1]
        if gap < 0.001:
            e_smooth += 100
        else:
            e_smooth += 1.0 / (gap * 1000)
    e_smooth /= max(1, len(sorted_pos))

    # 4. prereq_order — currently not implemented (no prereq metadata yet on
    #    most artifacts); placeholder for future
    e_prereq = 0.0

    # 5. conceptual_proximity — placeholder (would need keyword embedding)
    e_concept = 0.0

    weights = {"sequence_coherence": 1.0, "phase_alignment": 1.0,
               "density_smoothness": 0.3, "prereq_order": 2.0,
               "conceptual_proximity": 0.5}
    total = (
        weights["sequence_coherence"] * e_seq
        + weights["phase_alignment"] * e_phase
        + weights["density_smoothness"] * e_smooth
        + weights["prereq_order"] * e_prereq
        + weights["conceptual_proximity"] * e_concept
    )
    return {
        "total":               round(total, 4),
        "sequence_coherence":  round(e_seq, 4),
        "phase_alignment":     round(e_phase, 4),
        "density_smoothness":  round(e_smooth, 4),
        "prereq_order":        round(e_prereq, 4),
        "conceptual_proximity": round(e_concept, 4),
    }


def load_pins() -> dict[str, float]:
    """Load manual artifact pins from pins.json. Format:
       { "lookup_name": <t_position>, ... }
    Keys starting with '_' are ignored (used for notes).
    Returns empty dict if missing."""
    if not PINS_PATH.exists():
        return {}
    try:
        with open(PINS_PATH, "r", encoding="utf-8") as f:
            raw = json.load(f)
        return {k: float(v) for k, v in raw.items()
                if not k.startswith("_") and isinstance(v, (int, float))}
    except (json.JSONDecodeError, OSError, ValueError):
        return {}


def relax_positions(positions: dict[str, float],
                    artifacts: list[dict],
                    seq_positions: dict[str, dict],
                    seq_of: dict[str, str],
                    iterations: int = 20,
                    pinned: set[str] | None = None) -> dict[str, float]:
    """Iteratively shift positions toward lower energy.

    Per artifact, the gradient combines:
      (a) PULL toward sequence centre (coherence)         weight 0.4
      (b) REPULSION from immediate neighbours within 0.002 window (smooth)
      (c) CLAMP inside the sequence's own t-range (keep in lane)

    Pinned artifacts are skipped — they're sticks in the river.
    Learning rate is small (0.02), iterations many. Both attractive and
    repulsive gradients normalized so neither dominates.
    """
    pinned = pinned or set()
    lr = 0.02
    REPULSION_RANGE = 0.002    # neighbours within this t-distance repel
    MIN_GAP = 0.0003

    for it in range(iterations):
        sorted_names = sorted(positions.keys(), key=lambda n: positions[n])
        idx_by_name = {n: i for i, n in enumerate(sorted_names)}

        updates: dict[str, float] = {}
        for a in artifacts:
            name = a["lookup_name"]
            if name not in positions or name in pinned: continue
            t = positions[name]
            grad = 0.0

            # (a) Pull toward sequence centre
            s = seq_of.get(name, "unplaced")
            info = seq_positions.get(s)
            if info:
                centre = (info["t_start"] + info["t_end"]) / 2
                grad += (t - centre) * 0.4

            # (b) Repulsion from close neighbours
            i = idx_by_name[name]
            for ni in (i - 2, i - 1, i + 1, i + 2):
                if 0 <= ni < len(sorted_names):
                    other = sorted_names[ni]
                    if other in pinned: continue
                    other_t = positions[other]
                    gap = t - other_t
                    abs_gap = abs(gap)
                    if abs_gap < MIN_GAP:
                        # Hard collision — push by MIN_GAP
                        grad -= (1 if gap >= 0 else -1) * 0.001
                    elif abs_gap < REPULSION_RANGE:
                        # Soft repulsion: stronger as gap shrinks, capped
                        push = (REPULSION_RANGE - abs_gap) / REPULSION_RANGE
                        grad -= (1 if gap >= 0 else -1) * push * 0.0008

            new_t = t - lr * grad

            # (c) Clamp inside sequence range with soft margin
            if info:
                margin = (info["t_end"] - info["t_start"]) * 0.02
                lo = info["t_start"] + margin
                hi = info["t_end"] - margin
                if new_t < lo: new_t = lo + (new_t - lo) * 0.3
                if new_t > hi: new_t = hi + (new_t - hi) * 0.3

            updates[name] = max(0.0, min(1.0, new_t))

        for name, new_t in updates.items():
            positions[name] = new_t

    return positions


# ─────────────────────────────────────────────────────────────────────
# SVG rendering
# ─────────────────────────────────────────────────────────────────────

def render_timeline_svg(positions: dict[str, float],
                        artifacts: list[dict],
                        seq_positions: dict[str, dict],
                        seq_of: dict[str, str],
                        spine: dict) -> str:
    """Horizontal timeline. Artifacts as dots, coloured by phase. Sequence
    bands across the top. Phase regions coloured along the timeline rail."""
    canvas_w = 1800
    canvas_h = 900
    margin_l = 40; margin_r = 40
    margin_t = 100; margin_b = 200
    plot_w = canvas_w - margin_l - margin_r
    plot_h = canvas_h - margin_t - margin_b
    timeline_y = margin_t + plot_h / 2

    parts = [f'<rect width="{canvas_w}" height="{canvas_h}" fill="#0A0A0E"/>']

    # Title
    parts.append(f'<text x="{margin_l}" y="36" font-family="ui-monospace,monospace" '
                 f'font-size="22" font-weight="700" fill="#FFFFFF">'
                 f'Artifact timeline — {len(positions)} artifacts on the spine</text>')
    parts.append(f'<text x="{margin_l}" y="60" font-family="ui-monospace,monospace" '
                 f'font-size="12" fill="#9090A0">'
                 f'each dot is one artifact at its t-position · '
                 f'phase regions coloured along the rail · '
                 f'sequence bands above</text>')

    # Phase backdrop bands
    phase_count = len(PHASE_ORDER)
    for i, phase in enumerate(PHASE_ORDER):
        t_lo = i / phase_count; t_hi = (i + 1) / phase_count
        x1 = margin_l + plot_w * t_lo
        x2 = margin_l + plot_w * t_hi
        col = PHASE_COLORS[phase]
        parts.append(f'<rect x="{x1}" y="{margin_t + 10}" '
                     f'width="{x2 - x1}" height="{plot_h - 20}" '
                     f'fill="{col}" fill-opacity="0.06"/>')
        # Phase label
        parts.append(f'<text x="{(x1 + x2) / 2}" y="{margin_t - 12}" '
                     f'font-family="ui-monospace,monospace" font-size="13" '
                     f'font-weight="600" fill="{col}" text-anchor="middle">{phase}</text>')

    # Sequence bands along top (just inside phase region)
    spine_seqs = spine["spine"]["sequences"]
    for entry in spine_seqs:
        name = entry["name"]
        order = entry["order"]
        n = len(spine_seqs)
        t_lo = (order - 1) / n; t_hi = order / n
        x1 = margin_l + plot_w * t_lo
        x2 = margin_l + plot_w * t_hi
        col = PHASE_COLORS.get(entry["phase"], "#888")
        # Band
        parts.append(f'<rect x="{x1}" y="{margin_t + 15}" '
                     f'width="{x2 - x1 - 1}" height="20" '
                     f'fill="{col}" fill-opacity="0.18" stroke="{col}" stroke-width="0.5"/>')
        # Rotated label
        cx = (x1 + x2) / 2
        parts.append(f'<text x="{cx}" y="{margin_t + 30}" '
                     f'font-family="ui-monospace,monospace" font-size="8" '
                     f'fill="#E8E8EE" text-anchor="middle">{name[:10]}</text>')

    # Central rail
    parts.append(f'<line x1="{margin_l}" y1="{timeline_y}" '
                 f'x2="{margin_l + plot_w}" y2="{timeline_y}" '
                 f'stroke="#3A3A45" stroke-width="2"/>')

    # Bucket-aggregate to avoid 1900 individual circles overlapping
    # Build a histogram of artifact counts per phase per fine bucket
    n_buckets = 200
    bucket_size = 1.0 / n_buckets
    buckets: dict[int, list[tuple[float, str, str]]] = defaultdict(list)
    for a in artifacts:
        name = a["lookup_name"]
        if name not in positions: continue
        t = positions[name]
        s = seq_of.get(name, "unplaced")
        phase = seq_positions.get(s, {}).get("phase", "synthesis")
        bi = min(n_buckets - 1, int(t * n_buckets))
        buckets[bi].append((t, name, phase))

    # Render each bucket as a stack of small dots (jitter Y by index)
    DOT_R = 2.5
    for bi, members in buckets.items():
        for j, (t, name, phase) in enumerate(members):
            x = margin_l + plot_w * t
            # Stack alternating above/below the rail
            row = (j + 1) // 2
            sign = -1 if j % 2 == 0 else 1
            y_off = sign * (DOT_R * 2.2 * (row + 0.5))
            y = timeline_y + y_off
            col = PHASE_COLORS.get(phase, "#888")
            parts.append(f'<circle cx="{x}" cy="{y}" r="{DOT_R}" fill="{col}" '
                         f'fill-opacity="0.75" stroke="#0A0A0E" stroke-width="0.3"/>')

    # Density histogram below
    hist_y = canvas_h - margin_b + 30
    hist_h = 80
    parts.append(f'<text x="{margin_l}" y="{hist_y - 6}" '
                 f'font-family="ui-monospace,monospace" font-size="11" '
                 f'fill="#9090A0">density (artifacts per bucket)</text>')
    max_count = max((len(v) for v in buckets.values()), default=1)
    for bi in range(n_buckets):
        n = len(buckets.get(bi, []))
        if n == 0: continue
        x1 = margin_l + plot_w * (bi / n_buckets)
        w = plot_w / n_buckets
        h = (n / max_count) * hist_h
        # Color by majority phase in bucket
        if buckets.get(bi):
            phase = max((m[2] for m in buckets[bi]),
                        key=lambda p: sum(1 for m in buckets[bi] if m[2] == p))
            col = PHASE_COLORS.get(phase, "#888")
        else:
            col = "#888"
        parts.append(f'<rect x="{x1}" y="{hist_y + hist_h - h}" '
                     f'width="{w - 0.5}" height="{h}" '
                     f'fill="{col}" fill-opacity="0.7"/>')

    # Stats at bottom
    stats_y = canvas_h - 60
    n_placed = sum(1 for a in artifacts if a["lookup_name"] in positions)
    n_unplaced = sum(1 for a in artifacts if seq_of.get(a["lookup_name"]) == "unplaced")
    parts.append(f'<text x="{margin_l}" y="{stats_y}" '
                 f'font-family="ui-monospace,monospace" font-size="12" '
                 f'fill="#E8E8EE">{n_placed} artifacts positioned · '
                 f'{n_unplaced} unplaced (no sequence membership) · '
                 f'max density: {max_count} artifacts in one bucket</text>')

    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{canvas_w}" height="{canvas_h}" '
            f'viewBox="0 0 {canvas_w} {canvas_h}">{"".join(parts)}</svg>')


# ─────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--iterations", type=int, default=20)
    p.add_argument("--report", action="store_true")
    args = p.parse_args()

    if args.report:
        with open(OUT_DIR / "timeline.json", "r", encoding="utf-8") as f:
            data = json.load(f)
        print(f"timeline contains {len(data['positions'])} artifacts")
        return

    print("loading spine + sequences + artifacts...")
    spine = load_spine()
    seq_positions = build_sequence_positions(spine, include_branches=True)
    artifacts = load_artifacts()
    spine_count = sum(1 for v in seq_positions.values() if v["in_spine"])
    branch_count = len(seq_positions) - spine_count
    print(f"  {len(artifacts)} artifacts in registry")
    print(f"  {spine_count} spine sequences + {branch_count} branch sequences with t-ranges")

    print("scanning all maps for ground-truth artifact→sequence membership...")
    map_derived = build_artifact_to_sequences()
    print(f"  {len(map_derived)} artifacts found in at least one map's interactables")

    pins = load_pins()
    if pins:
        print(f"  {len(pins)} manual pins loaded from {PINS_PATH.relative_to(ROOT)}")
    pinned_set: set[str] = set(pins.keys())

    # Map artifact → its primary sequence
    seq_of: dict[str, str] = {}
    positions: dict[str, float] = {}
    for a in artifacts:
        name = a["lookup_name"]
        if name in pins:
            # Pinned: t is fixed; still resolve sequence for grouping
            _, seq, _ = initial_position(a, seq_positions, map_derived)
            positions[name] = pins[name]
            seq_of[name] = seq
        else:
            t, seq, phase = initial_position(a, seq_positions, map_derived)
            positions[name] = t
            seq_of[name] = seq

    initial_e = compute_energy(positions, artifacts, seq_positions, seq_of)
    print(f"  initial energy: {initial_e['total']:.4f}")
    print(f"    sequence_coherence: {initial_e['sequence_coherence']:.4f}")
    print(f"    phase_alignment:    {initial_e['phase_alignment']:.4f}")
    print(f"    density_smoothness: {initial_e['density_smoothness']:.4f}")

    print(f"relaxing for {args.iterations} iterations...")
    relax_positions(positions, artifacts, seq_positions, seq_of, args.iterations,
                    pinned=pinned_set)
    final_e = compute_energy(positions, artifacts, seq_positions, seq_of)
    print(f"  final energy: {final_e['total']:.4f}")
    print(f"    sequence_coherence: {final_e['sequence_coherence']:.4f}")
    print(f"    phase_alignment:    {final_e['phase_alignment']:.4f}")
    print(f"    density_smoothness: {final_e['density_smoothness']:.4f}")

    # Write JSON
    out_data = {
        "n_artifacts":   len(artifacts),
        "n_placed":      len(positions),
        "energy_initial": initial_e,
        "energy_final":   final_e,
        "phase_bands": {
            phase: [i / len(PHASE_ORDER), (i + 1) / len(PHASE_ORDER)]
            for i, phase in enumerate(PHASE_ORDER)
        },
        "sequence_positions": seq_positions,
        "positions": {
            name: {
                "t":         round(positions[name], 4),
                "sequence":  seq_of.get(name, "unplaced"),
                "phase":     seq_positions.get(seq_of.get(name, ""), {}).get("phase", "synthesis"),
            }
            for name in positions
        },
    }
    json_path = OUT_DIR / "timeline.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(out_data, f, indent=2)
    print(f"wrote {json_path}")

    # Render SVG
    svg = render_timeline_svg(positions, artifacts, seq_positions, seq_of, spine)
    svg_path = OUT_DIR / "timeline.svg"
    svg_path.write_text(svg, encoding="utf-8")
    print(f"wrote {svg_path}")

    # Also copy to encyclopedia public so the URL works in any /timeline page
    enc_public = ROOT.parent / "ada_encyclopedia" / "public" / "placement_research"
    if enc_public.exists():
        (enc_public / "timeline.svg").write_text(svg, encoding="utf-8")
        with open(enc_public / "timeline.json", "w", encoding="utf-8") as f:
            json.dump(out_data, f, indent=2)
        print(f"also wrote {enc_public.relative_to(ROOT.parent)}/timeline.{{svg,json}}")


if __name__ == "__main__":
    main()
