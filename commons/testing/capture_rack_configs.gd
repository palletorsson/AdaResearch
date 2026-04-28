extends SceneTree

## Capture each rack config as a screenshot.
## Usage: godot --path . --xr-mode off --no-window --script res://commons/testing/capture_rack_configs.gd

const UVAC_SCENE = preload("res://commons/audio/UniversalVRAudioController.tscn")

const RACK_CONFIGS = [
	"basic_rack",
	"sine_wave_rack",
	"mario_rack",
	"heartbeat_rack",
	"lab_intro_rack",
	"slider_rack",
	"synth_rack",
	"full_rack",
	"all_components",
]

var _output_dir: String = "user://rack_gallery/"
var _camera: Camera3D
var _viewport: SubViewport
var _current_idx: int = 0
var _frame_count: int = 0
var _uvac_instance: Node3D = null

# When --config=<res://path.json> is passed as a user arg, the script
# renders ONLY that config and writes one PNG. Otherwise it batches the
# hardcoded RACK_CONFIGS list. This lets module_research.py drive
# per-config rendering of auto-generated racks under rack_configs/auto/.
var _single_config_path: String = ""
var _single_config_name: String = ""
var _single_out_abs: String = ""


func _init():
	_parse_args()
	# Ensure output directory — globalize so user:// works on Windows
	var abs_dir: String = _output_dir
	if abs_dir.begins_with("user://"):
		abs_dir = ProjectSettings.globalize_path(_output_dir)
	DirAccess.make_dir_recursive_absolute(abs_dir)


func _parse_args() -> void:
	for raw in OS.get_cmdline_user_args():
		var arg := String(raw).strip_edges()
		if not arg.begins_with("--"):
			continue
		var eq := arg.find("=")
		if eq <= 2:
			continue
		var key := arg.substr(2, eq - 2)
		var value := arg.substr(eq + 1).strip_edges()
		match key:
			"config":
				# Accept res:// path OR bare config name
				_single_config_path = value
				if _single_config_path.begins_with("res://"):
					_single_config_name = _single_config_path.get_file().get_basename()
				else:
					_single_config_name = value
			"out":
				# When --out is a specific .png, honor it verbatim; else treat as dir
				if value.ends_with(".png"):
					_single_out_abs = value
					if _single_out_abs.begins_with("user://"):
						_single_out_abs = ProjectSettings.globalize_path(_single_out_abs)
				else:
					_output_dir = value if value.ends_with("/") else value + "/"


func _process(_delta):
	_frame_count += 1

	# Wait a few frames for scene to settle
	if _frame_count < 5:
		return

	# Single-config mode: render one and quit
	if not _single_config_path.is_empty():
		if _frame_count == 5:
			_setup_viewport()
			_load_specific_config(_single_config_path, _single_config_name)
			return
		if _frame_count == 18:
			_frame_current_rack()
			return
		if _frame_count == 22:
			_capture_single()
			quit()
		return

	# Batch mode — original behavior
	if _current_idx >= RACK_CONFIGS.size():
		print("capture_rack_configs: Done - %d configs captured to %s" % [RACK_CONFIGS.size(), _output_dir])
		quit()
		return

	if _frame_count == 5:
		_setup_viewport()
		_load_next_config()
		return

	# After loading, wait 10 frames for render, then capture
	if (_frame_count - 5) % 15 == 11:
		_frame_current_rack()
		return

	if (_frame_count - 5) % 15 == 14:
		_capture_current()
		_current_idx += 1
		if _current_idx < RACK_CONFIGS.size():
			_load_next_config()


func _load_specific_config(config_path: String, config_name: String) -> void:
	if _uvac_instance:
		_uvac_instance.queue_free()
		_uvac_instance = null
	print("capture_rack_configs: Loading single %s..." % config_path)
	_uvac_instance = UVAC_SCENE.instantiate()
	_uvac_instance.rack_config_path = config_path
	_viewport.add_child(_uvac_instance)
	_camera.transform.origin = Vector3(0, 0, 1.0)


