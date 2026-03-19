# @identity
# essence: state(t+1) = P(state(t)) -- floating tetrahedron with 4 face-states governed by probabilities
# desire: a Markov chain attacking in grammar -- lunge, sweep, projectile, shield -- transitions visible
# critical_parameter: _markov_state / transition probabilities -- which attack follows which, mutating over time
# triggers: transition_timer fires state changes; probabilities shift with mutations; attack follows state
# emerges: unpredictability with structure -- behavior is random but statistically learnable
# needs: HazardCreatureBase [has]; state machine [has]; visible probabilities [has]; mutation system [has]; VR interaction [missing]
# relationships: embodies grammar_systems sequence; Markov concept shared with generative_music
# truth: every stochastic process is a bet on what comes next -- and the probabilities are always drifting.

extends HazardCreatureBase
class_name GrammarMarkov
## Floating Markov chain creature with 4 colored face-states.
## Each face represents a state in the chain: RED(lunge), BLUE(sweep),
## GREEN(projectile), GOLD(shield). Transitions follow visible probabilities.
## After 3 full cycles the transition matrix mutates slightly.

enum MarkovState { RED, BLUE, GREEN, GOLD }

@export_group("Markov")
@export var transition_interval: float = 2.0
@export var lunge_speed: float = 6.0
@export var sweep_speed: float = 4.0
@export var projectile_speed: float = 8.0
@export var shield_heal: float = 5.0
@export var cycles_before_mutation: int = 3

# ── Markov State ────────────────────────────────────────────────────────

var _markov_state: MarkovState = MarkovState.RED
var _transition_timer: float = 0.0
var _cycle_count: int = 0
var _transitions_in_cycle: int = 0
var _mutation_count: int = 0

# Transition matrix: _trans[from][to] = probability
# Rows must sum to 1.0
var _trans: Array[Array] = [
	[0.1, 0.4, 0.3, 0.2],  # RED  -> ...
	[0.3, 0.1, 0.2, 0.4],  # BLUE -> ...
	[0.2, 0.3, 0.1, 0.4],  # GREEN-> ...
	[0.4, 0.2, 0.3, 0.1],  # GOLD -> ...
]

# ── Visual refs ─────────────────────────────────────────────────────────

var _body_mesh: MeshInstance3D = null
var _face_meshes: Array[MeshInstance3D] = []
var _face_materials: Array[StandardMaterial3D] = []
var _label: Label3D = null
var _body_material: StandardMaterial3D = null

# Attack state
var _attack_timer: float = 0.0
var _is_lunging: bool = false
var _lunge_dir: Vector3 = Vector3.ZERO
var _is_sweeping: bool = false
var _sweep_angle: float = 0.0
var _projectile_cooldown: float = 0.0

const FACE_COLORS: Array[Color] = [
	Color(0.9, 0.15, 0.1),   # RED
	Color(0.1, 0.3, 0.9),    # BLUE
	Color(0.1, 0.85, 0.2),   # GREEN
	Color(0.95, 0.8, 0.1),   # GOLD
]

const FACE_NAMES: Array[String] = ["RED", "BLUE", "GREEN", "GOLD"]

const FACE_DIRECTIONS: Array[Vector3] = [
	Vector3(0, 0, 1),    # RED   - front
	Vector3(0, 0, -1),   # BLUE  - back
	Vector3(1, 0, 0),    # GREEN - right
	Vector3(-1, 0, 0),   # GOLD  - left
]


func _on_ready() -> void:
	# Float above ground
	_mesh_root.position.y = 0.8
	max_health = 80.0
	_health = max_health
	chase_speed = 2.0
	patrol_speed = 1.2


func _create_materials() -> void:
	_body_material = _make_material(Color(0.3, 0.3, 0.35), Color(0.1, 0.1, 0.15))
	_face_materials.clear()
	for i in range(4):
		var mat := _make_material(FACE_COLORS[i], FACE_COLORS[i] * 0.3)
		_face_materials.append(mat)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.35
	col.shape = shape
	col.position.y = 0.8
	add_child(col)


func _build_mesh() -> void:
	# Central torus body
	var torus := TorusMesh.new()
	torus.inner_radius = 0.12
	torus.outer_radius = 0.25
	_body_mesh = _add_mesh(torus, _body_material)

	# 4 prism faces at cardinal directions
	for i in range(4):
		var prism := PrismMesh.new()
		prism.size = Vector3(0.12, 0.12, 0.06)
		var mi := _add_mesh(prism, _face_materials[i], FACE_DIRECTIONS[i] * 0.28)
		# Orient face outward
		mi.look_at_from_position(mi.position, mi.position + FACE_DIRECTIONS[i], Vector3.UP)
		_face_meshes.append(mi)

	# Transition label
	_label = Label3D.new()
	_label.text = ""
	_label.font_size = 48
	_label.pixel_size = 0.003
	_label.position = Vector3(0, 0.35, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1, 1, 1, 0.9)
	_mesh_root.add_child(_label)

	_update_face_glow()


func _process_visual(delta: float) -> void:
	# Gentle float bob
	_mesh_root.position.y = 0.8 + sin(_state_time * 2.0) * 0.05

	# Slow rotation on patrol
	if _state == BaseState.PATROL or _state == BaseState.IDLE:
		_mesh_root.rotation.y += delta * 0.5

	# Sweep rotation
	if _is_sweeping:
		_sweep_angle += delta * sweep_speed * TAU
		_mesh_root.rotation.y = _sweep_angle
		if _sweep_angle >= TAU:
			_is_sweeping = false
			_sweep_angle = 0.0

	# Projectile cooldown
	_projectile_cooldown = max(0.0, _projectile_cooldown - delta)


