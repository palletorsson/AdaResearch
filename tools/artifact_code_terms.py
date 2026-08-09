# -*- coding: utf-8 -*-
"""artifact_code_terms.py — what an artifact's CODE actually does, and what it combines.

The info board reads descriptions, which is a keyword match over prose someone
wrote. This reads the GDScript. A description can say "laser"; only the code can
say that the laser casts a ray, tests a collision, and then removes a cube — and
that combination is the thing Palle asked about: not which terms are present, but
which are used TOGETHER.

Every signal here is a call or a type that the engine actually runs:

  collision   RayCast3D, intersect_ray, move_and_collide, body_entered, Area3D
  transform   Transform3D, .basis, rotate*, translate*, look_at
  randomness  randf, randi, RandomNumberGenerator, rand_range
  loop        for/while
  array       Array[, PackedVector3Array, range(, .append
  cube        BoxMesh, CSGBox3D, BoxShape3D
  laser       RayCast3D, laser, beam
  ...

A term counted here is a term the artifact EXECUTES. That is a stronger claim
than the board's, and the two disagreeing on an artifact is worth knowing: it
means the description promises something the code does not do, or the code does
something nobody wrote down.

    python tools/artifact_code_terms.py
    python tools/artifact_code_terms.py --with=laser
"""
import json, re, argparse, pathlib, sys
from collections import Counter, defaultdict

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "commons/data/artifact_code_terms.json"
sys.path.insert(0, str(ROOT / "tools"))
import walk_polish as wp                       # noqa: E402
import spine_typologies as sty                 # noqa: E402

# code signals — types and calls, not adjectives
SIGNALS = {
    "collision":  [r"RayCast3D", r"intersect_ray", r"move_and_collide", r"body_entered",
                   r"area_entered", r"Area3D", r"CollisionShape3D", r"get_overlapping"],
    "laser":      [r"RayCast3D", r"\blaser", r"\bbeam\b"],
    "transform":  [r"Transform3D", r"\.basis", r"\brotate[_a-z]*\(", r"\btranslate\(",
                   r"look_at\(", r"\.rotation", r"\.scale\b"],
    "randomness": [r"\brandf\(", r"\brandi\(", r"RandomNumberGenerator", r"rand_range",
                   r"\.randomize\(", r"randf_range"],
    "noise":      [r"FastNoiseLite", r"NoiseTexture", r"\bnoise\.", r"perlin", r"simplex"],
    "loop":       [r"^\s*for\s+\w+\s+in\b", r"^\s*while\s+"],
    "array":      [r"\bArray\[", r"Packed\w+Array", r"\brange\(", r"\.append\(", r"\bDictionary\b"],
    "cube":       [r"BoxMesh", r"CSGBox3D", r"BoxShape3D", r"\bvoxel"],
    "point":      [r"Vector3\(", r"\bposition\b", r"global_position"],
    "line":       [r"ImmediateMesh", r"PRIMITIVE_LINE", r"draw_line", r"\bCurve3D\b"],
    "plane":      [r"PlaneMesh", r"QuadMesh", r"\bPlane\("],
    "primitive":  [r"SphereMesh", r"CylinderMesh", r"TorusMesh", r"CapsuleMesh", r"PrismMesh"],
    "colour":     [r"\bColor\(", r"albedo_color", r"Color\.from_hsv", r"\.modulate"],
    "wave":       [r"\bsin\(", r"\bcos\(", r"\bTAU\b", r"\bPI\b"],
    "force":      [r"apply_impulse", r"apply_force", r"RigidBody3D", r"\bgravity\b",
                   r"linear_velocity"],
    "softbody":   [r"SoftBody3D", r"\bspring", r"\bdamping\b"],
    "isosurface": [r"marching", r"\bsdf\b", r"metaball", r"iso_level"],
    "boolean":    [r"CSGCombiner", r"OPERATION_SUBTRACTION", r"OPERATION_INTERSECTION",
                   r"OPERATION_UNION"],
    "grammar":    [r"\brule[s]?\s*[:=]", r"\baxiom\b", r"rewrite", r"l_system", r"lsystem"],
    "automata":   [r"neighbou?r_count", r"\bgeneration\b.*\bcell", r"rule_number", r"\bca_step"],
    "graph":      [r"adjacency", r"\bedges\b", r"\bnodes\b.*\bedges\b", r"astar", r"AStar"],
    "learning":   [r"\bweights\b", r"\bneuron", r"backprop", r"\blayer[s]?\b.*\bweight"],
    "fractal":    [r"\brecurs", r"self_similar", r"\biterat\w*_depth", r"\bdepth\s*[-+]?=\s*1"],
}


