extends CharacterBody3D
class_name WaterbombEnemy
## A rolling/deploying enemy using rigid waterbomb origami geometry.
## The shell actually folds using geometric constraints, not fake scaling.

signal fired_projectile(position: Vector3, direction: Vector3)
signal enemy_destroyed(enemy: Node3D)

enum State { ROLL, DETECT, DEPLOY, AIM, FIRE, RETRACT, DEAD }

const FIRE_BOLT_SCENE: PackedScene = preload("res://commons/hazards/armadillo_droideka/fire_bolt.tscn")

@export_group("Origami Geometry")
@export var radial_segments: int = 12:
	set(v):
		radial_segments = max(6, v)
		if _origami: _rebuild_shell()
@export var ring_count: int = 2:
	set(v):
		ring_count = max(1, v)
		if _origami: _rebuild_shell()
@export var shell_radius: float = 0.5:
	set(v):
		shell_radius = max(0.1, v)
		if _origami: _rebuild_shell()

@export_group("Combat")
@export var max_health: float = 80.0
@export var roll_speed: float = 2.8
@export var turn_speed: float = 5.0
@export var detection_radius: float = 10.0
@export var disengage_radius: float = 16.0
@export var shots_per_burst: int = 3
@export var fire_interval: float = 0.35
@export var fire_speed: float = 14.0
@export var fire_damage: float = 14.0
@export var contact_damage: float = 10.0

@export_group("Timing")
@export var detect_hold_time: float = 0.35
@export var deploy_duration: float = 0.8
@export var aim_duration: float = 0.4
@export var retract_duration: float = 0.6

@export_group("Appearance")
@export var shell_color: Color = Color(0.55, 0.85, 0.75, 1.0)
@export var crease_color: Color = Color(0.2, 0.25, 0.22, 1.0)
@export var core_color: Color = Color(0.15, 0.15, 0.18, 1.0)
@export var emission_color: Color = Color(1.0, 0.4, 0.15, 1.0)

# Internal state
var _health: float = 0.0
var _state: State = State.ROLL
var _state_time: float = 0.0
var _deployment: float = 0.0  # 0 = collapsed ball, 1 = open flower
var _roll_angle: float = 0.0
var _shot_timer: float = 0.0
var _shots_fired: int = 0
var _contact_timer: float = 0.0
var _player_node: Node3D = null

# Geometry
var _origami: RigidOrigami = null
var _shell_root: Node3D = null
var _face_meshes: Array[MeshInstance3D] = []
var _core: Node3D = null
var _muzzle: Marker3D = null

# Materials
var _shell_material: StandardMaterial3D
var _crease_material: StandardMaterial3D
var _core_material: StandardMaterial3D


func _ready() -> void:
	_health = max_health
	_create_materials()
	_build_collision()
	_origami = RigidOrigami.new()
	_rebuild_shell()
	_find_player()
	add_to_group("enemy")
	add_to_group("origami_enemy")


func _physics_process(delta: float) -> void:
	_state_time += delta
	_contact_timer = max(0.0, _contact_timer - delta)
	
	if not is_instance_valid(_player_node):
		_find_player()
	
	match _state:
		State.ROLL:
			_process_roll(delta)
		State.DETECT:
			_process_detect(delta)
		State.DEPLOY:
			_process_deploy(delta)
		State.AIM:
			_process_aim(delta)
		State.FIRE:
			_process_fire(delta)
		State.RETRACT:
			_process_retract(delta)
		State.DEAD:
			_process_dead(delta)
	
	# Update shell geometry
	_update_shell()
	
	if _state != State.DEAD:
		move_and_slide()
		_handle_contact_damage()


## State processing

