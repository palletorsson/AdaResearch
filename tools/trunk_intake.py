#!/usr/bin/env python3
"""The intake — readings arrive as SENTENCES, not rows.

The trunk (commons/data/trunk_branches.json) holds readings as
(anchor, token, kind, why) rows. Palle's readings do not arrive that way;
they arrive as a spoken stream ahead of any token:

    "point, o before the point?, throwiness, ok the point, o a vector, must
     have body ... a line is also always measure, a line in many thing,
     lazer, trajectories ... the digital is always crocked, but it not
     reasonable to register every part of the trace, and there is no
     original. Then the triangle, and the angle, all we need not build
     meshes, think more of triangles"

This tool takes such a paragraph and PROPOSES candidate rows — node, token,
kind, space, why = the clause itself — with provenance "spoken", into a
PENDING queue that the museum and hero_walk never read. On /trunk each row
is kept (-> a hand branch, via "intake"), retargeted, or dropped.

HEURISTIC ONLY, and honest about it: a field the cues cannot decide is left
BLANK ("") rather than guessed, so the eye goes to what is missing. Every
row records which cue fired (cues.node / cues.kind), so a wrong proposal is
explainable and the lexicon can be corrected.

    python tools/trunk_intake.py --text "..." [--node noise] [--json] [--write]
    python tools/trunk_intake.py --file reading.md --node primitives --write
    echo "..." | python tools/trunk_intake.py --stdin --json
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from build_trunk_branches import KINDS, OUT, ORDER, SPINE, guess_space, load, registry_artifacts  # noqa: E402

#: words that name a trunk node — the SPOKEN vocabulary, not the token vocabulary
NODE_CUES: dict[str, list[str]] = {
    "primitives": ["point", "points", "line", "lines", "triangle", "triangles", "angle", "vector",
                   "vectors", "body", "grab", "grabbable", "mesh", "meshes", "trace", "primitive"],
    "transformation": ["rotate", "rotation", "translate", "matrix", "scale", "transform"],
    "symmetry": ["mirror", "reflect", "reflection", "wallpaper", "symmetry", "symmetric"],
    "array_tutorial": ["grid", "index", "array", "arrays", "row", "column"],
    "color": ["color", "colour", "hue", "saturation", "palette"],
    "change": ["derivative", "slope", "rate", "change", "calculus", "tangent"],
    "forces": ["force", "forces", "gravity", "attraction", "repulsion", "spring"],
    "formfinding": ["minimum", "catenary", "tension", "form finding", "formfinding", "hanging"],
    "wavefunctions": ["wave", "waves", "sine", "oscillat", "frequency"],
    "randomness": ["random", "dice", "throw", "throwiness", "chance", "coin"],
    "noise": ["noise", "perlin", "simplex", "blob", "blobs"],
    "cellularautomata": ["cell", "cells", "automata", "automaton", "rule", "neighbour", "neighbor"],
    "fractals": ["fractal", "koch", "self-similar", "self similar", "mandelbrot"],
    "lsystems": ["turtle", "grammar", "l-system", "lsystem", "rewrite"],
    "proceduralgeneration": ["procedural", "generation", "generator", "dungeon"],
    "softbodies": ["soft", "softbody", "soft body", "jelly", "cloth"],
    "isosurfaces": ["marching", "isosurface", "iso", "surface", "sdf"],
    "boolean_surfaces": ["boolean", "union", "subtract", "intersect"],
    "swarmintelligence": ["boid", "boids", "flock", "swarm"],
    "machinelearning": ["gradient", "weight", "weights", "learn", "learning", "neural"],
    "graphtheory": ["graph", "graphs", "node", "nodes", "edge", "edges", "network"],
    "foundationscrisis": ["gödel", "godel", "halting", "incomplete", "paradox", "turing"],
    "qfeplaboratory": ["qfep", "queer", "feminist", "laboratory"],
    "postfoundationscrisis": ["after the crisis", "post-foundations", "postfoundations"],
}

#: cue phrases per kind. Order matters: the first kind whose cue fires wins.
#: "hero" is not a branch kind — on keep it becomes op:hero on the node.
KIND_CUES: list[tuple[str, list[str]]] = [
    ("hero", ["all we need", "think more of", "must have", "the have a", "have a point",
              "what can we build", "ok the "]),
    ("contradicts", ["no original", "not reasonable", "unreasonable", "crooked", "crocked", " but ",
                     "never", "against", "not ", "cannot", "can not", "no "]),
    ("queers", ["is also", "also always", "many thing", "many things", "undoes", "in drag",
                "in disguise", "in the sand", "end of the line"]),
    ("edge", ["before the", "before that", "end of the", "no more", "resolution", "limit",
              "the edge", "?"]),
    ("synthesizes", ["can hold", "together", "both", "with the"]),
    ("varies", ["vertical", "horizontal", "many line", "many kinds", "versions", "another kind"]),
    ("extends", ["also", "many", "for a ", "further", "and then", "in many", "then the", "to point"]),
]

STOP = set("""a an the and or of to in on at for is are was were be been it its this that these those
o ok oh so as by with from into out up down not no yes we you i they he she then than there here
what which who how when where why must have has had do does did can could should would will just
like also always many more most very kind kinds thing things way etc""".split())


def clauses(text: str) -> list[str]:
    """Sentences on . ? ! and newlines; a long sentence sub-splits on commas;
    fragments under three words glue onto the previous clause. The ORIGINAL
    text of each clause is kept — it becomes the row's why."""
    out: list[str] = []
    for sent in re.split(r"(?<=[.?!])\s+|\n+", text.strip()):
        sent = sent.strip()
        if not sent:
            continue
        parts = [sent]
        if len(sent.split()) > 14 and "," in sent:
            parts = [p.strip() for p in sent.split(",") if p.strip()]
        for p in parts:
            if out and len(p.split()) < 3:
                out[-1] = out[-1] + ", " + p
            else:
                out.append(p)
    return out


