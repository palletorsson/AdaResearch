## One-off sweep capture for the Wolfram-CA-rules DNA gallery.
##
## Pedagogical claim — for a 1D, two-state, three-neighbour cellular automaton,
## there are exactly 2^8 = 256 possible local rules. The rule number IS the DNA
## (8 bits, one per local-neighbourhood pattern). The substrate is the same
## across all 256: a tape of cells, evolved one step at a time. Same starting
## condition (single black cell at position 128 in a 256-wide tape) renders
## eight very different "physics" depending on which rule is loaded.
##
## Wolfram's four classes (A New Kind of Science, 2002) map onto QFEP phases:
##   Class 1 (decays to constant)        → F_order      → blue   #3A7BFF
##   Class 2 (periodic / fractal)        → oscillation  → green  #7DFFA8
##   Class 3 (chaotic)                   → E_entropy    → orange #F4A261
##   Class 4 (complex / edge of chaos)   → lambda_edge  → red    #E63946
##
## The 8 rules chosen:
##   Rule   0  (class 1, F_order)      — decays to all 0
##   Rule 255  (class 1, F_order)      — decays to all 1
##   Rule  90  (class 2, oscillation)  — Sierpinski triangle
##   Rule 184  (class 2, oscillation)  — traffic flow
##   Rule  30  (class 3, E_entropy)    — pseudo-random (cross: shannon)
##   Rule 110  (class 4, lambda_edge)  — Turing-complete (cross: halting)
##   Rule  54  (class 4, lambda_edge)  — gliders + collisions
##   Rule 126  (class 3, E_entropy)    — symmetric chaos
##
## Each cell renders:
##   - A 256-wide × 256-step textured quad. Row 0 = initial state (single black
##     cell in the middle). Row 255 = step 255. Time flows downward.
##   - A class-color frame around the quad (blue/green/orange/red).
##   - Big label: "Rule 30" etc.
##   - Subtitle: "class 3 / E_entropy / pseudo-random"
##   - A small cross-reference badge for the bridging rules.
##
## Wolfram 1D rule logic:
##   For rule R (0–255), the next state of a cell with left=L, center=C,
##   right=R_neigh is bit (L*4 + C*2 + R_neigh) of R.
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_ca_rules_gallery.gd \
##     -- --out=user://ca_rules_gallery
##
## Output: <out>/{id}.png + {id}.json + manifest.json
extends SceneTree

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.06, 0.07, 0.10)

# Camera framing: orthographic, looking head-on at the XY plane.
# ORTHO_SIZE = 4.0 means the visible Y range is [-2, +2].
const ORTHO_SIZE: float = 4.0

# CA dimensions
const TAPE_WIDTH: int = 256
const TIME_STEPS: int = 256

# The CA-image quad placement (centered, with room above for label, below for subtitle).
const QUAD_HALF: float = 1.40         # quad spans [-1.40, +1.40] in X and Y around its center
const QUAD_CENTER_Y: float = -0.15

# Class → QFEP color (timeline PHASE_COLORS).
const COLOR_CLASS_1: Color = Color(0.227, 0.482, 1.0)    # #3A7BFF F_order
const COLOR_CLASS_2: Color = Color(0.490, 1.0, 0.659)    # #7DFFA8 oscillation
const COLOR_CLASS_3: Color = Color(0.957, 0.635, 0.380)  # #F4A261 E_entropy
const COLOR_CLASS_4: Color = Color(0.902, 0.224, 0.275)  # #E63946 lambda_edge

# Bit-color palette inside the CA image.
const ALIVE_COLOR: Color = Color(0.05, 0.05, 0.07)       # near-black for 1
const DEAD_COLOR: Color = Color(0.97, 0.97, 0.98)        # near-white for 0

const TEXT_BRIGHT: Color = Color(0.96, 0.96, 0.98)
const TEXT_DIM: Color = Color(0.72, 0.74, 0.82)
const PANEL_BG: Color = Color(0.10, 0.12, 0.17, 0.85)


