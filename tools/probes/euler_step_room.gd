extends "res://tools/probes/transformation_encounters.gd"
var source_origin := Vector3.ZERO
func at(p: Vector3) -> Vector3: return source_origin+hall.global_basis*p
func landing_checks() -> void:
	museum.call("flush_stamps"); await create_timer(.8).timeout
	var player=museum.get("_player")
	if player is Node3D: player.hide(); player.set_process(false); player.set_physics_process(false); player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var wardrobe=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")): wardrobe.get("costume").hide()
	for child in museum.get_children():
		if child is Node3D and child.has_meta("em_map") and child!=hall: child.hide()
	var inventory: Array=[]
	for rec in museum.get("_edit_records"):
		var node=rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node):
			inventory.append({"token":rec.get("token",""),"position":xyz(hall.to_local(node.global_position))})
			if str(rec.get("token","")).begins_with("launch_arc"):
				source_origin=node.global_position-hall.global_basis*Vector3(14.5,0,8.5)
	observations.inventory=inventory; observations.source_origin=xyz(source_origin)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=49
	camera.global_position=at(Vector3(22,60,43)); camera.look_at(at(Vector3(22,0,43)),Vector3.FORWARD); camera.current=true
	await create_timer(.5).timeout; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"overhead.png"))
	camera.size=29;camera.global_position=at(Vector3(21,40,12));camera.look_at(at(Vector3(21,0,12)),Vector3.FORWARD)
	await create_timer(.5).timeout; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"front-overhead.png"))
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	await snapshot("bay",at(Vector3(25,1.65,5)),at(Vector3(29,1.7,6.5)),80)
	await snapshot("raised",at(Vector3(24,10,19)),at(Vector3(23,1.3,7)),76)
	var work:=find_scene("/euler_drift/step_study.gd")
	if work!=null: await experiment(work)
	observations.scope="Existing launch museum; tracked headset not tested."

func experiment(work: Node3D) -> void:
	work.set_physics_process(false)
	for n in [10,20,40]:
		work.model.choose_steps(n);work.restart(false);work.sync_slider();work.model.advance(1);work._physics_process(0)
		check("museum signed difference "+str(n),absf(work.model.difference().y-4.9/n)<.00002)
		observations["steps_"+str(n)]=work.model.snapshot()
		await snapshot("steps-"+str(n),work.to_global(Vector3(0,2.15,4.6)),work.to_global(Vector3(0,2.05,0)),65)
		check("rendered points retain endpoint "+str(n),work.points[1].global_position.distance_to(work.to_global(work.display(work.model.position,1)))<.0001 and work.points[0].global_position.distance_to(work.to_global(work.display(work.model.reference_at(1),0)))<.0001)
	await snapshot("comparison",work.to_global(Vector3(-3,2.15,4.6)),work.to_global(Vector3(0,2.05,0)),65)
	work.act("RESET");work._physics_process(0)
	var approach:=work.to_global(Vector3(0,0,2.35))
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	for id in ["ONE STEP","FIRE / PAUSE","REPLAY","OTHER THROW","RESET"]:
		observations["pointer_"+id]=await driver.press(work.buttons[id],approach)
		var ok:=false
		match id:
			"ONE STEP":ok=work.model.tick==1 and not work.running
			"FIRE / PAUSE":ok=work.running
			"REPLAY":ok=work.running and work.model.tick==0
			"OTHER THROW":ok=work.model.initial_velocity.x==3 and not work.running
			"RESET":ok=work.model.count==10 and work.model.initial_velocity.x==4
		check("pointer operates "+id,ok)
	driver.teardown();driver.queue_free();await tick()
	var origin:=XROrigin3D.new();root.add_child(origin)
	var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	var joint:Node3D=work.slider.get_node("SliderOrigin/InteractableSlider")
	var handle=joint.get_node("HandleOrigin/InteractableHandle")
	controller.global_transform=handle.global_transform;handle.pick_up(pickup);await tick();await tick()
	controller.global_position+=joint.global_basis.x*.25
	for i in 6:await tick()
	check("held slider selects forty steps",work.model.count==40 and not work.running and work.model.tick==0)
	handle.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick();origin.queue_free();await tick()
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var clear:=true;var samples:=0
	for path in [[Vector3(22.5,0,3.5),Vector3(29.5,0,3.5)],[Vector3(29.5,0,3.5),Vector3(29.5,0,4.15)]]:
		var a:Vector3=path[0];var b:Vector3=path[1];var n:=ceili(a.distance_to(b)/.15)
		for i in range(n+1):
			var foot:=at(a.lerp(b,float(i)/n));var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.collision_mask=1|4;q.transform.origin=foot+Vector3.UP*.88
			var hits:=hall.get_world_3d().direct_space_state.intersect_shape(q,4);var floor:=floor_at(foot)
			clear=clear and hits.is_empty() and not floor.is_empty() and absf(floor.position.y-foot.y)<.04;samples+=1
			if not hits.is_empty():observations["blocked_"+str(foot)]=str(hits[0].collider.get_path())
	check("entry to panel supported capsule route",clear);observations.route_samples=samples
	work.act("RESET");work._physics_process(0)
	await snapshot("controls",work.to_global(Vector3(0,1.65,2.7)),work.to_global(Vector3(0,.85,1.25)),74)
	work.act("REPLAY");work._physics_process(1)
	check("both carried points visible at calculated position",work.points[1].global_position.distance_to(work.to_global(work.display(work.model.position,1)))<.0001)
