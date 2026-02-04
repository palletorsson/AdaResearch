# stuck_detector.gd
# Detects if player is stuck inside geometry and teleports them to safety
# Works as autoload - finds player automatically

extends Node

@export var check_interval: float = 2.0  # Seconds between checks
@export var stuck_threshold: int = 3  # Consecutive stuck detections before rescue
@export var ray_distance: float = 0.3  # If all rays hit within this distance, probably stuck
@export var rescue_position: Vector3 = Vector3(2, 3, 2)  # Fallback rescue position
@export var use_spawn_point: bool = true  # Try to find spawn point first
@export var enabled: bool = true

var _stuck_count: int = 0
var _timer: float = 0.0
var _player_body: Node3D = null

func _ready():
	# Find player body (parent should be XROrigin3D or similar)
	_player_body = _find_player_body()
	if _player_body:
		print("StuckDetector: Monitoring player at %s" % _player_body.name)
	else:
		print("StuckDetector: Warning - could not find player body, will retry")

func _process(delta: float):
	if not enabled:
		return
	
	_timer += delta
	if _timer < check_interval:
		return
	_timer = 0.0
	
	# Make sure we have a player reference
	if not _player_body or not is_instance_valid(_player_body):
		_player_body = _find_player_body()
		if not _player_body:
			return
	
	# Check if stuck
	if _is_stuck():
		_stuck_count += 1
		print("StuckDetector: Player appears stuck (%d/%d)" % [_stuck_count, stuck_threshold])
		
		if _stuck_count >= stuck_threshold:
			print("StuckDetector: Rescuing player!")
			_rescue_player()
			_stuck_count = 0
	else:
		_stuck_count = 0

func _is_stuck() -> bool:
	# Cast rays in 6 directions from player position
	var origin = _player_body.global_position + Vector3(0, 1.0, 0)  # Eye level
	var directions = [
		Vector3.UP,
		Vector3.DOWN,
		Vector3.LEFT,
		Vector3.RIGHT,
		Vector3.FORWARD,
		Vector3.BACK
	]
	
	var space_state = _player_body.get_world_3d().direct_space_state
	var blocked_count = 0
	
	for dir in directions:
		var query = PhysicsRayQueryParameters3D.create(origin, origin + dir * ray_distance)
		query.exclude = _get_player_rids()
		var result = space_state.intersect_ray(query)
		
		if result:
			blocked_count += 1
	
	# If 5+ directions are blocked within ray_distance, probably stuck
	return blocked_count >= 5

func _get_player_rids() -> Array[RID]:
	# Get RIDs of player collision shapes to exclude from raycast
	var rids: Array[RID] = []
	var bodies = get_tree().get_nodes_in_group("player_body")
	for body in bodies:
		if body is CollisionObject3D:
			rids.append(body.get_rid())
	return rids

func _rescue_player():
	var rescue_pos = rescue_position
	
	# Try to find spawn point first
	if use_spawn_point:
		var spawn = _find_spawn_point()
		if spawn:
			rescue_pos = spawn.global_position + Vector3(0, 0.5, 0)
			print("StuckDetector: Using spawn point at %s" % rescue_pos)
		else:
			print("StuckDetector: No spawn point found, using fallback %s" % rescue_pos)
	
	# Find the root player node to teleport
	var player_root = _find_player_root()
	if player_root:
		print("StuckDetector: Teleporting %s to %s" % [player_root.name, rescue_pos])
		player_root.global_position = rescue_pos
		
		# Reset velocity if applicable
		if "velocity" in player_root:
			player_root.velocity = Vector3.ZERO
		if "linear_velocity" in player_root:
			player_root.linear_velocity = Vector3.ZERO
	else:
		push_warning("StuckDetector: Could not find player root to teleport")

func _find_player_body() -> Node3D:
	# Try multiple strategies to find player
	
	# 1. Check if parent is player
	var parent = get_parent()
	if parent is Node3D and (parent.is_in_group("player") or "XROrigin" in parent.name or "Player" in parent.name):
		return parent
	
	# 2. Search in tree
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	
	# 3. Find XROrigin3D
	var xr_origin = get_tree().get_first_node_in_group("xr_origin")
	if xr_origin:
		return xr_origin
	
	# 4. Find by class
	var root = get_tree().current_scene
	if root:
		var origin = root.find_child("XROrigin3D", true, false)
		if origin:
			return origin
		var player = root.find_child("PlayerBody", true, false)
		if player:
			return player
	
	return null

func _find_player_root() -> Node3D:
	# Find the root node that should be teleported (XROrigin or CharacterBody)
	if not _player_body:
		return null
	
	var current = _player_body
	while current:
		if current.is_in_group("player") or "XROrigin" in current.name:
			return current
		if current is CharacterBody3D:
			return current
		current = current.get_parent()
	
	return _player_body

func _find_spawn_point() -> Node3D:
	# Find spawn point utility in current scene
	var spawns = get_tree().get_nodes_in_group("spawn_point")
	if spawns.size() > 0:
		return spawns[0]
	
	# Try finding by name
	var root = get_tree().current_scene
	if root:
		var spawn = root.find_child("SpawnPoint", true, false)
		if spawn:
			return spawn
	
	return null

# Public API to force rescue
func force_rescue():
	print("StuckDetector: Force rescue triggered")
	_rescue_player()
	_stuck_count = 0

# Public API to reset stuck counter
func reset():
	_stuck_count = 0
