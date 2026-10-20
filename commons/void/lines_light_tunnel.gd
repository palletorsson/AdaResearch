extends "res://commons/artifacts/line_black_box/line_black_box.gd"
## A detachable editor part. Two open ends; the roof makes the carried light felt.
func _ready() -> void:
	var dark := _material(Color("15191e"),.84)
	var steel := _material(Color("34373e"),.45)
	_box("West",Vector3(.12,2.75,4.8),Vector3(-1.3,1.375,0),dark,true)
	_box("East",Vector3(.12,2.75,4.8),Vector3(1.3,1.375,0),dark,true)
	_box("Roof",Vector3(2.72,.12,4.8),Vector3(0,2.75,0),dark,true)
	for z in [-2.3,-1.15,0,1.15,2.3]:
		for x in [-1.2,1.2]: _box("Rib",Vector3(.06,2.6,.06),Vector3(x,1.3,z),steel)
		_box("Rib",Vector3(2.46,.06,.06),Vector3(0,2.6,z),steel)
	var title := _label("04 / CARRY A LINE OF LIGHT",Vector3(0,2.98,-2.45),32,Color("e9ddd9"))
	title.rotation=Vector3(0,PI,0)
	var invitation := _label("Take the pink stick. Walk through.",Vector3(0,2.28,-2.45),23,Color("edd7e4"))
	invitation.rotation.y=PI
	for x in [-1.13,1.13]:
		_box("LowEdge",Vector3(.018,.014,4.6),Vector3(x,.03,0),_material(Color("8f687f"),.7,.15))

func _process(_delta: float) -> void: pass
