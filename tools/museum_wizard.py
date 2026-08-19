#!/usr/bin/env python3
"""The museum wizard's engine — the spatial chain, staged so a human can watch it.

`tools/wizard_compose.py` does this for a GROWN map: you pick a cast, the composer
grows rooms around each body, and `/map-wizard` shows every intermediate product.
That wizard cannot do museums, and the reason is not a missing feature — its unit
of placement is a cell in a room it invented, and a museum's unit is a SLOT in a
building somebody else authored. See doc/reports/museum_wizard.md.

So this is the sibling engine, over the chain doc/SPATIAL_PIPELINE.md already names:

    brief        tools/exhibition_brief.py      order and kinship, no coordinates
    staging      tools/emit_dressing_room.py    each body's dressing room
    building     tools/spatial_floorplan.py     one of 30 authored museums
    negotiate    tools/spatial_negotiation.py   slot/rotation/mode, or a refusal
    lineage      spatial_negotiation.hang_run   DNA runs as rows on walls
    export       tools/export_museum_plan.py    ada_run/em_plan.json
    assemble     commons/scenes/endless_museum.gd --em-plan
    publish      tools/publish_iteration.py     -> /spatial-iterations

NOTHING HERE RE-IMPLEMENTS A STAGE. Every stage calls the tool that owns it and
reports what came back. A second placement algorithm inside a viewer is exactly
the failure doc/SPATIAL_PIPELINE.md §0 is about, so the only logic this file adds
is (a) which entries of the brief become the floor cast, and (b) drawing.

Read-only by default. `--apply=<step>` is the only thing that touches the world,
and every applying step shoots a BEFORE frame first and an AFTER frame second.

    python tools/museum_wizard.py --museum=uffizi-spine-enfilade --count=8
    python tools/museum_wizard.py --spec-file=spec.json --out=out.json
    python tools/museum_wizard.py --spec-file=spec.json --apply=export --out=out.json
    python tools/museum_wizard.py --spec-file=spec.json --apply=assemble --out=out.json
    python tools/museum_wizard.py --spec-file=spec.json --apply=publish --out=out.json
    python tools/museum_wizard.py --spec-file=spec.json --save=Uffizi_First
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

from emit_dressing_room import ROOMS_DIR, build as build_room, is_authored, staged
from exhibition_brief import KIND_RULE, brief_for, load as _load, spine_order
from spatial_floorplan import PATTERNS, VOID, WALL, from_museum
from spatial_negotiation import Occupancy, hang_run, run as negotiate_run

RELATIONS = REPO / "commons" / "data" / "artifact_relations.json"
EM_PLAN = REPO / "ada_run" / "em_plan.json"
RECIPES = REPO / "commons" / "data" / "museum_recipes"
RUNS = REPO / "ada_run" / "museum_wizard"
GODOT = Path(os.environ.get("GODOT_EXE",
                            "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"))

#: The apron export_museum_plan.py uses. Named once here and passed down rather
#: than re-typed, because a wizard that plans with a different apron than the
#: exporter would show a plan the museum never receives.
APRON = 14

STEPS: list[dict[str, Any]] = [
    {"op": "brief",     "n": "1", "title": "Brief",
     "sub": "order and kinship — no coordinates", "world": False},
    {"op": "staging",   "n": "2", "title": "Staging",
     "sub": "one dressing room per body", "world": True},
    {"op": "building",  "n": "3", "title": "Building",
     "sub": "one of 30 authored museums, received not grown", "world": False},
    {"op": "negotiate", "n": "4", "title": "Negotiation",
     "sub": "slot · rotation · mode — or a refusal with its reason", "world": False},
    {"op": "lineage",   "n": "5", "title": "Lineage",
     "sub": "DNA runs hung as rows on walls", "world": False},
    {"op": "export",    "n": "6", "title": "Plan",
     "sub": "ada_run/em_plan.json — what the museum receives", "world": True},
    {"op": "assemble",  "n": "7", "title": "Assembly",
     "sub": "endless_museum.gd stamps it · before = the blind dealer", "world": True},
    {"op": "publish",   "n": "8", "title": "Publish",
     "sub": "iteration + recipe", "world": True},
]

DEFAULT_SPEC: dict[str, Any] = {
    "museum": "uffizi-spine-enfilade",
    "anchors": [],
    "count": 8,
    "relations": 2,
    "include_relations": True,
    "dna_cap": 6,
    "segments": 2,
    "shot_at": None,
}


# ── the brief ───────────────────────────────────────────────────────

def stage_brief(spec: dict[str, Any]) -> dict[str, Any]:
    """Whose exhibition this is. The only stage that reasons about MEANING."""
    rel = _load(RELATIONS).get("artifacts", {})
    graph_doc = _load(REPO / "commons" / "data" / "museum_relational_graph.json")
    graph = graph_doc.get("artifacts", {})
    anchors = [a for a in spec.get("anchors") or [] if a]
    if not anchors:
        seen: set[str] = set()
        for row in spine_order():
            tok = str(row.get("lookup", ""))
            if tok in rel and tok not in seen:
                anchors.append(tok)
                seen.add(tok)
            if len(anchors) >= int(spec.get("count", 8)):
                break

    briefs = [brief_for(a, rel, int(spec.get("relations", 2)),
                        int(spec.get("dna_cap", 6)), graph) for a in anchors]

    # THE ONE DECISION THIS FILE MAKES, and it is shown rather than buried:
    # features and their relations go to the FLOOR as bodies; dna_variants do
    # NOT. A variant is the same scene at a different value, so five of them on
    # the floor is five copies of one object taking five slots. They are a
    # lineage, and exhibition_brief.match_runs_on_walls already routes a lineage
    # to a wall — stage 5 does that, from the same brief.
    cast: list[str] = []
    entries: list[dict[str, Any]] = []
    for b in briefs:
        for e in b["entries"]:
            tok = e.get("lookup_name")
            row = {
                "lookup": tok,
                "anchor": b["anchor"],
                "role": e["role"],
                "kind": (e.get("relation") or {}).get("kind"),
                "rule": (e.get("relation") or {}).get("rule", ""),
                "why": e.get("why", ""),
                "dna": e.get("dna"),
                "config": e.get("config") or {},
            }
            on_floor = e["role"] in ("feature", "related", "synthesis")
            if e["role"] == "related" and not spec.get("include_relations", True):
                on_floor = False
            row["on_floor"] = on_floor
            if on_floor and tok and tok not in cast:
                cast.append(tok)
            elif on_floor and tok in cast:
                row["on_floor"] = False
                row["why"] = (row["why"] or "") + " (already in the cast)"
            entries.append(row)

    return {
        "op": "brief",
        "anchors": [b["anchor"] for b in briefs],
        "entries": entries,
        "cast": cast,
        "kind_rules": KIND_RULE,
        "dna_runs": [{"anchor": b["anchor"], **b["dna_run"]}
                     for b in briefs if b.get("dna_run")],
        "unknown": [b["anchor"] for b in briefs if not b["known_to_relations"]],
        "why": (f"{len(briefs)} anchors -> {len(cast)} bodies for the floor; "
                f"{sum(1 for b in briefs if b.get('dna_run'))} lineages for the walls"),
    }


# ── staging ─────────────────────────────────────────────────────────

def _room_row(lookup: str) -> dict[str, Any]:
    contract, room = staged(lookup)
    on_disk = (ROOMS_DIR / f"{lookup}.json").exists()
    footing = (room.get("footing") or {}).get("tiles") or [[1]]
    return {
        "lookup": lookup,
        "on_disk": on_disk,
        "authored": is_authored(lookup),
        "generated": bool(room.get("_generated")),
        "footprint_cells": list(contract.footprint_cells),
        "body_m": [round(v, 2) for v in contract.body_m],
        "support": contract.required_support,
        "preferred_mode": contract.preferred_mode,
        "modes": list(contract.modes),
        "rotations": list(contract.rotations),
        "authored_rotation": contract.authored_rotation,
        "clearance": dict(contract.clearance),
        "wall_allowed": bool(contract.wall_allowed),
        "importance": contract.importance,
        "footing_height": max((max(r) for r in footing if r), default=1),
        "approach": str(room.get("approach") or ""),
        "exit": str(room.get("exit") or ""),
        "posture": str(room.get("posture") or ""),
        "grade": str(room.get("production_grade") or ""),
    }


def stage_staging(spec: dict[str, Any], brief: dict[str, Any]) -> dict[str, Any]:
    rows = [_room_row(t) for t in brief["cast"]]
    missing = [r["lookup"] for r in rows if not r["on_disk"]]
    return {
        "op": "staging",
        "rooms": rows,
        "missing": missing,
        "authored": sum(1 for r in rows if r["authored"]),
        "generated": sum(1 for r in rows if r["generated"]),
        "world": True,
        "world_action": (f"write {len(missing)} generated dressing room(s) to "
                         f"commons/artifacts/dressing_rooms/"),
        "why": ("an authored room is never overwritten; a missing one is derived "
                "from the measured body and written so the next run reads a file, "
                "not a fallback"),
    }


# ── the building ────────────────────────────────────────────────────

def stage_building(spec: dict[str, Any]) -> tuple[dict[str, Any], Any]:
    key = spec.get("museum") or DEFAULT_SPEC["museum"]
    plan = from_museum(key, apron=APRON)
    pats = json.loads(PATTERNS.read_text(encoding="utf-8"))["patterns"]
    tile = pats[key]["tile"]
    stage = {
        "op": "building",
        "museum": key,
        "label": pats[key].get("label", key),
        "width": plan.width, "depth": plan.depth,
        "tile_w": len(tile[0]), "tile_h": len(tile),
        "apron": APRON,
        "grid": [[str(c) for c in row] for row in plan.grid],
        "slots": [s.as_dict() for s in plan.slots],
        "walls": [{"id": w.id, "side": w.side, "bay": w.bay,
                   "length_m": round(w.length_m, 1), "height_m": w.height_m,
                   "origin_cell": list(w.origin_cell), "normal": list(w.normal)}
                  for w in plan.walls],
        "spawn": list(plan.spawn), "exit": list(plan.exit),
        "route": [list(c) for c in sorted(plan.route)],
        "expandable": plan.expandable,
        "why": (f"{len(plan.slots)} authored slots, {len(plan.walls)} wall surfaces, "
                f"a {APRON}-cell apron of grounds. expandable={plan.expandable} — "
                f"widening an authored museum to fit a body is not placement"),
    }
    return stage, plan


# ── negotiation ─────────────────────────────────────────────────────

def stage_negotiate(plan: Any, cast: list[str]) -> tuple[dict[str, Any], list, Occupancy]:
    _, placements, occ = negotiate_run(list(cast), plan=plan)
    rows: list[dict[str, Any]] = []
    for p in placements:
        d = p.as_dict()
        d["tile_cell"] = [d["anchor_cell"][0] - APRON, d["anchor_cell"][1] - APRON]
        d["failed_rule"] = next(
            (f"{t.rule}: {t.detail}" for t in reversed(p.traces) if t.status == "fail"),
            "")
        d["compromises"] = [f"{t.rule}: {t.detail}" for t in p.traces
                            if t.status == "compromised"]
        d["footprint"] = (list(p.contract.footprint_cells) if p.contract else [1, 1])
        rows.append(d)
    acc = [r for r in rows if r["result"] == "ACCEPT"]
    return ({
        "op": "negotiate",
        "placements": rows,
        "accepted": len(acc),
        "rejected": len(rows) - len(acc),
        "interior": sum(1 for r in acc if r["venue"] == "interior"),
        "venues": sorted({r["venue"] for r in acc}),
        "why": (f"{len(acc)}/{len(rows)} placed, {sum(1 for r in acc if r['venue'] == 'interior')} "
                f"inside the building; the rest went to the venue the building could offer"),
    }, placements, occ)


# ── lineage on walls ────────────────────────────────────────────────

def stage_lineage(plan: Any, brief: dict[str, Any], occ: Occupancy) -> dict[str, Any]:
    rows: list[dict[str, Any]] = []
    for run_row in brief["dna_runs"]:
        r = hang_run(plan, run_row["anchor"], run_row["axis"],
                     list(run_row["values"]), occ)
        rows.append({
            "anchor": run_row["anchor"], "axis": run_row["axis"],
            "values": list(run_row["values"]),
            "wall": r.wall, "housed": r.result == "ACCEPT",
            "rects_uv": r.rects, "world": r.world,
            "why": next((t.detail for t in reversed(r.traces) if t.status == "fail"),
                        (r.traces[0].detail if r.traces else "")),
        })
    housed = sum(1 for r in rows if r["housed"])
    return {
        "op": "lineage", "runs": rows, "housed": housed,
        "walls_in_museum": len(plan.walls),
        "why": (f"{housed}/{len(rows)} lineages found a wall long enough. "
                f"A run is a row on a wall, not a floor series — the corpus offers "
                f"36 floor series against 481 anchors that declare a run"),
    }


# ── the plan ────────────────────────────────────────────────────────

def stage_export(spec: dict[str, Any], neg: dict[str, Any]) -> dict[str, Any]:
    key = spec.get("museum")
    on_disk: dict[str, Any] = {}
    if EM_PLAN.exists():
        try:
            on_disk = json.loads(EM_PLAN.read_text(encoding="utf-8"))
        except Exception:
            on_disk = {}
    prev = (on_disk.get("museums") or {}).get(key) or {}
    prev_tokens = {a["token"] for a in prev.get("artifacts", [])}
    now_tokens = {p["artifact"] for p in neg["placements"] if p["result"] == "ACCEPT"}
    return {
        "op": "export",
        "path": "ada_run/em_plan.json",
        "museum": key,
        "exists": EM_PLAN.exists(),
        "museums_on_disk": sorted((on_disk.get("museums") or {}).keys()),
        "previous": {"placed": len(prev.get("artifacts", [])),
                     "rejected": len(prev.get("rejected", [])),
                     "interior": prev.get("interior_count", 0)},
        "next": {"placed": len(now_tokens), "rejected": neg["rejected"],
                 "interior": neg["interior"]},
        "added": sorted(now_tokens - prev_tokens),
        "removed": sorted(prev_tokens - now_tokens),
        "world": True,
        "world_action": (f"rewrite the '{key}' entry of ada_run/em_plan.json "
                         f"(other museums in the file are left alone)"),
        "why": ("the museum is a dealer and stays one — it consumes resolved "
                "cells, it does not solve. A museum key absent from this file "
                "deals exactly as it did before"),
    }


# ── assembly + publish ──────────────────────────────────────────────

def _run_dir(spec: dict[str, Any]) -> Path:
    return RUNS / str(spec.get("museum") or "unknown")


def stage_assemble(spec: dict[str, Any]) -> dict[str, Any]:
    d = _run_dir(spec)
    before, after = d / "assemble_before.png", d / "assemble_after.png"
    return {
        "op": "assemble",
        "dir": str(d.relative_to(REPO)),
        "before": str(before.relative_to(REPO)) if before.exists() else None,
        "after": str(after.relative_to(REPO)) if after.exists() else None,
        "before_bytes": before.stat().st_size if before.exists() else 0,
        "after_bytes": after.stat().st_size if after.exists() else 0,
        "segments": int(spec.get("segments", 2)),
        "world": True,
        "world_action": ("boot endless_museum.gd twice for this museum — once "
                         "WITHOUT --em-plan (the blind dealer) and once WITH it"),
        "why": ("the before frame is not a mock-up: it is the same building "
                "stamped by the dealer that shipped, so the difference in the "
                "two images is exactly what the negotiator bought"),
    }


def stage_publish(spec: dict[str, Any]) -> dict[str, Any]:
    ency = Path("C:/Users/palle/Documents/GitHub/ada_encyclopedia")
    manifest = ency / "public" / "spatial-iterations" / "index.json"
    iters: list[dict[str, Any]] = []
    if manifest.exists():
        try:
            iters = json.loads(manifest.read_text(encoding="utf-8")).get("iterations", [])
        except Exception:
            pass
    mine = [i for i in iters if str(i.get("label", "")).startswith("museum-wizard")]
    d = _run_dir(spec)
    shots = sorted(p.name for p in d.glob("*.png")) if d.is_dir() else []
    recipes = sorted(p.stem for p in RECIPES.glob("*.json")) if RECIPES.is_dir() else []
    return {
        "op": "publish",
        "ready": shots,
        "iterations": len(iters),
        "mine": [{"slug": i["slug"], "label": i["label"], "at": i["at"],
                  "shots": len(i.get("shots", [])), "facts": i.get("facts", {})}
                 for i in mine[:8]],
        "recipes": recipes,
        "url": "http://localhost:3003/spatial-iterations",
        "world": True,
        "world_action": (f"copy {len(shots)} frame(s) into public/spatial-iterations/ "
                         f"as a dated iteration, and stamp the run's numbers on it"),
        "why": ("an iteration is a directory, never an overwrite — a gallery that "
                "shows only the newest frame cannot answer 'did that get better'"),
    }


# ── drawing ─────────────────────────────────────────────────────────

def _font(size: int = 12):
    """A real font if Windows has one; PIL's bitmap default is latin-1 only and
    dies on an em-dash, which is how the first three captions were lost."""
    from PIL import ImageFont
    for f in ("C:/Windows/Fonts/consola.ttf", "C:/Windows/Fonts/arial.ttf"):
        try:
            return ImageFont.truetype(f, size)
        except Exception:
            continue
    return ImageFont.load_default()


def _draw_plan(stage_b: dict[str, Any], placements: list[dict[str, Any]],
               path: Path, title: str, cell: int = 9) -> Path:
    """The building with bodies on it, as a PNG. Used for the export before/after."""
    from PIL import Image, ImageDraw

    grid = stage_b["grid"]
    h, w = len(grid), len(grid[0])
    pad, head = 6, 26
    img = Image.new("RGB", (w * cell + pad * 2, h * cell + pad * 2 + head), (14, 18, 27))
    dr = ImageDraw.Draw(img)
    dr.text((pad, 7), title[:120], fill=(190, 200, 215), font=_font(13))

    colour = {VOID: (14, 18, 27), "1": (52, 60, 76), WALL: (128, 138, 158),
              "1s": (70, 92, 120), "2s": (92, 78, 132), "3s": (120, 78, 118)}
    for z, row in enumerate(grid):
        for x, c in enumerate(row):
            col = colour.get(c, (52, 60, 76))
            if c == VOID:
                continue
            x0, y0 = pad + x * cell, pad + head + z * cell
            dr.rectangle([x0, y0, x0 + cell - 1, y0 + cell - 1], fill=col)

    hot = [(239, 108, 108), (108, 200, 239), (140, 214, 128), (240, 200, 100),
           (200, 140, 240), (240, 160, 100), (110, 226, 210), (238, 130, 190)]
    for i, p in enumerate(placements):
        if p.get("result") != "ACCEPT":
            continue
        fx, fz = p.get("footprint") or [1, 1]
        ax, az = p["anchor_cell"]
        col = hot[i % len(hot)]
        x0, y0 = pad + ax * cell, pad + head + az * cell
        dr.rectangle([x0, y0, x0 + max(1, fx) * cell - 1, y0 + max(1, fz) * cell - 1],
                     fill=col, outline=(255, 255, 255))
    sx, sz = stage_b["spawn"]
    dr.ellipse([pad + sx * cell, pad + head + sz * cell,
                pad + sx * cell + cell, pad + head + sz * cell + cell],
               outline=(90, 230, 160), width=2)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    return path


def _draw_rooms(rows: list[dict[str, Any]], path: Path, title: str) -> Path:
    """Every body's footing, as a strip. Used for the staging before/after."""
    from PIL import Image, ImageDraw

    cell, cw, head = 11, 132, 26
    cols = min(6, max(1, len(rows)))
    rws = (len(rows) + cols - 1) // cols
    ch = 108
    img = Image.new("RGB", (cols * cw + 12, rws * ch + head + 12), (14, 18, 27))
    dr = ImageDraw.Draw(img)
    dr.text((6, 7), title[:150], fill=(190, 200, 215), font=_font(13))
    for i, r in enumerate(rows):
        ox = 6 + (i % cols) * cw
        oy = head + 6 + (i // cols) * ch
        fw, fd = r["footprint_cells"]
        col = ((110, 200, 150) if r["authored"] else
               (108, 160, 226) if r["on_disk"] else (150, 110, 110))
        for z in range(max(1, fd)):
            for x in range(max(1, fw)):
                dr.rectangle([ox + x * cell, oy + z * cell,
                              ox + x * cell + cell - 2, oy + z * cell + cell - 2],
                             fill=col)
        tag = ("authored" if r["authored"] else
               "generated" if r["on_disk"] else "NO FILE — fallback")
        dr.text((ox, oy + ch - 34), r["lookup"][:19], fill=(200, 208, 222), font=_font(11))
        dr.text((ox, oy + ch - 22), f"{fw}x{fd}c  {tag}", fill=(140, 150, 168), font=_font(10))
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    return path


# ── the applying half ───────────────────────────────────────────────

USERDIR = Path("C:/Users/palle/AppData/Roaming/Godot/app_userdata/Ada Research Zero One")


def _shot_log(since: float) -> dict[str, Any]:
    """What the engine SAID about the frame it just took.

    The non-console Godot exe writes nothing to stdout, so the watchdog's pipe
    is empty and the run looks silent. `file_logging/enable_file_logging=true`
    in project.godot means it is not: endless_museum prints its chosen
    standpoint and how many dealt objects that standpoint can see, which is the
    one number that separates 'the plan changed the room' from 'the camera
    moved'. Read from the newest log written after this run started.
    """
    logs = USERDIR / "logs"
    if not logs.is_dir():
        return {}
    # `godot.log` is ALWAYS the run that just finished: Godot rotates the
    # previous one to debug_<stamp>.log at boot, and that rotated file's mtime
    # is the boot instant — newer than `since`, so a plain newest-file search
    # picks the PREVIOUS run's output. That is how the after-shot first came
    # back with no standpoint line while the before-shot had one.
    live = logs / "godot.log"
    newest: Path | None = live if live.exists() and live.stat().st_mtime >= since else None
    if newest is None:
        newest_t = since
        with os.scandir(logs) as it:
            for e in it:
                if not e.name.endswith(".log"):
                    continue
                t = e.stat().st_mtime
                if t >= newest_t:
                    newest, newest_t = Path(e.path), t
    if newest is None:
        return {}
    out: dict[str, Any] = {"log": newest.name}
    for line in newest.read_text(encoding="utf-8", errors="replace").splitlines():
        if "shot composed at" in line:
            out["composed"] = line.split("]", 1)[-1].strip()
        elif "proof shot ->" in line:
            out["saved"] = True
    return out


def _godot_shot(museum: str, out: Path, segments: int, with_plan: bool,
                shot_at: float | None) -> dict[str, Any]:
    """One headless render. Wrapped in the watchdog — the 16-second rule."""
    out.parent.mkdir(parents=True, exist_ok=True)
    if out.exists():
        out.unlink()
    args = [str(GODOT), "--path", str(REPO), "--xr-mode", "off", "--no-window",
            "res://commons/scenes/endless_museum.tscn", "--",
            f"--em-first={museum}", f"--em-shot={out.as_posix()}",
            f"--em-segments={max(1, segments)}"]
    if shot_at is not None:
        args.append(f"--em-shot-at={shot_at}")
    if with_plan:
        args.append("--em-plan")
    # A longer grace than the 45 s default: the museum has to stamp its
    # segments before the shot camera exists, so a capture-sized grace kills a
    # healthy boot. The stall window is what actually catches a hang.
    cmd = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"),
           f"--expect={out}", "--grace=150", "--stall=30", "--"] + args
    t0 = datetime.now()
    mark = t0.timestamp()
    proc = subprocess.run(cmd, cwd=str(REPO), capture_output=True, text=True,
                          timeout=420)
    return {
        "with_plan": with_plan, "out": str(out),
        "ok": out.exists(), "bytes": out.stat().st_size if out.exists() else 0,
        "seconds": round((datetime.now() - t0).total_seconds(), 1),
        "returncode": proc.returncode,
        "tail": (proc.stdout or "")[-700:] + (proc.stderr or "")[-400:],
        "engine": _shot_log(mark),
        "cmd": " ".join(args),
    }


