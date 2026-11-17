extends SceneTree
## Read the installed chapter nodes without changing placements or interacting.
var game: Node3D
var folder := ""
var inventory := []
var verify := false
var opera: Node
var binding_checks := []
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
		if arg == "--verify-opera": verify = true
	assert(not folder.is_empty())
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.body.scripted_input = true
	game.body.set_process_unhandled_input(false)
	game.scene_loaded()
	game.scene_visible()
	if verify:
		opera = load("res://commons/void/inner_opera.gd").new()
		opera.game = game
		assert(opera._read_bindings())
	for floor in range(22):
		game.place_player_at_spawn(floor)
		var began := Time.get_ticks_msec()
		while Time.get_ticks_msec() - began < 45000:
			await process_frame
			if game.building.content.roots.has(floor) and not game.building.content.pending.any(func(job): return int(job.index) == floor): break
		for tick in 12: await process_frame
		if verify:
			opera._bind_what_stands()
			var wanted: Dictionary = opera.by_floor.get(floor, {})
			var missing := []
			for selector in wanted:
				var key := "%d/%s" % [floor, selector]
				var instance: int = int(opera.bound.get(key, 0))
				var node: Object = instance_from_id(instance) if instance != 0 else null
				if node == null or str(node.get_meta("object_id", "")) != str(wanted[selector]): missing.append(selector)
			binding_checks.append({"floor": floor, "expected": wanted.size(), "missing": missing})
			FileAccess.open(folder.path_join("bindings-check.json"), FileAccess.WRITE).store_string(JSON.stringify(binding_checks, "  "))
			print("OPERA_BINDINGS floor ", floor, " expected ", wanted.size(), " missing ", missing)
			continue
		var rows := []
		for mounts: Dictionary in [game.building.content.exhibits, game.building.content.props]:
			for key in mounts:
				if not str(key).begins_with(str(floor) + "/"): continue
				var mount: Node = mounts[key]
				if not is_instance_valid(mount): continue
				var nodes: Array = [mount]
				nodes.append_array(mount.find_children("*", "Node3D", true, false))
				for node: Node in nodes:
					if node is VisualInstance3D or node is CollisionShape3D: continue
					var script: Script = node.get_script()
					rows.append({"row": str(key).get_slice("/", 1), "path": str(mount.get_path_to(node)), "name": str(node.name),
						"scene": node.scene_file_path, "script": script.resource_path if script != null else "",
						"source": str(node.get_meta("void_source", "")), "token": str(node.get_meta("artifact_lookup_name", "")),
						"solid_type": str(node.get_meta("solid_type", ""))})
		inventory.append({"floor": floor, "map": str(game.building.content.data.floors[floor].map), "nodes": rows})
		FileAccess.open(folder.path_join("nodes.json"), FileAccess.WRITE).store_string(JSON.stringify(inventory, "  "))
		print("OPERA_INVENTORY floor ", floor, " nodes ", rows.size())
	if opera != null: opera.free()
	game.queue_free()
	await create_timer(0.3).timeout
	var failed := verify and binding_checks.any(func(check): return not check.missing.is_empty())
	quit(1 if failed else 0)
