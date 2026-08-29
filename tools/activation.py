#!/usr/bin/env python3
"""How activated is each sequence — does the visitor do a verb, or only look?

2026-08-29, Palle: "How can we activate each sequence in the same manner? ...
does all have activation ... how do we see change in the different sequences,
how do we get activated."

ACTIVATION is not interactivity. An artifact that varies between placements was
CONFIGURED by the map author; an artifact the visitor can turn a knob on has been
TOUCHED. Neither is what makes trace, constructcube and the transformation bench
feel alive. The rule those three share is sharper:

    the visitor supplies something the algorithm did not have,
    and the algorithm answers with something the visitor could not have supplied.

    trace          position  ->  derivative   (you walk; it hands back velocity)
    constructcube  corner    ->  invariant    (you deform it; the topology holds)
    transformation detent    ->  verdict      (you turn it; it says "commutes")

THE LADDER, and every rung is decided by a grep so the number can be argued with:

    0 inert       a mesh and nothing else
    1 configured  apply_grid_config only. It varies. It does not answer anyone.
    2 touched     a control the visitor operates; one parameter moves
    3 driven      the visitor's hand or body becomes an ELEMENT of the array the
                  algorithm iterates. Not a parameter — a datum.
    4 authored    what the visitor made LEAVES the artifact and is READ elsewhere

RUNG 4 NEEDS A READER, and the clause is not optional. flower_lab writes
user://flower_lab_preset_<timestamp>.json, prints "Preset saved!", and nothing in
the repo ever reads that path. Every stage green, and the visitor authored
nothing. Requiring a reader IN A DIFFERENT FILE cuts the corpus's rung-4 count
from 14 tokens to 8 — see --rung4 for the list and which of them are self-loops.

    python tools/activation.py                  # the spine, one row per sequence
    python tools/activation.py --sequence=noise # one sequence, artifact by artifact
    python tools/activation.py --rung4          # who authors, and who only saves
    python tools/activation.py --json
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPINE = os.path.join(ROOT, "commons", "maps", "curriculum_spine.json")
SEQ_DIR = os.path.join(ROOT, "commons", "maps", "sequences")
MAP_DIR = os.path.join(ROOT, "commons", "maps")
REG_DIR = os.path.join(ROOT, "commons", "artifacts", "registry")

#: A control the visitor operates. Deliberately broad — being liftable counts as
#: touching, which is why every grabbable prop lands on rung 2 and not above it.
TOUCH = re.compile(
    r"InteractableArea|\bbutton_pressed\b|\bslider_moved\b|is_button_pressed"
    r"|_on_body_entered|func _input\s*\(|func _unhandled_input\s*\("
    r"|XRToolsPickable|\bpicked_up\b|\bdropped\b")

#: RUNG 3 IS A CONJUNCTION, and that is what separates it from rung 2. The hand
#: has to be a SOURCE of data (left) and that data has to reach a container the
#: algorithm iterates (right). Either half alone is a knob.
DRIVE_SRC = re.compile(
    r"XROrigin3D|xr_origin|GRAB_SPHERE|HANDLE_SCENE|grab_sphere_point"
    r"|_grab_point|_draw_sphere|get_camera_3d\s*\(\s*\)")
DRIVE_SINK = re.compile(
    r"(_?(trail_)?points|vertices|_pts|samples|handles|nodes|seeds|_loop)\s*\.\s*append\s*\("
    r"|_handles_changed|_update_geometry_from_handles|_rebuild_(trail|mesh|final_mesh|ghost)")

#: What the visitor made leaving the artifact. The READER is checked separately.
AUTHOR_OUT = re.compile(
    r"/root/TraceData|TraceData\.|add_trace|save_pattern|MAP_SAVE_URL"
    r"|FileAccess\.open\([^)]*WRITE")
CONFIGURED = re.compile(r"func apply_grid_config")


def registry() -> dict:
    """token -> script path on disk, from every registry file."""
    out: dict[str, str] = {}
    for path in glob.glob(os.path.join(REG_DIR, "*.json")):
        try:
            with open(path, encoding="utf-8") as fh:
                doc = json.load(fh)
        except Exception:
            continue
        # SHAPE, MEASURED: {"artifacts": {token: {...}}}. The first version read
        # the top level as token -> entry, found nothing anywhere, and printed a
        # table of clean zeros for all 22 sequences. A survey that says "nothing
        # is activated" is exactly as wrong-looking as the truth, which is the
        # whole reason this file argues for greps you can re-run.
        doc = doc.get("artifacts", doc) if isinstance(doc, dict) else {}
        for token, entry in (doc.items() if isinstance(doc, dict) else []):
            if token.startswith("_") or not isinstance(entry, dict):
                continue
            scene = str(entry.get("scene") or entry.get("path") or "")
            if not scene:
                continue
            gd = scene.replace("res://", "").replace(".tscn", ".gd")
            full = os.path.join(ROOT, gd.replace("/", os.sep))
            if os.path.exists(full):
                out[token] = full
    return out


def sequence_tokens(name: str) -> tuple[list, list]:
    """Every interactable token this sequence's maps place, and the map names."""
    path = os.path.join(SEQ_DIR, name + ".json")
    if not os.path.exists(path):
        return [], []
    with open(path, encoding="utf-8") as fh:
        doc = json.load(fh)
    # SHAPE: {"sequences": {<name>: {..., "maps": [...]}}}. deferred_maps are
    # deliberately excluded — a sequence is not answerable for a hall it has not
    # dealt yet.
    inner = ((doc.get("sequences") or {}).get(name)
             if isinstance(doc.get("sequences"), dict) else None) or doc
    maps: list = [str(m) for m in (inner.get("maps") or []) if isinstance(m, str)]
    toks: list[str] = []
    for m in [x for x in maps if x]:
        mp = os.path.join(MAP_DIR, m, "map_data.json")
        if not os.path.exists(mp):
            continue
        try:
            with open(mp, encoding="utf-8") as fh:
                md = json.load(fh)
        except Exception:
            continue
        for row in ((md.get("layers") or {}).get("interactables") or []):
            for cell in (row if isinstance(row, list) else []):
                s = str(cell).strip()
                if not s or s == "0":
                    continue
                toks.append(s.split("#")[0].split(":")[0])
    return toks, [x for x in maps if x]


