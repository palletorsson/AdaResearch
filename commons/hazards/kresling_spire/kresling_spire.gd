extends CharacterBody3D
class_name KreslingSpire
## Kresling origami sniper tower - twisting cylinder that extends to fire.
## Compact disc form for mobility, tall tower form for sniping.

signal fired_projectile(position: Vector3, direction: Vector3)
signal enemy_destroyed(enemy: Node3D)

enum State { DISC, RISE, AIM, FIRE, COLLAPSE, RELOCATE, DEAD }

const FIRE_BOLT_SCENE: PackedScene = preload("res://commons/hazards/armadillo_droideka/fire_bolt.tscn")

@export_group("Geometry")
@export var radial_segments: int = 6
@export var layers: int = 5
@export var radius: float = 0.28
@export var edge_length: float = 0.22

@export_group("Combat")
@export var max_health: float = 70.0
@export var disc_speed: float = 1.8
@export var detection_radius: float = 14.0
@export var optimal_range: float = 8.0
@export var fire_speed: float = 18.0
@export var fire_damage: float = 22.0
@export var shots_per_burst: int = 2
@export var fire_interval: float = 0.6

@export_group("Timing")
@export var rise_duration: float = 0.7
@export var aim_duration: float = 0.5
@export var collapse_duration: float = 0.4
@export var relocate_time: float = 2.0

@export_group("Appearance")
@export var shell_color: Color = Color(0.35, 0.38, 0.45, 1.0)
@export var crease_color: Color = Color(0.55, 0.58, 0.52, 1.0)
@export var core_color: Color = Color(0.2, 0.22, 0.25, 1.0)
@export var emission_color: Color = Color(1.0, 0.35, 0.1, 1.0)

# State
var _health: float = 0.0
var _state: State = State.DISC
var _state_time: float = 0.0
var _twist: float = 1.0  # 0 = extended (tall), 1 = compressed (disc)
var _shot_timer: float = 0.0
var _shots_fired: int = 0
var _spin_angle: float = 0.0
var _player_node: Node3D = null

# Geometry
var _geometry: KreslingGeometry = null
var _mesh_root: Node3D = null
var _face_meshes: Array[MeshInstance3D] = []
var _platform: Node3D = null
var _muzzle: Marker3D = null

# Materials
var _shell_material: StandardMaterial3D
var _crease_material: StandardMaterial3D
var _platform_material: StandardMaterial3D


func _ready() -> void:
	_health = max_health
	_create_materials()
	_build_collision()
	_geometry = KreslingGeometry.new()
	_rebuild_mesh()
	_find_player()
	add_to_group("enemy")
	add_to_group("kresling_enemy")


func _physics_process(delta: float) -> void:
	_state_time += delta
	
	if not is_instance_valid(_player_node):
		_find_player()
	
	match _state:
		State.DISC:
			_process_disc(delta)
		State.RISE:
			_process_rise(delta)
		State.AIM:
			_process_aim(delta)
		State.FIRE:
			_process_fire(delta)
		State.COLLAPSE:
			_process_collapse(delta)
		State.RELOCATE:
			_process_relocate(delta)
		State.DEAD:
			_process_dead(delta)
	
	_update_mesh()
	
	if _state != State.DEAD:
		move_and_slide()


func _process_disc(delta: float) -> void:
	_twist = move_toward(_twist, 0.95, delta * 3.0)
	
	# Spin while disc
	_spin_angle += delta * 4.0
	if _mesh_root:
		_mesh_root.rotation.y = _spin_angle
	
	# Move toward optimal range
	var dist: float = _get_player_distance()
	
	if dist <= detection_radius:
		if abs(dist - optimal_range) < 1.5:
			# Good position, rise up
			_set_state(State.RISE)
		else:
			# Move to optimal range
			velocity = _get_positioning_velocity()
	else:
		velocity = Vector3.ZERO


