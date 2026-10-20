extends "res://tools/probes/transformation_encounters.gd"
var completed := false
var origin: Vector3

func at(p: Vector3) -> Vector3:
	return origin+hall.global_basis*p

func landing_checks() -> void:
	museum.call("flush_stamps")
	var stream = museum.get("_portal_stream")
	if stream != null: stream.process_mode = Node.PROCESS_MODE_DISABLED
	var player = museum.get("_player")
	if player is Node3D:
		player.hide(); player.process_mode = Node.PROCESS_MODE_DISABLED
		player.global_position = Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes := CameraAttributesPractical.new()
	attributes.exposure_multiplier = .35
	camera.attributes = attributes
	var tank := find_scene("/boids_aquarium.gd")
	var flock := find_scene("/boid_manager.gd")
	var balcony := hall.get_node_or_null("ObservationBalcony")
	check("Permanent balcony loads with the existing flock",balcony != null and flock != null and tank != null)
	if balcony == null or flock == null or tank == null: return
	origin = tank.global_position-hall.global_basis*Vector3(4.5,0,6.5)
	origin.y = hall.global_position.y
	check("All 100 large boids remain",flock.get_boids().size()==100)
	check("Balcony floor has 8 by 5 metre observation area",balcony.get_node("Deck").mesh.size.is_equal_approx(Vector3(8.02,.24,5)))
	check("Balcony has three full collision guards",balcony.find_children("EdgeGuard*","StaticBody3D",false,false).size()==3)
	var blocked: Array=[]
	var supported := true
	var shape := CapsuleShape3D.new();shape.radius=.24;shape.height=1.7
	for i in range(46):
		var p := at(Vector3(4-float(i)*.25,0,10.5))
		var floor := floor_at(p)
		if floor.is_empty() or absf(floor.position.y-origin.y)>.015:supported=false
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape=shape;query.collision_mask=1
		query.transform.origin=p+Vector3.UP*.87
		var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
		for hit in hits:blocked.append(str(hit.collider.get_path()))
	check("Continuous level floor from hall through doorway to balcony",supported)
	check("Standing capsule has clear route through the three-metre doorway",blocked.is_empty())
	observations.blockers=blocked
	# Real move_and_slide, with gravity: a supported walker travels both directions.
	var walker := CharacterBody3D.new();walker.name="BalconyTestWalker"
	walker.collision_layer=0;walker.collision_mask=1
	var collision := CollisionShape3D.new();collision.shape=shape;collision.position.y=.86
	walker.add_child(collision);root.add_child(walker)
	walker.global_position=at(Vector3(3.5,.01,10.5))
	await tick()
	var out_ok := await walk_to(walker,-6.5)
	check("CharacterBody walks onto the balcony with gravity",out_ok and walker.is_on_floor())
	observations.walk_out=xyz(walker.global_position)
	var back_ok := await walk_to(walker,3.5)
	check("CharacterBody returns to the hall without a jump",back_ok and walker.is_on_floor())
	walker.queue_free();await tick()
	var guards := true
	for pair: Array in [[Vector3(-7,.6,9),Vector3(-9,.6,9)],[Vector3(-5,.6,8),Vector3(-5,.6,6)],[Vector3(-5,.6,11),Vector3(-5,.6,13)]]:
		var query := PhysicsRayQueryParameters3D.create(at(pair[0]),at(pair[1]),1)
		var hit:=hall.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or not str(hit.collider.name).begins_with("EdgeGuard"):guards=false
	check("All exposed sides stop a body at waist height",guards)
	var eye:=at(Vector3(-7.5,1.7,10.5))
	var clear:=true
	for target:Vector3 in [Vector3(-15,1,6),Vector3(-18,3,10.5),Vector3(-14,-3,10.5)]:
		var query:=PhysicsRayQueryParameters3D.create(eye,at(target),1)
		if not hall.get_world_3d().direct_space_state.intersect_ray(query).is_empty():clear=false
	check("Standing sightlines clear the rail above and below",clear)
	var first:Vector3=flock.get_boids()[0].global_position
	await create_timer(.5).timeout
	check("The original flock continues moving",first.distance_to(flock.get_boids()[0].global_position)>.01)
	# Keep the flock and its trails moving in the photographs.
	await snapshot("doorway",at(Vector3(3.8,1.7,10.5)),at(Vector3(-7,1.0,10.5)),76)
	await snapshot("balcony-eye",at(Vector3(-7.5,1.7,10.5)),at(Vector3(-15,-1,4)),80)
	await snapshot("balcony-look-back",at(Vector3(-6.5,1.7,10.5)),at(Vector3(2,1.7,9.5)),76)
	await snapshot("above",at(Vector3(-16,20,24)),at(Vector3(2,0,8)),65)
	observations.headset_tested=false
	observations.flock_motion_changed=false
	completed=true

func walk_to(body: CharacterBody3D, x: float) -> bool:
	var goal:=at(Vector3(x,0,10.5))
	for i in range(360):
		await physics_frame
		var direction:=goal-body.global_position;direction.y=0
		if direction.length()<.09:return true
		body.velocity.x=direction.normalized().x*3
		body.velocity.z=direction.normalized().z*3
		body.velocity.y-=9.8/60.0
		body.move_and_slide()
	return false

func finish() -> void:
	var result:Dictionary={"room":map_id,"passed":completed and failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Permanent museum geometry; collision and CharacterBody walking. No physical headset test."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if result.passed else 1)
