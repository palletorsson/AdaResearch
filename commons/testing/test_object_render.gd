extends SceneTree
## Real GPU render of the object_scatter layer — confirms registered artifacts
## instantiate + render. Saves to user:// (not the repo). Needs GPU → --no-window.
##   godot --no-window --xr-mode off --path . --script res://commons/testing/test_object_render.gd

const Scatter = preload("res://commons/biome_layers/object_scatter.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var root := get_root()
	root.world_3d = World3D.new()
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.11, 0.12, 0.15)
	e.ambient_light_color = Color(0.8, 0.8, 0.8)
	e.ambient_light_energy = 1.0
	env.environment = e
	root.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	root.add_child(light)

	var node := Node3D.new()
	node.set_script(Scatter)
	root.add_child(node)
	node.call("apply", {
		"grid_dims": Vector3i(14, 1, 14), "cube_size": 1.0, "rng_seed": 7, "budget_scale": 1.0,
		"stage_order": 19,
		"paint_layers": [{"element": "object", "mode": "random", "density": 0.1,
			"params": {"artifact": "prefab_sculpture"}}],
	})
	print("  object children: %d" % node.get_child_count())

	var cam := Camera3D.new()
	root.add_child(cam)
	cam.look_at_from_position(Vector3(7, 8, 20), Vector3(7, 1.0, 7), Vector3.UP)
	cam.make_current()

	for i in 8:
		await process_frame
	await create_timer(0.4).timeout
	var img := root.get_texture().get_image()
	img.save_png("user://object_scatter_render.png")
	print("RENDER SAVED ", ProjectSettings.globalize_path("user://object_scatter_render.png"))
	quit(0)
