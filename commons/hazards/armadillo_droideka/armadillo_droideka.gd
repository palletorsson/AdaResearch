extends CharacterBody3D
class_name ArmadilloDroideka

signal fired_projectile(position: Vector3, direction: Vector3)
signal enemy_destroyed(enemy: Node3D)

enum State {
	ROLL,
	DETECT,
	DEPLOY,
	AIM,
	FIRE,
	RETRACT,
	DEAD
}

const FIRE_BOLT_SCENE: PackedScene = preload("res://commons/hazards/armadillo_droideka/fire_bolt.tscn")

@export_group("Combat")
@export var max_health: float = 80.0
@export var roll_speed: float = 2.8
@export var strafe_speed: float = 1.7
@export var turn_speed: float = 6.0
@export var detection_radius: float = 10.0
@export var disengage_radius: float = 16.0
@export var can_deploy_fire: bool = true
@export var shots_per_burst: int = 3
@export var fire_interval: float = 0.35
@export var fire_speed: float = 14.0
@export var fire_damage: float = 14.0
@export var biped_distance_threshold: float = 6.0
@export var contact_damage: float = 10.0
@export var contact_damage_cooldown: float = 0.65

@export_group("State Timing")
@export var detect_hold_time: float = 0.35
@export var deploy_duration: float = 0.75
@export var aim_duration: float = 0.45
@export var retract_duration: float = 0.65
@export var dead_cleanup_time: float = 4.0

@export_group("Folding Geometry")
@export var scute_count: int = 12
@export var shell_radius: float = 0.62
@export var shell_height: float = 1.02
@export var shell_thickness: float = 0.075
@export var scute_open_degrees: float = 70.0
@export var scute_wave_degrees: float = 7.0
@export var ring_open_degrees: float = 52.0
@export var core_raise_height: float = 0.52
@export var leg_upper_length: float = 0.45
@export var leg_lower_length: float = 0.38
@export var leg_folded_hip_degrees: float = -116.0
@export var leg_deployed_hip_degrees: float = 34.0
@export var leg_folded_knee_degrees: float = 132.0
@export var leg_deployed_knee_degrees: float = -26.0

var _health: float = 0.0
var _state: int = State.ROLL
var _state_time: float = 0.0
var _fold_amount: float = 0.0
var _shot_timer: float = 0.0
var _shots_fired: int = 0
var _roll_spin: float = 0.0
var _is_biped_stance: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _contact_damage_timer: float = 0.0

var _player_node: Node3D = null

var _shell_root: Node3D = null
var _equator_upper: Node3D = null
var _equator_lower: Node3D = null
var _core_root: Node3D = null
var _muzzle: Marker3D = null

var _scute_hinges: Array[Node3D] = []
var _leg_hips: Array[Node3D] = []
var _leg_knees: Array[Node3D] = []

func _ready() -> void:
	_rng.randomize()
	_health = max_health
	_build_collision_and_hurtbox()
	_build_visual_rig()
	_apply_fold_pose(0.0)
	_find_player()
	add_to_group("enemy")

func _physics_process(delta: float) -> void:
	_state_time += delta
	_contact_damage_timer = max(0.0, _contact_damage_timer - delta)

	if not is_instance_valid(_player_node):
		_find_player()

	match _state:
		State.ROLL:
			_process_roll_state(delta)
		State.DETECT:
			_process_detect_state(delta)
		State.DEPLOY:
			_process_deploy_state(delta)
		State.AIM:
			_process_aim_state(delta)
		State.FIRE:
			_process_fire_state(delta)
		State.RETRACT:
			_process_retract_state(delta)
		State.DEAD:
			_process_dead_state(delta)

	_apply_fold_pose(_fold_amount)

	if _state != State.DEAD:
		move_and_slide()
		_handle_contact_damage()

