extends Node3D
## THE CHECKING STATION (floor Godel_Incompleteness; the pass, 2026-11-15)
##
## A visual argument in the form of a ROBOT STATION, for plates 2 and 3 of the hall's cardboard
## (commons/data/arguments/Godel_Incompleteness.json): three ways a search stops, and finding is not checking.
##
## A robot brings candidates to a gate. Each candidate is a derivation in the hall's own toy syntax (axiom 0, rule
## w -> Sw), one step longer than the last. The gate checks it against what was asked with the bench's own checker
## (doc/book/studies/foundations-lineage/derivation.gd: verify) and passes it through or has it pushed aside; every
## fourth candidate has lost a middle line, as the bench's damaged candidate has. The station counts what it
## checked. It never says "none will pass", because it cannot: refusing one more is checking, and "none ever" is a
## sentence about all of them.
##
## `asks` is the axis, and the three values are the hall's three ways a search stops:
##   SSS0       - the fourth candidate passes: it was only a matter of steps;
##   SSSSSSSS0  - eight refusals first, then the ninth passes: SLOW, and nothing in the refusals told you so;
##   0S         - nothing the rule makes ends in an S: IMPOSSIBLE, and the station looks exactly as it does while it
##                is being slow. The reason is on the board, not at the gate: it is an argument, not a check.
## Three plates ask for one of the three. The bench's model will not count past a budget of thirty-two; there the
## row stops and says so.
##
## Built from the tower's prefabs through prefab_city.gd: crates for the candidates, a gate of crates and a timber
## panel as in the harbour, a robot of a construction cube on trace balls with a plank for a pusher. Its motion is
## kinematic (it is moved, nothing is simulated). `pace` only speeds the clock.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const Derivation := preload("res://doc/book/studies/foundations-lineage/derivation.gd")
const TARGETS := ["SSS0", "SSSSSSSS0", "0S"]
const ROW_X := [-1.35, -2.2, -3.05]
const GATE_X := 0.0
const DWELL := 0.8
const LINE_NOTE := "res://commons/font/handwriting/PatrickHand.ttf"

@export_enum("SSS0", "SSSSSSSS0", "0S") var asks := "SSSSSSSS0"
@export var pace := 1.0

var _city = City.new()
var _model = Derivation.new()
var _row: Array[Node3D] = []            # the waiting candidates, nearest the gate first
var _row_tags: Array[Label3D] = []
var _carried: Node3D
var _carried_tag: Label3D
var _robot: Node3D
var _hinge: Node3D
var _gate_shape: CollisionShape3D
var _screen: Label3D
var _board: Label3D
var _passed_shelf: Array[Node3D] = []
var _refused_pile: Array[Node3D] = []
var _plates: Array = []
var _body: CharacterBody3D
var _n := 0                             # candidates brought so far
var _checked := 0
var _passed := 0
var _short := 0
var _broken := 0
var _first_pass := -1
var _phase := "fetch"
var _t := 0.0
var _proof: Array = []
var _accepted := false
var _why := ""
var _stopped := false
var _build_ms := 0


func _ready() -> void:
	for key in ["asks", "pace"]:
		if has_meta("config_" + key): _take({key: get_meta("config_" + key)})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	ask(asks)


func _take(config_data: Dictionary) -> void:
	if config_data.has("asks") and str(config_data["asks"]) in TARGETS: asks = str(config_data["asks"])
	if config_data.has("pace"): pace = clampf(float(str(config_data["pace"])), 0.1, 40.0)


func apply_grid_config(config_data: Dictionary) -> void:
	var before := asks
	_take(config_data)
	if is_inside_tree() and _board != null and asks != before: ask(asks)


## ---- the candidates and the check: the bench's own model ----

## The n-th candidate: the derivation n steps long (0, S0, ... n times S and a 0); every fourth has lost a middle line.
func candidate(n: int) -> Array:
	var found: Dictionary = _model.search("S".repeat(n) + "0", n)
	var proof: Array = (found.get("proof", []) as Array).duplicate()
	if n % 4 == 2 and proof.size() >= 3: proof.remove_at(proof.size() / 2)
	return proof


