# TurtlePipeBase - Abstract base class for turtle-graphics pipe systems
# Provides shared cursor tracking, command parsing, and segment management
# Extend this class and override _create_segment() for specific pipe types
extends Node3D
class_name TurtlePipeBase

signal segment_created(segment: Node3D, segment_type: String)
signal build_started
signal build_completed

@export_category("Pipe Dimensions")
@export var pipe_radius: float = 0.1
@export var segment_length: float = 1.0

@export_category("Build Settings")
@export var auto_build: bool = true
@export_file("*.json") var config_path: String = ""

# Cursor state for turtle graphics
var cursor_pos: Vector3 = Vector3.ZERO
var cursor_basis: Basis = Basis.IDENTITY

# Segment tracking
var active_segments: Dictionary = {}  # id -> Node3D
var segment_count: int = 0

# Command registry - subclasses add their own commands
var _command_handlers: Dictionary = {}

# Anchor system for layout
var _anchors: Dictionary = {}  # name -> Vector3

func _ready() -> void:
	_register_base_commands()
	_register_custom_commands()
	if auto_build and config_path != "":
		load_config(config_path)

# =============================================================================
# COMMAND REGISTRATION
# =============================================================================

func _register_base_commands() -> void:
	# Direction commands - shared by all pipe types
	_command_handlers["f"] = _cmd_forward
	_command_handlers["forward"] = _cmd_forward
	_command_handlers["straight"] = _cmd_forward
	_command_handlers["l"] = _cmd_left
	_command_handlers["left"] = _cmd_left
	_command_handlers["r"] = _cmd_right
	_command_handlers["right"] = _cmd_right
	_command_handlers["u"] = _cmd_up
	_command_handlers["up"] = _cmd_up
	_command_handlers["d"] = _cmd_down
	_command_handlers["down"] = _cmd_down
	print("TurtlePipeBase: Registered %d commands: %s" % [_command_handlers.size(), _command_handlers.keys()])

## Override in subclass to register type-specific commands
func _register_custom_commands() -> void:
	pass

# =============================================================================
# CONFIG LOADING
# =============================================================================

