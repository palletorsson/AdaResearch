# DecoupledTileEffectManager.gd
# Completely decoupled tile effect system that can work with any scene's tiles
# Automatically detects and applies effects to existing tiles without creating new ones

extends Node3D
class_name DecoupledTileEffectManager

# Configuration
@export_group("Effect Settings")
@export var tile_detection_mode: String = "auto"  # auto, grid_pattern, tag_based, collision_based
@export var reveal_speed: float = 2.0
@export var disco_speed: float = 3.0
@export var effect_intensity: float = 1.0
@export var player_detection_height: float = 0.5  # How high above tiles to detect player

@export_group("Player Detection")
@export var enable_step_triggers: bool = true
@export var step_trigger_radius: float = 0.8
@export var step_trigger_cooldown: float = 0.5

# Tile detection and management
var detected_tiles: Array[DetectedTile] = []
var tile_grid_bounds: AABB
var grid_dimensions: Vector3i
var tile_size: float = 1.0

# Effect states
enum EffectType {
	NONE,
	REVEAL,
	DISCO,
	WAVE,
	PULSE,
	SEQUENCE_REVEAL
}

var current_effect: EffectType = EffectType.NONE
var effect_start_time: float = 0.0
var effect_center: Vector3 = Vector3.ZERO
var effect_radius: float = 0.0

# Player tracking
var player_body: CharacterBody3D
var player_position: Vector3
var last_trigger_time: float = 0.0
var last_trigger_position: Vector3

# Detected tile data structure
class DetectedTile:
	var node: Node3D
	var mesh_instance: MeshInstance3D
	var original_material: Material
	var effect_material: ShaderMaterial
	var world_position: Vector3
	var grid_position: Vector3i
	var is_revealed: bool = false
	var effect_progress: float = 0.0
	var trigger_area: Area3D  # For step detection
	
	func _init(tile_node: Node3D, mesh: MeshInstance3D):
		node = tile_node
		mesh_instance = mesh
		world_position = tile_node.global_position
		original_material = mesh.material_override if mesh.material_override else mesh.get_surface_override_material(0)

# Signals
signal tile_stepped_on(tile: DetectedTile, player_body: Node3D)
signal effect_started(effect_type: EffectType, center: Vector3)
signal effect_completed(effect_type: EffectType)

func _ready():
	print("DecoupledTileEffectManager: Initializing decoupled tile effect system")
	
	# Wait a moment for scene to fully load
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Start tile detection
	_detect_scene_tiles()
	
	# Find player
	_find_player()
	
	# Setup step detection if enabled
	if enable_step_triggers:
		_setup_step_detection()

func _detect_scene_tiles():
	"""Automatically detect all tiles in the scene"""
	print("DecoupledTileEffectManager: Detecting tiles in scene using mode: %s" % tile_detection_mode)
	
	match tile_detection_mode:
		"auto":
			_auto_detect_tiles()
		"grid_pattern":
			_detect_grid_pattern_tiles()
		"tag_based":
			_detect_tagged_tiles()
		"collision_based":
			_detect_collision_tiles()
		_:
			_auto_detect_tiles()
	
	print("DecoupledTileEffectManager: Detected %d tiles" % detected_tiles.size())
	
	if detected_tiles.size() > 0:
		_calculate_grid_bounds()
		_setup_effect_materials()

func _auto_detect_tiles():
	"""Automatically detect tiles using multiple heuristics"""
	var root_node = get_tree().current_scene
	
	# Look for common tile patterns
	_scan_for_tiles(root_node, [
		"cube", "tile", "floor", "platform", "grid",  # Common tile names
		"CubeBase", "StaticBody3D", "RigidBody3D"     # Common tile types
	])

func _scan_for_tiles(node: Node, keywords: Array[String]):
	"""Recursively scan for tiles based on keywords"""
	# Check if this node looks like a tile
	if _is_potential_tile(node, keywords):
		var mesh_instance = _find_mesh_instance(node)
		if mesh_instance:
			var detected_tile = DetectedTile.new(node, mesh_instance)
			detected_tiles.append(detected_tile)
			print("  Found tile: %s at %s" % [node.name, node.global_position])
	
	# Scan children
	for child in node.get_children():
		_scan_for_tiles(child, keywords)

