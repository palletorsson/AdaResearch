@tool
extends Node3D

# Lissajous Curve Generator
# Parametric curves formed by combining perpendicular harmonic motions
# X = A * sin(a*t + δ), Y = B * sin(b*t), Z = C * sin(c*t)


# @identity
# essence: (x,y,z) = (A_x*sin(a*t+delta), A_y*sin(b*t), A_z*sin(c*t)) — parametric Lissajous
# desire: Watch a glowing particle trace beautiful closed curves defined by frequency ratios
# critical_parameter: freq_ratio_x / freq_ratio_y — rational ratios close the curve, irrational ratios fill space
# triggers: time drives the parametric position; preset selection switches between classic ratio combinations
# emerges: complex geometric figures from the interference of perpendicular oscillations
# needs: VR frequency ratio control [missing], 3D rotation [has], a curve legible across a room [has: tube], the ratio said aloud [has: ratio line]
# relationships: depends on ImmediateMesh trail rendering; contrasts with SphericalHarmonics (planar vs spherical oscillation); unlocks frequency ratio visualization
# truth: The ratio of two frequencies determines whether a curve closes or wanders forever.

# --- DNA (stage 2, promoted 2026-08-03) ---------------------------------------
# Two axes, both readable in a single still.
#
#   ratio     Which figure the interference produces. This artifact's own truth
#             line says the ratio decides whether the curve CLOSES or WANDERS,
#             and the whole curve is generated as standing geometry (the full
#             parameter sweep, every frame), not traced out over time — so the
#             argument is already in the picture. SphericalHarmonics had to
#             decline its orbit-ratio axis because a spherical Lissajous is
#             drawn by a moving point; here there is nothing to wait for.
#             1_phi_0 is the one value that does NOT close: an irrational ratio
#             traced over six turns, densening instead of repeating. It carries
#             a longer span and a matching sample count of its own, because
#             non-closure is invisible inside a single period.
#             The presets already in set_preset() bundled a characteristic
#             phase with each ratio (a 1:1 at delta=0 is a straight diagonal,
#             at delta=PI/2 a circle); the axis keeps that pairing verbatim.
#
#   evidence  How much of the construction is shown — the family word, used
#             here in the family's ladder: result (the closed figure alone) <
#             trace (+ the running tracer, the shipped build) < longhand (+ the
#             two generating oscillations drawn beside it, the oscilloscope
#             picture) < axiom (+ the parametric definition in words).
#
# Default is ratio=3_2_1, evidence=trace, which is the .tscn byte for byte.
# ------------------------------------------------------------------------------

## Which frequency ratio the two (three) oscillations stand in. The figure IS
## the ratio: 1_1_0 a circle, 2_1_0 a figure eight, 5_4_0 a lattice, 1_phi_0 an
## irrational ratio that never closes.
@export_enum("3_2_1", "1_1_0", "2_1_0", "3_2_0", "5_4_0", "1_phi_0") var ratio: String = "3_2_1"

## How much of the working is on show. See the DNA note above.
@export_enum("trace", "result", "longhand", "axiom") var evidence: String = "trace"

@export_group("Frequency Ratios")
@export var freq_ratio_x: float = 3.0  # a in the equation
@export var freq_ratio_y: float = 2.0  # b in the equation
@export var freq_ratio_z: float = 1.0  # c in the equation (for 3D extension)

@export_group("Amplitudes")
@export var amplitude_x: float = 1.0  # A
@export var amplitude_y: float = 1.0  # B
@export var amplitude_z: float = 0.5  # C

@export_group("Phase")
@export var phase_shift: float = 0.0  # δ (delta) in radians
@export var animate_phase: bool = true
@export var phase_speed: float = 0.5

@export_group("Visualization")
@export var num_points: int = 500
@export var line_width: float = 0.02
@export var trail_length: int = 200
@export var show_particle: bool = true
@export var particle_size: float = 0.08
@export var rainbow_gradient: bool = true
## Draw the curve as a glowing tube line_width thick. A LINE_STRIP is one pixel at any line_width, so from two metres
## the figure - the whole argument - was a hairline (2026-11-09).
@export var tube: bool = true
@export_range(3, 12) var tube_sides: int = 6
@export_range(0.0, 4.0, 0.1) var glow: float = 0.7
## A line under the figure that says what the ratio does: rational closes, irrational never does.
@export var ratio_label: bool = true

