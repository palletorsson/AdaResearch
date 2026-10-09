extends Node3D
## Same PointBody: choose a spatial section without changing the paired state.
const FIRST_Z := -2.25
const PITCH := 0.11
var study: Node3D
var point: XRToolsPickable
var was_held := false

func _ready() -> void:
	study = get_parent()
	point = load("res://commons/artifacts/ca_rule_explorer/point_body.gd").new()
	point.name = "PointBody"
	add_child(point)
	park()
	point.action_pressed.connect(func(_p): study.operate(0))
	study.box("SliceHandRail",Vector3(.018,.018,1.26),Vector3(-3.35,1.08,-1.7),Color("ffd18e"))
	study.box("SliceHandFoot",Vector3(.35,1.02,.35),Vector3(-3.35,.51,-1.7),Color("e4dfd4"),true)
	var words:Label3D=study.label("HandReadsSlice","MOVE POINT: Z SLICE / TRIGGER: STEP\nHAND WHILE HELD; WALK AFTER RELEASE",26)
	words.position=Vector3(-3.35,1.5,-2.46);words.rotation.y=PI
	study.add_child(words)

func _physics_process(_delta: float) -> void:
	if point.held():
		var z:float=to_local(point.global_position).z
		study.select_spatial_slice(roundi((z-FIRST_Z)/PITCH))
		was_held=true
	else:
		if was_held and is_instance_valid(study.slice_walker):
			study.slice_walker.last_band=-1
		was_held=false
		park()

func park() -> void:
	point.position=Vector3(-3.35,1.24,FIRST_Z+PITCH*study.slice_z)
