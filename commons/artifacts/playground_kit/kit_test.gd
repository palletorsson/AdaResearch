extends RefCounted
## THE LOAD TEST (Palle, 2026-11-06: the node editor builds in edit mode - everything held where it was fired - and "a
## separate test lets physics loose"). The hand's TEST tool (items.json "test", the little cast-iron weight) fired at a
## kit piece tests the whole structure it belongs to:
##   - every ball the bars do not fix (kit_rigidity.gd, the floor balls as anchors) or that nothing supports becomes a
##     body under gravity, and every rod of the structure becomes a HINGE at both ends - it keeps the distance between
##     its sockets, not an angle. So the unbraced square SAGS, the braced square standing up TIPS about its floor edge,
##     and what the count calls rigid does not move at all;
##   - fired again, the test is undone: every ball and rod back on its node, frozen, every joint fixed again.
## A structure that is rigid and supported answers "holds" and nothing changes. The support graph and the faces leave
## a structure under test alone (its balls carry `testing`).

const Rigidity = preload("res://commons/artifacts/playground_kit/kit_rigidity.gd")
const Structure = preload("res://commons/artifacts/playground_kit/kit_structure.gd")
const AXES := ["x", "y", "z"]
const PUSH := 0.6   ## m/s: the load hung on each loose ball, along its free motion

## The trigger with the test tool: start or undo the test of the structure the controller points at.
## Returns "started", "holds", "reset" or "" (nothing of the kit pointed at).
static func toggle_at(controller: Node3D, reach: float, exclude: Array = [], mask := 0xFFFFFFFF) -> String:
	var piece := pointed(controller, reach, exclude, mask)
	if piece == null:return ""
	var parts := structure(piece)
	for b in parts.balls:
		if b.testing:reset(parts);return "reset"
	return start(parts)

## The kit piece (a ball or a rod) the controller points at, or null.
static func pointed(controller: Node3D, reach: float, exclude: Array = [], mask := 0xFFFFFFFF) -> Node3D:
	var from := controller.global_position;var q := PhysicsRayQueryParameters3D.create(from, from - controller.global_basis.z * reach, mask)
	q.exclude = exclude
	var hit := controller.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():return null
	var n: Node = hit.collider
	while n != null and n is Node3D:
		if n.is_in_group("playground_balls") or n.is_in_group("playground_rods"):return n
		n = n.get_parent()
	return null

## Every ball and rod joined to `piece` through sockets: {balls, rods}.
static func structure(piece: Node3D) -> Dictionary:
	var balls: Array = [];var rods: Array = [];var queue: Array = [piece]
	while not queue.is_empty():
		var n: Node = queue.pop_back()
		if not is_instance_valid(n):continue
		if n.is_in_group("playground_balls"):
			if n in balls:continue
			balls.append(n)
			for r in n.sockets:
				if r != null and is_instance_valid(r) and r not in rods:queue.append(r)
		elif n.is_in_group("playground_rods"):
			if n in rods:continue
			rods.append(n)
			for j in n.joints:
				if is_instance_valid(j.ball):queue.append(j.ball)
	return {"balls": balls, "rods": rods}

## Let physics loose on what the bars and the floor do not hold.
static func start(parts: Dictionary) -> String:
	var balls: Array = parts.balls;var rods: Array = parts.rods
	var index := {};var pts: Array = [];var anchored: Array = []
	for i in balls.size():index[balls[i]] = i;pts.append(balls[i].global_position);anchored.append(balls[i].grounded())
	var bars: Array = []
	for r in rods:
		if r.joints.size() == 2 and index.has(r.joints[0].ball) and index.has(r.joints[1].ball):
			bars.append(Vector2i(index[r.joints[0].ball], index[r.joints[1].ball]))
	var res: Dictionary = Rigidity.analyse(pts, anchored, bars)
	var flex: Array = res.flexible
	var loose: Array = []
	for i in balls.size():
		if flex[i] or not balls[i].supported:loose.append(balls[i])
	if loose.is_empty():return "holds"
	for b in balls:
		b.set_meta("kit_test_home", b.global_transform);b.set_meta("kit_test_editing", b.editing)
		b.testing = true
	for r in rods:
		r.set_meta("kit_test_home", r.global_transform);r.set_meta("kit_test_freeze", r.freeze)
		for j in r.joints:_hinge(j.joint, true)
		r.freeze = false;r.sleeping = false;r.set_physics_process(true)
	for b in loose:
		b.freeze = false;b.sleeping = false
		# THE LOAD: a structure standing exactly on its nodes is balanced like a pencil on its tip and would start to move
		# only from rounding noise - the test hangs a small push on each loose ball along its own free motion
		var m: Vector3 = res.mode[index[b]]
		if m.length() > .01:b.apply_central_impulse(m.normalized() * PUSH * b.mass)
	balls[0].reevaluate(balls[0].get_tree())   # the faces let go of it (their wobble rests), the renderer redraws
	_mark(balls)
	return "started"

## Back on the nodes: every piece where it stood, frozen, every joint fixed.
static func reset(parts: Dictionary) -> void:
	for r in parts.rods:
		if not r.has_meta("kit_test_home"):continue
		_put(r, r.get_meta("kit_test_home"))
		r.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC;r.freeze = true   # still while the joints are made fixed
	for b in parts.balls:
		if not b.has_meta("kit_test_home"):continue
		_put(b, b.get_meta("kit_test_home"));b._hold()
		b.editing = bool(b.get_meta("kit_test_editing", b.editing));b.testing = false
		b.remove_meta("kit_test_home");b.remove_meta("kit_test_editing")
	for r in parts.rods:
		for j in r.joints:_hinge(j.joint, false)
		if r.has_meta("kit_test_home"):
			r.freeze = bool(r.get_meta("kit_test_freeze"));r.remove_meta("kit_test_home");r.remove_meta("kit_test_freeze")
	if not parts.balls.is_empty() and is_instance_valid(parts.balls[0]):
		parts.balls[0].reevaluate(parts.balls[0].get_tree())

static func _put(body: RigidBody3D, t: Transform3D) -> void:
	body.linear_velocity = Vector3.ZERO;body.angular_velocity = Vector3.ZERO;body.global_transform = t
	PhysicsServer3D.body_set_state(body.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, t)

## A rod's joint as a hinge (angles free, the distance kept) or fixed again (every axis locked).
static func _hinge(j: Variant, free: bool) -> void:
	if not is_instance_valid(j):return
	for ax in AXES:j.set("angular_limit_%s/enabled" % ax, not free)

static func _mark(balls: Array) -> void:
	if balls.is_empty() or not is_instance_valid(balls[0]):return
	var st: Node = Structure.current(balls[0].get_tree())
	if st != null:st.dirty = true
