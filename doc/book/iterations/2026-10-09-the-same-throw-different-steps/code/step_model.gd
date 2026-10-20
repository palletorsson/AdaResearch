extends RefCounted
## Explicit Euler beside a constant-acceleration reference. Metres and seconds.
const DURATION := 1.0
const COUNTS := [10, 20, 40]
var start := Vector3(-2, .75, 0)
var initial_velocity := Vector3(4, 4.9, 0)
var gravity := Vector3(0, -9.8, 0)
var count := 10
var tick := 0
var position := Vector3.ZERO
var velocity := Vector3.ZERO
var credit := 0.0
var _history: Array[Dictionary] = []

func _init() -> void: reset()
func h() -> float: return DURATION / count
func time() -> float: return tick * h()
func finished() -> bool: return tick == count
func reference_at(t: float) -> Vector3:
	return start + initial_velocity*t + .5*gravity*t*t
func difference() -> Vector3: return position-reference_at(time())
func snapshot() -> Dictionary:
	return {"tick":tick,"time":time(),"position":position,"velocity":velocity,"reference":reference_at(time()),"difference":difference()}
func history() -> Array[Dictionary]: return _history.duplicate(true)
func reset() -> void:
	tick=0; credit=0; position=start; velocity=initial_velocity
	_history=[snapshot()]
func choose_steps(value: int) -> bool:
	if not value in COUNTS: return false
	count=value; reset(); return true
func step() -> bool:
	if finished(): return false
	position += velocity*h()
	velocity += gravity*h()
	tick += 1
	_history.append(snapshot())
	return true
func advance(seconds: float) -> void:
	if not is_finite(seconds) or seconds<=0 or finished(): return
	# The entire run is at most forty steps, even after a long render frame.
	credit += minf(seconds,DURATION)
	while credit+1e-9>=h() and not finished():
		credit -= h(); step()
	if finished(): credit=0
