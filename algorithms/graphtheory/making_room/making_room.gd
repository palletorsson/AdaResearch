extends Node3D
## MAKING ROOM (floor GT_Matching; the pass, 2026-11-13)
##
## The hall begins: one person takes the drill, the other waits, there is still a saw on the table. Follow the
## waiting person's line to the drill, then back to the person holding it; from there another line reaches the saw.
## No new tool arrives. Someone changes their arrangement, and both can work.
##
## This is that workshop at the size of a body, and the body is the one who waits. Four makers, four tools. Three
## makers stand at benches - cone figures A, B and C; the fourth chair is the visitor's, and the visitor's task
## needs the DRILL. A line on the floor from a chair to a bench: that maker's task permits that tool. A, B and C
## each took the first tool they were allowed, which for each of them was the bench to their left; so the drill is
## taken and the LATHE at the far end stands unused. Walk your line to the drill and stand still on ASK: the
## question goes down the row - A could use the saw, if B lets go of it; B could use the plane, if C lets go of it;
## C finds the lathe free - and then the moves come back up the row: C steps to the lathe, B to the plane, A to the
## saw, and the drill is free. Step up to it: four are working, and no new tool arrived.
##
## The pairing is the hall's own model (doc/book/studies/graphs-through-the-hands/GT_Matching/matching_model.gd):
## its greedy() makes the first arrangement, its alternating_path() is the question that goes down the row, its
## augment() is the rearrangement. Only the people, the tools and the lines are this workshop's (the model's own
## are two makers and two tools - the same story with one step). Bench: tools/probes/making_room_bench.py.
##
## `arrangement` is the axis: first = the first allowed choices, the visitor waits; revised = after the question
## has been asked, the drill kept free; short = the lathe is not there - four makers and three tools: the question
## goes down the row, C's task permits nothing that is free, and nobody moves. What looked like a shortage in
## `first` was the consequence of an earlier allocation; in `short` it is a shortage.
##
## Built from the tower's prefabs through prefab_city.gd: counter walls for benches and salvaged chairs from the
## wider catalogue, traffic pyramids with trace balls for heads as the makers. Forty seconds with nobody near and
## the workshop is again what its row says.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const Matching := preload("res://doc/book/studies/graphs-through-the-hands/GT_Matching/matching_model.gd")
const PEOPLE := ["A", "B", "C", "YOU"]
const TOOLS := ["DRILL", "SAW", "PLANE", "LATHE"]
## Maker, tool: this maker's task permits this tool. People are 0-3, tools 4-7. The order is the order of choosing.
const LINKS := [[0, 4], [0, 5], [1, 5], [1, 6], [2, 6], [2, 7], [3, 4]]
const YOU := 3
const BENCH_X := [-4.5, -1.5, 1.5, 4.5]
const HOME_X := [-1.5, 1.5, 4.5, -4.5]
const BENCH_Z := -3.6
const MAT_Z := -2.7
const HOME_Z := 2.2
const ASK_AT := Vector3(-4.5, 0, -1.35)
const DWELL := 0.8
const EMPTY_SECONDS := 40.0
const PALE := Color("88aaa9")
const IN_USE := Color("e2ac70")
const GIVEN_UP := Color("ee85ba")
const FREE := Color("5fd08a")
const NOT_YOURS := Color("6f7f96")

@export_enum("first", "revised", "short") var arrangement := "first"

var _city = City.new()
var _model = Matching.new()
var _given := "first"
var _figures: Array[Node3D] = []
var _tags: Array[Label3D] = []
var _lines: Array[MeshInstance3D] = []
var _mats: Array[MeshInstance3D] = []
var _bench_signs: Array[Label3D] = []
var _lathe: Node3D
var _lathe_line: MeshInstance3D
var _ask_tile: MeshInstance3D
var _board: Label3D
var _body: CharacterBody3D
var _still := 0.0
var _held := false
var _steps: Array = []                  # the question and the moves, in time: {"t": float, "do": Callable}
var _clock := 0.0
var _busy := false
var _moves: Array = []                  # {"figure": int, "from": Vector3, "to": Vector3, "t": float}
var _said := {}
var _given_up: Array = []
var _asked: Array = []
var _refused := false
var _asks := 0
var _restored := 0
var _touched := false
var _away := 0.0
var _at_drill := false
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_arrangement"): _take({"arrangement": get_meta("config_arrangement")})
	_given = arrangement
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	set_arrangement(arrangement)


