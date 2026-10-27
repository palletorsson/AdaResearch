extends SceneTree
## The ladder's grid (grid_2d_4x4) and lattice (grid_3d_4x4x4): what each builds, as names and
## positions of its children, at load and through the config path, written to
## ada_run/array_occupancy/build_<label>.json. Run before and after a change to prove the old paths
## byte for byte; the after run also builds each under #occupancy:<rule> for every address rule and
## reports the empty addresses (frames) and grid_data's zeros.
##   godot --headless --script res://commons/testing/probe_array_occupancy.gd -- <label>

const Rules := preload("res://commons/artifacts/regularity/address_rules.gd")


func _init() -> void:
	var label: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "now"
	var out := {"label": label}
	out["grid_load"] = await _build("res://algorithms/arrays/grid_2d_4x4.tscn", {})
	out["grid_config"] = await _build("res://algorithms/arrays/grid_2d_4x4.tscn", {"cols": 5, "rows": 5})
	out["lattice_load"] = await _build("res://algorithms/arrays/grid_3d_4x4x4.tscn", {})
	out["lattice_config"] = await _build("res://algorithms/arrays/grid_3d_4x4x4.tscn", {"size_x": 4})
	if label != "before":
		var occ := {}
		for rule in Rules.NAMES:
			occ[rule] = {"grid": await _build("res://algorithms/arrays/grid_2d_4x4.tscn", {"occupancy": rule}),
				"lattice": await _build("res://algorithms/arrays/grid_3d_4x4x4.tscn", {"occupancy": rule})}
		out["occupancy"] = occ
	var dir := ProjectSettings.globalize_path("res://ada_run/array_occupancy")
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir.path_join("build_%s.json" % label), FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	quit(0)


func _build(path: String, config: Dictionary) -> Dictionary:
	var node: Node3D = load(path).instantiate()
	root.add_child(node)
	await process_frame
	if not config.is_empty():
		node.call("apply_grid_config", config)
		for i in 4:
			await process_frame
	var children: Array = []
	for c in node.get_children():
		children.append([str(c.name), snappedf(c.position.x, 0.0001), snappedf(c.position.y, 0.0001), snappedf(c.position.z, 0.0001)])
	var result := {"children": children}
	if "grid_data" in node:
		# a COPY: freeing the grid below sends every cube's "picked up" callback into this array
		result["grid_data"] = (node.get("grid_data") as Array).duplicate(true)
	node.queue_free()
	await process_frame
	return result
