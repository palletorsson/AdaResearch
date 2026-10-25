#!/usr/bin/env python3
"""The main track and its branches, by capacity.

Palle, 25 Oct 2026: "not every term has to be on the main track … what is the main principle
that we need to flow … a good progression of relevant difference … your own understanding of
distance in the taxonomy of 3D objects." The principle: ONE STEP ON THE MAIN TRACK GIVES THE
THING ONE NEW CAPACITY — one new kind of relation, to space, to the body, to time, to other
things, or to a reader. What only varies a thing (colour, scale, surface, place, how many of
the same) is a branch.

Signatures come from ONE reader for terms and artifacts alike: the disassembly
(ada_run/disassembly/*.jsonl — every mod_ token and every spine artifact instantiated and read
off its tree). What a tree cannot show is read from the term's JSON: the kind of engine
(driven by a function, or reacting) and whether it measures.

  principle axes (the track)                     staging axes (the exhibit wrapper)
  form   0 point · 1 line · 2 surface · 3 solid · 4 field     read   0 mute · 1 label · 2 screen
  body   0 seen · 1 collides · 2 falls · 3 graspable           light  0 · 1 a lamp
  many   0 one · 1 repeated · 2 at scale                       sense  0 · 1 senses the visitor
  parts  0 one kind · 1 a few · 2 many kinds
  joint  0 apart · 1 tied
  drive  0 still · 1 moved by a function of time
  react  0 · 1 obeys physics · 2 decides (a rule turns inputs into an output)
  measure 0 · 1 reads a quantity off things

Gate: each track step must exceed the ENVELOPE (the per-axis maximum of the steps before it)
on exactly one principle axis by exactly one notch — the axis it declares. Falling (body 2)
brings obeying physics (react 1) with it; that pair counts as one capacity.

Branches: every other term and every spine artifact hangs off the track step nearest to it by
principle distance (staging stripped — `exhibit` closes it); a tie goes to the later step.
A thing that exceeds the whole track on some axis hangs off the first HOLE that names that
axis (e.g. field form, waiting for the field operator).

    python tools/capacity_track.py      # writes commons/data/capacity_track.json
    python tools/capacity_track.py --terms=<file>     # gate another terms file; write nothing
    python tools/capacity_track.py --propose=<file> [--note=text]
        # a proposed track (a JSON list of steps, from /tree-of-life): gate it first; only if it
        # passes, write it into terms.json, append it to commons/data/capacity_track_history.jsonl
        # (the track's own lineage: every version it has had) and regenerate the path
"""
from __future__ import annotations

import collections
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TERMS = ROOT / "commons/modular/terms.json"
LEDGERS = ROOT / "ada_run/disassembly"
OUT = ROOT / "commons/data/capacity_track.json"
HISTORY = ROOT / "commons/data/capacity_track_history.jsonl"

PRINCIPLE = ["form", "body", "many", "parts", "joint", "drive", "react", "measure"]
STAGING = ["read", "light", "sense"]
DRIVE_KINDS = {"sine", "sine_field", "noise", "random", "hand"}
REACT_KINDS = {"physics", "trace"}
SOLID_SHAPES = {"box", "sphere", "cylinder", "capsule", "torus", "prism", "cone"}


