extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	var walker = museum.get("_player")
	if walker is Node3D: walker.visible = false
	var previous = museum.get("_cam")
	if previous is Node3D: previous.visible = false
	camera.set_cull_mask_value(19, false)
	var wardrobe = museum.get("_wardrobe")
	if wardrobe != null and is_instance_valid(wardrobe.get("costume")): wardrobe.get("costume").visible = false
	var tree = find_scene("/recursivetree/recursive_tree.gd")
	check("Existing recursive tree remains in its authored hall", tree != null)
	if tree == null: return
	var desk = tree.get_node("TreeLesson")
	check("Hand model and full canopy installed in production", desk.hand_fork != null and desk._canopy != null)
	var fork = desk.hand_fork
	await snapshot("arrival", tree.to_global(Vector3(-2.5, 1.65, 3.2)), tree.to_global(Vector3(0, 1.5, 0)), 75)
	for i in 4: desk.act("GROW")
	await create_timer(0.3).timeout
	await snapshot("hand-model", fork.to_global(Vector3(0.75, 1.65, 1.65)), fork.to_global(Vector3(0, 1.40, -0.05)), 58)
	await snapshot("before-turn", tree.to_global(Vector3(-2.5, 1.65, 3.2)), tree.to_global(Vector3(-2.0, 3.2, -1.2)), 84)
	var origin := XROrigin3D.new(); root.add_child(origin)
	var controller := XRController3D.new(); origin.add_child(controller)
	var hand = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate(); controller.add_child(hand)
	var grip = fork.grips[0]
	controller.global_position = grip.global_position; grip.pick_up(hand)
	await create_timer(0.15).timeout
	controller.global_position = fork.model.to_global(Vector3(0.95, 1.90, 0.8))
	await create_timer(0.5).timeout
	var direction: Vector3 = tree.generated.get_child(1).get_meta("branch_data").direction
	check("Actual museum point steers through the XR grab driver", direction.z > 0.4)
	await snapshot("after-turn", tree.to_global(Vector3(-2.5, 1.65, 3.2)), tree.to_global(Vector3(-2.0, 3.2, -1.2)), 84)
	grip.let_go(hand, Vector3.ZERO, Vector3.ZERO)
	await create_timer(0.2).timeout
	await snapshot("under-canopy", desk._canopy.to_global(Vector3(-1.5, 0.92, 3.4)), desk._canopy.to_global(Vector3(0, 1.6, 0)), 80)
	await snapshot("above", hall.to_global(Vector3(2, 12, 5)), hall.to_global(Vector3(8.5, 0, 13)), 65)
	for point in fork.grips:
		var height: float = point.global_position.y - hall.global_position.y
		check("Point within standing reach: " + str(point.name), height > 1.15 and height < 1.8)
	var approach: Vector3 = fork.to_global(Vector3(0, 0, 0.95))
	check("Hand-model approach has actual museum floor", not floor_at(approach).is_empty())
	var route: Array[Vector3] = [Vector3(8.5, 0, 6), Vector3(8.5, 0, 15), Vector3(14.5, 0, 15), Vector3(14.5, 0, 25), Vector3(8.5, 0, 25)]
	for i in range(route.size() - 1):
		var supported := true; var clear := true
		var steps := ceili(route[i].distance_to(route[i + 1]) / 0.4)
		for j in range(steps + 1):
			var at: Vector3 = hall.to_global(route[i].lerp(route[i + 1], float(j) / steps))
			supported = supported and not floor_at(at).is_empty()
			var shape := CapsuleShape3D.new(); shape.radius = 0.26; shape.height = 1.6
			var q := PhysicsShapeQueryParameters3D.new(); q.shape = shape; q.transform.origin = at + Vector3.UP * 0.91; q.collision_mask = 1 | 4
			for hit in hall.get_world_3d().direct_space_state.intersect_shape(q, 8):
				if is_instance_valid(walker) and (hit.collider == walker or walker.is_ancestor_of(hit.collider)): continue
				clear = false
				observations.get_or_add("obstructions", []).append(str(hit.collider.get_path()))
		check("Route floor %d" % i, supported)
		check("Route clearance %d" % i, clear)
	observations.direction_after_turn = xyz(direction)
	observations.segment_count = tree.segment_count
	observations.scope = "Production map, actual XRTools grab with supplied poses; six rendered views. Route sampled every 0.4 m, not every possible path. Headset comfort untested."
	origin.queue_free()
