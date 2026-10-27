"""Do the two implementations of the address rules agree, cell for cell?

The spatial lab's rules (ada_encyclopedia/src/lib/colour-study.ts RULES, three.js) and the hall's
(commons/artifacts/regularity/address_rules.gd, Godot) are one rule written twice, and a second
implementation drifts. This evaluates both on the same grids and fails on any disagreement.

  python tools/address_rules_crosscheck.py [--images] [--disco] [--lewitt]

--images also writes the tiling hall's six rule fields as PNGs to ada_run/address_rules/.
--disco also compares the disco hall console's RULES patterns (disco_controls.gd, in a room of its
own: probe_disco_rules.gd) with the lab's disco floor study, beat by beat, and reports the
console's own checks (at load unchanged, RULES changes the floor, PATTERN restores it).
--lewitt also compares LeWitt's incomplete open cubes as Tutorial_3D's open_rules.gd enumerates them
(probe_lewitt_122.gd) with the lab's list, mask for mask.
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


# disco_controls.gd RULE_PATTERNS, as the lab's disco floor study spells them (an 8 x 8 floor)
DISCO = [("RINGS / CYCLE", {"time": "cycle", "rule": "rings", "entries": 4}), ("SPIRAL / CYCLE", {"time": "cycle", "rule": "spiral", "entries": 4}),
         ("PASCAL / TRAVEL", {"time": "travel", "rule": "pascal", "entries": 2}), ("RULE 90", {"time": "elementary", "ca_rule": 90}),
         ("RULE 30", {"time": "elementary", "ca_rule": 30}), ("LIFE", {"time": "life"})]


def disco(tsx: Path) -> int:
    bad = 0
    for mode in ("mono", "colour"):
        (OUT / "disco_gd.json").unlink(missing_ok=True)
        args = [GODOT, "--headless", "--path", str(ROOT), "--xr-mode", "off", "--script", "res://commons/testing/probe_disco_rules.gd", "--", mode]
        slot = acquire_native_slot(f"disco rules cross-check ({mode})", timeout=600)
        try:
            subprocess.run([sys.executable, str(ROOT / "tools" / "godot_watchdog.py"), f"--expect={OUT / 'disco_gd.json'}", "--", *args],
                           capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=ROOT)
        finally:
            slot.close()
        if not (OUT / "disco_gd.json").exists():
            print(f"disco ({mode}): the hall side wrote nothing")
            return bad + 2
        hall = json.loads((OUT / "disco_gd.json").read_text(encoding="utf-8"))
        for c in hall["checks"]:
            print(f"  {'PASS' if c['pass'] else 'FAIL'}  {mode:6} {c['check']}")
            bad += 0 if c["pass"] else 1
        w, d = hall.get("width"), hall.get("depth")
        if w is None or w != d:
            print(f"  FAIL  {mode:6} the lab's disco floor is square; the hall floor is {w} x {d}")
            bad += 1
            continue
        # the lab side at the hall floor's real size (it was 12 x 12, not the registry's 8 x 8)
        cases = [{"name": n, "settings": dict(st, size=w), "beats": len(hall["patterns"][0]["beats"])} for n, st in DISCO]
        (OUT / "disco_cases.json").write_text(json.dumps(cases), encoding="utf-8")
        ts = subprocess.run([str(tsx), str(ROOT / "tools" / "disco_rules_values.ts"), str(OUT / "disco_cases.json")],
                            capture_output=True, text=True, encoding="utf-8", cwd=ROOT)
        if ts.returncode != 0:
            print("disco, lab side failed:", ts.stderr[-1500:])
            return bad + 2
        lab = {c["name"]: c["beats"] for c in json.loads(ts.stdout)}
        for pat in hall["patterns"]:
            diff = [t for t, (a, b) in enumerate(zip(pat["beats"], lab[pat["name"]])) if a != b]
            print(f"  {'PASS' if not diff else 'FAIL'}  {mode:6} {pat['name']:15} beats 0-{len(pat['beats']) - 1} on {w} x {d} {'agree with the lab' if not diff else f'differ first at beat {diff[0]}'}")
            bad += 1 if diff else 0
    return bad


def lewitt(tsx: Path) -> int:
    ts = subprocess.run([str(tsx), str(ROOT / "tools" / "lewitt_values.ts")], capture_output=True, text=True, encoding="utf-8", cwd=ROOT)
    if ts.returncode != 0:
        print("lewitt, lab side failed:", ts.stderr[-1500:])
        return 2
    lab = json.loads(ts.stdout)
    (OUT / "lewitt_gd.json").unlink(missing_ok=True)
    args = [GODOT, "--headless", "--path", str(ROOT), "--xr-mode", "off", "--script", "res://commons/testing/probe_lewitt_122.gd"]
    slot = acquire_native_slot("lewitt 122 cross-check", timeout=600)
    try:
        subprocess.run([sys.executable, str(ROOT / "tools" / "godot_watchdog.py"), f"--expect={OUT / 'lewitt_gd.json'}", "--", *args],
                       capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=ROOT)
    finally:
        slot.close()
    if not (OUT / "lewitt_gd.json").exists():
        print("lewitt: the hall side wrote nothing")
        return 2
    hall = json.loads((OUT / "lewitt_gd.json").read_text(encoding="utf-8"))
    bad = 0
    for c in hall["checks"]:
        print(f"  {'PASS' if c['pass'] else 'FAIL'}  lewitt {c['check']}")
        bad += 0 if c["pass"] else 1
    same = sorted(hall["masks"]) == sorted(lab["rotations"])
    print(f"  {'PASS' if same else 'FAIL'}  lewitt the hall's {len(hall['masks'])} and the lab's {len(lab['rotations'])} are the same masks (the lab counts {len(lab['mirrors'])} with mirror images as one)")
    return bad + (0 if same else 1)


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
    if "--disco" in sys.argv:
        bad += disco(tsx)
    if "--lewitt" in sys.argv:
        bad += lewitt(tsx)
    return bad


if __name__ == "__main__":
    raise SystemExit(main())
