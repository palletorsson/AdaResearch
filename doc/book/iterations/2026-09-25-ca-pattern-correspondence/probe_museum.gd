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
	OS.low_processor_usage_mode = false
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
	var scene_host:=Node3D.new();scene_host.name="MuseumProbeHost"
	root.add_child(scene_host);current_scene=scene_host
	scene_host.add_child(museum)
	var started := Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec() - started < 60000:
		await process_frame
	museum.set("_lazy_pending", 0)
	museum.set_process(false)
	museum.set_physics_process(false)
	museum.call("flush_stamps")
	var museum_camera: Camera3D = museum.get("_cam")
	if museum_camera != null:
		for timer in museum_camera.find_children("*","Timer",true,false): timer.stop()
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
	await investigate_pair(nodes, origin, report, folder, museum)
	await physics_frame
	var space := hall.get_world_3d().direct_space_state
	for row in spec.get("rays", []):
		var ray := PhysicsRayQueryParameters3D.create(origin + Vector3(float(row["x"]),float(row.get("from_y",20.0)),float(row["z"])), origin + Vector3(float(row["x"]),-5,float(row["z"])), 1)
		var ray_walker:CollisionObject3D= museum.get("_player")
		if ray_walker!=null:ray.exclude=[ray_walker.get_rid()]
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


func check(report: Dictionary, label: String, passed: bool, value: Variant = null) -> void:
	if not report.has("checks"): report["checks"] = []
	report["checks"].append({"name":label,"passed":passed,"value":value})
	if not passed: failures.append(label)


