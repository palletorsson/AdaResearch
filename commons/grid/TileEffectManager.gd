# TileEffectManager.gd
extends Node3D
class_name TileEffectManager

# Configuration
@export var tile_size: float = 1.0
@export var reveal_speed: float = 2.0
@export var disco_speed: float = 3.0
@export var disco_intensity: float = 1.0

# Effect cleanup settings
@export_group("Effect Cleanup")
@export var auto_cleanup_on_complete: bool = true
@export var effect_duration: float = 10.0  # Max duration for timed effects
@export var cleanup_delay: float = 2.0  # Delay before cleanup after effect completes

# Grid reference
var grid_system: GridSystem
var grid_dimensions: Vector3i
var tile_grid: Array = []  # 3D array of tile data

# Effect states
enum EffectType {
	NONE,
	REVEAL,
	DISCO,
	FADE_IN,
	FADE_OUT,
	PULSE,
	WAVE
}

# Tile data structure
class GridTileData:
	var position: Vector3i
	var world_position: Vector3
	var mesh_instance: MeshInstance3D
	var material: ShaderMaterial
	var is_revealed: bool = false
	var effect_type: EffectType = EffectType.NONE
	var effect_progress: float = 0.0
	var base_color: Color = Color.WHITE
	var target_color: Color = Color.WHITE
	var effect_start_time: float = 0.0  # Track when effect started
	
	func _init(pos: Vector3i, world_pos: Vector3):
		position = pos
		world_position = world_pos

# Reveal effect data
var reveal_center: Vector3i
var reveal_radius: float = 0.0
var max_reveal_radius: float = 20.0
var is_revealing: bool = false
var reveal_completed: bool = false

# Disco effect data
var disco_time: float = 0.0
var disco_start_time: float = 0.0
var is_disco_active: bool = false
var disco_colors: Array = [
	Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, 
	Color.MAGENTA, Color.CYAN, Color.ORANGE, Color.PINK
]

# Effect timing and cleanup
var effect_timers: Dictionary = {}  # Track effect completion times
var cleanup_queue: Array = []  # Effects waiting for cleanup

# Shaders
var tile_shader: Shader
var tile_material_template: ShaderMaterial

# Signals for effect completion
signal effect_completed(effect_type: String)
signal tiles_cleaned_up(count: int)

func _ready():
	_setup_shaders()

func _setup_shaders():
	# Create a simple tile shader for effects
	tile_shader = Shader.new()
	tile_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, depth_test_disabled, blend_mix;

uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform vec4 base_color : source_color = vec4(1.0);
uniform vec4 effect_color : source_color = vec4(1.0);
uniform float effect_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float time_offset : hint_range(0.0, 10.0) = 0.0;

