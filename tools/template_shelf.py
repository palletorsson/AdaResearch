# -*- coding: utf-8 -*-
"""template_shelf.py — one shelf, so the plans and the laws can finally meet.

This project has two families that have never met.

THE TILE FAMILY: /template-pattern-editor authors a tile of cell roles, it lands
in template_patterns.json, /template-maps paints it as a region and fills its
slots, endless_museum.gd streams it as a walkable corridor. Here a floor plan is
DATA — painted, or extracted from eight real museums, or derived from the 269
maps of the spine. Real provenance, and no laws: nothing checks that the artifact
standing in a slot fits it, that the hero's reach is respected, that the walk
works.

THE LAW FAMILY: wizard_compose.py, where a plan is GROWN from a cast under FIT,
REACH, SEAM and WALL-VETO, walked by the pathfinder, furnished by the occupant
pass. All the laws, and no provenance: it invents its plans, and its output is a
species the curriculum contains zero instances of.

The shelf is the smallest thing that lets one become the other's input. It is
DERIVED, never authored: template_patterns.json belongs to the museum line and
is edited live, so nothing here writes to it. Rebuild the shelf whenever either
source moves.

    python tools/template_shelf.py build
    python tools/template_shelf.py list --source=museum --stampable
"""
import json, argparse, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SHELF = ROOT / "commons/data/template_shelf.json"
SOURCES = [
    ("commons/data/template_patterns.json", None),      # source decided per entry
    ("commons/data/spine_typologies.json", "spine"),
    ("commons/data/spine_segments.json", "spine-segment"),
]


def slot_count(tile):
    return sum(1 for row in (tile or []) for c in row if str(c).endswith("s"))


def normalise(key, p, source):
    """One entry shape. Each family keeps its own extras rather than losing them
    — the museum's walk_rule and em_order, the spine's share and derivation —
    because the shelf is a JOIN, not a lowest common denominator."""
    core = {"label", "color", "w", "h", "mode", "tile"}
    tile = p.get("tile") or []
    return {
        "key": key,
        "label": p.get("label", key),
        "color": p.get("color", "#888888"),
        "w": int(p.get("w", max((len(r) for r in tile), default=0))),
        "h": int(p.get("h", len(tile))),
        "mode": p.get("mode", "repeat"),
        "source": source,
        "slots": slot_count(tile),
        "stampable": p.get("mode") == "stamp",     # a whole plan, not a repeating motif
        "tile": tile,
        "extra": {k: v for k, v in p.items() if k not in core},
    }


def build():
    out, seen, counts = {}, {}, {}
    for rel, forced in SOURCES:
        f = ROOT / rel
        if not f.exists():
            print("  missing (skipped): %s" % rel)
            continue
        pats = json.loads(f.read_text(encoding="utf-8")).get("patterns", {})
        for key, p in pats.items():
            # the museum line tags its extractions; everything else in that file
            # came off the pattern editor, which is a different kind of claim
            src = forced or ("museum" if p.get("museum") else "authored")
            k = key
            if k in out:
                # never silently overwrite: two families can name a plan the same
                k = "%s__%s" % (src, key)
                print("  key collision on %r -> kept as %r" % (key, k))
            out[k] = normalise(k, p, src)
            seen[k] = rel
            counts[src] = counts.get(src, 0) + 1
    stampable = sum(1 for v in out.values() if v["stampable"])
    SHELF.write_text(json.dumps({
        "_readme": ("ONE SHELF, derived. Joins the pattern editor's tiles, the museum line's "
                    "extracted floor plans and the spine's measured typologies into a single "
                    "registry so /template-maps, endless_museum.gd and wizard_compose.py can read "
                    "the same plans. NEVER EDIT THIS FILE — it is rebuilt from its sources by "
                    "tools/template_shelf.py. `stampable` marks a whole floor plan (mode=stamp) as "
                    "opposed to a motif meant to repeat over a painted region."),
        "sources": [s[0] for s in SOURCES],
        "counts": dict(counts, total=len(out), stampable=stampable),
        "patterns": out}, indent=1), encoding="utf-8")
    print("\nshelf: %d patterns (%s), %d stampable -> %s"
          % (len(out), ", ".join("%s %d" % kv for kv in sorted(counts.items())), stampable, SHELF))


