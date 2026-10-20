extends "res://tools/probes/transformation_encounters.gd"
var completed := false
func landing_checks() -> void:
	museum.call("flush_stamps")
	var stream = museum.get("_portal_stream")
	if stream != null: stream.process_mode = Node.PROCESS_MODE_DISABLED
	var player = museum.get("_player")
	if player is Node3D:
		player.hide(); player.process_mode = Node.PROCESS_MODE_DISABLED; player.global_position = Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes := CameraAttributesPractical.new(); attributes.exposure_multiplier=.35; camera.attributes=attributes
	var h := find_scene("/listening_horde.gd")
	var colony := find_scene("/AntColonyOptimization.gd")
	check("Listening horde loads in actual ABM hall", h != null)
	check("Existing foraging and navigator comparisons retained", colony != null and find_scene("/NavigatorNoise.gd") != null)
	if h == null: return
	check("Twenty human-scale listeners begin resting", h.bodies.size()==20 and h.model.counts()==[20,0,0])
	var origin: Vector3 = h.global_position - hall.global_basis * Vector3(18.5,0,4.5)
	observations.origin=xyz(origin); observations.artifact=xyz(h.global_position)
	var supported:=true;var clear:=true
	var capsule:=CapsuleShape3D.new();capsule.radius=.24;capsule.height=1.7
	# Same-level approach from original hall, through side door and crowd gate.
	var approach:Array[Vector3]=[]
	for i in range(25): approach.append(Vector3(11+i*.25,0,5.5))
	for i in range(5): approach.append(Vector3(17,0,5.5-i*.25))
	for i in range(21): approach.append(Vector3(17+i*.25,0,4.5))
	for map_position in approach:
		var at:Vector3=origin+hall.global_basis*map_position
		if floor_at(at).is_empty():supported=false
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1;query.transform.origin=at+Vector3.UP*.9
		var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
		if not hits.is_empty():
			clear=false;print("BLOCKED APPROACH ",map_position," ",hits[0].collider.get_path())
	check("Side court has continuous floor support",supported)
	check("Standing visitor can reach the side court",clear)
	var old_route:=true
	for i in range(19):
		var at:=origin+hall.global_basis*Vector3(6.5,0,.5+i*.5)
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1;query.transform.origin=at+Vector3.UP*.9
		if floor_at(at).is_empty() or not hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty():old_route=false
	check("Original north-south museum route remains supported and clear",old_route)
	var gate_clear:=true
	for i in range(21):
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1
		query.transform.origin=h.to_global(Vector3(-2+i*.2,.9,0))
		if not hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty():gate_clear=false
	check("Crowd opening also admits a standing visitor",gate_clear)
	var wall_ray:=PhysicsRayQueryParameters3D.create(h.to_global(Vector3(-1,.5,2)),h.to_global(Vector3(1,.5,2)),1)
	check("Low partition has real physical collision",not hall.get_world_3d().direct_space_state.intersect_ray(wall_ray).is_empty())
	var stand_floor:=floor_at(h.to_global(h.HOME+Vector3(0,-1.18,-.6)))
	check("Sphere stand has reachable floor and hand height",not stand_floor.is_empty() and h.point.global_position.y-stand_floor.position.y>1.0 and h.point.global_position.y-stand_floor.position.y<1.4)
	await snapshot("resting",h.to_global(Vector3(-4.3,1.7,-2.8)),h.to_global(Vector3(1.1,1.05,.1)),80)
	await snapshot("hall-above",h.to_global(Vector3(-6,27,5)),h.to_global(Vector3(-6,0,0)),64)
	var pointer:=Node3D.new();root.add_child(pointer)
	h.point.on_desktop_grab(pointer);h.point.global_position=h.to_global(Vector3(-2.1,1.4,-1.6));h.point.action()
	check("Held trigger starts pulse in native hall",h.model.pulses==1 and h.heard==20)
	await create_timer(2).timeout
	h.point.global_position=h.to_global(Vector3(-3.5,1.4,2.4))
	check("Moving hand leaves native remembered marker behind",h.marker.position.is_equal_approx(Vector3(-2.1,0,-1.6)))
	await snapshot("investigating",h.to_global(Vector3(-4.3,1.7,-2.8)),h.to_global(Vector3(.7,1.05,0)),80)
	await create_timer(2.5).timeout
	await snapshot("a-place-kept",h.to_global(Vector3(-4.2,5.7,3.4)),h.to_global(Vector3(-.5,0,-.4)),76)
	var returned := false
	for i in range(35):
		if h.model.counts()==[20,0,0]: returned=true;break
		await create_timer(1).timeout
	check("All listeners return after the live investigation",returned)
	h.point.on_desktop_drop(pointer);await create_timer(2).timeout
	check("Released sphere returns to its stand",h.point.position.distance_to(h.HOME)<.01)
	check("No fixed scene replacement during interaction",h.bodies.size()==20)
	observations.counts_at_end=h.model.counts();observations.last_pulse=xyz(h.recorded_position)
	observations.headset_tested=false
	completed=true

func finish() -> void:
	var result:Dictionary={"passed":completed and failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Actual ABM museum, synthetic pickup/action, live agent movement and native screenshots. Physical headset untested."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if result.passed else 1)
