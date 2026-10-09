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

	for timer in museum.get("_cam").find_children("*","Timer",true,false):timer.stop()

	var desk: Node3D = nodes.get("soft_workshop_console")
	check(desk!=null and desk.ready_for_input,"hall desk binds both specimens")
	if desk!=null and desk.ready_for_input:
		var m: Node3D = desk.model
		check(not m.volume_feedback,"feedback is explicitly off at arrival")
		check(is_equal_approx(m.position.y,0.84),"lesson bench is seated before reference capture")
		check(m._vertex_count>0 and m._rest_volume>0,"seated specimen has a physics reference")
		var body_bounds:=AABB()
		for i in m._vertex_count:
			var p: Vector3=PhysicsServer3D.soft_body_get_point_global_position(m._sb_rid,i)
			if i==0:body_bounds=AABB(p,Vector3.ZERO)
			else:body_bounds=body_bounds.expand(p)
		check(body_bounds.position.y-origin.y>0.65 and body_bounds.end.y-origin.y<2.0,"live body is at standing working height")
		report["specimen_y_range"]=[body_bounds.position.y-origin.y,body_bounds.end.y-origin.y]
		check(Vector2(body_bounds.get_center().x-m.global_position.x,body_bounds.get_center().z-m.global_position.z).length()<0.65,"live points remain with their placed bench")
		check(m._strain_mi.global_transform.is_equal_approx(Transform3D.IDENTITY) and m._ghost_mi.global_transform.is_equal_approx(Transform3D.IDENTITY) and m._force_mi.global_transform.is_equal_approx(Transform3D.IDENTITY),"world-space overlays align with the solver rather than being transformed twice")
		await photo(origin+Vector3(8.5,1.75,8.2),origin+Vector3(8.5,1.1,10.5),folder+"specimen.png",60)
		var mouse:=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=true
		Input.parse_input_event(mouse);await process_frame
		m._update_vr_hand(0.016)
		check(m._hand_active and m._hand_pos.distance_to(m._current_center)<0.5,"desktop squeeze follows the live body instead of world zero")
		mouse.pressed=false;Input.parse_input_event(mouse);await process_frame
		var ys: Dictionary={}
		var zs: Dictionary={}
		for b in desk.buttons.values():ys[b.position.y]=true;zs[b.position.z]=true
		check(desk.buttons.size()==7 and ys.size()==1 and zs.size()==2,"seven controls retain two rows and one height")
		var p0: float=m._soft_body.pressure_coefficient
		for mode in ["collision","volume","strain"]:
			await press(desk,"MEASURE")
			await create_timer(0.15).timeout
			check(m.measure==mode and is_equal_approx(m._soft_body.pressure_coefficient,p0),"reading "+mode+" does not change pressure")
		await press(desk,"MEASURE");await press(desk,"MEASURE")
		await press(desk,"FEEDBACK")
		check(m.volume_feedback and m.measure=="volume","feedback can be enabled without changing the reading")
		# Controlled nonzero error isolates pressure feedback from solver variability.
		m.set_process(false)
		var saved_rest: float=m._rest_volume
		var saved_current: float=m._current_volume
		m._rest_volume=1.0;m._current_volume=0.5
		m._soft_body.pressure_coefficient=0.3
		m._apply_volume_correction(0.1)
		check(is_equal_approx(m._soft_body.pressure_coefficient,0.315),"declared feedback error changes pressure by gain times elapsed delta")
		await press(desk,"MEASURE")
		var before: float=m._soft_body.pressure_coefficient
		m._apply_volume_correction(0.1)
		check(m.measure=="strain" and m.volume_feedback and m._soft_body.pressure_coefficient>before,"feedback continues under a different reading")
		await press(desk,"FEEDBACK")
		m._apply_volume_correction(0.1)
		check(not m.volume_feedback and is_equal_approx(m._soft_body.pressure_coefficient,m._pressure),"feedback off restores selected pressure and blocks correction")
		m._rest_volume=saved_rest;m._current_volume=saved_current
		# The instrument's local button shares the hall controller's state.
		var local_button: Node=m._rack_panel.find_child("Btn_1",true,false).get_node("InteractableAreaButton")
		local_button.emit_signal("button_pressed",local_button)
		await create_timer(0.6).timeout
		check(m.volume_feedback and desk.readout.text.contains("feedback ON"),"local feedback button updates the hall readout")
		local_button.emit_signal("button_pressed",local_button)
		m.set_process(true)
		# Root configuration must not overwrite a mode selected on the child.
		m._cycle_mode()
		desk.works.rounded_softbody_test.apply_grid_config({"volume_feedback":"true"})
		check(m.measure=="collision" and m.volume_feedback,"root forwards feedback without resetting the selected reading")
		desk.works.rounded_softbody_test.apply_grid_config({"volume_feedback":"false"})
		await press(desk,"MEASURE")
		await photo(origin+Vector3(15.5,1.7,0.7),origin+Vector3(15.5,1.1,2.8),folder+"volume-reading.png",70)
		await press(desk,"FEEDBACK")
		await photo(origin+Vector3(15.5,1.7,0.7),origin+Vector3(15.5,1.1,2.8),folder+"volume-feedback.png",70)
		await press(desk,"FEEDBACK");await press(desk,"MEASURE")
		await press(desk,"SQUEEZE");await press(desk,"STIFFNESS")
		check(is_equal_approx(m._squeeze_strength,1.0) and is_equal_approx(m._soft_body.linear_stiffness,0.1),"material and interaction controls remain separate")
		m._on_squeeze_changed("review",0.4);m._on_stiffness_changed("review",0.5)
		var vessel: Node3D=desk.other
		await check_skin(vessel,"initial 200 steps")
		for steps in [40,400,200]:
			var old_skin: Node=vessel.get_node("Vessel/FrozenSkin")
			await press(desk,"DURATION")
			check(not is_instance_valid(old_skin) or not old_skin.is_inside_tree(),"duration "+str(steps)+" removes the old collision")
			check(vessel.sim_steps==steps,"duration chooses "+str(steps)+" integration steps")
			await check_skin(vessel,str(steps)+" steps")
			if steps in [40,400]:await photo(origin+Vector3(23,2.5,10),origin+Vector3(20.5,1,13.5),folder+"vessel-"+str(steps)+".png",65)
		for gx in [2.0,-2.0,0.0]:
			await press(desk,"GRAVITY")
			check(is_equal_approx(vessel.gravity_x,gx),"lateral force chooses "+str(gx))
			await check_skin(vessel,"gravity "+str(gx))
		# Actual body support/contact, not a claim that the closed skin has an entrance.
		var actor: CharacterBody3D=museum.get("_player")
		museum.set("_player",null)
		var skin: Node=vessel.get_node("Vessel/FrozenSkin")
		var bounds: AABB=vessel._mi.mesh.get_aabb()
		var peak: Vector3=vessel._mi.to_global(Vector3(0,bounds.end.y,0))
		actor.global_position=peak+Vector3.UP
		actor.velocity=Vector3.ZERO
		var met_skin:=false
		for i in 150:
			actor.velocity=Vector3(0,actor.velocity.y-11.0/60.0,0)
			actor.move_and_slide()
			for j in actor.get_slide_collision_count():
				if actor.get_slide_collision(j).get_collider()==skin:met_skin=true
			await physics_frame
		check(met_skin and actor.global_position.y-origin.y>0.5,"CharacterBody meets and is supported by the frozen surface")
		report["body_on_skin"]={"contact":met_skin,"position":arr(actor.global_position-origin)}
		actor.global_position=origin+Vector3(27,0.1,3)
		await press(desk,"RULE")
		check(desk.rule_card.visible,"explanation remains available after the encounter")
		await press(desk,"RULE")
		# The shared desk's original six-button layout remains unchanged.
		var six: Node3D=load("res://commons/artifacts/timing_machines/pg_workshop.gd").new()
		root.add_child(six);six.position=Vector3(100,0,100)
		six._build_compact_console(["A","B","C","D","E","F"],"layout check")
		check(six.buttons.A.position.is_equal_approx(Vector3(-0.32,1.045,1.88)) and six.buttons.F.position.is_equal_approx(Vector3(0.32,1.045,2.11)),"six-button desks keep their prior layout")
		six.queue_free()
		var original: Node3D=load("res://algorithms/softbodies/rounded_softbody_test.tscn").instantiate()
		original.position=Vector3(100,10,100);root.add_child(original)
		check(is_equal_approx(original.get_node("RoundedSoftBody").position.y,3.0),"unconfigured harnesses retain their prior elevation")
		await process_frame;await process_frame
		original.queue_free()
	report["review_checks"]=checks
	report["review_scope"]="Actual museum artifacts and button signals. One controlled error tests feedback independently of solver variability. Matching mesh/collision, reconstruction replacement, support rays and a CharacterBody contact test. No headset or learner acceptance."

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
	if DisplayServer.get_name() != "headless":
		var old_camera: Camera3D = museum.get("_cam")
		if old_camera != null:
			for timer in old_camera.find_children("*", "Timer", true, false):
				timer.stop()
		var camera := Camera3D.new()
		root.add_child(camera)
		camera.current = true
		for row in spec.get("shots", []):
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


