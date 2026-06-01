extends SceneTree

## High-res head-on capture of the point chalkboard so we can read whether
## the LATIN text lines render or only the symbols/diagram draw.
##   godot --path . --xr-mode off --script res://commons/testing/shoot_chalkboard_closeup.gd

const BOARD := "res://commons/primitives/point_chalkboard/point_chalkboard.tscn"
const OUT := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/artifact-gallery/captures/palm_scanner/chalkboard_text_check.png"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.2, 0.2, 0.24)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 1, 1)
	e.ambient_light_energy = 1.2
	env.environment = e
	world.add_child(env)

	var board: Node3D = load(BOARD).instantiate()
	world.add_child(board)
	# Reproduce the LAB path: lab_loader sets config meta then calls
	# apply_grid_config deferred AFTER _ready (here: no_collider:true). That
	# rebuilds the board's SubViewport — the suspected text-loss trigger.
	board.set_meta("config_no_collider", true)
	board.call_deferred("apply_grid_config", {"no_collider": true})
	# Let the rebuilt SubViewport scribble render.
	for i in range(50):
		await process_frame

	var cam := Camera3D.new()
	cam.fov = 70.0
	world.add_child(cam)
	cam.make_current()
	# Match the VR screenshot: oblique angle, off to the side and below, where
	# the thin font text was vanishing. This is the real stress test.
	cam.global_position = Vector3(-1.6, -0.3, 1.7)
	cam.look_at(Vector3(0.2, 0, 0), Vector3.UP)
	# Give the deferred bake time to swap in the mipmapped texture.
	for i in range(12):
		await process_frame

	DirAccess.make_dir_recursive_absolute(OUT.get_base_dir())
	var img: Image = root.get_texture().get_image()
	img.save_png(OUT)
	print("[cb] saved %s" % OUT)
	quit(0)
