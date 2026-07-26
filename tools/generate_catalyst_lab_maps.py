#!/usr/bin/env python3
"""
Generate the ``catalyst_lab`` sequence — 6 arenas that test the catalyst's
SEQUENCE-BINDING logic (not the mode roster; that's ``catalyst_test``).

What binds where (see commons/hazards/catalyst_sequence_binding.gd):
  the catalyst resolves a sequence -> its native projectile mode;
  the vent resolves the SAME sequence -> its brood's friend kind;
  the capability manager maps the mode -> a lasting friend power.

The six maps walk the relation:

  01 Home            — sequence:auto on both sides while catalyst_lab
                       itself is running. catalyst_lab has NO binding
                       entry, so this is the negative test: catalyst =
                       knowledge only, brood = default GOO. Nothing new
                       may fire here.
  02 Pair_Primitives — both sides pinned sequence:primitives. Native
                       mode 'primitives' armed on pickup; goo brood;
                       first FRIEND grants Shield.
  03 Pair_Transform  — sequence:transformation. Purple beam native;
                       transport brood (friends shove peers); Porter.
  04 Pair_Waveform   — sequence:wavefunctions. Waveform native; wave
                       brood (slow-pulse friends); Calmer.
  05 Mismatch        — catalyst pinned to 'color' (chromatic), vents
                       pinned to 'cellularautomata' (drainfriend brood).
                       Vent A spawns raw foes: the first catalyst hit
                       RE-LOCKS them to chromatic — the catalyst names
                       the unformed. Vent B spawns 'curious' creatures:
                       already past 'foe', they KEEP the drainfriend
                       lineage — the counterpart remembers who touched
                       it first.
  06 Chain           — sequence:swarmintelligence, one vent, big wave.
                       Convert one, watch the escort lineage propagate
                       peer-to-peer; flock forms the shield-wall.

Writes map_data.json files directly (no API dependency), then the caller
should run tools/compact_map_json.py on each to keep diff hygiene.

Run: python tools/generate_catalyst_lab_maps.py
"""

import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
W, D = 12, 10  # cells (floor extent)

SEQ_ID = "catalyst_lab"

MAPS: list[dict] = [
    {
        "slug": "01_Home",
        "pedestal": {"sequence": "auto"},
        "vents": [
            {"r": 5, "c": 6, "rate": 2.0, "wave": 4, "delay": 3.0,
             "extra": {"foe_mode": "auto"}},
        ],
        "summary": "Negative test: catalyst_lab is unbound — knowledge only, goo brood.",
    },
    {
        "slug": "02_Pair_Primitives",
        "pedestal": {"sequence": "primitives"},
        "vents": [
            {"r": 5, "c": 6, "rate": 2.0, "wave": 5, "delay": 3.0,
             "extra": {"sequence": "primitives"}},
        ],
        "summary": "Matched pair: primitives native mode, goo brood, Shield power.",
    },
    {
        "slug": "03_Pair_Transform",
        "pedestal": {"sequence": "transformation"},
        "vents": [
            {"r": 5, "c": 6, "rate": 2.5, "wave": 4, "delay": 3.0,
             "extra": {"sequence": "transformation"}},
        ],
        "summary": "Matched pair: transformation native, transport brood, Porter power.",
    },
    {
        "slug": "04_Pair_Waveform",
        "pedestal": {"sequence": "wavefunctions"},
        "vents": [
            {"r": 5, "c": 6, "rate": 2.0, "wave": 5, "delay": 3.0,
             "extra": {"sequence": "wavefunctions"}},
        ],
        "summary": "Matched pair: waveform native, wave brood, Calmer power.",
    },
    {
        "slug": "05_Mismatch",
        "pedestal": {"sequence": "color"},
        "vents": [
            # Vent A — raw foes: first chromatic hit re-locks their lineage.
            {"r": 4, "c": 6, "rate": 2.0, "wave": 4, "delay": 3.0,
             "extra": {"sequence": "cellularautomata"}},
            # Vent B — pre-warmed 'curious': past 'foe', they keep the
            # drainfriend lineage even when the chromatic catalyst hits.
            {"r": 7, "c": 6, "rate": 2.5, "wave": 3, "delay": 5.0,
             "extra": {"sequence": "cellularautomata",
                       "initial_state": "curious"}},
        ],
        "summary": "Mismatch: chromatic catalyst vs drainfriend brood — who names whom.",
    },
    {
        "slug": "06_Chain",
        "pedestal": {"sequence": "swarmintelligence"},
        "vents": [
            {"r": 4, "c": 7, "rate": 1.2, "wave": 10, "delay": 3.0,
             "extra": {"sequence": "swarmintelligence"}},
        ],
        "summary": "Chain: swarm lineage propagates peer-to-peer into an escort flock.",
    },
    {
        "slug": "07_Lease",
        # Real pedestal (not a raw crystal) so the return is visible: the
        # cage fades on pickup, the crystal dissolves after 20s, and the
        # cage re-materializes with a fresh crystal ~1.5s later.
        "pedestal": {"sequence": "primitives", "lease_s": 20},
        "use_pedestal": True,
        "vents": [
            {"r": 5, "c": 6, "rate": 2.0, "wave": 5, "delay": 3.0,
             "extra": {"sequence": "primitives"}},
        ],
        "summary": "Timed lease: 20s of catalyst, then it returns to its pedestal.",
    },
]


