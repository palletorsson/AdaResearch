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
	report["required_present"] = nodes.has(spec.required)
	report["checks"] = []
	var specimen: Node3D = nodes.get("queer_morphology_specimen")
	if specimen==null:
		push_error("Synthesis specimen missing")
		quit(1)
		return
	specimen.set_physics_process(false)
	check(report,specimen.scale.is_equal_approx(Vector3.ONE),"Specimen and controls stand at full scale")
	var body: SoftBody3D = specimen._soft_body
	check(report,body!=null,"A real SoftBody3D supplies the specimen")
	move_handles(specimen,.5,0)
	specimen._breathing_time=0
	specimen._update_pressure()
	check(report,is_equal_approx(body.pressure_coefficient,1.5),"Midpoint pressure baseline is 1.5 at zero phase")
	specimen._breathing_time=PI/(2*1.25)
	specimen._update_pressure()
	check(report,absf(body.pressure_coefficient-1.59)<.00001,"Breathing peak multiplies the mapped baseline: 1.59")
	specimen._breathing_time=3*PI/(2*1.25)
	specimen._update_pressure()
	check(report,absf(body.pressure_coefficient-1.41)<.00001,"Breathing trough retains mapped baseline: 1.41")
	var old_damping: float = body.damping_coefficient
	press(specimen,3)
	check(report,not specimen.breathing_enabled and is_equal_approx(body.pressure_coefficient,1.5),"Actual button selects steady baseline, not zero pressure")
	specimen._physics_process(4.0)
	check(report,is_equal_approx(body.pressure_coefficient,1.5) and body.damping_coefficient==old_damping,"Steady pressure persists without altering damping")
	move_handles(specimen,.1,.8)
	check(report,absf(body.linear_stiffness-.82)<.00001 and absf(body.pressure_coefficient-1.1)<.00001,"Lambda reaches stiffness and pressure through rail callback")
	check(report,absf(body.damping_coefficient-.0209)<.00001 and absf(body.drag_coefficient-.03)<.00001,"Signed Phi reaches damping and drag through rail callback")
	var old_pressure: float = body.pressure_coefficient
	move_handles(specimen,.1,-.8)
	check(report,absf(body.damping_coefficient-.1801)<.00001 and body.pressure_coefficient==old_pressure,"Phi changes damping independently of pressure")
	move_handles(specimen,.8,-.8)
	check(report,absf(body.linear_stiffness-.26)<.00001 and absf(body.pressure_coefficient-1.2)<.00001,"High lambda gives another stiffness and pressure combination")
	press(specimen,1)
	check(report,is_equal_approx(specimen.lambda,.5) and is_zero_approx(specimen.phi),"Pair B button restores its two authored settings")
	press(specimen,3)
	check(report,specimen.breathing_enabled and is_zero_approx(specimen._breathing_time),"Pulse restarts its imposed phase")
	specimen._physics_process(.25)
	check(report,body.pressure_coefficient>1.5 and absf(body.linear_stiffness-.5)<.00001,"Physics tick modulates pressure while preserving stiffness")
	check(report,specimen._state_label.text.contains("pressure base 1.500") and not specimen._state_label.text.contains("Life emerges"),"Readout names actual mechanics instead of certifying life")
	for i in range(4):
		var button: Node3D=specimen._control_panel.find_child("Btn_%d" % i,true,false)
		check(report,button.global_position.distance_to(origin+Vector3(3.05,1.15,2.65))<.75,"Button within selected 0.75m reach")
	for slider in [specimen._lambda_slider,specimen._phi_slider]:
		check(report,slider.global_position.distance_to(origin+Vector3(3.05,1.15,2.65))<.75,"Slider within selected 0.75m reach")
	# Reproduce the precise former mapping mismatch from the frozen source.
	var legacy_code: String = FileAccess.get_file_as_string("res://doc/book/iterations/2026-09-20-qfep-synthesis-review/before/commons/artifacts/queer_morphology_specimen/queer_morphology_specimen.gd").replace("class_name QueerMorphologySpecimen", "")
	var legacy_script := GDScript.new()
	legacy_script.source_code=legacy_code
	check(report,legacy_script.reload()==OK,"Frozen prior source compiles for the pressure comparison")
	var legacy := Node3D.new()
	legacy.set_script(legacy_script)
	legacy.position=Vector3(1000,10,0)
	root.add_child(legacy)
	legacy.set_process(false)
	legacy.set_lambda(.5)
	var old_before: float=legacy._soft_body.pressure_coefficient
	legacy._process(.01)
	var old_after: float=legacy._soft_body.pressure_coefficient
	check(report,is_equal_approx(old_before,1.5) and old_after<=1.061 and old_after>=.939,"Frozen breathing overwrites the former midpoint baseline")
	report["legacy_pressure"]={"after_lambda":old_before,"after_process":old_after}
	legacy.queue_free()
	# Let actual physics run, recording a mesh point rather than inferring motion
	# from the animated fluid shader surrounding it.
	var initial_point: Vector3=body.get_point_transform(10)
	for i in range(120): await physics_frame
	var final_point: Vector3=body.get_point_transform(10)
	check(report,initial_point.is_finite() and final_point.is_finite(),"Deformable mesh point remains finite through actual physics")
	report["point_sample"]={"initial":arr(initial_point),"after_120_frames":arr(final_point),"displacement":initial_point.distance_to(final_point)}

	check(report,specimen._phi_slider.range_min==-1.0 and specimen._phi_slider.range_max==1.0,"Small Phi display uses the same signed range as the main plate")
	for variant in ["jarred","cracked","escaped","clouded"]:
		var instance := Node3D.new()
		instance.set_script(specimen.get_script())
		instance.becoming=variant
		instance.position=Vector3(1000,10,0)
		root.add_child(instance)
		var shell: Node=instance.get_node_or_null("JarBoundary")
		var correct: bool=true
		if variant=="escaped":
			correct=shell==null and instance._soft_body!=null
		else:
			correct=shell!=null and shell.get_child_count()==(16 if variant=="cracked" else 17)
		if variant=="clouded": correct=correct and instance._soft_body==null and instance._cloud.multimesh.instance_count==160 and instance._live_values.text.contains("No deformable body")
		else: correct=correct and instance._soft_body!=null
		check(report,correct,"Preserved %s form has the intended body and boundary" % variant)
		instance.queue_free()
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
	var walker: CharacterBody3D = museum.get("_player")
	if walker != null:
		report["walker"] = {"name":str(walker.name),"layer":walker.collision_layer,"mask":walker.collision_mask,"groups":walker.get_groups()}
	museum.set("_player", null)
	for row in spec.get("walks", []):
		if walker == null:
			failures.append("Missing museum walker")
			break
		var target_host: Node3D = nodes.get(str(row.get("token", ""))) as Node3D
		var target_cube: Node3D = null
		if target_host != null:
			target_cube = target_host.get_node_or_null(str(row["child"])) if row.has("child") else target_host
		var initial_exists := is_instance_valid(target_cube)
		walker.global_position = origin + vec(row["from"])
		walker.velocity = Vector3.ZERO
		var target := origin + vec(row["to"])
		for i in range(int(float(row.get("seconds",4.0))*60)):
			var delta := target-walker.global_position
			delta.y = 0
			var direction := delta.normalized() if delta.length() > 0.08 else Vector3.ZERO
			walker.velocity = Vector3(direction.x*2, 0.0 if walker.is_on_floor() else walker.velocity.y-11.0/60.0, direction.z*2)
			walker.move_and_slide()
			await physics_frame
		var error := Vector2(walker.global_position.x-target.x, walker.global_position.z-target.z).length()
		var passed := error < float(row.get("tolerance",0.3)) and absf(walker.global_position.y-target.y) < float(row.get("height_tolerance",0.2))
		var out := {"tag":row["tag"],"passed":passed,"end":arr(walker.global_position-origin),"target":row["to"]}
		if row.has("expect_collected"):
			var removed := initial_exists and not is_instance_valid(target_cube)
			out["collected"] = removed
			if not initial_exists or removed != bool(row["expect_collected"]):
				passed = false
				out["passed"] = false
				failures.append("collection during actual walker approach: " + str(row["tag"]))
		if row.has("expected_data"):
			var after: Variant = target_host.get(str(row["data"]))
			out["after"] = after.duplicate(true) if after is Array else after
			if not same_values(after, row["expected_data"]):
				passed = false
				out["passed"] = false
				failures.append("value after actual walker approach: " + str(row["tag"]))
		(report["walks"] as Array).append(out)
		if not passed: failures.append("walk: " + str(row["tag"]))
	for row in spec.get("collections", []):
		var host: Node3D = nodes.get(str(row["token"])) as Node3D
		var cube: Node3D = host.get_node_or_null(str(row["child"])) if host != null else null
		if cube == null:
			failures.append("Missing collection target: " + str(row))
			continue
		var before: Variant = host.get(str(row.get("data", "array_data")))
		var before_copy: Variant = before.duplicate(true) if before is Array else before
		cube.call("collect")
		await create_timer(0.3).timeout
		var after: Variant = host.get(str(row.get("data", "array_data")))
		var labels: Array = []
		for label in host.find_children("*", "Label3D", true, false):
			labels.append(label.text)
		var removed := not is_instance_valid(cube)
		if not removed: failures.append("direct collection failed: " + str(row["child"]))
		if row.has("expected_data") and not same_values(after, row["expected_data"]): failures.append("direct collection value mismatch: " + str(row["child"]))
		(report["collections"] as Array).append({"token":row["token"],"child":row["child"],"before":before_copy,"after":after.duplicate(true) if after is Array else after,"labels_after":labels,"removed":removed,"scope":"Invokes live collection method; approach checked separately."})
	if is_instance_valid(walker): walker.hide()
	if DisplayServer.get_name() != "headless":
		var old_camera: Camera3D = museum.get("_cam")
		if old_camera != null:
			for timer in old_camera.find_children("*", "Timer", true, false):
				timer.stop()
		var camera := Camera3D.new()
		root.add_child(camera)
		camera.current = true

		for row in spec.get("shots", []):
			move_handles(specimen,float(row.l),float(row.p))
			specimen.breathing_enabled=bool(row.pulse)
			specimen._breathing_time=PI/(2.0*lerpf(.5,2.0,specimen.lambda))
			specimen._update_pressure()
			specimen._update_state_label()
			for settle in range(120): await physics_frame
			var bounds_min := Vector3(INF,INF,INF)
			var bounds_max := Vector3(-INF,-INF,-INF)
			for point_index in range(specimen._soft_body.mesh.surface_get_array_len(0)):
				var point: Vector3=specimen.to_local(specimen._soft_body.get_point_transform(point_index))
				bounds_min=bounds_min.min(point)
				bounds_max=bounds_max.max(point)
			report.get_or_add("body_bounds",[]).append({"shot":row.tag,"min":arr(bounds_min),"max":arr(bounds_max)})
			check(report,bounds_min.is_finite() and bounds_max.is_finite() and bounds_min.y>=-.01 and bounds_max.y<=specimen.jar_height+.01 and maxf(absf(bounds_min.x),absf(bounds_max.x))<specimen.jar_radius+.01 and maxf(absf(bounds_min.z),absf(bounds_max.z))<specimen.jar_radius+.01,"Deformable mesh stays inside container at %s" % row.tag)
			report.get_or_add("captured_states", []).append({"shot":row.tag,"lambda":specimen.lambda,"phi":specimen.phi,"baseline":specimen._pressure_baseline,"pressure":specimen._soft_body.pressure_coefficient,"stiffness":specimen._soft_body.linear_stiffness,"damping":specimen._soft_body.damping_coefficient,"drag":specimen._soft_body.drag_coefficient,"pulse":specimen.breathing_enabled})

			camera.global_position = origin + vec(row["from"])
			camera.look_at(origin + vec(row["look_at"]))
			camera.fov = float(row.get("fov",70))
			camera.current = true
			await create_timer(0.4).timeout
			await RenderingServer.frame_post_draw
			if root.get_camera_3d() != camera:
				failures.append("capture camera was replaced: " + str(row["tag"]))
			var output := folder + str(row["tag"]) + ".png"
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output))
			(report["shots"] as Array).append(output)
	report["failures"] = failures
	report["passed"] = failures.is_empty()
	var file := FileAccess.open(folder + "report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("ENCOUNTER PROBE ", map_id, " ", "PASS" if failures.is_empty() else "FAIL", " ", failures)
	quit(0 if failures.is_empty() else 1)

func check(report: Dictionary, ok: bool, message: String) -> void:
	(report.checks as Array).append({"ok":ok,"message":message})
	if not ok: failures.append(message)
func move_handles(s: Node, l: float, p: float) -> void:
	s._lambda_slider.set_normalized_value(l)
	s._lambda_slider.slider_moved.emit(0.0)
	s._phi_slider.set_normalized_value((p+1)*.5)
	s._phi_slider.slider_moved.emit(0.0)
func press(s: Node, index: int) -> void:
	s._control_panel.find_child("Btn_%d" % index,true,false).get_node("InteractableAreaButton").button_pressed.emit(null)
