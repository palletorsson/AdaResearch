# @identity
# essence: F = -k*x -- 3x3 grid of mass nodes connected by springs obeying Hooke's law
# desire: nine masses connected by springs deforming under stress, tension converted to damage
# critical_parameter: spring constants / mass positions -- k determines stiffness; deformation generates damage
# triggers: continuous spring simulation; masses oscillate under Hooke's law; contact triggers damage
# emerges: soft body physics as threat -- the jiggling mass-spring system damages through deformation
# needs: HazardCreatureBase [has]; 3x3 mass-spring grid [has]; Hooke's law [has]; tension viz [has]; VR interaction [missing]
# relationships: embodies softbodies sequence; pairs with collision_crasher (elasticity vs impulse)
# truth: F = -k*x -- the spring knows only displacement and stiffness, yet soft body dynamics emerge.

extends HazardCreatureBase
class_name SpringMassBouncer
## Soft bodies sequence — 3x3 grid of mass nodes connected by springs.
## Hooke's law spring physics with damping. Nodes jiggle and deform
## when the creature moves or collides. Contact damage scales with
## spring compression at impact point.

@export_group("Spring Physics")
@export var spring_k: float = 40.0       # Spring constant (stiffness)
@export var damping: float = 2.0         # Damping coefficient
@export var node_mass: float = 1.0       # Mass of each node
@export var rest_length: float = 0.18    # Rest distance between adjacent nodes
@export var node_radius: float = 0.05

@export_group("Combat")
@export var base_damage: float = 10.0
@export var tension_damage_multiplier: float = 3.0

# ── Spring-Mass State ──────────────────────────────────────────────────
const GRID_SIZE: int = 3

var _mass_positions: Array[Vector3] = []   # Local offsets from center of mass
var _mass_velocities: Array[Vector3] = []
var _springs: Array[Array] = []            # [idx_a, idx_b]
var _mass_meshes: Array[MeshInstance3D] = []
var _mass_mats: Array[StandardMaterial3D] = []
var _total_tension: float = 0.0
var _total_energy: float = 0.0
var _label: Label3D = null
var _base_color: Color = Color(0.95, 0.55, 0.15)
var _hot_color: Color = Color(0.95, 0.15, 0.05)
var _time: float = 0.0


func _on_ready() -> void:
	max_health = 70.0
	_health = max_health
	chase_speed = 2.8
	patrol_speed = 1.6
	contact_damage = 12.0
	detection_radius = 8.0


func _create_materials() -> void:
	pass  # Materials created per-node in _build_mesh


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.35
	col.shape = shape
	col.position.y = 0.35
	add_child(col)


func _build_mesh() -> void:
	_mesh_root.position.y = 0.35

	# Initialize 3x3 grid of mass nodes
	for row in range(GRID_SIZE):
		for col_idx in range(GRID_SIZE):
			var x: float = (col_idx - 1) * rest_length
			var z: float = (row - 1) * rest_length
			var pos := Vector3(x, 0, z)
			_mass_positions.append(pos)
			_mass_velocities.append(Vector3.ZERO)

			var mat := _make_material(_base_color, _base_color * 0.6)
			_mass_mats.append(mat)

			var sphere := SphereMesh.new()
			sphere.radius = node_radius
			sphere.height = node_radius * 2.0
			var mi := _add_mesh(sphere, mat, pos)
			mi.name = "Mass_%d_%d" % [row, col_idx]
			_mass_meshes.append(mi)

	# Build springs — horizontal and vertical connections (12 springs)
	for row in range(GRID_SIZE):
		for col_idx in range(GRID_SIZE):
			var idx: int = row * GRID_SIZE + col_idx
			# Right neighbor
			if col_idx < GRID_SIZE - 1:
				_springs.append([idx, idx + 1])
			# Down neighbor
			if row < GRID_SIZE - 1:
				_springs.append([idx, idx + GRID_SIZE])

	# Label
	_label = Label3D.new()
	_label.text = ""
	_label.font_size = 36
	_label.pixel_size = 0.003
	_label.position = Vector3(0, 0.4, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1, 1, 1, 0.85)
	_mesh_root.add_child(_label)


