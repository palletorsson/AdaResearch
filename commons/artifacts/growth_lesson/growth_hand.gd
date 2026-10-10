extends Node3D
## Reuse the carried point; only the existing interpreter's ratio changes.
const PointBody = preload("res://doc/book/studies/lsystems-through-the-hands/LSystems_Grammar_Lab/point_body.gd")
const RATIOS := [0.45, 0.72, 1.0, 1.15]
var point: XRToolsPickable
var desk: Node3D

func _ready() -> void:
	desk = get_parent()
	point = PointBody.new()
	point.name = "BranchPoint"
	add_child(point)
	point.action_pressed.connect(_step)
	desk.box(Vector3(0, 1.01, 2.55), Vector3(1.3, 0.07, 0.22), desk.material("e5e0dc"), true)
	for i in RATIOS.size():
		var tag = desk.label("%.2f" % RATIOS[i], Vector3((i - 1.5) * 0.35, 1.055, 2.62), 0.0008)
		tag.rotation_degrees.x = -60
	desk.label("MOVE THE POINT: RATIO / HELD TRIGGER: STEP", Vector3(0, 0.95, 2.67), 0.00067)
	park()

func _physics_process(_dt: float) -> void:
	if point.held():
		var index := clampi(roundi(to_local(point.global_position).x / 0.35 + 1.5), 0, 3)
		var ratio: float = RATIOS[index]
		if not is_equal_approx(desk.source.length_decay, ratio):
			desk.source.length_decay = ratio
			desk.source.reinterpret()
	else:
		park()

func park() -> void:
	var index := 0
	for i in RATIOS.size():
		if is_equal_approx(desk.source.length_decay, RATIOS[i]):index = i
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3((index - 1.5) * 0.35, 1.18, 2.55))

func _step(_body = null) -> void:
	desk.act("STEP")