func _process_rise(delta: float) -> void:
	velocity = Vector3.ZERO
	
	var t: float = clamp(_state_time / rise_duration, 0.0, 1.0)
	_twist = lerp(0.95, 0.1, ease(t, 0.4))
	
	# Untwist rotation
	_spin_angle = lerp(_spin_angle, 0.0, t)
	if _mesh_root:
		_mesh_root.rotation.y = _spin_angle
	
	if t >= 1.0:
		_set_state(State.AIM)


func _process_aim(delta: float) -> void:
	velocity = Vector3.ZERO
	_twist = move_toward(_twist, 0.05, delta * 2.0)
	
	_aim_at_player(delta)
	
	if _state_time >= aim_duration:
		_shots_fired = 0
		_shot_timer = 0.0
		_set_state(State.FIRE)


func _process_fire(delta: float) -> void:
	velocity = Vector3.ZERO
	_aim_at_player(delta)
	
	_shot_timer -= delta
	if _shot_timer <= 0.0 and _shots_fired < shots_per_burst:
		_fire_projectile()
		_shots_fired += 1
		_shot_timer = fire_interval
	
	if _shots_fired >= shots_per_burst and _shot_timer <= 0.0:
		# Check if should relocate
		var dist: float = _get_player_distance()
		if dist < optimal_range * 0.5 or dist > detection_radius:
			_set_state(State.COLLAPSE)
		else:
			# Fire again
			_shots_fired = 0
			_set_state(State.AIM)


func _process_collapse(delta: float) -> void:
	velocity = Vector3.ZERO
	
	var t: float = clamp(_state_time / collapse_duration, 0.0, 1.0)
	_twist = lerp(0.05, 0.95, ease(t, 2.0))
	
	if t >= 1.0:
		_set_state(State.RELOCATE)


func _process_relocate(delta: float) -> void:
	_twist = 0.95
	
	# Spin while moving
	_spin_angle += delta * 5.0
	if _mesh_root:
		_mesh_root.rotation.y = _spin_angle
	
	velocity = _get_positioning_velocity() * 1.5
	
	var dist: float = _get_player_distance()
	if _state_time >= relocate_time or abs(dist - optimal_range) < 2.0:
		_set_state(State.RISE)


func _process_dead(delta: float) -> void:
	velocity = Vector3.ZERO
	_twist = move_toward(_twist, 0.7, delta)
	
	if _state_time >= 3.0:
		queue_free()


func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	_state_time = 0.0


func _get_positioning_velocity() -> Vector3:
	if not is_instance_valid(_player_node):
		return Vector3.ZERO
	
	var to_player: Vector3 = _player_node.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()
	
	if dist < 0.1:
		return Vector3.ZERO
	
	var dir: Vector3 = to_player.normalized()
	
	if dist < optimal_range * 0.6:
		# Too close, back away
		return -dir * disc_speed
	elif dist > optimal_range * 1.3:
		# Too far, approach
		return dir * disc_speed
	else:
		# Good range, strafe
		var side: Vector3 = Vector3(-dir.z, 0.0, dir.x)
		return side * disc_speed * 0.7


## Geometry

func _create_materials() -> void:
	_shell_material = StandardMaterial3D.new()
	_shell_material.albedo_color = shell_color
	_shell_material.metallic = 0.4
	_shell_material.roughness = 0.5
	_shell_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	_crease_material = StandardMaterial3D.new()
	_crease_material.albedo_color = crease_color
	_crease_material.metallic = 0.3
	_crease_material.roughness = 0.6
	
	_platform_material = StandardMaterial3D.new()
	_platform_material.albedo_color = core_color
	_platform_material.metallic = 0.6
	_platform_material.roughness = 0.3
	_platform_material.emission_enabled = true
	_platform_material.emission = emission_color
	_platform_material.emission_energy_multiplier = 0.8


func _build_collision() -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "CollisionShape"
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = radius * 1.1
	capsule.height = radius * 4.0
	shape.shape = capsule
	add_child(shape)


