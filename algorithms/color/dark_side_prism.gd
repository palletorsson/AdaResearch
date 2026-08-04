extends Node3D

# @identity
# essence: Snell's law visualized — white beam enters prism, refracts into 7-color fan by wavelength-dependent angle
# desire: to stand inside the album cover and watch white light split into a rainbow you can almost touch
# critical_parameter: fan_length — controls how far the spectrum spreads, making refraction feel gentle or dramatic
# triggers: none — static sculpture, always present, always splitting
# emerges: the glow/bloom system makes the beams feel volumetric even though they are 1-pixel ImmediateMesh lines
# needs: VR interaction [missing]; adjustable prism angle [missing]; Label3D [missing]
# relationships: contrasts with rainbow (full arc vs linear split); precedes spectrum_forest (spatial color mapping)
# truth: white light is not the absence of color — it is every color compressed into one, waiting for a boundary to reveal the multiplicity

# Pink Floyd "Dark Side of the Moon" Prism Effect in 3D
# Generates a procedural prism and light spectrum using standard geometry

# --- DNA (stage 2, promoted 2026-08-03) ------------------------------------
# The album cover is a picture of a RESULT. Two things were hard-coded into it and both
# are arguments the artifact was making silently.
#
# bands — HOW MANY WAVELENGTHS the beam is treated as. The shipped fan has exactly seven
# lines because Newton named seven, and he named seven to match the diatonic scale. That
# is a cultural fact wearing the costume of a physical one, and the artifact could not
# say anything else. `one` is Newton's second prism (the experimentum crucis): take a
# single colour out of the fan, send it in again, and nothing further happens — the
# monochromatic ray is the thing that will not split. `three` is the screen's model of
# light, red/green/blue, the primaries of a display and not of the sky. `continuum` is
# the physics: sixty-four samples through the same anchors, no bands at all, the seven
# revealed as a naming convention laid over a smooth ramp.
#
# evidence — HOW MUCH OF THE LAW is admitted alongside the rainbow, the family ladder
# used character for character (fibonacci_sequences, koch_curve, pythagorean_triangle_angles
# and twenty-three others). A prism that shows only the fan shows the result and not the
# law: nothing in the shipped frame says WHERE the angle is measured from.
#   result   the shipped sculpture, byte for byte: white in, faint internal segment, fan out.
#   trace    the surface normals drawn dashed at the entry and exit faces, and the two
#            arcs at the entry point — theta_1 between the incoming ray and the normal,
#            theta_2 between the internal ray and the same normal. The pair Snell relates.
#   longhand result + trace + the per-wavelength measurement: each band gets its own arc
#            at the exit face at its own radius, and a rule at the end of the fan with a
#            tick where each band lands. The wavelength-dependence stops being a spray
#            and becomes a set of measured angles.
#   axiom    the normals, the arcs and n1 sin(theta_1) = n2 sin(theta_2) in symbols, with
#            the rainbow withheld. The law before it has anything pretty to show.
@export_enum("one", "three", "seven", "continuum") var bands: String = "seven"
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"

const BANDS_VALUES := ["one", "three", "seven", "continuum"]
const EVIDENCE_VALUES := ["result", "trace", "longhand", "axiom"]

# Newton's seven, exactly the array the shipped artifact drew.
var SPECTRUM: Array[Color] = [
	Color(1, 0, 0),       # Red
	Color(1, 0.5, 0),     # Orange
	Color(1, 1, 0),       # Yellow
	Color(0, 1, 0),       # Green
	Color(0, 0.5, 1),     # Blue
	Color(0.3, 0, 0.5),   # Indigo
	Color(0.6, 0, 1)      # Violet
]

# Beam geometry — these were locals in the shipped build and keep those exact values.
const BEAM_START := Vector3(-4, -0.2, 0)
const BEAM_HIT := Vector3(-0.5, 0.0, 0)
const BEAM_EXIT := Vector3(0.5, 0.0, 0)
const FAN_LENGTH := 5.0
const FAN_TOP_Y := -0.5
const FAN_BOTTOM_Y := -2.0
const PRISM_SIZE := Vector3(2.5, 2.5, 0.5)

var _beam_node: MeshInstance3D
var _beam_mesh: ImmediateMesh
# Law geometry. Built lazily the first time a non-default `evidence` asks for it, so a
# shipped placement has not one extra node in its tree.
var _law_node: MeshInstance3D
var _law_mesh: ImmediateMesh
var _formula_label: Label3D
var _built: bool = false

