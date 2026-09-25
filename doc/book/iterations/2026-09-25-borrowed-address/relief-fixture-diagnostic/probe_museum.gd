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
	var a:Node3D=nodes.get("noisesphere")
	check(report,"retained sphere study and supporting orb",a!=null and nodes.has("dark_sphere"))
	if a==null:return
	var study:Node3D=a.get_node("WarpStudy")
	var shell:Node3D=study.enclosure
	var surface:MeshInstance3D=shell.surface
	var collider:CollisionShape3D=shell.get_node("ShellCollision").get_child(0)
	var initial_vertices:PackedVector3Array=surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var initial_colors:PackedColorArray=surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var initial_relief:PackedVector3Array=shell.displaced_vertices.duplicate()
	check(report,"room starts in vertex-shader relief",study.relief and surface.material_override is ShaderMaterial and is_equal_approx(surface.material_override.get_shader_parameter("relief_depth"),.8))
	check(report,"vertex source retains original sphere support",initial_vertices.size()==37248 and initial_vertices==base_vertices(shell))
	check(report,"collision matches the displaced surface on arrival",collider.shape.get_faces()==initial_relief and initial_relief!=initial_vertices)
	check_deformation(study,report)
	var camera:=Camera3D.new();root.add_child(camera);camera.current=true
	camera.global_position=origin+Vector3(6.5,1.7,2.5);camera.look_at(origin+Vector3(6.5,1.3,6.0));camera.fov=85
	await shot(camera,folder,"instrument",report)
	camera.global_position=origin+Vector3(10.5,1.7,5.3);camera.look_at(origin+Vector3(5.4,3.3,5.3));camera.fov=95
	await shot(camera,folder,"vertex-room",report)
	var walker:CharacterBody3D=museum.get("_player")
	var cam:Camera3D=museum.get("_cam")
	var hand:Node3D=walker.get_node("DesktopHand")
	var feel:Node=museum.get("_feel")
	if feel!=null:feel.set_process(false);feel.set_physics_process(false)
	museum.set_process_input(false);museum.set_process_unhandled_input(false)
	walker.global_position=origin+Vector3(3.9,.07,3.25);walker.velocity=Vector3.ZERO
	for i in range(20):
		walker.velocity=Vector3(0,-1,0);walker.move_and_slide();await physics_frame
	check(report,"inside control approach stays on unchanged floor",walker.global_position.distance_to(origin+Vector3(3.9,.06,3.25))<.12)
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;report["desktop_input"]=[]
	await click_room_control(study,"Btn_1",walker,cam,hand,origin,report)
	camera.global_position=origin+Vector3(3.9,1.7,3.25);camera.look_at(origin+Vector3(6.5,4.5,1.3));camera.fov=85
	await shot(camera,folder,"relief-patch",report)
	await compare_gpu(study,camera,report)
	await click_room_control(study,"Btn_2",walker,cam,hand,origin,report)
	check(report,"SKIN restores spherical geometry and collision",not study.relief and shell.displaced_vertices==initial_vertices and collider.shape.get_faces()==initial_vertices and surface.material_override.get_shader_parameter("relief_depth")==0.0)
	check(report,"RELIEF toggle retains colour samples",surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]==initial_colors)
	await shot(camera,folder,"skin-patch",report)
	camera.global_position=origin+Vector3(10.5,1.7,5.3);camera.look_at(origin+Vector3(5.4,3.3,5.3));camera.fov=95
	await shot(camera,folder,"skin-room",report)
	var fixed_ring:int=shell.sample_ring.mesh.get_instance_id()
	var p_before:Array=study.selected().p
	await click_room_control(study,"Btn_3",walker,cam,hand,origin,report)
	check(report,"ZERO agrees at every plate sample",study.values[0]==study.values[1] and study.strength()==0.0)
	check(report,"ZERO in SKIN keeps direction and ring fixed",study.selected().p==p_before and shell.sample_ring.mesh.get_instance_id()==fixed_ring)
	camera.global_position=origin+Vector3(3.9,1.7,3.25);camera.look_at(origin+Vector3(6.5,4.5,1.3));camera.fov=85
	await shot(camera,folder,"ring-zero",report)
	await click_room_control(study,"Btn_0",walker,cam,hand,origin,report)
	await shot(camera,folder,"ring-warp",report)
	check(report,"WARP in SKIN changes colour without moving surface or ring",study.strength()==.35 and shell.sample_ring.mesh.get_instance_id()==fixed_ring and shell.displaced_vertices==initial_vertices)
	await click_room_control(study,"Btn_0",walker,cam,hand,origin,report)
	await click_room_control(study,"Btn_2",walker,cam,hand,origin,report)
	check(report,"RELIEF at .8 recovers original displaced collision",study.relief and study.strength()==.8 and shell.displaced_vertices==initial_relief and collider.shape.get_faces()==initial_relief)
	var before_warp:PackedVector3Array=shell.displaced_vertices.duplicate()
	await click_room_control(study,"Btn_0",walker,cam,hand,origin,report)
	check(report,"WARP in RELIEF changes the shape and matching collision",study.strength()==1.4 and shell.displaced_vertices!=before_warp and collider.shape.get_faces()==shell.displaced_vertices)
	check(report,"WARP preserves selected input direction while relief radius changes",study.selected().p==p_before)
	check_deformation(study,report)
	await shot(camera,folder,"strong-relief",report)
	# Return to the authored arrival state before testing all five selections.
	await click_room_control(study,"Btn_3",walker,cam,hand,origin,report)
	await click_room_control(study,"Btn_0",walker,cam,hand,origin,report)
	await click_room_control(study,"Btn_0",walker,cam,hand,origin,report)
	var surface_id:int=surface.mesh.get_instance_id()
	var pair_ids:Array=[study.spheres[0].mesh.get_instance_id(),study.spheres[1].mesh.get_instance_id()]
	var values_before:Array=study.values.duplicate(true)
	var faces_before:PackedVector3Array=collider.shape.get_faces()
	report["witnesses"]=[]
	for i in range(5):
		var rec:Dictionary=study.selected()
		var d:Vector3=study.PROBES[study.sample_index].normalized()
		check(report,"same selected direction at enclosing surface %d"%i,shell.sample_direction.is_equal_approx(d))
		var ring_vertices:PackedVector3Array=shell.sample_ring.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var max_error:float=0.0
		var min_angle:float=INF;var max_angle:float=0.0
		for v in ring_vertices:
			var offset:Vector3=v-shell.CENTRE
			max_error=maxf(max_error,absf(offset.length()-(shell.radius_at(offset.normalized(),study)-shell.WITNESS_INSET)))
			var angle:float=acos(clampf(offset.normalized().dot(d),-1,1))
			min_angle=minf(min_angle,angle);max_angle=maxf(max_angle,angle)
		check(report,"hollow ring follows relief just inside the wall %d"%i,ring_vertices.size()==288 and max_error<.0001 and min_angle>.035 and max_angle<.046)
		check(report,"ring projection is the instrument address %d"%i,Vector2(d.x,d.z).distance_to(Vector2(rec.p[0],rec.p[1])/3.0)<.00001)
		check(report,"SAMPLE preserves field meshes and collision %d"%i,surface.mesh.get_instance_id()==surface_id and study.spheres[0].mesh.get_instance_id()==pair_ids[0] and study.spheres[1].mesh.get_instance_id()==pair_ids[1] and study.values==values_before and collider.shape.get_faces()==faces_before)
		report.witnesses.append({"direction":arr(d),"selected":rec,"max_ring_error":max_error})
		await click_room_control(study,"Btn_1",walker,cam,hand,origin,report)
	check(report,"five SAMPLE presses return to selected overhead direction",study.sample_index==1)
	await physics_frame
	# Door and wall rays are actual physics-space queries after all state changes.
	var space:=shell.get_world_3d().direct_space_state
	for side in [-1,1]:
		for height in [.5,1.7,2.2]:
			var start:Vector3=shell.to_global(Vector3(side*4.1,height,.2))
			var end:Vector3=shell.to_global(Vector3(side*5.4,height,.2))
			var q:=PhysicsRayQueryParameters3D.create(start,end,1);q.exclude=[walker.get_rid()]
			check(report,"door remains open at side %d height %.1f"%[side,height],space.intersect_ray(q).is_empty())
	check(report,"controls remain at supported approach after all deformations",walker.global_position.distance_to(origin+Vector3(3.9,.06,3.25))<.12)
	report["study_position"]=arr(study.global_position-origin);report["study_scale"]=arr(study.global_basis.get_scale())
	report["scope"]="Actual private museum; true vertex shader with shared CPU noise samples, matching collision. Synthetic mouse through DesktopHand, camera smoothing paused, sampled CharacterBody routes. No tracked-headset/learner/Quest acceptance."
	camera.queue_free()

