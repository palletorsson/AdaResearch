extends "res://tools/probes/transformation_encounters.gd"
## This hall's real museum: edge fit, fire below the deck, and capsule passage.
func collider_bounds(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for shape in node.find_children("*", "CollisionShape3D", true, false):
		if shape.get_parent() is PhysicsBody3D and shape.shape != null and not shape.disabled:
			var box: AABB = shape.global_transform * shape.shape.get_debug_mesh().get_aabb()
			result = box if first else result.merge(box)
			first = false
	return result

func landing_checks() -> void:
	await super.landing_checks()
	var bridge := find_scene("/rotation_cube.gd")
	var bank := find_scene("/adjustable_landing.gd")
	if bridge == null or bank == null: return
	var b := collider_bounds(bridge)
	var landing_box := collider_bounds(bank.landing)
	check("aligned plank is three metres long", absf(b.size.z-3.0)<0.002)
	check("plank end meets landing without overlap or gap", absf(b.end.z-landing_box.position.z)<0.003)
	check("plank and landing supporting faces share deck height", absf(b.end.y-landing_box.end.y)<0.003)
	var approach := floor_at(Vector3(b.get_center().x,b.end.y,b.position.z-0.12))
	check("near bank reaches the plank at the same height", not approach.is_empty() and absf(approach.position.y-b.end.y)<0.003)
	check("bank readout starts at meeting edges", "edges meet" in bank.readout.text)
	bank.slider.set_normalized_value(1.0);bank.slider.slider_moved.emit(Vector3.ZERO)
	await create_timer(4.2).timeout
	var far := collider_bounds(bank.landing)
	check("full bank displacement opens a one-metre gap", absf(far.position.z-b.end.z-1.0)<0.003 and "gap 1.00 m" in bank.readout.text)
	bank.reset_landing();await create_timer(4.2).timeout
	var fires := hall.find_children("BasinFire", "Area3D", true, false)
	check("basin fire exists in the actual museum hall", not fires.is_empty())
	var fire_tops: Array = []
	var fire_shapes := 0
	for area in fires:
		check("fire has an active fall detector", area.monitoring and area.body_entered.get_connections().size()>0)
		for shape in area.find_children("*", "CollisionShape3D", true, false):
			var bounds: AABB = shape.global_transform * shape.shape.get_debug_mesh().get_aabb()
			fire_tops.append(bounds.end.y-b.end.y)
			fire_shapes += 1
			check("fire remains below the crossing deck", bounds.end.y < b.end.y-0.5)
	check("fire has a physical detector", fire_shapes > 0)
	# A single packed bed can cover several openings. Test coverage, not count.
	for suffix in ["/transport_cube.gd", "/scale_cube.gd", "/rotation_cube.gd"]:
		var crossing := find_scene(suffix)
		var covered := false
		if crossing != null:
			for area in fires:
				for shape in area.find_children("*", "CollisionShape3D", true, false):
					var bounds: AABB = shape.global_transform * shape.shape.get_debug_mesh().get_aabb()
					var p := Vector3(crossing.global_position.x,bounds.get_center().y,crossing.global_position.z)
					covered = covered or bounds.has_point(p)
		check("fire covers the basin under " + suffix, covered)
	observations["bridge_size_m"] = xyz(b.size)
	observations["aligned_overlap_m"] = b.end.z-landing_box.position.z
	observations["fire_top_below_deck_m"] = fire_tops
	# Check both directions with gravity against the actual museum colliders.
	var walker := CharacterBody3D.new()
	walker.name = "CrossingFitWalker"
	walker.collision_layer = 1;walker.collision_mask = 1
	walker.floor_snap_length = 0.15
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius=0.22;capsule.height=1.6
	shape.shape=capsule;shape.position.y=0.8
	walker.add_child(shape);root.add_child(walker)
	for direction in [1.0,-1.0]:
		walker.global_position = Vector3(b.get_center().x,b.end.y+0.04,b.get_center().z-direction*2.0)
		walker.velocity=Vector3.ZERO
		var minimum_y := walker.global_position.y
		for i in range(150):
			await physics_frame
			walker.velocity=Vector3(0,walker.velocity.y-9.8/60.0,direction*2.0)
			walker.move_and_slide()
			minimum_y=minf(minimum_y,walker.global_position.y)
		check("capsule crosses meeting edges in direction " + str(direction), direction*(walker.global_position.z-b.get_center().z)>2.0 and minimum_y>b.end.y-0.07 and absf(walker.global_position.y-b.end.y)<0.03)
	walker.queue_free()
	await snapshot("rotation-eye-level",bank.to_global(Vector3(3,1.7,-4.8)),bank.to_global(Vector3(1.9,-0.25,0)),65)
	var ferry := find_scene("/transport_cube.gd")
	if ferry != null:
		await snapshot("fire-under-the-ferry",ferry.to_global(Vector3(-2,2.2,-3)),ferry.to_global(Vector3(0,-0.3,1)),65)
	var player: CharacterBody3D = museum.get("_player")
	check("museum has the actual desktop player for fall test", player != null)
	if player != null and not fires.is_empty():
		var fire_shape: CollisionShape3D = fires[0].find_children("*", "CollisionShape3D", true, false)[0]
		var fire_box: AABB = fire_shape.global_transform * fire_shape.shape.get_debug_mesh().get_aabb()
		var fall := Vector3(bridge.global_position.x,fire_box.get_center().y,bridge.global_position.z)
		var deaths_before: int = museum.get("_deaths")
		player.global_position=fall
		player.velocity=Vector3.ZERO
		await create_timer(5.0).timeout
		check("entering fire invokes the museum death and reset", int(museum.get("_deaths")) == deaths_before+1 and not bool(museum.get("_dying")) and player.global_position.distance_to(fall)>2.0)
		observations["fire_reset_position"] = xyz(player.global_position)
