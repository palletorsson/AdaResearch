#!/usr/bin/env python3
"""compositor.py — sets the TEXT into the MAP (R-022).

NOC pairs explaining text with code; Ada pairs explaining text with MAPS — the
map is the code. This tool reads a chapter's text (authored overlay + built
tutorial + the maps' walked.md pages), extracts the order in which artifacts
ENTER THE PROSE, walks the sequence's maps for the order they ENTER THE BODY,
and reports the divergence. Every mismatch is a ruling waiting to happen:
re-lay the map (creator_walk) or rewrite the text. Report-only — proposals,
never auto-apply.

Usage:
  python tools/compositor.py --seq=primitives
  python tools/compositor.py --spine          # chapter order vs manuscript frame
"""
from __future__ import annotations

import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.path.join(os.path.dirname(REPO), "ada_encyclopedia")
SEQ_DIR = os.path.join(REPO, "commons", "maps", "sequences")
MAPS_DIR = os.path.join(REPO, "commons", "maps")
AUTHORED = os.path.join(REPO, "doc", "tutorial_authored")
TUTORIAL = os.path.join(ENC, "public", "tutorial")
FRAME = os.path.join(REPO, "doc", "manuscript_frame.json")
SPINE = os.path.join(REPO, "commons", "maps", "curriculum_spine.json")

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def load_json(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def seq_maps(seq: str) -> list:
    d = load_json(os.path.join(SEQ_DIR, f"{seq}.json"))
    maps = []
    for v in (d.get("sequences") or {}).values():
        for m in v.get("maps", []):
            name = m if isinstance(m, str) else m.get("name", "")
            if name:
                maps.append(name)
    return maps


def map_cast(mapname: str) -> list:
    """Artifacts in body-encounter order: row-major from the spawn side.
    v1 approximation of the walk; gaze_ride refines when precision matters."""
    p = os.path.join(MAPS_DIR, mapname, "map_data.json")
    if not os.path.exists(p):
        return []
    d = load_json(p)
    layers = d.get("layers", {})
    inter = layers.get("interactables", [])
    util = layers.get("utilities", [])
    # find spawn row to know which end the walk starts from
    spawn_row = None
    for r, row in enumerate(util):
        for cell in row:
            if str(cell).strip() in ("sp", "s"):
                spawn_row = r
    rows = list(enumerate(inter))
    if spawn_row is not None and spawn_row > len(inter) / 2:
        rows = rows[::-1]   # spawn at the south — walk north
    cast = []
    for _, row in rows:
        for cell in row:
            tk = str(cell).strip()
            if not tk or tk == " ":
                continue
            tk = tk.split(":")[0].split("#")[0].strip()
            if tk in ("cluster", ""):
                continue
            if tk not in cast:
                cast.append(tk)
    return cast


def gather_text(seq: str, maps: list) -> str:
    """All chapter prose, in reading order: authored overlay -> built tutorial
    pages -> the maps' walked.md pages (map order)."""
    chunks = []

    def strings_of(v):
        if isinstance(v, str):
            chunks.append(v)
        elif isinstance(v, dict):
            for x in v.values():
                strings_of(x)
        elif isinstance(v, list):
            for x in v:
                strings_of(x)

    for p in (os.path.join(AUTHORED, f"{seq}.json"),
              os.path.join(TUTORIAL, f"{seq}.json")):
        if os.path.exists(p):
            strings_of(load_json(p))
    for m in maps:
        wp = os.path.join(MAPS_DIR, m, "walked.md")
        if os.path.exists(wp):
            chunks.append(open(wp, encoding="utf-8").read())
    return "\n".join(chunks)


def mention_order(text: str, vocabulary: list) -> list:
    """First-mention index of each artifact in the prose (token or humanized)."""
    low = text.lower()
    hits = []
    for tk in vocabulary:
        names = {tk.lower(), tk.lower().replace("_", " ")}
        best = None
        for n in names:
            i = low.find(n)
            if i >= 0 and (best is None or i < best):
                best = i
        if best is not None:
            hits.append((best, tk))
    return [tk for _, tk in sorted(hits)]


def compose_seq(seq: str) -> int:
    maps = seq_maps(seq)
    if not maps:
        print(f"no maps for sequence '{seq}'")
        return 1
    body = []          # body-encounter order across the sequence's maps
    owner = {}         # artifact -> map
    for m in maps:
        for tk in map_cast(m):
            if tk not in owner:
                owner[tk] = m
                body.append(tk)
    text = gather_text(seq, maps)
    prose = mention_order(text, body)
    unmentioned = [tk for tk in body if tk not in prose]

    print(f"COMPOSITOR — {seq}: {len(maps)} maps, {len(body)} artifacts in body, "
          f"{len(prose)} enter the prose, {len(unmentioned)} silent")
    print()
    print(f"{'PROSE ORDER (the text teaches)':42s}  {'BODY ORDER (the maps walk)':42s}")
    width = max(len(prose), len(body))
    for i in range(width):
        a = prose[i] if i < len(prose) else ""
        b = body[i] if i < len(body) else ""
        mark = "  " if a == b else "≠ "
        print(f"{mark}{a:40s}  {b:40s}")
    print()
    # divergences: artifacts whose prose rank and body rank disagree by >1
    ranks_p = {tk: i for i, tk in enumerate(prose)}
    ranks_b = {tk: i for i, tk in enumerate(body)}
    diverging = [(tk, ranks_p[tk], ranks_b[tk]) for tk in prose
                 if abs(ranks_p[tk] - ranks_b[tk]) > 1]
    diverging.sort(key=lambda x: -abs(x[1] - x[2]))
    if diverging:
        print("DIVERGENCES (each one is a ruling: re-lay the map, or rewrite the text)")
        for tk, rp, rb in diverging:
            direction = "prose wants it EARLIER" if rp < rb else "prose holds it LATER"
            print(f"  {tk:34s} prose #{rp + 1:<3d} body #{rb + 1:<3d} in {owner.get(tk, '?'):26s} {direction}")
    else:
        print("NO DIVERGENCES — the text and the maps walk in step.")
    if unmentioned:
        print()
        print("SILENT IN THE PROSE (at depth — or missing from the text?)")
        for tk in unmentioned:
            print(f"  {tk:34s} in {owner.get(tk, '?')}")
    print()
    print("re-lay hint: python tools/creator_walk.py --seq=%s  (tray order = prose order)" % seq)
    return 0


def compose_spine() -> int:
    spine = [s["name"] for s in sorted(
        load_json(SPINE)["spine"]["sequences"], key=lambda s: s.get("order", 99))]
    frame = load_json(FRAME)
    frame_order = []

    def walk(v):
        if isinstance(v, str):
            if v in spine and v not in frame_order:
                frame_order.append(v)
        elif isinstance(v, dict):
            for x in v.values():
                walk(x)
        elif isinstance(v, list):
            for x in v:
                walk(x)
    walk(frame)
    print(f"{'SPINE (curriculum)':30s}  {'FRAME (the book tells)':30s}")
    for i in range(max(len(spine), len(frame_order))):
        a = spine[i] if i < len(spine) else ""
        b = frame_order[i] if i < len(frame_order) else ""
        mark = "  " if a == b else "≠ "
        print(f"{mark}{a:28s}  {b:28s}")
    return 0


def main() -> int:
    args = sys.argv[1:]
    seq = next((a.split("=", 1)[1] for a in args if a.startswith("--seq=")), None)
    if "--spine" in args:
        return compose_spine()
    if not seq:
        print(__doc__)
        return 1
    return compose_seq(seq)


if __name__ == "__main__":
    sys.exit(main())
