extends RefCounted
## A fixed two-dimensional course. Noise changes range, not geometry or waypoints.
const DT := 0.05
const LAST_TICK := 400
const SPEED := 0.6
const RADIUS := 0.14
const OBSTACLE_RADIUS := 0.25
const CLEARANCE := 0.5
const START_X := -1.65
const GOAL := Vector2(1.65,0)
const WAYPOINTS := [Vector2(-.65,.65),Vector2(.65,.65),GOAL]
const COURSE_MIN := Vector2(-1.85,-.18)
const COURSE_MAX := Vector2(1.85,.8)
const TERMINAL := ["GOAL","CONTACT","LEFT COURSE","TIMEOUT"]
var sample_seed := 1847
var sigma_m := .5
var dropout := .65
var missing_mode := false
var hold_command := false
var start_y := 0.0
var unit_noise := PackedFloat64Array()
var uniforms := PackedFloat64Array()
var tick := 0
var positions: Array[Vector2] = []
var commands: Array[Vector2] = []
var stages: Array[int] = [] # -1: approach goal; 0,1,2: detour waypoints.
var observations: Array = [] # A missing reading is null, never a numeric distance.
var sensed_true: Array[float] = []
var outcomes: Array[String] = []
var elapsed: Array[float] = []
var lengths: Array[float] = []
var history: Array[Dictionary] = []

func _init() -> void:
	resample(sample_seed); reset()

func resample(value: int) -> void:
	sample_seed=value
	var rng := RandomNumberGenerator.new(); rng.seed=sample_seed
	unit_noise.clear(); uniforms.clear()
	# Forty half-second blocks. Each has one saved range error and dropout draw.
	for i in 40:
		unit_noise.append(rng.randfn()); uniforms.append(rng.randf())

func reset() -> void:
	tick=0; positions=[Vector2(START_X,start_y),Vector2(START_X,start_y)]
	commands=[Vector2.ZERO,Vector2.ZERO]; stages=[-1,-1]
	observations=[null,null]; sensed_true=[distance_at(positions[0]),distance_at(positions[1])]
	outcomes=["READY","READY"]; elapsed=[0.0,0.0]; lengths=[0.0,0.0]; history.clear()

func distance_at(p: Vector2) -> float:
	return p.length()-OBSTACLE_RADIUS-RADIUS # Surface-to-surface clearance, metres.

func reading(lane: int, t: int, truth: float) -> Variant:
	if lane==0: return truth
	var block := mini(t/10,39)
	if missing_mode: return null if uniforms[block]<dropout else truth
	return truth+sigma_m*unit_noise[block] # Negative observations remain visible.

func decision(p: Vector2, stage: int, observed: Variant, previous: Vector2) -> Dictionary:
	if observed==null:
		return {"stage":stage,"command":previous if hold_command else Vector2.ZERO,"reason":"HOLD" if hold_command else "STOP"}
	if stage<0 and float(observed)<=CLEARANCE: stage=0
	if stage>=0 and stage<2 and p.distance_to(WAYPOINTS[stage])<.001: stage+=1
	var target: Vector2 = GOAL if stage<0 else WAYPOINTS[stage]
	var command := (target-p).limit_length(SPEED*DT)/DT
	return {"stage":stage,"command":command,"reason":"SEEK" if stage<0 else "DETOUR %d"%stage}

func contact_fraction(a: Vector2, b: Vector2) -> float:
	# Swept point versus expanded disc: first contact, including between endpoints.
	var radius := OBSTACLE_RADIUS+RADIUS
	var c := a.length_squared()-radius*radius
	if c<=0: return 0.0
	var d := b-a; var aa := d.length_squared()
	if aa<1e-16: return -1.0
	var bb := 2*a.dot(d); var discriminant := bb*bb-4*aa*c
	if discriminant<0: return -1.0
	var fraction := (-bb-sqrt(discriminant))/(2*aa)
	return fraction if fraction>=0 and fraction<=1 else -1.0

func finished() -> bool:
	return tick>=LAST_TICK or (outcomes[0] in TERMINAL and outcomes[1] in TERMINAL)

func exit_fraction(a: Vector2,b: Vector2) -> float:
	var fraction := 2.0
	for axis in 2:
		if b[axis]>COURSE_MAX[axis]: fraction=minf(fraction,(COURSE_MAX[axis]-a[axis])/(b[axis]-a[axis]))
		if b[axis]<COURSE_MIN[axis]: fraction=minf(fraction,(COURSE_MIN[axis]-a[axis])/(b[axis]-a[axis]))
	return fraction if fraction<=1 else -1.0

func step() -> bool:
	if finished(): return false
	var rows: Array[Dictionary]=[]
	for lane in 2:
		if outcomes[lane] in TERMINAL:
			rows.append({"inactive":true}); continue
		var before := positions[lane]
		# The sensor is read every simulation step; its recorded error is held .5s.
		sensed_true[lane]=distance_at(before)
		observations[lane]=reading(lane,tick,sensed_true[lane])
		var result := decision(before,stages[lane],observations[lane],commands[lane])
		stages[lane]=result.stage; commands[lane]=result.command
		var next := before+commands[lane]*DT
		var fraction := contact_fraction(before,next)
		var exit := exit_fraction(before,next)
		outcomes[lane]=result.reason
		if exit>=0 and (fraction<0 or exit<fraction):
			next=before.lerp(next,exit); outcomes[lane]="LEFT COURSE"
		elif fraction>=0:
			next=before.lerp(next,fraction); outcomes[lane]="CONTACT"
		positions[lane]=next; lengths[lane]+=before.distance_to(next)
		elapsed[lane]=(tick+1)*DT
		if outcomes[lane] not in TERMINAL and next.distance_to(GOAL)<.001: outcomes[lane]="GOAL"
		if tick+1==LAST_TICK and outcomes[lane] not in TERMINAL: outcomes[lane]="TIMEOUT"
		rows.append({"from":before,"to":next,"true":sensed_true[lane],"observed":observations[lane],"command":commands[lane],"stage":stages[lane],"outcome":outcomes[lane]})
	# New dictionaries and value-type vectors: old records do not alias current state.
	history.append({"time":tick*DT,"lanes":rows}); tick+=1
	return true
