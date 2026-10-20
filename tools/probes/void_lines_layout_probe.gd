extends "res://tools/probes/void_triangle_probe.gd"
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	await start(false)
	if "--void-start-floor=3" in OS.get_cmdline_user_args():
		check("Direct floor start uses the authored enclosure spawn",absf(game.body.global_position.x)<.05 and game.body.global_position.z>6 and game.checkpoint==3)
	game.place_player(Vector3(0,-17.94,6.9));await frames(35)
	var setting: Node3D=game.building.content.exhibits["3/setting_out"].get_node("Artifact")
	var plan: Node3D=setting.get_node("FloorPlanTable")
	plan.local_positions[0]=Vector3(-1,1.06,0)
	plan.local_positions[1]=Vector3(1.5,1.06,.4)
	await frames(20)
	var before: float=plan.measured_length
	setting.apply_grid_config({"parts":{"FloorPlanTable":{"position":[16.2,0,-2.7],"rotation":[0,90,0]}}})
	await frames(30)
	print("[probe] measure=",plan.measured_length," local=",plan.point_a.position.distance_to(plan.point_b.position)*10," active=",plan.can_process()," global=",plan.point_a.global_position.distance_to(plan.point_b.global_position)*10)
	check("Editor rotation preserves measurement after physics settles",absf(plan.measured_length-before)<.02)
	setting.apply_grid_config({"parts":{"FloorPlanTable":{"position":[16.5,0,-2.7],"rotation":[0,0,0]}}})
	var gate: Node3D=setting.get_node("MeasurementRoom")
	gate.armed=true;gate.point_b.global_position=gate.point_a.global_position+Vector3(.18,0,0)
	PhysicsServer3D.body_set_state(gate.point_b.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,gate.point_b.global_transform)
	await frames(120)
	check("Desktop body can pass the opened gate",gate.unlocked and await move_to(Vector3(0,-18,.3)))
	var ok := true
	for stop in game.building.content.data.floors[3].route.slice(4):
		if not await move_to(Vector3(stop.position[0],-18,stop.position[1])):
			print("[probe] blocked: ",stop.label)
			var p: Vector3=game.body.global_position
			for y in [.1,.5,1.0,1.5]:
				var result:=ray(p+Vector3(0,y,0),Vector3(stop.position[0],p.y+y,stop.position[1]))
				if not result.is_empty(): print("[probe] obstruction at ",y,": ",result.collider.get_path())
			ok=false;break
	check("Desktop route traverses all four encounters",ok and game.deaths==0)
	FileAccess.open(out.path_join("desktop-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks},"\t"))
	# A direct floor start requests the neighbouring Trace scenes in the
	# background. Drain those requests before exiting the short headless test.
	var deadline := Time.get_ticks_msec()+15000
	while not game.building.content.pending.is_empty() and Time.get_ticks_msec()<deadline:
		OS.delay_msec(5)
		await frames(1)
	# Give the background resource workers an actual scheduling interval, not
	# only the accelerated fixed-fps clock used by this headless traversal.
	OS.delay_msec(200)
	await frames(2)
	game.queue_free();await frames(20)
	quit(0 if failed.is_empty() else 1)
