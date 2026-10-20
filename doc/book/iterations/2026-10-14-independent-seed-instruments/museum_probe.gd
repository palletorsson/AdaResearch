extends "res://doc/book/iterations/2026-10-14-linked-seed-instruments/museum_probe.gd"

func landing_checks() -> void:
	await super.landing_checks()
	var bench := find_scene("/seed_replay_demo.gd")
	var ride := find_scene("/random_return.gd")
	if bench == null or ride == null: return
	ride.set_process(false)
	var journey: Node = bench._journey
	var parts := {"movement_sampler": bench._movement_sampler, "frame_timing": journey.jitter_scope, "source_console": journey.console}
	var frame: Transform3D = bench.get_parent().global_transform * bench.get_meta("artifact_map_frame")
	var receipt: Dictionary = bench._source_receipt.duplicate(true)
	var rng_state: int = ride.rng.state
	var saved: Dictionary = bench._part_layout.duplicate()
	for id in parts:
		var before := {}
		for other in parts: before[other] = parts[other].global_transform
		var local: Transform3D = frame.affine_inverse() * parts[id].global_transform
		var destination := local.origin + Vector3(0.4, 0, 0.3)
		bench.apply_grid_config({"part_" + id: "%s,%s,135" % [destination.x, destination.z]})
		await process_frame
		await process_frame
		check(id + " moves to its saved map pose", parts[id].global_position.distance_to(frame * destination) < 0.001)
		for other in parts:
			if other != id:
				check(id + " leaves " + other + " in place", parts[other].global_transform.is_equal_approx(before[other]))
		check(id + " preserves the seed receipt and route RNG", bench._source_receipt == receipt and ride.rng.state == rng_state)
		check(id + " stays in controller visibility bounds", (bench.get_meta("em_visibility_bounds") as AABB).has_point(bench.to_local(parts[id].global_position) + Vector3(0, 0.1, 0)))
		bench.apply_grid_config(saved)
		await process_frame
		await process_frame
	# A moved console includes its support and labels, not only the button panel.
	check("console labels and buttons share the movable stand", journey.panel.get_parent() == journey.console and journey.source_label.get_parent() == journey.console and journey.details.get_parent() == journey.console)
	var pose_before: Transform3D = journey.console.global_transform
	ride.position += Vector3(1, 0, 0)
	check("moving the parent cannot drag an independently placed console", journey.console.global_transform.is_equal_approx(pose_before))
	ride.position -= Vector3(1, 0, 0)
	journey.source_buttons.fixed.pressed.emit()
	check("moved console still selects the shared number seed", bench.current_seed() == int(journey.bank.fixed.seed) and ride.rng.seed == bench.current_seed())
	var first: Vector3 = ride.destination
	ride.advance(3.3)
	journey.panel.find_child("Btn_7", true, false).pressed.emit()
	check("moved console replay repeats the route", ride.destination == first)
	# Reload saved JSON into fresh scenes under a rotated, translated hall frame.
	var config: Dictionary = JSON.parse_string(JSON.stringify(saved))
	config.merge({"movement_seed": "true", "route_link": "independent_reload_probe"})
	var room := Node3D.new()
	room.position = Vector3(30, 0, 50)
	room.rotation_degrees.y = 90
	root.add_child(room)
	var fresh_bench: Node3D = load(bench.scene_file_path).instantiate()
	var fresh_ride: Node3D = load(ride.scene_file_path).instantiate()
	fresh_bench.set_meta("artifact_map_frame", Transform3D(Basis.IDENTITY, Vector3(0, 0, 4)))
	fresh_bench.apply_grid_config(config)
	fresh_ride.apply_grid_config({"route_link": "independent_reload_probe"})
	room.add_child(fresh_bench)
	room.add_child(fresh_ride)
	for i in range(5): await process_frame
	var fresh_parts := {"movement_sampler": fresh_bench._movement_sampler, "frame_timing": fresh_bench._journey.jitter_scope, "source_console": fresh_bench._journey.console}
	var fresh_frame: Transform3D = room.global_transform * fresh_bench.get_meta("artifact_map_frame")
	for id in fresh_parts:
		var fields: PackedStringArray = str(saved["part_" + id]).split(",")
		var expected: Transform3D = fresh_frame * Transform3D(Basis(Vector3.UP, deg_to_rad(float(fields[2]))), Vector3(float(fields[0]), 0, float(fields[1])))
		check(id + " reloads in the transformed hall", fresh_parts[id].global_transform.is_equal_approx(expected))
	room.queue_free()
	await snapshot("independent-instruments", ride.to_global(Vector3(0,3.7,3.8)), ride.to_global(Vector3(0.4,1.4,1.8)),100)
	observations["independent_part_layout"] = saved
