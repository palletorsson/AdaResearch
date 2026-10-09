extends Node
## Surface contact and lifecycle regression, using the museum's actual hand meshes.
## Run with tools/run_surface_grip_probe.py; no headset is required for these checks.

var SurfaceGrip: Script
var PoseSolver: Script
var GrabScript: Script
var GrabberScript: Script
var PointScript: Script
const OUTPUT := "res://ada_run/auto-hand-2026-10-05/regression.json"

var checks: Array[Dictionary] = []
var cases: Array[Dictionary] = []
var world: Node3D
var origin: XROrigin3D


func _ready() -> void:
	_run.call_deferred()


func _check(ok: bool, label: String, details: Variant = null) -> void:
	checks.append({"passed": ok, "check": label, "details": details})
	print("%s: %s%s" % ["PASS" if ok else "FAIL", label, " " + str(details) if details != null else ""])


func _frames(count: int = 5) -> void:
	for unused in count:
		await get_tree().physics_frame
		await get_tree().process_frame


func _hand(side: String) -> Node3D:
	var controller := XRController3D.new()
	controller.name = side + "_controller"
	controller.tracker = side + "_hand"
	controller.pose = "aim"
	origin.add_child(controller)
	controller.owner = world
	var hand: Node3D = load("res://commons/body/hands/%s_hand.tscn" % side).instantiate()
	# Same effective root setup as base.tscn, including its right-hand override.
	hand.set_script(load("res://addons/godot-xr-tools/hands/hand.gd"))
	hand.hand_blend_tree = load("res://addons/godot-xr-tools/hands/animations/%s/hand_blend_tree.tres" % side)
	hand.default_pose = load("res://addons/godot-xr-tools/hands/poses/pose_default_%s.tres" % side)
	controller.add_child(hand)
	# XRTools' find_instance deliberately searches owned scene nodes.
	hand.owner = world
	return hand as Node3D


func _add_shape(body: PhysicsBody3D, shape: Shape3D, at: Transform3D = Transform3D.IDENTITY) -> void:
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.transform = at
	body.add_child(collider)


func _box(size: Vector3 = Vector3.ONE * 0.14) -> BoxShape3D:
	var shape := BoxShape3D.new()
	shape.size = size
	return shape


func _body_for(hand: Node3D, kind: String, scale_factor: float = 1.0) -> RigidBody3D:
	var body: RigidBody3D = load("res://addons/godot-xr-tools/objects/pickable.gd").new()
	body.name = "GripCase_" + kind
	body.freeze = true
	if kind == "sphere":
		var sphere := SphereShape3D.new()
		sphere.radius = 0.075
		_add_shape(body, sphere)
	elif kind == "capsule":
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.045
		capsule.height = 0.20
		_add_shape(body, capsule)
	elif kind == "compound":
		_add_shape(body, _box(Vector3(0.055, 0.17, 0.10)), Transform3D(Basis.IDENTITY, Vector3(-0.065, 0.0, 0.0)))
		_add_shape(body, _box(Vector3(0.055, 0.17, 0.10)), Transform3D(Basis.IDENTITY, Vector3(0.065, 0.0, 0.0)))
	else:
		_add_shape(body, _box())
	world.add_child(body)
	var solver: RefCounted = PoseSolver.new()
	if not solver.configure(hand):
		_check(false, "test hand can configure palm frame")
		return body
	var palm: Transform3D = hand.global_transform * solver.palm_frame()
	var orientation := palm.basis.orthonormalized()
	if kind == "compound":
		orientation = orientation * Basis(Vector3.UP, 0.47) * Basis(Vector3.FORWARD, 0.23)
	body.global_transform = Transform3D(orientation.scaled(Vector3.ONE * scale_factor), palm.origin + palm.basis.z.normalized() * (0.13 * scale_factor))
	return body


