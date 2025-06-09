# ResetArea3D.gd
# Large reset area that catches players who fall off the map
# This should be placed below the map to catch falling players
extends Area3D

# Export the NodePath to make it easier to assign your player's XROrigin3D
@export var player_node_path: NodePath = NodePath("../XROrigin3D")
@export var reset_position: Vector3 = Vector3(0, 4, 0)  # Where to reset player
@export var fade_duration: float = 0.5
@export var show_debug_mesh: bool = false  # Show red debug area

var player_node: Node3D
var is_currently_resetting: bool = false
var debug_mesh: MeshInstance3D

func _ready():
	print("ResetArea3D: Initializing large reset area...")
	
	# Get the player node instance
	if not player_node_path.is_empty():
		var node = get_node_or_null(player_node_path)
		if node is Node3D:
			player_node = node
			print("ResetArea3D: Found player node: %s" % player_node.name)
		else:
			print("ResetArea3D: Player node at path '%s' not found or is not a Node3D." % player_node_path)
	else:
		# Try to find player automatically
		_find_player_automatically()
	
	# Setup debug visualization
	debug_mesh = find_child("DebugMesh")
	if debug_mesh:
		debug_mesh.visible = show_debug_mesh
	
	# Ensure the signal is connected
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		body_entered.connect(_on_body_entered)
		print("ResetArea3D: Connected body_entered signal")
	
	# Debug the setup
	_debug_setup()

func _find_player_automatically():
	"""Try to find the player node automatically"""
	print("ResetArea3D: Searching for player automatically...")
	
	# Look for XR-Tools PlayerBody first
	var player_body = get_tree().get_first_node_in_group("player_body")
	if player_body:
		player_node = player_body.get_parent()  # Usually XROrigin3D
		print("ResetArea3D: Found XR-Tools player: %s" % player_node.name)
		return
	
	# Look for common player node names
	var scene_root = get_tree().current_scene
	var potential_players = [
		scene_root.find_child("XROrigin3D", true, false),
		scene_root.find_child("VROrigin", true, false),
		scene_root.find_child("Player", true, false),
		get_tree().get_first_node_in_group("player")
	]
	
	for potential_player in potential_players:
		if potential_player and potential_player is Node3D:
			player_node = potential_player as Node3D
			print("ResetArea3D: Found player: %s" % player_node.name)
			return
	
	print("ResetArea3D: ❌ Could not find player node automatically!")

func _debug_setup():
	"""Debug the reset area setup"""
	print("=== RESET AREA DEBUG ===")
	print("Position: %s" % global_position)
	print("Size: %s" % _get_collision_size())
	print("Player node: %s" % (player_node.name if player_node else "NOT FOUND"))
	print("Collision layer: %d" % collision_layer)
	print("Collision mask: %d" % collision_mask)
	print("Monitoring: %s" % monitoring)
	print("========================")

func _get_collision_size() -> Vector3:
	"""Get the size of the collision shape"""
	var collision_shape = find_child("CollisionShape3D")
	if collision_shape and collision_shape.shape is BoxShape3D:
		var box_shape = collision_shape.shape as BoxShape3D
		return box_shape.size
	return Vector3.ZERO

func _on_body_entered(body: Node3D) -> void:
	if is_currently_resetting:
		return  # Already processing a reset
	
	# DEBUG: Show what body entered
	print("ResetArea3D: 🔍 Body entered reset area: %s (type: %s)" % [body.name, body.get_class()])
	print("ResetArea3D: 🔍 Body groups: %s" % body.get_groups())
	print("ResetArea3D: 🔍 Body position: %s" % body.global_position)
	
	if not player_node:
		print("ResetArea3D: ❌ Player node not assigned. Cannot reset.")
		return
	
	# Check if the body that entered is the player or part of the player
	var entered_body_is_player = _is_player_body(body)
	
	print("ResetArea3D: 🔍 Is player body? %s" % entered_body_is_player)
	
	if not entered_body_is_player:
		print("ResetArea3D: Non-player body entered, ignoring.")
		return
	
	print("ResetArea3D: ⚠️ PLAYER FELL OFF MAP - INITIATING RESET!")
	print("ResetArea3D: ⚠️ Player fell from position: %s" % body.global_position)
	
	is_currently_resetting = true
	_perform_reset()

