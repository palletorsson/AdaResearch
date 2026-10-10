extends Node3D
## PointBody is the carried hand; the existing editor remains the generator.
const PointBody = preload("res://doc/book/studies/lsystems-through-the-hands/LSystems_Grammar_Lab/point_body.gd")
const TURNS := [30.0, 60.0, 90.0, 120.0]
var point: XRToolsPickable
var desk: Node3D

func _ready() -> void:
	desk = get_parent()
	point = PointBody.new()
	point.name = "ReadingPoint"
	add_child(point)
	point.action_pressed.connect(_next)
	desk.box(Vector3(0, 1.01, 2.55), Vector3(1.3, 0.07, 0.22), desk.material("e5e0dc"), true)
	for i in TURNS.size():
		var tag = desk.label(str(int(TURNS[i])), Vector3((i - 1.5) * 0.35, 1.055, 2.62), 0.0008)
		tag.rotation_degrees.x = -60
	desk.label("MOVE THE POINT: TURN / HELD TRIGGER: NEXT", Vector3(0, 0.95, 2.67), 0.00067)
	park()

func _physics_process(_dt: float) -> void:
	if point.held():
		var index := clampi(roundi(to_local(point.global_position).x / 0.35 + 1.5), 0, 3)
		var angle: float = TURNS[index]
		if desk.source.angle_degrees != angle:
			desk.source.angle_degrees = angle
	else:
		park()

func park() -> void:
	# Presets can also name 22.5, 25 or 45 degrees: retain those until pickup.
	var x := clampf((desk.source.angle_degrees - 30.0) / 30.0 - 1.5, -1.5, 1.5) * 0.35
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(x, 1.18, 2.55))

func _next(_body = null) -> void:
	desk.act("NEXT")
