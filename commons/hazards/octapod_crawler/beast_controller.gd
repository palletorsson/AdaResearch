extends MeshInstance3D

## Beast demo controller — autonomous patrol + WASD override.
## The beast is a MeshInstance3D at a fixed Y. Movement = direct position change.
## IK legs + SpringArm3Ds are children → they follow automatically. No physics needed.

@export var rotation_speed := 40.0
@export var movement_speed := 3.0
@export var patrol_speed := 1.5
@export var patrol_turn_speed := 1.0
@export var patrol_direction_interval := 3.0

var _patrol_timer: float = 0.0
var _patrol_angle: float = 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_patrol_angle = _rng.randf_range(0, TAU)

func _process(delta: float) -> void:
	# WASD input (overrides patrol when active)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	if input_dir.length_squared() > 0.01:
		# Manual control
		position += -basis.z * input_dir.y * delta * movement_speed
		rotation.y += deg_to_rad(-input_dir.x * delta * rotation_speed)
	else:
		# Autonomous patrol — wander around
		_patrol_timer += delta
		if _patrol_timer >= patrol_direction_interval:
			_patrol_timer = 0.0
			_patrol_angle += _rng.randf_range(-PI * 0.5, PI * 0.5)

		# Smoothly turn toward patrol angle
		rotation.y = lerp_angle(rotation.y, _patrol_angle, patrol_turn_speed * delta)
		# Walk forward
		position += -basis.z * delta * patrol_speed