func _process_roll_state(delta: float) -> void:
	_fold_amount = move_toward(_fold_amount, 0.0, delta / max(retract_duration, 0.01))

	var move_dir: Vector3 = Vector3.ZERO
	var distance_to_player: float = INF
	if is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - global_position
		to_player.y = 0.0
		distance_to_player = to_player.length()
		if distance_to_player > 0.001:
			move_dir = to_player / distance_to_player
			_face_direction(move_dir, delta, turn_speed)

	velocity.x = move_dir.x * roll_speed
	velocity.z = move_dir.z * roll_speed
	velocity.y = 0.0

	var planar_speed: float = Vector2(velocity.x, velocity.z).length()
	_roll_spin += planar_speed * delta / max(shell_radius, 0.1)
	if _shell_root:
		_shell_root.rotation.x = _roll_spin

	if can_deploy_fire and distance_to_player <= detection_radius:
		_is_biped_stance = distance_to_player <= biped_distance_threshold
		_set_state(State.DETECT)

func _process_detect_state(delta: float) -> void:
	if not can_deploy_fire:
		_set_state(State.ROLL)
		return

	velocity.x = move_toward(velocity.x, 0.0, delta * 8.0)
	velocity.z = move_toward(velocity.z, 0.0, delta * 8.0)
	velocity.y = 0.0
	_fold_amount = move_toward(_fold_amount, 0.2, delta * 2.0)
	_aim_core_at_player(delta)
	if _state_time >= detect_hold_time:
		_set_state(State.DEPLOY)

func _process_deploy_state(_delta: float) -> void:
	if not can_deploy_fire:
		_set_state(State.ROLL)
		return

	velocity = Vector3.ZERO
	var t: float = clamp(_state_time / max(deploy_duration, 0.01), 0.0, 1.0)
	_fold_amount = t
	_aim_core_at_player(1.0)
	if t >= 1.0:
		_set_state(State.AIM)

func _process_aim_state(delta: float) -> void:
	if not can_deploy_fire:
		_set_state(State.ROLL)
		return

	velocity.x = move_toward(velocity.x, 0.0, delta * 8.0)
	velocity.z = move_toward(velocity.z, 0.0, delta * 8.0)
	velocity.y = 0.0
	_fold_amount = 1.0
	_aim_core_at_player(delta)
	if _state_time >= aim_duration:
		_shots_fired = 0
		_shot_timer = 0.0
		_set_state(State.FIRE)

func _process_fire_state(delta: float) -> void:
	if not can_deploy_fire:
		_set_state(State.ROLL)
		return

	_fold_amount = 1.0
	_aim_core_at_player(delta)
	_update_fire_movement(delta)

	_shot_timer -= delta
	if _shot_timer <= 0.0 and _shots_fired < max(1, shots_per_burst):
		var fire_dir: Vector3 = _get_fire_direction()
		_spawn_fire_bolt(fire_dir)
		_shots_fired += 1
		_shot_timer = max(0.05, fire_interval)
		fired_projectile.emit(_muzzle.global_position if _muzzle else global_position, fire_dir)

	if _shots_fired >= max(1, shots_per_burst) and _shot_timer <= 0.0:
		_set_state(State.RETRACT)

func _process_retract_state(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 0.25)
	velocity.z = move_toward(velocity.z, 0.0, 0.25)
	velocity.y = 0.0
	var t: float = clamp(_state_time / max(retract_duration, 0.01), 0.0, 1.0)
	_fold_amount = 1.0 - t
	if t >= 1.0:
		var distance_to_player: float = _get_distance_to_player()
		if distance_to_player <= disengage_radius:
			_is_biped_stance = distance_to_player <= biped_distance_threshold
		_set_state(State.ROLL)

func _process_dead_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, delta * 6.0)
	velocity.z = move_toward(velocity.z, 0.0, delta * 6.0)
	velocity.y = 0.0
	_fold_amount = move_toward(_fold_amount, 0.3, delta)
	if _state_time >= dead_cleanup_time:
		queue_free()

