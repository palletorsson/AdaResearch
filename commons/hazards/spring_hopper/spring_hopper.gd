# @identity
# essence: Hooke's law given legs — F = -kx as creature.
# desire: bounce endlessly, compress and release, launch anything that lands on top
# critical_parameter: _compression (0=fully extended/tall, 1=fully compressed/short)
# triggers: IDLE->WIND->BOUNCE->LAND->PATROL->DEAD
# emerges: the launch mechanic — player times a landing on the compressed spring to get boosted
# truth: A spring stores energy. Compression is potential. Release is motion. F = -kx is life.

extends CharacterBody3D
class_name SpringHopper
## A coil spring creature that bounces rhythmically.
## The player can ride on top during the compressed state to get launched upward.

signal enemy_destroyed(enemy: Node3D)

enum State { IDLE, WIND, BOUNCE, LAND, PATROL, DEAD }

## --- DNA (stage 2, promoted 2026-08-03) ---
##
## This creature's own truth line is "F = -kx is life", and the two axes are k and x.
##
## AXIS 1 — TEMPER: the spring constant written into the body.
## Before promotion `coil_turns = 6` was pure decoration: it set how many torus rings got
## stacked and entered no calculation anywhere. Wire gauge was not even that — it was the
## literal 0.75 inside `torus.inner_radius = coil_radius * 0.75`, a number with no name.
## But k is not a slider on a real spring, it is a SHAPE (k = Gd^4 / 8D^3n): few thick turns
## are stiff, many thin turns are soft, and you can read the constant off the object without
## touching it. temper co-varies turn count, wire gauge, the compression floor and the bounce
## the creature can actually produce, so the number and the silhouette stop disagreeing.
##   stock  6 turns, gauge 0.75, floor 0.15 - the shipped lineage, and a pure no-op branch.
##   fine   14 thin turns. Low k: a tall stack of hairs that gives way and throws high.
##   heavy  4 fat turns. High k: barely yields, and what it stores it returns short.
##   bound  5 turns so thick they overlap at rest. Solid length reached before any load
##          arrives - a spring that cannot compress, which is to say not a spring.
##
## AXIS 2 — POSTURE: where on the F = -kx line this one is caught standing.
## `_compression` is already the declared critical_parameter and already drives the whole
## body (coil Y-scale 1.0 -> floor, head height, head squash/stretch), but nothing outside
## the state machine could ever set it, so every spring_hopper in the corpus stands at the
## same 0.05 idle wobble. posture pins the RESTING compression - the x the spring holds
## while nothing is happening - and leaves WIND / BOUNCE / LAND to run from and return to
## it. Height stops being a fact about the creature and becomes a fact about its load.
##   cycle   sentinel: the state machine keeps sole ownership of _compression. Shipped.
##   drawn   -0.25, in tension. Coil stretched, head drawn thin. Storing by being pulled.
##   laden   0.40, standing under weight. Coil at two thirds, head level dropped.
##   solid   0.90, crushed nearly to its floor. Maximum potential, nowhere left to go.
## `cycle` is deliberately the only slack value: an "extended" rung would photograph as a
## near-duplicate of cycle and buy a fifth frame that answers nothing.
##
## Both defaults are no-ops and the 5 existing placements (Chamber_SoftBodies, _p1, _p2,
## _p3, Gallery_Hazards) are byte-identical to before.
##
## NOT declared, deliberately: bounce_period, launch_force and contact_damage are rates and
## impulses, invisible to a still. And `regime` (spring_demo, mass_spring_damper,
## harmonic_motion_demo: free/underdamped/critical/overdamped) was the obvious word to
## borrow and would have been a lie - those three integrate an ODE with a damping term, and
## this creature has no damping term and no integrator. Its compression is animated by a
## state machine. Sharing their word would claim a comparability that does not exist.
## `posture` is borrowed on purpose, from armadillo_eggling and kresling_spire in this same
## registry: same question (which body is this creature holding), same sentinel-first shape
## as kresling_spire's `cycle`, and the three measure alike.
const TEMPERS: PackedStringArray = ["stock", "fine", "heavy", "bound"]
const POSTURES: PackedStringArray = ["cycle", "drawn", "laden", "solid"]

@export_enum("stock", "fine", "heavy", "bound") var temper: String = "stock"
@export_enum("cycle", "drawn", "laden", "solid") var posture: String = "cycle"

## Fixture knob, not an axis. 1.0 is the shipped fall. The sweep harness builds no floor,
## so a CharacterBody3D left at 1.0 drops out of a fixed frame during the settle and the
## diff measures displacement instead of the axis.
@export var gravity_scale: float = 1.0

