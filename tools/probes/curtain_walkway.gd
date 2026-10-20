extends "res://tools/probes/transformation_encounters.gd"

class Walker extends CharacterBody3D:
	var direction := Vector3.ZERO
	func _physics_process(_delta: float) -> void:
		velocity = direction * 1.8 + Vector3.DOWN * 2.0
		move_and_slide()

var map_origin: Vector3
var completed := false
func map_at(p: Vector3) -> Vector3: return map_origin + hall.global_basis * p
func finish() -> void:
	check("All curtain checks completed", completed)
	super.finish()
func vertex_world(body: SoftBody3D, index: int) -> Vector3:
	return PhysicsServer3D.soft_body_get_point_global_position(body.get_physics_rid(), index)

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(1).timeout
	var stream = museum.get("_portal_stream")
	if stream != null: stream.set_process(false); stream.set_physics_process(false)
	var player = museum.get("_player")
	if player is Node3D:
		player.hide(); player.set_process(false); player.set_physics_process(false)
		player.global_position = Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes := CameraAttributesPractical.new()
	attributes.exposure_multiplier = 0.18
	camera.attributes = attributes
	var desk = find_scene("/timing_machines/soft_workshop.gd")
	check("Existing carousel desk still binds both exhibits", desk != null and desk.ready_for_input and desk.model != null and desk.other != null)
	if desk == null: return
	map_origin = desk.global_position - hall.global_basis * Vector3(11.5,0,5.5)
	var gates: Array = []
	var rear: Node3D
	for node in hall.find_children("*", "Node3D", true, false):
		if node.get_script() == null or not str(node.get_script().resource_path).ends_with("/cloth_straps.gd"): continue
		if node.walkway: gates.append(node)
		else: rear = node
	gates.sort_custom(func(a,b): return (hall.global_basis.inverse() * a.global_position).z < (hall.global_basis.inverse() * b.global_position).z)
	check("Five coloured curtains plus the existing rear doorway are installed", gates.size() == 5 and rear != null)
	if gates.size() != 5 or rear == null: return
	check("Rear doorway stands on the floor instead of being sunk into it", absf((hall.global_basis.inverse() * (rear.global_position - map_origin)).y) < 0.001 and is_equal_approx(rear.strap_height, 3.0))
	var all_gates: Array = gates.duplicate(); all_gates.append(rear)
	var anchors: Array = []
	var colours: Array = []; var configurations: Array = []
	for gate in all_gates:
		var bodies: Array = gate.find_children("*", "SoftBody3D", true, false)
		check(gate.palette + ": exact body count; no hidden template", bodies.size() == gate.strap_count and gate.get_node_or_null("SoftBodyStrip") == null)
		var correct := true; var fit := true
		for body: SoftBody3D in bodies:
			var rest: PackedVector3Array = body.get_meta("lesson_rest")
			var start: Transform3D = body.get_meta("curtain_rest_transform")
			var pins: Array = body.get_meta("curtain_pins")
			var row_count := 6 if gate.walkway else 8
			var expected := 1 if gate.hanging == "single" else (2 if gate.hanging == "corners" else row_count)
			correct = correct and pins.size() == expected
			for i in pins:
				var p: Vector3 = start * rest[i]
				fit = fit and absf(p.y - gate.attachment_height()) < 0.001 and absf(p.x) < gate.curtain_span() * 0.5 + 0.021
				anchors.append({"body": body, "index": i, "world": gate.to_global(p)})
			correct = correct and start.basis.is_equal_approx(Basis.IDENTITY)
		check(gate.palette + ": unscaled geometry and intended attachment pattern", correct)
		check(gate.palette + ": top anchors meet inner frame", fit)
		var colliders: Array = gate._rig.find_children("*", "CollisionShape3D", false, false)
		var beam: CollisionShape3D = colliders[0]
		var left: CollisionShape3D = colliders[1]
		var right: CollisionShape3D = colliders[2]
		var underside: float = gate._rig.position.y + beam.position.y - beam.shape.size.y * 0.5
		var inner_left: float = left.position.x + left.shape.size.x * 0.5
		var inner_right: float = right.position.x - right.shape.size.x * 0.5
		check(gate.palette + ": physical beam and posts fit the actual rest envelope", absf(underside - gate.attachment_height()) < 0.001 and absf(inner_left + gate.curtain_span() * 0.5 + 0.02) < 0.001 and absf(inner_right - gate.curtain_span() * 0.5 - 0.02) < 0.001)
		if gate.walkway:
			colours.append(gate.palette); configurations.append(gate.hanging)
	check("Every walkway gate has a distinct palette and configuration", colours == ["coral","rose","violet","blue","mint"] and configurations == ["row","corners","single","staggered","arch"])
	check("Curtains share museum lighting and camera", gates.all(func(g): return g.find_children("*","Camera3D",true,false).is_empty() and g.find_children("*","Light3D",true,false).is_empty()))
	observations.palettes = colours; observations.hanging = configurations
	await snapshot("above", map_at(Vector3(15,62,9)), map_at(Vector3(15,0,27)),62)
	await snapshot("walkway", map_at(Vector3(2.7,5.2,9)), map_at(Vector3(7.5,1.7,20)),67)
	await snapshot("entrance", map_at(Vector3(7.5,1.65,10.1)), map_at(Vector3(7.5,1.7,18)),64)
	await snapshot("different-hems", map_at(Vector3(3.6,3.5,26.7)), map_at(Vector3(7.5,1.7,22.5)),65)
	await snapshot("rear-fit", rear.to_global(Vector3(2,2.6,4.5)), rear.to_global(Vector3(0,1.7,0)),55)
	# A finite, colliding capsule crosses the actual soft bodies under Jolt.
	var walker := Walker.new()
	walker.collision_layer = 4; walker.collision_mask = 1 | 4
	var shape := CollisionShape3D.new(); var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28; capsule.height = 1.7
	shape.shape = capsule; shape.position.y = 0.88; walker.add_child(shape)
	root.add_child(walker); walker.global_position = map_at(Vector3(7.5,0.03,11.5))
	walker.direction = hall.global_basis * Vector3.BACK
	var max_motion := 0.0
	var contacted: SoftBody3D = gates[0].get_node("LessonStrip4")
	var initial: Vector3 = vertex_world(contacted,0)
	for i in 510:
		await tick()
		max_motion = maxf(max_motion, initial.distance_to(vertex_world(contacted,0)))
		if i == 80:
			await snapshot("parting", map_at(Vector3(4.3,2.4,15)), map_at(Vector3(7.5,1.5,13.5)),62)
	walker.direction = Vector3.ZERO
	var end: Vector3 = hall.global_basis.inverse() * (walker.global_position - map_origin)
	observations.capsule_end = xyz(end); observations.free_vertex_motion = max_motion
	check("Colliding capsule crosses all five curtains", end.z > 26.1 and absf(end.x-7.5)<0.5)
	check("Soft strips physically move during passage", max_motion > 0.10)
	walker.queue_free(); await tick()
	var worst := 0.0
	for anchor in anchors:
		worst = maxf(worst, vertex_world(anchor.body, anchor.index).distance_to(anchor.world))
	observations.maximum_anchor_error = worst
	check("Pins remain attached after passage", worst < 0.015)
	# A support-only change must not replace or reset the cloth used by the desk.
	var specimen: Node3D = gates[0]
	var id: int = specimen.get_node("LessonStrip0").get_instance_id()
	specimen.apply_grid_config({"suspension":"hoop"}); await tick()
	check("Changing the support preserves cloth identity", specimen.get_node("LessonStrip0").get_instance_id() == id)
	specimen.apply_grid_config({"suspension":"gantry"}); await tick()
	# Safe travel around the procession remains possible, with a floor throughout.
	var gaps: Array = []
	for z in range(11,28):
		if floor_at(map_at(Vector3(7.5,0.01,z))).is_empty(): gaps.append(z)
	check("Walkway has continuous museum floor", gaps.is_empty())
	observations.scope = "Native Endless Museum and Jolt. Actual capsule/cloth contact, dimensional and attachment checks. No headset or Quest performance claim."
	completed = true
