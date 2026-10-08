#!/usr/bin/env python3
"""em_shots.py — three verified views of a museum hall, one command.

    python tools/em_shots.py --hall "primitives|point one"
    python tools/em_shots.py --hall "primitives|point one" --view iso
    python tools/em_shots.py --chapter primitives
    python tools/em_shots.py --list

Palle, 2026-09-19: "can you optimize for you to take screen shot to verify,
top down, iso, fpv?"  Verifying a hall used to mean hand-tuning --em-shot-*
per hall and GUESSING a framing height.  This asks the hall's own record what
it is, drives the museum once per view, and lands three PNGs with a sidecar
each naming the camera that took them.

WHAT THIS REFUSES TO GUESS
  * hall geometry.  ada_run/em_layout_walk.json is the museum's OWN record,
    written by endless_museum.gd as each hall is built.  A hall nobody has
    walked simply has no row, and this refuses it by name rather than
    re-deriving w/h/span in Python.  tools/long_museum.py re-derived them once
    and reported a strip 16% too long with its own check green.
  * which chapter the museum will open at.  ada_run/em_control.json can carry
    a `resume_eye` (or `travel`) that OUTRANKS --em-chapter — see
    endless_museum.gd:_start_at_chapter.  This checks before it shoots, and
    reads back out of the run log which voice actually won.

WHAT COUNTS AS SUCCESS
  The PNG existing and being non-trivial.  NEVER the exit code: a museum run
  exits 3221225477 (0xC0000005) at renderer teardown AFTER writing its files.

  THAT GATE WAS TOO LOW AND IT PASSED TWO PICTURES THAT ARE NOT EVIDENCE.
  2026-09-19, three skeptics took one view each and one of three survived:

    top  SURVIVED, with a framing defect: a deep hall is portrait-shaped and
         the frame is 3:2 landscape, so the hall fills 94.3% of the frame's
         height and 26-46% of its width.  Half to three quarters of the pixels
         are star field.
    iso  REFUTED, and inherently: an axonometric of a building made of rooms
         looks along one ray through every interior partition, so part of the
         hall stands behind a wall from any corner and moving the camera is not
         the fix.  ABSENCE IN AN ISO FRAME IS NOT EVIDENCE OF ABSENCE.
         HOW MUCH IS NOT A CONSTANT AND IS NO LONGER KEPT HERE.  This file used
         to carry "roughly HALF, other corners 49/54/58%" as a stored figure,
         and read it out beside an engine measurement of 87% on the same hall —
         two numbers for one fact in one sentence, which teaches a reader to
         trust neither.  The figure now comes off the sidecar's own coverage
         block, per frame, or the tool says it is not available.
    fpv  REFUTED: 9 of the 16 artifacts the museum placed in primitives|point
         one are outside the frustum before occlusion is counted at all, and 5
         stand BEHIND the camera — including `origin` at world (0,0,0), the
         namesake of the hall.

  So a PNG that is merely non-blank is no longer "landed".  Every view now
  declares what it cannot see (see COVERAGE below), and a view that holds fewer
  than half the hall's works is REFUSED by the same naming as a wrong hall.

COVERAGE — MEASURED HERE, NOT TAKEN ON TRUST
  em_layout_walk.json's row carries every body the museum placed, with world
  positions, and the sidecar carries the camera as it was read back off the live
  Camera3D.  Projecting one through the other says exactly which works the frame
  holds.  Calibrated against both skeptics: this arithmetic returns 5 bodies
  behind the fpv camera and 94.3% frame fill down / 45.7% across for the top
  view of primitives|point one — the same numbers they measured independently.
  Occlusion is NOT measured here: re-deriving the hall's geometry in Python is
  how tools/long_museum.py produced a strip 16% too long with its own check
  green.  When endless_museum.gd writes a `coverage` block the tool reads it,
  says so, and compares the two counts; when it does not, the tool says the
  occlusion is undeclared rather than implying the frame is complete.

THE GUARD COMPARED TOTALS, SO IT COULD NOT FAIL (fixed 2026-09-19)
  Both sides counted 65 bodies in primitives|point one and the guard called that
  agreement.  They were different sets of 65.  endless_museum.gd:_shot_bodies
  drops kind "plinth", so the ledger row's comparable count is 63; and the
  engine names `weapon_cabinet` twice under `missing`, a token the ledger row
  has no record of at all.  Two bodies on each side, cancelling, and a guard
  that only ever subtracted one total from another saw nothing.

  It now compares SETS and HELD counts: the inventory rule is read out of
  _shot_bodies at run time rather than copied here, every token the engine names
  is looked up in the ledger row, the symmetric difference is printed by name,
  and a view whose two inventories are not the same inventory is DISPUTED and
  keeps the .REJECTED name.

  The same pass killed the fault that mattered most: the sidecar's own prose
  contradicted its own numbers.  "Of the 16 artifacts the museum placed, this
  frame holds 16" sat in the same file as an engine `missing` list naming 8 of
  those artifacts as hidden behind something solid — because the sentence was
  composed from this tool's frustum-only projection and the numbers beside it
  came from the engine's occlusion ray.  A sentence composed separately from the
  numbers it summarises will drift, and the sentence is the part a human reads.
  Every count in the blind sentence now carries the side that measured it.
"""
from __future__ import annotations

import argparse
import collections
import html
import json
import math
import os
import re
import shutil
import struct
import subprocess
import sys
import time

# ── where things live ────────────────────────────────────────────────────────
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LAYOUT = os.path.join(REPO, "ada_run", "em_layout_walk.json")
PLAN = os.path.join(REPO, "commons", "data", "museum", "em_plan.json")
CONTROL = os.path.join(REPO, "ada_run", "em_control.json")
MUSEUM_GD = os.path.join(REPO, "commons", "scenes", "endless_museum.gd")
WATCHDOG = os.path.join(REPO, "tools", "godot_watchdog.py")
OUT_ROOT = os.path.join(REPO, "ada_run", "em_shots")
SCENE = "res://commons/scenes/endless_museum.tscn"

# user:// is Roaming, NOT Local.  Measured: %APPDATA%/Godot/app_userdata/<name>
USER_DIR = os.path.join(
    os.environ.get("APPDATA", ""), "Godot", "app_userdata", "Ada Research Zero One"
)
GODOT_DEFAULT = os.environ.get(
    "GODOT_EXE", r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"
)

VIEWS = ("top", "iso", "fpv")
MIN_PNG_BYTES = 20_000          # a real 1800x1200 render is >100 KB; a black frame ~10 KB
EYE = 1.62                      # the camera sits this far above --em-shot-y

# the proof-shot lens, from endless_museum.gd:_take_proof_shot — 70 across,
# KEEP_WIDTH, on a 1800x1200 (3:2) viewport.  Coverage at height H:
#   across  2*tan(35 deg)*H       = 1.4004*H
#   down    2*atan(tan35 * 2/3)   = 50.06 deg -> 0.9336*H
FOV_ACROSS = 1.4004
FOV_DOWN = 0.9336


# ── the hall's own record ────────────────────────────────────────────────────
def load_json(path: str):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def norm(s: str) -> str:
    """Fold a hall name so 'Point One', 'point_one' and 'point one' are one thing."""
    return re.sub(r"[\s_\-]+", " ", str(s or "").strip().lower())


def slug(chapter: str, pearl: str) -> str:
    return "%s__%s" % (re.sub(r"[^a-z0-9]+", "_", norm(chapter)),
                       re.sub(r"[^a-z0-9]+", "_", norm(pearl)))


# THE LEDGER MOVES UNDER YOU. A shot run REWRITES em_layout_walk.json for the
# hall it builds — measured 2026-09-19, built_at went 17:50 -> 18:07 across a
# single run of this tool — so anything read back after the run is being
# compared against the run's own output. Every geometry fact this tool asserts
# comes out of SNAP, taken once before the first Godot boot, and the fingerprint
# is carried into every sidecar so a reader can tell which file it was.
SNAP = {"taken": False}


def _digest(path: str) -> str:
    import hashlib
    try:
        with open(path, "rb") as f:
            return hashlib.sha1(f.read()).hexdigest()[:12]
    except OSError:
        return ""


def load_halls() -> dict:
    """Recorded halls, keyed exactly as em_layout_walk.json keys them.

    Reads the file ONCE and freezes it in SNAP: this is the before-picture that
    every cross-check is made against."""
    d = load_json(LAYOUT)
    if not isinstance(d, dict) or not isinstance(d.get("halls"), dict):
        die("ada_run/em_layout_walk.json is missing or unreadable — nothing can be shot.\n"
            "  It is written by endless_museum.gd as each hall is built. Walk the museum once.")
    SNAP.update({
        "taken": True,
        "file": os.path.relpath(LAYOUT, REPO),
        "sha1_12": _digest(LAYOUT),
        "mtime": time.strftime("%Y-%m-%dT%H:%M:%S",
                               time.localtime(os.path.getmtime(LAYOUT)))
        if os.path.isfile(LAYOUT) else "",
        "taken_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "halls": len(d["halls"]),
    })
    return d["halls"]


def ledger_moved(keys) -> dict:
    """Re-read the ledger and say whether the run rewrote the rows we shot from.

    This is REPORTING, never a source: nothing downstream is allowed to compare
    against the after-picture, because a run that rewrote the row would then be
    checking itself."""
    d = load_json(LAYOUT) or {}
    halls = d.get("halls", {}) if isinstance(d, dict) else {}
    out = {"sha1_12": _digest(LAYOUT), "rows": {}}
    out["file_changed"] = bool(SNAP.get("sha1_12")) and out["sha1_12"] != SNAP["sha1_12"]
    for k in keys:
        row = halls.get(k) or {}
        out["rows"][k] = {"built_at_now": row.get("built_at")}
    return out


def load_plan_index() -> dict:
    """{norm(chapter)|norm(pearl): plan row} — so a refusal can say whether the
    hall is PLANNED but unbuilt, or not in the museum at all."""
    d = load_json(PLAN)
    out = {}
    if isinstance(d, dict):
        for i, row in enumerate(d.get("plans", []) or []):
            if not isinstance(row, dict):
                continue
            key = "%s|%s" % (norm(row.get("sequence", "")), norm(row.get("pearl", "")))
            row = dict(row)
            row["_plan_index"] = i
            out.setdefault(key, row)
    return out


def resolve_hall(halls: dict, want: str) -> tuple:
    """(key, row) for a hall the museum has actually built, or (None, reason).

    EVERY WAY OF NAMING IT IS GATHERED BEFORE ANYTHING IS PICKED. This returned
    the first match by key, then by map, then by pearl — so "biome ladder
    randomness", which is BOTH a map name under `primitives` and a pearl under
    `randomness`, quietly resolved to primitives and shot the wrong hall
    without a word. A tool whose whole job is refusing to photograph the wrong
    room must not have that bug in its own front door."""
    w = norm(want).replace("/", "|")
    hits = []
    for k, row in halls.items():
        if (norm(k).replace("/", "|") == w
                or norm(row.get("map", "")) == w
                or norm(row.get("pearl", "")) == w):
            hits.append(k)
    if len(hits) == 1:
        return hits[0], halls[hits[0]]
    if len(hits) > 1:
        # an exact chapter|pearl key is unambiguous by construction; only a bare
        # pearl or map name can collide
        exact = [k for k in hits if norm(k).replace("/", "|") == w]
        if len(exact) == 1:
            return exact[0], halls[exact[0]]
        lines = ["REFUSED: '%s' names %d recorded halls — say which chapter:"
                 % (want, len(hits))]
        for k in sorted(hits):
            lines.append("      %s  (map %s)" % (k, halls[k].get("map", "")))
        return None, "\n".join(lines)
    return None, None


def refusal_text(want: str, halls: dict) -> str:
    """Name what it would take to get a row, rather than shrugging."""
    w = norm(want).replace("/", "|")
    plan = load_plan_index()
    lines = ["REFUSED: no engine row for '%s' in ada_run/em_layout_walk.json." % want,
             "  That file is the museum's OWN record, written as each hall is built."
             "  %d of the plan's %d halls have a row." % (len(halls), len(plan) or 172)]
    row = plan.get(w)
    if row is None:  # try by map name / pearl
        for k, r in plan.items():
            if norm(r.get("map", "")) == w or norm(r.get("pearl", "")) == w:
                row, w = r, k
                break
    if row is not None:
        chap, pearl, mp = row.get("sequence", ""), row.get("pearl", ""), row.get("map", "")
        lines.append("  It IS planned (row %d of commons/data/museum/em_plan.json: chapter %s, pearl %s, map %s)"
                     % (row.get("_plan_index", -1), chap, pearl, mp))
        lines.append("  — the museum has simply never built it. Build it once, then shoot:")
        lines.append('      "%s" --path . --xr-mode off --no-window %s -- \\'
                     % (GODOT_DEFAULT, SCENE))
        lines.append("        --em-chapter=%s --em-map=%s --em-segments=1 --em-no-costume \\"
                     % (chap, mp))
        lines.append("        --em-shot=user://em_shots/_warm.png")
        lines.append("    (that run writes the hall's row; then re-run this tool)")
    else:
        near = sorted(halls, key=lambda k: -_overlap(w, norm(k)))[:5]
        lines.append("  It is not in commons/data/museum/em_plan.json either. Nearest recorded halls:")
        for k in near:
            lines.append("      %s" % k)
        lines.append("  Run --list for the full set.")
    return "\n".join(lines)


def plan_orphan(hall_key: str) -> str:
    """"" unless this hall's row has outlived the plan that made it.

    AN ENGINE ROW IS A MEMORY, NOT A PROMISE. em_layout_walk.json keeps a row
    for every hall the museum has EVER built; em_plan.json is the deal as it
    stands today. Measured 2026-09-19: 5 of 58 recorded halls are in the first
    and not the second (primitives|biome ladder randomness and three siblings,
    array_tutorial|motif). Asking for one of those, --em-map names a pearl the
    chapter no longer has, the museum opens at the chapter's FIRST pearl, and
    every downstream signal is green — the run exits 0, the PNG is 2.4 MB, the
    sidecar is written — while the photograph is of another room."""
    plan = load_plan_index()
    if not plan:
        return ""
    return ("" if norm(hall_key).replace("/", "|") in plan else
            "'%s' has an engine row but is NOT in commons/data/museum/em_plan.json. --em-map will name "
            "a pearl the chapter no longer deals, and the museum will open at the chapter's "
            "FIRST pearl instead. Expect WRONG HALL." % hall_key)


def _overlap(a: str, b: str) -> int:
    aw, bw = set(a.split()), set(b.split())
    return len(aw & bw)


# ── the control file, which can outrank the flag ─────────────────────────────
def control_check() -> dict:
    """What ada_run/em_control.json will do to a --em-chapter run.

    endless_museum.gd:_start_at_chapter — if the control carries `resume_eye`
    (non-null) or `travel` == 1, its first_chapter/first_map OVERWRITE whatever
    --em-chapter set, and the run photographs a different hall."""
    d = load_json(CONTROL)
    out = {"ok": True, "path": CONTROL, "notes": [], "blocking": []}
    if d is None:
        out["notes"].append("no ada_run/em_control.json — the flag speaks alone")
        return out
    if not isinstance(d, dict):
        out["notes"].append("ada_run/em_control.json is not an object — ignored by the museum")
        return out
    if d.get("resume_eye") is not None:
        out["ok"] = False
        out["blocking"].append(
            "resume_eye is SET (%s) — it OUTRANKS --em-chapter. The run would open at "
            "chapter '%s' / map '%s', not the hall asked for."
            % (json.dumps(d.get("resume_eye")), d.get("first_chapter", ""), d.get("first_map", "")))
    if int(d.get("travel", 0) or 0) == 1:
        out["ok"] = False
        out["blocking"].append(
            "travel == 1 — the spine strip's jump ranks with the resume and OUTRANKS "
            "--em-chapter (it is spent on the next boot, which would be this one).")
    if int(d.get("dollhouse", 0) or 0) == 1:
        out["notes"].append("dollhouse == 1 — a proof shot stands back up automatically "
                            "(endless_museum.gd:2718), so this does not block")
    if int(round(float(d.get("grid_pack", 0) or 0))) == 1:
        out["notes"].append("grid_pack == 1 — halls are TRANSPLANTED from their grid maps. "
                            "The control speaks for the modes ALWAYS; the picture will be "
                            "the packed hall, not the dealt one.")
    if not out["notes"] and out["ok"]:
        out["notes"].append("clean: no resume_eye, no travel — --em-chapter wins")
    return out