def _words(s: str) -> list[str]:
    return [w for w in re.findall(r"[a-zåäöé\-]+", s.lower()) if w not in STOP and len(w) > 1]


def node_of(clause: str) -> tuple[str, str]:
    """(node, cue) or ("", "") — first node whose cue appears as a whole word."""
    low = " " + clause.lower() + " "
    for node, cues in NODE_CUES.items():
        for c in cues:
            if re.search(r"(?<![a-z])" + re.escape(c) + r"(?![a-z])", low):
                return node, c
    return "", ""


def kind_of(clause: str) -> tuple[str, str]:
    low = " " + clause.lower() + " "
    for kind, cues in KIND_CUES:
        for c in cues:
            if c in low:
                return kind, c.strip()
    return "", ""


class TokenIndex:
    """Registry artifacts scored against a clause — the shape of the
    encyclopedia's search.ts scoreItem, in Python, so both doors agree."""

    def __init__(self) -> None:
        self.reg = registry_artifacts()
        self.seq_of: dict[str, str] = {}
        if ORDER.exists():
            for r in load(ORDER)["order"]:
                self.seq_of.setdefault(r["lookup"], r["sequence"])
        self.rows: list[tuple[str, set[str], set[str], set[str], set[str]]] = []
        for tok, v in self.reg.items():
            name_words = set(_words(tok.replace("_", " "))) | set(_words(str(v.get("name", ""))))
            tags = set(_words(" ".join(str(t) for t in (v.get("tags") or []))))
            desc = set(_words(str(v.get("description", ""))))
            self.rows.append((tok, name_words, tags, desc, set()))

    def score(self, clause: str, node: str) -> list[tuple[str, int]]:
        ws = set(_words(clause))
        if not ws:
            return []
        scored: list[tuple[str, int, bool]] = []
        for tok, name_words, tags, desc, _ in self.rows:
            s = 0
            strong = False                    # a whole NAME word of 4+ letters matched
            for w in ws:
                if w in name_words:
                    if len(w) >= 4:
                        s += 5; strong = True
                    else:
                        s += 2                # "big" alone must not pick big_o_race
                elif any(w in n for n in name_words if len(w) > 3):
                    s += 2
                if w in tags:
                    s += 3
                if w in desc:
                    s += 1
            if s and node and self.seq_of.get(tok) == node:
                s += 3
            if s:
                scored.append((tok, s, strong))
        scored.sort(key=lambda x: (-x[1], x[0]))
        return scored


