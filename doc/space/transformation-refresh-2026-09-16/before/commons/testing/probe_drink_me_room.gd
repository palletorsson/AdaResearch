extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[drink-me] ", "PASS " if ok else "FAIL ", message)
func run() -> void:
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL","res://ada_run/drink-me-control.json")
	em.set("_overrides_path","res://ada_run/drink-me-no-overrides.json")
	em.set("_hand_path","res://ada_run/drink-me-no-hand.json")
	em.set("start_chapter","transformation"); em.set("start_map","Trans_Scale")
	var f := FileAccess.open("res://ada_run/drink-me-control.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter":"transformation","dollhouse":0,"grid_pack":1})); f.close()
	root.add_child(em); current_scene = em
	await create_timer(1).timeout
	em.set_process(false); em.set_physics_process(false); em.call("flush_stamps")
	for i in range(160): await process_frame
	var seg: Node3D
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map", "") == "Trans_Scale": seg = rec.node; break
	check(seg != null, "Trans_Scale museum hall builds")
	if seg == null: quit(1); return
	var encounter: Node3D = seg.find_child("DrinkMeEncounter",true,false)
	check(encounter != null, "scale_me drink_me configuration builds the encounter")
	if encounter == null: quit(1); return
	check(not seg.has_meta("em_simulation_stage"), "gallery has no legacy simulation basin")
	print("[drink-me] anchor ",encounter.global_position," basis ",encounter.global_basis.get_scale())
	check(encounter.global_basis.get_scale().is_equal_approx(Vector3.ONE), "museum preserves authored metre scale")
	check(encounter.table.spread == "blooming" and encounter.table.service == "tower", "requested food table variant")
	check(encounter.figure.crust == "spire" and encounter.figure.panels == "leaning", "requested standing figure variant")
	var player: CharacterBody3D = em.get("_player")
	var player_scale := player.global_basis.get_scale()
	var museum_basis := em.global_basis
	var figure_before: Vector3 = encounter.figure.global_basis.get_scale()
	var table_before: Vector3 = encounter.table.global_basis.get_scale()
	var cam := Camera3D.new(); em.add_child(cam); cam.fov = 65
	if "--capture" in OS.get_cmdline_user_args():
		await capture(cam,encounter.to_global(Vector3(0,1.65,0.2)),encounter.to_global(Vector3(0,1.4,3.3)),"before")
	var query := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new(); capsule.radius = 0.22; capsule.height = 1.6
	query.shape = capsule; query.collision_mask = 1
	query.exclude = [player.get_rid()]
	query.transform.origin = encounter.room.to_global(Vector3(2,0.81,5.5)); query.motion = Vector3(0,0,1)
	check(seg.get_world_3d().direct_space_state.cast_motion(query)[0] < 0.99, "body cannot cross the tiny door before pickup")
	player.global_position = encounter.to_global(Vector3(0,0,2.5))
	var pointer: Node = player.find_child("DesktopPointer",true,false)
	if pointer == null:
		pointer = load("res://commons/scenes/DesktopInteractionPointer.gd").new(); player.add_child(pointer)
	cam.global_position = player.global_position+Vector3.UP*1.6
	cam.look_at(encounter.bottle.global_position)
	pointer.set("_camera",cam)
	var grabbable: Node3D = pointer.call("_find_grabbable")
	check(grabbable == encounter.bottle,"desktop crosshair ray finds the bottle on the pickable layer")
	if grabbable == null: quit(1); return
	pointer.call("_grab_held",grabbable)
	for i in range(6): await physics_frame
	check(encounter.enlarged, "desktop carry gesture activates the bottle")
	check(pointer.get("_held") == null, "consumed bottle releases desktop hand")
	check(not encounter.bottle.visible and encounter.bottle.collision_layer == 0, "bottle is consumed without a leftover collider")
	check(encounter.room.scale.is_equal_approx(Vector3.ONE*10), "only the explicit Room scales by ten")
	check(encounter.figure.global_basis.get_scale().is_equal_approx(figure_before*10), "standing figure scales by ten")
	check(encounter.table.global_basis.get_scale().is_equal_approx(table_before*10), "food table scales by ten")
	check(player.global_basis.get_scale().is_equal_approx(player_scale) and em.global_basis == museum_basis, "body and museum keep their scale")
	var target: Vector3 = encounter.table.to_global(encounter.landings[0])
	check(player.global_position.distance_to(target+Vector3.UP*0.08)<0.12, "pickup places feet on the crown of the enlarged table")
	query.transform.origin = target+Vector3.UP*0.88; query.motion = Vector3.ZERO
	check(seg.get_world_3d().direct_space_state.intersect_shape(query).is_empty(), "arrival has body-sized headroom")
	query.transform.origin = encounter.room.to_global(Vector3(2,0,5.8))+Vector3.UP*0.81; query.motion = Vector3(0,0,4)
	check(seg.get_world_3d().direct_space_state.cast_motion(query)[0]>0.99, "same body can cross the enlarged exit")
	var supported := true
	for local_top: Vector3 in encounter.landings:
		var p: Vector3 = encounter.table.to_global(local_top)
		var hit := seg.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*0.1,p-Vector3.UP*0.2))
		supported = supported and not hit.is_empty()
	check(supported, "all thirteen visible porcelain landings have collision")
	# Walk/drop from one serving plate to the next using the actual museum body.
	var descent := true
	for i in range(1,encounter.landings.size()):
		var next: Vector3 = encounter.table.to_global(encounter.landings[i])
		var arrived := false
		for frame in range(200):
			await physics_frame
			var delta: float = 1.0/60.0
			var offset := next-player.global_position; offset.y = 0
			var horizontal := offset.normalized()*2.5 if offset.length()>0.05 else Vector3.ZERO
			player.velocity.x = horizontal.x; player.velocity.z = horizontal.z
			player.velocity.y -= 9.8*delta
			player.move_and_slide()
			if player.is_on_floor() and absf(player.global_position.y-next.y)<0.15 and offset.length()<0.8:
				arrived = true; break
			if player.global_position.y < next.y-0.3: break
		print("[drink-me-step] ",i," ",arrived," feet ",player.global_position," target ",next)
		descent = descent and arrived
		if not arrived: break
	check(descent,"body can descend all serving steps under gravity")
	for waypoint in [Vector3(2,0,5.8),Vector3(2,0,6.3)]:
		var goal: Vector3 = encounter.room.to_global(waypoint)
		var reached := false
		for frame in range(1800):
			await physics_frame
			var offset := goal-player.global_position; offset.y = 0
			var horizontal := offset.normalized()*4.0 if offset.length()>0.1 else Vector3.ZERO
			player.velocity.x = horizontal.x; player.velocity.z = horizontal.z; player.velocity.y -= 9.8/60.0
			player.move_and_slide()
			if offset.length()<0.15 and player.is_on_floor(): reached = true; break
		check(reached,"walk from the descent to "+str(waypoint)+" on solid ground")
	player.global_position = encounter.room.to_global(Vector3(2,0.1,5.8))
	em.call("_cull_artifacts")
	check(encounter.get_parent().visible,"enlarged room stays visible at its distant exit")
	if "--capture" in OS.get_cmdline_user_args():
		await capture(cam,target+Vector3(0,1.65,0),encounter.room.to_global(Vector3(0,1.3,4.8)),"after")
		await capture(cam,encounter.room.to_global(Vector3(-2.6,2.7,0.6)),encounter.room.to_global(Vector3(0,1.1,3.2)),"overview")
	f = FileAccess.open("res://ada_run/drink_me_checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	print("[drink-me] ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
func capture(cam: Camera3D, pos: Vector3, target: Vector3, suffix: String) -> void:
	cam.global_position = pos; cam.look_at(target)
	for i in range(20): await process_frame; cam.make_current()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://ada_run/Trans_Scale_drink_me_"+suffix+".png")
