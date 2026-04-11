@tool
extends SceneTree

## Capture script for Eurorack racks and individual modules.
##
## Usage:
##   # Full rack preset
##   godot --path . --xr-mode off --no-window --script res://commons/testing/capture_eurorack.gd -- --preset=basic_mono
##   # Single module (isolated)
##   godot --path . --xr-mode off --no-window --script res://commons/testing/capture_eurorack.gd -- --module=vco

const OUTPUT_DIR := "user://eurorack_shots"

var _preset_name: String = ""
var _module_name: String = ""
var _frame_count: int = 0
var _uvac: Node3D = null
var _single_module: Node3D = null
var _camera: Camera3D = null
var _light: DirectionalLight3D = null
var _env: WorldEnvironment = null
var _angles: Array = []
var _angle_index: int = 0
var _captures_done: int = 0


func _init():
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--preset="):
			_preset_name = arg.substr(9)
		elif arg.begins_with("--module="):
			_module_name = arg.substr(9)

	if _module_name:
		print("capture_eurorack [module]: Will capture module '%s'" % _module_name)
	else:
		if _preset_name.is_empty():
			_preset_name = "basic_mono"
		print("capture_eurorack [preset]: Will capture preset '%s'" % _preset_name)


func _process(delta: float) -> bool:
	_frame_count += 1

	if _frame_count == 1:
		_setup_scene()
		return false

	if _frame_count < 8:
		return false

	if _frame_count == 8:
		_setup_angles()
		if _angles.is_empty():
			print("capture_eurorack: No angles — aborting")
			quit()
			return true
		_apply_angle()
		return false

	if _frame_count < 12:
		return false

	if _frame_count >= 12 and _captures_done <= _angle_index:
		_capture_current_angle()
		_captures_done += 1
		_angle_index += 1
		if _angle_index < _angles.size():
			_apply_angle()
			_frame_count = 8
			return false
		else:
			var target_name: String = _module_name if _module_name else _preset_name
			print("capture_eurorack: All %d angles captured for '%s'" % [_captures_done, target_name])
			quit()
			return true

	return false


func _setup_scene() -> void:
	var root := get_root()

	# Environment
	_env = WorldEnvironment.new()
	var env_res := Environment.new()
	env_res.background_mode = Environment.BG_COLOR
	env_res.background_color = Color(0.05, 0.05, 0.08)
	env_res.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_res.ambient_light_color = Color(0.3, 0.3, 0.35)
	env_res.ambient_light_energy = 0.5
	_env.environment = env_res
	root.add_child(_env)

	# Light
	_light = DirectionalLight3D.new()
	_light.rotation_degrees = Vector3(-40, -30, 0)
	_light.light_energy = 1.2
	_light.shadow_enabled = true
	root.add_child(_light)

	# Fill light
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 150, 0)
	fill.light_energy = 0.4
	fill.shadow_enabled = false
	root.add_child(fill)

	# Camera
	_camera = Camera3D.new()
	_camera.current = true
	_camera.fov = 50
	root.add_child(_camera)

	if _module_name:
		_setup_single_module(root)
	else:
		_setup_full_rack(root)


func _setup_full_rack(root: Window) -> void:
	var UVACScript = load("res://commons/audio/UniversalVRAudioController.gd")
	_uvac = Node3D.new()
	_uvac.set_script(UVACScript)
	_uvac.name = "UVAC"

	var param_container := Node3D.new()
	param_container.name = "ParameterGrid"
	_uvac.add_child(param_container)

	var audio_player := AudioStreamPlayer3D.new()
	audio_player.name = "AudioStreamPlayer3D"
	_uvac.add_child(audio_player)

	root.add_child(_uvac)
	_uvac.call_deferred("load_eurorack_preset", _preset_name)
	print("capture_eurorack: Loading rack preset '%s'" % _preset_name)