func _process_roll(delta: float) -> void:
	_deployment = move_toward(_deployment, 0.0, delta / retract_duration)
	
	var move_dir: Vector3 = Vector3.ZERO
	var dist: float = INF
	
	if is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - global_position
		to_player.y = 0.0
		dist = to_player.length()
		if dist > 0.01:
			move_dir = to_player.normalized()
			_face_direction(move_dir, delta)
	
	velocity = move_dir * roll_speed
	velocity.y = 0.0
	
	# Roll animation
	var speed: float = Vector2(velocity.x, velocity.z).length()
	_roll_angle += speed * delta / max(shell_radius * 0.5, 0.1)
	if _shell_root:
		_shell_root.rotation.x = _roll_angle
	
	if dist <= detection_radius:
		_set_state(State.DETECT)


func _process_detect(delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, delta * 8.0)
	_deployment = move_toward(_deployment, 0.15, delta * 2.0)
	_aim_at_player(delta)
	
	if _state_time >= detect_hold_time:
		_set_state(State.DEPLOY)


func _process_deploy(_delta: float) -> void:
	velocity = Vector3.ZERO
	var t: float = clamp(_state_time / deploy_duration, 0.0, 1.0)
	_deployment = t
	_aim_at_player(1.0)
	
	if t >= 1.0:
		_set_state(State.AIM)


func _process_aim(delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, delta * 6.0)
	_deployment = 1.0
	_aim_at_player(delta)
	
	if _state_time >= aim_duration:
		_shots_fired = 0
		_shot_timer = 0.0
		_set_state(State.FIRE)


func _process_fire(delta: float) -> void:
	_deployment = 1.0
	_aim_at_player(delta)
	
	_shot_timer -= delta
	if _shot_timer <= 0.0 and _shots_fired < shots_per_burst:
		_fire_projectile()
		_shots_fired += 1
		_shot_timer = fire_interval
	
	if _shots_fired >= shots_per_burst and _shot_timer <= 0.0:
		_set_state(State.RETRACT)


func _process_retract(_delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, 0.2)
	var t: float = clamp(_state_time / retract_duration, 0.0, 1.0)
	_deployment = 1.0 - t
	
	if t >= 1.0:
		_set_state(State.ROLL)


func _process_dead(delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, delta * 4.0)
	_deployment = move_toward(_deployment, 0.4, delta)
	
	if _state_time >= 4.0:
		queue_free()


func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	_state_time = 0.0


## Geometry building

func _create_materials() -> void:
	_shell_material = StandardMaterial3D.new()
	_shell_material.albedo_color = shell_color
	_shell_material.metallic = 0.2
	_shell_material.roughness = 0.55
	_shell_material.emission_enabled = true
	_shell_material.emission = emission_color * 0.3
	_shell_material.emission_energy_multiplier = 0.5
	_shell_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	_crease_material = StandardMaterial3D.new()
	_crease_material.albedo_color = crease_color
	_crease_material.metallic = 0.4
	_crease_material.roughness = 0.3
	
	_core_material = StandardMaterial3D.new()
	_core_material.albedo_color = core_color
	_core_material.metallic = 0.6
	_core_material.roughness = 0.25
	_core_material.emission_enabled = true
	_core_material.emission = emission_color
	_core_material.emission_energy_multiplier = 1.2


func _build_collision() -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "CollisionShape"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = shell_radius * 0.8
	shape.shape = sphere
	add_child(shape)


