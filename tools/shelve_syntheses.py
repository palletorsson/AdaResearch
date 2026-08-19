#!/usr/bin/env python3
"""shelve_syntheses.py — give every synthesis a SHELF, so it can sit in the endless museum.

WHAT A SHELF IS HERE. The museum does not place an artifact; it places a DRESSING ROOM —
commons/artifacts/dressing_rooms/<token>.json, the canonical staged unit. The room's
`posture` picks a staging template (commons/data/staging_dna.json: pedestal -> specimen ->
station_plinth; table -> instrument -> station_bench; platform -> a stage) and its footing
TILES say where the raised support is: 1 is floor, 2 is a 1.0 m top, 3 a 1.5 m plinth.
DressingRoomBuilder (staged mode) renders the raised region AS the station prop — that
prop is the shelf. No raised tile, no prop, and the artifact stands on bare floor.

THE STATE THIS FOUND. Of 109 syntheses, 88 had no dressing room at all, and the 21 that
did were all `_generated`, all flat ([[1,1,1]]), none with a posture. So the museum's
fallback for every one of them was a 1x1 flat pad: no shelf. And the registry hints were
wrong in the way that matters — builders wrote `spatial_needs.platform: "floor"` on 0.4 m
jars and 0.57 m boxes, meaning "it stands on the floor", while the posture vocabulary
reads `floor` as TERRAIN (the artifact IS the ground; no support ever). Wave 23 measured
the consequence from the other side: six rooms where the works were 1.5%-5.3% of the hall.

THE RULE, from the measured body and nothing else (registry `measurements.aabb_size`,
falling back to the size oracle). Bodies, not gauges:

    base <= 0.9 m           pedestal   a specimen held to the eye (1x1 plinth, 1.5 m top)
    base <= 3.5 m           table      a bench you stand square in front of (3x3, 1.0 m)
    base <= 5.2 m           platform   a stage (5x5, 1.0 m)
    larger, or >12 m long   monument   a SPACE, not an object — walked into, not shelved

Flat things (h < 0.4) are NOT left on the floor: a mosaic on a table at hand height is the
museum convention, and on bare floor in a big hall it is a speck. Float keywords are
ignored for syntheses — accord_swarm is a BENCH about swarms, not a swarm.

Authored (non-_generated) rooms are never overwritten. `--write` applies; dry-run prints.

Usage:  python tools/shelve_syntheses.py            # dry run
        python tools/shelve_syntheses.py --write    # write rooms + registry hints
"""
from __future__ import annotations
import json, pathlib, sys, collections, re

REPO = pathlib.Path(__file__).resolve().parents[1]
REG = REPO / "commons" / "artifacts" / "registry"
ROOMS = REPO / "commons" / "artifacts" / "dressing_rooms"
sys.path.insert(0, str(REPO / "tools"))
import classify_postures as cp   # the canonical room writer; we only choose the posture


def body_of(tok: str, entry: dict, sizes: dict) -> tuple:
    """(base_m, height_m, max_dim_m, source) — registry measurement first, oracle second."""
    m = (entry.get("measurements") or {}).get("aabb_size")
    if isinstance(m, list) and len(m) == 3 and max(float(x) for x in m) > 0.05:
        a = [float(x) for x in m]
        return (max(a[0], a[2]), a[1], max(a), "registry.measurements")
    s = sizes.get(tok) or {}
    if s.get("base_m"):
        return (float(s.get("base_m") or 0), float(s.get("height_m") or 0),
                float(s.get("max_dimension_m") or 0), "size oracle")
    return (0.0, 0.0, 0.0, "UNMEASURED")


def shelf_for(base: float, h: float, max_dim: float) -> tuple:
    if max_dim > 12.0 or base > 5.2:
        return "monument", "a space, not an object"
    if base <= 0.9:
        return "pedestal", "specimen"
    if base <= 3.5:
        return "table", "bench"
    return "platform", "stage"


def main() -> int:
    write = "--write" in sys.argv
    reg = cp.load_registry()
    sizes = cp.load_sizes()
    synth = sorted(t for t, e in reg.items() if ((e.get("dna") or {}).get("sources")))
    rows, dist = [], collections.Counter()
    for t in synth:
        e = reg[t]
        base, h, md, src = body_of(t, e, sizes)
        if src == "UNMEASURED":
            posture, why = "pedestal", "UNMEASURED — default museum pose, measure it"
        else:
            posture, why = shelf_for(base, h, md)
        dist[posture] += 1
        existing = cp.load_room(t)
        authored = bool(existing) and "_generated" not in existing and not cp.is_default_pillar(existing)
        rows.append((t, posture, why, base, h, src, existing is not None, authored))

    print(f"{len(synth)} syntheses   ->   " + "  ".join(f"{k}:{v}" for k, v in sorted(dist.items())))
    print(f"\n{'token':<24}{'shelf':<10}{'base':>6}{'h':>6}  {'room':<9} why")
    for t, p, why, b, h, src, has, auth in rows:
        flag = "AUTHORED" if auth else ("exists" if has else "new")
        print(f"{t:<24}{p:<10}{b:>6.2f}{h:>6.2f}  {flag:<9} {why}" + ("" if src != "UNMEASURED" else "  !! no body"))

    if not write:
        print("\n(dry run — pass --write to apply)")
        return 0

    status = collections.Counter()
    for t, p, why, b, h, src, has, auth in rows:
        existing = cp.load_room(t)
        if auth:
            status["skip-authored"] += 1
            continue
        st = cp.write_room(t, p, existing, True)
        status[st] += 1
        # The registry hint, so a future regeneration from the contract agrees with the
        # room. Each synthesis has its OWN registry file (<token>.json), so the round-trip
        # touches one small token-keyed dict — the 15,121-line reformat risk is a
        # multi-token file's, and we refuse if this turns out not to be one.
        rp = REG / f"{t}.json"
        if rp.exists():
            raw = rp.read_text(encoding="utf-8")
            d = json.loads(raw)
            if len((d.get("artifacts") or {})) != 1:
                status["registry-skipped(multi-token file)"] += 1
                continue
            sn = d["artifacts"][t].setdefault("spatial_needs", {})
            sn["platform"] = p
            sn["shelf_rule"] = f"{why} (base {b:.2f} m, h {h:.2f} m, {src})"
            indent = "\t" if re.search(r"^\t", raw, re.M) else 2
            rp.write_text(json.dumps(d, indent=indent, ensure_ascii=False) + "\n", encoding="utf-8")
            status["registry-hinted"] += 1
    print("\nwrite results:", dict(status))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
