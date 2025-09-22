extends Node3D

const RESET_POSITION: Vector3 = Vector3(0.5, 4.0, 0.5)

@export var drop_height: float = 8.0
@export var gravity_force: float = 30.0
@export var max_fall_speed: float = 28.0
@export var start_delay: float = 0.6
@export var ground_wait_time: float = 1.5
@export var hit_reset_delay: float = 1.2
@export var collision_mask: int = 0xFFFF_FFFF
@export var enable_logs: bool = false

var _rest_position: Vector3
var _top_position: Vector3
var _current_velocity: float = 0.0
var _is_falling: bool = false
var _timer: Timer

@onready var detection_area: Area3D = $DetectionArea

func _ready() -> void:
	_rest_position = global_position
	_top_position = _rest_position + Vector3(0.0, max(drop_height, 0.0), 0.0)
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)
	_configure_detection_area()
	set_physics_process(true)
	_move_to_top()
	_queue_drop(start_delay)

func _physics_process(delta: float) -> void:
	if not _is_falling:
		return
	_current_velocity = min(_current_velocity + gravity_force * delta, max_fall_speed)
	var target_y := global_position.y - _current_velocity * delta
	if target_y <= _rest_position.y:
		_set_global_y(_rest_position.y)
		_is_falling = false
		_current_velocity = 0.0
		_queue_drop(ground_wait_time)
	else:
		_set_global_y(target_y)

func _on_timer_timeout() -> void:
	_is_falling = true
	_current_velocity = 0.0
	if enable_logs:
		print("PickupCubeDanger: Fall started")

func _queue_drop(delay: float) -> void:
	_timer.stop()
	_move_to_top()
	_current_velocity = 0.0
	_is_falling = false
	if delay <= 0.0:
		_on_timer_timeout()
	else:
		_timer.wait_time = delay
		_timer.start()

func _debug_detection_area() -> void:
	if enable_logs:
		print("PickupCubeDanger: Detection area configured with mask ", collision_mask)

func _configure_detection_area() -> void:
	if detection_area == null:
		push_warning("PickupCubeDanger: DetectionArea missing")
		return
	detection_area.monitoring = true
	detection_area.monitorable = true
	detection_area.collision_layer = 0
	detection_area.collision_mask = collision_mask
	var callable := Callable(self, "_on_detection_area_body_entered")
	if detection_area.body_entered.is_connected(callable):
		detection_area.body_entered.disconnect(callable)
	detection_area.body_entered.connect(callable)
	_debug_detection_area()

func _on_detection_area_body_entered(body) -> void:
	if enable_logs:
		print("PickupCubeDanger: Area detected: ", body.name, " (", body.get_class(), ")")
	
	if not _is_player(body):
		if enable_logs:
			print("PickupCubeDanger: Not a player, ignoring: ", body.name)
		return
	
	if enable_logs:
		print("PickupCubeDanger: Player detected! Resetting: ", body.name)
	
	_reset_player(body)
	_queue_drop(hit_reset_delay)


func _is_player(body: Node3D) -> bool:
	"""Check if body is a player - using ResetTeleporter approach"""
	return (body.get_class().begins_with("XRToolsPlayerBody") or 
			body.is_in_group("player_body") or 
			body.is_in_group("player") or
			body.name.contains("PlayerBody"))


func _is_valid_target(body) -> bool:
	if body == null:
		return false
	if not body is Node3D:
		return false
	var node3d := body as Node3D
	var name_lower := node3d.name.to_lower()
	if node3d.has_method("is_in_group"):
		if node3d.is_in_group("player") or node3d.is_in_group("player_body") or node3d.is_in_group("vr_player"):
			return true
	return name_lower.find("player") != -1 or name_lower.find("xrorigin") != -1

func _reset_player(body) -> void:
	if enable_logs:
		print("PickupCubeDanger: Resetting player: ", body.name)
	
	# Reset velocity FIRST (like ResetTeleporter)
	_reset_velocity(body)
	
	# Find player root and reset that too
	var player_root = _find_player_root(body)
	if player_root and player_root != body:
		_reset_velocity(player_root)
	
	# Then teleport
	_teleport_player(body)

func _find_player_root(body: Node3D) -> Node3D:
	"""Find the main player node - using ResetTeleporter approach"""
	var current = body
	while current:
		if current.is_in_group("player") or current.name.contains("XROrigin"):
			return current
		current = current.get_parent()
	return body

func _reset_velocity(body: Node3D):
	"""Reset all player velocity - using ResetTeleporter approach"""
	# Direct velocity reset
	if "velocity" in body:
		body.velocity = Vector3.ZERO
	if "linear_velocity" in body:
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO

func _teleport_player(body: Node3D):
	"""Teleport player to reset position"""
	var player_root = _find_player_root(body)
	if player_root:
		player_root.global_position = RESET_POSITION
		if enable_logs:
			print("PickupCubeDanger: Teleported player to %s" % RESET_POSITION)
	else:
		body.global_position = RESET_POSITION
		if enable_logs:
			print("PickupCubeDanger: Teleported body to %s" % RESET_POSITION)

func _clear_velocity(node: Node) -> void:
	# Legacy function - now using _reset_velocity
	if "velocity" in node:
		node.velocity = Vector3.ZERO
	if "linear_velocity" in node:
		node.linear_velocity = Vector3.ZERO
	if "angular_velocity" in node:
		node.angular_velocity = Vector3.ZERO

func _move_to_top() -> void:
	_set_global_y(_top_position.y)

func _set_global_y(value: float) -> void:
	var pos := global_position
	pos.y = value
	global_position = pos