func _update_fire_movement(delta: float) -> void:
	if not _is_biped_stance or not is_instance_valid(_player_node):
		velocity.x = move_toward(velocity.x, 0.0, delta * 8.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 8.0)
		velocity.y = 0.0
		return

	var to_player: Vector3 = _player_node.global_position - global_position
	to_player.y = 0.0
	var distance_to_player: float = to_player.length()
	if distance_to_player <= 0.001:
		velocity = Vector3.ZERO
		return

	var toward: Vector3 = to_player / distance_to_player
	var side: Vector3 = Vector3(-toward.z, 0.0, toward.x)
	var sway: float = sin(_state_time * 4.5) * 0.7 + (_rng.randf() - 0.5) * 0.2
	var strafe: Vector3 = side * sway * strafe_speed
	velocity.x = strafe.x
	velocity.z = strafe.z
	velocity.y = 0.0
	_face_direction(toward, delta, turn_speed * 1.3)

func _handle_contact_damage() -> void:
	if _contact_damage_timer > 0.0:
		return
	if contact_damage <= 0.0:
		return

	var collisions: int = get_slide_collision_count()
	for i in range(collisions):
		var collision: KinematicCollision3D = get_slide_collision(i)
		if collision == null:
			continue
		var collider: Object = collision.get_collider()
		if _try_apply_contact_damage(collider):
			_contact_damage_timer = max(0.05, contact_damage_cooldown)
			break

func _try_apply_contact_damage(target: Object) -> bool:
	if target == null:
		return false

	if target.has_method("take_damage"):
		target.take_damage(contact_damage)
		return true
	if target.has_method("apply_damage"):
		target.apply_damage(contact_damage)
		return true
	if target.has_method("apply_health_damage"):
		target.apply_health_damage(contact_damage)
		return true
	if target.has_method("damage_player"):
		target.damage_player(contact_damage)
		return true

	if target is Node:
		var node: Node = target as Node
		var lower_name: String = node.name.to_lower()
		if node.is_in_group("player") or lower_name.contains("player") or lower_name.contains("xrorigin"):
			return true

	return false

func _spawn_fire_bolt(direction: Vector3) -> void:
	if FIRE_BOLT_SCENE == null:
		return

	var bolt_node: Node = FIRE_BOLT_SCENE.instantiate()
	if not bolt_node:
		return

	var spawn_origin: Vector3 = global_position + Vector3(0.0, core_raise_height + 0.15, -0.4)
	if _muzzle:
		spawn_origin = _muzzle.global_position

	var current_scene: Node = get_tree().current_scene
	if current_scene:
		current_scene.add_child(bolt_node)
	else:
		add_child(bolt_node)

	if bolt_node.has_method("launch"):
		bolt_node.launch(spawn_origin, direction, fire_speed, fire_damage)
	elif bolt_node is Node3D:
		var bolt_3d: Node3D = bolt_node as Node3D
		bolt_3d.global_position = spawn_origin

func _get_fire_direction() -> Vector3:
	if _muzzle:
		var muzzle_dir: Vector3 = -_muzzle.global_transform.basis.z
		if muzzle_dir.length_squared() > 0.0001:
			return muzzle_dir.normalized()

	if is_instance_valid(_player_node):
		var to_player: Vector3 = _get_player_aim_point() - global_position
		if to_player.length_squared() > 0.0001:
			return to_player.normalized()

	return -global_transform.basis.z.normalized()

func _aim_core_at_player(blend: float) -> void:
	if not _core_root or not is_instance_valid(_player_node):
		return

	var target: Vector3 = _get_player_aim_point()
	var origin: Vector3 = _core_root.global_position
	var direction: Vector3 = target - origin
	if direction.length_squared() < 0.0001:
		return

	var up: Vector3 = Vector3.UP
	var unit_dir: Vector3 = direction.normalized()
	if abs(unit_dir.dot(up)) > 0.98:
		up = Vector3.FORWARD

	var desired_yaw: float = atan2(unit_dir.x, unit_dir.z)
	_core_root.rotation.y = lerp_angle(_core_root.rotation.y, desired_yaw, clamp(blend * 0.2, 0.0, 1.0))

func _set_state(new_state: int) -> void:
	if _state == new_state:
		return
	_state = new_state
	_state_time = 0.0

