extends "res://tools/probes/void_game_probe.gd"
var charger: Node3D
var charger_floor := -1

func reach_charger() -> void:
	# Follow the shared layout, so moving the unit in the editor does not
	# leave this interaction probe reaching for an unloaded roof instance.
	for index in range(game.building.content.data.floors.size()):
		for prop in game.building.content.data.floors[index].get("props",[]):
			if prop.kind != "wall_charger": continue
			charger_floor=index
			game.place_player(game.spawn_for(index))
			await frames(35)
			charger=game.building.content.props["%d/%s"%[index,prop.id]].get_node("Prefab")
			return

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed: quit(1); return
	for use_xr in ([true] if "--xr-only" in OS.get_cmdline_user_args() else [false,true]):
		await start(use_xr)
		await reach_charger()
		var mode := "XR" if use_xr else "desktop"
		check(mode+": first charger is on Point Trace",charger_floor==4 and game.building.content.data.floors[charger_floor].map=="Point_Trace")
		game.place_player(charger.to_global(Vector3(0,0.06,1.1)))
		await frames(10)
		check(mode+": uses the Void body health",charger._health_node()==game.health)
		check(mode+": rectangular real input cap",charger.get_node("Charge/Button/ButtonMesh").mesh is BoxMesh)
		check(mode+": rigid supply reaches Trace NE overhead socket",charger.get_node("HardwareSupply").get_meta("grid_socket").is_equal_approx(Vector3(5,-19.2,-5.5)))
		var support := ray(charger.to_global(Vector3(0.48,1.4,0.7)),charger.to_global(Vector3(0.48,1.4,-0.25)))
		var wall: Node3D=game.building.content.props["4/trace-unfinished-wall"]
		check(mode+": charger is supported by the existing wall",not support.is_empty() and (wall==support.collider or wall.is_ancestor_of(support.collider)))
		game.health.set_health(60)
		await frames(25)
		check(mode+": proximity alone does not heal",is_equal_approx(game.health.get_health(),60))
		await hold(charger.charge_button,true)
		await frames(90)
		check(mode+": held input charges progressively",game.health.get_health()>65 and game.health.get_health()<90)
		if not use_xr and "--capture" in OS.get_cmdline_user_args():
			await photograph("charging.png",charger.to_global(Vector3(0,1.65,1.6)),charger.to_global(Vector3(0,1.5,0)))
		await hold(charger.charge_button,false)
		var before: float=game.health.get_health()
		await frames(30)
		check(mode+": release stops charging",is_equal_approx(before,game.health.get_health()))
		await hold(charger.isolation_button,true)
		await hold(charger.isolation_button,false)
		check(mode+": mains button switches supply off",not charger.powered)
		await hold(charger.charge_button,true)
		await frames(40)
		check(mode+": isolated charger cannot heal",is_equal_approx(before,game.health.get_health()))
		await hold(charger.charge_button,false)
		await hold(charger.isolation_button,true)
		await hold(charger.isolation_button,false)
		check(mode+": mains can reconnect",charger.powered)
		game.place_player(charger.to_global(Vector3(0,0.06,3.0)))
		await hold(charger.charge_button,true)
		await frames(40)
		check(mode+": remote input cannot charge across the room",is_equal_approx(before,game.health.get_health()))
		await hold(charger.charge_button,false)
		game.place_player(charger.to_global(Vector3(0,0.06,1.1)))
		await frames(10)
		game.health.apply_bite_damage(20)
		await hold(charger.charge_button,true)
		await frames(45)
		check(mode+": existing health recovery clears bite blur",is_zero_approx(game.health.sight_impairment))
		await frames(450)
		check(mode+": health caps at 100",is_equal_approx(game.health.get_health(),100))
		await hold(charger.charge_button,false)
		check(mode+": readout reports full",charger._face().contains("FULL"))
		if not use_xr and "--capture" in OS.get_cmdline_user_args():
			await photograph("wall-connection.png",charger.to_global(Vector3(2.1,2.3,3.5)),charger.to_global(Vector3(0,2.15,0)))
			game.place_player(Vector3(-4,-23.94,4.5)); await frames(30)
			await photograph("trace-context.png",Vector3(7.7,-21.8,-1.3),Vector3(3.4,-22.5,-5.3))
		game.queue_free()
		await frames(5)
		if use_xr:
			for item in [head,left,right]: XRServer.remove_tracker(item)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual Void scene, desktop input and synthetic XR controller ray/trigger through the museum rig. No physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)

func hold(button: Node3D, value: bool) -> void:
	var target := button.to_global(Vector3(0,0.024,0))
	if xr:
		var origin: Node3D=game.get_node("XROrigin3D")
		# Keep the simulated hand aimed while XRTools settles the body after
		# relocation. A frozen tracking pose otherwise misses the small cap.
		for i in range(20):
			var from: Vector3=game.camera.global_position+Vector3(0,-0.3,-0.1)
			var pose := Transform3D(Basis.IDENTITY,origin.to_local(from)).looking_at(origin.to_local(target),Vector3.UP)
			right.set_pose("aim",pose,Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
			await frames(1)
		if value: check("XR ray reaches "+str(button.get_parent().name),game.pointers[1].last_target==button)
		right.set_input("trigger_click",value)
	else:
		game.camera.look_at(target)
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		await frames(8)
		var event := InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=value
		Input.parse_input_event(event)
	await frames(5)

func photograph(filename: String, at: Vector3, target: Vector3, mask: int=1048575) -> void:
	# Use a separate documentary camera; the player stays at the live charger.
	var camera := Camera3D.new()
	camera.cull_mask=mask
	game.add_child(camera)
	camera.global_position=at
	camera.look_at(target)
	camera.current=true
	if game.desktop_help != null: game.desktop_help.hide()
	game.notice_time=0
	await frames(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(filename))
	camera.queue_free()
	game.camera.current=true
	await frames(2)
