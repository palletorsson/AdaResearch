extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(1).timeout
	var stream = museum.get("_portal_stream")
	if stream != null: stream.set_process(false); stream.set_physics_process(false)
	var player = museum.get("_player")
	if player is Node3D:
		player.hide(); player.set_process(false); player.set_physics_process(false)
		player.global_position = Vector3(0, -100, 0)
	camera.set_cull_mask_value(19, false)
	var source = find_scene("/Ecosystem/ForestCompetition.gd")
	check("Existing Competition forest is available for the learner reconstruction", source != null)
	if source == null: return
	var latest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://doc/book/iterations/2026-10-09-lsystems-ghost-student/latest-run.json"))
	var exercise := "res://" + str(latest.directory) + "/transfer-exercise/"
	var original = load(exercise + "original/competition.gd").new()
	var quarter = load(exercise + "quarter/competition.gd").new()
	original.transform = source.global_transform; quarter.transform = source.global_transform
	root.add_child(original); root.add_child(quarter)
	source.hide(); quarter.hide()
	original.attempt(); original.attempt(); quarter.attempt(); quarter.attempt()
	check("Both reconstructed programs retain the museum host transform", original.global_transform.is_equal_approx(source.global_transform) and quarter.global_transform.is_equal_approx(source.global_transform))
	check("Both retain the same branching sentence", original.trees[0].sentence == quarter.trees[0].sentence and original.trees[1].sentence == quarter.trees[1].sentence)
	check("Museum run reproduces original and edited uptake", is_equal_approx(original.trees[0].last, 2.25) and is_equal_approx(original.trees[1].last, 1.98) and is_equal_approx(quarter.trees[0].last, 3.75) and is_equal_approx(quarter.trees[1].last, 3.0))
	var eye: Vector3 = source.to_global(Vector3(6.8, 5.6, 5.8))
	var target: Vector3 = source.to_global(Vector3(0, .6, -3))
	await snapshot("original-15", eye, target, 66)
	original.hide(); quarter.show()
	await snapshot("changed-25", eye, target, 66)
	await snapshot("changed-close", source.to_global(Vector3(0, 1.75, 2.2)), source.to_global(Vector3(0, .7, -3.8)), 78)
	observations.scope = "Fresh rendered Competition hall. Exact original and one-constant edited learner programs placed temporarily at the installed study transform. Identical camera for the before/after pair; no persisted hall edit, physical-headset or independent learner test."
	observations.exercise = exercise
	observations.original_uptakes = [original.trees[0].last, original.trees[1].last]
	observations.changed_uptakes = [quarter.trees[0].last, quarter.trees[1].last]
	original.queue_free(); quarter.queue_free(); source.show()