func _face_direction(direction: Vector3, delta: float, speed: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	var target_yaw: float = atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clamp(speed * delta, 0.0, 1.0))

func _apply_fold_pose(fold: float) -> void:
	var clamped_fold: float = clamp(fold, 0.0, 1.0)

	var scute_total: int = _scute_hinges.size()
	for i in range(scute_total):
		var hinge: Node3D = _scute_hinges[i]
		var phase: float = TAU * float(i) / float(max(scute_total, 1))
		var fan_offset: float = sin(phase) * scute_wave_degrees
		hinge.rotation_degrees.z = (scute_open_degrees + fan_offset) * clamped_fold

	if _equator_upper:
		_equator_upper.rotation_degrees.x = -ring_open_degrees * clamped_fold
		_equator_upper.position.y = 0.08 * clamped_fold
	if _equator_lower:
		_equator_lower.rotation_degrees.x = ring_open_degrees * clamped_fold
		_equator_lower.position.y = -0.08 * clamped_fold

	if _core_root:
		_core_root.position.y = core_raise_height * clamped_fold

	var leg_count: int = min(_leg_hips.size(), _leg_knees.size())
	for i in range(leg_count):
		var leg_fold: float = clamped_fold
		if _is_biped_stance and (_state == State.AIM or _state == State.FIRE) and i == 2:
			leg_fold = clamped_fold * 0.25

		_leg_hips[i].rotation_degrees.x = lerp(leg_folded_hip_degrees, leg_deployed_hip_degrees, leg_fold)
		_leg_knees[i].rotation_degrees.x = lerp(leg_folded_knee_degrees, leg_deployed_knee_degrees, leg_fold)

func _build_collision_and_hurtbox() -> void:
	var body_collision: CollisionShape3D = CollisionShape3D.new()
	body_collision.name = "CollisionShape3D"
	var body_shape: CapsuleShape3D = CapsuleShape3D.new()
	body_shape.radius = max(0.2, shell_radius * 0.55)
	body_shape.height = max(0.4, shell_height * 0.75)
	body_collision.shape = body_shape
	add_child(body_collision)

	var hurtbox: Area3D = Area3D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.monitoring = true
	hurtbox.monitorable = true
	hurtbox.collision_layer = 0
	hurtbox.collision_mask = 0
	add_child(hurtbox)

	var hurt_collision: CollisionShape3D = CollisionShape3D.new()
	var hurt_shape: SphereShape3D = SphereShape3D.new()
	hurt_shape.radius = max(0.2, shell_radius * 0.95)
	hurt_collision.shape = hurt_shape
	hurtbox.add_child(hurt_collision)

func _build_visual_rig() -> void:
	var shell_material: StandardMaterial3D = _make_material(Color(0.47, 0.50, 0.56, 1.0), Color(0.08, 0.10, 0.12, 1.0), 0.65, 0.35)
	var ring_material: StandardMaterial3D = _make_material(Color(0.23, 0.26, 0.31, 1.0), Color(0.95, 0.65, 0.20, 1.0), 0.8, 0.25)
	var core_material: StandardMaterial3D = _make_material(Color(0.22, 0.24, 0.30, 1.0), Color(1.0, 0.33, 0.08, 1.0), 0.3, 0.55)

	_shell_root = Node3D.new()
	_shell_root.name = "ShellRoot"
	add_child(_shell_root)

	_create_scutes(shell_material)
	_create_equator_rings(ring_material)
	_create_leg_modules(ring_material)
	_create_core(core_material, ring_material)

func _create_scutes(material: Material) -> void:
	var count: int = max(6, scute_count)
	var scute_mesh: BoxMesh = BoxMesh.new()
	scute_mesh.size = Vector3(shell_thickness, shell_height, shell_radius * 0.42)

	for i in range(count):
		var orbit: Node3D = Node3D.new()
		orbit.name = "ScuteOrbit_%d" % i
		orbit.rotation.y = TAU * float(i) / float(count)
		_shell_root.add_child(orbit)

		var hinge: Node3D = Node3D.new()
		hinge.name = "ScuteHinge_%d" % i
		orbit.add_child(hinge)

		var panel: MeshInstance3D = MeshInstance3D.new()
		panel.name = "ScutePanel"
		panel.mesh = scute_mesh
		panel.material_override = material
		panel.position = Vector3(shell_radius, 0.0, 0.0)
		hinge.add_child(panel)

		_scute_hinges.append(hinge)

