# FallingBlocksHazard.gd
# Spawns falling blocks that damage the player on contact
extends Node3D
class_name FallingBlocksHazard

# Block configuration
@export var block_damage: float = 20.0
@export var block_count: int = 5
@export var spawn_interval: float = 2.0
@export var block_lifetime: float = 15.0
@export var warning_time: float = 1.5  # Time to show warning before block falls

# Spawn area configuration
@export var spawn_area_size: Vector3 = Vector3(20, 0, 20)
@export var spawn_height: float = 15.0
@export var player_proximity_spawn: bool = true  # Spawn near player
@export var proximity_distance: float = 8.0

# Block physics
@export var block_scale_min: float = 0.8
@export var block_scale_max: float = 2.0
@export var fall_speed_multiplier: float = 1.5

# Visual settings
@export var warning_material_color: Color = Color.RED
@export var block_material_color: Color = Color(0.5, 0.3, 0.2, 1.0)  # Brown
@export var show_warning_indicator: bool = true

# Audio
@export var warning_sound: AudioStream
@export var impact_sound: AudioStream
@export var falling_sound: AudioStream

# Internal tracking
var spawn_timer: float = 0.0
var active_blocks: Array = []
var player_node: Node3D
var warning_indicators: Array = []

signal block_spawned(block_position: Vector3)
signal block_hit_player(damage: float)
signal block_destroyed(block_position: Vector3)

class FallingBlock:
	var rigid_body: RigidBody3D
	var warning_indicator: MeshInstance3D
	var spawn_position: Vector3
	var target_position: Vector3
	var warning_timer: float = 0.0
	var is_falling: bool = false
	var audio_player: AudioStreamPlayer3D
	var age: float = 0.0
	
	func _init(spawn_pos: Vector3, target_pos: Vector3, warning_time: float):
		spawn_position = spawn_pos
		target_position = target_pos
		warning_timer = warning_time

func _ready():
	# Find player node
	_find_player()
	
	print("FallingBlocksHazard: Initialized with ", block_count, " max blocks")
	print("Spawn area: ", spawn_area_size, " at height: ", spawn_height)

func _find_player():
	# Try multiple ways to find the player
	player_node = get_tree().get_first_node_in_group("player")
	if not player_node:
		player_node = get_tree().current_scene.find_child("*Player*", true, false)
	if not player_node:
		# Look for nodes with "player" in the name
		_search_for_player(get_tree().current_scene)
	
	if player_node:
		print("FallingBlocksHazard: Found player node: ", player_node.name)
	else:
		print("FallingBlocksHazard: Warning - No player node found")

func _search_for_player(node: Node):
	if "player" in node.name.to_lower():
		player_node = node
		return
	
	for child in node.get_children():
		_search_for_player(child)
		if player_node:
			return

func _process(delta):
	spawn_timer += delta
	
	# Spawn new blocks
	if spawn_timer >= spawn_interval and active_blocks.size() < block_count:
		_spawn_falling_block()
		spawn_timer = 0.0
	
	# Update existing blocks
	_update_active_blocks(delta)

func _update_active_blocks(delta):
	var blocks_to_remove = []
	
	for i in range(active_blocks.size()):
		var block = active_blocks[i]
		block.age += delta
		
		# Check for lifetime expiration
		if block.age >= block_lifetime:
			blocks_to_remove.append(i)
			continue
		
		# Update warning phase
		if not block.is_falling:
			block.warning_timer -= delta
			
			# Update warning indicator pulse
			if block.warning_indicator and is_instance_valid(block.warning_indicator):
				var pulse_intensity = 0.5 + 0.5 * sin(block.age * 10.0)
				var warning_material = block.warning_indicator.get_surface_override_material(0)
				if warning_material:
					warning_material.emission_energy = 2.0 + pulse_intensity * 2.0
			
			# Start falling when warning time is up
			if block.warning_timer <= 0.0:
				_start_block_falling(block)
	
	# Remove expired blocks
	for i in range(blocks_to_remove.size() - 1, -1, -1):
		var idx = blocks_to_remove[i]
		_destroy_block(active_blocks[idx])
		active_blocks.remove_at(idx)

func _spawn_falling_block():
	var spawn_position = _get_spawn_position()
	var target_position = _get_target_position()
	
	var block = FallingBlock.new(spawn_position, target_position, warning_time)
	
	# Create warning indicator first
	if show_warning_indicator:
		_create_warning_indicator(block)
	
	# Play warning sound
	if warning_sound:
		_play_sound_at_position(warning_sound, target_position)
	
	active_blocks.append(block)
	emit_signal("block_spawned", spawn_position)
	
	print("Spawned falling block at: ", spawn_position, " targeting: ", target_position)

func _get_spawn_position() -> Vector3:
	var base_position = global_position
	
	if player_proximity_spawn and player_node:
		# Spawn near player
		var player_pos = player_node.global_position
		var random_offset = Vector3(
			randf_range(-proximity_distance, proximity_distance),
			0,
			randf_range(-proximity_distance, proximity_distance)
		)
		base_position = player_pos + random_offset
	else:
		# Random position in spawn area
		var random_offset = Vector3(
			randf_range(-spawn_area_size.x * 0.5, spawn_area_size.x * 0.5),
			0,
			randf_range(-spawn_area_size.z * 0.5, spawn_area_size.z * 0.5)
		)
		base_position += random_offset
	
	base_position.y = global_position.y + spawn_height
	return base_position

