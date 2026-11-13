extends Node3D
## THE CARRIED POINT (floor GT_Layout; the pass, 2026-11-13)
##
## The hall says: a connection is not a coordinate. In its small study a hand pulls the black point out of place,
## its neighbours follow, the shape answers; let go, and the arrangement continues without you. This is that study
## on the floor, twelve metres by eleven, and the black point is the body.
##
## Eight points lie on the floor - trace balls, seven tinted blue and one left black - joined by cords that lie
## flat between them. A cord pulls its two ends together; every point pushes every other away; the cones mark the
## bounds someone chose. Walk to the black point and it becomes you: a black disc under your feet, and wherever you
## go the points you have a cord to follow, and the others make room. A point without a cord to you can come near;
## nearness is not a connection, and the board says how near it is. Walk out past the cones and the drawing goes on
## without you.
##
## The rule is the tutorial's own (doc/book/studies/graphs-through-the-hands/GT_Layout/layout.gd): its forces() and
## its step(), with vertex 0 pinned to the body exactly as the study pins it to the hand. What the floor gives it is
## metres (spring 3, rest 2.2 m, repulsion 5, damping 3 - bench: tools/probes/carried_point_bench.py) and bounds.
## The connections are the hall artifact's own lists (ForceDirectedLayout.connections_for).
##
## `graph` is the axis, in the hall artifact's words: cube = its twelve connections, every point three cords;
## ring = one cycle, two follow you; star = the black point is the hub, and all seven follow.
##
## Built from the tower's prefabs through prefab_city.gd: trace balls for the points, traffic pyramids for the
## bounds. The cords are marks on the floor: they stretch, which no plank does. Forty seconds with nobody near and
## the drawing is again what its row says.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const Layout := preload("res://doc/book/studies/graphs-through-the-hands/GT_Layout/layout.gd")
const HALF_X := 6.0
const HALF_Z := 5.4
const INSET := 0.4
const TAKE := 0.6
const BALL := 0.45
const COUNT := 8
const EMPTY_SECONDS := 40.0
const CORD := Color("6c8fc4")
const YOURS := Color("e2ac70")
const KEPT := Color("ee85ba")
const BLUE := Color("3f6fd0")
## Where the eight points lie at rest, for each graph: printed by the bench (tools/probes/carried_point_bench.py), so
## that a floor is not built on a minute of settling. The drawing starts here and is stepped four seconds more.
const AT_REST := {
	"cube": [Vector2(0.46, 3.48), Vector2(1.41, 0.82), Vector2(-0.08, -1.22), Vector2(0.16, 1.35), Vector2(-1.33, 1.37), Vector2(-1.55, -0.96), Vector2(-0.19, -3.36), Vector2(1.24, -0.93)],
	"ring": [Vector2(3.43, 0.68), Vector2(1.96, 2.94), Vector2(-0.68, 3.49), Vector2(-2.93, 2.02), Vector2(-3.48, -0.62), Vector2(-2.01, -2.87), Vector2(0.63, -3.43), Vector2(2.88, -1.95)],
	"star": [Vector2(0.59, 0.24), Vector2(2.90, 1.95), Vector2(0.70, 3.11), Vector2(-1.58, 2.11), Vector2(-2.23, -0.30), Vector2(-0.74, -2.30), Vector2(1.74, -2.39), Vector2(3.37, -0.50)],
}

@export_enum("cube", "ring", "star") var graph := "cube"

var _city = City.new()
var _drawing = Layout.new()
var _given := "cube"
var _pairs: Array = []
var _neighbours: Array = []
var _holders: Array[Node3D] = []
var _balls: Array[Node3D] = []
var _numbers: Array[Label3D] = []
var _disc: MeshInstance3D
var _cords: Array[MeshInstance3D] = []
var _cord_kind: Array[int] = []
var _paints: Array[StandardMaterial3D] = []
var _kept := 0
var _board: Label3D
var _body: CharacterBody3D
var _carried := false
var _takes := 0
var _lets_go := 0
var _closest_stranger := 99.0
var _longest_own := 0.0
var _touched := false
var _away := 0.0
var _told := 0.0
var _restored := 0
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_graph"): _take({"graph": get_meta("config_graph")})
	_given = graph
	var began := Time.get_ticks_msec()
	_build_once()
	set_graph(graph)
	_build_ms = Time.get_ticks_msec() - began


