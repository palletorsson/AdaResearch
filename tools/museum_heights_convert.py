#!/usr/bin/env python3
"""Convert a map so its structure heights mean the same in the grid and the museum.

Palle, 2026-09-06: "can we set walls to 4 generally now and then inside the
transform have, set inner halls to 2 or 3 depending on what we want to achieve
in the maps?"  Yes - and this is the conversion.

THE RULE (endless_museum.gd, _derive_map_row, since 7a43d2a4b): a structure
value at or above the map's museum.wall_height is a wall; a value between 1 and
the threshold is FLOOR (v - 1) metres up - the grid's own reading, where a 2
stands one cube above a 1. Every map today has the default threshold 2, so its
2s are walls and it has no room for a step. This tool moves a map to threshold
4: every wall value below 4 (2 or 3 at threshold 2) becomes the wall value, and
museum.wall_height is set to 4. Afterwards 2 means one metre up and 3 two, in
both engines.

WHAT CHANGES WHERE: nothing, until the author writes a step. The grid builds a
stack of min(v, dimensions.max_height) cubes, so with max_height 2 a 4 is the
same two cubes a 2 was; the museum builds a 4 as the same 4.5 m wall it built a
2 as; tools/map_pathfinder.py keeps a wall unwalkable either way. A step of 3
(two metres) needs max_height >= 3 to build fully in the grid, and the museum
clamps the same way.

Only the structure layer and the map_info.museum key are touched, textually -
every other byte of the file is preserved (the maps are compact-rows JSON in
three indentation styles, and a json.dumps round-trip would reformat them).

WHICH 2s BECOME WALLS: in the transformation maps a 2 is both the wall round
a hole and the plateau a ride lifts you onto - the grid walks the top of any
column, and tools/map_pathfinder.py turned Trans_RotationSpectacle's teleport
unreachable when every 2 became a 4. So the default is --walls edge: only the
outer ring becomes 4 (the museum builds its own skin there anyway) and every
interior 2 stays a one-metre step, which is what it has always been in the
grid. --walls 4 converts them all; --walls keep changes only the threshold.

Usage:
  python tools/museum_heights_convert.py Trans_Pre Trans_Rotation      # check only
  python tools/museum_heights_convert.py --seq transformation           # every map of a sequence
  python tools/museum_heights_convert.py Trans_Pre --apply              # write (edge)
  python tools/museum_heights_convert.py Trans_Pre --apply --walls 4    # every wall value to 4
Exit code: the number of maps that could not be converted (parse or structure).
"""
from __future__ import annotations

import argparse
import io
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MAPS = REPO / "commons" / "maps"
SEQS = MAPS / "sequences"
TARGET_THRESHOLD = 4


def sequence_maps(seq_id: str) -> list[str]:
    """The maps of commons/maps/sequences/<seq>.json: {"sequences": {"<id>": {"maps": [...]}}}."""
    p = SEQS / f"{seq_id}.json"
    doc = json.loads(p.read_text(encoding="utf-8"))
    seqs = doc.get("sequences", doc)
    entry = None
    if isinstance(seqs, dict):
        entry = seqs.get(seq_id) or (next(iter(seqs.values())) if seqs else None)
    elif isinstance(seqs, list):
        entry = next((s for s in seqs if isinstance(s, dict) and s.get("id") == seq_id), seqs[0] if seqs else None)
    out: list[str] = []
    for m in (entry or {}).get("maps", []):
        name = m.get("name") if isinstance(m, dict) else m
        if isinstance(name, str) and name and name not in out:
            out.append(name)
    return out


