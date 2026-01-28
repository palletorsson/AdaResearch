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

	var col = instance.get_node_or_null("CollisionShape3D")
	if col and col.shape is CylinderShape3D:
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
