## One-off capture for the Russell's paradox DNA gallery.
##
## Six predicate-defined sets visualized as Venn-style discs, each labelled,
## with example sets drawn inside or outside based on membership. Cells 4-6
## carry self-reference arrows; cell 5 (Russell's R) carries the punchline:
## TWO red contradiction arrows forming a closed loop, neither direction
## consistent. Cell 6 shows the same paradox as a framed question — R at
## the center with both contradiction arrows orbiting like a Möbius logic.
##
## The mathematical claim — naive set theory's unrestricted comprehension
## (Frege 1879/1893) lets you build the set R = {x : x ∉ x}. Russell 1901
## observed that asking "R ∈ R?" yields a contradiction either way:
##   R ∈ R  ⇒  R satisfies its defining predicate  ⇒  R ∉ R   ⊥
##   R ∉ R  ⇒  R fails its defining predicate     ⇒  R ∈ R    ⊥
## The paradox forced set theory's revision. ZFC (Zermelo-Fraenkel, 1908/22)
## replaces unrestricted comprehension with the axiom of separation: you can
## only carve a subset out of an existing set, not conjure one from a
## predicate alone. Under separation, R = {x ∈ A : x ∉ x} is well-formed
## but reaches no contradiction — it just shows A ∉ A, which is fine.
##
## The 6 cells:
##   1. e_even              — {x : x is even integer}.        WELL-FORMED.
##   2. a_universal         — {x : x is a set}.              ZFC: no such set.
##   3. c_nonempty          — {x : x is a non-empty set}.    WELL-FORMED.
##   4. s_self_containing   — {x : x ∈ x}.                   Empty in ZFC.
##   5. r_russell           — {x : x ∉ x}.                   PARADOX.
##   6. frame_of_russell    — the question "R ∈ R?" itself.  Paradox-as-loop.
##
## Visual goals (matching halting-bench-gallery):
##   - Square 1024×1024 SubViewport, MSAA 8x + FXAA, isolated World3D
##   - Orthographic camera looking head-on at the XY plane
##   - Set as a translucent disc (TorusMesh ring + filled quad inside)
##   - Set name top of disc, predicate as text below disc
##   - Example elements as small spheres, color-coded inside/outside
##   - Self-reference arrows for cells 4-6 (curved, color = verdict)
##   - Cell 5: two red contradiction arrows forming a closed loop
##   - Cell 6: paradox at the center, two contradiction arrows orbiting
##   - Well-formed: blue rim. Empty: grey, dashed. Paradoxical: red, wavy.
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_russell_paradox_gallery.gd \
##     -- --out=user://russell_paradox_gallery
##
## Output: <out>/{id}.png + {id}.json + manifest.json
extends SceneTree

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.06, 0.07, 0.10)
const ORTHO_SIZE: float = 4.0

# Disc geometry
const DISC_RADIUS: float = 1.20
const DISC_RIM_THICKNESS: float = 0.04

# Colors
const COLOR_WELL_FORMED_RIM: Color = Color(0.40, 0.66, 1.0)        # blue rim
const COLOR_WELL_FORMED_FILL: Color = Color(0.22, 0.34, 0.58, 0.18) # very faint blue interior
const COLOR_EMPTY_RIM: Color = Color(0.62, 0.66, 0.74)              # grey
const COLOR_EMPTY_FILL: Color = Color(0.30, 0.33, 0.40, 0.10)       # near-clear grey
const COLOR_PARADOX_RIM: Color = Color(0.98, 0.36, 0.38)            # red
const COLOR_PARADOX_FILL: Color = Color(0.55, 0.18, 0.20, 0.20)     # blood interior

const COLOR_INSIDE_DOT: Color = Color(0.40, 0.92, 0.52)             # green = member
const COLOR_OUTSIDE_DOT: Color = Color(0.96, 0.58, 0.32)            # amber = non-member
const COLOR_AMBIGUOUS_DOT: Color = Color(0.94, 0.42, 0.46)          # red = paradoxical

const COLOR_ARROW_CONSISTENT: Color = Color(0.40, 0.85, 0.50)       # green = consistent self-reference
const COLOR_ARROW_PARADOX: Color = Color(0.98, 0.34, 0.36)          # red = contradiction

const TEXT_BRIGHT: Color = Color(0.96, 0.96, 0.98)
const TEXT_DIM: Color = Color(0.62, 0.66, 0.74)
const TEXT_OUTLINE: Color = Color(0.02, 0.03, 0.05, 0.9)

var _output_dir: String = "user://russell_paradox_gallery"
var _entries: Array = []
var _viewport: SubViewport
var _scene_holder: Node3D
var _camera: Camera3D


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
	_run.call_deferred()


