"""tools/describe_map.py — read a map_data.json, write a tweakable prompt.

The prompt is the *editable middle layer*. You can:
  1. Run describe on an existing map → get a prompt
  2. Edit any line of the prompt (dimensions, archetype, artifact list)
  3. Run tools/generate_from_prompt.py on the edited prompt → get a new map

Output: a markdown file with sections for archetype + dimensions + spawn/exit
+ structure summary + artifact table + pacing notes. The file is plain
markdown — open in any editor.

Run:
  python tools/describe_map.py --map=Point_Triangle
  python tools/describe_map.py --map=Trans_Rotation --out=trans_rotation.prompt.md
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
MAPS_DIR = ROOT / "commons" / "maps"
PROMPT_DIR = ROOT / "doc" / "placement_research" / "prompts"
PROMPT_DIR.mkdir(parents=True, exist_ok=True)

TOKEN_RE = re.compile(r"^([a-zA-Z_][a-zA-Z0-9_]*)")


WALKABLE = {"1", "2", "3"}      # any of these counts as floor-ish
HEIGHT_WALL = {"4", "5"}        # walls
HEIGHT_VOID = {"0", ""}         # empty / void


def detect_archetype(W: int, D: int, struct: list[list[str]]) -> str:
    """Heuristic shape classifier — returns one of the 20 archetype names.

    FIX 2026-05-17: previously checked only height-code `2` as walkable; now
    accepts `1`, `2`, `3` so maps using non-standard floor heights (like
    Random_Definition's height-1 floor) classify correctly.
    """
    aspect = max(D, W) / max(1, min(D, W))
    heights = Counter()
    for row in struct:
        for c in row:
            heights[(c or "").strip() or "0"] += 1
    total = sum(heights.values())
    void_frac = sum(heights.get(h, 0) for h in HEIGHT_VOID) / max(1, total)
    floor_frac = sum(heights.get(h, 0) for h in WALKABLE) / max(1, total)
    table_frac = heights.get("3", 0) / max(1, total)
    wall_frac = sum(heights.get(h, 0) for h in HEIGHT_WALL) / max(1, total)

    def is_walk(cell: str) -> bool:
        return (cell or "").strip() in WALKABLE
    def is_wall(cell: str) -> bool:
        return (cell or "").strip() in HEIGHT_WALL

    # Heuristic chain — corridor archetypes win on aspect alone
    if aspect >= 3.0 and floor_frac > 0.6:
        return "promenade"
    if aspect >= 3.0 and void_frac > 0.3:
        return "bridge"
    if wall_frac > 0.4 and aspect < 1.5:
        # Many walls + roughly square — could be maze, dungeon, citadel
        n_adj = 0
        for r in range(D - 1):
            for c in range(W - 1):
                if is_wall(struct[r][c]) and is_wall(struct[r][c + 1]):
                    n_adj += 1
        if n_adj / max(1, total) > 0.15:
            return "maze"
        return "dungeon"
    # Concentric layered?
    if table_frac > 0.15 and wall_frac > 0.1:
        cr, cc = D // 2, W // 2
        center = (struct[cr][cc] or "").strip()
        corner = (struct[0][0] or "").strip()
        if center in ("3", "4", "5") and corner in HEIGHT_VOID | HEIGHT_WALL:
            return "ziggurat"
    # Cruciform check — center row + center col have more floor than corners
    if aspect < 2.0 and floor_frac > 0.4:
        cr_floor = sum(1 for c in struct[D // 2] if is_walk(c))
        col_floor = sum(1 for r in range(D) if is_walk(struct[r][W // 2]))
        corner_void_or_wall = sum(
            1 for r in [0, D - 1] for c in [0, W - 1]
            if (struct[r][c] or "").strip() in (HEIGHT_VOID | HEIGHT_WALL)
        )
        if cr_floor > W * 0.6 and col_floor > D * 0.6 and corner_void_or_wall >= 2:
            return "crossroads"
    # Default
    if floor_frac > 0.7:
        return "forum"
    return "irregular"


def find_spawn_teleporter(util: list[list[str]]) -> tuple[tuple[int, int] | None,
                                                          tuple[int, int] | None]:
    sp = te = None
    for r, row in enumerate(util):
        for c, tok in enumerate(row):
            if not isinstance(tok, str): continue
            t = tok.strip()
            if t.startswith("sp"): sp = (r, c)
            elif t == "t": te = (r, c)
    return sp, te


def t_along_walk(r: int, c: int, sp: tuple[int, int],
                  te: tuple[int, int]) -> float:
    """Fraction along the spawn→teleporter line. 0 at spawn, 1 at teleporter."""
    dr = te[0] - sp[0]
    dc = te[1] - sp[1]
    length_sq = dr * dr + dc * dc
    if length_sq == 0: return 0.5
    pr = r - sp[0]; pc = c - sp[1]
    t = (pr * dr + pc * dc) / length_sq
    return max(0.0, min(1.0, t))


def perpendicular_label(r: int, c: int, W: int, D: int) -> str:
    """Where in the perpendicular plane is this cell?
    Returns 'spine', 'left_wall', 'right_wall', 'center_offset_L', etc."""
    # Assume walk axis is depth (vertical) which is most common.
    # For width: spine=center, left/right walls at edges.
    spine = W // 2
    if c == spine: return "spine"
    if c < spine - 1: return "left"
    if c > spine + 1: return "right"
    return "spine_offset"


def describe(map_name: str) -> str:
    p = MAPS_DIR / map_name / "map_data.json"
    if not p.exists():
        return f"# Map prompt: {map_name}\n\n(map_data.json not found)\n"
    with open(p, "r", encoding="utf-8") as f:
        d = json.load(f)
    info = d.get("map_info", {})
    dim = info.get("dimensions", {})
    W = int(dim.get("width", 0)); D = int(dim.get("depth", 0))
    struct = d.get("layers", {}).get("structure", [])
    util = d.get("layers", {}).get("utilities", [])
    inter = d.get("layers", {}).get("interactables", [])

    archetype = detect_archetype(W, D, struct)
    sp, te = find_spawn_teleporter(util)

    # Structure summary
    heights = Counter()
    for row in struct:
        for c in row:
            heights[c.strip() or "0"] += 1
    total = sum(heights.values())
    height_summary = []
    if heights.get("0", 0) / max(1, total) > 0.05:
        height_summary.append(f"void {heights['0'] * 100 // total}%")
    if heights.get("2", 0) / max(1, total) > 0.05:
        height_summary.append(f"floor {heights['2'] * 100 // total}%")
    if heights.get("3", 0) / max(1, total) > 0.02:
        height_summary.append(f"raised {heights['3'] * 100 // total}%")
    if (heights.get("5", 0) + heights.get("4", 0)) / max(1, total) > 0.02:
        wf = (heights.get("5", 0) + heights.get("4", 0)) * 100 // total
        height_summary.append(f"walls {wf}%")

    # Interactables — collect with positions + classify
    artifacts = []
    aspect = max(D, W) / max(1, min(D, W))
    for r, row in enumerate(inter):
        for c, tok in enumerate(row):
            if not isinstance(tok, str) or not tok.strip(): continue
            m = TOKEN_RE.match(tok.strip())
            if not m: continue
            name = m.group(1)
            # Compute t along walk if we have sp + te
            t = t_along_walk(r, c, sp, te) if (sp and te) else 0.5
            perp = perpendicular_label(r, c, W, D)
            artifacts.append({
                "name": name, "row": r, "col": c, "t": round(t, 3),
                "perp": perp,
            })

    # Format
    lines = []
    lines.append(f"# Map prompt: {map_name}")
    lines.append("")
    lines.append(f"*Auto-generated from `commons/maps/{map_name}/map_data.json`. "
                 f"Edit any line; re-generate via `tools/generate_from_prompt.py`.*")
    lines.append("")
    lines.append(f"**Archetype**: `{archetype}`  *(promenade · pit · ziggurat · "
                 f"dungeon · cathedral · amphitheater · spiral · hub_spokes · atrium · "
                 f"crossroads · forum · bridge · tower · maze · stacks · cave · theater · "
                 f"quadrants · citadel · constellation · irregular)*")
    lines.append(f"**Dimensions**: {W} wide × {D} deep × {dim.get('max_height', 3)} tall")
    lines.append(f"**Aspect ratio**: {aspect:.2f}  *(>2 = corridor, ~1 = room)*")
    if sp: lines.append(f"**Spawn**: row {sp[0]}, col {sp[1]}")
    if te: lines.append(f"**Teleporter**: row {te[0]}, col {te[1]}")
    lines.append(f"**Structure**: {' · '.join(height_summary) if height_summary else 'mostly empty'}")
    lines.append("")
    lines.append("## Artifacts")
    lines.append("")
    if artifacts:
        lines.append("| t | row | col | lane | name |")
        lines.append("|---|---|---|---|---|")
        # Sort by t along walk
        for a in sorted(artifacts, key=lambda x: x["t"]):
            lines.append(f"| {a['t']:.2f} | {a['row']} | {a['col']} | "
                         f"{a['perp']} | `{a['name']}` |")
    else:
        lines.append("*(no interactables placed)*")
    lines.append("")
    lines.append("## Pacing")
    lines.append("")
    if len(artifacts) >= 2:
        # Compute spacing along walk
        sorted_t = sorted([a["t"] for a in artifacts])
        gaps = [sorted_t[i + 1] - sorted_t[i] for i in range(len(sorted_t) - 1)]
        median_gap = sorted(gaps)[len(gaps) // 2] if gaps else 0
        lines.append(f"- {len(artifacts)} artifacts along the walk")
        lines.append(f"- median spacing between consecutive artifacts: t={median_gap:.2f} "
                     f"(≈ {int(median_gap * D)} cells)")
        if median_gap < 0.08:
            lines.append("- tight rhythm — most rows have an artifact")
        elif median_gap < 0.15:
            lines.append("- Mario-like pacing — encounter every few cells")
        else:
            lines.append("- sparse rhythm — long breathing rooms between artifacts")
    lines.append("")
    lines.append("## Notes")
    lines.append("")
    lines.append("- Edit any value above. Lines that start with `**Field**:` are parsed by the generator.")
    lines.append("- Artifact table positions can be given as `t=0.6 spine` or `row=12 col=5` — both work.")
    lines.append("- Changing the archetype tag re-routes the placement engine to a different strategy.")
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("```yaml")
    lines.append("# Machine-readable section (the generator reads here first)")
    lines.append(f"archetype: {archetype}")
    lines.append(f"width: {W}")
    lines.append(f"depth: {D}")
    if sp: lines.append(f"spawn: [{sp[0]}, {sp[1]}]")
    if te: lines.append(f"teleporter: [{te[0]}, {te[1]}]")
    # Structure layer — one row per line as a quoted string.
    # Delete this block to fall back to the archetype's structure template.
    lines.append("structure: |")
    for row in struct[:D]:
        # Encode empties as "0" so the row is always exactly W cells wide
        encoded = "".join(((c or "").strip() or "0") for c in row[:W])
        # Pad short rows
        if len(encoded) < W:
            encoded += "0" * (W - len(encoded))
        lines.append(f"  {encoded}")
    # Utilities other than spawn/teleporter (e.g. ramps, transport cubes)
    extra_utilities = []
    for r, row in enumerate(util):
        for c, tok in enumerate(row):
            if not isinstance(tok, str): continue
            t = tok.strip()
            if not t or t.startswith("sp") or t == "t": continue
            extra_utilities.append((r, c, t))
    if extra_utilities:
        lines.append("utilities:")
        for (r, c, t) in extra_utilities:
            lines.append(f"  - row: {r}")
            lines.append(f"    col: {c}")
            lines.append(f"    token: \"{t}\"")
    lines.append("artifacts:")
    for a in sorted(artifacts, key=lambda x: x["t"]):
        lines.append(f"  - name: {a['name']}")
        lines.append(f"    row: {a['row']}")
        lines.append(f"    col: {a['col']}")
        lines.append(f"    t: {a['t']:.3f}")
        lines.append(f"    lane: {a['perp']}")
    lines.append("```")
    return "\n".join(lines)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--map", type=str, required=True)
    p.add_argument("--out", type=str, default=None)
    args = p.parse_args()
    prompt = describe(args.map)
    out_path = Path(args.out) if args.out else (PROMPT_DIR / f"{args.map}.prompt.md")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(prompt, encoding="utf-8")
    print(f"wrote {out_path}")
    print()
    print(prompt[:1500])
    print("...")


if __name__ == "__main__":
    main()
