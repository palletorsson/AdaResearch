extends SceneTree

## Render the fontana_puncture with the embedded interactive point, so we can
## see the carved cube wrapping the live point in its void.
##   godot --path . --xr-mode off --script res://commons/testing/shoot_fontana_embed.gd

const FONTANA := "res://commons/primitives/fontana_puncture/fontana_puncture.tscn"
const OUT := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/artifact-gallery/captures/palm_scanner/fontana_embed.png"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.13, 0.14, 0.18)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 1, 1)
	e.ambient_light_energy = 1.0
	env.environment = e
	world.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, -35, 0)
	world.add_child(key)

	var f: Node3D = load(FONTANA).instantiate()
	f.set_meta("config_embed_artifact", "interactive_point_origin_force")
	f.set_meta("config_embed_mode", "transformation")
	world.add_child(f)
	if f.has_method("apply_grid_config"):
		f.call("apply_grid_config", {
			"embed_artifact": "interactive_point_origin_force",
			"embed_mode": "transformation"})
	for i in range(40):
		await process_frame

	var cam := Camera3D.new()
	cam.fov = 35.0
	world.add_child(cam)
	cam.make_current()
	cam.global_position = Vector3(0.7, 0.5, 1.2)
	cam.look_at(Vector3.ZERO, Vector3.UP)
	for i in range(6):
		await process_frame
	DirAccess.make_dir_recursive_absolute(OUT.get_base_dir())
	root.get_texture().get_image().save_png(OUT)
	print("[fpx] saved %s" % OUT)
	quit(0)
