# @identity
# essence: A box that walks. Stomp it flat — topology as vulnerability.
# desire: patrol corridors, bump into the player, get flattened by a stomp from above
# critical_parameter: _flatten (0=walking box, 1=completely flat/stunned)
# triggers: PATROL→DETECT→CHARGE→STOMPED→RECOVER→DEAD
# emerges: the stomp mechanic — player learns to attack from above, not head-on
# truth: A box has six faces but only one is vulnerable — the top.

extends CharacterBody3D
class_name GoombaBox
## A folding cardboard box that patrols and can be stomped from above.
## Stomp the lid to flatten it — Mario-style hazard with topology twist.

signal enemy_destroyed(enemy: Node3D)

enum State { PATROL, DETECT, CHARGE, STOMPED, RECOVER, DEAD }

@export_group("Geometry")
@export var box_width: float = 0.35
@export var box_height: float = 0.4
@export var box_depth: float = 0.3

@export_group("Combat")
@export var max_health: float = 40.0
@export var patrol_speed: float = 1.5
@export var charge_speed: float = 3.5
@export var detection_radius: float = 8.0
@export var contact_damage: float = 15.0
@export var stomp_stun_time: float = 3.0
@export var stomp_damage: float = 20.0

@export_group("Appearance")
@export var box_color: Color = Color(0.6, 0.35, 0.15)  # Cardboard brown
@export var crease_color: Color = Color(0.4, 0.22, 0.1)
@export var eye_color: Color = Color(1.0, 0.9, 0.2)  # Yellow angry eyes
@export var emission_color: Color = Color(0.8, 0.4, 0.1)

# State
var _health: float = 0.0
var _state: State = State.PATROL
var _state_time: float = 0.0
var _flatten: float = 0.0  # 0 = walking box, 1 = completely flat
var _walk_phase: float = 0.0
var _patrol_direction: Vector3 = Vector3.FORWARD
var _player_node: Node3D = null

# Mesh references
var _mesh_root: Node3D = null
var _body_mesh: MeshInstance3D = null
var _lid_mesh: Node3D = null  # Pivot node for lid hinge
var _lid_mesh_inst: MeshInstance3D = null
var _eye_left: MeshInstance3D = null
var _eye_right: MeshInstance3D = null

# Materials
var _box_material: StandardMaterial3D
var _crease_material: StandardMaterial3D
var _eye_material: StandardMaterial3D


func _ready() -> void:
	_health = max_health
	_create_materials()
	_build_collision()
	_build_mesh()
	_find_player()
	add_to_group("enemy")
	add_to_group("goomba_enemy")
	_set_state(State.PATROL)
	# Randomize initial patrol direction
	_patrol_direction = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
	if _patrol_direction.length_squared() < 0.01:
		_patrol_direction = Vector3.FORWARD
	print("GoombaBox: READY at %s" % global_position)


func _physics_process(delta: float) -> void:
	_state_time += delta
	_walk_phase += delta

	if not is_instance_valid(_player_node):
		_find_player()

	# Gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	# Check stomp before state processing
	if _check_stomp():
		_on_stomped()

	match _state:
		State.PATROL:
			_process_patrol(delta)
		State.DETECT:
			_process_detect(delta)
		State.CHARGE:
			_process_charge(delta)
		State.STOMPED:
			_process_stomped(delta)
		State.RECOVER:
			_process_recover(delta)
		State.DEAD:
			_process_dead(delta)

	_update_mesh()

	if _state != State.DEAD:
		move_and_slide()


## State processing

func _process_patrol(delta: float) -> void:
	_flatten = move_toward(_flatten, 0.0, delta * 3.0)

	# Walk in patrol direction
	velocity.x = _patrol_direction.x * patrol_speed
	velocity.z = _patrol_direction.z * patrol_speed

	# Face movement direction
	if _patrol_direction.length_squared() > 0.01:
		var target_yaw: float = atan2(_patrol_direction.x, _patrol_direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * 5.0)

	# Reverse on wall collision
	if is_on_wall():
		_patrol_direction = -_patrol_direction
		# Add slight random variation on bounce
		_patrol_direction = _patrol_direction.rotated(Vector3.UP, randf_range(-0.3, 0.3))
		_patrol_direction.y = 0.0
		_patrol_direction = _patrol_direction.normalized()

	# Detect player
	var dist: float = _get_player_distance()
	if dist <= detection_radius:
		_set_state(State.DETECT)