@export_group("Animation")
@export var animation_speed: float = 1.0
@export var auto_rotate: bool = false
@export var rotation_speed: float = 0.2

const PHI: float = 1.6180339887498949

# The allow-lists apply_grid_config validates a map token against. They must
# stay identical to the @export_enum lists above.
const RATIOS: Array[String] = ["3_2_1", "1_1_0", "2_1_0", "3_2_0", "5_4_0", "1_phi_0"]
const EVIDENCE: Array[String] = ["trace", "result", "longhand", "axiom"]

var time: float = 0.0
var curve_points: PackedVector3Array = []
var trail_points: Array[Vector3] = []

# Mesh for drawing the curve
var curve_mesh: ImmediateMesh
var curve_instance: MeshInstance3D
var particle_instance: MeshInstance3D

# Set by _apply_ratio(). Both are 1.0 for every rational ratio, which is what
# this file has always done — one parameter period at num_points samples.
var _turns: float = 1.0
var _sample_scale: float = 1.0
var _last_ratio: String = ""
var _last_evidence: String = ""
var _built: bool = false
var _tube_instance: MeshInstance3D
var _tube_indices: PackedInt32Array = PackedInt32Array()
var _tube_key: Vector2i = Vector2i(-1, -1)   # (points, sides) the cached index buffer was built for
var _ratio_plate: Label3D

func _ready() -> void:
	_apply_ratio()
	_last_evidence = evidence
	_setup_visualization()
	_generate_full_curve()
	_built = true

func _process(delta: float) -> void:
	# Only when the word actually moved — an inspector edit or a runtime swap.
	# At map load and in the sweep both were already resolved in _ready, so
	# neither branch fires and nothing is rebuilt.
	if ratio != _last_ratio:
		_apply_ratio()
		if evidence == "axiom":
			_setup_visualization()
		if _ratio_plate != null:
			_ratio_plate.text = _ratio_text()
	if evidence != _last_evidence:
		_last_evidence = evidence
		_setup_visualization()

	if Engine.is_editor_hint():
		_generate_full_curve()
		_update_curve_mesh()
		return

	time += delta * animation_speed

	# Animate phase shift
	if animate_phase:
		phase_shift += delta * phase_speed

	# Generate and update curve
	_generate_full_curve()
	_update_curve_mesh()

	# Update particle position
	if _wants_particle():
		_update_particle()

	# Auto-rotate for better viewing
	if auto_rotate:
		rotation.y += delta * rotation_speed

func _setup_visualization() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()
	particle_instance = null

	# Create immediate mesh for curve
	curve_mesh = ImmediateMesh.new()
	curve_instance = MeshInstance3D.new()
	curve_instance.name = "CurveMesh"
	curve_instance.mesh = curve_mesh

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.5
	mat.metallic = 0.0
	mat.roughness = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	curve_instance.material_override = mat

	add_child(curve_instance)

	# The tube: its own mesh, lit so it reads as a body in the room, glowing in its own colour
	_tube_instance = null
	_tube_key = Vector2i(-1, -1)
	if tube:
		_tube_instance = MeshInstance3D.new()
		_tube_instance.name = "CurveTube"
		var tube_mat := ShaderMaterial.new()
		tube_mat.shader = _tube_shader()
		tube_mat.set_shader_parameter("glow", glow)
		_tube_instance.material_override = tube_mat
		add_child(_tube_instance)

	_ratio_plate = null
	if ratio_label and evidence != "axiom":
		_ratio_plate = Label3D.new()
		_ratio_plate.name = "RatioLine"
		_ratio_plate.font_size = 44
		_ratio_plate.pixel_size = 0.004
		_ratio_plate.outline_size = 8
		_ratio_plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_ratio_plate.modulate = Color(0.92, 0.95, 1.0)
		_ratio_plate.outline_modulate = Color(0.05, 0.06, 0.1)
		_ratio_plate.position = Vector3(0.0, amplitude_y + 0.42, 0.0)   # above: under the figure it sat at the visitor's feet
		_ratio_plate.text = _ratio_text()
		add_child(_ratio_plate)

	# Create particle
	if _wants_particle():
		particle_instance = MeshInstance3D.new()
		particle_instance.name = "Particle"
		var sphere = SphereMesh.new()
		sphere.radius = particle_size
		sphere.height = particle_size * 2.0
		particle_instance.mesh = sphere

		var particle_mat = StandardMaterial3D.new()
		particle_mat.albedo_color = Color(1.0, 1.0, 0.0)
		particle_mat.emission_enabled = true
		particle_mat.emission = Color(1.0, 1.0, 0.0)
		particle_mat.emission_energy_multiplier = 2.0
		particle_mat.metallic = 0.0
		particle_mat.roughness = 1.0
		particle_instance.material_override = particle_mat

		add_child(particle_instance)

	# evidence = axiom: the definition itself, written out beside the figure.
	if evidence == "axiom":
		var plate := Label3D.new()
		plate.name = "Axiom"
		plate.text = ("x = Ax * sin(a*t + d)\ny = Ay * sin(b*t)\nz = Az * sin(c*t)\n"
			+ "a : b : c = %s : %s : %s" % [_fmt(freq_ratio_x), _fmt(freq_ratio_y), _fmt(freq_ratio_z)])
		plate.font_size = 48
		plate.pixel_size = 0.0035
		plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		plate.modulate = Color(0.82, 0.88, 1.0)
		plate.position = Vector3(0.0, amplitude_y + 0.8, 0.0)
		add_child(plate)

