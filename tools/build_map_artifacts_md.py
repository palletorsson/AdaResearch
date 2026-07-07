#!/usr/bin/env python3
"""Per-map artifacts.md — summarize each map through the artifacts it contains.

The roster IS the summary: what the room is made of, in the order you meet it.
For every map in the spine, reads its map_data.json `interactables` layer (the
real, full artifact list in reading order), enriches each token with its name /
image / essence from order_of_things.json, and writes:

    commons/maps/<Map>/artifacts.md

Usage:
  python tools/build_map_artifacts_md.py            # every spine map
  python tools/build_map_artifacts_md.py --map Point_One
"""
from __future__ import annotations
import argparse, json
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENC = ROOT.parent / "ada_encyclopedia"
ORDER_JSON = ENC / "public" / "order_of_things.json"
MAPS_DIR = ROOT / "commons" / "maps"


def by_lookup():
    d = json.loads(ORDER_JSON.read_text(encoding="utf-8"))
    idx = {}
    for arr in ("spine", "branch", "dna", "rest"):
        for it in d.get(arr, []):
            idx.setdefault(it["lookup"], it)
    # spine maps, in spine order
    maps = OrderedDict()
    for it in d.get("spine", []):
        mp = it.get("map") or ""
        if mp:
            maps.setdefault(mp, it)   # value carries sequence/phase for the header
    return idx, maps


def first_line(map_name: str, fname: str) -> str:
    p = MAPS_DIR / map_name / fname
    if not p.exists():
        return ""
    for ln in p.read_text(encoding="utf-8", errors="ignore").splitlines():
        s = ln.strip()
        if s and not s.startswith("#") and not s.startswith(">"):
            return s
    return ""


def map_artifacts(map_name: str) -> list[str]:
    """Lookups in the map's interactables layer, reading order, first occurrence."""
    p = MAPS_DIR / map_name / "map_data.json"
    if not p.exists():
        return []
    try:
        d = json.loads(p.read_text(encoding="utf-8", errors="ignore"))
    except Exception:
        return []
    grid = (d.get("layers") or {}).get("interactables") or []
    out, seen = [], set()
    for row in grid:
        for cell in row or []:
            s = str(cell).strip()
            if not s or s.startswith("#"):
                continue
            lk = s.split("#")[0].split(":")[0].strip()
            if lk and lk not in seen:
                seen.add(lk)
                out.append(lk)
    return out


def render(map_name: str, head: dict, idx: dict) -> str | None:
    arts = map_artifacts(map_name)
    if not arts:
        return None
    title = map_name.replace("_", " ")
    seq = head.get("sequence", "")
    phase = head.get("phase", "")
    intro = first_line(map_name, "blurb.md") or first_line(map_name, "summary.md")

    L = [f"# {title} — Artifacts",
         f"*{seq}{' · ' + phase if phase else ''} · {len(arts)} artifacts*", ""]
    if intro:
        L += [f"> {intro}", ""]
    L += ["The map, read through what it holds — its artifacts in the order you meet them:", ""]
    for lk in arts:
        it = idx.get(lk, {})
        name = it.get("name") or lk
        L.append(f"## {name}")
        if it.get("image"):
            L.append(f"![{name}]({it['image']})")
        why = it.get("why", "")
        if why:
            L.append("")
            L.append(why)
        L.append("")
        L.append(f"`{lk}`")
        L.append("")
    return "\n".join(L)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", help="only this map")
    args = ap.parse_args()

    idx, maps = by_lookup()
    n = 0
    for mp, head in maps.items():
        if args.map and mp != args.map:
            continue
        d = MAPS_DIR / mp
        if not d.exists():
            continue
        md = render(mp, head, idx)
        if md is None:
            continue
        (d / "artifacts.md").write_text(md, encoding="utf-8")
        n += 1
    print(f"wrote {n} artifacts.md (one per spine map) under commons/maps/<Map>/")


if __name__ == "__main__":
    main()
