class_name PlayerBoundsCheck extends Node3D

## Checks if the player exceeds specific spatial boundaries and resets them.
## "Combined abs vector" (Manhattan distance) or simple Box bounds.

enum CheckType {
	BOX,               ## Simple box check: inside -bounds to +bounds (fastest for square maps)
	MANHATTAN,         ## Combined abs magnitude: |x|+|y|+|z| > limit (fast, diamond shape)
	EUCLIDEAN_SQUARED  ## Spherical check: dist^2 > limit^2 (fast, spherical shape)
}

enum ResetMode {
	LAST_SAFE_POSITION,  ## Reset to last tracked safe position (default)
	UTILITY_SPAWN        ## Reset to "s" utility spawn point from map
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
@export var reset_mode: ResetMode = ResetMode.LAST_SAFE_POSITION  ## Where to reset player
@export var reset_position: Vector3 = Vector3(0.0, 2.0, 0.0)  # Higher default (fallback)
@export var reset_velocity: bool = true
@export var reset_cooldown: float = 2.0  # Seconds before allowing another reset

@export_group("Safe Position Tracking")
## How often to save the player's safe position (seconds)
@export var safe_position_interval: float = 3.0
## Minimum height above ground to consider position safe
@export var min_safe_height: float = -5.0

var player_node: Node3D
var _timer: float = 0.0
var is_resetting: bool = false
var _reset_cooldown_timer: float = 0.0

# Safe position tracking - saves last known good position
var _last_safe_position: Vector3 = Vector3.ZERO
var _safe_position_timer: float = 0.0
var _has_safe_position: bool = false

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
	
	# Track safe position periodically
	_safe_position_timer += delta
	if _safe_position_timer >= safe_position_interval:
		_safe_position_timer = 0.0
		_try_save_safe_position()

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

	print("PlayerBoundsCheck: ⚠️ Player out of bounds! Resetting...")
	is_resetting = true
	_reset_cooldown_timer = reset_cooldown  # Start cooldown

	# Determine target position based on reset mode
	var target_pos = reset_position
	
	match reset_mode:
		ResetMode.UTILITY_SPAWN:
			# Try utility spawn first, then SpawnPoint node, then default
			var utility_spawn_pos = _find_utility_spawn_position()
			if utility_spawn_pos != Vector3.ZERO:
				target_pos = utility_spawn_pos
				print("PlayerBoundsCheck: Using utility spawn position: %s" % target_pos)
			else:
				var spawn_node = get_tree().current_scene.find_child("SpawnPoint", true, false)
				if spawn_node:
					target_pos = spawn_node.global_position
					print("PlayerBoundsCheck: Using SpawnPoint (no utility spawn): %s" % target_pos)
				else:
					print("PlayerBoundsCheck: Using default reset position (no spawn found): %s" % target_pos)
		
		ResetMode.LAST_SAFE_POSITION, _:
			# Prefer last safe position, then spawn point, then default
			if _has_safe_position:
				target_pos = _last_safe_position
				print("PlayerBoundsCheck: Using last safe position: %s" % target_pos)
			else:
				var spawn_node = get_tree().current_scene.find_child("SpawnPoint", true, false)
				if spawn_node:
					target_pos = spawn_node.global_position
					print("PlayerBoundsCheck: Using SpawnPoint: %s" % target_pos)
				else:
					print("PlayerBoundsCheck: Using default reset position: %s" % target_pos)
	
	# Ensure minimum height
	if target_pos.y < 1.0:
		target_pos.y = 1.0

	# Try to find Fly Mode controller
	var flight_controller = _find_flight_controller(player_node)
	if flight_controller:
		print("PlayerBoundsCheck: Enabling Fly Mode to kill momentum")
		flight_controller.set_flying(true)

	# 1. Reset velocity immediately
	if reset_velocity:
		_reset_velocity(player_node)

	# 2. Teleport immediately using proper XR teleport
	_teleport_player_to(target_pos)

	# 3. Reset velocity again after teleport
	if reset_velocity:
		_reset_velocity(player_node)

	# 4. Wait one frame then check if stuck
	await get_tree().physics_frame

	if reset_velocity:
		_reset_velocity(player_node)

	# 5. Check if player is stuck inside geometry and try to fix
	var player_root = _find_player_root(player_node)
	await _check_and_fix_stuck_position(player_root if player_root else player_node, target_pos)

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
				_teleport_player_to(test_pos)
				print("PlayerBoundsCheck: ✅ Found clear position at offset %s" % offset)
				return

