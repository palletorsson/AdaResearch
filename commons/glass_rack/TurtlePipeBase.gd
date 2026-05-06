# GlassRackPipeBase.gd - Turtle Graphics Pipe Building System for Glass Rack
# Base class for building 3D pipe structures using turtle-graphics commands
extends Node3D
class_name GlassRackPipeBase

signal build_complete
const PRESET_INDEX_FILE := "presets_index.json"

@export_group("Build Settings")
@export var auto_build: bool = true
@export var config_file: String = ""
@export var auto_snap_ports: bool = true  ## Run port-chain auto-connect after building
@export var show_port_debug: bool = false  ## Show red/green port spheres

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
	
	if auto_snap_ports:
		var fixes := auto_connect_segments(true, true)
		if fixes > 0:
			print("TurtlePipeBase: auto-connect snapped %d joints" % fixes)
	
	if show_port_debug:
		_add_port_debug_visualization()
	
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
			if seg_data.has("id"):
				segment.name = seg_data["id"]
			_place_segment(segment)
			_advance_cursor_from_segment(segment, params)
	
	if auto_snap_ports:
		var fixes := auto_connect_segments(true, true)
		if fixes > 0:
			print("TurtlePipeBase: auto-connect snapped %d joints (segments mode)" % fixes)
	
	if show_port_debug:
		_add_port_debug_visualization()
	
	build_complete.emit()


func _advance_cursor_from_segment(segment: Node3D, params: Dictionary) -> void:
	# Follow declared segment ports when available so bends/junctions advance correctly.
	# Ports are AUTHORITATIVE — the out-port direction sets the cursor direction.
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


# =============================================================================
# PORT-CHAIN AUTO-CONNECT (post-pass)
# =============================================================================
# After all segments are placed, snap each segment so its "in" port aligns
# with the previous segment's "out" port. Fixes accumulated cursor drift
# and handles direction changes that the turtle got wrong.

func auto_connect_segments(snap_position: bool = true, snap_rotation: bool = true) -> int:
	## Runs a post-pass over all placed segments, snapping each segment's
	## "in" port to the previous segment's "out" port.
	## Returns the number of connections fixed.
	if not _segments_root:
		return 0
	
	var children := _segments_root.get_children()
	if children.size() < 2:
		return 0
	
	var fixes := 0
	
	for i in range(1, children.size()):
		var prev_seg: Node3D = children[i - 1]
		var curr_seg: Node3D = children[i]
		
		if not prev_seg.has_meta("ports") or not curr_seg.has_meta("ports"):
			continue
		
		var prev_ports: Dictionary = prev_seg.get_meta("ports", {})
		var curr_ports: Dictionary = curr_seg.get_meta("ports", {})
		
		# Find the output port of previous segment
		var out_name := _pick_primary_output_port(prev_ports)
		if out_name == "" or not curr_ports.has("in"):
			continue
		
		var prev_out: Dictionary = prev_ports[out_name]
		var curr_in: Dictionary = curr_ports["in"]
		
		if not (prev_out.get("position") is Vector3) or not (curr_in.get("position") is Vector3):
			continue
		
		# World-space position of previous segment's output port
		var _prev_out_pos: Vector3 = prev_out["position"]
		var _curr_in_pos: Vector3 = curr_in["position"]
		var prev_out_world: Vector3 = prev_seg.global_transform * _prev_out_pos
		# World-space position of current segment's input port
		var curr_in_world: Vector3 = curr_seg.global_transform * _curr_in_pos
		
		var delta := prev_out_world - curr_in_world
		
		if snap_position and delta.length() > 0.0001:
			curr_seg.global_position += delta
			fixes += 1
		
		if snap_rotation:
			# Align current segment so its in-port direction faces the
			# opposite of the previous segment's out-port direction
			var prev_out_dir_world: Vector3 = (prev_seg.global_transform.basis * prev_out.get("direction", Vector3.FORWARD)).normalized()
			var curr_in_dir_world: Vector3 = (curr_seg.global_transform.basis * curr_in.get("direction", Vector3.BACK)).normalized()
			
			# The in-port direction should point opposite to the out-port direction
			# (they face each other). If curr_in faces BACK and prev_out faces FORWARD,
			# they're aligned when -curr_in_dir == prev_out_dir
			var desired_in_dir := -prev_out_dir_world
			var actual_in_dir := curr_in_dir_world
			
			if desired_in_dir.dot(actual_in_dir) < 0.999:
				# Compute rotation from actual to desired
				var cross := actual_in_dir.cross(desired_in_dir)
				if cross.length() > 0.0001:
					var angle := actual_in_dir.angle_to(desired_in_dir)
					var axis := cross.normalized()
					# Rotate around the in-port world position
					var in_pos_v3: Vector3 = curr_in["position"]
					var pivot: Vector3 = curr_seg.global_position + curr_seg.global_transform.basis * in_pos_v3
					var rot_basis: Basis = Basis(axis, angle)
					var offset: Vector3 = curr_seg.global_position - pivot
					curr_seg.global_position = pivot + rot_basis * offset
					curr_seg.global_transform.basis = rot_basis * curr_seg.global_transform.basis
					# Re-snap position after rotation
					var prev_out_pos_v3: Vector3 = prev_out["position"]
					var curr_in_pos_v3: Vector3 = curr_in["position"]
					prev_out_world = prev_seg.global_transform * prev_out_pos_v3
					curr_in_world = curr_seg.global_transform * curr_in_pos_v3
					curr_seg.global_position += prev_out_world - curr_in_world
					fixes += 1
	
	return fixes


