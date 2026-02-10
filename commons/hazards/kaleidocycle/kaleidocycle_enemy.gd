extends CharacterBody3D
class_name KaleidocycleEnemy
## Kaleidocycle enemy - tumbling ring of tetrahedra with 4 attack modes.
## Each face type triggers a different attack when it becomes active.

signal fired_projectile(position: Vector3, direction: Vector3)
signal enemy_destroyed(enemy: Node3D)

enum State { ROLL, CYCLE, ATTACK, COOLDOWN, DEAD }
enum AttackMode { FIRE, ICE, SPIKE, SHIELD }

const FIRE_BOLT_SCENE: PackedScene = preload("res://commons/hazards/armadillo_droideka/fire_bolt.tscn")

@export_group("Geometry")
@export var segment_count: int = 6
@export var edge_length: float = 0.18
@export var leg_ratio: float = 1.4

@export_group("Combat")
@export var max_health: float = 100.0
@export var roll_speed: float = 3.0
@export var tumble_speed: float = 0.2
@export var detection_radius: float = 12.0
@export var attack_radius: float = 2.5
@export var base_damage: float = 15.0

@export_group("Timing")
@export var cycle_duration: float = 8.0
@export var attack_duration: float = 6.0
@export var cooldown_duration: float = 4.0

@export_group("Face Colors")
@export var fire_color: Color = Color(1.0, 0.3, 0.1, 1.0)
@export var ice_color: Color = Color(0.2, 0.6, 1.0, 1.0)
@export var spike_color: Color = Color(0.7, 0.2, 0.8, 1.0)
@export var shield_color: Color = Color(1.0, 0.85, 0.2, 1.0)

# State
var _health: float = 0.0
var _state: State = State.ROLL
var _state_time: float = 0.0
var _rotation_phase: float = 0.0
var _current_mode: AttackMode = AttackMode.FIRE
var _target_phase: float = 0.0
var _player_node: Node3D = null
var _shield_active: bool = false

# Geometry
var _geometry: KaleidocycleGeometry = null
var _mesh_root: Node3D = null
var _face_meshes: Array[Array] = []  # [tet_idx][face_idx]
var _materials: Array[StandardMaterial3D] = []


func _ready() -> void:
	_health = max_health
	_create_materials()
	_build_collision()
	_geometry = KaleidocycleGeometry.new()
	_rebuild_mesh()
	_find_player()
	add_to_group("enemy")
	add_to_group("kaleidocycle_enemy")
	print("KaleidocycleEnemy: READY at %s" % global_position)


func _physics_process(delta: float) -> void:
	_state_time += delta
	
	if not is_instance_valid(_player_node):
		_find_player()
	
	match _state:
		State.ROLL:
			_process_roll(delta)
		State.CYCLE:
			_process_cycle(delta)
		State.ATTACK:
			_process_attack(delta)
		State.COOLDOWN:
			_process_cooldown(delta)
		State.DEAD:
			_process_dead(delta)
	
	_update_mesh()
	
	if _state != State.DEAD:
		move_and_slide()


func _process_roll(delta: float) -> void:
	# Continuous tumbling while rolling
	_rotation_phase += delta * tumble_speed
	
	var dist: float = _get_player_distance()
	
	if dist <= detection_radius:
		if dist <= attack_radius:
			# Close enough to attack
			_start_cycle()
		else:
			# Roll toward player
			if is_instance_valid(_player_node):
				var to_player: Vector3 = _player_node.global_position - global_position
				to_player.y = 0.0
				if to_player.length() > 0.1:
					velocity = to_player.normalized() * roll_speed
				else:
					velocity = Vector3.ZERO
			else:
				velocity = Vector3.ZERO
	else:
		velocity = Vector3.ZERO
		_rotation_phase += delta * tumble_speed * 0.3


func _process_cycle(delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, delta * 8.0)
	
	var t: float = clamp(_state_time / cycle_duration, 0.0, 1.0)
	
	# Rotate to target phase
	_rotation_phase = lerp(_rotation_phase, _target_phase, t)
	
	if t >= 1.0:
		_set_state(State.ATTACK)


func _process_attack(_delta: float) -> void:
	velocity = Vector3.ZERO
	
	var t: float = clamp(_state_time / attack_duration, 0.0, 1.0)
	
	# Execute attack based on mode
	if t > 0.2 and t < 0.4:
		match _current_mode:
			AttackMode.FIRE:
				_attack_fire()
			AttackMode.ICE:
				_attack_ice()
			AttackMode.SPIKE:
				_attack_spike()
			AttackMode.SHIELD:
				_attack_shield()
	
	# Slight pulse
	_rotation_phase += sin(t * PI * 0.4) * 0.1
	
	if t >= 1.0:
		_shield_active = false
		_set_state(State.COOLDOWN)


func _process_cooldown(delta: float) -> void:
	_rotation_phase += delta * tumble_speed * 0.5
	velocity = velocity.move_toward(Vector3.ZERO, delta * 4.0)
	
	if _state_time >= cooldown_duration:
		_set_state(State.ROLL)


func _process_dead(delta: float) -> void:
	velocity = Vector3.ZERO
	_rotation_phase += delta * 0.5
	
	if _state_time >= 3.0:
		# Reset instead of destroy for dev observation
		_health = max_health
		_set_state(State.ROLL)


func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	_state_time = 0.0


func _start_cycle() -> void:
	# Choose next attack mode (cycle through or random)
	_current_mode = AttackMode.values()[randi() % 4]
	
	# Set target rotation to show that face
	var mode_offset: float = TAU / 4.0 * float(_current_mode)
	_target_phase = _rotation_phase + mode_offset
	
	_set_state(State.CYCLE)


