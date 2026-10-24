#!/usr/bin/env python3
"""The plan that takes every spine sequence into the modular class system, as a list.

Palle, 23 Oct 2026: "make a plan to integrate all the spine in a list" — then "this plan might
have holes or elements that can make us compress it more" — then "fold the compressed version
into the plan". This is the compressed version. One row per spine sequence, in spine order:
what stands there now (maps, artifacts, Void floors), the chapter (the spine's own phase), the
FAMILIES to author (a term with an axis is one family, many variants — the registry's DNA
mechanism), and the kernel piece it waits for (five pieces, not eighteen).

The numbers are read from the live files; the proposals are authored below (PROPOSALS) and
are NOT written to terms.json — the studio is where a term is authored and saved.

    python tools/modular_spine_plan.py            # writes doc/book/course/MODULAR_SPINE_PLAN.md
                                                  #   + commons/data/modular_spine_plan.json (for /modular-plan)
    python tools/modular_spine_plan.py --print    # the list on stdout
"""
from __future__ import annotations

import collections
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPINE = ROOT / "commons/maps/curriculum_spine.json"
TERMS = ROOT / "commons/modular/terms.json"
SIGNATURES = ROOT / "commons/data/modular_signatures.json"
SPAWNLISTS = ROOT / "commons/data/void_spawnlists.json"
ROOMS = ROOT / "commons/void/rooms.json"
ROLES = ROOT / "commons/data/artifact_roles.json"
OUT = ROOT / "doc/book/course/MODULAR_SPINE_PLAN.md"
JSON_OUT = ROOT / "commons/data/modular_spine_plan.json"

# ── the compression ─────────────────────────────────────────────────────────────────────────
# Twelve engines were two; `vary` was an engine at t = 0; array, times, recurse and rewrite were
# one replication operator; the shader axis was a key on associate, not a piece; boolean and
# isosurface are both a solid from a function of space. Five pieces, each named once.
KERNEL = {
    "connect": "a relation between two NAMED parts of one compose — drawn as a line it is an edge, with a step "
               "rule it is a spring, with a number it is a weight. `{\"op\":\"connect\",\"a\":\"n1\",\"b\":\"n2\"}`. "
               "Both builders. First, because forces (7) needs it long before graph theory (21) names it",
    "by": "the parameter function f(index, t): `{\"by\":{\"fn\":\"list|sine|noise|random|lerp\", …}}` — on an "
          "array it is `vary` (t = 0: colour, height, rotation, phase per part); on an engine it is motion "
          "(the same function with t running). One implementation serves both",
    "replicate": "one replication operator with four presets — array (X → X X X X shifted), times, recurse "
                 "(X → n transformed copies of X, bounded `depth`: the only place self-containment is allowed) "
                 "and rewrite (a string rule, generations; the turtle is its interpreter)",
    "step": "the neighbourhood engine: a named rule applied per part from its neighbours and connects — "
            "spring, field, boids, ca, verlet, learn share one interface. ONE verlet in both renderers (SoftBody3D "
            "cannot squeeze; Jolt only for the rigid fall that exists), so the two sides cannot drift",
    "field": "a solid from a function of space: a scalar field over a grid → marching cubes (iso); union / "
             "subtract / intersect as min / max of distance fields (boolean) — to be checked against the "
             "boolean_surfaces halls before the CSG nodes are dropped",
    "measure": "the instrument half of the grammar (Palle, 23 Oct: \"add measure as the sixth piece\"): a value READ off "
               "a thing — a length, a count, an entropy, a projection, a loss — `{\"op\":\"measure\",\"of\":{…},"
               "\"what\":\"length|count|entropy|…\"}`; RETAINED across steps as a record, a trail, a history (the "
               "sibling of `trace_data`, which carries what a visitor meant); and COMPARED with another under a stated "
               "rule (`{\"op\":\"compare\",\"a\":…,\"b\":…,\"rule\":…}`). It is what the spine's principles "
               "mostly say — compare (104), measure (67), retain (45) of the 420 — and no construction says it. Shown "
               "as a label, a bar or a readout beside the thing it reads; both builders",
}