def rung_of(src: str, path: str, authored_readers: set) -> int:
    if AUTHOR_OUT.search(src) and path in authored_readers:
        return 4
    if DRIVE_SRC.search(src) and DRIVE_SINK.search(src):
        return 3
    if TOUCH.search(src):
        return 2
    if CONFIGURED.search(src):
        return 1
    return 0


def authored_with_readers(reg: dict) -> tuple[set, list]:
    """Which producers are actually READ somewhere else. The whole rung.

    A producer whose only reader is itself has authored nothing: the visitor's
    work went into a file and stopped. Reported, not silently dropped.
    """
    producers = {}
    for token, path in reg.items():
        try:
            src = open(path, encoding="utf-8", errors="replace").read()
        except Exception:
            continue
        if AUTHOR_OUT.search(src):
            producers[path] = token
    # what does each producer write that another file could read?
    real, self_loop = set(), []
    corpus = {}
    for path in set(reg.values()):
        try:
            corpus[path] = open(path, encoding="utf-8", errors="replace").read()
        except Exception:
            pass
    for path, token in producers.items():
        src = corpus.get(path, "")
        keys = set(re.findall(r"user://([A-Za-z0-9_\-.]+)", src))
        keys |= {"TraceData"} if re.search(r"TraceData", src) else set()
        found = False
        for other, osrc in corpus.items():
            if other == path:
                continue
            for k in keys:
                base = k.split(".")[0].rstrip("0123456789_-")
                if base and base in osrc:
                    found = True
                    break
            if found:
                break
        (real.add(path) if found else self_loop.append((token, sorted(keys)[:2])))
    return real, self_loop


