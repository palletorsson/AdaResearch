extends XRToolsPickable
## A surface-writing tool owned by one whiteboard, independent of draw_dot.
var board: Node3D
var ink := Color.BLACK
var resolution_mm: float = 0.0
var eraser: bool = false
var _previous := Vector2(-1, -1)
var return_enabled := false
var return_delay := 1.25
var desktop_held := false
var docked := true
var return_count := 0
var _home_transform := Transform3D.IDENTITY
var _lost_time := 0.0

func _ready() -> void:
	super()
	_home_transform = transform
	picked_up.connect(func(_item): docked = false; _lost_time = 0.0)
	dropped.connect(func(_item): _previous = Vector2(-1,-1))

func _process(_delta: float) -> void:
	if not (is_picked_up() or desktop_held) or not is_instance_valid(board):
		_previous = Vector2(-1,-1)
		return
	var uv: Vector2 = board.sample_uv($WritingTip.global_position, resolution_mm)
	if uv.x < 0:
		_previous = Vector2(-1,-1)
		return
	if uv.is_equal_approx(_previous):
		return
	board.paint(_previous, uv, ink, eraser)
	_previous = uv


func on_desktop_grab(_pointer: Node) -> void:
	desktop_held = true
	docked = false
	_lost_time = 0.0


func on_desktop_drop(_pointer: Node) -> void:
	desktop_held = false
	_previous = Vector2(-1, -1)
	_lost_time = 0.0
	if return_enabled:
		freeze = false


func home_global_transform() -> Transform3D:
	return (get_parent() as Node3D).global_transform * _home_transform


func _physics_process(delta: float) -> void:
	if not return_enabled or docked or not is_instance_valid(board): return
	if is_picked_up() or desktop_held:
		_lost_time = 0.0
		return
	var home := home_global_transform().origin
	var fallen := global_position.y < home.y - 0.25
	var lost := global_position.distance_to(home) > 3.0
	_lost_time = _lost_time + delta if fallen or lost else 0.0
	if _lost_time >= return_delay:
		return_to_shelf()


func return_to_shelf() -> bool:
	# Return the existing body, never duplicate it or take it from a hand.
	if is_picked_up() or desktop_held: return false
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = home_global_transform()
	force_update_transform()
	PhysicsServer3D.body_set_state(get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, global_transform)
	reset_physics_interpolation()
	_previous = Vector2(-1, -1)
	_lost_time = 0.0
	docked = true
	return_count += 1
	return true
