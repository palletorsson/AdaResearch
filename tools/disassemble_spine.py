#!/usr/bin/env python3
"""Disassemble every artifact of the spine and categorise what it is made of.

Palle, 25 Oct 2026: "can we disassemble to extract the element and categorize every artifact
in the spine?" The scanner (modular_scan.py) read scripts; this runs the artifacts. For each of
the 25 sequences it starts Godot once with commons/testing/disassemble_spine.gd, which
instantiates every placed artifact, lets it build for two frames and reads the elements off
the tree it made — meshes by shape, size and colour; colliders; bodies; joints; lights;
labels; particles; multimeshes; whether a script ticks. A run the 16-second watchdog kills is
charged to the artifact in progress (marked "hang") and the next run resumes past it.

Then the census: identical meshes are folded into "(shape) * n", and each artifact gets a
category from what it is made of —
  point        one small mesh, no body
  line         long and thin
  solid        a body with colliders, few meshes
  array        n ≥ 4 identical meshes (or a multimesh): a replicate
  assemblage   several different meshes
  field        a custom/array mesh or particles — a surface from a function
  engine       a script ticks (on top of the shape category: "array·engine")
  document     labels, screens, viewports, cameras, audio and little else
  empty        nothing built headless (needs a map, a hand, a player)
and an expression in the grammar's notation, as the deconstruct would print it.

    python tools/disassemble_spine.py                 # all sequences (resumes)
    python tools/disassemble_spine.py --seq fractals
    python tools/disassemble_spine.py --report        # only recompute the census from the ledgers

Writes ada_run/disassembly/<seq>.jsonl (the ledgers), commons/data/spine_disassembly.json (the
census) and doc/book/course/SPINE_DISASSEMBLY.md (the tables).
"""
from __future__ import annotations

