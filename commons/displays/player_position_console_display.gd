extends Node

@export var player_path: NodePath
@export var update_interval_seconds: float = 1.0
@export var minimum_distance_delta: float = 0.15
@export var console_source: String = "player_position"
@export var message_type: String = "info"

var _player: Node3D
var _last_position: Vector3 = Vector3.INF
var _timer: Timer
var _warned_missing_game_manager := false

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = max(update_interval_seconds, 0.1)
	_timer.autostart = true
	_timer.one_shot = false
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)
	_resolve_player()
	_announce_activation()
	_on_timer_timeout()

func _resolve_player() -> void:
	# First, try the XROrigin3D sibling (most common for XR setups)
	var xr_origin = get_node_or_null("../XROrigin3D")
	if xr_origin and xr_origin is Node3D:
		_player = xr_origin
		print("PlayerPositionConsoleDisplay: Using XROrigin3D at %s" % xr_origin.get_path())
		return

	# Then try the exported player_path
	if not player_path.is_empty():
		var candidate = get_node_or_null(player_path)
		if candidate and candidate is Node3D:
			_player = candidate
			print("PlayerPositionConsoleDisplay: Using player_path: %s" % candidate.get_path())
			return

	# Finally, try common player groups
	var candidates: Array = [
		get_tree().get_first_node_in_group("xr_player"),
		get_tree().get_first_node_in_group("player_body"),
		get_tree().get_first_node_in_group("player")
	]
	for candidate in candidates:
		if candidate and candidate is Node3D:
			_player = candidate
			print("PlayerPositionConsoleDisplay: Using player from group: %s" % candidate.get_path())
			return

	push_warning("PlayerPositionConsoleDisplay: Could not find player node")

func _announce_activation() -> void:
	GameManager.add_console_message("Display active", message_type, console_source)


func _on_timer_timeout() -> void:
	if not is_instance_valid(_player):
		_resolve_player()
		if not is_instance_valid(_player):
			return
	var position: Vector3 = (_player as Node3D).global_position
	if _should_emit(position):
		_emit_position_message(position)
		_last_position = position

func _should_emit(position: Vector3) -> bool:
	if _last_position == Vector3.INF:
		return true
	return _last_position.distance_to(position) >= minimum_distance_delta

func _emit_position_message(position: Vector3) -> void:
	if typeof(GameManager) == TYPE_NIL or not GameManager.has_method("add_console_message"):
		if not _warned_missing_game_manager:
			push_warning("PlayerPositionConsoleDisplay: GameManager.add_console_message unavailable")
			_warned_missing_game_manager = true
		return
	_warned_missing_game_manager = false
	var message := "Player position: (%.2f, %.2f, %.2f)" % [position.x, position.y, position.z]
	GameManager.add_console_message(message, message_type, console_source)
