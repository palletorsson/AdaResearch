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

# Some archetypes only make sense for certain systems.
# `helix`/`branching` need vertical + t-junction support — big_pipe has vu/vd/t,
# glass also has these but some glass configs may not. Keep unrestricted for
# now and filter if needed.


def gen_one(rng: random.Random, system: str, archetype: str) -> tuple[str, dict]:
    sys_spec = SYSTEMS[system]
    name, path = ARCHETYPES[archetype](rng)
    seed_tag = f"{rng.randint(0, 1 << 20):05x}"
    cid = f"{sys_spec['prefix']}_{archetype}_{seed_tag}"
    return cid, {
        "rack_info": {
            "name": f"{archetype.capitalize()} ({system})",
            "description": (f"Auto-generated {archetype} turtle-path for {system} system. "
                            f"path='{path}'"),
            "system": system,
            "archetype": archetype,
            "auto_generated": True,
        },
        "layout": {
            "segment_length": sys_spec["segment_length"],
            "pipe_radius":    sys_spec["pipe_radius"],
        },
        "path": path,
    }


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

    arches = [archetype_filter] if archetype_filter else list(ARCHETYPES.keys())
    for a in arches:
        if a not in ARCHETYPES:
            print(f"[ERR] unknown archetype: {a}. Known: {', '.join(ARCHETYPES)}"); return 1

    rng = random.Random(seed)
    combos = [(s, a) for s in systems for a in arches]
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
    ap.add_argument("--archetype", dest="archetype_filter", help=", ".join(ARCHETYPES))
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
        return 0

    seed = args.seed if args.seed is not None else random.randint(0, 1 << 30)
    print(f"seed={seed}  count={args.count}  system={args.system_filter or 'all'}  "
          f"archetype={args.archetype_filter or 'all'}")
    return generate(args.count, seed, args.system_filter, args.archetype_filter, args.clean)


if __name__ == "__main__":
    sys.exit(main())
