extends "res://tools/probes/forces_layout.gd"
## Walk a standing capsule up the actual museum ramp. No jumping/teleporting.
var walker_probe: CharacterBody3D
var slope: Node3D

func landing_checks() -> void:
	await super.landing_checks()
	camera.set_cull_mask_value(19,false)
	var wardrobe: Node=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").visible=false
	for e in get_nodes_in_group("force_play"):
		if hall.is_ancestor_of(e) and e.kind=="friction":slope=e;break
	check("Friction comparison found in actual museum",slope!=null)
	if slope==null:return
	slope.slope_auto=false
	await snapshot("walk-up",slope.to_global(Vector3(12.8,1.7,6.8)),slope.to_global(Vector3(10.9,1.7,-3.5)),72)
	await snapshot("access-overview",slope.to_global(Vector3(15,8,-12)),slope.to_global(Vector3(1,1,-1)),78)
	walker_probe=CharacterBody3D.new();walker_probe.name="StandingWalkProbe"
	walker_probe.collision_layer=0;walker_probe.collision_mask=1|4
	walker_probe.floor_snap_length=0.3;walker_probe.floor_max_angle=deg_to_rad(45)
	var collision=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=0.24;capsule.height=1.7
	collision.shape=capsule;collision.position.y=0.85;walker_probe.add_child(collision)
	root.add_child(walker_probe);walker_probe.global_position=slope.to_global(Vector3(10.8,0.06,5))
	await walk_to(Vector3(10.8,2.13,-6.2),"Climb from floor to upper walkway without jumping")
	if slope.to_local(walker_probe.global_position).y<2:return
	check("Walker's feet reach the two-metre deck",absf(slope.to_local(walker_probe.global_position).y-2.13)<0.08)
	await walk_to(Vector3(-7.8,2.13,-6.2),"Cross walkway to the far comparison lane")
	await snapshot("at-the-bodies",walker_probe.global_position+Vector3.UP*1.65,slope.to_global(Vector3(0,1.5,0)),82)
	await walk_to(Vector3(-7.8,2.05,-5.05),"Step directly from walkway onto the slope")
	await walk_to(Vector3(-7.8,2.13,-6.2),"Return from slope to walkway")
	await walk_to(Vector3(10.8,2.13,-6.2),"Walk back across the deck")
	await walk_to(Vector3(10.8,0.05,4),"Descend continuously to the museum floor")
	check("Return to floor stays supported",walker_probe.is_on_floor() and slope.to_local(walker_probe.global_position).y<0.15)
	observations.walker_final=xyz(slope.to_local(walker_probe.global_position))
	walker_probe.queue_free()
	slope.reset();await create_timer(0.15).timeout
	slope.slope_drop_clock=6.95;await create_timer(0.28).timeout
	await snapshot("a-body-drops",slope.to_global(Vector3(-9.7,3.8,-6.1)),slope.to_global(Vector3(-7.8,2.0,-3.4)),67)
	check("Automatic release also runs inside museum",slope.slope_drop_count==1)
	observations.physics_engine=ProjectSettings.get_setting("physics/3d/physics_engine")

func walk_to(target: Vector3,message: String) -> void:
	var reached=false
	var last_position=walker_probe.global_position
	var stalled=0
	for frame in range(800):
		await physics_frame
		var at=slope.to_local(walker_probe.global_position)
		var direction=Vector3(target.x-at.x,0,target.z-at.z)
		if direction.length()<0.055:reached=true;break
		var speed=minf(3.0,direction.length()*60)
		var velocity=slope.global_basis*direction.normalized()*speed
		walker_probe.velocity.x=velocity.x;walker_probe.velocity.z=velocity.z
		walker_probe.velocity.y-=9.8/60.0
		walker_probe.move_and_slide()
		if walker_probe.global_position.distance_to(last_position)<0.001:stalled+=1
		else:stalled=0
		last_position=walker_probe.global_position
		if stalled>30:
			var contacts=[]
			for i in walker_probe.get_slide_collision_count():contacts.append(str(walker_probe.get_slide_collision(i).get_collider().get_path()))
			print("WALK STUCK ",message," at ",slope.to_local(last_position)," contacts ",contacts)
			break
	check(message,reached)
	if not reached:observations[message]=xyz(slope.to_local(walker_probe.global_position))
