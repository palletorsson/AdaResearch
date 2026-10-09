extends "res://tools/probes/fractal_hand_fork_museum.gd"

func landing_checks() -> void:
	await super.landing_checks()
	var source = find_scene("/recursivetree/recursive_tree.gd")
	var desk = source.get_node("TreeLesson")
	var readings = desk.tree_readings
	check("Plan and side readings are installed in the real tree hall", readings != null)
	if readings == null: return
	desk.act("RESET")
	for i in 4: desk.act("GROW")
	await create_timer(0.3).timeout
	readings.act("KEEP")
	await snapshot("two-readings-before", readings.to_global(Vector3(0, 1.8, 1.6)), readings.to_global(Vector3(0, 1.82, 0)), 70)
	var origin := XROrigin3D.new(); root.add_child(origin)
	var controller := XRController3D.new(); origin.add_child(controller)
	var hand = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate(); controller.add_child(hand)
	var point = desk.hand_fork.grips[0]
	controller.global_position = point.global_position; point.pick_up(hand)
	await create_timer(0.15).timeout
	controller.global_position = desk.hand_fork.model.to_global(Vector3(0.95, 1.9, 0.8))
	await create_timer(0.5).timeout
	point.let_go(hand, Vector3.ZERO, Vector3.ZERO)
	await create_timer(0.2).timeout
	check("Live hall drawings change while chosen endpoints remain", readings.saved != readings.current and readings.saved.size() == 31 and readings.current.size() == 31)
	await snapshot("two-readings-after", readings.to_global(Vector3(0, 1.8, 1.6)), readings.to_global(Vector3(0, 1.82, 0)), 70)
	await snapshot("readings-and-canopy", source.to_global(Vector3(-3.2, 1.8, 3.5)), source.to_global(Vector3(-1.2, 2.1, -0.2)), 90)
	var approach: Vector3 = readings.to_global(Vector3(0, 0, 0.95))
	check("Reading station has floor beneath its approach", not floor_at(approach).is_empty())
	var shape := CapsuleShape3D.new(); shape.radius = 0.28; shape.height = 1.6
	var query := PhysicsShapeQueryParameters3D.new(); query.shape = shape; query.transform.origin = approach + Vector3.UP * 0.91; query.collision_mask = 1 | 4
	var hits: Array = hall.get_world_3d().direct_space_state.intersect_shape(query)
	observations.reading_obstructions = hits.map(func(hit): return str(hit.collider.get_path()))
	check("Standing body has clearance at the reading station", hits.is_empty())
	var walker = museum.get("_player")
	if walker is Node3D:
		walker.set_process(false); walker.set_physics_process(false); walker.global_position = Vector3(0,-100,0)
	var driver = load("res://commons/testing/wcn_desktop_driver.gd").new(); museum.add_child(driver)
	driver.spawn(approach, museum)
	await create_timer(0.2).timeout
	var pressed: Dictionary = await driver.press(readings.buttons["CLEAR"], approach)
	check("Actual desktop ray reaches CLEAR without changing live tree", str(pressed.get("hover","")) not in ["","none","null","nothing"] and readings.saved.is_empty() and source.segment_count == 31)
	pressed = await driver.press(readings.buttons["KEEP"], approach)
	check("Actual desktop ray keeps the current reading", str(pressed.get("hover","")) not in ["","none","null","nothing"] and readings.saved == readings.current)
	driver.teardown(); origin.queue_free()
	observations.scope = "Real museum: inherited hand/canopy route checks plus live/kept projections, standing clearance, actual ray button input and new native captures. Supplied poses; no headset test."
