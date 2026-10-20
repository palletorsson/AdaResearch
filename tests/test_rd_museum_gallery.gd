extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var configs: Array = JSON.parse_string(FileAccess.get_file_as_string("res://commons/rd_grammar/research_configs.json")).configs
	var gallery: Node3D = load("res://commons/artifacts/rd_museum_gallery/rd_museum_gallery.tscn").instantiate()
	root.add_child(gallery)
	await process_frame
	var checks := 0
	for cfg: Dictionary in configs:
		var study: Node3D = gallery.get_node(cfg.id)
		assert(study.scene_file_path.is_empty(), "Flatten study instances before assigning ownership; avoid duplicate inherited children")
		assert(study.get_meta("config") == cfg, "Baked configuration must match the source: " + str(cfg.id))
		assert(study.get_node("Parameters").text.contains("Saved simulation"))
		assert(study.get_node("Plinth/Support").get_child(0).shape.size == Vector3(2.62,0.9,2.62))
		var field: Node3D = study.get_node("Field")
		if field is MeshInstance3D:
			var arrays: Array = field.mesh.surface_get_arrays(0)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			assert(vertices.size() == int(cfg.grid_size) * int(cfg.grid_size))
			assert(arrays[Mesh.ARRAY_INDEX].size() == (int(cfg.grid_size)-1) * (int(cfg.grid_size)-1) * 6)
			for v in vertices: assert(v.is_finite())
			if cfg.render_mode == "heightmap":
				for n in arrays[Mesh.ARRAY_NORMAL]: assert(n.y > 0.0, "Relief normals must face upward")
		else:
			assert(field is MultiMeshInstance3D and field.multimesh.instance_count > 0)
			assert(field.multimesh.buffer.size() == field.multimesh.instance_count * 16)
			assert(field.multimesh.get_aabb().size.x > 5.0)
			for i in field.multimesh.instance_count:
				assert(field.multimesh.get_instance_transform(i).is_finite())
		checks += 1
	# Temporary tree exit is normal during museum cartridge compilation.
	root.remove_child(gallery)
	await process_frame
	root.add_child(gallery)
	await process_frame
	assert(gallery.get_child_count() == 20)
	assert(gallery.get_script() == null)
	print("RD_GALLERY PASS: ", checks, " source-matched fields, geometry, labels, colliders and reattachment")
	gallery.queue_free()
	await process_frame
	quit()
