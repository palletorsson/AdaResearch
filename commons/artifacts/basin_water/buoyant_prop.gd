extends XRToolsPickable
## A light rigid toy supported by sampled depth, not by a water collider.
## Several buoyancy points let the ring tip and right itself after release.
var water: Node3D
var home := Vector3.ZERO
var ring := false
var radius := .3
var colour := Color("ffb83f")
var samples: Array[Vector3] = []
var reset_pending := false

func _ready() -> void:
	mass = .45 if ring else .3
	collision_layer = 4
	collision_mask = 196615
	release_mode = ReleaseMode.UNFROZEN
	ranged_grab_method = RangedMethod.LERP
	can_sleep = false
	continuous_cd = true
	linear_damp = .08
	angular_damp = .12
	var rubber := PhysicsMaterial.new()
	rubber.friction = .55
	rubber.bounce = .25
	physics_material_override = rubber
	var mesh := MeshInstance3D.new()
	var paint := StandardMaterial3D.new()
	paint.albedo_color = colour
	paint.roughness = .24
	mesh.material_override = paint
	if ring:
		radius = .18
		var torus := TorusMesh.new()
		torus.inner_radius = .46
		torus.outer_radius = .82
		torus.rings = 64
		torus.ring_segments = 16
		mesh.mesh = torus
		# Overlapping spheres keep the hole physically open, unlike a convex hull.
		for i in range(16):
			var a := TAU * i / 16.0
			var at := Vector3(cos(a), 0, sin(a)) * .64
			add_collision(at, radius)
			if i % 2 == 0: samples.append(at)
	else:
		var sphere := SphereMesh.new()
		sphere.radius = radius
		sphere.height = radius * 2
		sphere.radial_segments = 32
		sphere.rings = 16
		mesh.mesh = sphere
		add_collision(Vector3.ZERO, radius)
		samples.append(Vector3.ZERO)
	add_child(mesh)
	super._ready()

func add_collision(at: Vector3, size: float) -> void:
	var shape := SphereShape3D.new()
	shape.radius = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = at
	add_child(collision)

func return_to_pool() -> void:
	# RESET does not snatch a toy out of a visitor's hand.
	if not is_picked_up(): reset_pending = true

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not is_instance_valid(water) or is_picked_up(): return
	var local := water.to_local(state.transform.origin)
	if reset_pending or local.y < -6 or Vector2(local.x, local.z + 8).length() > 30:
		state.transform = Transform3D(water.global_basis.orthonormalized(), water.to_global(home))
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		reset_pending = false
		return
	var gravity := state.total_gravity.length()
	var wet := 0.0
	for sample in samples:
		var offset := state.transform.basis * sample
		var at := state.transform.origin + offset
		if not water.contains_water(at): continue
		var depth: float = water.height_world(at) - (at.y - radius)
		if depth <= 0: continue
		var velocity := state.linear_velocity + state.angular_velocity.cross(offset)
		# Weight is balanced when ~85% of the sample radius is submerged.
		var acceleration := clampf(gravity * depth / (radius * .85) - 4.5 * velocity.y, 0, gravity * 3.5)
		state.apply_force(Vector3.UP * mass * acceleration / samples.size(), offset)
		wet += clampf(depth / radius, 0, 1) / samples.size()
	if wet > 0:
		state.apply_central_force(-state.linear_velocity * mass * 1.6 * wet)
		state.apply_torque(-state.angular_velocity * mass * .7 * wet)
