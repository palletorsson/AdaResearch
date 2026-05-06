#!/usr/bin/env python
"""
generate_pipe_configs.py — emit turtle-graphics pipe configs for
auto-research of both glass_rack and big_pipe systems.

Both systems extend TurtlePipeBase and consume the same DNA — a path
string of turtle commands ("f,f,r,f,s,f" etc.). The only difference is
the segment library (lab glass vs. drain pipes) + scale, picked by
rack_info.system = "glass" | "big_pipe".

Turtle command alphabet (from TurtlePipeBase + system extensions):
  f   forward (straight segment)
  l   turn left 90°
  r   turn right 90°
  u   pitch up (vertical up)
  d   pitch down (vertical down)
  s   s-bend
  t   t-junction
  x   cross junction
  cap end cap
  vu  vertical up segment (big_pipe)
  vd  vertical down segment (big_pipe)

Generation archetypes (each returns a path string):
  - straight:   n forward segments
  - zigzag:     alternating l/r between forwards
  - spiral:     gradual turns, forming a coil in XY
  - branching:  t-junctions fan out from a trunk
  - helix:      forwards + pitch-up/down mix
  - chaos:      random walk respecting segment counts
  - maze:       planar random turns
  - cross:      x-junction at midpoint, 4 arms

Usage::

    python tools/generate_pipe_configs.py --count 32 --seed 11
    python tools/generate_pipe_configs.py --system big_pipe
    python tools/generate_pipe_configs.py --archetype spiral --clean
    python tools/generate_pipe_configs.py --list
"""
from __future__ import annotations

import argparse
import json
import random
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

REPO = Path(__file__).resolve().parent.parent
OUT_DIR = REPO / "commons" / "audio" / "pipe_configs"

SYSTEMS = {
    "glass":    {"segment_length": 0.15, "pipe_radius": 0.02, "prefix": "glass"},
    "big_pipe": {"segment_length": 2.0,  "pipe_radius": 0.8,  "prefix": "big"},
}

GLASS_PALETTES = [
    {
        "glass_color": [0.85, 0.92, 1.0, 0.28],
        "liquid_color": [0.2, 0.8, 0.4, 0.6],
        "show_liquid": True,
    },
    {
        "glass_color": [0.82, 0.9, 1.0, 0.3],
        "liquid_color": [0.9, 0.6, 0.2, 0.55],
        "show_liquid": True,
    },
    {
        "glass_color": [0.88, 0.94, 1.0, 0.24],
        "liquid_color": [0.05, 0.7, 1.0, 0.52],
        "show_liquid": True,
    },
    {
        "glass_color": [0.9, 0.96, 1.0, 0.22],
        "liquid_color": [0.85, 0.25, 0.72, 0.48],
        "show_liquid": True,
    },
]

# ─── Archetype path builders ────────────────────────────────────────────

def arch_straight(rng: random.Random) -> tuple[str, str]:
    n = rng.randint(3, 8)
    return "straight", ",".join(["f"] * n)


def arch_zigzag(rng: random.Random) -> tuple[str, str]:
    n = rng.randint(3, 6)
    path: list[str] = ["f"]
    for i in range(n):
        path.append("l" if i % 2 == 0 else "r")
        path.append("f")
    return "zigzag", ",".join(path)


def arch_spiral(rng: random.Random) -> tuple[str, str]:
    n = rng.randint(4, 8)
    turn = rng.choice(["l", "r"])
    path: list[str] = []
    for _ in range(n):
        path.append("f")
        path.append(turn)
    path.append("f")
    return "spiral", ",".join(path)


def arch_branching(rng: random.Random) -> tuple[str, str]:
    trunk = rng.randint(2, 4)
    branches = rng.randint(2, 3)
    path: list[str] = ["f"] * trunk
    for _ in range(branches):
        path.append("t")
        path.append("f")
        path.append(rng.choice(["l", "r"]))
        path.append("f")
    return "branching", ",".join(path)


def arch_helix(rng: random.Random) -> tuple[str, str]:
    n = rng.randint(3, 6)
    path: list[str] = []
    for i in range(n):
        path.append("f")
        path.append("u" if i % 2 == 0 else "r")
    path.append("f")
    return "helix", ",".join(path)


def arch_chaos(rng: random.Random) -> tuple[str, str]:
    n = rng.randint(6, 14)
    choices = ["f", "f", "f", "l", "r", "u", "d", "s"]
    return "chaos", ",".join(rng.choice(choices) for _ in range(n))


def arch_maze(rng: random.Random) -> tuple[str, str]:
    n = rng.randint(6, 10)
    path: list[str] = ["f"]
    for _ in range(n):
        path.append(rng.choice(["l", "r"]))
        path.append("f")
        path.append("f")
    return "maze", ",".join(path)


def arch_cross(rng: random.Random) -> tuple[str, str]:
    pre = rng.randint(1, 3)
    arm = rng.randint(1, 3)
    path: list[str] = ["f"] * pre + ["x"] + ["f"] * arm
    return "cross", ",".join(path)


