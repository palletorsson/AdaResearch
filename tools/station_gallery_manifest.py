#!/usr/bin/env python3
"""station_gallery_manifest.py — collect the station-model fleet for /station-gallery.

Scans commons/data/curated_walls/clusters/ for station clusters (mk_* modkit seeds
and ws_* workstation exports), pairs each with its capture in the encyclopedia's
wall-shots, and writes public/station-gallery.json grouped by template.

Usage: python tools/station_gallery_manifest.py
"""
from __future__ import annotations

import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLUSTERS = os.path.join(REPO, "commons", "data", "curated_walls", "clusters")
ENC = os.environ.get("ADA_ENCYCLOPEDIA_PATH",
                     os.path.join(os.path.dirname(REPO), "ada_encyclopedia"))
SHOTS = os.path.join(ENC, "public", "wall-shots")
OUT = os.path.join(ENC, "public", "station-gallery.json")
SPEC = os.path.join(REPO, "commons", "data", "station_modules.json")

STRUCTURAL = ("station_wall", "station_panel", "station_plinth", "station_micropod",
              "station_stage", "station_floorline", "station_pillar", "station_luminaire",
              "station_multiscreen")


def load_json(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def parse_name(name, templates):
    """mk_<template>_<hero>_s<n> | mk_<hero>_s<n> (bench) | ws_<hero>"""
    if name.startswith("ws_"):
        return "workstation", name[3:], None
    m = re.match(r"mk_(.+)_s(\d+)$", name)
    if not m:
        return "unknown", name, None
    body, seed = m.group(1), int(m.group(2))
    stems = {t.split("_")[0]: t for t in templates if t != "bench_v1"}
    for stem, full in stems.items():
        if body.startswith(stem + "_"):
            return full, body[len(stem) + 1:], seed
    return "bench_v1", body, seed


def main():
    spec = load_json(SPEC)
    templates = list(spec.get("templates", {}))
    notes = {t: spec["templates"][t].get("_note", "") for t in templates}
    notes["workstation"] = "cluster-unit exports (pre-modkit) — hero + ladder children + lab cast"

    entries = []
    for fn in sorted(os.listdir(CLUSTERS)):
        if not fn.endswith(".json") or not (fn.startswith("mk_") or fn.startswith("ws_")):
            continue
        name = fn[:-5]
        data = load_json(os.path.join(CLUSTERS, fn))
        pieces = data.get("pieces", [])
        cast = []
        for p in pieces:
            tok = p.get("token", "").split("#")[0]
            if tok and tok not in STRUCTURAL and tok not in cast:
                cast.append(tok)
        template, hero, seed = parse_name(name, templates)
        img = f"/wall-shots/{name}.png"
        has_shot = os.path.exists(os.path.join(SHOTS, name + ".png"))
        entries.append({
            "name": name, "template": template, "hero": hero, "seed": seed,
            "pieces": len(pieces), "cast": cast,
            "img": img if has_shot else None,
            "source": data.get("source", ""),
        })

    groups = {}
    for e in entries:
        groups.setdefault(e["template"], []).append(e)

    out = {"generated_by": "tools/station_gallery_manifest.py",
           "notes": notes,
           "groups": [{"template": t, "note": notes.get(t, ""), "stations": v}
                      for t, v in sorted(groups.items())]}
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(out, f, indent=1)
    n_img = sum(1 for e in entries if e["img"])
    print(f"station-gallery.json: {len(entries)} stations in {len(groups)} groups "
          f"({n_img} with captures) -> {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
