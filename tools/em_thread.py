#!/usr/bin/env python3
"""THE RED THREAD — draft a line for every body from its @identity, then read the
chapter in order and say where the thread breaks.

    python tools/em_thread.py primitives            # report only
    python tools/em_thread.py primitives --draft    # write draft lines (by: draft) into the book where no text

Palle, 2026-08-19: "extract a good line for each artifact from header or md … a
kind of red thread running through the topics in the short speak. where it is
not sequential something is off."

The line: the first sentence of the script's `# truth:` (cut at the first " — "
or "." past ~90 chars), else the first clause of `# essence:`, else the
registry description. Provenance `draft` — grey in /lines, the hand overwrites.

The thread: each line's TOPIC TERMS (point, line, origin, coordinate, trace,
grid, triangle, …) against its neighbours'. A line sharing no term with the
line before it AND none with the line after it is a BREAK — a body that does
not belong where it stands, or a pearl out of order. Printed as the page, with
the breaks marked; exit 1 when any.
"""
from __future__ import annotations
import json, re, sys, glob
from pathlib import Path
REPO = Path(__file__).resolve().parent.parent
BOOK = REPO / "commons" / "data" / "book"
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

# terms that carry the chapter's argument; variants collapse to one stem
TOPIC = {
    "point": "point", "points": "point", "dot": "point", "dots": "point", "position": "point", "mark": "point", "marks": "point", "zero": "point", "spot": "point",
    "line": "line", "lines": "line", "laser": "line", "lasers": "line", "ray": "line", "edge": "line", "edges": "line", "stroke": "line", "trajectory": "line", "trajectories": "line", "measure": "line", "measures": "line", "measurement": "line", "straight": "line", "parallel": "line",
    "origin": "origin", "coordinate": "coordinate", "coordinates": "coordinate", "axis": "coordinate", "axes": "coordinate", "frame": "coordinate", "vector": "coordinate", "space": "space", "void": "space", "3d": "space",
    "trace": "trace", "traces": "trace", "writing": "trace", "written": "trace", "draw": "trace", "drawn": "trace", "drawing": "trace", "ink": "trace", "memory": "trace", "past": "trace", "retention": "trace", "pad": "trace",
    "time": "time", "frames": "time", "clock": "time", "counter": "time", "running": "time",
    "grid": "grid", "lattice": "grid", "snap": "grid", "quantization": "grid", "cell": "grid", "cells": "grid", "room": "grid", "rooms": "grid",
    "triangle": "triangle", "triangles": "triangle", "angle": "triangle", "angles": "triangle", "quad": "triangle", "face": "triangle", "faces": "triangle", "fold": "triangle", "folded": "triangle", "strip": "triangle", "pythagoras": "triangle", "pythagorean": "triangle", "right": "triangle",
    "cube": "solid", "cubes": "solid", "polyhedron": "solid", "polyhedra": "solid", "pyramid": "solid", "solid": "solid", "sphere": "solid", "spheres": "solid", "net": "solid", "nets": "solid", "trihedron": "solid", "ball": "solid",
    "perspective": "perspective", "vanishing": "perspective", "horizon": "perspective", "window": "perspective", "portal": "perspective", "portals": "perspective", "achilles": "perspective", "tortoise": "perspective", "infinite": "perspective", "infinity": "perspective", "endless": "perspective",
    "ignorance": "ignorance", "melancholia": "melancholia", "melancholy": "melancholia", "dürer": "melancholia", "durer": "melancholia", "melencolia": "melancholia",
    "hand": "hand", "hands": "hand", "grab": "hand", "hold": "hand", "held": "hand", "pick": "hand", "touch": "hand", "grabbable": "hand",
    "catalyst": "catalyst", "pedestal": "catalyst", "vent": "catalyst", "becoming": "catalyst", "target": "catalyst",
    "light": "light", "lightrod": "light", "screen": "light", "dark": "light", "glow": "light",
    "octahedron": "solid", "tetrahedron": "solid", "torus": "solid", "capsule": "solid", "cylinder": "solid", "prism": "solid", "star": "solid", "diamond": "solid", "diamonds": "solid", "platonic": "solid", "lshape": "solid", "l": "solid", "rock": "solid", "roughrock": "solid", "hole": "solid", "cones": "solid", "polygon": "solid", "vertices": "solid", "mesh": "solid", "shape": "solid", "shapes": "solid", "symmetry": "solid", "dual": "solid", "subdividing": "solid", "resolution": "solid", "proportion": "solid",
    "library": "ignorance", "rack": "ignorance", "taxonomy": "ignorance", "organizing": "ignorance", "words": "ignorance", "tutorial": "ignorance", "code": "ignorance",
    "game": "catalyst", "level": "catalyst", "path": "catalyst", "watchdog": "catalyst", "tentacle": "catalyst", "fetched": "catalyst", "cross": "catalyst",
    "scale": "line", "standard": "line", "human": "line", "modulor": "line", "map": "line", "territory": "line", "flattened": "line",
}