# ── where the edges and the leaks go ────────────────────────────────────────────────────────
# Palle, 23 Oct: "where does leaks, edges go?" Every rule refuses something (doc/EDGE_INVENTORY.md:
# thirteen material kinds), and what it refuses is a LEAK — kept on the LeakData bus, named,
# never counted. A kernel piece is a rule, so each has edges BY CONSTRUCTION: its parameters.
# They are declared here so a family inherits them openly instead of shipping a silent ceiling
# (the Cantor set's MIN_SEGMENT_WIDTH, "THE SHIPPED DEPTH IS A LIE", is a replicate edge).
EDGES = {
    "connect": [("coupling", "the relation itself", "the two parts' right to differ — a spring pulls them alike; the "
                 "difference it removes each tick is the leak", "spill: the displacement a spring undid")],
    "by": [("quantiser", "index", "everything between two parts: f is sampled at integers, the curve between them "
            "is never built", "spill: the curve between the samples, as points"),
           ("order", "seed", "every other sequence the seed did not choose", "no spill — nothing was computed")],
    "replicate": [("ceiling", "depth / n", "the copies past the bound — MAX_DEPTH 24 in builder.gd; the Cantor set's "
                   "fourth removal (EDGE_INVENTORY: deadband at 0.01 m)", "spill: the transforms of the copies not built"),
                  ("deadband", "min size", "a copy smaller than the floor — the level at which a fractal stops being a "
                   "picture of itself", "spill: the sub-floor copies, as points")],
    "step": [("clock", "tick", "what happens between two ticks — the rule refuses on its own time", "no spill"),
             ("ball", "radius", "every neighbour outside the radius (boids, verlet): one region, every arrival "
              "alike", "spill: the neighbours a part did not see"),
             ("shelf", "clamp", "the stiffness, speed or force past the clamp", "spill: the force removed")],
    "measure": [("quantiser", "resolution", "everything finer than the instrument reads — a length to the millimetre, an "
                 "entropy to two decimals; the thing has more than the reading", "spill: the residual, as a number the bus "
                 "does not rank"),
                ("window", "record length", "what the record forgets — a trail keeps the last N, a history the last T; "
                 "the earlier passage is gone from the end you are not watching", "spill: the dropped entries"),
                ("coupling", "comparison rule", "what the rule equates — two things compared as lengths lose the right to "
                 "differ in everything but length", "no spill — the rule is named, which is the whole lesson")],
    "field": [("deadband", "iso threshold", "every value under the threshold — the field exists there and no surface is "
               "drawn", "spill: the sub-threshold cells"),
              ("mask", "subtract", "the subtracted volume — a body that is never seen; boolean's remainder is the "
               "clearest leak in the kernel", "spill: the subtracted volume, as points"),
              ("quantiser", "grid", "the surface between grid cells (marching cubes interpolates, it does not know)",
               "no spill")],
}
# Known material edges a family inherits from the artifact it twins (doc/EDGE_INVENTORY.md).
FAMILY_EDGES = {
    "fractal": "example_8_4_cantor_set_vr.MIN_SEGMENT_WIDTH — deadband 0.01 m; a twin that draws four rows under a "
               "label that says six repeats the lie unless it spills the missing rows",
    "crisis_table": "print_gallery_recursion.MIN_APERTURE_M — deadband 0.012 m; the sixth Escher frame is a floor, not "
                    "a vanishing point",
    "axis_sweep": "artifact_dna_critic.py.INERT_FOCUS — deadband 3 %; a variant that moves less is called decoration; "
                  "the sweep stood up in a hall must show the quiet variant too",
    "self_member": "builder.gd.MAX_DEPTH — the refusal IS the exhibit; the leak is the term that was asked for",
    "boolean_pair": "the subtracted volume — spill it; it is the clearest leak the kernel has",
    "scalar_field": "the iso threshold — the field under it exists and is not drawn",
}
# The scaffold is a leak too: what a construction removes when it is done (the line inside the
# tape). composite.gd spills it to LeakData as kind "scaffold" before freeing it.

# Four waves, by what the kernel needs. Not spine order: one piece unlocks many sequences.
WAVES = {
    1: "`connect`, `by`, `measure`, `step` with its first rule (spring) — fourteen sequences build on the kernel as it is plus these",
    2: "`replicate` — the self-containing terms",
    3: "the remaining `step` rules (ca, verlet, boids, learn) and `field`",
    4: "synthesis — no new construction: compare the grammar, turn its parameters, rewrite it",
}

