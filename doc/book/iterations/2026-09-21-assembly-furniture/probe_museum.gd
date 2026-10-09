extends SceneTree
const Store=preload("res://algorithms/computationalbiology/molecular_framework/AssemblyPoseRecord.gd")
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
	set_meta(Store.PATH_KEY,folder+"bond-probe-"+str(Time.get_ticks_usec())+".json")
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

	report["checks"]=[]
	var study: Node3D=nodes.get("MolecularDesigner")
	check(report,is_instance_valid(study),"MolecularDesigner loads in its actual museum hall")
	if not is_instance_valid(study): quit(1);return
	await process_frame
	var rag: Node3D=study.get_node_or_null("BodyRagdoll")
	var gold: Node3D=study.get_node_or_null("BodyWorkshop")
	check(report,is_instance_valid(rag),"Opt-in ragdoll built")
	if not is_instance_valid(rag):quit(1);return
	study.set_process(false)
	study._assemble("VRBody")
	settle(study,18)
	for p in study.parts:p.set_process(false)
	var gold_before: Dictionary=gold.export_pose()
	var saved_before: Dictionary=Store.read(self)
	check(report,rag.parts.size()==10 and rag.links.size()==9,"Ten physical parts joined by nine pin constraints")
	check(report,rag.grips.size()==13,"Every source body point has a grabbable ring")
	check(report,rag.global_basis.get_scale().is_equal_approx(Vector3.ONE),"Ragdoll physics stays at metre scale under enlarged artifact")
	report["ragdoll_position"]=arr(rag.global_position-origin)
	await create_timer(1.0).timeout
	check(report,is_instance_valid(rag.hanger) and rag.anchor_position("head").distance_to(rag.to_global(rag.points.head))<.05,"Hanging support keeps head in reach")
	var physical_live := true
	for part in rag.parts.values():physical_live=physical_live and not part.freeze and part.mass>0 and part.gravity_scale>0
	check(report,physical_live,"Physical parts use mass and gravity, never frozen during play")
	var grip: RigidBody3D=rag.grips.l_hand
	var start_hand: Vector3=rag.anchor_position("l_hand")
	var start_elbow: Vector3=rag.anchor_position("l_elb")
	var camera_hand:=Camera3D.new();root.add_child(camera_hand)
	camera_hand.global_position=grip.global_position+rag.global_basis*Vector3(0,0,1.2)
	camera_hand.look_at(grip.global_position)
	var pointer: Node3D=load("res://commons/scenes/DesktopInteractionPointer.gd").new()
	root.add_child(pointer);pointer.set_process(false);pointer._camera=camera_hand
	await physics_frame
	var found: Node3D=pointer._find_grabbable()
	report["desktop_hit"]=str(found.get_path()) if is_instance_valid(found) else "none"
	report["grip_position"]=arr(grip.global_position-rag.global_position)
	check(report,found==grip,"Desktop ray selects the hand ring")
	pointer._grab_held(grip)
	check(report,rag.active.has("l_hand") and not is_instance_valid(rag.hanger),"Taking hand releases hanging support")
	var camera_start:=camera_hand.global_position
	for frame in range(100):
		camera_hand.global_position=camera_start+rag.global_basis*Vector3(-.45,.7,.1)*minf(float(frame)/70,1)
		pointer._process(1.0/60)
		await physics_frame
	var hand_move: float=rag.anchor_position("l_hand").distance_to(start_hand)
	var elbow_move: float=rag.anchor_position("l_elb").distance_to(start_elbow)
	report["drag"]={"hand_distance":hand_move,"elbow_distance":elbow_move,"constraint_gap":gap(rag)}
	check(report,hand_move>.2 and elbow_move>.15,"Pulling hand moves both hand and neighbouring elbow")
	check(report,not rag.parts.l_fore.freeze,"Grabbing target does not freeze or teleport the physical limb")
	check(report,gap(rag)<.12,"Joined limb anchors remain within solver tolerance during dragging")
	rag.reset_button.button_pressed.emit(rag.reset_button)
	check(report,not rag.reset_pending and rag.active.size()==1,"Reset refuses to interrupt a held limb")
	pointer._drop_held()
	check(report,rag.active.is_empty() and grip.freeze and grip.collision_layer==4,"Desktop release stops pulling and restores pickable target")
	await create_timer(3.0).timeout
	var max_height:=0.0
	var finite_above_floor:=true
	for part in rag.parts.values():
		var local: Vector3=rag.to_local(part.global_position)
		max_height=maxf(max_height,local.y)
		finite_above_floor=finite_above_floor and local.is_finite() and local.y>-.03
	report["released"]={"highest_part_center":max_height,"constraint_gap":gap(rag)}
	check(report,max_height<.5 and finite_above_floor,"Released body falls, stays above floor and settles low")
	check(report,gap(rag)<.12,"Constraints survive the fall")
	rag.reset_button.button_pressed.emit(rag.reset_button)
	await create_timer(.8).timeout
	check(report,is_instance_valid(rag.hanger) and not rag.reset_pending,"Physical reset button hangs the body again")
	report["reset_head_error"]=rag.anchor_position("head").distance_to(rag.to_global(rag.points.head))
	check(report,rag.anchor_position("head").distance_to(rag.to_global(rag.points.head))<.05,"Reset restores the head to hanging position")
	# Two genuine XRTools drivers, with synthetic controllers rather than headset input.
	var controllers: Array=[]
	var pickups: Array=[]
	for id in ["l_hand","r_foot"]:
		var controller:=XRController3D.new();root.add_child(controller)
		var pickup: Node3D=load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
		controller.add_child(pickup);pickup.set_process(false)
		controller.global_position=rag.grips[id].global_position
		rag.grips[id].pick_up(pickup)
		controllers.append(controller);pickups.append(pickup)
	check(report,rag.active.size()==2,"Two XRTools pickups can hold different limbs together")
	var vr_start: Vector3=rag.anchor_position("r_foot")
	for frame in range(75):
		controllers[0].global_position+=rag.global_basis*Vector3(0,.008,0)
		controllers[1].global_position+=rag.global_basis*Vector3(.004,.008,0)
		await physics_frame
	check(report,rag.anchor_position("r_foot").distance_to(vr_start)>.2,"XRTools controller movement pulls the physical foot")
	report["two_hand_gap"]=gap(rag)
	check(report,gap(rag)<.12,"Joint constraints remain bounded with two held limbs")
	for i in range(2):rag.grips[["l_hand","r_foot"][i]].let_go(pickups[i],Vector3.ZERO,Vector3.ZERO)
	check(report,rag.active.is_empty(),"Both VR releases stop their forces")
	for c in controllers:c.queue_free()
	pointer.queue_free();camera_hand.queue_free()
	check(report,gold.export_pose()==gold_before and Store.read(self)==saved_before,"Physics play changes neither gold workshop nor saved return pose")
	var legacy: Node3D=load("res://algorithms/computationalbiology/molecular_framework/MolecularDesigner.tscn").instantiate()
	legacy.enable_auto_cycle=false;root.add_child(legacy);await process_frame
	check(report,not legacy.has_node("BodyRagdoll"),"Other catalogue placements remain unchanged unless opted in")
	legacy.queue_free()
	rag.request_reset();await create_timer(.7).timeout
	var gate: Dictionary=museum.get("_gate")
	if not gate.is_empty():gate.scanner.palm_scanned.emit();museum.get("_mod_gate").call("step_open",gate,10.0)

	report["furniture"]={}
	for kind in ["Chair","Table","Lamp"]:
		var furniture: Node3D=study.get_node_or_null("Furniture_"+kind)
		check(report,is_instance_valid(furniture),kind+" physics study loads in actual hall")
		if not is_instance_valid(furniture):continue
		var source: Dictionary=study.assemblies[kind]
		check(report,furniture.parts.size()==source.nodes.size() and furniture.links.size()==source.bonds.size(),kind+" retains source parts and connections")
		check(report,furniture.grips.size()==source.nodes.size(),kind+" has a grip for every part")
		check(report,furniture.global_basis.get_scale().is_equal_approx(Vector3.ONE),kind+" stays at metre scale")
		check(report,furniture.supports.size()==furniture.parts.size(),kind+" is initially held by explicit staging supports")
		var id: String={"Chair":"back","Table":"leg1","Lamp":"shade"}[kind]
		var neighbour: String={"Chair":"seat","Table":"top","Lamp":"bulb"}[kind]
		var handle: Node3D=furniture.grips[id]
		var start: Vector3=furniture.anchor_position(id)
		var neighbour_start: Vector3=furniture.parts[neighbour].global_position
		var cam:=Camera3D.new();root.add_child(cam)
		cam.global_position=start+furniture.global_basis*Vector3(0,.15,1.1)
		cam.look_at(start)
		var desktop: Node3D=load("res://commons/scenes/DesktopInteractionPointer.gd").new()
		root.add_child(desktop);desktop.set_process(false);desktop._camera=cam
		await physics_frame
		var furniture_hit: Node3D=desktop._find_grabbable()
		check(report,furniture_hit==handle,kind+" part can be selected by actual desktop ray")
		desktop._grab_held(handle)
		check(report,furniture.supports.is_empty() and furniture.active.has(id),kind+" first grab releases all staging supports")
		var cam_start:=cam.global_position
		for frame in range(85):
			cam.global_position=cam_start+furniture.global_basis*Vector3(-.35,.7,.3)*minf(float(frame)/60,1)
			desktop._process(1.0/60)
			await physics_frame
		var neighbour_move: float=furniture.parts[neighbour].global_position.distance_to(neighbour_start)
		var target_move: float=furniture.anchor_position(id).distance_to(start)
		var live:=true
		for body in furniture.parts.values():live=live and not body.freeze
		check(report,neighbour_move>.12 and target_move>.15,kind+" drag travels from selected part into its neighbour")
		check(report,live and gap(furniture)<.14,kind+" parts stay dynamic and joints remain connected while pulled")
		furniture.reset_button.button_pressed.emit(furniture.reset_button)
		check(report,not furniture.reset_pending and furniture.active.size()==1,kind+" reset refuses during a hold")
		desktop._drop_held()
		await create_timer(2.5).timeout
		var valid:=true
		var moving_slowly:=true
		for body in furniture.parts.values():
			var local: Vector3=furniture.to_local(body.global_position)
			valid=valid and local.is_finite() and local.y>-.06 and local.length()<4
			moving_slowly=moving_slowly and body.linear_velocity.length()<.45
		check(report,valid and gap(furniture)<.14,kind+" remains finite, joined and above the floor after release")
		check(report,moving_slowly,kind+" settles after release")
		furniture.reset_button.button_pressed.emit(furniture.reset_button)
		await create_timer(.7).timeout
		var reset_error:=0.0
		for name in furniture.parts:
			reset_error=maxf(reset_error,furniture.parts[name].position.distance_to(furniture.initial[name].origin))
		check(report,reset_error<.06 and furniture.supports.size()==furniture.parts.size(),kind+" reset restores the supported starting arrangement")
		# Use actual XRTools drivers with two synthetic controllers.
		var control_pair: Array=[]
		var driver_pair: Array=[]
		var ids: Array=[id,neighbour]
		for name in ids:
			var controller:=XRController3D.new();root.add_child(controller)
			var pickup: Node3D=load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
			controller.add_child(pickup);pickup.set_process(false)
			controller.global_position=furniture.grips[name].global_position
			furniture.grips[name].pick_up(pickup)
			control_pair.append(controller);driver_pair.append(pickup)
		for frame in range(50):
			control_pair[0].global_position+=furniture.global_basis*Vector3(.003,.006,0)
			control_pair[1].global_position+=furniture.global_basis*Vector3(-.002,.004,0)
			await physics_frame
		check(report,furniture.active.size()==2 and gap(furniture)<.14,kind+" supports two simultaneous XRTools grips")
		for i in range(2):furniture.grips[ids[i]].let_go(driver_pair[i],Vector3.ZERO,Vector3.ZERO)
		check(report,furniture.active.is_empty(),kind+" releases both VR force targets")
		for controller in control_pair:controller.queue_free()
		furniture.request_reset();await create_timer(.5).timeout
		report.furniture[kind]={"position":arr(furniture.global_position-origin),"parts":furniture.parts.size(),"joints":furniture.links.size(),"selected_moved":target_move,"neighbour_moved":neighbour_move,"reset_error":reset_error,"desktop_hit":str(furniture_hit.name) if is_instance_valid(furniture_hit) else "none"}
		desktop.queue_free();cam.queue_free()
	check(report,gold.export_pose()==gold_before and Store.read(self)==saved_before,"All furniture play leaves the gold body and its saved record untouched")

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
	Engine.time_scale = 4.0
	for row in spec.get("walks", []):
		if walker == null:
			failures.append("Missing museum walker")
			break
		var target_host: Node3D = nodes.get(str(row.get("token", ""))) as Node3D
		var target_cube: Node3D = null
		if target_host != null:
			target_cube = target_host.get_node_or_null(str(row["child"])) if row.has("child") else target_host
		var initial_exists := is_instance_valid(target_cube)
		if report.walks.is_empty(): walker.global_position = origin + vec(row["from"])
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
	Engine.time_scale = 1.0
	if is_instance_valid(walker): walker.hide()
	if DisplayServer.get_name() != "headless":
		var old_camera: Camera3D = museum.get("_cam")
		if old_camera != null:
			for timer in old_camera.find_children("*", "Timer", true, false):
				timer.stop()
		var camera := Camera3D.new()
		root.add_child(camera)
		camera.current = true

		for row in spec.get("shots", []):
			if row.has("kind"):
				var furniture: Node3D=study.get_node("Furniture_"+row.kind)
				var id: String={"Chair":"back","Table":"leg1","Lamp":"shade"}[row.kind]
				if row.state=="held":
					furniture.request_reset();await create_timer(.7).timeout
				if row.state=="pull":
					var start: Vector3=furniture.grips[id].global_position
					furniture.grips[id].on_desktop_grab(null)
					for i in range(90):
						furniture.grips[id].global_position=start+furniture.global_basis*Vector3(-.4,.8,.2)*minf(float(i)/65,1)
						await physics_frame
				if row.state=="drop":
					furniture.grips[id].on_desktop_drop(null)
					await create_timer(2.5).timeout
			else:
				for kind in ["Chair","Table","Lamp"]:study.get_node("Furniture_"+kind).request_reset()
				await create_timer(.7).timeout

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

