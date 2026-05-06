extends "res://commons/primitives/point/grab_sphere.gd"

## Axis-constrained slider for teaching translation
## Slides only along one axis (X, Y, or Z)
## Can be used as obstacles that block paths

@export_enum("X", "Y", "Z") var slide_axis: String = "X"
@export var slide_min: float = -2.0
@export var slide_max: float = 2.0
@export var snap_to_grid: bool = false
@export var grid_spacing: float = 0.5
@export var show_rail: bool = true  # Visual guide showing slide path
@export var rail_color: Color = Color(0.3, 0.6, 1.0, 0.5)
@export var show_position_marker: bool = true  # Shows current position on axis

var _start_position: Vector3
var _rail_mesh: MeshInstance3D
var _position_marker: MeshInstance3D

func _ready() -> void:
	super._ready()
	_start_position = position

	if show_rail:
		_create_rail_visual()

	if show_position_marker:
		_create_position_marker()

func _create_rail_visual() -> void:
	# Create a thin cylinder showing the slide path
	_rail_mesh = MeshInstance3D.new()
	_rail_mesh.name = "SlideRail"

	var length = slide_max - slide_min
	var rail = CylinderMesh.new()
	rail.height = length
	rail.top_radius = 0.02
	rail.bottom_radius = 0.02

	_rail_mesh.mesh = rail

	var material = StandardMaterial3D.new()
	material.albedo_color = rail_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = rail_color * 0.5
	material.roughness = 1.0
	material.metallic = 0.0
	material.metallic_specular = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_rail_mesh.material_override = material

	# Position rail at center of slide range
	var center_offset = (slide_max + slide_min) / 2.0
	match slide_axis:
		"X":
			_rail_mesh.rotation = Vector3(0, 0, PI/2)  # Rotate to horizontal
			_rail_mesh.position = Vector3(center_offset, 0, 0)
		"Y":
			_rail_mesh.position = Vector3(0, center_offset, 0)
		"Z":
			_rail_mesh.rotation = Vector3(PI/2, 0, 0)  # Rotate to depth
			_rail_mesh.position = Vector3(0, 0, center_offset)

	add_child(_rail_mesh)

func _create_position_marker() -> void:
	# Small sphere that shows current position along axis
	_position_marker = MeshInstance3D.new()
	_position_marker.name = "PositionMarker"

	var marker = SphereMesh.new()
	marker.radius = 0.03
	marker.height = 0.06

	_position_marker.mesh = marker

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.5, 0.2)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.5, 0.2) * 0.8
	material.roughness = 1.0
	material.metallic = 0.0
	material.metallic_specular = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_position_marker.material_override = material

	add_child(_position_marker)
	_update_position_marker()

func _update_position_marker() -> void:
	if not _position_marker:
		return

	# Position marker along the rail based on current position
	var current_offset = 0.0
	match slide_axis:
		"X":
			current_offset = position.x
			_position_marker.position = Vector3(current_offset, -0.15, 0)
		"Y":
			current_offset = position.y
			_position_marker.position = Vector3(-0.15, current_offset, 0)
		"Z":
			current_offset = position.z
			_position_marker.position = Vector3(0, -0.15, current_offset)

# Override the dropped handler to constrain to axis
func _on_dropped(pickable) -> void:
	super._on_dropped(pickable)
	_constrain_to_axis()

func _physics_process(_delta: float) -> void:
	# Continuously constrain while being dragged
	if is_picked_up():
		_constrain_to_axis()

	if show_position_marker:
		_update_position_marker()

func _constrain_to_axis() -> void:
	var constrained_pos = _start_position

	# Get the current position along the allowed axis
	var axis_value = 0.0
	match slide_axis:
		"X":
			axis_value = position.x
		"Y":
			axis_value = position.y
		"Z":
			axis_value = position.z

	# Clamp to min/max range
	axis_value = clamp(axis_value, slide_min, slide_max)

	# Apply grid snapping if enabled
	if snap_to_grid:
		axis_value = round(axis_value / grid_spacing) * grid_spacing

	# Set position only along the allowed axis
	match slide_axis:
		"X":
			constrained_pos.x = axis_value
		"Y":
			constrained_pos.y = axis_value
		"Z":
			constrained_pos.z = axis_value

	position = constrained_pos

func reset_position() -> void:
	position = _start_position
	if is_picked_up():
		drop()

func get_axis_progress() -> float:
	# Returns 0.0 to 1.0 representing position along axis
	var current = 0.0
	match slide_axis:
		"X":
			current = position.x
		"Y":
			current = position.y
		"Z":
			current = position.z

	var range_size = slide_max - slide_min
	if range_size == 0:
		return 0.0

	return (current - slide_min) / range_size