func _run() -> void:
	# ── Viewport setup ──────────────────────────────────────────────
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.transparent_bg = false
	_viewport.own_world_3d = true
	var iso_world := World3D.new()

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.86, 0.92)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.2
	iso_world.environment = env

	_viewport.world_3d = iso_world
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_8X
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_viewport.use_taa = false
	_viewport.use_debanding = true
	get_root().add_child(_viewport)

	# A soft directional light so spheres get a hint of dimensionality.
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-40, 15, 0)
	key_light.light_energy = 0.7
	_viewport.add_child(key_light)

	# Orthographic camera looking down +Z at origin.
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = ORTHO_SIZE
	_camera.near = 0.01
	_camera.far = 50.0
	_camera.current = true
	_camera.position = Vector3(0, 0, 5)
	_viewport.add_child(_camera)
	_camera.look_at(Vector3.ZERO, Vector3.UP)

	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	# ── Sweep over the 6 cells ─────────────────────────────────────
	var specs := _build_specs()
	for spec in specs:
		_build_scene(spec)
		await create_timer(0.06).timeout
		await _capture_and_record(spec)
		_clear_holder()
		await create_timer(0.02).timeout

	# ── Manifest ────────────────────────────────────────────────────
	var manifest := {
		"version": 1,
		"description": "Six sets defined by predicates. Five are well-formed; the sixth — R = {x : x ∉ x} — paradoxes. The naive comprehension axiom (any predicate defines a set) collapses under self-reference. ZFC's restricted comprehension (axiom of separation) prevents R from being built — you can only carve a subset out of an existing set, not conjure one from a predicate. Russell's 1901 letter to Frege, made into a 6-cell Venn-style gallery.",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"camera": {"projection": "orthogonal", "size": ORTHO_SIZE},
		"references": {
			"frege": "Frege 1879/1893 — Begriffsschrift, Grundgesetze. Unrestricted comprehension: every predicate defines a set.",
			"russell": "Russell 1901 — letter to Frege. {x : x ∉ x} produces a contradiction; arithmetic's foundations are inconsistent.",
			"zfc": "Zermelo 1908, Fraenkel 1922 — ZFC. Axiom of separation: subsets are carved from existing sets, not conjured from predicates. Eliminates R as a set.",
		},
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries saved to %s" % [_entries.size(), _output_dir])
	quit(0)


# ─── Cell specifications ─────────────────────────────────────────────
# Each spec:
# {
#   "id": "1_e_even",
#   "set_name": "E",
#   "predicate": "{x : x is even integer}",
#   "english": "the even integers",
#   "examples": [{label, in_set: bool, [optional: ambiguous: bool]}, ...],
#   "verdict": "well_formed" | "empty" | "paradox" | "problematic",
#   "self_reference": "none" | "consistent_in" | "consistent_out" | "paradox" | "paradox_frame",
#   "notes": "...",
# }
func _build_specs() -> Array:
	var specs: Array = []

	# 1. E — the even integers. Classic well-formed set.
	specs.append({
		"id": "1_e_even",
		"set_name": "E",
		"predicate": "E = { x : x is even }",
		"english": "the even integers",
		"examples": [
			{"label": "2", "in_set": true},
			{"label": "4", "in_set": true},
			{"label": "6", "in_set": true},
			{"label": "1", "in_set": false},
			{"label": "3", "in_set": false},
		],
		"verdict": "well_formed",
		"self_reference": "none",
		"notes": "A textbook well-formed set. Membership is a clean predicate on integers, and integers themselves are not sets that contain integers — there is no self-reference to worry about. Comprehension and separation agree.",
	})

	# 2. A — the set of all sets. Allowed by naive comprehension. Forbidden by ZFC.
	specs.append({
		"id": "2_a_universal",
		"set_name": "A",
		"predicate": "A = { x : x is a set }",
		"english": "the universal set",
		"examples": [
			{"label": "{1,2}", "in_set": true},
			{"label": "∅", "in_set": true},
			{"label": "ℕ", "in_set": true},
			{"label": "A", "in_set": true},
		],
		"verdict": "problematic",
		"self_reference": "consistent_in",
		"notes": "Well-formed by intention — 'all sets' has a clear meaning. But under ZFC there is no universal set: by separation, A would have to contain A, and the axiom of foundation forbids x ∈ x. The naive predicate is meaningful; the ZFC machinery refuses to build it.",
	})

	# 3. C — non-empty sets. Classic, large, but unproblematic.
	specs.append({
		"id": "3_c_nonempty",
		"set_name": "C",
		"predicate": "C = { x : x is a non-empty set }",
		"english": "the non-empty sets",
		"examples": [
			{"label": "{1}", "in_set": true},
			{"label": "{1,2}", "in_set": true},
			{"label": "ℕ", "in_set": true},
			{"label": "∅", "in_set": false},
		],
		"verdict": "well_formed",
		"self_reference": "none",
		"notes": "Defined by a clean cardinality predicate. Like A, this is a 'proper class' in ZFC (too big to be a set), but the PREDICATE itself is consistent — it just defines a class, not a set. The trouble with R is not size, it's self-negation.",
	})

	# 4. S — sets that contain themselves. Naive: well-formed. ZFC: empty.
	specs.append({
		"id": "4_s_self_containing",
		"set_name": "S",
		"predicate": "S = { x : x ∈ x }",
		"english": "sets that contain themselves",
		"examples": [
			{"label": "?", "in_set": true},
		],
		"verdict": "empty",
		"self_reference": "consistent_in",
		"notes": "Naive comprehension allows it; the predicate 'x ∈ x' is meaningful. Under ZFC's axiom of foundation, no set can contain itself, so S = ∅. The point: a self-referential predicate doesn't automatically paradox — sometimes it just defines the empty set. The arrow loops back consistently because both 'S ∈ S' and 'S ∉ S' do not contradict the definition (you only contradict if you BOTH satisfy and fail the predicate at the same time).",
	})

	# 5. R — Russell's paradox. The punchline cell.
	specs.append({
		"id": "5_r_russell",
		"set_name": "R",
		"predicate": "R = { x : x ∉ x }",
		"english": "sets that do NOT contain themselves",
		"examples": [
			{"label": "{1,2}", "in_set": true},
			{"label": "∅", "in_set": true},
			{"label": "ℕ", "in_set": true},
			{"label": "R", "in_set": true, "ambiguous": true},
		],
		"verdict": "paradox",
		"self_reference": "paradox",
		"notes": "Russell 1901. Ask: is R ∈ R? If R ∈ R, then R satisfies its defining predicate (x ∉ x), so R ∉ R. If R ∉ R, then R satisfies the predicate, so R ∈ R. Both arrows are red. The contradiction is symmetric — there is no escape direction. This forced the revision of set theory.",
	})

	# 6. Frame of R — the paradox itself rendered as a closed Möbius-style loop.
	specs.append({
		"id": "6_frame_of_russell",
		"set_name": "R",
		"predicate": "R ∈ R ?",
		"english": "the question that cannot be answered",
		"examples": [],
		"verdict": "paradox",
		"self_reference": "paradox_frame",
		"notes": "The same set R rendered with its membership question at the center and both contradiction arrows orbiting it like a Möbius strip of logic. Either truth value implies its own negation. ZFC's axiom of separation — you can only carve a subset out of an existing set, never conjure one from a free-floating predicate — eliminates R as a constructible set. The paradox doesn't go away; it's just blocked at the construction step.",
	})

	return specs


# ─── Scene construction ───────────────────────────────────────────────
func _build_scene(spec: Dictionary) -> void:
	# Header — set name big at the top
	_add_set_name_header(spec)

	# The disc itself
	var verdict: String = spec["verdict"]
	_add_disc(verdict, spec.get("self_reference", "none"))

	# Example elements (inside / outside) — except for cell 6 (frame), which has none.
	if spec["id"] != "6_frame_of_russell":
		_add_examples(spec["examples"], verdict)

	# Predicate label below
	_add_predicate_label(spec["predicate"])

	# Verdict badge bottom-left
	_add_verdict_badge(verdict)

	# Self-reference / contradiction arrows
	var sr: String = spec.get("self_reference", "none")
	if sr == "consistent_in":
		_add_self_loop(COLOR_ARROW_CONSISTENT, "%s ∈ %s ?" % [spec["set_name"], spec["set_name"]])
	elif sr == "paradox":
		_add_russell_double_contradiction(spec["set_name"])
	elif sr == "paradox_frame":
		_add_frame_orbit(spec["set_name"])


# ─── Set name header (top) ────────────────────────────────────────────
func _add_set_name_header(spec: Dictionary) -> void:
	var label_text: String = spec["set_name"]
	var verdict: String = spec["verdict"]
	var color: Color = TEXT_BRIGHT
	if verdict == "paradox":
		color = COLOR_PARADOX_RIM
	elif verdict == "empty":
		color = COLOR_EMPTY_RIM
	elif verdict == "well_formed":
		color = COLOR_WELL_FORMED_RIM

	var name_lab := Label3D.new()
	name_lab.text = "Set " + label_text
	name_lab.font_size = 96
	name_lab.outline_size = 16
	name_lab.modulate = color
	name_lab.outline_modulate = TEXT_OUTLINE
	name_lab.shaded = false
	name_lab.no_depth_test = true
	name_lab.pixel_size = 0.0025
	name_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lab.position = Vector3(0.0, 1.62, 0.04)
	_scene_holder.add_child(name_lab)

	var en_lab := Label3D.new()
	en_lab.text = spec["english"]
	en_lab.font_size = 38
	en_lab.outline_size = 7
	en_lab.modulate = TEXT_DIM
	en_lab.outline_modulate = TEXT_OUTLINE
	en_lab.shaded = false
	en_lab.no_depth_test = true
	en_lab.pixel_size = 0.0025
	en_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	en_lab.position = Vector3(0.0, 1.30, 0.04)
	_scene_holder.add_child(en_lab)


# ─── The set disc ─────────────────────────────────────────────────────
# Two parts:
# - filled interior quad behind the rim (translucent)
# - rim itself drawn as a thin ring of triangles (solid color)
# For paradoxical sets, the rim is rendered with a wavy displacement.
# For empty sets, the rim is dashed (gaps every few degrees).
func _add_disc(verdict: String, self_ref: String) -> void:
	var rim_color: Color
	var fill_color: Color
	match verdict:
		"well_formed":
			rim_color = COLOR_WELL_FORMED_RIM
			fill_color = COLOR_WELL_FORMED_FILL
		"problematic":
			rim_color = COLOR_WELL_FORMED_RIM
			fill_color = COLOR_WELL_FORMED_FILL
		"empty":
			rim_color = COLOR_EMPTY_RIM
			fill_color = COLOR_EMPTY_FILL
		"paradox":
			rim_color = COLOR_PARADOX_RIM
			fill_color = COLOR_PARADOX_FILL
		_:
			rim_color = COLOR_WELL_FORMED_RIM
			fill_color = COLOR_WELL_FORMED_FILL

	# Skip the disc fill for the "frame of R" — it's a logic diagram, not a Venn.
	# Actually we KEEP a dimmed disc for the frame to read as "R" the set.
	# Interior fill (a triangle fan)
	var im_fill := ImmediateMesh.new()
	im_fill.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material_transparent(fill_color))
	var segments: int = 64
	for i in range(segments):
		var a0: float = float(i) * TAU / float(segments)
		var a1: float = float(i + 1) * TAU / float(segments)
		var c := Vector3(0, 0, 0.0)
		var p0 := Vector3(cos(a0) * DISC_RADIUS, sin(a0) * DISC_RADIUS, 0.0)
		var p1 := Vector3(cos(a1) * DISC_RADIUS, sin(a1) * DISC_RADIUS, 0.0)
		im_fill.surface_add_vertex(c)
		im_fill.surface_add_vertex(p0)
		im_fill.surface_add_vertex(p1)
	im_fill.surface_end()

	var mi_fill := MeshInstance3D.new()
	mi_fill.mesh = im_fill
	mi_fill.name = "DiscFill"
	_scene_holder.add_child(mi_fill)

	# Rim — as a ring quad strip (two-radius polygon).
	# For paradox: WAVY (radius perturbed by sin(angle * 8) * 0.02)
	# For empty: DASHED (skip every other segment)
	# For others: clean solid ring
	var im_rim := ImmediateMesh.new()
	im_rim.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material(rim_color))
	var rim_segs: int = 128
	var inner: float = DISC_RADIUS - DISC_RIM_THICKNESS * 0.5
	var outer: float = DISC_RADIUS + DISC_RIM_THICKNESS * 0.5
	for i in range(rim_segs):
		# Skip every other segment if EMPTY (dashed look)
		if verdict == "empty" and (i % 4) >= 2:
			continue
		var a0: float = float(i) * TAU / float(rim_segs)
		var a1: float = float(i + 1) * TAU / float(rim_segs)
		var wave0: float = 0.0
		var wave1: float = 0.0
		if verdict == "paradox":
			wave0 = sin(a0 * 12.0) * 0.025
			wave1 = sin(a1 * 12.0) * 0.025
		var p_in0 := Vector3(cos(a0) * (inner + wave0), sin(a0) * (inner + wave0), 0.01)
		var p_in1 := Vector3(cos(a1) * (inner + wave1), sin(a1) * (inner + wave1), 0.01)
		var p_out0 := Vector3(cos(a0) * (outer + wave0), sin(a0) * (outer + wave0), 0.01)
		var p_out1 := Vector3(cos(a1) * (outer + wave1), sin(a1) * (outer + wave1), 0.01)
		# Two triangles forming the rim quad
		im_rim.surface_add_vertex(p_in0)
		im_rim.surface_add_vertex(p_out0)
		im_rim.surface_add_vertex(p_out1)
		im_rim.surface_add_vertex(p_in0)
		im_rim.surface_add_vertex(p_out1)
		im_rim.surface_add_vertex(p_in1)
	im_rim.surface_end()

	var mi_rim := MeshInstance3D.new()
	mi_rim.mesh = im_rim
	mi_rim.name = "DiscRim"
	_scene_holder.add_child(mi_rim)