func _surface_distance(body: PhysicsBody3D, point: Vector3) -> float:
	var smallest := INF
	for owner_id in body.get_shape_owners():
		var xf: Transform3D = body.global_transform * body.shape_owner_get_transform(owner_id)
		var p: Vector3 = xf.affine_inverse() * point
		for index in body.shape_owner_get_shape_count(owner_id):
			var shape: Shape3D = body.shape_owner_get_shape(owner_id, index)
			var error := INF
			if shape is BoxShape3D:
				var d: Vector3 = p.abs() - shape.size * 0.5
				error = d.max(Vector3.ZERO).length() + minf(maxf(d.x, maxf(d.y, d.z)), 0.0)
			elif shape is SphereShape3D:
				error = p.length() - shape.radius
			elif shape is CapsuleShape3D:
				var half_segment: float = maxf(0.0, shape.height * 0.5 - shape.radius)
				var q := Vector3(p.x, p.y - clampf(p.y, -half_segment, half_segment), p.z)
				error = q.length() - shape.radius
			# These fixtures use uniform scale; convert the analytic distance
			# back to world metres before comparing finger radii.
			smallest = minf(smallest, error * xf.basis.get_scale().x)
	return smallest


func _case(side: String, kind: String, scale_factor: float = 1.0) -> void:
	var label := "%s %s scale %.1f" % [side, kind, scale_factor]
	var hand := _hand(side)
	await _frames(2)
	var body := _body_for(hand, kind, scale_factor)
	await _frames(2)
	var original_object_transform := body.global_transform
	var grip: Node3D = SurfaceGrip.begin(hand, body)
	await _frames(7)
	var fitted := is_instance_valid(grip) and bool(grip.get("fitted"))
	_check(fitted, label + " fits")
	if fitted:
		var rigid_frame := body.global_transform.orthonormalized()
		var contact: Vector3 = rigid_frame * grip.contact_point
		var normal: Vector3 = rigid_frame.basis * grip.contact_normal
		var error := absf(_surface_distance(body, contact))
		# The solver can extend an initially intersecting finger before its
		# closing search. Compare the rendered bones to that actual solution.
		var solver: RefCounted = grip._solver
		var palm: Vector3 = hand.global_transform * solver.palm_frame().origin
		var palm_error: float = palm.distance_to(contact + normal * SurfaceGrip.SKIN * XRServer.world_scale)
		_check(error < 0.003, label + " contact is on collider, not its bounding box", error)
		_check(palm_error < 0.005, label + " visible palm reaches surface", palm_error)
		_check(body.global_transform.is_equal_approx(original_object_transform), label + " pose does not move object")
		_check(grip.curls.size() == 5, label + " solves all five fingers", grip.curls)
		var bounded := true
		for value in grip.curls.values():
			bounded = bounded and is_finite(float(value)) and float(value) >= 0.0 and float(value) <= 1.0
		_check(bounded, label + " curls stay finite and bounded")
		var finger_clearance: Dictionary = {}
		for finger in grip.curls:
			var clearance := INF
			var points: PackedVector3Array = solver.finger_probe_positions(finger, grip.curls[finger], 0.006)
			for sample in points:
				clearance = minf(clearance, _surface_distance(body, hand.global_transform * sample) - 0.006 * XRServer.world_scale)
			finger_clearance[finger] = clearance
			_check(clearance >= -0.0006, label + " " + finger + " finger padding stays outside collider", clearance)
		var skeleton: Skeleton3D = hand.find_child("Skeleton3D", true, false)
		var expected: Dictionary = solver.bone_positions(grip.curls)
		var worst_bone_error := 0.0
		for bone in skeleton.get_bone_count():
			var bone_name := skeleton.get_bone_name(bone)
			var actual: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(bone).origin
			var wanted: Vector3 = hand.global_transform * expected[bone_name]
			worst_bone_error = maxf(worst_bone_error, actual.distance_to(wanted))
		_check(worst_bone_error < 0.0005, label + " rendered skeleton receives solved finger pose", worst_bone_error)
		_check(not grip._body.is_valid() and not grip._space.is_valid(), label + " releases temporary physics RIDs")
		cases.append({"case": label, "surface_error": error, "palm_error": palm_error, "curls": grip.curls.duplicate(), "finger_clearance": finger_clearance, "rendered_bone_error": worst_bone_error})
		body.global_position += Vector3(0.08, 0.04, 0.02)
		body.rotate_y(0.2)
		await _frames(3)
		rigid_frame = body.global_transform.orthonormalized()
		contact = rigid_frame * grip.contact_point
		normal = rigid_frame.basis * grip.contact_normal
		palm = hand.global_transform * solver.palm_frame().origin
		_check(palm.distance_to(contact + normal * SurfaceGrip.SKIN * XRServer.world_scale) < 0.005, label + " surface contact follows object translation and rotation")
		grip.stop()
		await _frames(2)
		_check(hand._pose_overrides.is_empty() and hand._target_overrides.is_empty(), label + " release restores tracked hand")
	body.queue_free()
	hand.get_parent().queue_free()
	await _frames(2)


