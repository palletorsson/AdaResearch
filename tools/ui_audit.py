#!/usr/bin/env python3
"""ui_audit.py — Interface Overhaul tracker.

Scans every .gd artifact/scene script for interface signatures (sliders,
buttons, dials, readouts, hand-rolled boards) and classifies each by:

  - TYPE         which overhaul recipe it needs (see TAXONOMY below)
  - CANONICAL    already on a canonical system? (control_panel / control_console
                 / ForcesRackPanel / RackTemplates) or hand-rolled
  - STATUS       done / converged / todo

The goal: turn ~140 scattered interfaces into one drainable queue. Run at the
start of every overhaul session to see what's left.

Usage:
    python tools/ui_audit.py                  # full table to stdout
    python tools/ui_audit.py --todo           # only the not-yet-migrated
    python tools/ui_audit.py --type workbench # filter by recipe type
    python tools/ui_audit.py --json out.json  # machine-readable dump
    python tools/ui_audit.py --summary        # counts only

Recipe TYPES (the "fit their artifact" taxonomy):
    workbench  sliders + readout + a visualization   -> console + board + viz host
    machine    mostly buttons / presets / capture     -> board + button rows
    console    game/control surface, keep character    -> console + board, custom
    readout    Label3D display only, no controls       -> board readout (no console)
    rack       algorithms rack panel (Forces/Rack)     -> converge underneath
"""
from __future__ import annotations
import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SCAN_ROOTS = ["commons/artifacts", "commons/ui", "algorithms"]

# Signatures ---------------------------------------------------------------
SLIDER_RE = re.compile(r"slider_smooth|slider_horizontal|slider_axis|add_slider")
BUTTON_RE = re.compile(r"push_button|add_button|\bbutton_pressed\b")
DIAL_RE = re.compile(r"dial_smooth|add_dial|joystick_smooth|add_joystick")
READOUT_RE = re.compile(r"Label3D\.new|add_readout|_readout|_build_readout")
BOARD_RE = re.compile(r"_build_plate|_build_panel|_build_board|_build_console|"
                      r"_plate_root|_build_controls|PanelBacking")

# Canonical rack bases whose dependents are NOT ad-hoc.
#  - ForcesRackPanel: converged onto ControlPanel (its files render the canonical board).
#  - RackTemplates: a recognized canonical SIBLING — the eurorack module builder. It is
#    NOT rebuilt on ControlPanel (that would destroy the eurorack aesthetic); it already
#    uses the shared interactables (slider_smooth/dial_smooth/push_button). Its dependents
#    are on a canonical system. (Open quality task: slider_h still loads the old
#    slider_horizontal + controls are scaled — harmless for desktop-pointer racks, a
#    VR-grab concern only; modernise slider_h → slider_smooth when those racks go VR.)
#  - VectorSceneBase: the vector-bench stage framework (grabbable arrows + bezel-
#    housed readouts). Recognized sibling; its slider factory now uses the canonical
#    slider_smooth. Its subclasses (the vector benches) are on a canonical framework.
#  - ShaderRackPanel: converged into an adapter over ControlPanel (like ForcesRackPanel);
#    the book_of_shaders demos inherit the canonical board.
CONVERGED_BASES = {"ForcesRackPanel", "forces_rack_panel", "RackTemplates", "VectorSceneBase", "ShaderRackPanel"}

# Canonical-system markers
CANON_CONSOLE = re.compile(r"control_console\.gd|ControlConsole|control_console\.tscn")
CANON_PANEL = re.compile(r"control_panel\.tscn|control_panel\.gd|\bControlPanel\b")
CANON_FORCES = re.compile(r"ForcesRackPanel|forces_rack_panel")
CANON_RACK = re.compile(r"RackTemplates")


def count(pat: re.Pattern, text: str) -> int:
    return len(pat.findall(text))


