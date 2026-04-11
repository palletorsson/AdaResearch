# @identity
# essence: Kick the shell — conservation of momentum given a body.
# desire: patrol peacefully, retract when scared, become a projectile when kicked
# critical_parameter: _spin_speed (0=stopped, increases with each kick, decays over time)
# triggers: PATROL→RETRACT→SHELL→KICKED→RICOCHET→RECOVER→DEAD
# emerges: chain reactions — a kicked shell hitting another enemy teaches collision physics
# truth: A sphere is the shape that rolls most freely. An icosahedron is the closest polygon.

extends CharacterBody3D
class_name ShellRoller
## Kickable shell creature. Patrols on legs, retracts into shell when player
## approaches, and becomes a rolling projectile when kicked. Bounces off walls,
## damages other enemies on impact — teaching conservation of momentum.

signal enemy_destroyed(enemy: Node3D)

enum State { PATROL, RETRACT, SHELL, KICKED, RICOCHET, RECOVER, DEAD }

@export_group("Geometry")
@export var shell_radius: float = 0.25
@export var leg_length: float = 0.12
@export var num_legs: int = 6

@export_group("Combat")
@export var max_health: float = 50.0
@export var patrol_speed: float = 1.2
@export var kick_speed: float = 6.0
@export var kick_damage: float = 25.0  # damage to OTHER enemies when kicked
@export var contact_damage: float = 10.0
@export var detection_radius: float = 7.0
@export var kick_decay: float = 0.5  # speed loss per second while rolling

@export_group("Appearance")
@export var shell_color: Color = Color(0.15, 0.55, 0.2)  # Green shell
@export var belly_color: Color = Color(0.9, 0.85, 0.6)  # Pale belly
@export var eye_color: Color = Color(1.0, 1.0, 1.0)
@export var emission_color: Color = Color(0.2, 0.8, 0.3)

# State
var _health: float = 0.0
var _state: State = State.PATROL
var _state_time: float = 0.0
var _spin_speed: float = 0.0
var _walk_phase: float = 0.0
var _player_node: Node3D = null
var _kick_direction: Vector3 = Vector3.FORWARD
var _retract_amount: float = 0.0  # 0=legs out, 1=fully retracted

# Patrol
var _patrol_direction: Vector3 = Vector3.FORWARD
var _patrol_timer: float = 0.0
var _patrol_turn_interval: float = 3.0

# Geometry nodes
var _mesh_root: Node3D = null
var _shell_mesh: MeshInstance3D = null
var _belly_mesh: MeshInstance3D = null
var _leg_meshes: Array[Node3D] = []
var _eye_left: Node3D = null
var _eye_right: Node3D = null

# Materials
var _shell_material: StandardMaterial3D
var _belly_material: StandardMaterial3D
var _eye_material: StandardMaterial3D
var _pupil_material: StandardMaterial3D
var _leg_material: StandardMaterial3D


func _ready() -> void:
	_health = max_health
	_patrol_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	if _patrol_direction.length_squared() < 0.01:
		_patrol_direction = Vector3.FORWARD
	_create_materials()
	_build_collision()
	_build_mesh()
	_find_player()
	add_to_group("enemy")
	add_to_group("shell_roller")
	_set_state(State.PATROL)


func _physics_process(delta: float) -> void:
	_state_time += delta

	if not is_instance_valid(_player_node):
		_find_player()

	# Gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	match _state:
		State.PATROL:
			_process_patrol(delta)
		State.RETRACT:
			_process_retract(delta)
		State.SHELL:
			_process_shell(delta)
		State.KICKED:
			_process_kicked(delta)
		State.RICOCHET:
			_process_ricochet(delta)
		State.RECOVER:
			_process_recover(delta)
		State.DEAD:
			_process_dead(delta)

	_update_mesh(delta)

	if _state != State.DEAD:
		move_and_slide()
		_check_slide_collisions()


# ── State processors ──────────────────────────────────────────────

