extends "res://tools/probes/void_transfer_probe.gd"
## Actual ball trajectories and native mouse / synthetic-XR control presses.
var trajectories: Array = []

func run() -> void:
	trial="matter_gates";level=1;take_photos=true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	if "--release-inputs" in OS.get_cmdline_user_args():
		await release_inputs();return
	if "--capture-only" in OS.get_cmdline_user_args():
		await start(false)
		var scene: Node3D=station("and")
		await photo("04-inside-tower-ready",scene.to_global(Vector3(0,3.1,7)),scene.to_global(Vector3(0,1.7,-.5)))
		await photo("05-at-the-controls",scene.to_global(Vector3(0,1.65,5.3)),scene.to_global(Vector3(0,1.6,1)))
		game.place_player(scene.to_global(Vector3(0,.06,5.3)));await frames(8)
		for i in 2:await press(scene.buttons[i].get_node("PushButton"))
		await press(scene.buttons[2].get_node("PushButton"))
		for i in 1050:
			await frames(1)
			if scene.outcome>=0:break
		check("final lit standard-floor assembly still receives the ball",scene.outcome==1)
		await photo("06-inside-tower-both-filled",scene.to_global(Vector3(2,2.65,6.8)),scene.to_global(Vector3(0,1.2,-.5)))
		var fragment: Node3D=load("res://commons/artifacts/matter_gates/matter_and.tscn").instantiate()
		game.add_child(fragment);fragment.position=Vector3(16,-6,4)
		fragment.apply_grid_config({"only_parts":["InputX"],"parts":{"InputX":{"position":[0,0,0],"rotation":[0,90,0]}}})
		await frames(8)
		check("editor fragment is independent and has only its requested part",fragment.get_child_count()==1 and fragment.has_node("InputX") and fragment.fragment)
		check("editor fragment respects its saved turn",is_equal_approx(fragment.get_node("InputX").rotation_degrees.y,90))
		fragment.queue_free()
		FileAccess.open(out.path_join("capture-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed},"  "))
		quit(0 if failed.is_empty() else 1);return
	for mode in [false,true]:
		await start(mode)
		var label := "Synthetic XR: " if mode else "Desktop: "
		var gate: Node3D=station("and")
		game.place_player(gate.to_global(Vector3(0,.06,5.3)));await frames(20)
		check(label+"standard floor and both open shafts",game.building.spec.width==42 and game.building.spec.depth==18 and [-10,10].all(func(x):return ray(Vector3(x,-5,0),Vector3(x,-6.5,0)).is_empty()))
		check(label+"original wedge instantiated",gate.get_node("EntryWedge/OriginalWP").scene_file_path=="res://commons/scenes/mapobjects/walkableprism.tscn")
		check(label+"original one-metre source cubes",gate.cubes.all(func(c):return c.get_node("OriginalBuildingCube").scene_file_path=="res://commons/artifacts/primitive_encounters/platform_block.tscn" and c.get_node("CubeCollision").shape.size==Vector3.ONE))
		check(label+"original plank body reused",gate.get_node("EntryPlanks/OriginalPlank1").get_script().resource_path=="res://commons/artifacts/line_relations_gallery/line_body.gd")
		check(label+"white gravity source and live pickable ball",gate.supply.get_script().resource_path=="res://commons/artifacts/surface_ball_test/surface_ball_test.gd" and gate.ball.has_method("pick_up") and not gate.ball.freeze and gate.ball.get_node("WhitePoint").material_override.albedo_color==Color.WHITE)
		if not mode:await photo("01-matter-and-ready",gate.to_global(Vector3(9,5.5,10)),gate.to_global(Vector3(0,1.9,0)))
		for value in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1)]:
			await press(gate.buttons[3].get_node("PushButton"))
			check(label+"reset restores both suspended cubes",gate.inputs==Vector2i.ZERO and gate.cubes.all(func(c):return c.freeze and absf(c.position.y-2.8)<.01))
			if value.x==1:await press(gate.buttons[0].get_node("PushButton"))
			if value.y==1:await press(gate.buttons[1].get_node("PushButton"))
			check(label+"real control inputs %s"%str(value),gate.inputs==value)
			await press(gate.buttons[2].get_node("PushButton"))
			check(label+"real release starts observation",gate.waiting or gate.running)
			for i in 1050:
				await frames(1)
				if gate.outcome>=0:break
			var wanted := 1 if value==Vector2i.ONE else 0
			check(label+"physical AND %s observed %d"%[str(value),wanted],gate.outcome==wanted)
			var samples: Array=gate.run_samples.map(func(p):return [p.x,p.y,p.z])
			trajectories.append({"mode":"synthetic_xr" if mode else "desktop","inputs":[value.x,value.y],"observed":gate.outcome,"samples":samples})
			print("MATTER_PATH ",label,value," outcome=",gate.outcome," final=",gate.to_local(gate.ball.global_position)," frames=",samples.size()," cubes=",gate.cubes.map(func(c):return c.position))
			check(label+"released body moved without a prescribed trajectory",samples.size()>10 and Vector3(samples[0][0],samples[0][1],samples[0][2]).distance_to(gate.to_local(gate.ball.global_position))>.3)
			if not mode and value==Vector2i(1,0):await photo("02-one-gap-open",gate.to_global(Vector3(5,2.5,6.5)),gate.to_global(Vector3(0,1,-.5)))
			if not mode and value==Vector2i.ONE:await photo("03-both-cubes-ball-arrives",gate.to_global(Vector3(8,3.8,7)),gate.to_global(Vector3(1.2,1.3,-.5)))
		check(label+"all four observations retained",gate.observations.size()==4 and gate.observations.get("11",-1)==1)
		# Move and turn the complete construction on the same negative floor.
		# New gravity balls are still spawned above the edited release part.
		await press(gate.buttons[3].get_node("PushButton"))
		gate.position+=Vector3(0,0,-1);gate.rotation_degrees.y=12
		gate._sync_bodies(gate)
		gate.reset_gate();gate.set_gate(0,true);gate.set_gate(1,true);gate.release_ball()
		for i in 1050:
			await frames(1)
			if gate.outcome>=0:break
		check(label+"moved / rotated physical assembly still computes AND",gate.outcome==1)
		game.queue_free();await frames(10)
		if mode:
			for item in [head,left,right]:XRServer.remove_tracker(item)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"First Matter AND gate only. Real four-combination physics, desktop mouse and synthetic XR button input; moved/turned assembly. Physical headset not tested."},"  "))
	FileAccess.open(out.path_join("trajectories.json"),FileAccess.WRITE).store_string(JSON.stringify(trajectories))
	print("MATTER_GATES_RESULT ",checks.size()," ",failed)
	quit(0 if failed.is_empty() else 1)

