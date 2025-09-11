# BlockBuilderEntity.gd
# AI entity that builds blocks in the player's path to obstruct movement
extends CharacterBody3D
class_name BlockBuilderEntity

# AI behavior settings
@export var detection_range: float = 15.0
@export var build_range: float = 8.0
@export var movement_speed: float = 3.0
@export var build_interval: float = 2.0
@export var max_blocks: int = 20
@export var block_lifetime: float = 30.0

# Prediction settings
@export var predict_player_movement: bool = true
@export var prediction_time: float = 2.0
@export var build_ahead_distance: float = 5.0

# Block properties
@export var block_health: float = 50.0
@export var block_size: Vector3 = Vector3(1, 1, 1)
@export var block_material_color: Color = Color(0.8, 0.3, 0.1, 1.0)  # Orange

# Entity appearance
@export var entity_color: Color = Color(0.2, 0.8, 0.2, 1.0)  # Green
@export var entity_size: float = 0.8

# Internal state
var player_node: Node3D
var built_blocks: Array = []
var build_timer: float = 0.0
var current_target_position: Vector3
var last_player_position: Vector3
var player_velocity: Vector3

# AI state machine
enum AIState {
	SEEKING_PLAYER,
	POSITIONING,
	BUILDING,
	RETREATING
}

var current_state: AIState = AIState.SEEKING_PLAYER
var state_timer: float = 0.0

# Components
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var detection_area: Area3D
var navigation_agent: NavigationAgent3D

signal block_built(position: Vector3)
signal player_path_blocked(block_count: int)
signal entity_destroyed()

func _ready():
	# Setup entity mesh
	_create_entity_mesh()
	
	# Setup collision
	_setup_collision()
	
	# Setup detection area
	_setup_detection_area()
	
	# Setup navigation
	_setup_navigation()
	
	# Find player
	_find_player()
	
	print("BlockBuilderEntity: AI block builder initialized")

func _create_entity_mesh():
	mesh_instance = MeshInstance3D.new()
	
	# Create robot-like appearance
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(entity_size, entity_size * 1.2, entity_size)
	mesh_instance.mesh = box_mesh
	
	# Create entity material
	var entity_material = StandardMaterial3D.new()
	entity_material.albedo_color = entity_color
	entity_material.emission_enabled = true
	entity_material.emission = entity_color * 0.3
	entity_material.emission_energy = 1.0
	entity_material.metallic = 0.7
	entity_material.roughness = 0.3
	mesh_instance.material_override = entity_material
	
	add_child(mesh_instance)
	
	# Add "eyes" or sensors
	_create_entity_details()

func _create_entity_details():
	# Create sensor "eyes"
	for i in range(2):
		var eye = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.1
		sphere_mesh.height = 0.2
		eye.mesh = sphere_mesh
		
		var eye_material = StandardMaterial3D.new()
		eye_material.albedo_color = Color.RED
		eye_material.emission_enabled = true
		eye_material.emission = Color.RED
		eye_material.emission_energy = 2.0
		eye.material_override = eye_material
		
		var x_offset = 0.2 if i == 0 else -0.2
		eye.position = Vector3(x_offset, 0.3, 0.4)
		mesh_instance.add_child(eye)

func _setup_collision():
	collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(entity_size, entity_size * 1.2, entity_size)
	collision_shape.shape = box_shape
	add_child(collision_shape)

func _setup_detection_area():
	detection_area = Area3D.new()
	detection_area.monitoring = true
	detection_area.body_entered.connect(_on_detection_area_entered)
	detection_area.body_exited.connect(_on_detection_area_exited)
	
	var detection_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = detection_range
	detection_shape.shape = sphere_shape
	detection_area.add_child(detection_shape)
	
	add_child(detection_area)

func _setup_navigation():
	navigation_agent = NavigationAgent3D.new()
	navigation_agent.path_desired_distance = 1.0
	navigation_agent.target_desired_distance = 1.0
	add_child(navigation_agent)

func _find_player():
	player_node = get_tree().get_first_node_in_group("player")
	if not player_node:
		player_node = get_tree().current_scene.find_child("*Player*", true, false)
	if not player_node:
		_search_for_player(get_tree().current_scene)
	
	if player_node:
		print("BlockBuilderEntity: Found player: ", player_node.name)
		last_player_position = player_node.global_position
	else:
		print("BlockBuilderEntity: Warning - No player found")

func _search_for_player(node: Node):
	if "player" in node.name.to_lower():
		player_node = node
		return
	for child in node.get_children():
		_search_for_player(child)
		if player_node:
			return

func _physics_process(delta):
	build_timer += delta
	state_timer += delta
	
	if player_node:
		_update_player_tracking(delta)
		_update_ai_state(delta)
		_update_movement(delta)
	
	# Clean up old blocks
	_cleanup_old_blocks()

func _update_player_tracking(delta):
	var current_player_pos = player_node.global_position
	player_velocity = (current_player_pos - last_player_position) / delta
	last_player_position = current_player_pos

