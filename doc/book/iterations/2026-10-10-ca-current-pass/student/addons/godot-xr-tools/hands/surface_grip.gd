# Surface fitting for free XR grabs: real collider contact, then individual fingers.
# Adapts the AutoHand approach without changing XRTools' object/throw driver.
# Authored grab points take precedence. Physics queries use a private snapshot so
# picked-up collision layers and nearby scenery cannot contaminate the pose.
extends Node3D

const PoseSolver = preload("res://addons/godot-xr-tools/hands/surface_grip_pose.gd")
const PRIORITY := 90
const SKIN := 0.003

var _hand: Node3D
var _object: Node3D
var _space: RID
var _body: RID
var _shapes: Array[Shape3D] = []
var _centres: Array[Vector3] = []
var _extent := 0.5
var _snapshot_frame: Transform3D
var _solver: RefCounted
var _frames := 0
var _stopped := false
var _installed := false

## Diagnostic values; no per-frame finger queries are required after fitting.
var fitted := false
var curls: Dictionary = {}
var contact_point := Vector3.ZERO
var contact_normal := Vector3.ZERO
var fit_usec := 0
var failure_reason := ""


static func begin(hand: Node3D, object: Node3D) -> Node3D:
	var grip := new()
	grip.name = "SurfaceGrip"
	grip._hand = hand
	grip._object = object
	object.add_child(grip)
	return grip


func _ready() -> void:
	process_physics_priority = -60 # Object driver and tracked hand update first.
	_solver = PoseSolver.new()
	if not _solver.configure(_hand):
		stop()
		return
	_snapshot_frame = _object.global_transform.orthonormalized()
	_space = PhysicsServer3D.space_create()
	PhysicsServer3D.space_set_active(_space, true)
	_body = PhysicsServer3D.body_create()
	PhysicsServer3D.body_set_mode(_body, PhysicsServer3D.BODY_MODE_STATIC)
	PhysicsServer3D.body_set_space(_body, _space)
	PhysicsServer3D.body_set_collision_layer(_body, 1)
	PhysicsServer3D.body_set_collision_mask(_body, 0)
	_collect_shapes(_object)
	if _shapes.is_empty():
		stop()


func _collect_shapes(node: Node) -> void:
	if node is PhysicsBody3D:
		for owner_id in node.get_shape_owners():
			if node.is_shape_owner_disabled(owner_id):
				continue
			var shape_transform: Transform3D = _snapshot_frame.affine_inverse() * node.global_transform * node.shape_owner_get_transform(owner_id)
			for index in node.shape_owner_get_shape_count(owner_id):
				var shape: Shape3D = node.shape_owner_get_shape(owner_id, index)
				# Infinite planes/rays have no enclosing surface suitable for a hand.
				if shape is WorldBoundaryShape3D or shape is SeparationRayShape3D:
					continue
				_shapes.append(shape)
				PhysicsServer3D.body_add_shape(_body, shape.get_rid(), shape_transform)
				var mesh: ArrayMesh = shape.get_debug_mesh()
				var bounds: AABB = shape_transform * mesh.get_aabb()
				_centres.append(bounds.get_center())
				_extent = maxf(_extent, bounds.position.length() + bounds.size.length())
	for child in node.get_children():
		if child != self:
			_collect_shapes(child)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_hand) or not is_instance_valid(_object):
		stop()
		return
	# The private broadphase needs one complete physics step after adding shapes.
	_frames += 1
	if _frames < 2:
		return
	var started := Time.get_ticks_usec()
	_fit()
	fit_usec = Time.get_ticks_usec() - started
	_free_query_space()
	set_physics_process(false)


func _fit() -> void:
	var space := PhysicsServer3D.space_get_direct_state(_space)
	if not space:
		return
	# Snapshot is in a rigid object frame; shape transforms already contain scale.
	var frame := _object.global_transform.orthonormalized()
	var hand_in_query: Transform3D = frame.affine_inverse() * _hand.global_transform
	var palm: Transform3D = _solver.palm_frame()
	var palm_position: Vector3 = hand_in_query * palm.origin
	var palm_direction: Vector3 = (hand_in_query.basis * palm.basis.z).normalized()
	var hit := _find_contact(space, palm_position, palm_direction)
	if hit.is_empty():
		failure_reason = "No collider surface within palm reach"
		return
	var normal: Vector3 = hit.normal
	var rotation := Basis(Quaternion(palm_direction, -normal))
	var fitted_hand := Transform3D(rotation * hand_in_query.basis, Vector3.ZERO)
	var world_scale := XRServer.world_scale
	fitted_hand.origin = hit.position + normal * SKIN * world_scale - fitted_hand.basis * palm.origin
	var result: Dictionary = _solver.solve(fitted_hand, space, 0.006 * world_scale)
	if not result.has("pose"):
		return
	if not result.get("initial_blocked", []).is_empty():
		failure_reason = "No clear opening pose for %s" % str(result.initial_blocked)
		return
	curls = result.get("curls", {})
	contact_point = hit.position
	contact_normal = normal
	# XRToolsHand multiplies its own initial/world-scale transform after target.
	# Remove that transform here so the calibrated palm lands exactly at contact.
	global_transform = frame * fitted_hand * _hand._transform.affine_inverse()
	_hand.add_pose_override(self, PRIORITY, result.pose)
	_hand.add_target_override(self, PRIORITY)
	_installed = true
	fitted = true


func _find_contact(space: PhysicsDirectSpaceState3D, palm: Vector3, inward: Vector3) -> Dictionary:
	var best: Dictionary = {}
	var reach: float = _hand.surface_grip_max_distance * XRServer.world_scale
	var best_score := INF
	var rays: Array[Vector3] = []
	for centre in _centres:
		if not centre.is_equal_approx(palm):
			rays.append(centre)
	# Reverse rays also find exit surfaces if the palm starts inside a collider.
	# AABBs only bound the search; all accepted points come from collider ray hits.
	var radius := maxf(_extent + palm.length() + 0.1, reach * 2.0)
	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1, 2):
				var direction := Vector3(x, y, z)
				if direction != Vector3.ZERO:
					rays.append(palm + direction.normalized() * radius)
	rays.append(palm + inward * radius)
	rays.append(palm - inward * radius)
	for endpoint in rays:
		for reverse in [false, true]:
			var query := PhysicsRayQueryParameters3D.create(endpoint if reverse else palm, palm if reverse else endpoint, 1)
			query.hit_back_faces = true
			var hit := space.intersect_ray(query)
			if hit.is_empty() or hit.normal.is_zero_approx():
				continue
			var distance: float = palm.distance_to(hit.position)
			if distance > reach:
				continue
			var score: float = distance + 0.02 * XRServer.world_scale * (1.0 + inward.dot(hit.normal))
			if score < best_score:
				best_score = score
				best = hit
	return best


func stop() -> void:
	if _stopped:
		return
	_stopped = true
	_remove_overrides()
	_free_query_space()
	set_physics_process(false)
	queue_free()


func _exit_tree() -> void:
	_remove_overrides()
	_free_query_space()


func _remove_overrides() -> void:
	if _installed and is_instance_valid(_hand):
		_hand.remove_pose_override(self)
		_hand.remove_target_override(self)
	_installed = false


func _free_query_space() -> void:
	if _body.is_valid():
		PhysicsServer3D.free_rid(_body)
		_body = RID()
	if _space.is_valid():
		PhysicsServer3D.free_rid(_space)
		_space = RID()
	_shapes.clear()
