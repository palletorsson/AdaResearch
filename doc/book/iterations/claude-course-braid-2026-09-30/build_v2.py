"""Build course.json v2 and COURSE_v2.md from the winner (course_v1.json).

v2 (2026-10-01, Palle: "refine this order to make it possible to introduce capacity to
make different assemblages or forms in logical Ada order"): the winner's chapters are
kept, reordered into the spine's order of FORM OPERATIONS, grouped into parts that each
add operations to the student's toolkit, and closed by ASSEMBLAGE chapters where the
operations learned so far are composed into one body. Three chapters are new, one is
split. Everything else is the winner's text.

Run from this folder:  python build_v2.py
It refuses to write when the code ladder is broken or a hall does not exist.
"""
import json, os, re, sys, copy

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
V1 = json.load(open(os.path.join(HERE, "course_v1.json"), encoding="utf-8"))

# ---------------------------------------------------------------- the spine (halls exist?)
SPINE = json.load(open(os.path.join(REPO, "commons/maps/curriculum_spine.json"), encoding="utf-8"))
ORDER, HALLSEQ = {}, {}
for s in SPINE["spine"]["sequences"]:
    ORDER[s["name"]] = s["order"]
    d = json.load(open(os.path.join(REPO, f"commons/maps/sequences/{s['name']}.json"), encoding="utf-8"))
    q = d["sequences"].get(s["name"]) or list(d["sequences"].values())[0]
    for m in q.get("maps", []):
        HALLSEQ[m if isinstance(m, str) else (m.get("map") or m.get("name"))] = s["name"]

CH = {c["id"]: copy.deepcopy(c) for c in V1["chapters"]}

# ---------------------------------------------------------------- edits to winner chapters
def edit(cid, **kw):
    CH[cid].update(kw)

# ch13 is now the first chapter of Part 2; it must not lean on the chessboard (ch9), which now comes after it.
edit("ch13", code_returns=[x for x in CH["ch13"].get("code_returns", []) if x not in ("instancing", "nested_loops", "materials")])

# ch09: instancing is first met at ch42 (a body of parts), which now comes before the chessboard.
edit("ch09", code_new=["nested_loops", "materials"], code_returns=CH["ch09"].get("code_returns", []) + ["instancing"])
# ch16: UVs are taught at ch10 (Part 4), after the budget chapter; the catenoid's UVs are set by the supplied emitter.
edit("ch16", code_returns=[x for x in CH["ch16"].get("code_returns", []) if x != "uv"])
# ch29: resources (ch17) and raycasts (ch21) are met later now.
edit("ch29", code_returns=[x for x in CH["ch29"].get("code_returns", []) if x not in ("resources", "raycasts")])
# ch22: the RigidBody3D comparison moves to ch23, where bodies are introduced.
edit("ch22", code_returns=[x for x in CH["ch22"].get("code_returns", []) if x != "physics_bodies"],
     body=CH["ch22"]["body"].replace("; beside it the same launch as a RigidBody3D", " (the same launch as a RigidBody3D is compared at ch23, where bodies arrive)"))
# ch23 introduces physics bodies (six family members released into the region); ch20 keeps signals.
edit("ch23", code_new=["forces", "areas", "physics_bodies"], code_returns=[x for x in CH["ch23"].get("code_returns", []) if x != "signals"])
edit("ch20", code_new=["signals"], code_returns=CH["ch20"].get("code_returns", []) + ["physics_bodies"])
# ch21: composition is first met at ch42; signals come at ch20, which now follows legs; the ground is the plane, not noise.
edit("ch21", code_new=["raycasts"], code_returns=[x for x in CH["ch21"].get("code_returns", []) if x not in ("signals", "noise")] + ["composition"])
# ch27 introduces packed arrays (the WAV's PackedByteArray); ch12 then returns them. Timers come at ch25.
edit("ch27", code_new=["audio", "packed_arrays"], code_returns=[x for x in CH["ch27"].get("code_returns", []) if x not in ("packed_arrays", "timers")])
edit("ch12", code_new=["noise"], code_returns=CH["ch12"].get("code_returns", []) + ["packed_arrays"])
# ch25: the round's score does not persist; save_load is taught at ch17 (Part 7).
edit("ch25", code_returns=[x for x in CH["ch25"].get("code_returns", []) if x != "save_load"])
# ch17 names an L-systems hall as an encounter.
edit("ch17", spine=["proceduralgeneration", "randomness", "lsystems"])

# ch15: the setters/@tool chapter anchors on the first family hall; the colour and softbodies halls are visits.
edit("ch15", spine=["primitives", "color", "softbodies"],
     halls=[{"map": "Primitives_Ignorance", "role": "carrier"}, {"map": "Color_Context_Placed", "role": "field trip"},
            {"map": "Topology_Entropy_Morphogenesis", "role": "field trip"}])

# ch10: the pattern chapter now also dresses the assemblage.
edit("ch10", project_step=CH["ch10"].get("project_step", "") +
     " Then dress the assemblage from Part 3: every part of your body of parts gets a material from your palette (ch29) and one tiled skin by rule; the imported part keeps its own texture, so the seam between made and found stays visible.")

# ch07: the axis as the kit measured it (point-plane, 2026-10-01, 66/66): smooth and flat normals are identical on a flat fan,
# and a face with no normals renders the same, so the visible values are winding and flipped normals.
CH["ch07"]["argument"].update({
    "axis": "winding and the side the face shows",
    "values": ["clockwise", "clockwise, flipped normals", "counter-clockwise", "counter-clockwise, double-sided"],
    "predict": "From above, clockwise and counter-clockwise double-sided will look most alike: both show a lit face and differ only by the shadow (measured: 0.82% of the frame). Counter-clockwise alone shows nothing from above and everything from below. Write which pair you expect before you render.",
})
edit("ch07", debt=CH["ch07"]["debt"] + " Measured in the kit: the collider is one-sided too. A marble falls through a counter-clockwise face from above unless backface_collision is set, so a surface that shows from one side also holds from one side.")

# ch08: the axis as the kit measured it (point-cube, 2026-10-01, 68/68). The winner's axis ("how much the prompt fixes") was a
# claim about what a model returns, which a kit that runs without one cannot measure; the axis is which draft builds the cube.
CH["ch08"]["argument"].update({
    "axis": "which draft builds the cube",
    "values": ["my one face", "the one-line draft (make a cube)", "the three-line draft", "the repaired draft"],
    "predict": "From above, your one face and the three-line draft will look most alike (measured: 0.36% of the frame apart), because the draft's top is wound the wrong way and is absent. The one-line draft, wrong in every triangle, looks like a whole cube from above and like an open room from behind; a marble dropped on it comes to rest inside. Write which pair you expect, from above and from behind, before you render.",
    "claim": "An instruction fixes what it names; naming is not checking. The draft that looks most finished from one side is the one that is wrong everywhere.",
})
edit("ch08", debt=CH["ch08"]["debt"] + " Measured in the kit's first export: assert() is skipped in a release build, push_error() loses its line number there, and the exe without its .pck answers that the project data could not be loaded; what the editor told you, the build may not.")

