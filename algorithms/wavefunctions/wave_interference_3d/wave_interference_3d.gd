# wave_interference_3d.gd
# Wave Interference 3D — two circular wave sources on a grid of spheres
# Each sphere's Y position = sum of two sine waves from the two sources.
# Color: blue (trough) → white (zero) → orange (peak).
#
# @identity
# essence: two simple waves create a complex pattern — superposition is the grammar of interference
# desire: adjust frequency, separation, amplitude and watch nodes rise and flatten as waves collide
# critical_parameter: separation — controls the spacing of the interference fringes
# triggers: _process animates every frame; sliders change frequency, separation, amplitude
# emerges: bright ridges of constructive interference; still lines of destructive cancellation
# needs: RackTemplates panel with 3 sliders [has]; 16x16 sphere grid [has]; 2 source markers [has]
# relationships: builds on wave_interference (2D ring version); feeds diffraction, holography
# truth: Two waves meeting don't fight — they add. The pattern they make holds more information than either wave alone.

extends Node3D

class_name WaveInterference3D

# ── Parameters ───────────────────────────────────────────────────────
const GRID_SIZE: int = 16
const GRID_SPACING: float = 0.018
const SPHERE_RADIUS: float = 0.003
const SOURCE_RADIUS: float = 0.008

const COLOR_TROUGH := Color(0.15, 0.3, 0.95)
const COLOR_ZERO := Color(0.9, 0.9, 0.9)
const COLOR_PEAK := Color(0.95, 0.55, 0.1)

# ── State ────────────────────────────────────────────────────────────
var _time: float = 0.0
var _frequency: float = 4.0       # 1 – 10
var _separation: float = 0.12     # distance between sources
var _amplitude: float = 0.015

var _grid_spheres: Array[MeshInstance3D] = []
var _grid_mats: Array[StandardMaterial3D] = []
var _source_a: MeshInstance3D
var _source_b: MeshInstance3D
var _grid_root: Node3D


func _ready() -> void:
	_build_grid()
	_build_sources()
	_build_panel()


func _process(delta: float) -> void:
	_time += delta
	_animate_grid()


# ═════════════════════════════════════════════════════════════════════
# GRID
# ═════════════════════════════════════════════════════════════════════

func _build_grid() -> void:
	_grid_root = Node3D.new()
	_grid_root.name = "GridRoot"
	_grid_root.position = Vector3(0.0, 0.35, 0.0)
	add_child(_grid_root)

	var base_mesh := SphereMesh.new()
	base_mesh.radius = SPHERE_RADIUS
	base_mesh.height = SPHERE_RADIUS * 2.0

	var half_extent: float = (GRID_SIZE - 1) * GRID_SPACING * 0.5

	for iz in GRID_SIZE:
		for ix in GRID_SIZE:
			var mi := MeshInstance3D.new()
			mi.mesh = base_mesh
			var mat := StandardMaterial3D.new()
			mat.albedo_color = COLOR_ZERO
			mat.emission_enabled = true
			mat.emission = COLOR_ZERO
			mat.emission_energy_multiplier = 0.4
			mi.material_override = mat

			mi.position = Vector3(
				ix * GRID_SPACING - half_extent,
				0.0,
				iz * GRID_SPACING - half_extent
			)
			_grid_root.add_child(mi)
			_grid_spheres.append(mi)
			_grid_mats.append(mat)


# ═════════════════════════════════════════════════════════════════════
# SOURCES
# ═════════════════════════════════════════════════════════════════════

func _build_sources() -> void:
	var src_mesh := SphereMesh.new()
	src_mesh.radius = SOURCE_RADIUS
	src_mesh.height = SOURCE_RADIUS * 2.0

	var src_mat := StandardMaterial3D.new()
	src_mat.albedo_color = Color(0.95, 0.2, 0.2)
	src_mat.emission_enabled = true
	src_mat.emission = Color(0.95, 0.2, 0.2)
	src_mat.emission_energy_multiplier = 0.8

	_source_a = MeshInstance3D.new()
	_source_a.mesh = src_mesh
	_source_a.material_override = src_mat
	_grid_root.add_child(_source_a)

	_source_b = MeshInstance3D.new()
	_source_b.mesh = src_mesh
	_source_b.material_override = src_mat.duplicate()
	_grid_root.add_child(_source_b)

	_update_source_positions()


func _update_source_positions() -> void:
	var half_sep: float = _separation * 0.5
	_source_a.position = Vector3(-half_sep, 0.0, 0.0)
	_source_b.position = Vector3(half_sep, 0.0, 0.0)


# ═════════════════════════════════════════════════════════════════════
# ANIMATION
# ═════════════════════════════════════════════════════════════════════

func _animate_grid() -> void:
	var k: float = _frequency * TAU  # wave number
	var w: float = _frequency * TAU * 0.5  # angular frequency (half speed for readability)
	var src_a_pos := _source_a.position
	var src_b_pos := _source_b.position

	for i in _grid_spheres.size():
		var mi: MeshInstance3D = _grid_spheres[i]
		var xz := Vector3(mi.position.x, 0.0, mi.position.z)

		var d1: float = xz.distance_to(Vector3(src_a_pos.x, 0.0, src_a_pos.z))
		var d2: float = xz.distance_to(Vector3(src_b_pos.x, 0.0, src_b_pos.z))

		var y: float = _amplitude * (sin(k * d1 - w * _time) + sin(k * d2 - w * _time))
		mi.position.y = y

		# Color: lerp trough → zero → peak
		var norm_y: float = clampf(y / (_amplitude * 2.0), -1.0, 1.0)
		var color: Color
		if norm_y < 0.0:
			color = COLOR_TROUGH.lerp(COLOR_ZERO, norm_y + 1.0)
		else:
			color = COLOR_ZERO.lerp(COLOR_PEAK, norm_y)

		var mat: StandardMaterial3D = _grid_mats[i]
		mat.albedo_color = color
		mat.emission = color


# ═════════════════════════════════════════════════════════════════════
# PANEL
# ═════════════════════════════════════════════════════════════════════

func _build_panel() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("WAVE INTERFERENCE", [
		[{"type": "slider_h", "label": "FREQ", "default": (_frequency - 1.0) / 9.0}],
		[{"type": "slider_h", "label": "SEPARATION", "default": (_separation - 0.04) / 0.26}],
		[{"type": "slider_h", "label": "AMPLITUDE", "default": 0.5}],
	])
	panel.position = Vector3(0, 0.08, 0.18)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	for i in 3:
		var slider: Node = panel.find_child("Param_%d" % i, true, false)
		if slider and slider.has_signal("slider_moved"):
			slider.slider_moved.connect(_on_slider_changed)


func _on_slider_changed(_value: float) -> void:
	var panel_node: Node = get_node_or_null("WAVE_INTERFERENCE")
	if not panel_node:
		return

	for i in 3:
		var slider: Node = panel_node.find_child("Param_%d" % i, true, false)
		if slider and slider.has_method("get_normalized_value"):
			var norm: float = slider.get_normalized_value()
			match i:
				0: _frequency = 1.0 + norm * 9.0        # 1 – 10
				1:
					_separation = 0.04 + norm * 0.26     # 0.04 – 0.30
					_update_source_positions()
				2: _amplitude = 0.005 + norm * 0.025     # 0.005 – 0.030


# ═════════════════════════════════════════════════════════════════════
# GRID CONFIG
# ═════════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	pass
