extends Node3D
const PointBody = preload("res://doc/book/studies/lsystems-through-the-hands/LSystems_Grammar_Lab/point_body.gd")
var point: XRToolsPickable
var desk: Node3D
func _ready() -> void:
	desk = get_parent()
	point = PointBody.new(); point.name = "TurnPoint"; add_child(point)
	point.action_pressed.connect(func(_body): desk.act("STEP"))
	desk.box(Vector3(.88,.52,2.0),Vector3(.27,1.04,.27),desk.material("e5e0dc"),true)
	desk.label("HOLD / TRIGGER\nONE TURN",Vector3(.88,.91,2.145),.00055)
	park()
func _physics_process(_dt: float) -> void:
	if not point.held(): park()
func park() -> void:
	point.global_transform=global_transform*Transform3D(Basis.IDENTITY,Vector3(.88,1.14,2.0))