func check(report: Dictionary, ok: bool, message: String) -> void:
	report.checks.append({"ok":ok,"message":message})
	if not ok: failures.append(message)
func settle(s: Node, seconds: int) -> void:
	for i in range(seconds*60):
		for p in s.parts:
			if p.target_active:p._dock_to_target(1.0/60.0)
		if s.assembled:
			s._park_surplus(1.0/60.0)
			s._update_bonds()
func prepare_view(s: Node, mode: String) -> void:
	if mode=="float":
		s._set_float_mode()
		seed(19)
		for p in s.parts:
			p.position=s.inventory_center+Vector3(randf_range(-1,1),randf_range(-1,1),randf_range(-1,1))*s.inventory_box*.5
	else:
		s._assemble(mode)
		settle(s,18)
	for p in s.parts:p.set_process(false)
func capture_state(s: Node, mode: String) -> Dictionary:
	return {"mode":mode,"assembly":s.current_assembly,"assembled":s.assembled,"parts":s.parts.size(),"bonds":s.bonds.size(),"witness_instance":s.parts[0].get_instance_id(),"witness_type":s.parts[0].part_type,"witness_mesh":s.parts[0].mesh_node.mesh.get_class(),"witness_position":arr(s.parts[0].position)}

func same_points(a: Array,b: Array) -> bool:
	if a.size()!=b.size():return false
	for i in range(a.size()):
		if a[i].distance_to(b[i])>.00001:return false
	return true

func gap(rag: Node3D) -> float:
	var maximum:=0.0
	for link in rag.links: maximum=maxf(maximum,link.a.to_global(link.pa).distance_to(link.b.to_global(link.pb)))
	return maximum
