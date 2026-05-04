#!/usr/bin/env python3
"""
Generate 10 catalyst test maps via the encyclopedia save API so they
land with the compact-rows JSON format. Each map exercises ONE catalyst
projectile mode end-to-end, mirroring the auto-research matrix lab in
``commons/testing/catalyst_matrix_lab.gd``.

The full catalyst-mode roster (each one a row in the visual matrix at
``user://catalyst_matrix/results.md``):

    01 Primitives     — bouncy white sphere, slow, transforms on contact
    02 Transformation — purple beam, instant convert, foe pushes peers
    03 Chromatic      — orange RGB pulse, foe falls through (chromatic)
    04 Forces         — blue physics-driven, foe becomes faster swarm
    05 Waveform       — pink sine wave projectile (goo)
    06 Chaos          — red turbulent shot, swarm-class foe
    07 Cellular       — green entropic, drainfriend-class foe
    08 Fractal        — purple split-and-recurse (goo)
    09 Branching      — green tree-spreading projectile (goo)
    10 Swarm          — yellow boid cluster, swarm-class foe

Each map gives the player:
  * spawn at (1, 1)
  * pedestal pre-armed with that mode at (2, 2) on a height-2 plinth
  * one or more vents emitting foes
  * teleporter at (D-2, W-2) chaining to the next map (and 10 -> 01)

Run: python tools/generate_catalyst_test_maps.py
"""

import json
import sys
import urllib.request
import urllib.error
from pathlib import Path

API = "http://localhost:3003/api/voxel-editor"
W, D = 12, 10  # cells (floor extent)


# ────────────────────────────────────────────────────────────────────
# MODE ROSTER — must match commons/testing/catalyst_matrix_lab.gd
# ────────────────────────────────────────────────────────────────────
# Each entry pairs a projectile mode with the test map's flavour: how
# many vents, how fast they fire, how big the wave. We exaggerate the
# mode's character a little so each arena feels distinct in VR.
MODES: list[dict] = [
    {
        "slug": "Primitives",
        "mode": "primitives",
        "summary": "Bouncy white sphere, slow. Transforms foe -> GOO.",
        "vents": [(5, 6, 2.0, 5)],  # (row, col, rate_s, wave_size)
    },
    {
        "slug": "Transformation",
        "mode": "transformation",
        "summary": "Purple beam, instant. Foe -> TRANSPORT (pushes peers).",
        "vents": [(5, 6, 2.5, 4)],
    },
    {
        "slug": "Chromatic",
        "mode": "chromatic",
        "summary": "Orange RGB pulse. Foe -> GOO (chromatic falls through).",
        "vents": [(5, 6, 2.0, 5)],
    },
    {
        "slug": "Forces",
        "mode": "forces",
        "summary": "Blue physics-driven. Foe -> SWARM (faster, bigger).",
        "vents": [(5, 6, 1.5, 6)],
    },
    {
        "slug": "Waveform",
        "mode": "waveform",
        "summary": "Pink sine wave. Foe -> GOO.",
        "vents": [(5, 6, 2.0, 5)],
    },
    {
        "slug": "Chaos",
        "mode": "chaos",
        "summary": "Red turbulent shot. Foe -> SWARM (chaos).",
        "vents": [(5, 6, 1.4, 7), (5, 9, 2.0, 4)],  # double vent
    },
    {
        "slug": "Cellular",
        "mode": "cellular",
        "summary": "Green entropic. Foe -> DRAINFRIEND (entropy).",
        "vents": [(5, 6, 2.0, 5)],
    },
    {
        "slug": "Fractal",
        "mode": "fractal",
        "summary": "Purple split-and-recurse. Foe -> GOO.",
        "vents": [(5, 6, 2.0, 5)],
    },
    {
        "slug": "Branching",
        "mode": "branching",
        "summary": "Green tree-spreading. Foe -> GOO.",
        "vents": [(5, 6, 2.0, 5)],
    },
    {
        "slug": "Swarm",
        "mode": "swarm",
        "summary": "Yellow boid cluster. Foe -> SWARM.",
        "vents": [(2, 8, 2.5, 4), (7, 8, 2.5, 4)],  # double vent
    },
]


def map_name(idx: int, slug: str) -> str:
    return f"Catalyst_{idx:02d}_{slug}"


def base_map(name: str) -> dict:
    """A 12×10 open arena with floor at h=1 everywhere, no walls."""
    structure = [["1"] * W for _ in range(D)]
    utilities = [[" "] * W for _ in range(D)]
    interactables = [[" "] * W for _ in range(D)]
    biome_paint = [[" "] * W for _ in range(D)]
    # spawn at (1, 1) — actual teleporter target slot is filled per map below
    utilities[1][1] = "sp"
    return {
        "map_info": {
            "name": name,
            "lookup_name": name,
            "format": "json",
            "version": "1.0",
            "dimensions": {"width": W, "depth": D, "max_height": 5},
            "metadata": {"source": "catalyst_test_generator"},
        },
        "layers": {
            "structure": structure,
            "utilities": utilities,
            "interactables": interactables,
            "biome_paint": biome_paint,
        },
        "settings": {
            "cube_size": 1, "gutter": 0, "show_grid": True,
            "background": {"type": "sky", "color": [0.08, 0.10, 0.18]},
            "grid_animation": {"enabled": False},
            "initial_tile_visibility": "all_visible",
        },
        "utility_definitions": {
            "sp": {"type": "spawn"}, "t": {"type": "teleporter"},
        },
    }


