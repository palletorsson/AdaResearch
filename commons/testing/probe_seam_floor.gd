extends SceneTree
## Floor height across a seam: ray down at (x, z) for z in a range.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json"); m.set("_first_chapter", "primitives")
	get_root().add_child(m); await create_timer(0.8).timeout
	m.call("_build_segment"); await create_timer(0.3).timeout
	await physics_frame; await physics_frame
	var space := m.get_world_3d().direct_space_state
	for z in [116.5, 118.5, 119.5, 120.2, 120.5, 121.5, 123.5, 125.5]:
		var line := "z %6.1f:" % z
		for x in [3.5, 6.5, 9.5, 12.5]:
			var q := PhysicsRayQueryParameters3D.create(Vector3(x, 3.0, z), Vector3(x, -5.0, z))
			var hit := space.intersect_ray(q)
			line += "  x%4.1f y=%s" % [x, ("%.2f" % hit.position.y) if hit else "none"]
		print(line)
	quit(0)
