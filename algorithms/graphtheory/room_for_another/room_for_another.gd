extends Node3D
## ROOM FOR ANOTHER (floor GT_Flow; the pass, 2026-11-13)
##
## The hall's harbour model allocates one delivery, finds the second one waiting, and then a pink connection takes
## back part of the first so that both fit. This is that harbour for a body, and the body is the delivery.
##
## The network is the hall's own: the links of commons/artifacts/graph_worlds/flow_model.gd are read, not typed again.
## Five quays lie in a basin ten metres by twelve: DEPOT A and DEPOT B behind the south bank, YARD 3 and YARD 4, the
## DOCK, and beyond it the ship's side, which is the hall floor north of the basin. Every crate slot is a bridge of
## its own, a metre wide (the dock's link to the ship holds two, so it is two gangways): nine bridges.
##
## A bridge is EMPTY or PROMISED. An empty bridge has a timber gate at its far end that swings open for a body coming
## from its near end, and never from the other side: nothing was promised there, so there is nothing to take back.
## Walk it through and a crate is set down on it behind you: the slot is promised, and the crate fills the bridge
## for whoever comes next. A promised bridge can only be entered from its far end, at the pink mark on the floor:
## the crate is taken back, and when you step off at the near end the slot is free again. Each quay lies on a mat,
## green while a crate could still get there - the delivery the body has under way, or another one from the south
## bank when the body is outside - and grey when it could not. So a body always walks
## where a crate could still go, forwards over a free slot or backwards over a promised one, and what the crates show
## when the body is outside is always a plan that adds up (bench: tools/probes/room_for_another_bench.py - thirty
## states a body can produce, none that does not add up, none it cannot leave).
##
## `promised` is the axis and what the floor begins as: none = nothing promised; first = the hall model's first
## allocation stands (depot A through yard 3), so depot B's delivery reaches yard 3 and waits - until the body walks
## the bridge from depot A backwards, and brings A's crate through yard 4 instead; both = the hall model's second
## step: two on the ship's side, every way from the south bank closed by a promised slot, as many slots as arrived.
## The plans are made by the hall model's own step(); the board's way through is its own search().
##
## Built from the tower's prefabs through prefab_city.gd: plank decks let into the floor, gates of the 1 x 1 m timber
## panel, the lab's crate, concrete barriers round the basin, the catalogue's work light and pink triangle sign.
## A crate left under way by a body that vanished, or forty seconds with nobody near, and the harbour is again what
## its row says.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const Flow := preload("res://commons/artifacts/graph_worlds/flow_model.gd")
const HALF_X := 5.0
const HALF_Z := 6.0
const WIDE := 1.0
const REACH := 0.3
const PROUD := 0.014
const EMPTY_SECONDS := 40.0
const NAMES := ["SOUTH BANK", "DEPOT A", "DEPOT B", "YARD 3", "YARD 4", "DOCK", "SHIP'S SIDE"]
## The quays, by the hall model's vertex numbers (0 and 6 are the hall floor south and north of the basin).
const LANDS := {1: Rect2(-5.0, 3.0, 6.0, 2.0), 2: Rect2(2.5, 3.0, 2.5, 2.0), 3: Rect2(-1.0, -1.0, 6.0, 2.0), 4: Rect2(-5.0, -1.0, 2.5, 2.0), 5: Rect2(-5.0, -5.0, 10.0, 2.0)}
## Where the bridges of a link lie across the basin: one x a crate slot. Every bridge runs north, tail to head.
const WAYS := {"0>1": [-2.0], "0>2": [3.75], "1>3": [0.0], "1>4": [-3.75], "2>3": [3.75], "3>5": [2.0], "4>5": [-3.75], "5>6": [-1.0, 1.0]}
const PLANS := {"none": 0, "first": 1, "both": 2}
const OPEN := Color("5fd08a")
const SHUT := Color("8a8f98")
const PINK := Color("ff5fa8")

