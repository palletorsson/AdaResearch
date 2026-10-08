extends SceneTree

## Visual proof of the first-frame VR loading cell. Captures before the deferred
## museum boot is allowed past its first process-frame yield.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node3D.new()
	get_root().add_child(world)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.032, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.45
	environment.environment = env
	world.add_child(environment)
	var camera := Camera3D.new()
	camera.position = Vector3(7.5, 1.65, 1.15)
	camera.look_at_from_position(camera.position, Vector3(7.5, 2.05, 4.0))
	camera.current = true
	world.add_child(camera)
	var museum := (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	museum.set("_force_vr", true)
	world.add_child(museum)
	await process_frame
	await RenderingServer.frame_post_draw
	var image := get_root().get_texture().get_image()
	image.save_png("res://ada_run/em_loading_cell.png")
	print("[loading-cell-shot] res://ada_run/em_loading_cell.png")
	quit(0)
