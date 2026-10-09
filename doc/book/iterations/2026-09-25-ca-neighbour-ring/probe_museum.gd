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


func investigate_pair(nodes:Dictionary,origin:Vector3,report:Dictionary,folder:String,museum:Node3D)->void:
	report["desktop_input"] = []
	var expected := ["synthesis_stand", "dark_sphere", "persian_rug", "ca_rule_explorer", "grid_substrate_runner", "langton_swarm", "line_network_ca", "rule110_computer", "ca_showcase"]
	check(report,"nine authored works retained",expected.all(func(key):return nodes.has(key)))
	var work:Node3D=nodes.ca_rule_explorer
	var study:Node3D=work.get_node("NeighbourStudy")
	var ring:Node3D=study.get("room_ring")
	check(report,"map opts into a ring",ring!=null)
	if ring==null:return
	var walker:CharacterBody3D=museum.get("_player")
	var cam:Camera3D=museum.get("_cam")
	var hand:Node3D=walker.get_node("DesktopHand")
	var feel:Node=museum.get("_feel")
	if feel!=null:feel.set_process(false)
	museum.set_process_input(false);museum.set_process_unhandled_input(false)
	walker.global_position=origin+Vector3(8.55,.02,5.5);await settle(walker)
	cam.position=Vector3(0,1.65,0)
	var camera:=Camera3D.new();root.add_child(camera)
	var controls:Node3D=study.get_node("StudyControls")
	check(report,"arrival is held at generation zero",work.generation==0 and not work.auto_run)
	check_ring(work,ring,report,"arrival")
	await view(camera,origin,folder,"arrival",Vector3(8.7,1.65,6.4),Vector3(10.3,1.2,5.5),85,report)
	await view(camera,origin,folder,"corridor",Vector3(8.7,1.65,6.6),Vector3(10,2.5,7.8),95,report)
	var old_row:Array=work._current_row.duplicate()
	await click_room_control(controls,"Btn_0",walker,cam,hand,origin,report)
	var correct:bool=true
	for col in range(32):correct=correct and work._current_row[col]==(bool(old_row[posmod(col-1,32)])!=bool(old_row[(col+1)%32]))
	check(report,"actual STEP follows independent Rule 90 XOR",correct and work.generation==1 and not work.auto_run)
	check_ring(work,ring,report,"one STEP")
	var gen:int=work.generation;await create_timer(.4).timeout
	check(report,"held row does not advance while waiting",work.generation==gen)
	for i in range(14):work.step()
	study.refresh();check_ring(work,ring,report,"fifteen steps")
	await view(camera,origin,folder,"history",Vector3(8.7,1.65,6.6),Vector3(10,2.5,7.8),95,report)
	camera.global_position=ring.to_global(Vector3(0,1.65,0));camera.look_at(ring.to_global(Vector3(0,2.8,1.5)));camera.fov=85
	await shot(camera,folder,"inside",report)
	# Boundary neighbourhood is directly adjacent in the drawn ring.
	work.sample_cell=31;study.refresh()
	await click_room_control(controls,"Btn_3",walker,cam,hand,origin,report)
	check(report,"CELL wraps from 31 to zero",work.sample_cell==0)
	for j in range(3):
		var col:int=posmod(work.sample_cell+j-1,32)
		check(report,"witness locates wrapped neighbour "+str(j),ring.witness[j].position.distance_to(ring.at(col,-.7,ring.RADIUS-.04))<.00001)
	var step:float=ring.at(0,0).distance_to(ring.at(1,0))
	check(report,"31 to 0 spacing equals all other neighbours",absf(ring.at(31,0).distance_to(ring.at(0,0))-step)<.00001)
	camera.global_position=ring.to_global(Vector3(0,1.65,0));camera.look_at(ring.to_global(Vector3(0,2.05,1.5)))
	await shot(camera,folder,"seam",report)
	await click_room_control(controls,"Btn_2",walker,cam,hand,origin,report)
	check(report,"SEED restarts pair without changing rule",work.seed_pair and work.generation==0 and work.rule==90)
	check_ring(work,ring,report,"pair seed")
	await click_room_control(work._control_panel,"Btn_0",walker,cam,hand,origin,report)
	check(report,"existing rule preset reaches ring",work.rule==30 and work.generation==0)
	await click_room_control(controls,"Btn_1",walker,cam,hand,origin,report)
	await create_timer(.8).timeout
	await click_room_control(controls,"Btn_1",walker,cam,hand,origin,report)
	check(report,"RUN starts and holds same automaton",work.generation>0 and not work.auto_run)
	for i in range(30):work.step()
	study.refresh();check_ring(work,ring,report,"bounded history")
	check(report,"history stays bounded at twenty-four rows",ring.rendered.size()==24 and ring.cells.instance_count==32*24)
	camera.global_position=ring.to_global(Vector3(0,1.65,0));camera.look_at(ring.to_global(Vector3(.7,3.15,1.4)))
	await shot(camera,folder,"rule30",report)
	await click_room_control(work._control_panel,"Btn_4",walker,cam,hand,origin,report)
	study.refresh();check_ring(work,ring,report,"reset")
	check(report,"RST clears hanging history",work.generation==0 and ring.rendered.size()==1)
	# Floor and passage retain their existing collision.
	var passed:=true;var poses:Array=[]
	for target in [Vector3(8.65,0,6.8),Vector3(10,0,7.1),Vector3(10,0,8.65)]:
		for frame in range(220):
			var d:Vector3=origin+target-walker.global_position;d.y=0
			if d.length()<.09:break
			var v:Vector3=d.normalized()*1.2
			walker.velocity=Vector3(v.x,0 if walker.is_on_floor() else walker.velocity.y-11.0/60,v.z)
			walker.move_and_slide();await physics_frame
		var p:Vector3=walker.global_position-origin
		poses.append(arr(p));passed=passed and Vector2(p.x-target.x,p.z-target.z).length()<.12 and absf(p.y)<.03
	check(report,"body walks from controls through the ring",passed,poses)
	check(report,"ring adds no collision or areas",ring.find_children("*","CollisionObject3D",true,false).is_empty())
	check(report,"ring below hall roof above standing eye",ring.to_global(Vector3(0,ring.CURRENT_Y,0)).y>origin.y+1.9 and ring.to_global(Vector3(0,ring.CURRENT_Y+23*ring.ROW_PITCH,0)).y<origin.y+4.5)
	# The existing study without this map opt-in must not grow a room.
	var legacy:Node3D=(load("res://commons/artifacts/ca_rule_explorer/ca_rule_explorer.tscn") as PackedScene).instantiate()
	legacy.set_meta("config_study","neighbours");legacy.position=Vector3(0,-200,0)
	root.add_child(legacy)
	check(report,"unconfigured neighbour study remains desk only",legacy.get_node("NeighbourStudy").get("room_ring")==null)
	legacy.queue_free();await process_frame
	work.rule=90;work.seed_pair=false;work._reset();study.refresh()
	check(report,"final held single seed restored",work.generation==0 and not work.auto_run and not work.seed_pair)
	report["scope"]="Actual museum body routes and pointer events; ring reads production explorer history. No tracked headset, comfort, Quest or learner acceptance."

