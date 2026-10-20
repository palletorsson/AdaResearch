extends Node3D
## Centre-mounted blades. All landings are cells in Trans_Rotation's grid.
const Parts = preload("res://commons/artifacts/rotation_studies/parts.gd")
const RideDeck = preload("res://commons/artifacts/rotation_studies/rotation_rider_deck.gd")
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
var manual_pose := false
var ride_progress := 0.0
var ride_rise := RISE
var ride_run := RUN

func _ready() -> void:
	process_physics_priority = -110 # Carry before XRTools' -100 body update.
	# A tower can place the same rides independently. Defaults keep the museum.
	var single_axis := str(get_meta("config_single_axis", ""))
	ride_rise = clampf(float(get_meta("config_ride_rise", RISE)), 1.0, RISE)
	ride_run = clampf(float(get_meta("config_ride_run", RUN)), 3.0, RUN)
	var climb := rad_to_deg(atan2(ride_rise, ride_run))
	var length := sqrt(ride_rise*ride_rise+ride_run*ride_run)+0.78
	var axle_y := ride_rise/2.0 - THICKNESS/(2.0*cos(deg_to_rad(climb)))
	if single_axis.is_empty() or single_axis == "Y":
		build_station("Y",Vector3(-12,0,0) if single_axis.is_empty() else Vector3.ZERO,Vector3.UP,1.0,Vector3(0,-0.1,0),Vector3(8.4,0.2,2.4),90.0,"CENTRE SWING / LEVEL CROSSING",Color(0.36,0.77,0.5))
	if single_axis.is_empty() or single_axis == "X":
		build_station("X",Vector3.ZERO,Vector3.RIGHT,-1.0,Vector3(0,axle_y,0),Vector3(2.4,0.2,length if not single_axis.is_empty() else 8.4),climb,"CENTRE PADDLE / CLIMB FORWARD",Color(0.93,0.43,0.24))
	if single_axis.is_empty() or single_axis == "Z":
		build_station("Z",Vector3(12,0,0) if single_axis.is_empty() else Vector3.ZERO,Vector3.BACK,1.0,Vector3(0,axle_y,0),Vector3(length if not single_axis.is_empty() else 8.4,0.2,2.4),climb,"CENTRE PADDLE / CLIMB SIDEWAYS",Color(0.34,0.59,0.95))
	if single_axis.is_empty():
		Parts.label(self,"TURN AROUND THE MIDDLE\n8.4 m blades / landings made from the grid",Vector3(0,3.8,-7.5),36)
	else:
		for station in stations:
			station.label.position = Vector3(0,1.6,-ride_run/2.0-1.4)
			station.label.font_size = 23
	for station in stations:
		if station.id == "Y": continue
		var deck = RideDeck.new()
		deck.name = "LevelEndPlatform"
		deck.along_z = station.id == "X"
		deck.color = Color("e5b286") if deck.along_z else Color("93c1df")
		station.node.add_child(deck)
		station["ride_deck"] = deck
		# A visible arm along the axle joins the offset deck to the rotor. The
		# offset lets a standing rider clear the blade's entire vertical sweep.
		station["arm"] = Parts.box(station.node,"DeckArm",Vector3(2.2,0.08,0.08) if deck.along_z else Vector3(0.08,0.08,2.2),Vector3.ZERO,Color("d9ceb7"),false)
	set_crossing_pose()
	manual_pose = false

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
	manual_pose = true
	angle = degrees
	for station in stations: _apply(station,degrees)

func set_crossing_pose() -> void:
	manual_pose = true
	elapsed = 0.0
	ride_progress = 0.0
	for station in stations: _apply(station,float(station.crossing))
	_place_decks(0.0)

func start_rides() -> void:
	elapsed = 0.0
	manual_pose = false

func _physics_process(delta: float) -> void:
	if manual_pose:
		_place_decks(ride_progress)
		return
	elapsed += delta
	# A half-turn repeats the geometry of a centred rectangular blade.
	# Advance in one sense, pausing at each traversable alignment.
	var turn_time := 180.0/turn_speed
	var period := turn_time+crossing_hold
	var half_turn := floori(elapsed/period)
	var phase := fposmod(elapsed,period)
	var y_degrees := 90.0+turn_direction*180.0*half_turn
	if phase>crossing_hold: y_degrees+=turn_direction*(phase-crossing_hold)*turn_speed
	for station in stations:
		if station.id == "Y": _apply(station,y_degrees)
	# The occupied end traverses the upper arc and retraces it. It never
	# continues around through the basin on the return journey.
	var leg := floori(elapsed/period)
	var amount := clampf((phase-crossing_hold)/turn_time,0.0,1.0)
	ride_progress = amount if leg%2 == 0 else 1.0-amount
	for station in stations:
		if station.id == "Y": continue
		_apply(station,float(station.crossing)-180.0*ride_progress)
	_place_decks(ride_progress)

func _place_decks(progress: float) -> void:
	for station in stations:
		if not station.has("ride_deck"): continue
		var forward: bool = station.id == "X"
		var radial := Vector3(0,-ride_rise/2.0,-ride_run/2.0) if forward else Vector3(-ride_run/2.0,-ride_rise/2.0,0)
		var orbit := Basis(station.axis,PI*progress*(1.0 if forward else -1.0))*radial
		# The upright bracket offsets the old thickness-compensated blade axle.
		var endpoint := Vector3(0,ride_rise/2.0,0)+orbit
		var offset := Vector3(-2.2,0,0) if forward else Vector3(0,0,-2.2)
		station.ride_deck.transport_to(endpoint+offset)
		station.arm.position = endpoint+offset*0.5+Vector3(0,-0.15,0)
		var remaining := maxf(0.0,crossing_hold-fposmod(elapsed,180.0/turn_speed+crossing_hold))
		var at_dock := is_zero_approx(progress) or is_equal_approx(progress,1.0)
		station.label.text = "%s / LEVEL END-PLATFORM\n%s / UP %.1f m\n%s" % [station.id,"FORWARD +Z" if forward else "SIDEWAYS +X",ride_rise,("DOCK / %.0f seconds" % remaining) if remaining>0 and at_dock else "HALF-TURN / STAY ON THE LEVEL DECK"]

func prepare_editor_preview() -> void:
	set_crossing_pose()