var _output_dir: String = "user://ca_rules_gallery"
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

	# Cosmetic light — unshaded materials don't strictly need it, but the env
	# pipeline likes having something.
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-45, 0, 0)
	key_light.light_energy = 0.6
	_viewport.add_child(key_light)

	# Orthographic camera, head-on at the XY plane.
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

	# ── Sweep over the 8 rules ──────────────────────────────────────
	var sweep: Array = _build_sweep()
	for spec in sweep:
		var evolution: Array = _evolve_rule(spec["rule"])
		var stats: Dictionary = _compute_stats(evolution)
		var ca_texture: ImageTexture = _make_ca_texture(evolution)
		_build_scene(spec, ca_texture)
		await create_timer(0.05).timeout
		await _capture_and_record(spec, stats)
		_clear_holder()
		await create_timer(0.02).timeout

	# ── Manifest ────────────────────────────────────────────────────
	var manifest := {
		"version": 1,
		"description": "Eight Wolfram 1D cellular-automata rules from the 256 elementary rules, each run for %d steps from a single black cell at position %d on a %d-wide tape. The rule number IS the DNA; the output is the substrate. Wolfram's four classes map onto QFEP phases: Class 1 (decays to constant) = F_order, Class 2 (periodic / fractal) = oscillation, Class 3 (chaotic) = E_entropy, Class 4 (complex structures persist) = lambda_edge. Rule 90 IS the Sierpinski triangle; Rule 30 IS pseudo-randomness from order (sister to shannon-bound-gallery); Rule 110 IS Turing-complete (sister to halting-bench-gallery)." % [TIME_STEPS, TAPE_WIDTH / 2, TAPE_WIDTH],
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"camera": {"projection": "orthogonal", "size": ORTHO_SIZE},
		"tape_width": TAPE_WIDTH,
		"time_steps": TIME_STEPS,
		"initial_condition": "single 1 at position %d, all others 0" % (TAPE_WIDTH / 2),
		"phase_colors": {
			"F_order": "#3A7BFF",
			"oscillation": "#7DFFA8",
			"E_entropy": "#F4A261",
			"lambda_edge": "#E63946",
		},
		"references": {
			"wolfram_2002": "Stephen Wolfram, A New Kind of Science (Wolfram Media, 2002). The elementary CA classification, the four classes, and the rules 30, 90, 110 case studies.",
			"cook_2004": "Matthew Cook, Universality in Elementary Cellular Automata, Complex Systems 15 (2004), 1-40. Proof that Rule 110 is Turing-complete.",
		},
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries saved to %s" % [_entries.size(), _output_dir])
	quit(0)


# ─── Sweep specification ─────────────────────────────────────────────
# Sorted by class (1 → 4) so the eye walks toward lambda_edge.
func _build_sweep() -> Array:
	var sweep: Array = []
	sweep.append({
		"id": "1_rule000_f_order",   "rule": 0,   "wolfram_class": 1,
		"qfep_phase": "F_order",
		"phase_color_hex": "#3A7BFF",
		"subtitle": "class 1 / F_order / vacuum",
		"bridges_to": [],
		"notes": "Rule 0: every neighbourhood maps to 0. The single seed dies on step 1 and the tape is constant zero forever. F_order in its purest form — the substrate that swallows every state into silence.",
	})
	sweep.append({
		"id": "2_rule255_f_order",   "rule": 255, "wolfram_class": 1,
		"qfep_phase": "F_order",
		"phase_color_hex": "#3A7BFF",
		"subtitle": "class 1 / F_order / saturated",
		"bridges_to": [],
		"notes": "Rule 255: every neighbourhood maps to 1. The seed fills the entire tape on step 1 and stays full. The inverse of Rule 0 — same F_order phase, opposite constant. Order can be a black sea as easily as a white one.",
	})
	sweep.append({
		"id": "3_rule090_oscillation", "rule": 90, "wolfram_class": 2,
		"qfep_phase": "oscillation",
		"phase_color_hex": "#7DFFA8",
		"subtitle": "class 2 / oscillation / Sierpinski",
		"bridges_to": ["fractal-gallery"],
		"notes": "Rule 90: next = left XOR right. From a single seed this generates the Sierpinski triangle — exact, infinite, self-similar. The CA IS the fractal; no separate renderer needed. Class 2 because the long-run behaviour is periodic on any finite tape, but the structure is endlessly nested.",
	})
	sweep.append({
		"id": "4_rule184_oscillation", "rule": 184, "wolfram_class": 2,
		"qfep_phase": "oscillation",
		"phase_color_hex": "#7DFFA8",
		"subtitle": "class 2 / oscillation / traffic",
		"bridges_to": [],
		"notes": "Rule 184: the traffic rule. Each 1 (a 'car') moves right by one cell per step if the next cell is empty, else it waits. The single-seed start makes the diagonal car-trail visible — a stream moving steadily through space. Used as a minimal model of single-lane traffic flow.",
	})
	sweep.append({
		"id": "5_rule030_e_entropy",  "rule": 30, "wolfram_class": 3,
		"qfep_phase": "E_entropy",
		"phase_color_hex": "#F4A261",
		"subtitle": "class 3 / E_entropy / pseudo-random",
		"bridges_to": ["shannon-bound-gallery"],
		"notes": "Rule 30: deterministic but apparently random. Wolfram used this rule's center column as a pseudo-random number generator in Mathematica. The simplest possible local rule produces a stream whose entropy is indistinguishable from a fair coin — F_order rules birthing E_entropy bits. The sibling claim of shannon-bound-gallery: H≈1.0 from a deterministic source.",
	})
	sweep.append({
		"id": "6_rule110_lambda_edge", "rule": 110, "wolfram_class": 4,
		"qfep_phase": "lambda_edge",
		"phase_color_hex": "#E63946",
		"subtitle": "class 4 / lambda_edge / Turing-complete",
		"bridges_to": ["halting-bench-gallery"],
		"notes": "Rule 110: proven Turing-complete by Matthew Cook in 2004 — the simplest known universal computer. Gliders of different speeds collide and interact; the right initial condition can encode any algorithm. The lambda_edge in its strongest form: complex structures persist forever, and what they compute is undecidable in general. Sibling to halting-bench-gallery's universality cell.",
	})
	sweep.append({
		"id": "7_rule054_lambda_edge", "rule": 54, "wolfram_class": 4,
		"qfep_phase": "lambda_edge",
		"phase_color_hex": "#E63946",
		"subtitle": "class 4 / lambda_edge / gliders",
		"bridges_to": [],
		"notes": "Rule 54: another class-4 rule. Persistent gliders travel left and right and collide into bounded structures. Less famous than Rule 110 but in the same neighbourhood — complex persistent particles, not chaos, not order. Often paired with 110 in the literature as evidence that lambda_edge isn't a singular rule but a phase.",
	})
	sweep.append({
		"id": "8_rule126_e_entropy",  "rule": 126, "wolfram_class": 3,
		"qfep_phase": "E_entropy",
		"phase_color_hex": "#F4A261",
		"subtitle": "class 3 / E_entropy / symmetric chaos",
		"bridges_to": [],
		"notes": "Rule 126: visually symmetric chaos. Like Rule 30, deterministic noise from a single seed; unlike Rule 30, left-right reflection is preserved. The cone of chaos is bilateral, but the pixel-level statistics are still pseudo-random. E_entropy with a residual symmetry.",
	})
	return sweep


# ─── Wolfram 1D rule evolution ───────────────────────────────────────
# Returns an Array of PackedByteArray, one per time step.
# Tape uses wrap-around boundaries (left of cell 0 is cell 255, right of cell
# 255 is cell 0). Wrap is the convention; without it the seed never makes it
# to the edges in 256 steps anyway, but wrap is cleaner.
func _evolve_rule(rule: int) -> Array:
	var rows: Array = []
	var cur: PackedByteArray = PackedByteArray()
	cur.resize(TAPE_WIDTH)
	# Initial: single 1 in the middle.
	for i in range(TAPE_WIDTH):
		cur[i] = 0
	cur[TAPE_WIDTH / 2] = 1
	rows.append(cur.duplicate())

	for _step in range(TIME_STEPS - 1):
		var nxt: PackedByteArray = PackedByteArray()
		nxt.resize(TAPE_WIDTH)
		for i in range(TAPE_WIDTH):
			var l: int = cur[(i - 1 + TAPE_WIDTH) % TAPE_WIDTH]
			var c: int = cur[i]
			var r: int = cur[(i + 1) % TAPE_WIDTH]
			var idx: int = (l << 2) | (c << 1) | r
			nxt[i] = (rule >> idx) & 1
		rows.append(nxt.duplicate())
		cur = nxt

	return rows


# Stats — count alives per row, total alives, plus the center-column bit
# string (used by Rule 30 as a PRNG demonstration).
func _compute_stats(rows: Array) -> Dictionary:
	var total_alive: int = 0
	var per_row: Array = []
	var center_col: String = ""
	var final_alive: int = 0
	for r in range(rows.size()):
		var row: PackedByteArray = rows[r]
		var n_alive: int = 0
		for b in row:
			if b == 1:
				n_alive += 1
		total_alive += n_alive
		per_row.append(n_alive)
		center_col += "1" if row[TAPE_WIDTH / 2] == 1 else "0"
		if r == rows.size() - 1:
			final_alive = n_alive
	return {
		"total_alive": total_alive,
		"per_row_alive": per_row,
		"center_column_bits": center_col,
		"final_row_alive": final_alive,
		"fill_fraction": float(total_alive) / float(TAPE_WIDTH * TIME_STEPS),
	}


# ─── Build the CA texture (one pixel per cell-step) ──────────────────
func _make_ca_texture(rows: Array) -> ImageTexture:
	var img := Image.create(TAPE_WIDTH, TIME_STEPS, false, Image.FORMAT_RGB8)
	for y in range(TIME_STEPS):
		var row: PackedByteArray = rows[y]
		for x in range(TAPE_WIDTH):
			var c: Color = ALIVE_COLOR if row[x] == 1 else DEAD_COLOR
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


# ─── Scene construction ──────────────────────────────────────────────
func _build_scene(spec: Dictionary, ca_texture: ImageTexture) -> void:
	var class_color: Color = _class_color(spec["wolfram_class"])
	_add_ca_quad(ca_texture, class_color)
	_add_title(spec, class_color)
	_add_subtitle(spec, class_color)
	_add_bridges(spec)


func _class_color(c: int) -> Color:
	match c:
		1: return COLOR_CLASS_1
		2: return COLOR_CLASS_2
		3: return COLOR_CLASS_3
		4: return COLOR_CLASS_4
	return COLOR_CLASS_1


# The 256×256 CA evolution as a textured quad with a thick class-color frame.
func _add_ca_quad(tex: ImageTexture, class_color: Color) -> void:
	var x_lo: float = -QUAD_HALF
	var x_hi: float = QUAD_HALF
	var y_lo: float = QUAD_CENTER_Y - QUAD_HALF
	var y_hi: float = QUAD_CENTER_Y + QUAD_HALF

	# Outer frame slab — solid colored frame BEHIND the quad.
	var frame_pad: float = 0.06
	var im_frame := ImmediateMesh.new()
	im_frame.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material(class_color))
	_quad(im_frame,
		Vector3(x_lo - frame_pad, y_lo - frame_pad, 0.004),
		Vector3(x_hi + frame_pad, y_lo - frame_pad, 0.004),
		Vector3(x_hi + frame_pad, y_hi + frame_pad, 0.004),
		Vector3(x_lo - frame_pad, y_hi + frame_pad, 0.004))
	im_frame.surface_end()
	# Subtle black inner border between frame and quad.
	im_frame.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material(Color(0.03, 0.04, 0.06, 1.0)))
	var inner_pad: float = 0.014
	_quad(im_frame,
		Vector3(x_lo - inner_pad, y_lo - inner_pad, 0.006),
		Vector3(x_hi + inner_pad, y_lo - inner_pad, 0.006),
		Vector3(x_hi + inner_pad, y_hi + inner_pad, 0.006),
		Vector3(x_lo - inner_pad, y_hi + inner_pad, 0.006))
	im_frame.surface_end()
	var mi_frame := MeshInstance3D.new()
	mi_frame.mesh = im_frame
	mi_frame.name = "Frame"
	_scene_holder.add_child(mi_frame)

	# Textured quad (the CA evolution itself).
	var mesh := QuadMesh.new()
	mesh.size = Vector2(x_hi - x_lo, y_hi - y_lo)
	var mi_quad := MeshInstance3D.new()
	mi_quad.mesh = mesh
	mi_quad.position = Vector3((x_lo + x_hi) * 0.5, (y_lo + y_hi) * 0.5, 0.008)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 1, 1, 1)
	mat.albedo_texture = tex
	# Nearest-neighbour sampling so the cells stay crisp at any zoom.
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1, 1)
	mat.emission_energy_multiplier = 0.25
	mi_quad.material_override = mat
	mi_quad.name = "CAQuad"
	_scene_holder.add_child(mi_quad)


