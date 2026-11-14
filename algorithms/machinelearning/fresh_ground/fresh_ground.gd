extends Node3D
## FRESH GROUND (floor ML_Evolution; the pass, 2026-11-14)
##
## The hall's first work is a small black plane on which bodies gain energy by visiting new cells, lose it with
## time, and divide when they have enough: no judge, and still something selects. Its tutorial table asks the same
## with twelve bodies on an eight-by-eight field, once with ground that pays once and once with ground that returns.
## This is that table at the size of a body, and the visitor is one of the bodies.
##
## A floor of sixty-four timber panels, a metre each. Twelve bodies - trace balls, a colour a family, as big as
## their energy - wait on it. The clock starts when the visitor steps onto the field. A panel under a body pays that
## body and is gone: bare floor. The visitor is paid by the same panels, drained by the same clock, and over the
## threshold the visitor too divides: a pink ball rolls away with half the energy. On finite ground the floor is
## eaten in about eight seconds and the last body stops near twenty-five (bench: tools/probes/fresh_ground_bench.py,
## forty seeds); the visitor's own energy runs out with theirs - the disc under the feet goes dark, and the person
## is still standing there. Every panel the visitor takes is one another body did not get.
##
## The rule is the tutorial's own (doc/book/studies/ml-environment/population.gd): its reset(), step(),
## available(), make_body() and constants. The visitor is a body in the model's own list - the thirteenth, after
## the twelve founders, so in a contested cell the founders are served first and the visitor before any child - and
## the only thing the floor does is put that body where the visitor stands before each step. The model's step()
## pays it, drains it, divides it and takes it away. A metre is a cell: the model's field of -1..1 is 8 x 8 m, its
## speeds of 0.1-0.4 are 0.4-1.6 m/s. (A first version gave the visitor a turn of its own after everyone else: on
## returning ground a visitor standing still then starved in a full field, an artefact of being last in line.)
##
## `ground` is the axis: finite = a panel pays once; returns = a panel comes back after four seconds, and the field
## carries thirty-two bodies for as long as anyone watches; barren = nothing is laid: twelve bodies and a visitor
## with what they came with, ten seconds. Two plates south of the field begin again, on finite ground or on ground
## that returns, with the next seed. After a finite run the field stays bare until someone begins again: that
## absence belongs to the process too.
##
## Built from the tower's prefabs through prefab_city.gd: timber panels let into the floor, trace balls, traffic
## pyramids at the corners. Forty seconds with nobody near and the field is again what its row says.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const Population := preload("res://doc/book/studies/ml-environment/population.gd")
const SIDE := 8
const HALF := 4.0
const PROUD := 0.014
const DWELL := 0.8
const EMPTY_SECONDS := 40.0
const MY_FAMILY := 12
const MY_SPEED := 0.3
const BARE := Color("161c28")
const PINK := Color("ff5fa8")

@export_enum("finite", "returns", "barren") var ground := "finite"
## Seconds of the model run at build, with nobody on the field (for a still: the field after twelve seconds).
@export var prerun := 0.0
@export var world_seed := 17

var _city = City.new()
var _world = Population.new()
var _given := "finite"
var _seed := 17
var _panels: Array[Node3D] = []
var _balls: Array[Node3D] = []
var _ball_family: Array[int] = []
var _paints := {}
var _disc: MeshInstance3D
var _disc_paint: StandardMaterial3D
var _plates: Array = []                 # {"at": Vector3, "ground": String, "time": float, "held": bool}
var _board: Label3D
var _body: CharacterBody3D
var _running := false
var _over := false
var _acc := 0.0
var _me := {"energy": 1.5, "alive": true, "children": 0, "meals": 0, "stopped_at": -1.0}
var _mine: Dictionary = {}              # the visitor's body in the model's list
var _on_field := false
var _bare_at := -1.0
var _ended_at := -1.0
var _runs := 0
var _touched := false
var _away := 0.0
var _told := 0.0
var _restored := 0
var _build_ms := 0


func _ready() -> void:
	for key in ["ground", "prerun", "world_seed"]:
		if has_meta("config_" + key): _take({key: get_meta("config_" + key)})
	_given = ground
	_seed = world_seed
	var began := Time.get_ticks_msec()
	_build_once()
	set_ground(ground)
	_build_ms = Time.get_ticks_msec() - began


