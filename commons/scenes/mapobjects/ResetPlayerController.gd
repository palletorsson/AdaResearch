# ResetLevelController.gd
# Reset Level Cube - Utility type "r"
# Resets the entire level/map when activated

extends Node3D

@export var fade_duration: float = 0.5
@export var warning_distance: float = 2.0
@export var reset_delay: float = 1.0
@export var activation_method: String = "proximity"  # "proximity" or "touch"

var player_node: Node3D
var is_resetting: bool = false
var scene_manager: Node
var player_in_area: bool = false

# Reset-specific signals
signal level_reset_started()
signal level_reset_complete()
signal player_approaching_reset(distance: float)

# Area3D for detection - CRITICAL: Must be properly configured
@onready var reset_area: Area3D = $ResetArea

func _ready():
	print("ResetLevelController: Initializing reset cube...")
	
	# Find player and scene manager
	_find_player_node()
	_find_scene_manager()
	
	# Setup reset area collision detection - THIS IS KEY
	_setup_reset_area()
	
	# Setup visual effects
	_setup_visual_effects()
	
	print("ResetLevelController: Level reset cube ready")

func _setup_reset_area():
	"""Setup the Area3D for proper collision detection with XR-Tools PlayerBody"""
	if not reset_area:
		push_error("ResetLevelController: ResetArea not found! Scene structure incorrect.")
		return
	
	print("ResetLevelController: Setting up reset area collision detection...")
	
	# CRITICAL: Set collision mask to detect Player Body (layer 20 in XR-Tools)
	# Layer 20 = 2^19 = 524288
	reset_area.collision_layer = 0  # This area doesn't provide collision
	reset_area.collision_mask = 1048576  # Detect layer 20 (Player Body)
	
	# Enable monitoring
	reset_area.monitoring = true
	reset_area.monitorable = false  # Other areas don't need to detect this
	
	# Connect signals - MUST be done correctly
	if not reset_area.is_connected("body_entered", Callable(self, "_on_reset_area_body_entered")):
		reset_area.body_entered.connect(_on_reset_area_body_entered)
		print("ResetLevelController: ✅ Connected body_entered signal")
	
	if not reset_area.is_connected("body_exited", Callable(self, "_on_reset_area_body_exited")):
		reset_area.body_exited.connect(_on_reset_area_body_exited)
		print("ResetLevelController: ✅ Connected body_exited signal")
	
	# Debug collision setup
	print("ResetLevelController: Reset area collision_layer=%d, collision_mask=%d" % [reset_area.collision_layer, reset_area.collision_mask])
	print("ResetLevelController: Reset area monitoring=%s, monitorable=%s" % [reset_area.monitoring, reset_area.monitorable])

func _setup_visual_effects():
	"""Setup visual effects for the reset cube"""
	# Find mesh instance for visual feedback
	var mesh_instance = find_child("MeshInstance3D", true, false)
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as ShaderMaterial
		if material:
			# Set reset cube to orange-red color
			material.set_shader_parameter("emissionColor", Color.ORANGE_RED)
			material.set_shader_parameter("emission_strength", 3.0)

func _process(delta):
	# Check player distance for warning (only if using proximity activation)
	if activation_method == "proximity" and player_node and not is_resetting:
		var distance = global_position.distance_to(player_node.global_position)
		if distance <= warning_distance:
			player_approaching_reset.emit(distance)
			_show_warning_effects()

func _find_player_node():
	"""Find the player node - specifically the XR-Tools PlayerBody"""
	# Look for XR-Tools PlayerBody first (most likely in VR)
	var player_body = get_tree().get_first_node_in_group("player_body")
	if player_body:
		player_node = player_body as Node3D
		print("ResetLevelController: Found XR-Tools PlayerBody: %s" % player_node.name)
		return
	
	# Fallback to other player node types
	var potential_players = [
		get_tree().get_first_node_in_group("player"),
		get_tree().current_scene.find_child("XROrigin3D", true, false),
		get_tree().current_scene.find_child("VROrigin", true, false),
		get_tree().current_scene.find_child("Player", true, false)
	]
	
	for potential_player in potential_players:
		if potential_player and potential_player is Node3D:
			player_node = potential_player as Node3D
			print("ResetLevelController: Found fallback player node: %s" % player_node.name)
			return
	
	print("ResetLevelController: WARNING - No player node found!")

func _find_scene_manager():
	"""Find scene manager for advanced reset"""
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
	"""Flash orange-red to warn player they're approaching reset"""
	var mesh_instance = find_child("MeshInstance3D", true, false)
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as ShaderMaterial
		if material:
			material.set_shader_parameter("emissionColor", Color.ORANGE_RED)
			material.set_shader_parameter("emission_strength", 6.0)

