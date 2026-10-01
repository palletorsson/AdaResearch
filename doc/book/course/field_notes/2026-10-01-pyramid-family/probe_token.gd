extends SceneTree

func _initialize() -> void:
	var comp = load("res://commons/grid/GridInteractablesComponent.gd").new()
	var scene: PackedScene = load("res://commons/primitives/pyramid/pyramid.tscn")
	for tok in ["pyramid#base_sides:8", "pyramid#base_sides:3", "pyramid#base_sides:6", "pyramid#apex_stance:corner", "pyramid"]:
		var r: Dictionary = comp._parse_config_token(tok)
		var cfg: Dictionary = r.get("config_data", {})
		var inst: Node3D = scene.instantiate()
		for k in cfg:
			inst.set_meta("config_" + str(k), cfg[k])
		root.add_child(inst)
		var verts := -1
		for c in inst.get_children():
			if c is MeshInstance3D and c.mesh != null:
				verts = c.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()
		print("TOKEN ", tok, " | config=", cfg, " | overrides=", r.get("overrides", {}), " | pyramid.base_sides=", inst.get("base_sides"), " | mesh vertices=", verts)
		inst.queue_free()
	comp.free()
	quit()
