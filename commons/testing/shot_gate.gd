extends SceneTree
## A still of the sealed threshold from the vestibule.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(m)
	await create_timer(2.5).timeout
	var gate2: Dictionary = m.get("_gate")
	if gate2.is_empty(): print("no gate"); quit(1); return
	var d: Node3D = gate2.get("door")
	var sc: Node3D = gate2.get("scanner")
	# a FREE camera: the walker's own is driven by em_feel every frame
	var cam := Camera3D.new()
	get_root().add_child(cam)
	cam.global_position = d.global_position + Vector3(-2.2, 1.75, -2.6)
	cam.look_at(sc.global_position + Vector3(-0.3, -0.1, 0.0), Vector3.UP)
	cam.fov = 70.0
	cam.make_current()
	await create_timer(0.6).timeout
	await process_frame; await process_frame
	var img: Image = get_root().get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("user://em_gate.png"); print("shot -> user://em_gate.png")
	quit(0)
