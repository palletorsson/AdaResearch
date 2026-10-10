extends Node3D
## The same carried point controls the two independent reader decisions.
const PointBody = preload("res://doc/book/studies/lsystems-through-the-hands/LSystems_Grammar_Lab/point_body.gd")
const ANGLES := [25.0, 45.0, 90.0]
var point: XRToolsPickable
var desk: Node3D

func _ready() -> void:
	desk = get_parent()
	point = PointBody.new()
	point.name = "InterpreterPoint"
	add_child(point)
	point.action_pressed.connect(_exchange)
	desk.box(Vector3(0, 1.01, 2.55), Vector3(1.3, 0.07, 0.22), desk.material("e5e0dc"), true)
	for i in ANGLES.size():
		var tag = desk.label(str(int(ANGLES[i])), Vector3((i - 1) * 0.35, 1.055, 2.62), 0.0008)
		tag.rotation_degrees.x = -60
	desk.label("MOVE: MIDDLE ANGLE / HELD TRIGGER: BLUE READ F", Vector3(0, 0.95, 2.67), 0.00063)
	park()

func _physics_process(_dt: float) -> void:
	if point.held():
		var index := clampi(roundi(to_local(point.global_position).x / 0.35 + 1), 0, 2)
		var angle: float = ANGLES[index]
		if not is_equal_approx(desk.turn_angle, angle):
			desk.turn_angle = angle
			desk.rebuild()
	else:
		park()

func park() -> void:
	var x: float = (ANGLES.find(desk.turn_angle) - 1) * 0.35
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(x, 1.18, 2.55))

func _exchange(_body = null) -> void:
	desk.act("READ F")