# SIGNAL HANDLERS - These are the critical functions that must work
func _on_reset_area_body_entered(body: Node3D):
	"""Handle player entering the reset area"""
	print("ResetLevelController: 🔍 BODY ENTERED RESET AREA: %s (type: %s)" % [body.name, body.get_class()])
	print("ResetLevelController: 🔍 Body groups: %s" % body.get_groups())
	print("ResetLevelController: 🔍 Body collision layer: %s" % (body.collision_layer if body.has_property("collision_layer") else "N/A"))
	
	# Check if it's the player body
	if _is_player_body(body):
		print("ResetLevelController: ✅ PLAYER DETECTED IN RESET AREA!")
		player_in_area = true
		
		if activation_method == "proximity":
			# Auto-activate on proximity
			_activate_reset()
		else:
			# Wait for manual activation (touch/grab)
			print("ResetLevelController: Player in area, waiting for activation...")
	else:
		print("ResetLevelController: ❌ Not recognized as player body")

func _on_reset_area_body_exited(body: Node3D):
	"""Handle player exiting the reset area"""
	print("ResetLevelController: Body exited reset area: %s" % body.name)
	
	if _is_player_body(body):
		print("ResetLevelController: Player exited reset area")
		player_in_area = false

func _is_player_body(body: Node3D) -> bool:
	"""Check if the body is the player - specifically for XR-Tools"""
	if not body:
		return false
	
	print("  - Checking if body is player...")
	
	# Check if it's in the player_body group (XR-Tools)
	if body.has_method("is_in_group") and body.is_in_group("player_body"):
		print("  - ✅ Body is in 'player_body' group (XR-Tools)")
		return true
	
	# Check if it's in the player group
	if body.has_method("is_in_group") and body.is_in_group("player"):
		print("  - ✅ Body is in 'player' group")
		return true
	
	# Check if it matches our found player node
	if player_node and (body == player_node or body.get_parent() == player_node):
		print("  - ✅ Body matches found player node")
		return true
	
	# Check for XR-Tools PlayerBody class
	if body.get_class() == "XRToolsPlayerBody":
		print("  - ✅ Body is XRToolsPlayerBody")
		return true
	
	# Check common player node names
	var player_names = ["PlayerBody", "XROrigin3D", "VROrigin", "CharacterBody3D", "player"]
	if body.name.to_lower() in player_names or "player" in body.name.to_lower():
		print("  - ✅ Body name suggests it's a player: %s" % body.name)
		return true
	
	# Check if it's a CharacterBody3D (common for players)
	if body is CharacterBody3D:
		print("  - ✅ Body is CharacterBody3D")
		return true
	
	print("  - ❌ Body not recognized as player")
	return false

func _activate_reset():
	"""Activate the level reset"""
	if is_resetting:
		print("ResetLevelController: Already resetting, ignoring activation")
		return
	
	print("ResetLevelController: 🔄 LEVEL RESET ACTIVATED!")
	is_resetting = true
	level_reset_started.emit()
	
	# Start level reset sequence
	_perform_level_reset()

func _perform_level_reset():
	"""Perform the actual level reset sequence"""
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
	"""Execute the level reset"""
	print("ResetLevelController: Executing level reset...")
	
	if scene_manager and scene_manager.has_method("reload_current_scene"):
		# Use scene manager for advanced reload
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
	"""Simple Godot scene reload"""
	var current_scene_path = get_tree().current_scene.scene_file_path
	
	if current_scene_path.is_empty():
		print("ResetLevelController: Using get_tree().reload_current_scene()")
		get_tree().reload_current_scene()
	else:
		print("ResetLevelController: Reloading scene: %s" % current_scene_path)
		get_tree().change_scene_to_file(current_scene_path)

func _trigger_reset_flash():
	"""Bright flash for level reset"""
	var mesh_instance = find_child("MeshInstance3D", true, false)
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as ShaderMaterial
		if material:
			material.set_shader_parameter("emissionColor", Color.WHITE)
			material.set_shader_parameter("emission_strength", 20.0)

func _perform_fade(fade_in: bool, duration: float):
	"""Enhanced fade implementation for level reset"""
	print("ResetLevelController: %s over %s seconds" % ["Fading in" if fade_in else "Fading out", duration])
	
	# Simple timer fallback - replace with your fade system
	await get_tree().create_timer(duration).timeout

# Public API
func force_level_reset():
	"""Force level reset immediately (for testing)"""
	print("ResetLevelController: FORCE LEVEL RESET triggered")
	_activate_reset()

# Debug input for testing
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			print("ResetLevelController: 🔄 MANUAL RESET TRIGGERED (R key)")
			_activate_reset()
		elif event.keycode == KEY_T:
			print("ResetLevelController: 🔧 Testing collision detection")
			_test_collision_detection()

func _test_collision_detection():
	"""Test the collision detection setup"""
	print("=== RESET AREA COLLISION TEST ===")
	print("Reset area exists: %s" % (reset_area != null))
	if reset_area:
		print("Reset area monitoring: %s" % reset_area.monitoring)
		print("Reset area collision_mask: %s" % reset_area.collision_mask)
		print("Reset area collision_layer: %s" % reset_area.collision_layer)
		
		# Check for bodies in area
		var bodies = reset_area.get_overlapping_bodies()
		print("Bodies currently in reset area: %d" % bodies.size())
		for body in bodies:
			print("  - %s (groups: %s)" % [body.name, body.get_groups()])
	
	print("Player node found: %s" % (player_node.name if player_node else "NONE"))
	print("==================================")
