extends Node3D
## The carried point supplies a position to the existing rule; trigger steps it.
var study:Node3D
var point:XRToolsPickable
func _ready() -> void:
	study=get_parent()
	point=load("res://commons/artifacts/ca_rule_explorer/point_body.gd").new()
	point.name="PointBody";add_child(point)
	point.action_pressed.connect(func(_body): study.source_mode=3;study.step_once())
	park()
	study.box("PointShelf",Vector3(.4,.05,.35),Vector3(-4.05,.97,-1.6),Color("365159"),true)
	study.box("PointStem",Vector3(.06,.95,.06),Vector3(-4.05,.475,-1.6),Color("bf9469"),true)
	study.box("PointCaption",Vector3(.85,.27,.025),Vector3(-4.05,.72,-1.8),Color("153237"))
	var caption:Label3D=study.label("HandCaption","HOLD POINT NEAR A CELL\nTRIGGER: HAND + STEP\nRELEASE: RECOVERY",28)
	caption.position=Vector3(-4.05,.72,-1.816);caption.rotation.y=PI;add_child(caption)
func _physics_process(_delta:float) -> void:
	if not point.held():park()
func park() -> void:
	point.position=Vector3(-4.05,1.08,-1.6)
