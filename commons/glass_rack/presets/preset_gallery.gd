@tool
extends Node3D

## Gallery for previewing and editing glass rack + big pipe presets.
## Run this scene → use number keys (1-9,0,-,=) to select glass presets,
## Shift+1-8 for pipe presets. Edit the path in the console label.
## Press Enter to rebuild current preset with modified path.

const GLASS_PRESETS: Array[Dictionary] = [
	{"file": "simple_tube", "path": "spiral"},
	{"file": "spiral_tube", "path": "spiral"},
	{"file": "spiral_condenser", "path": "f,f,u,spiral,d,f"},
	{"file": "distillation_rack", "path": "flask,f,u,spiral,d,f,f,flask"},
	{"file": "distillation_y", "path": "flask,f,ypipe,[,l,spiral],r,spiral,f,beaker"},
	{"file": "fractional_distillation", "path": "flask,f,u,f,spiral,f,reducer,f,spiral,f,reducer,f,corner45,f,condenser,d,f,f,beaker"},
	{"file": "reflux_apparatus", "path": "flask,f,condenser,f,ubend,f,f"},
	{"file": "branching_condenser", "path": "f,ypipe,[,l,f,spiral],r,f,spiral,f"},
	{"file": "sbend_manifold", "path": "f,sbend,f,sbend,f,sbend,f"},
	{"file": "complex_apparatus", "path": "flask,f,u,spiral,d,junction,f,f,beaker"},
	{"file": "breaking_bad_coffee", "path": "flask,f,u,spiral,d,f,reducer,f,f,beaker"},
]

const PIPE_PRESETS: Array[Dictionary] = [
	{"file": "default", "path": "f,f,s,l,f,r,f"},
	{"file": "straight_run", "path": "cap,f,f,f,f,f,f,cap"},
	{"file": "l_bend", "path": "cap,f,f,r,f,f,cap"},
	{"file": "t_distribution", "path": "cap,f,f,t,f,cap"},
	{"file": "serpentine", "path": "cap,f,f,f,f,f,r,f,r,f,f,f,f,f,l,f,l,f,f,f,f,f,cap"},
	{"file": "vertical_bypass", "path": "cap,f,vu,f,vd,f,cap"},
	{"file": "cross_manifold", "path": "cap,f,f,x,f,f,cap"},
	{"file": "industrial_branch", "path": "f,s,f,t,f,x,f,vu,f,vd,f,cap"},
]

var _current_index: int = 0
var _current_is_pipe: bool = false
var _current_path: String = ""
var _current_instance: Node3D = null
var _label: Label3D = null
var _path_label: Label3D = null

func _ready() -> void:
	if Engine.is_editor_hint():
		_build_all_gallery()
		return
	_setup_labels()
	_load_preset(0, false)

func _setup_labels() -> void:
	_label = Label3D.new()
	_label.font_size = 48
	_label.position = Vector3(0, 1.5, -0.5)
	_label.modulate = Color(0.4, 0.9, 1.0)
	add_child(_label)

	_path_label = Label3D.new()
	_path_label.font_size = 28
	_path_label.position = Vector3(0, 1.1, -0.5)
	_path_label.modulate = Color(0.8, 0.8, 0.6)
	add_child(_path_label)

func _load_preset(index: int, is_pipe: bool) -> void:
	# Remove old instance
	if _current_instance and is_instance_valid(_current_instance):
		_current_instance.queue_free()
		_current_instance = null

	_current_index = index
	_current_is_pipe = is_pipe

	var presets = PIPE_PRESETS if is_pipe else GLASS_PRESETS
	if index < 0 or index >= presets.size():
		return

	var preset: Dictionary = presets[index]
	_current_path = preset["path"]

	var kind := "pipe" if is_pipe else "glass"
	var name_str: String = preset["file"]

	if is_pipe:
		_current_instance = _build_pipe(_current_path)
	else:
		_current_instance = _build_glass(_current_path, preset)

	if _current_instance:
		add_child(_current_instance)

	if _label:
		_label.text = "[%s %d/%d] %s" % [kind.to_upper(), index + 1, presets.size(), name_str]
	if _path_label:
		_path_label.text = _current_path

func _build_glass(path_str: String, preset: Dictionary) -> Node3D:
	var scene := load("res://commons/glass_rack/GlassRack.tscn")
	if not scene:
		return null
	var inst := (scene as PackedScene).instantiate()
	# Override config with live path
	inst.set("auto_build", false)
	inst.set("config_file", "")
	# Read the config for material colors
	var config_path := "res://commons/glass_rack/configs/%s.json" % preset["file"]
	if FileAccess.file_exists(config_path):
		var file := FileAccess.open(config_path, FileAccess.READ)
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
			var data: Dictionary = json.data
			if data.has("layout"):
				var layout: Dictionary = data["layout"]
				if layout.has("segment_length"):
					inst.set("segment_length", layout["segment_length"])
				if layout.has("tube_radius"):
					inst.set("pipe_radius", layout["tube_radius"])
			if data.has("materials"):
				var mats: Dictionary = data["materials"]
				if mats.has("glass_color"):
					var c: Array = mats["glass_color"]
					inst.set("glass_color", Color(c[0], c[1], c[2], c[3]))
				if mats.has("liquid_color"):
					var c: Array = mats["liquid_color"]
					inst.set("liquid_color", Color(c[0], c[1], c[2], c[3]))
	# Deferred build after _ready
	inst.call_deferred("generate_from_code", path_str)
	return inst