# ── the view flag ────────────────────────────────────────────────────────────
def museum_has_view_flag() -> bool:
    try:
        with open(MUSEUM_GD, "r", encoding="utf-8", errors="replace") as f:
            return "--em-shot-view" in f.read()
    except OSError:
        return False


def museum_writes_coverage() -> bool:
    """Whether endless_museum.gd puts a coverage block in the sidecar.

    A BARE grep FOR "coverage" IS A FALSE POSITIVE: the word already appears in
    a comment about shading at line 2412, so the quoted dict key is what is
    looked for. This is only a heads-up line for the report — the real answer is
    whether the block is in the sidecar the run actually wrote."""
    try:
        with open(MUSEUM_GD, "r", encoding="utf-8", errors="replace") as f:
            txt = f.read()
    except OSError:
        return False
    return bool(re.search(r'"(coverage|shot_coverage|bodies_in_frame)"', txt))


def view_flags(view: str, row: dict, x_override, z_override) -> tuple:
    """(extra cmdline flags, a dict describing the camera we ASKED for).

    With --em-shot-view present the museum frames from the hall it just built
    and we pass nothing else.  Without it we compose the nearest thing the
    existing flags can reach, and say so."""
    w = float(row.get("w", 0) or 0)
    h = float(row.get("h", 0) or 0)
    vest = float(row.get("vestibule", 0) or 0)
    x0 = float(row.get("cell_x0", -1) or -1)
    cx = x0 + 1.0 + w / 2.0        # hall centre in x: the record's own origin
    cz = vest + h / 2.0            # hall centre in z, past the vestibule

    if museum_has_view_flag():
        flags = ["--em-shot-view=" + view]
        if view == "fpv":
            if x_override is not None:
                flags.append("--em-shot-x=%.2f" % x_override)
            if z_override is not None:
                flags.append("--em-shot-at=%.2f" % z_override)
        return flags, {"mode": "museum", "view": view}

    # ---- legacy composition, when the flag has not landed yet ----
    if view == "top":
        # the whole hall inside the frame: z fills the short axis, x the long
        hgt = max(h / FOV_DOWN, w / FOV_ACROSS) * 1.06
        return (["--em-shot-pitch=-89", "--em-shot-yaw=180",
                 "--em-shot-y=%.2f" % (hgt - EYE),
                 "--em-shot-x=%.2f" % cx, "--em-shot-at=%.2f" % cz],
                {"mode": "legacy", "view": view, "projection": "perspective",
                 "why": "no --em-shot-view: a long lens straight down, not orthographic",
                 "arith": "height = max(h/%.4f, w/%.4f)*1.06 = max(%.1f, %.1f)*1.06 = %.2f m"
                          % (FOV_DOWN, FOV_ACROSS, h / FOV_DOWN, w / FOV_ACROSS, hgt),
                 "asked": {"x": cx, "z": cz, "eye_y": hgt, "yaw": 180.0, "pitch": -89.0}})
    if view == "iso":
        diag = math.hypot(w, h)
        hgt = max(2.5, diag * 0.45)
        return (["--em-shot-pitch=-35.264", "--em-shot-yaw=225",
                 "--em-shot-y=%.2f" % (hgt - EYE),
                 "--em-shot-x=%.2f" % (x0 + 1.5), "--em-shot-at=%.2f" % (vest + 1.5)],
                {"mode": "legacy", "view": view, "projection": "perspective",
                 "why": "no --em-shot-view: a raised OBLIQUE from the near-low corner. "
                        "This is NOT the contract's orthographic axonometric — the existing "
                        "flags cannot make the camera orthographic, and --em-shot-x/-at snap "
                        "to a walk cell so it cannot stand outside the hall.",
                 "arith": "eye = 0.45 * diag(%.0f,%.0f) = %.2f m; yaw 225 faces (+x,+z)"
                          % (w, h, hgt),
                 "asked": {"x": x0 + 1.5, "z": vest + 1.5, "eye_y": hgt,
                           "yaw": 225.0, "pitch": -35.264}})
    # fpv
    fx = cx if x_override is None else float(x_override)
    fz = (vest + 2.0) if z_override is None else float(z_override)
    return (["--em-shot-yaw=180", "--em-shot-pitch=-2", "--em-shot-y=0",
             "--em-shot-x=%.2f" % fx, "--em-shot-at=%.2f" % fz],
            {"mode": "legacy", "view": view, "projection": "perspective",
             "why": "no --em-shot-view: standing eye height, yaw 180 faces +z INTO the hall",
             "arith": "eye_y = --em-shot-y 0 + %.2f = %.2f m" % (EYE, EYE),
             "asked": {"x": fx, "z": fz, "eye_y": EYE, "yaw": 180.0, "pitch": -2.0}})


# ── running one view ─────────────────────────────────────────────────────────
def png_dims(path: str):
    """(w, h) from the IHDR, without a decoder dependency."""
    try:
        with open(path, "rb") as f:
            head = f.read(24)
        if len(head) >= 24 and head[:8] == b"\x89PNG\r\n\x1a\n":
            return struct.unpack(">II", head[16:24])
    except OSError:
        pass
    return None


def frame_detail(path: str) -> dict:
    """Is there anything IN the frame, or is it a wall?

    THE BYTE COUNT IS NOT EVIDENCE. Measured 2026-09-19: an fpv shot standing
    nose-first against a blank plaster wall came back 1,563,386 bytes and sailed
    through a 20 kB floor — the film grain alone defeats PNG. Calibrated over
    six frames of this museum:

        blank wall   std  6.1   busy 16%   edge 0.16
        real halls   std 27-38  busy 76-87%  edge 3.5-3.9

    `edge`, the mean absolute horizontal gradient of the luminance, separates
    them by 22x, so that is the gate. Falls back to the byte count when Pillow
    or numpy is absent, and SAYS SO rather than passing quietly."""
    try:
        from PIL import Image
        import numpy as np
    except ImportError:
        return {"measured": False,
                "note": "no Pillow/numpy — falling back to the byte count, "
                        "which cannot tell a hall from a wall"}
    try:
        a = np.asarray(Image.open(path).convert("L").resize((240, 160)),
                       dtype="float32")
    except Exception as exc:                                  # a truncated PNG
        return {"measured": False, "note": "unreadable: %s" % exc}
    med = float(np.median(a))
    return {"measured": True,
            "std": round(float(a.std()), 2),
            "busy_pct": round(float((abs(a - med) > 8).mean()) * 100, 1),
            "edge": round(float(abs(np.diff(a, axis=1)).mean()), 2)}


MIN_EDGE = 1.0          # halfway, in log terms, between the wall (0.16) and a hall (3.5)
MIN_BUSY_PCT = 35.0
MIN_VIEW_DIFF_PCT = 5.0  # two views of one hall must disagree about at least this much


def cross_view_check(recs: list, out_dir: str) -> list:
    """Three cameras must not produce one picture.

    THE SIDECAR CAN DESCRIBE A CAMERA THAT DID NOT TAKE THE PICTURE. Measured
    2026-09-19 on fractals|fractal mengersponge: top, iso and fpv came back with
    0.00% of pixels differing by more than 8 — one image, three times — while
    each sidecar named a different camera and the top sidecar claimed an
    orthographic eye at y 68.3 looking straight down. The frame is a low
    perspective view of another room. Every other gate was green: the exit code
    was 0, each PNG was 2.0 MB at 1800x1200, the museum's log named the right
    hall, and the detail gate saw edge 2.50 because architecture has edges.

    A correctly shot hall is nowhere near this: noise|random noise types
    measured 81%, 99% and 99% differing across the same three pairs."""
    try:
        from PIL import Image
        import numpy as np
    except ImportError:
        return []
    live = [r for r in recs if r.get("ok") and r.get("png") and os.path.isfile(r["png"])]
    if len(live) < 2:
        return []
    imgs = {}
    for r in live:
        try:
            imgs[r["view"]] = np.asarray(
                Image.open(r["png"]).convert("RGB").resize((360, 240)), dtype="int16")
        except Exception:
            pass
    bad = []
    names = sorted(imgs)
    for i in range(len(names)):
        for j in range(i + 1, len(names)):
            a, b = names[i], names[j]
            pct = float((abs(imgs[a] - imgs[b]).max(axis=2) > 8).mean()) * 100.0
            if pct < MIN_VIEW_DIFF_PCT:
                bad.append((a, b, round(pct, 2)))
    return bad


# ── what the frame CANNOT see ────────────────────────────────────────────────
# A PICTURE WHOSE BLIND SPOTS ARE UNDECLARED IS WORSE THAN NO PICTURE, BECAUSE
# IT READS AS COMPLETE. The three views were refuted one by one on 2026-09-19
# and the tool called all three landed, because its only question was whether a
# non-blank PNG existed. These functions ask the question the skeptics asked.
#
# The arithmetic is deliberately small and it re-derives NOTHING about the hall:
#   * the bodies come from the ledger's own row, with the world positions the
#     museum wrote as it placed them;
#   * the camera comes from the sidecar, which endless_museum.gd reads back off
#     the live Camera3D at the moment of capture;
#   * the only thing computed here is whether one is inside the other.
# Re-deriving hall geometry in Python is exactly how tools/long_museum.py came
# to report a strip 16% too long with its own check green.

WORK_KINDS = ("artifact", "showing")     # what a hall is FOR; furniture is the building
BODY_UP = 1.6        # the ledger records an ORIGIN, not an extent — see `assumption`
BODY_R = 0.4
MIN_HELD_PCT = 50.0  # a frame holding fewer than half the works is not about the hall

# A standing blind sentence per view: what this standpoint cannot see BY
# CONSTRUCTION, with the measurement that established it. These are not
# hedges — each one is a refutation somebody performed.
BLIND = {
    "top": "A plan discards height: anything under a lid, inside a body or beneath "
           "another body reads as its footprint, and a tall work and a flat one look "
           "alike. Whether the box the lens was fitted to reaches the top of what was "
           "built is a separate question — the `box_height` cross-check answers it per "
           "frame rather than assuming either way.",
    # NO STORED FIGURE LIVES IN THIS SENTENCE. It used to say "roughly HALF, and
    # the other three corners measure 49%, 54% and 58%" — a constant measured on
    # one hall on one day — and it was printed beside the engine's own per-frame
    # measurement of 87% on that same hall. Two numbers for one fact in one
    # sentence is how a reader learns to trust neither, so the number is taken
    # from the sidecar per frame by coverage_verdict, or its absence is said.
    "iso": "ABSENCE IN THIS FRAME IS NOT EVIDENCE OF ABSENCE. An axonometric looks along "
           "ONE ray through a building made of rooms, so part of the hall stands behind an "
           "interior partition from any corner: this is a fact about the projection, not a "
           "tuning problem, and no corner fixes it. How much of THIS hall is behind a wall "
           "is whatever the engine's coverage block below measures for this frame — this "
           "tool keeps no figure of its own. Only presence carries information here.",
    "fpv": "One standpoint, 70 degrees across, and a hall is deeper than a frustum is wide. "
           "Everything behind the eye is gone by construction — on primitives|point one "
           "that took in the artifact `origin` at (0,0,0), the namesake of the hall.",
}


def _basis(yaw_deg: float, pitch_deg: float) -> tuple:
    """(right, up, forward) for Godot's yawed player carrying a pitched camera.

    B = Ry(yaw) * Rx(pitch), the order endless_museum.gd itself builds in
    _compose_view_shot. Checked against all three of the engine's own written
    claims: top gives right -X / up +Z / forward -Y, and iso gives forward
    (1,-1,1)/sqrt(3). If this basis were wrong those three would not all land."""
    y, p = math.radians(yaw_deg), math.radians(pitch_deg)
    cy, sy, cp, sp = math.cos(y), math.sin(y), math.cos(p), math.sin(p)
    right = (cy, 0.0, -sy)
    up = (sy * sp, cp, cy * sp)
    fwd = (-sy * cp, sp, -cy * cp)
    return right, up, fwd


def _dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def camera_from_sidecar(side: dict) -> dict:
    """The camera the sidecar says took the picture, or None with a reason."""
    if not isinstance(side, dict):
        return None
    pos = side.get("position")
    if not (isinstance(pos, list) and len(pos) == 3
            and all(isinstance(v, (int, float)) for v in pos)):
        return None
    yaw, pitch = side.get("yaw_deg"), side.get("pitch_deg")
    if yaw is None or pitch is None:
        return None
    vp = side.get("viewport")
    aspect = 1.5
    if isinstance(vp, list) and len(vp) == 2 and float(vp[1] or 0) > 0:
        aspect = float(vp[0]) / float(vp[1])
    right, up, fwd = _basis(float(yaw), float(pitch))
    ortho = str(side.get("projection", "")).startswith("ortho")
    cam = {"eye": tuple(float(v) for v in pos), "right": right, "up": up, "fwd": fwd,
           "aspect": aspect, "ortho": ortho}
    if ortho:
        size = side.get("ortho_size")
        if size is None:
            return None
        cam["half_w"] = float(size) / 2.0
        cam["half_h"] = float(size) / (2.0 * aspect)
    else:
        cam["tan_half"] = math.tan(math.radians(float(side.get("fov", 70.0)) / 2.0))
    return cam


def _sample_in_frame(cam: dict, pt: tuple) -> tuple:
    """(inside, depth, u, half_w, v, half_h) for one world point."""
    d = (pt[0] - cam["eye"][0], pt[1] - cam["eye"][1], pt[2] - cam["eye"][2])
    f = _dot(d, cam["fwd"])
    u = _dot(d, cam["right"])
    v = _dot(d, cam["up"])
    if cam["ortho"]:
        hw, hh = cam["half_w"], cam["half_h"]
        ok = f > 0.0 and abs(u) <= hw + BODY_R and abs(v) <= hh + BODY_R
    else:
        if f <= 0.05:
            return False, f, u, 0.0, v, 0.0
        hw = cam["tan_half"] * f
        hh = hw / cam["aspect"]
        ok = abs(u) <= hw + BODY_R and abs(v) <= hh + BODY_R
    return ok, f, u, hw, v, hh


def frame_fill(cam: dict, box: dict) -> dict:
    """How much of the frame the hall's BOUNDING BOX occupies — which is not the
    same question as how much of the frame the hall occupies.

    IT IS AN UPPER BOUND AND IT WAS BEING READ AS A MEASUREMENT. For the plan
    the camera's axes are the box's axes, so the two questions nearly coincide.
    For the iso they do not: the camera looks down a diagonal, the box's
    projected outline is a hexagon whose corners stand outside anything that was
    ever built, and this reported 94.3% across and down for a frame whose hall
    rasterises to about half of it. The number is kept, because fitting is what
    it describes; the claim it makes has been narrowed to the one it can carry."""
    if not cam or not cam.get("ortho") or not isinstance(box, dict):
        return {}
    try:
        xs, ys, zs = box["x"], box["y"], box["z"]
    except (KeyError, TypeError):
        return {}
    du = dv = 0.0
    cx = (float(xs[0]) + float(xs[1])) / 2.0
    cy = (float(ys[0]) + float(ys[1])) / 2.0
    cz = (float(zs[0]) + float(zs[1])) / 2.0
    for ix in (float(xs[0]), float(xs[1])):
        for iy in (float(ys[0]), float(ys[1])):
            for iz in (float(zs[0]), float(zs[1])):
                d = (ix - cx, iy - cy, iz - cz)
                du = max(du, abs(_dot(d, cam["right"])))
                dv = max(dv, abs(_dot(d, cam["up"])))
    return {"across_pct": round(du / cam["half_w"] * 100.0, 1),
            "down_pct": round(dv / cam["half_h"] * 100.0, 1),
            "of": "the hall's BOUNDING BOX, not the hall",
            "note": "how much of the frame the fitted BOX spans, at aspect %.2f:1. A box is "
                    "not a silhouette: where the camera's axes are not the box's axes — the "
                    "iso — the projected box is a hexagon reaching outside everything built, "
                    "so read this as an UPPER BOUND on the hall's share of the frame and not "
                    "as a measurement of it. Whatever is not hall is star field."
                    % cam["aspect"]}