# The spine's own phases are the chapters. No second taxonomy.
PHASE_CHAPTER = {"F_order": "order", "oscillation": "oscillation", "E_entropy": "entropy", "lambda_edge": "edge",
                 "integration": "integration", "relation": "relation", "synthesis": "synthesis"}

# Which existing terms.json chapters already stand in which sequence (the `have` column).
CHAPTER_SEQ = {"point": "primitives", "line": "primitives", "association": "primitives", "triangle": "primitives",
               "solid": "primitives", "assemblage": "primitives", "transformation": "transformation",
               "array": "array_tutorial", "motion": "change", "logic": "cellularautomata"}

# One entry per spine sequence. `room` is the sub-heading inside the phase chapter (the old
# chapter name, kept for the tutorial path). `families` are (name, expression, axis) — an axis is
# "name: v1|v2|v3" or "" for a singleton; declared on the mod_ token as dna.axes, so the DNA
# sweep, gallery and bite critic apply to it unchanged. `needs` are KERNEL keys.
PROPOSALS = {
    "primitives": dict(room="point · line · triangle · solid", wave=1, needs=["measure"], families=[
        ("length", "measure(line): the distance between its two points, read beside the line — dist(point, point) = length", "show: label|bar|readout"),
        ("vector", "line + cone at the end", "head: arrow|none"),
        ("plane", "quad + association(surface)", "surface: paper|wood|concrete"),
    ]),
    "transformation": dict(room="transformation", wave=1, needs=["by"], families=[
        ("transform_cube", "transform(cube, …)", "op: translate|rotate|scale|mirror"),
        ("ride", "cube + by(lerp between two transforms, t)", ""),
    ]),
    "array_tutorial": dict(room="array", wave=1, needs=[], families=[
        ("array_cube", "replicate(cube, array)", "rank: row|grid|stack|grid_3d"),
        ("index_label", "array_cube + label per cell", ""),
    ]),
    "color": dict(room="colour", wave=1, needs=["by"], families=[
        ("swatch", "quad + association(surface: hex)", ""),
        ("swatch_row", "array(swatch) by(list of colours)", "set: gradient|census_17"),
        ("light_colour", "point + light(colour)", ""),
    ]),
    "tiling": dict(room="tiling", wave=1, needs=["by"], families=[
        ("tile", "quad + association(surface)", ""),
        ("tiling", "array(tile) 2D by(rotation)", "rule: square|truchet|meander"),
    ]),
    "change": dict(room="motion", wave=1, needs=["by"], families=[
        ("slide", "cube + by(lerp, t)", "kind: slide|clock|choreography"),
    ]),
    "forces": dict(room="physics", wave=1, needs=["connect", "step", "measure"], families=[
        ("velocity_readout", "measure(drop, velocity) retained as a trail; compare(two drops, rule: which stops first) — ending force is not stopping motion", "retain: value|trail|history"),
        ("drop", "sphere_collider + step(gravity) — the fall", ""),
        ("spring_pair", "connect(sphere_collider, sphere_collider) + step(spring)", ""),
        ("force_field", "grid + step(field)", "kind: field|conveyor"),
    ]),
    "formfinding": dict(room="physics", wave=1, needs=["connect", "step"], families=[
        ("chain", "array(grab_sphere) + connects + step(spring), ends held", "form: chain|catenary|membrane"),
    ]),
    "wavefunctions": dict(room="wave", wave=1, needs=["by", "measure"], families=[
        ("spectrum_reading", "measure(wave_line, frequency · amplitude · phase) retained over t", "measure: frequency|amplitude|phase"),
        ("wave_line", "array(point) + by(sine, phase by index, t)", "kind: line|interference|spectrum"),
        ("synth_rack", "array(wave_line) + grabbable sliders", ""),
    ]),
    "randomness": dict(room="chance", wave=1, needs=["by", "measure"], families=[
        ("entropy_meter", "measure(scatter, shannon entropy); compare(sample order, symbol shares, entropy) without equating them — shannon_entropy_meter stands here", "measure: count|share|entropy"),
        ("chance", "thing + by(random, seed)", "kind: dice|scatter|walk|room"),
    ]),
    "noise": dict(room="noise", wave=1, needs=["by"], families=[
        ("noise_thing", "array(point) + by(noise, seed)", "kind: line|field|terrain"),
    ]),
    "shaders": dict(room="shader", wave=1, needs=[], families=[
        ("shaded_quad", "quad + association(shader)", "shader: ink|gradient|noise|screen"),
    ]),
    "cellularautomata": dict(room="automaton", wave=3, needs=["step", "measure"], families=[
        ("rule_census", "measure(rule_row, count of live cells) retained per generation — the rule read as a number", "measure: count|density"),
        ("cell", "cube + logic(state)", ""),
        ("rule_row", "array(cell) + step(ca)", "rule: rule30|rule110|life"),
    ]),
    "fractals": dict(room="recursion", wave=2, needs=["replicate"], families=[
        ("fractal", "replicate(X, recurse, depth)", "of: koch_line|tree|sierpinski"),
    ]),
    "lsystems": dict(room="grammar", wave=2, needs=["replicate"], families=[
        ("turtle", "stick + the rewrite interpreter", ""),
        ("rewrite_tree", "replicate(stick, rewrite: axiom, rules, generations)", "kind: tree|growth"),
    ]),
    "proceduralgeneration": dict(room="generation", wave=1, needs=["by"], families=[
        ("generated", "walls + by(random, seed)", "kind: room|dungeon|tower"),
    ]),
    "softbodies": dict(room="soft", wave=3, needs=["step"], families=[
        ("soft_body", "grid of grab_spheres + connects + step(verlet)", "form: jelly|cloth|squeeze"),
    ]),
    "isosurfaces": dict(room="field", wave=3, needs=["field", "measure"], families=[
        ("field_probe", "measure(scalar_field at a point) — the value under the threshold, read where no surface is drawn", ""),
        ("scalar_field", "grid + field(iso)", "show: field|metaball|marching"),
    ]),
    "boolean_surfaces": dict(room="boolean", wave=3, needs=["field"], families=[
        ("boolean_pair", "field(cube, sphere)", "op: union|subtract|intersect"),
    ]),
    "swarmintelligence": dict(room="swarm", wave=3, needs=["step"], families=[
        ("flock", "array(sphere_collider) + step(boids)", "show: boid|flock|trail"),
    ]),
    "graphtheory": dict(room="relation", wave=1, needs=["connect"], families=[
        ("node", "point + label", ""),
        ("edge", "connect(node, node)", ""),
        ("graph", "array(node) + connects", "show: graph|path"),
    ]),
    "machinelearning": dict(room="learning", wave=3, needs=["connect", "step", "measure"], families=[
        ("loss_meter", "measure(learner, loss) retained over steps; compare(two learners, rule: lower loss)", "retain: value|history"),
        ("dataset", "scatter + by(colour by class)", ""),
        ("learner", "array(node) + connects + step(learn)", "kind: perceptron|descent"),
    ]),
    # The three synthesis sequences add no construction; they add the three things one can do to
    # the grammar — compare it, turn its parameters, rewrite it. Their plaques, sliders and
    # workbenches stay; these stand beside them.
    "foundationscrisis": dict(room="compare", wave=4, needs=["replicate"], families=[
        ("crisis_table", "assemblage(one hero per chapter, 1–22) — the whole path on one table", ""),
        ("self_member", "replicate(grab_sphere, recurse, depth ∞) — the kernel REFUSES; the refusal, printed by the "
                        "hand message, is the exhibit (Russell)", ""),
        ("undecided_plaque", "label + the builder's own error text for a term it cannot build (Gödel)", ""),
    ]),
    "qfeplaboratory": dict(room="parametrize", wave=4, needs=["by", "step", "measure"], families=[
        ("dial_reading", "measure(dial) compared under λ: the same flock read at two settings — the lab reads its own instrument", "compare: lambda|phi"),
        ("axis_sweep", "array(term) by(its own dna axis) — every family's variants in a row, the DNA sweep stood up", ""),
        ("dial", "slider + step(rule weighted by the dial) on a flock, a rule_row or a membrane", "of: lambda|phi"),
    ]),
    "postfoundationscrisis": dict(room="rewrite", wave=4, needs=["replicate"], families=[
        ("open_term", "a term whose build the visitor edits in the hall — spawn menu + hand message, the studio in VR", ""),
        ("after_table", "replicate(crisis_table, rewrite: the visitor's rule) — the same parts, another order", ""),
        ("commons_table", "assemblage of what visitors left — the proposal lane of the live update chain", ""),
    ]),
}

