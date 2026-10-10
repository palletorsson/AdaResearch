extends Node3D
## The carried point places one matched seed, using the existing field states.
var study:Node3D
var point:XRToolsPickable
func _ready() -> void:
	study=get_parent()
	point=load("res://commons/artifacts/ca_rule_explorer/point_body.gd").new();add_child(point)
	point.action_pressed.connect(func(_body):plant())
	study.box("SeedPointShelf",Vector3(.4,.05,.35),Vector3(-5.85,.97,-1.7),Color("365159"),true)
	study.box("SeedPointStem",Vector3(.06,.95,.06),Vector3(-5.85,.475,-1.7),Color("bf9469"),true)
	study.box("SeedPointCaption",Vector3(1,.3,.025),Vector3(-5.85,.7,-1.92),Color("153237"))
	var caption:Label3D=study.label("SeedPointWords","HOLD OVER EITHER TABLE\nTRIGGER: SEED BOTH FIELDS\nSTEP AT THE DESK",26)
	caption.position=Vector3(-5.85,.7,-1.94);caption.rotation.y=PI;add_child(caption);park()
func target_site() -> Vector2i:
	if not point.held():return Vector2i(-1,-1)
	var at:Vector3=study.to_local(point.global_position)
	for cx:float in [2.45,-2.45]:
		if absf(at.x-cx)<.8 and absf(at.z-.5)<.8 and absf(at.y-.967)<.35:
			return Vector2i(floori((at.x-cx+.8)/.05),floori((at.z-.5+.8)/.05))
	return Vector2i(-1,-1)
func plant() -> void:
	var site:=target_site()
	if site.x>=0:study.inject_at(site)
func _physics_process(_delta:float) -> void:
	if not point.held():park()
func park() -> void:point.position=Vector3(-5.85,1.08,-1.7)