def engine_coverage(side: dict) -> dict:
    """endless_museum.gd's own coverage block, if it has landed yet.

    WRITTEN BLIND TO ITS SPELLING, ON PURPOSE. This was authored while another
    agent was still writing that block, so rather than guess one set of key names
    and silently read nothing, every plausible spelling is accepted and the block
    is carried VERBATIM under `_raw` beside whatever could be normalised out of
    it. The guess was wrong — the block landed as bodies_placed / in_frame /
    hidden_behind_geometry, none of which was in the first alias list — and the
    tolerance is the only reason this is a two-line fix rather than a silent
    "engine declared no coverage" on a sidecar that declared it.

    ITS `in_frame` IS ALREADY OCCLUSION-SUBTRACTED: the engine counts a body as
    in frame only if it is inside the frustum AND a physics ray reaches it, and
    reports the ones it can see but not reach as hidden_behind_geometry. Reading
    that as a further subtraction would double-count every hidden body.

    When nothing is there the tool says the engine declared no coverage, which
    is a fact about the engine, not a pass."""
    if not isinstance(side, dict):
        return {}
    blk = side.get("coverage")
    if not isinstance(blk, dict):
        for k in ("shot_coverage", "frame_coverage", "visibility", "bodies_coverage"):
            if isinstance(side.get(k), dict):
                blk = side[k]
                break
    if not isinstance(blk, dict):
        # a flat spelling, straight on the sidecar
        flat = {k: side[k] for k in
                ("bodies_total", "bodies_in_frame", "bodies_visible", "bodies_occluded")
                if k in side}
        if not flat:
            return {}
        blk = flat

    def pick(*names):
        for n in names:
            v = blk.get(n)
            if isinstance(v, (int, float)):
                return int(v)
            if isinstance(v, list):
                return len(v)
        return None

    out = {"_raw": blk, "_by": "endless_museum.gd"}
    tot = pick("bodies_placed", "bodies", "bodies_total", "total", "placed", "n_bodies",
               "count", "dealt")
    held = pick("in_frame", "bodies_in_frame", "visible", "bodies_visible", "seen",
                "shown", "framed", "inside")
    occ = pick("hidden_behind_geometry", "occluded", "bodies_occluded", "hidden",
               "behind_wall")
    beh = pick("behind_camera", "behind", "bodies_behind")
    outf = pick("outside_frustum", "out_of_frame", "outside")
    for k, v in (("total", tot), ("held", held), ("occluded", occ),
                 ("behind_camera", beh), ("outside_frustum", outf)):
        if v is not None:
            out[k] = v
    cells = blk.get("cells")
    if isinstance(cells, dict) and isinstance(cells.get("hall_seen"), (int, float)):
        # the engine walks the hall's own floor cells: the share of the ROOM a
        # reader can actually see, which body counts alone never say
        out["hall_seen_pct"] = round(float(cells["hall_seen"]) * 100.0, 1)
    # THE ENGINE'S OWN TOKEN LIST, when it publishes one. This is what makes a
    # real symmetric difference possible instead of an inference off the missing
    # list: with both sides naming every body, the comparison runs in BOTH
    # directions and a body the ledger has and the engine does not is findable
    # too. It appeared on 2026-09-19 while this was being written; the code
    # below degrades to the missing-list comparison when it is absent, because a
    # block that changes shape must not take the guard down with it.
    inv = blk.get("inventory")
    if isinstance(inv, dict):
        if isinstance(inv.get("tokens"), list):
            out["inventory_tokens"] = [str(t) for t in inv["tokens"]]
        if isinstance(inv.get("not_counted"), dict):
            out["inventory_not_counted"] = {k: list(v) if isinstance(v, list) else v
                                            for k, v in inv["not_counted"].items()}
        if isinstance(inv.get("kinds"), dict):
            out["inventory_kinds"] = dict(inv["kinds"])
    if isinstance(blk.get("by_kind"), dict):
        out["by_kind"] = blk["by_kind"]
    ff = blk.get("frame_fill")
    if isinstance(ff, dict) and isinstance(ff.get("hall_pct"), (int, float)):
        # the hall's own meshes rasterised over the frame — the measurement this
        # tool's box-corner arithmetic could never make
        out["hall_pct"] = round(float(ff["hall_pct"]), 1)
        out["hall_pct_method"] = str(ff.get("method", ""))[:400]
    if isinstance(blk.get("missing"), list):
        # `missing` is TRUNCATED for display and must never be the thing a
        # comparison is made against: the fpv block names 53 bodies and a guard
        # reading the first 14 would find agreement in the tail it never read.
        # The whole list stays reachable under `_raw`, and _eng_missing() is the
        # only accessor any check is allowed to use.
        out["missing"] = blk["missing"][:14]
        out["missing_n"] = len(blk["missing"])
        out["missing_by_kind"] = dict(collections.Counter(
            str(m.get("kind", "")) for m in blk["missing"] if isinstance(m, dict)))
        out["missing_by_why"] = dict(collections.Counter(
            str(m.get("why", "")) for m in blk["missing"] if isinstance(m, dict)))
    if isinstance(blk.get("method"), str):
        out["method"] = blk["method"]
    for k in ("blind", "blind_sentence", "caveat", "note", "warning", "blindness"):
        if isinstance(blk.get(k), str) and blk[k].strip():
            out["blind"] = blk[k].strip()
            break
    return out


# ── are the two inventories even the same inventory? ─────────────────────────
# THE GUARD THAT COMPARED 65 AGAINST 65. Until 2026-09-19 the only thing checked
# across the two implementations was a total, and on primitives|point one both
# totals were 65 — of different sets. The engine drops plinths (2 here) and
# holds two `weapon_cabinet` bodies the ledger row has no record of; the two
# differences cancel in the sum and the guard reported agreement. A guard that
# can only ever subtract one total from another is theatre: it cannot be wrong.
#
# Everything below compares what can actually be compared from the two records
# on disk — the engine's rule, its named bodies, and its held count — and says
# by name where they part company.

FRUSTUM_WHYS = ("behind the camera", "outside the frustum")
OCCLUDED_WHY = "in the frustum, behind something solid"


def engine_inventory_rule() -> dict:
    """Which body kinds endless_museum.gd's own inventory drops — READ OUT OF THE
    SOURCE at run time, never transcribed into this file.

    _shot_bodies() walks _edit_records and `continue`s past some kinds; the
    ledger row's `bodies` list keeps every one of them. That single difference is
    why two counts of "65" could mean different sets, so the rule has to come
    from the code that applies it. A hand-typed copy is the science_screen
    fault — the declaration and the enum drift, nothing fails loudly, and the
    verdict becomes a fact about a typo. If the rule cannot be read, this says
    so, and the count comparison is withheld rather than guessed."""
    try:
        with open(MUSEUM_GD, "r", encoding="utf-8", errors="replace") as f:
            txt = f.read()
    except OSError:
        return {"derived": False, "excludes": [],
                "why": "endless_museum.gd could not be read, so its inventory rule is "
                       "unknown and the two counts cannot be made like-for-like"}
    m = re.search(r"\nfunc\s+_shot_bodies\s*\([^\n]*\n(.*?)(?=\nfunc\s)", txt, re.S)
    if not m:
        return {"derived": False, "excludes": [],
                "why": "no _shot_bodies() found in endless_museum.gd — a count difference "
                       "could not be told from a definition difference, so it is not claimed"}
    kinds = re.findall(r'if\s+kind\s*==\s*"([^"]+)"\s*:\s*\r?\n\s*continue', m.group(1))
    return {"derived": True, "excludes": sorted(set(kinds)),
            "source": "commons/scenes/endless_museum.gd:_shot_bodies",
            "how": "read out of the function's own source at run time, so it follows the "
                   "engine if the rule changes instead of going stale here"}


def _mkey(d: dict) -> tuple:
    return (str(d.get("token", "")), str(d.get("kind", "")))


def _eng_missing(eng: dict) -> list:
    """The engine's WHOLE missing list. `missing` on the normalised block is cut
    to 14 for printing, and a set comparison made against a truncated list finds
    agreement in the tail it never read."""
    raw = eng.get("_raw") if isinstance(eng, dict) else None
    for src in (raw, eng):
        if isinstance(src, dict) and isinstance(src.get("missing"), list):
            return [m for m in src["missing"] if isinstance(m, dict)]
    return []


def inventory_dispute(cov: dict, eng: dict, snap_row: dict, rule: dict) -> dict:
    """Do the engine and the ledger describe the same set of bodies, and do they
    agree about how many of them this frame holds?

    HARD findings mean one side is describing a different hall: the two
    inventories are not the same size under the engine's own rule, the engine
    names a body the ledger row has never heard of, or the engine's block does
    not add up against itself. Those DISPUTE the view.

    SOFT findings are real disagreements with a stated cause — chiefly that this
    tool projects a body's ORIGIN while the engine projects its AABB, and that
    the engine can see occlusion and this cannot. They are named and printed and
    they do not reject on their own, because naming a known difference as a
    defect would make the guard cry wolf until nobody reads it."""
    out = {"comparable": False, "hard": [], "soft": [], "rule": rule}
    if not eng:
        out["why"] = ("the engine wrote no coverage block in this sidecar, so there is only "
                      "one inventory here and nothing to compare it against")
        return out
    bodies = [b for b in (snap_row.get("bodies") or []) if isinstance(b, dict)]
    if not bodies:
        out["why"] = ("the snapshot ledger row carries no body list, so the engine's count "
                      "stands unchecked — which is not the same as checked and agreed")
        return out
    out["comparable"] = True

    # TWO WAYS OF KNOWING WHAT THE ENGINE LEFT OUT, AND NEITHER IS TRUSTED ALONE.
    # The rule read out of _shot_bodies goes stale if that function is rewritten
    # past the regex; the block's own `not_counted` is the run's record but lists
    # only the kinds this hall actually had. Their union is what is filtered out
    # of the ledger row, so a failure of either one cannot turn a matching set
    # into a false symmetric difference. Where they disagree, that is reported
    # below rather than resolved here.
    decl_map = eng.get("inventory_not_counted")
    decl_map = decl_map if isinstance(decl_map, dict) else {}
    excl = set(rule.get("excludes") or []) | set(decl_map)
    out["excluded_by"] = {"source_rule": sorted(rule.get("excludes") or []),
                          "engine_declared": sorted(decl_map)}
    led_kind = collections.Counter(str(b.get("kind", "")) for b in bodies)
    led_tok = collections.Counter(_mkey(b) for b in bodies
                                  if str(b.get("kind", "")) not in excl)
    n_all = sum(led_kind.values())
    n_lfl = sum(v for k, v in led_kind.items() if k not in excl)
    eng_tot = eng.get("total")
    out.update({"ledger_bodies_raw": n_all, "ledger_bodies_like_for_like": n_lfl,
                "engine_bodies": eng_tot, "excluded_kinds": sorted(excl),
                "excluded_n": n_all - n_lfl,
                "ledger_by_kind": dict(led_kind)})

    # ── H1: the same number of bodies, under the engine's own rule ──
    if eng_tot is not None and rule.get("derived"):
        if int(eng_tot) != n_lfl:
            msg = ("TWO DIFFERENT INVENTORIES: the engine's live count is %d bodies; the "
                   "pre-run ledger row holds %d comparable ones (%s drops kind %s, and "
                   "there %s %d of those here)."
                   % (int(eng_tot), n_lfl, rule.get("source", "_shot_bodies"),
                      "/".join(sorted(excl)) or "nothing",
                      "is" if (n_all - n_lfl) == 1 else "are", n_all - n_lfl))
            if n_all == int(eng_tot):
                msg += (" The RAW ledger count is %d, equal to the engine's %d — which is "
                        "how this passed a guard that compared totals. Two different sets "
                        "of %d." % (n_all, int(eng_tot), n_all))
            out["hard"].append(msg)
        else:
            out["soft_ok"] = ("the two inventories are the same size under the engine's own "
                              "rule: %d bodies each, with %d %s excluded on both sides"
                              % (n_lfl, n_all - n_lfl, "/".join(sorted(excl)) or "kinds"))
    elif eng_tot is not None:
        out["soft"].append("The inventory rule could not be derived (%s), so the engine's %d "
                           "is compared against nothing: the ledger row's raw count is %d and "
                           "whether those are the same set is UNKNOWN."
                           % (rule.get("why", "no reason given"), int(eng_tot), n_all))

    # ── H2: the symmetric difference, both ways when both ways are possible ──
    miss = _eng_missing(eng)
    out["engine_missing_n"] = len(miss)
    inv_toks = eng.get("inventory_tokens")
    if isinstance(inv_toks, list) and inv_toks:
        # THE FULL SET, BOTH DIRECTIONS. The engine names every body it counted,
        # as "kind:token", so this is the comparison the task actually wanted and
        # not an inference off the bodies that happened to be missing.
        eng_tok = collections.Counter(
            tuple(reversed(t.split(":", 1))) if ":" in t else (t, "")
            for t in inv_toks)
        out["set_source"] = "the engine's own inventory.tokens — every body, both directions"
        only_e = eng_tok - led_tok
        only_l = led_tok - eng_tok
        out["set_engine_only"] = [{"token": k[0], "kind": k[1], "n": n}
                                  for k, n in sorted(only_e.items())][:20]
        out["set_ledger_only"] = [{"token": k[0], "kind": k[1], "n": n}
                                  for k, n in sorted(only_l.items())][:20]
        out["set_engine_only_n"] = sum(only_e.values())
        out["set_ledger_only_n"] = sum(only_l.values())
        if only_e or only_l:
            bits = []
            if only_e:
                bits.append("%d only the engine has (%s)"
                            % (sum(only_e.values()),
                               ", ".join("`%s`%s" % (k[0], "x%d" % n if n > 1 else "")
                                         for k, n in sorted(only_e.items())[:5])))
            if only_l:
                bits.append("%d only the ledger row has (%s)"
                            % (sum(only_l.values()),
                               ", ".join("`%s`%s" % (k[0], "x%d" % n if n > 1 else "")
                                         for k, n in sorted(only_l.items())[:5])))
            out["hard"].append(
                "THE TWO INVENTORIES ARE DIFFERENT SETS — symmetric difference: %s. Both "
                "claim to list every body in this hall; they do not list the same bodies, "
                "so every coverage number on this frame is an answer about a set nobody "
                "has stated." % "; ".join(bits))
        # the engine's DECLARED exclusions, checked against the rule read out of
        # its source. Two ways of knowing one thing, so it can fail.
        decl = decl_map
        if decl is not None and rule.get("derived"):
            # ONE DIRECTION ONLY, AND THIS COST A RUN TO LEARN. `not_counted`
            # lists the bodies actually dropped IN THIS HALL, so a hall with no
            # plinths declares none — which is not the rule disagreeing with the
            # code, it is a hall with no plinths. Comparing the two sets for
            # equality convicted primitives|primitives portals of a defect it
            # did not have. What CAN fail is the other way: a kind the block
            # says it dropped that the source never drops.
            decl_kinds = sorted(decl)
            rogue = sorted(set(decl_kinds) - set(rule.get("excludes") or []))
            if rogue:
                out["hard"].append(
                    "THE ENGINE'S BLOCK SAYS IT DROPPED KIND %s, WHICH ITS SOURCE DOES NOT "
                    "DROP (%s applies: %s). The block and the code disagree about what was "
                    "counted." % (", ".join(rogue), rule.get("source", "_shot_bodies"),
                                  ", ".join(sorted(excl)) or "nothing"))
            elif decl_kinds:
                out["exclusions_confirmed"] = decl_kinds
            else:
                out["exclusions_confirmed"] = ("none declared — this hall has no body of "
                                               "an excluded kind (%s)"
                                               % (", ".join(sorted(excl)) or "none"))
    else:
        out["set_source"] = ("the engine's `missing` list only — it publishes no full "
                             "inventory, so a body the LEDGER has and the engine does not "
                             "cannot be seen from here")
        eng_miss_tok = collections.Counter(_mkey(m) for m in miss)
        unknown = sorted((k, n, led_tok.get(k, 0)) for k, n in eng_miss_tok.items()
                         if led_tok.get(k, 0) < n)
        if unknown:
            out["engine_only"] = [{"token": k[0], "kind": k[1], "engine_names": n,
                                   "ledger_has": h} for (k, n, h) in unknown]
            out["hard"].append(
                "BODIES THE ENGINE NAMES AND THE LEDGER ROW DOES NOT CARRY: %s. The engine "
                "is reporting on a hall this row does not describe — either the row is "
                "stale or the run built something else."
                % "; ".join("`%s` (%s) named %dx, ledger has %d" % (k[0], k[1], n, h)
                            for (k, n, h) in unknown[:6]))

    # ── H3: a kind cannot be missing more often than it exists ──
    eng_miss_kind = collections.Counter(str(m.get("kind", "")) for m in miss)
    out["engine_missing_by_kind"] = dict(eng_miss_kind)
    for k, n in sorted(eng_miss_kind.items()):
        have = 0 if k in excl else led_kind.get(k, 0)
        if n > have:
            out["hard"].append(
                "The engine names %d bod%s of kind `%s` as out of frame, but the ledger row "
                "records %d of that kind in this hall%s."
                % (n, "y" if n == 1 else "ies", k, have,
                   " (the engine's own rule drops that kind entirely)" if k in excl else ""))

    # ── H4: the engine's block against itself ──
    held, beh = eng.get("held"), eng.get("behind_camera")
    outf, occ = eng.get("outside_frustum"), eng.get("occluded")
    parts = [held, beh, outf, occ]
    if eng_tot is not None and all(isinstance(v, int) for v in parts):
        if sum(parts) != int(eng_tot):
            out["hard"].append(
                "THE ENGINE'S BLOCK DOES NOT ADD UP: %d in frame + %d behind the camera + "
                "%d outside the frustum + %d behind something solid = %d, against its own "
                "stated total of %d." % (held, beh, outf, occ, sum(parts), int(eng_tot)))
        if miss and len(miss) != beh + outf + occ:
            out["hard"].append(
                "THE ENGINE NAMES %d BODIES UNDER `missing` BUT ACCOUNTS FOR %d (%d behind "
                "the camera + %d outside + %d occluded)."
                % (len(miss), beh + outf + occ, beh, outf, occ))

    # ── S1: the HELD counts, which the old guard never compared at all ──
    by = cov.get("by_kind") or {}
    tool_held = sum(int(d.get("held", 0)) for k, d in by.items() if k not in excl)
    tool_tot = sum(int(d.get("total", 0)) for k, d in by.items() if k not in excl)
    out.update({"tool_held_like_for_like": tool_held,
                "tool_bodies_like_for_like": tool_tot, "engine_held": held})
    # THE HELD COUNTS, WHICH THE OLD GUARD NEVER LOOKED AT AT ALL — and they are
    # not the same measurement, so subtracting them raw proves nothing. The
    # engine's held is frustum MINUS occlusion; this tool's is frustum alone. The
    # honest comparison is to predict the engine's number from this tool's and
    # say what is left over:
    #
    #     expected = tool frustum count - the engine's own occluded count
    #     residual = engine held - expected
    #
    # A residual of zero is agreement. A residual equal to the inventory gap is
    # agreement about every body BOTH records have, with the disputed bodies
    # accounting for the rest — which is a stronger statement than either number.
    if cov.get("measured") and isinstance(held, int):
        inv_gap = (int(eng_tot) - n_lfl) if (eng_tot is not None) else None
        if isinstance(occ, int):
            expected = tool_held - occ
            residual = held - expected
            out.update({"held_expected_from_tool": expected, "held_residual": residual,
                        "inventory_gap": inv_gap})
            if residual == 0:
                out["held_reconciles"] = True
                out["soft"].append(
                    "HELD COUNTS RECONCILE EXACTLY: this tool projects %d into the frustum, "
                    "the engine calls %d of them occluded, and %d - %d = %d is precisely the "
                    "engine's held count. The two implementations agree."
                    % (tool_held, occ, tool_held, occ, held))
            elif inv_gap and residual == inv_gap:
                out["held_reconciles"] = True
                out["soft"].append(
                    "HELD COUNTS RECONCILE ONCE THE DISPUTED BODIES ARE ADDED IN: this tool "
                    "projects %d into the frustum and the engine calls %d occluded, which "
                    "predicts %d; the engine holds %d. The residual of %d is exactly the %d "
                    "bod%s the engine has and the ledger row does not. The two agree about "
                    "every body they both know — the whole disagreement is the inventory."
                    % (tool_held, occ, expected, held, residual, inv_gap,
                       "y" if inv_gap == 1 else "ies"))
            else:
                out["soft"].append(
                    "HELD COUNTS DISAGREE BEYOND OCCLUSION: this tool projects %d into the "
                    "frustum and the engine calls %d occluded, predicting %d; the engine "
                    "holds %d, a residual of %+d%s. The stated cause on this side is the "
                    "ORIGIN assumption — a body is a point here and an AABB in the engine, "
                    "so a wide body can reach into a frame its origin misses."
                    % (tool_held, occ, expected, held, residual,
                       " against an inventory gap of %d" % inv_gap if inv_gap else ""))
        elif tool_held != held:
            out["soft"].append(
                "HELD COUNTS DIFFER and cannot be reconciled: the engine holds %d, this "
                "tool projects %d, and the engine declared no occluded count to explain "
                "the difference with." % (held, tool_held))
        else:
            out["held_agrees"] = True

    # ── S2: the named symmetric difference on frustum membership ──
    # occlusion is deliberately NOT compared: this tool cannot see it, so a
    # disagreement about it would be a disagreement with a known answer.
    c_eng_out = collections.Counter(_mkey(m) for m in miss
                                    if str(m.get("why", "")) in FRUSTUM_WHYS)
    c_tool_out = collections.Counter(_mkey(m) for m in (cov.get("missing_all") or []))
    only_eng = c_eng_out - c_tool_out
    only_tool = c_tool_out - c_eng_out
    if only_eng or only_tool:
        out["frustum_symmetric_difference"] = {
            "engine_says_out_tool_holds": [{"token": k[0], "kind": k[1], "n": n}
                                           for k, n in sorted(only_eng.items())][:12],
            "tool_says_out_engine_holds": [{"token": k[0], "kind": k[1], "n": n}
                                           for k, n in sorted(only_tool.items())][:12],
            "n_engine_only": sum(only_eng.values()),
            "n_tool_only": sum(only_tool.values())}
        bits = []
        if only_eng:
            bits.append("the engine puts %d outside the frame that this tool holds (%s)"
                        % (sum(only_eng.values()),
                           ", ".join("`%s`" % k[0] for k in list(only_eng)[:4])))
        if only_tool:
            bits.append("this tool puts %d outside that the engine has in the frustum (%s)"
                        % (sum(only_tool.values()),
                           ", ".join("`%s`" % k[0] for k in list(only_tool)[:4])))
        out["soft"].append(
            "THE TWO SIDES NAME DIFFERENT BODIES: %s. Same frustum, same hall, different "
            "answer per body — the counts can match while the sets do not." % "; and ".join(bits))
    out["disputed"] = bool(out["hard"])
    out["n_hard"], out["n_soft"] = len(out["hard"]), len(out["soft"])
    return out