# ch13: the axis as the kit measured it (organism, 2026-10-01, 83/83). The winner predicted that the pivot at the end and at
# one third would look most alike; measured at 30 degrees per joint, the closest pair is one third and the centre.
CH["ch13"]["argument"].update({
    "axis": "where the pivot sits on each segment, same joint angles",
    "values": ["at the end", "at one third", "at the centre", "outside the bar"],
    "predict": "At rest all four look the same: the pivot moves origins, not bars (measured: no pair differs on more than 0.18% of the frame). With every joint at 30 degrees, one third and the centre are the closest pair, and only the pivot at the end keeps the chain joined: the others open a gap at the knee (5 and 8 cm). Write the pair you expect, at rest and turned, before you render.",
})
edit("ch13", debt=CH["ch13"]["debt"] + " Measured in the kit: delta repairs the speed, not the sampling. At 144, 60 and 30 frames a second one turn of the limb carves the same 33 cells; at 3 frames a second it carves 26, because the foot is only asked where it is when a frame comes.")

# ch09: the argument as the kit measured it (chessboard, 2026-10-01, 57/57). The outline predicted that the chessboard and
# the stripes would look most alike and that only the hue ramp has a direction; cell by cell both are false.
CH["ch09"]["argument"].update({
    "predict": "Cell by cell, every cell alike and the x % 3 stripes are the closest pair: they differ in 24 of 64 cells (measured: 11.12% of the frame from the study camera). The chessboard and the stripes disagree on about half the floor (14.26%). Only when the cells are averaged away do the chessboard and the stripes come closest, and that distance was not rendered: it is arithmetic on the stills. The stripes have a direction too: swapping x and z changes 30 of their cells. Write the pair you expect before you render, and say from how far.",
})
edit("ch09", debt=CH["ch09"]["debt"] + " Measured in the kit: the planted integer division, (x + z) / (2 * n) without float(), gives hue 0 in all 64 cells, a red floor with one warning and no error. One material made before the loops is one material on 64 cubes: change one cube and all 64 change. And the gap a body meets depends on how fast it arrives: a marble let go at 0.75 m passes when the gap equals its width, to the millimetre; dropped from 2 m it passes 2 cm earlier and, just below that, sticks between the cubes. Why it switches where it does is not explained.")

# ch14: the argument as the kit measured it (family, 2026-10-01, 56/56). The outline's closest pair held, the first
# on the short track to do so. Its planted bug did not: Godot 4.6 converts a String handed to a typed int through set().
CH["ch14"]["argument"].update({
    "predict": "16 and 64 will look most alike at 2 m (measured: they differ on 0.85% of the still from the side, 0.99% from above, and stay the closest pair lit flat, at 4.65%). Most of that likeness is smooth shading: the rim differs by a band about 3 pixels wide. From above, the outline of 16 misses the circle by 2.06% (the chord arithmetic gives 1.92%). 4 is another body, but not the octahedron: with rings at half it has two rings and 16 triangles. Write the pair you expect, and what you think the likeness is made of, before you render.",
    "claim": "The class's integer decides which body you have, and there is no step where a sphere stops paying: against 64 the difference falls evenly, 15.27, 5.17, 0.85, 0.19% for 4, 8, 16 and 32 segments. What looks like enough is a decision about distance and light.",
})
edit("ch14", debt=CH["ch14"]["debt"].replace(" And a typed set() refuses a wrong type in silence, so a sweep can publish four identical members and look finished (the Ada project's own science_screen case).", "")
     + " Measured in the kit: set() on a typed int does not refuse a text. It converts it in silence: '16' becomes 16, 'sixteen' becomes 0, '4 8 16 64' becomes 481664, and 640 passes an @export_range of 4 to 64. What set() does refuse in silence is a name the class does not have, and a number handed to a String field. So the planted fault is a wrong field name: four members come back alike under four different plates, and only the printed triangle counts say so (the Ada project's own science_screen case).")

# ch18: the argument as the kit measured it (collage, 2026-10-01, 59/59). Three values, not four: nothing in the kit
# was sculpted by a hand in a headset. The found body is a stand-in made by a script from the solid itself.
CH["ch18"]["argument"].update({
    "values": ["by hand", "drafted from your three lines", "found (a stand-in for a scan)"],
    "predict": "By hand and drafted will look most alike, and here they are the same picture: 0.00% of the still differs from the side, from above and lit flat. The reason is not that they share primitives (one is built with SurfaceTool, the other from an indexed array); the three lines named every number the picture shows. Ask both for a value the lines did not name and they part: a cut of 0.9 is clamped by one and kept by the other, and the stills differ on 14.88%. The found body differs from the solid on about 3% and has 5,851 triangles to its 20. Whether a real scan is the outlier by count and not by silhouette is not tested here: the stand-in was made from the solid, so its outline is near by construction. Write the pair you expect, and what would make two bodies made the same way differ.",
    "claim": "Two bodies that look the same have agreed only about what was named. How a body was made shows in what it does with a value nobody asked for, and in its triangle count.",
})
edit("ch18", debt=CH["ch18"]["debt"] + " Measured in the kit: the import arrives 99.04 m high, its lowest point 4.3 m up and 43 m from its plate, with none of its corners in view. Godot prints no error and still reports the triangle count; the picture shows an empty plate. Scale alone does not bring it home: the file has its own origin, and that is a second fault. The drafted answer in the kit came from one question put once to an assistant of the same kind as the one that wrote the lesson, so it is not an independent witness.")

# ch40: the QFEP chapter speaks of F and of entropy; the method handoff (2026-10-01) asks that both be stated as what they are.
edit("ch40", body=CH["ch40"]["body"].replace("(QFEP's F term)", "(a heuristic reading of QFEP's F term: a prediction error you wrote down, not a measured free energy)"),
     debt=CH["ch40"]["debt"] + " The entropy counted here is the Shannon entropy of the symbol frequencies in one row, a stated distribution and a stated estimator. It is not the entropy of the room, of your search or of you, and the chapter makes no claim about those.")

# ch17 moves to Part 7, where PG_Genetic_Evolution sits on the spine.
edit("ch17", spine=["proceduralgeneration", "randomness"])

# ch18: the collage is the second assemblage.
edit("ch18", title="Collage: a found body joins the family (assemblage II)")

# ch19: the walker is opened where motion is the subject; Trans_Scale becomes the field trip.
edit("ch19", spine=["forces", "transformation", "foundationscrisis"],
     halls=[{"map": "VFM_03_Motion", "role": "carrier"}, {"map": "Trans_Scale", "role": "field trip"},
            {"map": "Escher_Impossible", "role": "field trip"}])

# ch25: the round closes Part 6 as its assemblage (seeded stones over the noise terrain, in the shader skin).
edit("ch25", title="To stand despite all possibilities to fall: a round (assemblage IV, midterm)",
     body=CH["ch25"]["body"] + " In v2 the round is built on your own ground: the stones stand on the noise terrain of ch12, wear the rim shader of ch30, and are members of your family.")

# ch28: the field is sampled from a SUPPLIED sampler until noise is taught (ch12 comes later now).
edit("ch28", code_returns=[x for x in CH["ch28"].get("code_returns", []) if x not in ("noise", "random")],
     halls=[h for h in CH["ch28"]["halls"] if h["map"] != "Noise_Inside_Noise"],
     spine=["change", "forces"],
     body=CH["ch28"]["body"].replace("sampled from noise over the room", "sampled over the room from a supplied field function (opened at ch12, Noise)"),
     departure=None)
