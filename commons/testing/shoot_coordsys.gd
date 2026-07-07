extends SceneTree

## Render CoordinateSystem3M with the Point One token config applied, to SEE
## whether ticks are gone and the frame is axis-aligned (no Y tilt).
##   godot --path . --xr-mode off --script res://commons/testing/shoot_coordsys.gd

const CS := "res://algorithms/vectors/00_coordinates/CoordinateSystem3M.tscn"
const OUT := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/artifact-gallery/captures/palm_scanner/coordsys.png"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.10, 0.11, 0.15)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 1, 1)
	e.ambient_light_energy = 1.0
	env.environment = e
	world.add_child(env)

	var c: Node3D = load(CS).instantiate()
	world.add_child(c)
	# Apply the exact Point One token config (tick_step:0 => no ticks).
	if c.has_method("apply_grid_config"):
		c.call("apply_grid_config", {"display_scale": 1.0, "axis_length": 3.0, "tick_step": 0.0})
	for i in range(20):
		await process_frame

	var cam := Camera3D.new()
	cam.fov = 45.0
	world.add_child(cam)
	cam.make_current()
	cam.global_position = Vector3(3.2, 2.4, 4.2)
	cam.look_at(Vector3(1.2, 1.0, 0), Vector3.UP)
	for i in range(6):
		await process_frame
	DirAccess.make_dir_recursive_absolute(OUT.get_base_dir())
	root.get_texture().get_image().save_png(OUT)
	print("[coord] saved %s" % OUT)
	quit(0)
