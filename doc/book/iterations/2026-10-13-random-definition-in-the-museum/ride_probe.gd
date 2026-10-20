extends "res://tools/probes/transformation_encounters.gd"

class HandStub extends Node3D:
	var picked_up_ranged := false

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	if map_id == "Randomness_10_PRINT_Algorithm":
		var textile := find_scene("/dna_comparison.gd")
		check("textiles installed in 10 PRINT",textile != null and textile.textile)
		if textile == null: return
		check("textile approach has floor",not floor_at(textile.to_global(Vector3(0,0,-2.4))).is_empty())
		await snapshot("textiles-in-ten-print",textile.to_global(Vector3(0,1.65,-4.8)),textile.to_global(Vector3(0,0.95,0)),57)
		await snapshot("ten-print-with-textiles",textile.to_global(Vector3(-3.6,2.5,-5.8)),textile.to_global(Vector3(0,0.9,0)),65)
		return
	var ride := find_scene("/random_return.gd")
	check("return sphere installed in Random Definition",ride != null)
	check("textiles no longer occupy Random Definition",find_scene("/dna_comparison.gd") == null)
	if ride == null: return
	ride.set_physics_process(false)
	ride.restart(42)
	var destinations: Array[Vector3] = []
	var bounded := true
	for i in range(100):
		destinations.append(ride.destination)
		bounded = bounded and ride.destination.length()>=1.1 and ride.destination.length()<=2.2
		bounded = bounded and ride.route_position(0).is_equal_approx(ride.CENTRE) and ride.route_position(ride.CYCLE_SECONDS).is_equal_approx(ride.CENTRE)
		ride.advance(ride.CYCLE_SECONDS)
	check("100 excursions stay in range and return to the centre",bounded)
	ride.restart(42)
	var repeats := true
	for expected in destinations:
		repeats = repeats and ride.destination.is_equal_approx(expected)
		ride.advance(ride.CYCLE_SECONDS)
	check("same seed repeats all 100 destinations",repeats)
	ride.restart(43)
	check("next seed changes the first destination",not ride.destination.is_equal_approx(destinations[0]))
	ride.restart(42)
	check("ride centre has real museum floor",not floor_at(ride.global_position).is_empty())
	var body: CharacterBody3D = museum.get("_player")
	var hand: Node3D = body.get_node("DesktopHand")
	body.global_position = ride.to_global(Vector3(0,0.01,-0.7))
	body.velocity = Vector3.ZERO
	for i in range(12):
		await physics_frame
		body.velocity = Vector3.DOWN
		body.move_and_slide()
	var home := body.global_position
	var view_before := body.global_basis
	hand.call("_grab_held",ride.point)
	ride._physics_process(0.0)
	check("desktop pickup resolves museum player as rider",ride.rider == body and ride.point.held())
	var point_before: Vector3 = ride.point.global_position
	hand.call("_process",0.016)
	check("desktop hand does not pull the sphere off its route",ride.point.global_position.is_equal_approx(point_before))
	check("replay refuses to teleport a held rider",not ride.restart(99) and ride.route_seed == 42)
	var distance := 0.0
	for i in range(510):
		await physics_frame
		ride._physics_process(1.0/60.0)
		body.velocity = ride.carry_velocity(body,1.0/60.0,body.velocity)
		body.move_and_slide()
		distance = maxf(distance,body.global_position.distance_to(home))
	check("held sphere carries the actual player out and back",distance>1.0 and body.global_position.distance_to(home)<0.1)
	check("riding leaves the view orientation unchanged",body.global_basis.is_equal_approx(view_before))
	observations["ride_distance_metres"] = distance
	observations["return_error_metres"] = body.global_position.distance_to(home)
	hand.call("_drop_held")
	ride._physics_process(0.0)
	check("desktop release immediately ends carry",ride.rider == null and not ride._point_inside(body.global_position))
	var released := body.global_position
	for i in range(20): ride._physics_process(0.05)
	check("unheld sphere does not move the player",body.global_position.is_equal_approx(released))
	# XR Tools' own driver retains grab ownership without driving the sphere pose.
	var xr_hand := HandStub.new()
	root.add_child(xr_hand)
	xr_hand.global_position = ride.point.global_position
	point_before = ride.point.global_position
	ride.point.pick_up(xr_hand)
	xr_hand.position += Vector3(2,1,0)
	await tick()
	check("XR grab retains path ownership",ride.point.is_picked_up() and ride.point.global_position.is_equal_approx(point_before))
	ride.point.let_go(xr_hand,Vector3.ZERO,Vector3.ZERO)
	check("XR release clears grab ownership",not ride.point.is_picked_up())
	xr_hand.queue_free()
	# Collision is exercised on the same museum CharacterBody, not inferred.
	ride.restart(42)
	ride.destination = Vector3(2.2,0,0)
	body.global_position = home
	body.velocity = Vector3.ZERO
	var wall := StaticBody3D.new()
	root.add_child(wall)
	wall.global_position = home+Vector3(0.8,1,0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.2,2,4)
	shape.shape = box
	wall.add_child(shape)
	await tick()
	hand.call("_grab_held",ride.point)
	ride._physics_process(0.0)
	for i in range(300):
		await physics_frame
		ride._physics_process(1.0/60.0)
		body.velocity = ride.carry_velocity(body,1.0/60.0,body.velocity)
		body.move_and_slide()
	check("ride cannot carry the player through a wall",body.global_position.x < home.x+0.7 and body.global_position.x>home.x+0.05)
	hand.call("_drop_held")
	ride._physics_process(0.0)
	wall.queue_free()
	await tick()
	ride.restart(42)
	body.global_position = home+Vector3(5,0,-6)
	await snapshot("return-centre",ride.to_global(Vector3(-3.5,1.65,-5.5)),ride.to_global(Vector3(0,1.2,0)),62)
	ride.advance(ride.WAIT_SECONDS+ride.LEG_SECONDS)
	await tick()
	check("outward sphere pose persists across the physics frame",ride.point.position.is_equal_approx(ride.CENTRE+ride.destination))
	observations["outward_point_local"] = xyz(ride.point.position)
	await snapshot("return-outward",ride.to_global(Vector3(-3.5,1.65,-5.5)),ride.to_global(Vector3(0,1.2,0)),62)
	var demo := find_scene("/seed_replay_demo.gd")
	demo.restore_museum_state({"seed":42,"extra_on":false,"side":8})
	await snapshot("seed-before",demo.to_global(Vector3(0,2,4.4)),demo.to_global(Vector3(0,1.9,0)),53)
	demo.toggle_extra_draw()
	await snapshot("seed-after",demo.to_global(Vector3(0,2,4.4)),demo.to_global(Vector3(0,1.9,0)),53)
	var book := find_scene("/random_number_book_page_1995.gd")
	await snapshot("number-page",book.to_global(Vector3(0,0,-8)),book.global_position,51)
	observations["scope"] = "Actual museum, real desktop grab/drop hooks, XR Tools grab driver, bounded seeded route, real CharacterBody movement and wall collision. Physical headset acceptance remains untested."

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()},"  "))
	print("RANDOM RETURN ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