		# Last resort: move significantly higher
		_teleport_player_to(original_target + Vector3(0, 3.0, 0))
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

func _teleport_player_to(target_pos: Vector3):
	"""Teleport player using XRToolsPlayerBody.teleport() if available, else fallback"""
	var player_body = _find_xr_player_body()
	
	if player_body and player_body.has_method("teleport"):
		# Use XR Tools proper teleport
		var target_transform = Transform3D()
		target_transform.origin = target_pos
		target_transform.basis = player_body.global_transform.basis  # Keep current rotation
		player_body.teleport(target_transform)
		player_body.velocity = Vector3.ZERO
		print("PlayerBoundsCheck: Used XRToolsPlayerBody.teleport() to %s" % target_pos)
	else:
		# Fallback to raw position set
		var root = _find_player_root(player_node)
		if root:
			root.global_position = target_pos
			print("PlayerBoundsCheck: Fallback - set position to %s" % target_pos)
		elif player_node:
			player_node.global_position = target_pos

func _find_xr_player_body() -> Node3D:
	"""Find XRToolsPlayerBody in the tree"""
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

func _try_save_safe_position():
	"""Try to save the player's current position as a safe fallback position"""
	if not is_instance_valid(player_node):
		_find_player_node()
		if not player_node:
			return
	
	var root = _find_player_root(player_node)
	if not root:
		return
	
	var current_pos = root.global_position
	
	# Check if current position is valid (within bounds and above minimum height)
	var is_valid = _is_position_in_bounds(current_pos) and current_pos.y > min_safe_height
	
	# Also verify there's ground below (not falling through void)
	if is_valid:
		is_valid = _has_ground_below(current_pos)
	
	if is_valid:
		_last_safe_position = current_pos
		_has_safe_position = true
		# Uncomment for debug: print("PlayerBoundsCheck: 📍 Saved safe position: %s" % current_pos)

func _is_position_in_bounds(pos: Vector3) -> bool:
	"""Check if a position is within the defined bounds"""
	match check_type:
		CheckType.BOX:
			return abs(pos.x) <= box_bounds.x and abs(pos.y) <= box_bounds.y and abs(pos.z) <= box_bounds.z
		CheckType.MANHATTAN:
			return (abs(pos.x) + abs(pos.y) + abs(pos.z)) <= scalar_limit
		CheckType.EUCLIDEAN_SQUARED:
			return pos.length_squared() <= (scalar_limit * scalar_limit)
	return true

func _has_ground_below(pos: Vector3) -> bool:
	"""Check if there's solid ground below the position"""
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return true  # Assume valid if we can't check
	
	var ray_query = PhysicsRayQueryParameters3D.create(
		pos + Vector3(0, 0.5, 0),
		pos + Vector3(0, -10.0, 0)
	)
	ray_query.collision_mask = 1
	
	var result = space_state.intersect_ray(ray_query)
	return result != null and not result.is_empty()

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
				_teleport_player_to(test_pos)
				print("PlayerBoundsCheck: 🚨 Emergency unstuck to %s" % test_pos)
				# Restart monitoring
				_post_reset_last_position = test_pos
				_post_reset_monitor_time = POST_RESET_MONITOR_DURATION
				return

	# Last resort - just move up
	var fallback_pos = base_pos + Vector3(0, 3.0 + _post_reset_stuck_checks * 2, 0)
	_teleport_player_to(fallback_pos)
	print("PlayerBoundsCheck: 🚨 Emergency fallback - moved player up significantly")
	_post_reset_last_position = fallback_pos
	_post_reset_monitor_time = POST_RESET_MONITOR_DURATION

func _ensure_safe_spawn_position(player_root: Node3D):
	"""Ensure player is on safe ground, not inside geometry or outside grid"""
	if not player_root:
		return
	
	var current_pos = player_root.global_position
	print("PlayerBoundsCheck: Checking spawn safety at %s" % current_pos)
	
	# Get physics space state
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return
	
	# Check if player is inside geometry at multiple heights
	var is_inside_geometry = _check_if_inside_geometry(space_state, current_pos, player_root)
	
	# Check if player is above ground (has solid ground below)
	var ground_check = _find_ground_below(space_state, current_pos, player_root)
	