CH["ch28"].setdefault("borrows", [])
CH["ch28"]["borrows"] = [{"part": "field.gd: sample(x, z) -> Vector3, a smooth field over the room (opened at ch12, where noise is taught)", "depth": "use"}]

# ch36: implicit only; the boolean half becomes its own assemblage chapter (ch44).
edit("ch36", title="A body with no vertices until you ask: implicit bodies",
     body="A scalar field (metaballs plus noise) sampled on a 3D grid and polygonised by marching cubes with the supplied lookup table, built on a worker thread so the room keeps its frame rate while the body is rebuilt. The CSG half of the winner's chapter is now ch44, Combine.",
     spine=["isosurfaces", "noise"],
     halls=[{"map": "ISO_Introduction", "role": "carrier"}, {"map": "ISO_Metaballs", "role": "carrier"},
            {"map": "ISO_LookupTable", "role": "field trip"}, {"map": "ISO_Sculpting", "role": "field trip"}])

# ch41 is the final assemblage.
edit("ch41", title="Out of the lab: your hall in the collective museum (assemblage VII, final)")

# ---------------------------------------------------------------- three new chapters
NEW = {}
NEW["ch42"] = {
    "id": "ch42", "part": "p2", "title": "A body of parts: the first assemblage",
    "spine": ["transformation"], "verb": "assemble",
    "halls": [{"map": "Trans_Introduction", "role": "carrier"}, {"map": "Trans_Scale", "role": "carrier"},
              {"map": "Trans_Body", "role": "field trip"}, {"map": "Trans_Pre", "role": "encounter"}],
    "code_new": ["instancing", "composition"], "code_returns": ["transforms", "basis", "properties", "lifecycle", "delta"],
    "body": "The parts you have made so far, saved as scenes and instanced into one body: the point (ch2), the cube (ch8), your plane (ch7) and the three-segment limb (ch13), each a PackedScene, each added as a child of one root Node3D with its own pivot. Move the root and every part follows; turn the limb and only the limb's children follow; scale the root and the whole body scales, cube and plane together. The scene tree is the first assemblage: a body is parts in relation, and the tree says which relation.",
    "argument": {"axis": "how the same four parts are parented",
                 "values": ["flat: four children of the root", "a chain: each part the child of the one before", "a chain with offset pivots", "two chains from one hip"],
                 "predict": "At rest, flat and chain look identical: parenting changes nothing you can see in a still. Write that down, then render the sheet one second after the root turns 30 degrees: flat keeps every part where it was relative to the root; the chain swings the last part furthest; offset pivots make the same chain bend at different places. The closest pair is flat and chain at rest; the farthest is chain and offset pivots in motion.",
                 "claim": "An assemblage's structure is invisible at rest and decisive in motion: the tree, not the parts, says what the body does."},
    "debt": "A hierarchy is a command chain. The root moves, the leaves obey, and nothing in the picture shows who commanded whom. Klee drew it as brain, muscle, bone, active to passive; Godot draws it as a tree whose root you chose. The debt is that the choice of root is a choice of who gets to be the body's centre, and the default (the first node you made) is not a neutral one.",
    "place": "Carry the root: pick the whole body up (XR hand or desktop carry) and the parts come with it, pivots and all. Then walk into Trans_Scale with it: the room scales by four, the body scales with the room, and the door you could not use before is usable; the body's relations survive the scale, which is what a hierarchy is for.",
    "godot": ["PackedScene and instantiate()", "add_child, the owner and the scene tree", "local versus global transform in a chain", "scale propagates to children; shear if non-uniform", "Node3D pivots by nesting an empty parent"],
    "lineage": {"processing": "Learning Processing ch14 Transformations (pushMatrix/popMatrix as nesting) [mem]", "noc": "none",
                "application_wp": "pre-WP: 'a body as parts'; WP2 queer meshes, previewed",
                "klee": "I.9-12 bone, tendon, muscle; 'First organ active (brain)' - the trichotomy as a tree [V via v1 ch13]",
                "reference": "Kandinsky, Point and Line to Plane (composition as relation of elements) [V research_bauhaus]; Form+Code 'Transform' [V]; Gaboury, Image Objects, 'Object Paradigms' [V research_ccs]"},
    "departure": None,
    "project_step": "Your room's first assemblage: at least three parts of different origin (one made in code, one drawn by hand in the editor, one carried in from a classmate's scene) under one root. Decide the root and write one line in the README saying why that part commands.",
    "tracks": ["short", "long"],
}
NEW["ch43"] = {
    "id": "ch43", "part": "p7", "title": "Same desire: grown bodies join made ones (assemblage V)",
    "spine": ["proceduralgeneration", "lsystems", "cellularautomata"], "verb": "assemble",
    "halls": [{"map": "PG_Branching_Growth", "role": "carrier"}, {"map": "Assemblage_Same_Desire", "role": "carrier"},
              {"map": "LSystems_Architecture", "role": "field trip"}, {"map": "CA_ExpandingSpace", "role": "field trip"}],
    "code_new": [], "code_returns": ["recursion", "strings", "stacks", "buffers", "instancing", "classes", "export", "seeds"],
    "body": "One body from three growth rules and one made family. The grammar of ch33 grows the frame; the recursion of ch32 branches it; your family members from ch14 hang on the branches as instanced parts, oriented by the turtle's frame; and the cellular automaton of ch31 decides, row by row, which branches are solid and which are ghosts (ch3's if, now driven by a rule in time). Assemblage_Same_Desire is the hall's own version: one array of small choices, drawn as marks, as paths, and as a floor that carries you.",
    "argument": {"axis": "which rule grows the frame, from the same seed and the same hung family",
                 "values": ["the L-system of ch33", "the recursive tree of ch32", "the branching growth of PG_Branching_Growth", "a straight scaffold, no growth (the control)"],
                 "predict": "The L-system and the recursive tree will be the closest pair: both branch by angle and shortening, and from the same seed their crowns fill the same volume. The control will be farthest from all three. Write the predicted closest pair, then render the four with the same family hung on them.",
                 "claim": "The same parts on different frames are different bodies: in an assemblage the growth rule is the body, and the hung family only clothes it."},
    "debt": "Every body a grammar grows looks like the grammar. A rule written in ten lines produces ten thousand branches that all carry its accent, and the accent passes for nature. Who wrote the rule, and what a rule cannot grow (a branch that joins another, a loop, a part that was never a symbol) is the debt; Assemblage_Same_Desire's name says it: the same desire, many paths.",
    "place": "Walk the array as floor, then climb the grown frame: the solid branches (the automaton's live cells) carry you, the ghost branches let you fall. Carry one family member off a branch and the frame does not notice.",
    "godot": ["instancing on a turtle frame (Transform3D from the turtle's basis)", "a rule in time gating colliders (set layers = 0 for ghosts)", "one MultiMesh for the hung family when the count says so", "a seed shared by three rules"],
    "lineage": {"processing": "none", "noc": "ch8 fractals (L-systems), ch7 CA - previewed as one body",
                "application_wp": "WP2 Advanced Elements: fractal subdivision, L-systems, cellular automata, 'queer meshes'",
                "klee": "none: out of the sketchbook",
                "reference": "Prusinkiewicz and Lindenmayer, The Algorithmic Beauty of Plants [mem]; Deleuze and Guattari's assemblage as heterogeneous parts in relation, named by the hall [V application digest]"},
    "departure": None,
    "project_step": "A grown frame of your own with your family hung on it, and one rule you added that the grammar could not express (a branch that joins, a loop, a part that is not a symbol). Write what you had to do by hand to get it.",
    "tracks": ["long"],
}
NEW["ch44"] = {
    "id": "ch44", "part": "p8", "title": "Combine: union, subtraction, intersection (assemblage VI)",
    "spine": ["boolean_surfaces", "isosurfaces"], "verb": "combine",
    "halls": [{"map": "Boolean_Verbs", "role": "carrier"}, {"map": "Boolean_Works", "role": "carrier"},
              {"map": "Boolean_Gallery", "role": "field trip"}, {"map": "ISO_Sculpting", "role": "field trip"}],
    "code_new": ["other:csg"], "code_returns": ["meshes", "collision", "instancing", "classes", "profiling"],
    "body": "A body carved from your assemblage with three verbs: the union of two family members, the subtraction of the implicit body of ch36 (its tunnel bored through the union), and the intersection with the shell of the scanned body from ch18. CSGCombiner3D holds the operands as children, in order; then the result is baked to a mesh with a collider made from it, because a CSG body is a renderer's interior and physics is told nothing (Boolean_Works' lesson: seventy-five objects offer themselves to your hand and are not there).",
    "argument": {"axis": "the order of the same three operands and verbs",
                 "values": ["(A union B) minus C", "(A minus C) union B", "(A intersect B) minus C", "A minus (B union C)"],
                 "predict": "The first two will be the closest pair: they differ only where C overlaps B, so with C's tunnel through A alone they are the same body. The third will lose most of its volume (an intersection keeps only the overlap). Write the predicted closest pair and the volume order, then render.",
                 "claim": "Boolean combination is not commutative: the order of the verbs is part of the form, and a body carved by subtraction has an inside only where the physics was told so."},
    "debt": "The picture of an inside against an inside. A CSG interior renders perfectly and holds nothing: Boolean_Works hangs 'WALK THE HOLLOW' over a metre of solid rock beneath a cave whose floor is above your head. Baking fixes it at a cost: the seams of a subtraction multiply triangles (polycount against smooth deformation, ch16's debt returns), and the baked mesh forgets its verbs, so the body can no longer be re-carved. An interior is an agreement between the renderer and the physics, and someone has to write it.",
    "place": "Walk into the tunnel before baking and fall through the floor (the hall's own failure, now yours); bake, walk in, and stand in the hollow. Then put the baked body in the museum hall and let a classmate find the seam.",
    "godot": ["CSGCombiner3D, CSGMesh3D, operation = UNION | SUBTRACTION | INTERSECTION", "operand order is child order", "bake_static_mesh() / bake_collision_shape() to a MeshInstance3D + StaticBody3D", "use_collision on the combiner for a prototype only", "triangle count before and after baking"],
    "lineage": {"processing": "none", "noc": "none",
                "application_wp": "WP2 'the algorithmic topology of desire and the creation of queer meshes'; 'Deformation and Polygon Count'",
                "klee": "I.12 'stone upon stone' (additive) against 'chip from chip' (subtractive) [V klee_ps l.420-428 via v1]",
                "reference": "Form+Code 'Transform' and 'Parameterize' [V]; Gaboury, Image Objects, hidden surfaces [V research_ccs]; Boolean_Works' B3 SYNTHESIZE curriculum role [V intent.md]"},
    "departure": None,
    "project_step": "One carved body in your room with its verbs written beside it (the operand order as a line of text on the plinth), baked, standable, and its triangle count before and after baking in the README.",
    "tracks": ["long"],
}
ADD = json.load(open(os.path.join(HERE, "v2_additions.json"), encoding="utf-8"))
for _id, _ch in ADD["chapters"].items():
    NEW[_id] = _ch
