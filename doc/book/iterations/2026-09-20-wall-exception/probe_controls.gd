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

	var cam: Camera3D = museum.get("_cam")
	if cam != null:
		for timer in cam.find_children("*","Timer",true,false): timer.stop()
	var wall: Node3D = nodes.get("wall_exception") as Node3D
	var tiling: Node3D = nodes.get("tiling_principles") as Node3D
	var actor: CharacterBody3D = museum.get("_player")
	var results: Array = []
	if wall == null or tiling == null or actor == null:
		failures.append("Required live artifact or body missing")
	else:
		actor.global_position = origin+Vector3(18.4,0.05,26.5)
		actor.velocity = Vector3.ZERO
		await physics_frame
		await physics_frame
		results.append({"check":"six original fields and wall pattern linked", "passed":tiling.surfaces.size()==6 and wall.study==tiling and wall.face.material_override.albedo_texture==tiling.surfaces[5].material_override.albedo_texture})
		var before_image: PackedByteArray = tiling.surfaces[5].material_override.albedo_texture.get_image().get_data()
		tiling.toggle_exception()
		results.append({"check":"image exception propagates without opening wall", "passed":wall.face.material_override.albedo_texture==tiling.surfaces[5].material_override.albedo_texture and tiling.surfaces[5].material_override.albedo_texture.get_image().get_data()!=before_image and not wall.open and is_zero_approx(wall.hinge.rotation.y)})
		var at: Vector3 = wall.global_position-origin
		results.append({"check":"wall root remains on intended cell and floor", "passed":at.distance_to(Vector3(20.5,0,25.5))<0.03,"position":arr(at)})
		results.append({"check":"museum omitted both replaced wall layers", "passed":(hall.get_meta("em_turning_wall_cells",{}) as Dictionary).size()==4})
		# Exercise the declaration guard independently: no owner means no hole.
		var dummy:=Node3D.new()
		museum.call("_prepare_turning_wall",dummy,{"turning_wall":{"side":"east","start_z":25},"artifacts":[]},hall.get_meta("em_tile"))
		results.append({"check":"opening refused without its placed owner", "passed":not dummy.has_meta("em_turning_wall_cells")})
		dummy.free()
		await capture(origin,folder,"closed",Vector3(16.8,1.65,25.8),Vector3(20.5,1.8,26))
		var stop: Dictionary = await travel(actor,origin,Vector3(18.4,0.05,26.5),Vector3(23.8,0,26.5),3.5)
		results.append({"check":"closed wall stops the walking body", "passed":float(stop.end[0])<20.35 and float(stop.end[0])>19.5,"end":stop.end})
		actor.global_position=origin+Vector3(18.4,0.05,26.5)
		actor.velocity=Vector3.ZERO
		await create_timer(0.15).timeout
		var printed: Texture2D=wall.face.material_override.albedo_texture
		wall.turn_button.get_node("InteractableAreaButton").emit_signal("button_pressed",wall.turn_button.get_node("InteractableAreaButton"))
		await create_timer(0.7).timeout
		results.append({"check":"wall turns gradually with its collider", "passed":wall.moving and wall.angle>0.05 and wall.angle<PI/2 and absf(wall.hinge.rotation.y-wall.angle)<0.03 and wall.hinge.get_child_count()>1,"angle":wall.angle,"body_angle":wall.hinge.rotation.y})
		await create_timer(2.3).timeout
		results.append({"check":"quarter turn completes without changing image", "passed":wall.open and not wall.moving and absf(wall.angle-PI/2)<0.01 and wall.face.material_override.albedo_texture==printed})
		await capture(origin,folder,"open",Vector3(16.8,1.65,25.8),Vector3(20.5,1.8,26))
		var outward: Dictionary = await travel(actor,origin,Vector3(18.4,0.05,26.5),Vector3(23.8,0,26.5),3.5)
		results.append({"check":"walk through both former wall layers onto landing", "passed":outward.passed,"end":outward.end})
		await capture(origin,folder,"outside",Vector3(23.9,1.65,27.0),Vector3(20.5,1.7,25.3))
		await capture(origin,folder,"reverse",Vector3(23.9,1.65,24.3),Vector3(21.5,1.7,25.0))
		wall.turn_button.pressed.emit()
		results.append({"check":"visitor outside prevents closing", "passed":wall.open and not wall.moving and wall.caption.text.contains("RETURN INSIDE")})
		var home: Dictionary=await travel(actor,origin,Vector3(23.8,0.05,26.5),Vector3(18.4,0,26.5),3.5)
		results.append({"check":"walk back into museum", "passed":home.passed,"end":home.end})
		await create_timer(0.15).timeout
		wall.turn_button.pressed.emit()
		await create_timer(2.8).timeout
		results.append({"check":"wall closes after return", "passed":not wall.open and not wall.moving and is_zero_approx(wall.angle)})
		tiling.toggle_exception()
		results.append({"check":"original image restores exactly", "passed":tiling.surfaces[5].material_override.albedo_texture.get_image().get_data()==before_image})
	for result in results:
		if not result.passed:failures.append(str(result.check))
	report["controls"]=results
	report["interaction_scope"]="Actual museum, real button signals, moving collision and controlled CharacterBody walking; no headset comfort or learner acceptance."

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
	var file := FileAccess.open(folder + "controls-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("ENCOUNTER PROBE ", map_id, " ", "PASS" if failures.is_empty() else "FAIL", " ", failures)
	quit(0 if failures.is_empty() else 1)


func travel(actor: CharacterBody3D, origin: Vector3, from: Vector3, to: Vector3, seconds: float) -> Dictionary:
	actor.global_position=origin+from
	actor.velocity=Vector3.ZERO
	var target:=origin+to
	for i in range(int(seconds*60)):
		var delta:=target-actor.global_position
		delta.y=0
		var direction:=delta.normalized() if delta.length()>0.06 else Vector3.ZERO
		actor.velocity=Vector3(direction.x*2,0 if actor.is_on_floor() else actor.velocity.y-11.0/60,direction.z*2)
		actor.move_and_slide()
		await physics_frame
	return {"passed":actor.global_position.distance_to(target)<0.25,"end":arr(actor.global_position-origin)}

func capture(origin:Vector3,folder:String,tag:String,from:Vector3,towards:Vector3) -> void:
	var c:=Camera3D.new()
	root.add_child(c)
	c.global_position=origin+from
	c.look_at(origin+towards)
	c.fov=75
	c.current=true
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	if root.get_camera_3d()!=c:failures.append("capture camera replaced")
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+tag+".png"))
	c.queue_free()
