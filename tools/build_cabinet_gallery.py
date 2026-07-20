#!/usr/bin/env python3
"""
build_cabinet_gallery.py — the CABINET FAMILY gallery.

The interface ruling (Palle, 2026-07-19): "the object interface and text has
to be one very good looking interface/text body, like a sci info kiosk."
Every artifact that had readouts and pads floating in air becomes ONE
appliance in a shared grammar — back slab, flank, window, service column,
sign-band cap, plinth. This gallery is the family portrait: each cabinet in
three views (front / left three-quarter / right three-quarter) so the body
reads as a body, plus the anatomy note that says which parts it inherited.

Pulls straight from the Godot capture output (multi_shots/<artifact>/) and
publishes to the encyclopedia as /cabinet-gallery.

Usage: python tools/build_cabinet_gallery.py
"""
from __future__ import annotations
import json
import os
import shutil
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PUB = REPO.parent / "ada_encyclopedia" / "public" / "cabinet-gallery"
SHOTS = Path(os.environ.get("APPDATA", "")) / "Godot" / "app_userdata" / \
    "Ada Research Zero One" / "multi_shots"

VIEWS = [("front", "front"), ("left", "three-quarter left"), ("right", "three-quarter right")]

# order = propagation order (the way the grammar actually grew)
CABINETS = [
    {
        "artifact": "galton_board",
        "body": "squat vending machine",
        "no": 1,
        "sign": "GALTON BOARD / BINOMIAL CASCADE",
        "note": "The first body. Balls fall behind glass; the stats that used to "
                "hang beside the board now print on the service column's screen, "
                "the keypad sits on a wedge instead of hovering, and the title "
                "that floated overhead is baked into the sign band. Everything the "
                "artifact says, it says on itself.",
    },
    {
        "artifact": "monte_carlo_dartboard",
        "body": "tall street kiosk",
        "no": 2,
        "sign": "MONTE CARLO / AREA BY ACCIDENT",
        "note": "Same anatomy, taller proportion. The live estimate (pi, darts, "
                "inside/outside, error) rides the column glass while darts keep "
                "landing on the board — the readout is part of the machine that "
                "produces it.",
    },
    {
        "artifact": "distribution_comparator",
        "body": "wide console",
        "no": 3,
        "sign": "DISTRIBUTION COMPARATOR / ONE SOURCE - THREE RULES",
        "note": "The landscape variant. Three histograms share ONE window, and the "
                "column headers — once floating labels — are signage baked on the "
                "window's back wall in each column's colour. Flat, peaked, decaying: "
                "the artifact's whole argument in a single look.",
    },
    {
        "artifact": "coin_toss",
        "body": "pedestal station",
        "no": 4,
        "sign": "COIN TOSS / BERNOULLI TRIAL P = 0.5",
        "note": "The pedestal was already there, so the cabinet grew behind the "
                "tray: TALLY screen inset, result flash at the crown, and a deck "
                "that ties tray, keypad wedge and pedestal into one silhouette. "
                "The green felt landing pad stays loose on the floor — the coin "
                "still has somewhere to go.",
    },
    {
        "artifact": "dice_throw",
        "body": "table console (HORIZONTAL dialect)",
        "no": 5,
        "sign": "DICE THROW / DISCRETE UNIFORM DISTRIBUTION (inlaid flat in the rail)",
        "note": "The correction that made the family honest. This first got a "
                "standing backboard — and a kiosk behind a table is two objects "
                "pretending to be one. A table's interface plane is horizontal, so "
                "the integration had to be too: a broad working RAIL instead of a "
                "back slab, the readout sunk into the far rail at 14 degrees off "
                "the deck, the name INLAID FLAT to be read looking down, the keypad "
                "recessed FLUSH and pressed downward (frameless — the milled pocket "
                "IS the faceplate), maroon as edge banding, vents in the apron. "
                "Nothing rises more than a hand's width above the deck.",
    },
]

ANATOMY = ["back slab", "maroon flank", "window + glass", "service screen",
           "wedge-mounted keypad", "vent slats", "sign-band cap", "plinth / skirt"]


def main() -> int:
    PUB.mkdir(parents=True, exist_ok=True)
    entries: list[dict] = []
    missing: list[str] = []
    idx = 0
    for cab in CABINETS:
        art = cab["artifact"]
        for view, view_label in VIEWS:
            src = SHOTS / art / f"{view}.png"
            if not src.exists():
                missing.append(f"{art}/{view}.png")
                continue
            idx += 1
            dst_name = f"{art}__{view}.png"
            shutil.copyfile(src, PUB / dst_name)
            entries.append({
                "id": f"{art}__{view}",
                "index": idx,
                "image": f"/cabinet-gallery/{dst_name}",
                "label": f"{art} — {view_label}",
                "dna": {
                    "propagation": cab["no"],
                    "body_type": cab["body"],
                    "sign_band": cab["sign"],
                    "view": view,
                    "anatomy": ANATOMY,
                },
                "notes": cab["note"] if view == "front" else
                         f"{cab['body'].capitalize()}, {view_label} — the shared "
                         f"anatomy from another side: {', '.join(ANATOMY[:4])}.",
            })

    manifest = {
        "version": 1,
        "description": "The cabinet family: artifacts that used to scatter their "
                       "readouts, titles and keypads into the air, rebuilt as single "
                       "appliances in one shared grammar. Five body types so far — "
                       "squat vending machine, tall kiosk, wide console, pedestal "
                       "station, croupier table. Rebuild: python tools/build_cabinet_gallery.py",
        "entries": entries,
    }
    (PUB / "manifest.json").write_text(
        json.dumps(manifest, indent=1, ensure_ascii=False) + "\n",
        encoding="utf-8", newline="\n")
    print(f"cabinet-gallery: {len(entries)} views across {len(CABINETS)} cabinets")
    if missing:
        print("MISSING captures (recapture then rerun): " + ", ".join(missing))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