for _id, _e in ADD["edits"].items():
    _t = NEW[_id] if _id in NEW else CH[_id]
    if "body_append" in _e:
        _t["body"] = _t["body"] + _e["body_append"]
    for _k in ("works", "borrows"):
        if _k in _e:
            _t[_k] = _t.get(_k, []) + _e[_k]
for k, v in NEW.items():
    v.setdefault("opening_stop", None); v.setdefault("kit", None); v.setdefault("status", "planned"); v.setdefault("status_note", None)
    CH[k] = v

# ch42: the axis as the kit measured it (body-of-parts, 2026-10-01, 82/82). The chapter said the parenting shows once the
# root turns. It does not: the four arrangements are pixel-identical at rest AND while only the root moves.
CH["ch42"]["argument"].update({
    "values": ["flat: four children of the root", "a chain: each part the child of the one before", "a chain with offset pivots", "two chains from one hip"],
    "predict": "At rest all four look the same, and they still look the same when the root turns 30 degrees: every pair differs on 0.00% of the frame, because a root carries everything below it whatever the tree looks like. Turn every pivot 30 degrees and they part: flat and two chains stay closest (0.55% of the frame), the offset chain and two chains are farthest (4.77%), and the toe travels 0.47 m in the flat body against 2.61 m at the end of the chain. Write which pair you expect closest, and when you expect any difference at all, before you render.",
    "claim": "The structure of an assemblage is invisible at rest and while only its root moves; it shows when a part inside moves. The tree, not the parts, says what the body does.",
})

