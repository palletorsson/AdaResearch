extends RefCounted
## Deliberately small ABM: a heard position is a record, not a live target.
enum State { RESTING, INVESTIGATING, RETURNING }
const COUNT := 20
const HEARING_RADIUS := 8.0
const SPEED := 1.6
const LIMIT := Vector2(4.25, 3.35)
const WALL_MARGIN := 0.36
const GAP := 0.85 # Half opening after allowing for the body's radius.
var positions: Array[Vector2] = []
var velocities: Array[Vector2] = []
var homes: Array[Vector2] = []
var memories: Array[Vector2] = []
var states: Array[int] = []
var dwell: Array[float] = []
var pulses := 0

func _init() -> void:
	for i in range(COUNT):
		var p := Vector2(1.25 + (i % 4) * 0.85, -2.8 + (i / 4) * 1.4)
		positions.append(p); homes.append(p); memories.append(p)
		velocities.append(Vector2.ZERO); states.append(State.RESTING); dwell.append(0.0)

func valid_source(source: Vector3) -> bool:
	return source.is_finite() and absf(source.x) <= LIMIT.x and absf(source.z) <= LIMIT.y and source.y >= 0 and source.y <= 4 and not (absf(source.x) < WALL_MARGIN and absf(source.z) > GAP)

func pulse(source: Vector3) -> int:
	if not valid_source(source): return 0
	var heard := 0
	for i in range(COUNT):
		var ear := Vector3(positions[i].x, 1.4, positions[i].y)
		if ear.distance_to(source) <= HEARING_RADIUS:
			memories[i] = Vector2(source.x, source.z)
			states[i] = State.INVESTIGATING; dwell[i] = 0.0; heard += 1
	pulses += 1
	return heard

func waypoint(p: Vector2, destination: Vector2) -> Vector2:
	if p.x * destination.x < 0:
		var crossing := lerpf(p.y, destination.y, -p.x / (destination.x - p.x))
		if absf(crossing) > GAP * 0.6:
			# A supplied single-door route, not a general search algorithm.
			if absf(p.y) > GAP * 0.45: return Vector2(signf(p.x) * 0.7, 0)
			return Vector2(-signf(p.x) * 0.7, 0)
	return destination

func step(dt: float) -> void:
	dt = clampf(dt, 0.0, 0.05)
	var old := positions.duplicate()
	for i in range(COUNT):
		if states[i] == State.RESTING:
			velocities[i] = Vector2.ZERO; continue
		var p: Vector2 = old[i]
		var destination: Vector2 = memories[i] if states[i] == State.INVESTIGATING else homes[i]
		var distance := p.distance_to(destination)
		var target := waypoint(p, destination)
		var arrived := distance < (1.0 if states[i] == State.INVESTIGATING else 0.12) and target.is_equal_approx(destination)
		if arrived:
			velocities[i] = Vector2.ZERO
			if states[i] == State.INVESTIGATING:
				dwell[i] += dt
				if dwell[i] >= 3.0: states[i] = State.RETURNING
			else:
				positions[i] = homes[i]; states[i] = State.RESTING
			continue
		var desired := p.direction_to(target) * SPEED * minf(p.distance_to(target) / 0.6, 1.0)
		var separation := Vector2.ZERO
		for j in range(COUNT):
			if i == j: continue
			var difference: Vector2 = p - old[j]
			var d := difference.length()
			if d > 0.001 and d < 0.52:
				separation += difference / d * (0.52 - d) * 4.0
		var v := velocities[i].move_toward((desired + separation).limit_length(SPEED), 5.0 * dt)
		var next := p + v * dt
		next.x = clampf(next.x, -LIMIT.x, LIMIT.x); next.y = clampf(next.y, -LIMIT.y, LIMIT.y)
		# Solid partition: no through-wall steering, even with a large external dt.
		if absf(next.x) < WALL_MARGIN and absf(next.y) > GAP:
			next.x = signf(p.x) * WALL_MARGIN; v.x = 0
		positions[i] = next; velocities[i] = v

func counts() -> Array[int]:
	var result: Array[int] = [0, 0, 0]
	for state in states: result[state] += 1
	return result
