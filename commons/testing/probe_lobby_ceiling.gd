extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(m)
	await create_timer(4.0).timeout
	var stack: Array = [m]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children(): stack.append(c)
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var mi := n as MeshInstance3D
			var box: AABB = mi.global_transform * mi.mesh.get_aabb()
			if box.has_point(Vector3(7.5, 3.6, 3.85)) or box.has_point(Vector3(7.5, 3.6, 4.15)):
				print("CEIL? %s (%s) y %.2f..%.2f x %.1f..%.1f z %.1f..%.1f" % [mi.name, mi.get_parent().name, box.position.y, box.end.y, box.position.x, box.end.x, box.position.z, box.end.z])
	quit(0)
