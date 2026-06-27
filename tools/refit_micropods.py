#!/usr/bin/env python3
"""Re-fit genuinely sub-1 m artifacts in the curated walls onto station_micropod.

Pairs each slim 1x1 station_plinth with the artifact sharing its (x,z); if that
artifact is sub-1 m (measured `measurements.aabb_size` max horizontal < THRESH, or in
the curator-flagged allow-list), swaps the plinth -> station_micropod, keeping the
caption_text + top_height and re-seating the artifact on the micropod cap.

Dry-run by default; pass --apply to write the curated_walls files.
"""
import json
import glob
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CURATED = os.path.join(ROOT, "commons", "data", "curated_walls")
REG = os.path.join(ROOT, "commons", "artifacts", "registry")
THRESH = 0.82          # sub-1 m horizontal footprint (metres)
APPLY = "--apply" in sys.argv

# Tokens the curators explicitly flagged sub-1 m that lack a measured aabb_size
# (flat pads / small held cubes whose 1-cell footprint hides their true scale).
FORCE_SUB1M = {
    "force_pad", "force_cube", "vector_machine", "length_lantern",
}
# Never micropod these even if small-measured (they read as proper podium things).
NEVER = set()


def load_aabb():
    aabb = {}
    for p in glob.glob(os.path.join(REG, "*.json")):
        try:
            d = json.load(open(p, encoding="utf-8"))
        except Exception:
            continue
        arts = d.get("artifacts", d)
        if not isinstance(arts, dict):
            continue
        for tok, e in arts.items():
            if isinstance(e, dict):
                m = e.get("measurements") or {}
                sz = m.get("aabb_size")
                if sz and len(sz) >= 3:
                    aabb[tok] = sz
    return aabb


def sub1m(tok, aabb):
    if tok in NEVER:
        return False, ""
    if tok in FORCE_SUB1M:
        return True, "flagged"
    sz = aabb.get(tok)
    if sz:
        mx = max(float(sz[0]), float(sz[2]))
        # Skip near-zero AABBs (unbuilt/empty measurements, e.g. motion demos measured
        # at their spawn point) — a full 1 m plinth is the safer base than a 0.6 m post
        # under something whose true size we don't actually know.
        if 0.10 <= mx < THRESH:
            return True, "aabb %.2fx%.2f" % (float(sz[0]), float(sz[2]))
    return False, ""


def main():
    aabb = load_aabb()
    total = 0
    for wp in sorted(glob.glob(os.path.join(CURATED, "*.json"))):
        wall = json.load(open(wp, encoding="utf-8"))
        pieces = wall["pieces"]
        swaps = []
        for pc in pieces:
            if pc.get("token") != "station_plinth":
                continue
            cfg = pc.get("config", {})
            if int(cfg.get("width_cells", 1)) > 1 or int(cfg.get("depth_cells", 1)) > 1:
                continue   # only slim 1x1 plinths are micropod candidates
            art = next((q for q in pieces if q is not pc
                        and abs(q["x"] - pc["x"]) < 0.05 and abs(q["z"] - pc["z"]) < 0.05
                        and not str(q.get("token", "")).startswith("station_")), None)
            if not art:
                continue
            ok, why = sub1m(art["token"], aabb)
            if ok:
                swaps.append((pc, art, why))
        for pc, art, _why in swaps:
            cap = pc.get("config", {}).get("caption_text", "")
            th = float(pc.get("config", {}).get("top_height", 1.1))
            if APPLY:
                pc["token"] = "station_micropod"
                pc["config"] = {"caption_text": cap, "top_height": th}
                art["y"] = th
        if APPLY and swaps:
            json.dump(wall, open(wp, "w", encoding="utf-8"), indent=1)
        total += len(swaps)
        name = os.path.basename(wp)[:-5]
        print("%-32s %d -> %s" % (name, len(swaps),
              ", ".join("%s(%s)" % (a["token"], why) for _, a, why in swaps)))
    print("\nTOTAL: %d swaps  (%s)" % (total, "APPLIED" if APPLY else "dry-run"))


if __name__ == "__main__":
    main()
