# durer_grid.gd - Standing perspective grid frame inspired by Albrecht Dürer
# Usage: dgrid:90:1:1#config:10:10 for 10x10 grid cells
# Format: dgrid[:rotation:height:scale]#config:rows:cols
# A standing frame with a grid of wires for perspective drawing assistance
#
# @identity
# essence: a standing frame strung with a grid of wires — Dürer's drawing screen, the reticule that flattens depth
# desire: learner sees perspective as a literal projection through a grid, not an optical trick of the eye
# critical_parameter: rows x cols — the grid density that quantizes the continuous scene into drawable cells
# triggers: builds on ready; rebuilds when apply_grid_config or set_grid_resolution changes the cell count
# emerges: the realization that Renaissance perspective was an algorithm — sample the world cell by cell
# needs: [renders frame + reconfigurable wire grid [has], missing a subject seen THROUGH the grid to project]
# relationships: a descendant of grid_lines and line; the frame that turns a coordinate grid into an instrument
# truth: perspective is a projection through a grid — Dürer put a screen between eye and world to flatten it
extends Node3D

const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")

# Grid configuration
@export var rows: int = 10  # Number of horizontal divisions
@export var cols: int = 10  # Number of vertical divisions
@export var frame_width: float = 1.0  # Width of the frame
@export var frame_height: float = 1.2  # Height of the frame
@export var frame_depth: float = 0.04  # Depth/thickness of frame bars

# Visual settings
@export var frame_color: Color = Color(0.4, 0.6, 0.9)  # Light blue
@export var wire_color: Color = Color(0.5, 0.7, 1.0, 0.9)  # Light blue wire
@export var wire_thickness: float = 0.003  # Thin wires

# Internal nodes
var _frame_container: Node3D
var _wire_container: Node3D
var _mesh_instances: Array[MeshInstance3D] = []

func _ready():
	# Check for config metadata set by grid system
	if has_meta("config_config"):
		var config_str = str(get_meta("config_config"))
		_parse_config_string(config_str)

	_build_frame()

# Parse config string like "10:10" for rows:cols
func _parse_config_string(config_str: String) -> void:
	var parts = config_str.split(":")
	if parts.size() >= 1 and parts[0].is_valid_int():
		rows = max(2, int(parts[0]))
	if parts.size() >= 2 and parts[1].is_valid_int():
		cols = max(2, int(parts[1]))
	print("DurerGrid configured: rows=%d, cols=%d" % [rows, cols])

# Called by grid system for #config syntax
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("config"):
		_parse_config_string(str(config_data.config))
	if config_data.has("rows"):
		rows = max(2, int(config_data.rows))
	if config_data.has("cols"):
		cols = max(2, int(config_data.cols))
	if config_data.has("width"):
		frame_width = float(config_data.width)
	if config_data.has("height"):
		frame_height = float(config_data.height)

	# Rebuild if already built
	if _frame_container:
		_build_frame()

func _build_frame() -> void:
	# Clean up existing
	_clear_existing()

	# Create containers
	_frame_container = Node3D.new()
	_frame_container.name = "Frame"
	add_child(_frame_container)

	_wire_container = Node3D.new()
	_wire_container.name = "Wires"
	add_child(_wire_container)

	# Build wooden frame (4 bars)
	_create_frame_bars()

	# Build wire grid
	_create_wire_grid()

	# Add collision for the frame
	_create_collision()

func _clear_existing() -> void:
	if _frame_container:
		_frame_container.queue_free()
		_frame_container = null
	if _wire_container:
		_wire_container.queue_free()
		_wire_container = null
	_mesh_instances.clear()

