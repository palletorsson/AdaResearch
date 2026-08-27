"""Generic concept-map builder — classify a domain's artifacts into concepts + tiers.

The vectors/forces concept map has a bespoke builder; this is the reusable version for the
other domains. It scans the domain's registries, scores every artifact against an ordered list
of concept keyword-sets, assigns it to the best concept (ties break to the earlier = more
specific concept), tiers it by footprint, and emits doc/<domain>_concept_map.json in the exact
shape tools/mindmap_graph.py consumes (concepts / concept_meta{act,truth,tiers} / groups).

That single output is what puts a domain on the /mind-map page at artifact level.

Run:  python tools/build_concept_map.py transformation
      python tools/build_concept_map.py primitives
"""
import json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import concept_distance_text as T   # reuse tokens / tfidf / cos_d for the concept-text distance

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REG = os.path.join(ROOT, "commons", "artifacts", "registry")
IMG_DIR = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia", "public", "scene-catalog"))
DOC = os.path.join(ROOT, "doc")

# ── per-domain config ─────────────────────────────────────────────────────────────────────────
# concept = (key, act, truth, [strong keywords], [weak keywords]). Order = specific first.
CONFIG = {
 "color": {
  # THE COLOR TAXONOMY (2026-08-27, Palle: "color does not teach color... order them
  # into a taxonomy... what concept we need to introduce to make an object exist. The
  # cheat code in the godot documentation"). Rungs ordered by EXISTENCE DEPENDENCY in
  # the engine itself: what must exist before a coloured object can. The engine's own
  # API is the honest order - Light3D before Color(r,g,b) before albedo before lerp -
  # and where the engine goes silent (harmony, context) the silence IS the rung.
  # Acts: I before the object / II the number / III the body / IV the meeting /
  # V the relation / VI the screen and the room. Closes as a loop: rung 12 is colour
  # you stand INSIDE, the sequence truth ("color is perception") made walkable.
  "title": "Color - what must exist for a coloured object to exist",
  "registries": ["color.json"],
  "applied_kw": ["controller", "mixing", "scanner", "interpolator", "navigator", "collection"],
  "large_kw": ["hallway", "forest", "office", "wall", "room", "corridor", "field"],
  "concepts": [
   ("No light, no color", "I - before the object",
    "Light3D.light_color: the room decides first. Kill the light and every albedo in the scene is the same black.",
    ["laser", "disco", "strobe", "flashlight", "lamp", "bulb"], ["light"]),
   ("The triple", "II - the number",
    "Color(r, g, b) - three floats 0..1. Additive mixing: the whole visible world in a trench coat of three numbers.",
    ["mixing", "colorball", "rgb", "additive", "coloredline", "spherecolor"], ["mix", "triple"]),
   ("The second door", "II - the number",
    "Color.from_hsv(h, s, v) - the SAME triple through human knobs: which color, how pure, how bright.",
    ["hsv", "hue", "spectrum", "saturation", "space_navigator"], ["wheel", "navigator"]),
   ("Skin", "III - the body",
    "albedo_color: color as what a surface REFLECTS. Paint, nails, sheets - color applied to a body as an act.",
    ["nail", "paint", "sheet", "skin", "albedo", "gridcolor", "swatch", "sticker"], ["hand", "apply"]),
   ("Glow", "III - the body",
    "emission: color as what a body EMITS. Self-luminous - the neon, the rainbow emitter, color that needs no light.",
    ["emission", "glow", "neon", "rainbow", "emitter"], ["luminous"]),
   ("Through", "III - the body",
    "alpha / transparency: color light passes THROUGH - the prism, the fin, the stained pane.",
    ["prism", "transparen", "alpha", "glass", "fin", "translucen"], ["through"]),
   ("Multiplication", "IV - the meeting",
    "seen = light x albedo. A red dress under blue light is black: metamerism, the stage-light lesson.",
    ["metameri", "scanner"], ["stage", "match"]),
   ("The path", "IV - the meeting",
    "Color.lerp and Gradient: between two colors there are many roads - the RGB road greys out mid-way, the HSV road stays saturated around the wheel.",
    ["gradient", "interpolat", "lerp", "trail", "transition"], ["between", "ramp"]),
   ("The chord", "V - the relation",
    "complementary, triad, temperature - relations BETWEEN triples. The engine has no word for harmony; that silence is culture's rung.",
    ["sets", "palette", "collection", "pillar", "complementary", "triad", "harmony", "k_means"], ["chord", "scheme"]),
   ("The ground", "V - the relation",
    "simultaneous contrast: the same triple reads differently against different grounds. Albers - color is the relation, not the number.",
    ["contrast", "simultaneous", "albers", "constancy", "context"], ["ground", "relation"]),
   ("The screen's flesh", "VI - the screen and the room",
    "digital materiality: subpixels, banding, glitch. The screen's body showing through the image - the queer flesh of digital color.",
    ["glitch", "subpixel", "banding", "pixel", "artifact_compression"], ["screen", "digital"]),
   ("The room", "VI - the screen and the room",
    "Environment: ambient, fog, sky. Color you stand INSIDE - Rothko as weather, Turrell as architecture. The loop closes: color is perception.",
    ["fog", "ambient", "atmosphere", "constellation", "office", "forest", "room", "rothko", "turrell"], ["environment", "inside"]),
  ],
  "catch_all": ("Off the ladder", "meta", "color-registry artifacts the taxonomy does not yet claim - furniture, sticks, factories. A chip decides their fate."),
 },
 "transformation": {
  "title": "Transformations",
  "registries": ["transforms.json", "alternative_geometries.json"],
  "applied_kw": ["workbench", "composition", "carousel", "machine", "gun", "demo_scene"],
  "large_kw": ["_xl", "world", "space", "maze", "tunnel", "room", "field"],
  "concepts": [
   ("Three rigid motions", "rigid motions", "translation, rotation, scale: the grammar of motion.", ["transformation_workbench", "workbench", "three"], ["grammar"]),
   ("Translation", "rigid motions", "translation preserves everything except position.", ["translation", "translate", "axis_translation", "x_translation", "y_translation", "z_translation", "displacement"], ["slide", "move"]),
   ("Rotation", "rigid motions", "rotation turns without resizing — the circle hidden in motion.", ["rotation", "rotate", "gimbal", "spin", "orient"], ["angle", "turn"]),
   ("Scale", "rigid motions", "scale resizes; a shape is a ratio held against a unit.", ["scale", "scaleme", "dilation", "resize", "rotatescale"], ["bigger", "shrink"]),
   ("Shear", "beyond rigid", "shear slides parallel layers past each other.", ["shear", "skew"], ["slant"]),
   ("Composition", "beyond rigid", "transforms compose, and the order is the meaning.", ["composition", "compose", "transform_composition", "carousel_cake"], ["chain", "sequence"]),
   ("Matrix / homogeneous", "representation", "every transform is a matrix; homogeneous coordinates unify them.", ["matrix_4x4", "homogeneous", "homogeneous_coordinates", "4x4"], ["matrix", "linear"]),
   ("Invariants", "representation", "what a transform leaves unchanged names its kind.", ["invariant", "invariants_demo", "preserve"], ["unchanged"]),
   ("Tiling / pattern", "operations on space", "a transform repeated fills a plane.", ["floor_tiles", "tile", "tiling", "pattern"], ["repeat", "wallpaper"]),
   ("Field / flow", "operations on space", "a transform assigned to every point is a field.", ["vector_field", "quantum_field", "field", "flow"], ["vector"]),
   ("Boolean / CSG", "operations on space", "add and subtract solids to carve new form.", ["boolean", "csg", "boolean_tunnel", "union", "subtract"], ["carve"]),
   ("Curved space (non-Euclidean)", "operations on space", "transform the space itself, not the object in it.", ["mobius", "riemann", "hyperbolic", "elliptic", "gyroid", "curvature", "non_euclidean", "organic_space", "rhizomatic", "bulging", "marching_cubes", "toruscylinder"], ["geodesic", "saddle"]),
  ],
  "catch_all": ("Other transforms", "operations on space", "transformation artifacts not yet sorted."),
 },
 "primitives": {
  "title": "Primitives",
  "registries": ["primitives.json", "primitive_assembler.json", "primitive_combo_puzzle.json"],
  "applied_kw": ["puzzle", "tool", "editor", "drag", "snap", "slider", "plate", "builder", "game", "edit", "sword", "evolution_screen", "runner"],
  "large_kw": ["_xl", "field", "world", "layout", "bookshelf", "tower", "hall", "_big", "bigframe"],
  "concepts": [
   ("Point", "0D · point", "a point is a decision: here, not there — but only inside a system.", ["origin", "point_origin", "grab_sphere_point", "vertex", "pixel_thumb"], ["dot", "position", "point"]),
   ("Line / edge", "1D · line", "a line is the claim two things are connected — and the ruler that measures it.", ["grabbable_line", "coordinate_lines", "cross_line", "cross_lines", "grid_lines", "edge", "segment"], ["line", "connect", "between"]),
   ("Arrow / vector", "1D · line", "a line with a direction is an instruction, not a place.", ["arrow", "vector_arrow", "laser_sword"], ["direction"]),
   ("Triangle", "2D · surface", "three lines make the minimum enclosure — the first closed thing.", ["triangle", "lefttriangle", "pythagorean", "draw_triangle"], ["tri"]),
   ("Plane / quad", "2D · surface", "a flat surface: the field a shape is drawn upon.", ["plane", "quad", "square", "glass_plane", "rectangle"], ["flat", "face"]),
   ("Grid / array", "2D · surface", "the grid is the commitment to discretize — to count space.", ["grid", "dgrid", "array", "lattice", "chalkboard"], ["cell", "rows"]),
   ("Cube / box", "3D · solids", "the cube: six faces, the faceted unit of volume.", ["cube", "box", "animatedcube", "animated_cube", "voxel"], ["block"]),
   ("Sphere / ball", "3D · solids", "the sphere: every point equidistant from a centre.", ["sphere", "ball", "orb", "floating_sphere"], ["round"]),
   ("Cylinder", "3D · solids", "a circle swept along a line.", ["cylinder", "tube", "pipe", "barrel"], []),
   ("Capsule", "3D · solids", "a cylinder with hemispherical caps — the soft solid.", ["capsule", "pill"], []),
   ("Torus / ring", "3D · solids", "a solid with a hole — genus one, the first topology.", ["torus", "toroid", "donut", "ring_solid"], ["ring"]),
   ("Platonic / polyhedra", "3D · solids", "the regular solids: symmetry made into volume.", ["tetrahedron", "octahedron", "dodecahedron", "icosahedron", "polyhedra", "platonic", "icosphere"], []),
   ("Cone / pyramid", "3D · solids", "a base tapering to a point.", ["cone", "pyramid", "bipyramid", "spike", "wedge"], ["taper"]),
   ("Prism / extrusion", "3D · solids", "a 2D profile pushed through the third dimension.", ["prism", "extrude", "extrusion", "prismblock", "prism_block"], []),
   ("Helix / spiral", "3D · solids", "a line that climbs as it turns.", ["helix", "spiral", "coil", "spring_shape", "screw"], []),
   ("Arch / structure", "structures", "primitives composed into something that stands.", ["arch", "vault", "column", "frame", "bigframe", "scaffold", "bookshelf"], ["beam"]),
   ("Curve / organic", "structures", "the smooth and the grown — designed and botanical form.", ["vase", "tree", "flower", "tulip", "aalto", "alessi", "bezier", "spline", "lathe", "blob", "leaf", "organic"], ["curve", "smooth"]),
   ("Text / glyph", "meta", "a primitive that carries a symbol.", ["text", "glyph", "letter", "pixel_heart", "icon", "label", "number"], ["font"]),
   ("Assembly / SDF / boolean", "meta", "primitives combined: union, subtraction, the assembler.", ["assembler", "combine", "combo", "boolean", "csg", "sdf", "union", "composite", "merge"], ["assembly"]),
   ("Interactive tool", "meta", "a primitive you grab, drag, snap or edit.", ["slider", "plate", "drag", "snap", "grab_tetrahedron", "grab_octahedron", "puzzle", "editor", "builder", "xyz_slider", "edit"], ["tool"]),
  ],
  "catch_all": ("Other primitives", "meta", "primitive artifacts not yet sorted."),
 },
}


