extends Node3D
## Same five cubes and angle: each local centre versus one shared parent pivot.
const Parts = preload("res://commons/artifacts/rotation_studies/parts.gd")
var bays: Array[Dictionary] = []
var elapsed := 0.0
var angle := 0.0

func _ready() -> void:
	for index in range(2):
		var bay := Node3D.new()
		bay.name = "EachCube" if index==0 else "WholeArray"
		bay.position.x = -5.5 if index==0 else 5.5
		add_child(bay)
		for end in [-1,1]:
			Parts.box(bay,"Bank"+str(end),Vector3(8,0.3,2),Vector3(0,-0.15,end*3.45),Color(0.31,0.34,0.39))
		var group := Node3D.new()
		group.name = "ArrayPivot"
		group.position.y = -0.5
		bay.add_child(group)
		var cubes: Array[Node3D] = []
		for i in range(5):
			var color := Color.from_hsv(0.52+0.06*i,0.5,0.8)
			var cube := Parts.box(group,"Cube"+str(i+1),Vector3(1.04,1,1.04),Vector3((i-2)*1.02,0,0),color)
			# A contrasting edge and index let a quarter-turn of a cube be seen.
			Parts.box(cube,"Facing",Vector3(0.85,0.015,0.06),Vector3(0,0.51,-0.40),Color(1,0.75,0.20),false)
			var number := Parts.label(cube,str(i+1),Vector3(0,0.515,0),52)
			number.rotation_degrees = Vector3(-90,0,0)
			cubes.append(cube)
		Parts.axis(bay,Vector3(0,0.05,0),Vector3.UP,Color(0.93,0.74,0.29),0.3)
		var title := "EACH CUBE / FIVE CENTRES" if index==0 else "WHOLE ARRAY / ONE CENTRE"
		var readout := Parts.label(bay,title,Vector3(0,1.4,-4.1),34)
		bays.append({"node":bay,"group":group,"cubes":cubes,"label":readout,"title":title})
	Parts.label(self,"ONE ARRAY / WHERE DOES THE TURN ACT?",Vector3(0,2.8,-5.5),40)
	set_angle(0)

func set_angle(degrees: float) -> void:
	angle = clampf(degrees,0,90)
	var turn := Basis(Vector3.UP,deg_to_rad(angle))
	# Local positions stay fixed in both cases. Only the chosen basis is changed.
	for cube: Node3D in bays[0].cubes:
		cube.basis = turn
	bays[1].group.basis = turn
	for bay in bays:
		bay.label.text = "%s\nY / %.0f degrees" % [bay.title,angle]

func _process(delta: float) -> void:
	elapsed += delta
	set_angle(Parts.cycle_angle(elapsed))