func _process_chase(delta: float) -> void:
	_transition_timer += delta

	if _transition_timer >= transition_interval:
		_transition_timer = 0.0
		_do_markov_transition()
		_execute_current_attack()

	# Lunge movement
	if _is_lunging:
		_attack_timer -= delta
		velocity.x = _lunge_dir.x * lunge_speed
		velocity.z = _lunge_dir.z * lunge_speed
		velocity.y = 0.0
		if _attack_timer <= 0.0:
			_is_lunging = false
			velocity = Vector3.ZERO
	elif not _is_sweeping:
		# Slow drift toward player between attacks
		var dist := _get_player_distance()
		if dist > disengage_radius:
			_set_state(BaseState.PATROL)
			return
		if is_instance_valid(_player_node):
			var dir := _get_player_direction()
			velocity.x = dir.x * chase_speed * 0.4
			velocity.z = dir.z * chase_speed * 0.4
			velocity.y = 0.0
		else:
			velocity = Vector3.ZERO


func _do_markov_transition() -> void:
	var from_idx: int = _markov_state as int
	var row: Array = _trans[from_idx]
	var roll: float = randf()
	var cumulative: float = 0.0
	var next_idx: int = 0

	for i in range(4):
		cumulative += row[i]
		if roll <= cumulative:
			next_idx = i
			break

	var old_state := _markov_state
	_markov_state = next_idx as MarkovState

	# Update label
	if _label:
		var prob_str := "%.1f" % row[next_idx]
		_label.text = "%s->%s (%s)" % [FACE_NAMES[old_state as int], FACE_NAMES[next_idx], prob_str]

	_update_face_glow()

	# Track cycles
	_transitions_in_cycle += 1
	if _transitions_in_cycle >= 4:
		_transitions_in_cycle = 0
		_cycle_count += 1
		if _cycle_count >= cycles_before_mutation:
			_cycle_count = 0
			_mutate_matrix()


func _execute_current_attack() -> void:
	match _markov_state:
		MarkovState.RED:
			_start_lunge()
		MarkovState.BLUE:
			_start_sweep()
		MarkovState.GREEN:
			_fire_projectile()
		MarkovState.GOLD:
			_activate_shield()


func _start_lunge() -> void:
	_is_lunging = true
	_attack_timer = 0.4
	_lunge_dir = _get_player_direction()


func _start_sweep() -> void:
	_is_sweeping = true
	_sweep_angle = 0.0


func _fire_projectile() -> void:
	if _projectile_cooldown > 0.0:
		return
	_projectile_cooldown = 1.0

	# Create a small projectile sphere
	var proj := RigidBody3D.new()
	proj.gravity_scale = 0.0
	proj.freeze = false

	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.05
	sphere_mesh.height = 0.1
	var mi := MeshInstance3D.new()
	mi.mesh = sphere_mesh
	var mat := _make_material(FACE_COLORS[MarkovState.GREEN], FACE_COLORS[MarkovState.GREEN])
	mi.set_surface_override_material(0, mat)
	proj.add_child(mi)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.05
	col.shape = shape
	proj.add_child(col)

	var dir := _get_player_direction()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position + Vector3(0, 0.8, 0) + dir * 0.4
	proj.linear_velocity = dir * projectile_speed + Vector3(0, 2.0, 0)

	# Auto-remove after 4 seconds
	var timer := get_tree().create_timer(4.0)
	timer.timeout.connect(func(): if is_instance_valid(proj): proj.queue_free())


func _activate_shield() -> void:
	# Pause and heal
	velocity = Vector3.ZERO
	_health = min(max_health, _health + shield_heal)


func _update_face_glow() -> void:
	for i in range(_face_meshes.size()):
		var is_active: bool = (i == _markov_state as int)
		var mat: StandardMaterial3D = _face_materials[i]
		if is_active:
			mat.emission_energy_multiplier = 3.0
			mat.albedo_color = FACE_COLORS[i]
		else:
			mat.emission_energy_multiplier = 0.3
			mat.albedo_color = FACE_COLORS[i] * 0.4


func _mutate_matrix() -> void:
	_mutation_count += 1
	for row_idx in range(4):
		# Pick a random pair of entries and shift probability
		var a: int = randi_range(0, 3)
		var b: int = (a + randi_range(1, 3)) % 4
		var shift: float = randf_range(-0.1, 0.1)

		_trans[row_idx][a] = max(0.05, _trans[row_idx][a] + shift)
		_trans[row_idx][b] = max(0.05, _trans[row_idx][b] - shift)

		# Renormalize row
		var row_sum: float = 0.0
		for j in range(4):
			row_sum += _trans[row_idx][j]
		for j in range(4):
			_trans[row_idx][j] /= row_sum


func _on_damaged(_amount: float) -> void:
	# Flash all faces white briefly then return
	for mat in _face_materials:
		mat.emission_energy_multiplier = 5.0
	_set_state(BaseState.STUNNED)


func _on_state_changed(new_state: BaseState) -> void:
	if new_state == BaseState.CHASE:
		_transition_timer = 0.0
		_is_lunging = false
		_is_sweeping = false
	elif new_state == BaseState.PATROL or new_state == BaseState.IDLE:
		_is_lunging = false
		_is_sweeping = false
		if _label:
			_label.text = ""
	elif new_state == BaseState.STUNNED:
		_is_lunging = false
		_is_sweeping = false
		velocity = Vector3.ZERO
