extends Node
## Prevents micro-drift by zeroing tiny velocities on the player body.
## Add this as a child of your XROrigin3D.

@export var deadzone: float = 0.05  # Increased from 0.01
@export var zero_ground_control: bool = true

var _player_body: XRToolsPlayerBody

func _ready() -> void:
	_player_body = XRToolsPlayerBody.find_instance(self)

func _physics_process(_delta: float) -> void:
	if not _player_body:
		return

	# Get velocity relative to ground
	var local_vel = _player_body.velocity - _player_body.ground_velocity

	# Get horizontal velocity (ignore gravity axis)
	var horizontal_vel = local_vel.slide(_player_body.up_gravity)

	# Zero out tiny horizontal velocities to prevent drift
	if horizontal_vel.length() < deadzone:
		# Keep vertical component, zero horizontal
		var vertical_vel = local_vel - horizontal_vel
		_player_body.velocity = vertical_vel + _player_body.ground_velocity

	# Also zero ground control if nothing is being input
	if zero_ground_control and _player_body.ground_control_velocity.length() < 0.01:
		_player_body.ground_control_velocity = Vector2.ZERO
