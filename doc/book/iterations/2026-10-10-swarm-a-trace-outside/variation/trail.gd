extends RefCounted
const WIDTH := 16
const SENSOR_DISTANCE := 1.5
const TURN := PI / 4.0
var retention := 0.92
var values := PackedFloat32Array()
var positions: Array[Vector2] = []
var headings: Array[float] = []
var steps := 0

func _init() -> void:
	reset()

func reset() -> void:
	values.resize(WIDTH * WIDTH)
	values.fill(0.0)
	positions.assign([Vector2(6,8), Vector2(12,8), Vector2(8,4),
		Vector2(8,12), Vector2(4,4), Vector2(12,12)])
	headings.assign([0.0, PI, PI/2.0, -PI/2.0, PI/4.0, -3.0*PI/4.0])
	steps = 0

func wrap_position(p: Vector2) -> Vector2:
	return Vector2(fposmod(p.x, WIDTH), fposmod(p.y, WIDTH))

func index_at(p: Vector2) -> int:
	var cell := Vector2i(wrap_position(p).floor())
	return cell.x + cell.y * WIDTH

func sensor_position(agent: int, offset: float) -> Vector2:
	return wrap_position(positions[agent] + Vector2.from_angle(headings[agent] + offset) * SENSOR_DISTANCE)

func sense(agent: int, offset: float) -> float:
	return values[index_at(sensor_position(agent, offset))]

func deposit(p: Vector2) -> void:
	var cell := index_at(p)
	values[cell] = minf(8.0, values[cell] + 1.0)

func step() -> void:
	# Everyone reads the old field before anyone changes it.
	for i in range(positions.size()):
		var left := sense(i, TURN)
		var ahead := sense(i, 0.0)
		var right := sense(i, -TURN)
		if left > ahead and left > right:
			headings[i] += TURN
		elif right > ahead and right > left:
			headings[i] -= TURN
		# Equal readings keep the current heading.
		positions[i] = wrap_position(positions[i] + Vector2.from_angle(headings[i]) * 0.45)
	for cell in range(values.size()):
		values[cell] *= retention
	for p in positions:
		deposit(p)
	steps += 1
