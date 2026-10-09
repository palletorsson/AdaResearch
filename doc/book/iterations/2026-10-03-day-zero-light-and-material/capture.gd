extends SceneTree

var destination: String

func _initialize() -> void:
	destination = OS.get_cmdline_user_args()[0]
	call_deferred("run")

func capture(path: String) -> void:
	for i in 40:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(destination.path_join(path))

func run() -> void:
	var room = load("res://main.tscn").instantiate()
	root.add_child(room)
	for i in 45:
		await physics_frame
	room.get_node("Study").set_process(false)
	room.get_node("Study").display.text = "48"
	await capture("after.png")
	room.player.position = Vector3(-0.6, 0, 1.2)
	room.player.camera.look_at(Vector3(-1.65, 1.04, -0.2))
	await capture("material.png")
	room.get_node("KeyLight").light_energy = 0.0
	await capture("key-off.png")
	room.queue_free()
	await process_frame
	await process_frame
	quit()
