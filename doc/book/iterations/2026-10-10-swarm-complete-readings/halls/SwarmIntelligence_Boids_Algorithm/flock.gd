extends RefCounted
const WIDTH := 16
const SPEED := 3.0
const RESPONSE := 0.5
const MAX_ACCEL := 6.0
const DT := 0.05
const CLOSE := 2.0
var positions: Array[Vector2] = []
var velocities: Array[Vector2] = []
var radius := 3.5
var weights := Vector3(1.5, 1.0, 1.0)
var mode := 0 # Separation, alignment, cohesion, all three.
var steps := 0

func _init() -> void:
	reset()

func reset() -> void:
	positions.assign([Vector2(6,8), Vector2(7,8), Vector2(8,9),
		Vector2(11,7), Vector2(4,12), Vector2(12,12)])
	velocities.assign([Vector2(1,0), Vector2(0,2), Vector2(0,2),
		Vector2(-2,0), Vector2(1,-1), Vector2(-1,-1)])
	steps = 0

func wrap_position(p: Vector2) -> Vector2:
	return Vector2(fposmod(p.x,WIDTH), fposmod(p.y,WIDTH))

func neighbours(i: int) -> Array[int]:
	var found: Array[int] = []
	for j in range(positions.size()):
		if j != i and positions[i].distance_to(positions[j]) < radius:
			found.append(j)
	return found

func steer_to(desired: Vector2, i: int) -> Vector2:
	return ((desired - velocities[i]) / RESPONSE).limit_length(MAX_ACCEL)

func requests(i: int) -> Array[Vector2]:
	var result: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	var nearby := neighbours(i)
	if nearby.is_empty(): return result
	var away := Vector2.ZERO
	var velocity_sum := Vector2.ZERO
	var offset_sum := Vector2.ZERO
	for j in nearby:
		var offset := positions[j] - positions[i]
		var d2 := offset.length_squared()
		if d2 > 0.000001 and d2 < CLOSE*CLOSE:
			away -= offset / d2
		velocity_sum += velocities[j]
		offset_sum += offset
	if not away.is_zero_approx():
		result[0] = steer_to(away.normalized()*SPEED, i)
	result[1] = steer_to(velocity_sum/nearby.size(), i)
	var centre_offset := offset_sum/nearby.size()
	if not centre_offset.is_zero_approx():
		result[2] = steer_to(centre_offset.normalized()*SPEED, i)
	return result

func acceleration(i: int) -> Vector2:
	var parts := requests(i)
	var total := Vector2.ZERO
	for rule in range(3):
		if mode == 3 or mode == rule:
			total += parts[rule]*weights[rule]
	return total.limit_length(MAX_ACCEL)

func step() -> void:
	var next_positions: Array[Vector2] = []
	var next_velocities: Array[Vector2] = []
	for i in range(positions.size()):
		var v := (velocities[i] + acceleration(i)*DT).limit_length(SPEED)
		next_velocities.append(v)
		next_positions.append(wrap_position(positions[i] + v*DT))
	positions = next_positions
	velocities = next_velocities
	steps += 1