# ─── Example elements (small spheres inside / outside the disc) ───────
func _add_examples(examples: Array, verdict: String) -> void:
	if examples.is_empty():
		return

	# Place IN-set examples on a circle inside the disc; OUT-set examples
	# outside the disc, scattered. We pre-compute angular slots.
	var inside: Array = []
	var outside: Array = []
	for ex in examples:
		if ex.get("in_set", false):
			inside.append(ex)
		else:
			outside.append(ex)

	# Layout inside examples on a small inner circle
	var inside_r: float = DISC_RADIUS * 0.55
	var n_in: int = inside.size()
	for i in range(n_in):
		var ex: Dictionary = inside[i]
		var a: float
		if n_in == 1:
			a = -PI * 0.5
		else:
			# distribute around the inner ring
			a = -PI * 0.5 + float(i) * TAU / float(n_in)
		var x: float = cos(a) * inside_r
		var y: float = sin(a) * inside_r
		# Center single inside dot in the middle for visual balance
		if n_in == 1:
			x = 0.0
			y = 0.0
		var ambiguous: bool = ex.get("ambiguous", false)
		var dot_color: Color = COLOR_AMBIGUOUS_DOT if ambiguous else COLOR_INSIDE_DOT
		_add_dot(Vector3(x, y, 0.05), dot_color, ex.get("label", ""), ambiguous, verdict)

	# Layout outside examples scattered around the disc perimeter
	var outside_r: float = DISC_RADIUS + 0.35
	var n_out: int = outside.size()
	for i in range(n_out):
		var ex: Dictionary = outside[i]
		# Distribute angles to avoid colliding with inside positions.
		# Offset by quarter-turn to keep visual separation.
		var a: float = PI * 0.25 + float(i) * TAU / max(1, n_out)
		var x: float = cos(a) * outside_r
		var y: float = sin(a) * outside_r
		_add_dot(Vector3(x, y, 0.05), COLOR_OUTSIDE_DOT, ex.get("label", ""), false, verdict)


