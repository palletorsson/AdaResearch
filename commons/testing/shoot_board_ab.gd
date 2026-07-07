extends SceneTree

## A/B: render the base chalkboard (triangle, WORKS) and the point_chalkboard
## (reported broken) side by side at the SAME distance + the SAME lab-mount
## path (no_collider rebuild), so we can compare text rendering directly.
##   godot --path . --xr-mode off --script res://commons/testing/shoot_board_ab.gd

const TRI := "res://commons/primitives/chalkboard/chalkboard.tscn"
const PT  := "res://commons/primitives/point_chalkboard/point_chalkboard.tscn"
const OUT := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/artifact-gallery/captures/palm_scanner/board_ab.png"


func _initialize() -> void:
	_run.call_deferred()


func _mount(world: Node3D, scene: String, x: float) -> void:
	var b: Node3D = load(scene).instantiate()
	b.position = Vector3(x, 0, 0)
	# Reproduce the lab-mount path: config + deferred apply_grid_config.
	b.set_meta("config_no_collider", true)
	world.add_child(b)
	if b.has_method("apply_grid_config"):
		b.call_deferred("apply_grid_config", {"no_collider": true})


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.12, 0.13, 0.17)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 1, 1)
	e.ambient_light_energy = 1.0
	env.environment = e
	world.add_child(env)

	_mount(world, TRI, -1.0)   # left = triangle (works)
	_mount(world, PT, 1.0)     # right = point (reported broken)
	for i in range(60):
		await process_frame

	var cam := Camera3D.new()
	cam.fov = 50.0
	world.add_child(cam)
	cam.make_current()
	cam.global_position = Vector3(0, 0, 3.2)
	cam.look_at(Vector3(0, 0, 0), Vector3.UP)
	for i in range(8):
		await process_frame
	DirAccess.make_dir_recursive_absolute(OUT.get_base_dir())
	root.get_texture().get_image().save_png(OUT)
	print("[ab] saved %s  (left=triangle, right=point)" % OUT)
	quit(0)