def signature(row: dict) -> dict:
    """capacities read off an instantiated tree"""
    e = row["elements"]
    s = dict.fromkeys(PRINCIPLE + STAGING, 0)
    meshes, mm = e["meshes"], e["multimesh"]
    b = row.get("bounds") or [0, 0, 0]
    big, small = max(b), min(b)
    mid = sorted(b)[1]
    # a CSG boolean is a surface made by an operation on volumes — the same hole as the isosurface
    csg = any(str(c).startswith("CSG") for c in e.get("classes", {}))
    field = bool(e["particles"]) or csg or any(m.get("tris", 0) > 500 and min(m["size"]) > 0.01 for m in meshes)
    if field:
        s["form"] = 4
    elif not meshes and not mm:
        s["form"] = 0
    elif not meshes:
        # a replicate only: the reader has no bounds for MultiMesh instances (the capture AABB has
        # the same blind spot), so read the form off the replicated shape
        s["form"] = 2 if all(x["shape"] in ("plane", "quad") for x in mm) else 3
    elif big < 0.15 and not e["colliders"] and not e["bodies"]:
        s["form"] = 0                                  # a point: small in every direction, and nothing to touch
                                                       # (a 10 cm sphere you can grab has extent: a small solid)
    elif mid < 0.08 * big:
        s["form"] = 1                                  # a line: long in one direction only
    elif small < 0.03 * big:
        s["form"] = 2                                  # a surface: flat
    else:
        s["form"] = 3
    bodies = e["bodies"]
    pick = any("pickable" in sc.lower() for sc in e.get("scripts", []))
    s["body"] = 3 if pick else 2 if bodies.get("rigid") else 1 if e["colliders"] else 0
    kinds = collections.Counter((m["shape"], tuple(round(v, 2) for v in m["size"])) for m in meshes)
    n_mm = sum(x["count"] for x in mm)
    s["many"] = 2 if n_mm >= 50 or len(meshes) >= 100 else 1 if (mm or any(n >= 4 for n in kinds.values())) else 0
    # a PART is a kind of mesh of comparable size: at least 15 % of the thing's largest extent.
    # A 7 cm point at the end of a metre-long line is a mark, not a component (the gate showed
    # the line "adding" composition when it counted its end points)
    significant = {k for k in kinds if max(k[1]) >= 0.15 * big} if big > 0 else set(kinds)
    nk = len(significant) + len(mm)
    s["parts"] = 2 if nk > 6 else 1 if nk >= 2 else 0
    s["joint"] = 1 if e["joints"] else 0
    if e["engine"]:
        if bodies.get("rigid") or e["particles"]:
            s["react"] = 1
        else:
            s["drive"] = 1
    s["read"] = 2 if (e["viewports"] or e["cameras"]) else 1 if e["labels"] else 0
    s["light"] = 1 if e["lights"] else 0
    s["sense"] = 1 if bodies.get("area") else 0
    return s


def empty(row: dict) -> bool:
    """built nothing a reader can measure in its first two frames: it grows over time, or its
    _ready is gated on a map. Not a point — unread"""
    e = row["elements"]
    return not (e["meshes"] or e["multimesh"] or e["particles"] or any(str(c).startswith("CSG") for c in e.get("classes", {})))


def lack(s: dict, step: dict) -> int:
    """the capacities a step has and the thing does not: a thing that lacks one is a precursor of
    that step, not a variation of it"""
    return sum(max(0, step[k] - s[k]) for k in PRINCIPLE)


def term_overrides(tid: str, terms: dict, s: dict) -> dict:
    """what a tree cannot show: the kind of engine, a decision, a measure"""
    seen: set = set()
    def walk(e):
        if not isinstance(e, dict):
            return
        t = e.get("t")
        if isinstance(t, str) and t in terms and t not in seen:
            seen.add(t); walk(terms[t]["build"])
        op = e.get("op")
        if op == "engine":
            k = str(e.get("kind", ""))
            if k in DRIVE_KINDS: s["drive"] = max(s["drive"], 1)
            if k in REACT_KINDS: s["react"] = max(s["react"], 1)
        if op in ("sort", "measure"):
            s["measure"] = 1
        if e.get("p") == "grabbable":
            s["body"] = 3
        if "of" in e: walk(e["of"])
        for p in e.get("parts", []) or []:
            walk(p.get("of", p) if isinstance(p, dict) else p)
    walk(terms[tid]["build"])
    if terms[tid].get("logic"):
        s["react"] = 2                                 # a machine whose truth table holds: it decides
    return s


def pdist(a: dict, b: dict) -> int:
    return sum(abs(a[k] - b[k]) for k in PRINCIPLE)


