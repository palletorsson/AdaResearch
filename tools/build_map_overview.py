#!/usr/bin/env python
"""build_map_overview.py — top-down layout + footprints of every spine map.

For each spine sequence's maps, extract the structure grid (floor height vs void), the placed
interactables with their footprint (base_m, max of static/live), and the spawn/teleporter
markers — so the encyclopedia can draw each map FROM ABOVE and you can scroll the sequences
and SEE the footprints sitting on the grid ("footprint determines the grid").

  Out: ada_encyclopedia/public/map-overview.json

Run: python tools/build_map_overview.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.path.join(os.path.dirname(ROOT), "ada_encyclopedia")
OUT = os.path.join(ENC, "public", "map-overview.json")

_SIZES = None


def load(p):
    return json.load(open(p, encoding="utf-8"))


def base_of(a):
    global _SIZES
    if _SIZES is None:
        st = load(os.path.join(ROOT, "commons", "data", "artifact_sizes.json")).get("sizes", {})
        lvp = os.path.join(ROOT, "commons", "data", "artifact_sizes_live.json")
        lv = load(lvp).get("sizes", {}) if os.path.exists(lvp) else {}
        _SIZES = (st, lv)
    st, lv = _SIZES
    return max(float((st.get(a) or {}).get("base_m", 0) or 0),
               float((lv.get(a) or {}).get("base_m", 0) or 0))


def token_name(c):
    return str(c).split("#")[0].split(":")[0].strip()


def map_data(name):
    mp = os.path.join(ROOT, "commons", "maps", name, "map_data.json")
    if not os.path.exists(mp):
        return None
    try:
        d = load(mp)
    except Exception:
        return None
    layers = d.get("layers", {})
    st = layers.get("structure", []) or []
    it = layers.get("interactables", []) or []
    ut = layers.get("utilities", []) or []
    rows = len(st)
    cols = max((len(r) for r in st), default=0)
    if rows == 0 or cols == 0:
        return None
    # structure as height-char strings ('0' = void)
    struct = ["".join((str(c).strip() or "0")[:1] for c in r).ljust(cols, "0") for r in st]
    # interactables -> footprint squares
    arts = []
    for z, r in enumerate(it):
        for x, c in enumerate(r):
            nm = token_name(c)
            if nm and nm not in ("", "0"):
                arts.append({"x": x, "z": z, "n": nm, "b": round(base_of(nm), 1)})
    # utilities: spawn + teleporter markers
    utils = []
    for z, r in enumerate(ut):
        for x, c in enumerate(r):
            code = str(c).split(":")[0].strip()
            if code in ("s", "sp", "t"):
                utils.append({"x": x, "z": z, "c": code})
    return {
        "name": name, "rows": rows, "cols": cols, "structure": struct,
        "arts": arts, "utils": utils,
        "footprint": round(sum(a["b"] for a in arts), 1),
    }


def main():
    spine = load(os.path.join(ROOT, "commons", "maps", "curriculum_spine.json"))
    out = []
    for q in sorted(spine["spine"]["sequences"], key=lambda x: float(x.get("order", 0))):
        seq = q["name"]
        sp = os.path.join(ROOT, "commons", "maps", "sequences", seq + ".json")
        maps = []
        if os.path.exists(sp):
            sd = (load(sp).get("sequences", {}) or {}).get(seq, {}) or {}
            maps = sd.get("maps", [])
        mlist = [m for m in (map_data(mn) for mn in maps) if m]
        out.append({
            "seq": seq, "phase": q.get("phase", ""), "role": q.get("qfep_role", ""),
            "n_maps": len(mlist), "maps": mlist,
        })
    # The book's generated rooms (creator_walk / wall_extrude / wall review) belong to
    # no sequence but must be findable — a synthetic, view-only section at the end.
    maps_dir = os.path.join(ROOT, "commons", "maps")
    hangars = sorted(n for n in os.listdir(maps_dir)
                     if n.startswith(("Hangar_", "Walls_"))
                     and os.path.isdir(os.path.join(maps_dir, n)))
    hlist = [m for m in (map_data(mn) for mn in hangars) if m]
    if hlist:
        out.append({"seq": "book_hangars", "phase": "book", "role": "the book's rooms",
                    "n_maps": len(hlist), "maps": hlist})
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(out, open(OUT, "w", encoding="utf-8"), separators=(",", ":"))
    sz = os.path.getsize(OUT)
    tot = sum(len(s["maps"]) for s in out)
    print(f"wrote {OUT}  ({len(out)} sequences, {tot} maps, {sz // 1024} KB)")
    for s in out:
        print(f"  {s['seq']:24s} {len(s['maps']):3d} maps")


if __name__ == "__main__":
    main()