def apply_step(step: str, spec: dict[str, Any], stages: dict[str, Any],
               placements: list[dict[str, Any]]) -> dict[str, Any]:
    """Do the world change for one step, with a BEFORE and an AFTER frame."""
    d = _run_dir(spec)
    d.mkdir(parents=True, exist_ok=True)
    rep: dict[str, Any] = {"step": step, "dir": str(d.relative_to(REPO))}

    if step == "staging":
        rows = stages["staging"]["rooms"]
        _draw_rooms(rows, d / "staging_before.png",
                    f"BEFORE — {sum(1 for r in rows if not r['on_disk'])} of "
                    f"{len(rows)} bodies have no dressing room on disk")
        wrote: list[str] = []
        for r in rows:
            if r["on_disk"]:
                continue
            p = ROOMS_DIR / f"{r['lookup']}.json"
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(json.dumps(build_room(r["lookup"]), indent=2) + "\n",
                         encoding="utf-8")
            wrote.append(r["lookup"])
        after = [_room_row(r["lookup"]) for r in rows]
        _draw_rooms(after, d / "staging_after.png",
                    f"AFTER — {len(wrote)} room(s) derived and written; "
                    f"authored rooms untouched")
        rep |= {"wrote": wrote, "before": "staging_before.png",
                "after": "staging_after.png"}

    elif step == "export":
        b = stages["building"]
        prev = {}
        if EM_PLAN.exists():
            try:
                prev = json.loads(EM_PLAN.read_text(encoding="utf-8"))
            except Exception:
                prev = {}
        key = spec["museum"]
        old = [{"result": "ACCEPT", "anchor_cell": [a["tile_cell"][0] + APRON,
                                                    a["tile_cell"][1] + APRON],
                "footprint": [1, 1]}
               for a in (prev.get("museums", {}).get(key, {}).get("artifacts", []))]
        _draw_plan(b, old, d / "export_before.png",
                   f"BEFORE — em_plan.json holds {len(old)} placement(s) for {key}")

        # Write through the OWNER of this file, not by hand: one writer, one
        # schema. Other museums already in the file are preserved.
        museums = dict(prev.get("museums") or {})
        from export_museum_plan import brief_context, plan_museum
        museums[key] = plan_museum(key, list(stages["brief"]["cast"]),
                                   list(stages["brief"]["anchors"]),
                                   brief_context(stages["brief"]))
        EM_PLAN.parent.mkdir(parents=True, exist_ok=True)
        EM_PLAN.write_text(json.dumps({
            "schema": "adaresearch.em_plan.v1",
            "_readme": prev.get("_readme", "Placements resolved by "
                                "tools/spatial_negotiation.py. Read by "
                                "commons/scenes/endless_museum.gd under --em-plan."),
            "_wizard": {"museum": key, "at": datetime.now().isoformat(timespec="seconds"),
                        "cast": stages["brief"]["cast"]},
            "offered": stages["brief"]["cast"],
            "museums": museums,
        }, indent=2) + "\n", encoding="utf-8")
        _draw_plan(b, placements, d / "export_after.png",
                   f"AFTER — {stages['negotiate']['accepted']} negotiated placement(s), "
                   f"{stages['negotiate']['interior']} interior")
        rep |= {"placed": len(museums[key]["artifacts"]),
                "rejected": len(museums[key]["rejected"]),
                "before": "export_before.png", "after": "export_after.png"}

    elif step == "assemble":
        seg = int(spec.get("segments", 2))
        at = spec.get("shot_at")
        rep["before_shot"] = _godot_shot(spec["museum"], d / "assemble_before.png",
                                         seg, False, at)
        rep["after_shot"] = _godot_shot(spec["museum"], d / "assemble_after.png",
                                        seg, True, at)
        rep |= {"before": "assemble_before.png", "after": "assemble_after.png"}

    elif step == "publish":
        label = f"museum-wizard · {spec['museum']}"
        note = (f"{stages['negotiate']['accepted']}/"
                f"{len(stages['negotiate']['placements'])} placed, "
                f"{stages['negotiate']['interior']} interior; "
                f"{stages['lineage']['housed']}/{len(stages['lineage']['runs'])} "
                f"lineages walled. before/after pairs: staging, export, assembly.")
        cmd = [sys.executable, str(REPO / "tools" / "publish_iteration.py"),
               "--label", label, "--from", str(d), "--note", note]
        proc = subprocess.run(cmd, cwd=str(REPO), capture_output=True, text=True,
                              timeout=180)
        rep |= {"returncode": proc.returncode,
                "stdout": proc.stdout[-1200:], "stderr": proc.stderr[-600:],
                "url": "http://localhost:3003/spatial-iterations"}
    else:
        rep["error"] = f"step '{step}' changes nothing in the world"
    return rep


