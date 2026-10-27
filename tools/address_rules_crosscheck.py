"""Do the two implementations of the address rules agree, cell for cell?

The spatial lab's rules (ada_encyclopedia/src/lib/colour-study.ts RULES, three.js) and the hall's
(commons/artifacts/regularity/address_rules.gd, Godot) are one rule written twice, and a second
implementation drifts. This evaluates both on the same grids and fails on any disagreement.

  python tools/address_rules_crosscheck.py [--images]

--images also writes the tiling hall's six rule fields as PNGs to ada_run/address_rules/.
Exit code: the number of cases that disagree (0 = the twins agree), 2 if a side could not run.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENC = Path(os.environ.get("ADA_ENCYCLOPEDIA", ROOT.parent / "ada_encyclopedia"))
GODOT = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
OUT = ROOT / "ada_run" / "address_rules"
sys.path.insert(0, str(ROOT / "tools"))
from void_native_slot import acquire_native_slot  # noqa: E402


def cases() -> list[dict]:
    names = ["sum", "difference", "columns", "rows", "knight", "linear", "product", "squares", "gcd", "pascal",
             "xor", "and", "rings", "diamonds", "frames", "sectors", "spiral", "primes", "collatz", "scatter"]
    out = []
    for rule in names:
        for size in (8, 11, 21):
            for n in (2, 3, 4, 12):
                for a, b in ([(1, 3), (2, 5), (-3, 4)] if rule == "linear" else [(1, 3)]):
                    out.append({"rule": rule, "size": size, "n": n, "a": a, "b": b})
    return out


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    grid = cases()
    tsx = ENC / "node_modules" / ".bin" / ("tsx.cmd" if os.name == "nt" else "tsx")
    (OUT / "cases.json").write_text(json.dumps(grid), encoding="utf-8")
    ts = subprocess.run([str(tsx), str(ROOT / "tools" / "address_rules_values.ts"), str(OUT / "cases.json")],
                        capture_output=True, text=True, encoding="utf-8", cwd=ROOT)
    if ts.returncode != 0:
        print("TypeScript side failed:", ts.stderr[-2000:])
        return 2
    (OUT / "ts.json").write_text(ts.stdout, encoding="utf-8")
    (OUT / "gd.json").unlink(missing_ok=True)
    args = [GODOT, "--headless", "--path", str(ROOT), "--xr-mode", "off",
            "--script", "res://commons/testing/probe_address_rules.gd"]
    if "--images" in sys.argv:
        args += ["--", "--images"]
    slot = acquire_native_slot("address rules cross-check", timeout=600)
    try:
        gd = subprocess.run([sys.executable, str(ROOT / "tools" / "godot_watchdog.py"), f"--expect={OUT / 'gd.json'}", "--", *args],
                            capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=ROOT)
    finally:
        slot.close()
    if not (OUT / "gd.json").exists():
        print("Godot side wrote nothing:", (gd.stdout + gd.stderr)[-2000:])
        return 2
    a = json.loads((OUT / "ts.json").read_text(encoding="utf-8"))
    b = json.loads((OUT / "gd.json").read_text(encoding="utf-8"))
    if a["rules"] != b["rules"]:
        print(f"the rule lists differ:\n  ts {a['rules']}\n  gd {b['rules']}")
    bad = 0
    for ca, cb in zip(a["cases"], b["cases"]):
        diff = [i for i, (u, v) in enumerate(zip(ca["states"], cb["states"])) if u != v]
        if diff:
            bad += 1
            i = diff[0]
            x, z = divmod(i, ca["size"])
            print(f"DIFFER {ca['rule']:10} N={ca['size']:2} n={ca['n']:2} a,b={ca['a']},{ca['b']}: {len(diff)} cells, first ({x}, {z}) ts {ca['states'][i]} gd {cb['states'][i]}")
    print(f"{len(a['cases']) - bad} of {len(a['cases'])} cases agree cell for cell ({sum(len(c['states']) for c in a['cases'])} cells)")
    for p in b.get("images", []):
        print("image", p)
    return bad


if __name__ == "__main__":
    raise SystemExit(main())