func _rebuild_mesh() -> void:
	if _mesh_root:
		_mesh_root.queue_free()
	_face_meshes.clear()
	_platform = null
	_muzzle = null
	
	_geometry.build_pattern(radial_segments, layers, radius, edge_length)
	_geometry.solve_twist(_twist)
	
	_mesh_root = Node3D.new()
	_mesh_root.name = "MeshRoot"
	add_child(_mesh_root)
	
	# Build face meshes
	for i in range(_geometry.faces.size()):
		var mesh_inst: MeshInstance3D = MeshInstance3D.new()
		mesh_inst.name = "Face_%d" % i
		mesh_inst.material_override = _shell_material
		_mesh_root.add_child(mesh_inst)
		_face_meshes.append(mesh_inst)
	
	# Build top platform
	_platform = Node3D.new()
	_platform.name = "Platform"
	_mesh_root.add_child(_platform)
	
	var platform_mesh: MeshInstance3D = MeshInstance3D.new()
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.height = 0.08
	cylinder.top_radius = radius * 0.7
	cylinder.bottom_radius = radius * 0.8
	platform_mesh.mesh = cylinder
	platform_mesh.material_override = _platform_material
	_platform.add_child(platform_mesh)
	
	# Muzzle
	_muzzle = Marker3D.new()
	_muzzle.name = "Muzzle"
	_muzzle.position = Vector3(0.0, 0.05, -radius * 0.5)
	_platform.add_child(_muzzle)
	
	# Muzzle light
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = emission_color
	light.light_energy = 1.5
	light.omni_range = 4.0
	_muzzle.add_child(light)
	
	_update_mesh()


func _update_mesh() -> void:
	if not _geometry:
		return
	
	_geometry.solve_twist(_twist)
	
	# Update face meshes
	for i in range(min(_face_meshes.size(), _geometry.faces.size())):
		var face: PackedInt32Array = _geometry.faces[i]
		if face.size() < 3:
			continue
		
		var v0: Vector3 = _geometry.vertices[face[0]]
		var v1: Vector3 = _geometry.vertices[face[1]]
		var v2: Vector3 = _geometry.vertices[face[2]]
		
		_face_meshes[i].mesh = _create_triangle_mesh(v0, v1, v2)
	
	# Update platform position
	if _platform:
		var top_pos: Vector3 = _geometry.get_top_center()
		top_pos.y = _geometry.get_height()
		_platform.position = top_pos


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
	
	fired_projectile.emit(spawn_pos, fire_dir)


func _get_fire_direction() -> Vector3:
	if _muzzle:
		return -_muzzle.global_transform.basis.z.normalized()
	
	if is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - global_position
		to_player.y += 1.2
		return to_player.normalized()
	
	return Vector3.FORWARD


func _aim_at_player(delta: float) -> void:
	if not _platform or not is_instance_valid(_player_node):
		return
	
	var target: Vector3 = _player_node.global_position + Vector3(0, 1.2, 0)
	var to_target: Vector3 = target - _platform.global_position
	
	if to_target.length_squared() < 0.001:
		return
	
	var yaw: float = atan2(to_target.x, to_target.z)
	_platform.rotation.y = lerp_angle(_platform.rotation.y, yaw, delta * 5.0)


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
		# Flash
		var tween: Tween = create_tween()
		tween.tween_property(_platform_material, "emission_energy_multiplier", 3.0, 0.05)
		tween.tween_property(_platform_material, "emission_energy_multiplier", 0.8, 0.15)


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


func configure(config: Dictionary) -> void:
	if config.has("segments"):
		radial_segments = int(config["segments"])
	if config.has("layers"):
		layers = int(config["layers"])
	if config.has("health"):
		max_health = float(config["health"])
		_health = max_health
	if config.has("damage"):
		fire_damage = float(config["damage"])
	
	if _geometry:
		_rebuild_mesh()


func apply_grid_config(config: Dictionary) -> void:
	configure(config)
