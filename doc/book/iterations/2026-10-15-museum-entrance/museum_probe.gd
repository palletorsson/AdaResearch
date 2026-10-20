extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	root.size = Vector2i(1440,1000)
	museum.call("flush_stamps")
	await create_timer(0.8).timeout
	var navigation: Node3D = museum.get("_portal_stream")
	check("portal navigation is ready", navigation != null and not navigation.get("busy"))
	if navigation == null: return
	navigation.set_process(false)
	var entry: Dictionary = navigation.get("_entry")
	var departure: Dictionary = navigation.get("_exit")
	observations.entry = str(entry)
	observations.departure = str(departure)
	check("authored entrance is used without fallback", not entry.is_empty() and not entry.get("invalid",false) and entry.get("cage",false))
	check("authored teleporter is used without fallback", not departure.is_empty() and not departure.get("invalid",false) and departure.get("cell",Vector2i(-1,-1)) == Vector2i(6,36))
	check("old sliding gate is absent", (museum.get("_gate") as Dictionary).is_empty())
	check("enclosed entrance exists", hall.has_node("HallPortals/EntranceLanding/EntryRoomCollision"))
	var tile: Array = hall.get_meta("em_tile")
	check("complete back row stays wall", (tile[-1] as Array).all(func(c): return str(c) == "4"))
	check("front has the authored three-cell entrance", str(tile[0][5]) == "1" and str(tile[0][6]) == "1" and str(tile[0][7]) == "1")
	# Negative controls: maps that omit the option, and continuous corridors,
	# keep their existing physical passage behavior.
	var solid_tile: Array = [["4","4","4","4","4","4","4"], ["4","1","1","1","1","1","4"], ["4","1","1","1","1","1","4"], ["4","4","4","4","4","4","4"]]
	var unchanged: Array = museum.call("_authored_passages",solid_tile,{"kind":"none"})
	check("undeclared maps keep the legacy exit opening", (unchanged[-1] as Array).has("1"))
	museum.set("_portal_mode",false)
	var corridor: Array = museum.call("_authored_passages",solid_tile,{"kind":"none","carve_exit":false})
	museum.set("_portal_mode",true)
	check("continuous museum still has a walk-through exit", (corridor[-1] as Array).has("1"))
	check("passage builder does not mutate the authored tile", (solid_tile[-1] as Array).all(func(c): return str(c)=="4"))
	var base := hall.global_position + Vector3(0,0,4)
	var space := hall.get_world_3d().direct_space_state
	for x in [5.5,6.5,7.5]:
		var ray := PhysicsRayQueryParameters3D.create(base+Vector3(x,1.4,37.4),base+Vector3(x,1.4,39.2),1)
		var hit := space.intersect_ray(ray)
		check("back wall physically closes former opening x="+str(x), not hit.is_empty() and absf(hit.position.z-base.z-38.0)<0.06)
	var arrival: Vector3 = navigation.get("_arrival")
	observations.arrival = xyz(arrival-base)
	var walker: CharacterBody3D = museum.get("_player")
	# Floor rays must not hit the visitor parked on the tested patch of floor.
	if walker != null:
		walker.global_position=base+Vector3(10.5,0.05,34.5)
		await physics_frame
		await physics_frame
	# A ray exactly on a tile-box edge may return its vertical side normal.
	# Offset the samples from those edges; the walker test crosses the joins.
	for z in [-1.35,-0.5,0.5,1.35,2.35]:
		var ground := floor_at(base+Vector3(6.5,0.05,z))
		observations["floor_"+str(z)] = {"position":xyz(ground.position-base), "collider":str(ground.collider.get_path())} if not ground.is_empty() else {}
		var supported: bool = not ground.is_empty() and navigation.call("_supported",ground.position+Vector3.UP*0.05)
		if not supported and not ground.is_empty():
			var capsule := CapsuleShape3D.new()
			capsule.radius=0.3; capsule.height=1.8
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape=capsule
			query.transform.origin=ground.position+Vector3.UP
			if walker != null: query.exclude=[walker.get_rid()]
			var contacts: Array = []
			for hit in space.intersect_shape(query,16):
				contacts.append({"path":str(hit.collider.get_path()),"layer":hit.collider.collision_layer})
			var rays: Array = []
			for offset in [Vector3.ZERO,Vector3(0.3,0,0),Vector3(-0.3,0,0),Vector3(0,0,0.3),Vector3(0,0,-0.3)]:
				var ray := PhysicsRayQueryParameters3D.create(ground.position+offset+Vector3.UP*0.2,ground.position+offset-Vector3.UP*0.15)
				var hit := space.intersect_ray(ray)
				rays.append({"path":str(hit.collider.get_path()),"normal":xyz(hit.normal)} if not hit.is_empty() else {})
			observations["support_failure_"+str(z)]={"contacts":contacts,"rays":rays}
		check("supported entrance approach z="+str(z), supported)
	if walker != null:
		walker.global_position=arrival
		walker.velocity=Vector3.ZERO
		await walk_to(walker,base+Vector3(6.5,0,3.0),3.0)
		check("actual walker enters through the new doorway", Vector2(walker.global_position.x-6.5,walker.global_position.z-base.z-3.0).length()<0.2)
		walker.global_position=base+Vector3(9.5,0.05,36.5)
		walker.velocity=Vector3.ZERO
		await walk_to(walker,base+Vector3(9.5,0,39.5),2.0)
		check("actual walker cannot walk out through back wall", walker.global_position.z-base.z < 38.0 and walker.global_position.z-base.z > 37.0)
	await snapshot("entrance",base+Vector3(6.5,1.65,-1.35),base+Vector3(6.5,1.6,5.0),70)
	await snapshot("entrance-from-hall",base+Vector3(6.5,1.65,3.2),base+Vector3(6.5,1.65,-0.8),72)
	await snapshot("closed-exit",base+Vector3(8.5,1.65,33.8),base+Vector3(6.5,1.6,38.3),72)
	# Trigger the production crossing through its normal proximity detector.
	if not departure.is_empty() and not departure.get("invalid",false):
		museum.set_process(true) # destination stamps need the normal loader tick
		var p: Vector3 = departure.door
		var inward: Vector3 = departure.inward
		navigation.call("_move_player",p+inward*0.2)
		navigation.set("_armed",true)
		navigation.set("_previous_eye",p+inward+Vector3.UP*1.65)
		navigation.set("_have_previous_eye",true)
		navigation.call("_process",0.1)
		check("approaching teleporter starts crossing", navigation.get("busy"))
		var started := Time.get_ticks_msec()
		while navigation.get("busy") and navigation.get("phase") != "error" and Time.get_ticks_msec()-started < 65000:
			await process_frame
		var current: Dictionary = navigation.get("_current")
		observations.next_map = str(current.get("map",""))
		observations.crossing_phase = navigation.get("phase")
		check("teleporter loads Random Entropy", current.get("map","") == "Random_Entropy" and navigation.get("phase") == "idle")
		check("destination arrival is supported", navigation.call("_arrival_supported"))
	observations.scope = "Native hall: actual CharacterBody traversal and production teleporter crossing; no headset comfort claim."

func walk_to(walker: CharacterBody3D, target: Vector3, seconds: float) -> void:
	for i in range(int(seconds*60)):
		var diff := target-walker.global_position
		diff.y=0
		var direction := diff.normalized() if diff.length()>0.05 else Vector3.ZERO
		walker.velocity=Vector3(direction.x*2,0 if walker.is_on_floor() else walker.velocity.y-11.0/60.0,direction.z*2)
		walker.move_and_slide()
		await physics_frame
