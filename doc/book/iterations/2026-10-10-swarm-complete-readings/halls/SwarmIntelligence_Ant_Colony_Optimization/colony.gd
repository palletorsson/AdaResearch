extends RefCounted
const WIDTH := 16
const COUNT := 24
const DT := 0.05
const SPEED := 3.0
const RESPONSE := 0.5
const MAX_ACCEL := 6.0
const TURN := PI/4.0
const SENSOR_DISTANCE := 1.5
const HOME := Vector2(3,8)
const FOOD := Vector2(12,8)
const CONTACT := 1.0
var retention := 0.995
var deposit_amount := 0.5
var home := PackedFloat32Array()
var food := PackedFloat32Array()
var positions: Array[Vector2] = []
var velocities: Array[Vector2] = []
var carrying: Array[bool] = []
var energy: Array[float] = []
var delivered := 0
var steps := 0

func _init() -> void:
	reset()

func replace_agents() -> void:
	positions.clear()
	velocities.clear()
	carrying.clear()
	energy.clear()
	for i in range(COUNT):
		var direction := Vector2.from_angle(TAU*i/COUNT)
		positions.append(HOME+direction*0.5)
		velocities.append(direction*SPEED)
		carrying.append(false)
		energy.append(1.0)

func reset() -> void:
	home.resize(WIDTH*WIDTH)
	food.resize(WIDTH*WIDTH)
	home.fill(0.0)
	food.fill(0.0)
	delivered = 0
	steps = 0
	replace_agents()

func wrap_position(p: Vector2) -> Vector2:
	return Vector2(fposmod(p.x,WIDTH),fposmod(p.y,WIDTH))

func index_at(p: Vector2) -> int:
	var cell := Vector2i(wrap_position(p).floor())
	return cell.x+cell.y*WIDTH

func heading(i: int) -> Vector2:
	if not velocities[i].is_zero_approx(): return velocities[i].normalized()
	return Vector2.LEFT if carrying[i] else Vector2.RIGHT

func sensor_position(i: int, offset: float) -> Vector2:
	return wrap_position(positions[i]+heading(i).rotated(offset)*SENSOR_DISTANCE)

func sense(i: int, offset: float, read_home: bool) -> float:
	var cell := index_at(sensor_position(i,offset))
	return home[cell] if read_home else food[cell]

func desired_velocity(i: int) -> Vector2:
	var direction := heading(i)
	var left := sense(i,TURN,carrying[i])
	var ahead := sense(i,0.0,carrying[i])
	var right := sense(i,-TURN,carrying[i])
	if left > ahead and left > right:
		direction = direction.rotated(TURN)
	elif right > ahead and right > left:
		direction = direction.rotated(-TURN)
	return direction*SPEED

func deposit(i: int) -> void:
	var cell := index_at(positions[i])
	var amount := deposit_amount*energy[i]
	if carrying[i]:
		food[cell] = minf(8.0,food[cell]+amount)
	else:
		home[cell] = minf(8.0,home[cell]+amount)

func step() -> void:
	var next_positions: Array[Vector2] = []
	var next_velocities: Array[Vector2] = []
	for i in range(positions.size()):
		if carrying[i] and positions[i].distance_to(HOME) < CONTACT:
			carrying[i] = false
			delivered += 1
			velocities[i] = -velocities[i]
			energy[i] = 1.0
		elif not carrying[i] and positions[i].distance_to(FOOD) < CONTACT:
			carrying[i] = true
			velocities[i] = -velocities[i]
			energy[i] = 1.0
		energy[i] = maxf(0.0,energy[i]-DT*0.05)
		var a := ((desired_velocity(i)-velocities[i])/RESPONSE).limit_length(MAX_ACCEL)
		var v := (velocities[i]+a*DT).limit_length(SPEED)
		next_velocities.append(v)
		next_positions.append(wrap_position(positions[i]+v*DT))
	positions = next_positions
	velocities = next_velocities
	for cell in range(home.size()):
		home[cell] *= retention
		food[cell] *= retention
	for i in range(positions.size()):
		deposit(i)
	home[index_at(HOME)] = 8.0
	food[index_at(FOOD)] = 8.0
	steps += 1
