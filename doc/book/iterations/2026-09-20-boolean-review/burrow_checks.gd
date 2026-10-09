
func investigate_burrow(nodes: Dictionary, walker: CharacterBody3D, report: Dictionary, origin: Vector3) -> void:
	var burrow: Node3D = nodes.get("boolean_burrow")
	if burrow == null or walker == null:
		failures.append("Missing burrow or museum body")
		return
	var centres: Array = burrow.get("_centres")
	var measurements := {"graph":burrow.call("report"), "centres":[], "body":[], "journey":[]}
	for c in centres: measurements.centres.append(arr(c))
	for c in walker.find_children("*", "CollisionShape3D", true, false):
		measurements.body.append({"shape":str(c.shape), "height":c.shape.height if c.shape is CapsuleShape3D else 0.0, "radius":c.shape.radius if c.shape is CapsuleShape3D else 0.0, "position":arr(c.position)})
	var first: Vector3 = centres[0]
	walker.global_position = burrow.to_global(Vector3(-burrow.block_size.x * 0.5 - 1.0, 0.08, first.z))
	walker.velocity = Vector3.ZERO
	for i in mini(centres.size(), 6):
		var local_target: Vector3 = centres[i]
		local_target.y = 0.02
		var target := burrow.to_global(local_target)
		var before := walker.global_position
		for step in range(180):
			var d := target - walker.global_position; d.y = 0
			var dir := d.normalized() if d.length() > 0.06 else Vector3.ZERO
			walker.velocity = Vector3(dir.x*2.0, 0.0 if walker.is_on_floor() else walker.velocity.y-11.0/60.0, dir.z*2.0)
			walker.move_and_slide()
			await physics_frame
		var error := Vector2(walker.global_position.x-target.x, walker.global_position.z-target.z).length()
		measurements.journey.append({"step":i,"passed":error<0.25,"from":arr(before-origin),"end":arr(walker.global_position-origin),"target":arr(target-origin),"horizontal_error":error})
		if error >= 0.25: break
	measurements["all_six_reached"] = measurements.journey.size()==6 and measurements.journey.all(func(j): return j.passed)
	if str(burrow.carver_profile) == "level":
		if not measurements.all_six_reached: failures.append("Level-floor inward route failed")
		measurements["return"] = []
		for i in range(4, -2, -1):
			var local_target: Vector3 = centres[maxi(i, 0)]
			local_target.y = 0.02
			if i < 0: local_target.x = -burrow.block_size.x * 0.5 - 1.0
			var target := burrow.to_global(local_target)
			await walk_to(walker, target, 180)
			var error := Vector2(walker.global_position.x-target.x, walker.global_position.z-target.z).length()
			measurements["return"].append({"step":i,"passed":error<0.25,"end":arr(walker.global_position-origin)})
			if error>=0.25: failures.append("Return from burrow failed at " + str(i))
		# Try an intact wall, away from any cutter, using the very same body.
		walker.global_position = burrow.to_global(Vector3(0,0.08,-6.0))
		walker.velocity = Vector3.ZERO
		await walk_to(walker,burrow.to_global(Vector3(0,0.02,-3.5)),150)
		var local_end := burrow.to_local(walker.global_position)
		measurements["wall_stops_body"] = local_end.z < -4.5 and local_end.z > -5.0
		if not measurements.wall_stops_body: failures.append("Stock wall did not stop the body")
	report["burrow"] = measurements

func walk_to(walker: CharacterBody3D, target: Vector3, frames: int) -> void:
	for step in frames:
		var d := target-walker.global_position;d.y=0
		var dir := d.normalized() if d.length()>0.06 else Vector3.ZERO
		walker.velocity = Vector3(dir.x*2.0, 0.0 if walker.is_on_floor() else walker.velocity.y-11.0/60.0, dir.z*2.0)
		walker.move_and_slide()
		await physics_frame
