extends "res://tools/probes/transformation_encounters.gd"
var completed := false
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
	var flow := find_scene("/FlowFieldMain.gd")
	check("Existing flow-field exhibit is present",flow != null)
	if flow == null:return
	var adapter := find_scene("/flow_museum.gd")
	var origin:Vector3=flow.global_position-hall.global_basis*Vector3(6.5,0,4.5)
	if adapter != null:origin=adapter.global_position-hall.global_basis*Vector3(4.5,0,2.5)
	observations.origin=xyz(origin)
	observations.agents=flow.agents.size()
	observations.hall_position=xyz(hall.global_position)
	await snapshot("above-before",origin+hall.global_basis*Vector3(6.5,20,15),origin+hall.global_basis*Vector3(6.5,0,5.5),60)
	await snapshot("entry-before",origin+hall.global_basis*Vector3(6.5,1.7,1.5),origin+hall.global_basis*Vector3(6.5,1,4.5),70)
	if adapter != null:
		check("Original200 agents and40x40 grid are retained",flow.agents.size()==200 and flow.grid.width==40 and flow.grid.height==40)
		check("Full-size simulation is in a private physics world",flow.get_world_3d()!=hall.get_world_3d())
		check("Outer screen is2.8 metres square",adapter.screen.mesh.size==Vector2(2.8,2.8))
		adapter.apply_grid_config({"scenario":"wind","field_display":"arrows"})
		check("Adapter forwards the existing field configuration",flow.scenario=="wind" and flow.sequence_mode==4 and flow.visualizer.visible)
		var old:Vector3=flow.agents[0].position
		await create_timer(.3).timeout
		check("Original agents keep moving inside live display",flow.agents[0].position.distance_to(old)>.01)
		await snapshot("live-flow-table",adapter.to_global(Vector3(0,2.9,2.0)),adapter.to_global(Vector3(0,1,0)),70)
		adapter.apply_grid_config({"scenario":"tour"})
		await learner_checks(origin)
	completed=true

func clear_at(p:Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=.24;shape.height=1.65
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform.origin=p+Vector3.UP*.9
	return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func learner_checks(origin:Vector3) -> void:
	var s=load("res://doc/book/iterations/2026-10-10-flow-directions-already-here/printed/study.tscn").instantiate()
	hall.add_child(s)
	s.global_transform=Transform3D(hall.global_basis*Basis(Vector3.UP,-PI/2),origin+hall.global_basis*Vector3(8.5,0,2.5))
	await tick();s.set_process(false)
	check("Complete printed study is built in the real FlowFields hall",s.points.size()==6 and s.arrows.size()==256)
	var approach:Vector3=s.to_global(Vector3(0,.01,2.05))
	check("Student controls have a supported body-clear approach",not floor_at(approach).is_empty() and clear_at(approach))
	var aisle:=true
	observations.aisle=[]
	# This approach ends at the study bay; the hall's central wedge starts beyond it.
	for z in range(2,7):
		var p:Vector3=origin+hall.global_basis*Vector3(6.5,.01,z*.5)
		var hit:Dictionary=floor_at(p)
		var shape:=CapsuleShape3D.new();shape.radius=.24;shape.height=1.65
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform.origin=p+Vector3.UP*.9
		var bodies:=hall.get_world_3d().direct_space_state.intersect_shape(query)
		var names:Array=[]
		for body in bodies:names.append(str(body.collider.get_path()))
		observations.aisle.append({"at":xyz(p),"floor":not hit.is_empty(),"colliders":names})
		aisle=aisle and not hit.is_empty() and bodies.is_empty()
	check("Study-bay approach has floor and body clearance (z1 through3)",aisle)
	await snapshot("student-start",s.to_global(Vector3(0,3.0,2.3)),s.to_global(Vector3(0,1.2,0)),70)
	s.get_node("Run").emit_signal("pressed")
	for i in range(42):s._process(.05)
	check("Real controls advance the model through its first turn",s.field.steps==42 and s.field.velocities[0].y>0)
	await snapshot("student-turn",s.to_global(Vector3(0,3.0,2.3)),s.to_global(Vector3(0,1.2,0)),70)
	await snapshot("student-eye-level",s.to_global(Vector3(0,1.7,2.1)),s.to_global(Vector3(0,1.35,0)),75)
	s.get_node("Reset").emit_signal("pressed");s.get_node("Patch").emit_signal("pressed");s.get_node("Run").emit_signal("pressed")
	for i in range(42):s._process(.05)
	check("Zero patch gives a different velocity at the same tick",s.field.steps==42 and is_zero_approx(s.field.velocities[0].y) and s.field.velocities[0].x<2.5)
	await snapshot("student-brake",s.to_global(Vector3(0,3.0,2.3)),s.to_global(Vector3(0,1.2,0)),70)
	var blocked:=false
	for target:Vector3 in [s.caption.global_position,s.to_global(Vector3(0,1.02,-1))]:
		var ray:=PhysicsRayQueryParameters3D.create(s.to_global(Vector3(0,1.7,1.85)),target,1)
		var hit:Dictionary=hall.get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():
			blocked=true
			observations.blocked_view={"at":xyz(hit.position),"body":str(hit.collider.get_path())}
	check("Study label and far field have clear standing sightlines",not blocked)
	await snapshot("above-after",origin+hall.global_basis*Vector3(6.5,20,15),origin+hall.global_basis*Vector3(6.5,0,5.5),60)

func finish() -> void:
	var result:Dictionary={"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":completed and failures.is_empty(),"completed":completed,"scope":"Native museum; no physical headset claim."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if result.passed else 1)