func base_vertices(shell:Node3D)->PackedVector3Array:
	var result:=PackedVector3Array()
	for d in shell.directions:result.append(shell.CENTRE+d*shell.RADIUS)
	return result

func check_deformation(study:Node3D,report:Dictionary)->void:
	var shell:Node3D=study.enclosure
	var data:Array=shell.surface.mesh.surface_get_arrays(0)
	var uv:PackedVector2Array=data[Mesh.ARRAY_TEX_UV]
	var error:float=0.0;var min_shift:float=INF;var max_shift:float=-INF;var pinned:int=0
	for i in range(shell.directions.size()):
		var d:Vector3=shell.directions[i]
		var value:float=study.value_at(Vector2(d.x,d.z)*3.0,study.strength())
		var weight:float=shell.relief_weight(d)
		error=maxf(error,uv[i].distance_to(Vector2(value,weight)))
		var offset:float=value*weight*.8
		min_shift=minf(min_shift,offset);max_shift=maxf(max_shift,offset)
		if is_zero_approx(weight):
			pinned+=1
			error=maxf(error,shell.displaced_vertices[i].distance_to(data[Mesh.ARRAY_VERTEX][i]))
	var max_position_error:float=0.0
	for i in range(uv.size()):
		var base:Vector3=data[Mesh.ARRAY_VERTEX][i]
		var expected:Vector3=base+(base-shell.CENTRE).normalized()*uv[i].x*uv[i].y*.8
		max_position_error=maxf(max_position_error,expected.distance_to(shell.displaced_vertices[i]))
	check(report,"signed samples and doorway/floor weights reach the shader %.2f"%study.strength(),error<.00001 and pinned>100,{"attribute_error":error,"pinned_vertices":pinned})
	check(report,"shader formula matches collision vertices %.2f"%study.strength(),max_position_error<.00001,{"max_error":max_position_error})
	check(report,"meaningful inward and outward relief %.2f"%study.strength(),min_shift<-.15 and max_shift>.15,{"min_metres":min_shift,"max_metres":max_shift})
	check(report,"displaced bounds fit expanded render bounds",shell.displaced_vertices.all(func(v):return shell.surface.custom_aabb.has_point(v)))

