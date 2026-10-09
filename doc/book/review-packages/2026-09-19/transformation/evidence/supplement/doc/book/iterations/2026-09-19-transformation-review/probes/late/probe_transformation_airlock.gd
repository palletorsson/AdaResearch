extends SceneTree
## Focused physical contract for the cumulative Transformation exit.
## Real scene, physics rays and a 0.44 m CharacterBody capsule; no museum fixture.
## Run after autoload initialization: godot --headless --path REPO --xr-mode off
## --script res://commons/testing/probe_transformation_airlock.gd
const SCENE := "res://commons/artifacts/transformation_airlock/transformation_airlock.tscn"
const SCRIPT := "res://commons/artifacts/transformation_airlock/transformation_airlock.gd"
const OUT := "res://doc/book/iterations/2026-09-19-transformation-review/evidence/late/airlock-checks.json"
var checks: Array = []
var failures: Array[String] = []
var observations: Dictionary = {}
var world: Node3D
var source_sha256: String

func _initialize() -> void: run.call_deferred()

func check(title: String, passed: bool, detail: Variant = null) -> void:
	checks.append({"name":title,"passed":passed,"detail":detail})
	if not passed: failures.append(title)
	print("[airlock-test] ", "PASS " if passed else "FAIL ", title, " ", str(detail) if detail != null else "")

func tick() -> void:
	await physics_frame
	await process_frame

func wait_seconds(seconds: float) -> void:
	for i in ceili(seconds * Engine.physics_ticks_per_second): await tick()

func xyz(value: Vector3) -> Array: return [value.x,value.y,value.z]

func fixture(yaw: float, at: Vector3) -> Dictionary:
	var frame := Node3D.new()
	frame.position = at
	frame.rotation.y = yaw
	world.add_child(frame)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(24,0.2,24)
	floor_shape.shape = box
	floor_shape.position.y = -0.1
	floor_body.add_child(floor_shape)
	frame.add_child(floor_body)
	var door: Node3D = load(SCENE).instantiate()
	frame.add_child(door)
	door.set_physics_process(false)
	return {"frame":frame,"door":door}

func capsule(feet: Vector3, layer: int = 1) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = "PhysicalVisitor"
	body.collision_layer = layer
	body.collision_mask = 1
	body.floor_snap_length = 0.12
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.22
	shape.height = 1.7
	collider.shape = shape
	collider.position.y = 0.85
	body.add_child(collider)
	world.add_child(body)
	body.global_position = feet
	return body

func walk(frame: Node3D, x: float, start_z: float, end_z: float) -> Dictionary:
	var start := frame.to_global(Vector3(x,0.01,start_z))
	var direction := frame.global_basis.z.normalized() * signf(end_z-start_z)
	var walker := capsule(start)
	var travel := 0.0
	var stalled := 0
	var minimum_y := start.y
	var side_drift := 0.0
	var wanted := absf(end_z-start_z)
	for i in ceili((wanted / 2.4 + 2.0) * Engine.physics_ticks_per_second):
		# move_and_slide chooses the engine's physics delta only within this signal.
		# Awaiting process_frame first would turn this into frame-rate-dependent walking.
		await physics_frame
		walker.velocity = direction * 2.4 + Vector3.UP * (walker.velocity.y - 9.8 / Engine.physics_ticks_per_second)
		walker.move_and_slide()
		var next_travel := (walker.global_position-start).dot(direction)
		stalled = stalled + 1 if next_travel-travel < 0.0005 else 0
		travel = next_travel
		minimum_y = minf(minimum_y,walker.global_position.y)
		side_drift = maxf(side_drift,absf(frame.to_local(walker.global_position).x-x))
		if travel >= wanted or stalled >= 40: break
	var result := {"arrived":travel >= wanted-0.02,"travel":travel,"local_end":xyz(frame.to_local(walker.global_position)),"minimum_y":minimum_y,"side_drift":side_drift}
	walker.queue_free()
	await tick()
	return result

func descendant_count(node: Node) -> int:
	var count := node.get_child_count()
	for child in node.get_children(): count += descendant_count(child)
	return count

func capsule_clearance(frame: Node3D) -> float:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.22
	shape.height = 1.7
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(frame.global_basis,frame.to_global(Vector3(0,0.88,-2)))
	query.motion = frame.global_basis.z * 4.0
	query.collision_mask = 1
	var fractions := world.get_world_3d().direct_space_state.cast_motion(query)
	return fractions[0] if fractions.size() > 0 else -1.0