func _take(config_data: Dictionary) -> void:
	if config_data.has("ground") and str(config_data["ground"]) in ["finite", "returns", "barren"]: ground = str(config_data["ground"])
	if config_data.has("prerun"): prerun = clampf(float(str(config_data["prerun"])), 0.0, 120.0)
	if config_data.has("world_seed"): world_seed = int(float(str(config_data["world_seed"])))


func apply_grid_config(config_data: Dictionary) -> void:
	var before := [ground, prerun, world_seed]
	_take(config_data)
	_given = ground
	_seed = world_seed
	if is_inside_tree() and not _panels.is_empty() and before != [ground, prerun, world_seed]: set_ground(ground)


## ---- the field: the tutorial's own model ----

func set_ground(which: String) -> void:
	ground = which
	_world.reset(_seed, which == "returns")
	if which == "barren": _world.ready_at.fill(INF)
	for i in int(prerun / Population.DT): _world.step()
	_running = false
	_over = false
	_acc = 0.0
	_me = {"energy": 1.5, "alive": true, "children": 0, "meals": 0, "stopped_at": -1.0}
	_mine = {}
	_bare_at = -1.0
	_ended_at = -1.0
	_touched = false
	_away = 0.0
	_redraw()
	_tell()


func clock() -> float:
	return float(_world.ticks) * Population.DT


func fresh() -> int:
	var count := 0
	for i in SIDE * SIDE:
		if _world.available(i): count += 1
	return count


## One step of the model with the visitor's body put where the visitor stands (while on the field; off it, the body
## stays where the visitor left). What the step did to that body is read back, not decided here.
func _step_with_me(p: Vector3) -> void:
	var before := 0.0
	if bool(_me["alive"]):
		if _on_field: _mine["p"] = Vector2(clampf(p.x / HALF, -0.999, 0.999), clampf(p.z / HALF, -0.999, 0.999))
		before = float(_mine["energy"])
	_world.step()
	if not bool(_me["alive"]): return
	if not (_world.bodies as Array).has(_mine):
		_me["alive"] = false
		_me["energy"] = 0.0
		_me["stopped_at"] = clock()
		return
	var after: float = float(_mine["energy"])
	var unpaid: float = before - Population.DRAIN * Population.DT
	if after < unpaid * 0.75:
		# it divided: half went to a child; it was paid as well if what is left is more than half of the unpaid
		_me["children"] = int(_me["children"]) + 1
		if after > unpaid * 0.5 + 0.2: _me["meals"] = int(_me["meals"]) + 1
	elif after > unpaid + 0.2:
		_me["meals"] = int(_me["meals"]) + 1
	_me["energy"] = after


func mine_alive() -> int:
	var count := 0
	for body in _world.bodies:
		if int(body["family"]) == MY_FAMILY and not is_same(body, _mine): count += 1
	return count


func _physics_process(delta: float) -> void:
	var here := _body != null and is_instance_valid(_body)
	var p := Vector3.ZERO
	if here: p = to_local(_body.global_position)
	_on_field = here and absf(p.x) < HALF and absf(p.z) < HALF
	if _on_field and not _running and not _over:
		_running = true
		_runs += 1
		_touched = true
		# the visitor joins the model's list: after the founders, before any child
		_mine = _world.make_body(Vector2(clampf(p.x / HALF, -0.999, 0.999), clampf(p.z / HALF, -0.999, 0.999)), MY_SPEED, 1.5, -1, 0, MY_FAMILY)
		(_world.bodies as Array).append(_mine)
	if _running:
		_acc += minf(delta, 0.1)
		var steps := 0
		while _acc >= Population.DT and steps < 4:
			_acc -= Population.DT
			steps += 1
			_step_with_me(p)
			if _bare_at < 0.0 and fresh() == 0 and not _world.renewal: _bare_at = clock()
			if (_world.bodies as Array).is_empty() and not bool(_me["alive"]):
				_running = false
				_over = true
				_ended_at = clock()
				break
	# the plates: begin again
	for plate in _plates:
		var at: Vector3 = plate["at"]
		var on_plate: bool = here and Vector2(p.x - at.x, p.z - at.z).length() < 0.3
		if on_plate and Vector2(_body.velocity.x, _body.velocity.z).length() < 0.3:
			plate["time"] = float(plate["time"]) + delta
			if float(plate["time"]) >= DWELL and not bool(plate["held"]):
				plate["held"] = true
				begin_again(str(plate["ground"]))
		else:
			plate["time"] = 0.0
			if not on_plate: plate["held"] = false
	_redraw(p, here)