func _ready() -> void:
	_create_environment()
	_create_prism()
	# Disable old beams, use trace lines
	_create_trace_beams()
	_apply_evidence()
	_create_camera()
	_built = true

func _create_environment() -> void:
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0) # Pure black
	env.glow_enabled = true
	env.glow_intensity = 1.5
	env.glow_strength = 1.3
	env.glow_bloom = 0.5 # High bloom for neon look
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env_node.environment = env
	add_child(env_node)

func _create_camera() -> void:
	var cam = Camera3D.new()
	cam.position = Vector3(0, 0, 4)
	add_child(cam)

func _create_prism() -> void:
	var prism = MeshInstance3D.new()
	var mesh = PrismMesh.new()
	mesh.size = PRISM_SIZE # Flatter depth
	prism.mesh = mesh

	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.1, 0.1, 0.1, 0.2)
	material.metallic = 0.5
	material.roughness = 0.1
	material.refraction_enabled = true
	material.refraction_scale = 0.05

	# Rim for the white outline effect
	material.rim_enabled = true
	material.rim = 0.8
	material.rim_tint = 1.0

	prism.material_override = material

	# PrismMesh default: Triangle points UP Y. Faces Z forward/back.
	# We want it facing camera Z.
	# This seems correct by default.

	add_child(prism)

	# Add subtle edge outlines
	_add_prism_edges(prism, mesh.size)

func _add_prism_edges(parent, size) -> void:
	# Create a simple wireframe triangle using ImmediateMesh for crisp lines
	var im = ImmediateMesh.new()
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = im

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.6, 0.6, 0.6) # Subtle grey outline
	mesh_inst.material_override = mat

	parent.add_child(mesh_inst)

	var top = Vector3(0, size.y/2, size.z/2)
	var br = Vector3(size.x/2, -size.y/2, size.z/2)
	var bl = Vector3(-size.x/2, -size.y/2, size.z/2)

	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	im.surface_add_vertex(bl)
	im.surface_add_vertex(top)
	im.surface_add_vertex(br)
	im.surface_add_vertex(bl) # Close loop
	im.surface_end()


# --- TRACE BEAM SYSTEM (ImmediateMesh Lines) ---

func _create_trace_beams() -> void:
	_beam_node = MeshInstance3D.new()
	_beam_node.name = "Beams"
	_beam_mesh = ImmediateMesh.new()
	_beam_node.mesh = _beam_mesh
	_beam_node.material_override = _line_material()
	add_child(_beam_node)
	_paint_beams()


## The unshaded vertex-colour material the beams have always used.
func _line_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 2.0
	return mat


## The wavelengths this value of `bands` draws.
##
## The "seven" branch returns SPECTRUM itself, in order, which is why the default fan is
## the shipped fan down to the last vertex: the loop below divides by size() - 1 exactly
## as it always did.
func _palette() -> Array[Color]:
	var out: Array[Color] = []
	match bands:
		"one":
			# Newton's second prism: the middle of the seven, sent through alone.
			out.append(SPECTRUM[3])
		"three":
			# The display's primaries, taken from the same seven so the claim is legible
			# as a SUBSET of Newton's and not a different palette.
			out.append(SPECTRUM[0])
			out.append(SPECTRUM[3])
			out.append(SPECTRUM[4])
		"continuum":
			var steps: int = 64
			var last: int = SPECTRUM.size() - 1
			for i in range(steps):
				var t: float = float(i) / float(steps - 1)
				var pos: float = t * float(last)
				var lo: int = int(pos)
				if lo > last - 1:
					lo = last - 1
				var frac: float = pos - float(lo)
				out.append(SPECTRUM[lo].lerp(SPECTRUM[lo + 1], frac))
		_:
			for i in range(SPECTRUM.size()):
				out.append(SPECTRUM[i])
	return out


