# PipeLayout - High-level controller for pipe network layouts
# Manages multiple pipe systems, anchors, and path connections
# Supports JSON-based layout definitions with anchor points
extends Node3D
class_name PipeLayout

signal layout_built
signal path_completed(path_id: String)

@export_category("Layout Settings")
@export_file("*.json") var layout_config_path: String = ""
@export var auto_build: bool = true
@export var show_anchors: bool = false
@export var anchor_color: Color = Color(1.0, 0.5, 0.0, 0.6)

@export_category("Pipe Type")
@export_enum("glass", "drain", "custom") var pipe_type: String = "glass"
@export var custom_pipe_scene: PackedScene

# Layout data
var anchors: Dictionary = {}  # name -> Vector3
var paths: Array = []  # Array of path definitions
var pipe_systems: Dictionary = {}  # path_id -> TurtlePipeBase instance
var anchor_markers: Dictionary = {}  # name -> MeshInstance3D

# Pipe system references
const GLASS_PIPE_SCRIPT = preload("res://commons/glass_rack/GlassRackController.gd")
const BIG_PIPE_SCRIPT = preload("res://algorithms/wavefunctions/big_pipe_system/big_pipe_system.gd")

func _ready() -> void:
	if auto_build and layout_config_path != "":
		load_layout(layout_config_path)

# =============================================================================
# LAYOUT LOADING
# =============================================================================

