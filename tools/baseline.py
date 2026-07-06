#!/usr/bin/env python3
"""baseline.py — the baseline contract auditor (R-023).

The missing layer: selection was running backwards. "Which of 752 artifacts
deserve to be in?" has no answer. Flip it — if the VR game were JUST a plain
tutorial on this concept, what would it minimally NEED? That's the BASELINE:
a small set of teaching BEATS (roles), each cast with one artifact. Then the
VOLTAGE: the few pieces a plain tutorial would never include — the critical
script, the thinker with QFEP — that turn it into Ada. Everything uncast is
AT DEPTH: kept, honored by the dig line, not needed by the book or the walk.

This tool reads doc/book/baselines/<seq>.json and reports:
  · each BEAT: cast present in a walkable map? (or understudy? or UNCAST)
  · each VOLTAGE piece: present?
  · the DEPTH: inventory artifacts not in the contract (kept, not needed)
  · a FINISH verdict: beats cast & walkable / voltage present.

A chapter is finished when its beats are cast and walkable — NOT when the
inventory is exhausted. Report-only.

Usage:
  python tools/baseline.py --seq=primitives
  python tools/baseline.py --all
"""
from __future__ import annotations

import glob
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE_DIR = os.path.join(REPO, "doc", "book", "baselines")
SEQ_DIR = os.path.join(REPO, "commons", "maps", "sequences")
MAPS_DIR = os.path.join(REPO, "commons", "maps")

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def load_json(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def seq_maps(seq: str) -> list:
    p = os.path.join(SEQ_DIR, f"{seq}.json")
    if not os.path.exists(p):
        return []
    d = load_json(p)
    maps = []
    for v in (d.get("sequences") or {}).values():
        for m in v.get("maps", []):
            name = m if isinstance(m, str) else m.get("name", "")
            if name:
                maps.append(name)
    return maps


def map_cast(mapname: str) -> list:
    p = os.path.join(MAPS_DIR, mapname, "map_data.json")
    if not os.path.exists(p):
        return []
    d = load_json(p)
    inter = d.get("layers", {}).get("interactables", [])
    out = []
    for row in inter:
        for cell in row:
            tk = str(cell).strip()
            if not tk or tk == " ":
                continue
            tk = tk.split(":")[0].split("#")[0].strip()
            if tk and tk not in ("cluster",) and tk not in out:
                out.append(tk)
    return out


def audit(seq: str) -> dict:
    bp = os.path.join(BASE_DIR, f"{seq}.json")
    if not os.path.exists(bp):
        print(f"no baseline for '{seq}' — draft doc/book/baselines/{seq}.json first")
        return {}
    base = load_json(bp)
    maps = seq_maps(seq)
    present = {}   # artifact -> map it stands in
    for m in maps:
        for tk in map_cast(m):
            present.setdefault(tk, m)

    beats = base.get("beats", [])
    voltage = base.get("voltage", [])
    contract = set()

    print(f"BASELINE — {seq}: {len(beats)} beats, {len(voltage)} voltage, "
          f"{len(maps)} maps, {len(present)} artifacts in body")
    print()
    print("DECK 1 — BEATS (the plain tutorial: cast & walkable?)")
    cast_ok = 0
    for b in beats:
        role, cast = b["role"], b.get("cast", "")
        alts = b.get("alts", [])
        contract.add(cast)
        contract.update(alts)
        if cast in present:
            mark, note = "✅", f"{cast}  @ {present[cast]}"
            cast_ok += 1
        else:
            under = next((a for a in alts if a in present), None)
            if under:
                mark, note = "◐", f"understudy {under} @ {present[under]}  (lead {cast} absent)"
                cast_ok += 1
            else:
                mark, note = "☐", f"UNCAST — {cast} not in any walkable map"
        print(f"  {mark} {role:34s} {note}")

    print()
    print("DECK 2 — VOLTAGE (the critical script: present?)")
    volt_ok = 0
    for v in voltage:
        piece = v["piece"]
        contract.add(piece)
        if piece in present:
            volt_ok += 1
            print(f"  ✅ {piece:28s} @ {present[piece]:24s} {v.get('why','')[:60]}")
        else:
            print(f"  ☐ {piece:28s} {'(absent)':26s} {v.get('why','')[:60]}")

    depth = [tk for tk in present if tk not in contract]
    print()
    print(f"AT DEPTH — {len(depth)} artifacts in the maps, kept, not in the contract")
    print(f"  (honored by the dig line; not needed by the book or the walk)")
    if depth:
        for i in range(0, len(depth), 4):
            print("   " + "  ".join(f"{t:24s}" for t in depth[i:i + 4]))

    finished = cast_ok == len(beats) and volt_ok == len(voltage)
    print()
    print(f"FINISH: beats {cast_ok}/{len(beats)} cast & walkable · "
          f"voltage {volt_ok}/{len(voltage)} present · "
          f"{'✅ FINISHED (baseline met)' if finished else '☐ open'}")
    return {"seq": seq, "beats": len(beats), "cast_ok": cast_ok,
            "voltage": len(voltage), "volt_ok": volt_ok,
            "depth": len(depth), "finished": finished}


def main() -> int:
    args = sys.argv[1:]
    if "--all" in args:
        rows = []
        for bp in sorted(glob.glob(os.path.join(BASE_DIR, "*.json"))):
            rows.append(audit(os.path.basename(bp)[:-5]))
            print("\n" + "─" * 70 + "\n")
        done = sum(1 for r in rows if r.get("finished"))
        print(f"SUMMARY: {done}/{len(rows)} sequences meet their baseline")
        return 0
    seq = next((a.split("=", 1)[1] for a in args if a.startswith("--seq=")), None)
    if not seq:
        print(__doc__)
        return 1
    audit(seq)
    return 0


if __name__ == "__main__":
    sys.exit(main())