func _lifecycle() -> void:
	var hand := _hand("left")
	await _frames(2)
	var body := _body_for(hand, "box")
	var early: Node3D = SurfaceGrip.begin(hand, body)
	early.stop()
	await _frames(4)
	_check(not is_instance_valid(early) and hand._pose_overrides.is_empty() and hand._target_overrides.is_empty(), "release before deferred fit leaves no pose or target")
	var freed: Node3D = SurfaceGrip.begin(hand, body)
	await _frames(6)
	_check(is_instance_valid(freed) and freed.fitted, "object teardown test starts from a fitted grasp")
	body.queue_free()
	await _frames(3)
	_check(not is_instance_valid(freed) and hand._pose_overrides.is_empty() and hand._target_overrides.is_empty(), "freeing held object restores hand")

	# Authored override remains authoritative even if a lower-priority fit exists.
	body = _body_for(hand, "sphere")
	var authored := Node3D.new()
	world.add_child(authored)
	var authored_pose: Resource = hand.default_pose
	hand.add_pose_override(authored, 100, authored_pose)
	hand.add_target_override(authored, 100)
	var fallback: Node3D = SurfaceGrip.begin(hand, body)
	await _frames(6)
	_check(hand._pose_overrides[0].who == authored and hand._target == authored, "authored pose and target priority beats surface fallback")
	if is_instance_valid(fallback): fallback.stop()
	hand.remove_pose_override(authored)
	hand.remove_target_override(authored)
	authored.queue_free()
	body.queue_free()
	hand.get_parent().queue_free()
	await _frames(3)


func _grab_lifecycle() -> void:
	var left := _hand("left")
	var right := _hand("right")
	await _frames(2)
	var body := _body_for(left, "sphere")
	var left_by := Node3D.new()
	var right_by := Node3D.new()
	world.add_child(left_by)
	world.add_child(right_by)
	left_by.global_transform = left.global_transform
	right_by.global_transform = right.global_transform
	var left_grabber : RefCounted = GrabberScript.new(left_by)
	left_grabber.hand = left
	var right_grabber : RefCounted = GrabberScript.new(right_by)
	right_grabber.hand = right
	var left_grab : RefCounted = GrabScript.new(left_grabber, body, null, true)
	var right_grab : RefCounted = GrabScript.new(right_grabber, body, null, true)
	_check(left_grab._surface_grip == null, "Grab waits for arrival before fitting")
	left_grab.set_arrived()
	right_grab.set_arrived()
	await _frames(7)
	_check(is_instance_valid(left_grab._surface_grip) and left_grab._surface_grip.fitted and is_instance_valid(right_grab._surface_grip) and right_grab._surface_grip.fitted, "two hands fit independent grasps on one object")
	left_grab.release()
	await _frames(2)
	_check(left._pose_overrides.is_empty() and is_instance_valid(right_grab._surface_grip) and right_grab._surface_grip.fitted, "one hand releases without clearing other hand")
	right_grab.release()
	await _frames(2)
	_check(right._pose_overrides.is_empty() and right._target_overrides.is_empty(), "second hand releases cleanly")

	var point : Node3D = PointScript.new()
	point.hand_pose = left.default_pose
	body.add_child(point)
	var authored_grab : RefCounted = GrabScript.new(left_grabber, body, point, true)
	authored_grab.set_arrived()
	await _frames(3)
	_check(authored_grab._surface_grip == null and left._target == point and left._pose_overrides[0].who == point, "Grab with authored point bypasses fitting")
	var generic: Node3D = load("res://addons/godot-xr-tools/objects/grab_points/grab_point.gd").new()
	generic.position = Vector3(0.01, 0.02, 0.03)
	body.add_child(generic)
	authored_grab.set_grab_point(generic)
	_check(authored_grab._surface_grip == null and authored_grab.transform.is_equal_approx(generic.transform) and left._pose_overrides.is_empty(), "switch to generic authored point preserves transform and clears hand pose")
	authored_grab.set_grab_point(null)
	await _frames(6)
	_check(is_instance_valid(authored_grab._surface_grip) and authored_grab._surface_grip.fitted, "switch to free grasp activates surface fit")
	authored_grab.release()
	left.surface_grip_enabled = false
	var disabled_grab : RefCounted = GrabScript.new(left_grabber, body, null, true)
	disabled_grab.set_arrived()
	await _frames(3)
	_check(disabled_grab._surface_grip == null, "surface-grip option disables fallback")
	disabled_grab.release()
	body.queue_free()
	left_by.queue_free()
	right_by.queue_free()
	left.get_parent().queue_free()
	right.get_parent().queue_free()
	await _frames(3)


