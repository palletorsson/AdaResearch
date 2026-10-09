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


class SelectionSentinel extends Node3D:
	var received: int = 0
	func apply_perlin_cell_selection(_cell: Vector3i) -> void: received += 1
	func apply_perlin_terrain_controls(_payload: Dictionary) -> void: received += 1

func investigate_pair(nodes:Dictionary,origin:Vector3,report:Dictionary,folder:String,museum:Node3D)->void:
	var a:Node3D=nodes.get("perlin_terrain_sculptor")
	var b:Node3D=nodes.get("voxelnoise")
	var screen:Node3D=nodes.get("science_screen")
	check(report,"retained model, volume, section screen and orb",a!=null and b!=null and screen!=null and nodes.has("dark_sphere"))
	if a==null or b==null or screen==null:return
	check(report,"pair shares world orientation",a.global_basis.is_equal_approx(b.global_basis))
	check(report,"same dimensions and fivefold spacing",a.grid_size==24 and b.chunk_size==24 and b.world_height==24 and is_equal_approx(b.voxel_scale/a.voxel_size,5.0))
	check(report,"same named seed",a._named_seed==31415 and b.noise_seed==31415)
	check(report,"frames do not collide",b._slice_frame.find_children("*","CollisionObject3D",true,false).is_empty() and b._cell_frame.find_children("*","CollisionObject3D",true,false).is_empty())
	var pointer:=Node3D.new();root.add_child(pointer)
	var camera:=Camera3D.new();root.add_child(camera);camera.current=true
	for view in [{"name":"bench","from":[4.5,1.7,5.35],"at":[4.5,1.4,7.5],"fov":70},{"name":"comparison","from":[5.5,1.7,4.2],"at":[7.1,1.6,8.4],"fov":82},{"name":"volume","from":[7.0,1.7,5.9],"at":[9.5,1.7,9.5],"fov":75}]:
		camera.global_position=origin+vec(view["from"]);camera.look_at(origin+vec(view["at"]));camera.fov=view["fov"]
		await shot(camera,folder,view["name"],report)
	var other_hall:=Node3D.new();other_hall.set_meta("em_map","Unrelated probe hall");root.add_child(other_hall)
	var sentinel:=SelectionSentinel.new();other_hall.add_child(sentinel);sentinel.add_to_group("voxelnoise_receivers")
	var mesh_id:int=b._generated_root.get_child(0).get_instance_id()
	var old_rebuilds:int=a._rebuilds
	var original_set:Dictionary=b._occupied_cells.duplicate()
	report["selections"]=[]
	for k in range(5):
		var c:Vector3i=a._cell
		var section:Dictionary=screen.voxel_slice_data()
		var expected:Vector3=Vector3(c.x-11.5,c.y+0.5,c.z-11.5)*.2
		check(report,"CELL selects same address in all views %d"%k,b._selected_cell==c and int(section.y)==c.y and section.selected==[c.x,c.z])
		check(report,"section height and address centre %d"%k,is_equal_approx(b._slice_frame.position.y,expected.y) and b._cell_frame.position.is_equal_approx(expected))
		check(report,"section perimeter clears volume %d"%k,is_equal_approx(b._slice_frame.get_child(0).position.x,-2.45))
		report.selections.append({"cell":arr(Vector3(c)),"height":expected.y,"decision":a.cell_report().decision})
		if k==2:
			await shot(camera,folder,"slice-low",report)
		await press_button(a,"Btn_1",pointer)
	check(report,"CELL returns to initial address",a._cell==Vector3i(12,12,12) and b._selected_cell==a._cell)
	check(report,"CELL never rebuilds the bodies",a._rebuilds==old_rebuilds and b._generated_root.get_child(0).get_instance_id()==mesh_id and b._occupied_cells==original_set)
	await shot(camera,folder,"slice-high",report)
	# Explicit link opt-out and a separate hall must stay isolated.
	b.link_to_perlin_sculptor=false
	await press_button(a,"Btn_1",pointer)
	check(report,"disabled receiver ignores CELL",b._selected_cell==Vector3i(12,12,12))
	b.link_to_perlin_sculptor=true;a._cell=Vector3i(12,12,12);a._place_cell_marker();a._update_lattice_readout();a._broadcast_cell_selection()
	report["thresholds"]=[]
	for k in range(5):
		await press_button(a,"Btn_0",pointer)
		await create_timer(.15).timeout
		var mismatches:int=0;var samples_differ:int=0
		for x in range(24):
			for y in range(24):
				for z in range(24):
					var c:=Vector3i(x,y,z)
					if bool(a._voxels[x][y][z])!=b._occupied_cells.has(c):mismatches+=1
					var v:Vector3=Vector3(c)/23.0
					if PerlinTerrainSculptor.contract_value(a._noise,v.x,v.y,v.z)!=PerlinTerrainSculptor.contract_value(b.noise,v.x,v.y,v.z):samples_differ+=1
		var occupied:Dictionary=a.occupancy_report()
		check(report,"full field and occupancy match at %+.2f"%a.threshold,mismatches==0 and samples_differ==0 and occupied.occupied==b._occupied_cells.size())
		var mesh:MeshInstance3D=b._generated_root.get_child(0)
		var colliders:Array=b._generated_root.find_children("*","CollisionShape3D",true,false)
		check(report,"surface and collision agree at %+.2f"%a.threshold,colliders.size()==1 and colliders[0].shape.get_faces()==mesh.mesh.get_faces())
		check(report,"selection survives threshold at %+.2f"%a.threshold,b._selected_cell==a._cell and b._slice_frame.visible)
		report.thresholds.append({"threshold":a.threshold,"occupied":occupied.occupied,"pieces":occupied.pieces})
		if is_equal_approx(a.threshold,.2):await shot(camera,folder,"threshold-sparse",report)
	check(report,"five button presses restore initial field and set",is_equal_approx(a.threshold,0.0) and b._occupied_cells==original_set)
	var prior_count:int=a._active_voxel_count
	mesh_id=b._generated_root.get_child(0).get_instance_id()
	await press_button(a,"Btn_3",pointer)
	check(report,"CUT removes only model drawing",a._cut and a._active_voxel_count<prior_count and a.occupancy_report().occupied==6767 and b._occupied_cells==original_set and b._generated_root.get_child(0).get_instance_id()==mesh_id)
	camera.global_position=origin+Vector3(4.5,1.7,5.9);camera.look_at(a.global_position);camera.fov=64
	await shot(camera,folder,"model-cut",report)
	await press_button(a,"Btn_3",pointer)
	check(report,"CUT restores visible model",not a._cut and a._active_voxel_count==prior_count)
	check(report,"other hall never receives control or selection",sentinel.received==0)
	report["bench_state"]=a.lattice_state()
	other_hall.queue_free();pointer.queue_free();camera.queue_free()

func press_button(a:Node3D,key:String,pointer:Node3D)->void:
	var event_script=load("res://addons/godot-xr-tools/events/pointer_event.gd")
	var target:Node3D=a.find_child(key,true,false).get_node("InteractableAreaButton")
	for kind in [2,3]:target.pointer_event(event_script.new(kind,pointer,target,target.global_position,target.global_position))
	await process_frame

func shot(camera:Camera3D,folder:String,tag:String,report:Dictionary)->void:
	camera.current=true;await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	var path:=folder+tag+".png";root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path));report["shots"].append(path)
