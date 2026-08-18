extends SceneTree
## Photograph the gate from the vestibule (run WITHOUT --headless).
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(m)
	await create_timer(5.0).timeout
	var cam := Camera3D.new()
	cam.fov = 80
	get_root().add_child(cam)
	cam.global_position = Vector3(7.5, 1.6, 0.6)
	cam.look_at(Vector3(7.5, 1.3, 4.5), Vector3.UP)
	cam.current = true
	await create_timer(1.5).timeout
	await process_frame
	await process_frame
	var img: Image = get_root().get_texture().get_image()
	img.save_png("user://em_gate_shot.png")
	print("GATE SHOT saved %dx%d" % [img.get_width(), img.get_height()])
	quit(0)