# Small sphere + label below
func _add_dot(pos: Vector3, color: Color, label: String, ambiguous: bool, verdict: String) -> void:
	var sph := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.07
	mesh.height = 0.14
	mesh.radial_segments = 16
	mesh.rings = 8
	sph.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.45
	mat.roughness = 0.4
	mat.metallic = 0.0
	sph.material_override = mat
	sph.position = pos
	_scene_holder.add_child(sph)

	# Halo for ambiguous dots — a small wavy ring around the sphere
	if ambiguous:
		var im := ImmediateMesh.new()
		var halo_col := COLOR_PARADOX_RIM
		halo_col.a = 0.7
		im.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(halo_col))
		var segs: int = 36
		var ri: float = 0.10
		var ro: float = 0.14
		for i in range(segs):
			var a0: float = float(i) * TAU / float(segs)
			var a1: float = float(i + 1) * TAU / float(segs)
			var r0: float = ri + sin(a0 * 8.0) * 0.012
			var r1: float = ri + sin(a1 * 8.0) * 0.012
			im.surface_add_vertex(Vector3(pos.x + cos(a0) * r0, pos.y + sin(a0) * r0, pos.z))
			im.surface_add_vertex(Vector3(pos.x + cos(a1) * r1, pos.y + sin(a1) * r1, pos.z))
			im.surface_add_vertex(Vector3(pos.x + cos(a0) * ro, pos.y + sin(a0) * ro, pos.z))
			im.surface_add_vertex(Vector3(pos.x + cos(a1) * ro, pos.y + sin(a1) * ro, pos.z))
		im.surface_end()
		var mi := MeshInstance3D.new()
		mi.mesh = im
		_scene_holder.add_child(mi)

	if label != "":
		var lab := Label3D.new()
		lab.text = label
		lab.font_size = 36
		lab.outline_size = 7
		lab.modulate = TEXT_BRIGHT
		if ambiguous:
			lab.modulate = COLOR_PARADOX_RIM
		lab.outline_modulate = TEXT_OUTLINE
		lab.shaded = false
		lab.no_depth_test = true
		lab.pixel_size = 0.0025
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.position = Vector3(pos.x, pos.y - 0.18, pos.z + 0.01)
		_scene_holder.add_child(lab)