func _build_pipe(path_str: String) -> Node3D:
	var scene := load("res://algorithms/wavefunctions/big_pipe_system/BigPipeSystem.tscn")
	if not scene:
		return null
	var inst := (scene as PackedScene).instantiate()
	inst.set("auto_build", false)
	inst.call_deferred("generate_from_code", path_str)
	return inst

func _rebuild_current() -> void:
	_load_preset(_current_index, _current_is_pipe)

func _save_current_config() -> void:
	var presets = PIPE_PRESETS if _current_is_pipe else GLASS_PRESETS
	if _current_index < 0 or _current_index >= presets.size():
		return
	var preset: Dictionary = presets[_current_index]

	var config_path: String
	if _current_is_pipe:
		config_path = "res://algorithms/wavefunctions/big_pipe_system/configs/%s.json" % preset["file"]
	else:
		config_path = "res://commons/glass_rack/configs/%s.json" % preset["file"]

	if not FileAccess.file_exists(config_path):
		return

	var file := FileAccess.open(config_path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	file.close()
	var data: Dictionary = json.data
	data["path"] = _current_path

	var out := FileAccess.open(config_path, FileAccess.WRITE)
	out.store_string(JSON.stringify(data, "\t"))
	out.close()

	if _label:
		_label.text += "  [SAVED]"

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return

	# Shift + number = pipe presets
	if key.shift_pressed:
		var pipe_idx := _key_to_index(key.keycode)
		if pipe_idx >= 0 and pipe_idx < PIPE_PRESETS.size():
			_load_preset(pipe_idx, true)
			return

	# Number keys = glass presets (1-9, 0=10, -=11)
	var glass_idx := _key_to_index(key.keycode)
	if not key.shift_pressed and glass_idx >= 0 and glass_idx < GLASS_PRESETS.size():
		_load_preset(glass_idx, false)
		return

	# Left/Right = prev/next within current category
	if key.keycode == KEY_LEFT:
		var presets = PIPE_PRESETS if _current_is_pipe else GLASS_PRESETS
		_load_preset((_current_index - 1) % presets.size(), _current_is_pipe)
		return
	if key.keycode == KEY_RIGHT:
		var presets = PIPE_PRESETS if _current_is_pipe else GLASS_PRESETS
		_load_preset((_current_index + 1) % presets.size(), _current_is_pipe)
		return

	# Tab = toggle glass/pipe
	if key.keycode == KEY_TAB:
		_current_is_pipe = not _current_is_pipe
		_load_preset(0, _current_is_pipe)
		return

	# Ctrl+S = save current path to config file
	if key.keycode == KEY_S and key.ctrl_pressed:
		_save_current_config()
		return

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
		KEY_0: return 9
		KEY_MINUS: return 10
		KEY_EQUAL: return 11
	return -1

# ---------------------------------------------------------------------------
# Editor gallery mode — show everything in a grid
# ---------------------------------------------------------------------------

func _build_all_gallery() -> void:
	for i in range(GLASS_PRESETS.size()):
		var preset: Dictionary = GLASS_PRESETS[i]
		var config_path := "res://commons/glass_rack/configs/%s.json" % preset["file"]
		var scene := load("res://commons/glass_rack/GlassRack.tscn")
		if not scene:
			continue
		var inst := (scene as PackedScene).instantiate()
		inst.position = Vector3(i * 1.2, 0, 0)
		# Load config if exists
		if FileAccess.file_exists(config_path):
			inst.set("config_file", "%s.json" % preset["file"])
		add_child(inst)
		if Engine.is_editor_hint():
			inst.owner = get_tree().edited_scene_root

		var label := Label3D.new()
		label.text = preset["file"]
		label.font_size = 24
		label.position = Vector3(i * 1.2, -0.3, 0.15)
		label.rotation.x = -PI / 4
		add_child(label)
		if Engine.is_editor_hint():
			label.owner = get_tree().edited_scene_root

	for i in range(PIPE_PRESETS.size()):
		var preset: Dictionary = PIPE_PRESETS[i]
		var scene := load("res://algorithms/wavefunctions/big_pipe_system/BigPipeSystem.tscn")
		if not scene:
			continue
		var inst := (scene as PackedScene).instantiate()
		inst.position = Vector3(i * 6.0, 0, -8)
		inst.set("config_file", "%s.json" % preset["file"])
		inst.set("auto_build", true)
		add_child(inst)
		if Engine.is_editor_hint():
			inst.owner = get_tree().edited_scene_root

		var label := Label3D.new()
		label.text = preset["file"]
		label.font_size = 36
		label.position = Vector3(i * 6.0, -0.5, -6)
		label.rotation.x = -PI / 4
		add_child(label)
		if Engine.is_editor_hint():
			label.owner = get_tree().edited_scene_root
