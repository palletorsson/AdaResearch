extends "res://doc/book/iterations/2026-10-16-entropy-button-reach/control_probe.gd"
const WalkPush=preload("res://commons/movement/pushable_walk.gd")

func types_controls() -> void:
	var study=find_scene("/ordinary_entropies/one_guess.gd")
	check("four chair pyramids installed",study!=null and study.versions.size()==4)
	if study==null:return
	await create_timer(5.0).timeout
	observations["pyramids"]=[]
	for group in study.versions:
		var stable:=true
		var awake:=0
		for i in 16:
			var chair=group.chairs[i]
			stable=stable and chair.position.distance_to(group.site(i))<0.15
			if not chair.sleeping:awake+=1
		check(group.cohort+" sixteen full-size physical chairs",group.chairs.size()==16 and group.chairs.all(func(c):return c is RigidBody3D and c.has_method("pick_up") and not c.freeze and c.collision_layer==7))
		check(group.cohort+" pyramid stands without frozen bodies",stable)
		observations.pyramids.append({"group":group.cohort,"awake":awake,"positions":group.chairs.map(func(c):return xyz(c.position)),"best":group.model.readings().best})
		await exercise(group.buttons["PINK"],group,group.cohort+" PINK",Vector3.UP)
		await exercise(group.buttons["DRAW"],group,group.cohort+" DRAW",Vector3.UP)
		check(group.cohort+" real input chooses and draws",group.model.guess==0 and group.model.draws==2)
	check("A and B retain same best guess and distinct average uncertainty",study.versions[0].model.readings().min==1.0 and study.versions[1].model.readings().min==1.0 and study.versions[1].model.readings().shannon==1.5)
	await snapshot("four-pyramids",study.to_global(Vector3(0,4.5,7.5)),study.to_global(Vector3(0,0.9,0)),78)
	var group=study.versions[3]
	await snapshot("pink-pyramid",group.to_global(Vector3(2.6,1.65,3.2)),group.to_global(Vector3(0,1.05,0)),65)
	var original: Dictionary=group.capture()
	# Actual desktop carry driver, including layer/freeze restoration.
	var desktop=load("res://commons/scenes/DesktopInteractionPointer.gd").new()
	root.add_child(desktop);desktop.set_process(false);desktop.set_physics_process(false)
	var chair=group.chairs[4]
	desktop._grab_held(chair)
	await tick()
	check("desktop carry is held and removed from contact",chair.held() and chair.freeze and chair.collision_mask==0)
	group.reset_table()
	check("RESET does not delete a held chair",is_instance_valid(chair) and group.chairs[4]==chair)
	check("held study cannot be captured or restored",group.capture().is_empty() and not group.restore(original))
	chair.position=Vector3(1.25,1.15,0);chair.rotation.z=0.5
	await tick()
	desktop._drop_held()
	check("release resumes physics with rotation retained",not chair.held() and not chair.freeze and chair.collision_layer==7 and is_equal_approx(chair.rotation.z,0.5))
	await create_timer(3.0).timeout
	observations["released_chair"]={"position":xyz(chair.position),"freeze":chair.freeze,"sleeping":chair.sleeping,"processing":chair.can_process()}
	check("chair falls instead of snapping upright to a table",chair.position.y<1.0 and chair.position.distance_to(group.site(4))>0.5)
	check("all-pink prediction survives extraction",group.model.readings().best==1.0 and group.model.readings().min==0.0)
	await snapshot("pink-after-support",group.to_global(Vector3(2.6,1.65,3.2)),group.to_global(Vector3(0,0.8,0)),65)
	# Pose/motion receipts round-trip through JSON before a subsequent physics step.
	chair.linear_velocity=Vector3(0.1,0.2,0.3);chair.angular_velocity=Vector3(0.2,0.1,0.4)
	var record: Dictionary=group.capture()
	var roundtrip: Variant=JSON.parse_string(JSON.stringify(record,"",true,true))
	group.choose(0);var next: Array=[]
	for i in 16:group.model.draw();next.append(group.model.selected)
	check("floor receipt restores full pose and motion",group.restore(roundtrip) and group.chairs[4].position.is_equal_approx(Vector3(record.poses[4][0],record.poses[4][1],record.poses[4][2])) and group.chairs[4].angular_velocity.is_equal_approx(Vector3(0.2,0.1,0.4)))
	group.choose(0);var again: Array=[]
	for i in 16:group.model.draw();again.append(group.model.selected)
	check("next seeded IDs replay exactly",next==again)
	var invalid: Dictionary=record.duplicate(true);invalid.poses[0][0]="not a coordinate"
	var unchanged: Dictionary=group.capture()
	check("malformed receipt rejected before mutation",not group.restore(invalid) and group.capture()==unchanged)
	check("old tabletop receipt is not silently resized",not group.restore({"schema":"one-guess-table/1"}))
	# Exercise the XR Tools grab driver with a supplied controller node.
	var origin:=XROrigin3D.new();var controller:=XRController3D.new()
	origin.add_child(controller);root.add_child(origin)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate()
	controller.add_child(pickup);pickup.set_process(false);pickup.set_physics_process(false)
	chair=group.chairs[15];pickup.global_position=chair.global_position
	pickup._object_in_grab_area.append(chair);pickup._pick_up_object(chair)
	await tick()
	check("XR Tools grabs a chair through its driver",chair.is_picked_up() and chair.freeze and chair.collision_layer==(1<<16))
	pickup.global_position+=Vector3.UP*0.3
	await tick();pickup.drop_object();await tick()
	check("XR release restores physical collision",not chair.is_picked_up() and not chair.freeze and chair.collision_layer==7)
	origin.queue_free()
	group.reset_table();await create_timer(3.0).timeout
	check("pyramid stable again before walking",group.chairs[15].position.distance_to(group.site(15))<0.15)
	# Move a real museum walker into the pyramid with the production contact hook.
	var walker: CharacterBody3D=museum.get("_player")
	walker.global_position=group.to_global(Vector3(0,0.02,-1.4))
	var before: Array=group.chairs.map(func(c):return c.position)
	var touched:=false
	for i in 100:
		await physics_frame
		walker.velocity=group.global_basis*Vector3(0,-0.2,0.8)
		var incoming:=walker.velocity
		walker.move_and_slide()
		for j in walker.get_slide_collision_count():
			if walker.get_slide_collision(j).get_collider() in group.chairs:touched=true
		WalkPush.after_move(walker,incoming,1.0/Engine.physics_ticks_per_second)
		await process_frame
	walker.global_position=study.to_global(Vector3(0,0.02,0))
	await create_timer(2.0).timeout
	var moved:=0.0
	for i in 16:moved=maxf(moved,group.chairs[i].position.distance_to(before[i]))
	check("walking contacts a chair through museum collision mask",touched)
	check("walking physically nudges the stack",moved>0.03)
	check("walking preserves group IDs and min-entropy",group.model.categories.size()==16 and group.model.readings().min==0.0)
	observations["walk_max_displacement_m"]=moved
	observations["walk_positions"]=group.chairs.map(func(c):return xyz(c.position))
	check("walking disturbance stays local",moved<6.0)
	await snapshot("pink-after-walking",group.to_global(Vector3(2.6,1.65,3.2)),group.to_global(Vector3(0,0.8,0)),65)
	var mixed=study.versions[1]
	var pose=mixed.chairs[15].transform
	mixed.change_one()
	check("CHANGE ONE alters category without resetting pose",mixed.model.counts()==[9,4,3] and mixed.chairs[15].transform.is_equal_approx(pose))
	group.reset_table();await create_timer(3.0).timeout
	check("RESET reconstructs pyramid and seed",group.chairs[15].position.y>1.35 and group.model.draws==0)
	for z in range(-5,6):
		var ray:=PhysicsRayQueryParameters3D.create(study.to_global(Vector3(0,0.7,z)),study.to_global(Vector3(0,0.7,z-0.8)),1)
		ray.exclude=[walker.get_rid()]
		check("central walking route clear "+str(z),hall.get_world_3d().direct_space_state.intersect_ray(ray).is_empty())
	var ref=find_scene("/ordinary_entropies/chair_reference.gd")
	check("entrance chair also grabbable",ref!=null and ref.get_node("ReferenceChair").has_method("pick_up"))
	desktop.free()