# ─── Predicate label (below disc) ─────────────────────────────────────
func _add_predicate_label(predicate: String) -> void:
	var lab := Label3D.new()
	lab.text = predicate
	lab.font_size = 50
	lab.outline_size = 10
	lab.modulate = TEXT_BRIGHT
	lab.outline_modulate = TEXT_OUTLINE
	lab.shaded = false
	lab.no_depth_test = true
	lab.pixel_size = 0.0025
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.position = Vector3(0.0, -1.52, 0.04)
	_scene_holder.add_child(lab)


# ─── Verdict badge (bottom-left) ──────────────────────────────────────
func _add_verdict_badge(verdict: String) -> void:
	var text: String
	var color: Color
	match verdict:
		"well_formed":
			text = "WELL-FORMED"
			color = COLOR_WELL_FORMED_RIM
		"problematic":
			text = "PROBLEMATIC IN ZFC"
			color = Color(0.96, 0.82, 0.40)
		"empty":
			text = "EMPTY UNDER ZFC"
			color = COLOR_EMPTY_RIM
		"paradox":
			text = "PARADOX"
			color = COLOR_PARADOX_RIM
		_:
			text = verdict
			color = TEXT_DIM

	var lab := Label3D.new()
	lab.text = text
	lab.font_size = 44
	lab.outline_size = 9
	lab.modulate = color
	lab.outline_modulate = TEXT_OUTLINE
	lab.shaded = false
	lab.no_depth_test = true
	lab.pixel_size = 0.0025
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lab.position = Vector3(-1.85, -1.85, 0.04)
	_scene_holder.add_child(lab)