var checks: Array=[]
func check(ok: bool, label: String) -> void:
	checks.append({"check":label,"passed":ok})
	if not ok:failures.append(label)

func press(desk: Node3D,id: String) -> void:
	var b: Node=desk.buttons[id].get_node("InteractableAreaButton")
	b.emit_signal("button_pressed",b)
	await create_timer(0.2).timeout

func check_skin(vessel: Node3D,label: String) -> void:
	await physics_frame
	var skin: StaticBody3D=vessel.get_node_or_null("Vessel/FrozenSkin")
	var bodies: Array=vessel.find_children("*","StaticBody3D",true,false)
	check(skin!=null and bodies.size()==1,label+": exactly one active skin")
	if skin==null:return
	var shape: ConcavePolygonShape3D=skin.get_node("Surface").shape
	check(shape.backface_collision and shape.get_faces()==vessel._mi.mesh.get_faces(),label+": collision matches both sides of the rendered mesh")
	var bounds: AABB=vessel._mi.mesh.get_aabb()
	check(absf(vessel._mi.position.y+bounds.position.y)<0.001,label+": full form meets its floor datum")
	var ray:=PhysicsRayQueryParameters3D.create(vessel._mi.to_global(Vector3(0,bounds.end.y+0.5,0)),vessel._mi.to_global(Vector3(0,bounds.position.y-0.1,0)),1)
	var hit:=vessel.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and hit.collider==skin,label+": vertical ray meets the actual skin")

func photo(from: Vector3,toward: Vector3,path: String,fov_: float) -> void:
	var c:=Camera3D.new();root.add_child(c)
	c.global_position=from;c.look_at(toward);c.fov=fov_;c.current=true
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	check(root.get_camera_3d()==c,"capture camera owns "+path.get_file())
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	c.queue_free()