# ---------------------------------------------------------------- the v2 order: parts of form operations
PARTS = [
    ("p1", "Place and join (primitives; Klee I.1-4)",
     "You can put a body where you say, give it size and a boundary, carry it, join two into a line, keep a walk as a record, close the record into a plane you can stand on, pull the plane up into a solid, and ship a build.",
     ["ch01", "ch02", "ch03", "ch04", "ch05", "ch06", "ch07", "ch45", "ch08"]),
    ("p2", "Articulate (transformation)",
     "You can nest parts into one body with pivots, move the whole and keep the parts' relations while it moves: the first assemblage.",
     ["ch13", "ch42"]),
    ("p3", "Repeat and vary (arrays; the family; Melencolia)",
     "You can make many from one by a rule, turn a body into a family with named parameters, tune it live, measure what a value costs, and let a scanned body join the family: the second assemblage.",
     ["ch09", "ch14", "ch15", "ch16", "ch18"]),
    ("p4", "Surface (colour, tiling)",
     "You can give any body a colour system and a patterned skin by rule, and dress the assemblage so that the seam between made and found stays visible.",
     ["ch29", "ch10"]),
    ("p5", "Move by law (change, forces, form finding, waves)",
     "You can write motion as steps, give a region its own law, open the walker you have used since day one, balance a body, make legs that follow, climb a spiral and hear a swing: bodies that move by rules you wrote.",
     ["ch22", "ch19", "ch23", "ch21", "ch20", "ch24", "ch26", "ch27", "ch28"]),
    ("p6", "Disturb, field, skin (randomness, noise, shaders)",
     "You can let chance in with a seed, make ground from a field that remembers its neighbour, bend any body with that field, write a skin per pixel, and assemble a round someone can lose: the midterm.",
     ["ch11", "ch12", "ch46", "ch30", "ch25"]),
    ("p7", "Grow by rule (cellular automata, fractals, L-systems, procedural generation)",
     "You can grow bodies from rules in time, from recursion and from grammars, keep a genome as a file, generate a world and navigate it, and join grown bodies to made ones.",
     ["ch31", "ch32", "ch33", "ch17", "ch34", "ch43"]),
    ("p8", "Deform, imply, combine, flock (soft bodies, isosurfaces, boolean surfaces, swarms)",
     "You can make bodies that give, bodies with no vertices until asked, bodies combined by union and subtraction, and bodies that move as a crowd.",
     ["ch35", "ch36", "ch44", "ch37"]),
    ("p9", "Learn, break, measure, release (machine learning, graph theory, the crises, QFEP, post-crisis)",
     "You can make a body that learns and say whose data taught it, a space that holds from one standpoint only, measure your own predictions, and release your hall: the final assemblage.",
     ["ch38", "ch39", "ch40", "ch41"]),
]
VERBS = {"ch01": "instruct", "ch02": "place", "ch03": "decide: solid or ghost", "ch04": "carry", "ch05": "join", "ch06": "record", "ch07": "close",
         "ch08": "build, direct, ship", "ch13": "articulate", "ch42": "assemble", "ch09": "repeat", "ch14": "parameterise", "ch15": "tune",
         "ch16": "budget", "ch18": "collage", "ch29": "colour", "ch10": "pattern", "ch22": "integrate", "ch28": "field", "ch19": "walk",
         "ch23": "push", "ch20": "balance", "ch21": "follow", "ch24": "climb", "ch26": "swing", "ch27": "sound", "ch11": "disturb",
         "ch12": "noise", "ch30": "skin", "ch25": "play", "ch31": "rule in time", "ch32": "recurse", "ch33": "grow", "ch17": "save a genome",
         "ch34": "navigate", "ch43": "assemble", "ch35": "deform", "ch36": "imply", "ch44": "combine", "ch37": "flock", "ch38": "learn",
         "ch39": "break", "ch40": "measure", "ch41": "release"}
VERBS.update({"ch45": "extrude", "ch46": "displace"})
ASSEMBLAGES = {"ch42": "I", "ch18": "II", "ch10": "III (dressed, inside the chapter)", "ch25": "IV (midterm)", "ch43": "V", "ch44": "VI", "ch41": "VII (final)"}

OPENING_STOP = {"ch01": "day_zero", "ch02": "Point_Zero", "ch03": "Point_One", "ch04": "Point_Coordinates", "ch05": "Point_Lines",
                "ch06": "Point_Trace", "ch07": "ch07", "ch08": "ch08", "ch13": "ch13", "ch42": "ch42", "ch09": "ch09", "ch14": "ch14", "ch18": "ch18"}
_mp = os.path.join(REPO, "doc/book/course/opening.json")
MANIFEST_STOPS = {st["id"]: st for st in json.load(open(_mp, encoding="utf-8"))["stops"]} if os.path.exists(_mp) else {}
order = [cid for _, _, _, ids in PARTS for cid in ids]
assert len(order) == len(set(order)) == 46, len(order)
missing = set(CH) - set(order)
assert not missing, f"winner chapters left out: {missing}"

# ---------------------------------------------------------------- assemble, number, check
chapters = []
for n, cid in enumerate(order, 1):
    ch = CH[cid]
    for h in ch["halls"]:
        hs = HALLSEQ.get(h["map"])
        if hs and hs not in ch["spine"]:
            ch["spine"].append(hs)
    ch["code_returns"] = [x for x in ch.get("code_returns", []) if x not in ch["code_new"]]
    ch["n"] = n
    ch["part"] = next(p for p, _, _, ids in PARTS if cid in ids)
    ch["verb"] = VERBS[cid]
    # the /course manifest: a chapter links to its stop only when opening.json has that stop
    stop_id = OPENING_STOP.get(cid)
    if stop_id and stop_id in MANIFEST_STOPS:
        ch["opening_stop"] = stop_id
        ch["status"] = MANIFEST_STOPS[stop_id].get("status", "planned")
        ch["kit"] = MANIFEST_STOPS[stop_id].get("kit")
    if cid in ASSEMBLAGES:
        ch["assemblage"] = ASSEMBLAGES[cid]
    chapters.append(ch)

VOCAB = set("statements output errors variables types expressions calling properties methods functions parameters return lifecycle delta conditions booleans loops nested_loops arrays packed_arrays dictionaries strings vectors transforms basis trig interpolation random seeds noise classes inheritance composition export setters tool_scripts signals input await timers instancing groups lifetime recursion stacks queues state_machines buffers meshes surface_tool normals uv materials shaders uniforms multimesh physics_bodies collision areas raycasts forces integration camera player ui audio particles navigation graphs search sorting resources files json save_load profiling threads debugging testing export_build xr import_assets ai_assist".split())
problems = []
seen = set()
for ch in chapters:
    for r in ch.get("code_returns", []):
        if r not in seen:
            problems.append(f"ladder: {ch['id']} (n{ch['n']}) returns '{r}' before any chapter introduces it")
    for x in ch["code_new"]:
        if x in seen:
            problems.append(f"ladder: {ch['id']} introduces '{x}' again")
        seen.add(x)
    for x in ch["code_new"] + ch.get("code_returns", []):
        if x not in VOCAB and not x.startswith("other:"):
            problems.append(f"vocab: {ch['id']} uses unknown id '{x}'")
    for h in ch["halls"]:
        if h["map"] not in HALLSEQ:
            problems.append(f"hall: {ch['id']} names {h['map']}, which is not on the spine")
        elif HALLSEQ[h["map"]] not in ch["spine"]:
            problems.append(f"hall: {ch['id']} names {h['map']} ({HALLSEQ[h['map']]}) but its spine list is {ch['spine']}")
    if len(ch["code_new"]) > 3:
        problems.append(f"load: {ch['id']} carries {len(ch['code_new'])} new ideas")

# spine relation: a chapter's place is its FIRST (carrier) sequence
place = [ORDER[ch["spine"][0]] for ch in chapters]
agree = pairs = 0
for i in range(len(place)):
    for j in range(i + 1, len(place)):
        pairs += 1
        agree += place[i] <= place[j]
order_agreement = round(agree / pairs, 3)
v1place = [ORDER[ch["spine"][0]] for ch in sorted(V1["chapters"], key=lambda c: c["n"])]
a1 = p1 = 0
for i in range(len(v1place)):
    for j in range(i + 1, len(v1place)):
        p1 += 1; a1 += v1place[i] <= v1place[j]
v1_agreement = round(a1 / p1, 3)

