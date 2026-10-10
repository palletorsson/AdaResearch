extends Node3D
const PointBody = preload("res://doc/book/studies/lsystems-through-the-hands/LSystems_Grammar_Lab/point_body.gd")
var desk: Node3D
var point: XRToolsPickable
var last_slot := -1
func _ready() -> void:
	desk = get_parent()
	point = PointBody.new(); point.name = "ArchitecturePoint"; add_child(point)
	point.action_pressed.connect(func(_body): desk.act("PLAN" if desk.built else "BUILD"))
	desk.box(Vector3(0,1.01,2.55),Vector3(1.3,.07,.22),desk.material("e5e0dc"),true)
	for i in 3:
		var tag=desk.label(str(desk.WIDTHS[i]),Vector3((i-1)*.35,1.055,2.62),.0008)
		tag.rotation_degrees.x=-60
	desk.label("MOVE: WIDTH / HELD TRIGGER: BUILD OR PLAN",Vector3(0,.95,2.67),.00063)
	park()
func _physics_process(_dt: float) -> void:
	if point.held():
		var slot:=clampi(roundi(to_local(point.global_position).x/.35+1),0,2)
		if slot!=last_slot:
			last_slot=slot
			if slot==desk.width_index:return
			if desk.people_inside():
				desk.act("WIDTH") # Existing refusal; no queued construction after exit.
				return
			desk.width_index=slot;desk.notice="";desk.show_rule=false;desk.rebuild()
	else:
		last_slot=-1;park()
func park() -> void:
	point.global_transform=global_transform*Transform3D(Basis.IDENTITY,Vector3((desk.width_index-1)*.35,1.18,2.55))