def load():
    return json.loads(SHELF.read_text(encoding="utf-8"))["patterns"] if SHELF.exists() else {}


def listing(source, stampable_only):
    pats = load()
    rows = [p for p in pats.values()
            if (not source or p["source"] == source) and (not stampable_only or p["stampable"])]
    rows.sort(key=lambda p: (p["source"], -p["slots"], p["key"]))
    print("%-34s %-9s %-6s %5s %5s %s" % ("key", "source", "mode", "w", "h", "slots"))
    for p in rows:
        print("%-34s %-9s %-6s %5d %5d %5d" % (p["key"][:34], p["source"], p["mode"],
                                               p["w"], p["h"], p["slots"]))
    print("\n%d patterns" % len(rows))


SRC_TINT = {"museum": "#946b3d", "spine": "#3d7a94", "authored": "#6b4b8a"}


def sheet(per=6):
    """A contact sheet in the museum manner: floor light, void dark, slots
    marked, one band per source. Drawn from the SHELF, so what you see is what
    the composer can now stamp — the point of the merge, made visible."""
    pats = load()
    bands = []
    for src in ("museum", "spine", "authored"):
        rows = [p for p in pats.values() if p["source"] == src and p["stampable"]]
        rows.sort(key=lambda p: (-p["slots"], p["key"]))
        bands.append((src, rows[:per]))
    CELL, PAD = 7, 24
    colw = max(p["w"] for _, rs in bands for p in rs) * CELL + 26
    rowh = max(p["h"] for _, rs in bands for p in rs) * CELL + 52
    W = PAD * 2 + per * colw
    H = PAD + 54 + len(bands) * (rowh + 26)
    sv = ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">' % (W, H, W, H),
          '<rect width="100%" height="100%" fill="#12141a"/>',
          '<text x="%d" y="30" fill="#e8e4dc" font-family="Georgia,serif" font-size="19">'
          'One shelf: %d floor plans the composer can stamp</text>' % (PAD, sum(1 for p in pats.values() if p["stampable"])),
          '<text x="%d" y="48" fill="#8a8f9a" font-family="Georgia,serif" font-size="11.5">'
          'the pattern editor’s tiles, the museum line’s extracted plans and the spine’s '
          'measured typologies, joined · floor light, void dark, slot marked</text>' % PAD]
    y = 66
    for src, rows in bands:
        n = sum(1 for p in pats.values() if p["source"] == src)
        sv.append('<text x="%d" y="%d" fill="%s" font-family="Georgia,serif" font-size="13">'
                  '%s — %d on the shelf</text>' % (PAD, y, SRC_TINT[src], src, n))
        for i, p in enumerate(rows):
            ox = PAD + i * colw
            oy = y + 14
            sv.append('<text x="%d" y="%d" fill="#6f7480" font-family="Georgia,serif" '
                      'font-size="9">%s</text>' % (ox, oy, p["label"][:26]))
            for z, row in enumerate(p["tile"]):
                for x, c in enumerate(row):
                    s = str(c); slot = s.endswith("s")
                    hh = s.rstrip("s").rstrip("fum") or "0"
                    try: hv = int(float(hh))
                    except Exception: hv = 0
                    fill = ("#191c24" if hv <= 0 else "#3a3f4c" if hv >= 4
                            else ["#c9c4b8", "#b3ada0", "#9d9789"][min(hv - 1, 2)])
                    sv.append('<rect x="%.1f" y="%.1f" width="%d" height="%d" fill="%s"/>'
                              % (ox + x * CELL, oy + 6 + z * CELL, CELL, CELL, fill))
                    if slot:
                        sv.append('<circle cx="%.1f" cy="%.1f" r="1.9" fill="%s"/>'
                                  % (ox + x * CELL + CELL / 2.0, oy + 6 + z * CELL + CELL / 2.0,
                                     SRC_TINT[src]))
        y += rowh + 26
    sv.append('</svg>')
    out = ROOT / "commons/data/template_shelf.svg"
    out.write_text("\n".join(sv), encoding="utf-8")
    print("sheet -> %s" % out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("stage", choices=["build", "list", "sheet"])
    ap.add_argument("--source", default="")
    ap.add_argument("--stampable", action="store_true")
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")
    if a.stage == "build": build()
    elif a.stage == "sheet": sheet()
    else: listing(a.source, a.stampable)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