# Big label: "Rule 30"
func _add_title(spec: Dictionary, class_color: Color) -> void:
	var lab := Label3D.new()
	lab.text = "Rule %d" % spec["rule"]
	lab.font_size = 96
	lab.outline_size = 14
	lab.modulate = TEXT_BRIGHT
	lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.95)
	lab.shaded = false
	lab.no_depth_test = true
	lab.pixel_size = 0.0025
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lab.position = Vector3(-1.85, 1.78, 0.02)
	_scene_holder.add_child(lab)

	# A class-colored dot next to the title to anchor the framing color.
	var dot_im := ImmediateMesh.new()
	dot_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material(class_color))
	var dot_r: float = 0.08
	var dot_z: float = 0.018
	var dot_center := Vector3(1.70, 1.78, dot_z)
	var n_sides: int = 24
	for i in range(n_sides):
		var a0: float = float(i) * TAU / float(n_sides)
		var a1: float = float(i + 1) * TAU / float(n_sides)
		var v0 := dot_center + Vector3(cos(a0) * dot_r, sin(a0) * dot_r, 0.0)
		var v1 := dot_center + Vector3(cos(a1) * dot_r, sin(a1) * dot_r, 0.0)
		dot_im.surface_add_vertex(dot_center)
		dot_im.surface_add_vertex(v0)
		dot_im.surface_add_vertex(v1)
	dot_im.surface_end()
	var mi_dot := MeshInstance3D.new()
	mi_dot.mesh = dot_im
	mi_dot.name = "ClassDot"
	_scene_holder.add_child(mi_dot)


