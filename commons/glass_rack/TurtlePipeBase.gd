# GlassRackPipeBase.gd - Turtle Graphics Pipe Building System for Glass Rack
# Base class for building 3D pipe structures using turtle-graphics commands
extends Node3D
class_name GlassRackPipeBase

signal build_complete
const PRESET_INDEX_FILE := "presets_index.json"

@export_group("Build Settings")
@export var auto_build: bool = true
@export var config_file: String = ""

@export_group("Pipe Dimensions")
@export var pipe_radius: float = 0.02
@export var segment_length: float = 0.2

# Turtle state
var cursor_pos: Vector3 = Vector3.ZERO
var cursor_forward: Vector3 = Vector3.FORWARD
var cursor_up: Vector3 = Vector3.UP
var cursor_right: Vector3 = Vector3.RIGHT

# Build state
var _segments_root: Node3D = null
var _command_handlers: Dictionary = {}
var _built: bool = false

func _ready() -> void:
	_register_base_commands()
	_register_custom_commands()
	
	if auto_build and config_file != "":
		load_config(config_file)

# =============================================================================
# COMMAND REGISTRATION
# =============================================================================

func _register_base_commands() -> void:
	# Movement commands
	_command_handlers["f"] = _cmd_forward
	_command_handlers["forward"] = _cmd_forward
	_command_handlers["b"] = _cmd_backward
	_command_handlers["backward"] = _cmd_backward
	
	# Rotation commands
	_command_handlers["u"] = _cmd_up
	_command_handlers["up"] = _cmd_up
	_command_handlers["d"] = _cmd_down
	_command_handlers["down"] = _cmd_down
	_command_handlers["l"] = _cmd_left
	_command_handlers["left"] = _cmd_left
	_command_handlers["r"] = _cmd_right
	_command_handlers["right"] = _cmd_right
	
	# Segment commands
	_command_handlers["straight"] = _cmd_straight

## Override in subclass to add custom commands
func _register_custom_commands() -> void:
	pass

# =============================================================================
# BASE COMMANDS
# =============================================================================

func _cmd_forward() -> void:
	var segment = _create_segment("straight", {"length": segment_length})
	if segment:
		_place_segment(segment)
	_advance_cursor_forward(segment_length)

func _cmd_backward() -> void:
	_advance_cursor_forward(-segment_length)

func _cmd_straight() -> void:
	_cmd_forward()

func _cmd_up() -> void:
	_rotate_cursor_pitch(-PI / 2)

func _cmd_down() -> void:
	_rotate_cursor_pitch(PI / 2)

func _cmd_left() -> void:
	_rotate_cursor_yaw(PI / 2)

func _cmd_right() -> void:
	_rotate_cursor_yaw(-PI / 2)

# =============================================================================
# CURSOR MANIPULATION
# =============================================================================

func _advance_cursor_forward(distance: float) -> void:
	cursor_pos += cursor_forward * distance

func _rotate_cursor_pitch(angle: float) -> void:
	# Rotate around the right axis
	var rotation = Basis(cursor_right, angle)
	cursor_forward = rotation * cursor_forward
	cursor_up = rotation * cursor_up

func _rotate_cursor_yaw(angle: float) -> void:
	# Rotate around the up axis
	var rotation = Basis(cursor_up, angle)
	cursor_forward = rotation * cursor_forward
	cursor_right = rotation * cursor_right

func _rotate_cursor_roll(angle: float) -> void:
	# Rotate around the forward axis
	var rotation = Basis(cursor_forward, angle)
	cursor_up = rotation * cursor_up
	cursor_right = rotation * cursor_right

func _get_cursor_transform() -> Transform3D:
	var basis = Basis(cursor_right, cursor_up, -cursor_forward)
	return Transform3D(basis, cursor_pos)

func _reset_cursor() -> void:
	cursor_pos = Vector3.ZERO
	cursor_forward = Vector3.FORWARD
	cursor_up = Vector3.UP
	cursor_right = Vector3.RIGHT

# =============================================================================
# SEGMENT PLACEMENT
# =============================================================================

func _place_segment(segment: Node3D) -> void:
	if not _segments_root:
		_segments_root = Node3D.new()
		_segments_root.name = "Segments"
		add_child(_segments_root)
	
	segment.transform = _get_cursor_transform()
	_segments_root.add_child(segment)

## Override in subclass to create specific segment types
func _create_segment(segment_type: String, params: Dictionary) -> Node3D:
	push_warning("TurtlePipeBase._create_segment not implemented for type: %s" % segment_type)
	return null

# =============================================================================
# PATH PARSING
# =============================================================================

func generate_from_code(code: String) -> void:
	_clear_segments()
	_reset_cursor()
	
	var commands = code.split(",")
	for cmd in commands:
		cmd = cmd.strip_edges().to_lower()
		if cmd.is_empty():
			continue
		
		if _command_handlers.has(cmd):
			_command_handlers[cmd].call()
		else:
			push_warning("TurtlePipeBase: Unknown command: %s" % cmd)
	
	build_complete.emit()

func _clear_segments() -> void:
	if _segments_root:
		_segments_root.queue_free()
		_segments_root = null
	_built = false

# =============================================================================
# CONFIG LOADING
# =============================================================================

