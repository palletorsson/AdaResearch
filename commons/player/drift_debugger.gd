extends Node
## Debug script to identify the source of player drift.
## Add this to XROrigin3D and check the console output.

@export var enabled: bool = true
@export var log_threshold: float = 0.001  # Only log movements larger than this

var _player_body: XRToolsPlayerBody
var _origin: XROrigin3D
var _last_origin_pos: Vector3
var _last_body_pos: Vector3
var _last_velocity: Vector3

func _ready() -> void:
	_player_body = XRToolsPlayerBody.find_instance(self)
	_origin = XRHelpers.get_xr_origin(self)

	if _origin:
		_last_origin_pos = _origin.global_position
	if _player_body:
		_last_body_pos = _player_body.global_position
		_last_velocity = _player_body.velocity

func _physics_process(_delta: float) -> void:
	if not enabled:
		return

	if not _player_body or not _origin:
		return

	var origin_movement = _origin.global_position - _last_origin_pos
	var body_movement = _player_body.global_position - _last_body_pos
	var velocity = _player_body.velocity
	var ground_velocity = _player_body.ground_velocity
	var ground_control = _player_body.ground_control_velocity

	# Check for drift
	if origin_movement.length() > log_threshold:
		print("DRIFT DETECTED:")
		print("  Origin moved: ", origin_movement, " (", origin_movement.length(), ")")
		print("  Body moved: ", body_movement)
		print("  Velocity: ", velocity, " (len: ", velocity.length(), ")")
		print("  Ground velocity: ", ground_velocity)
		print("  Ground control: ", ground_control)
		print("  On ground: ", _player_body.on_ground)
		print("  Near ground: ", _player_body.near_ground)
		print("---")

	_last_origin_pos = _origin.global_position
	_last_body_pos = _player_body.global_position
	_last_velocity = velocity
