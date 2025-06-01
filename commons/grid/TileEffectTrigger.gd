# TileEffectTrigger.gd
extends RigidBody3D
class_name TileEffectTrigger

# Tile effect trigger configuration
@export_group("Effect Configuration")
@export var effect_type: String = "disco"  # disco, reveal, wave, pulse, etc.
@export var trigger_method: String = "step_on"  # step_on, grab, click
@export var effect_radius: int = 5  # radius for area effects
@export var effect_center: Vector3i = Vector3i(-1, -1, -1)  # center position (auto-detect if -1)
@export var one_time_trigger: bool = false  # trigger only once
@export var trigger_delay: float = 0.0  # delay before effect starts

@export_group("Visual Settings")
@export var trigger_tile_color: Color = Color.MAGENTA
@export var show_effect_indicator: bool = true
@export var glow_intensity: float = 1.0

@export_group("Audio")
@export var trigger_sound_path: String = ""
@export var audio_volume: float = 0.5

# Internal state
var grid_system: Node  # Changed from GridSystem1
var tile_effect_manager: Node  # Changed from TileEffectManager
var trigger_position: Vector3i
var has_been_triggered: bool = false
var is_active: bool = true

# Visual components
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var effect_indicator: MeshInstance3D
var audio_player: AudioStreamPlayer3D

# Area detection for step_on triggers
var area_detector: Area3D

# Effect configuration data (loaded from JSON)
var effect_config: Dictionary = {}

# Signals
signal effect_triggered(effect_type: String, position: Vector3i, config: Dictionary)
signal trigger_activated(trigger: TileEffectTrigger)

func _ready():
	# Find grid system in parent hierarchy
	_find_grid_system()
	
	# Set up visual appearance
	_setup_visual_components()
	
	# Set up interaction method
	_setup_trigger_method()
	
	# Set up audio if specified
	_setup_audio()
	
	print("TileEffectTrigger: Ready - Effect: %s, Method: %s" % [effect_type, trigger_method])

func _find_grid_system():
	var parent = get_parent()
	while parent:
		# Look for any node that might be a grid system
		if "grid" in parent.name.to_lower() or parent.has_method("load_map_data"):
			grid_system = parent
			# Try to find tile effect manager
			if parent.has_method("get_node"):
				tile_effect_manager = parent.get_node_or_null("TileEffectManager")
				if not tile_effect_manager:
					tile_effect_manager = parent.get_node_or_null("tile_effect_manager")
			break
		parent = parent.get_parent()
	
	if not grid_system:
		print("WARNING: TileEffectTFrigger could not find grid system in parent hierarchy")

func _setup_visual_components():
	# Create main mesh instance
	mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.9, 0.1, 0.9)  # Slightly smaller than tile
	mesh_instance.mesh = box_mesh
	
	# Create material with trigger color
	var material = StandardMaterial3D.new()
	material.albedo_color = trigger_tile_color
	material.emission_enabled = true
	material.emission = trigger_tile_color * 0.3
	material.metallic = 0.2
	material.roughness = 0.8
	mesh_instance.material_override = material
	
	add_child(mesh_instance)
	
	# Create collision shape
	collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.9, 0.1, 0.9)
	collision_shape.shape = box_shape
	add_child(collision_shape)
	
	# Create effect indicator if enabled
	if show_effect_indicator:
		_create_effect_indicator()

func _create_effect_indicator():
	effect_indicator = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.05
	sphere_mesh.height = 0.1
	effect_indicator.mesh = sphere_mesh
	effect_indicator.position.y = 0.1
	
	var indicator_material = StandardMaterial3D.new()
	indicator_material.albedo_color = Color.WHITE
	indicator_material.emission_enabled = true
	indicator_material.emission = Color.WHITE * glow_intensity
	effect_indicator.material_override = indicator_material
	
	add_child(effect_indicator)
	
	# Animate the indicator
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(effect_indicator, "scale", Vector3(1.5, 1.5, 1.5), 1.0)
	tween.tween_property(effect_indicator, "scale", Vector3(0.8, 0.8, 0.8), 1.0)

func _setup_trigger_method():
	match trigger_method:
		"step_on":
			_setup_step_on_trigger()
		"grab":
			_setup_grab_trigger()
		"click":
			_setup_click_trigger()

func _setup_step_on_trigger():
	area_detector = Area3D.new()
	var area_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(1.2, 2.0, 1.2)  # Larger detection area
	area_shape.shape = box_shape
	area_shape.position.y = 1.0  # Above the trigger
	
	area_detector.add_child(area_shape)
	add_child(area_detector)
	
	area_detector.body_entered.connect(_on_body_entered)
	area_detector.area_entered.connect(_on_area_entered)

