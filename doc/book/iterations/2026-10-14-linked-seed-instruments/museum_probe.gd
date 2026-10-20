extends "res://doc/book/iterations/2026-10-13-frame-jitter/museum_probe.gd"

func landing_checks() -> void:
	await super.landing_checks()
	var bench := find_scene("/seed_replay_demo.gd")
	var ride := find_scene("/random_return.gd")
	if bench == null or ride == null: return
	var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/Random_Definition/map_data.json"))
	var centre := Vector3.ZERO
	for z in range(map.layers.interactables.size()):
		for x in range(map.layers.interactables[z].size()):
			if str(map.layers.interactables[z][x]).begins_with("random_return:"):
				centre = Vector3(x + 0.5, 0, z + 0.5)
	var parts := {"movement_sampler": bench._movement_sampler,
		"frame_timing": bench._journey.jitter_scope, "source_console": bench._journey.panel}
	var positions := {}
	for id in parts:
		var node: Node3D = parts[id]
		check("linked editor part exists: " + id, node != null and node.is_inside_tree())
		var map_position: Vector3 = node.global_position - ride.global_position + centre
		positions[id] = [map_position.x, map_position.z]
	observations["editor_parts"] = positions
	# The live map moved this exhibit toward the entrance; keep the camera inside.
	await snapshot("linked-instruments", ride.to_global(Vector3(0,3.7,3.8)), ride.to_global(Vector3(0.4,1.4,1.8)),100)
