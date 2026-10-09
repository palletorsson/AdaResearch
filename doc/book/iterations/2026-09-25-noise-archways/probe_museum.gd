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
	report["desktop_input"]=[]
	var first:Node3D=nodes.get("simplex_noise")
	var second:Node3D=nodes.get("perlin_noise")
	check(report,"all five authored works retained",first!=null and second!=null and nodes.has("perlin_noise_terrain") and nodes.has("dark_sphere") and nodes.has("configurable_portal"))
	var study:Node3D=first.get_node("PairStudy")
	check(report,"two archways attached",study.arches.size()==2,study.arches.size())
	if study.arches.size()!=2:return
	var a:Node3D=study.arches[0];var b:Node3D=study.arches[1]
	var walker:CharacterBody3D=museum.get("_player")
	var cam:Camera3D=museum.get("_cam")
	var hand:Node3D=walker.get_node("DesktopHand")
	var feel:Node=museum.get("_feel")
	if feel!=null:feel.set_process(false)
	museum.set_process_input(false);museum.set_process_unhandled_input(false)
	walker.global_position=origin+Vector3(6,0.02,9.5);await settle(walker)
	var camera:=Camera3D.new();root.add_child(camera)
	await view(camera,origin,folder,"arrival",Vector3(6,1.65,4.95),Vector3(6,1.65,8.4),100,report)
	await view(camera,origin,folder,"overview",Vector3(6,3.0,5.0),Vector3(6,1.25,10.5),90,report)
	check(report,"identical base arch geometry",a.vertices==b.vertices and a.indices==b.indices)
	check(report,"different fields dress identical forms",a.raw!=b.raw)
	check(report,"arches clear entrance and controls",a.global_position.z-origin.z-1>4.8 and a.global_position.z+1<study.get_node("Controls").global_position.z-.6)
	for arch in study.arches:
		var error:float=0;var edge_error:float=0
		for j in range(arch.V+1):
			for i in range(arch.U+1):
				var k:int=j*(arch.U+1)+i
				var u:float=float(i)/arch.U;var v:float=float(j)/arch.V
				error=maxf(error,absf(arch.raw[k]-arch.work.sample_at(-2+3.5*u,-2+3.5*v)))
				if i==0 or i==arch.U or j==0 or j==arch.V:edge_error=maxf(edge_error,arch.vertices[k].distance_to(arch.displaced[k]))
		check(report,str(arch.work.name)+" values come from existing field",error<.000001,error)
		check(report,str(arch.work.name)+" feet and entrances pinned",edge_error<.000001,edge_error)
		var faces:PackedVector3Array=arch.collider.shape.get_faces();var mismatch:float=0
		for i in range(arch.indices.size()):mismatch=maxf(mismatch,faces[i].distance_to(arch.displaced[arch.indices[i]]))
		check(report,str(arch.work.name)+" collision equals displaced triangles",mismatch<.000001,mismatch)
		check(report,str(arch.work.name)+" real vertex shader loaded",arch.surface.material_override.shader.code.contains("void vertex()"))
		check(report,str(arch.work.name)+" bound encloses relief",arch.surface.custom_aabb.has_point(Vector3(-1.9,0,0)) and arch.surface.custom_aabb.has_point(Vector3(1.9,3.2,0)))
		var query:=PhysicsRayQueryParameters3D.create(arch.to_global(Vector3(0,1.4,0)),arch.to_global(Vector3(2.5,1.4,0)),1)
		query.exclude=[walker.get_rid()]
		var hit:Dictionary=arch.get_world_3d().direct_space_state.intersect_ray(query)
		check(report,str(arch.work.name)+" inside ray meets physical wall",hit.get("collider")==arch.collider.get_parent())
		var walk:Dictionary=await arch_walk(arch,walker)
		check(report,str(arch.work.name)+" body walks through",walk.passed,walk)
		# Actual eye inside the arch, turned up and sideways to see the surface.
		cam.global_position=arch.to_global(Vector3(0,1.65,0));cam.look_at(arch.to_global(Vector3(-.85,2.0,.75)))
		await shot(cam,folder,"inside-"+("simplex" if arch==a else "perlin"),report)
		walker.global_position=origin+Vector3(6,0.02,9.5);await settle(walker)
	# Compare actual GPU displacement with the same pre-displaced mesh on the CPU.
	camera.global_position=a.to_global(Vector3(0,1.35,-.5));camera.look_at(a.to_global(Vector3(-1.0,1.9,.25)));camera.current=true
	await RenderingServer.frame_post_draw
	var gpu:Image=root.get_texture().get_image()
	var original_mesh:Mesh=a.surface.mesh
	var original_material:Material=a.surface.material_override
	var reference:ShaderMaterial=original_material.duplicate();reference.set_shader_parameter("relief_depth",0.0)
	a.surface.mesh=a.reference_mesh;a.surface.material_override=reference
	await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
	var cpu:Image=root.get_texture().get_image();var difference:float=0;var samples:int=0
	for y in range(0,gpu.get_height(),5):
		for x in range(0,gpu.get_width(),5):
			var p0:Color=gpu.get_pixel(x,y);var p1:Color=cpu.get_pixel(x,y)
			difference+=absf(p0.r-p1.r)+absf(p0.g-p1.g)+absf(p0.b-p1.b);samples+=3
	difference/=samples
	check(report,"rendered GPU and CPU reference agree",difference<.005,difference)
	a.surface.mesh=original_mesh;a.surface.material_override=original_material
	# Restore actual player camera to its original local eye before pointer input.
	cam.position=Vector3(0,1.65,0)
	var raw_a:PackedFloat32Array=a.raw.duplicate();var raw_b:PackedFloat32Array=b.raw.duplicate()
	var colour_a:PackedColorArray=a.colours.duplicate()
	walker.global_position=origin+Vector3(6,0.02,9.45);await settle(walker)
	await click_room_control(study,"Btn_1",walker,cam,hand,origin,report)
	check(report,"VIEW removes relief from both arches",a.plate and b.plate and a.displaced==a.vertices and b.displaced==b.vertices)
	check(report,"VIEW preserves field and colour",a.raw==raw_a and b.raw==raw_b and a.colours==colour_a)
	await view(camera,origin,folder,"colour-only",Vector3(6,1.65,4.95),Vector3(6,1.65,8.4),100,report)
	for i in range(5):
		await click_room_control(study,"Btn_0",walker,cam,hand,origin,report)
		var selected:Dictionary=study.selected();var p:Vector2=Vector2(selected.p[0],selected.p[1])
		var u:int=roundi((p.x+2)/3.5*a.U);var v:int=roundi((p.y+2)/3.5*a.V)
		check(report,"shared sample maps to each arch "+str(i),absf(a.raw[v*(a.U+1)+u]-selected.values[0])<.000001 and absf(b.raw[v*(b.U+1)+u]-selected.values[1])<.000001)
	await click_room_control(study,"Btn_1",walker,cam,hand,origin,report)
	check(report,"VIEW restores same relief",not a.plate and a.raw==raw_a and b.raw==raw_b)
	# Existing regeneration/replay API, independently of pointer tests above.
	first._on_regenerate_pressed();study.refresh();var changed:PackedFloat32Array=a.raw.duplicate()
	check(report,"REGEN reaches attached arch",changed!=raw_a)
	study.toggle_view();study.toggle_view()
	check(report,"VIEW does not reset regenerated field",a.raw==changed)
	await click_room_control(study,"Btn_2",walker,cam,hand,origin,report)
	check(report,"MATCH returns both arch fields",a.raw==raw_a and b.raw==raw_b)
	# A wall is not rebuilt into a visitor while they stand under its surface.
	walker.global_position=a.to_global(Vector3(0,.02,0));await settle(walker)
	var revision:int=a.revision;var existing:Shape3D=a.collider.shape
	first._on_frequency_changed(13.0);study.refresh()
	check(report,"occupied arch holds old mesh and collider",a.held and a.revision==revision and a.collider.shape==existing)
	check(report,"held state is visible",a.status.text.contains("Held while occupied"))
	walker.global_position=origin+Vector3(6,0.02,9.5);await settle(walker);study.refresh()
	check(report,"departure applies pending field",not a.held and a.revision>revision and a.raw!=raw_a)
	await click_room_control(study,"Btn_2",walker,cam,hand,origin,report)
	check(report,"final matched pair recovered",a.raw==raw_a and b.raw==raw_b)
	report["arch_scope"]="Real museum placements, GPU render/reference comparison, production pointer buttons and supplied CharacterBody movement. No headset/Quest acceptance."

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

