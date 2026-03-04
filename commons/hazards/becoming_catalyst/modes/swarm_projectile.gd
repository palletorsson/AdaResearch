# SwarmProjectile.gd
# 8 tiny boid spheres that flock using separation/alignment/cohesion.
# The swarm moves as one — collective intelligence, mutual aid.
extends CatalystProjectile

const BOID_COUNT := 8
const SEPARATION_WEIGHT := 1.2
const ALIGNMENT_WEIGHT := 1.2
const COHESION_WEIGHT := 1.8
const FORWARD_WEIGHT := 0.6
const MAX_SPEED := 3.5
const BOID_RADIUS := 0.012

# Boid state
var _boid_positions: Array[Vector3] = []
var _boid_velocities: Array[Vector3] = []
var _boid_alive: Array[bool] = []
var _multimesh_instance: MultiMeshInstance3D = null
var _multimesh: MultiMesh = null

func _build_visual() -> void:
	# No single mesh — we use MultiMesh for the swarm
	_mesh_instance = null

	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.instance_count = BOID_COUNT

	var sphere := SphereMesh.new()
	sphere.radius = BOID_RADIUS
	sphere.height = BOID_RADIUS * 2.0
	_multimesh.mesh = sphere

	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.multimesh = _multimesh

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = color_primary
	mat.emission_energy_multiplier = emission_energy
	_multimesh_instance.material_override = mat
	add_child(_multimesh_instance)

	# Initialize boid positions in a small cluster
	_boid_positions.resize(BOID_COUNT)
	_boid_velocities.resize(BOID_COUNT)
	_boid_alive.resize(BOID_COUNT)
	for i in BOID_COUNT:
		_boid_positions[i] = Vector3(
			randf_range(-0.05, 0.05),
			randf_range(-0.03, 0.03),
			randf_range(-0.05, 0.05)
		)
		_boid_velocities[i] = direction.normalized() * speed * randf_range(0.3, 0.6)
		_boid_alive[i] = true
		_multimesh.set_instance_color(i, color_primary.lerp(color_secondary, randf()))

func _build_collision() -> void:
	# Single collision shape for the whole swarm center
	_collision_shape = CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.1
	_collision_shape.shape = shape
	add_child(_collision_shape)

func _apply_initial_velocity() -> void:
	# Swarm manages its own movement — disable RigidBody velocity
	gravity_scale = 0.0
	linear_velocity = Vector3.ZERO
	freeze = true

func _update_trajectory(delta: float) -> void:
	if has_hit:
		return

	var alive_count := 0
	var center := Vector3.ZERO

	# Calculate swarm center
	for i in BOID_COUNT:
		if _boid_alive[i]:
			center += _boid_positions[i]
			alive_count += 1

	if alive_count == 0:
		_expire()
		return

	center /= alive_count

	# Move the node with the swarm
	global_position += direction.normalized() * speed * delta * 0.5

	# Update each boid
	for i in BOID_COUNT:
		if not _boid_alive[i]:
			continue

		var pos_i := _boid_positions[i]
		var vel_i := _boid_velocities[i]

		# Boid rules
		var separation := Vector3.ZERO
		var alignment := Vector3.ZERO
		var cohesion := center - pos_i

		var neighbor_count := 0
		for j in BOID_COUNT:
			if j == i or not _boid_alive[j]:
				continue
			var diff := pos_i - _boid_positions[j]
			var dist := diff.length()
			if dist < 0.08 and dist > 0.001:
				separation += diff / dist  # Push away from close neighbors
			alignment += _boid_velocities[j]
			neighbor_count += 1

		if neighbor_count > 0:
			alignment /= neighbor_count

		# Forward drive
		var forward_pull := direction.normalized() * FORWARD_WEIGHT

		# Combine forces
		var acceleration := (
			separation.normalized() * SEPARATION_WEIGHT +
			alignment.normalized() * ALIGNMENT_WEIGHT +
			cohesion.normalized() * COHESION_WEIGHT +
			forward_pull
		)

		vel_i += acceleration * delta
		if vel_i.length() > MAX_SPEED:
			vel_i = vel_i.normalized() * MAX_SPEED
		_boid_velocities[i] = vel_i
		_boid_positions[i] += vel_i * delta

		# Update MultiMesh transform
		var t := Transform3D()
		t.origin = _boid_positions[i]
		_multimesh.set_instance_transform(i, t)

func _on_hit(body: Node3D) -> void:
	projectile_hit.emit(body, global_position)
	# Kill boids near the hit point
	var hit_pos := global_position
	for i in BOID_COUNT:
		if _boid_alive[i]:
			var world_pos := global_position + _boid_positions[i]
			if world_pos.distance_to(hit_pos) < 0.15:
				_boid_alive[i] = false
				_multimesh.set_instance_color(i, Color(0, 0, 0, 0))
	# Check if any alive
	if not _boid_alive.any(func(v): return v):
		has_hit = true