func _process_visual(delta: float) -> void:
	_time += delta

	# ── Spring physics simulation ──────────────────────────────────
	_total_tension = 0.0
	_total_energy = 0.0

	# Compute spring forces
	var forces: Array[Vector3] = []
	forces.resize(_mass_positions.size())
	for i in range(forces.size()):
		forces[i] = Vector3.ZERO

	for spring in _springs:
		var a: int = spring[0]
		var b: int = spring[1]
		var diff: Vector3 = _mass_positions[b] - _mass_positions[a]
		var dist: float = diff.length()
		if dist < 0.001:
			continue

		var displacement: float = dist - rest_length
		var force_magnitude: float = spring_k * displacement  # Hooke's law
		var force_dir: Vector3 = diff.normalized()

		# Spring force
		var spring_force: Vector3 = force_dir * force_magnitude
		forces[a] += spring_force
		forces[b] -= spring_force

		# Damping force (velocity-dependent)
		var rel_vel: Vector3 = _mass_velocities[b] - _mass_velocities[a]
		var damp_force: Vector3 = force_dir * rel_vel.dot(force_dir) * damping
		forces[a] += damp_force
		forces[b] -= damp_force

		_total_tension += abs(displacement)
		_total_energy += 0.5 * spring_k * displacement * displacement

	# Add kinetic energy
	for i in range(_mass_velocities.size()):
		_total_energy += 0.5 * node_mass * _mass_velocities[i].length_squared()

	# Integrate (semi-implicit Euler)
	for i in range(_mass_positions.size()):
		var acceleration: Vector3 = forces[i] / node_mass
		_mass_velocities[i] += acceleration * delta
		# Additional damping to prevent divergence
		_mass_velocities[i] *= 0.98
		_mass_positions[i] += _mass_velocities[i] * delta

	# Constrain: keep center of mass at origin
	var com := Vector3.ZERO
	for pos in _mass_positions:
		com += pos
	com /= float(_mass_positions.size())
	for i in range(_mass_positions.size()):
		_mass_positions[i] -= com

	# Update mesh positions and colors
	for i in range(_mass_meshes.size()):
		_mass_meshes[i].position = _mass_positions[i]

		# Color based on local tension (speed of this node)
		var speed: float = _mass_velocities[i].length()
		var tension_t: float = clampf(speed / 2.0, 0.0, 1.0)
		var c: Color = _base_color.lerp(_hot_color, tension_t)
		_mass_mats[i].albedo_color = c
		_mass_mats[i].emission = c * (0.4 + tension_t * 0.8)
		_mass_mats[i].emission_energy_multiplier = 1.0 + tension_t * 2.0

	# Label
	if _label:
		_label.text = "TENSION: %.2f, ENERGY: %.2f" % [_total_tension, _total_energy]


func _process_chase(delta: float) -> void:
	var dist: float = _get_player_distance()
	if dist > disengage_radius:
		_set_state(BaseState.PATROL)
		return

	if is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - global_position
		to_player.y = 0.0
		if to_player.length() > 0.1:
			var move_dir: Vector3 = to_player.normalized()
			velocity.x = move_dir.x * chase_speed
			velocity.z = move_dir.z * chase_speed
			_face_direction(move_dir, delta * 5.0)

			# Movement excites springs — push front nodes forward
			for i in range(_mass_positions.size()):
				var local_forward: float = _mass_positions[i].dot(Vector3(0, 0, 1))
				if local_forward > 0:
					_mass_velocities[i] += move_dir * delta * 0.5
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	velocity.y = 0.0


func _on_damaged(_amount: float) -> void:
	# Excite springs — add random velocity to all nodes
	for i in range(_mass_velocities.size()):
		_mass_velocities[i] += Vector3(
			randf_range(-3.0, 3.0),
			randf_range(-1.0, 1.0),
			randf_range(-3.0, 3.0)
		)
	_set_state(BaseState.STUNNED)


func _on_state_changed(new_state: BaseState) -> void:
	if new_state == BaseState.CHASE:
		# Slightly excite springs on chase start
		for i in range(_mass_velocities.size()):
			_mass_velocities[i] += Vector3(
				randf_range(-0.5, 0.5),
				0,
				randf_range(-0.5, 0.5)
			)