func _update_ai_state(delta):
	match current_state:
		AIState.SEEKING_PLAYER:
			_update_seeking_state()
		AIState.POSITIONING:
			_update_positioning_state()
		AIState.BUILDING:
			_update_building_state(delta)
		AIState.RETREATING:
			_update_retreating_state()

func _update_seeking_state():
	if not player_node:
		return
	
	var distance_to_player = global_position.distance_to(player_node.global_position)
	
	if distance_to_player <= detection_range:
		_change_state(AIState.POSITIONING)
		current_target_position = _calculate_optimal_build_position()

func _update_positioning_state():
	var distance_to_target = global_position.distance_to(current_target_position)
	
	if distance_to_target <= 2.0:  # Close enough to build
		_change_state(AIState.BUILDING)
	elif state_timer > 10.0:  # Don't position for too long
		_change_state(AIState.SEEKING_PLAYER)

func _update_building_state(delta):
	if build_timer >= build_interval and built_blocks.size() < max_blocks:
		_attempt_build_block()
		build_timer = 0.0
	
	# Check if should retreat or reposition
	if built_blocks.size() >= max_blocks:
		_change_state(AIState.RETREATING)
	elif state_timer > 15.0:  # Don't build for too long in one spot
		_change_state(AIState.POSITIONING)
		current_target_position = _calculate_optimal_build_position()

func _update_retreating_state():
	if state_timer > 5.0:  # Retreat for a while
		_change_state(AIState.SEEKING_PLAYER)

func _update_movement(delta):
	if not navigation_agent:
		return
	
	var target_pos = Vector3.ZERO
	
	match current_state:
		AIState.SEEKING_PLAYER:
			if player_node:
				target_pos = player_node.global_position
		AIState.POSITIONING:
			target_pos = current_target_position
		AIState.BUILDING:
			# Stay in place while building
			return
		AIState.RETREATING:
			if player_node:
				# Move away from player
				var direction = (global_position - player_node.global_position).normalized()
				target_pos = global_position + direction * 10.0
	
	navigation_agent.target_position = target_pos
	
	if navigation_agent.is_navigation_finished():
		return
	
	var next_location = navigation_agent.get_next_path_position()
	var direction = (next_location - global_position).normalized()
	
	velocity = direction * movement_speed
	move_and_slide()
	
	# Face movement direction
	if direction.length() > 0.1:
		look_at(global_position + direction, Vector3.UP)

func _calculate_optimal_build_position() -> Vector3:
	if not player_node:
		return global_position
	
	var player_pos = player_node.global_position
	var build_position = player_pos
	
	if predict_player_movement and player_velocity.length() > 0.1:
		# Predict where player will be
		var predicted_pos = player_pos + player_velocity * prediction_time
		build_position = predicted_pos + player_velocity.normalized() * build_ahead_distance
	else:
		# Build ahead of player in their facing direction
		var player_forward = Vector3.FORWARD
		if player_node.has_method("get_forward_direction"):
			player_forward = player_node.get_forward_direction()
		elif player_node.has_property("transform"):
			player_forward = -player_node.transform.basis.z
		
		build_position = player_pos + player_forward * build_ahead_distance
	
	# Stay within build range
	var direction_to_build = (build_position - global_position).normalized()
	var max_distance = build_range * 0.8  # Stay a bit closer
	if global_position.distance_to(build_position) > max_distance:
		build_position = global_position + direction_to_build * max_distance
	
	return build_position

func _attempt_build_block():
	if not player_node:
		return
	
	var build_position = _find_best_block_position()
	if build_position != Vector3.ZERO:
		_create_block(build_position)

func _find_best_block_position() -> Vector3:
	if not player_node:
		return Vector3.ZERO
	
	var player_pos = player_node.global_position
	var candidate_positions = []
	
	# Generate candidate positions around predicted player path
	for i in range(5):
		var ahead_distance = float(i + 1) * 2.0
		var predicted_pos = player_pos
		
		if predict_player_movement and player_velocity.length() > 0.1:
			predicted_pos = player_pos + player_velocity.normalized() * ahead_distance
		else:
			var forward = Vector3.FORWARD
			if player_node.has_property("transform"):
				forward = -player_node.transform.basis.z
			predicted_pos = player_pos + forward * ahead_distance
		
		# Snap to grid
		predicted_pos.x = round(predicted_pos.x)
		predicted_pos.y = round(predicted_pos.y)
		predicted_pos.z = round(predicted_pos.z)
		
		# Check if position is valid
		if _is_valid_build_position(predicted_pos):
			candidate_positions.append(predicted_pos)
	
	# Return closest valid position within build range
	for pos in candidate_positions:
		if global_position.distance_to(pos) <= build_range:
			return pos
	
	return Vector3.ZERO