@export_enum("none", "first", "both") var promised := "first"

var _city = City.new()
var _model = Flow.new()
var _given := "first"
var _slots: Array = []                  # {"a": int, "b": int, "x": float, "south": float, "north": float, "rect": Rect2}
var _full: Array[bool] = []
var _on: Array[bool] = []
var _crates: Array[Node3D] = []
var _hinges: Array[Node3D] = []
var _gate_shapes: Array[CollisionShape3D] = []
var _marks: Array[MeshInstance3D] = []
var _mats := {}
var _signs := {}
var _board: Label3D
var _ship: Label3D
var _body: CharacterBody3D
var _land := -1                         # the quay the body stands on; -1 = outside (south bank and ship's side are one floor)
var _touched := false
var _away := 0.0
var _walked := 0
var _restored := 0
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_promised"): _take({"promised": get_meta("config_promised")})
	_given = promised
	var began := Time.get_ticks_msec()
	_model.reset()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	set_plan(promised)


func _take(config_data: Dictionary) -> void:
	if config_data.has("promised") and PLANS.has(str(config_data["promised"])): promised = str(config_data["promised"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := promised
	_take(config_data)
	_given = promised
	if is_inside_tree() and not _slots.is_empty() and promised != before: set_plan(promised)


## ---- the count: the hall's own model ----

## The harbour as the hall model made it: nothing, its first step, or its second.
func set_plan(which: String) -> void:
	promised = which
	_model.reset()
	for n in int(PLANS.get(which, 0)): _model.step()
	var used := {}
	for i in _slots.size():
		var key := "%d>%d" % [int(_slots[i]["a"]), int(_slots[i]["b"])]
		var taken: int = int(used.get(key, 0))
		_full[i] = taken < int(_model.flow[int(_slots[i]["a"])][int(_slots[i]["b"])])
		if _full[i]: used[key] = taken + 1
		_on[i] = false
	_touched = false
	_away = 0.0
	_apply(true)


## What the crates say, written into the hall model.
func _mirror() -> void:
	for a in Flow.COUNT:
		for b in Flow.COUNT: _model.flow[a][b] = 0
	for i in _slots.size():
		if not _full[i]: continue
		_model.flow[int(_slots[i]["a"])][int(_slots[i]["b"])] += 1
		_model.flow[int(_slots[i]["b"])][int(_slots[i]["a"])] -= 1


## A way a crate could still take from the south bank to the ship's side, as the hall model searches: vertex numbers.
func way() -> Array:
	_mirror()
	return _model.search()


## How many stretches of a way run against a promise.
func against(path: Array) -> int:
	var count := 0
	for i in path.size() - 1:
		if int(_model.capacity[int(path[i])][int(path[i + 1])]) == 0: count += 1
	return count


## The slots that close the harbour: from what a crate can still reach from the south bank to what it cannot.
func closes() -> Array:
	_mirror()
	var reach: Array = [int(Flow.SOURCE)]
	var at := 0
	while at < reach.size():
		var v: int = reach[at]
		at += 1
		for w in Flow.COUNT:
			if not reach.has(w) and int(_model.residual(v, w)) > 0: reach.append(w)
	var out := []
	for i in _slots.size():
		if reach.has(int(_slots[i]["a"])) and not reach.has(int(_slots[i]["b"])): out.append(i)
	return out


func arrived() -> int:
	var count := 0
	for i in _slots.size():
		if _full[i] and int(_slots[i]["b"]) == Flow.SINK: count += 1
	return count


## Promised into a quay minus promised out of it, for every quay where that is not nothing.
func excess() -> Dictionary:
	var e := {}
	for i in _slots.size():
		if not _full[i]: continue
		e[int(_slots[i]["b"])] = int(e.get(int(_slots[i]["b"]), 0)) + 1
		e[int(_slots[i]["a"])] = int(e.get(int(_slots[i]["a"]), 0)) - 1
	var out := {}
	for v in e:
		if int(e[v]) != 0 and v != Flow.SOURCE and v != Flow.SINK: out[v] = int(e[v])
	return out


## Where a crate can still get to - forwards over a free slot, backwards over a promised one - from the quay the body
## stands on (the delivery it has under way), or from the south bank when the body is outside (another delivery).
func can_reach() -> Array:
	var reach: Array = [_land if _land >= 0 else int(Flow.SOURCE)]
	var at := 0
	while at < reach.size():
		var v: int = reach[at]
		at += 1
		for i in _slots.size():
			var to := -1
			if not _full[i] and int(_slots[i]["a"]) == v: to = int(_slots[i]["b"])
			elif _full[i] and int(_slots[i]["b"]) == v: to = int(_slots[i]["a"])
			if to >= 0 and not reach.has(to): reach.append(to)
	return reach


func slot_name(i: int) -> String:
	return "%s > %s" % [str(NAMES[int(_slots[i]["a"])]).to_lower(), str(NAMES[int(_slots[i]["b"])]).to_lower()]


## ---- the body ----

func _physics_process(_delta: float) -> void:
	var here := _body != null and is_instance_valid(_body)
	var p := Vector3.ZERO
	if here: p = to_local(_body.global_position)
	var changed := false
	for i in _slots.size():
		var s: Dictionary = _slots[i]
		var x: float = s["x"]
		var north: float = s["north"]
		var south: float = s["south"]
		var over: bool = here and absf(p.x - x) < WIDE * 0.5 + 0.15 and p.z > north - REACH and p.z < south + REACH and absf(p.y) < 1.5
		if over and not _on[i]:
			# a free bridge opens for a body at its tail, a promised one for a body at its head
			var at_tail: bool = p.z > (north + south) * 0.5
			if at_tail != _full[i]:
				_on[i] = true
				changed = true
		elif not over and _on[i]:
			_on[i] = false
			changed = true
			if here and absf(p.x - x) < WIDE * 0.5 + 0.4:
				var left_at_head: bool = p.z < (north + south) * 0.5
				if left_at_head != _full[i]:
					_full[i] = left_at_head
					_walked += 1
					_touched = true
	var land := _land
	if not here or absf(p.x) > HALF_X or absf(p.z) > HALF_Z:
		land = -1
	else:
		for k in LANDS:
			if (LANDS[k] as Rect2).has_point(Vector2(p.x, p.z)): land = int(k)
	if land != _land:
		_land = land
		changed = true
	if changed: _apply(false)


func _process(delta: float) -> void:
	for i in _hinges.size():
		var want: float = -PI * 0.5 if (_full[i] or _on[i]) else 0.0
		_hinges[i].rotation.y = move_toward(_hinges[i].rotation.y, want, delta * 6.0)
	if _body != null and is_instance_valid(_body):
		_away = 0.0
		return
	_away += delta
	if (_away > 3.0 and not excess().is_empty()) or (_touched and _away >= EMPTY_SECONDS):
		_restored += 1
		set_plan(_given)


func _in_tree(node: Node3D, wanted: bool) -> void:
	if wanted and node.get_parent() == null: add_child(node)
	elif not wanted and node.get_parent() != null: remove_child(node)


func _apply(snap: bool) -> void:
	for i in _slots.size():
		_in_tree(_crates[i], _full[i] and not _on[i])
		_gate_shapes[i].disabled = _full[i] or _on[i]
		_marks[i].visible = _full[i]
		if snap: _hinges[i].rotation.y = -PI * 0.5 if _full[i] else 0.0
	_show()


func _exit_tree() -> void:
	for node in _crates:
		if is_instance_valid(node) and node.get_parent() == null: node.free()


func _show() -> void:
	var reach: Array = can_reach()
	var whose := "your delivery" if _land >= 0 else "another delivery"
	for k in LANDS:
		var ok: bool = reach.has(int(k))
		(_mats[k] as MeshInstance3D).material_override = _city.flat(OPEN if ok else SHUT)
		(_signs[k] as Label3D).text = "%s\n%s" % [NAMES[int(k)], "you are here" if int(k) == _land else ("%s can reach here" % whose if ok else "closed to %s" % whose)]
		(_signs[k] as Label3D).modulate = OPEN.lightened(0.3) if ok else SHUT.lightened(0.4)
	var path: Array = way()
	var under_way: Dictionary = excess()
	if _ship != null:
		_ship.text = "SHIP'S SIDE\narrived: %d" % arrived()
	if _board == null: return
	var lines := PackedStringArray(["ROOM FOR ANOTHER"])
	lines.append("Every bridge holds one crate. Its gate opens one way, toward the ship. A crate standing on a bridge: that slot is promised, and it is full.")
	if not under_way.is_empty():
		var where: int = int(under_way.keys()[0])
		lines.append("On the ship's side: %d. A delivery is under way with you on %s. Carry it through to the ship's side, or take it back out to the bank." % [arrived(), str(NAMES[where]).to_lower()])
	elif path.is_empty():
		var shut: Array = closes()
		var names := PackedStringArray()
		for i in shut: names.append(slot_name(int(i)))
		lines.append("On the ship's side: %d. Nothing more fits: every way from the south bank is closed by a promised slot. What closes it: %s. That is %d slots, as many as arrived. It is never otherwise." % [arrived(), ", ".join(names), shut.size()])
	else:
		var back: int = against(path)
		if back == 0:
			lines.append("On the ship's side: %d. There is room for another: a way is open from the south bank over %d bridges." % [arrived(), path.size() - 1])
		else:
			lines.append("On the ship's side: %d. There is room for another, but not straight through: the way runs over %d bridges, and %d of them against a promise." % [arrived(), path.size() - 1, back])
	lines.append("Walk onto a promised bridge from its far end, at the pink mark: the crate is taken back, and the slot is free again. Walk a delivery through from the south bank; walk round outside for the next.")
	_board.text = "\n".join(lines)


## ---- building, once ----

func _build_once() -> void:
	var ground := Node3D.new()
	ground.name = "Ground"
	add_child(ground)
	# the bridge places, from the hall model's links: one a crate slot
	for link in _model.links:
		var a: int = int(link["a"])
		var b: int = int(link["b"])
		var xs: Array = WAYS.get("%d>%d" % [a, b], [])
		if xs.size() < int(link["cap"]): push_warning("room_for_another: the hall model has a link %d>%d this harbour has no place for" % [a, b])
		for n in mini(int(link["cap"]), xs.size()):
			var south: float = HALF_Z if a == Flow.SOURCE else (LANDS[a] as Rect2).position.y
			var north: float = -HALF_Z if b == Flow.SINK else (LANDS[b] as Rect2).end.y
			var x: float = float(xs[n])
			_slots.append({"a": a, "b": b, "x": x, "south": south, "north": north, "rect": Rect2(x - WIDE * 0.5, north, WIDE, south - north)})
			_full.append(false)
			_on.append(false)
	# water wherever there is no quay and no bridge; a wall and concrete along the basin's west and east
	var dry: Array = []
	for k in LANDS: dry.append(LANDS[k])
	for s in _slots: dry.append(s["rect"])
	var wet: Dictionary = _city.water(ground, Rect2(-HALF_X, -HALF_Z, HALF_X * 2.0, HALF_Z * 2.0), dry)
	var solid: StaticBody3D = wet["solid"]
	for side in [-1.0, 1.0]:
		_city.fence(ground, Vector3(side * HALF_X, 0, -HALF_Z), Vector3(side * HALF_X, 0, HALF_Z), "barrier", 2.0, 0.9, 0.5)
		_city.wall(solid, Vector3(side * (HALF_X + 0.04), 0, 0), Vector3(0.08, 1.3, HALF_Z * 2.0))
	for edge in [HALF_Z, -HALF_Z]:
		var mouths := []
		for s in _slots:
			var r: Rect2 = s["rect"]
			if absf(r.position.y - edge) < 0.001 or absf(r.end.y - edge) < 0.001: mouths.append([r.position.x, r.end.x])
		mouths.sort_custom(func(p, q): return float(p[0]) < float(q[0]))
		var at := -HALF_X
		for mouth in mouths:
			_city.fence(ground, Vector3(at, 0, edge), Vector3(float(mouth[0]), 0, edge), "barrier", 2.0, 0.9, 0.5)
			at = float(mouth[1])
		_city.fence(ground, Vector3(at, 0, edge), Vector3(HALF_X, 0, edge), "barrier", 2.0, 0.9, 0.5)
	# the quays: a mat and a name
	for k in LANDS:
		var land: Rect2 = LANDS[k]
		var middle := Vector3(land.get_center().x, 0, land.get_center().y)
		_mats[k] = _city.sheet(ground, middle + Vector3(0, 0.005, 0), Vector2(land.size.x - 1.0, land.size.y - 0.9), OPEN)
		_signs[k] = _city.sign_post(ground, middle + Vector3(0, 2.0, 0))
	_ship = _city.sign_post(ground, Vector3(0, 2.2, -HALF_Z - 1.2))
	# the bridges
	for i in _slots.size(): _bridge(ground, solid, i)
	# what the depots have to send, a light on the dock, and the sign for the pink mark
	_city.part(ground, "crate", Vector3(-4.4, 0, 4.42), 14, Vector3(0.76, 0.76, 0.76))
	_city.part(ground, "crate", Vector3(4.42, 0, 4.42), -9, Vector3(0.76, 0.76, 0.76))
	_city.catalogue_part(ground, "work_light", Vector3(4.2, 0, -4.0), 115)
	_city.catalogue_part(ground, "pink_triangle_sign", Vector3(-3.7, 0, HALF_Z + 0.65), 0)
	_city.floor_words(ground, Vector3(-3.7, 0.012, HALF_Z + 1.25), "pink: a promise\nyou can take back", 30, PINK.lightened(0.2))
	# the body: one sensor over the basin and the floor round it
	var sensor := Area3D.new()
	sensor.name = "Reach"
	sensor.collision_layer = 0
	sensor.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(HALF_X * 2.0 + 6.0, 2.4, HALF_Z * 2.0 + 7.0)
	var shape := CollisionShape3D.new()
	shape.shape = room
	shape.position = Vector3(0, 1.2, 0.5)
	sensor.add_child(shape)
	ground.add_child(sensor)
	sensor.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _body = b)
	sensor.body_exited.connect(func(b: Node) -> void:
		if b == _body: _body = null)
	# the board: outside, between the two ways in, turned to the arrival
	_board = _city.board(ground, Vector3(1.0, 0, HALF_Z + 0.8), 3.3, 0.95)


## One crate slot: a plank deck let into the floor, a gate at its head, a crate for its tail, a pink mark beyond its head.
func _bridge(ground: Node3D, solid: StaticBody3D, i: int) -> void:
	var s: Dictionary = _slots[i]
	var x: float = s["x"]
	var north: float = s["north"]
	var south: float = s["south"]
	var length: int = roundi(south - north)
	var rows: int = roundi(WIDE / 0.25)
	for r in rows:
		_city.part(ground, "timber_plank_%dm" % length, Vector3(x + (float(r) - float(rows - 1) * 0.5) * 0.25, PROUD - 0.06, (north + south) * 0.5), 90, Vector3.ZERO, false)
	# the gate: a timber panel on a hinge at the west side of the head end; it swings in over the deck
	var hinge := Node3D.new()
	hinge.name = "Gate%d" % i
	hinge.position = Vector3(x - 0.48, 0, north + 0.06)
	ground.add_child(hinge)
	_city.part(hinge, "timber_panel_1x1", Vector3(0.48, 0, 0), 0, Vector3(0.96, 1.0, 0.045), false)
	for face in [1.0, -1.0]:
		var words := Label3D.new()
		words.text = "OPENS\ntoward the ship" if face > 0.0 else "NO WAY BACK\nnothing was promised here"
		words.pixel_size = 0.0016
		words.font_size = 40
		words.modulate = Color(0.12, 0.1, 0.08)
		words.outline_size = 0
		words.double_sided = false
		words.position = Vector3(0.48, 0.62, face * 0.03)
		if face < 0.0: words.rotation.y = PI
		hinge.add_child(words)
	_hinges.append(hinge)
	_gate_shapes.append(_city.wall(solid, Vector3(x, 0, north + 0.06), Vector3(WIDE, 1.3, 0.12)))
	# the crate: stands at the tail end while the slot is promised
	var holder := Node3D.new()
	holder.name = "Crate%d" % i
	add_child(holder)
	_city.part(holder, "crate", Vector3(x, PROUD, south - 0.45), 0, Vector3(0.76, 0.76, 0.76))
	for face in [1.0, -1.0]:
		var tag := Label3D.new()
		tag.text = "PROMISED"
		tag.pixel_size = 0.0016
		tag.font_size = 44
		tag.modulate = PINK
		tag.outline_size = 6
		tag.outline_modulate = Color(0, 0, 0, 1)
		tag.double_sided = false
		tag.position = Vector3(x, 0.5, south - 0.45 + face * 0.395)
		if face < 0.0: tag.rotation.y = PI
		holder.add_child(tag)
	_crates.append(holder)
	# the pink mark: on the floor beyond the head end, pointing back along the bridge
	var mark := MeshInstance3D.new()
	var arrow := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(-0.3, 0, -0.25), Vector3(0.3, 0, -0.25), Vector3(0, 0, 0.3)])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP])
	arrow.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mark.mesh = arrow
	var pink: StandardMaterial3D = _city.flat(PINK, 0.5)
	pink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pink.cull_mode = BaseMaterial3D.CULL_DISABLED
	mark.material_override = pink
	mark.position = Vector3(x, 0.014, north - 0.45)
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ground.add_child(mark)
	_marks.append(mark)


