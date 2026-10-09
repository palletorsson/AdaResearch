extends SceneTree
## Real museum placement/physics inspection. User arguments name a private spec file.
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func vec(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

func arr(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

func same_values(actual: Variant, expected: Variant) -> bool:
	# JSON numbers arrive as floats. Compare data values, not Array element types.
	if actual is Array and expected is Array:
		if actual.size() != expected.size(): return false
		for i in range(actual.size()):
			if not same_values(actual[i], expected[i]): return false
		return true
	if (actual is int or actual is float) and (expected is int or expected is float):
		return float(actual) == float(expected)
	return actual == expected

func run() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	var folder: String = spec["run"]
	var map_id: String = spec["room"]
	var museum: Node3D = (load(folder + "museum_snapshot.tscn") as PackedScene).instantiate()
	museum.set("EM_CONTROL", folder + "control.json")
	museum.set("_hand_path", folder + "necklace_hand.json")
	museum.set("_overrides_path", folder + "em_overrides.json")
	museum.set("start_chapter", spec["sequence"])
	museum.set("start_map", map_id)
	museum.set("plan_file", folder + "plan.json")
	root.add_child(museum)
	var started := Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec() - started < 60000:
		await process_frame
	museum.set("_lazy_pending", 0)
	museum.set_process(false)
	museum.set_physics_process(false)
	museum.call("flush_stamps")
	await create_timer(1.0).timeout
	var hall: Node3D = null
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map", "")) == map_id:
			hall = child
			break
	if hall == null:
		push_error("Requested museum hall did not load: " + map_id)
		quit(1)
		return
	var origin := hall.global_position + Vector3(0, 0, 4)
	var report := {"room": map_id, "scope": "Actual museum geometry and controlled CharacterBody locomotion with museum input/catch logic paused; no continuous gameplay, headset or learner acceptance.",
		"origin": arr(origin), "artifacts": [], "rays": [], "walks": [], "shots": [], "collections": []}
	var nodes: Dictionary = {}
	for record_v in museum.get("_edit_records"):
		var record: Dictionary = record_v
		var node: Node3D = record.get("node") as Node3D
		if not is_instance_valid(node) or record.get("seg") != hall:
			continue
		var token: String = record.get("token", "")
		nodes[token] = node
		var bounds: AABB = museum.call("_seat_extent", node)
		var info := {"token": token, "cell": record.get("from", []), "position": arr(node.global_position - origin),
			"scale": arr(node.scale), "rotation": arr(node.rotation_degrees),
			"bounds_position": arr(bounds.position - origin), "bounds_size": arr(bounds.size), "labels": [], "detectors": []}
		for label in node.find_children("*", "Label3D", true, false):
			(info["labels"] as Array).append({"text": label.text, "position": arr(label.global_position-origin), "parent": str(label.get_parent().name)})
		for shape in node.find_children("*", "CollisionShape3D", true, false):
			if shape.get_parent() is Area3D:
				(info["detectors"] as Array).append({"path": str(node.get_path_to(shape)), "position": arr(shape.global_position-origin), "disabled": shape.disabled})
		(report["artifacts"] as Array).append(info)
	report["checks"]=[]
	var study: Node3D=nodes.get("bias_from_inside")
	if study==null:
		push_error("Word-position study is absent")
		quit(1)
		return
	check(report,study.scale.is_equal_approx(Vector3.ONE),"Study is full size")
	check(report,study._marginalized_tags.size()==12 and study._default_tags.size()==12,"All 24 labels retained")
	check(report,not study._reading.visible,"Interpretation starts closed")
	var initial_transform: Transform3D=study.global_transform
	var warm_emission: float=study._marginalized_mat.emission_energy_multiplier
	var grey_colour: Color=study._default_mat.albedo_color
	var prior_warm: float=INF
	var prior_grey: float=0
	for value in [0.0,.5,1.0]:
		move_handle(study,value)
		check(report,is_equal_approx(study._perspective_blend,value),"Physical rail callback reaches normalized %.2f" % value)
		var exact: bool=true
		for i in range(12):
			var warm: Vector3=study._marginalized_positions_default[i].lerp(study._marginalized_positions_compressed[i],value)
			var grey: Vector3=study._default_positions_default[i].lerp(study._default_positions_compressed[i],value)
			exact=exact and study._marginalized_multimesh.multimesh.get_instance_transform(i).origin.is_equal_approx(warm) and study._default_multimesh.multimesh.get_instance_transform(i).origin.is_equal_approx(grey)
			exact=exact and study._marginalized_tags[i].position.is_equal_approx(warm+Vector3(0,study.sphere_radius+.03,0))
		check(report,exact,"Indexed positions and labels follow the authored interpolation at %.2f" % value)
		check(report,study._marginalized_mat.emission_energy_multiplier==warm_emission and study._default_mat.albedo_color==grey_colour,"Emission and alpha stay fixed at %.2f" % value)
		var warm: float=pair_distance(study._marginalized_multimesh)
		var grey: float=pair_distance(study._default_multimesh)
		check(report,warm<prior_warm and grey>prior_grey,"Selected warm pair contracts and grey pair separates at %.2f" % value)
		prior_warm=warm
		prior_grey=grey
		check(report,study.global_transform==initial_transform,"Handle leaves the exhibit transform unchanged")
	check(report,study._header_cache=="ARRANGEMENT B","Endpoint title names arrangement without prescribing a judgement")
	read_button(study)
	check(report,study._reading.visible and study._perspective_blend==1.0,"READ exposes interpretation without changing geometry")
	read_button(study)
	check(report,not study._reading.visible,"READ closes interpretation again")
	study.apply_grid_config({"perspective_blend":.4})
	check(report,absf(study._slider.get_normalized_value()-.4)<.00001 and study._marginalized_positions_default.size()==12,"Author configuration synchronizes handle and does not duplicate arrays")
	var old_radius: float=study.compressed_cluster_radius
	study.apply_grid_config({"compressed_cluster_radius":.3,"perspective_blend":1})
	check(report,pair_distance(study._marginalized_multimesh)>prior_warm,"Author radius configuration regenerates its endpoint")
	study.apply_grid_config({"compressed_cluster_radius":old_radius,"perspective_blend":0})
	check(report,study._slider.global_position.distance_to(origin+Vector3(4.5,1.3,5.3))<.75,"Handle lies within selected 0.75m reach")
	check(report,study._controls.find_child("Btn_0",true,false).global_position.distance_to(origin+Vector3(4.5,1.3,5.3))<.75,"READ button lies within selected reach")
	# Execute the frozen callback with the same physical rail signal.
	var legacy_script:=GDScript.new()
	legacy_script.source_code=FileAccess.get_file_as_string("res://doc/book/iterations/2026-09-20-postcrisis-bias-review/before/commons/artifacts/bias_from_inside/bias_from_inside.gd").replace("class_name BiasFromInside", "")
	check(report,legacy_script.reload()==OK,"Frozen source compiles for callback reproduction")
	var legacy:=Node3D.new()
	legacy.set_script(legacy_script)
	legacy.position=Vector3(1000,10,0)
	root.add_child(legacy)
	var old_slider: Node=legacy._controls.get_child(0)
	old_slider.set_normalized_value(1.0)
	old_slider.slider_moved.emit(old_slider.get_node("SliderOrigin/InteractableSlider").slider_position)
	report["legacy_endpoint"]={"handle":old_slider.get_normalized_value(),"blend":legacy._perspective_blend}
	check(report,old_slider.get_normalized_value()>.99 and legacy._perspective_blend<.2,"Frozen callback mistakes physical rail travel for the full blend")
	legacy.queue_free()
	await physics_frame
	var space := hall.get_world_3d().direct_space_state
	for row in spec.get("rays", []):
		var ray := PhysicsRayQueryParameters3D.create(origin + Vector3(float(row["x"]),20,float(row["z"])), origin + Vector3(float(row["x"]),-5,float(row["z"])), 1)
		var hit := space.intersect_ray(ray)
		var out := {"tag": row["tag"], "hit": not hit.is_empty()}
		if not hit.is_empty():
			out["top"] = (hit["position"] as Vector3).y - origin.y
			out["collider"] = str((hit["collider"] as Node).get_path())
		out["passed"] = not hit.is_empty() and (not row.has("top") or absf(float(out.get("top", -999))-float(row["top"])) < float(row.get("tolerance",0.06)))
		if not out["passed"]: failures.append("ray: " + str(row["tag"]))
		(report["rays"] as Array).append(out)
	var shapes: Array=[]
	for cs in hall.find_children("*", "CollisionShape3D", true, false):
		if cs.shape is BoxShape3D and cs.global_position.y > 0.1 and cs.global_position.y < 3.5:
			shapes.append({"path":str(cs.get_path()),"pos":arr(cs.global_position-origin),"size":arr(cs.shape.size),"rotation":arr(cs.global_rotation_degrees)})
	var f:=FileAccess.open("res://doc/book/iterations/2026-09-20-postcrisis-bias-review/collision-diagnostic.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(shapes,"\t"))
	f.close()
	quit()

func check(report: Dictionary, ok: bool, message: String) -> void:
	(report.checks as Array).append({"ok":ok,"message":message})
	if not ok: failures.append(message)
func move_handle(s: Node, value: float) -> void:
	s._slider.set_normalized_value(value)
	s._slider.slider_moved.emit(s._slider.get_node("SliderOrigin/InteractableSlider").slider_position)
func pair_distance(mm: MultiMeshInstance3D) -> float:
	return mm.multimesh.get_instance_transform(0).origin.distance_to(mm.multimesh.get_instance_transform(1).origin)
func read_button(s: Node) -> void:
	s._controls.find_child("Btn_0",true,false).get_node("InteractableAreaButton").button_pressed.emit(null)
