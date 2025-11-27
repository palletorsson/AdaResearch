# MovePlayerController.gd
# Move Player Utility - Utility type "m"
# Moves the player to a specific location after a delay

extends Node3D

@export var xr_origin_path: NodePath = NodePath("../../XROrigin3D")
@export var move_delay: float = 0.5
@export var move_target: Vector3 = Vector3.ZERO
@export var activation_method: String = "proximity"  # "proximity" or "touch"

var player_node: Node3D
var xr_origin: Node3D
var is_moving: bool = false
var player_in_area: bool = false

# Signals
signal player_move_started(target: Vector3)
signal player_move_complete()

# Area3D for detection
@onready var move_area: Area3D = $MoveArea

func _ready():
	print("MovePlayerController: Initializing move player utility...")

	# Find player and XR origin
	_find_player_node()
	_find_xr_origin()

	# Setup move area collision detection
	_setup_move_area()

	print("MovePlayerController: Move player utility ready (target: %s, delay: %.1fs)" % [move_target, move_delay])

func _setup_move_area():
	"""Setup the Area3D for proper collision detection with XR-Tools PlayerBody"""
	if not move_area:
		push_error("MovePlayerController: MoveArea not found! Scene structure incorrect.")
		return

	print("MovePlayerController: Setting up move area collision detection...")

	# CRITICAL: Set collision mask to detect Player Body (layer 20 in XR-Tools)
	# Layer 20 = 2^19 = 524288
	move_area.collision_layer = 0  # This area doesn't provide collision
	move_area.collision_mask = 1048576  # Detect layer 20 (Player Body)

	# Enable monitoring
	move_area.monitoring = true
	move_area.monitorable = false  # Other areas don't need to detect this

	# Connect signals
	if not move_area.is_connected("body_entered", Callable(self, "_on_move_area_body_entered")):
		move_area.body_entered.connect(_on_move_area_body_entered)
		print("MovePlayerController: ✅ Connected body_entered signal")

	if not move_area.is_connected("body_exited", Callable(self, "_on_move_area_body_exited")):
		move_area.body_exited.connect(_on_move_area_body_exited)
		print("MovePlayerController: ✅ Connected body_exited signal")

	print("MovePlayerController: Move area collision_layer=%d, collision_mask=%d" % [move_area.collision_layer, move_area.collision_mask])

func _find_player_node():
	"""Find the player node - specifically the XR-Tools PlayerBody"""
	# Look for XR-Tools PlayerBody first (most likely in VR)
	var player_body = get_tree().get_first_node_in_group("player_body")
	if player_body:
		player_node = player_body as Node3D
		print("MovePlayerController: Found XR-Tools PlayerBody: %s" % player_node.name)
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
			print("MovePlayerController: Found fallback player node: %s" % player_node.name)
			return

	print("MovePlayerController: WARNING - No player node found!")

func _find_xr_origin():
	"""Find the XROrigin3D node"""
	# Try using the exported path first
	if not xr_origin_path.is_empty():
		xr_origin = get_node_or_null(xr_origin_path)
		if xr_origin:
			print("MovePlayerController: Found XROrigin3D via path: %s" % xr_origin.name)
			return

	# Search for XROrigin3D in the scene
	xr_origin = get_tree().current_scene.find_child("XROrigin3D", true, false)
	if xr_origin:
		print("MovePlayerController: Found XROrigin3D: %s" % xr_origin.name)
		return

	print("MovePlayerController: WARNING - No XROrigin3D found!")

# SIGNAL HANDLERS
func _on_move_area_body_entered(body: Node3D):
	"""Handle player entering the move area"""
	print("MovePlayerController: 🔍 BODY ENTERED MOVE AREA: %s (type: %s)" % [body.name, body.get_class()])

	# Check if it's the player body
	if _is_player_body(body):
		print("MovePlayerController: ✅ PLAYER DETECTED IN MOVE AREA!")
		player_in_area = true

		if activation_method == "proximity":
			# Auto-activate on proximity
			_activate_move()
		else:
			# Wait for manual activation
			print("MovePlayerController: Player in area, waiting for activation...")
	else:
		print("MovePlayerController: ❌ Not recognized as player body")