# The loop one sequence goes through. Printed once; every row points at it.
LOOP = [
    "**scan** — `python tools/modular_scan.py` reads the sequence's artifacts into primitives, parts, behaviour, "
    "interaction (a hypothesis, coarse by design)",
    "**name** — author the row's families in `/modular-studio` (expression, parents, build JSON, Save to terms.json); "
    "each is a gate: the construction plays, the scaffold goes, the thing stands alone; the axis goes on the "
    "mod_ token as `dna.axes`, DERIVED from the build, never typed",
    "**grow** — if the row needs a kernel piece, add it to `builder.gd` AND `modular-terms.ts` in the same change, "
    "with a family that uses it, so the two renderers cannot drift",
    "**prove** — `probe_modular.gd` (every term builds, no body without a collider, no busy-parent warnings), "
    "`check_compile.gd`, `tsc` on the modular files, `check_dna_declarations.py` on the new axes",
    "**register** — `python tools/build_modular_registry.py` (mod_<term> tokens), `capture_multi_angle` per token "
    "(windowed; headless saves nothing), `build_dna_gallery.py` per family, `sync_artifact_captures.py`, "
    "`build_void_spawnlists.py`",
    "**twin** — stand the family's mod_ token beside the floor's primary through the bridge "
    "(`live_update_spawn_test.py --via-bridge --token mod_<term>`); rooms.json is the one model; a map gets it only "
    "where the hall is map-authored",
    "**path** — `python tools/modular_path.py` regenerates MODULAR_PATH.md; the lesson now has rooms to stand in",
    "**walk** — the headset (APK export) or `--vr-link` desktop; the hand message names what arrived",
]

