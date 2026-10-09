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
@export_enum("glass", "drain", "tube", "pipe", "cable", "custom") var pipe_type: String = "glass"
@export var custom_pipe_scene: PackedScene

# Layout data
var anchors: Dictionary = {}  # name -> Vector3
var paths: Array = []  # Array of path definitions
var pipe_systems: Dictionary = {}  # path_id -> renderer Node3D
var anchor_markers: Dictionary = {}  # name -> MeshInstance3D
var dimensions: Dictionary = {}
var _loading := false
var _next_id := 0
const RUN = preload("res://commons/primitives/pipes/swept_run.gd")

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

	if json.data is Dictionary: load_layout_from_dict(json.data)

func load_layout_from_dict(data: Dictionary) -> void:
	clear_layout()
	_loading = true
	dimensions = data.get("layout",{}).duplicate(true)

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
		paths = data["paths"].duplicate(true)

	# Build the layout
	_loading = false
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
		path_def["id"] = path_id
		_build_path(path_id, path_def)

	layout_built.emit()

func _build_path(path_id: String, path_def: Dictionary) -> void:
	var from_name: String = path_def.get("from","")
	var to_name: String = path_def.get("to","")
	for anchor in [from_name,to_name]:
		if not anchor.is_empty() and not anchors.has(anchor):
			push_warning("PipeLayout: missing anchor '%s' for '%s'" % [anchor,path_id]); return
	var origin: Vector3 = anchors.get(from_name,Vector3.ZERO)
	var code: String = path_def.get("code","")
	var kind: String = path_def.get("kind",pipe_type)
	var radius: float = path_def.get("pipe_radius",dimensions.get("pipe_radius",0.8 if kind == "drain" else 0.02 if kind == "glass" else 0.08))
	var system: Node3D
	if code.is_empty() or kind in ["tube","pipe","cable"]:
		var points := PackedVector3Array()
		for point in path_def.get("points",[]):
			if point is Vector3: points.append(point)
			elif point is Array and point.size() >= 3: points.append(Vector3(point[0],point[1],point[2]))
		if points.is_empty() and not to_name.is_empty(): points = PackedVector3Array([origin,anchors[to_name]])
		if points.size() < 2: return
		if not from_name.is_empty(): points[0] = origin
		if not to_name.is_empty(): points[-1] = anchors[to_name]
		system = RUN.new(); add_child(system)
		system.configure(points,radius,"pipe" if kind in ["glass","drain"] else kind,path_def.get("sides",16),Color(path_def.get("colour","d877a2")),path_def.get("sag",0.5))
	else:
		match kind:
			"glass": system = GLASS_PIPE_SCRIPT.new()
			"drain": system = BIG_PIPE_SCRIPT.new()
			"custom":
				if custom_pipe_scene: system = custom_pipe_scene.instantiate()
		if system == null: return
		if "auto_build" in system: system.auto_build = false
		add_child(system) # Glass sets its defaults in _ready; dimensions follow it.
		system.position = origin
		if "pipe_radius" in system: system.pipe_radius = radius
		if "segment_length" in system: system.segment_length = path_def.get("segment_length",dimensions.get("segment_length",system.segment_length))
		if not system.has_method("generate_from_code"):
			remove_child(system); system.queue_free(); return
		system.generate_from_code(code)
		# Neither current renderer accepts @anchor/>anchor tokens. Layout owns the
		# anchor transform and the explicit final connector instead of inventing APIs.
		if not to_name.is_empty():
			var endpoint: Vector3 = system.get("cursor_pos") if kind == "glass" else system.get("_pos") if kind == "drain" else Vector3.ZERO
			var valid_endpoint := kind in ["glass","drain"]
			if kind == "custom":
				var ports: Dictionary = system.get_meta("ports",{})
				valid_endpoint = ports.has("out") and ports.out.get("position") is Vector3
				if valid_endpoint: endpoint = ports.out.position
			if valid_endpoint:
				var connector = RUN.new(); system.add_child(connector)
				connector.configure(PackedVector3Array([endpoint,anchors[to_name]-origin]),radius,"pipe")
			else: push_warning("PipeLayout: custom renderer needs an out port to connect to an anchor")
	if pipe_systems.has(path_id):
		remove_child(pipe_systems[path_id]); pipe_systems[path_id].queue_free()
	system.name = path_id; pipe_systems[path_id] = system
	path_completed.emit(path_id)

# =============================================================================
# ANCHOR MANAGEMENT
# =============================================================================

func set_anchor(anchor_name: String, pos: Vector3) -> void:
	anchors[anchor_name] = pos
	if show_anchors:
		_update_anchor_marker(anchor_name)
	if not _loading:
		for path in paths:
			if path.get("from","") == anchor_name or path.get("to","") == anchor_name:
				_build_path(path.id,path)

func get_anchor(anchor_name: String) -> Vector3:
	return anchors.get(anchor_name, Vector3.ZERO)

func remove_anchor(anchor_name: String) -> void:
	for path in paths.duplicate():
		if path.get("from","") == anchor_name or path.get("to","") == anchor_name: remove_path(path.id)
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
	path_def = path_def.duplicate(true)
	while pipe_systems.has("path_%d" % _next_id): _next_id += 1
	var path_id = path_def.get("id", "path_%d" % _next_id)
	_next_id += 1
	remove_path(path_id)
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
		remove_child(pipe_systems[path_id])
		pipe_systems[path_id].queue_free()
		pipe_systems.erase(path_id)

func get_pipe_system(path_id: String) -> Node3D:
	return pipe_systems.get(path_id, null)

# =============================================================================
# UTILITY
# =============================================================================

func clear_layout() -> void:
	_clear_pipe_systems()
	anchors.clear()
	paths.clear()
	dimensions.clear()
	_update_anchor_markers()

func _clear_pipe_systems() -> void:
	for system in pipe_systems.values():
		remove_child(system)
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
	build_layout()

# =============================================================================
# QUICK BUILD API
# =============================================================================

## Quick method to build a simple linear pipe from code
static func quick_build(parent: Node3D, code: String, type: String = "glass") -> Node3D:
	var layout = PipeLayout.new()
	layout.pipe_type = type
	layout.auto_build = false
	parent.add_child(layout)

	layout.add_path({"code": code})

	# Return the first pipe system
	if layout.pipe_systems.size() > 0:
		return layout.pipe_systems.values()[0]
	return null
