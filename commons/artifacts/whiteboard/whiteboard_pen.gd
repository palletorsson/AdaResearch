extends XRToolsPickable
## A surface-writing tool owned by one whiteboard, independent of draw_dot.
var board: Node3D
var ink := Color.BLACK
var resolution_mm: float = 0.0
var eraser: bool = false
var _previous := Vector2(-1, -1)

func _ready() -> void:
	super()
	dropped.connect(func(_item): _previous = Vector2(-1,-1))

func _process(_delta: float) -> void:
	if not is_picked_up() or not is_instance_valid(board):
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
