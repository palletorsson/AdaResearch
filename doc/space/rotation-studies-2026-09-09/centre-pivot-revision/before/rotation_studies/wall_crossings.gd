extends Node3D
## One panel size, three explicitly different mounts and axes. Banks stay still.
const Parts = preload("res://commons/artifacts/rotation_studies/parts.gd")
var stations: Array[Dictionary] = []
var elapsed := 0.0
var angle := 0.0

func _ready() -> void:
	build_station("Y",Vector3(-8,0,0),Vector3.UP,1.0,Vector3(0,-0.1,0),Vector3(3.6,0.2,1.2),Vector3.ZERO,"SWING FLAT\ncentre pivot",Color(0.36,0.77,0.5))
	build_station("X",Vector3.ZERO,Vector3.RIGHT,1.0,Vector3(0,-0.1,-1.8),Vector3(1.2,3.6,0.2),Vector3(0,1.8,0),"LOWER FORWARD\nbottom hinge",Color(0.93,0.43,0.24))
	build_station("Z",Vector3(8,0,0),Vector3.BACK,-1.0,Vector3(-1.8,-0.1,0),Vector3(0.2,3.6,1.2),Vector3(0,1.8,0),"LOWER SIDEWAYS\nbottom hinge",Color(0.34,0.59,0.95))
	Parts.label(self,"ONE PANEL / THREE MOUNTS\n3.6 x 1.2 x 0.2 m",Vector3(0,2.7,-5.2),40)
	set_angle(0)

func build_station(id: String, at: Vector3, axis: Vector3, sign: float, hinge: Vector3, size: Vector3, centre: Vector3, title: String, color: Color) -> void:
	var station := Node3D.new()
	station.name = id
	station.position = at
	add_child(station)
	for end in [-1,1]:
		var bank_size := Vector3(6.4,0.3,2)
		var bank_pos := Vector3(0,-0.15,end*2.7)
		if id == "Z":
			bank_size = Vector3(2,0.3,6.4)
			bank_pos = Vector3(end*2.7,-0.15,0)
		Parts.box(station,"Bank"+str(end),bank_size,bank_pos,Color(0.31,0.34,0.39))
	var pivot := Node3D.new()
	pivot.name = "Pivot"
	pivot.position = hinge
	station.add_child(pivot)
	Parts.box(pivot,"Panel",size,centre,color)
	Parts.axis(station,hinge,axis,color,4.2)
	var readout := Parts.label(station,"",Vector3(0,1.3,-3.9),34)
	stations.append({"id":id,"node":station,"pivot":pivot,"axis":axis,"sign":sign,"label":readout,"title":title})

func set_angle(degrees: float) -> void:
	angle = clampf(degrees,0,90)
	for station in stations:
		station.pivot.basis = Basis(station.axis,deg_to_rad(angle*float(station.sign)))
		station.label.text = "%s / %.0f degrees\n%s" % [station.id,angle,station.title]

func _process(delta: float) -> void:
	elapsed += delta
	set_angle(Parts.cycle_angle(elapsed))
