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

	var old_cam: Camera3D = museum.get("_cam")
	if old_cam != null:
		for timer in old_cam.find_children("*", "Timer", true, false): timer.stop()
	var actor: CharacterBody3D = museum.get("_player")
	actor.global_position = origin + Vector3(2,0.1,2)
	var dungeon: Node3D = nodes.get("lsystem_dungeon")
	var desk: Node3D = dungeon.get_node_or_null("ArchitectureLesson") if dungeon != null else null
	review_check(desk != null, "Architecture lesson instantiated")
	if desk != null:
		var records: Dictionary = desk.records.duplicate(true)
		review_check(records.rooms.size()==2 and desk.room_addresses.size()==1, "two room records still share one address")
		review_check(not revealed(desk) and not desk.address_revealed, "opening leaves the address answer undisclosed in both labels")
		await photo(origin+Vector3(9.5,1.65,4.6), origin+Vector3(9.5,1.3,7.2), folder+"after-opening.png",65)
		await press(desk,"BUILD")
		review_check(desk.built and not revealed(desk), "BUILD preserves the unanswered comparison")
		await press(desk,"WIDTH")
		review_check(desk.width_index==2 and not revealed(desk), "WIDTH does not give away the address")
		await press(desk,"RULE")
		review_check(desk.address_revealed and revealed(desk), "RULE reveals the shared address in both labels")
		review_check(desk.readout.text.contains("mark this position"), "RULE retains the interpreter explanation")
		await press(desk,"RESET")
		review_check(not desk.address_revealed and not revealed(desk), "RESET restores discovery before ROOMS")
		await press(desk,"ROOMS")
		review_check(desk.rooms_enabled and revealed(desk) and desk.room_cells.size()==196, "ROOMS reveals one address while constructing its footprint")
		await photo(origin+Vector3(9.5,1.65,4.6), origin+Vector3(9.5,1.3,7.2), folder+"revealed.png",65)
		await press(desk,"ROOMS")
		review_check(not desk.rooms_enabled and revealed(desk), "removing the footprint keeps the discovered answer")
		await press(desk,"RESET")
		review_check(not desk.address_revealed and not revealed(desk) and not desk.built and desk.width_index==1, "RESET returns the complete opening state")
		review_check(desk.records==records, "all controls preserve the original sentence and records")
	# Exercise the actual streaming selection; never substitute a bespoke room order.
	var next_map: String = museum.call("_peek_next_authored_map")
	review_check(next_map=="LSystems_Competition", "museum selects Competition after Architecture")
	if next_map=="LSystems_Competition":
		museum.call("_build_segment")
		museum.call("flush_stamps")
		await create_timer(1).timeout
		var competition: Node3D = find_hall(museum,"LSystems_Competition")
		review_check(competition!=null, "Competition builds as the next museum segment")
		if competition != null:
			var forest: Node3D = null
			for record in museum.get("_edit_records"):
				if record.get("seg")==competition and record.get("token")=="ForestCompetition": forest=record.get("node")
			var pair: Node3D = forest.get_node_or_null("CompetitionLesson") if forest != null else null
			review_check(pair!=null, "restored forest includes its controlled pair")
			if pair != null:
				await press(pair,"STEP"); await press(pair,"STEP")
				review_check(is_equal_approx(pair.last_takes[0],2.25) and is_equal_approx(pair.last_takes[1],1.98), "restored encounter gives A first uptake 2.250 and B 1.980")
				await press(pair,"ORDER"); await press(pair,"STEP"); await press(pair,"STEP")
				review_check(is_equal_approx(pair.last_takes[1],2.25) and is_equal_approx(pair.last_takes[0],1.98), "changing the first turn reverses the advantage")
				await photo(pair.to_global(Vector3(5,5,4)),pair.to_global(Vector3(0,0,-3)),folder+"competition.png",73)
				await press(pair,"SEASON"); await press(pair,"STEP"); await press(pair,"STEP")
				review_check(pair.winter and pair.model._trees[0].generation==0 and pair.model._trees[1].generation==0 and pair.last_takes[0]>0 and pair.last_takes[1]>0, "winter still consumes without rewriting")
				report["competition_placement"] = arr(forest.global_position-competition.global_position-Vector3(0,0,4))
			next_map= museum.call("_peek_next_authored_map")
			review_check(next_map=="LSystems_Living", "museum selects Living after Competition")
			if next_map=="LSystems_Living":
				museum.call("_build_segment")
				museum.call("flush_stamps")
				await create_timer(1).timeout
				review_check(find_hall(museum,"LSystems_Living")!=null, "Living builds as the third segment")
	var route: Array = []
	for child in museum.get_children():
		if child.has_meta("em_map"): route.append(str(child.get_meta("em_map")))
	report["built_route"]=route
	report["review_checks"]=review_results
	report["review_scope"]="Real museum segment selection/building and real button signals. No end-to-end walk, headset comfort or learner acceptance claimed."

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
	var file := FileAccess.open(folder + "review-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("ENCOUNTER PROBE ", map_id, " ", "PASS" if failures.is_empty() else "FAIL", " ", failures)
	quit(0 if failures.is_empty() else 1)


var review_results: Array = []

func review_check(ok: bool, name_: String) -> void:
	review_results.append({"check":name_,"passed":ok})
	if not ok: failures.append(name_)

func revealed(desk: Node3D) -> bool:
	return desk.program.text.contains("1 shared address") and desk.readout.text.contains("1 shared address")

func press(desk: Node3D, id: String) -> void:
	var button: Node = desk.buttons[id].get_node("InteractableAreaButton")
	button.emit_signal("button_pressed",button)
	await create_timer(0.08).timeout

func find_hall(museum: Node3D, id: String) -> Node3D:
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map",""))==id: return child
	return null

func photo(from: Vector3, toward: Vector3, path: String, fov_: float) -> void:
	var c:=Camera3D.new()
	root.add_child(c);c.global_position=from;c.look_at(toward);c.fov=fov_;c.current=true
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	review_check(root.get_camera_3d()==c,"capture camera owns "+path.get_file())
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	c.queue_free()