func load_config(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("TurtlePipeBase: Failed to open config: %s" % path)
		return

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("TurtlePipeBase: JSON parse error: %s" % json.get_error_message())
		return

	load_config_from_dict(json.data)

func load_config_from_dict(data: Dictionary) -> void:
	# Load anchors if present
	if data.has("anchors"):
		for anchor_name in data["anchors"]:
			var pos = data["anchors"][anchor_name]
			if pos is Array and pos.size() >= 3:
				_anchors[anchor_name] = Vector3(pos[0], pos[1], pos[2])

	# Load layout settings
	if data.has("layout"):
		var layout = data["layout"]
		if layout.has("segment_length"):
			segment_length = layout["segment_length"]
		if layout.has("pipe_radius"):
			pipe_radius = layout["pipe_radius"]

	# Build from path code or paths array
	if data.has("path"):
		generate_from_code(data["path"])
	elif data.has("paths"):
		_build_from_paths(data["paths"])

func _build_from_paths(paths: Array) -> void:
	for path_def in paths:
		var from_anchor = path_def.get("from", "")
		var code = path_def.get("code", "")

		# Jump to start anchor if specified
		if from_anchor != "" and _anchors.has(from_anchor):
			cursor_pos = _anchors[from_anchor]

		# Generate path
		if code != "":
			_parse_and_execute(code)

# =============================================================================
# CODE PARSING AND EXECUTION
# =============================================================================

func generate_from_code(code: String) -> void:
	print("TurtlePipeBase: generate_from_code('%s'), handlers=%d" % [code, _command_handlers.size()])
	build_started.emit()
	clear_segments()
	reset_cursor()
	_parse_and_execute(code)
	build_completed.emit()

func _parse_and_execute(code: String) -> void:
	var commands = code.split(",")
	var i = 0

	while i < commands.size():
		var cmd = commands[i].strip_edges().to_lower()

		if cmd.is_empty():
			i += 1
			continue

		# Handle special commands
		if cmd.begins_with("@"):
			# Jump to anchor: @A
			var anchor_name = cmd.substr(1)
			if _anchors.has(anchor_name):
				cursor_pos = _anchors[anchor_name]
			else:
				push_warning("TurtlePipeBase: Unknown anchor '%s'" % anchor_name)
		elif cmd.begins_with(">"):
			# Auto-path to anchor: >B
			var anchor_name = cmd.substr(1)
			if _anchors.has(anchor_name):
				_auto_path_to(_anchors[anchor_name])
			else:
				push_warning("TurtlePipeBase: Unknown anchor '%s'" % anchor_name)
		elif cmd.begins_with("#"):
			# Repeat next command: #3
			var repeat_count = cmd.substr(1).to_int()
			if repeat_count > 0 and i + 1 < commands.size():
				var next_cmd = commands[i + 1].strip_edges().to_lower()
				for _j in range(repeat_count):
					_execute_command(next_cmd)
				i += 1  # Skip the repeated command
		elif _command_handlers.has(cmd):
			_execute_command(cmd)
		else:
			# Try subclass custom command
			if not _handle_custom_command(cmd):
				push_warning("TurtlePipeBase: Unknown command '%s'" % cmd)

		i += 1

func _execute_command(cmd: String) -> void:
	if _command_handlers.has(cmd):
		_command_handlers[cmd].call()

## Override in subclass for custom commands not in registry
func _handle_custom_command(_cmd: String) -> bool:
	return false

# =============================================================================
# BASE COMMANDS
# =============================================================================

func _cmd_forward() -> void:
	var segment = _create_segment("straight", {"length": segment_length})
	if segment:
		_place_segment(segment)
		_advance_cursor_forward(segment_length)

func _cmd_left() -> void:
	var segment = _create_segment("corner", {"axis": Vector3.UP, "angle": 90})
	if segment:
		_place_segment(segment)
		_advance_cursor_corner(Vector3.UP, 90)

func _cmd_right() -> void:
	var segment = _create_segment("corner", {"axis": Vector3.UP, "angle": -90})
	if segment:
		_place_segment(segment)
		_advance_cursor_corner(Vector3.UP, -90)

func _cmd_up() -> void:
	var segment = _create_segment("corner", {"axis": Vector3.RIGHT, "angle": 90})
	if segment:
		_place_segment(segment)
		_advance_cursor_corner(Vector3.RIGHT, 90)

func _cmd_down() -> void:
	var segment = _create_segment("corner", {"axis": Vector3.RIGHT, "angle": -90})
	if segment:
		_place_segment(segment)
		_advance_cursor_corner(Vector3.RIGHT, -90)

# =============================================================================
# SEGMENT CREATION (Override in subclass)
# =============================================================================

## Override this method to create type-specific segments
## Returns null if segment type is not supported
func _create_segment(_segment_type: String, _params: Dictionary) -> Node3D:
	push_error("TurtlePipeBase._create_segment() must be overridden in subclass")
	return null

func _place_segment(segment: Node3D) -> void:
	var seg_id = "seg_%d" % segment_count
	segment.name = seg_id
	segment.position = cursor_pos
	segment.transform.basis = cursor_basis
	add_child(segment)
	active_segments[seg_id] = segment
	segment_count += 1
	segment_created.emit(segment, segment.name)

# =============================================================================
# CURSOR MOVEMENT
# =============================================================================

func reset_cursor() -> void:
	cursor_pos = Vector3.ZERO
	cursor_basis = Basis.IDENTITY

func _advance_cursor_forward(length: float) -> void:
	var forward = cursor_basis.z
	cursor_pos += forward * length

func _advance_cursor_corner(axis: Vector3, angle_deg: float) -> void:
	var forward = cursor_basis.z
	var up = cursor_basis.y
	var right = cursor_basis.x
	var radius = segment_length

	if axis == Vector3.UP:
		if angle_deg > 0:  # Left
			cursor_pos += forward * radius - right * radius
			cursor_basis = cursor_basis.rotated(cursor_basis.y, deg_to_rad(90))
		else:  # Right
			cursor_pos += forward * radius + right * radius
			cursor_basis = cursor_basis.rotated(cursor_basis.y, deg_to_rad(-90))
	elif axis == Vector3.RIGHT:
		if angle_deg > 0:  # Up
			cursor_pos += forward * radius + up * radius
			cursor_basis = cursor_basis.rotated(cursor_basis.x, deg_to_rad(-90))
		else:  # Down
			cursor_pos += forward * radius - up * radius
			cursor_basis = cursor_basis.rotated(cursor_basis.x, deg_to_rad(90))

func _auto_path_to(target: Vector3) -> void:
	# Simple Manhattan-style auto-pathing
	var delta = target - cursor_pos
	var forward = cursor_basis.z
	var right = cursor_basis.x
	var up = cursor_basis.y

	# Project delta onto current axes
	var forward_dist = delta.dot(forward)
	var right_dist = delta.dot(right)
	var up_dist = delta.dot(up)

	# Move in order: forward, then horizontal turn, then vertical
	var threshold = segment_length * 0.5

	# Forward segments
	while forward_dist > threshold:
		_cmd_forward()
		forward_dist -= segment_length

	# Horizontal adjustment
	if abs(right_dist) > threshold:
		if right_dist > 0:
			_cmd_right()
		else:
			_cmd_left()
		# Continue forward after turn
		var remaining = abs(right_dist)
		while remaining > threshold:
			_cmd_forward()
			remaining -= segment_length

	# Vertical adjustment
	if abs(up_dist) > threshold:
		if up_dist > 0:
			_cmd_up()
		else:
			_cmd_down()
		# Continue forward after turn
		var remaining = abs(up_dist)
		while remaining > threshold:
			_cmd_forward()
			remaining -= segment_length

# =============================================================================
# UTILITY
# =============================================================================

func clear_segments() -> void:
	for child in get_children():
		child.queue_free()
	active_segments.clear()
	segment_count = 0

func set_anchor(name: String, pos: Vector3) -> void:
	_anchors[name] = pos

func get_anchor(name: String) -> Vector3:
	return _anchors.get(name, Vector3.ZERO)

func get_cursor_position() -> Vector3:
	return cursor_pos

func get_cursor_basis() -> Basis:
	return cursor_basis

## Called by grid system when placed on map
func apply_grid_config(config: Dictionary) -> void:
	if config.has("path"):
		generate_from_code(config["path"])
	if config.has("config"):
		var config_file = _get_config_directory() + "/%s.json" % config["config"]
		load_config(config_file)

## Override to specify where config files are located
func _get_config_directory() -> String:
	return "res://commons/primitives/pipes/configs"
