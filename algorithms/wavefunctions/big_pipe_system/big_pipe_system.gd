@tool
extends TurtlePipeBase

# Big Pipe System
# Generates a sequence of large drain pipe segments using scene instantiation
# Extends TurtlePipeBase for unified turtle-graphics interface
#
# Usage:
# var pipes = BigPipeSystem.new()
# pipes.generate_from_code("f,f,s,u,f,l,f")
# add_child(pipes)

class_name BigPipeSystem

# Segment Scenes
const SEGMENT_STRAIGHT = preload("res://algorithms/wavefunctions/big_pipe_system/segments/pipe_straight.tscn")
const SEGMENT_CORNER = preload("res://algorithms/wavefunctions/big_pipe_system/segments/pipe_corner.tscn")
const SEGMENT_SBEND = preload("res://algorithms/wavefunctions/big_pipe_system/segments/pipe_s_bend.tscn")
const SEGMENT_T_JUNCTION = preload("res://algorithms/wavefunctions/big_pipe_system/segments/pipe_t_junction.tscn")
const SEGMENT_CROSS = preload("res://algorithms/wavefunctions/big_pipe_system/segments/pipe_cross.tscn")
const SEGMENT_END_CAP = preload("res://algorithms/wavefunctions/big_pipe_system/segments/pipe_end_cap.tscn")
const SEGMENT_VERTICAL_UP = preload("res://algorithms/wavefunctions/big_pipe_system/segments/pipe_vertical_up.tscn")
const SEGMENT_VERTICAL_DOWN = preload("res://algorithms/wavefunctions/big_pipe_system/segments/pipe_vertical_down.tscn")

func _ready() -> void:
	# Set big pipe defaults
	pipe_radius = 0.8
	segment_length = 2.0
	super._ready()

# =============================================================================
# COMMAND REGISTRATION
# =============================================================================

func _register_custom_commands() -> void:
	# S-bend command specific to big pipes
	_command_handlers["s"] = _cmd_s_bend
	_command_handlers["sbend"] = _cmd_s_bend
	_command_handlers["offset"] = _cmd_s_bend
	_command_handlers["t"] = _cmd_t_junction
	_command_handlers["tee"] = _cmd_t_junction
	_command_handlers["junction"] = _cmd_t_junction
	_command_handlers["x"] = _cmd_cross
	_command_handlers["cross"] = _cmd_cross
	_command_handlers["cap"] = _cmd_end_cap
	_command_handlers["end"] = _cmd_end_cap
	_command_handlers["endcap"] = _cmd_end_cap
	_command_handlers["vu"] = _cmd_vertical_up
	_command_handlers["vup"] = _cmd_vertical_up
	_command_handlers["up_seg"] = _cmd_vertical_up
	_command_handlers["vd"] = _cmd_vertical_down
	_command_handlers["vdown"] = _cmd_vertical_down
	_command_handlers["down_seg"] = _cmd_vertical_down
	# "c" for counter/down is handled in base but we can alias it
	_command_handlers["c"] = _cmd_down

func _cmd_s_bend() -> void:
	var segment = _create_segment("sbend", {"offset": segment_length})
	if segment:
		_place_segment(segment)
		_advance_cursor_s_bend()

func _advance_cursor_s_bend() -> void:
	# S-Bend moves forward and offsets to the right
	var forward = cursor_basis.z
	var right = cursor_basis.x
	cursor_pos += (forward * segment_length) + (right * segment_length)


func _cmd_t_junction() -> void:
	var segment = _create_segment("t_junction", {})
	if segment:
		_place_segment(segment)
		_advance_cursor_forward(segment_length)


func _cmd_cross() -> void:
	var segment = _create_segment("cross", {})
	if segment:
		_place_segment(segment)
		_advance_cursor_forward(segment_length)


func _cmd_end_cap() -> void:
	var segment = _create_segment("end_cap", {})
	if segment:
		_place_segment(segment)


func _cmd_vertical_up() -> void:
	var segment = _create_segment("up", {})
	if segment:
		_place_segment(segment)
		_advance_cursor_corner(Vector3.RIGHT, 90)


func _cmd_vertical_down() -> void:
	var segment = _create_segment("down", {})
	if segment:
		_place_segment(segment)
		_advance_cursor_corner(Vector3.RIGHT, -90)

# =============================================================================
# SEGMENT CREATION
# =============================================================================

func _create_segment(segment_type: String, params: Dictionary) -> Node3D:
	match segment_type:
		"straight":
			return _create_straight_segment(params)
		"corner":
			return _create_corner_segment(params)
		"sbend":
			return _create_s_bend_segment(params)
		"t_junction":
			return _create_t_junction_segment(params)
		"cross":
			return _create_cross_segment(params)
		"end_cap":
			return _create_end_cap_segment(params)
		"up":
			return _create_vertical_up_segment(params)
		"down":
			return _create_vertical_down_segment(params)
		_:
			push_warning("BigPipeSystem: Unknown segment type: %s" % segment_type)
			return null

