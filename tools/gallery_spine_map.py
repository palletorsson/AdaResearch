"""gallery_spine_map.py — where does each encyclopedia gallery belong on the spine?

2026-08-27, Palle: "where in the sequence does /morphology-gallery, /graph-grammar-gallery,
/parametric-mesh-gallery, /soft-body-gallery and /facade-gallery and all other go"

THE ANSWER IS DERIVED, NOT GUESSED, wherever it can be. Every gallery page reads
public/<slug>/manifest.json. Where that manifest names registry artifacts, this walks
them through commons/data/spine_artifact_order.json - the first-appearance order of every
artifact PLACED in a spine map - and the gallery's home is wherever its contents already
live. Only where a manifest names no artifact at all does this fall back to keyword
cues over the manifest text, and those rows are labelled PROPOSED so nobody mistakes a
guess for a lookup.

THREE VERDICTS, and the difference between them is the point:

  PLACED   the gallery's artifacts appear in spine maps. It HAS a home; this prints it.
  ORPHAN   its artifacts are in the registry and in NO spine map. The bodies exist, the
           curriculum has never met them. This is the interesting column.
  STUDY    the manifest names no registry artifact - it is a generative catalogue
           (80 morphologies, N facades) rather than a collection of built things.
           A sequence is PROPOSED from keywords and is a suggestion, nothing more.

A gallery can be split across sequences; that is not an error, and the histogram is
printed rather than collapsed, because "this gallery is 60% randomness and 40% noise" is
a fact about the gallery worth seeing.

  python tools/gallery_spine_map.py                  the whole table
  python tools/gallery_spine_map.py --orphans        only galleries with no placed body
  python tools/gallery_spine_map.py --slug=morphology-gallery
  python tools/gallery_spine_map.py --json
"""
from __future__ import annotations
import collections
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia", "public"))
SPINE_ORDER = os.path.join(ROOT, "commons", "data", "spine_artifact_order.json")
SPINE = os.path.join(ROOT, "commons", "maps", "curriculum_spine.json")
REGISTRY = os.path.join(ROOT, "commons", "artifacts", "registry", "*.json")

# Only consulted for STUDY galleries, whose manifests name no artifact. Ordered: first
# hit wins, so put the specific cues above the general ones.
CUES = [
    ("softbodies", ["soft body", "soft-body", "softbody", "spring", "verlet", "jelly", "cloth"]),
    ("isosurfaces", ["isosurface", "marching cube", "metaball", "sdf", "signed distance"]),
    ("boolean_surfaces", ["boolean", "csg", "union", "subtract", "intersect"]),
    ("lsystems", ["l-system", "lsystem", "turtle", "grammar", "rewrite", "axiom", "branch", "trunk"]),
    ("cellularautomata", ["cellular automat", "rule 110", "wolfram", "neighbour", "neighbor", "lenia"]),
    ("fractals", ["fractal", "koch", "mandelbrot", "julia", "self-similar", "recursion"]),
    ("noise", ["perlin", "simplex", "fbm", "noise"]),
    ("randomness", ["random", "stochastic", "poisson", "distribution", "dice", "seed"]),
    ("graphtheory", ["graph", "node", "edge", "adjacency", "traversal", "shortest path"]),
    ("proceduralgeneration", ["procedural", "wfc", "wave function collapse", "facade", "building", "city", "dungeon"]),
    ("formfinding", ["catenary", "minimal surface", "tension", "form-find", "morpholog", "growth"]),
    ("swarmintelligence", ["boid", "flock", "swarm", "ant", "particle system"]),
    ("machinelearning", ["gradient", "neural", "weight", "training", "backprop", "learn"]),
    ("primitives", ["primitive", "platonic", "johnson", "polyhedr", "prism", "mesh", "vertex", "triangle"]),
    ("transformation", ["transform", "rotation", "matrix", "compose", "basis"]),
    ("color", ["colour", "color", "hue", "palette", "gamut"]),
    ("wavefunctions", ["wave", "sine", "oscillat", "harmonic", "fourier"]),
    ("forces", ["force", "gravity", "physics", "collision", "momentum"]),
    ("change", ["derivative", "slope", "rate", "riemann", "integral", "tangent"]),
    ("foundationscrisis", ["godel", "russell", "halting", "cantor", "paradox", "undecidab", "shannon"]),
    ("postfoundationscrisis", ["bias", "commons", "rhizome", "accountab"]),
]