# What a floor's artifact becomes. A DOCUMENT (film, plaque, screen, slider, readout) is never a
# construction and stays. A placement the scanner already reads as a small term is a SWAP
# candidate (Palle's call, per floor, never in bulk). The floor's first ruled-primary construction
# gets a TWIN (its reconstruction beside it). Everything else is KEPT.
DOCUMENT = ("film_", "plaque", "screen", "_vr", "readout", "display", "monitor", "slider", "letters",
            "counter", "chalkboard", "workbench", "booth", "wiki", "table", "timeline", "visualiz",
            "diptych", "fixture", "stack", "label", "sign")
SWAP_TERMS = {"point", "sphere_collider", "grab_sphere", "collider", "warhol_box", "game_spaces", "pick_up_cube"}


def classify(token: str, role: str, sig: dict, twinned: bool) -> str:
    t = token.lower()
    if t == "tt" or any(d in t for d in DOCUMENT):
        return "document"
    g = sig.get(token)
    if g and g.get("term") in SWAP_TERMS and sum(g["primitives"].values()) <= 4 and not g.get("behaviour"):
        return "swap"
    if role == "primary" and not twinned:
        return "twin"
    return "kept"


def load() -> tuple[list[dict], dict, dict, dict]:
    spine = json.loads(SPINE.read_text(encoding="utf-8"))["spine"]["sequences"]
    terms = json.loads(TERMS.read_text(encoding="utf-8"))
    sig = json.loads(SIGNATURES.read_text(encoding="utf-8"))["signatures"]
    tree = {c["id"]: c for c in json.loads(SPAWNLISTS.read_text(encoding="utf-8"))["trees"][0]["children"]}
    return sorted(spine, key=lambda s: s["order"]), terms, sig, tree


def variants(axis: str) -> int:
    return len(axis.split(":", 1)[1].split("|")) if axis else 1