func _setup_grab_trigger():
	# For VR hand grabbing - this would need to be implemented differently
	# RigidBody3D doesn't have grab signals by default
	# We can make this grabbable by adding pickup functionality
	print("TileEffectTrigger: Grab trigger setup - would need XRTools pickup functionality")
	
	# For now, just use collision detection as fallback
	_setup_step_on_trigger()

func _setup_click_trigger():
	# For pointer/click interaction - RigidBody3D doesn't have input_event signal
	# We need to add this functionality or use collision detection
	print("TileEffectTrigger: Click trigger setup - using collision detection instead")
	
	# Set up area detection as fallback
	_setup_step_on_trigger()

func _setup_audio():
	if not trigger_sound_path.is_empty():
		audio_player = AudioStreamPlayer3D.new()
		var audio_stream = load(trigger_sound_path)
		if audio_stream:
			audio_player.stream = audio_stream
			audio_player.volume_db = linear_to_db(audio_volume)
			add_child(audio_player)

# Trigger detection methods

func _on_body_entered(body):
	# Check if player or VR controller entered
	if _is_player_or_controller(body):
		_trigger_effect()

func _on_area_entered(area):
	# Check if player area entered
	if _is_player_or_controller(area.get_parent()):
		_trigger_effect()

func _is_player_or_controller(node: Node) -> bool:
	# Check if this is a player, VR controller, or related component
	if not node:
		return false
	
	var node_name = node.name.to_lower()
	return (
		"player" in node_name or 
		"xr" in node_name or 
		"hand" in node_name or 
		"controller" in node_name or
		node.is_in_group("player") or
		node.is_in_group("vr_controller")
	)

# Effect triggering

func _trigger_effect():
	if not is_active or (one_time_trigger and has_been_triggered):
		return
	
	if not tile_effect_manager:
		print("WARNING: TileEffectTrigger has no tile effect manager")
		return
	
	print("TileEffectTrigger: Triggering effect '%s' at position %s" % [effect_type, global_position])
	
	# Mark as triggered if one-time
	if one_time_trigger:
		has_been_triggered = true
		_deactivate_trigger()
	
	# Play audio if available
	if audio_player:
		audio_player.play()
	
	# Apply delay if specified
	if trigger_delay > 0:
		await get_tree().create_timer(trigger_delay).timeout
	
	# Determine effect center
	var center_pos = effect_center
	if center_pos == Vector3i(-1, -1, -1):
		# Auto-detect position from world position
		if grid_system and grid_system.has_method("world_to_grid_position"):
			center_pos = grid_system.world_to_grid_position(global_position)
		else:
			# Fallback to simple conversion
			center_pos = Vector3i(int(global_position.x), int(global_position.y), int(global_position.z))
	
	# Trigger the appropriate effect
	_execute_effect(center_pos)
	
	# Emit signals
	emit_signal("effect_triggered", effect_type, center_pos, effect_config)
	emit_signal("trigger_activated", self)

func _execute_effect(center_pos: Vector3i):
	if not tile_effect_manager:
		print("TileEffectTrigger: No tile effect manager available")
		return
	
	match effect_type.to_lower():
		"disco":
			if tile_effect_manager.has_method("start_disco_effect"):
				tile_effect_manager.start_disco_effect()
			else:
				print("TileEffectTrigger: start_disco_effect method not available")
		"reveal":
			if tile_effect_manager.has_method("start_reveal_effect"):
				tile_effect_manager.start_reveal_effect(center_pos)
			else:
				print("TileEffectTrigger: start_reveal_effect method not available")
		"wave":
			_trigger_wave_effect(center_pos)
		"pulse":
			_trigger_pulse_effect(center_pos)
		"show_all":
			if tile_effect_manager.has_method("reveal_all_tiles"):
				tile_effect_manager.reveal_all_tiles()
			else:
				print("TileEffectTrigger: reveal_all_tiles method not available")
		"hide_all":
			if tile_effect_manager.has_method("hide_all_tiles"):
				tile_effect_manager.hide_all_tiles()
			else:
				print("TileEffectTrigger: hide_all_tiles method not available")
		"stop":
			if tile_effect_manager.has_method("stop_all_effects"):
				tile_effect_manager.stop_all_effects()
			else:
				print("TileEffectTrigger: stop_all_effects method not available")
		"custom":
			_trigger_custom_effect(center_pos)
		_:
			print("WARNING: Unknown effect type: %s" % effect_type)

