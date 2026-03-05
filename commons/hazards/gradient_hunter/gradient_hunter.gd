extends HazardCreatureBase
class_name GradientHunter
## Sleek predator that uses gradient descent to find the player.
## Instead of direct pathfinding, samples 6 positions around itself,
## evaluates distance-to-player at each, and moves toward the lowest.
## Gets stuck behind walls (local minimum) — if stuck for >3 seconds,
## "anneals" by jumping to a random offset position.

@export_group("Gradient Descent")
@export var learning_rate: float = 3.0
@export var sample_radius: float = 0.8
@export var anneal_timeout: float = 3.0
@export var anneal_jump_radius: float = 2.5
@export var sample_count: int = 6

@export_group("Visual")
@export var body_inner_radius: float = 0.08
@export var body_outer_radius: float = 0.22
@export var sample_sphere_radius: float = 0.04
@export var leg_length: float = 0.25
@export var leg_radius: float = 0.02

# ── Gradient state ───────────────────────────────────────────────────────

var _sample_positions: Array[Vector3] = []   # World-space sample offsets
var _sample_losses: Array[float] = []        # Distance values at each sample
var _gradient_dir: Vector3 = Vector3.ZERO    # Computed gradient direction
var _best_sample_idx: int = 0
var _worst_sample_idx: int = 0
var _current_loss: float = 0.0
var _stuck_timer: float = 0.0
var _last_position: Vector3 = Vector3.ZERO
var _stuck_threshold: float = 0.15           # Distance moved threshold for "stuck"

# ── Visual refs ──────────────────────────────────────────────────────────

var _body_mesh: MeshInstance3D = null
var _body_mat: StandardMaterial3D = null
var _sample_meshes: Array[MeshInstance3D] = []
var _sample_materials: Array[StandardMaterial3D] = []
var _arrow_mesh: MeshInstance3D = null
var _arrow_mat: StandardMaterial3D = null
var _label: Label3D = null
var _leg_roots: Array[Node3D] = []
var _leg_meshes: Array[MeshInstance3D] = []
var _walk_phase: float = 0.0

# Colors
var _best_color: Color = Color(0.1, 0.95, 0.2)    # green
var _worst_color: Color = Color(0.95, 0.1, 0.1)   # red
var _neutral_color: Color = Color(0.8, 0.8, 0.2)  # yellow


func _on_ready() -> void:
	max_health = 75.0
	_health = max_health
	chase_speed = 0.0  # We handle movement via gradient
	patrol_speed = 1.2
	contact_damage = 18.0
	_last_position = global_position

	# Initialize sample arrays
	_sample_positions.resize(sample_count)
	_sample_losses.resize(sample_count)
	for i in range(sample_count):
		_sample_positions[i] = Vector3.ZERO
		_sample_losses[i] = 0.0


func _create_materials() -> void:
	_body_mat = _make_material(Color(0.15, 0.15, 0.2), Color(0.05, 0.05, 0.15))
	_arrow_mat = _make_material(Color(0.9, 0.9, 0.1), Color(0.9, 0.9, 0.1))
	_sample_materials.clear()
	for i in range(sample_count):
		var mat := _make_material(_neutral_color, _neutral_color * 0.5)
		_sample_materials.append(mat)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.25
	col.shape = shape
	col.position.y = leg_length + body_outer_radius
	add_child(col)


func _build_mesh() -> void:
	_mesh_root.position.y = leg_length + body_outer_radius

	# Elongated torus body (tube creature)
	var torus := TorusMesh.new()
	torus.inner_radius = body_inner_radius
	torus.outer_radius = body_outer_radius
	_body_mesh = _add_mesh(torus, _body_mat)

	# 6 sample point spheres floating around the body
	for i in range(sample_count):
		var sphere := SphereMesh.new()
		sphere.radius = sample_sphere_radius
		sphere.height = sample_sphere_radius * 2.0
		var angle: float = (float(i) / float(sample_count)) * TAU
		var pos := Vector3(cos(angle) * sample_radius, 0, sin(angle) * sample_radius)
		var mi := _add_mesh(sphere, _sample_materials[i], pos)
		mi.name = "Sample_%d" % i
		_sample_meshes.append(mi)

	# Arrow mesh pointing in gradient direction (thin cylinder)
	var arrow_cyl := CylinderMesh.new()
	arrow_cyl.height = 0.3
	arrow_cyl.top_radius = 0.005
	arrow_cyl.bottom_radius = 0.02
	_arrow_mesh = _add_mesh(arrow_cyl, _arrow_mat, Vector3(0, 0, 0))
	_arrow_mesh.name = "GradientArrow"

	# 4 legs
	for i in range(4):
		_build_leg(i)

	# Info label
	_label = Label3D.new()
	_label.text = ""
	_label.font_size = 40
	_label.pixel_size = 0.003
	_label.position = Vector3(0, body_outer_radius + 0.2, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1, 1, 1, 0.85)
	_mesh_root.add_child(_label)


func _build_leg(index: int) -> void:
	var root := Node3D.new()
	root.name = "Leg_%d" % index
	# Position legs at corners under the body
	var angle: float = (float(index) / 4.0) * TAU + PI / 4.0
	var x: float = cos(angle) * body_outer_radius * 0.7
	var z: float = sin(angle) * body_outer_radius * 0.7
	root.position = Vector3(x, -body_outer_radius * 0.5, z)
	_mesh_root.add_child(root)
	_leg_roots.append(root)

	var cyl := CylinderMesh.new()
	cyl.height = leg_length
	cyl.top_radius = leg_radius
	cyl.bottom_radius = leg_radius * 0.7
	var leg_mat := _make_material(Color(0.2, 0.2, 0.25), Color.BLACK)
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.set_surface_override_material(0, leg_mat)
	mi.position = Vector3(0, -leg_length * 0.5, 0)
	root.add_child(mi)
	_leg_meshes.append(mi)


