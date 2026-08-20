extends SceneTree
## SHOT: the wall fit reference, photographed for the record
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/wall_fit_reference.tscn") as PackedScene).instantiate() as Node3D
	get_root().add_child(m)
	await create_timer(2.5).timeout
	var cam: Camera3D = m.get("_cam")
	cam.position = Vector3(5.5, 1.65, 4.5)
	cam.rotation = Vector3(-0.02, 3.14159, 0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await create_timer(0.5).timeout
	await get_root().get_viewport().get_texture().get_image().save_png("user://wall_fit_ref.png")
	print("SHOT saved")
	quit(0)