## A new run with the next seed, on the given ground. The clock waits for a step onto the field.
func begin_again(which: String) -> void:
	_seed += 1
	prerun = 0.0
	set_ground(which)
	_touched = true


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
		_seed = world_seed
		set_ground(_given)


func _paint(family: int) -> StandardMaterial3D:
	if not _paints.has(family):
		var colour := PINK if family == MY_FAMILY else Color.from_hsv(float(family) / 12.0 * 0.62 + 0.08, 0.55, 0.95)
		_paints[family] = _city.flat(colour, 0.35)
	return _paints[family]


func _redraw(p: Vector3 = Vector3.ZERO, here: bool = false) -> void:
	for i in _panels.size(): _panels[i].visible = _world.available(i)
	var bodies: Array = _world.bodies
	for k in _balls.size():
		var ball := _balls[k]
		if k >= bodies.size():
			ball.visible = false
			continue
		var body: Dictionary = bodies[k]
		if is_same(body, _mine):
			ball.visible = false          # the visitor's body is the visitor: a disc under the feet
			continue
		ball.visible = true
		var at: Vector2 = body["p"]
		var size: float = clampf(0.55 + 0.25 * float(body["energy"]), 0.5, 1.45)
		ball.position = Vector3(at.x * HALF, 0, at.y * HALF)
		ball.scale = Vector3.ONE * size
		var family: int = int(body["family"])
		if _ball_family[k] != family:
			_ball_family[k] = family
			var paint := _paint(family)
			for mesh in ball.find_children("*", "MeshInstance3D", true, false): (mesh as MeshInstance3D).material_override = paint
	var shown: bool = here and _on_field and (_running or _over)
	_disc.visible = shown
	if shown:
		var alive: bool = _me["alive"]
		_disc.position = Vector3(p.x, 0.02, p.z)
		var wide: float = clampf(0.5 + 0.45 * float(_me["energy"]), 0.5, 2.2) if alive else 0.9
		_disc.scale = Vector3(wide, 1, wide)
		_disc_paint.albedo_color = PINK if alive else Color(0.05, 0.05, 0.06)


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["FRESH GROUND"])
	var rule := "A panel pays the body that reaches it, once." if ground == "finite" else ("A panel pays the body that reaches it and comes back after four seconds." if ground == "returns" else "Nothing is laid: no panel pays.")
	lines.append("No judge ranks these bodies. %s Energy drains with time; with enough of it a body divides. You are one of the bodies: the clock starts when you step on, and the pink disc under you is your energy." % rule)
	var count: int = (_world.bodies as Array).size()
	if _over:
		lines.append("It ended at %.0f s. Born %d, stopped %d. The ground was bare at %s. You took %d panels and had %d children; your energy was gone at %.0f s, and you are still standing." % [
			_ended_at, int(_world.born), int(_world.died), "%.0f s" % _bare_at if _bare_at >= 0.0 else "the start", int(_me["meals"]), int(_me["children"]), float(_me["stopped_at"])])
	elif _running:
		var mine := "your energy %.1f, your children alive %d" % [maxf(0.0, float(_me["energy"])), mine_alive()] if bool(_me["alive"]) else "your energy was gone at %.0f s; your children alive %d" % [float(_me["stopped_at"]), mine_alive()]
		lines.append("%.0f s. Alive %d. Born %d, stopped %d. Fresh panels %d of 64. You: %s." % [clock(), count, int(_world.born), int(_world.died), fresh(), mine])
	else:
		lines.append("Twelve bodies wait. Fresh panels %d of 64. Step onto the field." % fresh())
	lines.append("Begin again on one of the two plates south of the field: ground that pays once, or ground that returns.")
	_board.text = "\n".join(lines)


## ---- building, once ----

