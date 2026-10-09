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
	check(report,"all six authored works retained",["rd_artifact","the_clockmaker_of_rules","lattice_gas_pump","ca_sphere","crack_propagation_ca","rule_30_110_gravity"].all(func(k):return nodes.has(k)))
	var work:Node3D=nodes.get("rd_artifact")
	if work==null:return
	var study:Node3D=work.get_node("ExchangeStudy");study.set_process(false)
	var crossing:Node3D=study.get_node_or_null("WalkSeed")
	check(report,"map-only body crossing mounted",crossing!=null and study.walk_seed)
	if crossing==null:return
	var feel:Node=museum.get("_feel")
	if feel!=null:feel.set_process(false)
	museum.set_process_input(false);museum.set_process_unhandled_input(false)
	var walker:CharacterBody3D=museum.get("_player");var cam:Camera3D=museum.get("_cam");cam.position=Vector3(0,1.65,0)
	var hand:Node3D=walker.get_node("DesktopHand")
	var camera:=Camera3D.new();root.add_child(camera)
	check(report,"same held 32 by 32 beginning",study.left.ticks==0 and not study.running and study.left.u==study.right.u and study.left.v==study.right.v and study.left.u.size()==1024)
	check(report,"A and B stay unnamed until intervention",study.left_title.text=="A" and study.right_title.text=="B" and not study.exchange_revealed)
	camera.global_position=work.to_global(Vector3(0,3,-4));camera.look_at(work.to_global(Vector3(0,1.3,3)));camera.fov=80
	await shot(camera,folder,"arrival",report)
	study.step_once()
	check(report,"first exchange reaches W with U .92 V .02",absf(study.left.u[study.WITNESS]-.92)<.000001 and absf(study.left.v[study.WITNESS]-.02)<.000001)
	check(report,"reaction alone leaves W at U 1 V 0",study.right.u[study.WITNESS]==1.0 and study.right.v[study.WITNESS]==0.0)
	var periodic=study.Field.new();periodic.u.fill(1);periodic.v.fill(0);periodic.v[15*32]=.25;periodic.step()
	check(report,"calculation still wraps beyond visible edge",absf(periodic.v[15*32+31]-.02)<.000001)
	study.reset();study.hundred()
	for i in range(25):study._process(.1)
	check(report,"scheduled hundred stops exactly",study.left.ticks==100 and study.right.ticks==100 and not study.running)
	camera.global_position=work.to_global(Vector3(0,1.65,1.0));camera.look_at(work.to_global(Vector3(0,1.5,4.3)));camera.fov=85
	await shot(camera,folder,"walls-100",report)
	check(report,"A alone can receive at unseeded W",study.left.v[study.WITNESS]>0 and study.right.v[study.WITNESS]==0)
	for side in range(2):
		check(report,"table and wall share material %d"%side,study.get_node("TableField_%d"%side).material_override==study.walls[side].material_override)
		check(report,"all texture pixels match field %d"%side,pixels_match(study,side))
	# All original eight controls work via the actual museum mouse ray.
	walker.global_position=work.to_global(Vector3(-4.5,.025,-3.15));await settle(walker)
	for i in range(8):
		study.running=false;study.target=0
		var before:Dictionary=study.readback()
		await click_room_control(study.console,"Btn_%d"%i,walker,cam,hand,origin,report)
		var after:Dictionary=study.readback()
		var changed:bool=after.ticks==before.ticks+1 if i==0 else after.running if i==1 else after.ticks==0 if i==2 else after.target==before.ticks+100 if i==3 else after.exchange!=before.exchange and after.exchange_revealed if i==4 else after.injections==before.injections+1 if i==5 else after.view_u!=before.view_u if i==6 else after.coating!=before.coating
		check(report,"control %d intended change"%i,changed)
	study.right.exchange=false;study.show_u=false;study.coating=true;study.reset();study.advance(100)
	# Each walk enters physics Area3D. The floor is still the ordinary museum floor.
	walker.global_position=work.to_global(Vector3(0,.025,.7));await settle(walker)
	var saved:Array=[study.left.u.duplicate(),study.left.v.duplicate(),study.right.u.duplicate(),study.right.v.duplicate()]
	var approach:Dictionary=await walk_to(walker,work.to_global(Vector3(0,0,2.15)))
	report.visits.append({"tag":"enter seed square","result":approach})
	check(report,"body walks into mark on museum floor",approach.passed)
	check(report,"entry injects once without advancing time",study.injections==1 and study.left.ticks==100 and study.right.ticks==100 and crossing.visitors.size()==1)
	var exact:=true
	var actual:Array=[study.left.u,study.left.v,study.right.u,study.right.v]
	for index in range(1024):
		var x:int=index%32;var y:int=index/32;var seeded:bool=x>=3 and x<=5 and y>=14 and y<=16
		for channel in range(4):exact=exact and is_equal_approx(actual[channel][index],(.5 if channel%2==0 else .25) if seeded else saved[channel][index])
	check(report,"entry changes only the same nine cells in both fields",exact)
	check(report,"presence colours the floor mark",crossing.pad_material.albedo_color.is_equal_approx(Color("735269")))
	cam.look_at(work.to_global(Vector3(1.0,1.3,4.3)));cam.fov=92
	await shot(cam,folder,"body-seeded",report)
	camera.global_position=work.to_global(Vector3(0,2.4,-.6));camera.look_at(work.to_global(Vector3(0,1.2,3.9)));camera.fov=85
	await shot(camera,folder,"seeded",report)
	study.hundred()
	for i in range(25):study._process(.1);await physics_frame
	check(report,"waiting runs hundred steps without reseeding",study.injections==1 and study.left.ticks==200 and not study.running)
	check(report,"new seed develops with exchange and fades without",study.left.v[15*32+4]>.01 and study.right.v[15*32+4]<.0001,{"a":study.left.v[15*32+4],"b":study.right.v[15*32+4]})
	await shot(camera,folder,"after-seed-100",report)
	study.reset();await physics_frame;await physics_frame
	check(report,"replay while occupied stays a clean held beginning",study.injections==0 and study.left.ticks==0 and study.left.v[15*32+4]==0)
	var leave:Dictionary=await walk_to(walker,work.to_global(Vector3(0,0,3.2)));report.visits.append({"tag":"leave square","result":leave})
	check(report,"exit releases the seed mark",leave.passed and crossing.visitors.is_empty() and crossing.pad_material.albedo_color.is_equal_approx(Color("263744")))
	var back:Dictionary=await walk_to(walker,work.to_global(Vector3(0,0,2.15)));report.visits.append({"tag":"return to square","result":back})
	check(report,"return creates one new intervention",back.passed and study.injections==1 and study.left.ticks==0)
	await walk_to(walker,work.to_global(Vector3(0,0,.7)))
	study.reset()
	# An ordinary physics object, a hand and an unrelated character are not visitors.
	var ball:=RigidBody3D.new();root.add_child(ball)
	var hand_dummy:=Node3D.new();root.add_child(hand_dummy)
	var character:=CharacterBody3D.new();root.add_child(character)
	var n:int=study.injections
	crossing._entered(ball);crossing._entered(hand_dummy);crossing._entered(character)
	check(report,"props hands and unrelated characters do not inject",study.injections==n and crossing.visitors.is_empty());ball.queue_free();hand_dummy.queue_free();character.queue_free()
	var xr=load("res://addons/godot-xr-tools/player/player_body.gd").new()
	check(report,"real XRTools body class is accepted",crossing.accepts(xr));xr.free()
	var bypass:Dictionary=await walk_to(walker,work.to_global(Vector3(1.2,0,.7)))
	bypass=await walk_to(walker,work.to_global(Vector3(1.2,0,3.2)));report.visits.append({"tag":"pass beside mark","result":bypass})
	check(report,"visitor can pass beside mark without changing fields",bypass.passed and study.injections==0)
	# VIEW and COAT change the display only, including after a body injection.
	saved=[study.left.u.duplicate(),study.left.v.duplicate(),study.right.u.duplicate(),study.right.v.duplicate()]
	study.change_view();study.toggle_coating()
	check(report,"view and coating preserve field and time",study.left.u==saved[0] and study.left.v==saved[1] and study.right.u==saved[2] and study.right.v==saved[3] and study.left.ticks==0)
	check(report,"coat removes walls but retains seed mark",not study.walls[0].visible and not study.walls[1].visible and crossing.is_visible_in_tree())
	check(report,"U texture mapping remains exact",pixels_match(study,0) and pixels_match(study,1))
	study.change_view();study.toggle_coating();study.toggle_exchange();study.advance(80)
	check(report,"equal exchange restores full-field agreement",study.left.u==study.right.u and study.left.v==study.right.v)
	study.left.ticks=2399;study.right.ticks=2399;study.running=true;study.advance(8)
	check(report,"observation limit holds both at 2400",study.left.ticks==2400 and study.right.ticks==2400 and not study.running)
	# Reapplying map config never duplicates the crossing. Standalone study is unchanged.
	work.apply_grid_config({"study":"exchange","seed":"walk"});work.apply_grid_config({"study":"exchange","seed":"walk"})
	check(report,"repeated configuration keeps one receiver",study.find_children("WalkSeed","Node3D",false,false).size()==1)
	var plain:Node3D=load("res://commons/artifacts/rd_artifact/rd_artifact.tscn").instantiate();plain.position=Vector3(1000,0,1000);plain.apply_grid_config({"study":"exchange"});root.add_child(plain)
	check(report,"legacy exchange study has no crossing",not plain.get_node("ExchangeStudy").has_node("WalkSeed"));plain.queue_free()
	study.right.exchange=false;study.show_u=false;study.coating=true;study.reset()

func pixels_match(study:Node3D,side:int)->bool:
	var f=study.left if side==0 else study.right;var data:PackedFloat32Array=f.u if study.show_u else f.v
	var img:Image=study.textures[side].get_image()
	for y in range(32):
		for x in range(32):
			var actual:Color=img.get_pixel(x,y);var expected:Color=study.tint(data[y*32+x])
			if maxf(absf(actual.r-expected.r),maxf(absf(actual.g-expected.g),absf(actual.b-expected.b)))>.005:return false
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