func let_go() -> void:
	if xr:
		right.set_input("grip",0.0);await frames(12)
	else:
		for down in [true,false]:
			var event := InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_RIGHT;event.pressed=down
			Input.parse_input_event(event);await frames(10)

func await_result(gate: Node3D) -> void:
	for i in 1050:
		await frames(1)
		if gate.outcome>=0:return

func release_inputs() -> void:
	for mode in [false,true]:
		await start(mode)
		var gate: Node3D=station("and")
		var label := "Synthetic XR: " if mode else "Desktop: "
		var box: Node3D=gate.ball_box
		box.supply.elapsed=121.0
		await frames(2)
		check(label+"waiting does not expire the retained ball",is_instance_valid(gate.ball) and not box.supply.is_physics_processing())
		await frames(150)
		var home: Vector3=box.to_local(gate.ball.global_position)
		print("BALL_BOX_HOME ",label,home)
		check(label+"unfrozen ball stays inside physical open-top box",not gate.ball.freeze and absf(home.x)<.2 and absf(home.z)<.2 and home.y>-.2 and home.y<.3 and not gate.running)
		if not mode:await photo("07-ball-in-open-box",gate.to_global(Vector3(-3.8,3.2,1.8)),box.to_global(Vector3(0,.08,0)))
		game.place_player(gate.to_global(Vector3(0,.06,5.3)));await frames(8)
		for i in 2:await press(gate.buttons[i].get_node("PushButton"))
		game.place_player(gate.to_global(Vector3(-5.1,.06,1.15)));await frames(20)
		var held_ball: RigidBody3D=gate.ball
		var shape: CollisionShape3D=held_ball.get_child(0)
		if await input_grab(label+"ball / ",held_ball,shape,.6,.16):
			check(label+"holding ball suspends observation",not gate.running)
			await input_tip_to(shape,box.to_global(Vector3(0,.75,0)))
			await input_tip_to(shape,box.to_global(Vector3(.75,.75,0)))
			var drop_at: Vector3=held_ball.global_position
			await let_go()
			check(label+"hand drop enables real gravity and observation",not held_ball.is_picked_up() and not held_ball.freeze and gate.running)
			await await_result(gate)
			print("MANUAL_BALL_RESULT ",label,gate.outcome," drop=",gate.to_local(drop_at)," end=",gate.to_local(held_ball.global_position))
			check(label+"hand-dropped ball traverses supported AND",gate.outcome==1)
			check(label+"manual drop leaves lever closed",not box.opened and box.track.slider_position<.01)
		await press(gate.buttons[3].get_node("PushButton"))
		game.place_player(gate.to_global(Vector3(0,.06,5.3)));await frames(8)
		for i in 2:await press(gate.buttons[i].get_node("PushButton"))
		game.place_player(gate.to_global(Vector3(-4.9,.06,1.2)));await frames(25)
		var handle: Node3D=box.handle
		var grip: CollisionShape3D=handle.get_node("GripCollision")
		var closed: Vector3=grip.global_position
		if await input_grab(label+"lever / ",handle,grip,.5,.06):
			await input_tip_to(grip,closed+Vector3.UP*.5)
			check(label+"upward hand pull raises physical gate",box.track.slider_position>.34 and box.opened)
			await let_go()
			check(label+"released lever stays raised",box.track.slider_position>.34 and not handle.is_picked_up())
			if not mode:await photo("08-lifted-lever",gate.to_global(Vector3(-3.7,3.3,1.8)),box.to_global(Vector3(0,.26,.15)))
			await await_result(gate)
			print("LEVER_BALL_RESULT ",label,gate.outcome," slider=",box.track.slider_position," end=",gate.to_local(gate.ball.global_position))
			check(label+"lever-released ball traverses supported AND",gate.outcome==1)
		game.queue_free();await frames(10)
		if mode:
			for item in [head,left,right]:XRServer.remove_tracker(item)
	FileAccess.open(out.path_join("release-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Real desktop right-click and synthetic XR grip: pick up/drop source ball, pull vertical retained lever. Physical headset not tested."},"  "))
	print("MATTER_RELEASE_RESULT ",checks.size()," ",failed)
	quit(0 if failed.is_empty() else 1)

