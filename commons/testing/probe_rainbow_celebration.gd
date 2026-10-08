extends "res://commons/testing/probe_color_recovery.gd"

func run() -> void:
	await museum("Color_Rainbow")
	var party: Node3D
	for n in current_scene.find_children("*", "Node3D", true, false):
		if n.get_script() != null and n.get_script().resource_path.ends_with("rainbow_celebration.gd"):
			party = n
			break
	check(party != null, "celebration replaces the miniature rainbow placement")
	if party == null:
		quit(1)
		return
	var player: CharacterBody3D = current_scene.get("_player")
	var cam: Camera3D = current_scene.get("_cam")
	player.set_physics_process(false)
	current_scene.get("_feel").set_process(false)
	player.global_position += party.to_global(Vector3(0, 1.65, 10.3)) - cam.global_position
	cam.look_at(party.to_global(Vector3(0, 2.1, -0.5)))
	for frame in range(20):
		current_scene.call("_cull_artifacts")
		await process_frame
	check(party.buttons.size() == 2, "two real push-button controls")
	check(party.arch.rainbow_colors.size() == 6, "six-band arrival")
	var widths: Array[float] = []
	var geometry: Array[Transform3D] = []
	for tile in party.tiles:
		geometry.append(tile.transform)
	for count in [7,48,2,6]:
		party.buttons[0].pressed.emit()
		await process_frame
		await process_frame
		check(party.arch.rainbow_colors.size() == count, "%d actual generated bands" % count)
		check(party.arch._arc_roots[0].get_child_count() == count, "mesh band count agrees with palette")
		widths.append(party.arch._band_thickness() * count)
		for i in range(party.tiles.size()):
			check(party.tiles[i].transform == geometry[i], "re-dividing leaves route geometry fixed")
	check(widths.all(func(w): return is_equal_approx(w,5.6)), "total band width fixed across all four partitions")
	check(party.arch._arc_roots.size() == 2, "primary and reversed secondary arcs remain")
	check(party.confetti.multimesh.instance_count == 96, "confetti uses a bounded 96-instance mesh")
	party.buttons[1].pressed.emit()
	party._process(0.9)
	check(party.confetti.visible, "celebrate button produces visible confetti")
	party._process(4.0)
	check(not party.confetti.visible, "confetti ends without accumulating instances")
	party.buttons[1].pressed.emit()
	check(party.confetti.visible, "celebration can be repeated")
	var before: int = party.celebration_count
	var viewing_position: Vector3 = player.global_position
	player.global_position = party.trigger.global_position
	for frame in range(12):
		await physics_frame
	check(party.celebration_count == before + 1, "physical visitor overlap triggers the welcome celebration")
	player.global_position = viewing_position
	# Let the worn body's normal follow smoothing settle after the trigger test.
	await create_timer(1.0).timeout
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.5
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	query.transform.origin = party.to_global(Vector3(0, 0.85, 10))
	query.motion = party.global_basis * Vector3(0,0,-19)
	check(current_scene.get_world_3d().direct_space_state.cast_motion(query)[0] > 0.99, "continuous level centre route admits the player body")
	for i in range(8):
		var tile: MeshInstance3D = party.tiles[i]
		check(tile.find_children("*", "StaticBody3D", true, false).size() == 1, "optional step has collision")
	party.celebrate()
	party.set_process(false)
	party._process(0.8)
	for frame in range(20):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://ada_run/rainbow_celebration_museum.png")
	var report := {"checks":checks,"failures":failures,"headset_tested":false,"input":"Actual button signals and physics overlap with museum walker; headset interaction untested"}
	var f := FileAccess.open("res://ada_run/probe_rainbow_celebration.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "))
	print("RAINBOW_CELEBRATION ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