func load_layout(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("PipeLayout: Failed to open layout: %s" % path)
		return

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("PipeLayout: JSON parse error: %s" % json.get_error_message())
		return

	load_layout_from_dict(json.data)

func load_layout_from_dict(data: Dictionary) -> void:
	clear_layout()

	# Load layout settings
	if data.has("settings"):
		var settings = data["settings"]
		if settings.has("pipe_type"):
			pipe_type = settings["pipe_type"]
		if settings.has("show_anchors"):
			show_anchors = settings["show_anchors"]

	# Load anchors
	if data.has("anchors"):
		for anchor_name in data["anchors"]:
			var pos = data["anchors"][anchor_name]
			if pos is Array and pos.size() >= 3:
				set_anchor(anchor_name, Vector3(pos[0], pos[1], pos[2]))

	# Load paths
	if data.has("paths"):
		paths = data["paths"]

	# Build the layout
	build_layout()

# =============================================================================
# BUILDING
# =============================================================================

func build_layout() -> void:
	_clear_pipe_systems()
	_update_anchor_markers()

	for i in range(paths.size()):
		var path_def = paths[i]
		var path_id = path_def.get("id", "path_%d" % i)
		_build_path(path_id, path_def)

	layout_built.emit()

func _build_path(path_id: String, path_def: Dictionary) -> void:
	var pipe_system = _create_pipe_system()
	if not pipe_system:
		return

	pipe_system.name = path_id
	add_child(pipe_system)
	pipe_systems[path_id] = pipe_system

	# Pass anchors to pipe system
	for anchor_name in anchors:
		pipe_system.set_anchor(anchor_name, anchors[anchor_name])

	# Configure dimensions from path definition
	if path_def.has("segment_length"):
		pipe_system.segment_length = path_def["segment_length"]
	if path_def.has("pipe_radius"):
		pipe_system.pipe_radius = path_def["pipe_radius"]

	# Build the code
	var code = ""
	var from_anchor = path_def.get("from", "")
	var to_anchor = path_def.get("to", "")
	var path_code = path_def.get("code", "")

	# Construct full code with anchors
	if from_anchor != "":
		code = "@" + from_anchor
		if path_code != "":
			code += "," + path_code
	else:
		code = path_code

	if to_anchor != "" and path_code == "":
		# Auto-path if no explicit code given
		if code != "":
			code += ","
		code += ">" + to_anchor

	if code != "":
		pipe_system.generate_from_code(code)

	path_completed.emit(path_id)

func _create_pipe_system() -> TurtlePipeBase:
	var system: TurtlePipeBase

	match pipe_type:
		"glass":
			system = Node3D.new()
			system.set_script(GLASS_PIPE_SCRIPT)
		"drain":
			system = Node3D.new()
			system.set_script(BIG_PIPE_SCRIPT)
		"custom":
			if custom_pipe_scene:
				system = custom_pipe_scene.instantiate()

	return system

# =============================================================================
# ANCHOR MANAGEMENT
# =============================================================================

func set_anchor(anchor_name: String, pos: Vector3) -> void:
	anchors[anchor_name] = pos
	if show_anchors:
		_update_anchor_marker(anchor_name)

func get_anchor(anchor_name: String) -> Vector3:
	return anchors.get(anchor_name, Vector3.ZERO)

func remove_anchor(anchor_name: String) -> void:
	anchors.erase(anchor_name)
	if anchor_markers.has(anchor_name):
		anchor_markers[anchor_name].queue_free()
		anchor_markers.erase(anchor_name)

func _update_anchor_markers() -> void:
	# Clear old markers
	for marker in anchor_markers.values():
		marker.queue_free()
	anchor_markers.clear()

	if not show_anchors:
		return

	# Create new markers
	for anchor_name in anchors:
		_update_anchor_marker(anchor_name)

func _update_anchor_marker(anchor_name: String) -> void:
	if not show_anchors:
		return

	var marker: MeshInstance3D
	if anchor_markers.has(anchor_name):
		marker = anchor_markers[anchor_name]
	else:
		marker = MeshInstance3D.new()
		marker.name = "Anchor_" + anchor_name
		var sphere = SphereMesh.new()
		sphere.radius = 0.1
		sphere.height = 0.2
		marker.mesh = sphere

		var material = StandardMaterial3D.new()
		material.albedo_color = anchor_color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission_enabled = true
		material.emission = anchor_color
		material.emission_energy_multiplier = 0.5
		marker.material_override = material

		# Add label
		var label = Label3D.new()
		label.name = "Label"
		label.text = anchor_name
		label.font_size = 32
		label.pixel_size = 0.005
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(0, 0.2, 0)
		label.modulate = Color.WHITE
		marker.add_child(label)

		add_child(marker)
		anchor_markers[anchor_name] = marker

	marker.position = anchors[anchor_name]

# =============================================================================
# PATH MANAGEMENT
# =============================================================================

func add_path(path_def: Dictionary) -> String:
	var path_id = path_def.get("id", "path_%d" % paths.size())
	path_def["id"] = path_id
	paths.append(path_def)
	_build_path(path_id, path_def)
	return path_id

func remove_path(path_id: String) -> void:
	# Remove from paths array
	for i in range(paths.size() - 1, -1, -1):
		if paths[i].get("id", "") == path_id:
			paths.remove_at(i)
			break

	# Remove pipe system
	if pipe_systems.has(path_id):
		pipe_systems[path_id].queue_free()
		pipe_systems.erase(path_id)

func get_pipe_system(path_id: String) -> TurtlePipeBase:
	return pipe_systems.get(path_id, null)

# =============================================================================
# UTILITY
# =============================================================================

func clear_layout() -> void:
	_clear_pipe_systems()
	anchors.clear()
	paths.clear()
	_update_anchor_markers()

func _clear_pipe_systems() -> void:
	for system in pipe_systems.values():
		system.queue_free()
	pipe_systems.clear()

## Called by grid system when placed on map
func apply_grid_config(config: Dictionary) -> void:
	if config.has("layout"):
		var layout_file = "res://commons/primitives/pipes/layouts/%s.json" % config["layout"]
		load_layout(layout_file)
	if config.has("pipe_type"):
		pipe_type = config["pipe_type"]
	if config.has("show_anchors"):
		show_anchors = config["show_anchors"]

# =============================================================================
# QUICK BUILD API
# =============================================================================

## Quick method to build a simple linear pipe from code
static func quick_build(parent: Node3D, code: String, type: String = "glass") -> TurtlePipeBase:
	var layout = PipeLayout.new()
	layout.pipe_type = type
	layout.auto_build = false
	parent.add_child(layout)

	layout.add_path({"code": code})

	# Return the first pipe system
	if layout.pipe_systems.size() > 0:
		return layout.pipe_systems.values()[0]
	return null
