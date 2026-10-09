extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	var walker = museum.get("_player")
	if walker is Node3D:
		walker.hide(); walker.set_process(false); walker.set_physics_process(false)
		walker.global_position = Vector3(0, -100, 0)
	var previous = museum.get("_cam")
	if previous is Node3D: previous.hide()
	camera.set_cull_mask_value(19, false)
	var wardrobe = museum.get("_wardrobe")
	if wardrobe != null and is_instance_valid(wardrobe.get("costume")): wardrobe.get("costume").hide()
	var source = find_scene("/cantorset/cantor_set.gd")
	var pagoda = find_scene("/example_8_4_cantor_pagoda_vr.gd")
	check("Both authored Cantor anchors remain in the museum", source != null and pagoda != null)
	if source == null or pagoda == null: return
	observations.source_in_hall = xyz(hall.to_local(source.global_position))
	observations.pagoda_in_hall = xyz(hall.to_local(pagoda.global_position))
	# Reconstruct the pre-edit fixture from the saved file, in this isolated run.
	var desk = source.get_node("CantorLesson")
	source.remove_child(desk); desk.free()
	var old = load("res://doc/book/iterations/2026-10-08-cantor-a-cut-in-the-hand/before/cantor_lesson.gd").new()
	source.add_child(old)
	await snapshot("before", source.to_global(Vector3(-1.0, 1.7, 3.2)), source.to_global(Vector3(0.3, 1.3, 0.5)), 86)
	source.remove_child(old); old.free()
	desk = load("res://commons/artifacts/cantor_lesson/cantor_lesson.gd").new()
	desk.name = "CantorLesson"; source.add_child(desk)
	await create_timer(0.25).timeout
	var cut = desk.hand_cut
	await snapshot("arrival", source.to_global(Vector3(-1.0, 1.7, 3.2)), source.to_global(Vector3(0.3, 1.3, 0.5)), 86)
	await snapshot("hand-model", cut.to_global(Vector3(0.5, 1.65, 1.05)), cut.to_global(Vector3(0, 1.3, 0)), 62)
	var origin := XROrigin3D.new(); root.add_child(origin)
	var controller := XRController3D.new(); origin.add_child(controller)
	var hand = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate(); controller.add_child(hand)
	controller.global_position = cut.grip.global_position; cut.grip.pick_up(hand)
	await create_timer(0.15).timeout
	controller.global_position = cut.to_global(cut.HOME + Vector3(0, 0.08, 0.43))
	await create_timer(0.25).timeout
	check("Production hand model arms without changing the current row", cut.armed and source.current_iteration == 0)
	await snapshot("pull", cut.to_global(Vector3(0.7, 1.65, 1.12)), cut.to_global(Vector3(0, 1.32, 0.15)), 65)
	cut.grip.let_go(hand, Vector3.ZERO, Vector3.ZERO)
	await create_timer(0.2).timeout
	check("Production XR release makes exactly two outer intervals", source.current_iteration == 1 and source.current_bars.size() == 2)
	for i in 3: desk.act("NEXT")
	await snapshot("latest", source.to_global(Vector3(-1.0, 1.65, 3.2)), source.to_global(Vector3(0, 1.2, 0.2)), 86)
	desk.act("HISTORY"); desk.act("GHOST")
	await snapshot("history", source.to_global(Vector3(-1.0, 1.65, 3.2)), source.to_global(Vector3(0, 1.2, 0.2)), 86)
	check("Reachable grip has floor in front of its plinth", not floor_at(cut.to_global(Vector3(0, 0, 0.95))).is_empty())
	var body_shape := CapsuleShape3D.new(); body_shape.radius = 0.3; body_shape.height = 1.6
	var query := PhysicsShapeQueryParameters3D.new(); query.shape = body_shape; query.collision_mask = 1 | 4
	query.transform.origin = cut.to_global(Vector3(0, 0.91, 0.95))
	var obstructions: Array = hall.get_world_3d().direct_space_state.intersect_shape(query)
	observations.hand_approach_obstructions = obstructions.map(func(hit): return str(hit.collider.get_path()))
	check("Standing body has clearance at the hand model", obstructions.is_empty())
	var height: float = cut.grip.global_position.y - hall.global_position.y
	check("Grip at standing reach", height > 1.1 and height < 1.6)
	var driver = load("res://commons/testing/wcn_desktop_driver.gd").new(); museum.add_child(driver)
	driver.spawn(desk.to_global(Vector3(0, 0.001, 2.65)), museum)
	await create_timer(0.25).timeout
	var pressed: Dictionary = await driver.press(desk.buttons["RESET"], desk.to_global(Vector3(0, 0.001, 2.65)))
	check("Existing desktop ray reaches nearby RESET", str(pressed.get("hover", "")) not in ["", "none", "null", "nothing"] and source.current_iteration == 0)
	var vest: int = int(museum.get("VESTIBULE_H"))
	driver.rig.global_position = hall.to_global(Vector3(11.5, 0.001, 4.4 + vest)); driver.rig.velocity = Vector3.ZERO
	await physics_frame
	await walk_to(driver, hall.to_global(Vector3(11.5, 1.001, 8.5 + vest)))
	check("Existing ramp carries the actual desktop body onto the deck", driver.rig.global_position.distance_to(hall.to_global(Vector3(11.5, 1.001, 8.5 + vest))) < 0.65)
	var pd = pagoda.get_node("CantorLesson"); pd.set_stage(3)
	for pair in [[9.5, 3.0], [6.5, 1.0], [5.5, 1.0 / 3.0]]:
		driver.rig.global_position = hall.to_global(Vector3(pair[0], 1.001, 10 + vest)); driver.rig.velocity = Vector3.ZERO
		await physics_frame
		await walk_to(driver, hall.to_global(Vector3(pair[0], 1.001, 15 + vest)))
		var end := hall.to_local(driver.rig.global_position)
		check("%.3f m opening: body %s" % [pair[1], "passes" if pair[1] >= 1.0 else "stops"], end.z - vest > 14.5 if pair[1] >= 1.0 else end.z - vest < 11.5)
		observations.get_or_add("gap_tests", []).append({"width": pair[1], "endpoint": xyz(end)})
	driver.teardown()
	await snapshot("pagoda", hall.to_global(Vector3(14.5, 2.65, 9.6 + vest)), pagoda.to_global(Vector3(0, 2, 0)), 76)
	await snapshot("above", hall.to_global(Vector3(16.5, 14, 1.5 + vest)), hall.to_global(Vector3(9.5, 0.8, 12 + vest)), 68)
	# Exact printed lesson, placed in the existing room just for this capture.
	var study = load("res://ada_run/cantor_student/cantor.gd").new()
	study.position = hall.to_local(source.to_global(Vector3(-3.5, 0, 1.8))); study.rotation = source.rotation; hall.add_child(study)
	study.show_history = true
	for i in 3: study.advance()
	await snapshot("student", study.to_global(Vector3(0.3, 1.7, 1.35)), study.to_global(Vector3(0, 1.45, 0.15)), 65)
	check("Printed lesson builds beside existing artifacts in museum", study.current.size() == 8 and study.rows.get_child_count() == 15)
	study.queue_free(); origin.queue_free()
	observations.scope = "Native museum; synthetic XR poses and desktop ray/walking inputs. Before fixture reconstructed from pre-edit backup. Exact printed study temporarily added only for its capture. No physical headset test."

func walk_to(driver, target: Vector3) -> void:
	var start: Vector3 = driver.rig.global_position
	driver.aim_at(target + Vector3.UP * 1.6)
	await driver.walk("ui_up", int(Vector2(target.x - start.x, target.z - start.z).length() * 12))