func _process_patrol(delta: float) -> void:
	_walk_phase += delta * patrol_speed * 4.0
	_retract_amount = move_toward(_retract_amount, 0.0, delta * 3.0)
	_patrol_timer += delta

	# Random direction change
	if _patrol_timer >= _patrol_turn_interval:
		_patrol_timer = 0.0
		_patrol_turn_interval = randf_range(2.0, 5.0)
		var angle: float = randf_range(-PI * 0.5, PI * 0.5)
		_patrol_direction = _patrol_direction.rotated(Vector3.UP, angle).normalized()

	# Move
	var flat_vel: Vector3 = _patrol_direction * patrol_speed
	velocity.x = flat_vel.x
	velocity.z = flat_vel.z

	# Face movement direction
	var target_yaw: float = atan2(_patrol_direction.x, _patrol_direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, delta * 5.0)

	# Detect player → retract
	var dist: float = _get_player_distance()
	if dist < detection_radius:
		_set_state(State.RETRACT)

	# Reverse at walls (check after move_and_slide via slide collisions)


func _process_retract(delta: float) -> void:
	_retract_amount = move_toward(_retract_amount, 1.0, delta * 2.0)  # 0.5s to retract
	velocity.x = 0.0
	velocity.z = 0.0

	if _retract_amount >= 1.0:
		_set_state(State.SHELL)