func _setup_single_module(root: Window) -> void:
	# Load module_library.json directly
	var lib_path := "res://commons/audio/eurorack_modules/module_library.json"
	var file := FileAccess.open(lib_path, FileAccess.READ)
	if not file:
		push_error("capture_eurorack: Can't open %s" % lib_path)
		return

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("capture_eurorack: JSON parse error")
		return
	file.close()

	var modules: Dictionary = json.data.get("modules", {})
	if not modules.has(_module_name):
		push_error("capture_eurorack: Module '%s' not found. Available: %s" % [_module_name, ", ".join(modules.keys())])
		return

	var mod_def: Dictionary = modules[_module_name]

	# Build a minimal UVAC stand-in for the module's controls
	var UVACScript = load("res://commons/audio/UniversalVRAudioController.gd")
	_uvac = Node3D.new()
	_uvac.set_script(UVACScript)
	_uvac.name = "UVAC"

	var param_container := Node3D.new()
	param_container.name = "ParameterGrid"
	_uvac.add_child(param_container)

	var audio_player := AudioStreamPlayer3D.new()
	audio_player.name = "AudioStreamPlayer3D"
	_uvac.add_child(audio_player)

	root.add_child(_uvac)

	# Build the single module
	var EurorackModuleScript = load("res://commons/audio/EurorackModule.gd")
	_single_module = EurorackModuleScript.new()
	_single_module.name = "Module_%s" % _module_name.to_upper()
	param_container.add_child(_single_module)

	# Need to defer build so UVAC is ready
	_single_module.call_deferred("build_from_definition", mod_def, _uvac)
	print("capture_eurorack: Building single module '%s' (%d HP)" % [_module_name, mod_def.get("hp_width", 8)])


func _setup_angles() -> void:
	# Find the target node
	var target: Node3D = null
	if _single_module:
		target = _single_module
	else:
		var rack = _uvac.get_node_or_null("ParameterGrid/EurorackRack")
		if rack:
			target = rack

	if not target:
		push_warning("capture_eurorack: No target found!")
		_angles = [{"name": "front", "pos": Vector3(0, 0, 1.5), "look": Vector3.ZERO}]
		return

	var aabb: AABB = _get_subtree_aabb(target)
	var center: Vector3 = target.global_position + aabb.get_center()
	var size: Vector3 = aabb.size
	var max_dim: float = maxf(size.x, maxf(size.y, size.z))

	if _single_module:
		# Closer shots for single module — focus on controls
		var dist: float = max_dim * 1.4
		_angles = [
			{"name": "front", "pos": center + Vector3(0, 0, dist), "look": center},
			{"name": "close", "pos": center + Vector3(0, 0, dist * 0.5), "look": center},
			{"name": "angle", "pos": center + Vector3(-dist * 0.5, dist * 0.2, dist * 0.7), "look": center},
		]
	else:
		var dist: float = max_dim * 1.8
		_angles = [
			{"name": "front", "pos": center + Vector3(0, 0, dist), "look": center},
			{"name": "front_close", "pos": center + Vector3(0, 0, dist * 0.6), "look": center},
			{"name": "angle_left", "pos": center + Vector3(-dist * 0.7, dist * 0.3, dist * 0.7), "look": center},
			{"name": "above", "pos": center + Vector3(0, dist * 0.9, dist * 0.5), "look": center},
		]

	print("capture_eurorack: Target AABB center=%s size=%s, %d angles" % [center, size, _angles.size()])


func _apply_angle() -> void:
	var angle: Dictionary = _angles[_angle_index]
	_camera.global_position = angle["pos"] as Vector3
	_camera.look_at(angle["look"] as Vector3, Vector3.UP)
	print("capture_eurorack: Angle %d/%d '%s'" % [_angle_index + 1, _angles.size(), angle["name"]])


func _capture_current_angle() -> void:
	var angle_name: String = _angles[_angle_index]["name"]
	var target_name: String = ("module_%s" % _module_name) if _module_name else _preset_name
	var dir_path := OUTPUT_DIR + "/" + target_name
	DirAccess.make_dir_recursive_absolute(dir_path)

	var viewport := get_root()
	var img := viewport.get_texture().get_image()
	if img:
		var file_path := "%s/%s.png" % [dir_path, angle_name]
		img.save_png(file_path)
		print("capture_eurorack: Saved %s" % file_path)
	else:
		push_warning("capture_eurorack: Failed to get viewport image")


func _get_subtree_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.get_children():
		if child is MeshInstance3D:
			var mi: MeshInstance3D = child as MeshInstance3D
			var mesh_aabb: AABB = mi.get_aabb()
			var global_aabb: AABB = mi.global_transform * mesh_aabb
			if first:
				result = global_aabb
				first = false
			else:
				result = result.merge(global_aabb)
		if child is Node3D:
			var child_aabb := _get_subtree_aabb(child)
			if child_aabb.size != Vector3.ZERO:
				if first:
					result = child_aabb
					first = false
				else:
					result = result.merge(child_aabb)
	return result