func plate_probe(door: Node3D, leaf: AnimatableBody3D) -> Dictionary:
	var mesh: MeshInstance3D = leaf.get_node("Armor/PhysicalPlate")
	var aabb := mesh.mesh.get_aabb()
	var center := aabb.get_center()
	var cast_direction := mesh.global_basis.z.normalized()
	var bounds_error := 0.0
	var missed := 0
	var outside_false_hit := 0
	var space := world.get_world_3d().direct_space_state
	# Nine rays through independent points on the rendered solid plate. The expected
	# front face comes from its actual mesh AABB, not operation_values or shape.points.
	for u in [-0.65,0.0,0.65]:
		for v in [-0.65,0.0,0.65]:
			var local := center + Vector3(u*aabb.size.x*0.5,v*aabb.size.y*0.5,0)
			var middle := mesh.to_global(local)
			var expected := mesh.to_global(Vector3(local.x,local.y,aabb.position.z))
			var query := PhysicsRayQueryParameters3D.create(middle-cast_direction*0.8,middle+cast_direction*0.8,1)
			var hit := space.intersect_ray(query)
			if hit.is_empty() or hit.collider != leaf: missed += 1
			else: bounds_error = maxf(bounds_error,hit.position.distance_to(expected))
	# Rays just outside each transformed side must not still hit an old-sized hull.
	for sx in [-1.0,1.0]:
		var outside := mesh.to_global(center + Vector3(sx*aabb.size.x*0.5,0,0))
		outside += mesh.global_basis.x.normalized()*sx*0.045
		var query := PhysicsRayQueryParameters3D.create(outside-cast_direction*0.8,outside+cast_direction*0.8,1)
		var hit := space.intersect_ray(query)
		if not hit.is_empty() and hit.collider == leaf: outside_false_hit += 1
	return {"missed_inside":missed,"outside_false_hits":outside_false_hit,"face_error_m":bounds_error,"unit_physics_scale":leaf.global_basis.get_scale().distance_to(Vector3.ONE) < 0.00001}

func static_contract(fix: Dictionary, tag: String) -> void:
	var door: Node3D = fix.door
	var frame: Node3D = fix.frame
	var geometry_samples: Array = []
	var misses := 0
	var false_hits := 0
	var max_error := 0.0
	var all_unit := true
	var initial_nodes := descendant_count(door)
	for step in range(21):
		door.set("progress",float(step)/20.0)
		door.call("_apply_pose")
		await tick()
		var samples: Array = []
		for name in ["LeftLeaf","RightLeaf"]:
			var sample := plate_probe(door,door.get_node(name))
			misses += int(sample.missed_inside)
			false_hits += int(sample.outside_false_hits)
			max_error = maxf(max_error,float(sample.face_error_m))
			all_unit = all_unit and bool(sample.unit_physics_scale)
			samples.append(sample)
		geometry_samples.append({"progress":float(step)/20.0,"leaves":samples,"capsule_safe_fraction":capsule_clearance(frame)})
	check(tag+" rendered plates and physical front faces agree through 21 poses",misses == 0 and max_error < 0.002,{"misses":misses,"max_face_error_m":max_error,"interior_rays":378})
	check(tag+" shrinking hull does not keep its old width",false_hits == 0,{"outside_false_hits":false_hits,"outside_rays":84})
	check(tag+" moving physics bodies retain unit scale",all_unit)
	check(tag+" animation retains existing nodes",descendant_count(door) == initial_nodes,initial_nodes)
	door.set("progress",0.0)
	door.call("_apply_pose")
	await tick()
	var closed := await walk(frame,0.0,-2.0,2.0)
	check(tag+" closed door physically stops a 0.44m capsule",not closed.arrived and float(closed.travel) > 0.4 and float(closed.travel) < 2.0,closed)
	door.set("progress",1.0)
	door.call("_apply_pose")
	await tick()
	var open := await walk(frame,0.0,-2.0,2.0)
	check(tag+" fully open doorway admits the same capsule",open.arrived and float(open.side_drift)<0.01 and float(open.minimum_y)>frame.global_position.y-0.03,open)
	var reverse := await walk(frame,0.0,2.0,-2.0)
	check(tag+" fully open doorway is passable from the far side",reverse.arrived,reverse)
	observations[tag] = {"closed_walk":closed,"open_walk":open,"reverse_walk":reverse,"geometry_samples":geometry_samples}

