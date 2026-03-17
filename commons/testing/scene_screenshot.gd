extends SceneTree

## One-shot scene screenshot runner.
## Usage:
##   godot --path . --headless --script res://commons/testing/scene_screenshot.gd -- \
##     --scene=res://commons/mesh_grammar/villa_san_michele_demo.tscn \
##     --out=user://screenshot.png --settle=2.0 --width=1280 --height=720

var _scene_path: String = ""
var _out_path: String = "user://scene_screenshot.png"
var _settle: float = 2.0
var _width: int = 1280
var _height: int = 720

func _initialize() -> void:
	_parse_args()
	if _scene_path.is_empty():
		push_error("scene_screenshot: --scene required")
		quit(1)
		return
	call_deferred("_run")

func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var a: String = String(arg).strip_edges()
		if not a.begins_with("--"):
			continue
		var eq := a.find("=")
		if eq <= 2:
			continue
		var key := a.substr(2, eq - 2)
		var val := a.substr(eq + 1).strip_edges()
		match key:
			"scene": _scene_path = val
			"out": _out_path = val
			"settle":
				if val.is_valid_float(): _settle = maxf(0.1, float(val))
			"width":
				if val.is_valid_int(): _width = maxi(320, int(val))
			"height":
				if val.is_valid_int(): _height = maxi(240, int(val))

func _run() -> void:
	root.content_scale_size = Vector2i(_width, _height)
	
	var err := change_scene_to_file(_scene_path)
	if err != OK:
		push_error("scene_screenshot: Failed to load scene: %s (error %d)" % [_scene_path, err])
		quit(1)
		return

	# Wait for scene to initialize
	for i in range(5):
		await process_frame

	# Settle time for CSG/mesh generation
	if _settle > 0:
		await create_timer(_settle).timeout

	for i in range(3):
		await process_frame

	# Capture
	var image: Image = root.get_texture().get_image()
	if image == null:
		push_error("scene_screenshot: Failed to get viewport image")
		quit(1)
		return

	var abs_path: String = ProjectSettings.globalize_path(_out_path)
	var dir_path := abs_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	var save_err := image.save_png(abs_path)
	if save_err != OK:
		push_error("scene_screenshot: Failed to save: %s" % abs_path)
		quit(1)
		return

	print("scene_screenshot: Saved %dx%d -> %s" % [image.get_width(), image.get_height(), abs_path])
	quit(0)
