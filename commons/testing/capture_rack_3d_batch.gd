extends SceneTree

## Batch-capture individual 3D VR controls — one PNG per control type.
## Spawns a minimal UVAC with a single control, frames camera, captures.
## Usage:
##   godot_console --path . --xr-mode off --script res://commons/testing/capture_rack_3d_batch.gd

const UVAC_SCENE := "res://commons/audio/UniversalVRAudioController.tscn"

var _output_dir: String = "user://rack_3d_captures/"

# Each entry: [type_key, config_dict_for_apply_grid_config]
# We generate minimal rack configs inline
const CONTROL_ENTRIES := [
	["slv", {"type": "slider", "label": "FREQ", "parameter": "freq", "default": 0.65}],
	["slh", {"type": "slh", "label": "PAN", "parameter": "pan", "default": 0.65}],
	["sls", {"type": "sls", "label": "WAVE", "parameter": "wave", "step": 1, "min": -3, "max": 3, "default": 0}],
	["slz", {"type": "slz", "label": "TUNE", "parameter": "detune", "default": -0.4}],
	["knob", {"type": "knob", "label": "CUT", "parameter": "cutoff", "default": 0.5}],
	["wheel", {"type": "wheel", "label": "PITCH", "parameter": "pitch", "default": 0.5}],
	["xy", {"type": "xy", "label": "FILTER", "parameter_x": "filter_x", "parameter_y": "filter_y"}],
	["joystick", {"type": "joystick", "label": "LFO", "parameter_x": "lfo_x", "parameter_y": "lfo_y"}],
	["lever", {"type": "lever", "label": "POWER", "parameter": "power", "default": 0.65}],
	["btn", {"type": "button", "label": "PLAY", "parameter": "play", "action": "trigger", "color": "#ff4444"}],
	["meter", {"type": "meter", "label": "LVL"}],
	["label", {"type": "label", "text": "SYNTH", "font_size": 32}],
	["divider", {"type": "divider"}],
	["group", {"type": "group", "label": "OSCILLATOR", "width": 0.2, "height": 0.15}],
]

var _captured: int = 0


func _initialize() -> void:
	_parse_args()
	# make_dir_recursive_absolute does not handle `user://` URLs.
	# Globalize first so the OS-native absolute path is what we create.
	var abs_dir: String = _output_dir
	if abs_dir.begins_with("user://"):
		abs_dir = ProjectSettings.globalize_path(_output_dir)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	call_deferred("_run_all")


func _run_all() -> void:
	for entry in CONTROL_ENTRIES:
		var type_key: String = entry[0]
		var control_def: Dictionary = entry[1]
		await _capture_one(type_key, control_def)

	print("capture_rack_3d_batch: Done. %d controls captured to %s" % [_captured, _output_dir])
	quit(0)


func _capture_one(type_key: String, control_def: Dictionary) -> void:
	print("Capturing 3D: %s" % type_key)

	# Build minimal rack config
	var rack_config := {
		"rack_info": {"name": type_key, "sound_type": "basic_sine_wave"},
		"layout": {"padding_px": 20, "gap_px": 10, "hide_selection": true, "hide_buttons": true},
		"grid": [["ctrl"]],
		"control_definitions": {"ctrl": control_def}
	}

	# Write temp config JSON
	var temp_path := "user://rack_3d_captures/_temp_config.json"
	var temp_abs := OS.get_user_data_dir() + "/rack_3d_captures/_temp_config.json"
	var file := FileAccess.open(temp_abs, FileAccess.WRITE)
	if not file:
		push_warning("capture_rack_3d_batch: cannot write temp config")
		return
	file.store_string(JSON.stringify(rack_config, "\t"))
	file.close()

	# Load UVAC scene
	var scene := load(UVAC_SCENE) as PackedScene
	if not scene:
		push_warning("capture_rack_3d_batch: cannot load UVAC")
		return

	var uvac := scene.instantiate() as Node3D

	# Create scaffold
	var scaffold := Node3D.new()
	scaffold.name = "Scaffold_%s" % type_key

	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.08, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.4, 0.45)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	scaffold.add_child(world_env)

	# Camera
	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 40.0
	scaffold.add_child(camera)

	# Lights
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-35, -20, 0)
	key_light.light_energy = 1.0
	key_light.shadow_enabled = true
	scaffold.add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-15, 140, 0)
	fill_light.light_energy = 0.35
	scaffold.add_child(fill_light)

	scaffold.add_child(uvac)
	root.add_child(scaffold)

	# Wait for _ready
	await process_frame
	await process_frame

	# Load config via load_rack_config_from_dict
	uvac.load_rack_config_from_dict(rack_config)

	# Wait for controls to spawn and render
	for i in range(10):
		await process_frame

	# Frame camera — front view, tight on the control
	var rack_mesh := uvac.get_node_or_null("RackMesh") as MeshInstance3D
	var rack_size := Vector3(0.15, 0.15, 0.05)
	if rack_mesh and rack_mesh.mesh is BoxMesh:
		rack_size = (rack_mesh.mesh as BoxMesh).size

	var max_dim := maxf(rack_size.x, rack_size.y)
	var dist := max_dim * 1.8
	dist = maxf(dist, 0.25)
	camera.position = Vector3(0, 0, dist)
	camera.look_at(Vector3.ZERO, Vector3.UP)

	# Render settle
	for i in range(6):
		await process_frame

	# Capture from root viewport
	var image: Image = root.get_texture().get_image()
	if image:
		var abs_path: String
		if _output_dir.begins_with("user://"):
			# globalize_path handles the `user://` → native-OS path conversion
			# including the separator between the data dir and our subpath.
			var base: String = ProjectSettings.globalize_path(_output_dir)
			if not base.ends_with("/") and not base.ends_with("\\"):
				base += "/"
			abs_path = base + type_key + ".png"
		else:
			abs_path = _output_dir + type_key + ".png"
		var err := image.save_png(abs_path)
		if err == OK:
			print("  Saved: %s" % abs_path)
			_captured += 1
		else:
			push_warning("  Failed to save: error %d" % err)
	else:
		push_warning("  No image for %s" % type_key)

	# Cleanup
	root.remove_child(scaffold)
	scaffold.queue_free()

	# Extra frame for cleanup
	await process_frame


func _parse_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for raw_arg in args:
		var arg: String = String(raw_arg).strip_edges()
		if not arg.begins_with("--"):
			continue
		var eq_idx: int = arg.find("=")
		if eq_idx <= 2:
			continue
		var key: String = arg.substr(2, eq_idx - 2)
		var value: String = arg.substr(eq_idx + 1).strip_edges()
		match key:
			"out":
				_output_dir = value
				if not _output_dir.ends_with("/"):
					_output_dir += "/"
