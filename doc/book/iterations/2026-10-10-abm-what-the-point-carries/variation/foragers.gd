extends RefCounted
const WIDTH := 16
const DT := 0.05
const SPEED := 3.0
const RESPONSE := 0.5
const MAX_ACCEL := 6.0
const TURN := PI / 4.0
const SENSOR_DISTANCE := 1.5
const HOME := Vector2(3,8)
const FOOD := Vector2(12,8)
const CONTACT := 1.0
var retention := 0.92
var return_speed := 1.5
var values := PackedFloat32Array()
var positions: Array[Vector2] = []
var velocities: Array[Vector2] = []
var carrying: Array[bool] = []
var delivered := 0
var steps := 0

func _init() -> void:
	reset()

func replace_agents() -> void:
	positions.assign([Vector2(3,7.4), Vector2(4.2,7.4), Vector2(5.4,7.4),
		Vector2(3,8.6), Vector2(4.2,8.6), Vector2(5.4,8.6)])
	velocities.clear()
	carrying.clear()
	for i in range(positions.size()):
		velocities.append(Vector2(SPEED,0))
		carrying.append(false)

func reset() -> void:
	values.resize(WIDTH*WIDTH)
	values.fill(0.0)
	delivered = 0
	steps = 0
	replace_agents()

func wrap_position(p: Vector2) -> Vector2:
	return Vector2(fposmod(p.x,WIDTH),fposmod(p.y,WIDTH))

func index_at(p: Vector2) -> int:
	var cell := Vector2i(wrap_position(p).floor())
	return cell.x + cell.y*WIDTH

func sensor_position(i: int, offset: float) -> Vector2:
	var heading := velocities[i].angle() if not velocities[i].is_zero_approx() else 0.0
	return wrap_position(positions[i] + Vector2.from_angle(heading+offset)*SENSOR_DISTANCE)

func sense(i: int, offset: float) -> float:
	return values[index_at(sensor_position(i,offset))]

func search_velocity(i: int) -> Vector2:
	var direction := velocities[i].normalized() if not velocities[i].is_zero_approx() else Vector2.RIGHT
	var left := sense(i,TURN)
	var ahead := sense(i,0.0)
	var right := sense(i,-TURN)
	if left > ahead and left > right:
		direction = direction.rotated(TURN)
	elif right > ahead and right > left:
		direction = direction.rotated(-TURN)
	return direction*SPEED

func step() -> void:
	var next_positions: Array[Vector2] = []
	var next_velocities: Array[Vector2] = []
	var next_carrying: Array[bool] = []
	for i in range(positions.size()):
		var has_food := carrying[i]
		var arrived_home := has_food and positions[i].distance_to(HOME) < CONTACT
		if arrived_home:
			has_food = false
			delivered += 1
		elif not has_food and positions[i].distance_to(FOOD) < CONTACT:
			has_food = true
		var desired: Vector2
		if has_food:
			desired = (HOME-positions[i]).normalized()*return_speed
		elif arrived_home:
			desired = Vector2(SPEED,0)
		else:
			desired = search_velocity(i)
		var a := ((desired-velocities[i])/RESPONSE).limit_length(MAX_ACCEL)
		var v := (velocities[i]+a*DT).limit_length(SPEED)
		next_velocities.append(v)
		next_positions.append(wrap_position(positions[i]+v*DT))
		next_carrying.append(has_food)
	positions = next_positions
	velocities = next_velocities
	carrying = next_carrying
	for cell in range(values.size()):
		values[cell] *= retention
	for i in range(positions.size()):
		if carrying[i]:
			var cell := index_at(positions[i])
			values[cell] = minf(8.0,values[cell]+1.0)
	steps += 1
