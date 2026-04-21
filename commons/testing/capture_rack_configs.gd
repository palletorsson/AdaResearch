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


func _init():
	# Ensure output directory
	DirAccess.make_dir_recursive_absolute(_output_dir)


func _process(_delta):
	_frame_count += 1

	# Wait a few frames for scene to settle
	if _frame_count < 5:
		return

	if _current_idx >= RACK_CONFIGS.size():
		print("capture_rack_configs: Done - %d configs captured to %s" % [RACK_CONFIGS.size(), _output_dir])
		quit()
		return

	if _frame_count == 5:
		_setup_viewport()
		_load_next_config()
		return

	# After loading, wait 10 frames for render, then capture
	if (_frame_count - 5) % 15 == 14:
		_capture_current()
		_current_idx += 1
		if _current_idx < RACK_CONFIGS.size():
			_load_next_config()


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


func _capture_current():
	var config_name = RACK_CONFIGS[_current_idx]
	var img = _viewport.get_texture().get_image()
	var path = _output_dir + config_name + ".png"
	img.save_png(path)
	print("capture_rack_configs: OK %s -> %s" % [config_name, path])
