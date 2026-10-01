extends Node3D
## Supplied hand. It moves this node parallel to the floor, at its own height.
## It asks the Input Map (Project > Project Settings > Input Map) for four
## named actions. It never asks which key was pressed: change keys there, not here.

# @export makes a value editable in the Inspector: select B to see these three there.
@export var speed := 1.2                # metres per second
@export var autopilot := false          # tick to let the point move by itself
@export var area := Vector2(2.4, 1.5)   # furthest it may go from the middle, in x and in z

var _clock := 0.0          # seconds since the autopilot started
var _phase := 0.0          # how far along the figure-eight it has gone
var _centre := Vector3.ZERO
var _started := false

func _process(delta: float) -> void:
	if autopilot:
		_drive(delta)
		return
	# x: left -1 .. right +1; y: forward -1 .. backward +1. A diagonal is no longer than 1.
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	position.x = clampf(position.x + input.x * speed * delta, -area.x, area.x)
	position.z = clampf(position.z + input.y * speed * delta, -area.y, area.y)

## A slow figure-eight through the starting position: 2.5 s moving, then 1 s still.
func _drive(delta: float) -> void:
	if not _started:
		_centre = position
		_started = true
	_clock += delta
	if fmod(_clock, 3.5) < 2.5:
		_phase += 0.6 * delta
	position = _centre + Vector3(1.4 * sin(_phase), 0.0, 0.7 * sin(2.0 * _phase))