# Subtitle: "class 3 / E_entropy / pseudo-random"
func _add_subtitle(spec: Dictionary, class_color: Color) -> void:
	var lab := Label3D.new()
	lab.text = spec["subtitle"]
	lab.font_size = 38
	lab.outline_size = 8
	lab.modulate = class_color
	lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.95)
	lab.shaded = false
	lab.no_depth_test = true
	lab.pixel_size = 0.0025
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lab.position = Vector3(-1.85, 1.58, 0.02)
	_scene_holder.add_child(lab)

	# Tiny formula reminder under it.
	var formula := Label3D.new()
	formula.text = "binary[%s] · 256 steps from a single seed" % _rule_binary(spec["rule"])
	formula.font_size = 22
	formula.outline_size = 5
	formula.modulate = TEXT_DIM
	formula.outline_modulate = Color(0.02, 0.03, 0.05, 0.95)
	formula.shaded = false
	formula.no_depth_test = true
	formula.pixel_size = 0.0025
	formula.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	formula.position = Vector3(-1.85, 1.43, 0.02)
	_scene_holder.add_child(formula)


# A small cross-reference badge for the bridging rules.
func _add_bridges(spec: Dictionary) -> void:
	var bridges: Array = spec["bridges_to"]
	if bridges.is_empty():
		return
	var y: float = -1.78
	for b in bridges:
		var lab := Label3D.new()
		lab.text = "→ %s" % b.replace("-gallery", "")
		lab.font_size = 28
		lab.outline_size = 6
		lab.modulate = Color(0.96, 0.86, 0.34)
		lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.95)
		lab.shaded = false
		lab.no_depth_test = true
		lab.pixel_size = 0.0025
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lab.position = Vector3(-1.85, y, 0.02)
		_scene_holder.add_child(lab)
		y -= 0.16


