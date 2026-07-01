#!/usr/bin/env python
"""build_artifact_sizes_public.py — a lean name->base_m lookup for EVERY known
artifact (not just the ones on a particular map), for client-side use.

The simulator needs this to size candidates when it swaps an ontological
neighbor in for a placeholder pearl — the neighbor could be any artifact in
the registry, not just one already placed on the current map.

  Out: ada_encyclopedia/public/artifact-sizes-all.json  ({name: base_m})

Run: python tools/build_artifact_sizes_public.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.path.join(os.path.dirname(ROOT), "ada_encyclopedia")
OUT = os.path.join(ENC, "public", "artifact-sizes-all.json")


def main() -> None:
    st = json.load(open(os.path.join(ROOT, "commons", "data", "artifact_sizes.json"), encoding="utf-8")).get("sizes", {})
    lv_path = os.path.join(ROOT, "commons", "data", "artifact_sizes_live.json")
    lv = json.load(open(lv_path, encoding="utf-8")).get("sizes", {}) if os.path.exists(lv_path) else {}
    names = set(st) | set(lv)
    out = {}
    for n in names:
        s = float((st.get(n) or {}).get("base_m", 0) or 0)
        l = float((lv.get(n) or {}).get("base_m", 0) or 0)
        b = max(s, l)
        if b > 0:
            out[n] = round(b, 2)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(out, open(OUT, "w", encoding="utf-8"), separators=(",", ":"))
    print(f"wrote {OUT}  ({len(out)} artifacts, {os.path.getsize(OUT)//1024} KB)")


if __name__ == "__main__":
    main()