func _process_visual(delta: float) -> void:
	# Walk animation
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		_walk_phase += delta * 5.0
		for i in range(_leg_roots.size()):
			var phase_offset: float = float(i) * PI * 0.5
			_leg_roots[i].rotation.x = sin(_walk_phase + phase_offset) * 0.3
			_leg_roots[i].rotation.z = cos(_walk_phase + phase_offset) * 0.15

	# Update sample sphere positions (orbit slowly)
	for i in range(_sample_meshes.size()):
		var angle: float = (float(i) / float(sample_count)) * TAU + _state_time * 0.5
		var pos := Vector3(cos(angle) * sample_radius, sin(angle * 2.0) * 0.1, sin(angle) * sample_radius)
		_sample_meshes[i].position = pos

	# Update arrow orientation to point in gradient direction
	if _gradient_dir.length() > 0.01 and is_instance_valid(_arrow_mesh):
		var local_dir := _gradient_dir
		_arrow_mesh.position = local_dir * 0.2
		# Align cylinder with gradient direction
		var up := Vector3.UP
		if abs(local_dir.dot(up)) > 0.95:
			up = Vector3.RIGHT
		_arrow_mesh.look_at_from_position(_arrow_mesh.position, _arrow_mesh.position + local_dir, up)
		_arrow_mesh.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	# Update label
	if _label:
		_label.text = "loss=%.2f, lr=%.1f" % [_current_loss, learning_rate]


func _process_chase(delta: float) -> void:
	if not is_instance_valid(_player_node):
		velocity = Vector3.ZERO
		return

	var dist := _get_player_distance()
	if dist > disengage_radius:
		_set_state(BaseState.PATROL)
		return

	# ── Gradient descent step ────────────────────────────────────────
	_compute_gradient()

	# Move in gradient direction
	velocity.x = -_gradient_dir.x * learning_rate
	velocity.z = -_gradient_dir.z * learning_rate
	velocity.y = 0.0

	_face_direction(-_gradient_dir, delta * 3.0)

	# ── Stuck detection (local minimum) ──────────────────────────────
	var moved := global_position.distance_to(_last_position)
	if moved < _stuck_threshold * delta:
		_stuck_timer += delta
	else:
		_stuck_timer = max(0.0, _stuck_timer - delta * 0.5)

	if _stuck_timer > anneal_timeout:
		_anneal()
		_stuck_timer = 0.0

	_last_position = global_position


func _compute_gradient() -> void:
	if not is_instance_valid(_player_node):
		_gradient_dir = Vector3.ZERO
		return

	var best_loss: float = INF
	var worst_loss: float = -INF

	for i in range(sample_count):
		var angle: float = (float(i) / float(sample_count)) * TAU
		var sample_offset := Vector3(cos(angle), 0, sin(angle)) * sample_radius
		var sample_world_pos: Vector3 = global_position + sample_offset

		# Loss function = distance to player
		var loss: float = sample_world_pos.distance_to(_player_node.global_position)
		_sample_losses[i] = loss
		_sample_positions[i] = sample_offset

		if loss < best_loss:
			best_loss = loss
			_best_sample_idx = i
		if loss > worst_loss:
			worst_loss = loss
			_worst_sample_idx = i

	_current_loss = global_position.distance_to(_player_node.global_position)

	# Compute gradient as weighted average direction toward higher loss
	_gradient_dir = Vector3.ZERO
	for i in range(sample_count):
		var normalized_loss: float = 0.0
		if worst_loss - best_loss > 0.001:
			normalized_loss = (_sample_losses[i] - best_loss) / (worst_loss - best_loss)
		_gradient_dir += _sample_positions[i].normalized() * normalized_loss

	if _gradient_dir.length() > 0.01:
		_gradient_dir = _gradient_dir.normalized()

	# Update sample colors: best=green, worst=red, others=lerp
	for i in range(sample_count):
		if i < _sample_materials.size():
			if i == _best_sample_idx:
				_sample_materials[i].albedo_color = _best_color
				_sample_materials[i].emission = _best_color
				_sample_materials[i].emission_energy_multiplier = 2.0
			elif i == _worst_sample_idx:
				_sample_materials[i].albedo_color = _worst_color
				_sample_materials[i].emission = _worst_color
				_sample_materials[i].emission_energy_multiplier = 2.0
			else:
				var t: float = 0.5
				if worst_loss - best_loss > 0.001:
					t = (_sample_losses[i] - best_loss) / (worst_loss - best_loss)
				var c := _best_color.lerp(_worst_color, t)
				_sample_materials[i].albedo_color = c
				_sample_materials[i].emission = c * 0.5
				_sample_materials[i].emission_energy_multiplier = 1.0


func _anneal() -> void:
	# Simulated annealing: jump to random offset to escape local minimum
	var jump := Vector3(
		randf_range(-anneal_jump_radius, anneal_jump_radius),
		0,
		randf_range(-anneal_jump_radius, anneal_jump_radius)
	)
	global_position += jump

	# Visual feedback: flash sample points
	for mat in _sample_materials:
		mat.albedo_color = Color.WHITE
		mat.emission = Color.WHITE
		mat.emission_energy_multiplier = 4.0


func _on_damaged(_amount: float) -> void:
	# Getting hit increases learning rate temporarily
	learning_rate = min(8.0, learning_rate + 1.0)
	_set_state(BaseState.STUNNED)


func _on_state_changed(new_state: BaseState) -> void:
	if new_state == BaseState.PATROL:
		_stuck_timer = 0.0
		learning_rate = 3.0
	elif new_state == BaseState.CHASE:
		_last_position = global_position
		_stuck_timer = 0.0
