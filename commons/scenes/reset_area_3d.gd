extends Area3D

# Export the NodePath to make it easier to assign your player's XROrigin3D (or equivalent) node
@export var player_node_path: NodePath = NodePath("../../XROrigin3D") # Adjust default if needed

# --- For Fading ---
# If you have a global fade manager/CanvasLayer, get its reference here.
# Example: @onready var screen_fader = get_node("/root/ScreenFader")
# For VR, this is often a sphere around the camera or a post-process shader.
# For this example, _perform_fade will be a placeholder.

var player_node: Node3D
var is_currently_resetting: bool = false # To prevent multiple triggers at once

func _ready():
	# Get the player node instance
	if not player_node_path.is_empty():
		var node = get_node_or_null(player_node_path)
		if node is Node3D:
			player_node = node
		else:
			printerr("ResetArea3D: Player node at path '%s' not found or is not a Node3D." % player_node_path)
	else:
		printerr("ResetArea3D: Player node path is not set.")

	# Ensure the signal is connected (can also be done in the editor)
	# Check if already connected to avoid duplicate connections if _ready is called multiple times (rare)
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))


func _on_body_entered(body: Node3D) -> void:
	if is_currently_resetting:
		return # Already processing a reset, ignore further entries

	if not player_node:
		printerr("ResetArea3D: Player node is not assigned. Cannot reset.")
		return

	# Check if the body that entered is the player or part of the player's physics setup.
	# This condition might need to be more specific based on your player's structure.
	# For example, if player_node is the XROrigin3D, the 'body' might be a child CharacterBody3D or Area3D.
	# Using groups is a common way: if body.is_in_group("player_physics_body"):
	var entered_body_is_player: bool = false
	if body == player_node: # If the player_node itself is the one with the collision body
		entered_body_is_player = true
	elif body.is_in_group("player_body"): # If the colliding body is in the "player_body" group
		entered_body_is_player = true
	# Or, if player_node is an ancestor of body:
	# elif player_node.is_ancestor_of(body):
	#     entered_body_is_player = true
	
	if not entered_body_is_player:
		print_debug("ResetArea3D: Non-player body entered, ignoring.")
		return

	is_currently_resetting = true
	print("ResetArea3D: Player entered. Initiating reset sequence...")

	# 1. Fade Out
	await _perform_fade(false, 0.5) # Fade to opaque (e.g., black) over 0.5 seconds

	# 2. Reset Player Position
	# Ensure player_node is still valid after the await (it could have been freed)
	if is_instance_valid(player_node):
		player_node.global_position = Vector3(0, 4, 0)
		# If your player is a CharacterBody3D, you might also want to reset its velocity:
		# if player_node is CharacterBody3D:
		#     player_node.velocity = Vector3.ZERO
		print("ResetArea3D: Player position reset to (0, 4, 0).")
	else:
		printerr("ResetArea3D: Player node became invalid during fade out. Aborting reset.")
		is_currently_resetting = false
		return

	# 3. Fade In
	await _perform_fade(true, 0.5) # Fade to clear over 0.5 seconds

	print("ResetArea3D: Reset sequence complete.")
	is_currently_resetting = false


# Placeholder function for your screen/VR fading logic
# fade_in: bool (true to fade from black to clear, false to fade from clear to black)
# duration: float (duration of the fade in seconds)
func _perform_fade(fade_in: bool, duration: float) -> void:
	var target_alpha = 1.0 if not fade_in else 0.0
	var current_state = "Fading Out" if not fade_in else "Fading In"
	print("ResetArea3D: %s over %s seconds." % [current_state, duration])

	# --- Integrate your actual fade logic here ---
	# Example using a hypothetical global singleton 'ScreenFader':
	# if ScreenFader:
	#	 if fade_in:
	#		 await ScreenFader.fade_in(duration)
	#	 else:
	#		 await ScreenFader.fade_out(duration)
	#	 return
	
	# Example using a ColorRect on a CanvasLayer (for 2D screen fade):
	# var fade_rect = get_node_or_null("/root/MyGlobalCanvasLayer/FadeColorRect")
	# if fade_rect:
	#	 var tween = get_tree().create_tween()
	#	 tween.tween_property(fade_rect, "modulate:a" if fade_in else "modulate:a", target_alpha, duration)
	#	 await tween.finished
	#	 return

	# If you don't have a fade system yet, this will just simulate the delay:
	await get_tree().create_timer(duration).timeout
	print("ResetArea3D: Fade/delay finished.")
