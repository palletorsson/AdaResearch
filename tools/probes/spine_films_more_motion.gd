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
	create_timer(100).timeout.connect(func():quit(99))
	var manifest: Array = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/spine_films/more_motion/manifest.json"))
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
		if film.get("evidence")==null:
			check(false,"Stage script initialized: "+entry.id)
			film.free()
			continue
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
		check(film.validation().passed,"Source-specific validation: "+entry.id)
		for path in hashes: check(FileAccess.get_sha256(path) == hashes[path],"Unchanged source: "+path)
		check(randf() == expected_random,"Build and all film frames preserve global RNG: "+entry.id)
		reports.append({"id":entry.id,"build_and_check_ms":Time.get_ticks_msec()-started,"geometry_nodes":geometry_count,"evidence":data})
		print("MORE MOTION FILM ",entry.id," ",JSON.stringify(data))
		root.remove_child(film); film.free()
		await process_frame
	var result := {"checks":checks,"failures":failures,"films":reports}
	DirAccess.make_dir_recursive_absolute("res://ada_run/spine_films")
	var suffix := "" if filter.is_empty() else "-"+filter
	var file := FileAccess.open("res://ada_run/spine_films/more-motion-report"+suffix+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  "))
	print("MORE MOTION FILMS RESULT ",checks," checks / ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
