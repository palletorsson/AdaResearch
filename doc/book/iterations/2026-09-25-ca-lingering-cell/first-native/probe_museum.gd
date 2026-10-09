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
	report["desktop_input"]=[];report["neighbourhoods"]=[]
	var work:Node3D=nodes.get("structure_growth")
	check(report,"both authored works retained",work!=null and nodes.has("dark_sphere"))
	var study:Node3D=work.get_node("StructureStudy")
	var room:Node3D=study.get("neighbour_room")
	check(report,"map opts into enlarged neighbourhood",room!=null)
	if room==null:return
	var walker:CharacterBody3D=museum.get("_player")
	var cam:Camera3D=museum.get("_cam")
	var hand:Node3D=walker.get_node("DesktopHand")
	var feel:Node=museum.get("_feel")
	if feel!=null:feel.set_process(false)
	museum.set_process_input(false);museum.set_process_unhandled_input(false)
	walker.global_position=origin+Vector3(4.85,.02,2.7);await settle(walker);cam.position=Vector3(0,1.65,0)
	var controls:Node3D=study.get_node("Console/StudyControls")
	var camera:=Camera3D.new();root.add_child(camera)
	check(report,"original 50 cubed builder and held arrival",work.grid_size==Vector3i(50,50,50) and work.rule_string=="6-8/6-8/3/M" and work.generation==0 and not study.running)
	check_neighbourhood(work,room,report,"arrival")
	check(report,"chosen cell starts active",room.states[13]==1)
	var initial=work.current_state.duplicate()
	await view(camera,origin,folder,"arrival",Vector3(4.7,1.65,2.5),Vector3(6.2,1.15,6.3),80,report)
	await view(camera,origin,folder,"neighbours-active",Vector3(4.3,1.65,2.5),Vector3(2.65,1.5,4.7),80,report)
	var t:int=Time.get_ticks_usec()
	await click_room_control(controls,"Btn_0",walker,cam,hand,origin,report)
	report["pointer_step_wall_ms"]=(Time.get_ticks_usec()-t)/1000.0
	check_neighbourhood(work,room,report,"first STEP")
	check(report,"real fading cell has seven active neighbours",work.generation==1 and room.states[13]==2 and room.active_neighbours==7,room.readback())
	await view(camera,origin,folder,"neighbours-fading",Vector3(4.3,1.65,2.5),Vector3(2.65,1.5,4.7),80,report)
	var held=work.current_state.duplicate();var gen:int=work.generation
	await click_room_control(controls,"Btn_3",walker,cam,hand,origin,report)
	check(report,"VIEW retains every state and generation",work.current_state==held and work.generation==gen and not study.state_colours)
	check_neighbourhood(work,room,report,"height colours")
	await view(camera,origin,folder,"height-colours",Vector3(4.3,1.65,2.5),Vector3(2.65,1.5,4.7),80,report)
	await click_room_control(controls,"Btn_3",walker,cam,hand,origin,report)
	check(report,"VIEW returns state colours without updating",work.current_state==held and work.generation==gen and study.state_colours)
	await click_room_control(controls,"Btn_0",walker,cam,hand,origin,report)
	check_neighbourhood(work,room,report,"second STEP")
	check(report,"fading centre empties despite prior birth count",work.generation==2 and room.states[13]==0 and work.next_state[room.ADDRESS.x+room.ADDRESS.y*work.stride_y+room.ADDRESS.z*work.stride_z]==2)
	await view(camera,origin,folder,"neighbours-empty",Vector3(4.3,1.65,2.5),Vector3(2.65,1.5,4.7),80,report)
	await click_room_control(controls,"Btn_2",walker,cam,hand,origin,report)
	check(report,"REPLAY recovers whole source volume",work.current_state==initial and work.generation==0 and study.budget==20)
	check_neighbourhood(work,room,report,"replay")
	await click_room_control(controls,"Btn_4",walker,cam,hand,origin,report)
	check(report,"budget extends without changing state",study.budget==40 and work.current_state==initial and work.generation==0)
	await click_room_control(controls,"Btn_1",walker,cam,hand,origin,report)
	await create_timer(1.15).timeout
	await click_room_control(controls,"Btn_1",walker,cam,hand,origin,report)
	check(report,"RUN and hold use existing clock",work.generation>0 and not study.running)
	check_neighbourhood(work,room,report,"RUN then hold")
	study.replay();t=Time.get_ticks_usec();study.step_once();report["full_step_ms"]=(Time.get_ticks_usec()-t)/1000.0
	# Walk the open gaps, without crossing the retained pit.
	var passed:=true;var poses:Array=[]
	for target in [Vector3(3.215,0,2.7),Vector3(3.215,0,4.7),Vector3(3.215,0,6.4)]:
		for frame in range(220):
			var d:Vector3=origin+target-walker.global_position;d.y=0
			if d.length()<.08:break
			var v:Vector3=d.normalized()*1.2
			walker.velocity=Vector3(v.x,0 if walker.is_on_floor() else walker.velocity.y-11.0/60,v.z)
			walker.move_and_slide();await physics_frame
		var p:Vector3=walker.global_position-origin;poses.append(arr(p))
		passed=passed and Vector2(p.x-target.x,p.z-target.z).length()<.12 and absf(p.y)<.03
		if target.z==4.7:
			cam.look_at(room.global_position);await shot(cam,folder,"among-cells",report)
	check(report,"museum body walks between enlarged cells",passed,poses)
	check(report,"receiver adds no collision or sensors",room.find_children("*","CollisionObject3D",true,false).is_empty())
	check(report,"source address outlined at real coordinate",room.source_marker.position.distance_to(Vector3(room.ADDRESS)*work.cell_size)<.000001)
	check(report,"all 27 offsets are unique",room.offsets.size()==27 and room.offsets.count(Vector3i.ZERO)==1)
	# Opt-in does not affect an ordinary state study.
	var legacy:Node3D=(load("res://algorithms/cellularautomata/cellular_automata_3d/StructureGrowth.tscn") as PackedScene).instantiate()
	legacy.set_meta("config_study","states");legacy.position=Vector3(0,-200,0);root.add_child(legacy)
	check(report,"ordinary state study has no room",legacy.get_node("StructureStudy").get("neighbour_room")==null)
	legacy.queue_free();await process_frame
	study.replay();check(report,"held beginning restored",work.current_state==initial and work.generation==0 and not study.running)
	report["scope"]="Actual authored museum, source states and pointer events, supplied CharacterBody route through open gaps. No tracked headset, comfort, Quest or learner acceptance."

func check_neighbourhood(work:Node3D,room:Node3D,report:Dictionary,tag:String)->void:
	var values:=true;var colours:=true;var visible:=true;var count:int=0
	for i in range(room.offsets.size()):
		var p:Vector3i=room.ADDRESS+room.offsets[i]
		var state:int=work.current_state[p.x+p.y*work.stride_y+p.z*work.stride_z]
		values=values and room.states[i]==state
		if room.offsets[i]!=Vector3i.ZERO and state==1:count+=1
		var expected:Color=work.gradient.sample(float(p.y)/work.grid_size.y) if work.use_gradient else (work.color_alive if state<=1 else work.color_dying)
		colours=colours and room.cells.get_instance_color(i).is_equal_approx(expected)
		var t:Transform3D=room.cells.get_instance_transform(i)
		visible=visible and (t.basis.determinant()>.99 if state>0 else absf(t.basis.determinant())<.000001)
	check(report,tag+": all 27 states match source",values)
	check(report,tag+": only state 1 neighbours counted",count==room.active_neighbours)
	check(report,tag+": colours follow source mapping",colours)
	check(report,tag+": empty cubes disappear",visible)
	report.neighbourhoods.append(room.readback())

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