	if is_inside_geometry or not ground_check.has_ground:
		print("PlayerBoundsCheck: ⚠️ Player in unsafe position - inside_geo=%s, has_ground=%s" % [is_inside_geometry, ground_check.has_ground])
		_move_to_safe_ground(player_root, space_state)
	else:
		# Player is safe but might be floating - snap to ground if close
		if ground_check.has_ground and ground_check.distance < 3.0:
			var safe_y = ground_check.position.y + 0.2  # Slightly above ground
			if abs(current_pos.y - safe_y) > 0.5:
				var snap_pos = Vector3(current_pos.x, safe_y, current_pos.z)
				_teleport_player_to(snap_pos)
				print("PlayerBoundsCheck: Snapped player to ground at y=%.2f" % safe_y)
		print("PlayerBoundsCheck: ✅ Player in safe position")

func _check_if_inside_geometry(space_state: PhysicsDirectSpaceState3D, pos: Vector3, player_root: Node3D) -> bool:
	"""Check if player position is inside solid geometry"""
	var check_heights = [0.1, 0.8, 1.5]  # feet, torso, head
	
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 0.25
	query.shape = sphere
	query.collision_mask = 1  # World geometry layer
	query.exclude = _get_player_bodies(player_root)
	
	for height in check_heights:
		query.transform = Transform3D(Basis.IDENTITY, pos + Vector3(0, height, 0))
		var results = space_state.intersect_shape(query, 1)
		if results.size() > 0:
			return true
	
	return false

func _find_ground_below(space_state: PhysicsDirectSpaceState3D, pos: Vector3, player_root: Node3D) -> Dictionary:
	"""Find ground below player position"""
	var ray_query = PhysicsRayQueryParameters3D.create(
		pos + Vector3(0, 0.5, 0),  # Start slightly above feet
		pos + Vector3(0, -50.0, 0)  # Check far below
	)
	ray_query.collision_mask = 1
	ray_query.exclude = _get_player_bodies(player_root)
	
	var result = space_state.intersect_ray(ray_query)
	
	if result:
		return {
			"has_ground": true,
			"position": result.position,
			"distance": pos.y - result.position.y
		}
	
	return {"has_ground": false, "position": Vector3.ZERO, "distance": INF}

func _move_to_safe_ground(player_root: Node3D, space_state: PhysicsDirectSpaceState3D):
	"""Move player to a safe position on solid ground, avoiding enclosing objects"""
	print("PlayerBoundsCheck: 🔄 Finding safe ground for player...")
	
	# Get grid system for spawn data and bounds
	var grid_system = _find_grid_system()
	var grid_bounds = Vector3(10, 10, 10)  # Default
	var spawn_from_json = Vector3(1.5, 1.2, 1.5)  # Default safe position on grid
	
	if grid_system:
		if "structure_component" in grid_system and grid_system.structure_component:
			var dims = grid_system.structure_component.get_grid_dimensions()
			grid_bounds = Vector3(dims.x, dims.y, dims.z)
		
		# Try to get spawn position from data component
		if "data_component" in grid_system and grid_system.data_component:
			var spawn_points = grid_system.data_component.get_spawn_points()
			if spawn_points and spawn_points.has("default"):
				var default_spawn = spawn_points["default"]
				if default_spawn.has("position"):
					var pos = default_spawn["position"]
					spawn_from_json = Vector3(pos[0], pos[1], pos[2])
					print("PlayerBoundsCheck: Using spawn from JSON: %s" % spawn_from_json)
	
	# Also check for SpawnPoint node
	var spawn_point = get_tree().current_scene.find_child("SpawnPoint", true, false)
	var base_pos = spawn_from_json
	if spawn_point:
		base_pos = spawn_point.global_position
	
	# Build list of test positions - prioritize positions on the grid floor
	# Avoid the center/far areas where large objects like DarkSphere might be
	var test_positions = [
		spawn_from_json,  # JSON spawn point (should be safe)
		base_pos,  # SpawnPoint node position
		Vector3(1, 2, 1),  # Near origin corner (usually safe)
		Vector3(2, 2, 1),
		Vector3(1, 2, 2),
		Vector3(2, 2, 2),
		base_pos + Vector3(0, 2, 0),  # Elevated base
	]
	
	# Add more positions along the edges of the grid (less likely to have enclosing objects)
	for x in range(0, int(grid_bounds.x), 2):
		test_positions.append(Vector3(x, 2, 0))
		test_positions.append(Vector3(x, 2, 1))
	