func _get_target_position() -> Vector3:
	var spawn_pos = _get_spawn_position()
	return Vector3(spawn_pos.x, global_position.y, spawn_pos.z)

func _create_warning_indicator(block: FallingBlock):
	block.warning_indicator = MeshInstance3D.new()
	
	# Create warning mesh (glowing cylinder)
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 1.0
	cylinder_mesh.bottom_radius = 1.2
	cylinder_mesh.height = 0.1
	block.warning_indicator.mesh = cylinder_mesh
	
	# Create warning material
	var warning_material = StandardMaterial3D.new()
	warning_material.albedo_color = warning_material_color
	warning_material.emission_enabled = true
	warning_material.emission = warning_material_color
	warning_material.emission_energy = 2.0
	warning_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	warning_material.albedo_color.a = 0.7
	block.warning_indicator.material_override = warning_material
	
	# Position at target location
	block.warning_indicator.global_position = block.target_position
	add_child(block.warning_indicator)

func _start_block_falling(block: FallingBlock):
	if block.is_falling:
		return
	
	block.is_falling = true
	
	# Hide warning indicator
	if block.warning_indicator and is_instance_valid(block.warning_indicator):
		block.warning_indicator.queue_free()
		block.warning_indicator = null
	
	# Create the actual falling block
	_create_falling_rigid_body(block)
	
	print("Block started falling from: ", block.spawn_position)

func _create_falling_rigid_body(block: FallingBlock):
	block.rigid_body = RigidBody3D.new()
	block.rigid_body.global_position = block.spawn_position
	
	# Create block mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	var scale_factor = randf_range(block_scale_min, block_scale_max)
	box_mesh.size = Vector3(scale_factor, scale_factor, scale_factor)
	mesh_instance.mesh = box_mesh
	
	# Create block material
	var block_material = StandardMaterial3D.new()
	block_material.albedo_color = block_material_color
	block_material.metallic = 0.1
	block_material.roughness = 0.8
	mesh_instance.material_override = block_material
	block.rigid_body.add_child(mesh_instance)
	
	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = box_mesh.size
	collision_shape.shape = box_shape
	block.rigid_body.add_child(collision_shape)
	
	# Setup physics
	block.rigid_body.mass = scale_factor * 2.0  # Heavier blocks
	block.rigid_body.gravity_scale = fall_speed_multiplier
	
	# Setup collision detection
	block.rigid_body.contact_monitor = true
	block.rigid_body.max_contacts_reported = 10
	block.rigid_body.body_entered.connect(_on_block_collision.bind(block))
	
	# Set collision layers
	block.rigid_body.collision_layer = 16  # Hazard layer
	block.rigid_body.collision_mask = 1 | 2  # World and player
	
	# Add to scene
	add_child(block.rigid_body)
	
	# Play falling sound
	if falling_sound:
		block.audio_player = AudioStreamPlayer3D.new()
		block.audio_player.stream = falling_sound
		block.audio_player.playing = true
		block.rigid_body.add_child(block.audio_player)

func _on_block_collision(body, block: FallingBlock):
	print("Falling block hit: ", body.name)
	
	# Check if it hit the player
	if _is_player(body):
		_damage_player(body, block)
	
	# Play impact sound
	if impact_sound:
		_play_sound_at_position(impact_sound, block.rigid_body.global_position)
	
	# Remove the block after collision
	call_deferred("_destroy_block", block)

func _is_player(body) -> bool:
	return (body == player_node or 
			"player" in body.name.to_lower() or 
			body.is_in_group("player"))

func _damage_player(player_body, block: FallingBlock):
	var damage_dealt = block_damage
	
	# Try different damage methods
	if player_body.has_method("take_damage"):
		player_body.take_damage(damage_dealt)
	elif player_body.has_method("apply_health_damage"):
		player_body.apply_health_damage(damage_dealt)
	elif player_body.has_method("damage_player"):
		player_body.damage_player(damage_dealt)
	elif player_body.has_signal("health_changed"):
		player_body.emit_signal("health_changed", -damage_dealt)
	
	emit_signal("block_hit_player", damage_dealt)
	print("Falling block dealt ", damage_dealt, " damage to player!")

func _destroy_block(block: FallingBlock):
	if not block:
		return
	
	var position = Vector3.ZERO
	
	# Clean up warning indicator
	if block.warning_indicator and is_instance_valid(block.warning_indicator):
		position = block.warning_indicator.global_position
		block.warning_indicator.queue_free()
	
	# Clean up rigid body
	if block.rigid_body and is_instance_valid(block.rigid_body):
		position = block.rigid_body.global_position
		block.rigid_body.queue_free()
	
	emit_signal("block_destroyed", position)

func _play_sound_at_position(sound: AudioStream, position: Vector3):
	var audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = sound
	audio_player.global_position = position
	add_child(audio_player)
	audio_player.play()
	
	# Remove after playing
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 5.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(audio_player.queue_free)
	add_child(cleanup_timer)
	cleanup_timer.start()

# Public API
func set_spawn_rate(new_interval: float):
	spawn_interval = new_interval

func set_damage(new_damage: float):
	block_damage = new_damage

func start_hazard():
	set_process(true)

func stop_hazard():
	set_process(false)
	
	# Clean up all active blocks
	for block in active_blocks:
		_destroy_block(block)
	active_blocks.clear()

func get_active_block_count() -> int:
	return active_blocks.size()
