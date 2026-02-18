@tool
extends Node3D

## Demo gallery for Big Pipe System presets.
## Run this scene to see all pipe configurations.
##
## Controls:
##   1-8         Select preset by number
##   Left/Right  Prev/next preset
##   D           Toggle segment bounding boxes
##   Space       Rebuild current preset
##   +/-         Scale pipe radius up/down
##   Ctrl+S      Save modified path to config

const PIPE_SCENE = preload("res://algorithms/wavefunctions/big_pipe_system/BigPipeSystem.tscn")
const CONFIG_DIR = "res://algorithms/wavefunctions/big_pipe_system/configs/"

var _presets: Array[Dictionary] = []
var _current_index: int = 0
var _current_instance: Node3D = null
var _show_debug: bool = false
var _pipe_radius: float = 0.8
var _segment_length: float = 2.0

# UI
var _title_label: Label3D
var _path_label: Label3D
var _info_label: Label3D
var _camera: Camera3D

func _ready() -> void:
	_scan_presets()
	_setup_ui()
	_setup_camera()

	if not Engine.is_editor_hint():
		_load_preset(0)
	else:
		_build_editor_gallery()

func _scan_presets() -> void:
	_presets.clear()
	var dir := DirAccess.open(CONFIG_DIR)
	if not dir:
		push_error("PipeDemoGallery: Cannot open %s" % CONFIG_DIR)
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.ends_with(".json") and entry != "presets_index.json":
			var data := _load_json(CONFIG_DIR + entry)
			if not data.is_empty():
				data["_file"] = entry
				_presets.append(data)
		entry = dir.get_next()
	dir.list_dir_end()
	_presets.sort_custom(func(a, b): return a["_file"] < b["_file"])

func _setup_ui() -> void:
	_title_label = Label3D.new()
	_title_label.font_size = 64
	_title_label.position = Vector3(0, 8, -4)
	_title_label.modulate = Color(0.3, 0.85, 1.0)
	add_child(_title_label)

	_path_label = Label3D.new()
	_path_label.font_size = 36
	_path_label.position = Vector3(0, 6.5, -4)
	_path_label.modulate = Color(0.8, 0.8, 0.5)
	add_child(_path_label)

	_info_label = Label3D.new()
	_info_label.font_size = 28
	_info_label.position = Vector3(0, 5.5, -4)
	_info_label.modulate = Color(0.6, 0.6, 0.6)
	add_child(_info_label)

func _setup_camera() -> void:
	_camera = Camera3D.new()
	_camera.position = Vector3(0, 12, 20)
	_camera.rotation_degrees = Vector3(-25, 0, 0)
	_camera.fov = 60
	add_child(_camera)
	if not Engine.is_editor_hint():
		_camera.make_current()

func _load_preset(index: int) -> void:
	if index < 0 or index >= _presets.size():
		return

	# Remove old
	if _current_instance and is_instance_valid(_current_instance):
		_current_instance.queue_free()
		_current_instance = null

	_current_index = index
	var data: Dictionary = _presets[index]

	# Read layout
	if data.has("layout"):
		var layout: Dictionary = data["layout"]
		_pipe_radius = layout.get("pipe_radius", 0.8)
		_segment_length = layout.get("segment_length", 2.0)

	var path_str: String = data.get("path", "f,f,f")
	var name_str: String = data.get("_file", "unknown").replace(".json", "")
	var desc: String = ""
	if data.has("rack_info"):
		var info: Dictionary = data["rack_info"]
		if info.has("name"):
			name_str = info["name"]
		desc = info.get("description", "")

	# Build pipe
	_current_instance = PIPE_SCENE.instantiate()
	_current_instance.set("pipe_radius", _pipe_radius)
	_current_instance.set("segment_length", _segment_length)
	_current_instance.set("auto_build", false)
	add_child(_current_instance)
	_current_instance.call_deferred("generate_from_code", path_str)

	# Update labels
	_title_label.text = "[%d/%d] %s" % [index + 1, _presets.size(), name_str]
	_path_label.text = path_str
	_info_label.text = desc if desc != "" else "radius=%.1f  length=%.1f" % [_pipe_radius, _segment_length]

	# Count segments for info
	var seg_count := path_str.split(",").size()
	_info_label.text += "  |  %d commands" % seg_count

	if _show_debug:
		call_deferred("_add_debug_boxes")

