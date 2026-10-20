extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(.6).timeout
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	for child in museum.get_children():
		if child is Node3D and child.has_meta("em_map") and child!=hall:child.hide()
	var work:=find_scene("/monte_carlo_dartboard.gd")
	check("original dartboard exists",work!=null)
	if work==null:return
	check("selected hall enables sample budget",work.sample_budget and work.sample_console!=null)
	if work.sample_console==null:return
	observations.position=xyz(work.global_position)
	observations.root_y=work.global_position.y
	await snapshot("visitor",work.to_global(Vector3(0,1.27,3.5)),work.to_global(Vector3(.25,1.0,.3)),65)
	await snapshot("raised",work.to_global(Vector3(3,5,5)),work.to_global(Vector3(0,.7,.3)),65)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=29
	var centre:Vector3=work.global_position+hall.global_basis*Vector3(3,0,0)
	camera.global_position=centre+Vector3(0,34,0);camera.look_at(centre,Vector3.FORWARD)
	camera.current=true;await create_timer(.4).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"overhead.png"))
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	await interaction_checks(work)

func interaction_checks(work:Node3D)->void:
	var panel:Node3D=work.sample_console
	check("prepared run keeps 100 real samples",work._total_count==100 and work.sample_run.points.size()==100)
	check("sampler and board counts agree",work._inside_count==work.sample_run.inside)
	check("exactly one physical budget console",work.find_children("SampleBudgetConsole*","Node3D",true,false).size()==1)
	check("one budget panel replaces original controls",panel.buttons.size()==6 and work.find_children("*","Node3D",true,false).filter(func(n):return n.has_meta("panel_w")).is_empty())
	var approach:Vector3=work.to_global(Vector3(0,0,1.85))
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	for id in ["REPLAY","THROW","+100","FILL","8 SEEDS","NEXT SEED"]:
		var response:Dictionary=await driver.press(panel.buttons[id],approach)
		await tick();await tick()
		var ok:=false
		match id:
			"REPLAY":ok=work._total_count==0
			"THROW":ok=work._total_count==1
			"+100":ok=work._total_count==101
			"FILL":ok=work._total_count==500 and work._dart_meshes.size()==300
			"8 SEEDS":ok=panel.comparison_rows.size()==8 and work._total_count==500
			"NEXT SEED":ok=work.dart_seed==1848 and work._total_count==0
		check("real desktop pointer operates "+id,ok);observations["pointer_"+id]=response
		if id=="8 SEEDS":
			observations.seeds=panel.comparison_rows.duplicate(true)
			await snapshot("seed-comparison",work.to_global(Vector3(.65,1.65,2.35)),work.to_global(Vector3(.65,1.15,.02)),60)
	driver.teardown();driver.queue_free();await tick()
	var joint:Node3D=panel.effect_dial.get_node("DialOrigin/InteractableHinge")
	var handle=joint.get_node("Handles/Handle1/InteractableHandle")
	check("four native dial detents without physics scaling",joint.hinge_steps==90.0 and panel.effect_dial.scale==Vector3.ONE)
	var origin:=XROrigin3D.new();root.add_child(origin)
	var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_transform=handle.global_transform;handle.pick_up(pickup);await tick();await tick()
	var offset:Vector3=controller.global_position-joint.global_position
	controller.global_position=joint.global_position+offset.rotated(joint.global_basis.x.normalized(),1.6)
	for i in 8:await tick()
	check("held dial changes actual budget and replays",handle.is_picked_up() and work.max_darts!=500 and work._total_count==0)
	handle.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("budget dial releases",not handle.is_picked_up())
	origin.queue_free();await tick()
	work.max_darts=8000;work.dart_seed=1847;work.budget_replay();work.budget_add(8000);await tick()
	check("8000 samples retain all counts and only 300 marks",work._total_count==8000 and work.sample_run.points.size()==8000 and work._dart_meshes.size()==300 and work._inside_count==work.sample_run.inside)
	var saved:Array[Vector2]=work.sample_run.points.duplicate()
	work.budget_replay();work.budget_add(8000);await tick()
	check("installed replay recovers every sampled point",work.sample_run.points==saved)
	panel.act("8 SEEDS");await tick()
	check("readout declares retained and visible counts",panel.screen_state.text.contains("8000 COUNTED / NEWEST 300"))
	await snapshot("controls",work.to_global(Vector3(.1,1.65,2.25)),panel.to_global(Vector3(0,1,0)),65)
	await snapshot("budget-8000",work.to_global(Vector3(.6,1.65,2.6)),work.to_global(Vector3(.55,1.1,0)),65)
	var shape:=CapsuleShape3D.new();shape.radius=.25;shape.height=1.65
	var clear:=true;var count:=0
	for pair in [[Vector3(0,0,3.7),Vector3(0,0,1.85)],[Vector3(-1.6,0,3.7),Vector3(-1.6,0,-1.0)]]:
		for i in 25:
			var p:Vector3=work.to_global(pair[0].lerp(pair[1],float(i)/24))
			var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.collision_mask=1|4;q.transform.origin=p+Vector3.UP*.86
			var hits:=hall.get_world_3d().direct_space_state.intersect_shape(q,4)
			var floor:=floor_at(p)
			clear=clear and hits.is_empty() and not floor.is_empty() and absf(floor.position.y-p.y)<.04;count+=1
			if not hits.is_empty():observations["blocked "+str(p)]=str(hits[0].collider.get_path())
	check("approach and side bypass remain supported and clear",clear);observations.route_samples=count
	work.max_darts=500;work.budget_replay();work.budget_add(100);panel.comparison_rows.clear();panel.refresh()