func _take(config_data: Dictionary) -> void:
	if config_data.has("graph") and str(config_data["graph"]) in ["cube", "ring", "star"]: graph = str(config_data["graph"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := graph
	_take(config_data)
	_given = graph
	if is_inside_tree() and not _holders.is_empty() and graph != before: set_graph(graph)


## ---- the drawing: the tutorial's own rule, the hall artifact's own connections ----

func set_graph(kind: String) -> void:
	graph = kind
	var hall := ForceDirectedLayout.new()
	_pairs = hall.connections_for(kind)
	hall.free()
	_neighbours.clear()
	for v in COUNT: _neighbours.append([])
	for pair in _pairs:
		(_neighbours[int(pair[0])] as Array).append(int(pair[1]))
		(_neighbours[int(pair[1])] as Array).append(int(pair[0]))
	var places: Array[Vector3] = []
	var rest: Array[Vector3] = []
	for v in COUNT:
		var at: Vector2 = AT_REST[kind][v]
		places.append(Vector3(at.x, 0, at.y))
		rest.append(Vector3.ZERO)
	_drawing.positions = places
	_drawing.velocities = rest
	_drawing.spring = 3.0
	_drawing.rest_length = 2.2
	_drawing.repulsion = 5.0
	_drawing.damping = 3.0
	for i in 240:
		_drawing.step(1.0 / 60.0, _neighbours, -1)
		_bound()
	_kept = _pairs.size() - 1
	for i in _pairs.size():
		if int(_pairs[i][0]) != 0 and int(_pairs[i][1]) != 0:
			_kept = i
			break
	_carried = false
	_touched = false
	_away = 0.0
	_closest_stranger = 99.0
	_longest_own = 0.0
	for v in COUNT: _numbers[v].text = str((_neighbours[v] as Array).size())
	_redraw()
	_tell()


## The floor's bounds: a point stops at them.
func _bound() -> void:
	for v in COUNT:
		var p: Vector3 = _drawing.positions[v]
		var q := Vector3(clampf(p.x, -HALF_X + INSET, HALF_X - INSET), 0, clampf(p.z, -HALF_Z + INSET, HALF_Z - INSET))
		if q != p:
			var vel: Vector3 = _drawing.velocities[v]
			if q.x != p.x: vel.x = 0.0
			if q.z != p.z: vel.z = 0.0
			_drawing.velocities[v] = vel
			_drawing.positions[v] = q


func speed() -> float:
	var most := 0.0
	for v in COUNT: most = maxf(most, (_drawing.velocities[v] as Vector3).length())
	return most


func _physics_process(delta: float) -> void:
	var here := _body != null and is_instance_valid(_body)
	var p := Vector3.ZERO
	if here: p = to_local(_body.global_position)
	var inside: bool = here and absf(p.x) < HALF_X and absf(p.z) < HALF_Z
	var black: Vector3 = _drawing.positions[0]
	if _carried and not inside:
		_carried = false
		_lets_go += 1
	elif not _carried and inside and Vector2(p.x - black.x, p.z - black.z).length() < TAKE:
		_carried = true
		_takes += 1
		_touched = true
		_closest_stranger = 99.0
		_longest_own = 0.0
	var pinned := -1
	if _carried:
		# as the study pins vertex 0 to the hand
		_drawing.positions[0] = Vector3(clampf(p.x, -HALF_X + INSET, HALF_X - INSET), 0, clampf(p.z, -HALF_Z + INSET, HALF_Z - INSET))
		_drawing.velocities[0] = Vector3.ZERO
		pinned = 0
	_drawing.step(minf(delta, 1.0 / 30.0), _neighbours, pinned)
	_bound()
	if _carried:
		for v in range(1, COUNT):
			var far: float = (_drawing.positions[v] as Vector3).distance_to(_drawing.positions[0])
			if (_neighbours[0] as Array).has(v): _longest_own = maxf(_longest_own, far)
			else: _closest_stranger = minf(_closest_stranger, far)
	_redraw()


func _process(delta: float) -> void:
	_told += delta
	if _told >= 0.25:
		_told = 0.0
		_tell()
	if _body != null and is_instance_valid(_body):
		_away = 0.0
		return
	_away += delta
	if _touched and _away >= EMPTY_SECONDS:
		_restored += 1
		set_graph(_given)


func _redraw() -> void:
	for v in COUNT: _holders[v].position = _drawing.positions[v]
	_balls[0].visible = not _carried
	_disc.visible = _carried
	for i in _cords.size():
		var cord := _cords[i]
		if i >= _pairs.size():
			cord.visible = false
			continue
		cord.visible = true
		var a: Vector3 = _drawing.positions[int(_pairs[i][0])]
		var b: Vector3 = _drawing.positions[int(_pairs[i][1])]
		cord.position = (a + b) * 0.5 + Vector3(0, 0.012, 0)
		cord.scale = Vector3(1, 1, maxf(0.05, a.distance_to(b)))
		cord.rotation.y = atan2(b.x - a.x, b.z - a.z)
		var kind := 0
		if i == _kept: kind = 2
		elif _carried and (int(_pairs[i][0]) == 0 or int(_pairs[i][1]) == 0): kind = 1
		if kind != _cord_kind[i]:
			_cord_kind[i] = kind
			cord.material_override = _paints[kind]


func _tell() -> void:
	if _board == null: return
	var mine: Array = _neighbours[0]
	var lines := PackedStringArray(["A CONNECTION IS NOT A COORDINATE"])
	lines.append("The hall's blue graph on the floor: eight points, %d cords. A cord pulls its two ends together; every point pushes every other away. The cones are the bounds someone chose. Keep the pink cord's two ends in view while the drawing moves." % _pairs.size())
	if _carried:
		var lengths := PackedStringArray()
		var nearest := 99.0
		for v in range(1, COUNT):
			var far: float = (_drawing.positions[v] as Vector3).distance_to(_drawing.positions[0])
			if mine.has(v): lengths.append("%.1f m" % far)
			else: nearest = minf(nearest, far)
		var stranger := "The nearest point without a cord to you: %.1f m. Nearness is not a connection." % nearest if nearest < 90.0 else "Every other point has a cord to you."
		lines.append("You are the black point. Your %d cords: %s. %s Walk out past the cones and the drawing goes on without you." % [mine.size(), ", ".join(lengths), stranger])
	else:
		lines.append("The black point is free, with %d cords like %s. Walk to it: it becomes you, and wherever you go the same %d follow." % [mine.size(), "every other point" if graph != "star" else "no other point", mine.size()])
	_board.text = "\n".join(lines)


## ---- building, once ----

func _build_once() -> void:
	var ground := Node3D.new()
	ground.name = "Ground"
	add_child(ground)
	for colour in [CORD, YOURS, KEPT]:
		var paint: StandardMaterial3D = _city.flat(colour, 0.7)
		_paints.append(paint)
	# the points: trace balls, one left black; the number over each is how many cords it has
	for v in COUNT:
		var holder := Node3D.new()
		holder.name = "Point%d" % v
		ground.add_child(holder)
		var ball: Node3D = _city.part(holder, "trace_point_ball", Vector3.ZERO, 0, Vector3(BALL, BALL, BALL), false)
		if v > 0:
			var blue: StandardMaterial3D = _city.flat(BLUE, 0.35)
			for mesh in ball.find_children("*", "MeshInstance3D", true, false): (mesh as MeshInstance3D).material_override = blue
		var number: Label3D = _city.sign_post(holder, Vector3(0, BALL + 0.28, 0))
		number.pixel_size = 0.0036
		_holders.append(holder)
		_balls.append(ball)
		_numbers.append(number)
	_disc = MeshInstance3D.new()
	var plate := CylinderMesh.new()
	plate.top_radius = 0.42
	plate.bottom_radius = 0.42
	plate.height = 0.012
	_disc.mesh = plate
	_disc.material_override = _city.flat(Color(0.03, 0.03, 0.04), 0.4)
	_disc.position = Vector3(0, 0.016, 0)
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_disc.visible = false
	_holders[0].add_child(_disc)
	# the cords: twelve at most, lying on the floor
	for i in 12:
		var cord := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.1, 0.008, 1.0)
		cord.mesh = box
		cord.material_override = _paints[0]
		cord.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ground.add_child(cord)
		_cords.append(cord)
		_cord_kind.append(0)
	# the bounds: a line on the floor and traffic pyramids
	for side in [-1.0, 1.0]:
		_city.sheet(ground, Vector3(0, 0.004, side * HALF_Z), Vector2(HALF_X * 2.0, 0.06), Color("9aa0aa"))
		_city.sheet(ground, Vector3(side * HALF_X, 0.004, 0), Vector2(0.06, HALF_Z * 2.0), Color("9aa0aa"))
		for corner in [-1.0, 1.0]: _city.part(ground, "traffic_pyramid_5", Vector3(corner * HALF_X, 0, side * HALF_Z), 0, Vector3(0.45, 0.7, 0.45))
		for x in [-3.0, 3.0]: _city.part(ground, "traffic_pyramid_5", Vector3(x, 0, side * HALF_Z), 0, Vector3(0.45, 0.7, 0.45))
		_city.part(ground, "traffic_pyramid_5", Vector3(side * HALF_X, 0, 0), 0, Vector3(0.45, 0.7, 0.45))
	# the body: one sensor over the floor drawing and the floor round it
	var sensor := Area3D.new()
	sensor.name = "Reach"
	sensor.collision_layer = 0
	sensor.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(HALF_X * 2.0 + 4.0, 2.4, HALF_Z * 2.0 + 8.0)
	var shape := CollisionShape3D.new()
	shape.shape = room
	shape.position = Vector3(0, 1.2, 1.0)
	sensor.add_child(shape)
	ground.add_child(sensor)
	sensor.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _body = b)
	sensor.body_exited.connect(func(b: Node) -> void:
		if b == _body: _body = null)
	# the board: outside the bounds, east of the way in, turned to the arrival
	_board = _city.board(ground, Vector3(2.4, 0, HALF_Z + 1.0), 3.3, 0.95)