func _is_potential_tile(node: Node, keywords: Array[String]) -> bool:
	"""Check if a node looks like a tile"""
	var name_lower = node.name.to_lower()
	
	# Check for keyword matches
	for keyword in keywords:
		if keyword.to_lower() in name_lower:
			# Additional validation - must have mesh and be reasonably tile-sized
			var mesh = _find_mesh_instance(node)
			if mesh and _is_reasonable_tile_size(mesh):
				return true
	
	return false

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	"""Find MeshInstance3D in node or its children"""
	if node is MeshInstance3D:
		return node as MeshInstance3D
	
	for child in node.get_children():
		if child is MeshInstance3D:
			return child as MeshInstance3D
		var found = _find_mesh_instance(child)
		if found:
			return found
	
	return null

func _is_reasonable_tile_size(mesh_instance: MeshInstance3D) -> bool:
	"""Check if mesh is a reasonable size for a tile"""
	if not mesh_instance.mesh:
		return false
	
	var aabb = mesh_instance.mesh.get_aabb()
	var size = aabb.size
	
	# Reasonable tile sizes (between 0.1 and 10 units)
	return (size.x > 0.1 and size.x < 10.0 and 
	        size.z > 0.1 and size.z < 10.0 and
	        size.y > 0.01)  # Allow thin tiles

func _detect_grid_pattern_tiles():
	"""Detect tiles arranged in a grid pattern"""
	# This would analyze positioning to find grid-arranged tiles
	print("DecoupledTileEffectManager: Grid pattern detection not yet implemented")
	_auto_detect_tiles()  # Fallback

func _detect_tagged_tiles():
	"""Detect tiles based on groups/tags"""
	var tagged_nodes = get_tree().get_nodes_in_group("tiles")
	for node in tagged_nodes:
		var mesh_instance = _find_mesh_instance(node)
		if mesh_instance:
			var detected_tile = DetectedTile.new(node, mesh_instance)
			detected_tiles.append(detected_tile)

func _detect_collision_tiles():
	"""Detect tiles based on collision shapes"""
	print("DecoupledTileEffectManager: Collision-based detection not yet implemented")
	_auto_detect_tiles()  # Fallback

func _calculate_grid_bounds():
	"""Calculate the bounds and grid structure of detected tiles"""
	if detected_tiles.is_empty():
		return
	
	var min_pos = detected_tiles[0].world_position
	var max_pos = detected_tiles[0].world_position
	
	# Find bounds
	for tile in detected_tiles:
		var pos = tile.world_position
		min_pos = Vector3(min(min_pos.x, pos.x), min(min_pos.y, pos.y), min(min_pos.z, pos.z))
		max_pos = Vector3(max(max_pos.x, pos.x), max(max_pos.y, pos.y), max(max_pos.z, pos.z))
	
	tile_grid_bounds = AABB(min_pos, max_pos - min_pos)
	
	# Estimate tile size (use most common spacing)
	var spacings: Array[float] = []
	for i in range(min(detected_tiles.size(), 10)):  # Sample first 10 tiles
		for j in range(i + 1, min(detected_tiles.size(), 10)):
			var distance = detected_tiles[i].world_position.distance_to(detected_tiles[j].world_position)
			if distance > 0.1:  # Ignore very close tiles
				spacings.append(distance)
	
	if spacings.size() > 0:
		spacings.sort()
		tile_size = spacings[spacings.size() / 2]  # Use median spacing
	
	# Assign grid positions
	for tile in detected_tiles:
		tile.grid_position = _world_to_grid_position(tile.world_position)
	
	print("DecoupledTileEffectManager: Grid bounds: %s, tile size: %f" % [tile_grid_bounds, tile_size])