func investigate_pair(nodes: Dictionary, origin: Vector3, report: Dictionary, folder: String, museum: Node3D) -> void:
	report["desktop_input"] = []; report["visits"] = []
	var work: Node3D = nodes["ca_rule_explorer"]
	var pyramid: Node3D = nodes["sierpinski_pyramid"]
	var study: Node3D = work.get_node("NeighbourStudy")
	var floor_view: Node3D = study.get_node("ComparisonFloor")
	check(report, "two original authored works present", work != null and pyramid != null)
	check(report, "same 32-cell rule 90 begins held", work.cells_x == 32 and work.rule == 90 and not work.auto_run and work.generation == 0)
	check(report, "recursive recipe unchanged: six calls, depth four", pyramid.depth == 4 and pyramid.extra_crown and pyramid.leaf_count == 1296)
	var leaf_positions: Array = []
	for child in pyramid.get_children():
		if child is Node3D: leaf_positions.append(child.transform)
	check(report, "caption faces arrival and time points along the floor", floor_view.caption.global_basis.y.dot(Vector3.FORWARD) < -.99 and floor_view.caption.global_basis.z.dot(Vector3.UP) > .99)
	check(report, "floor introduces no physics receiver or collider", floor_view.find_children("*", "CollisionObject3D", true, false).is_empty())
	check(report, "floor begins beside desk and ends before pyramid", absf(floor_view.global_position.y - origin.y - .01) < .001 and absf(floor_view.global_position.x - origin.x - 7.4) < .001 and absf(floor_view.global_position.z - origin.z - 8.34) < .001, arr(floor_view.global_position-origin))
	var walker: CharacterBody3D = museum.get("_player")
	var cam: Camera3D = museum.get("_cam")
	var hand: Node3D = walker.get_node("DesktopHand")
	museum.set_process_input(false);museum.set_process_unhandled_input(false)
	walker.set_physics_process(false)
	var feel: Node = museum.get("_feel")
	if feel: feel.set_process(false);feel.set_physics_process(false)
	walker.global_position = origin + Vector3(3.5, .05, 3.55)
	walker.velocity = Vector3.ZERO
	await settle(walker)
	cam.position = Vector3(0, 1.65, 0)
	hand.set_process(true)
	await click_room_control(work._control_panel, "Btn_1", walker, cam, hand, origin, report)
	await click_room_control(work._control_panel, "Btn_4", walker, cam, hand, origin, report)
	await click_room_control(study.get_node("StudyControls"), "Btn_0", walker, cam, hand, origin, report)
	check(report, "mouse STEP makes exactly one generation", work.generation == 1)
	for i in range(14): work.step()
	floor_view.refresh()
	check(report, "floor reads the desk history exactly at 15", floor_matches(work,floor_view))
	# Rule 90's single-seed Pascal parity is an independent expected pattern here.
	var pascal_ok: bool = floor_view.rendered.size() == 16
	for g in range(mini(16, floor_view.rendered.size())):
		var expected: Array[bool] = [];expected.resize(32);expected.fill(false)
		for k in range(g+1):
			if (k & g) == k: expected[posmod(16-g+2*k,32)] = true
		if floor_view.rendered[g] != expected: pascal_ok = false
	check(report, "sixteen rows agree with independent Pascal parity", pascal_ok)
	var camera := Camera3D.new();root.add_child(camera)
	await view(camera,origin,folder,"floor-history",Vector3(6.5,5.6,4.4),Vector3(7.3,0,8.4),68,report)
	await view(camera,origin,folder,"comparison",Vector3(5.5,1.65,6.5),Vector3(8.2,1.35,10.6),80,report)
	# Walk onto one genuinely unoccupied cell inside the central triangular gap.
	check(report, "chosen gap is empty in generation eleven", not floor_view.rendered[11][16])
	walker.global_position = origin + Vector3(5.3,.05,6.1);await settle(walker)
	var gap: Vector3 = floor_view.to_global(floor_view.at(16,11));gap.y = origin.y
	var route: Dictionary = await walk_to(walker, gap);report.visits.append(route)
	check(report, "body can stand in the drawn triangular gap", route.passed and walker.is_on_floor(), arr(walker.global_position-origin))
	await view(camera,origin,folder,"standing-gap",walker.global_position-origin+Vector3(0,1.65,0),Vector3(9.5,2.8,12.5),78,report)
	work.step();floor_view.refresh()
	check(report, "generation sixteen cancels around the ring", work.generation == 16 and work._current_row.count(true) == 0 and floor_matches(work,floor_view))
	await settle(walker)
	check(report, "new empty row does not remove the supporting floor", walker.is_on_floor() and absf(walker.global_position.y-origin.y)<.025)
	var beside: Dictionary = await walk_to(walker,origin+Vector3(6.6,0,12.5));report.visits.append(beside)
	check(report, "continuous walk from history to side of pyramid", beside.passed, beside)
	await view(camera,origin,folder,"beside-pyramid",walker.global_position-origin+Vector3(0,1.65,0),Vector3(9.5,2.2,12.5),80,report)
	# Return by the open side, then operate SEED with the museum's real mouse ray.
	var ret: Dictionary = await walk_to(walker,origin+Vector3(5.3,0,6.1));report.visits.append(ret)
	check(report, "floor route back remains open", ret.passed)
	walker.global_position=origin+Vector3(3.5,.05,3.55);await settle(walker);cam.position=Vector3(0,1.65,0);cam.current=true
	await click_room_control(study.get_node("StudyControls"), "Btn_2", walker, cam, hand, origin, report)
	floor_view.refresh()
	check(report, "SEED clears both histories to two adjacent cells", work.seed_pair and work.generation == 0 and floor_view.rendered.size()==1 and floor_view.rendered[0].count(true)==2 and floor_matches(work,floor_view))
	for i in range(15): work.step()
	floor_view.refresh()
	check(report, "pair has a different live pattern on the same receiver", floor_view.rendered[15].count(true)==32 and floor_matches(work,floor_view))
	await view(camera,origin,folder,"pair-history",Vector3(6.5,5.6,4.4),Vector3(7.3,0,8.4),68,report)
	var after_positions: Array = []
	for child in pyramid.get_children():
		if child is Node3D: after_positions.append(child.transform)
	check(report, "changing seed did not change the pyramid", after_positions==leaf_positions)
	await click_room_control(study.get_node("StudyControls"), "Btn_2", walker, cam, hand, origin, report)
	await click_room_control(work._control_panel, "Btn_0", walker, cam, hand, origin, report)
	for i in range(30): work.step()
	floor_view.refresh()
	check(report, "Rule 30 history scrolls without invented cells", work.rule==30 and floor_view.rendered.size()==24 and floor_matches(work,floor_view))
	check(report, "caption records actual retained rows after scroll", "ROWS 7–30" in floor_view.caption.text)
	await click_room_control(work._control_panel, "Btn_4", walker, cam, hand, origin, report)
	floor_view.refresh()
	check(report, "RST clears obsolete floor rows", work.generation==0 and floor_view.rendered.size()==1 and floor_matches(work,floor_view))
	await click_room_control(study.get_node("StudyControls"), "Btn_1", walker, cam, hand, origin, report)
	await create_timer(.7).timeout
	await click_room_control(study.get_node("StudyControls"), "Btn_1", walker, cam, hand, origin, report)
	floor_view.refresh()
	check(report, "RUN uses original clock then holds both views", work.generation>=2 and not work.auto_run and floor_matches(work,floor_view))
	var held: int = work.generation
	await create_timer(.4).timeout
	check(report, "floor has no second clock", work.generation==held and floor_matches(work,floor_view))
	# An unconfigured placement must not acquire a comparison carpet.
	var plain: Node3D = load("res://commons/artifacts/ca_rule_explorer/ca_rule_explorer.tscn").instantiate()
	plain.position=origin+Vector3(50,0,50);root.add_child(plain);await process_frame
	check(report, "ordinary explorer retains default 64 cells and no floor", plain.cells_x==64 and not plain.has_node("NeighbourStudy"))
	plain.queue_free()
	work.rule=90;work.seed_pair=false;work._reset()
	for i in range(15):work.step()
	floor_view.refresh()
	camera.queue_free()

