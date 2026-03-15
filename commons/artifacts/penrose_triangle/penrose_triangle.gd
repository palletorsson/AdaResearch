# penrose_triangle.gd
# The impossible triangle - locally coherent, globally impossible
# A 3D construction that only "works" from specific viewpoints

extends Node3D

class_name PenroseTriangle

signal viewpoint_locked
signal illusion_revealed

@export var size: float = 0.5
@export var bar_thickness: float = 0.08
@export var auto_rotate: bool = false
@export var rotation_speed: float = 0.2
@export var show_sweet_spot: bool = true

var _bars: Array[MeshInstance3D] = []
var _sweet_spot_indicator: MeshInstance3D
var _info_label: Label3D
var _is_at_sweet_spot: bool = false

func _ready():
	_create_impossible_triangle()
	_create_info_label()
	if show_sweet_spot:
		_create_sweet_spot_indicator()

func _create_impossible_triangle():
	# Penrose triangle: three beams along the edges of an equilateral triangle.
	# One joint has a Z-offset so the triangle can't close in 3D,
	# but from the sweet-spot viewpoint it appears to form a closed shape.

	var h = size * 0.866  # sqrt(3)/2
	var half = size * 0.5

	# Three vertices of an equilateral triangle in XY plane
	var v_bl = Vector3(-half, -h / 3.0, 0)       # bottom-left
	var v_br = Vector3( half, -h / 3.0, 0)       # bottom-right
	var v_top = Vector3(0, h * 2.0 / 3.0, 0)     # top-center

	# Z-offset at top-center to create the impossible gap
	var z_gap = size * 0.25
	var v_top_back = Vector3(v_top.x, v_top.y, -z_gap)

	var mat_a = StandardMaterial3D.new()
	mat_a.albedo_color = Color(0.85, 0.78, 0.65)
	mat_a.metallic = 0.35
	mat_a.roughness = 0.5

	var mat_b = mat_a.duplicate()
	mat_b.albedo_color = Color(0.72, 0.65, 0.55)

	var mat_c = mat_a.duplicate()
	mat_c.albedo_color = Color(0.6, 0.55, 0.48)

	# Bar 1 — bottom edge: bottom-left → bottom-right
	_add_beam(v_bl, v_br, mat_a)

	# Bar 2 — right edge: bottom-right → top-back
	_add_beam(v_br, v_top_back, mat_b)

	# Bar 3 — left edge: top-front → bottom-left
	_add_beam(v_top, v_bl, mat_c)

func _add_beam(from: Vector3, to: Vector3, mat: StandardMaterial3D) -> void:
	var diff = to - from
	var length = diff.length()
	if length < 0.001:
		return

	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(bar_thickness, bar_thickness, length)
	mesh_instance.mesh = box
	mesh_instance.material_override = mat

	# Position at midpoint, rotate to align Z-axis with from→to direction
	mesh_instance.position = (from + to) * 0.5
	mesh_instance.look_at_from_position(mesh_instance.position, to, Vector3.UP)

	add_child(mesh_instance)
	_bars.append(mesh_instance)

func _create_info_label():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.001
	_info_label.font_size = 14
	_info_label.text = "PENROSE TRIANGLE\nLocally coherent\nGlobally impossible"
	_info_label.position = Vector3(0, -size * 0.8, 0)
	_info_label.modulate = Color(0.8, 0.8, 0.8)
	add_child(_info_label)

func _create_sweet_spot_indicator():
	_sweet_spot_indicator = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.03
	sphere.height = 0.06
	_sweet_spot_indicator.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 1.0, 0.3, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.3)
	mat.emission_energy_multiplier = 0.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_sweet_spot_indicator.material_override = mat
	
	# Position where the illusion works best
	_sweet_spot_indicator.position = Vector3(0, 0, size * 2.5)
	add_child(_sweet_spot_indicator)

func _process(delta):
	if auto_rotate:
		rotation.y += delta * rotation_speed

func check_viewer_position(viewer_pos: Vector3) -> bool:
	# Check if viewer is near the sweet spot where illusion works
	var local_pos = to_local(viewer_pos)
	var sweet_spot = Vector3(0, 0, size * 2.5)
	var distance = local_pos.distance_to(sweet_spot)
	
	var was_at_sweet_spot = _is_at_sweet_spot
	_is_at_sweet_spot = distance < size * 0.5
	
	if _is_at_sweet_spot and not was_at_sweet_spot:
		viewpoint_locked.emit()
		_info_label.text = "ILLUSION ACTIVE\nFrom here, it looks possible"
	elif not _is_at_sweet_spot and was_at_sweet_spot:
		illusion_revealed.emit()
		_info_label.text = "PENROSE TRIANGLE\nLocally coherent\nGlobally impossible"
	
	return _is_at_sweet_spot

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
