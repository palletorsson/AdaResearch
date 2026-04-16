# beat_frequency_demo.gd
# Beat Frequency Demo — two close sine waves producing a pulsing envelope
#
# Three rows of animated spheres: Wave A, Wave B, and their sum.
# The sum row shows the characteristic beat pattern when frequencies are close.
# Sliders control both frequencies. A label displays the beat frequency.
#
# @identity
# essence: f_beat = |f_a - f_b| — difference becomes rhythm
# desire: drag two frequencies close together and hear/see the slow pulse emerge from their interference
# critical_parameter: freq_a and freq_b sliders — the smaller the gap, the slower the beat
# triggers: slider_moved on either frequency recalculates the wave animation
# emerges: the beat envelope — a slow amplitude modulation born from two fast oscillations
# needs: RackTemplates panel with two sliders [has]; 3 rows of spheres [has]; Label3D [has]
# relationships: builds on sine_oscillation; connects to fourier_transform, standing_waves, resonance
# truth: When two nearly identical things interfere, their tiny difference becomes the loudest signal.

extends Node3D

class_name BeatFrequencyDemo

# ── Parameters ───────────────────────────────────────────────────────────
@export var sphere_count: int = 64
@export var sphere_radius: float = 0.006
@export var row_width: float = 0.5
@export var amplitude: float = 0.06
@export var row_spacing: float = 0.12

@export var color_a: Color = Color(0.2, 0.5, 0.95)
@export var color_b: Color = Color(0.2, 0.85, 0.3)
@export var color_sum: Color = Color(0.95, 0.6, 0.15)

# ── State ────────────────────────────────────────────────────────────────
var _freq_a: float = 4.0   # Hz (1-10 range)
var _freq_b: float = 5.0   # Hz
var _time: float = 0.0

var _spheres_a: Array[MeshInstance3D] = []
var _spheres_b: Array[MeshInstance3D] = []
var _spheres_sum: Array[MeshInstance3D] = []

var _beat_label: Label3D
var _freq_label: Label3D

var _base_y: float = 0.9   # center height of the display


func _ready() -> void:
	_create_row_labels()
	_create_spheres()
	_create_beat_label()
	_create_controls()
	_update_beat_label()


func _process(delta: float) -> void:
	_time += delta
	_animate_spheres()


# ═════════════════════════════════════════════════════════════════════════
# SPHERE ROWS
# ═════════════════════════════════════════════════════════════════════════

func _create_spheres() -> void:
	var dx := row_width / float(sphere_count - 1) if sphere_count > 1 else 0.0
	var x_start := -row_width / 2.0

	# Materials (shared per row)
	var mat_a := _make_sphere_mat(color_a)
	var mat_b := _make_sphere_mat(color_b)
	var mat_sum := _make_sphere_mat(color_sum)

	# Shared mesh
	var smesh := SphereMesh.new()
	smesh.radius = sphere_radius
	smesh.height = sphere_radius * 2.0
	smesh.radial_segments = 8
	smesh.rings = 4

	for i in range(sphere_count):
		var x := x_start + i * dx

		# Row A (top)
		var sa := MeshInstance3D.new()
		sa.mesh = smesh
		sa.material_override = mat_a
		sa.position = Vector3(x, _base_y + row_spacing, 0)
		add_child(sa)
		_spheres_a.append(sa)

		# Row B (middle)
		var sb := MeshInstance3D.new()
		sb.mesh = smesh
		sb.material_override = mat_b
		sb.position = Vector3(x, _base_y, 0)
		add_child(sb)
		_spheres_b.append(sb)

		# Row Sum (bottom)
		var ss := MeshInstance3D.new()
		ss.mesh = smesh
		ss.material_override = mat_sum
		ss.position = Vector3(x, _base_y - row_spacing, 0)
		add_child(ss)
		_spheres_sum.append(ss)


func _make_sphere_mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.3
	mat.metallic = 0.2
	mat.roughness = 0.5
	return mat


