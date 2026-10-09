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
	var study: Node3D=nodes.get("peer_production_tool")
	check(report,is_instance_valid(study),"Primary workbench instantiated")
	if not is_instance_valid(study):
		quit(1)
		return
	check(report,study.interactive and study.scale.is_equal_approx(Vector3.ONE),"Full-size interactive placement")
	check(report,is_equal_approx(study.add_period,.7),"Hall has slower arrivals")
	study.set_process(false)
	study.apply_grid_config({"interactive":true,"max_facets":60})
	var external:=Node3D.new()
	study.add_child(external)
	study.apply_grid_config({"interactive":true})
	check(report,is_instance_valid(external) and external.get_parent()==study,"Config rebuild preserves museum children")
	var initial_children: int=study.get_child_count()
	study.apply_grid_config({"interactive":true})
	await process_frame
	check(report,study.get_child_count()==initial_children,"Config rebuild remains bounded")
	study._paused=true
	for peer in [0,0,1]: study._place_facet(peer)
	check(report,counts(study)==[3,3,2,2,2,0,1],"Repeated source adds a piece but not another distinct source")
	var poses: Array=[]
	for i in range(3): poses.append(study._facets.multimesh.get_instance_transform(i))
	press(study,1)
	check(report,study._show_sources,"COLOUR exposes source identity")
	for i in range(3):
		check(report,study._facets.multimesh.get_instance_color(i).is_equal_approx(study._source_colour(int(study._records[i].source))),"Piece %d keeps source colour" % i)
		check(report,study._facets.multimesh.get_instance_transform(i).is_equal_approx(poses[i]),"Colour leaves piece %d in place" % i)
	press(study,2)
	check(report,study._paused and study._selected==1,"PIECE holds flow and selects next existing piece")
	press(study,3)
	check(report,study._records[1].disputed and counts(study)==[3,3,2,2,2,0,1],"DISPUTE marks without adding a contribution")
	var original: Transform3D=study._records[1].current
	press(study,4)
	check(report,counts(study)==[3,3,2,2,2,1,1],"REVISE increments only revision count")
	check(report,study._records[1].current!=original and study._records[1].previous==original and study._records[1].original==original,"Revision changes pose and retains previous/original pose")
	check(report,study._records[1].source==0 and study._records[1].revised_by=="VISITOR" and study._records[1].disputed,"Source persists and visitor revision does not settle dispute")
	check(report,study._facets.multimesh.get_instance_transform(0).is_equal_approx(poses[0]) and study._facets.multimesh.get_instance_transform(2).is_equal_approx(poses[2]),"Unselected pieces remain unchanged")
	press(study,3)
	check(report,not study._records[1].disputed,"Dispute can be cleared independently")
	press(study,0)
	study._spawn_packet(study._peers[2].marker.position,2)
	press(study,0)
	var life: float=study._packets[0].life
	study._process(.5)
	check(report,is_equal_approx(study._packets[0].life,life) and study._placed==3,"Held flow freezes packets and additions")
	press(study,0)
	study._process(.3)
	check(report,study._records.back().source==2 and study._placed==4,"Packet arrival preserves its actual sender")
	press(study,5)
	check(report,study._paused and study._packets.is_empty() and study._placed==0 and study._records.is_empty(),"VERSION clears form and in-flight packets, then waits")
	check(report,study._last_version.size()==4 and study._last_version[1].revision==1,"Previous version retains revision record")
	study._place_facet(0)
	check(report,counts(study)==[1,5,1,3,4,1,2],"Across versions participation rises but lifetime unique source does not")
	check(report,study._readout.text.contains("PARTICIPATIONS 4") and study._readout.text.contains("SOURCES 1/12 | EVER 3"),"Readout names the different counting domains")
	for i in range(70): study._place_facet(i%12)
	check(report,study._placed==60 and study._records.size()==60,"Capacity is bounded at sixty pieces")
	study._paused=false
	study._process(1.0)
	check(report,study._paused and study._placed==60,"Interactive capacity holds for inspection")
	press(study,5)
	press(study,3)
	press(study,4)
	check(report,study._placed==0 and study._selected==-1,"Empty dispute and revision are safe")
	for i in range(6):
		var button: Node3D=study._controls.find_child("Btn_%d" % i,true,false)
		check(report,button.global_position.distance_to(study.to_global(Vector3(0,1.3,1.6)))<.9,"Control %d within selected reach" % i)
	var legacy=load("res://commons/artifacts/peer_production_tool/peer_production_tool.tscn").instantiate()
	legacy.position=Vector3(1000,10,0)
	root.add_child(legacy)
	legacy.set_process(false)
	check(report,not legacy.interactive and not is_instance_valid(legacy._controls),"Passive default retains automatic exhibit without workbench controls")
	legacy.apply_grid_config({"peer_count":0,"max_facets":0,"add_period":0})
	check(report,legacy.peer_count==1 and legacy.max_facets==1 and legacy.add_period>=.08,"Grid configuration bounds prevent zero division and runaway counts")
	legacy._place_facet(0)
	legacy._process(.1)
	check(report,legacy._version==2 and legacy._placed==0,"Passive capacity still starts next version automatically")
	legacy.queue_free()
	seed_study(study)
	var gate: Dictionary=museum.get("_gate")
	if not gate.is_empty():
		gate.scanner.palm_scanned.emit()
		museum.get("_mod_gate").call("step_open",gate,10.0)
		await physics_frame
	check(report,gate.is_empty() or float(museum.get("_gate_t"))>=0,"Gate granted for selected walking tests")
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
		var blockers: Array=[]
		for c in range(walker.get_slide_collision_count()): blockers.append({"path":str(walker.get_slide_collision(c).get_collider().get_path()),"position":arr(walker.get_slide_collision(c).get_position()),"normal":arr(walker.get_slide_collision(c).get_normal()),"shape":walker.get_slide_collision(c).get_collider_shape()})
		out["blockers"]=blockers
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
			prepare_view(study,str(row.mode))
			await process_frame
			row["from"]=arr(study.to_global(Vector3(0,1.7,3.5))-origin)
			row["look_at"]=arr(study.to_global(Vector3(0,1.35,0))-origin)
			row["fov"]=64
			if row.mode=="side":
				row["from"]=arr(study.to_global(Vector3(2.5,1.7,2.6))-origin)
			report.get_or_add("captured_states",[]).append({"shot":row.tag,"counts":counts(study),"selected":study._selected,"record":str(study._records[study._selected]) if study._selected>=0 else "empty","readout":study._readout.text,"detail":study._detail.text})

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
func press(s: Node, i: int) -> void:
	s._controls.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton").button_pressed.emit(null)
func counts(s: Node) -> Array:
	return [s._placed,s._edits,s._version_sources,s._ever_seen.size(),s._contributors,s._revisions,s._version]
func seed_study(s: Node) -> void:
	s.apply_grid_config({"interactive":true,"add_period":.7})
	s._paused=true
	for i in range(40): s._place_facet([0,1,0,2,3,0,4,5][i%8])
	s._selected=30
	s._refresh_marks()
	s._update_readout()
func prepare_view(s: Node, mode: String) -> void:
	if mode=="order": seed_study(s)
	if mode=="sources": press(s,1)
	if mode=="dispute": press(s,3)
	if mode=="revision": press(s,4)
	if mode=="version":
		press(s,5)
		for peer in [0,0,1]: s._place_facet(peer)