func _world_to_grid_position(world_pos: Vector3) -> Vector3i:
	"""Convert world position to grid coordinates"""
	var relative_pos = world_pos - tile_grid_bounds.position
	return Vector3i(
		round(relative_pos.x / tile_size),
		round(relative_pos.y / tile_size),
		round(relative_pos.z / tile_size)
	)

func _setup_effect_materials():
	"""Create effect materials for all detected tiles"""
	var effect_shader = _create_effect_shader()
	
	for tile in detected_tiles:
		# Create effect material
		tile.effect_material = ShaderMaterial.new()
		tile.effect_material.shader = effect_shader
		
		# Copy properties from original material if it exists
		if tile.original_material:
			_copy_material_properties(tile.original_material, tile.effect_material)
		else:
			# Set default properties
			tile.effect_material.set_shader_parameter("base_color", Color.WHITE)
		
		# Set initial effect parameters
		tile.effect_material.set_shader_parameter("effect_intensity", 0.0)
		tile.effect_material.set_shader_parameter("reveal_alpha", 1.0)

func _create_effect_shader() -> Shader:
	"""Create the effect shader for tile effects"""
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, blend_mix;

uniform float reveal_alpha : hint_range(0.0, 1.0) = 1.0;
uniform vec4 base_color : source_color = vec4(1.0);
uniform vec4 effect_color : source_color = vec4(1.0, 0.0, 1.0, 1.0);
uniform float effect_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float time_offset : hint_range(0.0, 10.0) = 0.0;
uniform float wave_frequency : hint_range(0.1, 10.0) = 2.0;
uniform float disco_speed : hint_range(0.1, 5.0) = 1.0;

varying vec3 world_position;

void vertex() {
	world_position = VERTEX;
}