## Attacks

func _attack_fire() -> void:
	# Burst of fire projectiles
	if not FIRE_BOLT_SCENE:
		return
	
	for i in range(3):
		var angle: float = TAU / 3.0 * float(i)
		var dir: Vector3 = Vector3(cos(angle), 0.2, sin(angle)).normalized()
		
		var bolt: Node = FIRE_BOLT_SCENE.instantiate()
		if bolt:
			var scene: Node = get_tree().current_scene
			if scene:
				scene.add_child(bolt)
			if bolt.has_method("launch"):
				bolt.launch(global_position, dir, 12.0, base_damage)
			
			fired_projectile.emit(global_position, dir)


func _attack_ice() -> void:
	# Slow effect on nearby player (conceptual - just damage for now)
	_try_damage_player(base_damage * 0.8)


func _attack_spike() -> void:
	# High damage melee
	_try_damage_player(base_damage * 1.5)


func _attack_shield() -> void:
	# Activate shield - reduce incoming damage temporarily
	_shield_active = true


func _try_damage_player(damage: float) -> void:
	if not is_instance_valid(_player_node):
		return
	
	var dist: float = global_position.distance_to(_player_node.global_position)
	if dist > attack_radius * 1.5:
		return
	
	for method in ["take_damage", "apply_damage", "damage"]:
		if _player_node.has_method(method):
			_player_node.call(method, damage)
			return


## Geometry

func _create_materials() -> void:
	_materials.clear()
	
	# One material per attack mode
	for i in range(4):
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.metallic = 0.4
		mat.roughness = 0.5
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.emission_enabled = true
		mat.emission_energy_multiplier = 0.6
		
		match i:
			0:  # Fire
				mat.albedo_color = fire_color
				mat.emission = fire_color
			1:  # Ice
				mat.albedo_color = ice_color
				mat.emission = ice_color
			2:  # Spike
				mat.albedo_color = spike_color
				mat.emission = spike_color
			3:  # Shield
				mat.albedo_color = shield_color
				mat.emission = shield_color
		
		_materials.append(mat)


func _build_collision() -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "CollisionShape"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = edge_length * segment_count * 0.15
	shape.shape = sphere
	add_child(shape)


func _rebuild_mesh() -> void:
	if _mesh_root:
		_mesh_root.queue_free()
	_face_meshes.clear()
	
	_geometry.build(segment_count, edge_length, leg_ratio)
	_geometry.solve_rotation(_rotation_phase)
	
	_mesh_root = Node3D.new()
	_mesh_root.name = "MeshRoot"
	add_child(_mesh_root)
	
	# Create face meshes for each tetrahedron
	for tet_idx in range(_geometry.tetrahedra.size()):
		var tet_faces: Array = []
		
		for face_idx in range(4):
			var mesh_inst: MeshInstance3D = MeshInstance3D.new()
			mesh_inst.name = "Tet%d_Face%d" % [tet_idx, face_idx]
			mesh_inst.material_override = _materials[face_idx % _materials.size()]
			_mesh_root.add_child(mesh_inst)
			tet_faces.append(mesh_inst)
		
		_face_meshes.append(tet_faces)
	
	_update_mesh()


func _update_mesh() -> void:
	if not _geometry:
		return
	
	_geometry.solve_rotation(_rotation_phase)
	
	var active_face: int = _geometry.get_active_face()
	
	for tet_idx in range(_geometry.tetrahedra.size()):
		if tet_idx >= _face_meshes.size():
			continue
		
		var verts: PackedVector3Array = _geometry.tetrahedra[tet_idx]
		if verts.size() < 4:
			continue
		
		for face_idx in range(4):
			if face_idx >= _face_meshes[tet_idx].size():
				continue
			if face_idx >= _geometry.face_indices.size():
				continue
			
			var indices: PackedInt32Array = _geometry.face_indices[face_idx]
			if indices.size() < 3:
				continue
			
			var v0: Vector3 = verts[indices[0]]
			var v1: Vector3 = verts[indices[1]]
			var v2: Vector3 = verts[indices[2]]
			
			_face_meshes[tet_idx][face_idx].mesh = _create_triangle_mesh(v0, v1, v2)
			
			# Highlight active face
			var mat: StandardMaterial3D = _materials[face_idx % _materials.size()]
			if face_idx == active_face:
				mat.emission_energy_multiplier = 1.2
			else:
				mat.emission_energy_multiplier = 0.4


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

func take_damage(amount: float) -> void:
	_apply_damage(amount)

func apply_damage(amount: float) -> void:
	_apply_damage(amount)

func damage(amount: float) -> void:
	_apply_damage(amount)

func _apply_damage(amount: float) -> void:
	if _state == State.DEAD:
		return
	
	# Shield reduces damage
	if _shield_active:
		amount *= 0.3
	
	_health -= max(0.0, amount)
	
	if _health <= 0.0:
		_set_state(State.DEAD)
		enemy_destroyed.emit(self)
	else:
		# Flash all faces
		for mat in _materials:
			var tween: Tween = create_tween()
			tween.tween_property(mat, "emission_energy_multiplier", 2.0, 0.05)
			tween.tween_property(mat, "emission_energy_multiplier", 0.6, 0.15)


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
		segment_count = int(config["segments"])
	if config.has("health"):
		max_health = float(config["health"])
		_health = max_health
	if config.has("damage"):
		base_damage = float(config["damage"])
	
	if _geometry:
		_rebuild_mesh()


func apply_grid_config(config: Dictionary) -> void:
	configure(config)