func compare_gpu(study:Node3D,camera:Camera3D,report:Dictionary)->void:
	camera.current=true;await create_timer(.2).timeout;await RenderingServer.frame_post_draw
	var gpu:Image=root.get_texture().get_image()
	var surface:MeshInstance3D=study.enclosure.surface
	var data:Array=surface.mesh.surface_get_arrays(0)
	data[Mesh.ARRAY_VERTEX]=study.enclosure.displaced_vertices
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,data)
	var reference:=MeshInstance3D.new();reference.mesh=mesh
	var mat:ShaderMaterial=surface.material_override.duplicate();mat.set_shader_parameter("relief_depth",0.0)
	reference.material_override=mat;reference.cast_shadow=surface.cast_shadow
	surface.get_parent().add_child(reference);reference.transform=surface.transform;surface.visible=false
	await create_timer(.2).timeout;await RenderingServer.frame_post_draw
	var cpu:Image=root.get_texture().get_image()
	var error:float=0.0;var maximum:float=0.0
	for y in range(64):
		for x in range(64):
			var px:int=int((.1+.8*(x+.5)/64.0)*gpu.get_width())
			var py:int=int((.1+.8*(y+.5)/64.0)*gpu.get_height())
			var a:Color=gpu.get_pixel(px,py);var b:Color=cpu.get_pixel(px,py)
			var e:float=(absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b))/3.0
			error+=e;maximum=maxf(maximum,e)
	surface.visible=true;reference.queue_free();await process_frame
	check(report,"rendered GPU relief agrees with CPU collision-surface reference",error/4096.0<.006,{"samples":4096,"mean_rgb_error":error/4096.0,"max_sample_error":maximum})

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

func shot(camera:Camera3D,folder:String,tag:String,report:Dictionary)->void:
	camera.current=true;await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	var path:=folder+tag+".png";root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path));report["shots"].append(path)