# ─── Self-reference loop (cell 4) ─────────────────────────────────────
# Single curved arrow from the disc back to itself, label at top.
func _add_self_loop(color: Color, label_text: String) -> void:
	# Curved arrow: a small ring above the disc that arcs from one side of
	# the disc up and back to the other side.
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(color))
	var center := Vector3(0.0, 0.30, 0.08)
	var loop_r: float = 0.45
	var segs: int = 40
	for i in range(segs):
		var t0: float = float(i) / float(segs)
		var t1: float = float(i + 1) / float(segs)
		# Open arc — 5/4 turn so it reads as a "back-to-self" loop
		var a0: float = lerpf(PI * 1.4, PI * -0.4, t0)
		var a1: float = lerpf(PI * 1.4, PI * -0.4, t1)
		var p0 := center + Vector3(cos(a0) * loop_r, sin(a0) * loop_r, 0.0)
		var p1 := center + Vector3(cos(a1) * loop_r, sin(a1) * loop_r, 0.0)
		im.surface_add_vertex(p0)
		im.surface_add_vertex(p1)
	im.surface_end()
	# Arrowhead
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material(color))
	var end_a: float = PI * -0.4
	var tip := center + Vector3(cos(end_a) * loop_r, sin(end_a) * loop_r, 0.0)
	# Tangent direction at the end of the arc
	var tang := Vector2(-sin(end_a), cos(end_a))
	var ahead_size: float = 0.10
	var base_dir := Vector3(-tang.x, -tang.y, 0.0)
	var perp := Vector3(-tang.y, tang.x, 0.0)
	var base := tip + base_dir * ahead_size
	im.surface_add_vertex(tip)
	im.surface_add_vertex(base + perp * (ahead_size * 0.5))
	im.surface_add_vertex(base - perp * (ahead_size * 0.5))
	im.surface_end()

	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "SelfLoop"
	_scene_holder.add_child(mi)

	# Question label above the loop
	var lab := Label3D.new()
	lab.text = label_text
	lab.font_size = 42
	lab.outline_size = 8
	lab.modulate = color
	lab.outline_modulate = TEXT_OUTLINE
	lab.shaded = false
	lab.no_depth_test = true
	lab.pixel_size = 0.0025
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.position = Vector3(0.0, 0.92, 0.09)
	_scene_holder.add_child(lab)


# ─── Russell's double contradiction (cell 5) ──────────────────────────
# Two red arrows forming a closed loop:
#   Arrow A: top-left ⤴ across to top-right, labelled "R ∈ R ⇒ R ∉ R"
#   Arrow B: top-right ⤵ back across to top-left, labelled "R ∉ R ⇒ R ∈ R"
# Visually they form a Möbius-style closed loop above the disc.
func _add_russell_double_contradiction(_set_name: String) -> void:
	var color := COLOR_ARROW_PARADOX
	# Two arcs, one above the other slightly offset, both labelled.
	# Arc A — upper arc, sweeping right-to-left
	_draw_arc_with_arrow(
		Vector3(-0.80, 0.32, 0.08),
		Vector3(0.80, 0.32, 0.08),
		0.55,   # arc bulge upward
		color,
		1.0
	)
	# Arc B — lower arc (closer to disc rim), sweeping left-to-right
	_draw_arc_with_arrow(
		Vector3(0.80, 0.18, 0.08),
		Vector3(-0.80, 0.18, 0.08),
		-0.30,  # arc bulge downward (curve close to disc top)
		color,
		1.0
	)

	# Top label: "R ∈ R ⇒ R ∉ R   ⊥"
	var lab_a := Label3D.new()
	lab_a.text = "R ∈ R   ⇒   R ∉ R   ⊥"
	lab_a.font_size = 44
	lab_a.outline_size = 9
	lab_a.modulate = color
	lab_a.outline_modulate = TEXT_OUTLINE
	lab_a.shaded = false
	lab_a.no_depth_test = true
	lab_a.pixel_size = 0.0025
	lab_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab_a.position = Vector3(0.0, 1.00, 0.09)
	_scene_holder.add_child(lab_a)

	# Bottom label: "R ∉ R ⇒ R ∈ R   ⊥"
	var lab_b := Label3D.new()
	lab_b.text = "R ∉ R   ⇒   R ∈ R   ⊥"
	lab_b.font_size = 44
	lab_b.outline_size = 9
	lab_b.modulate = color
	lab_b.outline_modulate = TEXT_OUTLINE
	lab_b.shaded = false
	lab_b.no_depth_test = true
	lab_b.pixel_size = 0.0025
	lab_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab_b.position = Vector3(0.0, -0.05, 0.09)
	_scene_holder.add_child(lab_b)