func _sample_count() -> int:
	# num_points for every rational ratio — the shipped number. Only the
	# irrational value asks for more, because it draws six turns, not one.
	var n: int = int(round(float(num_points) * _sample_scale))
	return maxi(n, 2)

func _generate_full_curve() -> void:
	curve_points.clear()

	var steps: int = _sample_count()
	for i in range(steps + 1):
		var t: float = float(i) / float(steps) * TAU * _turns
		var point: Vector3 = _calculate_point(t)
		curve_points.append(point)

func _calculate_point(t: float) -> Vector3:
	"""Calculate Lissajous curve point at parameter t"""
	return Vector3(
		amplitude_x * sin(freq_ratio_x * t + phase_shift),
		amplitude_y * sin(freq_ratio_y * t),
		amplitude_z * sin(freq_ratio_z * t)
	)

func _update_curve_mesh() -> void:
	if not curve_mesh:
		return

	curve_mesh.clear_surfaces()

	if curve_points.size() < 2:
		return

	if tube and _tube_instance != null:
		_build_tube()
		if evidence == "longhand":
			_add_component_strip(true)
			_add_component_strip(false)
		return

	curve_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	for i in range(curve_points.size()):
		var point = curve_points[i]

		# Calculate color
		var color: Color
		if rainbow_gradient:
			var hue = float(i) / float(curve_points.size())
			color = Color.from_hsv(hue, 0.8, 1.0)
		else:
			color = Color(0.3, 0.8, 1.0)

		curve_mesh.surface_set_color(color)
		curve_mesh.surface_add_vertex(point)

	curve_mesh.surface_end()

	# evidence = longhand: the two oscillations the figure is made of, drawn
	# the way a scope shows them — x(t) below with time running down, y(t) to
	# the left with time running out. Same t and same phase as the figure, so
	# they stay in step with it as the phase drifts.
	if evidence == "longhand":
		_add_component_strip(true)
		_add_component_strip(false)