def rows() -> list[dict]:
    spine, terms, sig, tree = load()
    have = collections.defaultdict(list)
    for tid, t in terms["terms"].items():
        have[CHAPTER_SEQ.get(t.get("chapter", ""), "")].append(tid)
    out = []
    for s in spine:
        name = s["name"]
        node = tree.get(name, {"children": []})
        maps = node["children"]
        toks = [t for m in maps for t in m["items"]]
        read = collections.Counter(sig[t]["term"] for t in toks if t in sig and sig[t].get("term"))
        prims = collections.Counter()
        beh = grab = 0
        for t in toks:
            g = sig.get(t)
            if g:
                prims.update(g["primitives"].keys())
                beh += int(bool(g["behaviour"]))
                grab += int(bool(g["interaction"]))
        p = PROPOSALS.get(name, dict(room="?", wave=0, needs=[], families=[]))
        fams = [dict(name=n, expr=e, axis=a, variants=variants(a), edge=FAMILY_EDGES.get(n, "")) for n, e, a in p["families"]]
        out.append(dict(order=s["order"], name=name, phase=s["phase"], chapter=PHASE_CHAPTER.get(s["phase"], s["phase"]),
                        room=p["room"], role=s.get("qfep_role", ""), maps=len(maps), arts=len(toks), beh=beh,
                        grab=grab, read=[list(x) for x in read.most_common(3)], prims=[list(x) for x in prims.most_common(4)],
                        have=have.get(name, []), wave=p["wave"], needs=p["needs"], families=fams,
                        variants=sum(f["variants"] for f in fams)))
    return out


def floors(sig: dict, tree: dict) -> list[dict]:
    """Every Void floor, in Void order, with its sequence and its artifacts classed."""
    rooms = json.loads(ROOMS.read_text(encoding="utf-8"))["floors"]
    roles = json.loads(ROLES.read_text(encoding="utf-8"))["roles"]
    # the book's edge sentence per map: the dependency the map cannot absorb (the edges corpus)
    edges = {}
    for bf in sorted((ROOT / "commons/data/book").glob("*.json")):
        try:
            for pearl in json.loads(bf.read_text(encoding="utf-8")).get("pearls", []):
                if pearl.get("edge"):
                    edges.setdefault(pearl.get("map", ""), str(pearl["edge"]))
        except (json.JSONDecodeError, AttributeError):
            continue
    map_seq = {}
    for seq_id, node in tree.items():
        for m in node["children"]:
            map_seq.setdefault(m["id"], seq_id)
    out = []
    for i, f in enumerate(rooms):
        m = f.get("map", "")
        ruled = roles.get(m, {})
        twinned = False
        arts = []
        for a in f.get("artifacts", []):
            tok = str(a.get("artifact", ""))
            role = ruled.get(tok, "primary")   # unruled placements are primary
            cls = classify(tok, role, sig, twinned)
            if cls == "twin":
                twinned = True
            arts.append(dict(token=tok, role=role, cls=cls))
        out.append(dict(index=i, map=m, title=f.get("title", m), sequence=map_seq.get(m, ""),
                        artifacts=arts, props=len(f.get("props", [])), edge=edges.get(m, "")))
    return out


