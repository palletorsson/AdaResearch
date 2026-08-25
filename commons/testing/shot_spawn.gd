extends SceneTree
## What the walker sees at spawn in a plain desktop run — no flags, no editor.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(m)
	await create_timer(3.5).timeout
	var pl: Node3D = m.get("_player")
	var cam := Camera3D.new(); get_root().add_child(cam)
	cam.global_position = (pl.global_position if pl != null else Vector3(7.5, 0, 1.5)) + Vector3(0, 1.7, 0)
	cam.look_at(cam.global_position + Vector3(0, -0.12, 1), Vector3.UP)
	cam.fov = 75.0
	cam.make_current()
	await create_timer(0.5).timeout
	await process_frame; await process_frame
	var img: Image = get_root().get_viewport().get_texture().get_image()
	if img != null: img.save_png("user://em_spawn.png"); print("shot -> user://em_spawn.png")
	print("[state] records=%d inventory=%d gate=%s segments=%d" % [
		(m.get("_edit_records") as Array).size(), (m.get("_inventory") as Array).size(),
		"sealed" if not (m.get("_gate") as Dictionary).is_empty() else "none/open",
		(m.get("_segments") as Array).size()])
	quit(0)