@export_group("Geometry")
@export var coil_radius: float = 0.18
@export var coil_height: float = 0.5  # fully extended height
@export var coil_turns: int = 6
@export var head_radius: float = 0.15

@export_group("Combat")
@export var max_health: float = 45.0
@export var patrol_speed: float = 0.8
@export var bounce_height: float = 2.5  # meters
@export var bounce_period: float = 2.0  # seconds per bounce cycle
@export var contact_damage: float = 12.0
@export var launch_force: float = 8.0  # upward velocity given to player on stomp
@export var detection_radius: float = 6.0

@export_group("Appearance")
@export var coil_color: Color = Color(0.8, 0.2, 0.2)
@export var head_color: Color = Color(0.9, 0.75, 0.2)
@export var eye_color: Color = Color(0.1, 0.1, 0.1)
@export var emission_color: Color = Color(1.0, 0.4, 0.2)

# Shipped constants, now named so `stock` / `cycle` can restore them exactly.
const STOCK_WIRE_RATIO: float = 0.75
const STOCK_COIL_FLOOR: float = 0.15

# Derived from temper / posture. These hold the shipped values until told otherwise.
var _wire_ratio: float = STOCK_WIRE_RATIO
var _coil_floor: float = STOCK_COIL_FLOOR
var _rest: float = 0.0
var _pinned: bool = false

# State
var _health: float = 0.0
var _state: State = State.IDLE
var _state_time: float = 0.0
var _compression: float = 0.0  # 0 = fully extended, 1 = fully compressed
var _bounce_phase: float = 0.0
var _player_node: Node3D = null
var _base_y: float = 0.0  # ground level for bounce calculation
var _patrol_timer: float = 0.0
var _patrol_direction: Vector3 = Vector3.ZERO
var _dead_wobble_phase: float = 0.0

# Mesh nodes
var _mesh_root: Node3D = null
var _coil_root: Node3D = null
var _coil_meshes: Array[MeshInstance3D] = []
var _head_mesh: MeshInstance3D = null
var _base_mesh: MeshInstance3D = null
var _eye_left: MeshInstance3D = null
var _eye_right: MeshInstance3D = null

# Materials
var _coil_material: StandardMaterial3D
var _head_material: StandardMaterial3D
var _eye_material: StandardMaterial3D
var _base_material: StandardMaterial3D

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


## --- Genome resolution ---
##
## `stock` and `cycle` write nothing that was not already true, so an artifact that never
## hears about either axis is unchanged.

func _apply_temper() -> void:
	match temper:
		"fine":
			coil_turns = 14
			_wire_ratio = 0.90
			_coil_floor = 0.10
			bounce_height = 3.6
		"heavy":
			coil_turns = 4
			_wire_ratio = 0.55
			_coil_floor = 0.42
			bounce_height = 1.6
		"bound":
			coil_turns = 5
			_wire_ratio = 0.12
			_coil_floor = 0.86
			bounce_height = 0.5
		_:
			_wire_ratio = STOCK_WIRE_RATIO
			_coil_floor = STOCK_COIL_FLOOR


func _apply_posture() -> void:
	match posture:
		"drawn":
			_rest = -0.25
			_pinned = true
		"laden":
			_rest = 0.4
			_pinned = true
		"solid":
			_rest = 0.9
			_pinned = true
		_:
			_rest = 0.0
			_pinned = false


func _ready() -> void:
	_apply_temper()
	_apply_posture()
	_health = max_health
	_base_y = global_position.y
	_create_materials()
	_build_collision()
	_build_mesh()
	_find_player()
	add_to_group("enemy")
	add_to_group("spring_enemy")
	_set_state(State.IDLE)
	print("SpringHopper: READY at %s" % global_position)


func _physics_process(delta: float) -> void:
	_state_time += delta

	if not is_instance_valid(_player_node):
		_find_player()

	# Apply gravity when airborne
	if not is_on_floor():
		velocity.y -= _gravity * gravity_scale * delta
	else:
		# Track ground level
		_base_y = global_position.y

	match _state:
		State.IDLE:
			_process_idle(delta)
		State.WIND:
			_process_wind(delta)
		State.BOUNCE:
			_process_bounce(delta)
		State.LAND:
			_process_land(delta)
		State.PATROL:
			_process_patrol(delta)
		State.DEAD:
			_process_dead(delta)

	_update_mesh(delta)

	if _state != State.DEAD:
		move_and_slide()