func _paint_beams() -> void:
	_beam_mesh.clear_surfaces()
	_beam_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var palette: Array[Color] = _palette()

	# 1. Input Beam (White)
	# At bands == "one" the incoming ray is monochromatic too, otherwise the frame would
	# claim white light in and one colour out, which is the opposite of the experiment.
	var head_color := Color(2, 2, 2) # Overbright white
	var inner_color := Color(1, 1, 1, 0.5)
	if bands == "one":
		var c0: Color = palette[0]
		head_color = Color(c0.r * 2.0, c0.g * 2.0, c0.b * 2.0)
		inner_color = Color(c0.r, c0.g, c0.b, 0.5)

	_draw_line(_beam_mesh, BEAM_START, BEAM_HIT, head_color)

	# 2. Internal Beam (White/Faint)
	_draw_line(_beam_mesh, BEAM_HIT, BEAM_EXIT, inner_color)

	# 3. Output Spectrum (Fan) — withheld at evidence == "axiom".
	if evidence != "axiom":
		var n: int = palette.size()
		for i in range(n):
			var t: float = 0.5
			if n > 1:
				t = float(i) / float(n - 1)
			var color: Color = palette[i]
			# Overbright colors for glow
			color.r *= 1.5
			color.g *= 1.5
			color.b *= 1.5

			var y_target = lerp(FAN_TOP_Y, FAN_BOTTOM_Y, t)
			var end_pos = BEAM_EXIT + Vector3(FAN_LENGTH, y_target, 0)

			# Draw from exit point to fan end
			_draw_line(_beam_mesh, BEAM_EXIT, end_pos, color)

	_beam_mesh.surface_end()

func _draw_line(im: ImmediateMesh, from: Vector3, to: Vector3, color: Color) -> void:
	im.surface_set_color(color)
	im.surface_add_vertex(from)
	im.surface_add_vertex(to)


# ---------------------------------------------------------------------------
# Law geometry — everything below is reached only by a non-default `evidence`.
# ---------------------------------------------------------------------------

## The outward normal of the prism's left (entry) face, in the XY plane.
func _entry_normal() -> Vector3:
	var bl := Vector3(-PRISM_SIZE.x / 2.0, -PRISM_SIZE.y / 2.0, 0)
	var top := Vector3(0, PRISM_SIZE.y / 2.0, 0)
	var d: Vector3 = top - bl
	return Vector3(-d.y, d.x, 0).normalized()


## The outward normal of the prism's right (exit) face, in the XY plane.
func _exit_normal() -> Vector3:
	var br := Vector3(PRISM_SIZE.x / 2.0, -PRISM_SIZE.y / 2.0, 0)
	var top := Vector3(0, PRISM_SIZE.y / 2.0, 0)
	var d: Vector3 = top - br
	return Vector3(d.y, -d.x, 0).normalized()


## Which parts of the law are on show for the current value.
##
## The first line is the whole of the default guarantee: at evidence == "result" nothing
## below runs, no law node is ever constructed, and the sculpture is the shipped one.
func _apply_evidence() -> void:
	if evidence == "result" and _law_node == null:
		return
	if _law_node == null:
		_create_law_nodes()

	_law_node.visible = evidence != "result"
	_formula_label.visible = evidence == "axiom"
	if evidence == "result":
		_law_mesh.clear_surfaces()
		return

	var grey := Color(0.75, 0.75, 0.78)
	var faint := Color(0.45, 0.45, 0.5)
	var n_in: Vector3 = _entry_normal()
	var n_out: Vector3 = _exit_normal()
	var incoming: Vector3 = (BEAM_HIT - BEAM_START).normalized()
	var internal: Vector3 = (BEAM_EXIT - BEAM_HIT).normalized()

	_law_mesh.clear_surfaces()
	_law_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# The normals, dashed, drawn through the face in both directions. Without these the
	# frame has no line to measure an angle against, which is the whole complaint.
	_dashed(_law_mesh, BEAM_HIT - n_in * 1.3, BEAM_HIT + n_in * 1.3, grey, 0.12)
	_dashed(_law_mesh, BEAM_EXIT - n_out * 1.3, BEAM_EXIT + n_out * 1.3, grey, 0.12)

	# theta_1 (incoming ray to normal) and theta_2 (internal ray to normal), both at the
	# entry point, at different radii so they read as two angles and not one wedge.
	_arc(_law_mesh, BEAM_HIT, -incoming, n_in, 0.62, grey, 20)
	_arc(_law_mesh, BEAM_HIT, internal, -n_in, 0.40, faint, 20)

	if evidence == "longhand":
		_draw_measurements(_law_mesh, n_out)

	_law_mesh.surface_end()


