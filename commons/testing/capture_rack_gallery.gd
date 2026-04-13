extends Node

## Captures rack configs by loading them one at a time into the UVAC in the current scene.
## Attach this to the AudioRackDesktop scene root and run normally (not as --script).
## Usage: Add to audio_rack_desktop.tscn as autorun, or run scene with this attached.

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
var _current_idx: int = 0
var _frame_count: int = 0
var _uvac: Node3D = null
var _camera: Camera3D = null


func _ready():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	# Find UVAC and camera in the scene
	_uvac = _find_node_by_class(get_tree().root, "UniversalVRAudioController")
	_camera = get_viewport().get_camera_3d()
	if not _uvac:
		push_error("capture_rack_gallery: No UVAC found in scene")
		get_tree().quit()
		return
	print("capture_rack_gallery: Found UVAC, starting captures of %d configs" % RACK_CONFIGS.size())
	_load_config(_current_idx)


func _process(_delta):
	_frame_count += 1
	# Wait 20 frames per config for rendering to settle
	if _frame_count % 20 == 19:
		_capture()
		_current_idx += 1
		if _current_idx >= RACK_CONFIGS.size():
			print("capture_rack_gallery: Done — %d configs captured to %s" % [RACK_CONFIGS.size(), _output_dir])
			get_tree().quit()
		else:
			_load_config(_current_idx)


func _load_config(idx: int):
	var config_name = RACK_CONFIGS[idx]
	var path = "res://commons/audio/rack_configs/%s.json" % config_name
	print("capture_rack_gallery: Loading %s..." % config_name)
	if _uvac.has_method("load_rack_config"):
		_uvac.load_rack_config(path)
	else:
		push_warning("capture_rack_gallery: UVAC missing load_rack_config")


func _capture():
	var config_name = RACK_CONFIGS[_current_idx]
	var img = get_viewport().get_texture().get_image()
	var path = _output_dir + config_name + ".png"
	var global_path = ProjectSettings.globalize_path(path)
	img.save_png(global_path)
	print("capture_rack_gallery: saved %s -> %s" % [config_name, global_path])


func _find_node_by_class(node: Node, class_name_str: String) -> Node:
	if node.get_class() == class_name_str or node.name == "AudioRack":
		return node
	for child in node.get_children():
		var found = _find_node_by_class(child, class_name_str)
		if found:
			return found
	return null
