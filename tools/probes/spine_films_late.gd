extends SceneTree
var failures: Array[String] = []
var checks := 0
var report: Dictionary = {}
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var manifest: Array = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/spine_films/late/manifest.json"))
	var view := SubViewport.new()
	view.size = Vector2i(1024,576)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	for entry in manifest:
		var resource = load(entry.scene)
		if resource == null:
			_check(false,"%s loads" % entry.id)
			continue
		var film = resource.instantiate()
		if not film.has_method("validation"):
			_check(false,"%s script compiles" % entry.id)
			film.free()
			continue
		view.add_child(film)
		await process_frame
		await process_frame
		_check(film.phases.size()==4,"%s four phases" % entry.id)
		_check(film.duration>=20 and film.duration<=30,"%s duration" % entry.id)
		_check(film.source_paths==entry.source_paths,"%s source list" % entry.id)
		var snapshots: Array = []
		for phase in film.phases.size():
			for fraction in [.05,.5,.95]:
				film.playhead = (phase+fraction)*film.duration/film.phases.size()
				film.refresh()
				_check(_finite(film.display),"%s finite phase %d / %.2f" % [entry.id,phase,fraction])
				snapshots.append(film.display.get_child_count())
			film.playhead = (phase+.75)*film.duration/film.phases.size()
			film.refresh()
			if "--capture" in OS.get_cmdline_user_args():
				await process_frame
				await RenderingServer.frame_post_draw
				var output := "res://ada_run/spine_films_late/%s-%d.png" % [entry.id,phase]
				DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
				view.get_texture().get_image().save_png(output)
		var data: Dictionary = film.validation()
		report[entry.id] = data
		var rod: MeshInstance3D = film.film_unit_rod(Color.WHITE)
		var endpoint_a := Vector3(-2,.8,1)
		var endpoint_b := Vector3(1,2,-.4)
		film.film_rod_pose(rod,endpoint_a,endpoint_b)
		_check((rod.transform*Vector3(0,-.5,0)).distance_to(endpoint_a)<.00001 and (rod.transform*Vector3(0,.5,0)).distance_to(endpoint_b)<.00001,"%s rod endpoints match positions" % entry.id)
		rod.queue_free()
		_specific(entry.id,film)
		film.running = false
		var previous: float = film.playhead
		film.advance(1.0)
		_check(is_equal_approx(film.playhead,previous),"%s pause" % entry.id)
		film.replay()
		_check(film.playhead==0 and film.running,"%s replay" % entry.id)
		film.step_sample()
		_check(not film.running and film.playhead>0,"%s step" % entry.id)
		view.remove_child(film)
		film.queue_free()
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ada_run/spine_films_late"))
	var file := FileAccess.open("res://ada_run/spine_films_late/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"films":report},"\t"))
	print("LATE FILMS: ",checks," checks, ",failures.size()," failures")
	for failure in failures: print("FAIL: ",failure)
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures.append(message)

func _finite(node: Node) -> bool:
	if node is Node3D and not node.transform.is_finite(): return false
	for child in node.get_children():
		if not _finite(child): return false
	return true

func _specific(id: String, film: Node3D) -> void:
	var e: Dictionary = film.evidence
	match id:
		"iso_cell":
			_check(e.get("configs",[]).size()==4,"iso configs exist")
			if e.has("configs"):
				_check(e.configs.min()==e.configs.max(),"iso margin preserves classification")
				_check(e.triangle_counts.min()>0,"iso nonempty source triangles")
		"boolean_room":
			var original = load(film.SOURCE).new()
			original._plan_walk()
			var error := 0.0
			for i in original._centres.size(): error = maxf(error,original._centres[i].distance_to(film.CENTRES[i]))
			_check(error<.000002,"boolean fixture equals source seeded walk")
			_check(not e.uses_shared_rng,"boolean observer avoids global RNG")
			original.free()
		"boid_neighbour":
			_check(e.get("first_velocity_error",99.0)<.00001,"boid arrows reproduce actual first step")
			_check(e.get("selected_neighbours",0)==4,"boid actual neighbourhood")
		"learning_step":
			_check(e.get("final_loss",999)<e.get("initial_loss",0),"learning source steps decrease bowl loss")
		"graph_layout":
			_check(e.get("nodes",0)==9 and e.get("edges",0)==8,"graph source tree count")
			_check(film._snapshots[0]!=film._snapshots.back(),"graph source layout moves")
		"curvature_triangle":
			_check(absf(e.get("plane_angle_sum",0)-180)<.01,"plane angles")
			_check(e.get("sphere_angle_sum",0)>180,"sphere excess")
			_check(e.get("sphere_radius_error",99)<.00001,"great-circle samples stay on sphere")
		"shannon_threshold":
			_check(e.get("fixed_draws",0)==64,"shannon draw count")
			_check(e.get("entropy_endpoints",[])==[0.0,1.0,0.0],"shannon source entropy limits")
			_check(hash(film._source._draws)==e.draw_hash,"shannon drawings never resampled")
		"rhizome_routes":
			_check(e.get("three_link_edges",0)>e.get("one_link_edges",999),"rhizome source rewiring changes edges")
			_check(e.get("removed_degree",0)>0,"rhizome removes a connected node")
