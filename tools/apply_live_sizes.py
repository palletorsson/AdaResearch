#!/usr/bin/env python
"""apply_live_sizes.py — turn the --validate-props report into a live-size override.

WallHangarEditor --validate-props measures each held artifact's REAL footprint
over 56 frames; the static artifact_sizes.json only gives geometry 2 frames, so
it under-measures deferred / field artifacts — which is exactly what fooled the
HELD-vs-WORLD size-gate (a 3.37 m visualization tiered "small" landed on a 1 m
plinth and overhung). This writes those accurate footprints to a non-destructive
override the generator's base() prefers via max(static, live): the live number
only ever GROWS a size, so it catches the under-measurement without trusting a
broken under-measure (a half-built artifact that measured tiny stays its static
size).

  In:  commons/data/prop_validation_report.json   (copy of user://prop_shots/_report.json)
  Out: commons/data/artifact_sizes_live.json       ({sizes: {art: {base_m, source}}})

Run after a validate-props pass:  python tools/apply_live_sizes.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IN = os.path.join(ROOT, "commons", "data", "prop_validation_report.json")
OUT = os.path.join(ROOT, "commons", "data", "artifact_sizes_live.json")
STATIC = os.path.join(ROOT, "commons", "data", "artifact_sizes.json")


def main() -> None:
    rep = json.load(open(IN, encoding="utf-8"))
    static = json.load(open(STATIC, encoding="utf-8")).get("sizes", {})
    sizes = {}
    grew = []
    for r in rep:
        w = float(r.get("art_w", 0) or 0)
        if w <= 0.0:
            continue  # missing / unmeasured — leave the static value in place
        art = r["artifact"]
        sizes[art] = {"base_m": round(w, 2), "source": "validate-props"}
        st = float((static.get(art) or {}).get("base_m", 0.0) or 0.0)
        if w > st + 0.05:
            grew.append((art, st, round(w, 2)))
    json.dump(
        {"_comment": "live footprints from WallHangarEditor --validate-props; "
                     "generator base() takes max(static, live)", "sizes": sizes},
        open(OUT, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    print(f"wrote {OUT} ({len(sizes)} live sizes; {len(grew)} grow the static)")
    for art, st, lv in sorted(grew, key=lambda x: -x[2]):
        print(f"  {art:32s} static {st:5.2f} -> live {lv:5.2f}  (was under-measured)")


if __name__ == "__main__":
    main()