def cells_legend() -> dict:
    """The engine's OWN legend for the ledger row's cell grid, read out of the
    source rather than remembered. Without it the letters in `cells` are just
    letters and no claim can be made about them."""
    try:
        with open(MUSEUM_GD, "r", encoding="utf-8", errors="replace") as f:
            txt = f.read()
    except OSError:
        return {}
    m = re.search(r'"legend"\s*:\s*\{([^}]*)\}', txt)
    if not m:
        return {}
    return {a: b for a, b in re.findall(r'"([^"]*)"\s*:\s*"([^"]*)"', m.group(1))}


def sealed_floor_note(snap_row: dict, eng: dict) -> str:
    """Whether the floor figure's denominator still excludes what it asks about.

    THIS NOTE ASSERTED THE ANSWER AND THE ANSWER CHANGED UNDER IT, WITHIN THE
    HOUR. It was written to say the engine measures "how much of this hall's
    floor is under something" over _walk_cells — a set from which every cell a
    body seals has already been removed, so the question cannot be answered by
    it — and it said that as a standing fact. Between writing and running, the
    engine started unioning the sealed cells back in (`sealed_or_taken` in its
    own cells block, floor 343 -> 394) and the sentence became false while
    reading exactly as confidently as before. A note that asserts a stale fact
    is the failure this whole pass is against.

    So it reads the engine's record instead of remembering it: if the
    denominator names the sealed cells, this says they are counted and stands
    down; only when they are absent does the caveat stand — and then it is
    quantified off the ledger row's own grid, with the legend read out of the
    engine's source rather than transcribed."""
    if not eng or eng.get("hall_seen_pct") is None:
        return ""
    cells = (eng.get("_raw") or {}).get("cells")
    cells = cells if isinstance(cells, dict) else {}
    floor = cells.get("hall_floor")
    sealed_in = cells.get("sealed_or_taken")
    if isinstance(sealed_in, (int, float)) and sealed_in:
        return ("The floor figure's denominator INCLUDES the cells a body seals: the engine "
                "reports %d of its %s floor cells as sealed-or-taken, unioned back in "
                "rather than left out. A denominator that dropped them could not be asked "
                "what is on top of them, and this one can."
                % (int(sealed_in), floor if floor is not None else "own"))
    grid = snap_row.get("cells")
    if not isinstance(grid, list) or not grid:
        return ""
    counts = collections.Counter(
        "".join("".join(r) if isinstance(r, list) else str(r) for r in grid))
    leg = cells_legend()
    sealed = [ch for ch, word in leg.items() if "sealed" in word.lower()]
    n = sum(counts.get(ch, 0) for ch in sealed)
    if not sealed or not n:
        return ""
    return ("THE FLOOR FIGURE'S DENOMINATOR MAY EXCLUDE WHAT IT IS ASKING ABOUT: its cells "
            "block names no sealed-cell count, and the ledger row's own grid marks %d "
            "cell(s) `%s` — `%s` in the engine's legend. Against a floor of %s that is not "
            "a rounding difference: a cell a body stands on cannot be counted as a cell "
            "under a body, so a low 'under something' figure would be partly a fact about "
            "the denominator."
            % (n, "`/`".join(sealed), leg.get(sealed[0], "sealed by a body"),
               floor if floor is not None else "the engine's own count"))


def coverage_from_ledger(side: dict, snap_row: dict) -> dict:
    """Which of the hall's works this frame holds — from the SNAPSHOT row.

    Never from the ledger as it stands after the run: the run rewrote it."""
    cam = camera_from_sidecar(side)
    if cam is None:
        return {"measured": False,
                "why": "the sidecar does not carry a position/yaw/pitch this can project "
                       "through — no coverage can be claimed either way"}
    bodies = snap_row.get("bodies")
    if not isinstance(bodies, list) or not bodies:
        return {"measured": False,
                "why": "the snapshot ledger row carries no body list (schema %s) — what "
                       "the museum placed here is unknown, so what the frame holds is "
                       "unknowable" % snap_row.get("_schema", "?")}
    per = {}
    missing = []
    # EVERY KIND, not just the works. `missing` is filtered to artifact/showing
    # for reading, and a set comparison made against that filtered list would
    # silently agree about every piece of furniture it had already dropped —
    # which is exactly how `weapon_cabinet`, named twice by the engine and
    # unknown to the ledger row, went unnoticed. missing_all is what the guard
    # compares; missing is what a human reads.
    missing_all = []
    behind = off_side = off_updown = 0
    for b in bodies:
        if not isinstance(b, dict):
            continue
        kind = str(b.get("kind", ""))
        w = b.get("world")
        if not (isinstance(w, list) and len(w) == 3):
            continue
        p = tuple(float(v) for v in w)
        samples = [p, (p[0], p[1] + BODY_UP * 0.5, p[2]), (p[0], p[1] + BODY_UP, p[2])]
        res = [_sample_in_frame(cam, s) for s in samples]
        inside = any(r[0] for r in res)
        row = per.setdefault(kind, {"total": 0, "held": 0})
        row["total"] += 1
        if inside:
            row["held"] += 1
            continue
        if all(r[1] <= 0.05 for r in res):
            why, behind = "behind the camera", behind + 1
        elif all(abs(r[2]) > r[3] for r in res):
            why, off_side = "off the side of the frame", off_side + 1
        else:
            why, off_updown = "above or below the frame", off_updown + 1
        entry = {"token": b.get("token", ""), "kind": kind,
                 "world": [round(v, 2) for v in p], "why": why}
        missing_all.append(entry)
        if kind in WORK_KINDS:
            missing.append(entry)
    tot = sum(per.get(k, {}).get("total", 0) for k in WORK_KINDS)
    held = sum(per.get(k, {}).get("held", 0) for k in WORK_KINDS)
    out = {"measured": True,
           "_by": "tools/em_shots.py — the snapshot ledger row's bodies projected "
                  "through the sidecar's own camera",
           "works_total": tot, "works_held": held,
           "held_pct": round(held / tot * 100.0, 1) if tot else 0.0,
           # every kind, so the engine's all-bodies count can be compared with
           # a like-for-like one rather than with a works-only subset
           "bodies_total": sum(d["total"] for d in per.values()),
           "bodies_held": sum(d["held"] for d in per.values()),
           "behind_camera": behind, "off_side": off_side, "off_updown": off_updown,
           "by_kind": per,
           "missing": missing[:14],
           "missing_truncated": max(0, len(missing) - 14),
           "missing_all": missing_all,
           "assumption": "the ledger records an ORIGIN, not an extent, so each body is "
                         "modelled as a %.1f m standing segment of radius %.1f m. A tall "
                         "work whose origin is out of frame may still show; this is a "
                         "stated assumption, not a measurement." % (BODY_UP, BODY_R),
           "occlusion": "NOT MEASURED HERE. A body counted as held may still stand behind "
                        "a wall — this is frustum membership only. Re-deriving the hall's "
                        "walls in Python is the long_museum.py mistake."}
    fill = frame_fill(cam, side.get("hall_box") or {})
    if fill:
        out["frame_fill"] = fill
    behind_pct = depth_behind(cam, side.get("hall_box") or {})
    if behind_pct is not None:
        out["depth_behind_pct"] = behind_pct
    return out


def depth_behind(cam: dict, box: dict) -> float:
    """How much of the hall's own depth lies BEHIND the camera, as a percentage.

    General in the camera's forward axis rather than in z, so it holds for any
    yaw. Reproduces the fpv skeptic's 23% on primitives|point one: the eye
    stands at z 3.5 in a box spanning z -4..29."""
    if not cam or cam.get("ortho") or not isinstance(box, dict):
        return None
    try:
        xs, ys, zs = box["x"], box["y"], box["z"]
    except (KeyError, TypeError):
        return None
    fs = []
    for ix in (float(xs[0]), float(xs[1])):
        for iy in (float(ys[0]), float(ys[1])):
            for iz in (float(zs[0]), float(zs[1])):
                d = (ix - cam["eye"][0], iy - cam["eye"][1], iz - cam["eye"][2])
                fs.append(_dot(d, cam["fwd"]))
    lo, hi = min(fs), max(fs)
    if hi <= lo or lo >= 0.0:
        return 0.0
    return round(min(1.0, (0.0 - lo) / (hi - lo)) * 100.0, 1)


