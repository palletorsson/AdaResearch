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
@export var reset_position: Vector3 = Vector3(0.0, 2.0, 0.0)  # Higher default
@export var reset_velocity: bool = true
@export var reset_cooldown: float = 2.0  # Seconds before allowing another reset

var player_node: Node3D
var _timer: float = 0.0
var is_resetting: bool = false
var _reset_cooldown_timer: float = 0.0

# Continuous stuck detection
var _post_reset_monitor_time: float = 0.0
var _post_reset_last_position: Vector3 = Vector3.ZERO
var _post_reset_stuck_checks: int = 0
const POST_RESET_MONITOR_DURATION: float = 3.0  # Monitor for 3 seconds after reset
const STUCK_MOVEMENT_THRESHOLD: float = 0.05  # Must move at least 5cm to be "not stuck"
const MAX_STUCK_FIXES: int = 3  # Max attempts to fix stuck position

func _ready():
	_find_player_node()

func _physics_process(delta):
	if not active:
		return

	# Continuous stuck detection after reset
	if _post_reset_monitor_time > 0:
		_post_reset_monitor_time -= delta
		_check_post_reset_stuck(delta)
		return

	# Cooldown after reset
	if _reset_cooldown_timer > 0:
		_reset_cooldown_timer -= delta
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
	_reset_cooldown_timer = reset_cooldown  # Start cooldown

	# Find a target position - use SpawnPoint but ensure Y is high enough
	var target_pos = reset_position
	var spawn_node = get_tree().current_scene.find_child("SpawnPoint", true, false)
	if spawn_node:
		target_pos = spawn_node.global_position
		# Ensure minimum height to avoid spawning underground
		if target_pos.y < 1.5:
			target_pos.y = 1.5

	# Try to find Fly Mode controller
	var flight_controller = _find_flight_controller(player_node)
	if flight_controller:
		print("PlayerBoundsCheck: Enabling Fly Mode to kill momentum")
		flight_controller.set_flying(true)

	# 1. Reset velocity immediately
	if reset_velocity:
		_reset_velocity(player_node)

	# 2. Teleport immediately (no physics frame wait - faster reset)
	var root = _find_player_root(player_node)
	if root:
		root.global_position = target_pos
		print("PlayerBoundsCheck: Teleported player root '%s' to %s" % [root.name, target_pos])
	else:
		player_node.global_position = target_pos

	# 3. Reset velocity again after teleport
	if reset_velocity:
		_reset_velocity(player_node)

	# 4. Wait one frame then check if stuck
	await get_tree().physics_frame

	if reset_velocity:
		_reset_velocity(player_node)

	# 5. Check if player is stuck inside geometry and try to fix
	await _check_and_fix_stuck_position(root if root else player_node, target_pos)

	# Disable Fly Mode
	if flight_controller:
		print("PlayerBoundsCheck: Disabling Fly Mode")
		flight_controller.set_flying(false)

	is_resetting = false

	# Start post-reset monitoring for stuck detection
	_start_post_reset_monitoring()

func _check_and_fix_stuck_position(player_root: Node3D, original_target: Vector3):
	"""Check if player is stuck inside geometry and try alternate positions"""
	if not player_root:
		return

	# Wait a frame for physics to settle
	await get_tree().physics_frame

	# Get the camera to check if it's inside something
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return

	# Use a raycast from slightly above to check if we're in solid geometry
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return

	var camera_pos = camera.global_position
	var check_pos = player_root.global_position

	# Cast ray from above player down to check for obstructions
	var ray_start = check_pos + Vector3(0, 2.0, 0)
	var ray_end = check_pos

	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = 1  # Check against world geometry (layer 1)
	query.exclude = _get_player_bodies(player_root)

	var result = space_state.intersect_ray(query)

	if result and result.position.y > check_pos.y + 0.5:
		# We're likely inside geometry - try moving up
		print("PlayerBoundsCheck: ⚠️ Player may be stuck! Attempting to fix...")

		# Try positions: up, then cardinal directions
		var offsets = [
			Vector3(0, 1.0, 0),   # Up
			Vector3(0, 2.0, 0),   # Higher up
			Vector3(1, 0.5, 0),   # Right + up
			Vector3(-1, 0.5, 0),  # Left + up
			Vector3(0, 0.5, 1),   # Forward + up
			Vector3(0, 0.5, -1),  # Back + up
		]

		for offset in offsets:
			var test_pos = original_target + offset
			if _is_position_clear(test_pos, space_state, player_root):
				player_root.global_position = test_pos
				print("PlayerBoundsCheck: ✅ Found clear position at offset %s" % offset)
				return

		# Last resort: move significantly higher
		player_root.global_position = original_target + Vector3(0, 3.0, 0)
		print("PlayerBoundsCheck: ⚠️ Moved player up 3m as fallback")

