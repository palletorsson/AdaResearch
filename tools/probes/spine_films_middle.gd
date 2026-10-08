extends SceneTree
var failures: Array[String] = []
var reports: Array = []
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func inspect_node(node: Node) -> int:
	var geometries := 0
	if node is Node3D: check(node.transform.is_finite(),"Finite transform: "+str(node.get_path()))
	if node is MeshInstance3D and node.mesh != null:
		geometries += 1
		check(node.mesh.get_aabb().position.is_finite() and node.mesh.get_aabb().size.is_finite(),"Finite mesh bounds: "+str(node.get_path()))
	if node is MultiMeshInstance3D and node.multimesh != null:
		geometries += 1
		for i in node.multimesh.instance_count: check(node.multimesh.get_instance_transform(i).is_finite(),"Finite multimesh instance")
	for child in node.get_children(): geometries += inspect_node(child)
	return geometries

func run() -> void:
	var manifest: Array = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/spine_films/middle/manifest.json"))
	var filter := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--film="): filter = arg.trim_prefix("--film=")
	for entry in manifest:
		if not filter.is_empty() and entry.id != filter: continue
		var hashes := {}
		for path in entry.source_paths:
			check(FileAccess.file_exists(path),"Source exists: "+path)
			hashes[path] = FileAccess.get_sha256(path)
		var packed = load(entry.scene)
		check(packed is PackedScene,"Packed scene loads: "+entry.id)
		if not packed is PackedScene: continue
		var film = packed.instantiate()
		var started := Time.get_ticks_msec()
		seed(482901)
		var expected_random := randf()
		seed(482901)
		root.add_child(film)
		check(not film.evidence.is_empty(),"Source evidence: "+entry.id)
		check(film.phases.size() >= 3 and film.phases.size() <= 5,"Phase count: "+entry.id)
		check(film.notes.size() == film.phases.size(),"Phase notes: "+entry.id)
		var geometry_count := 0
		for sample in [0.0,4.5,8.0,11.5,15.0,19.0,23.0,25.5]:
			film.playhead = minf(sample,film.duration-.01)
			film.refresh()
			geometry_count = inspect_node(film.display)
			check(geometry_count > 0,"Geometry at %.1f: %s" % [sample,entry.id])
			check(film.camera.transform.is_finite(),"Finite camera: "+entry.id)
		var data: Dictionary = film.evidence
		match entry.id:
			"chance_passage": check(data.cells == 16 and data.decisions.size() == 16,"Sixteen retained decisions")
			"noise_layers": check(data.samples == 625 and data.weights == [12.0,6.0,1.5],"Authored noise weights")
			"shader_view": check(data.fixed_vertices > 100,"Fixed source mesh")
			"cellular_history": check(data.birth_neighbours == 3 and data.birth_old == 0 and data.birth_next == 1,"Actual three-neighbour birth")
			"menger_twenty": check(data.retained == 20 and data.removed == 7 and data.second_depth == 400,"Menger retained-index rule")
			"grammar_forward": check(data.segment_counts[1] > data.segment_counts[0] and data.segment_counts[0] > 0,"Actual rewrite grows path")
			"branch_decision": check(data.first_assignments == 8 and is_equal_approx(data.first_step_length,.5) and data.forks > 0,"Actual assignment, half-metre step and fork")
			"cloth_relations": check(data.positions == 225 and data.pins == 4 and data.maximum_pin_error < .000001 and data.recorded_frames > 100,"Source membrane records and fixed pins")
		for path in hashes: check(FileAccess.get_sha256(path) == hashes[path],"Unchanged source: "+path)
		check(randf() == expected_random,"Build and all film frames preserve global RNG: "+entry.id)
		reports.append({"id":entry.id,"build_and_check_ms":Time.get_ticks_msec()-started,"geometry_nodes":geometry_count,"evidence":data})
		print("MIDDLE FILM ",entry.id," ",JSON.stringify(data))
		root.remove_child(film); film.free()
		await process_frame
	var result := {"checks":checks,"failures":failures,"films":reports}
	DirAccess.make_dir_recursive_absolute("res://ada_run/spine_films")
	var suffix := "" if filter.is_empty() else "-"+filter
	var file := FileAccess.open("res://ada_run/spine_films/middle-report"+suffix+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  "))
	print("MIDDLE FILMS RESULT ",checks," checks / ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
