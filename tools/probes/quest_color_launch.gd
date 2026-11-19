extends SceneTree
## Run against the APK's extracted resources, with an isolated user-data folder.
func _initialize() -> void:
	begin.call_deferred()

func begin() -> void:
	if not OS.get_user_data_dir().contains("AdaQuestColorVerification"):
		quit(2); return
	var route_types := ["jump_terraces", "wave_s", "wave_eased", "wave_ripple", "wave_tube", "maximal_stairs", "boolean_drop"]
	for kind in route_types:
		var route = load("res://commons/void/sequence_descent.tscn").instantiate()
		route.apply_grid_config({"kind":kind,"drop":6,"destination_floor":1})
		root.add_child(route)
		if route.find_children("*", "CollisionShape3D", true, false).is_empty():
			push_error("Packaged route has no collision: " + kind)
			quit(1); return
		route.queue_free()
		await process_frame
	var request := FileAccess.open("user://void_launch.json", FileAccess.WRITE)
	request.store_string('{"map":"Color_Context_Placed"}')
	request.close()
	var staging: Node = load("res://commons/scenes/vr_staging.tscn").instantiate()
	root.add_child(staging); current_scene = staging
	var deadline := Time.get_ticks_msec() + 90000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var game := get_first_node_in_group("void_game")
		if game != null and game.get("ready_for_play"):
			var consumed := not FileAccess.file_exists("user://void_launch.json")
			var correct: bool = game.checkpoint == 28 and game.building.content.data.floors[28].map == "Color_Context_Placed"
			print("QUEST_COLOR_LAUNCH ", JSON.stringify({"passed":consumed and correct,"floor":game.checkpoint,"consumed":consumed,"route_types":route_types.size()}))
			# Finish the asynchronous staging handoff before tearing the tree down.
			await create_timer(1.0).timeout
			staging.queue_free()
			for frame in 4: await process_frame
			quit(0 if consumed and correct else 1)
			return
	print("QUEST_COLOR_LAUNCH timeout")
	quit(1)