## The gate's verdict, by the bench's checker, and in words why a refused one was refused.
func check(proof: Array, target: String) -> Dictionary:
	var ok: bool = _model.verify(proof, target)
	var why := "ends in what was asked"
	if not ok:
		var link := true
		for i in range(1, proof.size()):
			if str(proof[i]) != "S" + str(proof[i - 1]): link = false
		why = "a line does not follow from the line before" if not link else "ends in %s, not in %s" % [str(proof[-1]) if not proof.is_empty() else "nothing", target]
	return {"accepted": ok, "why": why, "broken": why.begins_with("a line")}


func ask(target: String) -> void:
	asks = target
	_n = 0
	_checked = 0
	_passed = 0
	_short = 0
	_broken = 0
	_first_pass = -1
	_phase = "fetch"
	_t = 0.0
	_stopped = false
	for crate in _passed_shelf + _refused_pile: crate.visible = false
	_carried.visible = false
	_robot.position = Vector3(-0.75, 0, 0)
	_hinge.rotation.y = 0.0
	_gate_shape.disabled = false
	_screen.text = "asked for\n%s" % asks
	_fill_row()
	_tell()


func _lines(proof: Array) -> String:
	var shown: Array = proof if proof.size() <= 5 else [proof[0], proof[1], "...", proof[-2], proof[-1]]
	return "\n".join(PackedStringArray(shown))


func _fill_row() -> void:
	for k in ROW_X.size():
		var n := _n + k + (1 if _phase != "fetch" else 0)
		var shows: bool = n <= 32
		_row[k].visible = shows
		if shows: _row_tags[k].text = "%d step%s" % [n, "" if n == 1 else "s"]


## ---- the clock: kinematic, in five beats a candidate ----

func _process(delta: float) -> void:
	_watch_plates(delta)
	if _stopped: return
	_t += delta * pace
	match _phase:
		"fetch":
			_robot.position.x = lerpf(-0.75, ROW_X[0] + 0.55, minf(1.0, _t / 0.9))
			if _t >= 0.9:
				if _n > 32:
					_stopped = true
					_screen.text = "the bench counts to 32.\nthe question does not stop there."
					_tell()
					return
				_proof = candidate(_n)
				_carried_tag.text = _lines(_proof)
				_carried.visible = true
				_carried.position = Vector3(ROW_X[0], 0, 0)
				_row[0].visible = false
				_next("carry")
		"carry":
			var u := minf(1.0, _t / 1.0)
			_carried.position.x = lerpf(ROW_X[0], GATE_X - 0.62, u)
			_robot.position.x = _carried.position.x - 0.55
			if u >= 1.0:
				_fill_row()
				_next("check")
		"check":
			var per := 0.28
			var shown: int = mini(_proof.size(), int(_t / per) + 1)
			var text := PackedStringArray()
			for i in shown:
				var follows: bool = i == 0 and str(_proof[0]) == "0" or i > 0 and str(_proof[i]) == "S" + str(_proof[i - 1])
				if _proof.size() > 7 and i > 2 and i < _proof.size() - 3:
					if i == 3: text.append("  ...")
					continue
				text.append("%s  %s" % ["ok" if follows else "NO", str(_proof[i])])
			_screen.text = "asked for %s\n%s" % [asks, "\n".join(text)]
			if _t >= per * float(_proof.size()) + 0.5:
				var verdict := check(_proof, asks)
				_accepted = bool(verdict["accepted"])
				_why = str(verdict["why"])
				_checked += 1
				if _accepted:
					_passed += 1
					if _first_pass < 0: _first_pass = _n + 1
				elif bool(verdict["broken"]): _broken += 1
				else: _short += 1
				_screen.text = "asked for %s\n%s\n%s" % [asks, "PASSED" if _accepted else "REFUSED", _why]
				_gate_shape.disabled = _accepted
				_tell()
				_next("dispose")
		"dispose":
			var u := minf(1.0, _t / 1.1)
			if _accepted:
				_hinge.rotation.y = lerpf(0.0, PI * 0.5, minf(1.0, u * 2.0))
				_carried.position = Vector3(lerpf(GATE_X - 0.62, 1.5, u), 0, 0)
				_robot.position.x = minf(_carried.position.x - 0.55, GATE_X - 0.5)
			else:
				_carried.position = Vector3(GATE_X - 0.62, 0, lerpf(0.0, 1.25, u))
				_robot.position.x = GATE_X - 1.17
			if u >= 1.0:
				_carried.visible = false
				_shelve(_passed_shelf if _accepted else _refused_pile, _passed if _accepted else _checked - _passed)
				_hinge.rotation.y = 0.0
				_gate_shape.disabled = false
				_n += 1
				_next("fetch")


