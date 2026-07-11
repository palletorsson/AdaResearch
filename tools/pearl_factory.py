#!/usr/bin/env python3
"""pearl_factory.py — THE FACTORY (Palle: 'a factory making a pearl necklace,
artifact as input, footprint as decoration, plus additional parameters we can
change. a rule box?').

The rule box lives in commons/data/map_rule_box.json: every strategy is the
same five-stage necklace factory (string -> pearl -> thread -> opening ->
dress) with different rules per stage and named KNOBS. This CLI is the one
door to all of them:

  python tools/pearl_factory.py --list
  python tools/pearl_factory.py --recipe=ants --seq=randomness
  python tools/pearl_factory.py --recipe=ants --seq=randomness --set THRESHOLD=3 --set ANTS=40
  python tools/pearl_factory.py --recipe=wanghall --seq=lsystems --seed=11

--set KNOB=value overrides a module constant in the strategy tool (the
additional parameters we can change). Knob names per recipe: --list.
"""
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BOX = ROOT / "commons" / "data" / "map_rule_box.json"
sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def load_box() -> dict:
    return json.loads(BOX.read_text(encoding="utf-8"))


def list_recipes(box: dict) -> int:
    print("THE RULE BOX — recipes (stage rules + knobs):\n")
    for name, r in box["recipes"].items():
        print(f"  {name:10s} {r['note']}")
        for k, v in r.get("knobs", {}).items():
            print(f"             knob {k} = {v}")
    print("\nstages:", " -> ".join(box["stages"].keys()))
    return 0


def main() -> int:
    argv = sys.argv[1:]
    box = load_box()
    if "--list" in argv or not argv:
        return list_recipes(box)
    arg = lambda k, d=None: next((a.split("=", 1)[1] for a in argv
                                  if a.startswith(f"--{k}=")), d)
    recipe = arg("recipe")
    if not recipe or recipe not in box["recipes"]:
        print(f"unknown recipe {recipe!r} — use --list")
        return 1
    r = box["recipes"][recipe]
    tool = ROOT / "tools" / r["tool"]
    if not tool.exists():
        print(f"recipe {recipe}: tool {r['tool']} not built yet (worker in flight?)")
        return 1
    cmd = [sys.executable, str(tool)] + list(r.get("args", []))
    for k in ("seq", "seed", "name"):
        v = arg(k)
        if v:
            cmd.append(f"--{k}={v}")
    sets = [a.split("=", 1)[1] for a in argv if a.startswith("--set=")]
    sets += [argv[i + 1] for i, a in enumerate(argv)
             if a == "--set" and i + 1 < len(argv)]
    for s in sets:
        cmd.append(f"--set={s}")
    print("factory:", " ".join(cmd[1:]))
    return subprocess.call(cmd, cwd=ROOT)


if __name__ == "__main__":
    sys.exit(main())
