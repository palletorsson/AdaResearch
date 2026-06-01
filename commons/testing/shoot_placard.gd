extends SceneTree

## Render the wall_placard so we can read its museum-label typography.
##   godot --path . --xr-mode off --script res://commons/testing/shoot_placard.gd

const ART := "res://commons/primitives/wall_placard/wall_placard.tscn"
const OUT := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/artifact-gallery/captures/palm_scanner/wall_placard.png"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.17, 0.2)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 1, 1)
	e.ambient_light_energy = 1.1
	env.environment = e
	world.add_child(env)

	var p: Node3D = load(ART).instantiate()
	p.set_meta("config_title", "THE POINT")
	p.set_meta("config_meta", "PRIMITIVES · 01 · 2036")
	p.set_meta("config_body", "Position without extension. Zero dimensions. The seed of all form.")
	world.add_child(p)
	if p.has_method("apply_grid_config"):
		p.call("apply_grid_config", {
			"title": "THE POINT",
			"meta": "PRIMITIVES · 01 · 2036",
			"body": "Position without extension. Zero dimensions. The seed of all form."})
	for i in range(40):
		await process_frame

	var cam := Camera3D.new()
	cam.fov = 32.0
	world.add_child(cam)
	cam.make_current()
	cam.global_position = Vector3(0.05, 0.0, 1.0)
	cam.look_at(Vector3.ZERO, Vector3.UP)
	for i in range(6):
		await process_frame
	DirAccess.make_dir_recursive_absolute(OUT.get_base_dir())
	root.get_texture().get_image().save_png(OUT)
	print("[plc] saved %s" % OUT)
	quit(0)