func _next(phase: String) -> void:
	_phase = phase
	_t = 0.0


func _shelve(places: Array[Node3D], count: int) -> void:
	for k in places.size(): places[k].visible = k < count


func _watch_plates(delta: float) -> void:
	var here := _body != null and is_instance_valid(_body)
	var p := Vector3.ZERO
	if here: p = to_local(_body.global_position)
	for plate in _plates:
		var at: Vector3 = plate["at"]
		var on_plate: bool = here and Vector2(p.x - at.x, p.z - at.z).length() < 0.32
		if on_plate and Vector2(_body.velocity.x, _body.velocity.z).length() < 0.3:
			plate["time"] = float(plate["time"]) + delta
			if float(plate["time"]) >= DWELL and not bool(plate["held"]):
				plate["held"] = true
				ask(str(plate["asks"]))
		else:
			plate["time"] = 0.0
			if not on_plate: plate["held"] = false


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["THE CHECKING STATION"])
	lines.append("The robot brings candidates, each one step longer than the last (every fourth has lost a line). The gate checks each against what was asked, by the bench's own rule, and passes it or has it pushed aside.")
	lines.append("Asked for: %s.  Checked %d: refused %d (%d stop short or go past, %d broken), passed %d." % [asks, _checked, _checked - _passed, _short, _broken, _passed])
	if _passed > 0:
		lines.append("The %s candidate passed. %s" % [_ordinal(_first_pass), "Nothing in the refusals before it told you it would: it was slow, not impossible." if _first_pass > 4 else "It was only a matter of steps."])
	elif _stopped:
		lines.append("The row has stopped at the bench's limit of thirty-two steps. Nothing passed. Is that because nothing can? The gate cannot say.")
	else:
		lines.append("The station has not said 'none will pass', and it never will: refusing one more is checking. 'None ever' is a sentence about ALL candidates.")
	if asks == "0S":
		lines.append("(The reason nothing passes here is not at the gate. It is an argument: every line the rule makes is some S's and then a 0. '0S' is not such a line. That took thinking about the rule, not one more check.)")
	lines.append("Stand on a plate to ask for something else. Before you do: will one pass? Say it first.")
	_board.text = "\n".join(lines)


func _ordinal(n: int) -> String:
	var words := ["", "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth"]
	return words[n] if n > 0 and n < words.size() else "%dth" % n


## ---- building, once ----

func _candidate_crate(parent: Node3D, at: Vector3) -> Array:
	var holder := Node3D.new()
	holder.position = at
	parent.add_child(holder)
	_city.part(holder, "crate", Vector3.ZERO, 0, Vector3(0.5, 0.5, 0.5), false)
	var tag := Label3D.new()
	tag.font = load(LINE_NOTE)
	tag.font_size = 44
	tag.pixel_size = 0.0018
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color(0.1, 0.08, 0.06)
	tag.outline_size = 12
	tag.outline_modulate = Color("f4f0e6")
	tag.position = Vector3(0, 0.78, 0)
	holder.add_child(tag)
	return [holder, tag]