func get_connection_gaps() -> Array[Dictionary]:
	## Returns info about gaps between connected segments.
	## Useful for debugging which connections are broken.
	var gaps: Array[Dictionary] = []
	if not _segments_root:
		return gaps
	
	var children := _segments_root.get_children()
	for i in range(1, children.size()):
		var prev_seg: Node3D = children[i - 1]
		var curr_seg: Node3D = children[i]
		
		if not prev_seg.has_meta("ports") or not curr_seg.has_meta("ports"):
			continue
		
		var prev_ports: Dictionary = prev_seg.get_meta("ports", {})
		var curr_ports: Dictionary = curr_seg.get_meta("ports", {})
		var out_name := _pick_primary_output_port(prev_ports)
		if out_name == "" or not curr_ports.has("in"):
			continue
		
		var _po_pos: Vector3 = prev_ports[out_name]["position"]
		var _ci_pos: Vector3 = curr_ports["in"]["position"]
		var prev_out_world: Vector3 = prev_seg.global_transform * _po_pos
		var curr_in_world: Vector3 = curr_seg.global_transform * _ci_pos
		var gap := prev_out_world.distance_to(curr_in_world)
		
		gaps.append({
			"index": i,
			"gap": gap,
			"prev_name": prev_seg.name,
			"curr_name": curr_seg.name,
			"prev_out_pos": prev_out_world,
			"curr_in_pos": curr_in_world,
		})
	
	return gaps


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


# =============================================================================
# DEBUG PORT VISUALIZATION
# =============================================================================