func _on_move_area_body_exited(body: Node3D):
	"""Handle player exiting the move area"""
	if _is_player_body(body):
		print("MovePlayerController: Player exited move area")
		player_in_area = false

func _is_player_body(body: Node3D) -> bool:
	"""Check if the body is the player"""
	if not body:
		return false

	# Check if it's in the player_body group (XR-Tools)
	if body.has_method("is_in_group") and body.is_in_group("player_body"):
		return true

	# Check if it's in the player group
	if body.has_method("is_in_group") and body.is_in_group("player"):
		return true

	# Check if it matches our found player node
	if player_node and (body == player_node or body.get_parent() == player_node):
		return true

	# Check for XR-Tools PlayerBody class
	if body.get_class() == "XRToolsPlayerBody":
		return true

	# Check if it's a CharacterBody3D (common for players)
	if body is CharacterBody3D:
		return true

	return false

func _activate_move():
	"""Activate the player move"""
	if is_moving:
		print("MovePlayerController: Already moving, ignoring activation")
		return

	print("MovePlayerController: 🚀 PLAYER MOVE ACTIVATED! Target: %s, Delay: %.1fs" % [move_target, move_delay])
	is_moving = true
	player_move_started.emit(move_target)

	# Start move sequence
	_perform_move()

func _perform_move():
	"""Perform the actual player move after delay"""
	print("MovePlayerController: Waiting %.1f seconds before moving..." % move_delay)

	# Wait for delay
	if move_delay > 0:
		await get_tree().create_timer(move_delay).timeout

	# Move the XROrigin3D
	_execute_move()

func _execute_move():
	"""Execute the player move using the same approach as ResetTeleporter"""
	if not player_node:
		print("MovePlayerController: ❌ Cannot execute move - Player not found!")
		is_moving = false
		return

	print("MovePlayerController: Moving player to %s" % move_target)

	# Reset velocity on player body and root
	_reset_velocity(player_node)

	# Find the player root (XROrigin3D)
	var player_root = _find_player_root(player_node)

	if player_root:
		# Move the player root
		player_root.global_position = move_target
		print("MovePlayerController: ✅ Moved player root '%s' to %s" % [player_root.name, move_target])
	else:
		print("MovePlayerController: ⚠️ Could not find player root, moving player node directly")
		player_node.global_position = move_target

	is_moving = false
	player_move_complete.emit()
	print("MovePlayerController: ✅ Player move complete!")

# Reset velocity on both the body and player root
func _reset_velocity(body: Node3D):
	"""Reset velocity on the player body and root"""
	# Reset velocity on the body
	if "velocity" in body:
		body.velocity = Vector3.ZERO
	if "linear_velocity" in body:
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO

	# Reset velocity on the player root too
	var player_root = _find_player_root(body)
	if player_root and player_root != body:
		if "velocity" in player_root:
			player_root.velocity = Vector3.ZERO
		if "linear_velocity" in player_root:
			player_root.linear_velocity = Vector3.ZERO
			player_root.angular_velocity = Vector3.ZERO

# Find the player root (XROrigin3D) from a player body
func _find_player_root(body: Node3D) -> Node3D:
	"""Walk up the tree to find XROrigin or player root"""
	var current = body
	while current:
		if current.is_in_group("player") or current.name.contains("XROrigin"):
			return current
		current = current.get_parent()
	return body

# Public API - Called by GridUtilitiesComponent
func set_move_parameters(target: Vector3, delay: float):
	"""Set move parameters from grid utilities"""
	move_target = target
	move_delay = delay
	print("MovePlayerController: Parameters set - Target: %s, Delay: %.1fs" % [target, delay])

# Public API for manual triggering
func force_move():
	"""Force player move immediately (for testing)"""
	print("MovePlayerController: FORCE MOVE triggered")
	_activate_move()

# Debug input for testing
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_M:
			print("MovePlayerController: 🔧 MANUAL MOVE TRIGGERED (M key)")
			_activate_move()