func floor_matches(work: Node3D, floor_view: Node3D) -> bool:
	if floor_view.rendered.size()!=work._grid.size():return false
	for row in range(work.rows_visible):
		for col in range(work.cells_x):
			var idx: int = row*work.cells_x+col
			var present: bool = row < work._grid.size()
			var transform: Transform3D = floor_view.cells.get_instance_transform(idx)
			if not present:
				if absf(transform.basis.determinant())>.001:return false
				continue
			var source_index: int = work._grid.size()-1-row
			if floor_view.rendered[row][col] != work._grid[source_index][col]:return false
			var expected: Color = work._multimesh.get_instance_color(source_index*work.cells_x+col)
			if not floor_view.cells.get_instance_color(idx).is_equal_approx(expected):return false
	return true

func walk_to(walker:CharacterBody3D,target:Vector3)->Dictionary:
	for frame in range(700):
		var d:Vector3=target-walker.global_position;d.y=0
		if d.length()<.035:break
		var v:Vector3=d.normalized()*1.8
		walker.velocity=Vector3(v.x,0 if walker.is_on_floor() else walker.velocity.y-11.0/60,v.z)
		walker.move_and_slide();await physics_frame
	walker.velocity=Vector3.ZERO;await physics_frame;await physics_frame
	return {"passed":Vector2(walker.global_position.x-target.x,walker.global_position.z-target.z).length()<.06 and absf(walker.global_position.y-target.y)<.03,"end":arr(walker.global_position),"target":arr(target)}

func settle(walker:CharacterBody3D)->void:
	for frame in range(20):
		walker.velocity=Vector3(0,-1,0);walker.move_and_slide();await physics_frame

func view(camera:Camera3D,origin:Vector3,folder:String,tag:String,from:Vector3,target:Vector3,fov:float,report:Dictionary)->void:
	camera.global_position=origin+from;camera.look_at(origin+target);camera.fov=fov
	await shot(camera,folder,tag,report)

func shot(camera:Camera3D,folder:String,tag:String,report:Dictionary)->void:
	camera.current=true;await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	var path:=folder+tag+".png";root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path));report["shots"].append(path)

func click_room_control(a:Node3D,key:String,walker:CharacterBody3D,cam:Camera3D,hand:Node3D,origin:Vector3,report:Dictionary)->void:
	var area:Node3D=a.find_child(key,true,false).get_node("InteractableAreaButton")
	cam.look_at(area.global_position);cam.current=true
	await physics_frame
	hand.global_transform=cam.global_transform
	var ray:RayCast3D=hand.get("_raycast");ray.force_raycast_update();hand._process(0)
	var tally:Dictionary={"n":0}
	var count:Callable=func(_b):tally.n+=1
	area.button_pressed.connect(count)
	var hover:Node3D=hand.get("_last_target")
	# Also check ordinary geometry; the interaction ray intentionally ignores walls.
	var q:=PhysicsRayQueryParameters3D.create(cam.global_position,area.global_position,1)
	q.exclude=[walker.get_rid()]
	var blocked:Dictionary=cam.get_world_3d().direct_space_state.intersect_ray(q)
	var blocker:Node=blocked.get("collider")
	var clear_to_button:bool=blocker==null or a.find_child(key,true,false).is_ancestor_of(blocker)
	for down in [true,false]:
		var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=root.get_visible_rect().size*.5;e.global_position=e.position
		Input.parse_input_event(e);Input.flush_buffered_events();await process_frame;await physics_frame
	area.button_pressed.disconnect(count)
	var rec:Dictionary={"button":key,"emissions":tally.n,"hover_matches":hover==area,"eye":arr(cam.global_position-origin),"feet":arr(walker.global_position-origin),"button_position":arr(area.global_position-origin),"distance":cam.global_position.distance_to(area.global_position),"geometry_blocker":str(blocker.get_path()) if blocker!=null else "none","clear_to_button":clear_to_button}
	report.desktop_input.append(rec)
	check(report,"actual museum mouse ray operates "+key,hover==area and tally.n==1 and clear_to_button,rec)