func _add_port_debug_visualization() -> void:
	## Add colored spheres at every port on every segment.
	## Red = input, Green = output, Yellow = branch/side ports
	## Also draws thin lines between connected ports to show gaps.
	if not _segments_root:
		return
	
	# Remove old debug viz
	var old_viz := get_node_or_null("PortDebug")
	if old_viz:
		old_viz.queue_free()
	
	var debug_root := Node3D.new()
	debug_root.name = "PortDebug"
	add_child(debug_root)
	
	var children := _segments_root.get_children()
	
	for seg in children:
		if not seg.has_meta("ports"):
			continue
		var ports: Dictionary = seg.get_meta("ports", {})
		
		for port_name: String in ports:
			var port: Dictionary = ports[port_name]
			var pos_local: Vector3 = port.get("position", Vector3.ZERO)
			var dir_local: Vector3 = port.get("direction", Vector3.FORWARD)
			var radius: float = port.get("radius", 0.01)
			
			# World position
			var pos_world: Vector3 = seg.global_transform * pos_local
			var dir_world: Vector3 = (seg.global_transform.basis * dir_local).normalized()
			
			# Color by port type
			var color: Color
			if port_name == "in":
				color = Color(1, 0.2, 0.2, 0.7)  # Red
			elif port_name == "out" or port_name == "out1":
				color = Color(0.2, 1, 0.2, 0.7)  # Green
			else:
				color = Color(1, 1, 0.2, 0.7)  # Yellow for branches
			
			# Sphere at port position
			var sphere_mesh := SphereMesh.new()
			sphere_mesh.radius = radius * 2.5
			sphere_mesh.height = radius * 5.0
			var sphere_inst := MeshInstance3D.new()
			sphere_inst.mesh = sphere_mesh
			var mat := StandardMaterial3D.new()
			mat.albedo_color = color
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			sphere_inst.material_override = mat
			sphere_inst.global_position = pos_world
			sphere_inst.name = "%s_%s" % [seg.name, port_name]
			debug_root.add_child(sphere_inst)
			
			# Direction arrow (small cylinder pointing out)
			var arrow_len := radius * 8.0
			var arrow := MeshInstance3D.new()
			var arrow_cyl := CylinderMesh.new()
			arrow_cyl.top_radius = radius * 0.5
			arrow_cyl.bottom_radius = radius * 1.5
			arrow_cyl.height = arrow_len
			arrow.mesh = arrow_cyl
			var arrow_mat := StandardMaterial3D.new()
			arrow_mat.albedo_color = color
			arrow_mat.albedo_color.a = 0.9
			arrow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			arrow.material_override = arrow_mat
			# Orient arrow along direction
			arrow.global_position = pos_world + dir_world * arrow_len * 0.5
			# Look rotation: cylinder default is Y-up, we want it along dir_world
			if dir_world.length() > 0.001:
				var up := Vector3.UP
				if abs(dir_world.dot(up)) > 0.99:
					up = Vector3.RIGHT
				arrow.look_at(arrow.global_position + dir_world, up)
				arrow.rotate_object_local(Vector3.RIGHT, PI / 2)
			debug_root.add_child(arrow)
	
	# Draw gap indicators between consecutive segments
	for i in range(1, children.size()):
		var prev_seg: Node3D = children[i - 1]
		var curr_seg: Node3D = children[i]
		if not prev_seg.has_meta("ports") or not curr_seg.has_meta("ports"):
			continue
		
		var prev_ports: Dictionary = prev_seg.get_meta("ports", {})
		var curr_ports: Dictionary = curr_seg.get_meta("ports", {})
		var out_name := _pick_primary_output_port(prev_ports)
		if out_name == "" or not curr_ports.has("in"):
			continue
		
		var _dbg_po_pos: Vector3 = prev_ports[out_name]["position"]
		var _dbg_ci_pos: Vector3 = curr_ports["in"]["position"]
		var prev_out_world: Vector3 = prev_seg.global_transform * _dbg_po_pos
		var curr_in_world: Vector3 = curr_seg.global_transform * _dbg_ci_pos
		var gap := prev_out_world.distance_to(curr_in_world)
		
		if gap > 0.001:
			# Gap indicator: red line between disconnected ports
			var mid := (prev_out_world + curr_in_world) * 0.5
			var line := MeshInstance3D.new()
			var line_cyl := CylinderMesh.new()
			line_cyl.top_radius = 0.002
			line_cyl.bottom_radius = 0.002
			line_cyl.height = gap
			line.mesh = line_cyl
			var line_mat := StandardMaterial3D.new()
			line_mat.albedo_color = Color(1, 0, 0, 0.9)
			line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			line.material_override = line_mat
			line.global_position = mid
			# Orient along gap direction
			var gap_dir := (curr_in_world - prev_out_world).normalized()
			if gap_dir.length() > 0.001:
				var up := Vector3.UP
				if abs(gap_dir.dot(up)) > 0.99:
					up = Vector3.RIGHT
				line.look_at(line.global_position + gap_dir, up)
				line.rotate_object_local(Vector3.RIGHT, PI / 2)
			line.name = "Gap_%d_%.3f" % [i, gap]
			debug_root.add_child(line)


func toggle_port_debug() -> void:
	## Toggle port debug visualization on/off
	show_port_debug = not show_port_debug
	var old_viz := get_node_or_null("PortDebug")
	if show_port_debug:
		_add_port_debug_visualization()
	elif old_viz:
		old_viz.queue_free()


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
