#!/usr/bin/env python3
"""build_composition_view.py — the three-column reading face (R-024).

The cockpit for the chapter loop: for each spine sequence, three orders side by
side —
  NEED       the baseline beats (plain tutorial, concept order)
  POTENTIAL  baseline + critical voltage woven in at its anchor (the Ada version)
  ACTUAL     how the maps really walk now, every artifact tagged
              beat / understudy / voltage / at-depth

The gap NEED→POTENTIAL is where the criticism enters; POTENTIAL→ACTUAL is the
compositor's divergence made spatial. Reads doc/book/baselines/<seq>.json +
the maps; writes ada_encyclopedia/public/composition-view.json for /composition.
Report-only — the face of baseline.py + compositor.py, no new capability.

Usage: python tools/build_composition_view.py
"""
from __future__ import annotations

import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.path.join(os.path.dirname(REPO), "ada_encyclopedia")
BASE_DIR = os.path.join(REPO, "doc", "book", "baselines")
SEQ_DIR = os.path.join(REPO, "commons", "maps", "sequences")
MAPS_DIR = os.path.join(REPO, "commons", "maps")
SPINE = os.path.join(REPO, "commons", "maps", "curriculum_spine.json")
OUT = os.path.join(ENC, "public", "composition-view.json")

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
    out = []
    for v in (d.get("sequences") or {}).values():
        for m in v.get("maps", []):
            name = m if isinstance(m, str) else m.get("name", "")
            if name:
                out.append(name)
    return out


def map_cast(mapname: str) -> list:
    p = os.path.join(MAPS_DIR, mapname, "map_data.json")
    if not os.path.exists(p):
        return []
    inter = load_json(p).get("layers", {}).get("interactables", [])
    out = []
    for row in inter:
        for cell in row:
            tk = str(cell).strip()
            if not tk or tk == " ":
                continue
            tk = tk.split(":")[0].split("#")[0].strip()
            if tk and tk != "cluster" and tk not in out:
                out.append(tk)
    return out


def build_seq(seq: str) -> dict:
    maps = seq_maps(seq)
    present = {}
    for m in maps:
        for tk in map_cast(m):
            present.setdefault(tk, m)

    bp = os.path.join(BASE_DIR, f"{seq}.json")
    has_baseline = os.path.exists(bp)
    beats, voltage = [], []
    if has_baseline:
        b = load_json(bp)
        beats = b.get("beats", [])
        voltage = b.get("voltage", [])

    # column 1 — NEED
    need = []
    contract = set()
    for bt in beats:
        cast = bt.get("cast", "")
        alts = bt.get("alts", [])
        contract.add(cast)
        contract.update(alts)
        state = ("cast" if cast in present
                 else "understudy" if any(a in present for a in alts)
                 else "uncast")
        under = next((a for a in alts if a in present), "")
        need.append({"role": bt["role"], "artifact": cast, "state": state,
                     "map": present.get(cast, present.get(under, "")),
                     "understudy": under if state == "understudy" else ""})

    # column 2 — POTENTIAL (beats + voltage woven at anchors)
    potential = []
    volt_by_anchor = {}
    for v in voltage:
        contract.add(v["piece"])
        volt_by_anchor.setdefault(v.get("after", ""), []).append(v)
    for bt in beats:
        potential.append({"kind": "beat", "label": bt["role"],
                          "artifact": bt.get("cast", "")})
        for v in volt_by_anchor.get(bt["role"], []):
            potential.append({"kind": "voltage", "label": v.get("why", ""),
                              "artifact": v["piece"],
                              "present": v["piece"] in present})
    for v in volt_by_anchor.get("", []):   # unanchored voltage at the end
        potential.append({"kind": "voltage", "label": v.get("why", ""),
                          "artifact": v["piece"], "present": v["piece"] in present})

    # column 3 — ACTUAL (body order, tagged)
    volt_set = {v["piece"] for v in voltage}
    beat_cast = {bt.get("cast", ""): bt["role"] for bt in beats}
    alt_roles = {}
    for bt in beats:
        for a in bt.get("alts", []):
            alt_roles[a] = bt["role"]
    actual = []
    for m in maps:
        for tk in map_cast(m):
            if any(a["artifact"] == tk and a["map"] == m for a in actual):
                continue
            tag = ("beat" if tk in beat_cast
                   else "understudy" if tk in alt_roles
                   else "voltage" if tk in volt_set
                   else "depth")
            actual.append({"artifact": tk, "map": m, "tag": tag,
                           "role": beat_cast.get(tk, alt_roles.get(tk, ""))})

    cast_ok = sum(1 for n in need if n["state"] in ("cast", "understudy"))
    volt_ok = sum(1 for v in voltage if v["piece"] in present)
    depth_n = len({a["artifact"] for a in actual if a["tag"] == "depth"})  # distinct, matches baseline.py
    return {
        "seq": seq, "has_baseline": has_baseline, "maps": len(maps),
        "need": need, "potential": potential, "actual": actual,
        "stats": {"beats": len(beats), "cast_ok": cast_ok,
                  "voltage": len(voltage), "volt_ok": volt_ok,
                  "depth": depth_n, "body": len(present),
                  "met": has_baseline and cast_ok == len(beats) and volt_ok == len(voltage)},
    }


def main() -> int:
    spine = [s["name"] for s in sorted(
        load_json(SPINE)["spine"]["sequences"], key=lambda s: s.get("order", 99))]
    out = {"generated_by": "tools/build_composition_view.py",
           "sequences": [build_seq(s) for s in spine]}
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        json.dump(out, f, indent=1, ensure_ascii=False)
    done = sum(1 for s in out["sequences"] if s["stats"]["met"])
    drafted = sum(1 for s in out["sequences"] if s["has_baseline"])
    print(f"composition-view.json: {len(spine)} sequences, {drafted} with baselines, "
          f"{done} meet baseline -> {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