func check_ring(work:Node3D,ring:Node3D,report:Dictionary,tag:String)->void:
	ring.refresh()
	check(report,tag+": stored history copied exactly",ring.rendered==work._grid)
	var colours:=true;var visible:=true
	for row in range(work.rows_visible):
		for col in range(work.cells_x):
			var index:int=row*work.cells_x+col
			var present:bool=row<work._grid.size()
			var state:bool=present and bool(work._grid[row][col])
			var expected:Color=work.alive_color if state else work.dead_color
			colours=colours and ring.cells.get_instance_color(index).is_equal_approx(expected)
			var t:Transform3D=ring.cells.get_instance_transform(index)
			visible=visible and (t.basis.determinant()>.99 if present else absf(t.basis.determinant())<.000001)
	check(report,tag+": all cell colours match source state",colours)
	check(report,tag+": uncomputed history is hidden",visible)

func arch_walk(arch:Node3D,walker:CharacterBody3D)->Dictionary:
	walker.global_position=arch.to_global(Vector3(0,.025,-1.4));await settle(walker)
	for frame in range(150):
		walker.velocity=Vector3(0,0 if walker.is_on_floor() else walker.velocity.y-11.0/60,1.2)
		walker.move_and_slide();await physics_frame
		if arch.to_local(walker.global_position).z>1.35:break
	var p:Vector3=arch.to_local(walker.global_position)
	return {"end":arr(p),"passed":p.z>1.30 and absf(p.y)<.03,"on_floor":walker.is_on_floor()}

func settle(walker:CharacterBody3D)->void:
	for frame in range(20):
		walker.velocity=Vector3(0,-1,0);walker.move_and_slide();await physics_frame

func walk_attempt(ground:Node3D,walker:CharacterBody3D,sidestep:bool,frames:int=330)->Dictionary:
	walker.global_position=ground.to_global(Vector3(0,1.03,-4.45));walker.velocity=Vector3.ZERO
	await settle(walker)
	var poses:Array=[]
	for frame in range(frames):
		var p:Vector3=ground.to_local(walker.global_position)
		var x:float=0.0
		if sidestep:
			var desired:float=.75 if p.z < -1 else 0.0
			x=clampf((desired-p.x)*3,-1.2,1.2)
		walker.velocity=Vector3(x,0.0 if walker.is_on_floor() else walker.velocity.y-11.0/60.0,2.0)
		walker.move_and_slide();await physics_frame
		if frame%5==0:poses.append(arr(ground.to_local(walker.global_position)))
		if ground.to_local(walker.global_position).z>4.42:break
	walker.velocity=Vector3.ZERO
	await settle(walker)
	return {"height":ground.height_scale,"sidestep":sidestep,"poses":poses,"end":arr(ground.to_local(walker.global_position)),"trace":Array(ground.walk_study.walked_trail.points).map(func(p):return arr(p)),"joins":Array(ground.walk_study.walked_trail.joins)}

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

