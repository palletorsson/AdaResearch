extends Node3D

const CUBE_SCENE: PackedScene = preload("res://commons/scenes/mapobjects/reset_cube.tscn")

@export var spawn_height: float = 12.0
@export var spawn_offset: Vector3 = Vector3.ZERO
@export var spawn_interval_range: Vector2 = Vector2(1.0, 2.5)
@export var start_delay: float = 0.5
@export var cube_damage: float = 20.0
@export var gravity: float = 35.0
@export var cube_mass: float = 1.0
@export var linear_damp: float = 0.05
@export var angular_damp: float = 0.05
@export var cleanup_floor_height: float = 0.0
@export var max_active_cubes: int = 1
@export var randomize_rotation: bool = false
@export var teleport_on_hit: bool = true
@export var teleport_target: Node3D

var _rng := RandomNumberGenerator.new()
var _spawn_timer: Timer
var _active_cubes: Array[RigidBody3D] = []
var _fallback_spawn: Node3D

func _ready() -> void:
	_rng.randomize()
	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_spawn_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_spawn_timer)
	set_physics_process(not Engine.is_editor_hint())
	call_deferred("_initialize_teleport_target")
	if Engine.is_editor_hint():
		return
	_start_spawning()

func _initialize_teleport_target() -> void:
	if teleport_target:
		return
	var current_scene := get_tree().current_scene
	if current_scene == null:
			return
	teleport_target = current_scene.find_child("SpawnPoint", true, false) as Node3D
	if teleport_target == null:
		teleport_target = current_scene.find_child("*spawn*", true, false) as Node3D
	if teleport_target == null:
		_fallback_spawn = Node3D.new()
		_fallback_spawn.name = "FallingBlocksFallbackSpawn"
		_fallback_spawn.position = Vector3(0.5, 4.0, 0.5)
		current_scene.add_child(_fallback_spawn)
		teleport_target = _fallback_spawn

func _physics_process(_delta: float) -> void:
	if _active_cubes.is_empty():
		return
	for i in range(_active_cubes.size() - 1, -1, -1):
		var cube: RigidBody3D = _active_cubes[i]
		if not is_instance_valid(cube):
			_active_cubes.remove_at(i)
			continue
		if cube.global_transform.origin.y < cleanup_floor_height:
			_despawn_cube_at_index(i)

func _on_spawn_timer_timeout() -> void:
	_spawn_falling_cube()
	_schedule_next_spawn()

func _start_spawning() -> void:
	var initial_wait: float = start_delay if start_delay > 0.0 else _get_random_interval()
	_spawn_timer.wait_time = max(0.05, initial_wait)
	_spawn_timer.start()

func _schedule_next_spawn() -> void:
	_spawn_timer.wait_time = _get_random_interval()
	_spawn_timer.start()

func _get_random_interval() -> float:
	var min_time: float = max(0.05, min(spawn_interval_range.x, spawn_interval_range.y))
	var max_time: float = max(min_time, max(spawn_interval_range.x, spawn_interval_range.y))
	return min_time if is_equal_approx(min_time, max_time) else _rng.randf_range(min_time, max_time)

func _spawn_falling_cube() -> void:
	if not _active_cubes.is_empty():
		_clear_active_cubes()
	if max_active_cubes > 0 and _active_cubes.size() >= max_active_cubes:
		return
	var cube_body: RigidBody3D = _build_falling_cube_body()
	if cube_body == null:
		push_error("Fallingblocks: Failed to build cube body")
		return
	cube_body.position = spawn_offset + Vector3(0.0, spawn_height, 0.0)
	cube_body.body_entered.connect(_on_cube_body_entered.bind(cube_body))
	add_child(cube_body)
	if randomize_rotation:
		cube_body.rotation.y = _rng.randf_range(0.0, TAU)
	
	# Enable physics interpolation for smooth movement
	cube_body.physics_interpolation_mode = Node3D.PHYSICS_INTERPOLATION_MODE_ON
	
	# Give the cube some initial downward velocity to ensure it falls
	cube_body.linear_velocity = Vector3(0.0, -1.0, 0.0)
	cube_body.angular_velocity = Vector3.ZERO
	
	# Ensure the cube is not sleeping
	cube_body.sleeping = false
	cube_body.can_sleep = false
	
	# Debug information
	print("FallingBlocks: Spawned cube at position: ", cube_body.global_position)
	print("FallingBlocks: Gravity scale: ", cube_body.gravity_scale)
	print("FallingBlocks: Mass: ", cube_body.mass)
	print("FallingBlocks: Initial velocity: ", cube_body.linear_velocity)
	
	_active_cubes.append(cube_body)

func _clear_active_cubes() -> void:
	for i in range(_active_cubes.size() - 1, -1, -1):
		_despawn_cube_at_index(i)

