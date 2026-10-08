extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var name := "Trans_Pre"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="): name=arg.trim_prefix("--map=")
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL","res://ada_run/build-up-control.json")
	em.set("_overrides_path","res://ada_run/build-up-no-overrides.json")
	em.set("_hand_path","res://ada_run/build-up-no-hand.json")
	em.set("start_chapter","transformation" if name.begins_with("Trans_") else "primitives")
	em.set("start_map",name)
	var f := FileAccess.open("res://ada_run/build-up-control.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter":"transformation" if name.begins_with("Trans_") else "primitives","dollhouse":0,"grid_pack":1}))
	f.close()
	root.add_child(em)
	current_scene=em
	await create_timer(1).timeout
	em.set_process(false)
	em.call("flush_stamps")
	var seg: Node3D
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map","")==name: seg=rec.node; break
	if seg == null:
		push_error("Requested museum hall missing"); quit(1); return
	if name.begins_with("Trans_"):
		for i in range(1800):
			var gs := seg.get_node_or_null("SimGrid_"+name)
			if gs != null and gs.has_meta("stage_grid_ready"): break
			await process_frame
	for i in range(30): await process_frame
	if "--expect-fire" in OS.get_cmdline_user_args():
		var fire := seg.get_node_or_null("BasinFire")
		var plan: Dictionary = seg.get_meta("em_simulation_stage")
		if fire == null:
			push_error("Requested basin fire is missing"); quit(1); return
		var shapes := 0
		for shape in fire.find_children("*","CollisionShape3D",true,false):
			var box: AABB = shape.global_transform*shape.shape.get_debug_mesh().get_aabb()
			if absf(box.position.y+float(plan.depth))>0.01 or absf(box.end.y+float(plan.depth)-0.6)>0.01:
				push_error("Fire must occupy only the bottom 0.6 metres of the basin"); quit(1); return
			shapes+=1
		if shapes==0:
			push_error("Fire has no contact volumes"); quit(1); return
		print("[basin-fire-check] ",shapes," volumes at basin base; clear of deck and rides")
	var camera := Camera3D.new()
	em.add_child(camera)
	camera.current=true
	camera.fov=55
	var target := Vector3.ZERO
	if name.begins_with("Trans_"):
		var plan: Dictionary = seg.get_meta("em_simulation_stage")
		target=seg.to_global(Vector3(plan.w/2.0,1,em.VESTIBULE_H+plan.d/2.0))
		var distance_factor := maxf(1.0,float(plan.d)/30.0)
		camera.global_position=target+Vector3(-17,25,-26)*distance_factor
	else:
		var artifact: Node3D
		for n in seg.find_children("*","Node3D",true,false):
			if n.get_meta("artifact_lookup_name","")=="simulation_grid": artifact=n; break
		if artifact==null:
			push_error("Simulation grid was not stamped in museum"); quit(1); return
		target=artifact.global_position
		print("[museum-plan] scale ",artifact.global_basis.get_scale()," position ",target)
		var state := seg.get_world_3d().direct_space_state
		var hits := 0
		for x in range(5):
			for z in range(5):
				var p := artifact.to_global(Vector3(x-2,0,z-2))
				var h := state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*0.3,p-Vector3.UP*0.3))
				if not h.is_empty(): hits+=1
		print("[museum-plan] walkable cells ",hits)
		if hits!=25 or not artifact.global_basis.get_scale().is_equal_approx(Vector3.ONE):
			push_error("Museum plan size/collision check failed"); quit(1); return
		camera.global_position=target+Vector3(0,8,-3)
	camera.look_at(target)
	for i in range(15): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://ada_run/"+name+"_build_up.png")
	print("[capture] ",name," saved")
	if name == "Trans_Rotation" and "--rotation-details" in OS.get_cmdline_user_args():
		for study in ["wall_crossings","array_compare"]:
			var artifact: Node3D
			for n in seg.find_children("*","Node3D",true,false):
				if n.get_script() == load("res://commons/artifacts/rotation_studies/"+study+".gd"):
					artifact=n; break
			if artifact == null:
				push_error("Rotation study missing: "+study); quit(1); return
			artifact.set_process(false)
			if study=="wall_crossings": artifact.set_crossing_pose()
			target=artifact.to_global(Vector3(0,0.7,0 if study=="wall_crossings" else 10))
			camera.global_position=target+Vector3(0,15,-36)
			camera.look_at(target)
			for i in range(15):
				await process_frame
				camera.make_current()
			print("[capture-camera] ",study," target ",target," eye ",camera.global_position)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://ada_run/Trans_Rotation_"+study+".png")
			print("[capture] ",study," current study saved")
	quit(0)
