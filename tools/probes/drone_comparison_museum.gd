extends "res://tools/probes/transformation_encounters.gd"
var completed:=false
func landing_checks() -> void:
	museum.call("flush_stamps")
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.process_mode=Node.PROCESS_MODE_DISABLED
	var player=museum.get("_player")
	if player is Node3D:
		player.hide();player.process_mode=Node.PROCESS_MODE_DISABLED;player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.35;camera.attributes=attributes
	var h:=find_scene("/drone_comparison.gd")
	var flock:=find_scene("/boid_manager.gd");var fish:=find_scene("/fish_school.gd")
	check("Drone comparison loads inside the Boids museum hall",h!=null)
	check("Original flock, aquarium and fish school remain",flock!=null and flock.get_boids().size()==100 and fish!=null and fish.boids.size()==72 and find_scene("/boids_aquarium.gd")!=null)
	check("West observation balcony is retained",hall.get_node_or_null("ObservationBalcony")!=null)
	if h==null:return
	check("Both flights contain twelve actual Boid-derived drones",h.flights.size()==2 and h.flights[0].drones.size()==12 and h.flights[1].drones[0] is Boid)
	var origin:=h.global_position-hall.global_basis*Vector3(20.5,0,6.5)
	observations.artifact=xyz(h.global_position)
	var points:Array[Vector3]=[]
	for i in range(15):points.append(Vector3(11+i*.2,0,6.5))
	for i in range(9):points.append(Vector3(13.8,0,6.5+i*.1))
	for i in range(60):points.append(Vector3(13.8+i*.2,0,7.3))
	var supported:=true;var clear:=true
	var capsule:=CapsuleShape3D.new();capsule.radius=.24;capsule.height=1.7
	for p in points:
		var world:=origin+hall.global_basis*p
		if floor_at(world).is_empty():supported=false
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1;query.transform.origin=world+Vector3.UP*.9
		var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
		if not hits.is_empty():clear=false;print("DRONE APPROACH BLOCK ",p," ",hits[0].collider.get_path())
	check("East court and aisle have floor support",supported)
	check("Standing visitor can enter, reach point and pass between flights",clear)
	var floor:=floor_at(h.to_global(h.HOME+Vector3(-.7,-1.18,0)))
	check("Point is reachable at hand height",not floor.is_empty() and h.point.global_position.y-floor.position.y>1.05 and h.point.global_position.y-floor.position.y<1.35)
	check("Only stand seals drone court navigation",h.get_museum_occupied_cells().size()<=4)
	await create_timer(12).timeout
	var error:=0.0
	for d in h.flights[0].drones:error+=d.position.distance_to(d.slot)
	error/=h.COUNT;observations.assigned_mean_error=error
	check("Assigned flight reaches its formation in native hall",error<.15)
	await snapshot("two-flights",h.to_global(Vector3(-5.0,1.75,0)),h.to_global(Vector3(.4,2.05,0)),103)
	await snapshot("hall-above",h.to_global(Vector3(-9,32,10)),h.to_global(Vector3(-9,0,0)),73)
	# Approach at visitor height before exercising the hand control.
	camera.global_position=h.to_global(Vector3(-5.0,1.75,0));camera.look_at(h.to_global(Vector3(.4,2.05,0)))
	await create_timer(1).timeout
	var pointer:=Node3D.new();root.add_child(pointer);h.point.on_desktop_grab(pointer)
	h.point.global_position=h.to_global(h.HOME+Vector3(1,.25,.4));await create_timer(4).timeout
	print("DRONE CONTROL held=",h.point.held()," physics=",h.is_physics_processing()," can=",h.can_process()," mode=",h.process_mode," position=",h.point.position," offset=",h.target_offset," guides=",h.guides)
	check("Held point shifts both flight targets in the museum",h.target_offset.distance_to(Vector3(1,.25,.4))<.01)
	check("Visible target markers show the actual destinations",h.beacons[0].position.is_equal_approx(h.flights[0].position+h.target_offset) and h.beacons[1].position.is_equal_approx(h.flights[1].position+h.target_offset))
	# Capture while the moved destination is still producing a visible correction.
	h.point.global_position=h.to_global(h.HOME+Vector3(-1,.1,-.4))
	await snapshot("hand-guidance",h.to_global(Vector3(-4.8,6.5,.1)),h.to_global(Vector3(0,1.5,0)),105)
	h.point.action();await create_timer(.25).timeout
	print("DRONE GUIDES held=",h.point.held()," process=",h.is_processing()," guides=",h.guides," beacon=",h.beacons[0].visible," slot=",h.slots[0].visible," elapsed=",h.elapsed)
	check("Trigger hides both flights' guidance",not h.guides and not h.beacons[0].visible and not h.slots[0].visible)
	await snapshot("without-guides",h.to_global(Vector3(-5.0,1.75,0)),h.to_global(Vector3(.4,2.05,0)),103)
	h.point.action();h.point.on_desktop_drop(pointer);await create_timer(2).timeout
	check("Release restores neutral control without replacing drones",h.target_offset.length()<.01 and h.point.position.distance_to(h.HOME)<.01 and h.flights[0].drones.size()==12)
	await snapshot("point-control",h.to_global(Vector3(-7.5,1.7,.5)),h.to_global(Vector3(-5.6,1.65,0)),70)
	observations.headset_tested=false;completed=true

func finish() -> void:
	var result:Dictionary={"passed":completed and failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Native Boids hall, synthetic pickup/action, live flights, physical floor/capsule checks and actual renders. No physical headset or Quest performance test."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if result.passed else 1)