func _add_debug_boxes() -> void:
	## Add wireframe boxes around each segment for debugging
	if not _current_instance:
		return
	var old := _current_instance.get_node_or_null("DebugBoxes")
	if old:
		old.queue_free()

	var debug_root := Node3D.new()
	debug_root.name = "DebugBoxes"
	_current_instance.add_child(debug_root)

	for child in _current_instance.get_children():
		if child == debug_root:
			continue
		if not child is Node3D:
			continue

		# Find mesh bounds
		var aabb := AABB()
		var found := false
		for mesh_child in child.find_children("*", "MeshInstance3D", true, false):
			var mi := mesh_child as MeshInstance3D
			if mi and mi.mesh:
				var mesh_aabb := mi.mesh.get_aabb()
				# Transform to segment local space
				var t := mi.transform
				var corners := [
					t * mesh_aabb.position,
					t * (mesh_aabb.position + Vector3(mesh_aabb.size.x, 0, 0)),
					t * (mesh_aabb.position + Vector3(0, mesh_aabb.size.y, 0)),
					t * (mesh_aabb.position + Vector3(0, 0, mesh_aabb.size.z)),
					t * mesh_aabb.end,
					t * (mesh_aabb.end - Vector3(mesh_aabb.size.x, 0, 0)),
					t * (mesh_aabb.end - Vector3(0, mesh_aabb.size.y, 0)),
					t * (mesh_aabb.end - Vector3(0, 0, mesh_aabb.size.z)),
				]
				for c in corners:
					if not found:
						aabb = AABB(c, Vector3.ZERO)
						found = true
					else:
						aabb = aabb.expand(c)

		if not found:
			continue

		# Create wireframe box using thin cylinders on edges
		var box_size := aabb.size
		var box_center := aabb.position + box_size * 0.5

		var box_node := Node3D.new()
		box_node.position = child.position
		box_node.transform.basis = child.transform.basis

		# Just show a semi-transparent box
		var box_mesh := BoxMesh.new()
		box_mesh.size = box_size * 1.05
		var box_inst := MeshInstance3D.new()
		box_inst.mesh = box_mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.8, 1.0, 0.15)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		box_inst.material_override = mat
		box_inst.position = box_center
		box_node.add_child(box_inst)

		# Origin marker
		var origin := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.15
		sphere.height = 0.3
		origin.mesh = sphere
		var origin_mat := StandardMaterial3D.new()
		origin_mat.albedo_color = Color(1, 0.3, 0.1, 0.8)
		origin_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		origin.material_override = origin_mat
		box_node.add_child(origin)

		debug_root.add_child(box_node)

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	return json.data if json.data is Dictionary else {}

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return

	# Number keys
	var idx := _key_to_index(key.keycode)
	if idx >= 0 and idx < _presets.size():
		_load_preset(idx)
		return

	match key.keycode:
		KEY_LEFT:
			_load_preset((_current_index - 1 + _presets.size()) % _presets.size())
		KEY_RIGHT:
			_load_preset((_current_index + 1) % _presets.size())
		KEY_D:
			_show_debug = not _show_debug
			if _show_debug:
				_add_debug_boxes()
			else:
				if _current_instance:
					var old := _current_instance.get_node_or_null("DebugBoxes")
					if old:
						old.queue_free()
			_info_label.text += "  [DEBUG %s]" % ("ON" if _show_debug else "OFF")
		KEY_SPACE:
			_load_preset(_current_index)
		KEY_EQUAL:  # +
			_pipe_radius = minf(_pipe_radius + 0.1, 2.0)
			_info_label.text = "radius=%.1f" % _pipe_radius
			_load_preset(_current_index)
		KEY_MINUS:
			_pipe_radius = maxf(_pipe_radius - 0.1, 0.2)
			_info_label.text = "radius=%.1f" % _pipe_radius
			_load_preset(_current_index)
		KEY_S:
			if key.ctrl_pressed:
				_save_current_config()

func _save_current_config() -> void:
	if _current_index < 0 or _current_index >= _presets.size():
		return
	var data: Dictionary = _presets[_current_index]
	var file_name: String = data.get("_file", "")
	if file_name == "":
		return
	var path := CONFIG_DIR + file_name
	# Remove internal metadata before saving
	var save_data := data.duplicate()
	save_data.erase("_file")
	var out := FileAccess.open(path, FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(save_data, "\t"))
		out.close()
		_title_label.text += "  [SAVED]"

func _key_to_index(keycode: Key) -> int:
	match keycode:
		KEY_1: return 0
		KEY_2: return 1
		KEY_3: return 2
		KEY_4: return 3
		KEY_5: return 4
		KEY_6: return 5
		KEY_7: return 6
		KEY_8: return 7
		KEY_9: return 8
	return -1

# ---------------------------------------------------------------------------
# Editor gallery — show all presets in a row
# ---------------------------------------------------------------------------
func _build_editor_gallery() -> void:
	var spacing := 16.0  # Big pipes need room
	for i in range(_presets.size()):
		var data: Dictionary = _presets[i]
		var path_str: String = data.get("path", "f,f,f")
		var name_str: String = data.get("_file", "").replace(".json", "")

		var inst := PIPE_SCENE.instantiate()
		if data.has("layout"):
			var layout: Dictionary = data["layout"]
			inst.set("pipe_radius", layout.get("pipe_radius", 0.8))
			inst.set("segment_length", layout.get("segment_length", 2.0))
		inst.set("auto_build", false)
		inst.position = Vector3(i * spacing, 0, 0)
		add_child(inst)
		inst.call_deferred("generate_from_code", path_str)
		if Engine.is_editor_hint():
			inst.owner = get_tree().edited_scene_root

		var label := Label3D.new()
		label.text = name_str
		label.font_size = 48
		label.position = Vector3(i * spacing, -1.5, 2)
		label.rotation.x = -PI / 4
		add_child(label)
		if Engine.is_editor_hint():
			label.owner = get_tree().edited_scene_root
