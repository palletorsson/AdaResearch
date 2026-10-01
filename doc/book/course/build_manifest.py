"""Build doc/book/course/opening.json (the /course manifest) from the course (v2) and the kits.

The manifest is the SHORT TRACK as stops: the six hand-written opening stops are kept as they
are; the chapters that follow (ch07 plane, ch08 cube, W01, CP1, ch13 organism, ch42 body of parts,
ch09 chessboard, ch14 family, ch18 collage) are generated from course.json and from each kit on
disk. A chapter whose kit does not exist yet is listed as planned, with its lesson path set, so
/course/<id> shows the 'being written' state instead of nothing.

  python doc/book/course/build_manifest.py            # dry run: prints the stop table, writes nothing
  python doc/book/course/build_manifest.py --write    # writes opening.json (keeps a .bak)
"""
import json, os, sys, re, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
ENC_PUBLIC = os.path.join(REPO, "..", "ada_encyclopedia", "public", "course")
COURSE = json.load(open(os.path.join(REPO, "doc/book/iterations/claude-course-braid-2026-09-30/course.json"), encoding="utf-8"))
OLD = json.load(open(os.path.join(HERE, "opening.json"), encoding="utf-8"))
CH = {c["id"]: c for c in COURSE["chapters"]}

# the short track, as stops: kept hand-written stops by id, generated chapters by (chapter id, kit folder)
ORDER = ["P00_the_plate", "day_zero", "Point_Zero", "Point_One", "Point_Coordinates", "Point_Lines", "Point_Trace",
         "W01_break_it_on_purpose", "CP1_opening", ("ch07", "point-plane"), ("ch08", "point-cube"), "W02_decide_and_note",
         ("ch13", "organism"), ("ch42", "body-of-parts"), ("ch09", "chessboard"), ("ch14", "family"), ("ch18", "collage")]
