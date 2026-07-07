"""tools/generate_from_prompt.py — prompt markdown → map_data.json.

Reads a prompt file (output of `describe_map.py`, with the YAML section at the
bottom) and materializes a new map. Edit the prompt before running this.

Tweak examples:
  - change `archetype: promenade` → `cathedral` to re-route the layout strategy
  - change `width: 7` → `width: 11` to expand the map
  - add `row` / `col` / `t` lines under an artifact to nudge its position
  - add new artifact entries with `name:` + `t:` + `lane:` to place new things

If positions are missing (only `name:` given), the auto-selector picks slots
using the archetype's natural flow.

Run:
  python tools/generate_from_prompt.py --in=trans_rotation.prompt.md \
                                       --out-name=MyTrans_Rotation_Variant
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
MAPS_DIR = ROOT / "commons" / "maps"
PROMPT_DIR = ROOT / "doc" / "placement_research" / "prompts"


# ─────────────────────────────────────────────────────────────────────
# Parse the YAML section at the bottom of the prompt
# ─────────────────────────────────────────────────────────────────────

def parse_prompt(text: str) -> dict:
    """Parse the markdown prompt. The YAML block at the bottom is authoritative;
    the prose section is for humans. We use a tiny YAML reader (we only need
    flat keys + a list of artifact dicts)."""
    # Find the ```yaml ... ``` block
    m = re.search(r"```yaml\s*(.+?)```", text, re.DOTALL)
    if not m:
        raise ValueError("prompt has no ```yaml ...``` block — describe_map.py adds one")
    yaml_text = m.group(1)
    return tiny_yaml(yaml_text)


def tiny_yaml(text: str) -> dict:
    """Tiny YAML parser. Handles flat key/value + a `structure: |` block-string
    + a list of `artifacts:` and `utilities:` dicts. Good enough for
    describe → tweak → generate."""
    out: dict = {}
    lines = text.split("\n")
    i = 0

    def parse_list_of_dicts() -> list[dict]:
        """Consume indented `- key: value` items until indentation changes."""
        nonlocal i
        items: list[dict] = []
        while i < len(lines) and (lines[i].startswith("  ") or lines[i] == ""):
            if lines[i].strip() == "":
                i += 1; continue
            if lines[i].startswith("  - "):
                item: dict = {}
                first = lines[i][4:].strip()
                if ":" in first:
                    k, v = first.split(":", 1)
                    item[k.strip()] = parse_value(v.strip())
                i += 1
                while i < len(lines) and lines[i].startswith("    "):
                    sub = lines[i][4:].strip()
                    if ":" in sub:
                        k, v = sub.split(":", 1)
                        item[k.strip()] = parse_value(v.strip())
                    i += 1
                items.append(item)
            else:
                break
        return items

    while i < len(lines):
        line = lines[i].rstrip()
        i += 1
        if not line or line.lstrip().startswith("#"): continue
        if line.startswith(" "): continue
        m = re.match(r"^([a-zA-Z_]+):\s*(.*)$", line)
        if not m: continue
        key, value = m.group(1), m.group(2).strip()

        if key == "structure" and value == "|":
            # Block scalar: each subsequent indented line is one row.
            rows: list[str] = []
            while i < len(lines) and (lines[i].startswith("  ") or lines[i] == ""):
                if lines[i].strip() == "":
                    i += 1; continue
                rows.append(lines[i].lstrip())
                i += 1
            out["structure"] = rows
        elif key in ("artifacts", "utilities"):
            out[key] = parse_list_of_dicts()
        else:
            out[key] = parse_value(value)
    return out


def parse_value(v: str):
    v = v.strip()
    if v.startswith("[") and v.endswith("]"):
        parts = [p.strip() for p in v[1:-1].split(",")]
        return [parse_value(p) for p in parts]
    try:
        if "." in v: return float(v)
        return int(v)
    except ValueError:
        return v.strip('"').strip("'")


# ─────────────────────────────────────────────────────────────────────
# Artifact position resolution
# ─────────────────────────────────────────────────────────────────────

def resolve_position(a: dict, W: int, D: int,
                     spawn: tuple[int, int],
                     teleporter: tuple[int, int]) -> tuple[int, int]:
    """An artifact entry might specify any of: row+col, t+lane, t alone, lane alone.
    Resolve to a single (row, col) inside the map.
    """
    # Explicit row/col wins
    if "row" in a and "col" in a:
        return int(a["row"]), int(a["col"])
    # t along walk + optional lane
    t = float(a.get("t", 0.5))
    lane = str(a.get("lane", "spine")).lower()
    # Compute row from t
    dr = teleporter[0] - spawn[0]
    dc = teleporter[1] - spawn[1]
    r = spawn[0] + int(round(dr * t))
    c = spawn[1] + int(round(dc * t))
    # Apply lane offset perpendicular to the walk
    walk_is_vertical = abs(dr) >= abs(dc)
    if walk_is_vertical:
        # perpendicular = column axis
        spine = W // 2
        if lane == "spine": c = spine
        elif lane in ("left", "left_wall", "left-wall"): c = max(0, spine - 3)
        elif lane in ("right", "right_wall", "right-wall"): c = min(W - 1, spine + 3)
        elif lane.startswith("col="):
            try: c = int(lane.split("=", 1)[1])
            except: pass
    else:
        spine = D // 2
        if lane == "spine": r = spine
        elif lane in ("left", "left_wall"): r = max(0, spine - 3)
        elif lane in ("right", "right_wall"): r = min(D - 1, spine + 3)
    # Clamp
    r = max(0, min(D - 1, r))
    c = max(0, min(W - 1, c))
    return r, c


# ─────────────────────────────────────────────────────────────────────
# Archetype-specific structure (minimal — full floor for now; archetype
# generators in generate_archetype_maps.py / _2.py are the rich version)
# ─────────────────────────────────────────────────────────────────────

def archetype_structure(archetype: str, W: int, D: int) -> list[list[str]]:
    """Returns a structure layer suited to the archetype. For unknown archetypes,
    just full floor.

    To get richer structures, the prompt-flow can be combined with the existing
    archetype generators — generate the structure via `generate_archetype_maps.py`
    and only use this tool for the artifact layer.
    """
    # All floor by default
    struct = [["2"] * W for _ in range(D)]
    if archetype == "bridge":
        # Carve a narrow spine, void on sides
        for r in range(D):
            for c in range(W):
                if c < W // 2 - 1 or c > W // 2 + 1:
                    struct[r][c] = "0"
    elif archetype == "pit":
        # Border walls + raised inner ring + sunken centre
        for r in range(D):
            for c in range(W):
                if r == 0 or r == D - 1 or c == 0 or c == W - 1:
                    struct[r][c] = "5"
                elif r == 1 or r == D - 2 or c == 1 or c == W - 2:
                    struct[r][c] = "3"
                else:
                    struct[r][c] = "2"
        # Sunken middle
        cy, cx = D // 2, W // 2
        for r in range(max(2, cy - 3), min(D - 2, cy + 4)):
            for c in range(max(2, cx - 3), min(W - 2, cx + 4)):
                struct[r][c] = "1"
    elif archetype in ("maze", "dungeon"):
        # Walled — leave the path-clearing to a richer generator;
        # for prompt-quick-gen, just mostly walls with a corridor
        for r in range(D):
            for c in range(W):
                struct[r][c] = "5"
        # Carve a simple zigzag path
        for r in range(D):
            struct[r][W // 2] = "2"
            if r % 3 == 0:
                for c in range(max(1, W // 2 - 2), min(W - 1, W // 2 + 3)):
                    struct[r][c] = "2"
    return struct


# ─────────────────────────────────────────────────────────────────────
# Generator
# ─────────────────────────────────────────────────────────────────────

def generate(prompt_data: dict, out_name: str) -> Path:
    archetype = prompt_data.get("archetype", "promenade")
    W = int(prompt_data.get("width", 9))
    D = int(prompt_data.get("depth", 24))

    # Spawn / teleporter
    spawn = tuple(prompt_data.get("spawn", [D - 1, W // 2]))[:2]
    teleporter = tuple(prompt_data.get("teleporter", [0, W // 2]))[:2]
    spawn = (int(spawn[0]), int(spawn[1]))
    teleporter = (int(teleporter[0]), int(teleporter[1]))

    # Structure — prefer explicit YAML structure block (lossless round-trip);
    # fall back to archetype template if absent.
    explicit_struct = prompt_data.get("structure")
    if isinstance(explicit_struct, list) and explicit_struct:
        struct = []
        for raw in explicit_struct[:D]:
            row = list(raw[:W])
            if len(row) < W:
                row.extend(["0"] * (W - len(row)))
            struct.append(row)
        while len(struct) < D:
            struct.append(["0"] * W)
    else:
        struct = archetype_structure(archetype, W, D)
    util = [[" "] * W for _ in range(D)]
    inter = [[" "] * W for _ in range(D)]

    # Extra utilities (anything other than spawn/teleporter — ramps, transport
    # cubes, jump pads…). Round-tripped verbatim from the source map.
    for u in prompt_data.get("utilities") or []:
        if "row" in u and "col" in u and "token" in u:
            r = int(u["row"]); c = int(u["col"])
            if 0 <= r < D and 0 <= c < W:
                util[r][c] = str(u["token"])

    # Place utilities — ensure walkable cells at spawn / teleporter
    if struct[spawn[0]][spawn[1]] in ("0", "5"):
        struct[spawn[0]][spawn[1]] = "2"
    if struct[teleporter[0]][teleporter[1]] in ("0", "5"):
        struct[teleporter[0]][teleporter[1]] = "2"
    util[spawn[0]][spawn[1]] = "sp"
    util[teleporter[0]][teleporter[1]] = "t"

    # Artifacts
    placed: list[dict] = []
    for a in prompt_data.get("artifacts") or []:
        if "name" not in a: continue
        r, c = resolve_position(a, W, D, spawn, teleporter)
        # Avoid overlapping spawn/teleporter
        if (r, c) == spawn or (r, c) == teleporter:
            # Nudge by 1 row
            r = min(D - 1, max(0, r + 1))
        # Ensure walkable beneath
        if struct[r][c] in ("0", "5"):
            struct[r][c] = "2"
        rot = int(a.get("rot", 0) or 0)
        inter[r][c] = f"{a['name']}:{rot}:0.0"
        placed.append({"name": a["name"], "row": r, "col": c})

    map_data = {
        "map_info": {
            "name":         out_name,
            "lookup_name":  out_name,
            "description":  f"Generated from prompt — archetype: {archetype}. "
                            f"See doc/placement_research/prompts/.",
            "version":      "prompt-generated-0.1",
            "format":       "json",
            "created_from": "tools/generate_from_prompt.py",
            "dimensions":   {"width": W, "depth": D, "max_height": 5},
            "metadata":     {"category": "prompt_generated",
                              "archetype": archetype,
                              "n_artifacts": len(placed)},
            "title":        out_name,
        },
        "utility_definitions": {
            "sp": {"name": "Spawn", "description": "Player spawn point", "type": "spawn"},
            "t":  {"name": "Exit Portal", "description": "Step here to leave",
                   "type": "teleporter",
                   "properties": {"action": "next_in_sequence"}},
        },
        "documentation": {
            "summary":  f"{out_name} — generated from prompt",
            "layout":   f"{W}×{D}, archetype {archetype}",
            "objective": "Walk the prompted layout.",
            "key_elements": [
                f"Spawn at ({spawn[0]}, {spawn[1]})",
                f"Teleporter at ({teleporter[0]}, {teleporter[1]})",
                *[f"{p['name']} at ({p['row']}, {p['col']})" for p in placed],
            ],
        },
        "lighting": {"ambient_color": [0.30, 0.32, 0.40], "ambient_energy": 0.9,
                     "directional_light": {"enabled": True,
                                            "direction": [-0.3, -1.0, -0.2],
                                            "energy": 0.7}},
        "settings": {"player_spawn_height": 0.5, "floor_tile_size": 1.0},
        "layers": {"structure": struct, "utilities": util, "interactables": inter},
    }

    out_dir = MAPS_DIR / out_name
    out_dir.mkdir(exist_ok=True)
    out_path = out_dir / "map_data.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(map_data, f, indent="\t")
    # Brief intent + blurb
    (out_dir / "intent.md").write_text(
        f"Concept: A map generated from a prompt. Archetype = {archetype}.\n\n"
        f"Actualizes: A round-trip through the description layer — read a map, "
        f"edit the prompt, generate a variant.\n\n"
        f"Sequence role: Demonstration / test artifact.\n\n"
        f"Technical angle: {W}×{D} cells, archetype {archetype}, {len(placed)} placed.\n\n"
        f"Critical angle: The prompt is the editable contract. Tweaking it produces "
        f"a new map without writing code.\n\n"
        f"Key artifacts:\n" +
        "\n".join(f"- {p['name']} at ({p['row']}, {p['col']})" for p in placed) +
        "\n\nGap: Prompt → structure mapping is currently coarse; rich archetype shapes "
        f"are handled by tools/generate_archetype_maps.py.\n",
        encoding="utf-8")
    (out_dir / "blurb.md").write_text(
        f"A prompt-generated map in the {archetype} archetype. {len(placed)} placed.\n",
        encoding="utf-8")
    return out_path


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--in", dest="input", type=str, required=True,
                   help="prompt markdown file (output of describe_map.py)")
    p.add_argument("--out-name", type=str, required=True,
                   help="map name to write under commons/maps/<name>/")
    args = p.parse_args()
    in_path = Path(args.input)
    if not in_path.is_absolute():
        # Try prompt dir
        candidate = PROMPT_DIR / in_path.name
        if candidate.exists():
            in_path = candidate
    text = in_path.read_text(encoding="utf-8")
    prompt = parse_prompt(text)
    print(f"parsed prompt: archetype={prompt.get('archetype')} "
          f"width={prompt.get('width')} depth={prompt.get('depth')} "
          f"n_artifacts={len(prompt.get('artifacts') or [])}")
    out_path = generate(prompt, args.out_name)
    print(f"wrote {out_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