def works_sentence(kind: str, cov: dict, eng: dict, disp: dict) -> str:
    """One sentence about a kind of body, with the side that measured each number
    named in it — or no sentence at all.

    THE FAULT THIS REPLACES WAS THE WORST ONE IN THE FILE. It said "Of the 16
    artifacts the museum placed, this frame holds 16" while the engine's own
    `missing` list, in the same sidecar, named 8 of those artifacts as hidden
    behind something solid. The count was this tool's frustum-only projection
    and the list beside it was the engine's occlusion ray, and nothing connected
    them: a sentence composed separately from the numbers it summarises WILL
    drift, and the sentence is the part a human reads.

    So the sentence is derived here from both sides at once. Where they agree it
    says one number. Where they differ it says both, attributes each, and says
    what the difference is made of. Where they cannot be reconciled it says that
    instead of picking a winner."""
    by = (cov.get("by_kind") or {}).get(kind) or {}
    tot = int(by.get("total") or 0)
    tool_held = int(by.get("held") or 0)
    label = kind + ("s" if not kind.endswith("s") else "")
    # THE ENGINE'S OWN PER-KIND TALLY FIRST, when it publishes one. Deriving the
    # engine's held as total-minus-missing was arithmetic over two records; its
    # by_kind block is one record, counted where the bodies were counted.
    ebk = (eng.get("by_kind") or {}).get(kind)
    if isinstance(ebk, dict) and isinstance(ebk.get("held"), int):
        e_held, e_placed = int(ebk["held"]), int(ebk.get("placed", 0))
        whys = collections.Counter(
            str(m.get("why", "")) for m in _eng_missing(eng)
            if str(m.get("kind", "")) == kind)
        det = ", ".join("%d %s" % (n, w) for w, n in sorted(whys.items(), key=lambda kv: -kv[1]))
        s = ("%s: the ENGINE holds %d of the %d it counted%s."
             % (label.capitalize(), e_held, e_placed,
                (" and names the other %d (%s)" % (e_placed - e_held, det))
                if e_placed > e_held and det else ""))
        if tot and (tot != e_placed or tool_held != e_held):
            s += (" This tool, projecting the ledger row's %d through the same camera and "
                  "blind to occlusion, gets %d — %s." % (tot, tool_held,
                  "the two records are DISPUTED below, so do not average them"
                  if disp.get("disputed") else
                  "the difference is the occlusion this tool cannot see"))
        return s
    eng_miss = (disp.get("engine_missing_by_kind") or {}).get(kind)
    if not tot and eng_miss is None:
        return ""
    if eng_miss is None:
        if not tot:
            return ""
        return ("%s: this tool's frustum-only projection of the ledger row holds %d of %d. "
                "Occlusion is undeclared for this frame, so that is an upper bound on what "
                "is visible, not a count of it." % (label.capitalize(), tool_held, tot))
    # the engine's held count for this kind is total-minus-missing, which is only
    # arithmetic if the two agree about the total. When they do not, say so.
    if disp.get("disputed") or not tot:
        return ("%s: the engine names %d as not in this frame; this tool projects %d of %d "
                "into the frustum. The two inventories are DISPUTED (below), so these are "
                "not two answers to one question and neither should be quoted as the hall's."
                % (label.capitalize(), eng_miss, tool_held, tot))
    eng_held = tot - eng_miss
    whys = collections.Counter(
        str(m.get("why", "")) for m in _eng_missing(eng)
        if str(m.get("kind", "")) == kind)
    detail = ", ".join("%d %s" % (n, w) for w, n in sorted(whys.items(), key=lambda kv: -kv[1]))
    if eng_held == tool_held:
        return ("%s: both sides hold %d of %d%s." % (label.capitalize(), eng_held, tot,
                                                     (" — the %d it does not: %s"
                                                      % (eng_miss, detail)) if eng_miss else ""))
    return ("%s: the ENGINE holds %d of %d and names the other %d (%s); this tool projects "
            "%d into the frustum and cannot see occlusion, which is what the difference of "
            "%d is made of. Read the engine's number."
            % (label.capitalize(), eng_held, tot, eng_miss, detail, tool_held,
               abs(tool_held - eng_held)))


def coverage_verdict(view: str, cov: dict, eng: dict, disp: dict, snap_row: dict) -> tuple:
    """(fail_reason or "", the sentence this view must carry).

    THE ENGINE'S BLOCK OUTRANKS THIS ONE WHERE THEY OVERLAP, because it can see
    occlusion and this cannot; where both speak, a disagreement is reported
    rather than resolved. A gate must compare ACROSS implementations."""
    blind = [BLIND.get(view, "")]
    if eng.get("blind"):
        blind.append("engine: " + eng["blind"])
    if not cov.get("measured") and not eng.get("held"):
        blind.append("COVERAGE UNMEASURED: %s. This frame's blind spots are undeclared, "
                     "so neither presence nor absence in it should be quoted."
                     % cov.get("why", "no reason given"))
        return "", " ".join(s for s in blind if s)
    # THE ENGINE'S COUNT LEADS WHEN IT EXISTS, and its `in_frame` is taken as
    # given: it is measured with real AABBs, the real frustum planes and a
    # physics ray, none of which this tool can see. Subtracting its
    # hidden_behind_geometry from it would count every hidden body twice.
    if eng.get("held") is not None and eng.get("total"):
        tot, held = int(eng["total"]), int(eng["held"])
        src = ("engine: frustum + occlusion ray over every placed body, "
               "hidden_behind_geometry already excluded")
    else:
        tot, held = cov.get("works_total", 0) or 0, cov.get("works_held", 0) or 0
        src = "ledger+sidecar: frustum membership of works only, occlusion NOT measured"
    pct = (held / tot * 100.0) if tot else 0.0

    # A GATE MUST COMPARE ACROSS IMPLEMENTATIONS — AND COMPARING TWO TOTALS IS
    # NOT THAT. This used to subtract one count of 65 from another count of 65
    # and report agreement between two different sets. inventory_dispute() does
    # the comparison now: sets, named bodies, and the held counts the old check
    # never looked at. Every finding it makes is carried in the sentence.
    for line in (disp.get("hard") or []):
        blind.append("DISPUTED — " + line)
    for line in (disp.get("soft") or []):
        blind.append(line)
    if disp.get("comparable") is False and disp.get("why"):
        blind.append("NOT CROSS-CHECKED: %s." % disp["why"])
    if eng.get("hall_seen_pct") is not None:
        blind.append("ENGINE, over the hall's own floor cells: %.0f%% of this hall's floor "
                     "is visible from this standpoint." % eng["hall_seen_pct"])
    sealed = sealed_floor_note(snap_row, eng)
    if sealed:
        blind.append(sealed)
    fill = (cov.get("frame_fill") or {})
    if fill and eng.get("hall_pct") is not None:
        # THE ENGINE RASTERISES THE HALL'S OWN MESHES AND THIS TOOL PROJECTS EIGHT
        # BOX CORNERS. Where both speak, the box number is named as what it is —
        # the fit — and the measurement is the engine's. Printing the larger one
        # alone is how "94% of the frame" came to stand for a hall covering half.
        blind.append("FRAME SHARE, both sides: the ENGINE rasterises this hall's own meshes "
                     "at %.0f%% of the frame; the BOUNDING BOX this tool projects spans "
                     "%.0f%% across and %.0f%% down. The box is what the lens was fitted "
                     "to, not what is in the picture — quote the %.0f%%."
                     % (eng["hall_pct"], fill.get("across_pct", 0),
                        fill.get("down_pct", 0), eng["hall_pct"]))
    elif fill:
        blind.append("MEASURED HERE: the hall's BOUNDING BOX spans %.0f%% of the frame "
                     "across and %.0f%% down — an upper bound on the hall's own share, not "
                     "a measurement of it; a box is not a silhouette, and no rasterised "
                     "figure is available for this frame to check it against."
                     % (fill.get("across_pct", 0), fill.get("down_pct", 0)))
    if cov.get("depth_behind_pct"):
        blind.append("MEASURED HERE: %.0f%% of this hall's depth lies behind the camera."
                     % cov["depth_behind_pct"])
    if cov.get("measured"):
        for k in ("artifact", "showing"):
            s = works_sentence(k, cov, eng, disp)
            if s:
                blind.append(s)
    if tot and pct < MIN_HELD_PCT:
        why = ("BLIND VIEW: the frame holds %d of %d bodies (%.0f%%, by %s)" %
               (held, tot, pct, src))
        det = []
        beh = eng.get("behind_camera", cov.get("behind_camera"))
        if beh:
            det.append("%d behind the camera" % int(beh))
        outf = eng.get("outside_frustum")
        if outf:
            det.append("%d outside the frustum" % int(outf))
        elif cov.get("off_side") or cov.get("off_updown"):
            det.append("%d outside the frustum"
                       % (cov.get("off_side", 0) + cov.get("off_updown", 0)))
        if eng.get("occluded"):
            det.append("%d in the frustum but behind something solid" % int(eng["occluded"]))
        if det:
            why += " — " + ", ".join(det)
        why += (". Most of the hall is outside this picture, so nothing in it can be read "
                "as an account of the hall.")
        return why, " ".join(s for s in blind if s)
    return "", " ".join(s for s in blind if s)


# ── the cross-checks, and which of them can actually fail ────────────────────
# A CHECK THAT CANNOT FAIL IS WORSE THAN NO CHECK, because it is counted.
# endless_museum.gd:_shot_hall_box does this:
#
#     var row: Dictionary = _layout_walk.get("%s|%s" % [chapter, pearl], {})
#     if row.has("h"):
#         h = int(row["h"])
#
# — h is COPIED OUT OF THE LEDGER. So checking the museum's printed h against
# the ledger's h compares the ledger with itself passed through a print. That
# check is dropped by name below rather than quietly deleted, and replaced by
# one that can fail: the segment's own far z, which comes from _segments[0] and
# never touches the ledger file.
def ledger_crosschecks(rec: dict, snap_row: dict, side: dict) -> list:
    out = []

    def add(name, status, independent, got, want, note):
        out.append({"check": name, "status": status, "independent": independent,
                    "got": got, "want": want, "note": note})

    got_hall = rec.get("museum_hall")
    add("hall", "pass" if (got_hall and not rec.get("wrong_hall"))
        else ("FAIL" if got_hall else "skipped"), True, got_hall, rec.get("hall"),
        "the museum's own account names the hall it framed; the ledger names the one asked "
        "for. Two sources, so it can fail — and it has. %s"
        % (rec.get("museum_hall_from")
           or "read off the printed [em-shot] hall line"
           if got_hall else
           "NEITHER the [em-shot] line nor the sidecar's `hall` block could be read, so the "
           "wrong-hall guard is OFF for this frame — that is not the same as passing."))

    wh = rec.get("museum_hall_wh") or []
    if len(wh) == 3:
        got_w, got_h, got_span = wh
        want_w = int(float(snap_row.get("w", -1) or -1))
        add("w", "pass" if got_w == want_w else "FAIL", True, got_w, want_w,
            "the engine takes w from _segments[0] — the segment it just built — not from "
            "the ledger row, so a stale row would show up here.")
        add("h", "DROPPED", False, got_h, int(float(snap_row.get("h", -1) or -1)),
            "CIRCULAR, removed 2026-09-19: endless_museum.gd:_shot_hall_box reads h out of "
            "_layout_walk, the ledger's own row, so this compared em_layout_walk.json "
            "against em_layout_walk.json. It could never fail. See `h_via_box` instead.")
        want_span = int(float(snap_row.get("span", -1) or -1))
        add("span", "pass" if got_span == want_span else "FAIL", True, got_span, want_span,
            "span is z1-z0 off the built segment record, not off the ledger row.")

    box = side.get("hall_box") if isinstance(side, dict) else None
    if isinstance(box, dict) and isinstance(box.get("z"), list) and len(box["z"]) == 2:
        z0, z1 = float(box["z"][0]), float(box["z"][1])
        want_h = int(float(snap_row.get("h", -1) or -1))
        add("h_via_box", "pass" if abs(z1 - want_h) < 0.51 else "FAIL", True, round(z1, 2),
            want_h, "REPLACES the circular h check: hall_box.z1 comes from _segments[0]'s "
                    "own far edge, so it is a fact about the segment that was built and it "
                    "can disagree with the ledger.")
        want_v = float(snap_row.get("vestibule", -1) or -1)
        add("vestibule_via_box", "pass" if abs(-z0 - want_v) < 0.51 else "FAIL", True,
            round(-z0, 2), want_v,
            "the box's near edge is -VESTIBULE_H; the ledger records the vestibule "
            "separately.")
    x = (box or {}).get("x") if isinstance(box, dict) else None
    if isinstance(x, list) and len(x) == 2 and snap_row.get("cell_x0") is not None:
        x0 = float(x[0])
        room_x0 = float(snap_row["cell_x0"])
        # endless_museum.gd:_shot_hall_box pads ONE cell for the wall skin, so
        # cell_x0 - 1 is the honest expectation; anything further out is a walk
        # cell that is not the room — the basin pool sits at x -2..1.
        want_x0 = room_x0 - 1.0
        slack = want_x0 - x0
        pool = box.get("pool_cells_excluded")
        if slack > 0.01:
            note = ("the fitted box starts %.0f m further out than the room's own start "
                    "plus the documented one-cell wall skin (cell_x0 %.0f, so %.0f): walk "
                    "cells that are NOT the room — the basin pool — widen it, and the "
                    "camera fitted to it is off-centre by about %.1f m."
                    % (slack, room_x0, want_x0, slack / 2.0))
            if pool:
                note += (" The engine excludes %d pool cells from its floor COUNT, but the "
                         "box the lens was fitted to still holds them." % int(pool))
        else:
            note = ("the box starts at the room's own start plus the one-cell wall skin, "
                    "with nothing outside the room pulling it wider.")
        add("box_x0", "pass" if slack <= 0.01 else "NOTE", True, x0, want_x0, note)
    y = (box or {}).get("y") if isinstance(box, dict) else None
    if isinstance(y, list) and len(y) == 2:
        y1 = float(y[1])
        tall = [b for b in (snap_row.get("bodies") or [])
                if isinstance(b, dict) and isinstance(b.get("world"), list)
                and len(b["world"]) == 3 and float(b["world"][1]) > y1]
        # WRITTEN AS A STANDING ACCUSATION AND IT WAS OUT OF DATE WITHIN THE
        # HOUR. y1 was the hard-coded WALL_H constant this morning, and the
        # engine now records which BODY set it in `y1_from`. The check reads
        # that field instead of repeating what used to be true: a note that
        # asserts a stale fact is the failure this whole pass is against.
        src = str(box.get("y1_from") or "").strip()
        if src:
            why = ("y1 is measured: it comes from the body `%s`, not from the WALL_H "
                   "constant it used to be hard-coded to (y0 from `%s`). Nothing is "
                   "clipped silently at the top of the frame."
                   % (src, str(box.get("y0_from") or "?")))
        else:
            why = ("y1 carries no `y1_from`, so it is the engine's WALL_H constant rather "
                   "than a measurement of what was built — anything taller than %.1f m is "
                   "clipped without a word." % y1)
        if tall:
            why += (" %d body origin(s) stand ABOVE the box: %s."
                    % (len(tall), ", ".join(str(b.get("token", "?")) for b in tall[:4])))
        else:
            why += (" No body ORIGIN in the ledger row stands above it, which is weaker "
                    "than 'nothing is taller': the ledger has no AABBs.")
        add("box_height", "FAIL" if tall else ("pass" if src else "NOTE"), True, y1,
            ("from body `%s`" % src) if src else "the built bodies' own extent", why)
    return out


def inventory_check(disp: dict) -> dict:
    """The cross-implementation row, in the same shape as the ledger checks —
    and with a status that can actually be bad.

    The check it replaces compared 65 against 65. This one compares the sets and
    the held counts, so `pass` now means something: the two records describe the
    same bodies and agree about how many of them the frame holds, up to the one
    difference that is stated rather than assumed."""
    if not disp.get("comparable"):
        return {"check": "inventory", "status": "skipped", "independent": True,
                "got": "one record only", "want": "two to compare",
                "note": disp.get("why", "no second inventory to compare against")}
    eng = disp.get("engine_bodies")
    lfl = disp.get("ledger_bodies_like_for_like")
    raw = disp.get("ledger_bodies_raw")
    if disp.get("hard"):
        return {"check": "inventory", "status": "DISPUTED", "independent": True,
                "got": "engine %s" % eng,
                "want": "ledger %s comparable (%s raw)" % (lfl, raw),
                "note": " | ".join(disp["hard"])}
    note = ("the engine's live inventory and the pre-run ledger row describe the same %s "
            "bodies under the engine's own rule, read out of %s; %s"
            % (lfl, (disp.get("rule") or {}).get("source", "_shot_bodies"),
               "the held counts agree" if disp.get("held_agrees") else
               ("the held counts reconcile through occlusion" if disp.get("held_reconciles")
                else "the held counts differ — see the soft findings")))
    status = "pass" if (disp.get("held_agrees") or disp.get("held_reconciles")) else "NOTE"
    return {"check": "inventory", "status": status, "independent": True,
            "got": "engine %s bodies, %s held" % (eng, disp.get("engine_held")),
            "want": "ledger %s bodies, %s held" % (lfl, disp.get("tool_held_like_for_like")),
            "note": note + ((" | " + " | ".join(disp["soft"])) if disp.get("soft") else "")}