func _create_equator_rings(material: Material) -> void:
	_equator_upper = Node3D.new()
	_equator_upper.name = "EquatorUpper"
	_shell_root.add_child(_equator_upper)

	_equator_lower = Node3D.new()
	_equator_lower.name = "EquatorLower"
	_shell_root.add_child(_equator_lower)

	var ring_top: MeshInstance3D = _create_torus_ring(shell_radius * 0.98, shell_thickness * 0.48, material)
	var ring_bottom: MeshInstance3D = _create_torus_ring(shell_radius * 0.98, shell_thickness * 0.48, material)
	_equator_upper.add_child(ring_top)
	_equator_lower.add_child(ring_bottom)

func _create_leg_modules(material: Material) -> void:
	var upper_mesh: CylinderMesh = CylinderMesh.new()
	upper_mesh.top_radius = 0.05
	upper_mesh.bottom_radius = 0.055
	upper_mesh.height = leg_upper_length

	var lower_mesh: CylinderMesh = CylinderMesh.new()
	lower_mesh.top_radius = 0.045
	lower_mesh.bottom_radius = 0.05
	lower_mesh.height = leg_lower_length

	for i in range(3):
		var leg_orbit: Node3D = Node3D.new()
		leg_orbit.name = "LegOrbit_%d" % i
		leg_orbit.rotation.y = TAU * float(i) / 3.0
		_shell_root.add_child(leg_orbit)

		var hip: Node3D = Node3D.new()
		hip.name = "LegHip_%d" % i
		hip.position = Vector3(shell_radius * 0.45, -0.1, 0.0)
		leg_orbit.add_child(hip)

		var upper_segment: MeshInstance3D = MeshInstance3D.new()
		upper_segment.name = "UpperSegment"
		upper_segment.mesh = upper_mesh
		upper_segment.material_override = material
		upper_segment.position = Vector3(0.0, -leg_upper_length * 0.5, 0.0)
		hip.add_child(upper_segment)

		var knee: Node3D = Node3D.new()
		knee.name = "LegKnee_%d" % i
		knee.position = Vector3(0.0, -leg_upper_length, 0.0)
		hip.add_child(knee)

		var lower_segment: MeshInstance3D = MeshInstance3D.new()
		lower_segment.name = "LowerSegment"
		lower_segment.mesh = lower_mesh
		lower_segment.material_override = material
		lower_segment.position = Vector3(0.0, -leg_lower_length * 0.5, 0.0)
		knee.add_child(lower_segment)

		_leg_hips.append(hip)
		_leg_knees.append(knee)

func _create_core(core_material: Material, ring_material: Material) -> void:
	_core_root = Node3D.new()
	_core_root.name = "CoreRoot"
	_shell_root.add_child(_core_root)

	var core_ball: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	core_ball.mesh = sphere
	core_ball.material_override = core_material
	_core_root.add_child(core_ball)

	for i in range(3):
		var ring_node: Node3D = Node3D.new()
		ring_node.name = "CoreRing_%d" % i
		match i:
			0:
				ring_node.rotation_degrees = Vector3(90.0, 0.0, 0.0)
			1:
				ring_node.rotation_degrees = Vector3(0.0, 0.0, 0.0)
			2:
				ring_node.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		_core_root.add_child(ring_node)

		var ring_mesh: MeshInstance3D = _create_torus_ring(0.28, 0.022, ring_material)
		ring_node.add_child(ring_mesh)

	_muzzle = Marker3D.new()
	_muzzle.name = "Muzzle"
	_muzzle.position = Vector3(0.0, 0.02, -0.48)
	_core_root.add_child(_muzzle)

	var muzzle_light: OmniLight3D = OmniLight3D.new()
	muzzle_light.name = "MuzzleLight"
	muzzle_light.light_color = Color(1.0, 0.48, 0.1, 1.0)
	muzzle_light.light_energy = 1.6
	muzzle_light.omni_range = 3.8
	_muzzle.add_child(muzzle_light)

