extends Node3D
## The existing point is a held step control for the installed three-state study.
var study: Node3D
var point: XRToolsPickable

func _ready() -> void:
	study = get_parent()
	point = load("res://commons/artifacts/ca_rule_explorer/point_body.gd").new()
	point.name = "PointBody"
	add_child(point)
	point.action_pressed.connect(func(_body): study.step_once())
	park()
	var label := Label3D.new()
	label.text = "HOLD POINT\nTRIGGER: STEP"
	label.font_size = 30
	label.pixel_size = .0012
	label.position = Vector3(-1.65,.80,-3.565)
	label.rotation.y = PI
	label.outline_size = 4
	add_child(label)
	study.box("HandInstructions",Vector3(.65,.16,.018),Vector3(-1.65,.80,-3.55),Color("152d33"))

func _physics_process(_delta: float) -> void:
	if not point.held(): park()

func park() -> void:
	point.position = Vector3(-1.65,1.12,-3.55)
