#!/usr/bin/env python3
"""
audit_spine_bodies.py — what does the museum actually know about the body of
every artifact on the spine?

NO GODOT. This is a static audit, and that is the point: the capture rig is
known-broken (25 of 72 staged measurements described the rig rather than the
artifact — see doc/plans/capture_measure_faults.md), so re-measuring 799
artifacts through it today would manufacture roughly 280 confident wrong numbers.
Every fault found so far leaves a SIGNATURE that can be tested from data alone:

  particle_box   oracle aabb is exactly [8, 8, 8] — Godot's default
                 GPUParticles3D.visibility_aabb recorded as a body. 19 in the
                 oracle; 15 of the 20 dressing rooms declaring [8,8,1] descend
                 from it.
  placeholder    dressing room declares [8, 8, 1]. Not a chosen default: it is
                 the particle box with its height clamped.
  zero           oracle says the artifact has no size. 223 corpus-wide.
  giant          oracle over 20 m. 125 corpus-wide, some genuine environments,
                 some one runaway mesh. Never usable without a source check.
  unmeasured     in the oracle's own `unmeasured` list, or absent entirely.
  staged         measured 2026-08-10 with a trust verdict attached.

A body is only called SOUND when nothing above fires and something actually
measured it.

    python tools/audit_spine_bodies.py
    python tools/audit_spine_bodies.py --write   # -> doc/reports/spine_body_audit.json
    python tools/audit_spine_bodies.py --list placeholder
"""
from __future__ import annotations
import argparse
import glob
import json
import os
import sys
from collections import Counter, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
PARTICLE_BOX = [8.0, 8.0, 8.0]
PLACEHOLDER = [8.0, 8.0, 1.0]