func _rebuild_shell() -> void:
	# Clear existing
	if _shell_root:
		_shell_root.queue_free()
		_shell_root = null
	_face_meshes.clear()
	_core = null
	_muzzle = null
	
	# Build origami geometry
	_origami.build_waterbomb_ball(radial_segments, ring_count, shell_radius)
	_origami.solve_deployment(_deployment)
	
	# Create shell root
	_shell_root = Node3D.new()
	_shell_root.name = "ShellRoot"
	add_child(_shell_root)
	
	# Build face meshes
	var positions: PackedVector3Array = _origami.get_vertex_positions()
	var face_indices: Array[PackedInt32Array] = _origami.get_face_indices()
	
	for i in range(face_indices.size()):
		var face: PackedInt32Array = face_indices[i]
		if face.size() < 3:
			continue
		
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		mesh_instance.name = "Face_%d" % i
		mesh_instance.material_override = _shell_material
		_shell_root.add_child(mesh_instance)
		_face_meshes.append(mesh_instance)
	
	# Build crease lines
	var crease_pairs: Array[Vector2i] = _origami.get_crease_pairs()
	var crease_signs: PackedFloat32Array = _origami.get_crease_signs()
	
	for i in range(crease_pairs.size()):
		var pair: Vector2i = crease_pairs[i]
		var sign_val: float = crease_signs[i]
		
		var v0: Vector3 = positions[pair.x]
		var v1: Vector3 = positions[pair.y]
		
		var line: MeshInstance3D = _create_crease_line(v0, v1, sign_val)
		_shell_root.add_child(line)
	
	# Build core (weapon platform)
	_build_core()
	
	# Initial update
	_update_shell_geometry()


func _build_core() -> void:
	_core = Node3D.new()
	_core.name = "Core"
	add_child(_core)
	
	# Core sphere
	var sphere_mesh: SphereMesh = SphereMesh.new()
	sphere_mesh.radius = shell_radius * 0.25
	sphere_mesh.height = shell_radius * 0.5
	var sphere_inst: MeshInstance3D = MeshInstance3D.new()
	sphere_inst.mesh = sphere_mesh
	sphere_inst.material_override = _core_material
	_core.add_child(sphere_inst)
	
	# Muzzle
	_muzzle = Marker3D.new()
	_muzzle.name = "Muzzle"
	_muzzle.position = Vector3(0.0, 0.0, -shell_radius * 0.5)
	_core.add_child(_muzzle)
	
	# Muzzle light
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = emission_color
	light.light_energy = 1.5
	light.omni_range = 3.0
	_muzzle.add_child(light)


func _create_crease_line(v0: Vector3, v1: Vector3, fold_sign: float) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	
	var direction: Vector3 = v1 - v0
	var length: float = direction.length()
	if length < 0.001:
		return mesh_instance
	
	# Use cylinder for crease line
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.height = length
	cylinder.top_radius = 0.004
	cylinder.bottom_radius = 0.004
	mesh_instance.mesh = cylinder
	
	# Color based on fold type
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	if fold_sign > 0:
		mat.albedo_color = Color(0.8, 0.3, 0.2)  # Mountain = red
	elif fold_sign < 0:
		mat.albedo_color = Color(0.2, 0.4, 0.8)  # Valley = blue
	else:
		mat.albedo_color = crease_color  # Neutral
	mat.metallic = 0.3
	mat.roughness = 0.4
	mesh_instance.material_override = mat
	
	# Position and orient
	var mid: Vector3 = (v0 + v1) * 0.5
	mesh_instance.position = mid
	
	var up: Vector3 = direction.normalized()
	if abs(up.dot(Vector3.UP)) < 0.99:
		mesh_instance.look_at(mesh_instance.global_position + up, Vector3.UP)
		mesh_instance.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	
	return mesh_instance


func _update_shell() -> void:
	if not _origami:
		return
	
	# Solve for current deployment
	_origami.solve_deployment(_deployment)
	
	# Update mesh geometry
	_update_shell_geometry()
	
	# Update core position (rises when deployed)
	if _core:
		_core.position.y = lerp(0.0, shell_radius * 0.6, _deployment)


func _update_shell_geometry() -> void:
	var positions: PackedVector3Array = _origami.get_vertex_positions()
	var face_indices: Array[PackedInt32Array] = _origami.get_face_indices()
	
	for i in range(min(_face_meshes.size(), face_indices.size())):
		var mesh_inst: MeshInstance3D = _face_meshes[i]
		var face: PackedInt32Array = face_indices[i]
		
		if face.size() < 3:
			continue
		
		var v0: Vector3 = positions[face[0]]
		var v1: Vector3 = positions[face[1]]
		var v2: Vector3 = positions[face[2]]
		
		# Rebuild triangle mesh
		mesh_inst.mesh = _create_triangle_mesh(v0, v1, v2)