func _process_detect(delta: float) -> void:
	_flatten = move_toward(_flatten, 0.0, delta * 3.0)
	velocity.x = 0.0
	velocity.z = 0.0

	# Face the player
	_face_player(delta * 5.0)

	# After 1 second pause, charge
	if _state_time >= 1.0:
		_set_state(State.CHARGE)


func _process_charge(delta: float) -> void:
	_flatten = move_toward(_flatten, 0.0, delta * 3.0)

	if is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - global_position
		to_player.y = 0.0
		if to_player.length() > 0.1:
			var move_dir: Vector3 = to_player.normalized()
			velocity.x = move_dir.x * charge_speed
			velocity.z = move_dir.z * charge_speed
			_face_player(delta * 8.0)
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	# Try to damage player on contact
	_try_damage_player()

	# Lose interest if player escapes
	var dist: float = _get_player_distance()
	if dist > detection_radius * 1.5:
		_set_state(State.PATROL)

	# Reverse direction on wall during charge
	if is_on_wall():
		_set_state(State.PATROL)
		_patrol_direction = -_patrol_direction.normalized()


func _process_stomped(delta: float) -> void:
	# Flatten quickly
	_flatten = move_toward(_flatten, 1.0, delta * (1.0 / 0.3))
	velocity.x = 0.0
	velocity.z = 0.0

	# After stun time, recover or die
	if _state_time >= stomp_stun_time:
		if _health > 0.0:
			_set_state(State.RECOVER)
		else:
			_set_state(State.DEAD)
			enemy_destroyed.emit(self)


func _process_recover(delta: float) -> void:
	# Unflatten over 1 second
	_flatten = move_toward(_flatten, 0.0, delta * 1.0)
	velocity.x = 0.0
	velocity.z = 0.0

	if _flatten <= 0.01:
		_set_state(State.PATROL)


func _process_dead(_delta: float) -> void:
	velocity = Vector3.ZERO
	_flatten = move_toward(_flatten, 1.0, _delta * 3.0)

	if _state_time >= 3.0:
		# Reset for dev observation
		_health = max_health
		_flatten = 0.0
		_set_state(State.PATROL)


func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	_state_time = 0.0


## Stomp detection (KEY MECHANIC)

func _check_stomp() -> bool:
	if _state == State.STOMPED or _state == State.DEAD:
		return false
	# Check slide collisions for something pressing from above
	for i in get_slide_collision_count():
		var collision: KinematicCollision3D = get_slide_collision(i)
		var normal: Vector3 = collision.get_normal()
		# Collision normal pointing down means something is on top
		if normal.y < -0.5:
			return true
	# Also check if player is directly above and close
	if is_instance_valid(_player_node):
		var diff: Vector3 = _player_node.global_position - global_position
		var horizontal_dist: float = Vector2(diff.x, diff.z).length()
		var above: float = diff.y
		if horizontal_dist < box_width * 1.5 and above > box_height * 0.3 and above < box_height * 2.0:
			# Player is above and close — check if they are moving downward
			if _player_node is CharacterBody3D:
				var pvel: Vector3 = (_player_node as CharacterBody3D).velocity
				if pvel.y < -0.5:
					return true
	return false


func _on_stomped() -> void:
	_apply_damage(stomp_damage)
	if _health > 0.0:
		_set_state(State.STOMPED)
	# If health went to 0, _apply_damage already triggers DEAD


## Mesh building

func _create_materials() -> void:
	_box_material = StandardMaterial3D.new()
	_box_material.albedo_color = box_color
	_box_material.metallic = 0.0
	_box_material.roughness = 0.85
	_box_material.emission_enabled = true
	_box_material.emission = emission_color
	_box_material.emission_energy_multiplier = 0.0

	_crease_material = StandardMaterial3D.new()
	_crease_material.albedo_color = crease_color
	_crease_material.metallic = 0.0
	_crease_material.roughness = 0.9

	_eye_material = StandardMaterial3D.new()
	_eye_material.albedo_color = eye_color
	_eye_material.metallic = 0.2
	_eye_material.roughness = 0.3
	_eye_material.emission_enabled = true
	_eye_material.emission = eye_color
	_eye_material.emission_energy_multiplier = 1.5


func _build_collision() -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "CollisionShape"
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(box_width, box_height, box_depth)
	shape.shape = box
	shape.position = Vector3(0.0, box_height * 0.5, 0.0)
	add_child(shape)