func automatic_contract(fix: Dictionary) -> void:
	var frame: Node3D = fix.frame
	var door: Node3D = fix.door
	door.set("progress",0.0)
	door.call("_apply_pose")
	door.set_physics_process(true)
	var opening := float(door.get("opening_seconds"))
	var hold := float(door.get("empty_hold_seconds"))
	check("shipped timing remains a readable opening and empty hold",opening >= 4.0 and hold >= 2.5,{"opening_seconds":opening,"empty_hold_seconds":hold})
	var ball := RigidBody3D.new()
	ball.name = "PitBallMustNotTrigger"
	ball.freeze = true
	ball.collision_layer = 1
	ball.collision_mask = 0
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.25
	collision.shape = sphere
	ball.add_child(collision)
	world.add_child(ball)
	ball.global_position = frame.to_global(Vector3(0,1,-1))
	await wait_seconds(0.4)
	check("Pit-style ball does not open the door",float(door.get("progress"))==0.0 and not bool(door.get("occupied")))
	ball.queue_free()
	await tick()
	# XR player-body collision layer, with a genuine CharacterBody3D. No camera or
	# tracked rig is simulated here; the museum's actual XR path is a separate test.
	var visitor := capsule(frame.to_global(Vector3(0,0.01,-6)),524288)
	visitor.rotation.y = 0.37
	await wait_seconds(0.2)
	check("distant visitor does not trigger",float(door.get("progress"))==0.0)
	visitor.global_position = frame.to_global(Vector3(0,0.01,-2))
	var original_pose := visitor.global_transform
	await wait_seconds(opening+0.2)
	check("real XR-layer character approaching opens automatically",float(door.get("progress"))==1.0 and bool(door.get("occupied")))
	check("opening does not relocate or turn the visitor",visitor.global_transform.is_equal_approx(original_pose))
	visitor.global_position = frame.to_global(Vector3(0,0.01,0))
	var throat_pose := visitor.global_transform
	await wait_seconds(hold+0.3)
	check("visitor standing in the throat keeps passage open",float(door.get("progress"))==1.0 and visitor.global_transform.is_equal_approx(throat_pose))
	visitor.global_position = frame.to_global(Vector3(0,0.01,6))
	await wait_seconds(hold-0.25)
	check("leaving preserves the full empty hold before closing",float(door.get("progress"))==1.0)
	await wait_seconds(0.65)
	var closing_progress := float(door.get("progress"))
	check("empty doorway begins closing after its hold",closing_progress>0.0 and closing_progress<0.99,closing_progress)
	visitor.global_position = frame.to_global(Vector3(0,0.01,2))
	await wait_seconds(0.35)
	check("reentry from the far side reverses closing",float(door.get("progress"))>closing_progress,{"before":closing_progress,"after":door.get("progress")})
	await wait_seconds(0.7)
	check("reentry restores a fully open door",float(door.get("progress"))==1.0)
	visitor.global_position = frame.to_global(Vector3(0,0.01,6))
	await wait_seconds(hold+opening+0.3)
	check("door closes fully after the visitor leaves",float(door.get("progress"))==0.0)
	visitor.queue_free()
	await tick()
	door.set_physics_process(false)

func run() -> void:
	source_sha256 = FileAccess.get_sha256(SCRIPT)
	world = Node3D.new()
	root.add_child(world)
	current_scene = world
	var first := fixture(0.0,Vector3.ZERO)
	await tick()
	await static_contract(first,"origin")
	first.frame.queue_free()
	await tick()
	var rotated := fixture(PI,Vector3(13,2.5,-9))
	await tick()
	await static_contract(rotated,"translated_yaw180")
	await automatic_contract(rotated)
	var data := {"source":SCRIPT,"source_sha256":source_sha256,"source_sha256_at_finish":FileAccess.get_sha256(SCRIPT),"scene":SCENE,"checks":checks,"failures":failures,"observations":observations,"limits":["Standalone artifact on a flat test floor; does not assert final museum placement.","Real CharacterBody3D capsule and ray queries, not a worn headset or tracked-hand comfort test.","Uniform scaled plates are checked; raised decorative trim is outside the solid base-plate contract."]}
	var output := FileAccess.open(OUT,FileAccess.WRITE)
	output.store_string(JSON.stringify(data,"\t"))
	output.close()
	print("[airlock-test] RESULT ",checks.size()," checks / ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
