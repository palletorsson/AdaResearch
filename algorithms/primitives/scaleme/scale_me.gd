extends "res://commons/primitives/point/grab_sphere.gd"

## Scale parameters
@export var scale_amount: float = 100.0
@export var scale_duration: float = 20.0  # seconds
@export var scale_up_time: float = 5.0  # seconds to scale up
@export var scale_down_time: float = 5.0  # seconds to scale down
@export var world_node_path: NodePath = NodePath("")  # Optional: specific node to scale
@export var xr_origin_path: NodePath = NodePath("../../XROrigin3D")  # Path to player
@export var auto_revert: bool = true # If true, scales back after duration. If false, stays scaled.

var _original_scale: Vector3 = Vector3.ONE
var _is_scaled: bool = false
var _scale_timer: Timer
var _world_node: Node3D
var _xr_origin: XROrigin3D

func _ready() -> void:
	super._ready()

	# Setup timer for auto-scaling back
	_scale_timer = Timer.new()
	_scale_timer.name = "ScaleTimer"
	_scale_timer.one_shot = true
	_scale_timer.timeout.connect(_on_scale_timer_timeout)
	add_child(_scale_timer)

	# Find world node to scale
	_find_world_node()

	# Find the XR origin (player)
	# Try using the specified path first
	if xr_origin_path != NodePath(""):
		_xr_origin = get_node_or_null(xr_origin_path)

	# Fall back to XRHelpers if path didn't work
	if not _xr_origin:
		_xr_origin = XRHelpers.get_xr_origin(self)

	if _xr_origin:
		print("ScaleMe: Found XR Origin at ", _xr_origin.get_path())
	else:
		push_warning("ScaleMe: Could not find XR Origin")

func _find_world_node() -> void:
	# If a specific path is provided, use it
	if world_node_path != NodePath(""):
		_world_node = get_node_or_null(world_node_path)
		if _world_node:
			_original_scale = _world_node.scale
			print("ScaleMe: Using specified world node at ", world_node_path)
			return

	# 2. Look specifically for "DarkSphere" as requested by user
	# We search the entire current scene for it
	var dark_sphere = _find_node_by_name(get_tree().current_scene, "DarkSphere")
	if dark_sphere:
		_world_node = dark_sphere
		_original_scale = _world_node.scale
		print("ScaleMe: Found DarkSphere to scale: ", _world_node.name)
		return

	# 3. Otherwise, use the parent node of scale_me (the local area to scale)
	_world_node = get_parent()
	if _world_node and _world_node is Node3D:
		_original_scale = _world_node.scale
		print("ScaleMe: Scaling parent node: ", _world_node.name)
	else:
		push_warning("ScaleMe: Could not find valid world node to scale")

func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_by_name(child, target_name)
		if result:
			return result
			
	return null

# Override the pickup handler
func _on_picked_up(pickable) -> void:
	super._on_picked_up(pickable)

	# Scale the world when picked up
	if not _is_scaled:
		_scale_world()

func _scale_world() -> void:
	if not _world_node:
		push_warning("ScaleMe: No world node to scale")
		return

	_is_scaled = true

	# Disable the grab sphere's collider before scaling
	var collision_shape = get_node_or_null("CollisionShape3D")
	if collision_shape:
		collision_shape.disabled = true
		print("ScaleMe: Disabled collider to prevent scaling physics objects")

	# Store original scale if not already stored
	if _original_scale == Vector3.ONE and _world_node.scale != Vector3.ONE:
		_original_scale = _world_node.scale

	# Scale player X,Z by (scale_amount / 5), set Y to 5
	if _xr_origin:
		var current_pos = _xr_origin.global_position
		var scale_factor = scale_amount / 5.0
		var new_x = current_pos.x * scale_factor
		var new_z = current_pos.z * scale_factor
		var new_pos = Vector3(new_x, 5.0, new_z)
		_xr_origin.global_position = new_pos
		print("ScaleMe: Set player Y to 5, scaled X,Z by ", scale_factor, " - position: ", new_pos)

	# Scale the world
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_world_node, "scale", _original_scale * scale_amount, scale_up_time)

	print("ScaleMe: World scaling to ", _original_scale * scale_amount)

	# Wait for scale-up to complete, then check for collisions
	await tween.finished
	
	# Check if player is stuck inside geometry after scaling up
	if _xr_origin:
		await get_tree().physics_frame  # Wait for physics to update
		_ensure_player_not_stuck()

	# Start timer to scale back down ONLY if auto_revert is true
	if auto_revert:
		_scale_timer.start(scale_duration)
	else:
		print("ScaleMe: Auto-revert disabled, world will stay scaled.")

	# Properly drop the object first, then hide and free
	call_deferred("_cleanup_pill")

func _cleanup_pill() -> void:
	# Disable the object to prevent further interactions
	enabled = false

	# Drop the object properly if it's still being held
	if is_picked_up():
		drop()

	# Hide immediately
	hide()

	# Disable collision to prevent physics issues
	collision_layer = 0
	collision_mask = 0

	# Don't free the object yet - we need it to keep the timer alive for scale-down
	# It will be freed after the scale-down completes

