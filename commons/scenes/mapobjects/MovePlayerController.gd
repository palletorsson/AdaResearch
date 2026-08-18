# MovePlayerController.gd
# Move Player Utility - Utility type "m"
# Automatically moves the player to a specific location after a delay

extends Node3D

@export var xr_origin_path: NodePath = NodePath("../../XROrigin3D")
@export var move_delay: float = 0.5
@export var move_target: Vector3 = Vector3.ZERO

var player_node: Node3D
var xr_origin: Node3D
var is_moving: bool = false

# Signals
signal player_move_started(target: Vector3)
signal player_move_complete()

func _ready():
	print("MovePlayerController: Initializing move player utility...")

	# Find player and XR origin
	_find_player_node()
	_find_xr_origin()

	print("MovePlayerController: Move player utility ready (target: %s, delay: %.1fs)" % [move_target, move_delay])
	print("MovePlayerController: Will automatically move player after %.1fs" % move_delay)
	
	# Automatically start the move sequence after delay
	_start_automatic_move()

func _start_automatic_move():
	"""Start the automatic move sequence"""
	# Wait for scene to fully initialize (physics, transforms, spawning)
	await get_tree().create_timer(1.0).timeout
	
	if not player_node:
		print("MovePlayerController: ❌ Cannot start move - Player not found!")
		return
	
	# Debug: log position chain up to root
	print("MovePlayerController: === POSITION DEBUG ===")
	print("MovePlayerController: local_pos=%s global_pos=%s" % [position, global_position])
	var node = self
	while node.get_parent():
		node = node.get_parent()
		if node is Node3D:
			print("MovePlayerController:   ancestor '%s' pos=%s global=%s" % [node.name, node.position, node.global_position])
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			return
		if node == get_tree().root:
			break
	
	# Use own global position + drop height as target
	move_target = global_position + Vector3(0, 2.0, 0)
	print("MovePlayerController: target=%s player_at=%s" % [move_target, player_node.global_position])
	print("MovePlayerController: ===================")
	
	print("MovePlayerController: Starting automatic move in %.1fs..." % move_delay)
	_activate_move()

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
	"""Execute the player move - properly synchronized with physics"""
	if not player_node:
		print("MovePlayerController: ❌ Cannot execute move - Player not found!")
		is_moving = false
		return

	print("MovePlayerController: Moving player to %s" % move_target)

	# CRITICAL: Reset velocity FIRST, before any position changes
	_reset_velocity(player_node)
	
	# Wait for the physics frame to process the velocity reset
	await get_tree().physics_frame

	# Use XRToolsPlayerBody.teleport() if available (proper XR teleport)
	_teleport_player_to(move_target)
	
	# Reset velocity AGAIN after the move to prevent physics from moving player away
	_reset_velocity(player_node)
	
	# Wait one more physics frame to ensure the position sticks
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().physics_frame

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

# Teleport player using XRToolsPlayerBody.teleport() if available, else fallback
func _teleport_player_to(target_pos: Vector3):
	var player_body = _find_xr_player_body()
	
	if player_body and player_body.has_method("teleport"):
		var target_transform = Transform3D()
		target_transform.origin = target_pos
		target_transform.basis = player_body.global_transform.basis  # Keep current rotation
		player_body.teleport(target_transform)
		player_body.velocity = Vector3.ZERO
		print("MovePlayerController: ✅ Used XRToolsPlayerBody.teleport() to %s" % target_pos)
	else:
		# Fallback to raw position set
		var player_root = _find_player_root(player_node)
		if player_root:
			player_root.global_position = target_pos
			print("MovePlayerController: ⚠️ Fallback - set global_position to %s" % target_pos)
		elif player_node:
			player_node.global_position = target_pos

# Find XRToolsPlayerBody in the tree
func _find_xr_player_body() -> Node3D:
	# Search in groups first
	var player_bodies = get_tree().get_nodes_in_group("player_body")
	for pb in player_bodies:
		if pb.has_method("teleport"):
			return pb
	
	# Find by name in scene
	var root = get_tree().current_scene
	if root:
		var pb = root.find_child("PlayerBody", true, false)
		if pb and pb.has_method("teleport"):
			return pb
	
	return null

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