func _build_once() -> void:
	var ground := Node3D.new()
	ground.name = "Ground"
	add_child(ground)
	_city.sheet(ground, Vector3(-0.6, 0.004, 0), Vector2(6.4, 0.7), Color("3a3d45"))
	# the row: three candidates in sight, and where the floor ends for the rest
	for k in ROW_X.size():
		var made := _candidate_crate(ground, Vector3(ROW_X[k], 0, 0))
		_row.append(made[0])
		_row_tags.append(made[1])
	_city.catalogue_part(ground, "museum_tape_barrier", Vector3(-3.75, 0, 0), 90)
	_city.floor_words(ground, Vector3(-3.1, 0.014, 0.75), "the row goes on.\nthe floor does not.", 28)
	var carried := _candidate_crate(ground, Vector3(ROW_X[0], 0, 0))
	_carried = carried[0]
	_carried_tag = carried[1]
	# the gate: two posts of crates, a timber panel on a hinge across the track, a solid while it is shut
	var solid := StaticBody3D.new()
	ground.add_child(solid)
	for side in [-1.0, 1.0]:
		_city.part(ground, "crate", Vector3(GATE_X, 0, side * 0.62), 0, Vector3(0.3, 1.3, 0.3))
	_hinge = Node3D.new()
	_hinge.position = Vector3(GATE_X, 0, -0.46)
	_hinge.rotation_degrees.y = 0
	ground.add_child(_hinge)
	var leaf: Node3D = _city.part(_hinge, "timber_panel_1x1", Vector3(0, 0.1, 0.46), 90, Vector3(0.92, 1.0, 0.045), false)
	leaf.name = "Leaf"
	_gate_shape = _city.wall(solid, Vector3(GATE_X, 0, 0), Vector3(0.12, 1.3, 0.94))
	_screen = Label3D.new()
	_screen.font = load(LINE_NOTE)
	_screen.font_size = 48
	_screen.pixel_size = 0.0022
	_screen.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_screen.modulate = Color("9fe0a0")
	_screen.outline_size = 14
	_screen.outline_modulate = Color(0.05, 0.06, 0.05)
	_screen.position = Vector3(GATE_X, 2.15, 0)
	ground.add_child(_screen)
	# the robot: a construction cube on four trace balls, a plank for a pusher, a pyramid for its head
	_robot = Node3D.new()
	_robot.name = "Robot"
	ground.add_child(_robot)
	_city.part(_robot, "construction_cube", Vector3(0, 0.12, 0), 0, Vector3(0.42, 0.26, 0.52), false)
	for wx in [-0.17, 0.17]:
		for wz in [-0.24, 0.24]: _city.part(_robot, "trace_point_ball", Vector3(wx, 0, wz), 0, Vector3(0.16, 0.16, 0.16), false)
	_city.part(_robot, "timber_plank_1m", Vector3(0.26, 0.1, 0), 90, Vector3(0.6, 0.2, 0.05), false)
	_city.part(_robot, "traffic_pyramid_5", Vector3(-0.05, 0.38, 0), 0, Vector3(0.2, 0.3, 0.2), false)
	# where the passed and the refused go
	for k in 6:
		_passed_shelf.append(_candidate_crate(ground, Vector3(1.5 + float(k % 3) * 0.56, float(k / 3) * 0.52, -0.95 - 0.0))[0])
		_refused_pile.append(_candidate_crate(ground, Vector3(-0.62 + float(k % 3) * 0.56, float(k / 3) * 0.52, 1.6))[0])
	for crate in _passed_shelf + _refused_pile:
		for label in crate.find_children("*", "Label3D", true, false): label.queue_free()
	_city.floor_words(ground, Vector3(2.05, 0.014, -0.25), "PASSED", 34, Color("9fe0a0"))
	_city.floor_words(ground, Vector3(-0.05, 0.014, 2.25), "REFUSED (the last six)", 30, Color("ff9a9a"))
	# three plates to ask for something else, the body's sensor, the board
	for k in TARGETS.size():
		var at := Vector3(1.3 + float(k) * 0.85, 0, 2.3)
		_city.sheet(ground, at + Vector3(0, 0.006, 0), Vector2(0.62, 0.62), Color("5a5d68"))
		_city.floor_words(ground, at + Vector3(0, 0.014, 0.55), "ask for\n%s" % TARGETS[k], 28)
		_plates.append({"at": at, "asks": TARGETS[k], "time": 0.0, "held": false})
	var sensor := Area3D.new()
	sensor.name = "Reach"
	sensor.collision_layer = 0
	sensor.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(10.0, 2.4, 9.0)
	var shape := CollisionShape3D.new()
	shape.shape = room
	shape.position = Vector3(0, 1.2, 1.0)
	sensor.add_child(shape)
	ground.add_child(sensor)
	sensor.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _body = b)
	sensor.body_exited.connect(func(b: Node) -> void:
		if b == _body: _body = null)
	_board = _city.board(ground, Vector3(4.6, 0, 1.0), 3.2, 1.35)
	(_board.get_parent().get_parent() as Node3D).rotation_degrees.y = -45.0


## ---- for a test ----

func state() -> Dictionary:
	return {"asks": asks, "brought": _n, "checked": _checked, "passed": _passed, "short": _short, "broken": _broken, "first_pass": _first_pass, "phase": _phase, "stopped": _stopped,
		"said_none_will_pass": false, "prefab_parts": int(_city.parts), "build_ms": _build_ms}


func plate_point(target: String) -> Vector3:
	for plate in _plates:
		if str(plate["asks"]) == target: return to_global(plate["at"])
	return global_position