func _take(config_data: Dictionary) -> void:
	if config_data.has("arrangement") and str(config_data["arrangement"]) in ["first", "revised", "short"]: arrangement = str(config_data["arrangement"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := arrangement
	_take(config_data)
	_given = arrangement
	if is_inside_tree() and not _figures.is_empty() and arrangement != before: set_arrangement(arrangement)


## ---- the pairing: the hall's own model, with this workshop's people, tools and lines ----

func set_arrangement(which: String) -> void:
	arrangement = which
	var tools: Array[int] = [4, 5, 6, 7]
	var links := LINKS.duplicate(true)
	if which == "short":
		tools = [4, 5, 6]
		links = links.filter(func(l): return int(l[1]) != 7)
	var people: Array[int] = [0, 1, 2, 3]
	_model.people = people
	_model.tools = tools
	_model.links = links
	_model.greedy()
	if which == "revised": _model.augment()
	_steps.clear()
	_moves.clear()
	_said.clear()
	_given_up.clear()
	_asked.clear()
	_refused = false
	_busy = false
	_touched = false
	_away = 0.0
	_in_tree(_lathe, which != "short")
	_lathe_line.visible = which != "short"
	for p in _figures.size(): _figures[p].position = _place(p)
	_show()


func _in_tree(node: Node3D, wanted: bool) -> void:
	if wanted and node.get_parent() == null: add_child(node)
	elif not wanted and node.get_parent() != null: remove_child(node)


func _exit_tree() -> void:
	if is_instance_valid(_lathe) and _lathe.get_parent() == null: _lathe.free()


func _mate(v: int) -> int:
	return int(_model.mate[v]) if v < (_model.mate as Array).size() else -1


## Where a maker stands: at the bench of the tool it holds, or beside its chair.
func _place(p: int) -> Vector3:
	var tool := _mate(p)
	if tool >= 0: return Vector3(BENCH_X[tool - 4], 0, MAT_Z)
	return Vector3(HOME_X[p] + 0.6, 0, HOME_Z)


func working() -> int:
	var count := 0
	for p in 3:
		if _mate(p) >= 0: count += 1
	if _at_drill and _mate(4) == YOU: count += 1
	return count


## The makers a question from the visitor reaches, in order, and whether it ends at a free tool.
func question() -> Dictionary:
	var path: Array = _model.alternating_path()
	if not path.is_empty():
		var on_the_way := []
		for i in range(2, path.size(), 2): on_the_way.append(int(path[i]))
		return {"path": path, "asked": on_the_way, "ends_free": true}
	# no way: follow the row as far as the question gets
	var asked := []
	var tool := 4
	while true:
		var holder := _mate(tool)
		if holder < 0 or asked.has(holder): break
		asked.append(holder)
		var other := -1
		for l in _model.links:
			if int(l[0]) == holder and int(l[1]) != tool and not asked.has(_mate(int(l[1]))): other = int(l[1])
		if other < 0: break
		tool = other
	return {"path": [], "asked": asked, "ends_free": false}


## The visitor asks for the drill.
func ask() -> bool:
	if _busy or _mate(4) == YOU or _mate(4) < 0: return false
	_asks += 1
	_touched = true
	_busy = true
	_clock = 0.0
	_steps.clear()
	_said.clear()
	_given_up.clear()
	var q := question()
	_asked = q["asked"]
	_refused = not bool(q["ends_free"])
	var t := 0.2
	var path: Array = q["path"]
	for k in _asked.size():
		var p: int = int(_asked[k])
		var words := ""
		if bool(q["ends_free"]):
			var wants: int = int(path[k * 2 + 3])
			words = "the %s is free. I take it." % TOOLS[wants - 4].to_lower() if k == _asked.size() - 1 else "I could use the %s, if %s lets go of it" % [TOOLS[wants - 4].to_lower(), PEOPLE[int(_asked[k + 1])]]
		else:
			var other := _other_tool(p)
			if k == _asked.size() - 1: words = "my task permits nothing that is free. I stay."
			else: words = "I could use the %s, if %s lets go of it" % [TOOLS[other - 4].to_lower(), PEOPLE[int(_asked[k + 1])]]
		_steps.append({"t": t, "do": _say.bind(p, words)})
		t += 1.5
	if bool(q["ends_free"]):
		for k in range(_asked.size() - 1, -1, -1):
			var p: int = int(_asked[k])
			var to_tool: int = int(path[k * 2 + 3])
			_steps.append({"t": t, "do": _step_to.bind(p, to_tool)})
			t += 1.4
		_steps.append({"t": t, "do": _rearranged})
	else:
		for k in range(_asked.size() - 2, -1, -1):
			_steps.append({"t": t, "do": _say.bind(int(_asked[k]), "then I stay")})
			t += 1.0
		_steps.append({"t": t + 1.5, "do": _settled})
	_show()
	return true


func _other_tool(p: int) -> int:
	for l in _model.links:
		if int(l[0]) == p and int(l[1]) != _mate(p): return int(l[1])
	return -1


func _say(p: int, words: String) -> void:
	_said[p] = words
	_show()


func _step_to(p: int, tool: int) -> void:
	_said[p] = "to the %s" % TOOLS[tool - 4].to_lower()
	_moves.append({"figure": p, "from": _figures[p].position, "to": Vector3(BENCH_X[tool - 4], 0, MAT_Z), "t": 0.0})
	_show()


func _rearranged() -> void:
	_model.augment()
	_given_up = (_model.removed as Array).duplicate(true)
	_said.clear()
	_busy = false
	arrangement = "revised"
	for p in _figures.size(): _figures[p].position = _place(p)
	_show()


func _settled() -> void:
	_said.clear()
	_busy = false
	_show()


## ---- the body and the clock ----

func _physics_process(delta: float) -> void:
	var here := _body != null and is_instance_valid(_body)
	var at_drill := false
	if here:
		var p := to_local(_body.global_position)
		at_drill = absf(p.x - BENCH_X[0]) < 0.5 and absf(p.z - MAT_Z) < 0.35 and _mate(4) == YOU
		var on_plate: bool = Vector2(p.x - ASK_AT.x, p.z - ASK_AT.z).length() < 0.3
		var v: Vector3 = _body.velocity
		if on_plate and Vector2(v.x, v.z).length() < 0.3:
			_still += delta
			if _still >= DWELL and not _held:
				_held = true
				ask()
		else:
			_still = 0.0
			if not on_plate: _held = false
	if at_drill != _at_drill:
		_at_drill = at_drill
		if at_drill: _touched = true
		_show()


func _process(delta: float) -> void:
	if _busy:
		_clock += delta
		while not _steps.is_empty() and float(_steps[0]["t"]) <= _clock:
			var step: Dictionary = _steps.pop_front()
			(step["do"] as Callable).call()
	for move in _moves:
		# a maker does not step into a body standing in its way
		var blocked := false
		if _body != null and is_instance_valid(_body):
			var p := to_local(_body.global_position)
			var fig: Vector3 = _figures[int(move["figure"])].position
			blocked = Vector2(p.x - fig.x, p.z - fig.z).length() < 0.85 and (p.x - fig.x) * ((move["to"] as Vector3).x - fig.x) > 0.0
		if not blocked: move["t"] = minf(1.0, float(move["t"]) + delta / 1.2)
		_figures[int(move["figure"])].position = (move["from"] as Vector3).lerp(move["to"], smoothstep(0.0, 1.0, float(move["t"])))
	_moves = _moves.filter(func(m): return float(m["t"]) < 1.0)
	if _body != null and is_instance_valid(_body):
		_away = 0.0
		return
	_away += delta
	if _touched and not _busy and _away >= EMPTY_SECONDS:
		_restored += 1
		set_arrangement(_given)


func _show() -> void:
	if _board == null: return
	for i in LINKS.size():
		var link: Array = LINKS[i]
		var colour := PALE
		if _mate(int(link[0])) == int(link[1]): colour = IN_USE
		for gone in _given_up:
			if int(gone[0]) == int(link[1]) and int(gone[1]) == int(link[0]): colour = GIVEN_UP
			if int(gone[0]) == int(link[0]) and int(gone[1]) == int(link[1]): colour = GIVEN_UP
		_lines[i].material_override = _city.flat(colour, 0.7)
	for t in 4:
		var holder := _mate(t + 4)
		var words := "free"
		var colour := FREE if t == 0 else NOT_YOURS
		if holder >= 0 and holder != YOU:
			words = "maker %s" % PEOPLE[holder]
			colour = IN_USE
		elif holder == YOU:
			words = "you are working" if _at_drill else "free - kept for you"
			colour = IN_USE.lightened(0.25) if _at_drill else FREE
		elif t != 0:
			words = "free - not a tool your task permits"
		_bench_signs[t].text = "%s\n%s" % [TOOLS[t], words]
		_mats[t].material_override = _city.flat(colour)
	for p in _tags.size():
		var tool := _mate(p)
		var line: String = "at the %s" % str(TOOLS[tool - 4]).to_lower() if tool >= 0 else "waiting"
		if _said.has(p): line = "\"%s\"" % str(_said[p])
		_tags[p].text = "%s\n%s" % [PEOPLE[p], line]
		_tags[p].modulate = Color(1.0, 0.86, 0.93) if _said.has(p) else Color(0.95, 0.95, 0.98)
	_ask_tile.material_override = _city.flat(GIVEN_UP if (_mate(4) >= 0 and _mate(4) != YOU and not _busy) else Color("3a3d45"))
	var lines := PackedStringArray(["ROOM FOR TWO"])
	lines.append("Four makers, four tools, one maker a tool. A line on the floor from a chair to a bench: that maker's task permits that tool. Your chair is the one on the left, and your task needs the drill.")
	var tools_here: int = (_model.tools as Array).size()
	if _mate(4) == YOU:
		lines.append("Working: %d of 4%s. No new tool arrived: three makers changed their arrangement, and the pink lines are what they gave up." % [working(), "" if _at_drill else " - four when you step up to the drill"])
	elif _busy:
		lines.append("Working: %d of 4. The question is going down the row." % working())
	elif _refused:
		lines.append("Working: %d of 4. The question went down the row and came back: four makers, %d tools. Whatever is rearranged, someone waits." % [working(), tools_here])
	else:
		lines.append("Working: %d of 4. A, B and C each took the first tool they were allowed.%s" % [working(), " The lathe stands unused." if tools_here == 4 else " There is no lathe today."])
	lines.append("Walk your line to the drill. If it is taken, stand still on ASK.")
	_board.text = "\n".join(lines)


## ---- building, once ----

func _strip(parent: Node3D, a: Vector3, b: Vector3, wide: float, colour: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(wide, 0.008, a.distance_to(b))
	mesh.mesh = box
	mesh.material_override = _city.flat(colour, 0.7)
	mesh.position = (a + b) * 0.5 + Vector3(0, 0.006, 0)
	mesh.rotation.y = atan2(b.x - a.x, b.z - a.z)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	return mesh


func _block(parent: Node3D, size: Vector3, at: Vector3, colour: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _city.flat(colour, 0.5)
	mesh.position = at
	parent.add_child(mesh)


## The tool lying on its counter, in a few blocks (the drill and the saw are the hall model's own, larger).
func _tool(parent: Node3D, kind: int, at: Vector3) -> void:
	var holder := Node3D.new()
	holder.position = at
	parent.add_child(holder)
	var wood := Color("dca95d")
	var steel := Color("cccccc")
	match kind:
		0:
			_block(holder, Vector3(0.16, 0.34, 0.14), Vector3(0, 0.17, 0), wood)
			_block(holder, Vector3(0.56, 0.2, 0.16), Vector3(0, 0.36, 0), wood)
			_block(holder, Vector3(0.26, 0.035, 0.035), Vector3(0.4, 0.36, 0), steel)
		1:
			_block(holder, Vector3(0.7, 0.24, 0.03), Vector3(0.12, 0.12, 0), steel)
			_block(holder, Vector3(0.1, 0.3, 0.1), Vector3(-0.3, 0.15, 0), wood)
		2:
			_block(holder, Vector3(0.6, 0.14, 0.18), Vector3(0, 0.07, 0), wood)
			_block(holder, Vector3(0.1, 0.16, 0.1), Vector3(-0.18, 0.22, 0), wood)
			_block(holder, Vector3(0.2, 0.03, 0.14), Vector3(0.08, 0.16, 0), steel)
		3:
			_block(holder, Vector3(0.9, 0.08, 0.2), Vector3(0, 0.04, 0), steel)
			_block(holder, Vector3(0.14, 0.3, 0.2), Vector3(-0.38, 0.19, 0), steel)
			_block(holder, Vector3(0.1, 0.24, 0.16), Vector3(0.38, 0.16, 0), steel)
			_block(holder, Vector3(0.6, 0.1, 0.1), Vector3(0, 0.22, 0), wood)


func _bench(parent: Node3D, t: int) -> void:
	var x: float = BENCH_X[t]
	_city.catalogue_part(parent, "counter_wall", Vector3(x, 0, BENCH_Z), 0)
	_tool(parent, t, Vector3(x, 1.06, BENCH_Z))
	_mats.append(_city.sheet(parent, Vector3(x, 0.005, MAT_Z), Vector2(1.0, 1.0), NOT_YOURS))
	_bench_signs.append(_city.sign_post(parent, Vector3(x, 2.05, BENCH_Z)))


func _build_once() -> void:
	var ground := Node3D.new()
	ground.name = "Ground"
	add_child(ground)
	_lathe = Node3D.new()
	_lathe.name = "Lathe"
	add_child(_lathe)
	# the benches: a counter wall, the tool on it, a place to stand in front
	for t in 4: _bench(_lathe if t == 3 else ground, t)
	# the chairs and the lines: what each maker's task permits
	for p in 4:
		_city.catalogue_part(ground, "salvage_chair", Vector3(HOME_X[p], 0, HOME_Z), 180)
		_city.floor_words(ground, Vector3(HOME_X[p], 0.012, HOME_Z + 0.75), "YOUR CHAIR\nyour task needs the drill" if p == YOU else "%s's chair" % PEOPLE[p], 30)
	for link in LINKS:
		var line := _strip(ground, Vector3(HOME_X[int(link[0])], 0, HOME_Z - 0.45), Vector3(BENCH_X[int(link[1]) - 4], 0, MAT_Z + 0.62), 0.12, PALE)
		_lines.append(line)
		if int(link[1]) == 7: _lathe_line = line
	# the makers: a traffic pyramid with a trace ball for a head
	for p in 3:
		var figure := Node3D.new()
		figure.name = "Maker%s" % PEOPLE[p]
		ground.add_child(figure)
		_city.part(figure, "traffic_pyramid_5", Vector3.ZERO, 0, Vector3(0.56, 1.05, 0.56))
		_city.part(figure, "trace_point_ball", Vector3(0, 1.03, 0), 0, Vector3(0.3, 0.3, 0.3), false)
		var tag: Label3D = _city.sign_post(figure, Vector3(0, 1.75, 0))
		tag.pixel_size = 0.0026
		_figures.append(figure)
		_tags.append(tag)
	# ASK: where the visitor's line meets the drill's bench
	_ask_tile = _city.sheet(ground, ASK_AT + Vector3(0, 0.009, 0), Vector2(0.62, 0.62), GIVEN_UP)
	_city.floor_words(ground, ASK_AT + Vector3(0, 0.016, 0), "ASK\nstand still", 30, Color(0.1, 0.08, 0.1)).outline_size = 0
	# the body: one sensor over the workshop and the floor round it
	var sensor := Area3D.new()
	sensor.name = "Reach"
	sensor.collision_layer = 0
	sensor.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(16.0, 2.4, 14.0)
	var shape := CollisionShape3D.new()
	shape.shape = room
	shape.position = Vector3(0, 1.2, 0.5)
	sensor.add_child(shape)
	ground.add_child(sensor)
	sensor.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _body = b)
	sensor.body_exited.connect(func(b: Node) -> void:
		if b == _body: _body = null)
	# the board: south of the chairs, turned to the arrival
	_board = _city.board(ground, Vector3(0.6, 0, HOME_Z + 1.7), 3.3, 1.0)


## ---- for a test ----

func state() -> Dictionary:
	var pairs := []
	for p in 4:
		if _mate(p) >= 0: pairs.append("%s-%s" % [PEOPLE[p], TOOLS[_mate(p) - 4].to_lower()])
	var asked := []
	for p in _asked: asked.append(PEOPLE[int(p)])
	var stand := []
	for f in _figures: stand.append([snappedf(f.position.x, 0.01), snappedf(f.position.z, 0.01)])
	return {"arrangement": arrangement, "pairs": pairs, "working": working(), "tools": (_model.tools as Array).size(), "path": _model.alternating_path() if _mate(YOU) < 0 else [],
		"asked": asked, "refused": _refused, "busy": _busy, "at_drill": _at_drill, "asks": _asks, "restored": _restored, "figures": stand,
		"prefab_parts": int(_city.parts), "build_ms": _build_ms}


func ask_point() -> Vector3:
	return to_global(ASK_AT)


func drill_mat() -> Vector3:
	return to_global(Vector3(BENCH_X[0], 0, MAT_Z))


func your_chair() -> Vector3:
	return to_global(Vector3(HOME_X[YOU], 0, HOME_Z - 0.7))
