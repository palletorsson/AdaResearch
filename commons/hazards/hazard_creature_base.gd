extends CharacterBody3D
class_name HazardCreatureBase
## Shared base class for all mobile hazard creatures.
## Provides state machine, player detection, damage interface,
## patrol/chase AI, and virtual stubs for geometry and behavior.
## Each creature extends this and overrides _build_mesh() and state processors.

signal enemy_destroyed(enemy: Node3D)

enum BaseState { IDLE, PATROL, DETECT, CHASE, ATTACK, STUNNED, DEAD }

# ── Exports ──────────────────────────────────────────────────────────────

@export_group("Combat")
@export var max_health: float = 60.0
@export var patrol_speed: float = 1.8
@export var chase_speed: float = 3.2
@export var detection_radius: float = 7.0
@export var disengage_radius: float = 12.0
@export var contact_damage: float = 15.0
@export var contact_cooldown: float = 0.8

@export_group("Patrol")
@export var patrol_width: float = 3.0
@export var patrol_depth: float = 2.0

# ── State ────────────────────────────────────────────────────────────────

var _health: float = 0.0
var _state: BaseState = BaseState.PATROL
var _state_time: float = 0.0
var _contact_timer: float = 0.0
var _player_node: Node3D = null
var _patrol_origin: Vector3 = Vector3.ZERO
var _patrol_index: int = 0
var _patrol_corners: Array[Vector3] = []

# Visual root — subclasses attach mesh children here
var _mesh_root: Node3D = null


func _ready() -> void:
	_health = max_health
	_patrol_origin = global_position
	_build_patrol_corners()

	_mesh_root = Node3D.new()
	_mesh_root.name = "MeshRoot"
	add_child(_mesh_root)

	_create_materials()
	_build_collision()
	_build_mesh()
	_find_player()
	add_to_group("enemy")
	_on_ready()


func _physics_process(delta: float) -> void:
	_state_time += delta
	_contact_timer = max(0.0, _contact_timer - delta)

	if not is_instance_valid(_player_node):
		_find_player()

	match _state:
		BaseState.IDLE:
			_process_idle(delta)
		BaseState.PATROL:
			_process_patrol(delta)
		BaseState.DETECT:
			_process_detect(delta)
		BaseState.CHASE:
			_process_chase(delta)
		BaseState.ATTACK:
			_process_attack(delta)
		BaseState.STUNNED:
			_process_stunned(delta)
		BaseState.DEAD:
			_process_dead(delta)

	_process_visual(delta)

	if _state != BaseState.DEAD:
		move_and_slide()
		_handle_contact_damage()


# ── Virtual stubs — override in subclasses ───────────────────────────────

## Called at end of _ready() for subclass-specific setup.
func _on_ready() -> void:
	pass

## Create materials for the creature's visual appearance.
func _create_materials() -> void:
	pass

## Build the collision shape. Default: 0.4m sphere.
func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.4
	col.shape = shape
	add_child(col)

## Build the creature's procedural mesh geometry on _mesh_root.
func _build_mesh() -> void:
	pass

## Per-frame visual update (animations, mesh rebuilds, etc).
func _process_visual(_delta: float) -> void:
	pass


# ── State Processing (override these for custom behavior) ───────────────

func _process_idle(_delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, 0.15)
	if _get_player_distance() <= detection_radius:
		_set_state(BaseState.DETECT)


func _process_patrol(delta: float) -> void:
	if _patrol_corners.is_empty():
		return

	var target: Vector3 = _patrol_corners[_patrol_index]
	var to_target: Vector3 = target - global_position
	to_target.y = 0.0
	var dist: float = to_target.length()

	if dist < 0.3:
		_patrol_index = (_patrol_index + 1) % _patrol_corners.size()
		target = _patrol_corners[_patrol_index]
		to_target = target - global_position
		to_target.y = 0.0

	if to_target.length() > 0.01:
		var move_dir: Vector3 = to_target.normalized()
		velocity.x = move_dir.x * patrol_speed
		velocity.z = move_dir.z * patrol_speed
		_face_direction(move_dir, delta * 3.0)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	velocity.y = 0.0

	if _get_player_distance() <= detection_radius:
		_set_state(BaseState.DETECT)


func _process_detect(_delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, 0.2)
	if _state_time >= 0.4:
		_set_state(BaseState.CHASE)


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
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	velocity.y = 0.0