def _find_block(text: str, key_pat: str, open_ch: str, close_ch: str, start: int = 0) -> tuple[int, int, int]:
    """(key_index, open_index, close_index) of the bracketed value after a key."""
    m = re.compile(key_pat).search(text, start)
    if not m:
        return -1, -1, -1
    i = text.index(open_ch, m.end())
    depth = 0
    j = i
    in_str = False
    while j < len(text):
        ch = text[j]
        if in_str:
            if ch == "\\":
                j += 1
            elif ch == '"':
                in_str = False
        elif ch == '"':
            in_str = True
        elif ch == open_ch:
            depth += 1
        elif ch == close_ch:
            depth -= 1
            if depth == 0:
                return m.start(), i, j
        j += 1
    return m.start(), i, -1


def convert_text(text: str, walls: str) -> tuple[str, dict]:
    """Return (new_text, report). Raises ValueError when the map cannot be read.

    walls: "edge" - the outer ring's wall values become 4, interior ones stay
           (they become steps under the new threshold: the grid walks their tops,
           so a plateau the rides lift you onto keeps its route);
           "4" / "w" - every wall value below 4 becomes that;
           "keep" - only the threshold changes."""
    doc = json.loads(text)
    mi = doc.get("map_info", {})
    mus = mi.get("museum") if isinstance(mi.get("museum"), dict) else {}
    threshold = int(float(mus.get("wall_height", 2))) if mus else 2
    dims = mi.get("dimensions", {}) if isinstance(mi.get("dimensions"), dict) else {}
    max_h = int(float(dims.get("max_height", 6)))
    struct = doc.get("layers", {}).get("structure", [])
    H = len(struct)
    W = max((len(r) for r in struct), default=0)
    report = {"threshold_before": threshold, "max_height": max_h, "changed": {}, "steps_kept": {}, "notes": []}

    # 1. the structure layer, cell by cell, textually - rows are the top-level
    #    lists of the structure block, so a cell's row/column is its position
    lk, lo, lc = _find_block(text, r'"layers"\s*:', "{", "}")
    if lo < 0:
        raise ValueError("no layers block")
    sk, so, sc = _find_block(text, r'"structure"\s*:', "[", "]", lo)
    if so < 0 or sc > lc:
        raise ValueError("no structure layer")
    body = text[so:sc + 1]
    pos = {"r": -1, "c": 0}

    def piece(mo: re.Match) -> str:
        tok = mo.group(0)
        if tok == "[":
            pos["r"] += 1          # the block's own "[" takes r to -1, the first row to 0
            pos["c"] = 0
            return tok
        s = mo.group(1).strip()
        r, c = pos["r"], pos["c"]
        pos["c"] += 1
        if not s.isdigit():
            return tok
        v = int(s)
        if v >= threshold and v < TARGET_THRESHOLD:
            on_edge = r <= 0 or r >= H - 1 or c == 0 or c >= W - 1
            wall_it = walls in ("4", "w") or (walls == "edge" and on_edge)
            if wall_it:
                report["changed"][s] = report["changed"].get(s, 0) + 1
                return '"%s"' % ("w" if walls == "w" else "4")
            report["steps_kept"][s] = report["steps_kept"].get(s, 0) + 1
            return tok
        if 1 < v < threshold:
            report["steps_kept"][s] = report["steps_kept"].get(s, 0) + 1
        return tok

    # the outer "[" of the structure block is at index 0 of body: rows start at -1
    pos["r"] = -2
    new_body = re.sub(r'\[|"([^"]*)"', piece, body)
    text = text[:so] + new_body + text[sc + 1:]

    # 2. museum.wall_height = 4, inside map_info, preserving the file's indentation
    mk, mo_, mc = _find_block(text, r'"map_info"\s*:', "{", "}")
    if mo_ < 0:
        raise ValueError("no map_info")
    seg = text[mo_:mc + 1]
    wh = re.compile(r'("wall_height"\s*:\s*)([0-9.]+)')
    mus_k, mus_o, mus_c = _find_block(seg, r'"museum"\s*:', "{", "}")
    if mus_o >= 0:
        inner = seg[mus_o:mus_c + 1]
        if wh.search(inner):
            inner2 = wh.sub(lambda m: m.group(1) + str(TARGET_THRESHOLD), inner, count=1)
        else:
            # the indentation of the first key inside museum (or of the closing brace + one unit)
            nl = "\r\n" if "\r\n" in text else "\n"
            after = inner[1:]
            m_ind = re.match(r'\s*\n([ \t]*)', after)
            ind = m_ind.group(1) if m_ind else ""
            inner2 = "{" + nl + ind + '"wall_height": %d,' % TARGET_THRESHOLD + after
        seg2 = seg[:mus_o] + inner2 + seg[mus_c + 1:]
    else:
        dk, do, dc = _find_block(seg, r'"dimensions"\s*:', "{", "}")
        if do < 0:
            raise ValueError("no dimensions in map_info")
        nl = "\r\n" if "\r\n" in text else "\n"
        line_start = seg.rfind("\n", 0, dk) + 1
        ind = seg[line_start:dk]
        unit = re.match(r'[ \t]*', seg[do + 1:].lstrip("\r\n")).group(0)
        unit = unit[len(ind):] if unit.startswith(ind) and len(unit) > len(ind) else (" " if ind.startswith(" ") else "\t")
        ins = "," + nl + ind + '"museum": {' + nl + ind + unit + '"wall_height": %d' % TARGET_THRESHOLD + nl + ind + "}"
        seg2 = seg[:dc + 1] + ins + seg[dc + 1:]
    text = text[:mo_] + seg2 + text[mc + 1:]
    report["threshold_after"] = TARGET_THRESHOLD
    json.loads(text)   # the result must still parse
    if max_h < 3:
        report["notes"].append("max_height %d: a 3 (two metres) would be clamped to one cube in the grid and one metre in the museum; raise max_height to 3 before writing a 3" % max_h)
    return text, report


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("maps", nargs="*", help="map names (commons/maps/<Name>/map_data.json)")
    ap.add_argument("--seq", help="every map of a sequence file (commons/maps/sequences/<seq>.json)")
    ap.add_argument("--walls", default="edge", choices=["edge", "4", "w", "keep"],
                    help="edge (default): the outer ring's wall values become 4 and interior ones stay as steps; "
                         "4 / w: every wall value below 4 becomes that; keep: only the threshold changes")
    ap.add_argument("--apply", action="store_true", help="write the files (default: report only)")
    a = ap.parse_args()
    names = list(a.maps)
    if a.seq:
        names += [n for n in sequence_maps(a.seq) if n not in names]
    if not names:
        ap.error("name at least one map, or --seq")
    failed = 0
    for name in names:
        path = MAPS / name / "map_data.json"
        if not path.exists():
            print(f"{name:28s} MISSING {path}")
            failed += 1
            continue
        raw = path.read_bytes()
        text = raw.decode("utf-8")
        try:
            new_text, rep = convert_text(text, a.walls)
        except ValueError as e:
            print(f"{name:28s} SKIP {e}")
            failed += 1
            continue
        wv = "w" if a.walls == "w" else "4"
        ch = ", ".join(f"{v}->{wv} x{n}" for v, n in sorted(rep["changed"].items())) or "no wall values below 4 to change"
        kept = ", ".join(f"{v} x{n}" for v, n in sorted(rep["steps_kept"].items()))
        already = rep["threshold_before"] >= TARGET_THRESHOLD
        state = "already at threshold %d" % rep["threshold_before"] if already else "threshold %d -> %d" % (rep["threshold_before"], TARGET_THRESHOLD)
        print(f"{name:28s} {state}; {ch}" + (f"; steps kept: {kept}" if kept else "") + f"; max_height {rep['max_height']}")
        for n in rep["notes"]:
            print(f"{'':28s}   note: {n}")
        if new_text == text:
            continue
        if a.apply:
            path.write_bytes(new_text.encode("utf-8"))
            print(f"{'':28s}   written")
        else:
            print(f"{'':28s}   (check only - add --apply to write)")
    return failed


if __name__ == "__main__":
    sys.exit(main())