def arch_glass_reflux_loop(rng: random.Random) -> tuple[str, str]:
    column = rng.randint(1, 3)
    return_arm = rng.randint(1, 2)
    path: list[str] = ["flask", "f", "u"]
    path.extend(["f"] * column)
    path.extend(["condenser", "ubend", "d"])
    path.extend(["f"] * return_arm)
    if rng.random() < 0.55:
        path.extend(["beaker"])
    return "glass_reflux_loop", ",".join(path)


def arch_glass_fractional_column(rng: random.Random) -> tuple[str, str]:
    stages = rng.randint(2, 4)
    path: list[str] = ["flask", "f", "u", "f"]
    for idx in range(stages):
        path.extend(["spiral", "f"])
        if idx < stages - 1:
            path.extend(["reducer", "f"])
    path.extend(["corner45", "f", "condenser", "d", "f", "f", "beaker"])
    return "glass_fractional_column", ",".join(path)


def arch_glass_cold_trap(rng: random.Random) -> tuple[str, str]:
    vertical = rng.randint(1, 2)
    tail = rng.randint(1, 2)
    path: list[str] = ["flask", "f", "u"]
    path.extend(["f"] * vertical)
    path.extend(["corner45", "f", "condenser", "ubend", "f"])
    path.extend(["d", "f"] * tail)
    path.extend(["drip"])
    if rng.random() < 0.5:
        path.extend(["beaker"])
    return "glass_cold_trap", ",".join(path)


def arch_glass_bubbler_tree(rng: random.Random) -> tuple[str, str]:
    trunk = rng.randint(1, 3)
    path: list[str] = ["flask"]
    path.extend(["f"] * trunk)
    path.extend([
        "cross",
        "[", "l", "f", "f", "drip", "]",
        "[", "r", "f", "f", "drip", "]",
        "f", "ypipe",
        "[", "l", "f", "drip", "]",
        "[", "r", "f", "beaker", "]",
        "f", "drip",
    ])
    return "glass_bubbler_tree", ",".join(path)


def arch_glass_spiral_condenser(rng: random.Random) -> tuple[str, str]:
    run = rng.randint(1, 2)
    tail = rng.randint(1, 2)
    path: list[str] = ["flask", "f", "u"]
    path.extend(["f"] * run)
    path.extend(["spiral", "f", "corner45", "f", "condenser", "d"])
    path.extend(["f"] * tail)
    path.extend(["beaker"])
    return "glass_spiral_condenser", ",".join(path)


def arch_glass_receiver_bank(rng: random.Random) -> tuple[str, str]:
    path: list[str] = [
        "flask", "f", "u", "f", "corner45", "f", "cross",
        "[", "l", "f", "beaker", "]",
        "[", "r", "f", "beaker", "]",
        "f", "ypipe",
        "[", "l", "f", "drip", "]",
        "[", "r", "f", "beaker", "]",
        "f", "cap",
    ]
    return "glass_receiver_bank", ",".join(path)


def arch_glass_dean_stark(rng: random.Random) -> tuple[str, str]:
    rise = rng.randint(1, 2)
    return_arm = rng.randint(1, 2)
    path: list[str] = ["flask", "f", "u"]
    path.extend(["f"] * rise)
    path.extend(["ypipe"])
    path.extend(["[", "l", "condenser", "f", "beaker", "]"])
    path.extend(["f", "ubend", "d"])
    path.extend(["f"] * return_arm)
    path.extend(["drip"])
    return "glass_dean_stark", ",".join(path)


def arch_glass_manifold_ladder(rng: random.Random) -> tuple[str, str]:
    repeats = rng.randint(2, 3)
    path: list[str] = ["f", "sbend", "f", "cross"]
    for _ in range(repeats):
        path.extend(["[", "l", "f", "drip", "]"])
        path.extend(["[", "r", "f", "drip", "]"])
        path.extend(["f", "sbend", "f"])
    path.extend(["cap"])
    return "glass_manifold_ladder", ",".join(path)


ARCHETYPES = {
    "straight":  arch_straight,
    "zigzag":    arch_zigzag,
    "spiral":    arch_spiral,
    "branching": arch_branching,
    "helix":     arch_helix,
    "chaos":     arch_chaos,
    "maze":      arch_maze,
    "cross":     arch_cross,
}

GLASS_ONLY_ARCHETYPES = {
    "glass_reflux_loop":      arch_glass_reflux_loop,
    "glass_fractional_column": arch_glass_fractional_column,
    "glass_cold_trap":        arch_glass_cold_trap,
    "glass_bubbler_tree":     arch_glass_bubbler_tree,
    "glass_spiral_condenser": arch_glass_spiral_condenser,
    "glass_receiver_bank":    arch_glass_receiver_bank,
    "glass_dean_stark":       arch_glass_dean_stark,
    "glass_manifold_ladder":  arch_glass_manifold_ladder,
}

