extends Node3D

@export var player_path: NodePath = NodePath("../../XROrigin3D")
@export var detected_text: String = "Player detected"
@export var idle_text: String = "Waiting for player"
@export var detected_color: Color = Color(0.1, 0.9, 0.5)
@export var idle_color: Color = Color(0.9, 0.9, 0.9)
@export_range(0.05, 5.0, 0.05) var poll_interval: float = 0.2

@onready var status_label: Label3D = $StatusLabel

var _player_node: Node3D = null
var _poll_timer: float = 0.0

func _ready() -> void:
	_poll_timer = 0.0
	_set_idle_state()
	set_process(true)
	_resolve_player()
	_check_for_player()

func _process(delta: float) -> void:
	_poll_timer -= delta
	if _poll_timer <= 0.0:
		_poll_timer = poll_interval
		_check_for_player()

func _resolve_player() -> void:
	_player_node = null
	if player_path.is_empty():
		return
	var node := get_node_or_null(player_path)
	if node and node is Node3D:
		_player_node = node

func _check_for_player() -> void:
	if not _player_node or not is_instance_valid(_player_node):
		_resolve_player()
	if _player_node and _player_node.is_inside_tree():
		_set_detected_state()
	else:
		_set_idle_state()

func _set_detected_state() -> void:
	if status_label:
		status_label.text = detected_text
		status_label.modulate = detected_color

func _set_idle_state() -> void:
	if status_label:
		status_label.text = idle_text
		status_label.modulate = idle_color