## ---- for a test ----

func state() -> Dictionary:
	var places := []
	for v in COUNT: places.append([snappedf((_drawing.positions[v] as Vector3).x, 0.01), snappedf((_drawing.positions[v] as Vector3).z, 0.01)])
	var cords := []
	var lengths := []
	for pair in _pairs:
		cords.append("%d-%d" % [int(pair[0]), int(pair[1])])
		lengths.append(snappedf((_drawing.positions[int(pair[0])] as Vector3).distance_to(_drawing.positions[int(pair[1])]), 0.01))
	var degree := []
	for v in COUNT: degree.append((_neighbours[v] as Array).size())
	return {"graph": graph, "carried": _carried, "places": places, "cords": cords, "lengths": lengths, "degree": degree, "yours": _neighbours[0], "speed": snappedf(speed(), 0.001),
		"closest_stranger": snappedf(_closest_stranger, 0.01), "longest_own": snappedf(_longest_own, 0.01), "takes": _takes, "lets_go": _lets_go, "restored": _restored,
		"black_ball_shown": _balls[0].visible, "prefab_parts": int(_city.parts), "build_ms": _build_ms}


func black_point() -> Vector3:
	return to_global(_drawing.positions[0])


func point_at(local: Vector3) -> Vector3:
	return to_global(local)