def place_vent(m: dict, r: int, c: int, rate_s: float = 2.0,
               wave: int = 5, damage_percent: float | None = None,
               start_delay_s: float = 3.0) -> None:
    """Place a catalyst_vent in interactables.

    Token grammar (Ada Research interactable convention):
      <lookup_name>:<rotation>:<y_offset>[#key:value[#key:value...]]
    Position uses ':' separator, config keys use '#' separator.
    See _parse_config_token in GridInteractablesComponent.gd.
    """
    config_parts = [
        f"emit_interval_s:{rate_s}",
        f"wave_size:{wave}",
        f"start_delay_s:{start_delay_s}",
    ]
    if damage_percent is not None:
        config_parts.append(f"damage_percent:{damage_percent}")
    tok = "catalyst_vent:0:0#" + "#".join(config_parts)
    m["layers"]["interactables"][r][c] = tok


def place_pedestal(m: dict, r: int, c: int, active_mode: str) -> None:
    """Place a catalyst on a height-2 plinth pre-armed with one mode.

    `shooting_only:true` skips voxel/wedge placement modes so the player
    can shoot immediately. `start_mode` and `active_mode` are both set
    to the same projectile mode — `start_mode` arms the bracelet at
    spawn and `active_mode` selects which stone is glowing.
    """
    parts = [
        "shooting_only:true",
        f"start_mode:{active_mode}",
        f"active_mode:{active_mode}",
    ]
    # Height-2 plinth under the catalyst — gives the player a visible
    # box to walk up to and reach the bracelet at hand-grab height.
    m["layers"]["structure"][r][c] = "2"
    m["layers"]["interactables"][r][c] = (
        "becoming_catalyst#" + "#".join(parts)
    )


def place_teleporter(m: dict, target_map: str) -> None:
    """Drop the teleporter at (D-2, W-2) targeting ``target_map``."""
    m["layers"]["utilities"][D - 2][W - 2] = f"t:{target_map}"


def build_one(idx: int, mode_def: dict, next_map: str) -> tuple[str, dict]:
    name = map_name(idx, mode_def["slug"])
    m = base_map(name)
    place_pedestal(m, 2, 2, mode_def["mode"])
    for vent in mode_def["vents"]:
        place_vent(m, *vent)
    place_teleporter(m, next_map)
    return name, m


def post_save(name: str, data: dict) -> bool:
    body = json.dumps({"mapName": name, "data": data}).encode("utf-8")
    req = urllib.request.Request(
        API, data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        resp = urllib.request.urlopen(req, timeout=15)
    except urllib.error.URLError as e:
        print(f"  FAIL: {name} — {e}")
        return False
    if resp.status != 200:
        print(f"  FAIL: {name} — HTTP {resp.status}")
        return False
    return True


def main() -> int:
    print(f"Generating {len(MODES)} catalyst test maps via {API}...")
    # Pre-compute names so each map can teleport to the NEXT one (and
    # the last loops back to the first for a continuous test loop).
    names = [map_name(i + 1, m["slug"]) for i, m in enumerate(MODES)]
    written: list[str] = []
    for i, mode_def in enumerate(MODES):
        next_idx = (i + 1) % len(MODES)
        name, data = build_one(i + 1, mode_def, names[next_idx])
        if post_save(name, data):
            print(f"  OK {name:<32} {mode_def['summary']}")
            written.append(name)

    # Write a sequence file so they appear in the editor's map browser.
    seq_path = Path("commons/maps/sequences/catalyst_test.json")
    seq_data = {
        "sequences": {
            "catalyst_test": {
                "name": "Catalyst Tests: 10 modes vs. one foe",
                "truth": "the catalyst doesn't kill — it phase-shifts",
                "description": (
                    "10 small arenas, one per catalyst projectile mode. "
                    "Mirrors the auto-research matrix lab. Walk through "
                    "each to feel how every mode lands on a fresh foe."
                ),
                "layer": "test",
                "maps": written,
                "prerequisites": [],
                "unlocks": [],
            }
        }
    }
    seq_path.parent.mkdir(parents=True, exist_ok=True)
    seq_path.write_text(json.dumps(seq_data, indent=2, ensure_ascii=False),
                        encoding="utf-8")
    print(f"\nWrote sequence file: {seq_path} ({len(written)} maps)")
    return 0 if len(written) == len(MODES) else 1


if __name__ == "__main__":
    sys.exit(main())
