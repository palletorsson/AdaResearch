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
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.process_mode=Node.PROCESS_MODE_DISABLED
	var player=museum.get("_player")
	if player is Node3D:
		player.hide();player.process_mode=Node.PROCESS_MODE_DISABLED;player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.35;camera.attributes=attributes
	var colony:=find_scene("/AntColonyOptimization.gd")
	var navigator:=find_scene("/NavigatorNoise.gd")
	check("Colony and optional navigator are present",colony!=null and navigator!=null)
	if colony==null:return
	var origin:Vector3=colony.global_position-hall.global_basis*Vector3(4.5,0,4.5)
	origin.y=hall.global_position.y
	observations.origin=xyz(origin)
	check("Existing colony keeps its40 agents and lesson display",colony._ants.size()==40 and colony.lesson_display)
	colony.set_process(false);colony._reset_colony()
	var p:Vector2=colony._ants[0].pos
	for i in range(120):colony._simulate_step(1.0/60)
	check("Existing colony is running its original movement",colony._ants[0].pos.distance_to(p)>.01)
	colony._pheromone_grid[2][2]=7
	colony._spawn_ants()
	check("Existing population replacement retains shared marks",colony._pheromone_grid[2][2]==7)
	colony._reset_colony()
	check("Existing full reset clears those marks",colony._pheromone_grid[2][2]==0)
	for i in range(1200):colony._simulate_step(1.0/60)
	colony._draw_all();colony._update_labels()
	await snapshot("colony-after",colony.to_global(Vector3(0,2.6,-3)),colony.to_global(Vector3(0,2,0)),65)
	var s=load("res://doc/book/iterations/2026-10-10-abm-what-the-point-carries/printed/study.tscn").instantiate()
	hall.add_child(s)
	s.global_transform=Transform3D(hall.global_basis*Basis(Vector3.UP,-PI/2),origin+hall.global_basis*Vector3(8.8,0,6.5))
	await tick()
	check("Printed learner scene uses six spheres in existing hall",s.points.size()==6 and s.tiles.size()==256)
	var approach:Vector3=s.to_global(Vector3(0,.01,2.1))
	check("Working approach has floor and capsule clearance",not floor_at(approach).is_empty() and clear_at(approach))
	var clear:=true
	for target:Vector3 in [s.caption.global_position,s.to_global(Vector3(0,1.02,-1))]:
		var ray:=PhysicsRayQueryParameters3D.create(s.to_global(Vector3(0,1.7,1.85)),target,1)
		var hit:=hall.get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():clear=false;observations.blocked_view=str(hit.collider.get_path())
	check("Standing sightlines reach readout and far grid",clear)
	await snapshot("searching",s.to_global(Vector3(0,2.7,2.2)),s.to_global(Vector3(0,1.35,0)),65)
	s.model.positions[0]=Vector2(12,8);s.model.velocities[0]=Vector2.ZERO;s.paint()
	s.get_node("Step").emit_signal("pressed")
	check("Museum One Tick button causes food pickup and visible cargo",s.model.carrying[0] and s.cargo[0].visible)
	await create_timer(.2).timeout
	check("Frozen rendered sphere stays at the model position across physics frames",s.points[0].position.distance_to(s.place(s.model.positions[0]))<.001)
	await snapshot("carrying",s.to_global(Vector3(0,2.7,2.2)),s.to_global(Vector3(0,1.35,0)),65)
	await snapshot("eye-level",s.to_global(Vector3(0,1.7,2.1)),s.to_global(Vector3(0,1.3,0)),75)
	for i in range(80):s.model.step()
	s.paint()
	var marks:PackedFloat32Array=s.model.values.duplicate()
	check("Returning travellers build shared trace",marks.count(0.0)<256)
	await snapshot("trace-kept",s.to_global(Vector3(0,2.7,2.2)),s.to_global(Vector3(0,1.35,0)),65)
	s.get_node("Replace").emit_signal("pressed")
	check("Museum Replace keeps the exact shared field",s.model.values==marks and s.model.carrying.count(false)==6)
	await snapshot("new-agents",s.to_global(Vector3(0,2.7,2.2)),s.to_global(Vector3(0,1.35,0)),65)
	s.get_node("Reset").emit_signal("pressed")
	check("Museum Clear All erases field and clock",s.model.values.count(0.0)==256 and s.model.steps==0)
	await snapshot("clear-all",s.to_global(Vector3(0,2.7,2.2)),s.to_global(Vector3(0,1.35,0)),65)
	await snapshot("above-after",origin+hall.global_basis*Vector3(6.5,23,14),origin+hall.global_basis*Vector3(6.5,0,5),55)
	var supported:=true
	for z in range(10):
		var at:=origin+hall.global_basis*Vector3(6.5,.02,float(z)+.5)
		supported=supported and not floor_at(at).is_empty() and clear_at(at)
	check("Central route has floor and body clearance",supported)
	observations.student_temporary=true
	observations.student_map_position=[8.8,0,6.5]
	observations.student_yaw_degrees=-90
	completed=true
func finish() -> void:
	var result:Dictionary={"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":completed and failures.is_empty(),"completed":completed,"scope":"Native museum, temporary printed learner scene. Capsule and ray probes; no physical headset or player portal crossing claim."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if result.passed else 1)
