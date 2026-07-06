#!/usr/bin/env python3
"""build_key_artifacts.py — define the KEY artifacts and promote them to DNA (R-026).

The baselines already answered "which artifacts matter": the ones cast as a
BEAT or chosen as VOLTAGE across the 22 chapters. This tool collects that set,
promotes each to a DNA entry — its book-role (what beats it teaches, what
critical charge it carries, which chapters depend on it) fused with its code
@identity (the essence line) and a capture — and writes key-artifacts.json for
the /key-artifacts gallery, ranked by book-weight (how many chapters lean on it).
That ranking IS the improvement worklist: fix the load-bearing artifacts first.

Usage: python tools/build_key_artifacts.py
"""
from __future__ import annotations

import glob
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.path.join(os.path.dirname(REPO), "ada_encyclopedia")
BASE_DIR = os.path.join(REPO, "doc", "book", "baselines")
REG_DIR = os.path.join(REPO, "commons", "artifacts", "registry")
PUB = os.path.join(ENC, "public")
OUT = os.path.join(PUB, "key-artifacts.json")

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def load_json(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def build_registry() -> dict:
    """lookup_name -> scene path, across all registries."""
    m = {}
    for p in glob.glob(os.path.join(REG_DIR, "*.json")):
        d = load_json(p)
        arts = d.get("artifacts", d) if isinstance(d, dict) else {}
        if isinstance(arts, dict):
            for k, e in arts.items():
                if isinstance(e, dict) and e.get("scene"):
                    m[e.get("lookup_name", k)] = e["scene"]
    return m


def gd_path(name: str, scene: str) -> str:
    """resolve an artifact's .gd file path from its scene, or '' if not found."""
    if not scene:
        return ""
    gd = scene.replace("res://", REPO + os.sep).replace("/", os.sep)
    gd = re.sub(r"\.tscn$", ".gd", gd)
    if not os.path.exists(gd):
        alt = os.path.join(os.path.dirname(gd), name + ".gd")
        gd = alt if os.path.exists(alt) else gd
    return gd if os.path.exists(gd) else ""


def essence_of(gd: str) -> str:
    """the code DNA — the @identity essence line from the artifact's .gd."""
    if not gd:
        return ""
    try:
        txt = open(gd, encoding="utf-8", errors="ignore").read()
    except Exception:
        return ""
    m = re.search(r"#\s*essence:\s*(.+)", txt)
    return m.group(1).strip() if m else ""


def mtime_of(gd: str) -> float:
    """the .gd's last-modified unix timestamp (0 if unknown) — the 'last changed' key."""
    try:
        return os.path.getmtime(gd) if gd else 0.0
    except OSError:
        return 0.0


def capture_of(name: str) -> str:
    for rel in (f"scene-catalog/{name}.png",
                f"artifact-gallery/captures/{name}/front.png",
                f"wall-shots/{name}.png"):
        if os.path.exists(os.path.join(PUB, rel)):
            return "/" + rel
    return ""


SPINE = ["primitives", "transformation", "array_tutorial", "color", "change",
         "isosurfaces", "boolean_surfaces", "forces", "wavefunctions", "randomness",
         "noise", "cellularautomata", "fractals", "lsystems", "proceduralgeneration",
         "swarmintelligence", "softbodies", "machinelearning", "graphtheory",
         "foundationscrisis", "qfeplaboratory", "postfoundationscrisis"]


def main() -> int:
    reg = build_registry()
    key = {}   # name -> {roles:[], voltage:[], alt:[], chapters:set}

    def touch(name):
        return key.setdefault(name, {"beats": [], "voltage": [], "alts": [],
                                     "chapters": set(), "weak": False})

    for seq in SPINE:
        p = os.path.join(BASE_DIR, f"{seq}.json")
        if not os.path.exists(p):
            continue
        d = load_json(p)
        for bt in d.get("beats", []):
            if bt.get("missing"):
                continue
            e = touch(bt["cast"])
            e["beats"].append({"seq": seq, "role": bt["role"]})
            e["chapters"].add(seq)
            if bt.get("weak"):
                e["weak"] = True
            for a in bt.get("alts", []):
                ae = touch(a)
                ae["alts"].append({"seq": seq, "role": bt["role"]})
                ae["chapters"].add(seq)
        for v in d.get("voltage", []):
            e = touch(v["piece"])
            e["voltage"].append({"seq": seq, "why": v.get("why", ""), "after": v.get("after", "")})
            e["chapters"].add(seq)

    entries = []
    for name, e in key.items():
        scene = reg.get(name, "")
        gd = gd_path(name, scene)
        is_hero = bool(e["beats"])
        is_volt = bool(e["voltage"])
        tier = ("hero_voltage" if is_hero and is_volt
                else "hero" if is_hero
                else "voltage" if is_volt
                else "understudy")
        weight = len(e["chapters"])
        entries.append({
            "name": name,
            "tier": tier,
            "weight": weight,
            "weak": e["weak"],
            "chapters": sorted(e["chapters"], key=lambda s: SPINE.index(s) if s in SPINE else 99),
            "beats": e["beats"],
            "voltage": e["voltage"],
            "alts": e["alts"],
            "essence": essence_of(gd),
            "capture": capture_of(name),
            "scene": scene,
            "mtime": round(mtime_of(gd)),
            "has_md": os.path.exists(os.path.join(PUB, "artifact-md", name + ".md")),
        })

    # rank: heroes+voltage first, then by book-weight, then weak-first (improve worklist)
    order = {"hero_voltage": 0, "hero": 1, "voltage": 2, "understudy": 3}
    entries.sort(key=lambda x: (order[x["tier"]], -x["weight"], not x["weak"], x["name"]))

    n_key = sum(1 for e in entries if e["tier"] != "understudy")
    out = {"generated_by": "tools/build_key_artifacts.py",
           "total_promoted": len(entries),
           "key_count": n_key,
           "with_capture": sum(1 for e in entries if e["capture"]),
           "with_essence": sum(1 for e in entries if e["essence"]),
           "weak": sum(1 for e in entries if e["weak"]),
           "entries": entries}
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        json.dump(out, f, indent=1, ensure_ascii=False)
    print(f"key-artifacts.json: {len(entries)} promoted ({n_key} key, "
          f"{len(entries)-n_key} understudy), {out['with_capture']} captured, "
          f"{out['with_essence']} with DNA essence, {out['weak']} weak -> {OUT}")
    # tier breakdown
    from collections import Counter
    c = Counter(e["tier"] for e in entries)
    for t in ("hero_voltage", "hero", "voltage", "understudy"):
        print(f"  {t:14s} {c.get(t,0)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