def demote(rec: dict, why: str) -> None:
    """Move an already-written frame to the REJECTED name and say why in its sidecar."""
    rec["ok"] = False
    rec["why"] = (rec.get("why", "") + "; " if rec.get("why") else "") + why
    png = rec.get("png")
    if not png or not os.path.isfile(png) or png.endswith(".REJECTED.png"):
        return
    new_png = png[:-4] + ".REJECTED.png"
    side = png[:-4] + ".json"
    try:
        os.replace(png, new_png)
        rec["png"] = new_png
    except OSError:
        return
    if os.path.isfile(side):
        doc = load_json(side) or {}
        doc["verdict"] = "REJECTED: " + rec["why"]
        try:
            with open(side[:-5] + ".REJECTED.json", "w", encoding="utf-8") as f:
                json.dump(doc, f, indent=1, ensure_ascii=False)
            os.remove(side)
            rec["sidecar"] = side[:-5] + ".REJECTED.json"
        except OSError:
            pass

VOICE_RE = re.compile(r"the walk opens at chapter (\S+) \(pool row (\d+) of (\d+)\) . (.+)")
HAND_RE = re.compile(
    r"\[em-shot\] by hand: standing ([-\d.]+),([-\d.]+),([-\d.]+) \(asked ([-\d.]+),([-\d.]+)\), "
    r"yaw ([-\d.]+) pitch ([-\d.]+)")
# what --em-shot-view prints: "... — hall primitives|point one 20x29 span 33, box ..."
CAM_RE = re.compile(r"\[em-shot\] (view=.*)")
CAM_HALL_RE = re.compile(r"hall ([^|]+\|[^ ]+(?: [^ ]+)*?) (\d+)x(\d+) span (\d+)")


def read_godot_log(user_rel: str) -> str:
    """The run's own prints.

    THE NON-CONSOLE GODOT WRITES NOTHING TO THE PIPE. Every stdout capture here
    came back two lines of watchdog chatter, so "which voice won" was being read
    off an empty string and silently never fired. The prints are in
    user://logs/godot.log — and since Godot rotates the PREVIOUS log at startup,
    godot.log holds THIS run once it exits, as long as runs are serialised.
    Identity is not assumed: the log is only accepted if it carries this run's
    own shot path."""
    finger = "proof shot -> user://" + user_rel
    logs = os.path.join(USER_DIR, "logs")
    cands = [os.path.join(logs, "godot.log")]
    try:
        rot = [os.path.join(logs, f) for f in os.listdir(logs)
               if f.startswith("godot") and f.endswith(".log")]
        rot.sort(key=lambda p: os.path.getmtime(p), reverse=True)
        cands += rot[:4]
    except OSError:
        pass
    for p in cands:
        try:
            with open(p, "r", encoding="utf-8", errors="replace") as f:
                txt = f.read()
        except OSError:
            continue
        if finger in txt:
            return txt
    return ""


def run_view(view: str, args, hall_key: str, hall: dict) -> dict:
    ch, pearl = hall.get("chapter", ""), hall.get("pearl", "")
    mp = hall.get("map", "")
    sl = slug(ch, pearl)
    out_dir = os.path.join(OUT_ROOT, sl)
    os.makedirs(out_dir, exist_ok=True)

    user_rel = "em_shots/%s/%s.png" % (sl, view)
    user_png = os.path.join(USER_DIR, user_rel.replace("/", os.sep))
    user_side = user_png[:-4] + ".json"
    os.makedirs(os.path.dirname(user_png), exist_ok=True)
    # a stale PNG would give the watchdog a baseline it can never beat
    for p in (user_png, user_side):
        try:
            os.remove(p)
        except OSError:
            pass

    extra, asked = view_flags(view, hall, args.x, args.at)
    cmd = [sys.executable, WATCHDOG, "--expect=" + user_png,
           "--grace=%d" % args.grace, "--stall=%d" % args.stall, "--",
           args.godot, "--path", REPO, "--xr-mode", "off", "--no-window", SCENE, "--",
           "--em-chapter=" + ch, "--em-map=" + mp,
           "--em-segments=%d" % args.segments, "--em-no-costume",
           "--em-shot=user://" + user_rel] + extra
    if args.no_sim:
        cmd.append("--em-no-sim")

    rec = {"view": view, "hall": hall_key, "map": mp, "cmd": cmd, "asked": asked}
    if args.dry_run:
        rec["skipped"] = "dry run"
        print("  %-3s DRY  %s" % (view, " ".join(cmd[cmd.index("--") + 1:])))
        return rec

    t0 = time.time()
    proc = subprocess.run(cmd, capture_output=True, text=True,
                          encoding="utf-8", errors="replace", cwd=REPO)
    pipe = (proc.stdout or "") + (proc.stderr or "")
    rec["seconds"] = round(time.time() - t0, 1)
    rec["exit"] = proc.returncode
    log = read_godot_log(user_rel)          # the pipe is empty on the non-console exe
    rec["log_found"] = bool(log)
    with open(os.path.join(out_dir, view + ".log"), "w", encoding="utf-8") as f:
        f.write(" ".join(cmd) + "\n\n--- watchdog ---\n" + pipe
                + "\n--- user://logs/godot.log ---\n"
                + (log or "(this run's log could not be identified)"))

    # WHICH VOICE WON — read out of the museum's own print, not assumed
    m = VOICE_RE.search(log)
    if m:
        rec["opened_at"] = {"chapter": m.group(1), "pool_row": int(m.group(2)),
                            "pool_size": int(m.group(3)), "voice": m.group(4).strip()}
    for tag in ("[em-resume]", "[em-jump]", "[em-menu]"):
        if tag in log:
            rec.setdefault("warnings", []).append(
                "run log carries %s — another voice spoke for the chapter" % tag)
    m = HAND_RE.search(log)
    if m:
        rec["stood"] = {"x": float(m.group(1)), "shot_y": float(m.group(2)),
                        "z": float(m.group(3)), "yaw_deg": float(m.group(6)),
                        "pitch_deg": float(m.group(7))}
    m = CAM_RE.search(log)
    if m:
        rec["museum_said"] = m.group(1).strip()
        # THE ONE CHECK THIS TOOL EXISTS FOR. The museum names the hall it
        # actually framed. Measured 2026-09-19: --em-map=Biome_Ladder_Randomness
        # produced a photograph of primitives|point one, 99.97% identical to the
        # Point_One shot pixel for pixel, and every other signal was green —
        # exit 0, 2.4 MB, 1800x1200, sidecar written. Without this the tool
        # would file a confident picture of the wrong room.
        mh = CAM_HALL_RE.search(m.group(1))
        if mh:
            shot_key = mh.group(1).strip()
            rec["museum_hall"] = shot_key
            rec["museum_hall_wh"] = [int(mh.group(2)), int(mh.group(3)), int(mh.group(4))]
            if norm(shot_key) != norm(hall_key):
                rec["wrong_hall"] = (
                    "asked for '%s', the museum framed '%s' (%sx%s span %s). "
                    "--em-map did not select the pearl."
                    % (hall_key, shot_key, mh.group(2), mh.group(3), mh.group(4)))
    if proc.returncode == 125:
        rec["fatal"] = "watchdog could not kill Godot — a surviving instance holds the lock"

    # JUDGE BY THE PNG, NEVER BY THE EXIT CODE (0xC0000005 at teardown is normal)
    if not os.path.isfile(user_png):
        rec["ok"] = False
        rec["why"] = "no PNG at %s (exit %s)" % (user_png, proc.returncode)
        return rec
    size = os.path.getsize(user_png)
    rec["bytes"] = size
    dims = png_dims(user_png)
    if dims:
        rec["pixels"] = list(dims)
    det = frame_detail(user_png)
    rec["detail"] = det

    # THE SIDECAR IS READ BEFORE THE VERDICT, NOT AFTER IT. It carries the
    # camera the museum read back off the live Camera3D, and without that there
    # is no way to ask what the frame could see — which is now half the verdict.
    side = {}
    if os.path.isfile(user_side):
        side = load_json(user_side) or {}
        side["_sidecar_by"] = "endless_museum.gd"
    else:
        side = {
            "_sidecar_by": "tools/em_shots.py — the museum wrote no sidecar "
                           "(--em-shot-view not in endless_museum.gd yet)",
            "view": view,
            "projection": asked.get("projection", "perspective"),
            "position": [asked.get("asked", {}).get("x"),
                         asked.get("asked", {}).get("eye_y"),
                         asked.get("asked", {}).get("z")],
            "yaw_deg": asked.get("asked", {}).get("yaw"),
            "pitch_deg": asked.get("asked", {}).get("pitch"),
            "fov": 70.0,
            "framing": asked.get("arith", ""),
            "caveat": asked.get("why", ""),
        }
        if rec.get("stood"):
            s = rec["stood"]
            side["position"] = [s["x"], s["shot_y"] + EYE, s["z"]]
            side["_position_note"] = ("read back out of the run log: --em-shot-x/-at are "
                                      "snapped to the nearest walk cell by _stand_near")
    # THE REQUEST GOES BESIDE THE MUSEUM'S ACCOUNT, NEVER OVER IT. This wrote
    # side["hall"] = the hall ASKED FOR, on top of whatever the museum had put
    # there — so the Biome_Ladder_Randomness sidecar claimed a hall 19x43 span
    # 47 while the museum's own hall_box in the same file said x -3..21 z -4..29,
    # which is Point_One. The sidecar was the only record, and it was lying.
    # THE HALL CHECK MUST NOT GO QUIET WHEN THE ENGINE CHANGES ITS WORDING. It
    # is read out of the museum's printed "[em-shot] ... hall <key> WxH span S"
    # line, and on 2026-09-19 the iso view started printing a cutaway sentence
    # instead — so the one check this tool exists for reported `skipped` and
    # nothing said that the wrong-hall guard was off for that view. The sidecar
    # carries the engine's own `hall` block; it is a second source for the
    # IDENTITY only. Its w/h/span are not taken: _shot_hall_box copies h out of
    # the ledger, so comparing those would be the circular check already dropped.
    if not rec.get("museum_hall") and isinstance(side.get("hall"), dict):
        hb = side["hall"]
        shot_key = "%s|%s" % (hb.get("chapter", ""), hb.get("pearl", ""))
        if shot_key.strip("|"):
            rec["museum_hall"] = shot_key
            rec["museum_hall_from"] = ("the sidecar's own `hall` block — the museum printed "
                                       "no parseable [em-shot] hall line for this view")
            if norm(shot_key) != norm(hall_key):
                rec["wrong_hall"] = ("asked for '%s', the sidecar says the museum framed "
                                     "'%s'." % (hall_key, shot_key))
    side["requested_hall"] = {"key": hall_key, "chapter": ch, "pearl": pearl, "map": mp,
                              "w": hall.get("w"), "h": hall.get("h"),
                              "span": hall.get("span"), "vestibule": hall.get("vestibule"),
                              "cell_x0": hall.get("cell_x0"),
                              "_source": "ada_run/em_layout_walk.json"}
    if rec.get("museum_hall"):
        side["shot_hall"] = rec["museum_hall"]
        side["shot_hall_matches_request"] = not rec.get("wrong_hall")
        if rec.get("wrong_hall"):
            side["WRONG_HALL"] = rec["wrong_hall"]
    elif "hall" not in side:
        side["shot_hall"] = "unknown — the museum printed no [em-shot] view= line"
    side["detail"] = rec.get("detail")

    # ── WHAT THIS FRAME CANNOT SEE ───────────────────────────────────────────
    # `hall` is the SNAPSHOT row, read before the first boot. The fingerprint
    # rides along so a reader can check which file it was.
    side["ledger_snapshot"] = {k: SNAP.get(k) for k in
                               ("file", "sha1_12", "mtime", "taken_at")}
    side["ledger_snapshot"]["row_built_at"] = hall.get("built_at")
    side["ledger_snapshot"]["_why"] = (
        "a shot run REWRITES this hall's row, so every geometry fact here is taken "
        "from the file as it stood BEFORE the run. Comparing against the file "
        "afterwards would be comparing the run with itself.")

    eng = engine_coverage(side)
    cov = coverage_from_ledger(side, hall)
    if not eng:
        cov["engine_block"] = ("ABSENT: endless_museum.gd wrote no coverage block in this "
                               "sidecar, so occlusion is undeclared for this frame.")
    rec["coverage"] = cov
    rec["engine_coverage"] = eng
    side["coverage_check"] = cov
    if eng:
        side["coverage_engine"] = eng
    # THE CROSS-IMPLEMENTATION COMPARISON, made before the verdict so the verdict
    # can use it. Two records of one hall, written by two hands that cannot see
    # each other: the only honest question is whether they say the same thing.
    disp = inventory_dispute(cov, eng, hall, engine_inventory_rule())
    rec["dispute"] = disp
    side["coverage_dispute"] = disp
    cov_fail, blind = coverage_verdict(view, cov, eng, disp, hall)
    side["blind"] = blind
    rec["blind"] = blind
    checks = ledger_crosschecks(rec, hall, side)
    checks.append(inventory_check(disp))
    side["ledger_crosschecks"] = checks
    rec["checks"] = checks

    whys = []
    if size < MIN_PNG_BYTES:
        whys.append("PNG is %s B, under the %s B floor" % (format(size, ","),
                                                           format(MIN_PNG_BYTES, ",")))
    if det.get("measured"):
        if det["edge"] < MIN_EDGE or det["busy_pct"] < MIN_BUSY_PCT:
            whys.append("BLANK FRAME: edge %.2f (floor %.1f), busy %.1f%% (floor %.0f%%) — "
                        "the camera is looking at a wall, not a hall"
                        % (det["edge"], MIN_EDGE, det["busy_pct"], MIN_BUSY_PCT))
    if rec.get("wrong_hall"):
        whys.append("WRONG HALL: " + rec["wrong_hall"])
    if cov_fail:
        whys.append(cov_fail)
    # A DISPUTED VIEW IS REFUSED. The two records are not describing the same
    # set of bodies, so every coverage number on this frame is an answer to a
    # question nobody can state — and a frame that lands as "usable" with that
    # underneath it is the exact state this whole pass exists to stop.
    if disp.get("hard"):
        whys.append("DISPUTED INVENTORY: " + " ".join(disp["hard"]))
    for c in checks:
        if c["status"] == "FAIL":
            whys.append("CROSS-CHECK %s FAILED: got %s, the pre-run ledger says %s — %s"
                        % (c["check"], c["got"], c["want"], c["note"]))
    rec["ok"] = not whys
    # A frame can be usable and still be UNACCOUNTED FOR. Saying so is the whole
    # point: "landed" with undeclared blind spots is the state that misleads.
    rec["coverage_declared"] = bool(cov.get("measured") or eng.get("held") is not None)
    if whys:
        rec["why"] = "; ".join(whys)

    # A REJECTED FRAME NEVER TAKES THE GOOD NAME. It is kept — a photograph of
    # the wrong hall is the evidence FOR the wrong-hall finding — but under
    # <view>.REJECTED.png, so nothing that globs <view>.png can pick up a
    # picture of another room, and any earlier good frame for this view is
    # removed rather than left to be read as current.
    good = os.path.join(out_dir, view + ".png")
    bad = os.path.join(out_dir, view + ".REJECTED.png")
    dst_png = good if rec["ok"] else bad
    for stale in (good, bad):
        if stale != dst_png:
            try:
                os.remove(stale)
            except OSError:
                pass
    shutil.copy2(user_png, dst_png)
    rec["png"] = dst_png

    if rec["ok"]:
        side["verdict"] = ("usable" if rec["coverage_declared"] else
                           "usable, COVERAGE UNMEASURED — the blind spots of this frame "
                           "are undeclared")
    else:
        side["verdict"] = "REJECTED: " + rec.get("why", "")
    side["flags"] = cmd[cmd.index("--") + 1:]
    # THE SIDECAR IS CLEANED THE SAME WAY THE PNG IS, IN BOTH DIRECTIONS. This
    # removed only the REJECTED name when a view passed, so a view that went the
    # other way — passing this morning, refused this afternoon — left its old
    # `<view>.json` on disk saying "usable" beside `<view>.REJECTED.png`. Found
    # 2026-09-19 on iso and fpv of primitives|point one: two sidecars claiming a
    # hall box of y 0..4.5 and a verdict of "usable" for frames that had just
    # been refused for holding 40% and 11% of the hall. A stale verdict beside a
    # rejected frame is the same lie this whole pass is against.
    dst_side = os.path.join(out_dir, view + (".json" if rec["ok"] else ".REJECTED.json"))
    for stale in (os.path.join(out_dir, view + ".json"),
                  os.path.join(out_dir, view + ".REJECTED.json")):
        if stale != dst_side:
            try:
                os.remove(stale)
            except OSError:
                pass
    with open(dst_side, "w", encoding="utf-8") as f:
        json.dump(side, f, indent=1, ensure_ascii=False)
    rec["sidecar"] = dst_side
    rec["camera"] = side
    return rec