func _build_falling_cube_body() -> RigidBody3D:
	var template: Node3D = CUBE_SCENE.instantiate()
	var rigid := RigidBody3D.new()
	rigid.name = "FallingResetCube"
	rigid.contact_monitor = true
	rigid.max_max_contacts_reported = 8
	rigid.mass = cube_mass
	rigid.linear_damp = linear_damp
	rigid.angular_damp = angular_damp
	rigid.gravity_scale = _calculate_gravity_scale()
	
	# Ensure proper physics setup
	rigid.lock_rotation = false
	rigid.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	rigid.sleeping = false
	rigid.can_sleep = false
	
	# Set collision layers for proper interaction
	rigid.collision_layer = 1  # World layer
	rigid.collision_mask = 1 | 2  # World and player layers
	
	# Get the mesh from the reset cube
	var mesh_instance: MeshInstance3D = template.get_node_or_null("MeshInstance3D")
	if mesh_instance and mesh_instance.mesh:
		var new_mesh_instance: MeshInstance3D = MeshInstance3D.new()
		new_mesh_instance.mesh = mesh_instance.mesh
		new_mesh_instance.material_override = mesh_instance.material_override
		rigid.add_child(new_mesh_instance)
	
	# Get the collision shape from the reset cube's Area3D
	var reset_area: Area3D = template.get_node_or_null("ResetArea")
	if reset_area:
		var collision_shape: CollisionShape3D = reset_area.get_node_or_null("CollisionShape3D")
		if collision_shape and collision_shape.shape:
			var new_collision_shape: CollisionShape3D = CollisionShape3D.new()
			new_collision_shape.shape = collision_shape.shape
			rigid.add_child(new_collision_shape)
	
	# Disable the ResetPlayerController script functionality for falling cubes
	# We'll handle collision detection through the RigidBody3D instead
	var reset_script: Node = template.get_node_or_null("ResetPlayerController")
	if reset_script:
		# Remove the reset functionality by disconnecting signals
		# The reset cube will just be a visual falling object
		pass
	
	# Apply any local transform from the template
	var template_children := template.get_children()
	for child in template_children:
		var node := child as Node
		var node3d := node as Node3D
		var local_transform := node3d.transform if node3d else Transform3D.IDENTITY
		template.remove_child(node)
		rigid.add_child(node)
		if node3d:
			node3d.transform = local_transform
	
	template.queue_free()
	return rigid

func _calculate_gravity_scale() -> float:
	if gravity <= 0.0:
		return 0.0
	var default_gravity_variant: Variant = ProjectSettings.get_setting("physics/3d/default_gravity")
	var default_gravity: float = float(default_gravity_variant) if default_gravity_variant != null else 9.8
	if is_zero_approx(default_gravity):
		return 1.0
	
	# Ensure gravity scale is reasonable (between 0.1 and 10.0)
	var gravity_scale = gravity / default_gravity
	return clamp(gravity_scale, 0.1, 10.0)

func _on_cube_body_entered(body: Node, cube: RigidBody3D) -> void:
	if not is_instance_valid(body) or not is_instance_valid(cube):
		return
	if not _is_player(body):
		return
	_apply_damage_to_player()
	if teleport_on_hit and body is Node3D:
		_teleport_player(body as Node3D)
	var index: int = _active_cubes.find(cube)
	if index != -1:
		_despawn_cube_at_index(index)

func _apply_damage_to_player() -> void:
	if Engine.is_editor_hint():
		return
	if typeof(GameManager) != TYPE_NIL:
		if GameManager.has_method("apply_health_damage"):
			GameManager.apply_health_damage(cube_damage)
		elif GameManager.has_method("set_health") and GameManager.has_method("get_health"):
			GameManager.set_health(GameManager.get_health() - cube_damage)
	else:
		var manager := get_node_or_null("/root/GameManager")
		if manager and manager.has_method("apply_health_damage"):
			manager.apply_health_damage(cube_damage)
		elif manager and manager.has_method("set_health") and manager.has_method("get_health"):
			manager.set_health(manager.get_health() - cube_damage)

func _teleport_player(body: Node3D) -> void:
	if body == null:
		return
	_initialize_teleport_target()
	if teleport_target == null:
		return
	_reset_velocity(body)
	var player_root := _find_player_root(body)
	if player_root and player_root != body:
		_reset_velocity(player_root)
		player_root.global_position = teleport_target.global_position
	else:
		body.global_position = teleport_target.global_position

func _reset_velocity(body: Node3D) -> void:
	if body == null:
		return
	if "velocity" in body:
		body.velocity = Vector3.ZERO
	if "linear_velocity" in body:
		body.linear_velocity = Vector3.ZERO
	if "angular_velocity" in body:
		body.angular_velocity = Vector3.ZERO

func _find_player_root(body: Node3D) -> Node3D:
	var current: Node = body
	while current:
		if current is Node3D:
			var node3d: Node3D = current as Node3D
			var name_lower := node3d.name.to_lower()
			if node3d.is_in_group("player") or node3d.is_in_group("player_body") or name_lower.find("xrorigin") != -1:
				return node3d
		current = current.get_parent()
	return body

func _despawn_cube_at_index(index: int) -> void:
	var cube: RigidBody3D = _active_cubes[index]
	_active_cubes.remove_at(index)
	if is_instance_valid(cube):
		cube.queue_free()

func _is_player(body: Object) -> bool:
	if body == null:
		return false
	var name_lower := String(body.name).to_lower()
	if body.has_method("is_in_group"):
		if body.is_in_group("player") or body.is_in_group("vr_player") or body.is_in_group("player_body"):
			return true
	return name_lower.find("player") != -1 or name_lower.find("xrorigin") != -1
