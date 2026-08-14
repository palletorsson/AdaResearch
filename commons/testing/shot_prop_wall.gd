extends SceneTree
## One photograph of the prop reference wall — the deliverable is a page you
## can open, and a page wants a picture.
##   godot --path . --xr-mode off --no-window --script res://commons/testing/shot_prop_wall.gd

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var inst: Node3D = (load("res://commons/scenes/prop_reference_wall.tscn") as PackedScene).instantiate()
	get_root().add_child(inst)
	for i in range(10):
		await process_frame
	var cam: Camera3D = inst.get("_cam")
	# framed from BEFORE the first token, so the extinguisher (x=3) is in shot
	cam.global_position = Vector3(56.0, 1.9, 7.0)
	cam.look_at(Vector3(70.0, 1.0, 1.5))
	for i in range(20):
		await process_frame
	var img: Image = get_root().get_texture().get_image()
	img.save_png("user://prop_wall_shot.png")
	print("[prop-wall] shot -> user://prop_wall_shot.png")
	quit(0)
