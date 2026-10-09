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
	report["desktop_input"]=[];report["visits"]=[]
	var work:Node3D=nodes.get("game_of_life_petri")
	check(report,"all six authored works retained",["game_of_life_petri","mold_network","science_screen","hexagon_ca_vr","ca_growth_network","dark_sphere"].all(func(k):return nodes.has(k)))
	if work==null:return
	var study:Node3D=work.get_node("AddressStudy")
	var walker:CharacterBody3D=museum.get("_player")
	var cam:Camera3D=museum.get("_cam")
	var hand:Node3D=walker.get_node("DesktopHand")
	var feel:Node=museum.get("_feel")
	if feel!=null:feel.set_process(false)
	museum.set_process_input(false);museum.set_process_unhandled_input(false);cam.position=Vector3(0,1.65,0)
	var camera:=Camera3D.new();root.add_child(camera)
	check(report,"9.6 metre map-only floor",study.walk_floor and is_equal_approx(study.floor_cell*24,9.6))
	check(report,"same held five-cell binary beginning",work._generation==0 and work._population==5 and not study.running and work.grid_size==24)
	var initial:Array=work._grid.duplicate(true)
	var fixed:Array=floor_transforms(study)
	var mapping_ok:=true
	for y in range(24):
		for x in range(24):
			mapping_ok=mapping_ok and study.floor_view.multimesh.get_instance_transform(y*24+x).origin.is_equal_approx(study.floor_position(Vector2i(x,y)))
	check(report,"all 576 floor positions follow original addresses",mapping_ok)
	var witness_ok:=true
	for i in range(3):
		var site:Vector2i=study.SITES[i];var pos:Vector3=study.floor_position(site)
		var marker:Node3D=study.get_node("FloorAddress"+study.receivers[i].letter)
		witness_ok=witness_ok and is_equal_approx(marker.position.x,pos.x) and absf(marker.position.z-pos.z)<.21 and is_equal_approx(study.receivers[i].position.z,pos.z) and study.receivers[i].site==site
	check(report,"gold addresses and lamps remain aligned",witness_ok)
	await view(camera,origin,folder,"arrival",Vector3(5.1,1.65,1.2),Vector3(7.0,.3,9.5),80,report)
	await view(camera,origin,folder,"floor",Vector3(2.0,1.65,5.5),Vector3(7.0,.25,10.5),82,report)
	walker.global_position=work.to_global(Vector3(0,.02,-3.5));await settle(walker)
	var controls:Node3D=study.console.get_node("AddressControls")
	for i in range(4):await click_room_control(controls,"Btn_0",walker,cam,hand,origin,report)
	var translated:=true
	for y in range(24):
		for x in range(24):translated=translated and work._grid[y][x]==initial[posmod(y-1,24)][posmod(x-1,24)]
	check(report,"four updates translate pattern one address each way",translated and work._generation==4)
	check(report,"travel does not move any floor geometry",floor_transforms(study)==fixed)
	await click_room_control(controls,"Btn_7",walker,cam,hand,origin,report)
	check(report,"TRACE shows the actual old/new wake",study.trace and trace_colours_match(work,study,true),{"born":study.born,"died":study.died})
	await view(camera,origin,folder,"trace",Vector3(4.1,1.65,8.0),Vector3(5.5,.02,10.0),82,report)
	var traced:Array=work._grid.duplicate(true);var gen:int=work._generation
	await click_room_control(controls,"Btn_7",walker,cam,hand,origin,report)
	check(report,"TRACE off restores both dish and floor without stepping",not study.trace and work._grid==traced and work._generation==gen and trace_colours_match(work,study,false))
	await click_room_control(controls,"Btn_4",walker,cam,hand,origin,report)
	var a:Node3D=study.receivers[0]
	check(report,"BLINKER keeps A occupied and lit",a.occupied and a.light.light_energy>0 and a.rises==0)
	var blink:Array=work._grid.duplicate(true)
	study.step_once();study.step_once()
	check(report,"BLINKER returns in two updates with no new onset at A",work._grid==blink and a.occupied and a.rises==0)
	await view(camera,origin,folder,"blinker",Vector3(2.0,1.65,5.5),Vector3(7.0,.25,10.5),82,report)
	await click_room_control(controls,"Btn_6",walker,cam,hand,origin,report)
	check(report,"LINK removes only receiver output",not study.linked and a.occupied and a.light.light_energy==0 and work._grid==blink)
	await click_room_control(controls,"Btn_6",walker,cam,hand,origin,report)
	check(report,"relinking counts no birth",study.linked and a.light.light_energy>0 and a.rises==0)
	await click_room_control(controls,"Btn_5",walker,cam,hand,origin,report)
	for i in range(6):study.step_once()
	check(report,"prepared meeting is empty at generation six",work._generation==6 and work._population==0)
	await click_room_control(controls,"Btn_3",walker,cam,hand,origin,report)
	await click_room_control(controls,"Btn_1",walker,cam,hand,origin,report)
	await create_timer(.65).timeout
	await click_room_control(controls,"Btn_1",walker,cam,hand,origin,report)
	check(report,"RUN and hold still operate",work._generation>0 and not study.running)
	await click_room_control(controls,"Btn_2",walker,cam,hand,origin,report)
	check(report,"REPLAY returns exact seeded beginning",work._grid==initial and work._generation==0 and study.receivers.all(func(r):return r.rises==0))
	# Stand on A while the state visits it. Movement itself supplies no Life input.
	walker.global_position=work.to_global(Vector3(-3,.02,-.3));await settle(walker)
	var at:Vector3=study.floor_position(Vector2i(10,10));at.y=0
	var walked:Dictionary=await walk_to(walker,work.to_global(at))
	check(report,"body walks to empty address A on continuous floor",walked.passed and not a.occupied and work._grid==initial,walked)
	await view(camera,origin,folder,"lamp-off",Vector3(8.3,1.65,8.6),Vector3(12.25,1.15,10.7),82,report)
	for i in range(8):study.step_once()
	await settle(walker)
	check(report,"A becomes occupied beneath a stationary supported body",a.occupied and a.light.light_energy>0 and a.rises==1 and walker.is_on_floor() and absf(walker.global_position.y-work.global_position.y)<.03)
	report.visits.append(study.readback())
	cam.fov=84;cam.look_at(study.receivers[0].global_position+Vector3(0,1,0));await shot(cam,folder,"standing-address",report)
	await view(camera,origin,folder,"lamp-on",Vector3(8.3,1.65,8.6),Vector3(12.25,1.15,10.7),82,report)
	study.toggle_link();await view(camera,origin,folder,"lamp-unlinked",Vector3(8.3,1.65,8.6),Vector3(12.25,1.15,10.7),82,report);study.toggle_link()
	for i in range(4):study.step_once()
	await settle(walker)
	check(report,"A empties without removing support or relocating the body",not a.occupied and a.light.light_energy==0 and a.rises==1 and walker.is_on_floor() and walker.global_position.distance_to(work.to_global(at))<.08 and floor_transforms(study)==fixed)
	report.visits.append(study.readback())
	var support_ok:=true
	for site in [Vector2i(0,0),Vector2i(23,0),Vector2i(0,23),Vector2i(23,23),Vector2i(10,10)]:
		var p:Vector3=work.to_global(study.floor_position(site));var q:=PhysicsRayQueryParameters3D.create(p+Vector3(0,1,0),p-Vector3(0,1,0),1);q.exclude=[walker.get_rid()]
		var hit:Dictionary=work.get_world_3d().direct_space_state.intersect_ray(q)
		support_ok=support_ok and not hit.is_empty() and absf((hit.position as Vector3).y-work.global_position.y)<.03
	check(report,"all four corners and A retain museum floor support",support_ok)
	check(report,"enlarged visual array adds no collision objects",study.floor_view.find_children("*","CollisionObject3D",true,false).is_empty())
	for i in range(50):study.step_once()
	check(report,"original 48 generation limit remains",work._generation==48 and not study.running)
	var legacy:Node3D=(load("res://commons/artifacts/game_of_life_petri/game_of_life_petri.tscn") as PackedScene).instantiate();legacy.set_meta("config_study","addresses");legacy.position=Vector3(0,-200,0);root.add_child(legacy)
	var old:Node3D=legacy.get_node("AddressStudy")
	check(report,"other address studies retain 4.8 metre floor",not old.walk_floor and is_equal_approx(old.floor_cell*24,4.8) and is_equal_approx(old.floor_z,3.6) and is_equal_approx(old.receivers[0].position.x,3.35))
	legacy.queue_free();await process_frame
	var hex:Node3D=nodes.get("hexagon_ca_vr")
	check(report,"hex table preserves full simulation dimensions",hex.radius==20 and hex.max_generations==10 and hex._coords.size()==1261 and hex._multi_mesh.multimesh.instance_count==13871)
	check(report,"hex specimen stays inside rear tabletop",hex._sim_root.scale.is_equal_approx(Vector3.ONE*.12) and hex.has_node("MuseumTable") and hex.global_position.distance_to(origin+Vector3(9.5,0,23.5))<.001)
	check(report,"hex control and status retain human scale",is_equal_approx(hex._controller_root.position.y,1.4) and hex._controller_root.scale==Vector3.ONE and is_equal_approx(hex._status_label.global_basis.get_scale().x,1))
	await view(camera,origin,folder,"hex-table",Vector3(11.0,1.65,20.5),Vector3(9.5,1.35,23.5),82,report)
	study.choose_glider();check(report,"held arrival restored",work._grid==initial and not study.running)
	report["scope"]="Native authored museum, supplied CharacterBody and actual mouse input. Fixed addresses, lamps, TRACE and support tested; no tracked-headset, comfort, Quest, full-gallery or learner acceptance."

func floor_transforms(study:Node3D)->Array:
	var out:Array=[]
	for i in range(24*24):out.append(study.floor_view.multimesh.get_instance_transform(i))
	return out

func trace_colours_match(work:Node3D,study:Node3D,traced:bool)->bool:
	for y in range(24):
		for x in range(24):
			var now:bool=work._grid[y][x];var was:bool=work._next_grid[y][x]
			var floor_c:Color=Color("90ebca") if now else Color("273e49")
			var dish_c:Color=work.alive_color if now else work.dead_color
			if traced and now!=was:
				floor_c=study.BIRTH_COLOUR if now else study.DEATH_COLOUR;dish_c=floor_c
			var actuals:Array=[study.floor_view.multimesh.get_instance_color(y*24+x),work._multimesh.get_instance_color(y*24+x)]
			for i in range(2):
				var expected:Color=floor_c if i==0 else dish_c
				for k in range(4):
					if absf(actuals[i][k]-expected[k])>.002:return false
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