func _is_position_clear(pos: Vector3, space_state: PhysicsDirectSpaceState3D, player_root: Node3D) -> bool:
	"""Check if a position is clear of geometry"""
	# Check a small sphere around the position
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 0.3
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, pos + Vector3(0, 1.0, 0))  # Check at head height
	query.collision_mask = 1
	query.exclude = _get_player_bodies(player_root)

	var results = space_state.intersect_shape(query, 1)
	return results.is_empty()

func _get_player_bodies(player_root: Node3D) -> Array[RID]:
	"""Get RIDs of player physics bodies to exclude from collision checks"""
	var rids: Array[RID] = []
	if not player_root:
		return rids

	# Find all physics bodies in player hierarchy
	var bodies_to_check = [player_root]
	while not bodies_to_check.is_empty():
		var node = bodies_to_check.pop_back()
		if node is PhysicsBody3D:
			rids.append(node.get_rid())
		for child in node.get_children():
			bodies_to_check.append(child)

	return rids

func _find_flight_controller(start_node: Node) -> Node:
	var root = _find_player_root(start_node)
	if not root: return null
	return _find_flight_recursive(root)

func _find_flight_recursive(node: Node) -> Node:
	# Check for XRToolsMovementFlight using string check to avoid circular deps or class loading issues
	if node.has_method("is_xr_class") and node.is_xr_class("XRToolsMovementFlight"):
		return node
	# Also check script name as fallback
	if node.get_script() and node.get_script().resource_path.contains("movement_flight.gd"):
		return node
		
	for child in node.get_children():
		var found = _find_flight_recursive(child)
		if found: return found
	return null

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
		player_node = get_tree().get_first_node_in_group("player_body")

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

func _start_post_reset_monitoring():
	"""Start monitoring player position after reset to detect if still stuck"""
	if not is_instance_valid(player_node):
		return
	_post_reset_monitor_time = POST_RESET_MONITOR_DURATION
	_post_reset_last_position = player_node.global_position
	_post_reset_stuck_checks = 0
	print("PlayerBoundsCheck: Starting post-reset stuck monitoring")

func _check_post_reset_stuck(_delta: float):
	"""Check if player is stuck after reset (hasn't moved)"""
	if not is_instance_valid(player_node):
		_post_reset_monitor_time = 0.0
		return

	var current_pos = player_node.global_position
	var movement = current_pos.distance_to(_post_reset_last_position)

	# If player moved enough, they're not stuck
	if movement > STUCK_MOVEMENT_THRESHOLD:
		print("PlayerBoundsCheck: ✅ Player moved %.2fm, not stuck" % movement)
		_post_reset_monitor_time = 0.0
		_post_reset_stuck_checks = 0
		return

	# Check if monitor period ended and player still hasn't moved
	if _post_reset_monitor_time <= 0:
		_post_reset_stuck_checks += 1
		if _post_reset_stuck_checks < MAX_STUCK_FIXES:
			print("PlayerBoundsCheck: ⚠️ Player still stuck after reset! Attempt %d/%d" % [_post_reset_stuck_checks, MAX_STUCK_FIXES])
			_emergency_unstuck()
		else:
			print("PlayerBoundsCheck: ❌ Max stuck fix attempts reached. Player may need manual intervention.")
			_post_reset_stuck_checks = 0

func _emergency_unstuck():
	"""Emergency unstuck - try more aggressive position fixes"""
	var root = _find_player_root(player_node)
	if not root:
		root = player_node

	# Reset velocity first
	_reset_velocity(root)

	# Try progressively higher positions
	var base_pos = reset_position
	var spawn_node = get_tree().current_scene.find_child("SpawnPoint", true, false)
	if spawn_node:
		base_pos = spawn_node.global_position

	# Emergency offsets - more aggressive than normal
	var emergency_offsets = [
		Vector3(0, 2.0 + _post_reset_stuck_checks, 0),  # Higher each attempt
		Vector3(1.0, 1.5, 0),
		Vector3(-1.0, 1.5, 0),
		Vector3(0, 1.5, 1.0),
		Vector3(0, 1.5, -1.0),
		Vector3(0, 5.0, 0),  # Very high as last resort
	]

	var space_state = get_world_3d().direct_space_state
	if space_state:
		for offset in emergency_offsets:
			var test_pos = base_pos + offset
			if _is_position_clear(test_pos, space_state, root):
				root.global_position = test_pos
				_reset_velocity(root)
				print("PlayerBoundsCheck: 🚨 Emergency unstuck to %s" % test_pos)
				# Restart monitoring
				_post_reset_last_position = test_pos
				_post_reset_monitor_time = POST_RESET_MONITOR_DURATION
				return

	# Last resort - just move up
	root.global_position = base_pos + Vector3(0, 3.0 + _post_reset_stuck_checks * 2, 0)
	_reset_velocity(root)
	print("PlayerBoundsCheck: 🚨 Emergency fallback - moved player up significantly")
	_post_reset_last_position = root.global_position
	_post_reset_monitor_time = POST_RESET_MONITOR_DURATION