void fragment() {
	vec4 final_color = mix(base_color, effect_color, effect_intensity);
	final_color.a *= alpha;
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
}
"""
	
	# Create material template
	tile_material_template = ShaderMaterial.new()
	tile_material_template.shader = tile_shader

func initialize(grid_ref: GridSystem):
	grid_system = grid_ref
	_get_grid_dimensions()
	_create_tile_grid()

func _get_grid_dimensions():
	if grid_system:
		grid_dimensions = Vector3i(
			grid_system.grid_x if grid_system.grid_x > 0 else 10,
			grid_system.grid_y if grid_system.grid_y > 0 else 6,
			grid_system.grid_z if grid_system.grid_z > 0 else 10
		)
	else:
		grid_dimensions = Vector3i(10, 6, 10)
	
	print("TileEffectManager: Grid dimensions set to: ", grid_dimensions)

func _create_tile_grid():
	print("Creating tile grid with dimensions: ", grid_dimensions)
	
	# Clear existing tiles
	_clear_tiles()
	
	# Initialize 3D array
	tile_grid = []
	tile_grid.resize(grid_dimensions.x)
	
	for x in grid_dimensions.x:
		var y_array = []
		y_array.resize(grid_dimensions.y)
		tile_grid[x] = y_array
		
		for y in grid_dimensions.y:
			var z_array = []
			z_array.resize(grid_dimensions.z)
			tile_grid[x][y] = z_array
			
			for z in grid_dimensions.z:
				var grid_pos = Vector3i(x, y, z)
				var world_pos = _grid_to_world_position(grid_pos)
				var tile_data = GridTileData.new(grid_pos, world_pos)
				
				# Create visual representation
				_create_tile_visual(tile_data)
				
				tile_grid[x][y][z] = tile_data

func _create_tile_visual(tile_data: GridTileData):
	# Create mesh instance for the tile
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(tile_size * 0.95, 0.1, tile_size * 0.95)  # Slightly smaller for visual separation
	
	mesh_instance.mesh = box_mesh
	mesh_instance.position = tile_data.world_position
	mesh_instance.position.y -= 0.45  # Place slightly below grid level
	
	# Create material
	var material = tile_material_template.duplicate()
	material.set_shader_parameter("base_color", Color(0.3, 0.3, 0.3, 0.0))  # Start invisible
	material.set_shader_parameter("alpha", 0.0)
	
	mesh_instance.material_override = material
	
	# Store references
	tile_data.mesh_instance = mesh_instance
	tile_data.material = material
	
	add_child(mesh_instance)

func _clear_tiles():
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()

func _grid_to_world_position(grid_pos: Vector3i) -> Vector3:
	if grid_system:
		return grid_system.grid_to_world_position(grid_pos)
	else:
		return Vector3(grid_pos.x * tile_size, grid_pos.y * tile_size, grid_pos.z * tile_size)

# Effect Functions

func start_reveal_effect(center_pos: Vector3i):
	"""Start revealing tiles from a center position outward"""
	print("Starting reveal effect from position: ", center_pos)
	reveal_center = center_pos
	reveal_radius = 0.0
	is_revealing = true
	reveal_completed = false
	
	# Track effect start time
	var current_time = Time.get_time_dict_from_system()
	var start_time = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
	
	# Set all tiles to unrevealed
	for x in grid_dimensions.x:
		for y in grid_dimensions.y:
			for z in grid_dimensions.z:
				var tile = tile_grid[x][y][z]
				tile.is_revealed = false
				tile.effect_type = EffectType.REVEAL
				tile.effect_progress = 0.0
				tile.effect_start_time = start_time
	
	# Schedule cleanup if auto-cleanup is enabled
	if auto_cleanup_on_complete:
		_schedule_effect_cleanup("reveal", max_reveal_radius / reveal_speed + cleanup_delay)

func start_disco_effect():
	"""Start disco effect on all tiles"""
	print("Starting disco effect")
	disco_time = 0.0
	disco_start_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	is_disco_active = true
	
	for x in grid_dimensions.x:
		for y in grid_dimensions.y:
			for z in grid_dimensions.z:
				var tile = tile_grid[x][y][z]
				tile.effect_type = EffectType.DISCO
				tile.is_revealed = true  # Make sure tiles are visible for disco
				tile.effect_start_time = disco_start_time
	
	# Schedule cleanup for disco effect
	if auto_cleanup_on_complete:
		_schedule_effect_cleanup("disco", effect_duration + cleanup_delay)

func stop_all_effects():
	"""Stop all tile effects"""
	print("Stopping all tile effects")
	is_revealing = false
	is_disco_active = false
	
	for x in grid_dimensions.x:
		for y in grid_dimensions.y:
			for z in grid_dimensions.z:
				var tile = tile_grid[x][y][z]
				tile.effect_type = EffectType.NONE
	
	# Clean up immediately when manually stopped
	if auto_cleanup_on_complete:
		_cleanup_all_effect_tiles()

func reveal_all_tiles():
	"""Instantly reveal all tiles"""
	for x in grid_dimensions.x:
		for y in grid_dimensions.y:
			for z in grid_dimensions.z:
				var tile = tile_grid[x][y][z]
				tile.is_revealed = true
				tile.material.set_shader_parameter("alpha", 1.0)
				tile.material.set_shader_parameter("base_color", Color.WHITE)

func hide_all_tiles():
	"""Hide all tiles"""
	for x in grid_dimensions.x:
		for y in grid_dimensions.y:
			for z in grid_dimensions.z:
				var tile = tile_grid[x][y][z]
				tile.is_revealed = false
				tile.material.set_shader_parameter("alpha", 0.0)

func _process(delta):
	_update_reveal_effect(delta)
	_update_disco_effect(delta)
	_update_tile_visuals(delta)
	_process_cleanup_queue(delta)

func _update_reveal_effect(delta):
	if not is_revealing:
		return
	
	reveal_radius += reveal_speed * delta
	
	if reveal_radius > max_reveal_radius:
		is_revealing = false
		reveal_completed = true
		print("Reveal effect completed")
		emit_signal("effect_completed", "reveal")
		return
	
	# Update tiles within reveal radius
	for x in grid_dimensions.x:
		for y in grid_dimensions.y:
			for z in grid_dimensions.z:
				var tile = tile_grid[x][y][z]
				if tile.effect_type != EffectType.REVEAL:
					continue
				
				var distance = tile.position.distance_to(Vector3(reveal_center))
				
				if distance <= reveal_radius and not tile.is_revealed:
					tile.is_revealed = true
					tile.effect_progress = 1.0 - (distance / reveal_radius)  # Closer tiles appear first

func _update_disco_effect(delta):
	if not is_disco_active:
		return
		
	disco_time += delta * disco_speed
	
	# Check if disco effect should end
	var current_time = Time.get_time_dict_from_system()
	var now = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
	if now - disco_start_time > effect_duration:
		is_disco_active = false
		print("Disco effect completed")
		emit_signal("effect_completed", "disco")
		return
	
	for x in grid_dimensions.x:
		for y in grid_dimensions.y:
			for z in grid_dimensions.z:
				var tile = tile_grid[x][y][z]
				if tile.effect_type != EffectType.DISCO:
					continue
				
				# Create wave pattern
				var wave_phase = (x + z) * 0.5 + disco_time
				var color_index = int(wave_phase) % disco_colors.size()
				tile.target_color = disco_colors[color_index]
				tile.effect_progress = (sin(wave_phase * 2.0) + 1.0) * 0.5

func _update_tile_visuals(delta):
	for x in grid_dimensions.x:
		for y in grid_dimensions.y:
			for z in grid_dimensions.z:
				var tile = tile_grid[x][y][z]
				_update_tile_material(tile, delta)

func _update_tile_material(tile: GridTileData, delta):
	if not tile.material:
		return
	
	match tile.effect_type:
		EffectType.REVEAL:
			if tile.is_revealed:
				var target_alpha = 1.0
				var current_alpha = tile.material.get_shader_parameter("alpha")
				var new_alpha = lerp(current_alpha, target_alpha, delta * reveal_speed)
				tile.material.set_shader_parameter("alpha", new_alpha)
				tile.material.set_shader_parameter("base_color", Color.WHITE)
		
		EffectType.DISCO:
			if tile.is_revealed:
				tile.material.set_shader_parameter("alpha", 1.0)
				var current_color = tile.material.get_shader_parameter("base_color")
				var new_color = current_color.lerp(tile.target_color, delta * disco_speed)
				tile.material.set_shader_parameter("base_color", new_color)
				tile.material.set_shader_parameter("effect_intensity", tile.effect_progress * disco_intensity)

# Utility functions

func get_tile_at(pos: Vector3i) -> GridTileData:
	"""Get tile data at grid position"""
	if _is_valid_position(pos):
		return tile_grid[pos.x][pos.y][pos.z]
	return null

func _is_valid_position(pos: Vector3i) -> bool:
	return pos.x >= 0 and pos.x < grid_dimensions.x and \
		   pos.y >= 0 and pos.y < grid_dimensions.y and \
		   pos.z >= 0 and pos.z < grid_dimensions.z

func get_grid_as_array() -> Array:
	"""Return the grid as a nested array structure"""
	var result = []
	
	for x in grid_dimensions.x:
		var x_layer = []
		for y in grid_dimensions.y:
			var y_layer = []
			for z in grid_dimensions.z:
				var tile = tile_grid[x][y][z]
				y_layer.append({
					"position": tile.position,
					"is_revealed": tile.is_revealed,
					"effect_type": tile.effect_type,
					"color": tile.base_color
				})
			x_layer.append(y_layer)
		result.append(x_layer)
	
	return result

func describe_grid() -> String:
	"""Describe the grid structure as arrays"""
	var description = "Grid Structure:\n"
	description += "Dimensions: %d x %d x %d\n" % [grid_dimensions.x, grid_dimensions.y, grid_dimensions.z]
	description += "Total tiles: %d\n" % (grid_dimensions.x * grid_dimensions.y * grid_dimensions.z)
	
	# Count revealed tiles
	var revealed_count = 0
	for x in grid_dimensions.x:
		for y in grid_dimensions.y:
			for z in grid_dimensions.z:
				if tile_grid[x][y][z].is_revealed:
					revealed_count += 1
	
	description += "Revealed tiles: %d\n" % revealed_count
	description += "Grid array structure: grid[x][y][z] where x=%d, y=%d, z=%d" % [grid_dimensions.x, grid_dimensions.y, grid_dimensions.z]
	
	return description 

# Effect cleanup system

func _schedule_effect_cleanup(effect_name: String, delay_seconds: float):
	"""Schedule an effect for cleanup after a delay"""
	var cleanup_time = Time.get_time_dict_from_system()
	var scheduled_time = cleanup_time.hour * 3600 + cleanup_time.minute * 60 + cleanup_time.second + delay_seconds
	
	cleanup_queue.append({
		"effect_name": effect_name,
		"cleanup_time": scheduled_time,
		"delay": delay_seconds
	})
	
	print("Scheduled cleanup for %s effect in %f seconds" % [effect_name, delay_seconds])

func _process_cleanup_queue(delta):
	"""Process scheduled cleanups"""
	if cleanup_queue.is_empty():
		return
	
	var current_time = Time.get_time_dict_from_system()
	var now = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
	
	for i in range(cleanup_queue.size() - 1, -1, -1):
		var cleanup_item = cleanup_queue[i]
		if now >= cleanup_item.cleanup_time:
			print("Executing scheduled cleanup for %s effect" % cleanup_item.effect_name)
			_cleanup_effect_tiles(cleanup_item.effect_name)
			cleanup_queue.remove_at(i)

func _cleanup_effect_tiles(effect_name: String = ""):
	"""Clean up effect tiles for a specific effect or all effects"""
	var cleaned_count = 0
	
	for x in grid_dimensions.x:
		for y in grid_dimensions.y:
			for z in grid_dimensions.z:
				var tile = tile_grid[x][y][z]
				
				# Check if this tile should be cleaned up
				var should_cleanup = false
				if effect_name.is_empty():
					# Clean up all effects
					should_cleanup = tile.effect_type != EffectType.NONE
				else:
					# Clean up specific effect
					match effect_name:
						"reveal":
							should_cleanup = tile.effect_type == EffectType.REVEAL
						"disco":
							should_cleanup = tile.effect_type == EffectType.DISCO
						"wave":
							should_cleanup = tile.effect_type == EffectType.WAVE
						"pulse":
							should_cleanup = tile.effect_type == EffectType.PULSE
				
				if should_cleanup:
					_cleanup_tile(tile)
					cleaned_count += 1
	
	print("Cleaned up %d effect tiles" % cleaned_count)
	emit_signal("tiles_cleaned_up", cleaned_count)

func _cleanup_tile(tile: GridTileData):
	"""Clean up a single tile - hide and reset it"""
	if tile.mesh_instance:
		# Fade out the tile before removing
		if tile.material:
			tile.material.set_shader_parameter("alpha", 0.0)
		
		# Remove the mesh instance after a short delay
		var tween = create_tween()
		tween.tween_property(tile.mesh_instance, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func(): 
			if tile.mesh_instance and is_instance_valid(tile.mesh_instance):
				tile.mesh_instance.queue_free()
				tile.mesh_instance = null
		)
	
	# Reset tile state
	tile.effect_type = EffectType.NONE
	tile.is_revealed = false
	tile.effect_progress = 0.0
	tile.effect_start_time = 0.0

func _cleanup_all_effect_tiles():
	"""Immediately clean up all effect tiles"""
	print("Cleaning up all effect tiles immediately")
	_cleanup_effect_tiles("")  # Empty string = clean all
	
	# Clear cleanup queue
	cleanup_queue.clear()

# Public cleanup methods

func cleanup_reveal_tiles():
	"""Manually clean up reveal effect tiles"""
	_cleanup_effect_tiles("reveal")

func cleanup_disco_tiles():
	"""Manually clean up disco effect tiles"""
	_cleanup_effect_tiles("disco")

func force_cleanup_all():
	"""Force immediate cleanup of all effect tiles"""
	_cleanup_all_effect_tiles()

func set_auto_cleanup(enabled: bool):
	"""Enable or disable automatic cleanup"""
	auto_cleanup_on_complete = enabled
	print("Auto cleanup %s" % ("enabled" if enabled else "disabled"))

func set_cleanup_delay(delay: float):
	"""Set the delay before cleanup after effect completion"""
	cleanup_delay = delay
	print("Cleanup delay set to %f seconds" % delay)

func get_cleanup_status() -> Dictionary:
	"""Get current cleanup system status"""
	return {
		"auto_cleanup_enabled": auto_cleanup_on_complete,
		"cleanup_delay": cleanup_delay,
		"pending_cleanups": cleanup_queue.size(),
		"effect_duration": effect_duration,
		"reveal_completed": reveal_completed,
		"disco_active": is_disco_active
	} 