def save_recipe(name: str, spec: dict[str, Any], stages: dict[str, Any]) -> dict[str, Any]:
    """The wizard as memory — same idea as commons/data/wizard_recipes/."""
    RECIPES.mkdir(parents=True, exist_ok=True)
    n = stages["negotiate"]
    rec = {
        "name": name,
        "date": datetime.now().strftime("%Y-%m-%d"),
        "spec": spec,
        "metrics": {
            "cast": len(stages["brief"]["cast"]),
            "placed": n["accepted"],
            "rejected": n["rejected"],
            "interior": n["interior"],
            "interior_share": round(n["interior"] / max(1, n["accepted"]), 3),
            "lineages": len(stages["lineage"]["runs"]),
            "lineages_walled": stages["lineage"]["housed"],
            "rooms_on_disk": sum(1 for r in stages["staging"]["rooms"] if r["on_disk"]),
            "rooms_authored": stages["staging"]["authored"],
        },
        "rejected_why": [{"token": p["artifact"], "why": p["failed_rule"]}
                         for p in n["placements"] if p["result"] != "ACCEPT"],
        "regeneration_warning": (
            "A recipe is not a time capsule. This replays the SPEC, not the "
            "corpus: spine_artifact_order.json, artifact_relations.json, the "
            "dressing rooms and slot_capacity.json all move under it, so the "
            "same spec can deal a different cast into different slots tomorrow. "
            "The metrics above are a receipt of one run, not a guarantee. "
            "(The same drift is confessed in wizard_recipes/Thread_Gate.json.)"),
    }
    p = RECIPES / f"{name}.json"
    p.write_text(json.dumps(rec, indent=1) + "\n", encoding="utf-8")
    return {"saved": str(p.relative_to(REPO)), "recipe": rec}