func load_config(path: String) -> void:
	var full_path = path
	if not path.begins_with("res://"):
		full_path = _get_config_directory().path_join(path)
		if not full_path.ends_with(".json"):
			full_path += ".json"
	
	if not FileAccess.file_exists(full_path):
		push_error("TurtlePipeBase: Config file not found: %s" % full_path)
		return
	
	var file = FileAccess.open(full_path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("TurtlePipeBase: Failed to parse config: %s" % json.get_error_message())
		return
	
	load_config_from_dict(json.data)

func load_config_from_dict(data: Dictionary) -> void:
	# Apply layout settings
	if data.has("layout"):
		var layout = data["layout"]
		if layout.has("segment_length"):
			segment_length = layout["segment_length"]
		if layout.has("tube_radius"):
			pipe_radius = layout["tube_radius"]
	
	# Build from path string
	if data.has("path") and data["path"] is String:
		generate_from_code(data["path"])
	# Or build from segments array
	elif data.has("segments") and data["segments"] is Array:
		_build_from_segments(data["segments"])
	
	_built = true

func _build_from_segments(segments: Array) -> void:
	_clear_segments()
	_reset_cursor()
	
	for seg_data in segments:
		if not seg_data is Dictionary:
			continue
		
		var seg_type = seg_data.get("type", "straight")
		var params = seg_data.get("params", {})
		
		# Handle explicit position
		if seg_data.has("position"):
			var pos = seg_data["position"]
			cursor_pos = Vector3(pos[0], pos[1], pos[2])
		
		var segment = _create_segment(seg_type, params)
		if segment:
			_place_segment(segment)
			_advance_cursor_from_segment(segment, params)
	
	build_complete.emit()


func _advance_cursor_from_segment(segment: Node3D, params: Dictionary) -> void:
	# Follow declared segment ports when available so bends/junctions advance correctly.
	if segment and segment.has_meta("ports"):
		var ports = segment.get_meta("ports", {})
		if ports is Dictionary and ports.has("in"):
			var out_name = _pick_primary_output_port(ports)
			if out_name != "":
				var in_port = ports.get("in", {})
				var out_port = ports.get(out_name, {})
				if in_port is Dictionary and out_port is Dictionary:
					var in_pos = in_port.get("position", null)
					var out_pos = out_port.get("position", null)
					if in_pos is Vector3 and out_pos is Vector3:
						var basis = _get_cursor_transform().basis
						var local_delta: Vector3 = out_pos - in_pos
						cursor_pos += basis * local_delta
						var out_dir_local = out_port.get("direction", null)
						if out_dir_local is Vector3:
							_set_cursor_forward((basis * out_dir_local).normalized())
						return
	
	var advance = params.get("advance", params.get("length", params.get("height", segment_length)))
	_advance_cursor_forward(float(advance))


func _pick_primary_output_port(ports: Dictionary) -> String:
	for candidate in ["out", "out1", "branch", "right", "left", "out2"]:
		if ports.has(candidate):
			return candidate
	for key in ports.keys():
		if key != "in":
			return str(key)
	return ""


func _set_cursor_forward(new_forward: Vector3) -> void:
	if new_forward.length_squared() < 0.0001:
		return
	
	cursor_forward = new_forward.normalized()
	var reference_up = cursor_up
	if abs(cursor_forward.dot(reference_up)) > 0.99:
		reference_up = Vector3.UP
		if abs(cursor_forward.dot(reference_up)) > 0.99:
			reference_up = Vector3.RIGHT
	
	cursor_right = reference_up.cross(cursor_forward).normalized()
	cursor_up = cursor_forward.cross(cursor_right).normalized()


func _load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return {}
	return json.data if json.data is Dictionary else {}


func list_presets() -> Array[Dictionary]:
	var index_path = _get_config_directory().path_join(PRESET_INDEX_FILE)
	var index_data = _load_json_file(index_path)
	var presets: Array[Dictionary] = []
	
	if not index_data.is_empty():
		var indexed = index_data.get("presets", [])
		if indexed is Array:
			for entry in indexed:
				if entry is Dictionary:
					presets.append(entry)
			return presets
	
	var dir = DirAccess.open(_get_config_directory())
	if not dir:
		return presets
	
	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".json") and entry != PRESET_INDEX_FILE:
			presets.append({
				"id": entry.trim_suffix(".json"),
				"file": entry
			})
		entry = dir.get_next()
	dir.list_dir_end()
	return presets


func has_preset(preset_id: String) -> bool:
	for preset in list_presets():
		if preset.get("id", "") == preset_id:
			return true
	return false


func get_preset_count() -> int:
	return list_presets().size()


func load_preset(preset_id: String) -> bool:
	for preset in list_presets():
		if preset.get("id", "") == preset_id:
			var file_name = preset.get("file", "")
			if file_name == "":
				file_name = preset_id + ".json"
			load_config(file_name)
			return true
	return false


func _get_config_directory() -> String:
	return "res://commons/glass_rack/configs"

# =============================================================================
# GRID SYSTEM INTEGRATION
# =============================================================================

func apply_grid_config(config: Dictionary) -> void:
	if config.has("segment_length"):
		segment_length = config["segment_length"]
	if config.has("pipe_radius"):
		pipe_radius = config["pipe_radius"]
	if config.has("path"):
		generate_from_code(config["path"])
	elif config.has("config_file"):
		load_config(config["config_file"])