# Draw a curved arrow from p0 to p1 with a sagitta `bulge` (positive = arc
# bulges in +Y direction beyond the straight line; negative = bulges in -Y).
# Arrow head is drawn at p1.
func _draw_arc_with_arrow(p0: Vector3, p1: Vector3, bulge: float, color: Color, _line_thickness: float) -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(color))
	var segs: int = 32
	# Parameterize a quadratic Bezier with control point = midpoint + bulge * up.
	# This gives us a clean arc.
	var mid := (p0 + p1) * 0.5
	# "Up" perpendicular to the segment in the XY plane
	var dir := (p1 - p0).normalized()
	var perp := Vector3(-dir.y, dir.x, 0.0)
	var control := mid + perp * bulge
	var pts: Array = []
	for i in range(segs + 1):
		var t: float = float(i) / float(segs)
		var inv: float = 1.0 - t
		# Quadratic Bezier
		var pt: Vector3 = inv * inv * p0 + 2.0 * inv * t * control + t * t * p1
		pts.append(pt)
	# Slight thickness via duplicated lines offset by a tiny amount
	# For now: single-pixel line is fine at MSAA 8x.
	for i in range(segs):
		im.surface_add_vertex(pts[i])
		im.surface_add_vertex(pts[i + 1])
	# Second pass — a parallel line offset slightly for thickness
	for i in range(segs):
		var off_a: Vector3 = (pts[i + 1] - pts[i]).normalized()
		var off_p := Vector3(-off_a.y, off_a.x, 0.0) * 0.015
		im.surface_add_vertex(pts[i] + off_p)
		im.surface_add_vertex(pts[i + 1] + off_p)
	im.surface_end()

	# Arrowhead at p1
	# Direction of approach: from last segment.
	var n: int = pts.size()
	var approach: Vector3 = (pts[n - 1] - pts[n - 2]).normalized()
	var ahead_size: float = 0.12
	var perp_h := Vector3(-approach.y, approach.x, 0.0)
	var base := p1 - approach * ahead_size
	var tri := ImmediateMesh.new()
	tri.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material(color))
	tri.surface_add_vertex(p1)
	tri.surface_add_vertex(base + perp_h * (ahead_size * 0.55))
	tri.surface_add_vertex(base - perp_h * (ahead_size * 0.55))
	tri.surface_end()

	var mi := MeshInstance3D.new()
	mi.mesh = im
	_scene_holder.add_child(mi)
	var mi_tri := MeshInstance3D.new()
	mi_tri.mesh = tri
	_scene_holder.add_child(mi_tri)


# ─── Frame of R (cell 6) — paradox-as-orbit ───────────────────────────
# Renders R as the disc (already drawn) with a big "?" at the centre and
# two contradiction arrows orbiting like a Möbius strip of logic. The
# arrows form a near-closed loop that visibly doesn't close — neither
# direction terminates.
func _add_frame_orbit(_set_name: String) -> void:
	var color := COLOR_ARROW_PARADOX

	# Big "?" at the centre
	var q_lab := Label3D.new()
	q_lab.text = "?"
	q_lab.font_size = 240
	q_lab.outline_size = 24
	q_lab.modulate = color
	q_lab.outline_modulate = TEXT_OUTLINE
	q_lab.shaded = false
	q_lab.no_depth_test = true
	q_lab.pixel_size = 0.0025
	q_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q_lab.position = Vector3(0.0, 0.06, 0.08)
	_scene_holder.add_child(q_lab)

	# Orbiting contradiction arrows — two arcs that wrap most-of-the-way
	# around the disc, in opposite directions, slightly offset radii. The
	# offset radii read as a Möbius double-loop.
	# Arc 1: from angle a to angle b, outer radius
	# Arc 2: from angle b to angle a, inner radius — but the gap remains
	# visible at both ends to make "doesn't close" legible.
	# Tighter radii so labels sit clear of the header/footer
	var r1: float = 1.40
	var r2: float = 1.26
	# Each arc spans most-of-the-way with gap at one end
	var arc1_start: float = deg_to_rad(115.0)
	var arc1_end: float = deg_to_rad(425.0)   # wraps through bottom
	var arc2_start: float = deg_to_rad(295.0)
	var arc2_end: float = deg_to_rad(605.0)

	_draw_orbit_arc(Vector3.ZERO, r1, arc1_start, arc1_end, color)
	_draw_orbit_arc(Vector3.ZERO, r2, arc2_start, arc2_end, color)

	# Side-positioned implication labels (not above/below where they collide
	# with the header / footer). The arrows themselves give direction; the
	# labels just name each arc.
	var lab_a := Label3D.new()
	lab_a.text = "R ∈ R ⇒ R ∉ R"
	lab_a.font_size = 38
	lab_a.outline_size = 8
	lab_a.modulate = color
	lab_a.outline_modulate = TEXT_OUTLINE
	lab_a.shaded = false
	lab_a.no_depth_test = true
	lab_a.pixel_size = 0.0025
	lab_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Above the disc, but BELOW the header subtitle ("the question…")
	lab_a.position = Vector3(0.0, 0.80, 0.09)
	_scene_holder.add_child(lab_a)

	var lab_b := Label3D.new()
	lab_b.text = "R ∉ R ⇒ R ∈ R"
	lab_b.font_size = 38
	lab_b.outline_size = 8
	lab_b.modulate = color
	lab_b.outline_modulate = TEXT_OUTLINE
	lab_b.shaded = false
	lab_b.no_depth_test = true
	lab_b.pixel_size = 0.0025
	lab_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Below the disc, ABOVE the predicate footer ("R ∈ R ?")
	lab_b.position = Vector3(0.0, -0.80, 0.09)
	_scene_holder.add_child(lab_b)