func _animate_spheres() -> void:
	var dx := row_width / float(sphere_count - 1) if sphere_count > 1 else 0.0
	var spatial_freq := TAU / row_width * 2.0  # ~2 full waves across the row

	for i in range(sphere_count):
		var phase_offset := float(i) * dx * spatial_freq

		# Wave A
		var ya := sin(_freq_a * TAU * _time + phase_offset) * amplitude
		_spheres_a[i].position.y = _base_y + row_spacing + ya

		# Wave B
		var yb := sin(_freq_b * TAU * _time + phase_offset) * amplitude
		_spheres_b[i].position.y = _base_y + yb

		# Sum (A + B) — scaled by 0.5 to keep within visual bounds
		var y_sum := (ya + yb) * 0.5
		_spheres_sum[i].position.y = _base_y - row_spacing + y_sum


# ═════════════════════════════════════════════════════════════════════════
# LABELS
# ═════════════════════════════════════════════════════════════════════════

func _create_row_labels() -> void:
	var label_x := -row_width / 2.0 - 0.06

	var la := Label3D.new()
	la.text = "A"
	la.pixel_size = 0.0012
	la.font_size = 14
	la.modulate = color_a
	la.position = Vector3(label_x, _base_y + row_spacing, 0)
	la.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(la)

	var lb := Label3D.new()
	lb.text = "B"
	lb.pixel_size = 0.0012
	lb.font_size = 14
	lb.modulate = color_b
	lb.position = Vector3(label_x, _base_y, 0)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(lb)

	var ls := Label3D.new()
	ls.text = "A+B"
	ls.pixel_size = 0.0012
	ls.font_size = 14
	ls.modulate = color_sum
	ls.position = Vector3(label_x, _base_y - row_spacing, 0)
	ls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(ls)


func _create_beat_label() -> void:
	_beat_label = Label3D.new()
	_beat_label.name = "BeatLabel"
	_beat_label.text = ""
	_beat_label.pixel_size = 0.0018
	_beat_label.font_size = 16
	_beat_label.modulate = color_sum
	_beat_label.position = Vector3(0, _base_y + row_spacing + 0.15, 0)
	_beat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_beat_label)

	_freq_label = Label3D.new()
	_freq_label.name = "FreqLabel"
	_freq_label.text = ""
	_freq_label.pixel_size = 0.001
	_freq_label.font_size = 12
	_freq_label.modulate = Color(0.65, 0.65, 0.7)
	_freq_label.position = Vector3(0, _base_y + row_spacing + 0.10, 0)
	_freq_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_freq_label)


func _update_beat_label() -> void:
	var beat := absf(_freq_a - _freq_b)
	_beat_label.text = "beat = |%.1f - %.1f| = %.1f Hz" % [_freq_a, _freq_b, beat]
	_freq_label.text = "f_a = %.1f Hz    f_b = %.1f Hz" % [_freq_a, _freq_b]


# ═════════════════════════════════════════════════════════════════════════
# CONTROLS
# ═════════════════════════════════════════════════════════════════════════

func _create_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("BEAT FREQUENCY", [
		[
			{"type": "slider_h", "label": "FREQ A", "default": 0.333},
		],
		[
			{"type": "slider_h", "label": "FREQ B", "default": 0.444},
		],
	])
	panel.position = Vector3(0.35, 0.8, 0.1)
	panel.rotation_degrees = Vector3(-15, -20, 0)
	add_child(panel)

	# Freq A slider (Param_0): maps [0,1] -> [1,10] Hz
	var slider_a: Node = panel.find_child("Param_0", true, false)
	if slider_a and slider_a.has_signal("slider_moved"):
		slider_a.slider_moved.connect(func(_name: String, val: float):
			_freq_a = lerpf(1.0, 10.0, val)
			_update_beat_label()
		)

	# Freq B slider (Param_1): maps [0,1] -> [1,10] Hz
	var slider_b: Node = panel.find_child("Param_1", true, false)
	if slider_b and slider_b.has_signal("slider_moved"):
		slider_b.slider_moved.connect(func(_name: String, val: float):
			_freq_b = lerpf(1.0, 10.0, val)
			_update_beat_label()
		)


func apply_grid_config(config: Dictionary) -> void:
	pass