func _create_triangle_mesh(v0: Vector3, v1: Vector3, v2: Vector3) -> ArrayMesh:
	var mesh: ArrayMesh = ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices: PackedVector3Array = [v0, v1, v2]
	var normal: Vector3 = (v1 - v0).cross(v2 - v0).normalized()
	var normals: PackedVector3Array = [normal, normal, normal]
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Combat

func _fire_projectile() -> void:
	if not FIRE_BOLT_SCENE or not _muzzle:
		return
	
	var bolt: Node = FIRE_BOLT_SCENE.instantiate()
	if not bolt:
		return
	
	var spawn_pos: Vector3 = _muzzle.global_position
	var fire_dir: Vector3 = _get_fire_direction()
	
	var scene: Node = get_tree().current_scene
	if scene:
		scene.add_child(bolt)
	else:
		add_child(bolt)
	
	if bolt.has_method("launch"):
		bolt.launch(spawn_pos, fire_dir, fire_speed, fire_damage)
	elif bolt is Node3D:
		(bolt as Node3D).global_position = spawn_pos
	
	fired_projectile.emit(spawn_pos, fire_dir)


func _get_fire_direction() -> Vector3:
	if _muzzle:
		var dir: Vector3 = -_muzzle.global_transform.basis.z
		if dir.length_squared() > 0.001:
			return dir.normalized()
	
	if is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - global_position
		to_player.y += 1.2
		if to_player.length_squared() > 0.001:
			return to_player.normalized()
	
	return -global_transform.basis.z.normalized()


func _handle_contact_damage() -> void:
	if _contact_timer > 0.0 or contact_damage <= 0.0:
		return
	
	for i in range(get_slide_collision_count()):
		var collision: KinematicCollision3D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if _try_damage(collider):
			_contact_timer = 0.6
			break


func _try_damage(target: Object) -> bool:
	if target == null:
		return false
	
	for method in ["take_damage", "apply_damage", "damage"]:
		if target.has_method(method):
			target.call(method, contact_damage)
			return true
	
	return false


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
		# Hit feedback
		if _core:
			var tween: Tween = create_tween()
			tween.tween_property(_core, "scale", Vector3(1.15, 1.15, 1.15), 0.05)
			tween.tween_property(_core, "scale", Vector3.ONE, 0.1)


## Utility

func _find_player() -> void:
	var scene: Node = get_tree().current_scene
	if not scene:
		_player_node = null
		return
	
	var candidates: Array = [
		get_tree().get_first_node_in_group("player"),
		scene.find_child("XROrigin3D", true, false),
		scene.find_child("Player", true, false),
	]
	
	for c in candidates:
		if c is Node3D:
			_player_node = c
			return
	
	_player_node = null


func _face_direction(dir: Vector3, delta: float) -> void:
	if dir.length_squared() < 0.001:
		return
	var target_yaw: float = atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)


func _aim_at_player(blend: float) -> void:
	if not _core or not is_instance_valid(_player_node):
		return
	
	var target: Vector3 = _player_node.global_position + Vector3(0, 1.2, 0)
	var direction: Vector3 = target - _core.global_position
	if direction.length_squared() < 0.001:
		return
	
	var yaw: float = atan2(direction.x, direction.z)
	_core.rotation.y = lerp_angle(_core.rotation.y, yaw, blend * 0.25)


func configure(config: Dictionary) -> void:
	if config.has("segments"):
		radial_segments = int(config["segments"])
	if config.has("rings"):
		ring_count = int(config["rings"])
	if config.has("radius"):
		shell_radius = float(config["radius"])
	if config.has("health"):
		max_health = float(config["health"])
		_health = max_health
	if config.has("speed"):
		roll_speed = float(config["speed"])
	if config.has("damage"):
		fire_damage = float(config["damage"])


func apply_grid_config(config: Dictionary) -> void:
	configure(config)
