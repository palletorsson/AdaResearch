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
		var ray := PhysicsRayQueryParameters3D.create(origin + Vector3(float(row["x"]),20,float(row["z"])), origin + Vector3(float(row["x"]),-5,float(row["z"])), 1)
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


func investigate_pair(nodes:Dictionary,origin:Vector3,report:Dictionary,folder:String,museum:Node3D)->void:
	var a:Node3D=nodes.get("noisetorus")
	check(report,"pair loaded",a!=null)
	if a==null:return
	check(report,"retained basin and independent orb",nodes.has("noiselayers") and nodes.has("dark_sphere"))
	var pointer:=Node3D.new();root.add_child(pointer)
	await press_button(a,"Btn_0",pointer)
	a._pair_time=2.0;a._apply_pair_params();a._place_markers();a._update_pair_readout()
	check(report,"FREEZE holds shared time",a._pair_frozen)
	await create_timer(.3).timeout
	check(report,"held time remains two seconds",a._pair_time==2.0)
	for r in a._rings:
		check(report,"upright holder: "+str(r.kind),is_equal_approx(r.holder.rotation.x,PI*.5) and is_equal_approx(r.holder.position.y,1.4))
		check(report,"shader clock held: "+str(r.kind),is_equal_approx(float(r.mat.get_shader_parameter("local_time")),2.0))
	var camera:=Camera3D.new();root.add_child(camera);camera.current=true
	camera.global_position=a.to_global(Vector3(0,1.7,1.95));camera.look_at(a.to_global(Vector3(0,1.25,0)));camera.fov=74
	await shot(camera,folder,"room",report)
	# Sight rays expose architectural obstructions, independently of the visual inspection.
	var walker:CollisionObject3D=museum.get("_player")
	for r in a._rings:
		var ray:=PhysicsRayQueryParameters3D.create(camera.global_position,r.holder.global_position,1)
		if walker!=null:ray.exclude=[walker.get_rid()]
		var hit:Dictionary=a.get_world_3d().direct_space_state.intersect_ray(ray)
		check(report,"approach sees ring centre: "+str(r.kind),hit.is_empty(),str(hit.get("position","clear")))
	# Every existing sample marker moves with its holder and retains its analytic offset.
	for i in range(6):
		var point:Vector3=a._sample_point()
		var value:float=a.field_value(point.x,point.z,2.0)
		for r in a._rings:
			var offset:float=a.relief_of(value) if r.kind=="relief" else 0.0
			var expected:Vector3=r.holder.to_global(point+point.normalized()*(offset+.04))
			check(report,"marker follows upright sample %d %s"%[i,r.kind],r.marker.global_position.distance_to(expected)<.00001)
		await press_button(a,"Btn_1",pointer)
	check(report,"six SAMPLE presses return to first address",a._sample_i==0)
	# Choose the first negative of the six existing addresses, at the declared held time.
	for i in range(6):
		if float(a.pair_state().value)<-.02:break
		await press_button(a,"Btn_1",pointer)
	var before:Dictionary=a.pair_state();report["held_example"]=before
	check(report,"example contains a negative sample",float(before.value)<0,before)
	check(report,"initial encoding clips that sample to black",before.colour==0.0)
	await shot(camera,folder,"clipped",report)
	await press_button(a,"Btn_4",pointer)
	var after:Dictionary=a.pair_state()
	check(report,"REMAP retains value and relief",before.value==after.value and before.relief==after.relief)
	check(report,"REMAP gives negative sample visible brightness",after.colour>0 and after.colour<.5,after.colour)
	await shot(camera,folder,"remapped",report)
	var sample_before:Vector3=a._sample_point();var old_value:float=a.field_value(sample_before.x,sample_before.z,2.0)
	for i in range(4):
		await press_button(a,"Btn_2",pointer)
		check(report,"AMPLITUDE keeps field %d"%i,a.field_value(sample_before.x,sample_before.z,2.0)==old_value)
	check(report,"amplitude completes its cycle",a._amp_i==2)
	await press_button(a,"Btn_3",pointer)
	check(report,"FREQUENCY changes the sampled coordinate",not is_equal_approx(a.field_value(sample_before.x,sample_before.z,2.0),old_value))
	await press_button(a,"Btn_3",pointer);await press_button(a,"Btn_3",pointer)
	check(report,"frequency cycle restores value",a.field_value(sample_before.x,sample_before.z,2.0)==old_value)
	var basin:Node3D=nodes.get("noiselayers")
	var original_vertices:PackedVector3Array=basin.terrain.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].duplicate()
	for index in [1,2,3,0]:
		await press_button(basin,"Btn_%d"%index,pointer)
		check(report,"basin mode selected %d"%index,basin.layer_index==index)
		var bodies:Array=basin.terrain.find_children("*","StaticBody3D",true,false)
		check(report,"one terrain body in mode %d"%index,bodies.size()==1)
		if bodies.size()==1:
			var shapes:Array=bodies[0].find_children("*","CollisionShape3D",true,false)
			check(report,"terrain collision matches visible triangles %d"%index,shapes.size()==1 and shapes[0].shape is ConcavePolygonShape3D and shapes[0].shape.get_faces()==basin.terrain.mesh.get_faces())
	check(report,"SUM restores complete terrain vertices",original_vertices==basin.terrain.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	camera.global_position=origin+Vector3(8.8,1.7,10.8);camera.look_at(basin.global_position);camera.fov=74
	await shot(camera,folder,"basin",report)
	camera.global_position=origin+Vector3(9.1,1.7,2.5);camera.look_at(origin+Vector3(5.5,1.1,5.5));camera.fov=78
	await shot(camera,folder,"hall",report)
	# Local pause leaves the existing dark orb's clock running.
	var orb:Node3D=nodes.get("dark_sphere");var orb_t:float=orb.get("_time_elapsed")
	await create_timer(.2).timeout
	check(report,"independent orb continues while pair held",float(orb.get("_time_elapsed"))>orb_t and a._pair_time==2.0)
	pointer.queue_free();camera.queue_free()

func press_button(a:Node3D,key:String,pointer:Node3D)->void:
	var event_script=load("res://addons/godot-xr-tools/events/pointer_event.gd")
	var target:Node3D=a.find_child(key,true,false).get_node("InteractableAreaButton")
	for kind in [2,3]:target.pointer_event(event_script.new(kind,pointer,target,target.global_position,target.global_position))
	await process_frame

func shot(camera:Camera3D,folder:String,tag:String,report:Dictionary)->void:
	camera.current=true;await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	var path:=folder+tag+".png";root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path));report["shots"].append(path)
