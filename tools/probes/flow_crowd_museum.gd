extends "res://tools/probes/transformation_encounters.gd"
var completed:=false
func landing_checks()->void:
	museum.call("flush_stamps")
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.process_mode=Node.PROCESS_MODE_DISABLED
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.process_mode=Node.PROCESS_MODE_DISABLED;player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var exposure:=CameraAttributesPractical.new();exposure.exposure_multiplier=.35;camera.attributes=exposure
	var h:=find_scene("/flow_crowd.gd")
	check("Walk-in crowd loads in the existing Flow Fields hall",h!=null)
	check("Original flow-field table remains",find_scene("/FlowFieldMain.gd")!=null)
	if h==null:return
	check("All twenty-four figures are present",h.figures.size()==24)
	var origin:=h.global_position-hall.global_basis*Vector3(22.5,0,7.5)
	var path:Array[Vector3]=[]
	for i in range(16):path.append(Vector3(11+i*.16,0,5.5))
	for i in range(21):path.append(Vector3(13.4,0,5.5+i*.1))
	for z in [-3.3,3.3]:
		for i in range(61):path.append(Vector3(15+i*.25,0,7.5+z))
	var supported:=true;var clear:=true
	var capsule:=CapsuleShape3D.new();capsule.radius=.24;capsule.height=1.7
	for p in path:
		var world:=origin+hall.global_basis*p
		if floor_at(world).is_empty():supported=false
		var q:=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=1;q.transform.origin=world+Vector3.UP*.9
		var hits:=hall.get_world_3d().direct_space_state.intersect_shape(q)
		if not hits.is_empty():clear=false;print("CROWD BLOCK ",p," ",hits[0].collider.get_path())
	check("Entrance and both sides of island have continuous floor",supported)
	check("Standing visitor can enter and walk around island",clear)
	var floor:=floor_at(h.to_global(h.HOME+Vector3(-.6,-1.18,0)))
	check("Point remains reachable at hand height",not floor.is_empty() and h.point.global_position.y-floor.position.y>1.05 and h.point.global_position.y-floor.position.y<1.35)
	await snapshot("hall-above",h.to_global(Vector3(-8,33,15)),h.to_global(Vector3(-8,0,0)),73)
	await snapshot("ready",h.to_global(Vector3(-7.8,1.7,-3.5)),h.to_global(Vector3(1,1,0)),90)
	var pointer:=Node3D.new();root.add_child(pointer);h.point.on_desktop_grab(pointer)
	h.point.global_position=h.to_global(h.HOME+Vector3(0,0,-.4));await create_timer(5).timeout
	print("CROWD CONTROL held=",h.point.held()," local=",h.point.position," home=",h.HOME," route=",h.model.route," ticks=",h.model.ticks," process=",h.is_physics_processing()," can=",h.can_process())
	check("Actual pickup selects destination A",h.model.route==-1 and h.point.held())
	check("A selection moves the crowd in the live hall",h.model.positions[0].distance_to(Vector3(-6.145,0,-1.075))>1)
	await snapshot("toward-a",h.to_global(Vector3(-5,9,5)),h.to_global(Vector3(0,0,0)),83)
	h.playing=false;await create_timer(.1).timeout
	var kept=h.model.positions.duplicate();h.point.action();await create_timer(.2).timeout
	check("Actual trigger hides the shared directions",not h.guides and not h.arrow_layer.visible)
	await snapshot("without-arrows",h.to_global(Vector3(-5,9,5)),h.to_global(Vector3(0,0,0)),83)
	check("Photograph comparison preserves positions",kept==h.model.positions)
	h.point.action();h.playing=true;camera.global_position=h.to_global(Vector3(-7.8,1.7,-3.5));camera.look_at(h.to_global(Vector3(1,1,0)))
	var started:=Time.get_ticks_msec()
	while h.model.arrived.count(true)<24 and Time.get_ticks_msec()-started<40000:await create_timer(.5).timeout
	observations.arrived_a=h.model.arrived.count(true)
	check("All bodies reach A in real-time museum run",h.model.route==-1 and h.model.arrived.count(true)==24 and h.model.positions[0].x>4)
	await snapshot("arrival",h.to_global(Vector3(1.5,2.1,-.5)),h.to_global(Vector3(5.5,1,-3.75)),76)
	h.point.global_position=h.to_global(h.HOME+Vector3(0,0,.4));await create_timer(1).timeout
	check("The same point can redirect the moving bodies to B",h.model.route==1 and h.model.arrived.count(true)<24)
	h.point.on_desktop_drop(pointer);await create_timer(2).timeout
	check("Dropping starts return and restores the hand point",h.model.route==0 and h.point.position.distance_to(h.HOME)<.01)
	started=Time.get_ticks_msec()
	while h.model.arrived.count(true)<24 and Time.get_ticks_msec()-started<40000:await create_timer(.5).timeout
	check("All original bodies return without replacement",h.model.arrived.count(true)==24 and h.figures.size()==24)
	await snapshot("point-control",h.to_global(Vector3(-9.2,1.75,1)),h.to_global(Vector3(-8.2,1.7,0)),70)
	observations.position=xyz(h.global_position);observations.headset_tested=false;completed=true
func finish()->void:
	var result={"passed":completed and failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Native Flow Fields hall; synthetic pickup/action, real-time arrival/return, walking clearance and actual captures. No physical headset or Quest test."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "));quit(0 if result.passed else 1)