func _is_player_body(body: Node3D) -> bool:
	"""Check if the entered body belongs to the player"""
	if not body:
		return false
	
	# Check if it's the player node itself
	if body == player_node:
		return true
	
	# Check if it's in player groups
	if body.has_method("is_in_group"):
		if body.is_in_group("player_body") or body.is_in_group("player"):
			return true
	
	# Check if it's a child of the player node
	if player_node and player_node.is_ancestor_of(body):
		return true
	
	# Check if it's the parent of the player node (for XR-Tools setup)
	if body.get_parent() == player_node:
		return true
	
	# Check for XR-Tools PlayerBody
	if body.get_class() == "XRToolsPlayerBody":
		return true
	
	# Check for common player body types
	if body is CharacterBody3D or body is RigidBody3D:
		if "player" in body.name.to_lower():
			return true
	
	return false

func _perform_reset():
	"""Perform the reset sequence"""
	print("ResetArea3D: Starting reset sequence...")
	
	# 1. Fade out (optional)
	await _perform_fade(false, fade_duration)
	
	# 2. Reset player position
	if is_instance_valid(player_node):
		print("ResetArea3D: Resetting player position from %s to %s" % [player_node.global_position, reset_position])
		player_node.global_position = reset_position
		
		# If player has velocity (CharacterBody3D/RigidBody3D), reset it
		var player_body = _find_player_physics_body()
		if player_body:
			if player_body is CharacterBody3D:
				player_body.velocity = Vector3.ZERO
			elif player_body is RigidBody3D:
				player_body.linear_velocity = Vector3.ZERO
				player_body.angular_velocity = Vector3.ZERO
		
		print("ResetArea3D: ✅ Player position reset successfully")
	else:
		print("ResetArea3D: ❌ Player node became invalid during reset")
		is_currently_resetting = false
		return
	
	# 3. Fade in
	await _perform_fade(true, fade_duration)
	
	print("ResetArea3D: Reset sequence complete.")
	is_currently_resetting = false

func _find_player_physics_body():
	"""Find the player's physics body for velocity reset"""
	if not player_node:
		return null
	
	# Check if player node itself is a physics body
	if player_node is CharacterBody3D or player_node is RigidBody3D:
		return player_node
	
	# Look for physics body in children
	for child in player_node.get_children():
		if child is CharacterBody3D or child is RigidBody3D:
			return child
	
	# Look for XR-Tools PlayerBody
	var player_body = player_node.find_child("PlayerBody", true, false)
	if player_body:
		return player_body
	
	return null

func _perform_fade(fade_in: bool, duration: float) -> void:
	"""Perform fade effect (placeholder - implement your own fade system)"""
	var action = "Fading In" if fade_in else "Fading Out"
	print("ResetArea3D: %s over %s seconds." % [action, duration])
	
	# --- Integrate your actual fade logic here ---
	# Example with a hypothetical fade manager:
	# var fade_manager = get_node_or_null("/root/FadeManager")
	# if fade_manager:
	#     if fade_in:
	#         await fade_manager.fade_in(duration)
	#     else:
	#         await fade_manager.fade_out(duration)
	#     return
	
	# Simple timer fallback if no fade system
	await get_tree().create_timer(duration).timeout

# Public API methods
func set_reset_position(pos: Vector3):
	"""Set where the player should be reset to"""
	reset_position = pos
	print("ResetArea3D: Reset position set to: %s" % reset_position)

func set_debug_visibility(visible: bool):
	"""Show/hide the debug mesh"""
	show_debug_mesh = visible
	if debug_mesh:
		debug_mesh.visible = visible



func test_detection():
	"""Test what's currently in the reset area"""
	print("=== RESET AREA DETECTION TEST ===")
	var bodies = get_overlapping_bodies()
	print("Bodies currently in reset area: %d" % bodies.size())
	for body in bodies:
		print("  - %s (%s) groups: %s" % [body.name, body.get_class(), body.get_groups()])
		print("    Is player: %s" % _is_player_body(body))
	print("=================================")