def script_of(entry):
    """The .gd an artifact actually runs: the scene's script, or a .gd beside it."""
    scene = str(entry.get("scene", "")).replace("res://", "")
    if not scene:
        return None
    p = ROOT / scene
    if p.suffix == ".gd" and p.exists():
        return p
    if p.exists() and p.suffix == ".tscn":
        try:
            txt = p.read_text(encoding="utf-8", errors="replace")
        except Exception:
            return None
        m = re.search(r'path="res://([^"]+\.gd)"', txt)
        if m:
            q = ROOT / m.group(1)
            if q.exists():
                return q
    q = p.with_suffix(".gd")
    return q if q.exists() else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--with", dest="with_term", default="")
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    reg = {}
    for f in (ROOT / "commons/artifacts/registry").glob("*.json"):
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        for k, v in (d.get("artifacts", d) or {}).items():
            if isinstance(v, dict):
                reg[k] = v

    spine_toks = set()
    for _, nm in sty.spine_maps():
        md = wp.load(nm)
        if not md:
            continue
        for row in wp.grids(md)[2]:
            for c in row:
                s = str(c).strip()
                if s and not s.startswith(wp.PRE) and not s.startswith("hangar_"):
                    spine_toks.add(s.split(":")[0])

    out, noscript = {}, 0
    for tok in sorted(spine_toks):
        sp = script_of(reg.get(tok, {}))
        if sp is None:
            noscript += 1
            continue
        try:
            src = sp.read_text(encoding="utf-8", errors="replace")
        except Exception:
            noscript += 1
            continue
        terms = sorted(t for t, pats in SIGNALS.items()
                       if any(re.search(p, src, re.M | re.I) for p in pats))
        out[tok] = {"script": str(sp.relative_to(ROOT)).replace("\\", "/"),
                    "lines": src.count("\n") + 1, "terms": terms}

    OUT.write_text(json.dumps({
        "_readme": ("What each spine artifact's GDScript actually executes. Signals are types and "
                    "calls, not adjectives, so a term here is a term the engine RUNS. Compare with "
                    "info_boards.json, which reads descriptions: where they disagree, either the "
                    "prose promises what the code does not do, or the code does something nobody "
                    "wrote down."),
        "signals": {k: v for k, v in SIGNALS.items()},
        "counts": {"artifacts": len(out), "no_script_found": noscript},
        "artifacts": out}, indent=1), encoding="utf-8")

    print("%d spine artifacts read (%d had no script)" % (len(out), noscript))
    freq = Counter(t for v in out.values() for t in v["terms"])
    print("terms the code actually runs:", freq.most_common(10))

    if a.with_term:
        who = {k: v for k, v in out.items() if a.with_term in v["terms"]}
        print("\n%d artifacts execute %r. WHAT IT COMBINES WITH:" % (len(who), a.with_term))
        co = Counter(t for v in who.values() for t in v["terms"] if t != a.with_term)
        for t, n in co.most_common(12):
            print("   %-12s in %d of %d  (%.0f%%)" % (t, n, len(who), 100.0 * n / len(who)))
        print("\n  examples:")
        for k, v in list(who.items())[:6]:
            print("   %-30s %s" % (k[:30], "+".join(x for x in v["terms"] if x != a.with_term)[:60]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