MAKES = {
    "ch07": "You close your recorded walk into a face: a triangle fan from the list, normals, and a collider you can stand on.",
    "ch08": "You build a cube from eight corners and twelve triangles, direct a drafter under a three-line protocol, read its errors, and export your first build.",
    "ch13": "You articulate a limb of three segments with pivots that turn by delta: the first body that moves by itself.",
    "ch42": "You instance the parts you have made into one body under a root, and learn that the tree, not the parts, says what the body does.",
    "ch09": "You repeat one cube into a floor by a nested loop, colour it by a rule over (x, z), and turn one cell into a ghost.",
    "ch14": "You describe a body in a single class with two exported fields, so it becomes a family, and sweep one axis into a comparison sheet.",
    "ch18": "You recreate Durer's truncated solid as a family member, import a scanned body beside it, and export the hybrid room.",
}
CAPTIONS = {
    "ch18": "The process strip of the collage: the cube pulled, stood on its diagonal, two corners cut, a drafted answer beside it, a found body arriving, and the found body given its unit and its origin. In tile 5 the plate marked found is empty: the body is there, 99 m high and 43 m away, and nothing says so.",
    "ch14": "The process strip of the family: a sphere written out, the same as a class, a row of four, hung and named, the axis set by a wrong name, the right name. In tile 5 the plates read 4, 8, 16, 64 over four identical bodies; nothing in the picture says so except the bodies themselves.",
    "ch09": "The process strip of the chessboard, one still after each operation: one cube, a row, the floor, two colours, hue by index, a ghost cell, the spacing opened. Tiles 5 and 6 are the same picture: the ghost cell looks like its neighbours, and a marble dropped on it falls through. Opening the spacing changed the picture most.",
    "ch42": "The process strip of the first assemblage, one still after each operation: the point, plus the walked plane, plus the cube, plus the limb, the pivots set, the same parts as a chain, and every pivot turned 30 degrees. Tiles 5 and 6 are identical to the pixel: the tree changed and the picture did not.",
    "ch13": "The limb of three bars, each joint turned, over the supplied lattice; the cube and the marble from the chapter before stand beside it. One turn of the limb carves 33 cells where the toe passes. Pass the toe position in the limb own frame by mistake and six other cells go instead.",
    "ch08": "The repaired cube, from above, with the marble at rest on its top. The one-line draft looks just as whole from here; from behind it is an open room, every triangle facing inward, and the marble comes to rest inside it.",
    "ch07": "The finished study, side 0 (clockwise), from above: a twelve-point walk closed into a face, lit, with its shadow on the floor; the marble waits beside it. Turned counter-clockwise the face vanishes from above and the marble still rests on it.",
}
LABELS = {  # the code vocabulary, for the teacher panel's chips
    "statements": "Statements, one after another", "output": "print() and the Output panel", "errors": "Reading an error message",
    "variables": "Variables and assignment", "types": "Static types", "expressions": "Expressions", "calling": "Calling a function or method",
    "properties": "Properties of a node", "methods": "Methods of your own class", "functions": "Defining a function", "parameters": "Parameters",
    "return": "Return values", "lifecycle": "_ready and _process", "delta": "delta: time per frame", "conditions": "if / elif / else",
    "booleans": "Booleans", "loops": "for loops and range", "nested_loops": "Nested loops", "arrays": "Arrays: append, index, size",
    "packed_arrays": "Packed arrays", "dictionaries": "Dictionaries", "strings": "Strings", "vectors": "Vector3 arithmetic",
    "transforms": "Transform3D, local and global", "basis": "Basis and orientation", "trig": "sin and cos", "interpolation": "lerp",
    "random": "Randomness", "seeds": "Seeds", "noise": "Noise fields", "classes": "class_name and extends", "inheritance": "Inheritance",
    "composition": "Composition: a scene of scenes", "export": "@export", "setters": "Setters that rebuild", "tool_scripts": "@tool scripts",
    "signals": "Signals", "input": "Input actions", "await": "await", "timers": "Timers", "instancing": "PackedScene and instantiate()",
    "groups": "Groups", "lifetime": "Object lifetime", "recursion": "Recursion", "stacks": "Stacks", "queues": "Queues",
    "state_machines": "State machines", "buffers": "Double buffers", "meshes": "Meshes as resources", "surface_tool": "SurfaceTool / ArrayMesh",
    "normals": "Normals and winding", "uv": "UVs", "materials": "StandardMaterial3D in code", "shaders": "Spatial shaders", "uniforms": "Uniforms",
    "multimesh": "MultiMesh", "physics_bodies": "Rigid, static and character bodies", "collision": "Collision shapes", "areas": "Area3D",
    "raycasts": "Raycasts", "forces": "Forces and impulses", "integration": "Integrating motion by steps", "camera": "Camera3D", "player": "A player body",
    "ui": "Control nodes", "audio": "Audio", "particles": "Particles", "navigation": "Navigation", "graphs": "Graphs", "search": "Search",
    "sorting": "Sorting", "resources": "Custom Resources", "files": "Files", "json": "JSON", "save_load": "Saving and loading",
    "profiling": "The profiler and frame time", "threads": "Worker threads", "debugging": "Debugging", "testing": "Repeatable checks",
    "export_build": "Exporting a build", "xr": "The XR rig", "import_assets": "Importing assets", "ai_assist": "Directing and checking generated code",
    "other:csg": "CSG nodes",
}


def kit_state(kit):
    folder = os.path.join(REPO, "doc/book/studies", kit)
    if not os.path.isdir(folder):
        return None
    st = {"folder": folder, "main_scene": None, "passed": None, "checks": None, "date": None}
    pg = os.path.join(folder, "project.godot")
    if os.path.exists(pg):
        m = re.search(r'run/main_scene="res://([^"]+)"', open(pg, encoding="utf-8").read())
        st["main_scene"] = m.group(1) if m else None
    vj = os.path.join(folder, "verification.json")
    if os.path.exists(vj):
        v = json.load(open(vj, encoding="utf-8"))
        st["passed"] = bool(v.get("passed", v.get("ok", False)))
        c = v.get("checks") or v.get("total") or v.get("count")
        st["checks"] = len(c) if isinstance(c, list) else c
        if isinstance(c, list) and "passed" not in v and "ok" not in v:
            st["passed"] = all(x.get("passed") for x in c)
        st["date"] = v.get("date") or v.get("run") or v.get("when") or __import__("time").strftime("%Y-%m-%d", __import__("time").localtime(os.path.getmtime(vj)))
    return st


