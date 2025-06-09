# ResetLevelController.gd
# Reset Level Cube - Utility type "r"
# Resets the entire level/map when activated

extends "res://commons/scenes/mapobjects/TeleportController.gd"

@export var fade_duration: float = 0.5
@export var warning_distance: float = 2.0
@export var reset_delay: float = 1.0

var player_node: Node3D
var is_resetting: bool = false
var scene_manager: Node
var player_in_area: bool = false

# Reset-specific signals
signal level_reset_started()
signal level_reset_complete()
signal player_approaching_reset(distance: float)

func _ready():
	# Call parent ready first
	super()
	
	# Override teleporter settings for reset behavior
	destination = "level_reset"  # Special destination identifier
	portal_color = Color.ORANGE_RED
	charge_time = 1.5  # Slightly longer for level reset
	activation_method = "proximity"  # Auto-activate when player gets close
	
	# Find player and scene manager
	_find_player_node()
	_find_scene_manager()
	
	# Debug collision setup
	_debug_collision_setup()
	
	print("ResetLevelController: Level reset cube ready")

func _process(delta):
	super(delta)
	
	# Check player distance for warning
	if player_node and not is_resetting:
		var distance = global_position.distance_to(player_node.global_position)
		if distance <= warning_distance:
			player_approaching_reset.emit(distance)
			_show_warning_effects()

func _find_player_node():
	# Look for VR origin or player body
	var potential_players = [
		get_tree().get_first_node_in_group("player"),
		get_tree().current_scene.find_child("XROrigin3D", true, false),
		get_tree().current_scene.find_child("VROrigin", true, false),
		get_tree().current_scene.find_child("Player", true, false)
	]
	
	for potential_player in potential_players:
		if potential_player and potential_player is Node3D:
			player_node = potential_player as Node3D
			print("ResetLevelController: Found player node: %s" % player_node.name)
			return
	
	print("ResetLevelController: WARNING - No player node found!")

func _find_scene_manager():
	# Look for scene manager for advanced reset
	var potential_managers = [
		get_node_or_null("/root/SceneManager"),
		get_node_or_null("/root/AdaSceneManager"),
		get_tree().current_scene.find_child("SceneManager", true, false),
		get_tree().current_scene.find_child("AdaSceneManager", true, false)
	]
	
	for manager in potential_managers:
		if manager:
			scene_manager = manager
			print("ResetLevelController: Found scene manager: %s" % manager.name)
			return
	
	print("ResetLevelController: No scene manager found - will use simple reload")

func _show_warning_effects():
	# Flash orange-red to warn player they're approaching reset
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as ShaderMaterial
		if material:
			material.set_shader_parameter("emissionColor", Color.ORANGE_RED)
			material.set_shader_parameter("emission_strength", 6.0)

func _debug_collision_setup():
	"""Debug the collision setup"""
	var reset_area = $ResetArea
	var beam_area = $BeamArea
	
	if reset_area:
		print("ResetLevelController: ResetArea collision_layer=%d, collision_mask=%d" % [reset_area.collision_layer, reset_area.collision_mask])
	if beam_area:
		print("ResetLevelController: BeamArea collision_layer=%d, collision_mask=%d" % [beam_area.collision_layer, beam_area.collision_mask])
	
	print("ResetLevelController: Player node found: %s" % (player_node.name if player_node else "NONE"))

# Override teleporter activation for level reset behavior
func _activate_teleporter():
	if is_resetting:
		print("ResetLevelController: Already resetting, ignoring activation")
		return
	
	print("ResetLevelController: 🔄 LEVEL RESET ACTIVATED")
	is_resetting = true
	level_reset_started.emit()
	
	# Start level reset sequence
	_perform_level_reset()

func _perform_level_reset():
	print("ResetLevelController: Starting level reset sequence...")
	
	# Visual feedback
	_trigger_reset_flash()
	
	# Fade out
	if fade_duration > 0:
		await _perform_fade(false, fade_duration)
	
	# Brief delay for effect
	if reset_delay > 0:
		await get_tree().create_timer(reset_delay).timeout
	
	# Perform the actual reset
	_execute_level_reset()

func _execute_level_reset():
	print("ResetLevelController: Executing level reset...")
	
	if scene_manager and scene_manager.has_method("reload_current_scene"):
		# Use scene manager for advanced reload (preserves user data, sequences, etc.)
		print("ResetLevelController: Using SceneManager reload")
		scene_manager.reload_current_scene()
		
	elif scene_manager and scene_manager.has_method("restart_current_map"):
		# Alternative scene manager method
		print("ResetLevelController: Using SceneManager restart")
		scene_manager.restart_current_map()
		
	else:
		# Fallback: Simple scene reload
		print("ResetLevelController: Using simple scene reload")
		_simple_scene_reload()
	
	# Signal completion (may not execute if scene reloads)
	level_reset_complete.emit()

func _simple_scene_reload():
	# Simple Godot scene reload
	var current_scene_path = get_tree().current_scene.scene_file_path
	
	if current_scene_path.is_empty():
		print("ResetLevelController: ERROR - Cannot determine scene path for reload")
		# Try alternative reload method
		get_tree().reload_current_scene()
	else:
		print("ResetLevelController: Reloading scene: %s" % current_scene_path)
		get_tree().change_scene_to_file(current_scene_path)

