extends "res://tools/probes/forces_layout.gd"
func landing_checks() -> void:
	await super.landing_checks()
	camera.set_cull_mask_value(19,false)
	var wardrobe: Node=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").visible=false
	var racer=find_scene("/endless_racer.gd")
	check("Endless Drive is placed in the final Forces hall",racer!=null)
	if racer==null:return
	var obstacle=PhysicsShapeQueryParameters3D.new();var car_space=BoxShape3D.new();car_space.size=Vector3(2.1,1.5,2.85)
	obstacle.shape=car_space;obstacle.transform=Transform3D(racer.global_basis,racer.to_global(Vector3(0,0.85,-0.35)));obstacle.collision_mask=1
	check("The boarding car clears museum walls and columns",racer.get_world_3d().direct_space_state.intersect_shape(obstacle).is_empty())
	await snapshot("museum-bay",racer.to_global(Vector3(-3.3,2.05,4.0)),racer.to_global(Vector3(0,1.0,0)),68)
	var walker: CharacterBody3D=museum.get("_player")
	walker.global_position=racer.to_global(Vector3(0,0,2.2));var home=walker.global_transform
	racer.board_nearest()
	check("The museum DRIVE action boards its actual walker",racer.rider==walker)
	if racer.rider!=walker:return
	await create_timer(0.25).timeout
	var seated=walker.global_position
	var key=InputEventKey.new();key.keycode=KEY_W;key.pressed=true;Input.parse_input_event(key)
	racer.countdown=0
	for i in range(100):
		museum.call("_physics_process",1.0/60)
		await physics_frame
	key.pressed=false;Input.parse_input_event(key)
	check("W drives the car through production keyboard input",racer.model.distance>3 and racer.model.speed>3)
	check("Museum walking cannot move the seated visitor",walker.global_position.distance_to(seated)<0.12)
	var driver_camera: Camera3D=museum.get("_cam")
	check("The actual desktop view faces down the track after movement updates",driver_camera.global_basis.z.dot(racer.arena.global_basis.z)>0.98)
	racer.set_physics_process(false)
	await snapshot("cockpit",racer.arena.to_global(Vector3(0,1.65,0)),racer.arena.to_global(Vector3(0,1.3,-11)),80)
	racer.model.distance=340;racer.model.offset=-1.0;racer.model.speed=19;racer.road.sync(racer.model)
	await snapshot("endless-bend",racer.arena.to_global(Vector3(5.8,4.2,8.6)),racer.arena.to_global(Vector3(-2,1,-28)),70)
	await snapshot("road-ahead",racer.arena.to_global(Vector3(0,1.65,0)),racer.arena.to_global(Vector3(0,1.45,-20)),78)
	racer.restart();check("Museum cockpit restart clears the run",racer.model.distance==0 and racer.countdown==3)
	racer.leave();await create_timer(0.1).timeout
	check("MUSEUM returns to the boarding position",walker.global_transform.is_equal_approx(home))
	check("The original hall and exit remain loaded",is_instance_valid(hall) and not museum.get("_portal_stream").get("_exit").get("invalid",false))
	observations.racer={"model":"arcade scrolling road","pool":28,"max_speed_m_s":26,"seat_displacement_during_drive":walker.global_position.distance_to(home.origin),"location":"Final Forces hall, before the capability court"}
