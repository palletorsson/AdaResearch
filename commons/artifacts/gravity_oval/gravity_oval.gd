extends "res://commons/artifacts/force_play/play_space.gd"
## An artificial circulating field: acceleration, contact and retained velocity.
## No path animation and no rotation of the tracked head.
const PROP = preload("res://commons/artifacts/force_trials/overflow_prop.gd")
const CENTRE = Vector3(0, 5.7, 0)
const RADII = Vector2(2.8, 4.5)
const FLOW_SPEED = 3.2
const COUNT = 24
var flow_arrows: Array = []

func _ready() -> void:
	super._ready()
	set_meta("em_visibility_bounds", AABB(Vector3(-7, -1, -8), Vector3(14, 14, 16)))
	add_to_group("gravity_oval")
	add_to_group("ada_museum_carry")
	get_tree().node_added.connect(func(n):
		if n is XRToolsPlayerBody: install_adapter.call_deferred())
	install_adapter.call_deferred()

func build() -> void:
	kind = "gravity_oval"
	extent = Vector2(14, 16)
	floor_patch(extent, ink)
	title("GRAVITY OVAL", "Step into the rising side. Over the top, down, and around again.", 11.5)
	# The slim outline and arrows expose the field without enclosing the visitor.
	for i in range(80):
		var a = TAU * float(i) / 80
		var b = TAU * float(i + 1) / 80
		rod(oval(a) + Vector3(0, 0, 0.95), oval(b) + Vector3(0, 0, 0.95), pale, 0.022)
	for i in range(12):
		var angle = TAU * float(i) / 12
		var at = oval(angle) + Vector3(0, 0, -1.05)
		flow_arrows.append(rod(at, at + tangent(angle) * 0.65, pink if cos(angle) < 0 else blue, 0.025, true))
	# Low marks describe entries, not additional collision plates.
	box(Vector3(-2.5, 0.06, -1.5), Vector3(2.2, 0.018, 2.1), pink)
	box(Vector3(2.5, 0.06, -1.5), Vector3(2.2, 0.018, 2.1), blue)
	words("RISE", Vector3(-4.4, 2.3, -0.4), 0.0015)
	words("RETURN", Vector3(4.4, 2.3, -0.4), 0.0015)
	words("STEP SIDEWAYS OUT OF THE STREAM", Vector3(0, 0.65, -3.7), 0.0009)
	for i in range(COUNT):
		var angle = TAU * float(i) / COUNT
		var at = oval(angle) + Vector3(0, 0, [-0.42, 0.0, 0.42][i % 3])
		var body: RigidBody3D
		if i % 4 == 0:
			body = sphere(at, 0.29, 1.0)
		else:
			body = PROP.new()
			body.prop_kind = ["crate", "chair", "extinguisher"][(i - 1) % 3]
			body.size_multiplier = 0.9 if body.prop_kind == "chair" else 1.0
			body.position = at
			add_child(body)
			remember(body)
		body.name = "FloatingPrefab%02d" % i
		body.gravity_scale = 0.0
		body.linear_damp = 0.0
		body.angular_damp = 0.1
		body.can_sleep = false
		body.linear_velocity = tangent(angle) * FLOW_SPEED
		body.angular_velocity = Vector3(0.15, (i % 3 - 1) * 0.22, 0.12)
		body.physics_material_override = physics_material(0.25, 0.18)

func oval(angle: float) -> Vector3:
	return CENTRE + Vector3(RADII.x * cos(angle), RADII.y * sin(angle), 0)

func tangent(angle: float) -> Vector3:
	# Clockwise: left rises, top turns right, right descends, bottom turns left.
	return Vector3(RADII.x * sin(angle), -RADII.y * cos(angle), 0).normalized()

func field_contains(p: Vector3) -> bool:
	return absf(p.x) < 4.7 and absf(p.z) < 2.2 and p.y > -0.5 and p.y < 12.0

func acceleration(p: Vector3, velocity: Vector3) -> Vector3:
	var q = p - CENTRE
	var angle = atan2(q.y / RADII.y, q.x / RADII.x)
	var target = oval(angle)
	# A driven flow relaxes toward a tangent velocity and the oval's section.
	# It supplies energy: this is deliberately not Newtonian attraction.
	var flow = tangent(angle) * FLOW_SPEED
	return ((flow - velocity) * 2.4 + (target - p) * 3.0).limit_length(18.0)

func step(_dt: float) -> void:
	var in_flow = 0
	for body in bodies:
		var inside = field_contains(body.position)
		body.gravity_scale = 0.0 if inside and not is_held(body) else 1.0
		if inside and not is_held(body) and not body.freeze:
			var local_velocity = global_basis.inverse() * body.linear_velocity
			body.apply_central_force(global_basis * acceleration(body.position, local_velocity) * body.mass)
			in_flow += 1
	status.text = "%d / %d bodies in the stream\nAn artificial field. Your head stays upright." % [in_flow, COUNT]

func _point_inside(world: Vector3) -> bool:
	return field_contains(to_local(world + Vector3.UP * 0.7))

func carry_velocity(body: CharacterBody3D, dt: float, incoming: Vector3) -> Vector3:
	var velocity: Vector3 = _carry.get(body.get_instance_id(), incoming)
	var local_velocity = global_basis.inverse() * velocity
	var p = to_local(body.global_position + Vector3.UP * 0.7)
	velocity += global_basis * acceleration(p, local_velocity) * dt
	# Deliberate walking can overcome the field's lateral centring and leave it.
	velocity += walk_velocity(body) * 4.0 * dt
	return velocity.limit_length(5.5)

func after_reset() -> void:
	_carry.clear()
	for body in bodies: body.gravity_scale = 0.0