def load_rows() -> tuple[dict, dict]:
    terms_rows, art_rows = {}, {}
    for f in sorted(LEDGERS.glob("*.jsonl")):
        for line in f.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            r = json.loads(line)
            if not r.get("ok") or not r.get("elements"):
                continue
            (terms_rows if f.stem == "modular" else art_rows)[r["token"]] = r
    return terms_rows, art_rows


def run(doc: dict, write: bool) -> int:
    terms, track = doc["terms"], doc.get("track", [])
    trows, arows = load_rows()
    if not trows:
        print("no modular ledger — run the disassembler with --seq=modular first"); return 1
    T = {}
    for tok, r in trows.items():
        tid = tok[4:]
        if tid in terms:
            T[tid] = term_overrides(tid, terms, signature(r))
    A = {tok: signature(r) for tok, r in arows.items() if not empty(r)}
    unread = sorted(tok for tok, r in arows.items() if empty(r))

    # the gate
    env = dict.fromkeys(PRINCIPLE, 0)
    steps, gate_ok = [], True
    for i, st in enumerate(track):
        tid = st.get("term")
        row = {"index": i, "term": tid, "adds": st.get("adds"), "axis": st.get("axis"), "hole": st.get("hole")}
        if not tid:
            row["status"] = "hole"
            steps.append(row); continue
        if tid not in T:
            row["status"] = "unread"; gate_ok = False
            steps.append(row); continue
        s = T[tid]
        new = {k: s[k] - env[k] for k in PRINCIPLE if s[k] > env[k]}
        if "body" in new and new.get("react") == 1 and s["body"] >= 2 and env["body"] < 2:
            new.pop("react")                           # falling brings obeying physics with it
        declared = st.get("axis", "")
        want_axis, _, want_n = declared.partition(":")
        if i == 0:
            ok = True
        else:
            ok = len(new) == 1 and list(new.values())[0] == 1 and (not want_axis or want_axis in new) and (not want_n or s[want_axis] == int(want_n))
        row.update(sig=s, envelope=dict(env), new=new, status="ok" if ok else "fails")
        gate_ok = gate_ok and ok
        steps.append(row)
        for k in PRINCIPLE:
            env[k] = max(env[k], s[k])
    track_terms = [st["term"] for st in steps if st.get("status") == "ok" or (st.get("term") and st.get("term") in T)]
    holes = [st for st in steps if st.get("status") == "hole"]

    def hang(s: dict) -> tuple[str, int, list]:
        beyond = [k for k in PRINCIPLE if s[k] > env[k]]
        for h in holes:
            ax = (h.get("axis") or "").partition(":")[0]
            if ax in beyond:
                return f"hole:{h['index']}", sum(max(0, s[k] - env[k]) for k in PRINCIPLE), beyond
        # nearest by notches; a tie goes to the step the thing lacks least of (a variation, not a
        # precursor), then to the later step. Measured 25 Oct: by notches alone 105 physics things
        # with two kinds of part tied between falling_cube and and_gate and all went to the gate
        best = min(((pdist(s, T[t]), lack(s, T[t]), -i, t) for i, t in enumerate(track_terms) if t in T), default=(99, 0, 0, ""))
        return best[3], best[0], beyond          # beyond the track with no hole naming it: nearest, and say so

    out_terms, out_art = {}, {}
    for tid, s in T.items():
        if tid in track_terms:
            out_terms[tid] = {"sig": s, "lane": "track"}
        else:
            node, d, beyond = hang(s)
            out_terms[tid] = {"sig": s, "lane": "branch", "branch_of": node, "distance": d, "beyond": beyond}
    for tok, s in A.items():
        node, d, beyond = hang(s)
        staged = [k for k in STAGING if s[k]]
        out_art[tok] = {"sig": s, "lane": "branch", "branch_of": node, "distance": d, "beyond": beyond, "staged": staged}
    for tok in unread:
        out_art[tok] = {"lane": "unread", "why": "built nothing measurable in its first two frames (grows over time, or gated on a map)"}
    hung = [v for v in out_art.values() if v["lane"] == "branch"]
    hist = collections.Counter(v["distance"] for v in hung)
    by_node = collections.Counter(v["branch_of"] for v in hung)
    report = {"_doc": "GENERATED by tools/capacity_track.py — the main track gated by capacity, every other term and artifact as a branch of its nearest step.",
              "principle_axes": PRINCIPLE, "staging_axes": STAGING, "gate_ok": gate_ok, "track": steps,
              "terms": out_terms, "artifacts": out_art,
              "summary": {"track_steps": len(steps), "holes": len(holes), "artifacts": len(out_art),
                          "artifact_distance": dict(sorted(hist.items())), "artifacts_per_step": dict(by_node.most_common()),
                          "within_one": sum(n for d, n in hist.items() if d <= 1), "staged": sum(1 for v in hung if v["staged"]), "unread": len(unread)}}
    if write:
        OUT.write_text(json.dumps(report, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"gate {'OK' if gate_ok else 'FAILS'} — {len(steps)} steps ({len(holes)} holes)")
    for st in steps:
        print(f"  {st['index']:2} {str(st.get('term')):16} {st.get('axis', ''):10} {st['status']:6} new={st.get('new', '')}")
    print(f"artifacts: {len(out_art)}; distance from their step: {dict(sorted(hist.items()))}; within one: {report['summary']['within_one']}; carry staging: {report['summary']['staged']}; unread (empty tree): {len(unread)}")
    print("artifacts per step:", dict(by_node.most_common()))
    return 0 if gate_ok else 1


def names(track: list) -> list:
    return [st.get("term") or f"({st.get('axis', 'hole')})" for st in track]


def propose(proposal: list, note: str) -> int:
    """gate a proposed track; only a passing one is written, recorded and propagated"""
    if not isinstance(proposal, list) or not all(isinstance(st, dict) for st in proposal):
        print("refused: a track is a list of steps"); return 2
    doc = json.loads(TERMS.read_text(encoding="utf-8"))
    unknown = [st["term"] for st in proposal if st.get("term") and st["term"] not in doc["terms"]]
    if unknown:
        print("refused: not terms:", unknown); return 2
    before = doc.get("track", [])
    doc["track"] = proposal
    print("-- the gate, on the proposal (nothing written yet)")
    if run(doc, write=False) != 0:
        print("refused: the gate fails, terms.json untouched"); return 1
    if not HISTORY.exists():                           # the lineage starts with the track as it was
        HISTORY.write_text(json.dumps({"at": None, "note": "the track before the first mutation", "track": before}, ensure_ascii=False) + "\n", encoding="utf-8")
    fresh = json.loads(TERMS.read_text(encoding="utf-8"))   # re-read: terms.json has other writers
    fresh["track"] = proposal
    tmp = TERMS.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(fresh, indent=2) + "\n", encoding="utf-8")
    for attempt in range(8):
        try:
            os.replace(tmp, TERMS); break
        except OSError:
            time.sleep(1.0)
    else:
        print("refused: terms.json is held by another process"); return 3
    with HISTORY.open("a", encoding="utf-8") as h:
        h.write(json.dumps({"at": datetime.now(timezone.utc).isoformat(timespec="seconds"), "note": note,
                            "from": names(before), "track": proposal}, ensure_ascii=False) + "\n")
    print("-- written; the branches re-hung")
    run(fresh, write=True)
    subprocess.run([sys.executable, str(ROOT / "tools/construction_path.py")], cwd=ROOT)
    return 0


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")   # read through a pipe (the /tree-of-life route), not only a console
    terms_path, write, proposal, note = TERMS, True, None, ""
    for a in sys.argv[1:]:
        if a.startswith("--terms="):
            terms_path, write = Path(a.split("=", 1)[1]), False   # a mutant track: gate only, write nothing
        elif a.startswith("--propose="):
            proposal = json.loads(Path(a.split("=", 1)[1]).read_text(encoding="utf-8"))
        elif a.startswith("--note="):
            note = a.split("=", 1)[1]
    if proposal is not None:
        return propose(proposal, note)
    return run(json.loads(terms_path.read_text(encoding="utf-8")), write)


if __name__ == "__main__":
    sys.exit(main())