def load(path, default=None):
    try:
        return json.load(open(os.path.join(ROOT, path), encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return default if default is not None else {}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--list", default="", help="print every artifact with this flag")
    a = ap.parse_args()

    order = load("commons/data/spine_artifact_order.json").get("order", [])
    spine = []
    seen = set()
    for r in order:                       # walk order, deduped, order preserved
        t = r.get("lookup")
        if t and t not in seen:
            seen.add(t)
            spine.append({"lookup": t, "map": r.get("map", ""), "sequence": r.get("sequence", "")})

    reg = {}
    for f in glob.glob(os.path.join(ROOT, "commons/artifacts/registry/*.json")):
        if f.endswith(".bak"):
            continue
        for k, v in load(os.path.relpath(f, ROOT)).get("artifacts", {}).items():
            if isinstance(v, dict):
                reg[k] = v

    sizes_doc = load("commons/data/artifact_sizes.json")
    sizes = sizes_doc.get("sizes", {})
    never = set(sizes_doc.get("unmeasured", []) or [])
    staged = load("commons/data/staged_measurements.json").get("artifacts", {})

    rows = []
    for s in spine:
        lk = s["lookup"]
        entry = reg.get(lk)
        dr_path = os.path.join(ROOT, "commons/artifacts/dressing_rooms", lk + ".json")
        dr = load(os.path.relpath(dr_path, ROOT)) if os.path.exists(dr_path) else None
        o = sizes.get(lk)
        st = staged.get(lk)

        flags = []
        if entry is None:
            flags.append("unregistered")
        if dr is None:
            flags.append("no_dressing_room")
        else:
            fp = dr.get("footprint")
            if fp and [round(float(x), 1) for x in fp[:3]] == PLACEHOLDER:
                flags.append("placeholder")
        if isinstance(o, dict):
            ab = o.get("aabb_size")
            md = o.get("max_dimension_m")
            if ab and [round(float(x), 1) for x in ab] == PARTICLE_BOX:
                flags.append("particle_box")
            elif md == 8.0:
                flags.append("particle_axis")
            if md in (0, 0.0):
                flags.append("zero")
            elif isinstance(md, (int, float)) and md > 20:
                flags.append("giant")
        elif lk in never or o is None:
            flags.append("unmeasured")
        if st:
            flags.append("staged")
            if st.get("trust") != "trustworthy":
                flags.append("staged_untrusted")

        measured = bool(st) or (isinstance(o, dict) and o.get("max_dimension_m") not in (None, 0, 0.0))
        suspect = any(f in flags for f in
                      ("particle_box", "particle_axis", "zero", "giant", "placeholder",
                       "no_dressing_room", "unregistered", "staged_untrusted"))
        verdict = "SOUND" if (measured and not suspect) else ("SUSPECT" if measured else "UNKNOWN")

        rows.append({**s, "flags": flags, "verdict": verdict,
                     "oracle_aabb": o.get("aabb_size") if isinstance(o, dict) else None,
                     "declared_footprint": (dr or {}).get("footprint"),
                     "staged_wdh": (st or {}).get("measured_wdh"),
                     "trust": (st or {}).get("trust"),
                     "placements": 0})

    # how many maps each stands in — a wrong body on a widely-placed artifact costs more
    place = Counter()
    for md in glob.glob(os.path.join(ROOT, "commons/maps/*/map_data.json")):
        try:
            d = json.load(open(md, encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        cast = set()
        for row in d.get("layers", {}).get("interactables", []):
            for c in row:
                t = str(c).split("#")[0].split(":")[0].strip()
                if t:
                    cast.add(t)
        for t in cast:
            place[t] += 1
    for r in rows:
        r["placements"] = place.get(r["lookup"], 0)

    verdicts = Counter(r["verdict"] for r in rows)
    flags = Counter(f for r in rows for f in r["flags"])
    by_seq = defaultdict(Counter)
    for r in rows:
        by_seq[r["sequence"]][r["verdict"]] += 1

    print(f"SPINE BODIES · {len(rows)} artifacts\n")
    for v in ("SOUND", "SUSPECT", "UNKNOWN"):
        n = verdicts[v]
        print(f"  {v:8} {n:4}  {n / max(len(rows), 1) * 100:5.1f}%")
    print("\n  flag                 count   exposure (map placements)")
    for f, n in flags.most_common():
        exp = sum(r["placements"] for r in rows if f in r["flags"])
        print(f"  {f:20} {n:5}   {exp}")

    worst = sorted([r for r in rows if r["verdict"] != "SOUND"],
                   key=lambda r: -r["placements"])[:12]
    print("\n  worst by exposure — a wrong body costs once per placement")
    for r in worst:
        print(f"  {r['lookup']:32} {r['placements']:4} maps  {','.join(r['flags'])}")

    if a.list:
        print(f"\n  every artifact flagged '{a.list}':")
        for r in rows:
            if a.list in r["flags"]:
                print(f"    {r['lookup']:34} {r['placements']:4} maps  {r['sequence']}")

    if a.write:
        out = os.path.join(ROOT, "doc", "reports", "spine_body_audit.json")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        json.dump({
            "_generated": "static audit — no Godot, no captures",
            "_why_static": ("the capture rig is known-broken: 25 of 72 staged measurements described "
                            "the rig rather than the artifact. Re-measuring the spine through it today "
                            "would manufacture roughly 280 confident wrong numbers. Every fault leaves "
                            "a signature testable from data alone; those are what this checks."),
            "_signatures": {
                "particle_box": "oracle aabb exactly [8,8,8] — Godot's default GPUParticles3D.visibility_aabb",
                "placeholder": "dressing room declares [8,8,1] — the particle box with height clamped",
                "zero": "oracle reports no size at all",
                "giant": "oracle over 20 m; unusable without a source check",
                "staged_untrusted": "staged 2026-08-10 and the verdict was not 'trustworthy'",
            },
            "summary": {"artifacts": len(rows), "verdicts": dict(verdicts), "flags": dict(flags)},
            "by_sequence": {k: dict(v) for k, v in sorted(by_seq.items())},
            "artifacts": rows,
        }, open(out, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
        print(f"\n-> {os.path.relpath(out, ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
