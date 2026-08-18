extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(m)
	await create_timer(4.0).timeout
	await physics_frame
	var space := m.get_world_3d().direct_space_state
	for y in [3.0, 3.2, 3.4, 3.6, 3.8, 4.0, 4.3]:
		var q := PhysicsRayQueryParameters3D.create(Vector3(7.5, y, 1.5), Vector3(7.5, y, 6.0))
		var r: Dictionary = space.intersect_ray(q)
		if r.is_empty(): print("RAY y=%.1f: nothing" % y)
		else: print("RAY y=%.1f: hit z=%.2f (%s / %s)" % [y, r.position.z, (r.collider as Node).name, (r.collider as Node).get_parent().name])
	# and every MeshInstance/MultiMesh whose AABB contains (7.5, 3.6, 3.7)
	var stack: Array = [m]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children(): stack.append(c)
		if n is VisualInstance3D:
			var box: AABB = (n as VisualInstance3D).global_transform * (n as VisualInstance3D).get_aabb()
			if n is Light3D: continue
			for zz in [1.6, 2.0, 2.5, 3.0, 3.3, 3.6, 3.9, 4.2, 4.6]:
				if box.has_point(Vector3(7.5, 3.6, zz)) and box.size.y < 4.0:
					print("VIS z=%.1f %s (%s) y %.2f..%.2f z %.2f..%.2f x %.1f..%.1f" % [zz, n.name, n.get_class(), box.position.y, box.end.y, box.position.z, box.end.z, box.position.x, box.end.x])
	quit(0)
