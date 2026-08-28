#!/usr/bin/env python3
"""Set one or more numbers in the museum's ANNEX — the enter room before 0,0,0.

2026-08-28, Palle: "can I get a courtyard and annex editor".

The annex is the four rows in front of a hall — z -4..-1, which no map cell can
name — and its FITTINGS are the window out to the maps, Folding Past behind the
glass, the roof you drop in through and the hole you drop through.

THEY LIVE IN THE MAP (2026-08-28, Palle: "move the lobby fittings into the map
too"). They used to be the `lobby` block of commons/data/em_layout.json, a
museum-wide config file — but the lobby IS segment 0's vestibule and nothing else
(`lobby_on` is `_seg_index == 0`), so it belongs to the hall standing behind it.
endless_museum.gd reads map_info.museum.lobby ahead of the file; the file keeps
its `_key` prose as documentation of what each default means.

WHY THIS IS A LINE EDITOR AND NOT json.dumps. A map is compact-rows and carries
its own arrangement; a round trip keeps the data and destroys it — 130 lines to
1870, measured today, and once a 15,121-line registry. A value is replaced in
place, on its own line, and every other byte of the file is the byte it was.

    python tools/annex_edit.py --show
    python tools/annex_edit.py --set drop_x=7 --set roof_wall_m=1.4
    python tools/annex_edit.py --map=Point_Lines --set with_counter=1
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

#: THE LOBBY LIVES IN THE MAP (2026-08-28, Palle: "move the lobby fittings into
#: the map too"). It used to be the `lobby` block of commons/data/em_layout.json,
#: a museum-wide config file — but the lobby IS segment 0's vestibule and nothing
#: else (`lobby_on` is `_seg_index == 0`), so it belongs to the hall standing
#: behind it. endless_museum.gd reads map_info.museum.lobby ahead of the file.
#: The file keeps its `_key` prose as documentation of the defaults.
DEFAULT_MAP = "Point_One"


def layout_path(map_name: str) -> str:
    return os.path.join(ROOT, "commons", "maps", map_name, "map_data.json")

#: Keys the annex editor may set, and what each one is. Anything not named here
#: is refused: the lobby block also holds strings and prose, and a typo that
#: silently invents a key would read as "the edit did nothing" rather than as an
#: error. `kind` is what the editor renders — a toggle, a cell, or a length.
FIELDS: dict[str, tuple[str, str, float, float]] = {
    # key                 kind      unit        min     max
    "window_x0":         ("cell",  "x cell",     0,     16),
    "window_x1":         ("cell",  "x cell",     0,     16),
    "window_sill_m":     ("len",   "m",          0.0,   3.0),
    "window_head_m":     ("len",   "m",          0.5,   4.5),
    "view_cell_x":       ("cell",  "x cell",     0,     16),
    "view_cell_z":       ("cell",  "z cell",    -4,     -1),
    "view_depth_m":      ("len",   "m",        -20.0,   0.0),
    "view_behind_m":     ("len",   "m",          0.0,  20.0),
    "view_y":            ("len",   "m",          0.0,   4.0),
    "view_light":        ("len",   "×",          0.0,   8.0),
    "intro_x":           ("len",   "m",          0.0,  16.0),
    "intro_y":           ("len",   "m",          0.0,   4.0),
    "drop_x":            ("cell",  "map x",      0,     24),
    "drop_z":            ("cell",  "map z",      0,     24),
    "roof_pad":          ("cell",  "cells",      0,      8),
    "roof_rise_m":       ("len",   "m",          0.0,   2.0),
    "roof_wall_m":       ("len",   "m",          0.0,   3.0),
    "door_header_m":     ("len",   "m",          0.0,   2.0),
    "drop_hole":         ("flag",  "",           0,      1),
    "intro_text":        ("flag",  "",           0,      1),
    "origin_well":       ("flag",  "",           0,      1),
    "enabled":           ("flag",  "",           0,      1),
    "with_counter":      ("flag",  "",           0,      1),
    "with_extinguisher": ("flag",  "",           0,      1),
    "with_elevator":     ("flag",  "",           0,      1),
    "with_pallet":       ("flag",  "",           0,      1),
}


def read_doc(map_name: str) -> dict:
    with open(layout_path(map_name), encoding="utf-8") as fh:
        doc = json.load(fh)
    return {"lobby": ((doc.get("map_info") or {}).get("museum") or {}).get("lobby") or {}}


def lobby_span(text: str) -> tuple[int, int]:
    """Byte span of the lobby block, so a key is only matched inside it.

    `enabled` is not unique in this file and neither is a bare number; scoping the
    search to the block is what stops an annex edit from setting somebody else's
    key that happens to share a name.
    """
    i = text.index('"lobby": {')
    depth = 0
    j = text.index("{", i)
    k = j
    while k < len(text):
        if text[k] == "{":
            depth += 1
        elif text[k] == "}":
            depth -= 1
            if depth == 0:
                return i, k + 1
        elif text[k] == '"':                 # skip a string, braces and all
            k += 1
            while k < len(text) and text[k] != '"':
                k += 2 if text[k] == "\\" else 1
        k += 1
    raise ValueError("the lobby block never closes")


def fmt(key: str, value: float) -> str:
    kind = FIELDS[key][0]
    if kind in ("flag", "cell"):
        return str(int(round(value)))
    s = ("%.6f" % float(value)).rstrip("0")
    return s + "0" if s.endswith(".") else s


def set_keys(pairs: list[tuple[str, float]], map_name: str) -> list[str]:
    # READ THE BYTES AND PUT THE SAME ONES BACK. Reading in text mode turns CRLF
    # into \n and writing with newline="" puts \n back, so the first run of this
    # tool silently converted all 154 lines of a Windows-checkout file — a change
    # git's autocrlf hid from `git diff` and `diff` then reported as "every line
    # changed", which is a terrible thing to be looking at while hunting a real
    # one-value edit somebody else made. The whole point of this tool is that it
    # touches one line; the line endings are part of that promise.
    LAYOUT = layout_path(map_name)
    raw = open(LAYOUT, "rb").read()
    text = raw.decode("utf-8")
    crlf = "\r\n" in text
    if crlf:
        text = text.replace("\r\n", "\n")
    lo, hi = lobby_span(text)
    block = text[lo:hi]
    notes = []
    for key, value in pairs:
        kind, unit, vmin, vmax = FIELDS[key]
        if not (vmin <= value <= vmax):
            raise SystemExit("%s = %s is outside %s..%s (%s)" % (key, value, vmin, vmax, unit))
        pat = re.compile(r'("%s"\s*:\s*)(-?[\d.]+|true|false)' % re.escape(key))
        m = pat.search(block)
        new = fmt(key, value)
        if m is None:
            # ADDED, NOT INVENTED. A key absent from the file is a key running on
            # the code's own default, so writing it is a real change of state and
            # is reported as one rather than passed over in silence.
            block = block.rstrip()
            assert block.endswith("}")
            block = block[:-1].rstrip().rstrip(",") + ',\n\t\t"%s": %s\n\t}' % (key, new)
            notes.append("%s: (default) -> %s   [key added]" % (key, new))
            continue
        was = m.group(2)
        # A FLAG KEEPS THE TYPE IT HAD. `enabled` is written `true` in this file
        # and the others are written 1/0; rewriting `true` as `1` would work today
        # (GDScript reads both as truthy) and quietly change what the file says a
        # flag IS. The tool edits a value, not a vocabulary.
        if kind == "flag" and was in ("true", "false"):
            new = "true" if float(value) >= 1 else "false"
        if was == new:
            notes.append("%s: already %s" % (key, new))
            continue
        block = block[:m.start(2)] + new + block[m.end(2):]
        notes.append("%s: %s -> %s" % (key, was, new))
    out = text[:lo] + block + text[hi:]
    json.loads(out)                          # refuse to write anything unparseable
    if crlf:
        out = out.replace(chr(10), chr(13) + chr(10))   # the file's own endings, given back
    tmp = LAYOUT + ".tmp"
    with open(tmp, "wb") as fh:
        fh.write(out.encode("utf-8"))
    os.replace(tmp, LAYOUT)                  # a sibling and a rename, like the book
    return notes


def main() -> int:
    ap = argparse.ArgumentParser(description="edit the museum's annex (em_layout.lobby)")
    ap.add_argument("--map", default=DEFAULT_MAP, help="the hall whose lobby to edit")
    ap.add_argument("--set", action="append", default=[], metavar="key=value")
    ap.add_argument("--show", action="store_true", help="print every editable key and its value")
    ap.add_argument("--json", action="store_true", help="print the editable block as JSON")
    ap.add_argument("--fields", action="store_true",
                    help="print the editable keys with kind, unit and bounds — what a "
                         "web editor builds its controls from, so the bounds are not "
                         "written down a second time somewhere they can drift")
    a = ap.parse_args()

    lobby = read_doc(a.map).get("lobby", {})
    if a.fields:
        json.dump({"fields": [{"key": k, "kind": kind, "unit": unit, "min": lo, "max": hi,
                               "value": lobby.get(k), "default": k not in lobby,
                               "why": lobby.get("_" + k) or lobby.get("_with_")
                               if k.startswith("with_") else lobby.get("_" + k)}
                              for k, (kind, unit, lo, hi) in FIELDS.items()]},
                  sys.stdout, ensure_ascii=False)
        sys.stdout.write("\n")
        return 0
    if a.json:
        json.dump({k: lobby.get(k) for k in FIELDS}, sys.stdout)
        sys.stdout.write("\n")
        return 0
    if a.show or not a.set:
        print("the annex — %s, map_info.museum.lobby\n" % a.map)
        for k, (kind, unit, lo, hi) in FIELDS.items():
            v = lobby.get(k, "(default)")
            print("  %-20s %-10s %-8s %s" % (k, v, unit, "%s..%s" % (lo, hi)))
        return 0

    pairs = []
    for s in a.set:
        if "=" not in s:
            raise SystemExit("--set wants key=value, got %r" % s)
        k, _, v = s.partition("=")
        k = k.strip()
        if k not in FIELDS:
            raise SystemExit("%s is not an annex key. --show lists them." % k)
        try:
            pairs.append((k, float(v)))
        except ValueError:
            raise SystemExit("%s wants a number, got %r" % (k, v))
    for n in set_keys(pairs, a.map):
        print("  " + n)
    print("\nwrote %s — the museum reads it at boot; a running one reloads within a second."
          % os.path.relpath(layout_path(a.map), ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