func _create_frame_bars() -> void:
	var bar_size = frame_depth
	var half_w = frame_width / 2.0
	var half_h = frame_height / 2.0

	# Frame material - wood-like
	var frame_mat = GridMaterialFactory.make(frame_color)

	# Top bar
	_create_bar(
		Vector3(0, half_h, 0),
		Vector3(frame_width + bar_size, bar_size, bar_size),
		frame_mat
	)

	# Bottom bar
	_create_bar(
		Vector3(0, -half_h, 0),
		Vector3(frame_width + bar_size, bar_size, bar_size),
		frame_mat
	)

	# Left bar
	_create_bar(
		Vector3(-half_w, 0, 0),
		Vector3(bar_size, frame_height, bar_size),
		frame_mat
	)

	# Right bar
	_create_bar(
		Vector3(half_w, 0, 0),
		Vector3(bar_size, frame_height, bar_size),
		frame_mat
	)

func _create_bar(pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size

	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	instance.name = "FrameBar"

	_frame_container.add_child(instance)
	_mesh_instances.append(instance)

	return instance

func _create_wire_grid() -> void:
	var half_w = frame_width / 2.0
	var half_h = frame_height / 2.0

	# Wire material - thin dark lines
	var wire_mat = StandardMaterial3D.new()
	wire_mat.albedo_color = wire_color
	wire_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Create horizontal wires
	var h_spacing = frame_height / float(rows)
	for i in range(1, rows):
		var y = -half_h + i * h_spacing
		_create_wire(
			Vector3(-half_w, y, 0),
			Vector3(half_w, y, 0),
			wire_mat
		)

	# Create vertical wires
	var v_spacing = frame_width / float(cols)
	for i in range(1, cols):
		var x = -half_w + i * v_spacing
		_create_wire(
			Vector3(x, -half_h, 0),
			Vector3(x, half_h, 0),
			wire_mat
		)

func _create_wire(start: Vector3, end: Vector3, material: Material) -> void:
	# Use ImmediateMesh for thin lines
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(start)
	mesh.surface_add_vertex(end)
	mesh.surface_end()

	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.name = "Wire"

	# Add a thin cylinder for better visibility and collision
	var length = start.distance_to(end)
	var mid = (start + end) / 2.0
	var direction = (end - start).normalized()

	var cylinder = CylinderMesh.new()
	cylinder.height = length
	cylinder.top_radius = wire_thickness
	cylinder.bottom_radius = wire_thickness
	cylinder.radial_segments = 4

	var cyl_instance = MeshInstance3D.new()
	cyl_instance.mesh = cylinder
	cyl_instance.material_override = material
	cyl_instance.position = mid

	# Rotate cylinder to align with wire direction
	# CylinderMesh is Y-axis aligned by default
	if abs(direction.y) > 0.99:
		# Vertical wire - no rotation needed
		pass
	elif abs(direction.x) > 0.99:
		# Horizontal wire along X axis - rotate 90° around Z
		cyl_instance.rotation.z = PI / 2.0
	elif abs(direction.z) > 0.99:
		# Wire along Z axis - rotate 90° around X
		cyl_instance.rotation.x = PI / 2.0
	else:
		# Arbitrary direction - use basis alignment
		var up = Vector3.UP if abs(direction.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
		cyl_instance.look_at(mid + direction, up)
		cyl_instance.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	_wire_container.add_child(cyl_instance)
	_mesh_instances.append(cyl_instance)

func _create_collision() -> void:
	var static_body = StaticBody3D.new()
	static_body.name = "FrameCollision"
	add_child(static_body)

	# Simple box collision for the frame area
	var shape = BoxShape3D.new()
	shape.size = Vector3(frame_width + frame_depth * 2, frame_height + frame_depth * 2, frame_depth)

	var collision = CollisionShape3D.new()
	collision.shape = shape
	static_body.add_child(collision)

func set_grid_resolution(new_rows: int, new_cols: int) -> void:
	rows = max(2, new_rows)
	cols = max(2, new_cols)
	_build_frame()

func set_frame_size(width: float, height: float) -> void:
	frame_width = width
	frame_height = height
	_build_frame()

func set_frame_color(color: Color) -> void:
	frame_color = color
	for instance in _mesh_instances:
		if instance.name == "FrameBar" and instance.material_override:
			instance.material_override = GridMaterialFactory.make(color)

func set_wire_color(color: Color) -> void:
	wire_color = color
	# Wires would need rebuild to change color
	_build_frame()
