extends Node3D

@export var teleport_target: Node3D
@export var reset_delay: float = 1.0
@export var teleport_root: NodePath
@onready var area: Area3D = $ResetArea 

var is_resetting: bool = false
var is_ready: bool = false

func _ready():
	# Avoid duplicate connections if the scene is re-loaded or instanced twice
	if not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered)
	
	# Auto-find spawn if no target set
	if not teleport_target:
		call_deferred("_find_spawn")
	
	# Delay activation to avoid triggering during scene transitions
	await get_tree().create_timer(2.0).timeout
	is_ready = true
	print("ResetTeleporter: Now active and ready to detect player falls")

func _find_spawn():
	teleport_target = get_tree().current_scene.find_child("SpawnPoint", true, false)

	if not teleport_target:
		var spawn_position = _get_grid_spawn_position()
		teleport_target = Node3D.new()
		teleport_target.position = spawn_position
		get_tree().current_scene.add_child(teleport_target)
		print("ResetTeleporter: Created default spawn at %s" % teleport_target.position)

func _get_grid_spawn_position() -> Vector3:
	var scene_root = get_tree().current_scene
	if not scene_root:
		return Vector3(0.5, 16.0, 0.5)

	var grid_system = scene_root.find_child("LabGridSystem", true, false)
	if not grid_system:
		grid_system = scene_root.find_child("GridSystem", true, false)

	if not grid_system:
		return Vector3(0.5, 16.0, 0.5)

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

	return Vector3(0.5, 16.0, 0.5)

func _on_body_entered(body: Node3D):
	if not is_ready:
		return
	
	if is_resetting or not _is_player(body):
		return
	
	print("ResetTeleporter: Player detected in reset area - initiating reset")
	is_resetting = true
	await get_tree().create_timer(reset_delay).timeout
	
	# Reset velocity FIRST
	_reset_velocity(body)
	
	# Wait for physics frame to process velocity reset
	await get_tree().physics_frame
	
	# THEN teleport
	_teleport_player(body)
	
	# Reset velocity AGAIN after teleport
	_reset_velocity(body)
	
	# Wait for physics frame to ensure position sticks
	await get_tree().physics_frame
	
	is_resetting = false

func _reset_velocity(body: Node3D):
	if "velocity" in body:
		body.velocity = Vector3.ZERO
	if "linear_velocity" in body:
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO

	var player_root = _find_player_root(body)
	if player_root and player_root != body:
		if "velocity" in player_root:
			player_root.velocity = Vector3.ZERO
		if "linear_velocity" in player_root:
			player_root.linear_velocity = Vector3.ZERO
			player_root.angular_velocity = Vector3.ZERO

func _find_player_root(body: Node3D) -> Node3D:
	var current = body
	while current:
		if current.is_in_group("player") or current.name.contains("XROrigin"):
			return current
		current = current.get_parent()
	return body

func _teleport_player(body: Node3D):
	if not teleport_target:
		return
	var player_root: Node3D = null
	if teleport_root and teleport_root != NodePath(""):
		player_root = get_node_or_null(teleport_root)
	if body:
		player_root = _find_player_root(body)
	elif player_root == null:
		player_root = _find_player_root(teleport_target)
	if player_root == null:
		player_root = _find_player_root(self)
	if player_root:
		player_root.global_position = teleport_target.global_position
		print("Reset: Teleported player to %s" % teleport_target.global_position)

func _is_player(body: Node3D) -> bool:
	return (body.get_class().begins_with("XRToolsPlayerBody") or 
			body.is_in_group("player_body") or 
			body.is_in_group("player") or
			body.name.contains("PlayerBody"))

func set_reset_position(new_position: Vector3):
	if not teleport_target:
		teleport_target = Node3D.new()
		get_tree().current_scene.add_child(teleport_target)

	teleport_target.global_position = new_position
	print("ResetTeleporter: Updated spawn position to %s" % new_position)

func is_xr_class(name: String) -> bool:
	return name == "XRToolsTeleportArea"
