extends RefCounted
const WIDTH := 16
const SPEED := 3.0
const RESPONSE := 0.5
const MAX_ACCEL := 6.0
const DT := 0.05
var vectors := PackedVector2Array()
var positions: Array[Vector2] = []
var velocities: Array[Vector2] = []
var patch_mode := 0
var steps := 0

func _init() -> void:
	reset()

func reset() -> void:
	vectors.resize(WIDTH * WIDTH)
	vectors.fill(Vector2.RIGHT)
	positions.assign([Vector2(4,8), Vector2(12,8), Vector2(8,4),
		Vector2(8,12), Vector2(4,4), Vector2(12,12)])
	velocities.resize(positions.size())
	velocities.fill(Vector2.ZERO)
	patch_mode = 0
	steps = 0
	set_patch()

func wrap_position(p: Vector2) -> Vector2:
	return Vector2(fposmod(p.x, WIDTH), fposmod(p.y, WIDTH))

func index_at(p: Vector2) -> int:
	var cell := Vector2i(wrap_position(p).floor())
	return cell.x + cell.y * WIDTH

func sample(p: Vector2) -> Vector2:
	return vectors[index_at(p)]

func set_patch() -> void:
	var directions := [Vector2(0,1), Vector2.ZERO, Vector2.RIGHT]
	for y in range(4,12):
		for x in range(8,12):
			vectors[x + y * WIDTH] = directions[patch_mode]

func edit_cell(p: Vector2) -> void:
	var address := index_at(p)
	var old := vectors[address]
	vectors[address] = Vector2(0,1) if old == Vector2.RIGHT else (
		Vector2.ZERO if old == Vector2(0,1) else Vector2.RIGHT)

func desired_at(p: Vector2) -> Vector2:
	return sample(p).normalized() * SPEED

func acceleration(i: int) -> Vector2:
	return ((desired_at(positions[i]) - velocities[i]) / RESPONSE).limit_length(MAX_ACCEL)

func step() -> void:
	# The field is read-only during motion. Nobody deposits a trace.
	for i in range(positions.size()):
		velocities[i] = (velocities[i] + acceleration(i) * DT).limit_length(SPEED)
		positions[i] = wrap_position(positions[i] + velocities[i] * DT)
	steps += 1
