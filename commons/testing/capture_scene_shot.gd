extends SceneTree

## One-shot scene screenshot utility for CLI usage.
## Example:
## godot_console --path . --script res://commons/testing/capture_scene_shot.gd -- \
##   --scene=res://commons/maps/catalog/MapCatalogDesktop3D.tscn \
##   --out=user://scene_shots/map_catalog.png \
##   --wait=5.0

var _scene_path: String = "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
var _output_path: String = "user://scene_shots/scene_capture.png"
var _wait_seconds: float = 5.0

func _initialize() -> void:
	_parse_args()
	call_deferred("_run_capture")

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
			"scene":
				_scene_path = value
			"out":
				_output_path = value
			"wait":
				if value.is_valid_float():
					_wait_seconds = maxf(0.5, float(value))

func _run_capture() -> void:
	var err: int = change_scene_to_file(_scene_path)
	if err != OK:
		push_error("capture_scene_shot: Failed to load scene: %s" % _scene_path)
		quit(1)
		return

	await process_frame
	await process_frame
	await create_timer(_wait_seconds).timeout
	await process_frame
	await process_frame

	var image: Image = root.get_texture().get_image()
	if image == null:
		push_error("capture_scene_shot: Could not read viewport image")
		quit(1)
		return

	var absolute_output: String = ProjectSettings.globalize_path(_output_path)
	var output_dir: String = absolute_output.get_base_dir()
	if not DirAccess.dir_exists_absolute(output_dir):
		DirAccess.make_dir_recursive_absolute(output_dir)

	var save_err: int = image.save_png(absolute_output)
	if save_err != OK:
		push_error("capture_scene_shot: Failed to save PNG: %s" % absolute_output)
		quit(1)
		return

	print("capture_scene_shot: Saved %s" % absolute_output)
	quit(0)
