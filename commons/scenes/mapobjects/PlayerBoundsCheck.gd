class_name PlayerBoundsCheck extends Node3D

## Checks if the player exceeds specific spatial boundaries and resets them.
## "Combined abs vector" (Manhattan distance) or simple Box bounds.

enum CheckType {
	BOX,               ## Simple box check: inside -bounds to +bounds (fastest for square maps)
	MANHATTAN,         ## Combined abs magnitude: |x|+|y|+|z| > limit (fast, diamond shape)
	EUCLIDEAN_SQUARED  ## Spherical check: dist^2 > limit^2 (fast, spherical shape)
}

@export_group("Settings")
@export var active: bool = true
## How often to check (in seconds). 0 = every frame.
@export var check_interval: float = 1.0 
@export var check_type: CheckType = CheckType.BOX

@export_group("Limits")
## Dimensions for BOX mode (e.g., 10 means -10 to 10)
@export var box_bounds: Vector3 = Vector3(10.0, 10.0, 10.0)
## Limit for MANHATTAN or EUCLIDEAN modes
@export var scalar_limit: float = 30.0

@export_group("Reset")
@export var reset_position: Vector3 = Vector3(0.0, 1.0, 0.0)
@export var reset_velocity: bool = true

var player_node: Node3D
var _timer: float = 0.0
var is_resetting: bool = false

func _ready():
	_find_player_node()

func _physics_process(delta):
	if not active:
		return
		
	# Timer check
	if check_interval > 0:
		_timer += delta
		if _timer < check_interval:
			return
		_timer = 0.0
	
	if not is_instance_valid(player_node):
		_find_player_node()
		if not player_node:
			return

	var pos = player_node.global_position
	var out_of_bounds = false

	match check_type:
		CheckType.BOX:
			if abs(pos.x) > box_bounds.x or abs(pos.y) > box_bounds.y or abs(pos.z) > box_bounds.z:
				out_of_bounds = true
		
		CheckType.MANHATTAN:
			# "Combined abs vector"
			var combined_abs = abs(pos.x) + abs(pos.y) + abs(pos.z)
			if combined_abs > scalar_limit:
				out_of_bounds = true
				
		CheckType.EUCLIDEAN_SQUARED:
			if pos.length_squared() > (scalar_limit * scalar_limit):
				out_of_bounds = true

	if out_of_bounds:
		_reset_player()

func _reset_player():
	if is_resetting:
		return
		
	print("PlayerBoundsCheck: ⚠️ Player out of bounds! Initiating reset...")
	is_resetting = true
	
	# Find a target position if we haven't yet, or if we want to respect the scene's spawn
	var target_pos = reset_position
	var spawn_node = get_tree().current_scene.find_child("SpawnPoint", true, false)
	if spawn_node:
		target_pos = spawn_node.global_position
	
	# Reset velocity FIRST
	_reset_velocity(player_node)
	
	# Wait for physics frame to process velocity reset
	await get_tree().physics_frame
	
	# THEN teleport the root
	var root = _find_player_root(player_node)
	if root:
		root.global_position = target_pos
		print("PlayerBoundsCheck: Teleported player root '%s' to %s" % [root.name, target_pos])
	else:
		player_node.global_position = target_pos
		print("PlayerBoundsCheck: Teleported player node to %s" % target_pos)
	
	# Reset velocity AGAIN after teleport
	_reset_velocity(player_node)
	
	# Wait for physics frame to ensure position sticks
	await get_tree().physics_frame
	
	is_resetting = false

func _reset_velocity(body: Node3D):
	if "velocity" in body:
		body.velocity = Vector3.ZERO
	if "linear_velocity" in body:
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO

	var root = _find_player_root(body)
	if root and root != body:
		if "velocity" in root:
			root.velocity = Vector3.ZERO
		if "linear_velocity" in root:
			root.linear_velocity = Vector3.ZERO
			root.angular_velocity = Vector3.ZERO

func _find_player_root(body: Node3D) -> Node3D:
	if not body: return null
	var current = body
	while current:
		if current.is_in_group("player") or current.name.contains("XROrigin"):
			return current
		current = current.get_parent()
	return body

func _find_player_node():
	# Strategy 1: Look for XR Origin (common in VR)
	player_node = get_tree().get_first_node_in_group("player")
	
	if not player_node:
		# Strategy 2: Look for specific names
		var root = get_tree().current_scene
		if root:
			player_node = root.find_child("XROrigin3D", true, false)
			
	if not player_node:
		# Strategy 3: Look for CharacterBody3D or RigidBody3D that might be the player
		# Use the parent of the camera if possible
		var cam = get_viewport().get_camera_3d()
		if cam:
			var p = cam.get_parent()
			# Walk up to find the root physics body
			while p:
				if p is CharacterBody3D or p is RigidBody3D:
					player_node = p
					break
				p = p.get_parent()
				
	if player_node:
		print("PlayerBoundsCheck: Tracking player node '", player_node.name, "'")