func _is_valid_build_position(pos: Vector3) -> bool:
	# Check if there's already a block here
	for block in built_blocks:
		if is_instance_valid(block.rigid_body) and block.rigid_body.global_position.distance_to(pos) < 1.5:
			return false
	
	# Check if position is too close to entity
	if global_position.distance_to(pos) < 2.0:
		return false
	
	# Could add more checks here (terrain, other obstacles, etc.)
	return true

func _create_block(position: Vector3):
	var block_data = _create_block_data()
	block_data.rigid_body.global_position = position
	
	add_child(block_data.rigid_body)
	built_blocks.append(block_data)
	
	emit_signal("block_built", position)
	print("BlockBuilderEntity: Built block at ", position)
	
	# Check if player path is significantly blocked
	if built_blocks.size() % 5 == 0:  # Every 5 blocks
		emit_signal("player_path_blocked", built_blocks.size())

func _create_block_data() -> Dictionary:
	var block_rigid_body = RigidBody3D.new()
	block_rigid_body.freeze = true  # Make it static
	
	# Create block mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = block_size
	mesh_instance.mesh = box_mesh
	
	# Create block material
	var block_material = StandardMaterial3D.new()
	block_material.albedo_color = block_material_color
	block_material.metallic = 0.3
	block_material.roughness = 0.7
	block_material.emission_enabled = true
	block_material.emission = block_material_color * 0.2
	block_material.emission_energy = 0.5
	mesh_instance.material_override = block_material
	
	block_rigid_body.add_child(mesh_instance)
	
	# Create collision
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = block_size
	collision_shape.shape = box_shape
	block_rigid_body.add_child(collision_shape)
	
	# Add health system to block
	var block_health_component = _create_block_health_component(block_rigid_body)
	
	return {
		"rigid_body": block_rigid_body,
		"health": block_health,
		"creation_time": Time.get_time_dict_from_system(),
		"health_component": block_health_component
	}

func _create_block_health_component(block_rigid_body: RigidBody3D) -> Node:
	var health_component = Node.new()
	health_component.name = "BlockHealth"
	health_component.set_script(GDScript.new())
	
	# Add damage method to block
	var script_code = """
extends Node

var health: float = %f
var block_entity: Node
var rigid_body: RigidBody3D

func _ready():
	block_entity = get_tree().get_first_node_in_group('block_builder')
	rigid_body = get_parent()

func take_damage(amount: float):
	health -= amount
	print('Block took ', amount, ' damage. Health: ', health)
	
	if health <= 0:
		destroy_block()

func destroy_block():
	if block_entity and block_entity.has_method('remove_block'):
		block_entity.remove_block(rigid_body)
	else:
		rigid_body.queue_free()
""" % block_health
	
	health_component.get_script().source_code = script_code
	block_rigid_body.add_child(health_component)
	
	return health_component

func _cleanup_old_blocks():
	var blocks_to_remove = []
	var current_time = Time.get_time_dict_from_system()
	
	for i in range(built_blocks.size()):
		var block = built_blocks[i]
		if not is_instance_valid(block.rigid_body):
			blocks_to_remove.append(i)
			continue
		
		# Check lifetime
		var creation_time = block.creation_time
		var age = (current_time.hour * 3600 + current_time.minute * 60 + current_time.second) - \
				  (creation_time.hour * 3600 + creation_time.minute * 60 + creation_time.second)
		
		if age >= block_lifetime:
			blocks_to_remove.append(i)
			block.rigid_body.queue_free()
	
	# Remove from array (in reverse order to maintain indices)
	for i in range(blocks_to_remove.size() - 1, -1, -1):
		built_blocks.remove_at(blocks_to_remove[i])

func _change_state(new_state: AIState):
	current_state = new_state
	state_timer = 0.0
	print("BlockBuilderEntity: State changed to ", AIState.keys()[new_state])

func _on_detection_area_entered(body):
	if body == player_node and current_state == AIState.SEEKING_PLAYER:
		print("BlockBuilderEntity: Player detected!")
		_change_state(AIState.POSITIONING)

func _on_detection_area_exited(body):
	if body == player_node:
		print("BlockBuilderEntity: Player lost!")

# Public API
func remove_block(block_rigid_body: RigidBody3D):
	for i in range(built_blocks.size()):
		if built_blocks[i].rigid_body == block_rigid_body:
			built_blocks.remove_at(i)
			block_rigid_body.queue_free()
			break

func set_aggressiveness(level: float):
	# 0.0 = passive, 1.0 = very aggressive
	build_interval = max(0.5, 2.0 - level * 1.5)
	max_blocks = int(10 + level * 20)
	movement_speed = 2.0 + level * 3.0

func destroy_entity():
	# Clean up all blocks
	for block in built_blocks:
		if is_instance_valid(block.rigid_body):
			block.rigid_body.queue_free()
	
	emit_signal("entity_destroyed")
	queue_free()

func get_ai_state() -> String:
	return AIState.keys()[current_state]

func get_block_count() -> int:
	return built_blocks.size()