## ---- for a test ----

func state() -> Dictionary:
	var full := []
	for i in _slots.size():
		if _full[i]: full.append("%d>%d" % [int(_slots[i]["a"]), int(_slots[i]["b"])])
	var path: Array = way()
	var shut := []
	for i in closes(): shut.append("%d>%d" % [int(_slots[int(i)]["a"]), int(_slots[int(i)]["b"])])
	return {"promised": promised, "slots": _slots.size(), "full": full, "arrived": arrived(), "land": _land, "way": path, "against": against(path), "closes": shut,
		"under_way": excess(), "reach": can_reach(), "walked": _walked, "restored": _restored, "prefab_parts": int(_city.parts), "build_ms": _build_ms}


## The slot of a link: the n-th bridge from vertex a to vertex b; -1 when there is none.
func slot_of(a: int, b: int, n: int = 0) -> int:
	for i in _slots.size():
		if int(_slots[i]["a"]) == a and int(_slots[i]["b"]) == b:
			if n == 0: return i
			n -= 1
	return -1


## A point to stand on before a bridge's tail and one beyond its head, global.
func ends(slot: int) -> Array:
	var s: Dictionary = _slots[slot]
	return [to_global(Vector3(float(s["x"]), 0, float(s["south"]) + 0.7)), to_global(Vector3(float(s["x"]), 0, float(s["north"]) - 0.7))]


func is_full(slot: int) -> bool:
	return _full[slot]