# ── the index page ───────────────────────────────────────────────────────────
def cam_line(side: dict) -> str:
    if not isinstance(side, dict):
        return "&mdash;"
    pos = side.get("position") or []
    bits = []
    if side.get("projection"):
        bits.append(html.escape(str(side["projection"])))
    if len(pos) == 3 and all(isinstance(v, (int, float)) for v in pos):
        bits.append("eye %.1f, %.1f, %.1f" % tuple(pos))
    if side.get("ortho_size") is not None:
        bits.append("ortho %.1f" % float(side["ortho_size"]))
    elif side.get("fov") is not None:
        bits.append("fov %.0f" % float(side["fov"]))
    if side.get("yaw_deg") is not None:
        bits.append("yaw %.0f" % float(side["yaw_deg"]))
    if side.get("pitch_deg") is not None:
        bits.append("pitch %.0f" % float(side["pitch_deg"]))
    la = side.get("looks_at")
    if isinstance(la, list) and len(la) == 3:
        bits.append("at %.1f, %.1f, %.1f" % tuple(float(v) for v in la))
    return " &middot; ".join(bits) or "&mdash;"


# A CONTACT SHEET THAT SHOWS THREE PICTURES AND NO CAVEATS IS THE THING THAT
# MISLEADS. Three frames in a row read as three angles on one complete account;
# two of these three were refuted on the day they were made. So the coverage
# rides ON the picture, in the same visual weight as the REJECTED banner, and
# the blind sentence sits under every frame whether it passed or not.
def coverage_bar(side: dict) -> str:
    cov = side.get("coverage_check") or {}
    eng = side.get("coverage_engine") or {}
    disp = side.get("coverage_dispute") or {}
    tot = eng.get("total", cov.get("works_total"))
    held = eng.get("held", cov.get("works_held"))
    if tot is None or held is None:
        return ('<div class="cov unk">coverage not measured &mdash; this frame&rsquo;s blind '
                'spots are undeclared</div>')
    pct = (held / tot * 100.0) if tot else 0.0
    word = "bodies" if eng.get("held") is not None else "works"
    # BOTH SIDES, NOT THE ENGINE'S ALONE. The bar used to print one number and a
    # reader had no way to know a second record disagreed with it — which is the
    # same fault as the prose that contradicted its own list, moved to the page
    # a human actually looks at.
    bits = ["engine holds <b>%d of %d</b> %s (%.0f%%)" % (held, tot, word, pct)
            if disp.get("comparable") else
            "holds <b>%d of %d</b> %s (%.0f%%)" % (held, tot, word, pct)]
    if disp.get("comparable"):
        t_held = disp.get("tool_held_like_for_like")
        t_tot = disp.get("ledger_bodies_like_for_like")
        if t_held is not None and t_tot is not None:
            same = (t_held == held and t_tot == tot)
            bits.append(("ledger row agrees" if same else
                         "<b>ledger row: %d of %d</b>" % (t_held, t_tot)))
    beh = eng.get("behind_camera", cov.get("behind_camera"))
    if beh:
        bits.append("%d behind the camera" % int(beh))
    outf = eng.get("outside_frustum")
    if outf is None:
        outf = (cov.get("off_side", 0) or 0) + (cov.get("off_updown", 0) or 0)
    if outf:
        bits.append("%d outside the frustum" % int(outf))
    if eng.get("occluded") is not None:
        bits.append("%d behind something solid" % int(eng["occluded"]))
    else:
        bits.append("occlusion undeclared")
    if eng.get("hall_seen_pct") is not None:
        bits.append("%.0f%% of the floor visible" % eng["hall_seen_pct"])
    fill = cov.get("frame_fill") or {}
    if fill:
        bits.append("box spans %.0f%% across, %.0f%% down (upper bound)"
                    % (fill.get("across_pct", 0), fill.get("down_pct", 0)))
    cls = "cov" + ("" if pct >= MIN_HELD_PCT else " thin")
    if disp.get("hard"):
        cls = "cov disp"
        bits.insert(0, "<b>DISPUTED</b>")
    return '<div class="%s">%s</div>' % (cls, " &middot; ".join(bits))


# THE PAGE MUST SHOW THE DISAGREEMENT, NOT ONLY THE ENGINE'S SIDE. A contact
# sheet that prints one record's numbers under a photograph is telling a reader
# there is one record. There are two, they are written by hands that cannot see
# each other, and where they part company that IS the finding.
def dispute_block(side: dict) -> str:
    disp = side.get("coverage_dispute") or {}
    hard = disp.get("hard") or []
    soft = disp.get("soft") or []
    if not hard and not soft:
        if disp.get("comparable"):
            return ('<div class="agree">both records agree: <b>%s</b> bodies, '
                    '<b>%s</b> held</div>'
                    % (disp.get("ledger_bodies_like_for_like"), disp.get("engine_held")))
        if disp.get("why"):
            return '<div class="agree none">not cross-checked &mdash; %s</div>' % html.escape(
                str(disp["why"]))
        return ""
    out = []
    for line in hard:
        out.append('<div class="disp hard"><b>DISPUTED</b> %s</div>' % html.escape(str(line)))
    for line in soft:
        out.append('<div class="disp soft">%s</div>' % html.escape(str(line)))
    sym = disp.get("frustum_symmetric_difference") or {}
    named = ([("engine says out, this tool holds it", r)
              for r in sym.get("engine_says_out_tool_holds", [])]
             + [("this tool says out, the engine has it in the frustum", r)
                for r in sym.get("tool_says_out_engine_holds", [])])
    if named:
        out.append('<div class="disp names">%s</div>' % " &middot; ".join(
            "<code>%s</code>%s <span class=meta>(%s)</span>"
            % (html.escape(str(r.get("token"))),
               ("&times;%d" % r["n"]) if int(r.get("n", 1)) > 1 else "", html.escape(w))
            for w, r in named[:8]))
    return "".join(out)


def blind_block(side: dict) -> str:
    txt = str(side.get("blind") or "").strip()
    if not txt:
        return ""
    return '<div class="blind"><b>cannot see:</b> %s</div>' % html.escape(txt)


def checks_block(side: dict) -> str:
    checks = side.get("ledger_crosschecks")
    if not isinstance(checks, list) or not checks:
        return ""
    bits = []
    for c in checks:
        st = str(c.get("status", ""))
        cls = {"pass": "ok", "FAIL": "no", "DROPPED": "drop"}.get(st, "note")
        bits.append('<span class="ck %s" title="%s">%s %s</span>'
                    % (cls, html.escape(str(c.get("note", ""))),
                       html.escape(str(c.get("check", ""))), html.escape(st)))
    return '<div class="checks">%s</div>' % " ".join(bits)


def build_index() -> str:
    rows = []
    for name in sorted(os.listdir(OUT_ROOT)) if os.path.isdir(OUT_ROOT) else []:
        d = os.path.join(OUT_ROOT, name)
        if not os.path.isdir(d):
            continue
        cells, hall = [], {}
        for v in VIEWS:
            png, stem = os.path.join(d, v + ".png"), v
            if not os.path.isfile(png) and os.path.isfile(os.path.join(d, v + ".REJECTED.png")):
                png, stem = os.path.join(d, v + ".REJECTED.png"), v + ".REJECTED"
            side = load_json(os.path.join(d, stem + ".json")) or {}
            hall = side.get("requested_hall") or side.get("hall") or hall
            if not os.path.isfile(png):
                cells.append('<figure class="miss"><div class="gap">no %s</div>'
                             '<figcaption><b>%s</b></figcaption></figure>' % (v, v))
                continue
            det = side.get("detail") or {}
            bad = str(side.get("verdict", "")).startswith("REJECTED")
            flag = ('<div class="bad">%s</div>' % html.escape(str(side.get("verdict", "")))
                    if bad else "")
            shot = side.get("shot_hall")
            shotline = ('<br><span class="meta">framed: %s</span>' % html.escape(str(shot))
                        if shot else "")
            meta = (("edge %.2f, busy %.0f%%" % (det["edge"], det["busy_pct"]))
                    if det.get("measured")
                    else html.escape(str(side.get("_sidecar_by", ""))[:40]))
            cells.append(
                '<figure class="{cls}"><img src="{dir}/{stem}.png" alt="{dir} {v}" '
                'loading="lazy">{flag}{cov}<figcaption><b>{v}</b><br>'
                '<span class="cam">{cam}</span>{shot}<br>'
                '<span class="meta">{kb:.0f} KB &middot; {meta}</span>{disp}{blind}{checks}'
                '</figcaption></figure>'.format(
                    cls="bad" if bad else "", dir=html.escape(name),
                    stem=html.escape(stem), v=v, flag=flag, cam=cam_line(side),
                    cov=coverage_bar(side), shot=shotline,
                    kb=os.path.getsize(png) / 1024.0, meta=meta,
                    disp=dispute_block(side),
                    blind=blind_block(side), checks=checks_block(side)))
        title = "%s &middot; %s" % (html.escape(str(hall.get("chapter", "?"))),
                                    html.escape(str(hall.get("pearl", name))))
        sub = "map %s &nbsp; w %s &nbsp; h %s &nbsp; span %s" % (
            html.escape(str(hall.get("map", "?"))), hall.get("w"), hall.get("h"),
            hall.get("span"))
        rows.append('<section><h2>%s</h2><p class="sub">%s</p><div class="row">%s</div></section>'
                    % (title, sub, "".join(cells)))
    page = """<!doctype html><meta charset="utf-8">
<title>Museum hall shots</title>
<style>
:root{--bg:#f7f6f3;--fg:#1b1b1b;--dim:#6a6a6a;--line:#d8d5cf;--card:#fff}
@media(prefers-color-scheme:dark){:root{--bg:#141413;--fg:#eceae4;--dim:#9b978e;--line:#2e2d2a;--card:#1d1c1a}}
*{box-sizing:border-box}
body{margin:0;padding:24px 16px 64px;background:var(--bg);color:var(--fg);
 font:15px/1.5 ui-sans-serif,system-ui,'Segoe UI',sans-serif}
h1{font-size:22px;margin:0 0 4px}
.lede{color:var(--dim);margin:0 0 28px;max-width:70ch}
section{border-top:1px solid var(--line);padding:20px 0}
h2{font-size:17px;margin:0 0 2px;font-weight:650}
.sub{color:var(--dim);margin:0 0 12px;font-size:13px}
.row{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:14px}
figure{margin:0;background:var(--card);border:1px solid var(--line);border-radius:8px;overflow:hidden}
img{display:block;width:100%;height:auto;background:#000}
figcaption{padding:8px 10px;font-size:12px;line-height:1.45}
.cam{color:var(--fg);font-family:ui-monospace,Consolas,monospace;font-size:11px}
.meta{color:var(--dim);font-size:11px}
figure.bad{border-color:#c0392b}
.bad>div.bad,div.bad{background:#c0392b;color:#fff;padding:5px 9px;font-size:11px;line-height:1.35}
.cov{background:#20603f;color:#fff;padding:5px 9px;font-size:11px;line-height:1.35}
.cov.thin{background:#a8560f}
.cov.unk{background:#6a6a6a}
.cov.disp{background:#7d2230}
.disp{margin-top:7px;padding:6px 8px;border-radius:4px;font-size:11px;line-height:1.45}
.disp.hard{background:rgba(192,57,43,.13);border-left:3px solid #c0392b}
.disp.soft{background:rgba(168,86,15,.12);border-left:3px solid #a8560f}
.disp.names{border-left:3px solid var(--line);color:var(--dim)}
.disp code{font-family:ui-monospace,Consolas,monospace}
.agree{margin-top:7px;padding:5px 8px;border-left:3px solid #20603f;color:var(--dim);
 font-size:11px}
.agree.none{border-left-color:var(--line)}
.blind{margin-top:7px;padding:6px 8px;border-left:3px solid var(--line);
 color:var(--dim);font-size:11px;line-height:1.45}
.checks{margin-top:7px;display:flex;flex-wrap:wrap;gap:4px}
.ck{font-family:ui-monospace,Consolas,monospace;font-size:10px;padding:1px 5px;
 border-radius:3px;border:1px solid var(--line);color:var(--dim);cursor:help}
.ck.ok{border-color:#20603f;color:#20603f}
.ck.no{border-color:#c0392b;color:#c0392b}
.ck.drop{text-decoration:line-through}
.miss .gap{aspect-ratio:3/2;display:flex;align-items:center;justify-content:center;
 color:var(--dim);font-size:13px;background:repeating-linear-gradient(45deg,transparent,
 transparent 9px,var(--line) 9px,var(--line) 10px)}
</style>
<h1>Museum hall shots</h1>
<p class="lede">Three views of each recorded hall, from <code>tools/em_shots.py</code>.
Geometry comes from <code>ada_run/em_layout_walk.json</code> as it stood <b>before</b> the run
&mdash; the museum&rsquo;s own record of what it built, snapshotted because a shot run rewrites
it. The camera facts under each frame are the sidecar beside the PNG: a picture nobody can
reproduce is not evidence. Built __WHEN__ &mdash; __N__ hall(s).</p>
<p class="lede"><b>Read the bar before the picture.</b> It says how many of the hall&rsquo;s bodies
the frame holds and who counted them. Three frames in a row look like a complete account and are
not one: the <i>iso</i> view was refuted outright, because an axonometric looks along one ray
through a building made of rooms, so part of the hall is behind an interior partition from every
corner &mdash; <b>absence in an iso frame is not evidence of absence</b>, only presence carries
information. How much is behind a wall is measured per frame by the engine and printed below each
one; this page keeps no stored figure of its own, because the one it used to keep read beside an
engine measurement several times its size. The <i>fpv</i> view sees one frustum from one
standpoint and everything behind it is gone. A frame that holds fewer than half the bodies is
refused and keeps the <code>.REJECTED</code> name.</p>
<p class="lede"><b>There are two records of every hall, and the red band is where they
disagree.</b> The engine counts the bodies it is standing among; the ledger row counts the bodies
the museum wrote down when it built the hall. Until 2026-09-19 the only check across them was a
total, and on <i>primitives&thinsp;|&thinsp;point one</i> both totals were 65 &mdash; of different
sets: the engine drops plinths, of which the row has two, and names two <code>weapon_cabinet</code>
bodies the row has never heard of. The differences cancelled in the sum. The sets and the held
counts are compared now, the symmetric difference is named body by body, and a view whose two
records are not describing the same hall is <b>DISPUTED</b> and refused.</p>
__ROWS__
"""
    page = page.replace("__ROWS__", "\n".join(rows) or '<p class="sub">nothing shot yet</p>')
    page = page.replace("__WHEN__", time.strftime("%Y-%m-%d %H:%M"))
    page = page.replace("__N__", str(len(rows)))
    os.makedirs(OUT_ROOT, exist_ok=True)
    path = os.path.join(OUT_ROOT, "index.html")
    with open(path, "w", encoding="utf-8") as f:
        f.write(page)
    return path


# ── cli ──────────────────────────────────────────────────────────────────────
def die(msg: str, code: int = 2):
    print(msg)
    sys.exit(code)


