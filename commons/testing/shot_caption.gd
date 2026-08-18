extends SceneTree
## A still of a body with its inventory caption.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(m)
	await create_timer(3.0).timeout
	var target: Node3D = null
	for r in (m.get("_edit_records") as Array):
		var rd: Dictionary = r
		if String(rd.get("kind", "artifact")) in ["artifact", ""] and rd.has("inv"):
			target = rd.get("node") as Node3D
			print("caption target: %s  %s" % [rd.get("token"), rd.get("inv")])
			break
	if target == null: print("no numbered body"); quit(1); return
	var cam := Camera3D.new(); get_root().add_child(cam)
	cam.global_position = target.global_position + Vector3(0.15, 1.45, -2.0)
	cam.look_at(target.global_position + Vector3(0.0, 0.80, -0.80), Vector3.UP)
	cam.fov = 55.0
	cam.make_current()
	await create_timer(0.6).timeout
	await process_frame; await process_frame
	var img: Image = get_root().get_viewport().get_texture().get_image()
	if img != null: img.save_png("user://em_caption.png"); print("shot -> user://em_caption.png")
	quit(0)