## --- State processors ---

func _process_idle(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0

	# Gentle wobble. A pinned posture stands dead still instead — a spring holding a load
	# does not breathe, and a still frame of a wobbling subject depends on capture timing.
	_bounce_phase += delta * 2.0
	if _pinned:
		_compression = _rest
	else:
		_compression = 0.1 * sin(_bounce_phase) * 0.5 + 0.05

	var dist: float = _get_player_distance()
	if dist <= detection_radius:
		_set_state(State.PATROL)


func _process_wind(_delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0

	# Compress over 0.5 seconds, from wherever the load leaves it standing
	var t: float = clamp(_state_time / 0.5, 0.0, 1.0)
	_compression = lerp(_rest, 1.0, ease(t, 2.0))

	if t >= 1.0:
		# Check if player is on top for launch
		if _check_player_on_top():
			_launch_player()
		# Release! Transition to BOUNCE
		_compression = _rest
		velocity.y = sqrt(2.0 * _gravity * bounce_height)
		_set_state(State.BOUNCE)


func _process_bounce(_delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0

	# Stretch effect during ascent
	if velocity.y > 0.0:
		_compression = -0.2 * clamp(velocity.y / 5.0, 0.0, 1.0)  # Negative = stretch
	else:
		_compression = 0.0

	# Landed
	if is_on_floor() and _state_time > 0.1:
		_compression = 0.8
		_set_state(State.LAND)


func _process_land(_delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0

	# Impact squash then spring back over 0.3s, settling onto the resting load
	var t: float = clamp(_state_time / 0.3, 0.0, 1.0)
	_compression = lerp(0.8, _rest, ease(t, 0.3))

	if t >= 1.0:
		# Try to damage player on contact
		_try_damage_player()

		var dist: float = _get_player_distance()
		if dist <= detection_radius:
			_set_state(State.PATROL)
		else:
			_set_state(State.IDLE)


func _process_patrol(delta: float) -> void:
	_patrol_timer += delta

	# Gentle idle compression while patrolling, about whatever it is standing under
	_bounce_phase += delta * 3.0
	_compression = _rest + 0.05 + 0.08 * sin(_bounce_phase)

	var dist: float = _get_player_distance()

	# Disengage if player too far
	if dist > detection_radius * 1.5:
		_set_state(State.IDLE)
		return

	# Time to bounce again
	if _patrol_timer >= bounce_period:
		_set_state(State.WIND)
		return

	# Waddle toward player
	if is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - global_position
		to_player.y = 0.0
		if to_player.length() > 0.5:
			var move_dir: Vector3 = to_player.normalized()
			velocity.x = move_dir.x * patrol_speed
			velocity.z = move_dir.z * patrol_speed
			_face_player(delta * 3.0)
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		velocity.x = 0.0
		velocity.z = 0.0


func _process_dead(delta: float) -> void:
	velocity = Vector3.ZERO
	_dead_wobble_phase += delta * 8.0
	_compression = 0.5 + 0.3 * sin(_dead_wobble_phase) * exp(-_state_time * 0.8)

	if _state_time >= 3.0:
		_health = max_health
		_set_state(State.IDLE)


func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	_state_time = 0.0
	if new_state == State.PATROL:
		_patrol_timer = 0.0


## --- Launch mechanic ---

func _check_player_on_top() -> bool:
	if not is_instance_valid(_player_node):
		return false
	var player_pos: Vector3 = _player_node.global_position
	var my_pos: Vector3 = global_position
	var horizontal_dist: float = Vector2(player_pos.x - my_pos.x, player_pos.z - my_pos.z).length()
	var height_diff: float = player_pos.y - my_pos.y
	return horizontal_dist < coil_radius * 2.0 and height_diff > 0.0 and height_diff < coil_height * 1.5


func _launch_player() -> void:
	if not is_instance_valid(_player_node):
		return
	if _player_node.has_method("apply_launch"):
		_player_node.apply_launch(Vector3.UP * launch_force)
	elif _player_node is CharacterBody3D:
		_player_node.velocity.y = launch_force


## --- Materials ---

func _create_materials() -> void:
	_coil_material = StandardMaterial3D.new()
	_coil_material.albedo_color = coil_color
	_coil_material.metallic = 0.6
	_coil_material.roughness = 0.35
	_coil_material.emission_enabled = true
	_coil_material.emission = emission_color * 0.3
	_coil_material.emission_energy_multiplier = 0.2

	_head_material = StandardMaterial3D.new()
	_head_material.albedo_color = head_color
	_head_material.metallic = 0.2
	_head_material.roughness = 0.5

	_eye_material = StandardMaterial3D.new()
	_eye_material.albedo_color = eye_color
	_eye_material.metallic = 0.8
	_eye_material.roughness = 0.1

	_base_material = StandardMaterial3D.new()
	_base_material.albedo_color = Color(0.25, 0.25, 0.28)
	_base_material.metallic = 0.4
	_base_material.roughness = 0.6


## --- Collision ---

func _build_collision() -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "CollisionShape"
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = coil_radius * 1.2
	capsule.height = coil_height + head_radius * 2.0
	shape.shape = capsule
	shape.position.y = (coil_height + head_radius * 2.0) * 0.5
	add_child(shape)


## --- Mesh building ---

func _build_mesh() -> void:
	if _mesh_root and is_instance_valid(_mesh_root):
		_mesh_root.free()
	_coil_meshes.clear()

	_mesh_root = Node3D.new()
	_mesh_root.name = "MeshRoot"
	add_child(_mesh_root)

	# Base platform disc
	_base_mesh = MeshInstance3D.new()
	_base_mesh.name = "Base"
	var base_cyl: CylinderMesh = CylinderMesh.new()
	base_cyl.top_radius = coil_radius * 1.3
	base_cyl.bottom_radius = coil_radius * 1.4
	base_cyl.height = 0.06
	_base_mesh.mesh = base_cyl
	_base_mesh.material_override = _base_material
	_base_mesh.position.y = 0.03
	_mesh_root.add_child(_base_mesh)

	# Coil root — this gets Y-scaled for compression
	_coil_root = Node3D.new()
	_coil_root.name = "CoilRoot"
	_coil_root.position.y = 0.06  # sits on base
	_mesh_root.add_child(_coil_root)

	# Build torus rings for the coil
	var ring_spacing: float = (coil_height - 0.06) / float(coil_turns)
	for i in range(coil_turns):
		var ring: MeshInstance3D = MeshInstance3D.new()
		ring.name = "CoilRing_%d" % i
		var torus: TorusMesh = TorusMesh.new()
		torus.inner_radius = coil_radius * _wire_ratio
		torus.outer_radius = coil_radius
		torus.rings = 16
		torus.ring_segments = 8
		ring.mesh = torus
		ring.material_override = _coil_material
		ring.position.y = ring_spacing * (i + 0.5)
		ring.rotation.y = deg_to_rad(30.0 * i)  # Slight helical rotation offset
		_coil_root.add_child(ring)
		_coil_meshes.append(ring)

	# Head sphere on top of coil
	_head_mesh = MeshInstance3D.new()
	_head_mesh.name = "Head"
	var head_sphere: SphereMesh = SphereMesh.new()
	head_sphere.radius = head_radius
	head_sphere.height = head_radius * 2.0
	_head_mesh.mesh = head_sphere
	_head_mesh.material_override = _head_material
	_head_mesh.position.y = coil_height + head_radius * 0.5
	_mesh_root.add_child(_head_mesh)

	# Eyes
	_eye_left = _create_eye(-1.0)
	_head_mesh.add_child(_eye_left)
	_eye_right = _create_eye(1.0)
	_head_mesh.add_child(_eye_right)


func _create_eye(side: float) -> MeshInstance3D:
	var eye: MeshInstance3D = MeshInstance3D.new()
	eye.name = "Eye_Left" if side < 0.0 else "Eye_Right"
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = head_radius * 0.22
	sphere.height = head_radius * 0.44
	eye.mesh = sphere
	eye.material_override = _eye_material
	# Position eyes on front face of head
	eye.position = Vector3(
		side * head_radius * 0.45,
		head_radius * 0.15,
		-head_radius * 0.8
	)
	return eye


## --- Mesh update ---

func _update_mesh(_delta: float) -> void:
	if not is_instance_valid(_mesh_root):
		return

	# Coil compression: scale Y of the coil root. The floor is the spring's SOLID LENGTH —
	# turns touching, nothing left to give. It is a temper property, not a magic number.
	var coil_scale_y: float = lerp(1.0, _coil_floor, clamp(_compression, -0.3, 1.0))
	_coil_root.scale.y = coil_scale_y

	# Head follows top of coil
	var effective_coil_top: float = 0.06 + (coil_height - 0.06) * coil_scale_y
	_head_mesh.position.y = effective_coil_top + head_radius * 0.5

	# Squash/stretch the head for juiciness
	if _compression > 0.5:
		# Squashed: wider and shorter
		var squash: float = lerp(1.0, 1.4, (_compression - 0.5) * 2.0)
		_head_mesh.scale = Vector3(squash, 1.0 / squash, squash)
	elif _compression < -0.1:
		# Stretched: taller and thinner
		var stretch: float = lerp(1.0, 1.3, abs(_compression) * 3.0)
		_head_mesh.scale = Vector3(1.0 / stretch, stretch, 1.0 / stretch)
	else:
		_head_mesh.scale = Vector3.ONE

	# Eyes face player during PATROL/WIND
	if _state in [State.PATROL, State.WIND, State.LAND] and is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - _head_mesh.global_position
		to_player.y = 0.0
		if to_player.length_squared() > 0.01:
			var local_dir: Vector3 = _head_mesh.global_transform.basis.inverse() * to_player.normalized()
			var eye_shift: float = clamp(local_dir.x, -1.0, 1.0) * head_radius * 0.1
			var eye_forward: float = clamp(-local_dir.z, 0.0, 1.0) * head_radius * 0.05
			if is_instance_valid(_eye_left):
				_eye_left.position.z = -head_radius * 0.8 - eye_forward
				_eye_left.position.x = -head_radius * 0.45 + eye_shift
			if is_instance_valid(_eye_right):
				_eye_right.position.z = -head_radius * 0.8 - eye_forward
				_eye_right.position.x = head_radius * 0.45 + eye_shift

	# Emission pulse during WIND (charging)
	if _state == State.WIND:
		var charge: float = clamp(_state_time / 0.5, 0.0, 1.0)
		_coil_material.emission_energy_multiplier = lerp(0.2, 1.5, charge)
	elif _state == State.BOUNCE:
		_coil_material.emission_energy_multiplier = lerp(1.5, 0.2, clamp(_state_time / 0.5, 0.0, 1.0))
	else:
		_coil_material.emission_energy_multiplier = 0.2


## --- Combat ---

func _try_damage_player() -> void:
	if not is_instance_valid(_player_node):
		return
	var dist: float = global_position.distance_to(_player_node.global_position)
	if dist > coil_radius * 3.0:
		return
	for method in ["take_damage", "apply_damage", "damage"]:
		if _player_node.has_method(method):
			_player_node.call(method, contact_damage)
			return


func take_damage(amount: float) -> void:
	_apply_damage(amount)

func apply_damage(amount: float) -> void:
	_apply_damage(amount)

func damage(amount: float) -> void:
	_apply_damage(amount)

func _apply_damage(amount: float) -> void:
	if _state == State.DEAD:
		return

	_health -= max(0.0, amount)

	if _health <= 0.0:
		_set_state(State.DEAD)
		enemy_destroyed.emit(self)
	else:
		# Flash on hit
		var tween: Tween = create_tween()
		tween.tween_property(_coil_material, "emission_energy_multiplier", 3.0, 0.05)
		tween.tween_property(_coil_material, "emission_energy_multiplier", 0.2, 0.15)


## --- Utility ---

func _find_player() -> void:
	var scene: Node = get_tree().current_scene
	if not scene:
		_player_node = null
		return

	for candidate in [
		get_tree().get_first_node_in_group("player"),
		scene.find_child("XROrigin3D", true, false),
		scene.find_child("Player", true, false),
	]:
		if candidate is Node3D:
			_player_node = candidate
			return


func _get_player_distance() -> float:
	if not is_instance_valid(_player_node):
		return INF
	return global_position.distance_to(_player_node.global_position)


func _face_player(speed: float) -> void:
	if not is_instance_valid(_player_node):
		return
	var to_player: Vector3 = _player_node.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.001:
		return
	var target_yaw: float = atan2(to_player.x, to_player.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, speed)


func configure(config: Dictionary) -> void:
	if config.has("coil_radius"):
		coil_radius = float(config["coil_radius"])
	if config.has("coil_height"):
		coil_height = float(config["coil_height"])
	if config.has("coil_turns"):
		coil_turns = int(config["coil_turns"])
	if config.has("health"):
		max_health = float(config["health"])
		_health = max_health
	if config.has("speed"):
		patrol_speed = float(config["speed"])
	if config.has("bounce_height"):
		bounce_height = float(config["bounce_height"])
	if config.has("launch_force"):
		launch_force = float(config["launch_force"])
	if config.has("damage"):
		contact_damage = float(config["damage"])

	_build_mesh()


func apply_grid_config(config_data: Dictionary) -> void:
	configure(config_data)