void fragment() {
	vec4 final_color = base_color;
	
	// Apply effect color mixing
	if (effect_intensity > 0.0) {
		// Create wave effect based on world position
		float wave = sin(world_position.x * wave_frequency + TIME * disco_speed + time_offset) * 0.5 + 0.5;
		wave *= sin(world_position.z * wave_frequency + TIME * disco_speed + time_offset * 1.3) * 0.5 + 0.5;
		
		vec4 animated_effect = effect_color;
		animated_effect.rgb *= wave;
		
		final_color = mix(base_color, animated_effect, effect_intensity);
	}
	
	final_color.a *= reveal_alpha;
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
}
"""
	return shader

func _copy_material_properties(source: Material, target: ShaderMaterial):
	"""Copy relevant properties from source material to shader material"""
	if source is StandardMaterial3D:
		var std_mat = source as StandardMaterial3D
		target.set_shader_parameter("base_color", std_mat.albedo_color)

func _find_player():
	"""Find the player body in the scene"""
	# Look for common player node patterns
	var potential_players = get_tree().get_nodes_in_group("player")
	if potential_players.size() > 0:
		for node in potential_players:
			if node is CharacterBody3D:
				player_body = node as CharacterBody3D
				break
	
	# Fallback: look for VR origin or player body
	if not player_body:
		var root = get_tree().current_scene
		player_body = _find_node_by_type(root, CharacterBody3D) as CharacterBody3D
	
	if player_body:
		print("DecoupledTileEffectManager: Found player: %s" % player_body.name)
	else:
		print("DecoupledTileEffectManager: No player found, step detection disabled")

func _find_node_by_type(node: Node, type) -> Node:
	"""Find first node of specific type"""
	if node.get_class() == type.get_class() or node is type:
		return node
	
	for child in node.get_children():
		var found = _find_node_by_type(child, type)
		if found:
			return found
	
	return null

func _setup_step_detection():
	"""Setup step-on detection for all tiles"""
	if not enable_step_triggers:
		return
	
	print("DecoupledTileEffectManager: Setting up step detection for %d tiles" % detected_tiles.size())
	
	for tile in detected_tiles:
		_create_step_trigger(tile)

func _create_step_trigger(tile: DetectedTile):
	"""Create step detection area for a tile"""
	var area = Area3D.new()
	area.name = "StepTrigger"
	area.position = Vector3(0, player_detection_height, 0)  # Above the tile
	
	var collision_shape = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.height = player_detection_height * 2
	shape.top_radius = step_trigger_radius
	shape.bottom_radius = step_trigger_radius
	collision_shape.shape = shape
	
	area.add_child(collision_shape)
	tile.node.add_child(area)
	tile.trigger_area = area
	
	# Connect signals
	area.body_entered.connect(_on_tile_stepped.bind(tile))

func _on_tile_stepped(tile: DetectedTile, body: Node3D):
	"""Handle player stepping on a tile"""
	if not _is_player_body(body):
		return
	
	# Check cooldown
	var current_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	if current_time - last_trigger_time < step_trigger_cooldown:
		return
	
	# Check if player moved significantly
	if tile.world_position.distance_to(last_trigger_position) < tile_size * 0.5:
		return
	
	last_trigger_time = current_time
	last_trigger_position = tile.world_position
	
	print("DecoupledTileEffectManager: Player stepped on tile at %s" % tile.world_position)
	
	# Emit signal
	tile_stepped_on.emit(tile, body)
	
	# Trigger effect based on current mode
	_trigger_effect_at_position(tile.world_position)

func _is_player_body(body: Node3D) -> bool:
	"""Check if body belongs to player"""
	if body == player_body:
		return true
	
	# Check if it's part of player (VR hands, etc.)
	var parent = body.get_parent()
	while parent:
		if parent == player_body:
			return true
		if "player" in parent.name.to_lower() or "xr" in parent.name.to_lower():
			return true
		parent = parent.get_parent()
	
	return false

func _trigger_effect_at_position(world_pos: Vector3):
	"""Trigger effect at specific world position"""
	# Default: start reveal effect from stepped position
	start_reveal_effect(world_pos)

# Public API - Effect Control

func start_reveal_effect(center_position: Vector3 = Vector3.ZERO):
	"""Start reveal effect expanding from center"""
	if center_position == Vector3.ZERO and detected_tiles.size() > 0:
		center_position = detected_tiles[0].world_position
	
	current_effect = EffectType.REVEAL
	effect_center = center_position
	effect_radius = 0.0
	effect_start_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	
	print("DecoupledTileEffectManager: Starting reveal effect at %s" % center_position)
	effect_started.emit(EffectType.REVEAL, center_position)

func start_disco_effect():
	"""Start disco effect on all tiles"""
	current_effect = EffectType.DISCO
	effect_start_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	
	print("DecoupledTileEffectManager: Starting disco effect")
	effect_started.emit(EffectType.DISCO, Vector3.ZERO)

func start_sequence_reveal_effect(center_position: Vector3):
	"""Start sequence reveal effect (reveals tiles in a pattern)"""
	current_effect = EffectType.SEQUENCE_REVEAL
	effect_center = center_position
	effect_radius = 0.0
	effect_start_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	
	print("DecoupledTileEffectManager: Starting sequence reveal effect")
	effect_started.emit(EffectType.SEQUENCE_REVEAL, center_position)

func stop_all_effects():
	"""Stop all current effects"""
	var previous_effect = current_effect
	current_effect = EffectType.NONE
	
	# Reset all tiles
	for tile in detected_tiles:
		if tile.mesh_instance:
			tile.mesh_instance.material_override = tile.original_material
		tile.is_revealed = true
		tile.effect_progress = 0.0
	
	if previous_effect != EffectType.NONE:
		effect_completed.emit(previous_effect)
	
	print("DecoupledTileEffectManager: Stopped all effects")

func reveal_all_tiles():
	"""Instantly reveal all tiles"""
	for tile in detected_tiles:
		tile.is_revealed = true
		if tile.effect_material:
			tile.effect_material.set_shader_parameter("reveal_alpha", 1.0)
			tile.effect_material.set_shader_parameter("effect_intensity", 0.0)
		if tile.mesh_instance:
			tile.mesh_instance.material_override = tile.effect_material

func hide_all_tiles():
	"""Hide all tiles"""
	for tile in detected_tiles:
		tile.is_revealed = false
		if tile.effect_material:
			tile.effect_material.set_shader_parameter("reveal_alpha", 0.0)
		if tile.mesh_instance:
			tile.mesh_instance.material_override = tile.effect_material

func _process(delta):
	if current_effect == EffectType.NONE:
		return
	
	match current_effect:
		EffectType.REVEAL:
			_update_reveal_effect(delta)
		EffectType.DISCO:
			_update_disco_effect(delta)
		EffectType.SEQUENCE_REVEAL:
			_update_sequence_reveal_effect(delta)

func _update_reveal_effect(delta):
	"""Update reveal effect"""
	effect_radius += reveal_speed * delta
	
	var max_distance = tile_grid_bounds.size.length()
	if effect_radius >= max_distance:
		current_effect = EffectType.NONE
		effect_completed.emit(EffectType.REVEAL)
		return
	
	# Update tiles within radius
	for tile in detected_tiles:
		var distance = tile.world_position.distance_to(effect_center)
		
		if distance <= effect_radius and not tile.is_revealed:
			tile.is_revealed = true
			if tile.effect_material:
				tile.effect_material.set_shader_parameter("reveal_alpha", 1.0)
				tile.effect_material.set_shader_parameter("effect_intensity", 0.0)
			if tile.mesh_instance:
				tile.mesh_instance.material_override = tile.effect_material

func _update_disco_effect(delta):
	"""Update disco effect"""
	var time_elapsed = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second - effect_start_time
	
	for tile in detected_tiles:
		if tile.effect_material and tile.mesh_instance:
			# Set disco colors
			var hue = (tile.grid_position.x + tile.grid_position.z + time_elapsed * disco_speed) * 0.1
			var disco_color = Color.from_hsv(fmod(hue, 1.0), 0.8, 1.0)
			
			tile.effect_material.set_shader_parameter("effect_color", disco_color)
			tile.effect_material.set_shader_parameter("effect_intensity", effect_intensity)
			tile.effect_material.set_shader_parameter("reveal_alpha", 1.0)
			tile.effect_material.set_shader_parameter("disco_speed", disco_speed)
			
			tile.mesh_instance.material_override = tile.effect_material

func _update_sequence_reveal_effect(delta):
	"""Update sequence reveal effect - reveals tiles in order"""
	effect_radius += reveal_speed * delta * 0.5  # Slower than regular reveal
	
	# Sort tiles by distance from center
	var sorted_tiles = detected_tiles.duplicate()
	sorted_tiles.sort_custom(func(a, b): return a.world_position.distance_to(effect_center) < b.world_position.distance_to(effect_center))
	
	# Reveal tiles in sequence
	var tiles_to_reveal = int(effect_radius * 2)  # Adjust rate
	for i in range(min(tiles_to_reveal, sorted_tiles.size())):
		var tile = sorted_tiles[i]
		if not tile.is_revealed:
			tile.is_revealed = true
			if tile.effect_material:
				tile.effect_material.set_shader_parameter("reveal_alpha", 1.0)
				tile.effect_material.set_shader_parameter("effect_intensity", 0.2)
				tile.effect_material.set_shader_parameter("effect_color", Color.CYAN)
			if tile.mesh_instance:
				tile.mesh_instance.material_override = tile.effect_material
	
	if tiles_to_reveal >= sorted_tiles.size():
		current_effect = EffectType.NONE
		effect_completed.emit(EffectType.SEQUENCE_REVEAL)

# Utility functions

func get_tile_count() -> int:
	return detected_tiles.size()

func get_tiles_in_radius(center: Vector3, radius: float) -> Array[DetectedTile]:
	var tiles_in_radius: Array[DetectedTile] = []
	for tile in detected_tiles:
		if tile.world_position.distance_to(center) <= radius:
			tiles_in_radius.append(tile)
	return tiles_in_radius

func get_tile_at_position(world_pos: Vector3, tolerance: float = 0.5) -> DetectedTile:
	for tile in detected_tiles:
		if tile.world_position.distance_to(world_pos) <= tolerance:
			return tile
	return null

func is_effect_active() -> bool:
	return current_effect != EffectType.NONE