REASONS = {
    "ch14": "return: the family is declared at the first family hall (Primitives_Ignorance), once there are many to vary (after the chessboard).",
    "ch15": "return: tuning the family live belongs beside its declaration; the colour and softbodies halls are visits.",
    "ch16": "return: the budget is the family's debt (polycount against deformation), so it is paid where the family is; the catenoid is a form-finding visit.",
    "ch18": "return: Melencolia, the last primitives hall, closes the repeat-and-vary part as its assemblage; it needs the family and the import.",
    "ch28": "return: the field of arrows (change, spine 6) closes Part 5 because it needs the part: forces for the particles, the hand's ray from legs, the MultiMesh from the swing; the field itself is a supplied function until noise (ch12).",
    "ch25": "return: the round is the part's assemblage, built on the noise terrain (ch12) in the shader skin (ch30), so it follows them.",
    "ch43": "return: the assemblage of grown bodies is anchored at a procedural-generation hall and names Assemblage_Same_Desire (L-systems) as its carrier.",
}
departures = []
running = -1
for ch, pl in zip(chapters, place):
    if pl < running:
        reason = REASONS.get(ch["id"])
        if not reason:
            problems.append(f"departure: {ch['id']} (n{ch['n']}, {ch['spine'][0]} {pl}) is below the running spine order {running} and has no declared reason")
        ch["departure"] = reason
        departures.append({"chapter": ch["id"], "n": ch["n"], "title": ch["title"], "kind": "return", "below_spine_order": True, "reason": reason or ""})
    else:
        ch["departure"] = ch.get("departure") if ch["id"] in ("ch08",) else None
    running = max(running, pl)
# ch8 keeps its v1 reason (no spine place for directing a drafter)
CH["ch08"]["departure"] = V1["chapters"][7]["departure"] if V1["chapters"][7]["id"] == "ch08" else CH["ch08"].get("departure")

if problems:
    print("REFUSED:"); [print(" -", p) for p in problems]; sys.exit(1)

# spine visits: visit k of N per sequence, by carrier
counts = {}
for ch in chapters:
    counts[ch["spine"][0]] = counts.get(ch["spine"][0], 0) + 1
seenseq = {}
for ch in chapters:
    s = ch["spine"][0]
    seenseq[s] = seenseq.get(s, 0) + 1
    ch["spine_visits"] = [{"sequence": s, "order": ORDER[s], "visit": seenseq[s], "of": counts[s]}]
    for extra in ch["spine"][1:]:
        ch["spine_visits"].append({"sequence": extra, "order": ORDER[extra]})
coverage = sorted({s for ch in chapters for s in ch["spine"]}, key=lambda s: ORDER[s])

# the process strip: the chain of operations behind a body, one still after each
for ch in chapters:
    if ch["id"] in ADD["process"]:
        ch["process"] = ADD["process"][ch["id"]]

# the DNA families already standing in each chapter's halls: registry dna.axes x the halls' map tokens.
# A token counts on an axis only when it carries a value on one of that artifact's own declared axes.
import glob
REG = {}
for _f in glob.glob(os.path.join(REPO, "commons/artifacts/registry/*.json")):
    try:
        _d = json.load(open(_f, encoding="utf-8", errors="replace"))
    except Exception:
        continue
    _e = _d.get("artifacts", _d) if isinstance(_d, dict) else {}
    if not isinstance(_e, dict):
        continue
    for _t, _v in _e.items():
        if isinstance(_v, dict) and (_v.get("dna") or {}).get("axes"):
            REG[_t] = {"axes": _v["dna"]["axes"], "predicted": bool(_v["dna"].get("predicted_degeneracy"))}


def hall_tokens(m):
    try:
        d = json.load(open(os.path.join(REPO, "commons/maps", m, "map_data.json"), encoding="utf-8", errors="replace"))
    except Exception:
        return []
    out = []
    for row in (d.get("layers") or {}).get("interactables", []):
        for c in row:
            c = str(c).strip()
            if c and c not in ("0", "."):
                out.append(c)
    return out


def axis_values(v):
    if isinstance(v, list):
        return [str(x) for x in v]
    if isinstance(v, dict):
        return [str(x) for x in v.keys()]
    return []


DNA = {"promoted_artifacts": len(REG), "declared_axes": sum(len(v["axes"]) for v in REG.values()),
       "chapters": len(chapters), "chapters_with_promoted_work": 0, "chapters_with_family_shown": 0}
for ch in chapters:
    fams = []
    for h in ch["halls"]:
        per = {}
        for c in hall_tokens(h["map"]):
            base = re.split(r"[:#]", c)[0]
            if base not in REG:
                continue
            ent = per.setdefault(base, {})
            for seg in c.split("#")[1:]:
                k = seg.split(":")[0]
                if k in REG[base]["axes"]:
                    ent.setdefault(k, set()).add(seg.split(":", 1)[1] if ":" in seg else "")
        for base, shown in per.items():
            axes = REG[base]["axes"]
            axis = max(axes, key=lambda a: len(shown.get(a, ())))
            fams.append({"hall": h["map"], "role": h["role"], "token": base, "axis": axis,
                         "values": axis_values(axes[axis])[:6], "shown": sorted(shown.get(axis, [])),
                         "family_shown": len(shown.get(axis, ())) >= 2, "predicted": REG[base]["predicted"]})
    fams.sort(key=lambda f: (not f["family_shown"], f["role"] != "carrier", not f["shown"], not f["predicted"], f["token"]))
    if fams:
        ch["hall_families"] = fams[:3]
        DNA["chapters_with_promoted_work"] += 1
    if any(f["family_shown"] for f in fams):
        DNA["chapters_with_family_shown"] += 1

# toolkit so far, per part
toolkit = []
parts = []
for pid, title, promise, ids in PARTS:
    toolkit += [VERBS[c] for c in ids]
    parts.append({"id": pid, "title": title, "promise": promise, "chapters": ids, "toolkit_so_far": list(toolkit),
                  "plate_now": ADD["plate"]["by_part"].get(pid, "")})

# tracks
short_ids = ["ch01", "ch02", "ch03", "ch04", "ch05", "ch06", "ch07", "ch08", "ch13", "ch42", "ch09", "ch14", "ch18"]
for ch in chapters:
    ch["tracks"] = ["short", "long"] if ch["id"] in short_ids else ["long"]
tracks = [
    {"id": "short", "title": "Three weeks: place, join, articulate, repeat, vary, and one assemblage (Queer 3D World format)",
     "length": "3 weeks (15 days)",
     "chapters": short_ids,
     "supplied": "the walker, the sketch helper (point / line / box), base.tscn, the sweep sheet, the XR rig in the course project; scanning done in one session, imported by the teacher",
     "mini_project": "A family in drag, assembled: one class of your own with one exported axis of 3-5 values, instanced as parts into a body of parts (ch42) with one scanned or found part (ch18); the closest pair predicted in writing before rendering; the comparison sheet; one claim sentence and one debt comment; shown to the class on day 15. Week 1: ch1-ch6 two a day on days 1-3, ch7 and a scanning / Tilt Brush session on day 4, ch8 (first export) on day 5. Week 2: ch13, ch42, ch9, ch14, ch18 (export on Friday; the brief is due the same day as a flowchart and a paper prototype). Week 3: the mini project, with two critique sessions in the SFPC Code Societies format and no new code: (a) the command chain, walked in Trans_Body and VFM_09_Legs, then each student re-roots a supplied three-segment organism in the Scene dock and moves it; (b) the blob aesthetic and the default body, walked in ISO_Metaballs and ML_Classification."},
    {"id": "long", "title": "One year: the operations of form in Ada's order, with seven assemblages",
     "length": "46 weeks as written (Part 1 at two chapters a week, then one a week, and a pause week with no new code after ch8, ch18, ch25 and ch43); 36 weeks with the eight pairings below",
     "chapters": order,
     "mini_project": "Midterm at ch25: a round in your room that a classmate can lose, on your own terrain, exported and played. Final at ch41: your hall in Ada's endless museum, built from your families and assemblages, exported to desktop and Quest; for each body a prediction, a comparison sheet, a claim and a debt comment, plus one public sculpture whose visitors' changes are kept as provenance records.",
     "pairings_36_weeks": [["ch15", "ch16"], ["ch22", "ch23"], ["ch26", "ch27"], ["ch12", "ch30"], ["ch32", "ch33"], ["ch17", "ch34"], ["ch35", "ch36"], ["ch38", "ch39"]]},
]