def gen(cid, kit, n):
    ch = CH[cid]
    carrier = next((h["map"] for h in ch["halls"] if h["role"] == "carrier"), ch["halls"][0]["map"])
    st = kit_state(kit)
    img = f"/course/{kit}.png" if os.path.exists(os.path.join(ENC_PUBLIC, f"{kit}.png")) else None
    runnable = bool(st and st["passed"])
    a = ch["argument"]
    why = (ch.get("departure") or "")
    why = (why + " " if why else "") + f"Operation added to the toolkit: {ch['verb']}."
    if ch.get("assemblage"):
        why += f" Assemblage {ch['assemblage']}."
    native = None
    if runnable:
        native = f"{st['date'] or ''} Godot 4.6 headless: verify.gd passes".strip()
        if st["checks"]:
            native += f" ({st['checks']} checks)"
    if runnable:
        status, note = "runnable", "Runs in Godot 4.6; verify.gd passes."
    elif st:
        status, note = "draft", "The kit exists but its checks have not passed yet."
    else:
        status, note = "planned", "Not written yet: the kit and its lesson are being built, in order, from the previous kit's finished state."
    return {
        "id": cid, "n": n, "kind": "hall", "title": ch["title"], "hall": carrier, "sequence": ch["spine"][0],
        "makes": MAKES[cid],
        "lesson": f"doc/book/studies/{kit}/TUTORIAL.md",
        "hall_reading": f"commons/maps/{carrier}/final.md",
        "kit": f"doc/book/studies/{kit}", "main_scene": st["main_scene"] if st else None,
        "image": img,
        "image_caption": CAPTIONS.get(cid) if img else None,
        "status": status, "status_note": note,
        "verified": {"native": native, "learner": None, "headset": None},
        "route": "desktop",
        "teacher": {
            "why_here": why,
            "new": [{"id": x, "depth": None} for x in ch["code_new"]],
            "returns": [{"id": x, "depth": None} for x in ch.get("code_returns", [])],
            "borrows": ch.get("borrows", []),
            "check": f"Axis: {a['axis']} - {' / '.join(a['values'])}. Predict first: {a['predict']}",
            "contrast": f"Claim: {a['claim']} Debt: {ch['debt']}",
            "carries": ch["project_step"],
            "learner_room": ch["place"],
        },
    }