def cmd_list(halls: dict) -> int:
    plan = load_plan_index()
    print("%d hall(s) have an engine row in ada_run/em_layout_walk.json "
          "(of %d planned) — these CAN be shot:\n" % (len(halls), len(plan)))
    print("  %-40s %-26s %4s %4s %5s  %-4s %s"
          % ("chapter|pearl", "map", "w", "h", "span", "shot", "plan"))
    orphans = 0
    for k in sorted(halls):
        r = halls[k]
        d = os.path.join(OUT_ROOT, slug(r.get("chapter", ""), r.get("pearl", "")))
        have = "".join(v[0] if os.path.isfile(os.path.join(d, v + ".png")) else "-"
                       for v in VIEWS)
        orphan = norm(k).replace("/", "|") not in plan
        orphans += orphan
        print("  %-40s %-26s %4s %4s %5s  %-4s %s"
              % (k[:40], str(r.get("map", ""))[:26], r.get("w"), r.get("h"),
                 r.get("span"), have, "ORPHAN" if orphan else ""))
    print("\n  shot column: t/i/f = top/iso/fpv already in ada_run/em_shots/")
    print("  plan column: ORPHAN = the row outlived the plan. --em-map names a pearl the")
    print("               chapter no longer deals, so the museum opens at its FIRST pearl")
    print("               and photographs the wrong room. %d of %d here." % (orphans, len(halls)))
    return 0


def main() -> int:
    for stream in (sys.stdout, sys.stderr):   # the report is full of em dashes
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except (AttributeError, ValueError):
            pass
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--hall", help='"<chapter>|<pearl>", a map name, or a unique pearl')
    p.add_argument("--chapter", help="every recorded hall of this chapter")
    p.add_argument("--view", default="all", help="top, iso, fpv, all, or a comma list")
    p.add_argument("--list", action="store_true", dest="do_list")
    p.add_argument("--x", type=float, default=None, help="fpv: where to stand in x (metres)")
    p.add_argument("--at", type=float, default=None, help="fpv: where to stand in z (metres)")
    p.add_argument("--segments", type=int, default=1)
    p.add_argument("--grace", type=int, default=240, help="watchdog boot window, seconds")
    p.add_argument("--stall", type=int, default=150, help="watchdog stall window, seconds")
    p.add_argument("--godot", default=GODOT_DEFAULT)
    p.add_argument("--no-sim", action="store_true", help="pass --em-no-sim")
    p.add_argument("--dry-run", action="store_true", help="print the commands, run nothing")
    p.add_argument("--force", action="store_true",
                   help="shoot even though em_control.json would outrank --em-chapter")
    p.add_argument("--index-only", action="store_true", help="rebuild index.html and stop")
    args = p.parse_args()

    if args.index_only:
        print("index -> %s" % build_index())
        return 0

    halls = load_halls()
    if args.do_list:
        return cmd_list(halls)
    if not args.hall and not args.chapter:
        p.print_usage()
        print("\n  say --hall \"<chapter>|<pearl>\", --chapter <name>, or --list")
        return 2

    views = list(VIEWS) if args.view in ("all", "") else [
        v.strip() for v in args.view.split(",") if v.strip()]
    bad = [v for v in views if v not in VIEWS]
    if bad:
        die("unknown view(s): %s — pick from %s" % (", ".join(bad), ", ".join(VIEWS)))

    # which halls
    targets = []
    if args.hall:
        key, row = resolve_hall(halls, args.hall)
        if key is None:
            die(row if isinstance(row, str) else refusal_text(args.hall, halls))
        targets.append((key, row))
    else:
        want = norm(args.chapter)
        targets = [(k, r) for k, r in sorted(halls.items()) if norm(r.get("chapter", "")) == want]
        if not targets:
            chapters = sorted({str(r.get("chapter", "")) for r in halls.values()})
            die("REFUSED: no recorded hall in chapter '%s'.\n  Recorded chapters: %s"
                % (args.chapter, ", ".join(chapters)))

    # the control file, before anything boots
    ctl = control_check()
    print("control  %s" % CONTROL)
    for n in ctl["notes"]:
        print("         %s" % n)
    for b in ctl["blocking"]:
        print("  !!!    %s" % b)
    if not ctl["ok"] and not args.force:
        die("\nREFUSED: ada_run/em_control.json would outrank --em-chapter and the run would\n"
            "photograph a hall you did not ask for (endless_museum.gd:_start_at_chapter).\n"
            "  Fix it, then re-run:\n"
            '    python -c "import json,io; p=r\'%s\';'
            " d=json.load(open(p)); d.pop('resume_eye',None); d.pop('travel',None);"
            " json.dump(d,open(p,'w'),indent=1)\"\n"
            "  Or re-run with --force to shoot anyway and read the log for which voice won."
            % CONTROL)

    # THE SNAPSHOT, SAID OUT LOUD. Everything below is checked against the
    # ledger as it stood here, because the runs that follow rewrite it.
    print("ledger   %s  sha1 %s  mtime %s  (%d hall rows) — SNAPSHOT taken %s, before any boot"
          % (SNAP.get("file"), SNAP.get("sha1_12"), SNAP.get("mtime"),
             SNAP.get("halls", 0), SNAP.get("taken_at")))
    for k, r in targets:
        print("         row %s built_at %s" % (k, r.get("built_at")))
    print("         every cross-check below compares against THIS, never against the file")
    print("         after the run: a shot run rewrites the row it builds.")
    print("engine   coverage block %s in endless_museum.gd — %s" % (
        "IS written" if museum_writes_coverage() else "is NOT written yet",
        "its sidecar block is read and compared against this tool's own count"
        if museum_writes_coverage() else
        "occlusion will be reported as UNDECLARED, never as absent"))
    rule = engine_inventory_rule()
    if rule.get("derived"):
        print("rule     the engine's inventory (%s) drops kind: %s"
              % (rule["source"], ", ".join(rule["excludes"]) or "nothing"))
        print("         — read out of the source at run time, so the two counts can be made")
        print("           like-for-like. A total compared against a total cannot fail: both")
        print("           sides said 65 of primitives|point one and meant different sets.")
    else:
        print("rule     the engine's inventory rule could NOT be derived — %s"
              % rule.get("why", ""))
        print("         the body counts will be reported side by side and NOT compared.")

    have_flag = museum_has_view_flag()
    print("museum   --em-shot-view %s in %s" % (
        "IS present" if have_flag else "is NOT present yet", os.path.relpath(MUSEUM_GD, REPO)))
    if not have_flag:
        print("         -> falling back to --em-shot-pitch/-y/-yaw/-x/-at. 'top' is a long lens")
        print("            straight down, NOT orthographic; 'iso' is a raised oblique, NOT an")
        print("            orthographic axonometric. Every sidecar says so.")
    print("views    %s   segments %d   godot %s" % (", ".join(views), args.segments, args.godot))
    if not os.path.isfile(args.godot):
        die("REFUSED: no Godot at %s (pass --godot=<exe> or set GODOT_EXE)" % args.godot)
    print()

    results = []
    for key, row in targets:
        print("hall     %s   map %s   w %s  h %s  span %s  vestibule %s"
              % (key, row.get("map"), row.get("w"), row.get("h"), row.get("span"),
                 row.get("vestibule")))
        orphan = plan_orphan(key)
        if orphan:
            print("  !!!    %s" % orphan)
        for v in views:
            rec = run_view(v, args, key, row)
            results.append(rec)
            if rec.get("skipped"):
                continue
            mark = ("ok  " if rec.get("coverage_declared") else "ok? ") \
                if rec.get("ok") else "FAIL"
            size = "%s B" % format(rec.get("bytes", 0), ",") if rec.get("bytes") else "-"
            px = "%dx%d" % tuple(rec["pixels"]) if rec.get("pixels") else "-"
            det = rec.get("detail") or {}
            dtl = ("edge %4.2f busy %4.1f%%" % (det["edge"], det["busy_pct"])
                   if det.get("measured") else "unmeasured")
            print("  %-3s %s %-13s %-10s %-22s %5ss  exit %-11s %s"
                  % (v, mark, size, px, dtl, rec.get("seconds", "-"), rec.get("exit"),
                     os.path.relpath(rec.get("png", ""), REPO) if rec.get("png") else ""))
            if rec.get("opened_at"):
                o = rec["opened_at"]
                print("      opened at chapter %s (pool row %d/%d) — voice: %s"
                      % (o["chapter"], o["pool_row"], o["pool_size"], o["voice"]))
            if rec.get("museum_hall"):
                print("      museum framed: %s%s"
                      % (rec["museum_hall"], "" if not rec.get("wrong_hall") else "   <-- NOT what was asked"))
            elif not rec.get("log_found"):
                print("      !! this run's user://logs/godot.log could not be identified — "
                      "the hall check could not run")
            if rec.get("stood"):
                s = rec["stood"]
                print("      stood %.1f, %.1f, %.1f  yaw %.0f  pitch %.0f  (snapped to a walk cell)"
                      % (s["x"], s["shot_y"] + EYE, s["z"], s["yaw_deg"], s["pitch_deg"]))
            if rec.get("museum_said"):
                print("      museum: %s" % rec["museum_said"])
            # WHAT THE FRAME HOLDS, AND WHAT IT CANNOT SEE — printed for every
            # view, passed or refused. This is the line the old gate did not have.
            cov = rec.get("coverage") or {}
            eng = rec.get("engine_coverage") or {}
            if cov.get("measured"):
                print("      coverage: holds %d of %d works (%.0f%%)%s%s%s"
                      % (cov["works_held"], cov["works_total"], cov["held_pct"],
                         "" if not cov.get("behind_camera")
                         else "  |  %d BEHIND the camera" % cov["behind_camera"],
                         "" if not cov.get("off_side")
                         else "  |  %d off the side" % cov["off_side"],
                         "" if not cov.get("off_updown")
                         else "  |  %d above/below" % cov["off_updown"]))
                print("        by kind: %s" % "  ".join(
                    "%s %d/%d" % (k, d["held"], d["total"])
                    for k, d in sorted(cov.get("by_kind", {}).items())))
                for miss in cov.get("missing", [])[:6]:
                    print("        out of frame: %-28s %s  (%s)"
                          % (str(miss.get("token"))[:28], miss.get("world"), miss.get("why")))
                if cov.get("missing_truncated"):
                    print("        ... and %d more" % cov["missing_truncated"])
                fill = cov.get("frame_fill") or {}
                if fill:
                    # THE CONSOLE SAID "the hall fills 94.3%" OF A FRAME THE HALL
                    # COVERS HALF OF. It is the fitted BOX, and on an oblique
                    # camera the box's outline reaches well outside the building.
                    print("      framing:  the fitted BOX spans %.1f%% of the frame across "
                          "and %.1f%% down (an upper bound — a box is not a silhouette)%s"
                          % (fill.get("across_pct", 0), fill.get("down_pct", 0),
                             "" if eng.get("hall_pct") is None else
                             ";  the ENGINE rasterises the hall's own meshes at %.1f%%"
                             % eng["hall_pct"]))
            else:
                print("      coverage: NOT MEASURED — %s" % cov.get("why", "?"))
            if eng:
                print("      engine coverage: %d placed, %d in frame, %d behind the camera, "
                      "%d outside it, %d behind something solid%s"
                      % (eng.get("total", -1), eng.get("held", -1),
                         eng.get("behind_camera", -1), eng.get("outside_frustum", -1),
                         eng.get("occluded", -1),
                         "" if eng.get("hall_seen_pct") is None
                         else ";  %.0f%% of the hall's floor visible" % eng["hall_seen_pct"]))
                for miss in (eng.get("missing") or [])[:6]:
                    print("        engine says out: %-24s %s  (%s)"
                          % (str(miss.get("token"))[:24], miss.get("world"),
                             miss.get("why")))
            else:
                print("      engine coverage: absent — occlusion is UNDECLARED for this "
                      "frame, which is not the same as nothing being hidden")
            # THE CROSS-IMPLEMENTATION COMPARISON, said out loud whichever way it
            # goes. A check is only worth printing when its pass means something,
            # so the pass line names what was actually compared.
            disp = rec.get("dispute") or {}
            if disp.get("comparable"):
                print("      inventories: engine %s bodies / %s held   vs   ledger row %s "
                      "comparable (%s raw, %s excluded) / %s held"
                      % (disp.get("engine_bodies"), disp.get("engine_held"),
                         disp.get("ledger_bodies_like_for_like"),
                         disp.get("ledger_bodies_raw"), disp.get("excluded_n"),
                         disp.get("tool_held_like_for_like")))
                for line in disp.get("hard", []):
                    print("      !!! DISPUTED  %s" % line)
                for line in disp.get("soft", []):
                    print("        note: %s" % line)
                sym = disp.get("frustum_symmetric_difference") or {}
                for r in (sym.get("engine_says_out_tool_holds") or [])[:5]:
                    print("        differ: %-26s engine says out, this tool holds it"
                          % str(r.get("token"))[:26])
                for r in (sym.get("tool_says_out_engine_holds") or [])[:5]:
                    print("        differ: %-26s this tool says out, engine has it in frustum"
                          % str(r.get("token"))[:26])
                if not disp.get("hard") and not disp.get("soft"):
                    print("        the two records agree on the set AND on the held count")
            else:
                print("      inventories: NOT compared — %s" % disp.get("why", "?"))
            if rec.get("blind"):
                print("      cannot see: %s" % rec["blind"])
            for c in rec.get("checks", []):
                if c["status"] != "pass":
                    print("      check %-18s %-8s got %s want %s — %s"
                          % (c["check"], c["status"], c["got"], c["want"], c["note"]))
            passed = [c["check"] for c in rec.get("checks", []) if c["status"] == "pass"]
            if passed:
                print("      checks passed: %s" % ", ".join(passed))
            for w in rec.get("warnings", []):
                print("      !! %s" % w)
            if rec.get("why"):
                print("      why: %s" % rec["why"])
            if rec.get("fatal"):
                print("      FATAL: %s — stopping, a surviving Godot starves every later run"
                      % rec["fatal"])
                break
        if not args.dry_run and len(views) > 1:
            hall_recs = [r for r in results if r.get("hall") == key]
            dup = cross_view_check(hall_recs, os.path.join(OUT_ROOT, slug(
                row.get("chapter", ""), row.get("pearl", ""))))
            for a, b, pct in dup:
                print("  !!!  %s and %s are THE SAME PICTURE (%.2f%% of pixels differ). "
                      "Three cameras, one frame — the sidecar describes a camera that did "
                      "not take it." % (a, b, pct))
            hit = {v for a, b, _ in dup for v in (a, b)}
            for r in hall_recs:
                if r.get("view") in hit and r.get("ok"):
                    demote(r, "IDENTICAL to another view of the same hall")
        print()

    if args.dry_run:
        print("result   dry run — %d view(s) planned, nothing booted" % len(results))
        return 0

    # THE LEDGER AFTER THE RUN, FOR THE RECORD ONLY. Nothing above was checked
    # against this; it is printed so a reader can see that the file did move,
    # and therefore why cross-checking after a shoot would be self-confirming.
    moved = ledger_moved([k for k, _ in targets])
    print("ledger   after the run: sha1 %s%s" % (
        moved["sha1_12"],
        "  (CHANGED from %s — the run rewrote it, as expected)" % SNAP.get("sha1_12")
        if moved["file_changed"] else "  (unchanged)"))
    for k, r in targets:
        was = r.get("built_at")          # the SNAPSHOT row, still in memory
        now = moved["rows"].get(k, {}).get("built_at_now")
        print("         %s built_at %s -> %s%s" % (k, was, now,
              "   <-- moved under us" if was != now else ""))
    print("         every number above was compared against the SNAPSHOT, not against this.")

    print("index    %s" % os.path.relpath(build_index(), REPO))
    done = [r for r in results if r.get("ok")]
    blindish = [r for r in done if not r.get("coverage_declared")]
    refused = [r for r in results if not r.get("ok") and not r.get("skipped")]
    disputed = [r for r in results if (r.get("dispute") or {}).get("hard")]
    print("result   %d of %d view(s) landed; %d of those with coverage UNMEASURED; %d refused"
          % (len(done), len(results), len(blindish), len(refused)))
    for r in refused:
        print("         REFUSED %-4s %s" % (r.get("view"), r.get("why", "")))
    if disputed:
        print("         %d view(s) DISPUTED: the engine's inventory and the ledger row are"
              % len(disputed))
        print("         not describing the same set of bodies, so no coverage number on")
        print("         those frames answers a question anybody can state. This is the")
        print("         failure the old totals-only guard could not have.")
    if blindish:
        print("         a view with unmeasured coverage is not a verified view — its blind")
        print("         spots are undeclared, so neither presence nor absence in it counts.")
    return 0 if len(done) == len(results) else 1


if __name__ == "__main__":
    sys.exit(main())
