"""How many placements have TWO things raising them, and do they fight?

2026-09-08, Palle: "in Point_Trace when I set science_screen:180:3 y offset the
y offset does not show". It did show. The cell was

    science_screen:180:3:0.5#offset:0.00,-2.95,0.00

and the museum applied BOTH: the head's +3.00 at endless_museum.gd:13006, then
the tail's -2.95 at :13036. Net +0.05 m, which em_built.json confirms as
world y = 0.05. Two authorities over one height, disagreeing, and nothing said so.

endless_museum.gd's own comment, twenty lines above the arithmetic:

    "A pedestal under one artifact took six rounds to trace, because SIX
     independent things can raise a body and none of them says so"

This counts them across the corpus. Three shapes, in descending nastiness:

  CANCELLING   head y-offset and a #offset y that largely undo each other. The
               author almost certainly means one of them. Point_Trace's screen.
  SWALLOWED    head y-offset AND #plinth. :12954 erases hover_m outright when a
               token asks for a pedestal ("a token that asks for a pedestal does
               not also hover above it"), so the head field is silently DROPPED
               — the map says a number the museum never reads.
  STACKED      head y-offset and a #offset y pulling the SAME way. Not a bug, but
               the total is the sum of two numbers written in two places.

  python tools/check_lift_authorities.py                 # the report
  python tools/check_lift_authorities.py --seq=forces    # one chapter
  python tools/check_lift_authorities.py --gate          # exit 1 if any CANCELLING or SWALLOWED

WHAT IT DELIBERATELY DOES NOT FLAG. A prefixed head (mc:, gridagent:,
criticalinfo:, cluster:) carries an identity in its fields, not a transform, and
a head with a WORD anywhere in it is opaque for the same reason —
`tt:row_early:180:1.0` has a name in field 1, and reading field 2 as a height
would invent one. Both are skipped, and counted so the skip is visible.

AND ONE THING IT CANNOT SEE: whether the net height is RIGHT. It reads the map,
not the room. A cancelling pair may be exactly what the author wanted after
measuring in the headset; the point is that the intent is split across two
fields, so the next edit to either one moves the body by a number nobody expects.
"""
from __future__ import annotations

import argparse
import io
import json
import sys
from collections import Counter
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
MAPS = ROOT / "commons" / "maps"

# GridInteractablesComponent branches on these before the normal parser runs;
# the field after the colon is an identity, never a rotation or a height.
PREFIXED = ("mc:", "gridagent:", "criticalinfo:", "cluster:")


def num(s: str):
    try:
        return float(str(s).strip())
    except (TypeError, ValueError):
        return None


def read(cell: str) -> dict | None:
    """One interactables cell -> what raises it, or None if nothing can."""
    raw = str(cell or "").strip()
    if not raw:
        return None
    segs = raw.split("#")
    head = segs[0].strip()
    if ";" in head and ":" not in head.split(";", 1)[0]:
        head = head.replace(";", ":", 1)
    if not head:
        return None
    tails = {}
    for s in segs[1:]:
        i = s.find(":")
        if i > 0:
            tails[s[:i].strip()] = s[i + 1:]
    if head.startswith(PREFIXED):
        return {"token": head, "skip": "prefixed", "raw": raw}
    parts = head.split(":")
    # a WORD anywhere in the head makes every field after it unreadable
    if any(f.strip() != "" and num(f) is None for f in parts[1:]):
        return {"token": parts[0], "skip": "word-in-head", "raw": raw}

    head_y = num(parts[2]) if len(parts) > 2 and str(parts[2]).strip() != "" else None
    off_y = None
    if "offset" in tails:
        bits = str(tails["offset"]).split(",")
        if len(bits) >= 3 and all(num(b) is not None for b in bits[:3]):
            off_y = num(bits[1])
    plinth = None
    if "plinth" in tails:
        plinth = num(str(tails["plinth"]).split(",")[0])
    return {"token": parts[0], "head_y": head_y, "off_y": off_y,
            "plinth": plinth, "raw": raw, "skip": ""}


