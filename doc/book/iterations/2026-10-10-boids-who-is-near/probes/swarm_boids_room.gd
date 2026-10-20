extends "res://tools/probes/transformation_encounters.gd"
var completed := false
func clear_at(p:Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=.24;shape.height=1.65
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform.origin=p+Vector3.UP*.9
	var bodies:=hall.get_world_3d().direct_space_state.intersect_shape(query)
	if not bodies.is_empty():
		observations.blocked_approach=[]
		for body in bodies:observations.blocked_approach.append(str(body.collider.get_path()))
	return bodies.is_empty()

func landing_checks() -> void:
	museum.call("flush_stamps")
	var stream= museum.get("_portal_stream")
	if stream != null:stream.process_mode=Node.PROCESS_MODE_DISABLED
	var player= museum.get("_player")
	if player is Node3D:
		player.hide();player.process_mode=Node.PROCESS_MODE_DISABLED;player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.35;camera.attributes=attributes
	var tank:=find_scene("/boids_aquarium.gd")
	var panel:=find_scene("/flocking_controls.gd")
	var flock:=find_scene("/boid_manager.gd")
	check("All three existing flock comparisons are loaded",tank!=null and panel!=null and flock!=null)
	if tank==null or panel==null or flock==null:return
	var origin:Vector3=tank.global_position-hall.global_basis*Vector3(4.5,0,6.5)
	origin.y=hall.global_position.y
	observations.origin=xyz(origin)
	observations.tank_position=xyz(tank.global_position)
	observations.panel_position=xyz(panel.global_position)
	observations.original_counts=[tank._boids.size(),panel._boids.size(),flock.get_boids().size()]
	check("Aquarium and controls each retain30 existing agents",tank._boids.size()==30 and panel._boids.size()==30)
	check("Tank and controls are raised into the1.15-1.4m viewing band",tank.global_position.y>1.15 and tank.global_position.y<1.4 and panel.global_position.y>1.15 and panel.global_position.y<1.4)
	check("Separation slider is within standing hand reach",panel._sep_slider.global_position.y>.8 and panel._sep_slider.global_position.y<1.25)
	var initial:Vector3=tank._boids[0].position
	await create_timer(.3).timeout
	check("Original aquarium is still running",tank._boids[0].position.distance_to(initial)>.0001)
	panel.set_process(false)
	var tracked=panel._boids[panel._highlighted]
	tracked.f_sep=Vector3.ZERO;tracked.f_align=Vector3.ZERO;tracked.f_coh=Vector3.ZERO
	panel._update_force_arrows()
	check("Zero-force diagram safely has no surface",panel._force_mesh.mesh.get_surface_count()==0)
	tracked.f_sep=Vector3(.1,0,0);panel._update_force_arrows()
	check("A nonzero request still draws an arrow",panel._force_mesh.mesh.get_surface_count()==1)
	panel.set_process(true)
	await snapshot("above-before",origin+hall.global_basis*Vector3(6.5,22,18),origin+hall.global_basis*Vector3(6.5,0,6.5),60)
	await snapshot("aquarium",tank.to_global(Vector3(0,2.0,2.6)),tank.to_global(Vector3(0,.8,0)),55)
	await snapshot("flocking-controls",panel.to_global(Vector3(0,1.3,1.9)),panel.global_position,55)
	var s=load("res://doc/book/iterations/2026-10-10-boids-who-is-near/printed/study.tscn").instantiate()
	hall.add_child(s)
	s.global_transform=Transform3D(hall.global_basis,origin+hall.global_basis*Vector3(6,0,9))
	await tick();s.set_process(false)
	check("Complete printed learner study is in the existing hall",s.points.size()==6 and s.arrows.size()==4)
	var approach:Vector3=s.to_global(Vector3(0,.01,2.1))
	check("Student controls have supported body-clear approach",not floor_at(approach).is_empty() and clear_at(approach))
	var rays_clear:=true
	for target:Vector3 in [s.caption.global_position,s.to_global(Vector3(0,1.02,-1))]:
		var ray:=PhysicsRayQueryParameters3D.create(s.to_global(Vector3(0,1.7,1.85)),target,1)
		var hit:=hall.get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():rays_clear=false;observations.blocked_view=str(hit.collider.get_path())
	check("Label and far table have clear standing sightlines",rays_clear)
	await snapshot("separation",s.to_global(Vector3(0,2.9,2.3)),s.to_global(Vector3(0,1.3,0)),65)
	s.get_node("Rule").emit_signal("pressed")
	check("Rule control selects alignment with its expected local correction",s.flock.mode==1 and s.flock.acceleration(0).is_equal_approx(Vector2(-2,4)))
	await snapshot("alignment",s.to_global(Vector3(0,2.9,2.3)),s.to_global(Vector3(0,1.3,0)),65)
	s.get_node("Rule").emit_signal("pressed")
	await snapshot("cohesion",s.to_global(Vector3(0,2.9,2.3)),s.to_global(Vector3(0,1.3,0)),65)
	s.get_node("Rule").emit_signal("pressed")
	check("All three weighted requests are visible before movement",s.arrows[0].visible and s.arrows[1].visible and s.arrows[2].visible)
	await snapshot("three-requests",s.to_global(Vector3(0,2.9,2.3)),s.to_global(Vector3(0,1.3,0)),65)
	await snapshot("eye-level",s.to_global(Vector3(0,1.7,2.1)),s.to_global(Vector3(0,1.32,0)),75)
	s.get_node("Radius").emit_signal("pressed")
	check("Radius changes actual neighbours from two to one",s.flock.neighbours(0)==[1] and s.halos[1].visible and not s.halos[2].visible)
	await snapshot("one-neighbour",s.to_global(Vector3(0,2.9,2.3)),s.to_global(Vector3(0,1.3,0)),65)
	s.get_node("Radius").emit_signal("pressed");s.get_node("Run").emit_signal("pressed")
	for i in range(20):s._process(.05)
	check("Native button advances20 fixed steps",s.flock.steps==20 and s.flock.positions[0]!=Vector2(6,8))
	await snapshot("in-motion",s.to_global(Vector3(0,2.9,2.3)),s.to_global(Vector3(0,1.3,0)),65)
	await snapshot("above-after",origin+hall.global_basis*Vector3(6.5,22,18),origin+hall.global_basis*Vector3(6.5,0,6.5),60)
	observations.student_temporary=true
	observations.student_map_position=[6,0,9]
	completed=true

func finish() -> void:
	var result:Dictionary={"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":completed and failures.is_empty(),"completed":completed,"scope":"Native museum, temporary printed learner study. Local approach and sightlines only; no physical headset or whole-hall traversal claim."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if result.passed else 1)