func _ranged_lifecycle() -> void:
	var hand := _hand("right")
	var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
	hand.get_parent().add_child(pickup)
	pickup.owner = world
	await _frames(2)
	var body := _body_for(hand, "sphere")
	body.global_position += Vector3(0.0, 0.0, -2.0)
	body.ranged_grab_method = 2 # XRToolsPickable.RangedMethod.LERP
	body.ranged_grab_speed = 20.0
	var initial_layer: int = body.collision_layer
	var initial_mask: int = body.collision_mask
	await _frames(2)
	pickup._pick_up_object(body)
	var driver: Node3D = body._grab_driver
	_check(pickup.picked_up_ranged and driver.state == 0 and driver.primary._surface_grip == null, "real ranged pickup starts LERP without fitting distant hand")
	await _frames(35)
	var grip: Node3D = driver.primary._surface_grip
	_check(driver.state == 1 and is_instance_valid(grip) and grip.fitted, "real ranged pickup fits only after LERP arrival", {"state": driver.state, "has_grip": is_instance_valid(grip), "fitted": grip.fitted if is_instance_valid(grip) else false, "failure": grip.failure_reason if is_instance_valid(grip) else "no grip", "grab_hand": str(driver.primary.hand), "grab_controller": str(driver.primary.controller), "grab_point": str(driver.primary.point), "object_position": body.global_position, "hand_position": hand.global_position})
	pickup.drop_object()
	await _frames(3)
	_check(pickup.picked_up_object == null and body._grab_driver == null and hand._pose_overrides.is_empty() and hand._target_overrides.is_empty(), "real pickup drop clears driver and surface pose")
	_check(body.collision_layer == initial_layer and body.collision_mask == initial_mask, "real pickup drop restores original collision layers")
	body.queue_free()
	hand.get_parent().queue_free()
	await _frames(3)


func _run() -> void:
	# Runtime loading avoids a test-only static reference cycle through the
	# XRTools global script graph and lets autoloads initialize first.
	SurfaceGrip = load("res://addons/godot-xr-tools/hands/surface_grip.gd")
	PoseSolver = load("res://addons/godot-xr-tools/hands/surface_grip_pose.gd")
	GrabScript = load("res://addons/godot-xr-tools/objects/grab_points/grab.gd")
	GrabberScript = load("res://addons/godot-xr-tools/objects/grab_points/grabber.gd")
	PointScript = load("res://addons/godot-xr-tools/objects/grab_points/grab_point_hand.gd")
	world = Node3D.new()
	get_tree().root.add_child(world)
	origin = XROrigin3D.new()
	world.add_child(origin)
	for side in ["left", "right"]:
		for kind in ["box", "sphere", "capsule", "compound"]:
			await _case(side, kind)
	await _case("left", "sphere", 1.5)
	XRServer.world_scale = 2.0
	await _case("right", "sphere", 2.0)
	XRServer.world_scale = 1.0
	await _lifecycle()
	await _grab_lifecycle()
	await _ranged_lifecycle()
	var failures := checks.filter(func(row: Dictionary) -> bool: return not row.passed)
	var report := {"checks": checks, "cases": cases, "passed": failures.is_empty(), "count": checks.size(), "failures": failures.size(), "scope": "Headless real hand scenes, collider queries and grab lifecycle; headset comfort not verified."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var output := FileAccess.open(OUTPUT, FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	output.close()
	print("SURFACE GRIP: %s (%d checks, %d failures)" % ["PASS" if failures.is_empty() else "FAIL", checks.size(), failures.size()])
	world.queue_free()
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
