extends "res://tools/probes/transformation_encounters.gd"
## Entry-to-exit clearance and real desktop approach; same cameras before/after.
var origin: Vector3
func at(p: Vector3) -> Vector3: return origin + hall.global_basis * p
func clearance(p: Vector3) -> Array:
	var shape := CapsuleShape3D.new(); shape.radius = 0.3; shape.height = 1.8
	var q := PhysicsShapeQueryParameters3D.new(); q.shape = shape
	q.transform.origin = p + Vector3(0,0.95,0); q.collision_mask = 1 | 4
	var walker = museum.get("_player")
	if walker is CollisionObject3D: q.exclude = [walker.get_rid()]
	return hall.get_world_3d().direct_space_state.intersect_shape(q, 16)
func support(p: Vector3) -> bool:
	var count := 0
	for offset in [Vector3.ZERO,Vector3(0.12,0,0.08),Vector3(-0.12,0,0.08),Vector3(0.12,0,-0.08),Vector3(-0.12,0,-0.08)]:
		var hit := floor_at(p+offset)
		if not hit.is_empty() and hit.normal.y > 0.8: count += 1
	return count >= 3
func landing_checks() -> void:
	museum.call("flush_stamps"); await create_timer(1).timeout
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	var after: bool = spec.get("after", false)
	var stream = museum.get("_portal_stream")
	stream.set_process(false); stream.set_physics_process(false)
	var player = museum.get("_player")
	if player is Node3D:
		player.hide(); player.set_process(false); player.set_physics_process(false); player.global_position = Vector3(0,-100,0)
	await tick(); await tick()
	camera.set_cull_mask_value(19,false)
	var attributes := CameraAttributesPractical.new(); attributes.exposure_multiplier = 0.45; camera.attributes = attributes
	var desk = find_scene("/timing_machines/pg_workshop.gd")
	check("Existing workshop bound to its unchanged artifacts", desk != null and desk.ready_for_input)
	if desk == null: return
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_id+"/map_data.json"))
	var dims: Dictionary = doc.map_info.dimensions
	var cell := Vector2i.ZERO
	for z in doc.layers.interactables.size():
		for x in doc.layers.interactables[z].size():
			if str(doc.layers.interactables[z][x]).begins_with("pg_workshop_console"):
				cell = Vector2i(x,z)
	origin = desk.global_position - hall.global_basis * Vector3(cell.x+0.5,0,cell.y+0.5)
	var centre: float = int(dims.width)/2 + 0.5
	var depth: float = dims.depth
	observations.entry = stream.get("_entry"); observations.exit = stream.get("_exit")
	observations.desk_position = xyz(desk.global_position)
	var valid_entry: bool = not observations.entry.is_empty() and not observations.entry.get("invalid",false)
	var valid_exit: bool = not observations.exit.is_empty() and not observations.exit.get("invalid",false)
	check("Authored entrance valid" if after else "Before: recorded entrance obstruction reproduced",valid_entry if after else not valid_entry)
	check("Authored onward exit valid",valid_exit)
	var start := Vector3(centre,0.05,1.5)
	var route: Array[Vector3] = [start,Vector3(centre,0.05,3.5),Vector3(dims.width-2,0.05,3.5),Vector3(dims.width-2,0.05,depth-3.5),Vector3(centre,0.05,depth-3.5),Vector3(centre,0.05,depth-1.5)]
	if map_id == "PG_Sculpted_Forms":
		# The left-hand circuit crosses in front of the relocated desk, not through it.
		route = [start,Vector3(centre,0.05,2.1),Vector3(3,0.05,2.1),Vector3(3,0.05,23),Vector3(20,0.05,23),Vector3(20,0.05,40.5),Vector3(centre,0.05,40.5),Vector3(centre,0.05,42.5)]
	var blocked: Array = []; var unsupported: Array = []; var samples := 0
	for j in range(route.size()-1):
		var a := route[j]; var b := route[j+1]; var steps := ceili(a.distance_to(b)/0.20)
		for k in steps+1:
			var p := a.lerp(b,float(k)/steps); var world := at(p); samples += 1
			var hits := clearance(world)
			if not hits.is_empty(): blocked.append({"at":xyz(p),"collider":str(hits[0].collider.get_path())})
			if not support(world): unsupported.append(xyz(p))
	observations.route = {"waypoints":route.map(func(p):return xyz(p)),"samples":samples,"blocked":blocked,"unsupported":unsupported,"clear":blocked.is_empty() and unsupported.is_empty()}
	if after:
		check("Continuous capsule route begins at authored entrance and reaches exit",blocked.is_empty())
		check("Route has floor support throughout",unsupported.is_empty())
	await snapshot("entrance",at(Vector3(centre,1.7,0.7)),at(Vector3(centre,1.25,11)),72)
	await snapshot("above",at(Vector3(dims.width*0.5,depth*1.12,depth*0.5-0.2)),at(Vector3(dims.width*0.5,0,depth*0.5)),68)
	if map_id == "PG_Sculpted_Forms":
		var dome: Node3D = desk.other
		var stock: CSGBox3D = dome.get_node("CSGBox3D")
		var bounds := AABB(); var first := true
		for x in [-0.5,0.5]:
			for y in [-0.5,0.5]:
				for z in [-0.5,0.5]:
					var p: Vector3 = hall.global_basis.inverse()*(stock.to_global(Vector3(x,y,z)*stock.size)-origin)
					if first: bounds = AABB(p,Vector3.ZERO); first = false
					else: bounds = bounds.expand(p)
		var contained: bool = bounds.position.x >= 1 and bounds.end.x <= dims.width-1 and bounds.position.z >= 1 and bounds.end.z <= depth-1
		observations.dome = {"minimum":xyz(bounds.position),"maximum":xyz(bounds.end),"contained":contained,"scale":xyz(dome.scale)}
		if after: check("Dome stock footprint inside room with perimeter clearance",contained)
		else: check("Before: dome exceeds room footprint",not contained)
		await snapshot("dome",at(Vector3(17,2.2,5)),dome.to_global(Vector3(0,9,0)),64)
	if not after: return
	var driver = load("res://commons/testing/wcn_desktop_driver.gd").new(); museum.add_child(driver)
	await driver.spawn(at(start),museum); await tick()
	var destination := at(Vector3(centre,0.05,4.0))
	driver.aim_at(destination+Vector3.UP*1.6)
	await driver.walk("ui_up",30)
	var finish_position: Vector3 = driver.rig.global_position
	check("Real desktop movement clears original entrance station",finish_position.distance_to(at(start)) > 1.5 and finish_position.y > at(start).y-0.3)
	observations.desktop_entry = {"start":xyz(at(start)),"end":xyz(finish_position),"log":driver.log.duplicate(true)}
	var approach: Vector3 = desk.to_global(Vector3(0,0.05,2.9))
	await driver.teardown(); await tick()
	await driver.spawn(approach,museum); await tick()
	var old_rule: bool = desk.rule_card.visible
	var result: Dictionary = await driver.press(desk.buttons["RULE"],approach); await tick()
	check("Relocated desk responds to actual pointer input",desk.rule_card.visible != old_rule)
	observations.pointer = result
	await driver.teardown(); driver.queue_free(); await tick()
	check("Desk approach supported and clear",clearance(approach).is_empty() and support(approach))
	await snapshot("desk",desk.to_global(Vector3(0,1.65,3.2)),desk.to_global(Vector3(0,1.05,1.9)),63)
	if map_id == "PG_Sculpted_Forms":
		for expected in ["blank","core","section","cast"]:
			desk.act("CUT"); await create_timer(0.35).timeout
			check("Scaled dome retains state "+expected,desk.other.facture == expected)
	observations.scope = "Native real hall; authored portal records, continuous 1.8m capsule route, supplied desktop movement at entrance and pointer input at moved desk. No complete headset or portal-stream transition test."
