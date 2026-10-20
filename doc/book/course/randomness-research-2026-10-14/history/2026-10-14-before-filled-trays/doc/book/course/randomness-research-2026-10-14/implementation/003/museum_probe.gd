extends "res://tools/probes/transformation_encounters.gd"

func press_pointer(button: Node3D) -> void:
	var pointer := Node3D.new(); root.add_child(pointer)
	var area: Area3D = button.get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(pointer, area, area.global_position)
	await tick()
	XRToolsPointerEvent.released(pointer, area, area.global_position)
	await tick()
	pointer.queue_free()

func landing_checks() -> void:
	var original := find_scene("/seed_replay_demo.gd")
	check("existing seed instrument remains", original != null)
	var study = load("res://doc/book/experiments/random-definition/seed-bench-001/runtime/seed_study.tscn").instantiate()
	study.position = Vector3(10.5,0,18.5); study.rotation_degrees.y = -90
	hall.add_child(study)
	await tick()
	study.export_path = folder + "visitor-kept.json"
	check("study creates both 16-cube arrays", study.cubes.size() == 2 and study.cubes[0].size() == 16 and study.cubes[1].size() == 16)
	var before: Dictionary = study.model.current.duplicate(true)
	await snapshot("A-flat", study.to_global(Vector3(0.95,1.85,1.55)), study.to_global(Vector3(0,1.12,0)), 49)
	await press_pointer(study.board.buttons[1])
	check("shared XR pointer path selects B", study.model.current.mapping_version == "rgb-mean-bar.v1")
	var actual: Array = []
	var same_colour := true
	var anchored := true
	for i in range(16):
		actual.append(study.cubes[1][i].mesh.size.y)
		anchored = anchored and is_equal_approx(study.cubes[1][i].position.y - study.cubes[1][i].mesh.size.y / 2.0, 0.08) and study.cubes[1][i].mesh.size.y <= 0.16
		same_colour = same_colour and study.cubes[0][i].material_override.albedo_color == study.cubes[1][i].material_override.albedo_color
	check("rendered pairs retain matching RGB", same_colour)
	check("rendered bars keep fixed bottoms and reduced range", anchored)
	check("board switch draws no values", study.model.current.raw_values == before.raw_values and study.model.current.state_after == before.state_after)
	await snapshot("B-anchored-bars", study.to_global(Vector3(0.95,1.85,1.55)), study.to_global(Vector3(0,1.12,0)), 49)
	await snapshot("control-board", study.to_global(Vector3(0,1.55,1.8)), study.board.global_position, 42)
	var rectangular := true
	for button in study.board.buttons:
		var cap: MeshInstance3D = button.get_node("Button/ButtonMesh")
		var touch: CollisionShape3D = button.get_node("InteractableAreaButton/CollisionShape3D")
		rectangular = rectangular and cap.mesh is BoxMesh and touch.shape is BoxShape3D and cap.mesh.size.x > cap.mesh.size.y * 2 and button.scale == Vector3.ONE
	check("eight rectangular caps have rectangular unscaled touch targets", rectangular)
	check("grid has 15 mm gutters", is_equal_approx(study.cubes[1][1].position.x - study.cubes[1][0].position.x - study.cubes[1][0].mesh.size.x, 0.015))
	# Exercise real overlap detection with the XR hand collision layer.
	var hand := Area3D.new(); hand.collision_layer = 131072; hand.collision_mask = 0
	var shape := CollisionShape3D.new(); var sphere := SphereShape3D.new(); sphere.radius = 0.008; shape.shape = sphere
	hand.add_child(shape); root.add_child(hand); hand.global_position = study.to_global(Vector3(0,2,2))
	await tick(); await tick()
	var flat_area: Area3D = study.board.buttons[0].get_node("InteractableAreaButton")
	hand.global_position = flat_area.to_global(Vector3(0.065,0,0.025))
	await tick(); await tick(); await tick()
	check("hand overlap at rectangular edge selects flat", study.model.current.mapping_version == "rgb-fixed.v2")
	hand.global_position = study.to_global(Vector3(0,2,2)); await tick(); await tick()
	check("hand withdrawal releases button", not flat_area.pressed)
	hand.queue_free()
	await press_pointer(study.board.buttons[1])
	await press_pointer(study.board.buttons[2])
	var kept: Dictionary = study.model.kept.duplicate(true)
	await press_pointer(study.board.close_button)
	check("close leaves data kept and hides board", not study.board.is_open and not study.board.face.visible and study.model.kept == kept)
	var disabled := true
	for button in study.board.buttons:
		disabled = disabled and button.get_node("InteractableAreaButton/CollisionShape3D").disabled
	check("closed controls cannot intercept hand or ray", disabled and study.board.reopen_button.visible)
	await press_pointer(study.board.reopen_button)
	check("controls tab restores board without acquiring values", study.board.is_open and study.board.face.visible and study.model.kept == kept and study.model.current.raw_values == before.raw_values)
	for action in [4,7,6,5,3]: await press_pointer(study.board.buttons[action])
	check("board alone exports changes clears imports and replays", study.model.current.seed == "42" and study.model.current.mapping_version == "rgb-mean-bar.v1" and study.model.current.raw_values == before.raw_values)
	for key in [KEY_F3, KEY_F5, KEY_F8, KEY_F7, KEY_F6]:
		var event := InputEventKey.new(); event.keycode = key; event.pressed = true
		Input.parse_input_event(event)
		await tick()
		event = InputEventKey.new(); event.keycode = key; event.pressed = false
		Input.parse_input_event(event)
		await tick()
	check("desktop controls keep export clear import result", study.model.current.seed == "42" and study.model.current.mapping_version == "rgb-mean-bar.v1" and study.model.current.raw_values == before.raw_values)
	check("study approach has actual museum floor", not floor_at(study.to_global(Vector3(0,0,1.2))).is_empty())
	observations = {"observer": "Codex scripted native probe", "kind": "rendered_museum_encounter",
		"study_hall_local": xyz(study.position), "study_world": xyz(study.global_position),
		"bar_heights_m": actual, "physical_VR": "not_tested", "independent_learner": "not_tested"}