func _capture_single() -> void:
	var img = _viewport.get_texture().get_image()
	var out_path: String = _single_out_abs
	if out_path.is_empty():
		# Fall back to output_dir + name.png
		var abs_dir: String = _output_dir
		if abs_dir.begins_with("user://"):
			abs_dir = ProjectSettings.globalize_path(_output_dir)
		if not abs_dir.ends_with("/"):
			abs_dir += "/"
		out_path = abs_dir + _single_config_name + ".png"
	# Ensure parent dir exists
	var parent := out_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(parent)
	var err := img.save_png(out_path)
	if err == OK:
		print("capture_rack_configs: OK %s -> %s" % [_single_config_name, out_path])
	else:
		push_warning("capture_rack_configs: save failed err=%d for %s" % [err, out_path])


func _setup_viewport():
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1280, 720)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.transparent_bg = false
	root.add_child(_viewport)

	# Environment
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.4, 0.5)
	env.ambient_light_energy = 2.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	_viewport.add_child(world_env)

	# Lights
	var dir_light = DirectionalLight3D.new()
	dir_light.transform = Transform3D(Basis.looking_at(Vector3(-0.3, -0.7, -0.5)), Vector3(0, 5, 3))
	dir_light.light_energy = 1.5
	dir_light.shadow_enabled = true
	_viewport.add_child(dir_light)

	var spot = SpotLight3D.new()
	spot.transform.origin = Vector3(0, 0.5, 1.5)
	spot.light_energy = 3.0
	spot.spot_range = 4.0
	spot.spot_angle = 40.0
	spot.look_at(Vector3.ZERO)
	_viewport.add_child(spot)

	# Camera
	_camera = Camera3D.new()
	_camera.fov = 40
	_camera.transform.origin = Vector3(0, 0, 0.8)
	_viewport.add_child(_camera)


func _load_next_config():
	# Remove previous
	if _uvac_instance:
		_uvac_instance.queue_free()
		_uvac_instance = null

	var config_name = RACK_CONFIGS[_current_idx]
	var config_path = "res://commons/audio/rack_configs/%s.json" % config_name

	print("capture_rack_configs: Loading %s..." % config_name)

	_uvac_instance = UVAC_SCENE.instantiate()
	_uvac_instance.rack_config_path = config_path
	_viewport.add_child(_uvac_instance)

	# Adjust camera distance based on config
	# Wider racks need camera further back
	_camera.transform.origin = Vector3(0, 0, 1.0)


func _frame_current_rack() -> void:
	if not _uvac_instance or not _camera:
		return
	var aabb := _combined_aabb(_uvac_instance)
	var center := aabb.get_center()
	var width := maxf(aabb.size.x, 0.2)
	var height := maxf(aabb.size.y, 0.2)
	var aspect := float(_viewport.size.x) / float(maxi(1, _viewport.size.y))
	var vfov := deg_to_rad(_camera.fov)
	var hfov := 2.0 * atan(tan(vfov * 0.5) * aspect)
	var dist_h := height / (2.0 * tan(vfov * 0.5))
	var dist_w := width / (2.0 * tan(hfov * 0.5))
	var distance := maxf(dist_h, dist_w) * 1.28 + maxf(aabb.size.z, 0.08)
	_camera.global_position = center + Vector3(0, 0, distance)
	_camera.look_at(center, Vector3.UP)


func _combined_aabb(node: Node3D) -> AABB:
	var total := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var current = stack.pop_back()
		if current is MeshInstance3D and current.mesh:
			var mesh_aabb: AABB = current.global_transform * current.get_aabb()
			if first:
				total = mesh_aabb
				first = false
			else:
				total = total.merge(mesh_aabb)
		for child in current.get_children():
			if child is Node3D:
				stack.append(child)
	if first:
		return AABB(Vector3(-0.5, -0.4, -0.05), Vector3(1.0, 0.8, 0.1))
	return total


func _capture_current():
	var config_name = RACK_CONFIGS[_current_idx]
	var img = _viewport.get_texture().get_image()
	var path = _output_dir + config_name + ".png"
	img.save_png(path)
	print("capture_rack_configs: OK %s -> %s" % [config_name, path])