func _build_once() -> void:
	var ground_node := Node3D.new()
	ground_node.name = "Ground"
	add_child(ground_node)
	_city.sheet(ground_node, Vector3(0, 0.004, 0), Vector2(HALF * 2.0, HALF * 2.0), BARE)
	# the panels: a metre a cell, in the model's own cell order
	for z in SIDE:
		for x in SIDE:
			var panel: Node3D = _city.part(ground_node, "timber_panel_1x1", Vector3(-HALF + float(x) + 0.5, PROUD - 0.045, -HALF + float(z) + 0.5), 0, Vector3.ZERO, false)
			_panels.append(panel)
	# the bodies: trace balls, as many as the model allows
	for k in Population.LIMIT:
		var holder := Node3D.new()
		holder.name = "Body%d" % k
		ground_node.add_child(holder)
		_city.part(holder, "trace_point_ball", Vector3.ZERO, 0, Vector3(0.34, 0.34, 0.34), false)
		_balls.append(holder)
		_ball_family.append(-1)
	# the visitor's disc
	_disc = MeshInstance3D.new()
	var plate := CylinderMesh.new()
	plate.top_radius = 0.5
	plate.bottom_radius = 0.5
	plate.height = 0.012
	_disc.mesh = plate
	_disc_paint = _city.flat(PINK, 0.5)
	_disc_paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_disc_paint.albedo_color.a = 0.75
	_disc.material_override = _disc_paint
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_disc.visible = false
	ground_node.add_child(_disc)
	# the corners, and the two plates south of the field
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]: _city.part(ground_node, "traffic_pyramid_5", Vector3(sx * (HALF + 0.3), 0, sz * (HALF + 0.3)), 0, Vector3(0.45, 0.7, 0.45))
	for spec in [[-2.6, "finite", "BEGIN AGAIN\nground that pays once"], [2.6, "returns", "BEGIN AGAIN\nground that returns"]]:
		var at := Vector3(float(spec[0]), 0, HALF + 0.9)
		_city.sheet(ground_node, at + Vector3(0, 0.006, 0), Vector2(0.62, 0.62), Color("3a3d45"))
		_city.floor_words(ground_node, at + Vector3(0, 0.014, 0.55), str(spec[2]), 28)
		_plates.append({"at": at, "ground": str(spec[1]), "time": 0.0, "held": false})
	# the body: one sensor over the field and the floor round it
	var sensor := Area3D.new()
	sensor.name = "Reach"
	sensor.collision_layer = 0
	sensor.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(HALF * 2.0 + 6.0, 2.4, HALF * 2.0 + 10.0)
	var shape := CollisionShape3D.new()
	shape.shape = room
	shape.position = Vector3(0, 1.2, 2.0)
	sensor.add_child(shape)
	ground_node.add_child(sensor)
	sensor.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _body = b)
	sensor.body_exited.connect(func(b: Node) -> void:
		if b == _body: _body = null)
	_board = _city.board(ground_node, Vector3(HALF + 2.2, 0, HALF - 0.6), 3.3, 1.0)
	(_board.get_parent().get_parent() as Node3D).rotation_degrees.y = -35.0


## ---- for a test ----

func state() -> Dictionary:
	var families := {}
	for body in _world.bodies: families[int(body["family"])] = int(families.get(int(body["family"]), 0)) + 1
	return {"ground": ground, "running": _running, "over": _over, "clock": snappedf(clock(), 0.01), "alive": (_world.bodies as Array).size(), "born": int(_world.born), "died": int(_world.died),
		"fresh": fresh(), "bare_at": snappedf(_bare_at, 0.01), "ended_at": snappedf(_ended_at, 0.01), "me": _me.duplicate(), "mine_alive": mine_alive(), "families": families,
		"on_field": _on_field, "runs": _runs, "restored": _restored, "seed": _seed, "prefab_parts": int(_city.parts), "build_ms": _build_ms}


func cell_point(x: int, z: int) -> Vector3:
	return to_global(Vector3(-HALF + float(x) + 0.5, 0, -HALF + float(z) + 0.5))


func plate_point(which: String) -> Vector3:
	for plate in _plates:
		if str(plate["ground"]) == which: return to_global(plate["at"])
	return global_position


func point_at(local: Vector3) -> Vector3:
	return to_global(local)
