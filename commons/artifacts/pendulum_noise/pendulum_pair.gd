extends RefCounted
## Two angular pendulums, one recorded horizontal force. SI units; no contact solver.
const DT := 1.0 / 120.0
const LENGTH := 1.1
const MASS := 1.0
const GRAVITY := 9.8
const BASE_DRAG := 0.35 # kg/s; tangential drag = -b * speed
const FORCE_SECONDS := 4.0
const DURATION := 20.0
const SAMPLE_TICKS := 12 # one saved force sample per 0.1 s
const LAST_TICK := 2400
const ANGLE_LIMIT := PI / 3.0 # initial release control only
const ANGLE_TOLERANCE := PI / 90.0 # 2 degrees
const SPEED_TOLERANCE := 0.05 # rad/s
var noise_seed: int = 1847
var sigma_n := 2.0
var changed_drag := 1.2
var compare_damping := false
var initial_angle := 0.6
var unit_forces := PackedFloat64Array()
var angle := PackedFloat64Array([0.6, 0.6])
var omega := PackedFloat64Array([0.0, 0.0])
var peak := PackedFloat64Array([0.6, 0.6])
var last_outside := PackedFloat64Array([4.0, 4.0])
var tick := 0
var history: Array[Dictionary] = []

func _init() -> void:
	resample(noise_seed)

func resample(value: int) -> void:
	noise_seed = value
	var rng := RandomNumberGenerator.new()
	rng.seed = value
	unit_forces.clear()
	for i in 40: unit_forces.append(rng.randfn())
	reset()

func reset() -> void:
	tick = 0
	angle = PackedFloat64Array([initial_angle, initial_angle])
	omega = PackedFloat64Array([0.0, 0.0])
	peak = PackedFloat64Array([absf(initial_angle), absf(initial_angle)])
	last_outside = PackedFloat64Array([FORCE_SECONDS, FORCE_SECONDS])
	history.clear()
	record()

func force_at(at_tick: int, lane: int) -> float:
	if at_tick < 0 or at_tick >= 480: return 0.0
	if lane == 0 and not compare_damping: return 0.0
	return unit_forces[at_tick / SAMPLE_TICKS] * sigma_n

func drag_for(lane: int) -> float:
	return changed_drag if lane == 1 and compare_damping else BASE_DRAG

func acceleration(theta: float, speed: float, force: float, drag: float) -> float:
	# A horizontal force projects onto the tangent through cos(theta).
	return -GRAVITY / LENGTH * sin(theta) - drag / MASS * speed + force * cos(theta) / (MASS * LENGTH)

func step() -> bool:
	if tick >= LAST_TICK: return false
	for lane in 2:
		omega[lane] += acceleration(angle[lane], omega[lane], force_at(tick, lane), drag_for(lane)) * DT
		angle[lane] += omega[lane] * DT
		peak[lane] = maxf(peak[lane], absf(angle[lane]))
	tick += 1
	var time := tick * DT
	if time >= FORCE_SECONDS:
		for lane in 2:
			if absf(angle[lane]) > ANGLE_TOLERANCE or absf(omega[lane]) > SPEED_TOLERANCE:
				last_outside[lane] = time
	if tick % 4 == 0: record()
	return true

func record() -> void:
	history.append({"time":tick * DT, "angles":angle.duplicate(), "speeds":omega.duplicate()})

func settled_at(lane: int) -> float:
	# Only report a terminal window after the finite run, with >= 1 s in tolerance.
	if tick < LAST_TICK or DURATION - last_outside[lane] < 1.0: return -1.0
	return last_outside[lane] + DT

func offset(lane: int) -> Vector3:
	return Vector3(LENGTH * sin(angle[lane]), -LENGTH * cos(angle[lane]), 0)

func energy(lane: int) -> float:
	return 0.5 * MASS * pow(LENGTH * omega[lane], 2) + MASS * GRAVITY * LENGTH * (1.0 - cos(angle[lane]))