func _rule_binary(rule: int) -> String:
	# Format as 8-bit binary, MSB first.
	var s: String = ""
	for i in range(8):
		var bit: int = (rule >> (7 - i)) & 1
		s += "1" if bit == 1 else "0"
	return s


# ─── Materials ───────────────────────────────────────────────────────
func _unshaded_material(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 0.4
	mat.disable_receive_shadows = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if c.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat


func _quad(im: ImmediateMesh, bl: Vector3, br: Vector3, tr: Vector3, tl: Vector3) -> void:
	im.surface_add_vertex(bl)
	im.surface_add_vertex(br)
	im.surface_add_vertex(tr)
	im.surface_add_vertex(bl)
	im.surface_add_vertex(tr)
	im.surface_add_vertex(tl)


# ─── Capture and record ──────────────────────────────────────────────
func _clear_holder() -> void:
	for c in _scene_holder.get_children():
		c.queue_free()


func _capture_and_record(spec: Dictionary, stats: Dictionary) -> void:
	# Yield a few frames so the viewport definitely renders before we sample.
	await process_frame
	await process_frame
	await process_frame
	var image := _viewport.get_texture().get_image()
	var img_rel := "%s.png" % spec["id"]
	var img_abs := "%s/%s" % [_output_dir, img_rel]
	image.save_png(ProjectSettings.globalize_path(img_abs))

	# JSON sidecar — full per-cell metadata.
	var cfg := {
		"id": spec["id"],
		"rule": spec["rule"],
		"rule_binary": _rule_binary(spec["rule"]),
		"wolfram_class": spec["wolfram_class"],
		"qfep_phase": spec["qfep_phase"],
		"phase_color": spec["phase_color_hex"],
		"subtitle": spec["subtitle"],
		"bridges_to": spec["bridges_to"],
		"tape_width": TAPE_WIDTH,
		"time_steps": TIME_STEPS,
		"initial_condition": "single 1 at position %d" % (TAPE_WIDTH / 2),
		"total_alive": stats["total_alive"],
		"final_row_alive": stats["final_row_alive"],
		"fill_fraction": stats["fill_fraction"],
		"center_column_bits": stats["center_column_bits"],
		"notes": spec["notes"],
	}
	var cfg_rel := "%s.json" % spec["id"]
	var cf := FileAccess.open("%s/%s" % [_output_dir, cfg_rel], FileAccess.WRITE)
	cf.store_string(JSON.stringify(cfg, "\t"))
	cf.close()

	_entries.append({
		"id": spec["id"],
		"rule": spec["rule"],
		"wolfram_class": spec["wolfram_class"],
		"qfep_phase": spec["qfep_phase"],
		"phase_color": spec["phase_color_hex"],
		"subtitle": spec["subtitle"],
		"bridges_to": spec["bridges_to"],
		"total_alive": stats["total_alive"],
		"fill_fraction": stats["fill_fraction"],
		"notes": spec["notes"],
		"image": "/ca-rules-gallery/%s" % img_rel,
		"config": "/ca-rules-gallery/%s" % cfg_rel,
	})
	print("  saved: %s  rule=%d  class=%d  phase=%s  fill=%.3f" % [
		spec["id"], spec["rule"], spec["wolfram_class"],
		spec["qfep_phase"], stats["fill_fraction"],
	])