func _create_torus_ring(radius: float, thickness: float, material: Material) -> MeshInstance3D:
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = max(0.01, radius - thickness)
	torus.outer_radius = radius + thickness
	torus.rings = 28
	torus.ring_segments = 14

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = torus
	mesh_instance.material_override = material
	return mesh_instance

func _make_material(albedo: Color, emission: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = albedo
	material.metallic = metallic
	material.roughness = roughness
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy = 0.55
	return material

func _find_player() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		_player_node = null
		return

	var potential_nodes: Array = [
		get_tree().get_first_node_in_group("player"),
		scene_root.find_child("XROrigin3D", true, false),
		scene_root.find_child("Player", true, false),
		scene_root.find_child("PlayerBody", true, false)
	]

	_player_node = null
	for candidate in potential_nodes:
		if candidate is Node3D:
			_player_node = candidate as Node3D
			break

func _get_player_aim_point() -> Vector3:
	if not is_instance_valid(_player_node):
		return global_position + Vector3(0.0, 1.0, -2.0)
	var aim_point: Vector3 = _player_node.global_position
	aim_point.y += 1.2
	return aim_point

func _get_distance_to_player() -> float:
	if not is_instance_valid(_player_node):
		return INF
	return global_position.distance_to(_player_node.global_position)

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
		_die()
	else:
		_play_hit_feedback()

func _play_hit_feedback() -> void:
	if not _core_root:
		return
	var tween: Tween = create_tween()
	tween.tween_property(_core_root, "scale", Vector3(1.08, 1.08, 1.08), 0.07)
	tween.tween_property(_core_root, "scale", Vector3.ONE, 0.11)

func _die() -> void:
	if _state == State.DEAD:
		return
	_set_state(State.DEAD)
	velocity = Vector3.ZERO
	enemy_destroyed.emit(self)

func apply_grid_config(config_data: Dictionary) -> void:
	configure(config_data)

func configure(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return

	if config_data.has("roll_speed"):
		roll_speed = _to_float(config_data["roll_speed"], roll_speed)
	if config_data.has("health"):
		max_health = _to_float(config_data["health"], max_health)
		_health = max_health
	if config_data.has("contact"):
		contact_damage = _to_float(config_data["contact"], contact_damage)
	if config_data.has("contact_damage"):
		contact_damage = _to_float(config_data["contact_damage"], contact_damage)
	if config_data.has("contact_cd"):
		contact_damage_cooldown = _to_float(config_data["contact_cd"], contact_damage_cooldown)
	if config_data.has("detect"):
		detection_radius = _to_float(config_data["detect"], detection_radius)
	if config_data.has("detection"):
		detection_radius = _to_float(config_data["detection"], detection_radius)
	if config_data.has("fire"):
		can_deploy_fire = _to_bool(config_data["fire"], can_deploy_fire)
	if config_data.has("burst"):
		shots_per_burst = int(_to_float(config_data["burst"], float(shots_per_burst)))
	if config_data.has("fire_interval"):
		fire_interval = _to_float(config_data["fire_interval"], fire_interval)
	if config_data.has("fire_speed"):
		fire_speed = _to_float(config_data["fire_speed"], fire_speed)
	if config_data.has("fire_damage"):
		fire_damage = _to_float(config_data["fire_damage"], fire_damage)

func _to_float(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		return float(value)
	var text: String = str(value).strip_edges()
	if text.is_valid_float():
		return float(text)
	return fallback

func _to_bool(value: Variant, fallback: bool) -> bool:
	if value is bool:
		return value
	var text: String = str(value).strip_edges().to_lower()
	if text in ["1", "true", "yes", "on"]:
		return true
	if text in ["0", "false", "no", "off"]:
		return false
	return fallback
