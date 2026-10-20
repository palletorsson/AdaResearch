extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	var bench := find_scene("/seed_replay_demo.gd")
	var ride := find_scene("/random_return.gd")
	check("seed bench and route loaded", bench != null and ride != null)
	if bench == null or ride == null: return
	var journey: Node = bench._journey
	var parts := {"movement_sampler": bench._movement_sampler, "frame_timing": journey.jitter_scope, "source_console": journey.console}
	var frame: Transform3D = bench.get_parent().global_transform * bench.get_meta("artifact_map_frame")
	var positions := {}
	var saved: Dictionary = bench._part_layout.duplicate()
	var receipt: Dictionary = bench._source_receipt.duplicate(true)
	ride.set_process(false)
	for id in parts:
		var part: Node3D = parts[id]
		var initial: Transform3D = part.global_transform
		var p: Vector3 = frame.affine_inverse() * initial.origin
		positions[id] = [p.x, p.z]
		var collisions := {}
		for child in part.find_children("*", "CollisionObject3D", true, false):
			collisions[child] = [child.collision_layer, child.collision_mask, child.input_ray_pickable]
		var others := {}
		for other in parts:
			if other != id: others[other] = parts[other].global_transform
		bench.apply_grid_config({"part_" + id + "_removed": "true"})
		await tick()
		check(id + " remove hides the whole instrument", not part.visible and part.process_mode == Node.PROCESS_MODE_DISABLED)
		var cleared := true
		for child in collisions:
			cleared = cleared and child.collision_layer == 0 and child.collision_mask == 0 and not child.input_ray_pickable
		check(id + " removed instrument has no collision or picking", cleared and not collisions.is_empty())
		check(id + " removal keeps the experiment receipt", bench._source_receipt == receipt)
		for other in others:
			check(id + " removal leaves " + other, parts[other].visible and parts[other].global_transform.is_equal_approx(others[other]))
		bench.apply_grid_config({"part_" + id + "_removed": "false"})
		await tick()
		check(id + " undo restores exact placement", part.visible and part.global_transform.is_equal_approx(initial))
		var restored := true
		for child in collisions:
			restored = restored and [child.collision_layer, child.collision_mask, child.input_ray_pickable] == collisions[child]
		check(id + " undo restores original collision settings", restored)
		bench.apply_grid_config({"part_" + id: "%s,%s,90,0.4,0.6" % [p.x, p.z]})
		await tick()
		var expected: Transform3D = frame * Transform3D(Basis(Vector3.UP, PI/2).scaled(Vector3.ONE*0.6), Vector3(p.x, 0.4, p.z))
		check(id + " height scale and rotation apply to complete body", part.global_transform.is_equal_approx(expected))
		bench.apply_grid_config(saved)
		await tick()
	journey.source_buttons.fixed.pressed.emit()
	check("restored console still selects shared seed", ride.rng.seed == bench.current_seed())
	var first: Vector3 = ride.destination
	ride.advance(3.3)
	journey.panel.find_child("Btn_7", true, false).pressed.emit()
	check("restored replay repeats the route", first == ride.destination)
	# Verify that removal also applies at fresh scene load, not just in-place.
	var room := Node3D.new()
	root.add_child(room)
	var fresh_bench: Node3D = load(bench.scene_file_path).instantiate()
	var fresh_ride: Node3D = load(ride.scene_file_path).instantiate()
	var config: Dictionary = JSON.parse_string(JSON.stringify(saved))
	config.merge({"movement_seed": "true", "route_link": "removed_reload_probe"})
	for id in parts: config["part_" + id + "_removed"] = "true"
	fresh_bench.set_meta("artifact_map_frame", Transform3D.IDENTITY)
	fresh_bench.apply_grid_config(config)
	fresh_ride.apply_grid_config({"route_link": "removed_reload_probe"})
	room.add_child(fresh_bench); room.add_child(fresh_ride)
	for i in range(5): await process_frame
	check("removed parts remain absent after fresh load", not fresh_bench._movement_sampler.visible and not fresh_bench._journey.console.visible and not fresh_bench._journey.jitter_scope.visible)
	fresh_bench.use_kept_seed(42, {"provider": "fixed", "seed": 42})
	fresh_bench.replay()
	check("remaining bench replays with all three parts removed", fresh_ride.rng.seed == 42)
	room.queue_free()
	observations["editor_parts"] = positions
	observations["tested_layout"] = saved