	for test_pos in test_positions:
		# Check if this position is clear of collision geometry
		if not _check_if_inside_geometry(space_state, test_pos, player_root):
			# Also check if we're inside any large mesh (like DarkSphere) by raycast test
			if not _is_inside_enclosing_mesh(test_pos):
				# Find ground below this position
				var ground = _find_ground_below(space_state, test_pos, player_root)
				if ground.has_ground and ground.distance < 10.0:  # Must have ground within 10m
					var safe_pos = Vector3(test_pos.x, ground.position.y + 0.2, test_pos.z)
					_teleport_player_to(safe_pos)
					print("PlayerBoundsCheck: ✅ Moved player to safe ground at %s" % safe_pos)
					return
	
	# Last resort: teleport to JSON spawn position elevated
	var final_pos = spawn_from_json + Vector3(0, 2, 0)
	_teleport_player_to(final_pos)
	print("PlayerBoundsCheck: ⚠️ Used elevated spawn fallback at %s" % final_pos)

func _is_inside_enclosing_mesh(pos: Vector3) -> bool:
	"""Check if position is inside a large enclosing mesh like DarkSphere by raycasting outward"""
	# If we raycast in multiple directions and ALL hit something close, we're probably enclosed
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return false
	
	var directions = [
		Vector3(1, 0, 0), Vector3(-1, 0, 0),
		Vector3(0, 1, 0), Vector3(0, -1, 0),
		Vector3(0, 0, 1), Vector3(0, 0, -1)
	]
	
	var hits_count = 0
	var check_distance = 5.0  # If all directions hit within 5m, we're probably enclosed
	
	for dir in directions:
		var ray_query = PhysicsRayQueryParameters3D.create(pos, pos + dir * check_distance)
		ray_query.collision_mask = 1
		var result = space_state.intersect_ray(ray_query)
		if result:
			hits_count += 1
	
	# If most directions hit something close, we're likely inside an enclosing mesh
	# But we need to be careful - this could also be a small room
	# Only consider it "enclosed" if we hit in ALL directions
	var is_enclosed = (hits_count >= 5)
	if is_enclosed:
		print("PlayerBoundsCheck: ⚠️ Position %s appears to be inside enclosing mesh (%d/6 directions blocked)" % [pos, hits_count])
	
	return is_enclosed

func _find_grid_system() -> Node:
	"""Find the GridSystem in the scene tree"""
	# Try common names
	var grid_system = get_tree().current_scene.find_child("GridSystem", true, false)
	if grid_system:
		return grid_system
	
	# Try to find by class/group
	var nodes_in_group = get_tree().get_nodes_in_group("grid_system")
	if nodes_in_group.size() > 0:
		return nodes_in_group[0]
	
	# Try to find any node with reload_map property
	return _find_node_with_property(get_tree().current_scene, "reload_map")

func _find_node_with_property(node: Node, property_name: String) -> Node:
	"""Recursively find a node that has a specific property"""
	if property_name in node:
		return node
	
	for child in node.get_children():
		var result = _find_node_with_property(child, property_name)
		if result:
			return result
	
	return null

func _find_utility_spawn_position() -> Vector3:
	"""Find spawn position from 's' utility in map data"""
	var grid_system = _find_grid_system()
	if not grid_system:
		print("PlayerBoundsCheck: No GridSystem found for utility spawn lookup")
		return Vector3.ZERO
	
	# Get cube_size and gutter for coordinate conversion
	var cube_size = 1.0
	var gutter = 0.0
	if "data_component" in grid_system and grid_system.data_component:
		var settings = grid_system.data_component.get_settings()
		cube_size = settings.get("cube_size", 1.0)
		gutter = settings.get("gutter", 0.0)
	
	# Find GridUtilitiesComponent
	var utilities_component = grid_system.find_child("GridUtilitiesComponent", false, false)
	if not utilities_component:
		print("PlayerBoundsCheck: No GridUtilitiesComponent found")
		return Vector3.ZERO
	
	# Get all utility positions and look for spawn_coordinates metadata
	if utilities_component.has_method("get_all_utility_positions"):
		var utility_positions = utilities_component.get_all_utility_positions()
		for pos in utility_positions:
			if utilities_component.has_method("get_utility_at"):
				var utility = utilities_component.get_utility_at(pos.x, pos.y, pos.z)
				if utility and utility.has_meta("spawn_coordinates"):
					var coords = utility.get_meta("spawn_coordinates")
					# Convert grid coordinates to world position
					var world_pos = Vector3(
						coords.x * (cube_size + gutter),
						coords.y,  # Y is already in world space
						coords.z * (cube_size + gutter)
					)
					print("PlayerBoundsCheck: Found utility spawn at grid(%s) -> world(%s)" % [coords, world_pos])
					return world_pos
	
	print("PlayerBoundsCheck: No utility spawn found in map")
	return Vector3.ZERO
