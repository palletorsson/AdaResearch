extends "res://tools/probes/transformation_encounters.gd"
var source_origin: Vector3
func at(p: Vector3) -> Vector3: return source_origin+hall.global_basis*p
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(.8).timeout
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var wardrobe=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
	for child in museum.get_children():
		if child is Node3D and child.has_meta("em_map") and child!=hall:child.hide()
	var inventory: Array=[]
	for rec in museum.get("_edit_records"):
		var node=rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node):
			inventory.append({"token":rec.get("token",""),"position":xyz(hall.to_local(node.global_position))})
			if str(rec.get("token","")).begins_with("force_play_springs"):
				source_origin=node.global_position-hall.global_basis*Vector3(15.5,0,11.5)
	observations.inventory=inventory;observations.source_origin=xyz(source_origin)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=82
	camera.global_position=at(Vector3(15,78,36));camera.look_at(at(Vector3(15,0,36)),Vector3.FORWARD);camera.current=true
	await create_timer(.5).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"overhead.png"))
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	await snapshot("raised",at(Vector3(-5,21,17)),at(Vector3(15,.8,24)),70)
	await snapshot("bay",at(Vector3(8.5,2.2,24.5)),at(Vector3(8.5,1.5,20.5)),85)
	var work:=find_scene("/pendulum_noise/PendulumNoise.gd")
	if work!=null:await experiment_checks(work)
	observations.scope="Native desktop museum, supplied controller poses; no physical headset test."

func experiment_checks(work: Node3D) -> void:
	work.set_process(false);work.set_physics_process(false)
	work.act("RESET");work.draw_state()
	await snapshot("comparison",work.to_global(Vector3(0,2.25,5)),work.to_global(Vector3(0,1.55,0)),76)
	for i in 2400:work.model.step()
	work.draw_state();work.draw_records()
	observations.off_on=work.model.history.duplicate(true)
	await snapshot("off-on-record",work.to_global(Vector3(0,4.1,2.4)),work.to_global(Vector3(0,.6,-.9)),85)
	work.act("MODE")
	for i in 2400:work.model.step()
	work.draw_state();work.draw_records()
	observations.damping={"peak":work.model.peak,"settled_at":[work.model.settled_at(0),work.model.settled_at(1)]}
	await snapshot("same-input",work.to_global(Vector3(0,2.25,5)),work.to_global(Vector3(0,1.55,0)),76)
	work.act("RESET")
	await interaction_checks(work)

func interaction_checks(work: Node3D) -> void:
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var clearance:=true;var samples:=0
	for path in [[Vector3(28.5,0,18.5),Vector3(28.5,0,36)], [Vector3(28.5,0,20.5),Vector3(11.4,0,20.5)]]:
		var a:Vector3=path[0];var b:Vector3=path[1];var n:=ceili(a.distance_to(b)/.2)
		for i in range(n+1):
			var foot:=at(a.lerp(b,float(i)/n));var q:=PhysicsShapeQueryParameters3D.new()
			q.shape=shape;q.collision_mask=1|4;q.transform.origin=foot+Vector3.UP*.88
			var hits:=hall.get_world_3d().direct_space_state.intersect_shape(q,4)
			var floor:=floor_at(foot)
			clearance=clearance and hits.is_empty() and not floor.is_empty() and absf(floor.position.y-foot.y)<.04
			if not hits.is_empty():observations["blocked_"+str(foot)]=str(hits[0].collider.get_path())
			samples+=1
	check("comparison approach and east bypass have capsule clearance and floor",clearance)
	observations.route_samples=samples
	var approach:=work.to_global(Vector3(0,0,2.8))
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	for id in ["RUN / PAUSE","REPLAY","MODE","NEXT SEED","RESET"]:
		var response:Dictionary=await driver.press(work.buttons[id],approach)
		var valid:=false
		match id:
			"RUN / PAUSE":valid=work.running
			"REPLAY":valid=work.running and work.model.tick==0
			"MODE":valid=work.model.compare_damping and not work.running
			"NEXT SEED":valid=work.model.noise_seed==1848
			"RESET":valid=work.model.noise_seed==1847 and not work.model.compare_damping
		check("desktop pointer operates "+id,valid);observations["pointer_"+id]=response
	driver.teardown();driver.queue_free();await tick()
	var origin:=XROrigin3D.new();root.add_child(origin)
	var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	var point=work.points[0];controller.global_transform=point.global_transform;point.pick_up(pickup)
	await tick();await tick()
	controller.global_position+=work.global_basis*Vector3(-.55,.12,.8)
	for i in 6:await tick()
	work.draw_state()
	check("real held point changes common release angle",point.is_picked_up() and absf(work.model.initial_angle-.6)>.1 and work.model.angle[0]==work.model.angle[1])
	var pivot_world:=work.to_global(work.anchor(0))
	check("grabbed point remains on1.1m rod despite depth movement",absf(point.global_position.distance_to(pivot_world)-1.1)<.0001 and absf(work.to_local(point.global_position).z)<.0001)
	check("one active hand prevents conflicting second release",not work.points[1].enabled and work.held_lane==0)
	point.let_go(pickup,Vector3(30,20,10),Vector3.ONE*5);await tick();await tick()
	check("release runs both models with zero throwing speed",work.running and work.held_lane==-1 and work.model.omega[0]==0 and work.model.omega[1]==0)
	observations.hand_release_angle=work.model.initial_angle
	work.act("RESET")
	for id in ["force","drag"]:
		var joint:Node3D=work.sliders[id].get_node("SliderOrigin/InteractableSlider")
		var handle=joint.get_node("HandleOrigin/InteractableHandle")
		controller.global_transform=handle.global_transform;handle.pick_up(pickup);await tick();await tick()
		controller.global_position+=joint.global_basis.x*.1
		for i in 6:await tick()
		check("held "+id+" slider changes the real comparison",work.model.sigma_n>3 if id=="force" else (work.model.changed_drag>1.4 and work.model.compare_damping))
		handle.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	origin.queue_free();await tick()
	work.act("RESET")
	# Advance through force-on to expose current force arrows, without changing the clock.
	for i in 120:work.model.step()
	work.draw_state();work.draw_records()
	check("displayed positions agree with model in rotated hall",work.points[0].global_position.distance_to(work.bob_world(0))<.0001 and work.points[1].global_position.distance_to(work.bob_world(1))<.0001)
	await snapshot("in-motion",work.to_global(Vector3(0,1.65,4.8)),work.to_global(Vector3(0,1.6,0)),80)
	await snapshot("controls",work.to_global(Vector3(0,1.65,2.9)),work.to_global(Vector3(0,1.1,1.75)),76)
	observations.final_receipt=work.log_entries[-1]
