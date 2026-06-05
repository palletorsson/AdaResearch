extends SceneTree
## Real GPU render of batched softbody_flora — confirms the cap wobble shader
## COMPILES and the MultiMesh flora render. Saves to user:// (NOT the repo).
## Run (needs GPU — use --no-window): godot --no-window --xr-mode off --path . \
##   --script res://commons/testing/test_softbody_render.gd

const Flora = preload("res://commons/biome_layers/softbody_flora.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var root := get_root()
	root.world_3d = World3D.new()
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.10, 0.11, 0.14)
	e.ambient_light_color = Color(0.8, 0.8, 0.8)
	e.ambient_light_energy = 1.0
	env.environment = e
	root.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	root.add_child(light)

	var node := Node3D.new()
	node.set_script(Flora)
	root.add_child(node)
	node.call("apply", {
		"params": {}, "grid_dims": Vector3i(10, 1, 10), "cube_size": 1.0,
		"grid_center": Vector3(5, 0, 5), "rng_seed": 7, "budget_scale": 1.0,
		"paint_layers": [
			{"element": "flower", "mode": "plane", "density": 0.5},
			{"element": "mushroom", "mode": "random", "density": 0.3},
		],
	})

	var cam := Camera3D.new()
	root.add_child(cam)
	cam.look_at_from_position(Vector3(5, 5, 13), Vector3(5, 0.4, 5), Vector3.UP)
	cam.make_current()

	for i in 6:
		await process_frame
	await create_timer(0.3).timeout

	var img := root.get_texture().get_image()
	img.save_png("user://softbody_batch_render.png")
	print("RENDER SAVED ", ProjectSettings.globalize_path("user://softbody_batch_render.png"))
	quit(0)
