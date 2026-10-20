extends "res://tools/probes/transformation_encounters.gd"
var source_origin:=Vector3.ZERO
func at(p: Vector3) -> Vector3:return source_origin+hall.global_basis*p
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(.8).timeout
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var wardrobe=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
	for child in museum.get_children():
		if child is Node3D and child.has_meta("em_map") and child!=hall:child.hide()
	var inventory:Array=[]
	for rec in museum.get("_edit_records"):
		var node=rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node):
			inventory.append({"token":rec.get("token",""),"position":xyz(hall.to_local(node.global_position))})
			if str(rec.get("token","")).begins_with("reference_pattern_garden"):source_origin=node.global_position-hall.global_basis*Vector3(10.5,0,20.5)
	observations.inventory=inventory;observations.source_origin=xyz(source_origin)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=36
	camera.global_position=at(Vector3(10,42,15));camera.look_at(at(Vector3(10,0,15)),Vector3.FORWARD);camera.current=true
	await create_timer(.5).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"overhead.png"))
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	await snapshot("bay",at(Vector3(13,1.65,13.5)),at(Vector3(17.5,2,13.5)),78)
	await snapshot("raised",at(Vector3(6,9,4)),at(Vector3(15,1.4,10)),78)
	var work:=find_scene("/camera_glitch_study/CameraGlitchStudy.gd")
	check("camera gallery installed in the real hall",work!=null)
	if work==null:return
	camera.global_position=work.to_global(Vector3(0,1.65,4.3));camera.look_at(work.to_global(Vector3(0,2.0,0)));camera.current=true
	await create_timer(1.0).timeout
	check("source shares the museum world",work.viewport.world_3d==hall.get_world_3d())
	check("source excludes display and HUD layers",work.source_camera.cull_mask & (1<<19)==0 and work.source_camera.cull_mask & (1<<18)==0)
	check("one bounded source viewport",work.viewport.size==Vector2i(640,360) and work.find_children("*","SubViewport",true,false).size()==1)
	await work.snapshot()
	var image:Image=work.held_texture.get_image();var original:=image.get_data().hex_encode().sha256_text()
	image.save_png(ProjectSettings.globalize_path(folder+"source.png"))
	var colours:Dictionary={}
	for y in range(0,image.get_height(),12):
		for x in range(0,image.get_width(),12):colours[image.get_pixel(x,y).to_html(false)]=true
	check("real camera image contains varied room pixels",colours.size()>30)
	work.paused=true;work.bind_images()
	for mode in 10:
		work.select(mode);work.amount=1.0;work.rebuild();await tick()
		if mode==6:
			work.paused=false;work.handle.rotate_y(.4);work.bind_images();await create_timer(.3).timeout
		check("mode %d has only its active receivers"%mode,work.receivers.size()==(3 if mode==2 else 1))
		await snapshot("mode-%02d"%(mode+1),work.to_global(Vector3(-1.6,1.65,4.8)),work.to_global(Vector3(-.3,2,0)),74)
		if mode==6:
			check("moving camera changes live frame while snapshot stays",work.viewport.get_texture().get_image().get_data().hex_encode().sha256_text()!=original and work.held_texture.get_image().get_data().hex_encode().sha256_text()==original)
			work.home_camera();work.paused=true;work.bind_images()
	check("all treatments retain the original held image",work.held_texture.get_image().get_data().hex_encode().sha256_text()==original)
	work.act("RESET")
	var approach:=work.to_global(Vector3(.5,0,3.0))
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	for id in ["NEXT","PREVIOUS","LIVE / HOLD","SNAP","HOME","RESET"]:
		observations["pointer_"+id]=await driver.press(work.buttons[id],approach)
		await tick();await tick()
		var ok:=true
		match id:
			"NEXT":ok=work.mode==1
			"PREVIOUS":ok=work.mode==0
			"LIVE / HOLD":ok=work.paused
			"SNAP":await create_timer(.15).timeout;ok=not work.taking_snapshot and work.held_texture!=null
			"HOME":ok=work.handle.transform.is_equal_approx(work.home_pose) and work.handle.position.distance_to(Vector3(-2.1,1.35,1.2))<.0001
			"RESET":ok=not work.paused and work.mode==0 and is_equal_approx(work.amount,.8)
		check("desktop pointer operates "+id,ok)
		if id=="HOME":observations.home={"local":xyz(work.handle.position),"home":xyz(work.home_pose.origin),"held":work.handle.held_by_visitor(),"basis_equal":work.handle.transform.is_equal_approx(work.home_pose),"actual_basis":str(work.handle.basis),"wanted_basis":str(work.home_pose.basis)}
	driver.teardown();driver.queue_free();await tick()
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_transform=work.handle.global_transform;work.handle.pick_up(pickup);await tick();await tick()
	controller.global_position+=Vector3(.4,.2,0);controller.rotate_y(.25)
	for i in 6:await tick()
	check("XRTools grab moves the real source camera",work.handle.is_picked_up() and work.source_camera.global_transform.is_equal_approx(work.handle.lens_pose()) and not work.handle.transform.is_equal_approx(work.home_pose))
	work.handle.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("released camera remains a held observation position",not work.handle.is_picked_up() and work.handle.freeze and not work.parked)
	var joint:Node3D=work.amount_dial.get_node("DialOrigin/InteractableHinge");var knob=joint.get_node("Handles/Handle1/InteractableHandle")
	controller.global_transform=knob.global_transform;knob.pick_up(pickup);await tick();await tick()
	controller.global_position=joint.global_position+(controller.global_position-joint.global_position).rotated(joint.global_basis.x.normalized(),-.75)
	for i in 6:await tick()
	check("XRTools dial changes effect amount",work.amount<.75)
	knob.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick();origin.queue_free();await tick();work.act("RESET")
	var shape:=CapsuleShape3D.new();shape.radius=.25;shape.height=1.7;var clear:=true;var count:=0
	for path in [[Vector3(10.5,0,11),Vector3(13.5,0,11)],[Vector3(13.5,0,11),Vector3(13.5,0,14)],[Vector3(13.5,0,14),Vector3(14.5,0,14)],[Vector3(10.5,0,11),Vector3(2.8,0,11)],[Vector3(2.8,0,11),Vector3(2.8,0,28)],[Vector3(2.8,0,28),Vector3(10.5,0,28)],[Vector3(10.5,0,28),Vector3(10.5,0,29.4)]]:
		var a:Vector3=path[0];var b:Vector3=path[1];var n:=ceili(a.distance_to(b)/.15)
		for i in range(n+1):
			var foot:=at(a.lerp(b,float(i)/n));var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1|4;query.transform.origin=foot+Vector3.UP*.88
			var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query,4);var floor:=floor_at(foot)
			clear=clear and hits.is_empty() and not floor.is_empty() and absf(floor.position.y-foot.y)<.04;count+=1
			if not hits.is_empty():observations["blocked_"+str(foot)]=str(hits[0].collider.get_path())
	check("entry, gallery controls and exit have supported capsule routes",clear);observations.route_samples=count
	await snapshot("controls",work.to_global(Vector3(.5,1.65,3)),work.to_global(Vector3(.5,.9,1.85)),74)
	await snapshot("gallery-raised",work.to_global(Vector3(-4,5.5,5.5)),work.to_global(Vector3(-.3,1.8,0)),68)