def classify(path: Path, text: str) -> dict | None:
    has_slider = bool(SLIDER_RE.search(text))
    has_button = bool(BUTTON_RE.search(text))
    has_dial = bool(DIAL_RE.search(text))
    has_readout = bool(READOUT_RE.search(text))
    has_board = bool(BOARD_RE.search(text))
    if not (has_slider or has_button or has_dial or has_readout or has_board):
        return None  # no interface at all

    on_console = bool(CANON_CONSOLE.search(text))
    on_panel = bool(CANON_PANEL.search(text))
    on_forces = bool(CANON_FORCES.search(text))
    on_rack = bool(CANON_RACK.search(text))
    canonical = on_console or on_panel
    rack_system = on_forces or on_rack

    # Type (recipe) — most specific wins
    if on_forces or on_rack:
        rtype = "rack"
    elif has_slider and (has_readout or has_board) and not has_button:
        rtype = "workbench"
    elif has_button and not has_slider:
        rtype = "machine"
    elif has_slider and has_button:
        rtype = "console"
    elif has_readout and not (has_slider or has_button or has_dial):
        rtype = "readout"
    else:
        rtype = "workbench"

    # Status
    on_converged_base = any(b in text for b in CONVERGED_BASES)
    if canonical:
        status = "done"
    elif on_converged_base:
        # on a canonical base/sibling (ForcesRackPanel / RackTemplates) — not ad-hoc.
        status = "converged"
    else:
        status = "todo"

    return {
        "path": str(path.relative_to(REPO)).replace("\\", "/"),
        "type": rtype,
        "canonical": canonical,
        "system": ("console" if on_console else "panel" if on_panel
                   else "forces" if on_forces else "rack" if on_rack else "hand"),
        "status": status,
        "sliders": count(SLIDER_RE, text),
        "buttons": count(BUTTON_RE, text),
        "dials": count(DIAL_RE, text),
        "readouts": count(READOUT_RE, text),
        "board": has_board,
    }


def scan() -> list[dict]:
    rows = []
    for root in SCAN_ROOTS:
        base = REPO / root
        if not base.exists():
            continue
        for gd in base.rglob("*.gd"):
            if ".claude" in gd.parts:
                continue
            try:
                text = gd.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue
            row = classify(gd, text)
            if row:
                rows.append(row)
    rows.sort(key=lambda r: (r["status"] != "todo", r["type"], r["path"]))
    return rows


def print_table(rows: list[dict]) -> None:
    hdr = f"{'STATUS':<6} {'TYPE':<9} {'SYSTEM':<8} {'s/b/d/r':<10} PATH"
    print(hdr)
    print("-" * len(hdr))
    for r in rows:
        sbdr = f"{r['sliders']}/{r['buttons']}/{r['dials']}/{r['readouts']}"
        print(f"{r['status']:<6} {r['type']:<9} {r['system']:<8} {sbdr:<10} {r['path']}")


def print_summary(rows: list[dict]) -> None:
    by_type: dict[str, dict[str, int]] = {}
    for r in rows:
        d = by_type.setdefault(r["type"], {})
        d[r["status"]] = d.get(r["status"], 0) + 1
    print(f"{'TYPE':<10} {'DONE':>5} {'CONV':>5} {'TODO':>5} {'TOTAL':>6}")
    print("-" * 34)
    tot = {"done": 0, "converged": 0, "todo": 0}
    for t in sorted(by_type):
        d = by_type[t]
        done, conv, todo = d.get("done", 0), d.get("converged", 0), d.get("todo", 0)
        tot["done"] += done
        tot["converged"] += conv
        tot["todo"] += todo
        print(f"{t:<10} {done:>5} {conv:>5} {todo:>5} {done + conv + todo:>6}")
    print("-" * 34)
    tt = tot["done"] + tot["converged"] + tot["todo"]
    print(f"{'ALL':<10} {tot['done']:>5} {tot['converged']:>5} {tot['todo']:>5} {tt:>6}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Interface overhaul audit / tracker")
    ap.add_argument("--todo", action="store_true", help="only not-yet-migrated")
    ap.add_argument("--type", help="filter by recipe type")
    ap.add_argument("--summary", action="store_true", help="counts only")
    ap.add_argument("--json", metavar="FILE", help="write machine-readable dump")
    args = ap.parse_args()

    rows = scan()
    if args.type:
        rows = [r for r in rows if r["type"] == args.type]
    if args.todo:
        rows = [r for r in rows if r["status"] == "todo"]

    if args.json:
        Path(args.json).write_text(json.dumps(rows, indent=2), encoding="utf-8")
        print(f"wrote {len(rows)} rows -> {args.json}")
        return 0

    if args.summary:
        print_summary(rows)
    else:
        print_table(rows)
        print()
        print_summary(rows)
    return 0


if __name__ == "__main__":
    sys.exit(main())