SYSTEM_ARCHETYPES = {
    "glass": {**ARCHETYPES, **GLASS_ONLY_ARCHETYPES},
    "big_pipe": ARCHETYPES,
}

# Some archetypes only make sense for certain systems.
# `helix`/`branching` need vertical + t-junction support — big_pipe has vu/vd/t,
# glass also has these but some glass configs may not. Keep unrestricted for
# now and filter if needed.


def _glass_materials(rng: random.Random) -> dict:
    return dict(rng.choice(GLASS_PALETTES))


def _display_name(archetype: str) -> str:
    label = archetype
    if label.startswith("glass_"):
        label = label[len("glass_"):]
    return label.replace("_", " ").title()


def _layout_for(system: str, rng: random.Random, archetype: str) -> dict:
    sys_spec = SYSTEMS[system]
    layout = {
        "segment_length": sys_spec["segment_length"],
        "pipe_radius": sys_spec["pipe_radius"],
    }
    if system == "glass":
        if archetype.startswith("glass_"):
            layout["segment_length"] = round(rng.uniform(0.11, 0.16), 3)
            layout["tube_radius"] = round(rng.uniform(0.010, 0.018), 3)
        else:
            layout["tube_radius"] = round(rng.uniform(0.011, 0.017), 3)
    return layout


def gen_one(rng: random.Random, system: str, archetype: str) -> tuple[str, dict]:
    sys_spec = SYSTEMS[system]
    name, path = SYSTEM_ARCHETYPES[system][archetype](rng)
    seed_tag = f"{rng.randint(0, 1 << 20):05x}"
    slug = archetype if not archetype.startswith(f"{sys_spec['prefix']}_") else archetype[len(sys_spec["prefix"]) + 1:]
    cid = f"{sys_spec['prefix']}_{slug}_{seed_tag}"
    cfg = {
        "rack_info": {
            "name": f"{_display_name(archetype)} ({system})",
            "description": (f"Auto-generated {archetype} turtle-path for {system} system. "
                            f"path='{path}'"),
            "system": system,
            "archetype": archetype,
            "auto_generated": True,
        },
        "layout": _layout_for(system, rng, archetype),
        "path": path,
    }
    if system == "glass":
        cfg["materials"] = _glass_materials(rng)
    return cid, cfg


def generate(count: int, seed: int, system_filter: str | None,
             archetype_filter: str | None, clean: bool) -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    if clean:
        n = 0
        for p in OUT_DIR.glob("*.json"):
            try: p.unlink(); n += 1
            except Exception: pass
        print(f"[clean] removed {n} files from {OUT_DIR.name}/")

    systems = [system_filter] if system_filter else list(SYSTEMS.keys())
    for s in systems:
        if s not in SYSTEMS:
            print(f"[ERR] unknown system: {s}. Known: {', '.join(SYSTEMS)}"); return 1

    rng = random.Random(seed)
    combos: list[tuple[str, str]] = []
    for s in systems:
        allowed = SYSTEM_ARCHETYPES[s]
        arches = [archetype_filter] if archetype_filter else list(allowed.keys())
        for a in arches:
            if a not in allowed:
                print(f"[ERR] unknown archetype for {s}: {a}. Known: {', '.join(allowed)}")
                return 1
            combos.append((s, a))
    per = max(1, count // len(combos))
    remainder = count - per * len(combos)
    emitted = 0
    for i, (s, a) in enumerate(combos):
        n = per + (1 if i < remainder else 0)
        for _ in range(n):
            cid, cfg = gen_one(rng, s, a)
            (OUT_DIR / f"{cid}.json").write_text(
                json.dumps(cfg, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )
            emitted += 1

    print(f"[ok] wrote {emitted} pipe configs to {OUT_DIR}")
    print("Next: python tools/module_research.py pipes-auto")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--count", type=int, default=32)
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("--system", dest="system_filter", help=", ".join(SYSTEMS))
    ap.add_argument("--archetype", dest="archetype_filter",
                    help="generic archetype or glass-only apparatus archetype")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--clean", action="store_true",
                    help="wipe auto-generated configs (but keep seeded glass_* ones)")
    args = ap.parse_args()

    if args.list:
        print("Systems:")
        for s, v in SYSTEMS.items():
            print(f"  {s:<10s} radius={v['pipe_radius']}, seg={v['segment_length']}")
        print()
        print("Archetypes:")
        for a, fn in ARCHETYPES.items():
            print(f"  {a:<10s} {(fn.__doc__ or '').strip().splitlines()[0] if fn.__doc__ else ''}")
        print()
        print("Glass-only archetypes:")
        for a in GLASS_ONLY_ARCHETYPES:
            print(f"  {a}")
        return 0

    seed = args.seed if args.seed is not None else random.randint(0, 1 << 30)
    print(f"seed={seed}  count={args.count}  system={args.system_filter or 'all'}  "
          f"archetype={args.archetype_filter or 'all'}")
    return generate(args.count, seed, args.system_filter, args.archetype_filter, args.clean)


if __name__ == "__main__":
    sys.exit(main())
