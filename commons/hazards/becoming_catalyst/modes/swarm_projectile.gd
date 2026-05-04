# SwarmProjectile.gd
# 8 boid spheres that flock and independently seek nearby targets.
# Collective intelligence — the swarm hunts together.
extends CatalystProjectile

const BOID_COUNT := 8
const SEPARATION_WEIGHT := 1.2
const ALIGNMENT_WEIGHT := 0.8
const COHESION_WEIGHT := 1.0
const SEEK_WEIGHT := 3.0
const FORWARD_WEIGHT := 0.4
const MAX_SPEED := 4.0
const BOID_RADIUS := 0.015
const SEEK_RANGE := 8.0  # How far boids detect targets

# Boid state
var _boid_positions: Array[Vector3] = []
var _boid_velocities: Array[Vector3] = []
var _boid_alive: Array[bool] = []
var _multimesh_instance: MultiMeshInstance3D = null
var _multimesh: MultiMesh = null
var _target_cache: Array[Node3D] = []
var _target_scan_timer: float = 0.0

func _build_visual() -> void:
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
	_collision_shape = CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.15
	_collision_shape.shape = shape
	add_child(_collision_shape)

func _apply_initial_velocity() -> void:
	gravity_scale = 0.0
	linear_velocity = Vector3.ZERO
	freeze = true

func _update_trajectory(delta: float) -> void:
	if has_hit:
		return

	# Periodically scan for targets
	_target_scan_timer -= delta
	if _target_scan_timer <= 0.0:
		_target_scan_timer = 0.5
		_scan_targets()

	var alive_count := 0
	var center := Vector3.ZERO

	for i in BOID_COUNT:
		if _boid_alive[i]:
			center += _boid_positions[i]
			alive_count += 1

	if alive_count == 0:
		_expire()
		return

	center /= alive_count

	# Move the node forward slowly
	global_position += direction.normalized() * speed * delta * 0.3

	# Update each boid
	for i in BOID_COUNT:
		if not _boid_alive[i]:
			continue

		var pos_i := _boid_positions[i]
		var vel_i := _boid_velocities[i]
		var world_pos := global_position + pos_i

		# Classic boid rules
		var separation := Vector3.ZERO
		var alignment := Vector3.ZERO
		var cohesion := center - pos_i

		var neighbor_count := 0
		for j in BOID_COUNT:
			if j == i or not _boid_alive[j]:
				continue
			var diff := pos_i - _boid_positions[j]
			var dist := diff.length()
			if dist < 0.1 and dist > 0.001:
				separation += diff / dist
			alignment += _boid_velocities[j]
			neighbor_count += 1

		if neighbor_count > 0:
			alignment /= neighbor_count

		# Target seeking — find nearest target for this boid
		var seek := Vector3.ZERO
		var best_dist := SEEK_RANGE
		for target in _target_cache:
			if not is_instance_valid(target):
				continue
			var to_target := target.global_position - world_pos
			var d := to_target.length()
			if d < best_dist:
				best_dist = d
				seek = to_target.normalized()

		# Forward drive (weaker when targets exist)
		var forward_pull := direction.normalized() * FORWARD_WEIGHT
		if seek.length_squared() > 0.01:
			forward_pull *= 0.2  # Let seeking dominate

		# Combine forces
		var acceleration := (
			separation.normalized() * SEPARATION_WEIGHT +
			alignment.normalized() * ALIGNMENT_WEIGHT +
			cohesion.normalized() * COHESION_WEIGHT +
			seek * SEEK_WEIGHT +
			forward_pull
		)

		vel_i += acceleration * delta
		if vel_i.length() > MAX_SPEED:
			vel_i = vel_i.normalized() * MAX_SPEED
		_boid_velocities[i] = vel_i
		_boid_positions[i] += vel_i * delta

		# Check if boid hit a target
		if best_dist < 0.2:
			for target in _target_cache:
				if is_instance_valid(target) and world_pos.distance_to(target.global_position) < 0.3:
					_dispatch_transformation(target)
					_boid_alive[i] = false
					_multimesh.set_instance_color(i, Color(0, 0, 0, 0))
					var t := Transform3D()
					t.origin = Vector3(0, -100, 0)
					_multimesh.set_instance_transform(i, t)
					break

		if _boid_alive[i]:
			var t := Transform3D()
			t.origin = _boid_positions[i]
			_multimesh.set_instance_transform(i, t)

	# Check if any alive
	if not _boid_alive.any(func(v): return v):
		has_hit = true
		_cleanup()

func _scan_targets() -> void:
	_target_cache.clear()
	if not is_inside_tree():
		return
	# Scan BOTH legacy practice targets and biome-borne foes.
	var targets: Array = get_tree().get_nodes_in_group("catalyst_target")
	targets.append_array(get_tree().get_nodes_in_group("catalyst_foe"))
	for t in targets:
		if t is Node3D and is_instance_valid(t):
			if t.global_position.distance_to(global_position) < SEEK_RANGE:
				_target_cache.append(t)

func _on_hit(body: Node3D) -> void:
	# Base class _on_body_entered already dispatched the transformation
	# (_dispatch_transformation runs first). Just emit signal + decorative work.
	projectile_hit.emit(body, global_position)
	# Kill nearby boids on collision
	for i in BOID_COUNT:
		if _boid_alive[i]:
			var world_pos := global_position + _boid_positions[i]
			if world_pos.distance_to(global_position) < 0.2:
				_boid_alive[i] = false
				_multimesh.set_instance_color(i, Color(0, 0, 0, 0))
	if not _boid_alive.any(func(v): return v):
		has_hit = true
