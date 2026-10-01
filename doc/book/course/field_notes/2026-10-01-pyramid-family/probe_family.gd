extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _sides_of(inst: Node) -> String:
	var verts := -1
	for c in inst.get_children():
		if c is MeshInstance3D and c.mesh != null:
			verts = c.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()
	return "base_sides=%s mesh_vertices=%d rotation_y_deg=%.1f" % [str(inst.get("base_sides")), verts, rad_to_deg(inst.rotation.y)]

func _run() -> void:
	var comp = load("res://commons/grid/GridInteractablesComponent.gd").new()
	var scene: PackedScene = load("res://commons/primitives/pyramid/pyramid.tscn")
	# BEFORE: what the parser returned for #base_sides:8 while the key was unlisted (measured earlier): config true, yaw 8
	var old: Node3D = scene.instantiate()
	old.set_meta("config_base_sides", true)
	root.add_child(old)
	old.rotation_degrees.y = 8.0
	await process_frame
	print("BEFORE pyramid#base_sides:8 as it was misread -> ", _sides_of(old))
	old.queue_free()
	for tok in ["pyramid#base_sides:3", "pyramid#base_sides:4", "pyramid#base_sides:5", "pyramid#base_sides:6", "pyramid#base_sides:8", "pyramid"]:
		var r: Dictionary = comp._parse_config_token(tok)
		var cfg: Dictionary = r.get("config_data", {})
		var inst: Node3D = scene.instantiate()
		for k in cfg:
			inst.set_meta("config_" + str(k), cfg[k])
		root.add_child(inst)
		var ov: Dictionary = r.get("overrides", {})
		if ov.has("rotation_y_degrees"):
			inst.rotation_degrees.y = float(ov["rotation_y_degrees"])
		await process_frame
		print("AFTER  ", tok, " | config=", cfg, " overrides=", ov, " -> ", _sides_of(inst))
		inst.queue_free()
	comp.free()
	quit()