def map_name(slug: str) -> str:
    return f"CatalystLab_{slug}"


def base_map(name: str) -> dict:
    """A 12x10 open arena with floor at h=1 everywhere, no walls."""
    structure = [["1"] * W for _ in range(D)]
    utilities = [[" "] * W for _ in range(D)]
    interactables = [[" "] * W for _ in range(D)]
    biome_paint = [[" "] * W for _ in range(D)]
    utilities[1][1] = "sp"
    return {
        "map_info": {
            "name": name,
            "lookup_name": name,
            "format": "json",
            "version": "1.0",
            "dimensions": {"width": W, "depth": D, "max_height": 5},
            "metadata": {"source": "catalyst_lab_generator"},
        },
        "layers": {
            "structure": structure,
            "utilities": utilities,
            "interactables": interactables,
            "biome_paint": biome_paint,
        },
        "settings": {
            "cube_size": 1, "gutter": 0, "show_grid": True,
            "background": {"type": "sky", "color": [0.10, 0.08, 0.16]},
            "grid_animation": {"enabled": False},
            "initial_tile_visibility": "all_visible",
        },
        "utility_definitions": {
            "sp": {"type": "spawn"}, "t": {"type": "teleporter"},
        },
    }


def cfg_token(base: str, cfg: dict) -> str:
    parts = [f"{k}:{v}" for k, v in cfg.items()]
    return base + ("#" + "#".join(parts) if parts else "")


def place_pedestal(m: dict, r: int, c: int, cfg: dict,
                   use_pedestal: bool = False) -> None:
    # Height-2 plinth so the bracelet sits at hand-grab height.
    m["layers"]["structure"][r][c] = "2"
    # Raw crystal by default; the wireframe display case when the map
    # tests pedestal behavior (e.g. the timed-lease return).
    base = "catalyst_pedestal:0:0" if use_pedestal else "becoming_catalyst"
    m["layers"]["interactables"][r][c] = cfg_token(base, cfg)


def place_vent(m: dict, v: dict) -> None:
    cfg = {
        "emit_interval_s": v["rate"],
        "wave_size": v["wave"],
        "start_delay_s": v["delay"],
    }
    cfg.update(v.get("extra", {}))
    m["layers"]["interactables"][v["r"]][v["c"]] = cfg_token(
        "catalyst_vent:0:0", cfg)


def build_one(map_def: dict, next_map: str) -> tuple[str, dict]:
    name = map_name(map_def["slug"])
    m = base_map(name)
    place_pedestal(m, 2, 2, map_def["pedestal"],
                   map_def.get("use_pedestal", False))
    for v in map_def["vents"]:
        place_vent(m, v)
    # Teleporter convention (pathfinder rule 5): the teleport cell is void.
    m["layers"]["structure"][D - 2][W - 2] = "0"
    m["layers"]["utilities"][D - 2][W - 2] = f"t:{next_map}"
    return name, m


def main() -> int:
    names = [map_name(m["slug"]) for m in MAPS]
    written: list[str] = []
    for i, map_def in enumerate(MAPS):
        next_map = names[(i + 1) % len(MAPS)]
        name, data = build_one(map_def, next_map)
        out_dir = REPO / "commons" / "maps" / name
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path = out_dir / "map_data.json"
        out_path.write_text(
            json.dumps(data, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8")
        print(f"  OK {name:<28} {map_def['summary']}")
        written.append(name)

    seq_path = REPO / "commons" / "maps" / "sequences" / f"{SEQ_ID}.json"
    seq_data = {
        "sequences": {
            SEQ_ID: {
                "name": "Catalyst Lab: sequence binding",
                "truth": "the catalyst and its counterpart are the same becoming seen from two sides",
                "description": (
                    "6 arenas testing the catalyst's sequence-binding "
                    "logic: passive knowledge, matched pairs (native mode "
                    "+ brood kind from one sequence name), the mismatch "
                    "case (who names whom), and lineage chain "
                    "propagation. The mode roster itself is covered by "
                    "catalyst_test."
                ),
                "layer": "test",
                "maps": written,
                "prerequisites": [],
                "unlocks": [],
            }
        }
    }
    seq_path.write_text(
        json.dumps(seq_data, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8")
    print(f"\nWrote sequence file: {seq_path} ({len(written)} maps)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
