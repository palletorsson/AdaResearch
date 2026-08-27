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
 "isosurfaces": {
  # THE ISOSURFACE TAXONOMY (2026-08-27). Cheat-code: a field sampled, then an
  # ArrayMesh built where it crosses a number you CHOSE. The surface is an OPINION
  # about a threshold - move the number and the object is different, though nothing
  # in the field changed. June's "concepts" were truncated map blurbs (one was
  # literally named "Two hundred and fifty"); no builder and no alias owned the file,
  # so the canon is authored here and the generic builder owns it from now on.
  "title": "Isosurfaces - the surface is an opinion about a threshold",
  "registries": ["isosurfaces.json"],
  "applied_kw": ["sculpt", "demo", "explorer", "gallery"],
  "large_kw": ["landscape", "cave", "world", "terrain", "system"],
  "concepts": [
   ("The field", "I - before the surface",
    "a function from position to number: how 'inside' each point is. No geometry yet - just space with an opinion everywhere, and most of it invisible.",
    ["noise_field", "scalar_field", "voxel_noise", "animated_noise"], ["field", "density"]),
   ("The threshold", "I - before the surface",
    "pick a number and call it the skin. iso = 0.5 is a DECISION, not a discovery: move it and the object changes while the field stays exactly the same.",
    ["threshold", "isolevel", "iso_value", "cutoff"], ["level", "surface_at"]),
   ("The sample grid", "II - asking",
    "you cannot ask every point, so you ask a lattice. Resolution is a budget, and every isosurface you have ever seen was an interview with finitely many places.",
    ["grid_resolution", "sample_grid", "lattice", "voxel_grid"], ["resolution", "samples"]),
   ("The fifteen cases", "II - asking",
    "eight corners, each in or out: 256 configurations, 15 after symmetry. The lookup table is the whole algorithm - the rest is bookkeeping.",
    ["fifteen_cases", "marching_cubes", "marching_squares", "mc_base", "case_table"], ["cases", "lookup"]),
   ("The interpolation", "III - the skin",
    "WHERE between two corners does the surface cross? Snap to the midpoint and it is blocky; interpolate on the field values and it is smooth. Same cases, different world.",
    ["interpolat", "smooth_shading", "vertex_lerp"], ["between", "blocky"]),
   ("The normal from the field", "III - the skin",
    "the gradient of the field IS the surface normal - lighting comes free from the same function that made the shape, because a field knows which way it thickens.",
    ["normal", "gradient", "shading"], ["lighting", "smooth_normal"]),
   ("Metaballs & implicit sums", "IV - what fields can be",
    "sum a few smooth fields and where they cross the threshold they MERGE: two blobs become one skin with no seam, which no mesh operation gives you.",
    ["metaball", "metaballs", "blob", "raymarched", "nakama"], ["merge", "implicit"]),
   ("Distance fields (SDF)", "IV - what fields can be",
    "let the number be distance-to-the-nearest-thing and the field becomes sculptural: add, subtract and blend solids by arithmetic on the value.",
    ["sdf", "gyroid", "distance_field", "sculpt"], ["signed", "carve"]),
   ("Landscapes & caves", "V - inhabiting the field",
    "the same algorithm at world scale: terrain is a threshold read from above, a cave the same threshold read from inside. Overhangs are the proof it is not a heightmap.",
    ["landscape", "terrain", "cave", "overhang", "portal", "rhizome", "queer_marching"], ["world", "inside"]),
   ("The field that moves", "V - inhabiting the field",
    "animate the field and the surface chases it - the skin is recomputed, never deformed, so it can split, merge and heal without anybody managing topology.",
    ["animated", "fountain", "evolving", "torus_sculpture", "shapes_gallery"], ["chase", "recompute"]),
  ],
  "catch_all": ("Off the ladder", "meta", "isosurface artifacts the taxonomy does not yet claim. A chip decides their fate."),
 },
 "noise": {
  # THE NOISE TAXONOMY (2026-08-27). Cheat-code: FastNoiseLite - randomness with a
  # NEIGHBOURHOOD. And the API is the ladder outright: noise is a FUNCTION, not a
  # stream (same x, same answer, forever); frequency is how fast the neighbourhood
  # forgets; fractal_octaves stacks the scales; noise_type is four temperaments of
  # coherence; domain_warp is noise controlling where noise is read. June's canon
  # was map blurbs ("White noise screams chaos" as a concept name); replaced.
  # Sequence truth kept: "Noise is randomness that remembers its neighbors."
  "title": "Noise - randomness with a neighbourhood",
  # noise.json ONLY. The sequence's bodies live in randomness.json, but scanning it
  # wholesale dumped 112 unrelated tokens into Off-the-ladder (the graphtheory
  # lesson). The 34 that belong arrive by the additions hand layer instead.
  "registries": ["noise.json"],
  "applied_kw": ["sculptor", "painter", "loom"],
  "large_kw": ["terrain", "space", "clouds", "world"],
  "concepts": [
   ("The scream", "I - before the promise",
    "white noise: randomness with NO neighbourhood - every sample a stranger to the last. The static the rest of the ladder tames.",
    ["whitenoise", "white_noise", "randompoint", "randompoints"], ["tv"]),
   ("The promise", "I - before the promise",
    "get_noise_2d(x, y): nearby points agree, and the same point answers the same forever. Noise is a FUNCTION wearing weather, not dice.",
    ["perlin_noise", "living_paper_perlin", "particle_randomness_perlin", "perlin_noise_clouds"], ["smooth"]),
   ("Frequency", "II - the knobs",
    "noise.frequency: how fast the neighbourhood forgets. Zoom is vocabulary - the same cloud at three magnifications is three moods.",
    ["noise_mixer", "profile_noise", "frequency"], ["wavelength"]),
   ("Octaves", "II - the knobs",
    "fractal_octaves, lacunarity, gain: scales stacked into detail. Mountains are a sum - big shapes plus their own gossip.",
    ["octaves", "noiselayers", "living_paper_noise_octaves", "profile_noise_octaves"], ["stack"]),
   ("The kinds", "II - the knobs",
    "noise_type: Perlin, Simplex, Cellular, Value - four temperaments of coherence from one seed. Worley's cells against Perlin's hills.",
    ["simplex_noise", "value_noise", "blue_noise", "curl_noise", "worley"], ["kind", "temperament"]),
   ("The field", "III - noise at work",
    "noise as DIRECTION: sample to angle, and space itself acquires a lean. The flow field is a cloud read as a map of wills.",
    ["noise_space", "shader_noise_space", "noisecolors", "noisesphere", "noisetorus"], ["direction"]),
   ("Displacement", "III - noise at work",
    "noise moving geometry: heights from samples - terrain, melted marble, the surface that remembered a storm.",
    ["noise_terrain", "perlin_noise_terrain", "perlin_terrain_sculptor", "terrain_with_blobs", "pool_hole_noise", "melting", "noise_sculpture"], ["relief"]),
   ("Noise of noise", "III - noise at work",
    "domain_warp: the output of one function bends the input of the next - noise controlling WHERE noise is read. The engine ships the warp.",
    ["warp", "noise_of", "nested", "noisesphere"], ["domain"]),
   ("The world", "IV - the door",
    "noise as substrate: give it enough octaves and a threshold and it is a coastline, a cave, a planet. The corridor to proceduralgeneration.",
    ["world", "planet", "substrate", "noise_space"], ["procgen"]),
  ],
  "catch_all": ("Off the ladder", "meta", "noise-registry artifacts the taxonomy does not yet claim. A chip decides their fate."),
 },
 "wavefunctions": {
  # THE WAVE TAXONOMY (2026-08-27). Cheat-code: sin(t) + AudioStreamPlayer - ONE
  # oscillator wearing two costumes. The unit circle is the engine's only oscillator;
  # everything else is that rotation dressed differently: shadowed (sine), summed
  # (Fourier - AudioStreamGenerator fills its buffer one addition at a time), met
  # (interference), answered (resonance), walked (propagation), HEARD (the same
  # phase at 44,100 samples a second stops being motion and becomes pitch), and
  # finally broken (the double pendulum, where the promise of return fails - the
  # door to randomness). June's canon was half real rungs, half room names; the
  # room sections survive by carry-forward while this ladder takes the canon.
  "title": "Wavefunctions - one oscillator wearing two costumes",
  "registries": ["wavefunctions.json"],
  "applied_kw": ["synth", "oscillator", "theremin", "sampler"],
  "large_kw": ["hall", "stairs", "space", "room", "field"],
  "concepts": [
   ("The circle", "I - the source",
    "sin(t) is the vertical shadow of uniform rotation. The unit circle is the engine's only oscillator; everything after is costume.",
    ["unit_circle", "circle", "rotation_shadow", "crank"], ["yoke"]),
   ("The three knobs", "I - the source",
    "A * sin(w*t + phi): amplitude, frequency, phase - everything a wave can be, in three floats.",
    ["amplitude", "frequency", "phase", "knob"], ["parameter"]),
   ("The wave in space", "II - the walk",
    "sin(x - v*t): the same function walked; period becomes wavelength, and the curve is somewhere you can stand.",
    ["sine_space", "trig_walk", "wavelength", "walkable"], ["trace"]),
   ("The sum", "III - the chorus",
    "Fourier: any signal is a sum of sines. Epicycles are the theorem made brass; AudioStreamGenerator fills its buffer one addition at a time.",
    ["fourier", "synthesis", "harmonic", "additive", "epicycle"], ["sum", "square_wave"]),
   ("The meeting", "III - the chorus",
    "interference: two waves add POINTWISE - reinforcing, cancelling, and beating slowly when nearly equal.",
    ["interfer", "beat", "superpos"], ["cancel", "node"]),
   ("Resonance", "III - the chorus",
    "a pendulum answers only its own frequency: gravity + length -> period, and the wave that matches it is the one it amplifies.",
    ["pendulum", "resonan", "natural_freq"], ["swing", "answer"]),
   ("Propagation", "IV - leaving home",
    "the wave leaves its source: fronts in 3D, the medium carrying what no single particle keeps.",
    ["propagat", "wavefront", "ripple", "chladni"], ["medium"]),
   ("The second costume", "IV - leaving home",
    "AudioStreamPlayer: the SAME sin(t), pushed 44,100 times a second, stops being motion and becomes PITCH. Seen and heard are one function.",
    ["sound", "audio", "tone", "horn", "speaker", "hear"], ["pitch", "sample"]),
   ("The break", "V - the door out",
    "the double pendulum: periodic to chaotic - where the promise of return fails. The door out of waves and into randomness.",
    ["double_pendulum", "chaos", "chaotic"], ["break", "unpredict"]),
  ],
  "catch_all": ("Off the ladder", "meta", "wave-registry artifacts the taxonomy does not yet claim. A chip decides their fate."),
 },
 "change": {
  # THE CHANGE TAXONOMY (2026-08-27). The cheat-code: the engine does calculus
  # NUMERICALLY, every frame - _process(delta) is a Riemann sum you live inside.
  # derivative = (now - before) / delta, integral = x += rate * delta, and the
  # fundamental theorem is the fact that the engine runs both at once and they
  # agree. June's four concepts (Rate/Accumulation/Flow/Reconciliation) were
  # already calculus-true; this grounds them in the frame and closes the loop
  # toward wavefunctions. Sequence truth kept: "Things change. Change
  # accumulates. Accumulation flows."
  "title": "Change - the frame is a Riemann sum you live inside",
  "registries": ["change.json"],
  "applied_kw": ["toy", "painter", "marble", "bridge"],
  "large_kw": ["field", "swarm", "well"],
  "concepts": [
   ("The frame", "I - before calculus",
    "_process(delta): the world is a flipbook, and delta is each page confessing how long it lasted. Nothing changes except per frame.",
    ["zoetrope", "frame", "flipbook"], ["delta", "tick"]),
   ("State", "I - before calculus",
    "a var is memory carried across frames - change needs somewhere to stand between two pages.",
    ["state", "memory_cell"], ["variable"]),
   ("The rate", "II - the two motions",
    "the derivative, as the engine knows it: (now - before) / delta. Slope measured from two frames, steepest-descent when it points downhill.",
    ["derivative", "descent", "gradient", "slope", "rate"], ["marble"]),
   ("Accumulation", "II - the two motions",
    "the integral, as the engine runs it: x += rate * delta, forever. Area under a curve is a heap the frames keep pouring.",
    ["integral", "accumul", "riemann", "area", "heap"], ["sum"]),
   ("The reconciliation", "III - the theorem",
    "the fundamental theorem: rate and accumulation are inverses, and the engine proves it every frame by running both at once.",
    ["ftc", "reconcil", "bridge", "fundamental"], ["inverse_pair"]),
   ("Flow", "IV - change with an address",
    "a rate at every point: the field. Drop anything anywhere and the space itself says which way and how fast.",
    ["flow", "field", "swarm", "particle"], ["stream"]),
   ("The loop", "V - the return",
    "fmod(t, T): change that comes home. The door out of change and into wavefunctions - a rate that repeats is a wave waiting to be named.",
    ["loop", "fmod", "period", "cycle"], ["return"]),
  ],
  "catch_all": ("Off the ladder", "meta", "change-registry artifacts the taxonomy does not yet claim. A chip decides their fate."),
 },
 "graphtheory": {
  # THE GRAPH TAXONOMY (2026-08-27). The cheat-code is the deepest in the corpus: THE
  # SCENE TREE IS ALREADY A GRAPH. Node/add_child is the engine's home data structure -
  # rooted, directed, acyclic BY REFUSAL (reparent under your own descendant and it
  # errors); NodePath is an address along edges; signals lay a second graph over the
  # tree and permit the cycles the tree refuses; AStar3D is the engine saying
  # "shortest path" out loud; GraphEdit means the editor itself ships a graph editor.
  # Rungs ordered by existence: a pair, then the home tree, then everything the tree
  # cannot say. Closes on the mirror: the artifact that renders its own subtree.
  # The June map was algorithm-name soup (one tile per named algorithm); this replaces
  # filing with teaching. Existing bodies arrive via the additions hand layer.
  "title": "Graph theory - the scene tree is already a graph",
  "registries": ["graphtheory.json"],
  "applied_kw": ["chandelier", "postman", "river", "travelers"],
  "large_kw": ["archipelago", "room", "basilica"],
  "concepts": [
   ("The pair", "I - before everything",
    "a node and an edge: a thing, and a link between things. Everything else is bookkeeping.",
    ["graphspace", "pair", "node_edge"], ["node", "edge"]),
   ("The tree", "II - the engine's home graph",
    "add_child: rooted, directed, acyclic by refusal. Move a parent and the whole line of descent moves - transform is inherited.",
    ["chandelier", "family", "tree"], ["parent", "child"]),
   ("The address", "II - the engine's home graph",
    "NodePath: '..' climbs, names descend. To reach a node is to WALK the edges - an address is a route, not a location.",
    ["postman", "path", "address", "nodepath"], ["mail", "route"]),
   ("The cycle", "III - beyond the tree",
    "what the tree refuses, connect() permits: signals close rings, and a call can outlive its caller.",
    ["ouroboros", "cycle", "ring"], ["loop", "signal"]),
   ("Direction", "III - beyond the tree",
    "parent to child is one-way. A directed graph without cycles can be SORTED into an order where every arrow points forward.",
    ["topological", "direction", "sort"], ["dag", "order"]),
   ("Degree", "IV - shape",
    "how many edges meet you. The star holds twelve hands, the wallflower one - remove the star and twelve dances end.",
    ["wallflower", "star", "degree", "hub"], ["dance", "popular"]),
   ("Components", "IV - shape",
    "islands until one edge marries them. Connectivity is a fact about the WHOLE graph, recomputed the moment a bridge opens.",
    ["archipelago", "wedding", "component", "connect"], ["island", "bridge"]),
   ("The layout", "IV - shape",
    "a graph has no WHERE until physics gives it one: springs on edges, repulsion on nodes, and shape emerges from relation.",
    ["force_directed", "layout", "basilica", "spring"], ["embed", "physics"]),
   ("Traversal", "V - walking",
    "same tree, two orders: the tide visits by distance (BFS), the diver commits to a branch (DFS). Every algorithm is an itinerary.",
    ["travelers", "traversal", "bfs", "dfs", "tide", "diver"], ["visit", "walk"]),
   ("The shortest path", "V - walking",
    "AStar3D: shortest is a fact about the whole graph. Sink one stone and the spark learns a new river.",
    ["river", "impatient", "astar", "shortest", "pathfinding"], ["spark", "stone"]),
   ("The seven bridges", "V - walking",
    "Konigsberg, 1736: cross every bridge exactly once - impossible, and the proof needed only DEGREES. The founding story.",
    ["konigsberg", "bridge", "euler"], ["seven"]),
   ("The skeleton and the pipes", "VI - the economy",
    "the cheapest tree that still touches everyone (MST), and the most a network can carry (flow, cut, matching) - graphs with prices on their edges.",
    ["mst", "spanning", "flow", "matching", "karger", "edmonds", "relabel"], ["network", "cost"]),
   ("The graph you are in", "VII - the mirror",
    "get_children(): you have been standing in a graph all along. This map, this artifact, you - nodes under one root.",
    ["tree_you_are_in", "mirror", "self", "switchboard"], ["subtree", "reflection"]),
  ],
  "catch_all": ("Off the ladder", "meta", "graph-registry artifacts the taxonomy does not yet claim. A chip decides their fate."),
 },
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
    ["fog", "ambient", "atmosphere", "constellation", "office", "forest", "room", "rothko", "turrell", "organ"], ["environment", "inside"]),
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
   ("Order matters", "compose", "T after R is not R after T — composition does not commute, and the difference is geometry, not bookkeeping.", ["order_matters", "noncommut", "choreography"], ["ab_ba"]),
   ("The inverse", "compose", "affine_inverse: every rigid move can be unsaid — the undo is itself a transform, and composing a move with its inverse is the identity.", ["inverse", "undo", "unwind"], ["affine_inverse"]),
   ("Local and global", "compose", "a child's transform lives INSIDE its parent's — the dancer keeps her pose while the stage turns her through the world.", ["local_global", "stage", "parent_space"], ["inherit"]),
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
   ("Point", "0D · point", "a point is a decision: here, not there — but only inside a system.", ["origin", "point_origin", "invisible_point", "grab_sphere_point", "vertex", "pixel_thumb"], ["dot", "position", "point"]),
   ("Line / edge", "1D · line", "a line is the claim two things are connected — and the ruler that measures it.", ["grabbable_line", "coordinate_lines", "cross_line", "cross_lines", "grid_lines", "edge", "segment"], ["line", "connect", "between"]),
   ("Arrow / vector", "1D · line", "a line with a direction is an instruction, not a place.", ["arrow", "vector_arrow", "laser_sword"], ["direction"]),
   ("Triangle", "2D · surface", "three lines make the minimum enclosure — the first closed thing.", ["triangle", "lefttriangle", "pythagorean", "draw_triangle"], ["tri"]),
   ("Plane / quad", "2D · surface", "a flat surface: the field a shape is drawn upon.", ["plane", "quad", "square", "glass_plane", "rectangle"], ["flat", "face"]),
   ("The normal", "2D · surface", "a surface has a FRONT: normals point, and the engine culls the back — walk behind a one-sided wall and it is not there.", ["backface", "one_sided", "normal_curtain"], ["cull", "facing"]),
   ("Grid / array", "2D · surface", "the grid is the commitment to discretize — to count space.", ["grid", "dgrid", "array", "lattice", "chalkboard"], ["cell", "rows"]),
   ("The seven words", "3D · solids", "Box, Sphere, Cylinder, Capsule, Torus, Prism, Plane — the engine's whole primitive vocabulary; every body in this world is sentences made of these.", ["seven_words", "choir", "vocabulary"], []),
   ("Cube / box", "3D · solids", "the cube: six faces, the faceted unit of volume.", ["cube", "box", "animatedcube", "animated_cube", "voxel"], ["block"]),
   ("Sphere / ball", "3D · solids", "the sphere: every point equidistant from a centre.", ["sphere", "ball", "orb", "floating_sphere"], ["round"]),
   ("Cylinder", "3D · solids", "a circle swept along a line.", ["cylinder", "tube", "pipe", "barrel"], []),
   ("Capsule", "3D · solids", "a cylinder with hemispherical caps — the soft solid.", ["capsule", "pill"], []),
   ("Torus / ring", "3D · solids", "a solid with a hole — genus one, the first topology.", ["torus", "toroid", "donut", "ring_solid"], ["ring"]),
   ("Platonic / polyhedra", "3D · solids", "the regular solids: symmetry made into volume.", ["tetrahedron", "octahedron", "dodecahedron", "icosahedron", "polyhedra", "platonic", "icosphere"], []),
   ("Cone / pyramid", "3D · solids", "a base tapering to a point.", ["cone", "pyramid", "bipyramid", "spike", "wedge"], ["taper"]),
   ("Prism / extrusion", "3D · solids", "a 2D profile pushed through the third dimension.", ["prism", "extrude", "extrusion", "prismblock", "prism_block"], []),
   ("The budget of smoothness", "3D · solids", "a sphere is a polyhedron in a trench coat: radial_segments is the budget, smoothness the purchase.", ["budget_of", "segments", "tessellation", "lowpoly"], ["resolution"]),
   ("Helix / spiral", "3D · solids", "a line that climbs as it turns.", ["helix", "spiral", "coil", "spring_shape", "screw"], []),
   ("Arch / structure", "structures", "primitives composed into something that stands.", ["arch", "vault", "column", "frame", "bigframe", "scaffold", "bookshelf"], ["beam"]),
   ("Curve / organic", "structures", "the smooth and the grown — designed and botanical form.", ["vase", "tree", "flower", "tulip", "aalto", "alessi", "bezier", "spline", "lathe", "blob", "leaf", "organic"], ["curve", "smooth"]),
   ("Text / glyph", "meta", "a primitive that carries a symbol.", ["text", "glyph", "letter", "pixel_heart", "icon", "label", "number"], ["font"]),
   ("Assembly / SDF / boolean", "meta", "primitives combined: union, subtraction, the assembler.", ["assembler", "combine", "combo", "boolean", "csg", "sdf", "union", "composite", "merge"], ["assembly"]),
   ("Everything is triangles", "the confession", "under every solid here, triangles all the way down — the wireframe twin shows the seams.", ["wireframe", "confession", "lathe"], ["mesh_edges"]),
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
        # CARRY FORWARD sections this builder does not own. The June maps carried a
        # "palette (unplaced)" section appended by another tool; a regen that drops it
        # silently deletes 50+ curation candidates from the concept gallery (measured
        # on transformation, 2026-08-27). Any concept present in the existing file but
        # absent from the config survives, minus tokens the new scoring now claims.
        prev_path = os.path.join(DOC, dm + "_concept_map.json")
        if os.path.exists(prev_path):
            try:
                prev = json.load(open(prev_path, encoding="utf-8"))
                claimed = {x["lookup"] for g in out["groups"].values() for x in g}
                for c in prev.get("concepts", []):
                    if c in out["concepts"]:
                        continue
                    # NEVER resurrect the catch-all. It is the builder's own section:
                    # when a config fix empties it, carrying the previous run's
                    # leftovers forward re-imports tokens the new scoring already
                    # rejected (noise, 2026-08-27: 110 stale tokens came back).
                    if c == cfg["catch_all"][0]:
                        continue
                    kept = [x for x in prev.get("groups", {}).get(c, [])
                            if x.get("lookup") not in claimed]
                    if kept:
                        out["concepts"].append(c)
                        out["groups"][c] = kept
                        out["concept_meta"][c] = prev.get("concept_meta", {}).get(c,
                            {"count": len(kept), "truth": "carried forward"})
                        out["concept_meta"][c]["count"] = len(kept)
            except Exception as e:
                print("  carry-forward skipped:", e)
        json.dump(out, open(os.path.join(DOC, dm + "_concept_map.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
        print("%s: %d artifacts -> %d concepts -> doc/%s_concept_map.json" % (dm, out["total"], out["total_concepts"], dm))
        for k in out["concepts"]:
            print("   %-28s %d" % (k, out["concept_meta"][k]["count"]))


if __name__ == "__main__":
    main()