func _build_mesh() -> void:
	if _mesh_root and is_instance_valid(_mesh_root):
		_mesh_root.free()

	_mesh_root = Node3D.new()
	_mesh_root.name = "MeshRoot"
	add_child(_mesh_root)

	# Body — main box (open top)
	_body_mesh = MeshInstance3D.new()
	_body_mesh.name = "Body"
	var body_box: BoxMesh = BoxMesh.new()
	body_box.size = Vector3(box_width, box_height, box_depth)
	_body_mesh.mesh = body_box
	_body_mesh.material_override = _box_material
	_body_mesh.position = Vector3(0.0, box_height * 0.5, 0.0)
	_mesh_root.add_child(_body_mesh)

	# Crease lines — vertical edges of the box
	var hw: float = box_width * 0.5
	var hd: float = box_depth * 0.5
	var crease_positions: Array[Vector3] = [
		Vector3(-hw, box_height * 0.5, -hd),
		Vector3(hw, box_height * 0.5, -hd),
		Vector3(-hw, box_height * 0.5, hd),
		Vector3(hw, box_height * 0.5, hd),
	]
	for pos in crease_positions:
		var crease: MeshInstance3D = MeshInstance3D.new()
		var cyl: CylinderMesh = CylinderMesh.new()
		cyl.height = box_height
		cyl.top_radius = 0.005
		cyl.bottom_radius = 0.005
		crease.mesh = cyl
		crease.material_override = _crease_material
		crease.position = pos
		_mesh_root.add_child(crease)

	# Horizontal crease around middle
	for edge in [
		[Vector3(-hw, box_height * 0.5, 0.0), box_depth],
		[Vector3(hw, box_height * 0.5, 0.0), box_depth],
		[Vector3(0.0, box_height * 0.5, -hd), box_width],
		[Vector3(0.0, box_height * 0.5, hd), box_width],
	]:
		var crease: MeshInstance3D = MeshInstance3D.new()
		var cyl: CylinderMesh = CylinderMesh.new()
		cyl.height = edge[1]
		cyl.top_radius = 0.004
		cyl.bottom_radius = 0.004
		crease.mesh = cyl
		crease.material_override = _crease_material
		crease.position = edge[0]
		crease.rotation.x = PI * 0.5 if edge[0].z == 0.0 else 0.0
		crease.rotation.z = 0.0 if edge[0].z == 0.0 else PI * 0.5
		_mesh_root.add_child(crease)

	# Lid — hinged at the back edge (positive Z)
	# Pivot at the back-top edge of the box
	_lid_mesh = Node3D.new()
	_lid_mesh.name = "LidPivot"
	_lid_mesh.position = Vector3(0.0, box_height, hd)
	_mesh_root.add_child(_lid_mesh)

	_lid_mesh_inst = MeshInstance3D.new()
	_lid_mesh_inst.name = "Lid"
	var lid_box: BoxMesh = BoxMesh.new()
	lid_box.size = Vector3(box_width, 0.02, box_depth)
	_lid_mesh_inst.mesh = lid_box
	_lid_mesh_inst.material_override = _crease_material
	# Offset so the lid extends forward from the hinge
	_lid_mesh_inst.position = Vector3(0.0, 0.01, -hd)
	_lid_mesh.add_child(_lid_mesh_inst)

	# Eyes — two glowing spheres on the front face (negative Z)
	var eye_size: float = 0.04
	var eye_spacing: float = box_width * 0.3
	var eye_height: float = box_height * 0.65

	_eye_left = MeshInstance3D.new()
	_eye_left.name = "EyeLeft"
	var eye_sphere_l: SphereMesh = SphereMesh.new()
	eye_sphere_l.radius = eye_size
	eye_sphere_l.height = eye_size * 2.0
	_eye_left.mesh = eye_sphere_l
	_eye_left.material_override = _eye_material
	_eye_left.position = Vector3(-eye_spacing, eye_height, -hd - 0.01)
	_mesh_root.add_child(_eye_left)

	_eye_right = MeshInstance3D.new()
	_eye_right.name = "EyeRight"
	var eye_sphere_r: SphereMesh = SphereMesh.new()
	eye_sphere_r.radius = eye_size
	eye_sphere_r.height = eye_size * 2.0
	_eye_right.mesh = eye_sphere_r
	_eye_right.material_override = _eye_material
	_eye_right.position = Vector3(eye_spacing, eye_height, -hd - 0.01)
	_mesh_root.add_child(_eye_right)

	# Feet — two small boxes at bottom front
	var foot_size: Vector3 = Vector3(0.06, 0.04, 0.08)
	var foot_spacing: float = box_width * 0.25
	for side in [-1.0, 1.0]:
		var foot: MeshInstance3D = MeshInstance3D.new()
		foot.name = "Foot_%s" % ("L" if side < 0 else "R")
		var foot_box: BoxMesh = BoxMesh.new()
		foot_box.size = foot_size
		foot.mesh = foot_box
		foot.material_override = _crease_material
		foot.position = Vector3(side * foot_spacing, foot_size.y * 0.5, -hd * 0.5)
		_mesh_root.add_child(foot)


