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
			if str(rec.get("token","")).begins_with("ant_colony_optimization"):
				source_origin=node.global_position-hall.global_basis*Vector3(4.5,0,4.5)
	observations.inventory=inventory; observations.source_origin=xyz(source_origin)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=18
	camera.global_position=at(Vector3(6.5,22,5)); camera.look_at(at(Vector3(6.5,0,5)),Vector3.FORWARD); camera.current=true
	await create_timer(.5).timeout; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"overhead.png"))
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	await snapshot("raised",at(Vector3(11,7.5,9)),at(Vector3(6,1,4)),80)
	await snapshot("bay",at(Vector3(8.5,1.7,6.8)),at(Vector3(8.5,1.6,1.5)),78)
	var work:=find_scene("/navigator_noise/NavigatorNoise.gd")
	if work!=null: await experiment_checks(work)
	observations.scope="Existing museum; no physical headset test."

func experiment_checks(work: Node3D) -> void:
	work.set_process(false); work.set_physics_process(false); work.act("RESET"); work.draw_state(); work.draw_trace()
	await snapshot("comparison",work.to_global(Vector3(0,2.3,3.2)),work.to_global(Vector3(0,2.25,0)),76)
	for i in 400: work.model.step()
	work.draw_state(); work.draw_trace()
	observations.noise={"outcomes":work.model.outcomes.duplicate(),"time":work.model.elapsed.duplicate(),"length":work.model.lengths.duplicate()}
	await snapshot("noise-paths",work.to_global(Vector3(0,2.3,3.2)),work.to_global(Vector3(0,2.25,0)),76)
	work.act("FALLBACK")
	for i in 400: work.model.step()
	work.draw_state(); work.draw_trace()
	observations.hold={"outcomes":work.model.outcomes.duplicate(),"time":work.model.elapsed.duplicate()}
	check("same default dropout record yields contact with HOLD",work.model.outcomes[1]=="CONTACT")
	await snapshot("missing-hold",work.to_global(Vector3(0,2.3,3.2)),work.to_global(Vector3(0,2.25,0)),76)
	work.act("FALLBACK")
	for i in 400: work.model.step()
	work.draw_state(); work.draw_trace()
	observations.stop={"outcomes":work.model.outcomes.duplicate(),"time":work.model.elapsed.duplicate()}
	await snapshot("missing-stop",work.to_global(Vector3(0,2.3,3.2)),work.to_global(Vector3(0,2.25,0)),76)
	work.act("RESET")
	var approach:=work.to_global(Vector3(0,0,2.0))
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new(); museum.add_child(driver); driver.spawn(approach,museum); await create_timer(.2).timeout
	for id in ["RUN / PAUSE","REPLAY","MODE","FALLBACK","NEXT SEED","RESET"]:
		var response:Dictionary=await driver.press(work.buttons[id],approach)
		var valid:=false
		match id:
			"RUN / PAUSE": valid=work.running
			"REPLAY": valid=work.running and work.model.tick==0
			"MODE": valid=work.model.missing_mode and not work.running
			"FALLBACK": valid=work.model.hold_command and work.model.missing_mode
			"NEXT SEED": valid=work.model.sample_seed==1848
			"RESET": valid=work.model.sample_seed==1847 and not work.model.missing_mode
		check("desktop pointer operates "+id,valid); observations["pointer_"+id]=response
	driver.teardown(); driver.queue_free(); await tick()
	var origin:=XROrigin3D.new(); root.add_child(origin)
	var controller:=XRController3D.new(); origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate(); controller.add_child(pickup)
	var point=work.points[0]; controller.global_transform=point.global_transform; point.pick_up(pickup); await tick(); await tick()
	controller.global_position+=work.global_basis*Vector3(.8,.12,.7)
	for i in 6: await tick()
	check("actual held point changes both starts",point.is_picked_up() and absf(work.model.start_y-.12)<.01 and work.model.positions[0]==work.model.positions[1])
	check("hand depth and horizontal motion project to start rail",absf(work.to_local(point.global_position).x+1.65)<.0001 and absf(work.to_local(point.global_position).z-.16)<.0001)
	point.let_go(pickup,Vector3.ONE*30,Vector3.ONE*5); await tick(); await tick()
	check("release starts matched model without throw velocity",work.running and work.model.commands==[Vector2.ZERO,Vector2.ZERO])
	work.act("RESET")
	var joint:Node3D=work.slider.get_node("SliderOrigin/InteractableSlider")
	var handle=joint.get_node("HandleOrigin/InteractableHandle")
	controller.global_transform=handle.global_transform; handle.pick_up(pickup); await tick(); await tick()
	controller.global_position+=joint.global_basis.x*.08
	for i in 6: await tick()
	check("actual held slider changes sigma and pauses",work.model.sigma_m>.65 and not work.running)
	handle.let_go(pickup,Vector3.ZERO,Vector3.ZERO); await tick(); await tick(); origin.queue_free(); await tick()
	var shape:=CapsuleShape3D.new(); shape.radius=.25; shape.height=1.7
	var clear:=true; var samples:=0
	for path in [[Vector3(6.5,0,1.5),Vector3(7.5,0,1.5)],[Vector3(7.5,0,1.5),Vector3(7.5,0,5.5)],[Vector3(7.5,0,5.5),Vector3(3.5,0,5.5)],[Vector3(3.5,0,5.5),Vector3(3.5,0,6.5)]]:
		var a:Vector3=path[0]; var b:Vector3=path[1]; var n:=ceili(a.distance_to(b)/.15)
		for i in range(n+1):
			var foot:=at(a.lerp(b,float(i)/n)); var q:=PhysicsShapeQueryParameters3D.new(); q.shape=shape; q.collision_mask=1|4; q.transform.origin=foot+Vector3.UP*.88
			var hits:=hall.get_world_3d().direct_space_state.intersect_shape(q,4); var floor:=floor_at(foot)
			clear=clear and hits.is_empty() and not floor.is_empty() and absf(floor.position.y-foot.y)<.04; samples+=1
			if not hits.is_empty(): observations["blocked_"+str(foot)]=str(hits[0].collider.get_path())
	check("entry to controls has supported capsule route",clear); observations.route_samples=samples
	work.act("RESET"); work.draw_state(); work.draw_trace()
	check("display points agree with model inside hall",work.points[0].global_position.distance_to(work.agent_world(0))<.0001 and work.points[1].global_position.distance_to(work.agent_world(1))<.0001)
	await snapshot("controls",work.to_global(Vector3(0,1.65,2.15)),work.to_global(Vector3(0,1.0,1.0)),73)