def classify(r: dict) -> str:
    hy, oy, pl = r.get("head_y"), r.get("off_y"), r.get("plinth")
    # :12954 — a token that asks for a pedestal has its hover ERASED
    if hy is not None and abs(hy) > 0.001 and pl is not None and pl > 0.05:
        return "SWALLOWED"
    if hy is None or abs(hy) <= 0.001 or oy is None or abs(oy) <= 0.001:
        return ""
    net = hy + oy
    if hy * oy < 0 and abs(net) < abs(hy) * 0.5:
        return "CANCELLING"
    return "STACKED"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--seq", default="", help="only the maps of this sequence")
    ap.add_argument("--gate", action="store_true", help="exit 1 on any CANCELLING or SWALLOWED")
    a = ap.parse_args()

    names: list[str] = []
    if a.seq:
        for f in sorted((ROOT / "commons" / "maps" / "sequences").glob("*.json")):
            try:
                doc = json.loads(io.open(f, encoding="utf-8").read())
            except Exception:
                continue
            raw = doc.get("sequences") or {}
            items = raw.items() if isinstance(raw, dict) else [
                ((s.get("id") or s.get("name") or ""), s) for s in raw if isinstance(s, dict)]
            for sid, sq in items:
                if sid == a.seq and isinstance(sq, dict) and not names:
                    names = list(sq.get("maps") or [])
    else:
        names = sorted(p.name for p in MAPS.iterdir() if (p / "map_data.json").exists())

    kinds: dict[str, list] = {"CANCELLING": [], "SWALLOWED": [], "STACKED": []}
    skips = Counter()
    n_cells = n_head = n_off = n_maps = 0

    for name in names:
        p = MAPS / name / "map_data.json"
        if not p.exists():
            continue
        try:
            doc = json.loads(io.open(p, encoding="utf-8").read())
        except Exception:
            continue
        n_maps += 1
        lay = doc.get("layers", doc)
        for z, row in enumerate(lay.get("interactables") or []):
            for x, v in enumerate(row):
                r = read(v)
                if r is None:
                    continue
                n_cells += 1
                if r.get("skip"):
                    skips[r["skip"]] += 1
                    continue
                if r.get("head_y") is not None and abs(r["head_y"]) > 0.001:
                    n_head += 1
                if r.get("off_y") is not None and abs(r["off_y"]) > 0.001:
                    n_off += 1
                k = classify(r)
                if k:
                    kinds[k].append((name, z, x, r))

    print("TWO AUTHORITIES OVER ONE HEIGHT — %d placements in %d maps%s"
          % (n_cells, n_maps, (" (sequence %s)" % a.seq) if a.seq else ""))
    print("  %d carry a head y-offset, %d carry a #offset y" % (n_head, n_off))
    print("  skipped as unreadable: %s" % (dict(skips) or "none"))
    print()
    for k, blurb in (("SWALLOWED", "head y-offset SILENTLY DROPPED — #plinth erases it (:12954)"),
                     ("CANCELLING", "head and #offset fight; the author means one of them"),
                     ("STACKED", "both pull the same way — the height is a sum written twice")):
        rows = kinds[k]
        print("%-11s %4d   %s" % (k, len(rows), blurb))
        for name, z, x, r in rows[:14]:
            hy = r.get("head_y") or 0.0
            oy = r.get("off_y") or 0.0
            pl = r.get("plinth") or 0.0
            if k == "SWALLOWED":
                # the head is ERASED, so the built height is the pedestal plus the
                # fine offset. Printing hy as "net" would repeat the very lie the
                # map tells.
                said = "map says %+.2f" % hy
                built = "museum builds %+.2f (plinth %.2f + offset %+.2f)" % (pl + oy, pl, oy)
            else:
                said = "head %+.2f, offset %+.2f" % (hy, oy)
                built = "net %+.2f m" % (hy + oy)
            print("    %-28s (%2d,%2d) %-16s %s" % (name, z, x, said, built))
            print("    %-28s          %s" % ("", r["raw"][:78]))
        if len(rows) > 14:
            print("    … and %d more" % (len(rows) - 14))
        print()

    bad = len(kinds["CANCELLING"]) + len(kinds["SWALLOWED"])
    if bad:
        print("%d placement(s) where the map says a height the museum does not build." % bad)
    else:
        print("no placement has two authorities disagreeing about its height.")
    return 1 if (a.gate and bad) else 0


if __name__ == "__main__":
    sys.exit(main())
