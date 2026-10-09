extends "res://doc/book/iterations/2026-09-19-color-review/fields/probes/recovery.gd"

func colour_close(a: Color, b: Color) -> bool:
	return maxf(absf(a.r-b.r), maxf(absf(a.g-b.g), absf(a.b-b.b))) <= 1.0/255.0

func run() -> void:
	await museum("Color_Grid_Pallet")
	var lesson: Node3D
	for n in current_scene.find_children("*", "Node3D", true, false):
		if n.get_script() and n.get_script().resource_path.ends_with("address_lesson.gd"):
			lesson = n
	check(lesson != null, "address console exists in the actual museum")
	if lesson == null:
		quit(1)
		return
	for frame in range(600):
		if lesson.ready_for_input: break
		await process_frame
	check(lesson.ready_for_input, "console has found its own room grid")
	var mm: MultiMesh = lesson.colorizer.multimesh
	var positions: Array = lesson.colorizer.grid_structure.cube_positions
	check(lesson.colorizer.multimesh_instance.get_parent() == lesson.get_parent().get_parent(), "writes to this room's GridMultiMesh")
	check(lesson.buttons.size() == 5 and not lesson.colorizer.auto_cycle_enabled, "five physical controls and no automatic overwrite")
	check(lesson.cells.size() > 25, "selection edits the room floor rather than an isolated model")
	var initial_palette: Array = lesson.colorizer._get_palette_colors(lesson.PALETTES[0])
	check(lesson.cells.keys().all(func(a): return colour_close(mm.get_instance_color(lesson.cells[a]), initial_palette[(a.x+a.y)%initial_palette.size()])), "initial floor already follows the address rule")
	var transforms: Array[Transform3D] = []
	var before: Array[Color] = []
	for i in range(mm.instance_count):
		transforms.append(mm.get_instance_transform(i))
		before.append(mm.get_instance_color(i))
	var chosen: int = lesson.cells[Vector2i(10, 10)]
	check(positions[chosen] == Vector3i(10, 0, 10), "selected address resolves through actual sparse cube positions")
	lesson.buttons[2].pressed.emit()
	var painted: Color = mm.get_instance_color(chosen)
	print("INK stored=", painted, " requested=", lesson.INKS[0])
	check(colour_close(painted, lesson.INKS[0]), "COLOUR button writes its first ink within the renderer's colour precision")
	var changed := 0
	for i in range(mm.instance_count):
		if not before[i].is_equal_approx(mm.get_instance_color(i)): changed += 1
	check(changed == 1, "exactly one instance changes")
	lesson.buttons[0].pressed.emit()
	check(lesson.selected == Vector2i(11, 10), "X control changes only x")
	for step in range(4): lesson.buttons[0].pressed.emit()
	check(lesson.selected == Vector2i(10, 10) and mm.get_instance_color(chosen).is_equal_approx(painted), "return to the same address finds the edited value")
	lesson.buttons[1].pressed.emit()
	check(lesson.selected == Vector2i(10, 11), "Z control changes only z")
	for step in range(4): lesson.buttons[1].pressed.emit()
	lesson.buttons[3].pressed.emit()
	check(mm.get_instance_color(chosen).is_equal_approx(before[chosen]), "RULE replaces the exception with the original rule value")
	lesson.buttons[4].pressed.emit()
	check(lesson.palette_index == 1, "PALETTE chooses another collection")
	var palette: Array = lesson.colorizer._get_palette_colors(lesson.PALETTES[1])
	var rule_matches := true
	for address: Vector2i in lesson.cells:
		var expected: Color = palette[(address.x + address.y) % palette.size()]
		rule_matches = rule_matches and colour_close(mm.get_instance_color(lesson.cells[address]), expected)
	check(rule_matches, "all floor values follow actual coordinate sums")
	var geometry_unchanged := true
	for i in range(mm.instance_count): geometry_unchanged = geometry_unchanged and transforms[i].is_equal_approx(mm.get_instance_transform(i))
	check(geometry_unchanged, "colour controls preserve every cube transform")
	check(lesson.readout.text.contains("(10,10)"), "cased readout shows the selected address")
	print("HEIGHT console=", lesson.get_node("AddressConsole").global_position.y, " floor=", lesson.marker.global_position.y-0.015)
	var player: CharacterBody3D = current_scene.get("_player")
	var head: Camera3D = current_scene.get("_cam")
	check(lesson.get_node("AddressConsole").global_position.y >= 1.0 and lesson.get_node("AddressConsole").global_position.y <= 1.4, "console sits at standing reach")
	var query := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.5
	query.shape = capsule
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	query.transform.origin = lesson.to_global(Vector3(7, 0.85, 18))
	query.motion = lesson.global_basis * Vector3(0,0,-2.1)
	check(current_scene.get_world_3d().direct_space_state.cast_motion(query)[0] > 0.99, "a body can approach the console")
	player.set_physics_process(false)
	current_scene.get("_feel").set_process(false)
	player.global_position += lesson.to_global(Vector3(7, 1.7, 18)) - head.global_position
	head.look_at(lesson.to_global(Vector3(10, 0.3, 10)))
	for frame in range(40):
		current_scene.call("_cull_artifacts")
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://doc/book/iterations/2026-09-19-color-review/fields/evidence/grid_address_museum.png")
	var report := {"checks":checks,"failures":failures,"headset_tested":false,"input":"Real console button signals; actual room MultiMesh values and transforms inspected. Tracked-controller pressing untested."}
	var f := FileAccess.open("res://doc/book/iterations/2026-09-19-color-review/fields/evidence/probe_grid_address.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	print("GRID_ADDRESS ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