func _process_shell(_delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0

	# Check for kick
	if _check_kick():
		_spin_speed = kick_speed
		_set_state(State.KICKED)
		return

	# Timeout → recover
	if _state_time >= 5.0:
		_set_state(State.RECOVER)


func _process_kicked(delta: float) -> void:
	_spin_speed = max(0.0, _spin_speed - kick_decay * delta)

	var flat_vel: Vector3 = _kick_direction * _spin_speed
	velocity.x = flat_vel.x
	velocity.z = flat_vel.z

	# Speed decayed enough → recover
	if _spin_speed < 0.5:
		_spin_speed = 0.0
		_set_state(State.RECOVER)


func _process_ricochet(_delta: float) -> void:
	# Brief flash state after wall bounce, continue rolling
	var flat_vel: Vector3 = _kick_direction * _spin_speed
	velocity.x = flat_vel.x
	velocity.z = flat_vel.z

	if _state_time >= 0.2:
		_set_state(State.KICKED)


func _process_recover(delta: float) -> void:
	_retract_amount = move_toward(_retract_amount, 0.0, delta * 1.0)  # 1s to recover
	velocity.x = 0.0
	velocity.z = 0.0

	if _retract_amount <= 0.0:
		_set_state(State.PATROL)


func _process_dead(_delta: float) -> void:
	velocity = Vector3.ZERO

	if _state_time >= 3.0:
		# Reset for dev observation
		_health = max_health
		_retract_amount = 0.0
		_spin_speed = 0.0
		_set_state(State.PATROL)


func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	_state_time = 0.0


# ── Collision handling ────────────────────────────────────────────

func _check_slide_collisions() -> void:
	for i in get_slide_collision_count():
		var collision: KinematicCollision3D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		var normal: Vector3 = collision.get_normal()

		if _state == State.KICKED or _state == State.RICOCHET:
			# Hit another enemy
			if collider is Node3D and collider != self and collider is Node and (collider as Node).is_in_group("enemy"):
				if collider.has_method("take_damage"):
					collider.take_damage(kick_damage)
				elif collider.has_method("apply_damage"):
					collider.apply_damage(kick_damage)
				elif collider.has_method("damage"):
					collider.damage(kick_damage)

			# Wall bounce (non-floor surface)
			if normal.y < 0.7:
				_kick_direction = _kick_direction.bounce(normal)
				_kick_direction.y = 0.0
				if _kick_direction.length_squared() > 0.001:
					_kick_direction = _kick_direction.normalized()
				_set_state(State.RICOCHET)

		elif _state == State.PATROL:
			# Reverse at walls
			if normal.y < 0.7:
				_patrol_direction = _patrol_direction.bounce(normal)
				_patrol_direction.y = 0.0
				if _patrol_direction.length_squared() > 0.001:
					_patrol_direction = _patrol_direction.normalized()

		elif _state == State.SHELL:
			# Player walks into shell → kick it
			if collider is Node3D and collider == _player_node:
				var away: Vector3 = (global_position - _player_node.global_position)
				away.y = 0.0
				if away.length_squared() > 0.001:
					_kick_direction = away.normalized()
				else:
					_kick_direction = Vector3.FORWARD
				_spin_speed = kick_speed
				_set_state(State.KICKED)


func _check_kick() -> bool:
	if _state != State.SHELL:
		return false
	if not is_instance_valid(_player_node):
		return false
	var dist: float = global_position.distance_to(_player_node.global_position)
	if dist < shell_radius * 4.0:
		# Player close enough to kick
		_kick_direction = (global_position - _player_node.global_position).normalized()
		_kick_direction.y = 0.0
		if _kick_direction.length_squared() > 0.001:
			_kick_direction = _kick_direction.normalized()
		else:
			_kick_direction = Vector3.FORWARD
		return true
	return false


# ── Mesh building ─────────────────────────────────────────────────

func _create_materials() -> void:
	_shell_material = StandardMaterial3D.new()
	_shell_material.albedo_color = shell_color
	_shell_material.metallic = 0.15
	_shell_material.roughness = 0.55
	_shell_material.emission_enabled = true
	_shell_material.emission = emission_color * 0.3
	_shell_material.emission_energy_multiplier = 0.2

	_belly_material = StandardMaterial3D.new()
	_belly_material.albedo_color = belly_color
	_belly_material.metallic = 0.0
	_belly_material.roughness = 0.9

	_eye_material = StandardMaterial3D.new()
	_eye_material.albedo_color = eye_color
	_eye_material.metallic = 0.0
	_eye_material.roughness = 0.3

	_pupil_material = StandardMaterial3D.new()
	_pupil_material.albedo_color = Color(0.05, 0.05, 0.05)
	_pupil_material.metallic = 0.0
	_pupil_material.roughness = 0.2

	_leg_material = StandardMaterial3D.new()
	_leg_material.albedo_color = belly_color * 0.85
	_leg_material.metallic = 0.0
	_leg_material.roughness = 0.8


func _build_collision() -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "CollisionShape"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = shell_radius
	shape.shape = sphere
	shape.position = Vector3(0, shell_radius, 0)
	add_child(shape)


func _build_mesh() -> void:
	if _mesh_root and is_instance_valid(_mesh_root):
		_mesh_root.free()
	_leg_meshes.clear()

	_mesh_root = Node3D.new()
	_mesh_root.name = "MeshRoot"
	_mesh_root.position = Vector3(0, shell_radius, 0)
	add_child(_mesh_root)

	# Shell — faceted icosahedron look (low-poly sphere)
	_shell_mesh = MeshInstance3D.new()
	_shell_mesh.name = "Shell"
	var shell_sphere: SphereMesh = SphereMesh.new()
	shell_sphere.radius = shell_radius
	shell_sphere.height = shell_radius * 2.0
	shell_sphere.radial_segments = 6
	shell_sphere.rings = 3
	_shell_mesh.mesh = shell_sphere
	_shell_mesh.material_override = _shell_material
	_mesh_root.add_child(_shell_mesh)

	# Belly — hemisphere on bottom
	_belly_mesh = MeshInstance3D.new()
	_belly_mesh.name = "Belly"
	var belly_sphere: SphereMesh = SphereMesh.new()
	belly_sphere.radius = shell_radius * 0.92
	belly_sphere.height = shell_radius * 0.9
	belly_sphere.radial_segments = 8
	belly_sphere.rings = 2
	_belly_mesh.mesh = belly_sphere
	_belly_mesh.material_override = _belly_material
	_belly_mesh.position = Vector3(0, -shell_radius * 0.25, 0)
	_mesh_root.add_child(_belly_mesh)

	# Eyes
	_eye_left = _build_eye(Vector3(-shell_radius * 0.35, shell_radius * 0.2, -shell_radius * 0.8))
	_eye_right = _build_eye(Vector3(shell_radius * 0.35, shell_radius * 0.2, -shell_radius * 0.8))
	_mesh_root.add_child(_eye_left)
	_mesh_root.add_child(_eye_right)

	# Legs
	for i in range(num_legs):
		var leg: Node3D = _build_leg(i)
		_mesh_root.add_child(leg)
		_leg_meshes.append(leg)


func _build_eye(pos: Vector3) -> Node3D:
	var eye_root: Node3D = Node3D.new()
	eye_root.name = "Eye"
	eye_root.position = pos

	# White of eye
	var white: MeshInstance3D = MeshInstance3D.new()
	white.name = "White"
	var white_mesh: SphereMesh = SphereMesh.new()
	white_mesh.radius = shell_radius * 0.15
	white_mesh.height = shell_radius * 0.3
	white_mesh.radial_segments = 8
	white_mesh.rings = 4
	white.mesh = white_mesh
	white.material_override = _eye_material
	eye_root.add_child(white)

	# Pupil
	var pupil: MeshInstance3D = MeshInstance3D.new()
	pupil.name = "Pupil"
	var pupil_mesh: SphereMesh = SphereMesh.new()
	pupil_mesh.radius = shell_radius * 0.07
	pupil_mesh.height = shell_radius * 0.14
	pupil_mesh.radial_segments = 6
	pupil_mesh.rings = 3
	pupil.mesh = pupil_mesh
	pupil.material_override = _pupil_material
	pupil.position = Vector3(0, 0, -shell_radius * 0.1)
	eye_root.add_child(pupil)

	return eye_root


func _build_leg(index: int) -> Node3D:
	var leg_root: Node3D = Node3D.new()
	leg_root.name = "Leg_%d" % index

	var angle: float = (float(index) / float(num_legs)) * TAU
	var x: float = cos(angle) * shell_radius * 0.55
	var z: float = sin(angle) * shell_radius * 0.55
	leg_root.position = Vector3(x, -shell_radius * 0.6, z)

	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	mesh_inst.name = "LegMesh"
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.height = leg_length
	cyl.top_radius = shell_radius * 0.08
	cyl.bottom_radius = shell_radius * 0.12
	cyl.radial_segments = 5
	mesh_inst.mesh = cyl
	mesh_inst.material_override = _leg_material
	leg_root.add_child(mesh_inst)

	# Small foot sphere
	var foot: MeshInstance3D = MeshInstance3D.new()
	foot.name = "Foot"
	var foot_mesh: SphereMesh = SphereMesh.new()
	foot_mesh.radius = shell_radius * 0.1
	foot_mesh.height = shell_radius * 0.2
	foot_mesh.radial_segments = 5
	foot_mesh.rings = 3
	foot.mesh = foot_mesh
	foot.material_override = _leg_material
	foot.position = Vector3(0, -leg_length * 0.5, 0)
	leg_root.add_child(foot)

	return leg_root


# ── Mesh update (every frame) ────────────────────────────────────

func _update_mesh(delta: float) -> void:
	if not is_instance_valid(_mesh_root):
		return

	# Leg positions and visibility based on retract amount
	for i in range(_leg_meshes.size()):
		if not is_instance_valid(_leg_meshes[i]):
			continue
		var leg: Node3D = _leg_meshes[i]
		var angle: float = (float(i) / float(num_legs)) * TAU

		# Base position
		var x: float = cos(angle) * shell_radius * 0.55
		var z: float = sin(angle) * shell_radius * 0.55
		var base_y: float = -shell_radius * 0.6

		# Walk animation — stagger per leg
		var walk_offset: float = 0.0
		if _state == State.PATROL:
			walk_offset = sin(_walk_phase + angle) * 0.03

		# Retract: pull legs inward and upward into shell
		var retracted_x: float = cos(angle) * shell_radius * 0.15
		var retracted_z: float = sin(angle) * shell_radius * 0.15
		var retracted_y: float = -shell_radius * 0.1

		leg.position = Vector3(
			lerp(x, retracted_x, _retract_amount),
			lerp(base_y + walk_offset, retracted_y, _retract_amount),
			lerp(z, retracted_z, _retract_amount)
		)

		# Scale down when retracted
		var s: float = lerp(1.0, 0.1, _retract_amount)
		leg.scale = Vector3(s, s, s)
		leg.visible = _retract_amount < 0.95

	# Eye visibility — hidden when retracted
	if is_instance_valid(_eye_left):
		_eye_left.visible = _retract_amount < 0.7
		var eye_hide: float = clamp(_retract_amount / 0.7, 0.0, 1.0)
		var eye_scale: float = lerp(1.0, 0.0, eye_hide)
		_eye_left.scale = Vector3(eye_scale, eye_scale, eye_scale)
	if is_instance_valid(_eye_right):
		_eye_right.visible = _retract_amount < 0.7
		var eye_hide: float = clamp(_retract_amount / 0.7, 0.0, 1.0)
		var eye_scale: float = lerp(1.0, 0.0, eye_hide)
		_eye_right.scale = Vector3(eye_scale, eye_scale, eye_scale)

	# Belly visibility — hidden when fully retracted
	if is_instance_valid(_belly_mesh):
		_belly_mesh.visible = _retract_amount < 0.9
		var belly_s: float = lerp(1.0, 0.3, _retract_amount)
		_belly_mesh.scale = Vector3(belly_s, belly_s, belly_s)

	# Shell spin during KICKED/RICOCHET
	if is_instance_valid(_shell_mesh):
		if _state == State.KICKED or _state == State.RICOCHET:
			_shell_mesh.rotation.x += _spin_speed * delta * 5.0
			_shell_mesh.rotation.z += _spin_speed * delta * 2.0

	# Waddle during PATROL
	if _state == State.PATROL:
		_mesh_root.rotation.z = sin(_walk_phase * 5.0) * 0.1
	else:
		_mesh_root.rotation.z = move_toward(_mesh_root.rotation.z, 0.0, delta * 5.0)

	# Ricochet flash
	if _state == State.RICOCHET:
		var flash: float = sin(_state_time * 40.0) * 0.5 + 0.5
		_shell_material.emission_energy_multiplier = flash * 2.0
	elif _state == State.KICKED:
		_shell_material.emission_energy_multiplier = 0.4
	else:
		_shell_material.emission_energy_multiplier = 0.2

	# Death wobble
	if _state == State.DEAD:
		var wobble: float = sin(_state_time * 15.0) * max(0.0, 1.0 - _state_time * 0.5)
		_mesh_root.scale = Vector3(1.0 + wobble * 0.2, 1.0 - wobble * 0.15, 1.0 + wobble * 0.2)
		_mesh_root.rotation.z = wobble * 0.3
	elif _state != State.PATROL:
		_mesh_root.scale = Vector3.ONE


# ── Combat ────────────────────────────────────────────────────────

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
		tween.tween_property(_shell_material, "emission_energy_multiplier", 3.0, 0.05)
		tween.tween_property(_shell_material, "emission_energy_multiplier", 0.2, 0.2)


# ── Utility ───────────────────────────────────────────────────────

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


func configure(config: Dictionary) -> void:
	if config.has("health"):
		max_health = float(config["health"])
		_health = max_health
	if config.has("speed"):
		patrol_speed = float(config["speed"])
	if config.has("kick_speed"):
		kick_speed = float(config["kick_speed"])
	if config.has("kick_damage"):
		kick_damage = float(config["kick_damage"])
	if config.has("radius"):
		shell_radius = float(config["radius"])
	if config.has("legs"):
		num_legs = int(config["legs"])

	if is_instance_valid(_mesh_root):
		_build_mesh()


func apply_grid_config(config: Dictionary) -> void:
	configure(config)