func _update_mesh() -> void:
	if not _mesh_root or not is_instance_valid(_mesh_root):
		return

	# Lid rotation — opens when flattened
	if _lid_mesh and is_instance_valid(_lid_mesh):
		_lid_mesh.rotation.x = lerp(0.0, -PI * 0.5, _flatten)

	# Body squash — flatten when stomped
	if _body_mesh and is_instance_valid(_body_mesh):
		var scale_y: float = lerp(1.0, 0.1, _flatten)
		_body_mesh.scale.y = scale_y
		_body_mesh.position.y = box_height * 0.5 * scale_y

	# Waddle during movement
	var waddle: float = 0.0
	if _state == State.PATROL or _state == State.CHARGE:
		waddle = sin(_walk_phase * 6.0) * 0.15
	_mesh_root.rotation.z = lerp(_mesh_root.rotation.z, waddle, 0.2)

	# Feet bob — alternate up/down during walk
	var foot_idx: int = 0
	for child in _mesh_root.get_children():
		if child.name.begins_with("Foot_"):
			var bob: float = 0.0
			if _state == State.PATROL or _state == State.CHARGE:
				bob = abs(sin(_walk_phase * 8.0 + foot_idx * PI)) * 0.03
			child.position.y = 0.02 + bob
			foot_idx += 1

	# Eyes — adjust glow based on state
	if _eye_material:
		var target_emission: float = 1.5
		match _state:
			State.PATROL:
				target_emission = 0.8
			State.DETECT:
				target_emission = 3.0
			State.CHARGE:
				target_emission = 2.5 + sin(_walk_phase * 10.0) * 0.5
			State.STOMPED:
				target_emission = 0.2
			State.RECOVER:
				target_emission = 1.0 + sin(_walk_phase * 4.0) * 0.5
			State.DEAD:
				target_emission = 0.0
		_eye_material.emission_energy_multiplier = lerp(
			_eye_material.emission_energy_multiplier, target_emission, 0.15
		)

	# Hide eyes when fully flattened
	if _eye_left and is_instance_valid(_eye_left):
		_eye_left.visible = _flatten < 0.8
	if _eye_right and is_instance_valid(_eye_right):
		_eye_right.visible = _flatten < 0.8

	# Box emission flash during detect/charge
	if _box_material:
		var box_emission: float = 0.0
		if _state == State.DETECT:
			box_emission = 0.3
		elif _state == State.CHARGE:
			box_emission = 0.15 + sin(_walk_phase * 12.0) * 0.1
		_box_material.emission_energy_multiplier = lerp(
			_box_material.emission_energy_multiplier, box_emission, 0.1
		)


## Combat

func _try_damage_player() -> void:
	if not is_instance_valid(_player_node):
		return
	if _state == State.STOMPED or _state == State.DEAD:
		return

	var dist: float = global_position.distance_to(_player_node.global_position)
	if dist > max(box_width, box_depth) * 1.5:
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
		tween.tween_property(_box_material, "emission_energy_multiplier", 2.0, 0.05)
		tween.tween_property(_box_material, "emission_energy_multiplier", 0.0, 0.15)


## Utility

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
	if config.has("health"):
		max_health = float(config["health"])
		_health = max_health
	if config.has("speed"):
		patrol_speed = float(config["speed"])
	if config.has("charge_speed"):
		charge_speed = float(config["charge_speed"])
	if config.has("damage"):
		contact_damage = float(config["damage"])
	if config.has("width"):
		box_width = float(config["width"])
	if config.has("height"):
		box_height = float(config["height"])
	if config.has("depth"):
		box_depth = float(config["depth"])

	if is_inside_tree():
		_build_collision()
		_build_mesh()


func apply_grid_config(config: Dictionary) -> void:
	configure(config)