def render(rs: list[dict], fls: list[dict]) -> str:
    _, terms, _, _ = load()
    n_terms = len(terms["terms"])
    n_fam = sum(len(r["families"]) for r in rs)
    n_var = sum(r["variants"] for r in rs)
    tot = collections.Counter(a["cls"] for f in fls for a in f["artifacts"])
    by_seq = collections.defaultdict(list)
    for f in fls:
        by_seq[f["sequence"]].append(f)
    L = []
    L.append("# The spine in the class system — the plan, as a list (compressed)\n")
    L.append("*Generated by `tools/modular_spine_plan.py`. The numbers are read from `curriculum_spine.json`, "
             "`modular_signatures.json`, `void_spawnlists.json`, `rooms.json` and `artifact_roles.json`; the proposed "
             "families are authored in the script and are proposals until someone saves them in the studio. "
             "Palle, 23 Oct 2026: \"make a plan to integrate all the spine in a list\" … \"fold the compressed "
             "version into the plan.\"*\n")
    L.append(f"The grammar has **{n_terms} terms** today, almost all of them the primitives sequence. The spine has "
             f"**{len(rs)} sequences, {sum(r['maps'] for r in rs)} maps, {sum(r['arts'] for r in rs)} placed artifacts, "
             f"{len(fls)} Void floors**. The plan proposes **{n_fam} families ({n_var} variants through their axes)** "
             f"in the spine's own **seven phase chapters**, and names the **six pieces the kernel must grow** to "
             "build them. A family is one term with a `dna.axes` declaration, so the registry's sweep, gallery and bite "
             "critic apply to every variant for free. Every family is built from terms that exist, so the derivation "
             "order stays a tutorial path. Nothing on a floor is rebuilt; the order is Palle's.\n")
    L.append("## What was compressed\n")
    L.append("- twelve engines → **two** (`by`: a function of index and time per part; `step`: a rule per part from "
             "its neighbours), with the rule names kept for the lessons;")
    L.append("- `vary` → the same `by` at t = 0; array, times, recurse, rewrite → **one `replicate`** with four presets;")
    L.append("- the shader axis → a key on `associate` (the ink stroke already proves it), not a kernel piece;")
    L.append("- boolean and isosurface → **one `field`** (a solid from a function of space), to be checked against the "
             "boolean halls;")
    L.append("- 82 terms → **%d families**; 17 new chapters → the **7 spine phases**; 6 waves → **4**; `connect` moved "
             "to wave 1 because a spring is a connect with a rule;" % n_fam)
    L.append("- the done gate: not the scanner (it matches primitive sets and will never read a flock as swarm) but "
             "**every floor's primary has a twin** — a finite target;")
    L.append("- one verlet in both renderers, Jolt only for the rigid fall that exists — a second implementation of one "
             "rule drifts (the long-museum lesson).\n")
    L.append("## The loop — what one sequence goes through\n")
    for i, step in enumerate(LOOP, 1):
        L.append(f"{i}. {step}")
    L.append("")
    L.append("## The order — four waves, by what the kernel needs\n")
    for w, label in WAVES.items():
        names = [f"{r['order']}·{r['name']}" for r in rs if r["wave"] == w]
        L.append(f"- **wave {w}** — {label}: {', '.join(names)}")
    L.append("")
    L.append("## The list — one row per spine sequence\n")
    L.append("| # | sequence | chapter · room | maps | artifacts | floors | twins | swap | docs | terms now | families (variants) | wave | needs |")
    L.append("|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    for r in rs:
        fl = by_seq.get(r["name"], [])
        c = collections.Counter(a["cls"] for f in fl for a in f["artifacts"])
        L.append(f"| {r['order']} | {r['name']} | {r['chapter']} · {r['room']} | {r['maps']} | {r['arts']} | {len(fl)} | "
                 f"{c['twin']} | {c['swap']} | {c['document']} | {len(r['have'])} | {len(r['families'])} ({r['variants']}) | "
                 f"{r['wave']} | {', '.join(r['needs']) or '—'} |")
    L.append("")
    L.append("## The families — what each sequence adds to the grammar\n")
    for r in rs:
        L.append(f"### {r['order']}. {r['name']} — chapter *{r['chapter']}*, room *{r['room']}*, wave {r['wave']}\n")
        L.append(f"*{r['role']}* · {r['maps']} maps, {r['arts']} artifacts, {len(by_seq.get(r['name'], []))} floors; "
                 "the scanner's primitives: " + ", ".join(f"{k} {v}" for k, v in r["prims"]) + ".\n")
        if r["have"]:
            L.append("Already in the grammar: " + ", ".join(f"`{t}`" for t in r["have"]) + ".\n")
        if r["needs"]:
            L.append("Needs first: " + ", ".join(f"`{n}`" for n in r["needs"]) + ".\n")
        for f in r["families"]:
            ax = f" — axis `{f['axis']}` ({f['variants']} variants)" if f["axis"] else ""
            L.append(f"- `{f['name']}` = {f['expr']}{ax}")
            if f["edge"]:
                L.append(f"  - *edge it inherits:* {f['edge']}")
        L.append("")
    L.append("## The kernel work list — six pieces, each named once\n")
    users = collections.defaultdict(list)
    for r in rs:
        for n in r["needs"]:
            users[n].append(r["name"])
    for key, text in KERNEL.items():
        L.append(f"- **{key}** — {text}. Used by: {', '.join(users.get(key, [])) or 'nobody yet'}.")
    L.append("")
    L.append("## The edges of the kernel — and where the leaks go\n")
    L.append("Every rule refuses something (`doc/EDGE_INVENTORY.md`: thirteen material kinds), and what it refuses is "
             "a **leak**: kept on the `LeakData` bus, named, never counted. A kernel piece is a rule, so each has edges "
             "by construction — its parameters. They are declared here so a family inherits them in the open instead of "
             "shipping a silent ceiling (the Cantor set's fourth removal is a `replicate` edge). The scaffold is a leak "
             "too: what a construction removes when it is done, the line inside the tape — `composite.gd` spills it "
             "before freeing it. The conceptual edges A–M (`doc/EDGES_OF_ALGORITHM.md`) are not kernel pieces; they are "
             "what the late-spine families are *about*, and the plan reads φ·dE as their political term: what F leaves "
             "out accumulates over t, and the leak bus is where it accumulates.\n")
    L.append("| piece | edge kind | parameter | what escapes | leak |")
    L.append("|---|---|---|---|---|")
    for key, rows_ in EDGES.items():
        for kind, param, escapes, leak in rows_:
            L.append(f"| {key} | {kind} | {param} | {escapes} | {leak} |")
    L.append("")
    n_edge = sum(len(v) for v in EDGES.values())
    inherited = [(r["name"], f["name"]) for r in rs for f in r["families"] if f["edge"]]
    L.append(f"{n_edge} declared edges on six pieces; {len(inherited)} families inherit a named material edge from the "
             "artifact they twin: " + ", ".join(f"`{f}` ({s})" for s, f in inherited) + ". A twin that hides the "
             "edge its original shows is a lie twin; the gate is that it spills what the original dropped.\n")
    L.append("## The floors — what each Void floor becomes\n")
    L.append(f"{len(fls)} floors in `commons/void/rooms.json`, {sum(tot.values())} artifacts: **{tot['twin']} twins** "
             f"(one reconstruction per floor, beside the primary), **{tot['swap']} swap candidates** (already a small "
             f"term; Palle's call per floor), **{tot['document']} documents** (films, plaques, screens, sliders — never a "
             f"construction), **{tot['kept']} kept** as they are. No floor is rebuilt; walls, route and props stay. "
             "Drawn at `/modular-plan`; stood up in three.js at `/modular-plan/3d`. "
             f"{sum(1 for f in fls if f['edge'])} of the floors carry the book's own edge sentence (the dependency the "
             "hall cannot absorb, `edge` on its pearl in `commons/data/book/*.json`) — the rest of that corpus is keyed "
             "to the museum's chambers, not to Void floors, so it does not reach them here.\n")
    L.append("## Done looks like\n")
    L.append("- every spine sequence has its families saved from the studio under its phase chapter, each a gate that "
             "plays and ends with the intended thing alone, each axis declared from the build and passing the "
             "declaration gate;")
    L.append("- `probe_modular` builds every term; the registry has a `mod_` token, a capture and a DNA gallery per family;")
    L.append(f"- **every floor's primary has a twin beside it** ({tot['twin']} floors), placed through the bridge and "
             "seen on the headset; swaps only where Palle marked them;")
    L.append("- `MODULAR_PATH.md` reads as the tutorial: seven phase chapters in spine order, every lesson built from "
             "lessons before it, with rooms to stand in;")
    L.append("- the synthesis floors hold the three meta-terms: the grammar compared, parametrized, rewritten.")
    L.append("")
    return "\n".join(L)


def main() -> int:
    rs = rows()
    _, _, sig, tree = load()
    fls = floors(sig, tree)
    text = render(rs, fls)
    if "--print" in sys.argv:
        print(text)
        return 0
    OUT.write_text(text, encoding="utf-8")
    JSON_OUT.write_text(json.dumps(dict(
        _doc="GENERATED by tools/modular_spine_plan.py — the spine plan as data for /modular-plan; edit the script.",
        waves=WAVES, kernel=KERNEL, edges=EDGES, chapters=PHASE_CHAPTER, sequences=rs, floors=fls), indent=1), encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)} + {JSON_OUT.relative_to(ROOT)} — {len(rs)} sequences, "
          f"{sum(len(r['families']) for r in rs)} families / {sum(r['variants'] for r in rs)} variants, "
          f"{len(KERNEL)} kernel pieces, {len(fls)} floors")
    return 0


if __name__ == "__main__":
    sys.exit(main())
