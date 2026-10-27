#!/usr/bin/env python3
"""albers_glass_identity_diff.py - the default albers wall, HEAD script against the working
tree, counted pixel by pixel from the PNGs probe_albers_glass_render.gd --mode=identity saved.

Reads ada_run/albers_glass_default_identity.json (written by the probe), compares every view's
PNGs pair by pair as the probe lists them (head_1 vs tree_3 and tree_2 vs head_4 are the
script's effect at equal session parity; head_1 vs head_4 and tree_2 vs tree_3 the measured
position noise) and writes ada_run/albers_glass_default_identity_pixels.json: per pair the
differing pixels and the largest channel difference. Exit 0 only when both script pairs are
identical in every view.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageChops

REPO = Path(__file__).resolve().parents[1]
SRC = REPO / "ada_run" / "albers_glass_default_identity.json"
OUT = REPO / "ada_run" / "albers_glass_default_identity_pixels.json"


def res(p: str) -> Path:
    return REPO / p.replace("res://", "")


def diff(a: Path, b: Path) -> dict:
    ia = Image.open(a).convert("RGB")
    ib = Image.open(b).convert("RGB")
    if ia.size != ib.size:
        return {"same_size": False}
    d = ImageChops.difference(ia, ib)
    bands = d.split()
    mx = max(band.getextrema()[1] for band in bands)
    # a pixel differs when any channel does
    mask = ImageChops.lighter(ImageChops.lighter(bands[0], bands[1]), bands[2]).point(lambda v: 255 if v else 0)
    differing = sum(1 for v in mask.getdata() if v)
    return {"same_size": True, "differing_pixels": differing, "max_channel_diff_255": mx,
            "pixels": ia.size[0] * ia.size[1], "png_bytes_equal": a.read_bytes() == b.read_bytes()}


def main() -> int:
    if not SRC.exists():
        print(f"no {SRC}: run probe_albers_glass_render.gd --mode=identity first")
        return 2
    rep = json.loads(SRC.read_text(encoding="utf-8"))
    out = {"source": str(SRC.relative_to(REPO)), "probe_verdict": rep.get("verdict"),
           "head_sha256": rep.get("head_sha256"), "tree_sha256": rep.get("tree_sha256"), "views": {}}
    ok = True
    pairs = rep.get("pairs") or {}
    for name, v in (rep.get("views") or {}).items():
        files = {tag: res(p) for tag, p in v["files"].items()}
        row = {}
        for pname, (a, b) in pairs.items():
            row[pname] = diff(files[a], files[b])
            if pname.startswith("script"):
                ok = ok and row[pname].get("differing_pixels") == 0
        out["views"][name] = row
        print(f"  {name}: " + ", ".join(f"{k} {r.get('differing_pixels')} px (max {r.get('max_channel_diff_255')})"
                                       for k, r in row.items()))
    out["verdict"] = "PIXEL-IDENTICAL (same session parity)" if ok and out["views"] else "DIFFERS"
    OUT.write_text(json.dumps(out, indent=2), encoding="utf-8")
    print(out["verdict"], "->", OUT.relative_to(REPO))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
