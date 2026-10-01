extends CharacterBody3D
## Supplied walker: a body with eyes, for the desktop. Its origin is at its feet;
## it is a capsule 1.8 m high and 0.6 m wide, its Eyes at 1.6 m, its Skin in SECOND.
## Contract:
##   keys        move_left, move_right, move_forward and move_backward walk it,
##               jump lifts it, switch_camera changes between its Eyes and the
##               scene's other camera. Hold the right mouse button, or the look
##               key, and move the mouse to turn. The mouse is never captured.
##   walk_to(points)   the autopilot. `points` is a list of Vector3. It walks
##               to each in turn, in a straight line, and does not listen to
##               the keys until the walk ends. Only x and z of a point count.
##   walk_ended(how)   the signal that ends every walk: "arrived" (it stands on
##               the last point), "blocked" (half a second without coming nearer
##               or falling), "fell" (below fall_limit) or "stopped" (stop()).
##               It comes just after the step of the physics that ended the
##               walk. A listener that removes the walker: queue_free(), not free().
##   stand_at(at)      puts it there, still. It returns there after a fall.
## A StaticBody3D stops it and carries it; one no higher than step_height it
## steps onto. A mesh with no collider does neither. A RigidBody3D in its way,
## the marble, is kicked along. `walking` and `ended` say what the signal says.

signal walk_ended(how: String)
const Look := preload("res://supplied/look.gd")

@export var speed := 2.0            # metres per second
@export var jump_speed := 4.0       # metres per second, upward, as the jump begins
@export var step_height := 0.35     # metres: the highest step it walks up; 0 and it climbs none
@export var look_speed := 0.003     # radians of turn for one pixel of mouse
@export var keys := true            # untick and it is deaf to keys and mouse; walk_to() still works
@export var through_eyes := false   # tick to start the scene looking through its Eyes
@export var fall_limit := -10.0     # metres: below this height it is put back where it started

var walking := false   # true from walk_to() until walk_ended
var ended := ""        # how the last walk ended; "" during a walk and before the first
var _route: Array[Vector3] = []   # the points still to reach
var _home := Vector3.ZERO         # where it returns after a fall
var _clock := 0.0                 # seconds since progress was last measured
var _before := Vector2(INF, INF)  # then: how far the next point was, and how high the feet were

func _ready() -> void:
	_home = global_position
	if has_node("Skin") and $Skin.material_override == null:
		$Skin.material_override = Look.paint(Look.SECOND)
	if through_eyes:
		$Eyes.make_current()

func walk_to(points: Array) -> void:
	_route.assign(points)   # a copy; an error here if something in the list is not a Vector3
	walking = true
	ended = ""
	_clock = 0.0
	_before = Vector2(INF, INF)

func stop() -> void:
	if walking:
		_end("stopped")

func stand_at(at: Vector3) -> void:
	global_position = at
	velocity = Vector3.ZERO
	_home = at

## Mouse look: the body turns left and right, the Eyes tilt up and down.
func _unhandled_input(event: InputEvent) -> void:
	if not keys or not event is InputEventMouseMotion:
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_action_pressed("look"):
		rotate_y(-event.relative.x * look_speed)
		$Eyes.rotation.x = clampf($Eyes.rotation.x - event.relative.y * look_speed, -1.4, 1.4)

func _physics_process(delta: float) -> void:
	if global_position.y < fall_limit:
		stand_at(_home)
		if walking:
			_end("fell")
	if not is_on_floor():
		velocity += get_gravity() * delta
	var direction := Vector3.ZERO   # along the floor, no longer than 1
	if walking:
		direction = _steer(delta)
	elif keys:
		if Input.is_action_just_pressed("switch_camera"):
			_switch_camera()
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_speed
		# x: left -1 .. right +1; y: forward -1 .. backward +1, turned the way the body faces.
		var input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		direction = global_basis * Vector3(input.x, 0.0, input.y)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	_step_up(direction)
	move_and_slide()
	for i in get_slide_collision_count():   # what it walked into: a loose body gets a kick
		var hit := get_slide_collision(i)
		if hit.get_collider() is RigidBody3D:
			hit.get_collider().apply_central_impulse(-hit.get_normal() * 0.3)

## The autopilot's one decision: which way to walk in this step.
func _steer(delta: float) -> Vector3:
	if _route.is_empty():
		_end("arrived")
		return Vector3.ZERO
	var to := _route[0] - global_position
	to.y = 0.0
	var left := to.length()
	if left < 0.1 and is_on_floor():   # this point is reached: the feet are down on it
		_route.pop_front()
		_clock = 0.0
		_before = Vector2(INF, INF)
		return Vector3.ZERO
	_clock += delta
	if _clock >= 0.5:           # twice a second: has it come nearer, or fallen nearer the ground?
		var now := Vector2(left, global_position.y)
		if _before.x - now.x < 0.05 and _before.y - now.y < 0.05:
			_end("blocked")
			return Vector3.ZERO
		_clock = 0.0
		_before = now
	if left < 0.1:
		return Vector3.ZERO     # over the point and still in the air
	rotation.y = atan2(-to.x, -to.z)                           # face the way it walks
	return to / left * minf(1.0, left / (speed * delta))      # and do not step past the point

## A capsule alone is stopped by any step above 9 cm. So: if something is in the way,
## the way is free one step_height up, and a StaticBody3D has a level top there, stand on it.
func _step_up(direction: Vector3) -> void:
	if step_height <= 0.0 or not is_on_floor() or direction.length() < 0.01:
		return
	var ahead := direction.normalized() * 0.32   # a little more than the capsule's radius
	var up := Vector3.UP * step_height
	var lifted := global_transform.translated(up)
	if not test_move(global_transform, ahead * 0.15) or test_move(global_transform, up) or test_move(lifted, ahead):
		return
	var landing := KinematicCollision3D.new()
	if test_move(lifted.translated(ahead), -up, landing) and landing.get_collider() is StaticBody3D and landing.get_normal().y > 0.9:
		global_position += up + ahead + landing.get_travel()

func _end(how: String) -> void:
	walking = false
	ended = how
	_route.clear()
	walk_ended.emit.call_deferred(how)   # after this step of the physics, not in the middle of it

func _switch_camera() -> void:
	if $Eyes.current:
		$Eyes.clear_current()               # the view goes to another camera of the scene
		if get_viewport().get_camera_3d() == null:
			$Eyes.make_current()            # there is no other: keep the Eyes
	else:
		$Eyes.make_current()