old_by_id = {s["id"]: s for s in OLD["stops"]}
# the opening picture (Palle, 2026-10-01): Haeckel's plate 31, before Day Zero
old_by_id["P00_the_plate"] = {
    "id": "P00_the_plate", "n": 0, "kind": "workshop", "title": "The plate",
    "hall": None, "sequence": "primitives",
    "makes": "You look at one picture, Haeckel's Cyrtoidea, and write down what its nine bodies share. The course returns to it at the end of every part.",
    "lesson": "doc/book/course/opening/PLATE.md",
    "hall_reading": None, "hall_reading_note": None,
    "kit": None, "main_scene": None, "image": "/course/haeckel_tafel_31_cyrtoidea.jpg",
    "image_caption": "Ernst Haeckel and Adolf Giltsch, Kunstformen der Natur, plate 31, Cyrtoidea, 1904. Nine shells of radiolaria. Public domain; from Wikimedia Commons, made smaller.",
    "status": "runnable", "status_note": "A page to read and a picture to look at; nothing to install. The remake is the museum work cyrtoid_by_rule; its gate passed on 2026-10-01.",
    "verified": {"native": "2026-10-01 probe_lathe_cells.gd: 0 failed; 30 variants swept, both axes bite", "learner": None, "headset": None},
    "route": "desktop",
    "teacher": {
        "why_here": "Before any tool. The course is about what bodies are possible, and this picture is nine bodies that turn out to be one body with numbers. Looking first, with nothing to install, gives the class a shared thing to decode, and the course asks at the end of each part what of it they can now make.",
        "new": [], "returns": [], "borrows": [],
        "check": "The learner has two written lists: what the nine share, and what differs.",
        "contrast": "A list of names (helmet, flask, tripod) is a list of species. A list of operations (an outline, turned, opened, branched) is a list of rules.",
        "carries": "The question asked at the end of every part: what of the plate can you make now?",
        "learner_room": None,
    },
}
# a hand-written stop that is not a chapter: the decision and the field note (Palle, 2026-10-01)
old_by_id["W02_decide_and_note"] = {
    "id": "W02_decide_and_note", "n": 0, "kind": "workshop", "title": "Decide, and keep a field note",
    "hall": "Point_Animatedcube", "sequence": "primitives",
    "makes": "You decide whether to follow a difference or to settle, and keep the reason in a field note someone else can run again.",
    "lesson": "doc/book/course/opening/FIELD_NOTE.md",
    "hall_reading": "doc/book/course/field_notes/2026-10-01-pyramid-family.md",
    "hall_reading_note": "A full field note from the making of this course: the pyramid family in Point_Animatedcube, with the first measurement that was wrong and what stayed unexplained.",
    "kit": None, "main_scene": None, "image": None,
    "status": "runnable", "status_note": "A page to read and a note to copy; no kit. The worked note below it was replayed on 2026-10-01.",
    "verified": {"native": "2026-10-01 the worked note's replay: 46 numeric axes checked, 0 misread", "learner": None, "headset": None},
    "route": "desktop",
    "teacher": {
        "why_here": "After the plane and the cube the learner has written two predictions before looking, and has seen at least one of them fail. This is where the lesson rhythm gains its last step: the decision, with its reason, kept as a note. The organism, next, is the first lesson whose argument ends in one.",
        "new": [], "returns": [{"id": "debugging", "depth": None}, {"id": "testing", "depth": None}],
        "borrows": [],
        "check": "The learner can show one field note in which the observation, the conclusion and the guess are separate lines, and the decision has a reason.",
        "contrast": "A note that says only what was built, with no prediction written before the trial, cannot be checked by anyone.",
        "carries": "The note format, used at every argument from here on.",
        "learner_room": None,
    },
}
stops = []
for item in ORDER:
    n = len(stops)
    if isinstance(item, tuple):
        stops.append(gen(item[0], item[1], n))
    else:
        s = dict(old_by_id[item])
        s["n"] = n
        stops.append(s)

caps = dict(OLD.get("capabilities", {}))
for cid in CH:
    for x in CH[cid]["code_new"] + CH[cid].get("code_returns", []):
        caps.setdefault(x, LABELS.get(x, x))
out = dict(OLD)
out.update({
    "title": "The Sketchbook in Drag: a grammar of bodies - the short track",
    "subtitle": "Place, join, articulate, repeat, vary: seventeen stops, from the plate and Day Zero to the first family in drag",
    "state": "Built by build_manifest.py from course.json (v2, 2026-10-01) and the kits on disk. Six opening stops are hand-written; the rest are generated and turn runnable as their kits pass.",
    "capabilities": caps, "stops": stops,
})
for s in stops:
    print(f"{s['n']:2d} {s['id']:26s} {s['kind']:10s} {s['status']:8s} kit={s.get('kit')} image={s.get('image')}")
if "--write" in sys.argv:
    shutil.copy2(os.path.join(HERE, "opening.json"), os.path.join(HERE, "opening.json.bak"))
    json.dump(out, open(os.path.join(HERE, "opening.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print("wrote opening.json (backup opening.json.bak)")
else:
    p = os.path.join(os.environ.get("TEMP", "."), "opening_dryrun.json")
    json.dump(out, open(p, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print("dry run ->", p)