# lineage rows: chapters per sequence (carrier first), keep v1's columns
v1rows = {r["sequence"]: r for r in V1["lineage"]}
lineage = []
for s in sorted(ORDER, key=lambda s: ORDER[s]):
    row = dict(v1rows.get(s, {"sequence": s}))
    row["order"] = ORDER[s]
    row["chapters"] = [ch["id"] for ch in chapters if s in ch["spine"]]
    lineage.append(row)

out = {k: copy.deepcopy(V1[k]) for k in ("strands", "layers", "rhythm", "sources", "learned_from")}
out["rhythm"].append(ADD["strip"])
out["sources"].append(ADD["source"])
out["mesh_grammar"] = ADD["mesh_grammar"]
out["method"] = ADD["method"]
out["plate"] = {k: v for k, v in ADD["plate"].items() if k != "by_part"}
out["rhythm"].append("The plate: each part ends on one question about the course's opening picture: what of it can you make now? The answer goes in your sketchbook, as a sketch or a still.")
out["rhythm"].append(ADD["decision"])
out["sources"].append({"name": ADD["method"]["name"], "role": "the decision step, the field note and the cautions about entropy and inference"})
out["dna"] = dict(DNA, method="The hall shows the family, the kit makes one. Where a chapter's hall holds a work with a declared axis, the hall shows that work at three to five values of the axis, side by side, and the first step of the lesson is to predict the closest pair there. The kit then sweeps an axis on the student's own body with the same sheet. A hall marked 'at its default' holds the work but not yet its family: adding the sibling tokens (name#axis:value) is the integration.")
out["rhythm"].insert(1, "Find the family in the hall: where the hall shows one work at several values of one axis, predict which two look most alike before you read anything beside them. It is the same question the kit will ask of your own body.")
out.update({
    "title": "The Sketchbook in Drag: a grammar of bodies",
    "subtitle": "Place, join, extrude, articulate, repeat, vary, surface, move, disturb, displace, grow, deform, combine, learn, release: the operations of form in Ada's order, each part closed by an assemblage",
    "date": "2026-10-01",
    "state": "v2, refined by hand on 2026-10-01 from the auto-research winner (d2_ada_first, course_v1.json): the same 41 chapters reordered into the spine's order of form operations, three assemblage chapters added, one chapter split; then two operations (extrude, displace), a process strip per assemblage, and the project's MeshGrammar as the tool behind both. A proposal: no tutorial, kit, spine or curriculum.json changed.",
    "state_detail": "Palle, 2026-10-01: 'refine this order to make it possible to introduce capacity to make different assemblages or forms in logical Ada order'. v1 followed Klee's Pedagogical Sketchbook for its first 30 chapters; v2 keeps Klee only where the spine already agrees (the point on a walk is the primitives sequence) and otherwise follows the spine, so that every part adds operations to one growing toolkit and ends by composing them.",
    "principle": "Every chapter adds one operation of form to the student's toolkit (place, join, articulate, repeat, vary, surface, move, disturb, grow, deform, combine, learn), in the order Ada's spine puts them; and every part ends in an assemblage, a body composed from the operations learned so far, made of parts of different origin. The spine's order is the order of operations; a chapter that returns to an earlier sequence says it is a return. The capacity the course builds is the capacity to make different assemblages: by the end the student can make a body by any of the operations and compose them.",
    "thesis": V1.get("thesis", ""),
    "anchor": "v2: the operations of form in Ada's order (Palle, 2026-10-01), grown from d2_ada_first",
    "verbs": {ch["id"]: ch["verb"] for ch in chapters},
    "assemblages": [{"chapter": ch["id"], "n": ch["n"], "number": ASSEMBLAGES[ch["id"]], "title": ch["title"]} for ch in chapters if ch["id"] in ASSEMBLAGES],
    "tracks": tracks, "parts": parts, "chapters": chapters, "lineage": lineage,
    "spine_relation": {
        "order_agreement": order_agreement,
        "order_agreement_note": "fraction of chapter pairs whose carrier sequences are in spine order; 1.0 is the spine itself",
        "v1_order_agreement_same_metric": v1_agreement,
        "spine_control_order_agreement": 1.0,
        "below_spine_order": len(departures), "declared_departures": len(departures), "undeclared_departures": 0,
        "kinds": {"return": len(departures)},
        "departures": departures,
        "spine_sequences_touched": len(coverage), "of": 25,
    },
    "checks": {"ladder_violations": 0, "unknown_ids": 0, "halls_off_spine": 0, "chapters_over_three_new_ideas": 0, "chapters": len(chapters)},
    "source_candidate": "d2_ada_first (course_v1.json), refined by hand",
})
json.dump(out, open(os.path.join(HERE, "course.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)

# ---------------------------------------------------------------- COURSE_v2.md
def md():
    L = []
    L.append(f"# {out['title']}\n")
    L.append(f"*{out['subtitle']}*\n")
    L.append(f"Status, 1 October 2026. {out['state']}\n")
    L.append("## For the student: why this order\n")
    L.append(out["principle"] + "\n")
    L.append("The course has four strands in every chapter: **code** (one programming idea), **body** (a body you build in code), **argument** (a family of that body, one axis varied, a prediction written before you render, one comparison image and one claim), and **place** (where a body meets yours). It has three layers in every chapter, from Palle's Queer 3D World course: **foundation** (the lab: how it works), **debt** (what the approximation owes or hides) and **ontology** (the body leaves the lab). The lesson rhythm is unchanged from v1:\n")
    for r in out["rhythm"]:
        L.append(f"- {r}")
    L.append("\n### The toolkit\n")
    L.append("Each chapter adds one operation. By the end of a part you can do everything in its row.\n")
    L.append("| part | operations added | the assemblage that closes it |")
    L.append("|---|---|---|")
    for p in parts:
        ops = ", ".join(VERBS[c] for c in p["chapters"])
        closing = [f"{ASSEMBLAGES[c]}: {CH[c]['title']}" for c in p["chapters"] if c in ASSEMBLAGES]
        L.append(f"| {p['title']} | {ops} | {'; '.join(closing) if closing else '-'} |")
    L.append("\n### What an assemblage is here\n")
    L.append("A body composed from parts of different origin and different operations: a part made by code, a part drawn by hand, a part scanned, a part grown by a rule, a part carved by subtraction, under one root whose choice is itself a decision. There are seven, and each uses everything learned before it: I a body of parts (the scene tree), II collage (a found body joins the family), III dressed (inside the pattern chapter), IV the round (the midterm game), V grown bodies join made ones, VI combine (boolean), VII your hall in the museum (the final).\n")
    mg = out["mesh_grammar"]
    L.append("### The project's own grammar of operations\n")
    L.append(mg["what"] + " " + mg["in_the_course"] + "\n")
    L.append("| the slide's node | MeshGrammar |")
    L.append("|---|---|")
    for row in mg["slide_to_grammar"]:
        L.append(f"| {row['slide']} | {row['grammar']} |")
    L.append("\n" + mg["where_to_see"] + "\n")
    L.append(mg["as_placed"])
    L.append("")
    dn = out["dna"]
    L.append("### The families already in the halls\n")
    L.append(f"{dn['method']} Measured for this course: {dn['promoted_artifacts']} artifacts declare {dn['declared_axes']} axes; {dn['chapters_with_promoted_work']} of the {dn['chapters']} chapters have such a work standing in their halls, and {dn['chapters_with_family_shown']} of them already show a family.\n")
    me = out["method"]
    pl = out["plate"]
    L.append("### The plate\n")
    L.append(pl["what"] + " " + pl["lineage"] + "\n")
    L.append(pl["citation"] + " " + pl["link"] + " The lesson is `" + pl["lesson"] + "`; the remake is " + pl["remake"] + " " + pl["not_reached"] + "\n")
    L.append("### The decision and the field note\n")
    L.append(me["what"] + " The template is `" + me["template"] + "`; a worked note from this project is `" + me["worked_note"] + "`.\n")
    for c in me["cautions"]:
        L.append(f"- {c}")
    L.append("")
    L.append("### Two tracks\n")
    for t in tracks:
        L.append(f"**{t['title']}** - {t['length']}. Chapters: {', '.join(t['chapters'])}.\n\n{t['mini_project']}\n")
    L.append("### Relation to the spine\n")
    L.append(f"The carrier sequences of the {len(chapters)} chapters are in spine order for {order_agreement:.3f} of chapter pairs (v1, Klee-first: {v1_agreement:.3f}; the spine itself: 1.000). {len(departures)} chapters sit below the running spine order, all declared as returns:\n")
    for d in departures:
        L.append(f"- {d['chapter']} (n{d['n']}) {d['title']}: {d['reason']}")
    L.append(f"\n{len(coverage)} of 25 spine sequences are touched. Decisions a reader may want to flip: chance stays at its spine place (Part 6), with `random()` met as a value in the chessboard (ch9), as Nake, Nees and Molnar lay disorder over a built grid; the first shader stays at spine 12 (Part 6), not with colour; the player's body is opened where motion is the subject (Part 5), having been borrowed since day one.\n")
    L.append("## The chapters\n")
    for p in parts:
        L.append(f"### {p['title']}\n")
        L.append(f"*{p['promise']}*\n")
        L.append(f"Toolkit so far: {', '.join(p['toolkit_so_far'])}.\n")
        if p.get("plate_now"):
            L.append("Of the plate, now: " + p["plate_now"] + "\n")
        for cid in p["chapters"]:
            ch = CH[cid]
            L.append(f"#### {ch['n']}. {ch['title']}\n")
            L.append(f"- **Operation:** {ch['verb']}. **Spine:** {', '.join(ch['spine'])}. **Halls:** {', '.join(h['map'] + ' (' + h['role'] + ')' for h in ch['halls'])}.")
            L.append(f"- **Code:** new {', '.join(ch['code_new']) or 'none (a synthesis)'}; returns {', '.join(ch.get('code_returns', [])) or '-'}.")
            L.append(f"- **Body:** {ch['body']}")
            a = ch["argument"]
            L.append(f"- **Argument:** axis {a['axis']}: {' / '.join(a['values'])}. Predict: {a['predict']} Claim: {a['claim']}")
            L.append(f"- **Debt:** {ch['debt']}")
            L.append(f"- **Place:** {ch['place']}")
            if ch.get("borrows"):
                L.append(f"- **Borrows:** " + "; ".join(f"{b['part']} ({b['depth']})" for b in ch["borrows"]))
            if ch.get("works"):
                L.append("- **Works to see:** " + "; ".join(f"{w['token']} ({w['note']})" for w in ch["works"]))
            if ch.get("process"):
                L.append("- **Process strip:** " + " -> ".join(ch["process"]))
            if ch.get("hall_families"):
                L.append("- **Families in the hall:** " + "; ".join(
                    f"{f['token']}.{f['axis']} ({' / '.join(f['values'])}) in {f['hall']}: "
                    + ("family shown: " + ", ".join(f["shown"]) if f["family_shown"] else ("one value shown: " + ", ".join(f["shown"]) if f["shown"] else "at its default"))
                    for f in ch["hall_families"]))
            L.append(f"- **In your room:** {ch['project_step']}")
            if ch.get("departure"):
                L.append(f"- **Departure:** {ch['departure']}")
            L.append("")
    L.append("## Lineage\n")
    L.append("| spine | chapters | application WP | Klee | Processing | NoC |")
    L.append("|---|---|---|---|---|---|")
    for r in lineage:
        L.append(f"| {r['order']} {r['sequence']} | {', '.join(r['chapters']) or '-'} | {r.get('application_wp','')} | {r.get('klee','')[:80]} | {r.get('processing','')[:80]} | {r.get('noc','')[:60]} |")
    L.append("\n## What changed from v1\n")
    L.append("- The order: v1 followed Klee's Pedagogical Sketchbook for 30 chapters (point, line, plane, structure, family, balance, gravity, kinetic forms, colour) and the spine after; v2 follows the spine's order of operations throughout, which keeps Klee's walk only where the spine already walks it (primitives).\n- Parts are named by operations and each ends in an assemblage; the toolkit is printed per part.\n- Three new chapters: ch42 a body of parts (assemblage I), ch43 same desire (assemblage V), ch44 combine (assemblage VI). ch36 is now implicit bodies only.\n- Moved: the family (ch14-16, 18) to Part 3 after the chessboard; chance, noise and the first shader to Part 6 at their spine places; the walker, balance, legs, stairs, swing and sound to Part 5 with change, forces, form finding and waves; the genome file (ch17) to Part 7 with procedural generation; the round (ch25) to the end of Part 6 as the midterm.\n- Re-anchored: ch19 on VFM_03_Motion (forces) with Trans_Scale as a visit; ch15 on Primitives_Ignorance; ch28 borrows a supplied field until noise is taught.\n- Added after a slide Palle supplied (a body written as a chain of operations) and his pointer to MeshGrammar: ch45 extrude, right after the plane; ch46 displace, right after noise; a process strip on every assemblage and on both new chapters; MeshGrammar used at ch45, used directly at ch46, opened at ch43.\n- Everything else is the winner's text. Untried with students; past the opening the chapters are plans.\n")
    return "\n".join(L)

open(os.path.join(HERE, "COURSE_v2.md"), "w", encoding="utf-8").write(md())
print(f"OK: {len(chapters)} chapters, {len(parts)} parts, order agreement {order_agreement} (v1 {v1_agreement}), {len(departures)} declared returns, {len(coverage)}/25 sequences")
print("wrote course.json and COURSE_v2.md")