func _create_law_nodes() -> void:
	_law_node = MeshInstance3D.new()
	_law_node.name = "LawGeometry"
	_law_mesh = ImmediateMesh.new()
	_law_node.mesh = _law_mesh
	_law_node.material_override = _line_material()
	add_child(_law_node)

	_formula_label = Label3D.new()
	_formula_label.name = "SnellFormula"
	_formula_label.text = "n₁ sin θ₁ = n₂ sin θ₂"
	_formula_label.font_size = 48
	_formula_label.pixel_size = 0.003
	_formula_label.position = Vector3(0, PRISM_SIZE.y / 2.0 + 0.6, 0)
	_formula_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_formula_label.modulate = Color(0.9, 0.9, 0.95)
	_formula_label.outline_size = 6
	_formula_label.outline_modulate = Color.BLACK
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formula_label.visible = false
	add_child(_formula_label)


## longhand only: every band measured rather than sprayed.
##
## Each wavelength gets its own arc against the exit normal, at its own radius so the
## fan reads as a stack of angles; and a rule at the far end of the fan carries a tick
## where each band actually lands. The claim "the angle depends on the wavelength" stops
## being something the viewer is asked to take on trust.
func _draw_measurements(im: ImmediateMesh, n_out: Vector3) -> void:
	var palette: Array[Color] = _palette()
	var n: int = palette.size()
	var rule_x: float = BEAM_EXIT.x + FAN_LENGTH + 0.35
	var rule_top := Vector3(rule_x, FAN_TOP_Y + 0.35, 0)
	var rule_bottom := Vector3(rule_x, FAN_BOTTOM_Y - 0.35, 0)
	_draw_line(im, rule_top, rule_bottom, Color(0.7, 0.7, 0.75))

	# A continuum would draw sixty-four overlapping arcs into a smear, so the arcs step
	# through at most eight of them; every band still gets its tick on the rule.
	var arc_stride: int = 1
	if n > 8:
		arc_stride = int(ceil(float(n) / 8.0))

	for i in range(n):
		var t: float = 0.5
		if n > 1:
			t = float(i) / float(n - 1)
		var y_target = lerp(FAN_TOP_Y, FAN_BOTTOM_Y, t)
		var end_pos = BEAM_EXIT + Vector3(FAN_LENGTH, y_target, 0)
		var ray: Vector3 = (end_pos - BEAM_EXIT).normalized()
		var color: Color = palette[i]

		if i % arc_stride == 0:
			var radius: float = 0.5 + 0.08 * float(i % 8)
			_arc(im, BEAM_EXIT, n_out, ray, radius, color, 16)

		var tick_y: float = end_pos.y + (rule_x - end_pos.x) * ray.y / ray.x
		_draw_line(im, Vector3(rule_x - 0.18, tick_y, 0), Vector3(rule_x + 0.18, tick_y, 0), color)


## A polyline arc from direction `a` to direction `b` about `center`.
func _arc(im: ImmediateMesh, center: Vector3, a: Vector3, b: Vector3, radius: float, color: Color, steps: int) -> void:
	var d0: Vector3 = a.normalized()
	var d1: Vector3 = b.normalized()
	var prev: Vector3 = center + d0 * radius
	for i in range(1, steps + 1):
		var t: float = float(i) / float(steps)
		var d: Vector3 = d0.slerp(d1, t).normalized()
		var p: Vector3 = center + d * radius
		_draw_line(im, prev, p, color)
		prev = p


## A dashed segment. Godot has no line stipple, so the dashes are real segments.
func _dashed(im: ImmediateMesh, from: Vector3, to: Vector3, color: Color, dash: float) -> void:
	var seg: Vector3 = to - from
	var total: float = seg.length()
	if total <= 0.0001 or dash <= 0.0:
		return
	var dir: Vector3 = seg / total
	var pos: float = 0.0
	while pos < total:
		var e: float = minf(pos + dash, total)
		_draw_line(im, from + dir * pos, from + dir * e, color)
		pos = e + dash


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Grid system integration.
##
## Guarded twice over: the key has to be present AND the value has to be one the code can
## actually build AND different from the current one, so a map token carrying unrelated
## layout keys repaints nothing. _built stays false until _ready has run once, which keeps
## a config applied early from painting into a mesh that does not exist yet — the exports
## alone are enough then, and _ready will build with them.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false

	if config_data.has("bands"):
		var want_bands: String = str(config_data["bands"]).strip_edges().to_lower()
		if want_bands != bands and BANDS_VALUES.has(want_bands):
			bands = want_bands
			changed = true

	if config_data.has("evidence"):
		var want_evidence: String = str(config_data["evidence"]).strip_edges().to_lower()
		if want_evidence != evidence and EVIDENCE_VALUES.has(want_evidence):
			evidence = want_evidence
			changed = true

	if not changed or not _built:
		return

	_paint_beams()
	_apply_evidence()
