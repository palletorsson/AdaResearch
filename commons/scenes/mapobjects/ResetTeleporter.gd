# SimpleResetCube.gd
# Minimal reset cube that stops velocity and teleports player
extends Node3D

@export var teleport_target: Node3D
@export var reset_delay: float = 1.0
@onready var area: Area3D = $ResetArea 

var is_resetting: bool = false
var is_ready: bool = false

func _ready():
	area.body_entered.connect(_on_body_entered)
	
	# Auto-find spawn if no target set
	if not teleport_target:
		call_deferred("_find_spawn")
	
	# Add a delay before the reset teleporter becomes active
	# This prevents it from triggering during scene transitions
	await get_tree().create_timer(2.0).timeout
	is_ready = true
	print("ResetTeleporter: Now active and ready to detect player falls")

func _find_spawn():
	# Look for spawn point or create default
	teleport_target = get_tree().current_scene.find_child("SpawnPoint", true, false)

	if not teleport_target:
		# Try to get spawn position from GridSpawnComponent
		var spawn_position = _get_grid_spawn_position()

		# Create temporary spawn node
		teleport_target = Node3D.new()
		teleport_target.position = spawn_position
		get_tree().current_scene.add_child(teleport_target)
		print("ResetTeleporter: Created default spawn at %s" % teleport_target.position)

func _get_grid_spawn_position() -> Vector3:
	"""Try to get spawn position from GridSpawnComponent or map data"""
	var scene_root = get_tree().current_scene
	if not scene_root:
		return Vector3(0.5, 16.0, 0.5)  # Default fallback

	# Try to find GridSystem
	var grid_system = scene_root.find_child("LabGridSystem", true, false)
	if not grid_system:
		grid_system = scene_root.find_child("GridSystem", true, false)

	if not grid_system:
		return Vector3(0.5, 16.0, 0.5)  # No grid system found

	# Try to get data component directly to read spawn points from JSON
	if grid_system.has_node("GridDataComponent"):
		var data_component = grid_system.get_node("GridDataComponent")
		if data_component and data_component.has_method("get_spawn_points"):
			var spawn_points = data_component.get_spawn_points()
			if spawn_points is Dictionary and not spawn_points.is_empty():
				var default_spawn = spawn_points.get("default", {})
				if default_spawn is Dictionary and not default_spawn.is_empty():
					var pos = default_spawn.get("position", [2.5, 16.0, 2.5])
					if pos is Array and pos.size() >= 3:
						return Vector3(pos[0], pos[1], pos[2])

	# Fallback to GridSpawnComponent default
	return Vector3(0.5, 16.0, 0.5)

func _on_body_entered(body: Node3D):
	# Don't trigger if not ready yet (prevents scene transition issues)
	if not is_ready:
		print("ResetTeleporter: Ignoring body entry - not ready yet")
		return
		
	if is_resetting or not _is_player(body):
		return
	
	print("ResetTeleporter: Player detected in reset area - initiating reset")
	is_resetting = true
	await get_tree().create_timer(reset_delay).timeout
	
	# Reset player velocity FIRST
	_reset_velocity(body)
	
	# Then teleport
	_teleport_player(body)
	
	is_resetting = false

func _reset_velocity(body: Node3D):
	"""Reset all player velocity - simple version"""
	# Direct velocity reset
	if "velocity" in body:
		body.velocity = Vector3.ZERO
	if "linear_velocity" in body:
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
	
	# Find player parent and reset that too
	var player_root = _find_player_root(body)
	if player_root and player_root != body:
		if "velocity" in player_root:
			player_root.velocity = Vector3.ZERO
		if "linear_velocity" in player_root:
			player_root.linear_velocity = Vector3.ZERO
			player_root.angular_velocity = Vector3.ZERO

func _find_player_root(body: Node3D) -> Node3D:
	"""Find the main player node"""
	var current = body
	while current:
		if current.is_in_group("player") or current.name.contains("XROrigin"):
			return current
		current = current.get_parent()
	return body

func _teleport_player(body: Node3D):
	"""Teleport player to target"""
	if not teleport_target:
		return
	
	var player_root = _find_player_root(body)
	if player_root:
		player_root.global_position = teleport_target.global_position
		print("Reset: Teleported player to %s" % teleport_target.global_position)

func _is_player(body: Node3D) -> bool:
	return (body.get_class().begins_with("XRToolsPlayerBody") or 
			body.is_in_group("player_body") or 
			body.is_in_group("player") or
			body.name.contains("PlayerBody"))

# Public API to update spawn position
func set_reset_position(new_position: Vector3):
	"""Update the reset/spawn position - called by GridSpawnComponent"""
	if not teleport_target:
		teleport_target = Node3D.new()
		get_tree().current_scene.add_child(teleport_target)

	teleport_target.global_position = new_position
	print("ResetTeleporter: Updated spawn position to %s" % new_position)

# XR-Tools compatibility
func is_xr_class(name: String) -> bool:
	return name == "XRToolsTeleportArea"