def survey() -> dict:
    with open(SPINE, encoding="utf-8") as fh:
        spine = json.load(fh)["spine"]["sequences"]
    reg = registry()
    readers, self_loops = authored_with_readers(reg)
    cache: dict[str, int] = {}
    rows = []
    for s in sorted(spine, key=lambda x: int(x.get("order", 0))):
        name = str(s.get("name"))
        toks, maps = sequence_tokens(name)
        counts = [0, 0, 0, 0, 0]
        unresolved = 0
        per: dict[str, int] = {}
        for t in toks:
            path = reg.get(t)
            if path is None:
                unresolved += 1
                continue
            if path not in cache:
                try:
                    cache[path] = rung_of(open(path, encoding="utf-8", errors="replace").read(), path, readers)
                except Exception:
                    cache[path] = 0
            counts[cache[path]] += 1
            per[t] = cache[path]
        placed = sum(counts)
        rows.append({
            "sequence": name, "order": int(s.get("order", 0)), "phase": str(s.get("phase", "")),
            "maps": len(maps), "placed": placed, "unresolved": unresolved,
            "rungs": counts,
            "activated": round(100.0 * (counts[2] + counts[3] + counts[4]) / placed, 1) if placed else 0.0,
            "driven": round(100.0 * (counts[3] + counts[4]) / placed, 1) if placed else 0.0,
            "tokens": per,
        })
    return {"sequences": rows, "self_loops": self_loops, "authored_files": len(readers)}


def main() -> int:
    ap = argparse.ArgumentParser(description="how activated is each sequence")
    ap.add_argument("--sequence", default="")
    ap.add_argument("--rung4", action="store_true", help="who authors, and who only saves")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()
    d = survey()

    if a.json:
        json.dump(d, sys.stdout, ensure_ascii=False)
        sys.stdout.write("\n")
        return 0

    if a.rung4:
        print("RUNG 4 NEEDS A READER\n")
        print("  %d producer file(s) are read by some other file — those author something." % d["authored_files"])
        print("  These write and are never read. The visitor's work went in and stopped:\n")
        for token, keys in d["self_loops"]:
            print("    %-34s writes %s" % (token, ", ".join(keys) or "(a file)"))
        return 0

    rows = d["sequences"]
    if a.sequence:
        r = next((x for x in rows if x["sequence"] == a.sequence), None)
        if r is None:
            raise SystemExit("no spine sequence %s" % a.sequence)
        print("%s — %d maps, %d placements (%d unresolved)\n" % (
            r["sequence"], r["maps"], r["placed"], r["unresolved"]))
        names = ["inert", "configured", "touched", "driven", "authored"]
        for tok, rung in sorted(r["tokens"].items(), key=lambda kv: (-kv[1], kv[0])):
            print("  %d %-10s %s" % (rung, names[rung], tok))
        return 0

    print("ACTIVATION ACROSS THE SPINE\n")
    print("  %-22s %-12s %5s  %5s %5s %5s %5s %5s   %7s %7s" % (
        "sequence", "phase", "place", "inert", "conf", "touch", "driv", "auth", "activ", "driven"))
    print("  " + "-" * 92)
    tot = [0, 0, 0, 0, 0]
    for r in rows:
        c = r["rungs"]
        for i in range(5):
            tot[i] += c[i]
        print("  %-22s %-12s %5d  %5d %5d %5d %5d %5d   %6.1f%% %6.1f%%" % (
            r["sequence"][:22], r["phase"][:12], r["placed"], c[0], c[1], c[2], c[3], c[4],
            r["activated"], r["driven"]))
    print("  " + "-" * 92)
    n = sum(tot)
    print("  %-22s %-12s %5d  %5d %5d %5d %5d %5d   %6.1f%% %6.1f%%" % (
        "ALL", "", n, tot[0], tot[1], tot[2], tot[3], tot[4],
        100.0 * (tot[2] + tot[3] + tot[4]) / n if n else 0,
        100.0 * (tot[3] + tot[4]) / n if n else 0))
    print()
    print("  A rung-2 control plus a VERDICT beats a rung-3 control plus a picture.")
    print("  The transformation bench turns a knob and the room says 'commutes'.")
    print("  That is the cheapest upgrade available to every sequence here.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