func _trigger_reset_flash():
	# Bright orange flash for level reset
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as ShaderMaterial
		if material:
			material.set_shader_parameter("emissionColor", Color.WHITE)
			material.set_shader_parameter("emission_strength", 20.0)

func _perform_fade(fade_in: bool, duration: float):
	# Enhanced fade implementation for level reset
	print("ResetLevelController: %s over %s seconds" % ["Fading in" if fade_in else "Fading out", duration])
	
	# Try to find a fade controller in the scene
	var fade_controller = _find_fade_controller()
	
	if fade_controller:
		if fade_in:
			await fade_controller.fade_in(duration)
		else:
			await fade_controller.fade_out(duration)
	else:
		# Simple timer fallback
		await get_tree().create_timer(duration).timeout

func _find_fade_controller():
	# Look for fade/transition controllers
	var potential_faders = [
		get_tree().current_scene.find_child("FadeController", true, false),
		get_tree().current_scene.find_child("TransitionController", true, false),
		get_node_or_null("/root/FadeManager")
	]
	
	for fader in potential_faders:
		if fader and (fader.has_method("fade_in") or fader.has_method("fade_out")):
			return fader
	
	return null

# Public API for different reset types
func reset_to_checkpoint():
	"""Reset to last checkpoint if available"""
	if scene_manager and scene_manager.has_method("reset_to_checkpoint"):
		print("ResetLevelController: Resetting to checkpoint")
		scene_manager.reset_to_checkpoint()
	else:
		# Fallback to full level reset
		_execute_level_reset()

func reset_with_user_data(user_data: Dictionary = {}):
	"""Reset level but preserve certain user data"""
	if scene_manager and scene_manager.has_method("reload_with_data"):
		print("ResetLevelController: Resetting with preserved data: %s" % user_data)
		scene_manager.reload_with_data(user_data)
	else:
		# Store data as metadata before reload
		get_tree().current_scene.set_meta("preserved_data", user_data)
		_execute_level_reset()

# Debug methods
func force_level_reset():
	"""Force level reset immediately (for testing)"""
	print("ResetLevelController: FORCE LEVEL RESET triggered")
	_activate_teleporter()

func test_different_reset_methods():
	"""Test various reset approaches"""
	print("ResetLevelController: Testing reset methods...")
	print("  Scene manager available: %s" % (scene_manager != null))
	print("  Current scene path: %s" % get_tree().current_scene.scene_file_path)
	print("  Available methods:")
	
	if scene_manager:
		var methods = ["reload_current_scene", "restart_current_map", "reset_to_checkpoint"]
		for method in methods:
			print("    %s: %s" % [method, scene_manager.has_method(method)])

# Signal handlers for area detection
func _on_player_entered_beam(body):
	print("ResetLevelController: *** BODY ENTERED *** %s (type: %s)" % [body.name, body.get_class()])
	
	# More detailed debug info
	if body.has_method("is_in_group"):
		print("  - In player group: %s" % body.is_in_group("player"))
	print("  - Body type: %s" % type_string(typeof(body)))
	print("  - Body class: %s" % body.get_class())
	print("  - Body collision layer: %s" % (body.collision_layer if body.has_property("collision_layer") else "N/A"))
	
	# Check if it's the player
	if _is_player_body(body):
		print("ResetLevelController: ✅ PLAYER DETECTED - activating reset!")
		player_in_area = true
		_activate_teleporter()
	else:
		print("ResetLevelController: ❌ Not recognized as player")

func _on_player_exited_beam(body):
	print("ResetLevelController: Body exited reset area: %s" % body.name)
	
	if _is_player_body(body):
		print("ResetLevelController: Player exited reset area")
		player_in_area = false

func _is_player_body(body) -> bool:
	"""Check if the body is the player"""
	print("  - Checking if body is player...")
	
	if not body:
		print("  - Body is null")
		return false
	
	# Check if it's in the player group
	if body.has_method("is_in_group") and body.is_in_group("player"):
		print("  - ✅ Body is in 'player' group")
		return true
	
	# Check common player node names
	var player_names = ["Player", "XROrigin3D", "VROrigin", "CharacterBody3D", "RigidBody3D", "player"]
	if body.name.to_lower() in player_names or body.name.to_lower().contains("player"):
		print("  - ✅ Body name suggests it's a player: %s" % body.name)
		return true
	
	# Check if it's a CharacterBody3D or RigidBody3D (common for players)
	if body is CharacterBody3D or body is RigidBody3D:
		print("  - ✅ Body is CharacterBody3D or RigidBody3D")
		return true
	
	# Check if it's the player node we found earlier
	if player_node and (body == player_node or body.get_parent() == player_node):
		print("  - ✅ Body matches found player node")
		return true
	
	print("  - ❌ Body not recognized as player")
	return false

# Add a simple test method that bypasses collision detection
func _input(event):
	# Press 'R' key to force reset (for testing)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			print("ResetLevelController: 🔄 MANUAL RESET TRIGGERED (R key)")
			_activate_teleporter()