# ── driver ──────────────────────────────────────────────────────────

def compose(spec: dict[str, Any]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    s = {**DEFAULT_SPEC, **(spec or {})}
    brief = stage_brief(s)
    staging = stage_staging(s, brief)
    building, plan = stage_building(s)
    neg, raw, occ = stage_negotiate(plan, brief["cast"])
    lineage = stage_lineage(plan, brief, occ)
    export = stage_export(s, neg)
    return ({
        "brief": brief, "staging": staging, "building": building,
        "negotiate": neg, "lineage": lineage, "export": export,
        "assemble": stage_assemble(s), "publish": stage_publish(s),
    }, neg["placements"])


def museum_keys() -> list[dict[str, Any]]:
    pats = json.loads(PATTERNS.read_text(encoding="utf-8"))["patterns"]
    out = []
    for k, v in sorted(pats.items()):
        if not v.get("museum"):
            continue
        tile = v.get("tile") or [[]]
        out.append({"key": k, "label": v.get("label", k), "museum": v.get("museum"),
                    "w": len(tile[0]) if tile and tile[0] else 0, "h": len(tile),
                    "walk_rule": v.get("walk_rule", "")})
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--spec-file", default="")
    ap.add_argument("--museum", default="")
    ap.add_argument("--count", type=int, default=0)
    ap.add_argument("--apply", default="", help="staging | export | assemble | publish")
    ap.add_argument("--save", default="")
    ap.add_argument("--out", default="")
    ap.add_argument("--options", action="store_true", help="museums + recipes, then exit")
    args = ap.parse_args()

    if args.options:
        recipes = []
        if RECIPES.is_dir():
            for f in sorted(RECIPES.glob("*.json")):
                try:
                    r = json.loads(f.read_text(encoding="utf-8"))
                    recipes.append({"name": r.get("name", f.stem), "date": r.get("date"),
                                    "spec": r.get("spec"), "metrics": r.get("metrics")})
                except Exception:
                    pass
        payload = {"museums": museum_keys(), "steps": STEPS, "recipes": recipes,
                   "default_spec": DEFAULT_SPEC}
        (Path(args.out).write_text(json.dumps(payload), encoding="utf-8")
         if args.out else print(json.dumps(payload, indent=1)))
        return 0

    spec = dict(DEFAULT_SPEC)
    if args.spec_file:
        spec |= json.loads(Path(args.spec_file).read_text(encoding="utf-8"))
    if args.museum:
        spec["museum"] = args.museum
    if args.count:
        spec["count"] = args.count

    stages, placements = compose(spec)
    result: dict[str, Any] = {"spec": spec, "steps": STEPS, "stages": stages}

    if args.apply:
        result["applied"] = apply_step(args.apply, spec, stages, placements)
        # the applied step's own panel is now stale — recompose it
        stages2, _ = compose(spec)
        result["stages"] = stages2
    if args.save:
        result["save"] = save_recipe(args.save, spec, result["stages"])

    if args.out:
        Path(args.out).write_text(json.dumps(result), encoding="utf-8")
        return 0

    n = stages["negotiate"]
    print(f"museum   {spec['museum']}")
    print(f"cast     {len(stages['brief']['cast'])} bodies from "
          f"{len(stages['brief']['anchors'])} anchors")
    print(f"rooms    {sum(1 for r in stages['staging']['rooms'] if r['on_disk'])} on disk, "
          f"{len(stages['staging']['missing'])} missing")
    print(f"building {stages['building']['width']}x{stages['building']['depth']} · "
          f"{len(stages['building']['slots'])} slots · "
          f"{len(stages['building']['walls'])} walls")
    print(f"placed   {n['accepted']}/{len(n['placements'])} "
          f"({n['interior']} interior) venues={n['venues']}")
    print(f"lineage  {stages['lineage']['housed']}/{len(stages['lineage']['runs'])} walled")
    for p in n["placements"]:
        mark = "ok " if p["result"] == "ACCEPT" else "REJ"
        print(f"  {mark} {p['artifact']:32s} {str(p['slot'] or '-'):16s} "
              f"rot {p['rotation']:>3} {p['placement_mode']:<14s} {p['venue']}"
              + (f"   {p['failed_rule']}" if p["failed_rule"] else ""))
    if args.apply:
        print(json.dumps(result["applied"], indent=1)[:2000])
    if args.save:
        print(f"recipe -> {result['save']['saved']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