## The curve as a tube: a ring of tube_sides vertices round each sample, carried along the curve without twisting
## (each ring's normal is the last one with its along-curve part taken out). The index buffer depends only on the
## sample and side counts, so it is built once and reused while the phase drifts.
func _build_tube() -> void:
	var n: int = curve_points.size()
	var s: int = tube_sides
	var r: float = maxf(line_width, 0.004)
	var verts := PackedVector3Array(); verts.resize(n * s)
	var norms := PackedVector3Array(); norms.resize(n * s)
	var cols := PackedColorArray(); cols.resize(n * s)
	var cosv := PackedFloat32Array(); var sinv := PackedFloat32Array()
	cosv.resize(s); sinv.resize(s)
	for k in s:
		cosv[k] = cos(TAU * float(k) / float(s)); sinv[k] = sin(TAU * float(k) / float(s))
	var t0: Vector3 = (curve_points[1] - curve_points[0]).normalized()
	var nrm: Vector3 = t0.cross(Vector3.UP if absf(t0.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT).normalized()
	for i in n:
		var a: Vector3 = curve_points[maxi(i - 1, 0)]
		var b: Vector3 = curve_points[mini(i + 1, n - 1)]
		var tan: Vector3 = b - a
		if tan.length_squared() > 1e-12:
			tan = tan.normalized()
			nrm = (nrm - tan * nrm.dot(tan))
			if nrm.length_squared() < 1e-10:
				nrm = tan.cross(Vector3.UP if absf(tan.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT)
			nrm = nrm.normalized()
		var bin: Vector3 = tan.cross(nrm)
		var col: Color = Color.from_hsv(float(i) / float(n), 0.95, 0.95) if rainbow_gradient else Color(0.3, 0.8, 1.0)
		for k in s:
			var d: Vector3 = nrm * cosv[k] + bin * sinv[k]
			verts[i * s + k] = curve_points[i] + d * r
			norms[i * s + k] = d
			cols[i * s + k] = col
	if _tube_key != Vector2i(n, s):
		_tube_key = Vector2i(n, s)
		_tube_indices = PackedInt32Array(); _tube_indices.resize((n - 1) * s * 6)
		var w: int = 0
		for i in n - 1:
			for k in s:
				var k2: int = (k + 1) % s
				var p0: int = i * s + k; var p1: int = i * s + k2; var p2: int = (i + 1) * s + k2; var p3: int = (i + 1) * s + k
				_tube_indices[w] = p0; _tube_indices[w + 1] = p1; _tube_indices[w + 2] = p2
				_tube_indices[w + 3] = p0; _tube_indices[w + 4] = p2; _tube_indices[w + 5] = p3
				w += 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = _tube_indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_tube_instance.mesh = mesh


func _tube_shader() -> Shader:
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode cull_disabled;
uniform float glow = 0.7;
void fragment() {
	ALBEDO = COLOR.rgb;
	EMISSION = COLOR.rgb * COLOR.rgb * glow * 0.5;   // squared: saturated hues glow without washing out to white
	ROUGHNESS = 0.45;
	METALLIC = 0.0;
	RIM = 0.4;
}
"""
	return sh


## What the ratio does, in one line: the figure closes for any rational ratio, and never for an irrational one.
func _ratio_text() -> String:
	if ratio == "1_phi_0":
		return "1 : φ   ·   irrational - the curve never closes"
	var parts: Array = [_fmt(freq_ratio_x), _fmt(freq_ratio_y)]
	if absf(amplitude_z) > 0.001 and absf(freq_ratio_z) > 0.001:
		parts.append(_fmt(freq_ratio_z))
	return "%s   ·   rational - the curve closes" % " : ".join(parts)


func _add_component_strip(is_x_component: bool) -> void:
	if not curve_mesh:
		return
	var steps: int = _sample_count()
	var span: float = 1.2
	var col: Color = Color(0.55, 0.62, 0.72)
	curve_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(steps + 1):
		var f: float = float(i) / float(steps)
		var t: float = f * TAU * _turns
		var p: Vector3 = Vector3.ZERO
		if is_x_component:
			p = Vector3(amplitude_x * sin(freq_ratio_x * t + phase_shift),
				-(amplitude_y + 0.35) - f * span, 0.0)
		else:
			p = Vector3(-(amplitude_x + 0.35) - f * span,
				amplitude_y * sin(freq_ratio_y * t), 0.0)
		curve_mesh.surface_set_color(col)
		curve_mesh.surface_add_vertex(p)
	curve_mesh.surface_end()

func _update_particle() -> void:
	if not particle_instance:
		return

	# Current position on curve
	var current_point = _calculate_point(time)
	particle_instance.position = current_point

	# Update trail
	trail_points.append(current_point)
	if trail_points.size() > trail_length:
		trail_points.pop_front()

func get_current_position() -> Vector3:
	"""Get current particle position"""
	return _calculate_point(time)

func get_velocity() -> Vector3:
	"""Get instantaneous velocity (derivative)"""
	var dt = 0.01
	var p1 = _calculate_point(time)
	var p2 = _calculate_point(time + dt)
	return (p2 - p1) / dt

# Preset configurations for famous Lissajous patterns
func set_preset(preset_name: String) -> void:
	match preset_name:
		"circle":
			freq_ratio_x = 1.0
			freq_ratio_y = 1.0
			freq_ratio_z = 0.0
			phase_shift = PI / 2.0
		"figure_eight":
			freq_ratio_x = 2.0
			freq_ratio_y = 1.0
			freq_ratio_z = 0.0
			phase_shift = 0.0
		"trefoil":
			freq_ratio_x = 3.0
			freq_ratio_y = 2.0
			freq_ratio_z = 0.0
			phase_shift = 0.0
		"3d_knot":
			freq_ratio_x = 3.0
			freq_ratio_y = 2.0
			freq_ratio_z = 1.0
			phase_shift = PI / 4.0
		"pentagram":
			freq_ratio_x = 5.0
			freq_ratio_y = 4.0
			freq_ratio_z = 0.0
			phase_shift = 0.0

	_generate_full_curve()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# --- DNA axes -----------------------------------------------------------------

func _wants_particle() -> bool:
	# `result` is the closed figure with nothing riding it. Every other value
	# keeps the tracer, which is what show_particle has always decided alone.
	return show_particle and evidence != "result"


func _fmt(v: float) -> String:
	# Godot's sprintf has no %g, so whole numbers are printed whole by hand.
	if is_equal_approx(v, round(v)):
		return str(int(round(v)))
	return "%.3f" % v


func _apply_ratio() -> void:
	_last_ratio = ratio
	match ratio:
		"1_1_0":
			# A 1:1 with delta = 0 is a straight diagonal, so the circle needs
			# its quarter-turn — the same pairing set_preset("circle") makes.
			freq_ratio_x = 1.0
			freq_ratio_y = 1.0
			freq_ratio_z = 0.0
			phase_shift = PI / 2.0
			_turns = 1.0
			_sample_scale = 1.0
		"2_1_0":
			freq_ratio_x = 2.0
			freq_ratio_y = 1.0
			freq_ratio_z = 0.0
			phase_shift = 0.0
			_turns = 1.0
			_sample_scale = 1.0
		"3_2_0":
			freq_ratio_x = 3.0
			freq_ratio_y = 2.0
			freq_ratio_z = 0.0
			phase_shift = 0.0
			_turns = 1.0
			_sample_scale = 1.0
		"5_4_0":
			freq_ratio_x = 5.0
			freq_ratio_y = 4.0
			freq_ratio_z = 0.0
			phase_shift = 0.0
			_turns = 1.0
			_sample_scale = 1.0
		"1_phi_0":
			# The one incommensurable ratio. Over a single period it would be
			# an unremarkable open arc; the curve only shows that it will never
			# close by being allowed to run past the period and miss its own
			# start. Six turns, and three times the samples to carry them.
			freq_ratio_x = 1.0
			freq_ratio_y = PHI
			freq_ratio_z = 0.0
			phase_shift = 0.0
			_turns = 6.0
			_sample_scale = 3.0
		_:
			# "3_2_1" — and anything unrecognised. These are the four numbers
			# lissajous_curves.tscn has always carried, so the default writes
			# what was already there and every shipped placement is untouched.
			freq_ratio_x = 3.0
			freq_ratio_y = 2.0
			freq_ratio_z = 1.0
			phase_shift = 0.0
			_turns = 1.0
			_sample_scale = 1.0


func apply_grid_config(config_data: Dictionary) -> void:
	# Guarded twice: a word is taken only when it is one this file knows AND
	# differs from what is already set, and nothing is rebuilt until _ready has
	# built once. A bare token passes no keys at all and never reaches either.
	var ratio_moved: bool = false
	var evidence_moved: bool = false

	if config_data.has("ratio"):
		var want: String = str(config_data["ratio"])
		if want in RATIOS and want != ratio:
			ratio = want
			ratio_moved = true
	if config_data.has("evidence"):
		var want_ev: String = str(config_data["evidence"])
		if want_ev in EVIDENCE and want_ev != evidence:
			evidence = want_ev
			evidence_moved = true

	if not _built:
		return
	if ratio_moved:
		_apply_ratio()
	if evidence_moved or (ratio_moved and evidence == "axiom"):
		_last_evidence = evidence
		_setup_visualization()
	if ratio_moved or evidence_moved:
		_generate_full_curve()