def _scene_index() -> dict:
    out = {}
    for f in glob.glob(str(REPO / "commons" / "artifacts" / "registry" / "*.json")):
        try:
            d = json.loads(Path(f).read_text(encoding="utf-8"))
        except Exception:
            continue
        a = d.get("artifacts") if "artifacts" in d else d
        for k, v in a.items():
            if isinstance(v, dict):
                out.setdefault(k, (str(v.get("scene_path") or v.get("scene") or ""), str(v.get("description") or "")))
    return out


def _first_sentence(s: str, soft: int = 90, hard: int = 140) -> str:
    s = " ".join(s.split())
    if len(s) <= soft:
        return s.rstrip(".")
    best = None
    for sep in (" — ", ". ", "; ", ": ", ", "):
        i = s.find(sep, soft // 2)
        if i != -1 and (best is None or i < best):
            best = i
    if best is not None and best <= hard:
        return s[:best].rstrip(" .,;:—")
    return s[:hard].rsplit(" ", 1)[0].rstrip(" .,;:—") + " …"


def draft_line(token: str, scenes: dict) -> tuple:
    sp, desc = scenes.get(token, ("", ""))
    gd = REPO / sp.replace("res://", "").replace(".tscn", ".gd") if sp else None
    truth = ess = ""
    if gd and gd.exists():
        head = gd.read_text(encoding="utf-8", errors="replace")[:6000]
        m = re.search(r"^#\s*truth:\s*(.+)$", head, re.M); truth = m.group(1).strip() if m else ""
        m = re.search(r"^#\s*essence:\s*(.+)$", head, re.M); ess = m.group(1).strip() if m else ""
    if truth:
        return _first_sentence(truth), "truth"
    if ess:
        return _first_sentence(ess), "essence"
    if desc:
        return _first_sentence(desc), "description"
    return "", ""


def terms(text: str) -> set:
    out = set()
    for w in re.findall(r"[A-Za-zÀ-ÿ0-9']+", text.lower()):
        w = w.strip("'")
        if w in TOPIC:
            out.add(TOPIC[w])
    return out


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__); return 2
    chapter = sys.argv[1]
    do_draft = "--draft" in sys.argv
    bp = BOOK / f"{chapter}.json"
    if not bp.exists():
        print(f"no book for {chapter} — python tools/book.py migrate --chapter {chapter}"); return 2
    book = json.loads(bp.read_text(encoding="utf-8"))
    scenes = _scene_index()
    drafted = 0
    rows = []            # (n, pearl, token, text, by, source)
    n = 0
    for p in book.get("pearls", []):
        if p.get("drop"):
            continue                    # a dropped pearl is not in the string
        for ln in p.get("lines", []):
            tok = ln.get("token")
            if not tok:
                continue
            n += 1
            text = str(ln.get("text", "")).strip(); by = str(ln.get("by", "")); src = ""
            if not text or by == "draft":
                d, src = draft_line(tok, scenes)
                if d:
                    if do_draft and text != d:
                        ln["text"] = d; ln["by"] = "draft"; drafted += 1
                    text, by = d, "draft"
            rows.append((n, p.get("pearl", ""), tok, text, by, src))
    if do_draft:
        bp.write_text(json.dumps(book, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    T = [terms(r[3] + " " + r[2].replace("_", " ")) for r in rows]
    breaks = []
    print(f"{chapter.upper()} — the thread ({len(rows)} lines" + (f", {drafted} drafted" if do_draft else "") + ")")
    last_pearl = None
    for i, r in enumerate(rows):
        prev_ok = i == 0 or bool(T[i] & T[i - 1])
        next_ok = i == len(rows) - 1 or bool(T[i] & T[i + 1])
        brk = not prev_ok and not next_ok
        if brk:
            breaks.append(r)
        if r[1] != last_pearl:
            print(f"\n  · {r[1]}")
            last_pearl = r[1]
        mark = " ✗" if brk else ("  " if prev_ok else " ·")
        tag = "" if r[4] == "hand" else f"  [{r[4]}{'/' + r[5] if r[5] else ''}]"
        print(f"  {mark} {r[0]:02d} {r[2]:28s} {r[3][:96]}{tag}")
        if not r[3]:
            print("       (no line)")
    print(f"\n  {len(breaks)} break(s) — a line sharing no topic with the line before or after it:")
    for r in breaks:
        print(f"    {r[0]:02d} {r[2]} ({r[1]}) — terms {sorted(terms(r[3] + ' ' + r[2].replace('_', ' '))) or 'none'}")
    print("  ✗ break · no topic shared with the line before (the thread turns) · ' ' continues")
    return 1 if breaks else 0


if __name__ == "__main__":
    raise SystemExit(main())