func _process_attack(_delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, 0.15)


func _process_stunned(_delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, 0.15)
	if _state_time >= 1.5:
		_set_state(BaseState.PATROL)


func _process_dead(_delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, 0.1)
	if _state_time >= 3.0:
		queue_free()


# ── State Management ────────────────────────────────────────────────────

func _set_state(new_state: BaseState) -> void:
	if _state == new_state:
		return
	_state = new_state
	_state_time = 0.0
	_on_state_changed(new_state)

## Called when state changes — override for transition effects.
func _on_state_changed(_new_state: BaseState) -> void:
	pass


# ── Player Detection ────────────────────────────────────────────────────

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
	_player_node = null


func _get_player_distance() -> float:
	if not is_instance_valid(_player_node):
		return INF
	return global_position.distance_to(_player_node.global_position)


func _get_player_direction() -> Vector3:
	if not is_instance_valid(_player_node):
		return Vector3.FORWARD
	var dir: Vector3 = _player_node.global_position - global_position
	dir.y = 0.0
	return dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD


# ── Damage Interface ────────────────────────────────────────────────────

func take_damage(amount: float) -> void:
	_apply_damage(amount)

func apply_damage(amount: float) -> void:
	_apply_damage(amount)

func damage(amount: float) -> void:
	_apply_damage(amount)

func _apply_damage(amount: float) -> void:
	if _state == BaseState.DEAD:
		return
	_health -= max(0.0, amount)
	if _health <= 0.0:
		_set_state(BaseState.DEAD)
		enemy_destroyed.emit(self)
	else:
		_on_damaged(amount)

## Called when damaged but not dead — override for custom reactions.
func _on_damaged(_amount: float) -> void:
	_set_state(BaseState.STUNNED)


# ── Contact Damage ──────────────────────────────────────────────────────

func _handle_contact_damage() -> void:
	if _contact_timer > 0.0 or contact_damage <= 0.0:
		return
	for i in range(get_slide_collision_count()):
		var collision: KinematicCollision3D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if _try_damage_target(collider):
			_contact_timer = contact_cooldown
			break

func _try_damage_target(target: Object) -> bool:
	if target == null:
		return false
	if target.has_method("apply_health_damage"):
		target.apply_health_damage(contact_damage)
		return true
	if target is Node and target.is_in_group("player"):
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("apply_health_damage"):
			gm.apply_health_damage(contact_damage)
			return true
	return false


# ── Patrol ──────────────────────────────────────────────────────────────

func _build_patrol_corners() -> void:
	var hw: float = patrol_width * 0.5
	var hd: float = patrol_depth * 0.5
	_patrol_corners = [
		_patrol_origin + Vector3(-hw, 0, -hd),
		_patrol_origin + Vector3(hw, 0, -hd),
		_patrol_origin + Vector3(hw, 0, hd),
		_patrol_origin + Vector3(-hw, 0, hd),
	]


# ── Facing ──────────────────────────────────────────────────────────────

func _face_direction(dir: Vector3, weight: float = 0.1) -> void:
	if dir.length_squared() < 0.001:
		return
	var target_angle: float = atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, clamp(weight, 0.0, 1.0))


# ── Configuration ───────────────────────────────────────────────────────

func configure(config: Dictionary) -> void:
	if config.has("health"):
		max_health = float(config["health"])
		_health = max_health
	if config.has("speed"):
		patrol_speed = float(config["speed"])
	if config.has("chase_speed"):
		chase_speed = float(config["chase_speed"])
	if config.has("damage"):
		contact_damage = float(config["damage"])
	if config.has("detection_radius"):
		detection_radius = float(config["detection_radius"])

func apply_grid_config(config: Dictionary) -> void:
	configure(config)


# ── Helpers ─────────────────────────────────────────────────────────────

## Create a StandardMaterial3D with emission.
func _make_material(color: Color, emission: Color = Color.BLACK, alpha: float = 1.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	if emission != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = 1.5
	if alpha < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

## Add a MeshInstance3D child to _mesh_root.
func _add_mesh(mesh: Mesh, material: StandardMaterial3D = null, local_pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if material:
		mi.set_surface_override_material(0, material)
	mi.position = local_pos
	_mesh_root.add_child(mi)
	return mi
