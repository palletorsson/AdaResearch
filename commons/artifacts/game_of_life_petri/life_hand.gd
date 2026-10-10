extends Node3D
## Carry the existing STEP while walking beside the floor; do not write cell state.
var study: Node3D
var point: XRToolsPickable

func _ready() -> void:
	study = get_parent()
	point = load("res://commons/artifacts/ca_rule_explorer/point_body.gd").new()
	point.name = "PointBody"
	add_child(point)
	point.action_pressed.connect(func(_body): study.step_once())
	park()
	study._box("HandShelf", Vector3(.4,.045,.32), Vector3(1.35,.97,-2.3), Color("365159"), true)
	study._box("HandStem", Vector3(.06,.95,.06), Vector3(1.35,.475,-2.3), Color("b39470"), true)
	study._box("HandInstructions", Vector3(.66,.2,.025), Vector3(1.35,.76,-2.37), Color("153237"))
	var label := Label3D.new()
	label.text = "CARRY POINT\nTRIGGER: STEP"
	label.font_size = 30
	label.pixel_size = .0012
	label.position = Vector3(1.35,.76,-2.386)
	label.rotation.y = PI
	label.outline_size = 0
	add_child(label)

func _physics_process(_delta: float) -> void:
	if not point.held(): park()

func park() -> void:
	point.position = Vector3(1.35,1.08,-2.3)
