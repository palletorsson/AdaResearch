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
	# The Penrose triangle is built from three bars that appear to connect
	# but actually don't in 3D space. The illusion works from one viewpoint.
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.75, 0.65)
	mat.metallic = 0.3
	mat.roughness = 0.6
	
	# Bar 1 - horizontal bottom
	var bar1 = _create_bar(Vector3(size, bar_thickness, bar_thickness))
	bar1.position = Vector3(0, -size * 0.4, 0)
	bar1.material_override = mat
	add_child(bar1)
	_bars.append(bar1)
	
	# Bar 2 - vertical right (but positioned to create illusion)
	var bar2 = _create_bar(Vector3(bar_thickness, size, bar_thickness))
	bar2.position = Vector3(size * 0.4, 0, -size * 0.3)
	var mat2 = mat.duplicate()
	mat2.albedo_color = Color(0.7, 0.65, 0.55)
	bar2.material_override = mat2
	add_child(bar2)
	_bars.append(bar2)
	
	# Bar 3 - diagonal connecting (impossible connection)
	var bar3 = _create_bar(Vector3(bar_thickness, bar_thickness, size))
	bar3.position = Vector3(-size * 0.35, size * 0.35, -size * 0.15)
	bar3.rotation_degrees = Vector3(0, 0, -60)
	var mat3 = mat.duplicate()
	mat3.albedo_color = Color(0.6, 0.55, 0.45)
	bar3.material_override = mat3
	add_child(bar3)
	_bars.append(bar3)
	
	# Corner pieces to sell the illusion
	_create_corner_piece(Vector3(size * 0.4, -size * 0.4, 0), mat)
	_create_corner_piece(Vector3(-size * 0.35, -size * 0.4, 0), mat2)
	_create_corner_piece(Vector3(-size * 0.35, size * 0.35, -size * 0.3), mat3)

func _create_bar(bar_size: Vector3) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = bar_size
	mesh_instance.mesh = box
	return mesh_instance

func _create_corner_piece(pos: Vector3, mat: StandardMaterial3D):
	var corner = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(bar_thickness * 1.5, bar_thickness * 1.5, bar_thickness * 1.5)
	corner.mesh = box
	corner.position = pos
	corner.material_override = mat
	add_child(corner)

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