func _on_scale_timer_timeout() -> void:
	if not _world_node:
		return

	# Don't move player when scaling down - let them stay at current position and fall
	if _xr_origin:
		var current_pos = _xr_origin.global_position
		print("ScaleMe: Player position unchanged at ", current_pos, " - will fall naturally")

	# Scale the world back down
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_world_node, "scale", _original_scale, scale_down_time)

	_is_scaled = false

	print("ScaleMe: World scaling down to ", _original_scale)

	# Wait for scale-down to complete, then clean up
	await tween.finished

	# Check if player is stuck inside geometry and move to safe position
	if _xr_origin:
		await get_tree().physics_frame  # Wait for physics to update
		_ensure_player_not_stuck()

	# Now we can safely free the object
	queue_free()

## Ensure the player is not stuck inside geometry after scaling
func _ensure_player_not_stuck() -> void:
	if not _xr_origin:
		return

	var space_state = _xr_origin.get_world_3d().direct_space_state
	var player_pos = _xr_origin.global_position

	# Check multiple points to better detect if player is inside geometry
	# Check at head, chest, and feet level
	var check_points = [
		player_pos + Vector3(0, 1.7, 0),  # Head height
		player_pos + Vector3(0, 1.0, 0),  # Chest height
		player_pos + Vector3(0, 0.1, 0),  # Feet height
	]
	
	var is_stuck = false
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.4  # Player collision radius (slightly larger for safety)
	query.shape = sphere_shape
	query.collision_mask = 1  # Check against world geometry
	
	# Check each point
	for check_point in check_points:
		query.transform = Transform3D(Basis.IDENTITY, check_point)
		var results = space_state.intersect_shape(query, 1)
		if results.size() > 0:
			is_stuck = true
			break
	
	if is_stuck:
		print("ScaleMe: Player stuck inside geometry, finding safe position...")
		_move_player_to_safe_position(space_state, player_pos)

func _move_player_to_safe_position(space_state: PhysicsDirectSpaceState3D, current_pos: Vector3) -> void:
	# Try multiple strategies to find a safe position
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.collision_mask = 1
	
	# Strategy 1: Try moving upward in steps to find open space
	var test_heights = [2.0, 5.0, 10.0, 20.0, 50.0]
	var safe_pos: Vector3 = current_pos
	var found_safe = false
	
	for height_offset in test_heights:
		var test_pos = current_pos + Vector3(0, height_offset, 0)
		
		# Check if this position is clear using shape query
		var query = PhysicsShapeQueryParameters3D.new()
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = 0.5
		query.shape = sphere_shape
		query.transform = Transform3D(Basis.IDENTITY, test_pos)
		query.collision_mask = 1
		
		var results = space_state.intersect_shape(query, 1)
		if results.size() == 0:
			# This position is clear, now find ground below it
			ray_query.from = test_pos + Vector3(0, 5.0, 0)
			ray_query.to = test_pos + Vector3(0, -100.0, 0)
			
			var down_result = space_state.intersect_ray(ray_query)
			if down_result:
				# Found ground, place player slightly above it
				safe_pos = down_result.position + Vector3(0, 0.2, 0)
				found_safe = true
				break
			else:
				# No ground, but position is clear - use it
				safe_pos = test_pos
				found_safe = true
				break
	
	# Strategy 2: If upward search failed, try raycasting in multiple directions
	if not found_safe:
		var directions = [
			Vector3(0, 1, 0),    # Up
			Vector3(1, 0, 0),    # Right
			Vector3(-1, 0, 0),   # Left
			Vector3(0, 0, 1),    # Forward
			Vector3(0, 0, -1),   # Back
			Vector3(0.7, 0.7, 0), # Up-right
			Vector3(-0.7, 0.7, 0), # Up-left
		]
		
		for dir in directions:
			ray_query.from = current_pos
			ray_query.to = current_pos + dir.normalized() * 20.0
			
			var result = space_state.intersect_ray(ray_query)
			if result:
				# Found a surface, try position just before it
				var surface_pos = result.position
				var safe_candidate = surface_pos - dir.normalized() * 1.0
				
				# Verify this position is clear
				var query = PhysicsShapeQueryParameters3D.new()
				var sphere_shape = SphereShape3D.new()
				sphere_shape.radius = 0.5
				query.shape = sphere_shape
				query.transform = Transform3D(Basis.IDENTITY, safe_candidate)
				query.collision_mask = 1
				
				var results = space_state.intersect_shape(query, 1)
				if results.size() == 0:
					safe_pos = safe_candidate
					found_safe = true
					break
	
	# Strategy 3: Last resort - move significantly upward
	if not found_safe:
		safe_pos = current_pos + Vector3(0, 10.0, 0)
		print("ScaleMe: Warning - using fallback position")
	
	# Apply the safe position
	_xr_origin.global_position = safe_pos
	print("ScaleMe: Moved player to safe position at ", safe_pos)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