func _create_straight_segment(_params: Dictionary) -> Node3D:
	var instance = SEGMENT_STRAIGHT.instantiate()

	# Configure dimensions
	var mesh_inst = instance.get_node_or_null("MeshInstance3D")
	if mesh_inst and mesh_inst.mesh is CylinderMesh:
		mesh_inst.mesh = mesh_inst.mesh.duplicate()
		mesh_inst.mesh.top_radius = pipe_radius
		mesh_inst.mesh.bottom_radius = pipe_radius
		mesh_inst.mesh.height = segment_length
		mesh_inst.position.z = segment_length / 2.0

	var col = instance.find_child("CollisionShape3D", true, false) as CollisionShape3D
	if col:
		if not (col.shape is CylinderShape3D):
			col.shape = CylinderShape3D.new()
		col.shape = col.shape.duplicate()
		col.shape.radius = pipe_radius
		col.shape.height = segment_length
		col.position.z = segment_length / 2.0

	return instance

func _create_corner_segment(params: Dictionary) -> Node3D:
	var instance = SEGMENT_CORNER.instantiate()

	# Configure dimensions
	if instance.get("pipe_radius") != null:
		instance.pipe_radius = pipe_radius
	if instance.get("corner_radius") != null:
		instance.corner_radius = segment_length

	# Handle visual rotation for parametric corner orientation
	var axis = params.get("axis", Vector3.UP)
	var angle_deg = params.get("angle", 90)

	# The parametric corner is a right turn by default
	# Rotate visual basis to match intended direction
	if axis == Vector3.RIGHT:  # Pitch
		if angle_deg > 0:  # Up
			instance.rotate(Vector3.FORWARD, PI / 2)
		else:  # Down
			instance.rotate(Vector3.FORWARD, -PI / 2)
	elif axis == Vector3.UP:  # Yaw
		if angle_deg > 0:  # Left
			instance.rotate(Vector3.FORWARD, PI)
		# Right is default, no rotation needed

	return instance

func _create_s_bend_segment(params: Dictionary) -> Node3D:
	var instance = SEGMENT_SBEND.instantiate()

	# Configure dimensions
	var offset = params.get("offset", segment_length)

	if instance.get("pipe_radius") != null:
		instance.pipe_radius = pipe_radius
	if instance.get("length") != null:
		instance.length = segment_length
	if instance.get("offset") != null:
		instance.offset = offset

	return instance


func _create_t_junction_segment(_params: Dictionary) -> Node3D:
	var instance = SEGMENT_T_JUNCTION.instantiate()
	_configure_cylinder_meshes(instance)
	return instance


func _create_cross_segment(_params: Dictionary) -> Node3D:
	var instance = SEGMENT_CROSS.instantiate()
	_configure_cylinder_meshes(instance)
	return instance


func _create_end_cap_segment(_params: Dictionary) -> Node3D:
	var instance = SEGMENT_END_CAP.instantiate()
	_configure_cylinder_meshes(instance)

	for node in instance.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if not mesh_instance:
			continue
		if mesh_instance.mesh is SphereMesh:
			var sphere := (mesh_instance.mesh as SphereMesh).duplicate()
			sphere.radius = pipe_radius
			sphere.height = pipe_radius
			mesh_instance.mesh = sphere

	return instance


func _create_vertical_up_segment(_params: Dictionary) -> Node3D:
	var instance = SEGMENT_VERTICAL_UP.instantiate()
	_configure_cylinder_meshes(instance)
	return instance


func _create_vertical_down_segment(_params: Dictionary) -> Node3D:
	var instance = SEGMENT_VERTICAL_DOWN.instantiate()
	_configure_cylinder_meshes(instance)
	return instance


func _configure_cylinder_meshes(root: Node3D) -> void:
	# Segment scenes are authored with 2.0m base length. Scale proportionally.
	var length_scale = segment_length / 2.0
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if not mesh_instance:
			continue
		if mesh_instance.mesh is CylinderMesh:
			var cylinder := (mesh_instance.mesh as CylinderMesh).duplicate()
			cylinder.top_radius = pipe_radius
			cylinder.bottom_radius = pipe_radius
			cylinder.height *= length_scale
			mesh_instance.mesh = cylinder
			mesh_instance.position *= length_scale
	
	_configure_collision_shapes(root, length_scale)


func _configure_collision_shapes(root: Node3D, length_scale: float) -> void:
	for node in root.find_children("*", "CollisionShape3D", true, false):
		var collision := node as CollisionShape3D
		if not collision or not collision.shape:
			continue
		
		if collision.shape is CylinderShape3D:
			var cylinder := (collision.shape as CylinderShape3D).duplicate()
			cylinder.radius = pipe_radius
			cylinder.height *= length_scale
			collision.shape = cylinder
			collision.position *= length_scale
		elif collision.shape is SphereShape3D:
			var sphere := (collision.shape as SphereShape3D).duplicate()
			sphere.radius = pipe_radius
			collision.shape = sphere
			collision.position *= length_scale

# =============================================================================
# LEGACY COMPATIBILITY
# =============================================================================

## Legacy API - generate pipes from code string
func generate_pipes(code: String) -> void:
	# Handle "bp:" prefix if present
	if code.begins_with("bp:"):
		code = code.substr(3)
	generate_from_code(code)

# =============================================================================
# GRID SYSTEM INTEGRATION
# =============================================================================

func _get_config_directory() -> String:
	return "res://algorithms/wavefunctions/big_pipe_system/configs"

func apply_grid_config(config: Dictionary) -> void:
	# Handle big pipe specific config
	if config.has("pipe_radius"):
		pipe_radius = config["pipe_radius"]
	if config.has("segment_length"):
		segment_length = config["segment_length"]

	# Call base class
	super.apply_grid_config(config)