TOKEN_RE = re.compile(r"[a-z][a-z0-9_]{4,48}")


def load_spine_sequences() -> list:
    d = json.load(open(SPINE, encoding="utf-8"))
    seqs = d["spine"]["sequences"]
    return [s["name"] for s in sorted(seqs, key=lambda s: s.get("order", 0))]


def load_placed() -> dict:
    """token -> sequence, for every artifact that appears in a spine map."""
    d = json.load(open(SPINE_ORDER, encoding="utf-8"))
    out = {}
    for row in d.get("order", []):
        lk = row.get("lookup")
        if lk and lk not in out:
            out[lk] = row.get("sequence", "?")
    return out


def load_registry() -> set:
    toks = set()
    for f in glob.glob(REGISTRY):
        try:
            d = json.load(open(f, encoding="utf-8"))
        except Exception:
            continue
        toks.update((d.get("artifacts") or {}).keys())
    return toks


# Keys whose VALUE may name an artifact. Prose keys (notes, description, caption) are
# deliberately absent — see tokens_in.
ID_KEYS = {"token", "artifact", "artifact_token", "lookup", "lookup_name", "id", "name",
           "scene", "slug", "target", "subject"}


def tokens_in(doc, registry: set) -> set:
    """Registry artifacts this manifest actually REFERENCES.

    The first version of this regexed the raw file for any word that was also a registry
    token, and it was wrong in a way that looked authoritative: the corpus contains
    artifacts literally named `sphere`, `plane`, `triangle`, `point` and `diamond`, so
    every manifest whose prose said "a soft body shaped like a sphere" acquired a
    reference to the artifact `sphere` — and soft-body-gallery was reported home to
    PRIMITIVES on the strength of one adjective. Descriptions are not references.

    So: walk the structure, and only accept a string that is either the value of an
    identifier key or the stem of an asset path. Prose fields are never read.
    """
    found = set()

    def stem(s: str) -> str:
        base = s.rsplit("/", 1)[-1].rsplit("\\", 1)[-1]
        return base.split(".", 1)[0].lower()

    def walk(node, key: str = "") -> None:
        if isinstance(node, dict):
            for k, v in node.items():
                walk(v, str(k).lower())
        elif isinstance(node, list):
            for v in node:
                walk(v, key)
        elif isinstance(node, str):
            s = node.strip()
            if not s:
                return
            if "/" in s or "\\" in s or s.endswith((".png", ".json", ".tscn", ".gd")):
                cand = stem(s)
                if cand in registry:
                    found.add(cand)
                return
            if key in ID_KEYS and s.lower() in registry:
                found.add(s.lower())

    walk(doc)
    return found


# Cues this weak decide nothing on their own — an "edge" is a mesh edge as often as a
# graph edge, and "wave" is a shape as often as a wavefunction. They still count in
# prose, but they can never outvote a slug.
WEAK = {"edge", "node", "graph", "mesh", "wave", "force", "rate", "plane", "growth",
        "branch", "trunk", "seed", "weight", "learn", "name"}


def propose(slug: str, raw: str) -> tuple:
    """Score every sequence, rather than taking the first cue that fires.

    First-match-wins read the whole file top to bottom and let one stray adjective
    decide: parametric-mesh-gallery was assigned to GRAPHTHEORY because a description
    somewhere said "edge", and facade-gallery likewise on "graph". The slug is written
    by a person naming the thing, so it outranks prose by design — and a weak cue can
    never win from prose alone.
    """
    slug_words = slug.replace("-", " ").replace("_", " ").lower()
    low = raw.lower()
    scored = []
    for seq, cues in CUES:
        score = 0
        best = ""
        for c in cues:
            in_slug = c in slug_words
            n = low.count(c)
            w = (10 if in_slug else 0) + (0 if c in WEAK and not in_slug else min(n, 6))
            if w > score:
                score, best = w, c
        if score:
            scored.append((score, seq, best))
    if not scored:
        return "", "", 0
    scored.sort(reverse=True)
    top = scored[0]
    runner = scored[1][0] if len(scored) > 1 else 0
    # ONLY A SLUG CUE COUNTS. Scoring prose put 44 galleries in wavefunctions and 30 in
    # swarmintelligence - `bay`, `interactable-demos`, `cantor-diagonal` among them -
    # because these manifests are generated descriptions and the word "wave" is common.
    # A description is not a curricular home. Prose is reported and never decides.
    if top[2] not in slug_words:
        return "", "no slug cue (best prose guess: %s via '%s')" % (top[1], top[2]), 0
    return top[1], "%s (slug)" % top[2], top[0] - runner


