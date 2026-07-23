#!/usr/bin/env python3
"""deck_city.py — one shot: a Wang-tiled platform map, dressed and furnished.

The KitBash cyber-district pipeline, end to end, into ONE named map:

    wall_kit --decks   the height field   (bands, rectangles, L-plazas)
        |
    deck_dresser       the bones          (railings, stairs, built bridges)
        |
    deck_props         the furniture      (masts, luminaires, crates)
        |
    map_pathfinder     the verdict        (walkable + every prop reachable)

Each stage keys off the same height field and each verifies itself; this wrapper
just runs them in order, in place, and rolls up the result. A stage that fails
stops the run and reports — a half-built map is never left behind silently.

Usage:
  python tools/deck_city.py --seed=8 --grid=6x5 --name=District_01
  python tools/deck_city.py --seed=3 --grid=5x4            # name auto from seed
  python tools/deck_city.py --seed=8 --grid=6x5 --density=0.2 --keep-stages
"""
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
PY = sys.executable

JSON_MODE = "--json" in sys.argv        # emit one JSON object, for the web wrapper
METRICS = {}                            # accumulated across stages


def _grab(text, pat, key, cast=int):
    m = re.search(pat, text)
    if m:
        try:
            METRICS[key] = cast(m.group(1))
        except ValueError:
            METRICS[key] = m.group(1)


def arg(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith(f"--{name}="):
            return a.split("=", 1)[1]
    return default


def flag(name):
    return f"--{name}" in sys.argv


def emit_fail(label, code, out):
    if JSON_MODE:
        print(json.dumps({"ok": False, "stage": label,
                          "error": (out or "").strip()[-400:] or f"exit {code}"}))
    else:
        print(f"\n✗ [{label}] failed (exit {code}) — run stopped.")
        if not (out or "").strip():
            print("  (no output)")
    sys.exit(code)


def run(label, args):
    """Run a stage; echo its own summary lines; abort the run on failure."""
    if not JSON_MODE:
        print(f"\n[{label}] " + " ".join(str(a) for a in args[2:]))
    # the child tools print UTF-8 (✓, em-dash); decode as such, not the Windows
    # locale codepage, or their summaries come back as mojibake
    r = subprocess.run([PY, *args], cwd=ROOT, capture_output=True, text=True,
                       encoding="utf-8", errors="replace")
    out = (r.stdout or "") + (r.stderr or "")
    if not JSON_MODE:
        for line in out.splitlines():
            s = line.strip()
            # surface each tool's own report lines, skip the noise
            if s and not s.startswith("warning:") and any(
                    k in line for k in ("—", "✓", "✗", "reach", "railing",
                                        "void spans", "pillars", "luminaire",
                                        "crates", "wrote", "blocks", "OK",
                                        "FAIL", "WARN", "unreached")):
                print("   " + s)
    if r.returncode != 0:
        emit_fail(label, r.returncode, out)
    return out


def main():
    seed = arg("seed", "8")
    gridv = arg("grid", "6x5")
    name = arg("name", f"DeckCity_{gridv}_s{seed}")
    density = arg("density")

    if not JSON_MODE:
        print(f"=== deck_city: {name}  (grid {gridv}, seed {seed}) ===")

    # 1) generate the height field
    g = run("generate", ["tools/wall_kit.py", f"--seed={seed}", f"--grid={gridv}",
                         f"--name={name}", "--decks"])
    _grab(g, r"\((\d+)x\d+ cells", "width")
    _grab(g, r"\(\d+x(\d+) cells", "depth")

    # 2) dress it in place — railings, stairs, bridge-decks
    d = run("dress", ["tools/deck_dresser.py", f"--map={name}", "--in-place"])
    _grab(d, r"railing edges\s+(\d+)", "railings")
    _grab(d, r"void spans added\s+(\d+)", "void_spans")
    _grab(d, r"pathfinder reach\s+(\d+)/", "reach")
    _grab(d, r"pathfinder reach\s+\d+/(\d+)", "walkable_cells")

    # 3) furnish it in place — masts, luminaires, crates
    props = ["tools/deck_props.py", f"--map={name}", "--in-place"]
    if density:
        props.append(f"--density={density}")
    p = run("furnish", props)
    _grab(p, r"pillars \(corners\)\s+(\d+)", "pillars")
    _grab(p, r"luminaires \(runs\)\s+(\d+)", "luminaires")
    _grab(p, r"crates \(lee\)\s+(\d+)", "crates")

    # 4) the verdict
    out = run("verify", ["tools/map_pathfinder.py", "check", name])
    ok = "0 FAIL" in out and "FAIL" not in out.replace("0 FAIL", "")

    if JSON_MODE:
        print(json.dumps({
            "ok": True, "name": name, "seed": int(seed), "grid": gridv,
            "walkable": ok,
            "view": f"/map-viewer?map={name}",
            "map_path": f"commons/maps/{name}/map_data.json",
            **METRICS,
            "props_total": (METRICS.get("pillars", 0) + METRICS.get("luminaires", 0)
                            + METRICS.get("crates", 0)),
        }))
        return

    print(f"\n=== {name}: {'✓ built, dressed, furnished, walkable' if ok else '⚠ built — see warnings above'} ===")
    print(f"    map    commons/maps/{name}/map_data.json")
    print(f"    view   /map-viewer?map={name}    (walk + fly)")
    print(f"    shoot  godot … capture_multi_angle.gd -- --mode=map --target={name}")


if __name__ == "__main__":
    main()