def load_registry(fn):
    p = os.path.join(REG, fn)
    if not os.path.exists(p):
        return {}
    d = json.load(open(p, encoding="utf-8"))
    return d.get("artifacts", d)


def footprint_cells(a):
    fp = a.get("footprint") or a.get("parameters", {}).get("footprint")
    if isinstance(fp, list) and len(fp) >= 3:
        return max(1, int(round(fp[0])) * int(round(fp[2])))
    sn = a.get("spatial_needs", {})
    fc = sn.get("footprint_cells")
    if isinstance(fc, list) and len(fc) >= 2:
        return max(1, int(round(fc[0])) * int(round(fc[1])))
    return 4


def tier_of(lookup, name, fp, applied_kw, large_kw):
    low = (lookup + " " + name).lower()
    if any(k in low for k in applied_kw):
        return "applied"
    if any(k in low for k in large_kw) or fp >= 9:
        return "large"
    if fp >= 3:
        return "medium"
    return "small"


def score(lookup, name, desc, strong, weak):
    s = 0.0
    for kw in strong:
        if kw == lookup:
            s += 6
        elif kw in lookup:
            s += 3
        elif kw in name:
            s += 2
        elif kw in desc:
            s += 1
    for kw in weak:
        if kw in lookup or kw in name or kw in desc:
            s += 0.5
    return s