def scan() -> list:
    placed = load_placed()
    registry = load_registry()
    rows = []
    for m in sorted(glob.glob(os.path.join(ENC, "*", "manifest.json"))):
        slug = os.path.basename(os.path.dirname(m))
        try:
            raw = open(m, encoding="utf-8", errors="replace").read()
            doc = json.loads(raw)
        except (OSError, ValueError):
            continue
        toks = tokens_in(doc, registry)
        hist = collections.Counter(placed[t] for t in toks if t in placed)
        n_placed = sum(hist.values())
        if not toks:
            seq, cue, margin = propose(slug, raw)
            rows.append({"slug": slug, "verdict": "STUDY", "tokens": 0, "placed": 0,
                         "home": seq, "margin": margin,
                         "why": ("cue: " + cue) if cue else "no cue", "hist": {}})
        elif n_placed == 0:
            seq, cue, margin = propose(slug, raw)
            rows.append({"slug": slug, "verdict": "ORPHAN", "tokens": len(toks), "placed": 0,
                         "home": seq, "margin": margin,
                         "why": "%d registry artifact(s), none in any spine map" % len(toks),
                         "hist": {}})
        else:
            top, n = hist.most_common(1)[0]
            rows.append({"slug": slug, "verdict": "PLACED", "tokens": len(toks), "placed": n_placed,
                         "home": top, "why": "%d/%d placed artifacts in %s" % (n, n_placed, top),
                         "hist": dict(hist.most_common())})
    return rows


def main() -> int:
    flags = {a.split("=", 1)[0]: (a.split("=", 1)[1] if "=" in a else True)
             for a in sys.argv[1:] if a.startswith("--")}
    if not os.path.isdir(ENC):
        print("encyclopedia public/ not found at", ENC)
        return 2
    rows = scan()

    if flags.get("--slug"):
        want = str(flags["--slug"])
        rows = [r for r in rows if r["slug"] == want or want in r["slug"]]
    if flags.get("--orphans"):
        rows = [r for r in rows if r["verdict"] != "PLACED"]
    if flags.get("--json"):
        print(json.dumps(rows, indent=2))
        return 0

    order = load_spine_sequences()
    rank = {s: i for i, s in enumerate(order)}
    rows.sort(key=lambda r: (r["verdict"] != "PLACED", rank.get(r["home"], 99), r["slug"]))

    print("%-34s %-8s %6s %6s  %-22s %s" % ("gallery", "verdict", "toks", "placed", "home on the spine", "why"))
    print("-" * 132)
    for r in rows:
        home = r["home"] or "—"
        if r["verdict"] != "PLACED" and r["home"]:
            home += "?"                      # proposed, not derived
        print("%-34s %-8s %6d %6d  %-22s %s" % (
            r["slug"], r["verdict"], r["tokens"], r["placed"], home, r["why"]))
        if r["verdict"] == "PLACED" and len(r["hist"]) > 1:
            spread = ", ".join("%s %d" % (k, v) for k, v in list(r["hist"].items())[:5])
            print("%-34s %s" % ("", "  also: " + spread))

    v = collections.Counter(r["verdict"] for r in rows)
    print()
    print("%d galleries — PLACED %d (home derived) · ORPHAN %d (bodies exist, spine has "
          "never met them) · STUDY %d (generative catalogue, home PROPOSED)"
          % (len(rows), v["PLACED"], v["ORPHAN"], v["STUDY"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
