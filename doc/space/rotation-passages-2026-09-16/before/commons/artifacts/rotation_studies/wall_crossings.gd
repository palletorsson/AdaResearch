extends Node3D
## Centre-mounted blades. All landings are cells in Trans_Rotation's grid.
const Parts = preload("res://commons/artifacts/rotation_studies/parts.gd")
const RISE := 3.0
const RUN := 7.0
const THICKNESS := 0.2
const CLIMB_ANGLE := 23.1985905146 # atan(3 / 7), degrees
@export var turn_speed := 15.0
@export var crossing_hold := 12.0
@export var turn_direction := -1.0
var stations: Array[Dictionary] = []
var elapsed := 0.0
var angle := 0.0

func _ready() -> void:
	# The upper face meets y=0 and y=3 at z/x = -3.5 and +3.5.
	var axle_y := RISE/2.0 - THICKNESS/(2.0*cos(deg_to_rad(CLIMB_ANGLE)))
	build_station("Y",Vector3(-12,0,0),Vector3.UP,1.0,Vector3(0,-0.1,0),Vector3(8.4,0.2,2.4),90.0,"CENTRE SWING / LEVEL CROSSING",Color(0.36,0.77,0.5))
	build_station("X",Vector3.ZERO,Vector3.RIGHT,-1.0,Vector3(0,axle_y,0),Vector3(2.4,0.2,8.4),CLIMB_ANGLE,"CENTRE PADDLE / CLIMB FORWARD +3 m",Color(0.93,0.43,0.24))
	build_station("Z",Vector3(12,0,0),Vector3.BACK,1.0,Vector3(0,axle_y,0),Vector3(8.4,0.2,2.4),CLIMB_ANGLE,"CENTRE PADDLE / CLIMB SIDEWAYS +3 m",Color(0.34,0.59,0.95))
	Parts.label(self,"TURN AROUND THE MIDDLE\n8.4 m blades / landings made from the grid",Vector3(0,3.8,-7.5),36)
	set_angle(0)

func build_station(id: String, at: Vector3, axis: Vector3, sign: float, axle: Vector3, size: Vector3, crossing: float, title: String, color: Color) -> void:
	var station := Node3D.new()
	station.name = id
	station.position = at
	add_child(station)
	var pivot := Node3D.new()
	pivot.name = "Pivot"
	pivot.position = axle
	station.add_child(pivot)
	var panel := Parts.box(pivot,"Panel",size,Vector3.ZERO,color)
	Parts.axis(station,axle,axis,color,3.6)
	var readout := Parts.label(station,"",Vector3(0,1.5,-5.9),30)
	stations.append({"id":id,"node":station,"pivot":pivot,"panel":panel,"axis":axis,"sign":sign,"crossing":crossing,"label":readout,"title":title})

func _apply(station: Dictionary, degrees: float) -> void:
	station.pivot.basis = Basis(station.axis,deg_to_rad(degrees*float(station.sign)))
	station.label.text = "%s / %.1f degrees\n%s" % [station.id,degrees,station.title]

func set_angle(degrees: float) -> void:
	angle = degrees
	for station in stations: _apply(station,degrees)

func set_crossing_pose() -> void:
	for station in stations: _apply(station,float(station.crossing))

func _process(delta: float) -> void:
	elapsed += delta
	# A half-turn repeats the geometry of a centred rectangular blade.
	# Advance in one sense, pausing at each traversable alignment.
	var turn_time := 180.0/turn_speed
	var period := turn_time+crossing_hold
	var half_turn := floori(elapsed/period)
	var phase := fposmod(elapsed,period)
	for station in stations:
		var degrees := float(station.crossing)+turn_direction*180.0*half_turn
		if phase>crossing_hold: degrees+=turn_direction*(phase-crossing_hold)*turn_speed
		_apply(station,degrees)
