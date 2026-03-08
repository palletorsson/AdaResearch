extends SceneTree

## Capture all RackControlBase 2D controls to PNG via SubViewport.
## Renders each control at its canonical pixel size from design tokens.
## Usage:
##   godot_console --path . --xr-mode off --script res://commons/testing/capture_rack_2d.gd -- \
##     --out=user://rack_captures/ --scale=2
##
## Options:
##   --out=<dir>      Output directory (default: user://rack_captures/)
##   --scale=<int>    Resolution multiplier (default: 2)
##   --control=<type> Capture only one control type (default: all)

# Force-load base classes so class_name registry is populated
var _preload_tokens = preload("res://commons/audio/rack_controls/RackDesignTokens.gd")
var _preload_base = preload("res://commons/audio/rack_controls/RackControlBase.gd")

var _output_dir: String = "user://rack_captures/"
var _scale: int = 2
var _single_control: String = ""

# All controls to capture: [type_key, scene_path, setup_callable_name]
const CONTROLS := [
	["slv", "res://commons/audio/rack_controls/RackSliderV.tscn", "_setup_slider"],
	["slh", "res://commons/audio/rack_controls/RackSliderH.tscn", "_setup_slider_h"],
	["sls", "res://commons/audio/rack_controls/RackSliderStepped.tscn", "_setup_stepped"],
	["slz", "res://commons/audio/rack_controls/RackSliderBipolar.tscn", "_setup_bipolar"],
	["knob", "res://commons/audio/rack_controls/RackKnob.tscn", "_setup_slider"],
	["wheel", "res://commons/audio/rack_controls/RackWheel.tscn", "_setup_slider"],
	["xy", "res://commons/audio/rack_controls/RackXYPad.tscn", "_setup_xy"],
	["joystick", "res://commons/audio/rack_controls/RackJoystick.tscn", "_setup_xy"],
	["lever", "res://commons/audio/rack_controls/RackLever.tscn", "_setup_slider"],
	["btn", "res://commons/audio/rack_controls/RackButton.tscn", "_setup_button"],
	["meter", "res://commons/audio/rack_controls/RackMeter.tscn", "_setup_meter"],
	["label", "res://commons/audio/rack_controls/RackLabel.tscn", "_setup_label"],
	["divider", "res://commons/audio/rack_controls/RackDivider.tscn", ""],
	["group", "res://commons/audio/rack_controls/RackGroup.tscn", "_setup_group"],
]

var _captured: int = 0


func _initialize() -> void:
	_parse_args()
	DirAccess.make_dir_recursive_absolute(_output_dir)
	# Run capture loop after tree is ready
	call_deferred("_run_all")


func _run_all() -> void:
	for entry in CONTROLS:
		var type_key: String = entry[0]
		if not _single_control.is_empty() and type_key != _single_control:
			continue
		await _capture_one(type_key, entry[1], entry[2])

	print("capture_rack_2d: Done. %d controls captured to %s" % [_captured, _output_dir])
	quit(0)


func _capture_one(type_key: String, scene_path: String, setup_func: String) -> void:
	# Load scene
	var scene := load(scene_path) as PackedScene
	if not scene:
		push_warning("capture_rack_2d: cannot load %s" % scene_path)
		return

	var control := scene.instantiate() as Control
	if not control:
		push_warning("capture_rack_2d: %s root is not Control" % scene_path)
		return

	# Apply setup before adding to tree
	if not setup_func.is_empty() and has_method(setup_func):
		call(setup_func, control)

	# Get canonical size
	var px_size := control.custom_minimum_size
	if px_size == Vector2.ZERO:
		px_size = Vector2(80, 80)

	# Create SubViewport
	var viewport := SubViewport.new()
	viewport.disable_3d = true
	viewport.size = Vector2i(int(px_size.x * _scale), int(px_size.y * _scale))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false

	# Set control size explicitly instead of using anchors (avoids deferred resize warning)
	control.position = Vector2.ZERO
	control.size = Vector2(viewport.size)
	viewport.add_child(control)

	root.add_child(viewport)
	print("Capturing: %s (%dx%d @ %dx)" % [type_key, int(px_size.x), int(px_size.y), _scale])

	# Wait frames for rendering to settle
	await process_frame
	await process_frame
	await process_frame
	await process_frame

	# Capture
	var image := viewport.get_texture().get_image()
	if image:
		var abs_path := _output_dir + type_key + ".png"
		if abs_path.begins_with("user://"):
			abs_path = OS.get_user_data_dir() + "/" + abs_path.substr(7)
		var err := image.save_png(abs_path)
		if err == OK:
			print("  Saved: %s" % abs_path)
			_captured += 1
		else:
			push_warning("  Failed to save: %s (error %d)" % [abs_path, err])
	else:
		push_warning("  No image for %s" % type_key)

	# Cleanup
	root.remove_child(viewport)
	viewport.queue_free()


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
			"scale":
				if value.is_valid_int():
					_scale = clampi(int(value), 1, 4)
			"control":
				_single_control = value


# --- Setup functions ---

func _setup_slider(control: Control) -> void:
	control.control_label = "FREQ"
	control.normalized_value = 0.65

func _setup_slider_h(control: Control) -> void:
	control.control_label = "PAN"
	control.normalized_value = 0.65

func _setup_stepped(control: Control) -> void:
	control.control_label = "WAVE"
	control.normalized_value = 0.5
	if "steps" in control:
		control.steps = 7

func _setup_bipolar(control: Control) -> void:
	control.control_label = "TUNE"
	control.normalized_value = 0.3

func _setup_xy(control: Control) -> void:
	control.control_label = "FILTER"
	control.normalized_value = 0.6
	if "normalized_value_y" in control:
		control.normalized_value_y = 0.4

func _setup_button(control: Control) -> void:
	control.control_label = "PLAY"

func _setup_meter(control: Control) -> void:
	control.control_label = "LVL"
	if "level" in control:
		control.level = 0.7

func _setup_label(control: Control) -> void:
	if "text" in control:
		control.text = "SYNTH"
	if "subtitle" in control:
		control.subtitle = "v1.0"

func _setup_group(control: Control) -> void:
	if "group_title" in control:
		control.group_title = "OSCILLATOR"
