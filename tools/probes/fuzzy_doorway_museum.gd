extends "res://tools/probes/fuzzy_body_museum.gd"

func landing_checks() -> void:
	await super.landing_checks()
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	var work:=find_scene("/fuzzy_doorway/fuzzy_doorway.gd")
	check("doorway instantiated by actual museum",work!=null)
	if work==null:return
	var source:PackedVector3Array=work.original.duplicate()
	check("one retained fourteen-rib source",source.size()==14*33*8)
	check("far visitor activates rest only",work.evaluate(9,2).is_equal_approx(Vector3(0,0,1)))
	check("near stationary visitor opens",work.evaluate(.5,0).is_equal_approx(Vector3(1,0,0)))
	check("near fast approach curls",work.evaluate(.5,3).is_equal_approx(Vector3(0,1,0)))
	# Independent smoothstep arithmetic at the midpoint of the declared pace band.
	var midpoint:float=work.pace*.95
	check("mid-band speed blends two active rules",work.evaluate(.5,midpoint).is_equal_approx(Vector3(.5,.5,0)))
	check("weighted consequent normalizes competing rules",work.consequent(Vector3(.3,.3,.2)).is_equal_approx(Vector2(.375,.375)))
	check("distance is symmetric through the doorway",is_equal_approx(work.gate_distance(Vector3(0,9,2)),work.gate_distance(Vector3(0,-8,-2))))
	check("outside opening adds lateral distance",work.gate_distance(Vector3(4,0,0))>2.5)
	check("capture camera is never selected as visitor",work.choose_visitor()==museum.get("_player") and work.choose_visitor()!=camera)
	work.set_physics_process(false);work.have_previous=false
	work.observe(work.to_global(Vector3(0,0,3)),.1)
	check("arrival initializes derivative without invented speed",work.raw_speed==0)
	work.observe(work.to_global(Vector3(0,0,2.8)),.1)
	check("approach speed measured from world movement",absf(work.raw_speed-2)<.001)
	work.observe(work.to_global(Vector3(0,0,3.0)),.1)
	check("retreat is not a fast approach",work.raw_speed==0)
	var jumps:int=work.reset_jumps;work.observe(work.to_global(Vector3(0,0,10)),.016)
	check("teleport resets derivative instead of claiming a sprint",work.raw_speed==0 and work.speed==0 and work.reset_jumps==jumps+1)
	var bounded:=true;var clear_geometry:=true;var topology:=true
	for open in [0.0,.5,1.0]:
		for curl in [0.0,.5,1.0]:
			work.pose=Vector2(open,curl);work.draw_ribs();topology=topology and work.vertices.size()==source.size()
			for p in work.vertices:
				bounded=bounded and p.is_finite() and absf(p.x)<3.5 and p.y<4.7 and absf(p.z)<2.6
				if p.y>=0 and p.y<2.3:clear_geometry=clear_geometry and absf(p.x)>.85
	check("all sampled rib extremes remain finite and in envelope",bounded)
	check("visual ribs stay outside centre walking clearance",clear_geometry)
	check("deformation preserves topology and original",topology and work.original==source)
	work.pose=Vector2.ZERO;work.draw_ribs();check("rest regenerates exact retained source",work.vertices==source)
	work.set_physics_process(true);work.reset()
	# Move the real museum CharacterBody through its collision solver at two
	# controlled speeds. No substitute sensor and no renderer-camera input.
	var body:CharacterBody3D=museum.get("_player")
	var samples:Array=[]
	for v in [.3,2.6]:
		body.global_position=work.to_global(Vector3(0,.02,1.6));body.velocity=Vector3.ZERO
		work.select_mode(0);await tick();await tick()
		for i in 24:
			await physics_frame
			body.velocity=work.global_basis*Vector3(0,-.15,-v);body.move_and_slide()
		await process_frame
		samples.append({"speed":work.speed,"raw":work.raw_speed,"weights":xyz(work.weights),"target":[work.target.x,work.target.y]})
		check("actual museum body drives "+str(v)+"m/s",absf(work.speed-v)<.35 and work.visitor==body and work.source_kind=="MUSEUM BODY")
	check("slow walk favours opening",samples[0].weights[0]>samples[0].weights[1])
	check("fast walk favours curling",samples[1].weights[1]>samples[1].weights[0])
	observations.doorway_walks=samples
	body.global_position=work.to_global(Vector3(0,.02,3.0));work.select_mode(0)
	var start:Vector3=body.global_position
	for i in 150:
		await physics_frame;body.velocity=work.global_basis*Vector3(0,-.15,-2.5);body.move_and_slide()
	check("real body passes through live ribs",work.to_local(body.global_position).z<-2.8 and absf(work.to_local(body.global_position).x)<.1)
	check("crossing stays on museum floor",absf(body.global_position.y-map_origin.y)<.08)
	observations.doorway_crossing={"from":xyz(start),"to":xyz(body.global_position)}
	body.global_position=Vector3(0,-100,0)
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver)
	var stand:Vector3=work.to_global(Vector3(-3.8,0,4.3));driver.spawn(stand,museum)
	var lamp=driver.rig.get_node("Head/PlayerHeldLight");lamp._restore_environment();lamp.darken_environment=false;lamp._light.hide();lamp.set_process(false)
	await tick()
	for i in 3:
		var id:String=["LIVE","DEMO SLOW","DEMO FAST"][i]
		observations["doorway_pointer_"+id]=await driver.press(work.panel.buttons[id],stand)
		await create_timer(.2).timeout
		check("pointer selects doorway "+id,work.mode==i)
		if i>0:check("demonstration identifies itself "+str(i),work.source_kind=="DEMO INPUT")
	work.reach=6;work.pace=2;work.sync_controls()
	await driver.press(work.panel.buttons["SWAP RULES"],stand);await create_timer(.2).timeout
	check("pointer reverses the authored response",work.reversed_rules and work.evaluate(.5,8).is_equal_approx(Vector3(1,0,0)))
	check("rule board exposes the changed mapping",work.labels[0].text.begins_with("NEAR + FAST / OPEN"))
	await driver.press(work.panel.buttons["RESET"],stand);await tick()
	check("native reset restores definitions and live mode",work.mode==0 and work.reach==4 and is_equal_approx(work.pace,1.2) and not work.reversed_rules)
	driver.teardown();driver.queue_free();await tick()
	var origin:=XROrigin3D.new();origin.name="DoorwayTestOrigin";root.add_child(origin);origin.current=true
	var eye:=XRCamera3D.new();origin.add_child(eye)
	museum.set("_force_vr",true);museum.set("_vr_cam",null)
	eye.global_position=work.to_global(Vector3(0,1.65,2));work.select_mode(0);await tick();await tick()
	check("live VR input resolves the museum XR eye",work.visitor==eye and work.source_kind=="XR HEAD")
	for i in 18:
		await physics_frame;eye.global_position-=work.global_basis.z*.02
	check("tracked-eye translation reaches the live rules",work.speed>.5 and work.sample_distance<1.8)
	museum.set("_force_vr",false);museum.set("_vr_cam",null);work.select_mode(0)
	var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	for pair in [[work.panel.reach_dial,"reach"],[work.panel.pace_dial,"pace"]]:
		var control:Node3D=pair[0];var key:String=pair[1];var before:float=work.get(key)
		var hinge:Node3D=control.get_node("DialOrigin/InteractableHinge");var knob=hinge.get_node("Handles/Handle1/InteractableHandle")
		controller.global_transform=knob.global_transform;knob.pick_up(pickup);await tick();await tick()
		controller.global_position=hinge.global_position+(controller.global_position-hinge.global_position).rotated(hinge.global_basis.x.normalized(),-.65)
		for i in 6:await tick()
		check("XRTools grip changes doorway "+key,knob.is_picked_up() and absf(float(work.get(key))-before)>.04)
		knob.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	origin.queue_free();work.reset()
	var shape:=CapsuleShape3D.new();shape.radius=.25;shape.height=1.7
	var route:Array[Vector3]=[Vector3(13,0,46),Vector3(12.3,0,48.9),Vector3(10.5,0,48.9),Vector3(8.5,0,49),Vector3(8.5,0,57.8),Vector3(18.5,0,57.8),Vector3(18.5,0,61.3)]
	var clear:=true;var n:=0;var blocked:Array=[]
	for i in range(route.size()-1):
		var count:=ceili(route[i].distance_to(route[i+1])/.15)
		for k in range(count+1):
			var p:=route[i].lerp(route[i+1],float(k)/count);var ok:=supported_clear(p,shape)
			clear=clear and ok;n+=1
			if not ok and blocked.size()<10:blocked.append(xyz(p))
	check("sphere to doorway controls and onward exit has clear supported route",clear)
	observations.doorway_route_samples=n;observations.doorway_blocked=blocked
	var shot:Vector3=work.to_global(Vector3(-6.8,3.1,9));var aim:Vector3=work.to_global(Vector3(0,2.5,.1))
	for mode in [0,1,2]:
		work.select_mode(mode);await create_timer(1.5).timeout
		await snapshot(["doorway-rest","doorway-slow","doorway-fast"][mode],shot,aim,60)
		observations["doorway_pose_"+str(mode)]={"pose":[work.pose.x,work.pose.y],"weights":xyz(work.weights),"source":work.source_kind}
	work.swap_rules();await create_timer(1.5).timeout
	await snapshot("doorway-fast-reversed",shot,aim,60)
	work.swap_rules()
	work.select_mode(1);await create_timer(1).timeout
	await snapshot("doorway-inside",work.to_global(Vector3(0,1.65,1.0)),work.to_global(Vector3(0,2.2,-3)),78)
	await snapshot("doorway-console",work.to_global(Vector3(-3.8,1.75,4.55)),work.panel.face.global_position,62)
	await snapshot("doorway-rules",work.to_global(Vector3(3.85,2.4,5.2)),work.rule_board.global_position+Vector3.UP*.35,52)
	await snapshot("doorway-sequence",at(Vector3(17,5,34)),at(Vector3(10,2.5,48)),70)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=41
	camera.global_position=at(Vector3(18,48,46));camera.look_at(at(Vector3(18,0,46)),Vector3.FORWARD);camera.current=true
	await create_timer(.4).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"doorway-above.png"))
	observations.doorway_scope="Installed actual museum. Museum CharacterBody moved using move_and_slide at scripted velocities; XR eye/controller poses simulated. Native pointer controls. No physical headset or Quest frame-time claim. Moving geometry has no collision; floor/supports fixed."
