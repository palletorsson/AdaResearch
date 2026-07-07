## One-off capture for coordinate_line — instances coordinate_axes_xy.tscn
## (which uses coordinate_line via PackedScene) to validate tick marks render.
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_coordinate_line_demo.gd \
##     -- --out=user://coord_line_demo
extends SceneTree

const SCENE_PATH: String = "res://commons/primitives/line/coordinate_axes_xy.tscn"

var _output_dir: String = "user://coord_line_demo"


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
	_run.call_deferred()


func _run() -> void:
	# Background + lights
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.09, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.6
	env_node.environment = env
	get_root().add_child(env_node)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-35, 30, 0)
	key_light.light_energy = 1.2
	get_root().add_child(key_light)

	var cam := Camera3D.new()
	cam.fov = 40.0
	cam.near = 0.01
	cam.current = true
	get_root().add_child(cam)

	# Spawn coordinate_axes_xy at origin (it instances two coordinate_line scenes
	# — one for X, one rotated for Y)
	var scene = load(SCENE_PATH)
	if not scene:
		push_error("Failed to load scene")
		quit(1)
		return
	var node = scene.instantiate()
	get_root().add_child(node)
	# Hide the scene's bundled camera so it doesn't override ours
	var bundled_cam = node.get_node_or_null("Camera3D")
	if bundled_cam:
		bundled_cam.queue_free()

	await create_timer(1.5).timeout

	# Frame the axes: they're 1.5m long each, default. Place camera back
	# to see both X and Y with ticks legible.
	var focus := Vector3(0.4, 0.4, 0.0)
	var cam_pos := focus + Vector3(0.0, 0.0, 1.6)
	cam.global_position = cam_pos
	cam.look_at(focus, Vector3.UP)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	await create_timer(0.3).timeout
	var image := get_root().get_viewport().get_texture().get_image()
	var path := "%s/front.png" % _output_dir
	image.save_png(ProjectSettings.globalize_path(path))
	print("saved: %s" % path)
	quit(0)
