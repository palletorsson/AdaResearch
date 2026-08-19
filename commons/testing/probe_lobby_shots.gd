extends SceneTree
## Photograph the lobby (run WITHOUT --headless): door+sign, window+view, lift corner.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(m)
	await create_timer(5.0).timeout
	var cam := Camera3D.new()
	cam.fov = 85
	get_root().add_child(cam)
	cam.current = true
	var shots: Array = [
		["door", Vector3(7.5, 1.6, 1.3), Vector3(7.5, 1.6, 4.5)],
		["enter", Vector3(7.5, 1.6, 5.2), Vector3(7.5, 1.3, 12.0)],
		["origin", Vector3(10.0, 1.5, 6.3), Vector3(12.5, 0.7, 8.5)],
		["speak", Vector3(8.0, 1.6, 5.1), Vector3(10.1, 1.1, 6.8)],
		["plaque", Vector3(11.2, 1.3, 7.3), Vector3(12.5, 0.9, 8.3)],
		["enter_right", Vector3(7.5, 1.6, 5.4), Vector3(3.0, 1.0, 8.5)],
		["enter_left", Vector3(7.5, 1.6, 5.4), Vector3(12.5, 1.0, 8.5)],
		["door_up", Vector3(7.5, 1.2, 1.2), Vector3(7.5, 3.4, 4.5)],
		["window", Vector3(7.5, 1.6, 3.8), Vector3(7.5, 1.4, 0.5)],
		["lift", Vector3(9.0, 1.6, 3.6), Vector3(15.5, 1.0, 2.2)],
		["west", Vector3(8.0, 1.5, 3.2), Vector3(1.0, 0.9, 2.6)],
	]
	for sh in shots:
		cam.global_position = sh[1]
		cam.look_at(sh[2], Vector3.UP)
		await create_timer(0.8).timeout
		await process_frame
		await process_frame
		var img: Image = get_root().get_texture().get_image()
		img.save_png("user://em_lobby_%s.png" % sh[0])
		print("LOBBY SHOT %s" % sh[0])
	quit(0)
