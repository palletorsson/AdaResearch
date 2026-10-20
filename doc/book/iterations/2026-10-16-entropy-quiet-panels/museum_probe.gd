extends "res://tools/probes/transformation_encounters.gd"
const IDS=["entropy_chairs_shannon","entropy_chairs_boltzmann","entropy_chairs_description","entropy_door_dynamics","entropy_cooling_cup","entropy_frosted_chair","entropy_ball_pit"]
func landing_checks() -> void:
	root.size=Vector2i(1600,1050);museum.call("flush_stamps");await create_timer(0.5).timeout
	var stations: Dictionary={}
	for node in hall.find_children("*","Node3D",true,false):
		if node.get_script()!=null and str(node.get_script().resource_path).ends_with("ordinary_entropies/encounter.gd"): stations[node.kind]=node
	check("all seven independently registered encounters installed",stations.size()==7)
	if stations.size()!=7:return
	for kind in 7:
		var bench: Node3D=stations[kind]
		bench.pointer_prefix="user://ordinary-hall-test-%d-" % Time.get_ticks_usec()
		check("everyday scale retained "+str(kind),bench.scale.is_equal_approx(Vector3.ONE))
		check("entrance-facing instrument "+str(kind),is_equal_approx(fposmod(bench.rotation_degrees.y,360),180))
		var approach: Vector3=bench.console.approach()
		check("supported approach "+str(kind),not floor_at(approach).is_empty())
		var shape:=CapsuleShape3D.new();shape.radius=0.22;shape.height=1.6
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform=Transform3D(Basis(),approach+Vector3.UP*0.85)
		check("clear standing space "+str(kind),bench.get_world_3d().direct_space_state.intersect_shape(query).is_empty())
		var area: Node=bench.buttons["NEXT"].get_node("InteractableAreaButton");area.button_pressed.emit(area);await tick();await tick()
		check("physical NEXT reaches model "+str(kind),bench.stage_index==1 and (kind!=4 or bench.seconds==5))
		area=bench.buttons["PREVIOUS"].get_node("InteractableAreaButton");area.button_pressed.emit(area);await tick();await tick()
		check("physical PREVIOUS restores first state "+str(kind),bench.stage_index==0 and (kind!=4 or bench.seconds==0))
		var eye: Vector3=bench.to_global(Vector3(0,1.65,4.0))
		var target: Vector3=bench.to_global(Vector3(0,0.7,0))
		var sight:=PhysicsRayQueryParameters3D.create(eye,target,1)
		var hit: Dictionary=bench.get_world_3d().direct_space_state.intersect_ray(sight)
		check("panel leaves centre view clear "+str(kind),hit.is_empty() or not bench.console.is_ancestor_of(hit.collider))
		check("only two or three visible controls "+str(kind),bench.buttons.size()>=2 and bench.buttons.size()<=3)
		await snapshot("panel-"+str(kind+1),bench.console.to_global(Vector3(0,1.55,0.95)),bench.console.face.global_position,48)
		await snapshot(IDS[kind],bench.to_global(Vector3(0,1.65,5.5 if kind==2 else 4.5)),bench.to_global(Vector3(0,0.65,0)),105 if kind==2 else 83)
	var first: Node3D=stations[0]
	first.change_stage(-first.stage_index);stations[1].change_stage(-stations[1].stage_index)
	await snapshot("paired-chairs",first.to_global(Vector3(-4.5,1.65,4.8)),first.to_global(Vector3(-4.5,1.0,0)),107)
	var cup: Node3D=stations[4]
	cup.seconds=0;cup.update_motion()
	await snapshot("steam-detail",cup.to_global(Vector3(0.8,1.6,1.6)),cup.to_global(Vector3(0,1.05,0)),47)
	var door: Node3D=stations[3]
	door.change_stage(2-door.stage_index);await tick()
	var through:=door.to_global(Vector3(0,0,0))
	var shape:=CapsuleShape3D.new();shape.radius=0.22;shape.height=1.6
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform=Transform3D(Basis(),through+Vector3.UP*0.85)
	await tick()
	check("held-open door leaves passage clear",door.get_world_3d().direct_space_state.intersect_shape(query).is_empty())
	await snapshot("through-the-door",door.to_global(Vector3(0,1.7,3.0)),door.to_global(Vector3(0,1.1,-7.0)),72)
	# Test the sequence of real passage cells, not just abstract reachability.
	var map_origin: Vector3=first.global_position-Vector3(4.5,0,6.5)
	for cell in [Vector2(9.5,1.5),Vector2(16.5,11.5),Vector2(16.5,24.5),Vector2(16.5,35.5),Vector2(9.5,44.5),Vector2(9.5,55.5)]:
		var p: Vector3=map_origin+Vector3(cell.x,0,cell.y)
		check("passage floor "+str(cell),not floor_at(p).is_empty())
	root.size=Vector2i(1050,1600);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=62
	await snapshot("aerial",map_origin+Vector3(9.5,50,28.5),map_origin+Vector3(9.5,0,28.51),50)
	observations.scope="Native actual hall load, normal scale, physical controls, standing clearance, door passage and unobstructed centre views; no headset or human learning claim."
