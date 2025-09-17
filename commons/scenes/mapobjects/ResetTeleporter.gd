# SimpleResetCube.gd
# Minimal reset cube that stops velocity and teleports player
extends Node3D

@export var teleport_target: Node3D
@export var reset_delay: float = 1.0
@onready var area: Area3D = $ResetArea 

var is_resetting: bool = false

func _ready():
	area.body_entered.connect(_on_body_entered)
	
	# Auto-find spawn if no target set
	if not teleport_target:
		call_deferred("_find_spawn")

func _find_spawn():
	# Look for spawn point or create default
	teleport_target = get_tree().current_scene.find_child("SpawnPoint", true, false)
	if not teleport_target:
		teleport_target = Node3D.new()
		teleport_target.position = Vector3(0.5, 3, 0.5)
		get_tree().current_scene.add_child(teleport_target)

func _on_body_entered(body: Node3D):
	if is_resetting or not _is_player(body):
		return
	
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

# XR-Tools compatibility
func is_xr_class(name: String) -> bool:
	return name == "XRToolsTeleportArea"
