extends Node3D
## A reversible native Jolt fixed joint. The strip owns its constraint lifetime.
## Utility pickables temporarily become physical while taped; authored state is
## restored when their last binding is removed. No global pickup code changes.
const LEASE := "tape_physics_lease"
var bodies: Array[WeakRef] = []
var joint: Generic6DOFJoint3D
var relative := Transform3D.IDENTITY
var age := 0.0
var torn := false
signal peeled

static func acquire(body: RigidBody3D) -> void:
	var state: Dictionary = body.get_meta(LEASE,{})
	if state.is_empty():
		state = {"count":0,"freeze":body.freeze,"gravity":body.gravity_scale,"mode":body.freeze_mode}
		if body.has_method("is_picked_up"):
			state.release = body.release_mode;state.restore = body.restore_freeze
			if body.is_picked_up():state.freeze = body.restore_freeze
	state.count += 1;body.set_meta(LEASE,state)
	# Already-dynamic exhibits retain their own gravity. Frozen utility pieces
	# need a real solver body rather than a second immovable joint anchor.
	if state.freeze and body.has_method("is_picked_up"):
		body.gravity_scale = maxf(state.gravity,1.0)
		body.release_mode = 0;body.restore_freeze = false
		if not body.is_picked_up():body.freeze = false
	body.sleeping = false

static func release(body: RigidBody3D) -> void:
	if not body.has_meta(LEASE):return
	var state: Dictionary = body.get_meta(LEASE);state.count -= 1
	if state.count>0:body.set_meta(LEASE,state);return
	body.remove_meta(LEASE);body.gravity_scale = state.gravity;body.freeze_mode = state.mode
	if state.has("release"):
		body.release_mode = state.release
		body.restore_freeze = state.freeze if body.is_picked_up() else state.restore
	if not body.has_method("is_picked_up") or not body.is_picked_up():body.freeze = state.freeze
	body.sleeping = false

func connect_bodies(a: PhysicsBody3D,b: PhysicsBody3D,at: Vector3) -> void:
	bodies = [weakref(a),weakref(b)];relative = a.global_transform.affine_inverse()*b.global_transform
	for body in [a,b]:
		if body is RigidBody3D:acquire(body)
	joint = Generic6DOFJoint3D.new();joint.name = "TapeFixedJoint";add_child(joint);joint.global_position = at
	# Preserve contacts: attaching tape must not make either object pass through
	# the other. The solver, rather than a per-frame pose copy, carries the load.
	joint.exclude_nodes_from_collision = false
	for axis in ["x","y","z"]:
		joint.call("set_flag_"+axis,Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT,true)
		joint.call("set_flag_"+axis,Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT,true)
		for parameter in [Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT,Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT,Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT,Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT]:joint.call("set_param_"+axis,parameter,0.0)
	joint.node_a = joint.get_path_to(a);joint.node_b = joint.get_path_to(b)

func _physics_process(delta: float) -> void:
	if torn or bodies.size()!=2:return
	var a = bodies[0].get_ref();var b = bodies[1].get_ref()
	if not is_instance_valid(a) or not is_instance_valid(b):detach();return
	if not a.is_inside_tree() or not b.is_inside_tree():return
	age += delta
	# Native pickup is kinematic. Pulling a wall-bound piece far enough peels
	# the tape rather than teleporting a wall or snapping the released hand back.
	var held_a: bool = a.has_method("is_picked_up") and a.is_picked_up()
	var held_b: bool = b.has_method("is_picked_up") and b.is_picked_up()
	if age>.25 and (held_a or held_b):
		var expected: Transform3D = a.global_transform*relative
		if expected.origin.distance_to(b.global_position)>.28:
			torn = true;detach();peeled.emit();print("TAPE_PEELED / hand pulled the bound objects apart")

func detach() -> void:
	if is_instance_valid(joint):joint.free()
	joint = null
	for ref in bodies:
		var body = ref.get_ref()
		if is_instance_valid(body) and body is RigidBody3D:release(body)
	bodies.clear()

func _exit_tree() -> void:detach()
