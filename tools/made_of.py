#!/usr/bin/env python3
"""WHAT A CHAPTER'S WORKS ARE ACTUALLY MADE OF — read off their source, not their prose.

    python tools/made_of.py --chapter=randomness
    python tools/made_of.py --chapter=randomness --silent   # works that never call their own chapter
    python tools/made_of.py                                 # every chapter, one line each
    python tools/made_of.py --token=origin                  # ONE work's code reference
    python tools/made_of.py --json

2026-08-31. tutorial_census.py asks what the LESSONS say. This asks what the WORKS
do, and the two together are Palle's question: "what are the algorithms described
in the tutorials. And do they match the maps?"

IT DOES NOT USE A WORD LIST. tutorial_census had to guess at prose vocabulary and
then throw half of it away for being ordinary English. Source code needs no
guessing: `randf(`, `FastNoiseLite`, `Transform3D`, `apply_impulse` are Godot
APIs with one meaning each. What a file CALLS is a fact about it.

THE NULL IS THE POINT. A work in the randomness chapter whose source contains no
RNG call is either mis-shelved or making an argument, and --silent is how you find
out which. In randomness it found coin_toss and dice_throw: 2289 lines between
them, not one randf, because both build XR pickables and read back
linear_velocity and angular_velocity. The physics decides. coin_toss says so in
its own identity — "the launch gauges show the spin and drop that decided it, and
the fairness starts to look like ignorance". The randomness is epistemic, and the
absence of a generator IS the thesis. An instrument that only counted presence
would have walked straight past the two best pieces in the chapter.

--token IS THE CODE REFERENCE. 2026-08-31, Palle: "how can I start to add the
code reference like processing.org/reference/point_.html for point.zero and a
point in godot with the principle of natureofcode? Building from the ground up."

Processing's reference names the primitive and says what it is. The Godot
equivalent for a work in this museum is not written, it is READ: origin.gd names
Vector3.ZERO, CoordinateSystem3M.gd names Vector3.UP, RIGHT, FORWARD, BACK, ONE
and ZERO — the whole basis. That is the reference, and it cannot go stale, because
it is the file.

GROUND UP is the ordering, and it comes from the spine rather than from taste:
the types a work names are sorted by the chapter that owns them, so a work reads
as the stack it stands on — Vector3 before Transform3D before Basis — the way
Nature of Code builds vectors before forces before oscillation.

Each carries the URL of its own class page on docs.godotengine.org, and each
constant the anchor of its own entry. The anchor scheme was written down as a
guess and then CHECKED against the live page: docs.godotengine.org's Vector3
class really does carry id="class-vector3-constant-zero", along with -one, -inf,
-left and -right. So Vector3.ZERO links to Vector3.ZERO, not merely to Vector3 —
which is the difference between a reference and a signpost.

WHAT IT CANNOT SEE, and the number is large: a work reaches its source through the
registry's `scene`, and for randomness only 28 of 64 works resolve — the rest are
shader-only, scene-only, or registered without a scene. The unresolved are counted
and named rather than quietly dropped, because 36 silent works would otherwise
look like a clean bill of health.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
BASE = REPO.parent / "ada_encyclopedia" / "public" / "base_layer.json"

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

# Godot APIs and idioms, each with one meaning. Not a vocabulary — a call list.
CALLS: dict[str, list[str]] = {
    "randomness": [r"\brandf\b", r"\brandi\b", r"\brandomize\b", r"RandomNumberGenerator",
                   r"\brand_range\b", r"\bpick_random\b", r"\bshuffle\("],
    "noise": [r"FastNoiseLite", r"NoiseTexture", r"\bnoise\b"],
    "wavefunctions": [r"\bsin\(", r"\bcos\(", r"\bTAU\b", r"\bfmod\("],
    "primitives": [r"Vector3\(", r"Vector2\(", r"BoxMesh", r"SphereMesh", r"ArrayMesh",
                   r"SurfaceTool", r"ImmediateMesh"],
    "transformation": [r"Transform3D", r"\bBasis\b", r"\.rotated\(", r"\.scaled\(", r"look_at"],
    "forces": [r"\bgravity\b", r"linear_velocity", r"angular_velocity", r"RigidBody",
               r"apply_impulse", r"apply_central_force"],
    "graphtheory": [r"\bAStar", r"adjacency", r"\bneighbou?rs\b", r"\bbreadth_first", r"\bdepth_first"],
    "cellularautomata": [r"neighbou?r_count", r"\bnext_generation\b", r"\brule_?110\b"],
    "machinelearning": [r"\bweights\b", r"\bgradient\b", r"\bsigmoid\b", r"\bbackprop"],
    "softbodies": [r"\bspring\b", r"\bdamping\b", r"verlet", r"\bstiffness\b"],
    "isosurfaces": [r"marching_?cubes", r"\bisosurface", r"\bsdf\b", r"scalar_field"],
    "color": [r"Color\(", r"from_hsv", r"\bhue\b", r"albedo_color"],
    "lsystems": [r"\baxiom\b", r"\bturtle\b", r"\bproductions?\b", r"\brewrite\b"],
    "swarmintelligence": [r"\bboid", r"\bflock", r"pheromone", r"\bswarm"],
    "fractals": [r"\brecurs", r"\bkoch\b", r"sierpinski", r"self_similar", r"\bsubdivide\b"],
    "proceduralgeneration": [r"wave_?function_?collapse", r"\bmarkov\b", r"\bwfc\b"],
    "boolean_surfaces": [r"\bcsg", r"CSGCombiner", r"\bunion\b", r"\bsubtract\b"],
}


def registry() -> dict:
    out = {}
    for f in (REPO / "commons" / "artifacts" / "registry").glob("*.json"):
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        a = d.get("artifacts", d) if isinstance(d, dict) else {}
        if isinstance(a, dict):
            for k, v in a.items():
                if isinstance(v, dict):
                    out[k] = v
    return out


def source_of(reg: dict, tok: str) -> Path | None:
    """The .gd a work actually runs. Read out of the .tscn when the naming
    convention does not hold, which it does not for a third of them."""
    v = reg.get(tok) or {}
    sc = str(v.get("scene", "")).replace("res://", "")
    if not sc:
        return None
    p = REPO / sc
    if p.suffix == ".gd" and p.exists():
        return p
    if p.suffix == ".tscn" and p.exists():
        m = re.search(r'\[ext_resource type="Script"[^\]]*path="res://([^"]+)"',
                      p.read_text(encoding="utf-8", errors="replace"))
        if m:
            q = REPO / m.group(1)
            if q.exists():
                return q
    g = p.with_suffix(".gd")
    return g if g.exists() else None


# The Godot types worth naming in a reference, and the chapter each belongs to.
# The chapter is what orders them ground-up; a type with no chapter sorts last.
TYPE_CHAPTER = {
    "Vector2": "primitives", "Vector3": "primitives", "Plane": "primitives",
    "BoxMesh": "primitives", "SphereMesh": "primitives", "CylinderMesh": "primitives",
    "TorusMesh": "primitives", "ArrayMesh": "primitives", "SurfaceTool": "primitives",
    "ImmediateMesh": "primitives", "MeshInstance3D": "primitives", "Node3D": "primitives",
    "Transform3D": "transformation", "Basis": "transformation", "Quaternion": "transformation",
    "Color": "color", "StandardMaterial3D": "color", "ShaderMaterial": "color",
    "RandomNumberGenerator": "randomness", "FastNoiseLite": "noise",
    "RigidBody3D": "forces", "CharacterBody3D": "forces", "Area3D": "forces",
    "CollisionShape3D": "forces", "MultiMesh": "primitives", "MultiMeshInstance3D": "primitives",
    "Label3D": "primitives", "Curve3D": "change", "AStar3D": "graphtheory",
}
SPINE_ORDER = ["primitives", "transformation", "color", "change", "forces", "formfinding",
               "wavefunctions", "randomness", "noise", "cellularautomata", "fractals",
               "lsystems", "proceduralgeneration", "softbodies", "isosurfaces",
               "boolean_surfaces", "swarmintelligence", "machinelearning", "graphtheory",
               "foundationscrisis", "qfeplaboratory", "postfoundationscrisis"]


def doc_url(cls: str) -> str:
    return "https://docs.godotengine.org/en/stable/classes/class_%s.html" % cls.lower()


def code_reference(reg: dict, tok: str) -> dict:
    """The primitives one work stands on, read off its own source.

    Types AND the constants of those types, because `Vector3.ZERO` is the thing
    Palle is pointing at and `Vector3` alone does not say it. Ordered by the
    chapter that owns each type, so the list reads bottom-up like Nature of Code
    rather than alphabetically like a symbol table."""
    src = source_of(reg, tok)
    if src is None:
        return {"token": tok, "src": None, "types": [], "error": "no source resolves for this work"}
    txt = src.read_text(encoding="utf-8", errors="replace")
    found = []
    for cls, chapter in TYPE_CHAPTER.items():
        if not re.search(r"\b%s\b" % re.escape(cls), txt):
            continue
        consts = sorted(set(re.findall(r"\b%s\.([A-Z][A-Z0-9_]+)\b" % re.escape(cls), txt)))
        found.append({
            "type": cls, "chapter": chapter, "url": doc_url(cls),
            "constants": [{"name": "%s.%s" % (cls, c),
                           "anchor": doc_url(cls) + "#class-%s-constant-%s" % (cls.lower(), c.lower())}
                          for c in consts],
        })
    order = {c: i for i, c in enumerate(SPINE_ORDER)}
    found.sort(key=lambda f: (order.get(f["chapter"], 99), f["type"]))
    return {"token": tok, "src": str(src.relative_to(REPO)).replace("\\", "/"),
            "types": found}


def works(chapter: str) -> list[str]:
    d = json.loads(BASE.read_text(encoding="utf-8"))
    return sorted({w["token"] for c in d.get("chapters", []) if c.get("chapter") == chapter
                   for h in c.get("halls", []) for w in h.get("works", [])})


def measure(chapter: str, reg: dict) -> dict:
    toks = works(chapter)
    per, missing = {}, []
    for t in toks:
        s = source_of(reg, t)
        if s is None:
            missing.append(t)
            continue
        txt = s.read_text(encoding="utf-8", errors="replace")
        per[t] = {"src": str(s.relative_to(REPO)).replace("\\", "/"),
                  "calls": sorted(k for k, pats in CALLS.items()
                                  if any(re.search(x, txt) for x in pats))}
    counts: dict[str, int] = {}
    for r in per.values():
        for k in r["calls"]:
            counts[k] = counts.get(k, 0) + 1
    return {"chapter": chapter, "works": len(toks), "read": len(per),
            "unresolved": missing, "counts": counts, "per": per}


def main() -> int:
    ap = argparse.ArgumentParser(description="what a chapter's works actually call")
    ap.add_argument("--chapter", default="")
    ap.add_argument("--token", default="", help="one work's code reference, read off its source")
    ap.add_argument("--silent", action="store_true", help="works that never call their own chapter")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()

    reg = registry()

    if a.token:
        ref = code_reference(reg, a.token)
        if a.json:
            print(json.dumps(ref, ensure_ascii=False, indent=1))
            return 0 if ref.get("types") else 2
        if ref.get("error"):
            print("%s — %s" % (a.token, ref["error"]))
            return 2
        print("CODE REFERENCE — %s" % a.token)
        print("  %s" % ref["src"])
        print()
        print("  what it stands on, ground up:")
        last = ""
        for t in ref["types"]:
            if t["chapter"] != last:
                print("    [%s]" % t["chapter"])
                last = t["chapter"]
            print("      %-22s %s" % (t["type"], t["url"]))
            for c in t["constants"]:
                print("        %s" % c["name"])
        return 0

    if not a.chapter:
        d = json.loads(BASE.read_text(encoding="utf-8"))
        print("MADE OF — every chapter, from its works' source")
        print()
        print("  %-24s %5s %5s  %s" % ("chapter", "works", "read", "calls its own"))
        for c in d.get("chapters", []):
            ch = c.get("chapter", "")
            m = measure(ch, reg)
            own = m["counts"].get(ch, 0)
            print("  %-24s %5d %5d  %d%s" % (ch, m["works"], m["read"], own,
                  "" if ch in CALLS else "   (no call list for this chapter)"))
        return 0

    m = measure(a.chapter, reg)
    if a.json:
        print(json.dumps(m, ensure_ascii=False, indent=1))
        return 0

    n = m["read"]
    print("MADE OF — %s" % a.chapter)
    print()
    print("  works in the chapter        : %d" % m["works"])
    print("  with a source that reads    : %d" % n)
    print("  UNRESOLVED (no .gd found)   : %d" % len(m["unresolved"]))
    if m["unresolved"]:
        print("    %s%s" % (", ".join(m["unresolved"][:8]),
                            " …" if len(m["unresolved"]) > 8 else ""))
    print()
    if not n:
        print("  nothing to read.")
        return 2
    print("  WHAT THEY CALL:")
    for k, c in sorted(m["counts"].items(), key=lambda kv: -kv[1]):
        own = "  <- the chapter's own" if k == a.chapter else ""
        print("    %-22s %3d of %3d  (%2.0f%%)%s" % (k, c, n, 100.0 * c / n, own))

    if a.silent or True:
        quiet = [t for t, r in m["per"].items() if a.chapter not in r["calls"]]
        print()
        print("  CALLS NOTHING OF ITS OWN CHAPTER: %d of %d" % (len(quiet), n))
        print("  (mis-shelved, or the absence IS the argument — read them before deciding)")
        for t in quiet:
            print("    %-34s %s" % (t, m["per"][t]["src"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
