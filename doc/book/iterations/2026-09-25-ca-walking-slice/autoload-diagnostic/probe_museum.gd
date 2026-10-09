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
	report["desktop_input"]=[];report["visits"]=[]
	var work:Node3D=nodes["self_organization_ca"]
	var study:Node3D=work.get_node("DifferenceStudy");study.set_process(false)
	var reader:Node3D=study.get_node("WalkingSlice")
	var m=study.model
	check(report,"all five authored works present",nodes.has("self_organization_ca") and nodes.has("ca_screen") and nodes.has("disease_spread_ca") and nodes.has("volumetric_fog_ca") and nodes.has("crackpropagation_ca"))
	check(report,"unchanged paired domain and held beginning",m.a.size()==1331 and m.tick==0 and study.target==0 and study.slice_z==5)
	check(report,"all addresses still rendered in each volume",study.volumes[0].multimesh.instance_count==1331 and study.volumes[1].multimesh.instance_count==1331)
	check(report,"difference floor and case share one material",study.floor_view.material_override==study.walls[2].material_override)
	check(report,"reader adds only an area and no solid barrier",reader.find_children("*","StaticBody3D",true,false).is_empty() and reader.find_children("*","Area3D",true,false).size()==1)
	var crate:=RigidBody3D.new();var stranger:=CharacterBody3D.new();var xr:=XRToolsPlayerBody.new()
	check(report,"accepts tracked player class and rejects loose objects",reader.accepts(xr) and not reader.accepts(crate) and not reader.accepts(stranger))
	crate.free();stranger.free();xr.free()
	var walker:CharacterBody3D=museum.get("_player");var cam:Camera3D=museum.get("_cam");var hand:Node3D=walker.get_node("DesktopHand")
	var feel:Node=museum.get("_feel");if feel:feel.set_process(false)
	museum.set_process_input(false);museum.set_process_unhandled_input(false);walker.set_physics_process(false)
	cam.position=Vector3(0,1.65,0)
	var camera:=Camera3D.new();root.add_child(camera)
	await view(camera,origin,folder,"arrival",work.global_position-origin+Vector3(0,1.65,-3.6),work.global_position-origin+Vector3(0,1.6,3),80,report)
	var a_before:PackedFloat64Array=m.a.duplicate();var b_before:PackedFloat64Array=m.b.duplicate()
	walker.global_position=work.to_global(Vector3(0,.05,-.55));await settle(walker)
	check(report,"actual museum walker recognized",reader.accepts(walker))
	for z in range(11):
		var destination:Vector3=work.to_global(Vector3(0,0,.25+.27*z))
		var route:Dictionary=await walk_to(walker,destination);report.visits.append(route)
		await physics_frame;await physics_frame
		check(report,"body selects depth %d without advancing or editing"%z,route.passed and study.slice_z==z and m.tick==0 and m.a==a_before and m.b==b_before,study.slice_z)
		check(report,"slice %d colours and volume frames agree"%z,slice_matches(study) and absf(reader.frames[0].position.z-(.25+.27*z))<.00001 and reader.frames[0].position.z==reader.frames[1].position.z)
		if z in [4,5,6]:
			var expected:float=1 if z==5 else 0
			check(report,"visible peak at Z %d matches the selected section"%z,is_equal_approx(section_peak(study),expected),section_peak(study))
			await view(camera,origin,folder,"slice-%d"%z,walker.global_position-origin+Vector3(0,1.65,0),work.global_position-origin+Vector3(-3.9,2,6.4),80,report)
			if z==5:
				await view(camera,origin,folder,"slice-middle-wide",work.global_position-origin+Vector3(-4.8,3.1,-2.8),work.global_position-origin+Vector3(0,1.7,3),85,report)
	check(report,"looking does not operate the console or stop a clock",study.actions==0 and study.target==0)
	# Leave the back of the reader; manual view selection must remain available.
	var out:Dictionary=await walk_to(walker,work.to_global(Vector3(0,0,3.7)));report.visits.append(out)
	await physics_frame;await physics_frame
	check(report,"walk out leaves ordinary support and releases reader",out.passed and reader.visitors.is_empty() and walker.is_on_floor())
	walker.global_position=work.to_global(Vector3(-5,.05,-3.3));await settle(walker);cam.position=Vector3(0,1.65,0)
	for i in range(12):
		var before:Dictionary=study.readback()
		await click_room_control(study.console,"Btn_%d"%i,walker,cam,hand,origin,report)
		var after:Dictionary=study.readback()
		var changed:bool=false
		match i:
			0:changed=after.tick==before.tick+1
			1:changed=after.target==mini(before.tick+10,100)
			2:changed=after.tick==0
			3:changed=after.changed!=before.changed
			4:changed=after.coupling==0
			5:changed=after.coupling==.25
			6:changed=after.disturbance==0
			7:changed=after.disturbance==1
			8:changed=not after.scattered
			9:changed=not after.integer_storage
			10:changed=after.slice==(before.slice+1)%11
			11:changed=after.coating!=before.coating
		check(report,"existing control %d performs its action"%i,changed)
	# The manuscript's storage comparison, on the live paired model.
	m.scattered=false;m.disturbance=0;m.coupling=.25;m.changed=true;m.integer_storage=true;m.reset();study.coating=true;study.advance(1)
	check(report,"integer storage removes the +1 intervention in one update",m.report().different==0 and m.report().max_difference==0)
	m.integer_storage=false;m.reset();study.advance(1)
	check(report,"fractional storage spreads to 27 sites with peak .75",m.report().different==27 and is_equal_approx(m.report().max_difference,.75))
	walker.global_position=work.to_global(Vector3(0,.05,-.55));await settle(walker)
	for z in [3,4,5,6,7,5]:
		var route:Dictionary=await walk_to(walker,work.to_global(Vector3(0,0,.25+.27*z)));report.visits.append(route)
		await physics_frame;await physics_frame
		var peak:float=section_peak(study)
		var expected:float=0 if z in [3,7] else .75 if z==5 else .25/26
		check(report,"one-update section %d can be lost and found without changing time"%z,route.passed and study.slice_z==z and m.tick==1 and absf(peak-expected)<.00000001 and slice_matches(study),peak)
		if z in [3,5]:await view(camera,origin,folder,"fractional-z%d"%z,work.global_position-origin+Vector3(-4.8,3.1,-2.8),work.global_position-origin+Vector3(0,1.7,3),85,report)
	# Jitter near a band edge should not flicker the selected plane.
	walker.global_position=work.to_global(Vector3(0,0,1.6+.14));await physics_frame;await physics_frame
	check(report,"small boundary jitter retains slice five",study.slice_z==5)
	walker.global_position=work.to_global(Vector3(0,0,1.6+.18));await physics_frame;await physics_frame
	check(report,"deliberate movement crosses the hysteresis band",study.slice_z==6)
	# Scheduled time remains an independent control; body selection never cancels it.
	study.operate(1);var pending:int=study.target
	var move:Dictionary=await walk_to(walker,work.to_global(Vector3(0,0,.25)));report.visits.append(move)
	check(report,"walking leaves the pending ten-update run intact",move.passed and study.slice_z==0 and study.target==pending and m.tick==1)
	for i in range(10):study._process(.12)
	check(report,"scheduled run still stops at exactly eleven",m.tick==11 and study.target==0)
	check(report,"gain grows as maximum fades",study.view_gain>1/.75 and m.report().max_difference<.75)
	# Reverse over the centre once again and view its weakened, amplified trace.
	var centre:Dictionary=await walk_to(walker,work.to_global(Vector3(0,0,1.6)));report.visits.append(centre)
	await view(camera,origin,folder,"spread",work.global_position-origin+Vector3(-4.8,3.1,-2.8),work.global_position-origin+Vector3(0,1.7,3),85,report)
	check(report,"wide trace is still the paired data",centre.passed and slice_matches(study))
	m.changed=false;m.disturbance=4;m.reset();study.advance(20)
	check(report,"matched forcing preserves exact agreement without intervention",m.a==m.b and m.report().different==0)
	m.changed=true;m.disturbance=0;m.coupling=0;m.reset();study.advance(20)
	check(report,"zero pull preserves one local difference",m.report().different==1 and is_equal_approx(m.report().max_difference,1))
	# The original study remains usable without any body receiver.
	var plain:Node3D=load("res://algorithms/cellularautomata/ca_showcase/difference_study.gd").new();plain.position=origin+Vector3(50,0,50);root.add_child(plain);await process_frame
	check(report,"unconfigured paired study has no walking reader",not plain.has_node("WalkingSlice") and plain.model.a.size()==1331)
	plain.queue_free()
	m.coupling=.25;m.disturbance=1;m.integer_storage=true;m.scattered=true;m.changed=true;m.reset();study.target=0;study.slice_z=5;study.paint()
	camera.queue_free()

func section_peak(study:Node3D)->float:
	var peak:float=0
	for y in range(11):
		for x in range(11):
			var i:int=x+11*y+121*study.slice_z
			peak=maxf(peak,absf(study.model.a[i]-study.model.b[i]))
	return peak

func slice_matches(study:Node3D)->bool:
	for side in range(3):
		var img:Image=study.textures[side].get_image()
		for y in range(11):
			for x in range(11):
				var i:int=x+11*y+121*study.slice_z
				var expected:Color=study.tint(study.model.a[i] if side==0 else study.model.b[i]) if side<2 else Color("112c31").lerp(Color("ffd18e"),absf(study.model.a[i]-study.model.b[i])*study.view_gain)
				var actual:Color=img.get_pixel(x,10-y)
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