def propose(text: str, node_hint: str = "", index: TokenIndex | None = None) -> list[dict]:
    idx = index or TokenIndex()
    now = datetime.now().isoformat(timespec="seconds")
    sticky = node_hint
    sticky_by = "hint" if node_hint else ""
    rows: list[dict] = []
    for cl in clauses(text):
        node, ncue = node_of(cl)
        if node:
            sticky, sticky_by = node, "cue"
            node_by = "cue:" + ncue
        else:
            node = sticky
            node_by = "sticky" if sticky_by == "cue" else sticky_by
        kind, kcue = kind_of(cl)
        scored = idx.score(cl, node)
        token = ""
        # confident only when a real NAME word matched and the lead is clear;
        # otherwise the row offers options and leaves the token to the hand
        if scored and scored[0][2] and scored[0][1] >= 5 \
                and (len(scored) == 1 or scored[0][1] - scored[1][1] >= 2):
            token = scored[0][0]
        space = guess_space(kind, cl) if kind and kind != "hero" else ""
        rid = hashlib.sha1((node + "|" + cl).encode("utf-8")).hexdigest()[:10]
        rows.append({
            "id": rid, "anchor": node, "token": token,
            "token_options": [t for t, _, _ in scored[:6]],
            "kind": kind, "space": space, "space_by": "heuristic" if space else "",
            "why": cl, "cues": {"node": node_by, "kind": kcue},
            "provenance": "spoken", "at": now,
        })
    return rows


def write_pending(rows: list[dict], path: Path = OUT) -> dict:
    d = load(path)
    pend: list[dict] = d.get("pending", [])
    have = {p.get("id") for p in pend}
    dropped = set(d.get("pending_dropped", []))
    kept = {(b.get("anchor"), b.get("why")) for b in d.get("branches", []) if b.get("via") == "intake"}
    added = 0
    for r in rows:
        if r["id"] in have or r["id"] in dropped or (r["anchor"], r["why"]) in kept:
            continue
        pend.append(r)
        added += 1
    d["pending"] = pend
    d.setdefault("counts", {})["pending"] = len(pend)
    path.write_text(json.dumps(d, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    return {"added": added, "pending": len(pend), "path": str(path)}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--text", default="")
    ap.add_argument("--file", default="")
    ap.add_argument("--stdin", action="store_true")
    ap.add_argument("--node", default="", help="seed node for clauses before the first cue")
    ap.add_argument("--json", action="store_true", help="print the candidates as JSON")
    ap.add_argument("--write", action="store_true", help="append to `pending` in trunk_branches.json")
    ap.add_argument("--path", default=str(OUT), help="trunk file (tests point this at a copy)")
    a = ap.parse_args()
    text = a.text
    if a.file:
        text = Path(a.file).read_text(encoding="utf-8")
    if a.stdin:
        text = sys.stdin.read()
    if not text.strip():
        print("nothing to read", file=sys.stderr)
        return 2
    rows = propose(text, a.node)
    info = write_pending(rows, Path(a.path)) if a.write else None
    if a.json:
        print(json.dumps({"candidates": rows, "written": info}, ensure_ascii=False, indent=1))
    else:
        for r in rows:
            print(f"{r['anchor'] or '?':20s} {r['kind'] or '?':12s} {r['space'] or '-':6s} "
                  f"{r['token'] or ('(' + ', '.join(r['token_options'][:3]) + ')') if r['token_options'] else '?':40s} | {r['why'][:70]}")
        if info:
            print(f"-> pending +{info['added']} ({info['pending']} waiting) in {info['path']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