import argparse
import collections
import json
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GODOT = Path("C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
LEDGERS = ROOT / "ada_run/disassembly"
SPINE = ROOT / "commons/maps/curriculum_spine.json"
SPAWNLISTS = ROOT / "commons/data/void_spawnlists.json"
JSON_OUT = ROOT / "commons/data/spine_disassembly.json"
MD_OUT = ROOT / "doc/book/course/SPINE_DISASSEMBLY.md"
WATCHDOG = ROOT / "tools/godot_watchdog.py"


def spine_names() -> list[str]:
    return [s["name"] for s in sorted(json.loads(SPINE.read_text(encoding="utf-8"))["spine"]["sequences"], key=lambda s: s["order"])]


def run_sequence(seq: str, max_passes: int = 6) -> None:
    """Run Godot for one sequence until it finishes or every hang is charged."""
    LEDGERS.mkdir(parents=True, exist_ok=True)
    ledger = LEDGERS / f"{seq}.jsonl"
    marker = LEDGERS / "_in_progress.txt"
    for p in range(max_passes):
        marker.write_text("", encoding="utf-8")
        cmd = [sys.executable, str(WATCHDOG), f"--expect={ledger}", "--", str(GODOT), "--headless", "--path", str(ROOT), "--xr-mode", "off",
               "--script", "res://commons/testing/disassemble_spine.gd", "--", f"--seq={seq}"]
        t0 = time.time()
        r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
        out = r.stdout + r.stderr
        done_line = [l for l in out.splitlines() if l.startswith("DISASSEMBLE ")]
        if done_line:
            print(f"  {seq}: {done_line[-1]} ({time.time() - t0:.0f}s)")
            return
        # killed: charge the artifact in progress
        try:
            mk = json.loads(marker.read_text(encoding="utf-8") or "{}")
        except json.JSONDecodeError:
            mk = {}
        tok = mk.get("token")
        if tok:
            with ledger.open("a", encoding="utf-8") as f:
                f.write(json.dumps({"token": tok, "scene": mk.get("scene", ""), "ok": False, "error": "hang", "elements": None}) + "\n")
            print(f"  {seq}: watchdog killed the run on {tok} — marked hang, resuming ({time.time() - t0:.0f}s)")
        else:
            # an empty marker means the run finished (the watchdog swallows Godot's last line)
            n = sum(1 for l in ledger.read_text(encoding="utf-8").splitlines() if l.strip()) if ledger.exists() else 0
            print(f"  {seq}: finished — {n} artifacts in the ledger ({time.time() - t0:.0f}s)")
            return


def fold(meshes: list[dict]) -> list[tuple[str, int, list[float]]]:
    """identical meshes (shape + size to the cm) → (shape, n, size)"""
    groups: dict[tuple, list] = collections.OrderedDict()
    for m in meshes:
        key = (m["shape"], tuple(round(v, 2) for v in m["size"]))
        groups.setdefault(key, []).append(m)
    return [(k[0], len(v), list(k[1])) for k, v in groups.items()]


def categorise(row: dict) -> tuple[str, str]:
    e = row.get("elements")
    if not row.get("ok") or e is None:
        # "no scene": the token is not a registry artifact — the Void builds it itself from
        # rooms.json (void_* works, kits, props); it is disassembled by the Void, not here
        return ("hang" if row.get("error") == "hang" else "void-built"), "?"
    meshes, mm = e["meshes"], e["multimesh"]
    n_mesh = len(meshes) + sum(x["count"] for x in mm)
    groups = fold(meshes)
    bodies = sum(e["bodies"].values())
    docs = e["labels"] + e["viewports"] + e["cameras"] + e["audio"]
    engine = bool(e["engine"])
    custom = any(g[0] in ("custom", "array", "immediate", "placeholder") for g in groups) or any(x["shape"] in ("custom", "array") for x in mm)
    b = row.get("bounds") or [0, 0, 0]
    longest, shortest = max(b), min(b) if b else 0
    if n_mesh == 0:
        cat = "document" if docs else "empty"
    elif docs >= 2 and n_mesh <= 3:
        cat = "document"
    elif mm or any(g[1] >= 4 for g in groups):
        cat = "array"
    elif e["particles"] or custom:
        cat = "field"
    elif n_mesh == 1 and longest < 0.5 and bodies == 0:
        cat = "point"
    elif longest > 0 and shortest / longest < 0.08 and n_mesh <= 3:
        cat = "line"
    elif bodies and n_mesh <= 3:
        cat = "solid"
    else:
        cat = "assemblage"
    if engine and cat not in ("document", "empty"):
        cat += "·engine"
    # the expression, as the deconstruct prints it
    parts = []
    for shape, n, size in groups[:6]:
        s = "×".join(f"{v:g}" for v in size)
        parts.append(f"({shape} {s}) * {n}" if n > 1 else f"{shape} {s}")
    if len(groups) > 6:
        parts.append(f"… +{len(groups) - 6} kinds")
    for x in mm:
        parts.append(f"replicate({x['shape']}, {x['count']})")
    expr = " + ".join(parts) or "·"
    if e["colliders"]:
        c = collections.Counter(e["colliders"])
        expr += " + collider(" + ", ".join(f"{k}×{v}" if v > 1 else k for k, v in c.items()) + ")"
    if bodies:
        expr += " + body(" + ", ".join(f"{k}×{v}" if v > 1 else k for k, v in e["bodies"].items()) + ")"
    if e["joints"]:
        expr += f" + connect × {e['joints']}"
    if e["lights"]:
        expr += f" + light × {e['lights']}"
    if e["labels"]:
        expr += f" + label × {e['labels']}"
    if engine:
        expr = f"step({expr})"
    return cat, expr


def census() -> dict:
    sl = json.loads(SPAWNLISTS.read_text(encoding="utf-8"))
    tree = {c["id"]: c for c in sl["trees"][0]["children"]}
    out = {"_doc": "GENERATED by tools/disassemble_spine.py from ada_run/disassembly/*.jsonl — every spine artifact instantiated and read off its tree.",
           "sequences": {}, "artifacts": {}}
    for seq in spine_names():
        ledger = LEDGERS / f"{seq}.jsonl"
        rows = {}
        if ledger.exists():
            for line in ledger.read_text(encoding="utf-8").splitlines():
                if line.strip():
                    r = json.loads(line)
                    rows[r["token"]] = r
        tokens = []
        for m in tree.get(seq, {"children": []})["children"]:
            for t in m["items"]:
                tok = t.split("@")[0]
                if tok not in tokens:
                    tokens.append(tok)
        cats = collections.Counter()
        shapes = collections.Counter()
        elements = collections.Counter()
        for tok in tokens:
            r = rows.get(tok)
            if r is None:
                cats["not run"] += 1
                continue
            cat, expr = categorise(r)
            cats[cat.split("·")[0]] += 1
            if "engine" in cat:
                cats["·engine"] += 1
            e = r.get("elements") or {}
            for m in e.get("meshes", []):
                shapes[m["shape"]] += 1
            for mm in e.get("multimesh", []):
                shapes[mm["shape"] + " (multimesh)"] += mm["count"]
            elements["meshes"] += len(e.get("meshes", []))
            elements["colliders"] += len(e.get("colliders", []))
            elements["bodies"] += sum(e.get("bodies", {}).values())
            elements["joints"] += e.get("joints", 0)
            elements["lights"] += e.get("lights", 0)
            elements["labels"] += e.get("labels", 0)
            elements["particles"] += e.get("particles", 0)
            out["artifacts"][tok] = {"sequence": seq, "category": cat, "expr": expr, "bounds": r.get("bounds"), "nodes": e.get("nodes", 0),
                                     "scripts": e.get("scripts", []), "error": r.get("error")}
        out["sequences"][seq] = {"artifacts": len(tokens), "run": sum(1 for t in tokens if t in rows), "categories": dict(cats),
                                 "shapes": dict(shapes.most_common(8)), "elements": dict(elements)}
    return out


def render(c: dict) -> str:
    L = ["# The spine, disassembled\n",
         "*Generated by `tools/disassemble_spine.py`. Every artifact a spine sequence places was instantiated in Godot "
         "(headless, two frames to build) and its elements read off the tree it made: meshes by shape, size and colour, "
         "colliders, bodies, joints, lights, labels, particles, multimeshes, and whether a script ticks. Identical meshes "
         "fold into `(shape) * n`. The category is read from the elements, not the name. Palle, 25 Oct 2026: \"can we "
         "disassemble to extract the element and categorize every artifact in the spine?\"*\n"]
    tot_art = sum(s["artifacts"] for s in c["sequences"].values())
    tot_run = sum(s["run"] for s in c["sequences"].values())
    cats = collections.Counter()
    for s in c["sequences"].values():
        cats.update(s["categories"])
    L.append(f"**{tot_art} artifacts across the 25 sequences, {tot_run} run.** By what they are made of: " +
             ", ".join(f"{k} {v}" for k, v in cats.most_common() if not k.startswith("·")) +
             f"; {cats.get('·engine', 0)} of them tick (an engine). *void-built* is a token with no registry scene — a "
             "work The Void builds itself from rooms.json (the void_* works, kits, props), which this probe cannot "
             "instantiate alone; *empty* built nothing headless (it waits for a map, a hand or a player); *hang* never "
             "yielded a frame and was killed by the watchdog. In the shape counts, \"(multimesh)\" numbers are instances, "
             "not nodes — a lattice of 600,000 spheres is one node.\n")
    L.append("| # | sequence | artifacts | run | point | line | solid | array | field | assemblage | document | empty | void-built | hang | engine | meshes | colliders | bodies | lights | labels |")
    L.append("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    for i, (seq, s) in enumerate(c["sequences"].items(), 1):
        k = s["categories"]; e = s["elements"]
        L.append(f"| {i} | {seq} | {s['artifacts']} | {s['run']} | {k.get('point', 0)} | {k.get('line', 0)} | {k.get('solid', 0)} | {k.get('array', 0)} | "
                 f"{k.get('field', 0)} | {k.get('assemblage', 0)} | {k.get('document', 0)} | {k.get('empty', 0)} | {k.get('void-built', 0)} | {k.get('hang', 0)} | {k.get('·engine', 0)} | "
                 f"{e.get('meshes', 0)} | {e.get('colliders', 0)} | {e.get('bodies', 0)} | {e.get('lights', 0)} | {e.get('labels', 0)} |")
    L.append("")
    L.append("## What the spine is made of — mesh shapes, all sequences\n")
    shapes = collections.Counter()
    for s in c["sequences"].values():
        shapes.update(s["shapes"])
    L.append(", ".join(f"**{k}** {v}" for k, v in shapes.most_common(12)) + "\n")
    L.append("## Every artifact, disassembled\n")
    for seq, s in c["sequences"].items():
        L.append(f"### {seq}\n")
        L.append("| artifact | category | elements, as the deconstruct prints them | bounds (m) |")
        L.append("|---|---|---|---|")
        for tok, a in c["artifacts"].items():
            if a["sequence"] != seq:
                continue
            b = a["bounds"]
            bs = "×".join(f"{v:g}" for v in b) if b else "—"
            L.append(f"| `{tok}` | {a['category']} | {a['expr'][:140]} | {bs} |")
        L.append("")
    return "\n".join(L)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--seq")
    ap.add_argument("--report", action="store_true")
    a = ap.parse_args()
    if not a.report:
        for seq in ([a.seq] if a.seq else spine_names()):
            run_sequence(seq)
    c = census()
    JSON_OUT.write_text(json.dumps(c, indent=1), encoding="utf-8")
    MD_OUT.write_text(render(c), encoding="utf-8")
    tot = sum(s["run"] for s in c["sequences"].values()); art = sum(s["artifacts"] for s in c["sequences"].values())
    print(f"wrote {MD_OUT.relative_to(ROOT)} + {JSON_OUT.relative_to(ROOT)} — {tot}/{art} artifacts disassembled")
    return 0


if __name__ == "__main__":
    sys.exit(main())
