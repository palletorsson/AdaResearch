extends "res://tools/probes/transformation_encounters.gd"

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
	study.point.position = Vector3(-0.15,0.85,0.42)
	study.point.action_pressed.emit("trigger_click")
	check("inherited point signal selects B", study.model.current.mapping_version == "rgb-mean-height.v1")
	var actual: Array = []
	var same_colour := true
	for i in range(16):
		actual.append(study.cubes[1][i].position.y)
		same_colour = same_colour and study.cubes[0][i].material_override.albedo_color == study.cubes[1][i].material_override.albedo_color
	check("rendered pairs retain matching RGB", same_colour)
	check("point switch draws no values", study.model.current.raw_values == before.raw_values and study.model.current.state_after == before.state_after)
	study.point.position = Vector3(-0.85,1.05,0.65)
	await snapshot("B-mean-height", study.to_global(Vector3(0.95,1.85,1.55)), study.to_global(Vector3(0,1.12,0)), 49)
	for key in [KEY_F3, KEY_F5, KEY_F8, KEY_F7, KEY_F6]:
		var event := InputEventKey.new(); event.keycode = key; event.pressed = true
		study._unhandled_key_input(event)
	check("desktop controls keep export clear import result", study.model.current.seed == "42" and study.model.current.mapping_version == "rgb-mean-height.v1" and study.model.current.raw_values == before.raw_values)
	check("study approach has actual museum floor", not floor_at(study.to_global(Vector3(0,0,1.2))).is_empty())
	observations = {"observer": "Codex scripted native probe", "kind": "rendered_museum_encounter",
		"study_hall_local": xyz(study.position), "study_world": xyz(study.global_position),
		"rendered_heights_m": actual, "physical_VR": "not_tested", "independent_learner": "not_tested"}