func _trigger_wave_effect(center_pos: Vector3i):
	# Create a wave effect expanding from center
	var max_radius = effect_radius
	for radius in range(1, max_radius + 1):
		_reveal_tiles_at_radius(center_pos, radius)
		await get_tree().create_timer(0.2).timeout

func _trigger_pulse_effect(center_pos: Vector3i):
	# Pulse effect: show briefly, then hide, then show again
	_reveal_tiles_in_radius(center_pos, effect_radius)
	await get_tree().create_timer(0.5).timeout
	tile_effect_manager.hide_all_tiles()
	await get_tree().create_timer(0.3).timeout
	_reveal_tiles_in_radius(center_pos, effect_radius)

func _trigger_custom_effect(center_pos: Vector3i):
	# Load custom effect configuration from effect_config
	var custom_pattern = effect_config.get("pattern", "circle")
	var custom_speed = effect_config.get("speed", 1.0)
	var custom_colors = effect_config.get("colors", [])
	
	# Implement custom pattern based on configuration
	print("TileEffectTrigger: Custom effect not yet implemented")

func _reveal_tiles_at_radius(center: Vector3i, radius: int):
	# Reveal tiles in a circle at specific radius
	for x in range(-radius, radius + 1):
		for z in range(-radius, radius + 1):
			var distance = sqrt(x*x + z*z)
			if abs(distance - radius) < 0.5:  # Approximately at the radius
				var pos = Vector3i(center.x + x, center.y, center.z + z)
				if _is_valid_grid_position(pos):
					tile_effect_manager.start_reveal_effect(pos)

func _reveal_tiles_in_radius(center: Vector3i, radius: int):
	# Reveal all tiles within radius
	for x in range(-radius, radius + 1):
		for z in range(-radius, radius + 1):
			var distance = sqrt(x*x + z*z)
			if distance <= radius:
				var pos = Vector3i(center.x + x, center.y, center.z + z)
				if _is_valid_grid_position(pos):
					tile_effect_manager.start_reveal_effect(pos)

func _is_valid_grid_position(pos: Vector3i) -> bool:
	if not grid_system:
		return false
	
	# Check if grid_system has the expected properties
	var grid_x = 10  # default
	var grid_z = 10  # default
	
	if grid_system.has_method("get") or "grid_x" in grid_system:
		if grid_system.get("grid_x"):
			grid_x = grid_system.grid_x
		if grid_system.get("grid_z"):
			grid_z = grid_system.grid_z
	
	return (pos.x >= 0 and pos.x < grid_x and pos.z >= 0 and pos.z < grid_z)

func _deactivate_trigger():
	is_active = false
	
	# Visual feedback for deactivation
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as StandardMaterial3D
		material.albedo_color = material.albedo_color.darkened(0.5)
		material.emission = Color.BLACK
	
	if effect_indicator:
		effect_indicator.visible = false

# Public methods for external control

func set_effect_config(config: Dictionary):
	"""Set effect configuration from JSON data"""
	effect_config = config
	
	# Apply configuration
	if config.has("effect_type"):
		effect_type = config.effect_type
	if config.has("trigger_method"):
		trigger_method = config.trigger_method
	if config.has("effect_radius"):
		effect_radius = config.effect_radius
	if config.has("one_time_trigger"):
		one_time_trigger = config.one_time_trigger
	if config.has("trigger_delay"):
		trigger_delay = config.trigger_delay
	if config.has("color"):
		var color_array = config.color
		if color_array.size() >= 3:
			trigger_tile_color = Color(color_array[0], color_array[1], color_array[2])

func reset_trigger():
	"""Reset the trigger to be usable again"""
	has_been_triggered = false
	is_active = true
	
	# Restore visual appearance
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as StandardMaterial3D
		material.albedo_color = trigger_tile_color
		material.emission = trigger_tile_color * 0.3
	
	if effect_indicator:
		effect_indicator.visible = show_effect_indicator

func activate():
	"""Manually activate the trigger"""
	_trigger_effect()

func deactivate():
	"""Deactivate the trigger"""
	_deactivate_trigger()

# Utility functions

func get_trigger_info() -> Dictionary:
	"""Get information about this trigger"""
	var grid_pos = Vector3i.ZERO
	if grid_system and grid_system.has_method("world_to_grid_position"):
		grid_pos = grid_system.world_to_grid_position(global_position)
	
	return {
		"effect_type": effect_type,
		"trigger_method": trigger_method,
		"effect_radius": effect_radius,
		"position": global_position,
		"grid_position": grid_pos,
		"is_active": is_active,
		"has_been_triggered": has_been_triggered,
		"config": effect_config
	} 
