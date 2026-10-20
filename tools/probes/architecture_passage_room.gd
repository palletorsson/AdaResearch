extends "res://tools/probes/transformation_encounters.gd"
var map_origin:Vector3
func map_at(p:Vector3) -> Vector3:return map_origin+hall.global_basis*p
func clear_body(at:Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.transform.origin=at+Vector3.UP*.88;q.collision_mask=1|4
	var hits:=hall.get_world_3d().direct_space_state.intersect_shape(q)
	if not hits.is_empty():observations["hits_"+str(at)]=hits.map(func(h):return str(h.collider.get_path()))
	return hits.is_empty()
func traverse(study:Node3D,from:Vector3,to:Vector3) -> Vector3:
	var body:=CharacterBody3D.new();body.collision_layer=2;body.collision_mask=1
	var collision:=CollisionShape3D.new();var shape:=CapsuleShape3D.new();shape.radius=.3;shape.height=1.8;collision.shape=shape;body.add_child(collision);root.add_child(body)
	body.global_position=study.to_global(from);await tick();await tick()
	for i in 120:
		body.move_and_collide(study.global_basis*((to-from)/120));await physics_frame
	var end:=study.to_local(body.global_position);body.queue_free();await tick();return end
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var source=find_scene("/lsystem_dungeon/lsystem_dungeon.gd");check("Existing dungeon present",source!=null)
	if source==null:return
	var desk=source.get_node("ArchitectureLesson");var hand=desk.get_node("ArchitectureHand")
	map_origin=source.global_position-hall.global_basis*Vector3(9.5,0,7.5)
	var works:Array=[]
	for rec in museum.get("_edit_records"):
		var node=rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node):works.append(str(rec.get("token","")))
	var expected:=["lsystem_dungeon","catalyst_vent","mesh_grammar_petal_flower","dark_sphere","dragon_room","CityGenerator","grammar_seed","catalyst_prompter_box","mesh_grammar_coral_fingers"]
	check("All nine authored works retained once",expected.all(func(t):return works.count(t)==1))
	check("Original miniature retained",source.has_node("OriginalModel") and source.get_node("OriginalModel").get_child_count()>0)
	var approach:Vector3=source.to_global(Vector3(0,.01,3.2))
	check("Controls and point have clear supported reachable approach",clear_body(approach) and not floor_at(approach).is_empty() and hand.point.global_position.distance_to(approach+Vector3.UP*1.2)<.85)
	await snapshot("plan",source.to_global(Vector3(7,8,5)),source.to_global(Vector3(0,0,-4)),70)
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	for id in ["PLAN","BUILD","WIDTH","ROOMS","RESET","RULE"]:
		var r:Dictionary=await driver.press(desk.buttons[id],approach)
		check("Nearby pointer reaches "+id,str(r.get("hover","")) not in ["","none","null","nothing"])
	await driver.teardown();driver.queue_free();await tick()
	desk.act("RESET");var records:Dictionary=desk.records.duplicate(true)
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=hand.point.global_position;hand.point.pick_up(pickup);await tick();await tick()
	controller.global_position=hand.to_global(Vector3(.35,1.18,2.55));await tick();await tick();await tick()
	check("Held point chooses width without rewriting",hand.point.is_picked_up() and desk.width_index==2 and desk.records==records)
	hand.point.action();await tick();check("Held trigger builds existing construction",desk.built)
	origin.hide();await snapshot("hand",source.to_global(Vector3(1.7,2.1,3.7)),source.to_global(Vector3(0,1.14,2.2)),70)
	var person:=Node3D.new();root.add_child(person);person.add_to_group("player_body");person.global_position=source.to_global(Vector3(0,1,-4))
	controller.global_position=hand.to_global(Vector3(-.35,1.18,2.55));await tick();await tick();hand.point.action()
	check("Occupied study refuses hand width and trigger changes",desk.width_index==2 and desk.built and not desk.notice.is_empty())
	person.global_position=source.to_global(Vector3(0,1,4));await tick();await tick()
	check("Leaving does not apply held refused choice",desk.width_index==2 and desk.built)
	controller.global_position=hand.to_global(Vector3(0,1.18,2.55));await tick();await tick();await tick()
	check("Fresh hand movement applies after exit",desk.width_index==1)
	hand.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Release parks point at selected width",not hand.point.held() and hand.point.position.is_equal_approx(Vector3(0,1.18,2.55)))
	person.queue_free();origin.queue_free();await tick()
	observations.widths=[];var exact:=true
	for i in 3:
		desk.width_index=i;desk.rebuild();var low:=100.0;var high:=-100.0
		for cell in desk.occupied:
			if cell.y==-20:low=minf(low,cell.x*desk.PITCH);high=maxf(high,(cell.x+1)*desk.PITCH)
		exact=exact and is_equal_approx(high-low,desk.WIDTHS[i]);observations.widths.append({"label":desk.WIDTHS[i],"measured":high-low})
	check("All advertised widths equal constructed inner widths",exact)
	desk.act("RESET");desk.act("BUILD");await tick()
	await snapshot("built",source.to_global(Vector3(7,8,5)),source.to_global(Vector3(0,0,-4)),70)
	var wide:Vector3=await traverse(source,Vector3(0,.99,1.5),Vector3(0,.99,-7.5))
	check("Actual0.6m capsule passes wide entrance and open junction",wide.distance_to(Vector3(0,.99,-7.5))<.03)
	await snapshot("inside",source.to_global(Vector3(0,1.7,-1)),source.to_global(Vector3(0,1.2,-5)),74)
	desk.act("ROOMS");await snapshot("room",source.to_global(Vector3(7,8,5)),source.to_global(Vector3(0,0,-4)),70)
	check("Two R records become one room without changing path",desk.records==records and desk.room_addresses.size()==1 and desk.room_cells.size()==784)
	desk.width_index=0;desk.rebuild();await tick()
	var narrow:Vector3=await traverse(source,Vector3(0,.99,1.5),Vector3(0,.99,-2))
	check("Same capsule stops at narrow entrance even with room enabled",narrow.z>.2)
	await snapshot("narrow",source.to_global(Vector3(0,1.7,1.65)),source.to_global(Vector3(0,1.2,-4)),76)
	desk.act("RESET");desk.act("BUILD");desk.act("ROOMS")
	await snapshot("above",map_at(Vector3(9.5,36,13)),map_at(Vector3(9.5,0,21)),70)
	var route_ok:=true;var samples:=0
	for route in [[Vector3(9.5,0,2),Vector3(2.1,0,4),Vector3(2.1,0,36),Vector3(9.5,0,36.5),Vector3(9.5,0,37)], [Vector3(9.5,0,2),Vector3(16.9,0,4),Vector3(16.9,0,36),Vector3(9.5,0,36.5)]]:
		for j in range(route.size()-1):
			var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
			for k in steps+1:
				var at:Vector3=map_at(a.lerp(b,float(k)/steps)+Vector3.UP*.01)
				route_ok=clear_body(at) and not floor_at(at).is_empty() and route_ok;samples+=1
	check("Supported outer routes reach onward opening",route_ok);observations.route_samples=samples
	if stream!=null:
		observations.entry=stream.get("_entry");observations.exit=stream.get("_exit")
		check("Entry and onward records nonempty and valid",not observations.entry.is_empty() and not observations.exit.is_empty() and not observations.entry.get("invalid",false) and not observations.exit.get("invalid",false))
	# Temporary printed study at the same transform; remove original collision first.
	desk.act("PLAN");source.hide()
	var study=load("res://doc/book/iterations/2026-10-09-architecture-a-place-to-pass/printed/architecture.gd").new();study.transform=source.global_transform;root.add_child(study)
	study.act("BUILD");study.act("ROOMS");await tick()
	await snapshot("student",study.to_global(Vector3(7,8,5)),study.to_global(Vector3(0,0,-4)),70)
	check("Printed reconstruction builds same occupied footprint inside museum",study.layout.occupied==desk.occupied and study.layout.rooms==desk.room_cells)
	study.queue_free();source.show();desk.act("RESET")
	observations.scope="Native Architecture hall, supplied desktop events, XRTools supplied poses, actual0.6m capsule collisions and sampled outer routes. No physical headset, independent student or full portal traversal."