# Draw an arc around `center` at `radius`, sweeping from `a0` to `a1` (radians).
# Includes an arrowhead at the end of the arc.
func _draw_orbit_arc(center: Vector3, radius: float, a0: float, a1: float, color: Color) -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(color))
	var segs: int = 80
	var pts: Array = []
	for i in range(segs + 1):
		var t: float = float(i) / float(segs)
		var a: float = lerpf(a0, a1, t)
		var p := center + Vector3(cos(a) * radius, sin(a) * radius, 0.08)
		pts.append(p)
	for i in range(segs):
		im.surface_add_vertex(pts[i])
		im.surface_add_vertex(pts[i + 1])
	# Parallel line for thickness
	for i in range(segs):
		var off_a: Vector3 = (pts[i + 1] - pts[i]).normalized()
		var off_p := Vector3(-off_a.y, off_a.x, 0.0) * 0.015
		im.surface_add_vertex(pts[i] + off_p)
		im.surface_add_vertex(pts[i + 1] + off_p)
	im.surface_end()

	# Arrowhead at the end
	var n: int = pts.size()
	var tip: Vector3 = pts[n - 1]
	var approach: Vector3 = (pts[n - 1] - pts[n - 2]).normalized()
	var ahead_size: float = 0.14
	var perp_h := Vector3(-approach.y, approach.x, 0.0)
	var base := tip - approach * ahead_size
	var tri := ImmediateMesh.new()
	tri.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material(color))
	tri.surface_add_vertex(tip)
	tri.surface_add_vertex(base + perp_h * (ahead_size * 0.55))
	tri.surface_add_vertex(base - perp_h * (ahead_size * 0.55))
	tri.surface_end()

	var mi := MeshInstance3D.new()
	mi.mesh = im
	_scene_holder.add_child(mi)
	var mi_tri := MeshInstance3D.new()
	mi_tri.mesh = tri
	_scene_holder.add_child(mi_tri)


# ─── Materials ────────────────────────────────────────────────────────
func _unshaded_material(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 0.4
	mat.disable_receive_shadows = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _unshaded_material_transparent(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = c
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = Color(c.r, c.g, c.b, 1.0)
	mat.emission_energy_multiplier = 0.15
	return mat


# ─── Capture and record ──────────────────────────────────────────────
func _clear_holder() -> void:
	for c in _scene_holder.get_children():
		c.queue_free()


func _capture_and_record(spec: Dictionary) -> void:
	await process_frame
	await process_frame
	await process_frame
	var image := _viewport.get_texture().get_image()
	var id: String = spec["id"]
	var img_rel := "%s.png" % id
	var img_abs := "%s/%s" % [_output_dir, img_rel]
	image.save_png(ProjectSettings.globalize_path(img_abs))

	# JSON sidecar — full cell description
	var example_elements: Array = []
	for ex in spec["examples"]:
		example_elements.append({
			"label": ex.get("label", ""),
			"in_set": ex.get("in_set", false),
			"ambiguous": ex.get("ambiguous", false),
		})
	var cfg := {
		"id": id,
		"set_name": spec["set_name"],
		"predicate": spec["predicate"],
		"english": spec["english"],
		"example_elements": example_elements,
		"is_well_formed": spec["verdict"] == "well_formed",
		"verdict": spec["verdict"],
		"self_reference": spec.get("self_reference", "none"),
		"notes": spec["notes"],
	}
	var cfg_rel := "%s.json" % id
	var cf := FileAccess.open("%s/%s" % [_output_dir, cfg_rel], FileAccess.WRITE)
	cf.store_string(JSON.stringify(cfg, "\t"))
	cf.close()

	_entries.append({
		"id": id,
		"set_name": spec["set_name"],
		"predicate": spec["predicate"],
		"english": spec["english"],
		"verdict": spec["verdict"],
		"is_well_formed": spec["verdict"] == "well_formed",
		"self_reference": spec.get("self_reference", "none"),
		"notes": spec["notes"],
		"image": "/russell-paradox-gallery/%s" % img_rel,
		"config": "/russell-paradox-gallery/%s" % cfg_rel,
	})
	print("  saved: %s  verdict=%s" % [id, spec["verdict"]])