def build(domain):
    cfg = CONFIG[domain]
    arts = {}
    for fn in cfg["registries"]:
        for lk, a in load_registry(fn).items():
            if isinstance(a, dict):
                arts[lk] = (a, fn)
    concept_keys = [c[0] for c in cfg["concepts"]] + [cfg["catch_all"][0]]
    meta = {}
    for c in cfg["concepts"]:
        meta[c[0]] = {"act": c[1], "truth": c[2]}
    meta[cfg["catch_all"][0]] = {"act": cfg["catch_all"][1], "truth": cfg["catch_all"][2]}
    groups = {k: [] for k in concept_keys}
    concept_text = {k: meta[k].get("truth", "") for k in concept_keys}   # accrue each concept's prose

    for lk, (a, fn) in sorted(arts.items()):
        name = (a.get("name") or lk).lower()
        desc = (a.get("description") or "").lower() + " " + " ".join(a.get("tags", []) + a.get("dev_themes", [])).lower()
        best, bestscore = cfg["catch_all"][0], 0.0
        for key, _act, _truth, strong, weak in cfg["concepts"]:
            sc = score(lk.lower(), name, desc, strong, weak)
            if sc > bestscore:
                bestscore, best = sc, key
        fp = footprint_cells(a)
        tier = tier_of(lk.lower(), name, fp, cfg["applied_kw"], cfg["large_kw"])
        groups[best].append({
            "lookup": lk, "name": a.get("name", lk), "registry": fn,
            "tier": tier, "fp": fp,
            "has_image": os.path.exists(os.path.join(IMG_DIR, lk + ".png")),
            "recommended": bool(a.get("map_ready", False)),
        })
        concept_text[best] += " " + name + " " + (a.get("description") or "")

    for k in concept_keys:
        tiers = {"small": [], "medium": [], "large": [], "applied": []}
        for art in groups[k]:
            tiers[art["tier"]].append(art["lookup"])
        meta[k]["tiers"] = tiers
        meta[k]["count"] = len(groups[k])
        meta[k]["thin"] = len(groups[k]) <= 1
    # drop empty concepts (keep order)
    # Keep DECLARED concepts even when empty: a starving rung is a loud gap the
    # curation gallery must show (forces' Scaling taught this), and the additions
    # hand-layer can only fill a concept that exists. Only the catch-all may vanish.
    concept_keys = [k for k in concept_keys
                    if groups[k] or k != cfg["catch_all"][0]]
    total = sum(len(groups[k]) for k in concept_keys)
    # concept-level distance: TF-IDF cosine over each concept's accrued text, min-max rescaled
    vecs, _ = T.tfidf([concept_text[k] for k in concept_keys])
    nc = len(concept_keys)
    CD = [[0.0 if i == j else T.cos_d(vecs[i], vecs[j]) for j in range(nc)] for i in range(nc)]
    _raw = [CD[i][j] for i in range(nc) for j in range(i + 1, nc)]
    if _raw and max(_raw) > min(_raw):
        lo, hi = min(_raw), max(_raw)
        CD = [[0.0 if i == j else round((CD[i][j] - lo) / (hi - lo), 4) for j in range(nc)] for i in range(nc)]
    out = {
        "title": cfg["title"], "domain": domain,
        "note": "Auto-classified by tools/build_concept_map.py — heuristic keyword scoring, tier by footprint.",
        "acts": [],
        "concepts": concept_keys,
        "concept_meta": {k: meta[k] for k in concept_keys},
        "concept_distance": CD,
        "groups": {k: groups[k] for k in concept_keys},
        "total": total, "total_concepts": len(concept_keys),
        "recommended_total": sum(1 for k in concept_keys for x in groups[k] if x["recommended"]),
        "map_ready_total": sum(1 for k in concept_keys for x in groups[k] if x["recommended"]),
    }
    return out


def main():
    which = sys.argv[1] if len(sys.argv) > 1 else None
    domains = [which] if which else list(CONFIG.keys())
    for dm in domains:
        if dm not in CONFIG:
            print("no config for", dm); continue
        out = build(dm)
        json.dump(out, open(os.path.join(DOC, dm + "_concept_map.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
        print("%s: %d artifacts -> %d concepts -> doc/%s_concept_map.json" % (dm, out["total"], out["total_concepts"], dm))
        for k in out["concepts"]:
            print("   %-28s %d" % (k, out["concept_meta"][k]["count"]))


if __name__ == "__main__":
    main()
