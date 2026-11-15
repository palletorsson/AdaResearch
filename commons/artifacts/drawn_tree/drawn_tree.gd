extends Node3D
## WHO DREW THE TREE? (floor QFEP_E_Term; the pass, 2026-11-15)
##
## The hall's fan counts leaves and reports ln(N) "under equal leaf weights". Its text keeps asking what the count
## cannot say: "Eighty-one drawn leaves do not tell you that a traveller is equally likely to arrive at each one."
## "Twenty-seven tells us how many endings remain, not which ones." "Reopening a route may not restore the lives
## or histories lost when it closed." "Who drew the tree? ... You can reopen it. You cannot yet ask it to grow
## otherwise." This is a tree to be the traveller in - a PLAYGROUND form.
##
## Sixteen endings from four forks of two, taped on the floor from START. Walk a path: it lights behind you, and
## a bead is hung at the ending you reach. The stand gives the entropy twice: counted, as if every ending were
## equally likely (ln 16), and as walked, from where travellers actually arrived.
##
## PRUNE A and PRUNE B each close four gates and leave eight endings: the same count, the same entropy, different
## endings - and different arrivals behind the gates. An amber gate stands where continuation is refused; what
## lay beyond it is no longer drawn. OPEN takes the gates away: the endings return, the beads that hung there do
## not, and the stand says how many were lost.
##
## And what the fan cannot do yet: stand still at one of the eight last forks and a third way is drawn where none
## was offered, to an ending nobody specified. Only at the last forks: that is where the one who drew the tree
## left room, and the board says so.
##
## `drawn` is the axis: open, pruned_a, pruned_b - the tree as it stands when found.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const DRAWN := ["open", "pruned_a", "pruned_b"]
const DEPTH := 4
const DZ := 1.35                         # from one fork to the next, north
const DX := 0.62                         # between two endings
const ROOT_Z := 2.7
const ASKED := 0.45                      # an asked-for ending lies this far beyond its fork's two
const PLATES := [
	{"key": "prune_a", "says": "PRUNE A", "at": Vector2(2.0, 2.9)},
	{"key": "prune_b", "says": "PRUNE B", "at": Vector2(3.0, 2.9)},
	{"key": "open", "says": "OPEN", "at": Vector2(4.0, 2.9)},
]
const PLATE := 0.84
const TAPE := Color("f4efe2")
const LIT := Color("40f2ff")
const AMBER := Color("f2a23a")
const PINK := Color("ff5fa8")
const DARK := Color("191e29")
const PALE := Color("efe9dc")

@export_enum("open", "pruned_a", "pruned_b") var drawn := "open"

var _city = City.new()
var _plates := {}                        # "L/i" -> MeshInstance3D, and "asked/i"
var _edges := {}                         # "L/i" -> MeshInstance3D (the tape into that node), and "asked/i"
var _gates := {}                         # "3/i" -> {node, shape}
var _beads := {}                         # ending id -> Array[MeshInstance3D]
var _plate_tiles: Array[MeshInstance3D] = []
var _closed := {}                        # "3/i" -> true
var _asked := {}                         # fork i -> true
var _tally := {}                         # ending id -> arrivals
var _lost := 0
var _at := "0/0"
var _armed := false
var _last_arrival := ""
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _count_words: Label3D
var _equal_words: Label3D
var _walked_words: Label3D
var _closed_words: Label3D
var _here_words: Label3D
var _board: Label3D
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_drawn"): _take({"drawn": get_meta("config_drawn")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_prune(drawn)


func _take(config_data: Dictionary) -> void:
	if config_data.has("drawn") and str(config_data["drawn"]) in DRAWN: drawn = str(config_data["drawn"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := drawn
	_take(config_data)
	if is_inside_tree() and _board != null and drawn != before:
		_tally.clear()
		_lost = 0
		_asked.clear()
		_prune(drawn)


## ---- the rule ----

## The fan's own reading (entropy_fan.possibility_reading): the logarithm of the count, every ending weighed alike.
static func equal_entropy(count: int) -> float:
	return log(float(maxi(count, 1)))


## The entropy of where travellers arrived: -sum f ln f over the endings' shares.
static func walked_entropy(arrivals: Array) -> float:
	var total := 0
	for n in arrivals: total += int(n)
	if total == 0: return 0.0
	var h := 0.0
	for n in arrivals:
		if int(n) > 0:
			var f: float = float(n) / float(total)
			h -= f * log(f)
	return h


## Where a node stands: level 0 is START, level 4 the endings; an ending's place is counted from the west.
static func node_at(level: int, i: int) -> Vector3:
	var leaves: int = 1 << (DEPTH - level)                       # endings under this node
	var first: int = i * leaves
	var middle: float = float(first) + float(leaves - 1) * 0.5
	return Vector3((middle - 7.5) * DX, 0, ROOT_Z - float(level) * DZ)


static func asked_at(fork: int) -> Vector3:
	return node_at(3, fork) + Vector3(0, 0, -DZ - ASKED)


## The turns from START to a node: L is west, R east.
static func path(level: int, i: int) -> String:
	var turns := PackedStringArray()
	for l in range(level, 0, -1): turns.insert(0, "R" if (i >> (level - l)) & 1 == 1 else "L")
	return " ".join(turns) if not turns.is_empty() else "START"


func _fork_open(fork: int) -> bool:
	return not _closed.has("3/%d" % fork)


## The endings that can be reached now: their ids, west to east, the asked-for ones in their forks' places.
func endings() -> Array:
	var out := []
	for fork in 8:
		if not _fork_open(fork): continue
		out.append("4/%d" % (fork * 2))
		if _asked.has(fork): out.append("asked/%d" % fork)
		out.append("4/%d" % (fork * 2 + 1))
	return out


func _prune(how: String) -> void:
	var closing := {}
	if how != "open":
		for level2 in 4: closing["3/%d" % (level2 * 2 + (1 if how == "pruned_a" else 0))] = true
	# what hung behind a gate when it closes is lost; opening does not bring it back
	for key in closing:
		if _closed.has(key): continue
		var fork: int = int(str(key).get_slice("/", 1))
		for id in ["4/%d" % (fork * 2), "4/%d" % (fork * 2 + 1), "asked/%d" % fork]:
			_lost += int(_tally.get(id, 0))
			_tally.erase(id)
	_closed = closing
	_show()
	_tell()


func _arrive(id: String) -> void:
	_tally[id] = int(_tally.get(id, 0)) + 1
	_last_arrival = id
	_armed = false
	_show()
	_tell()


func _ask(fork: int) -> void:
	_asked[fork] = true
	_show()
	_tell()


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _visible_key(key: String) -> bool:
	var parts := key.split("/")
	if parts[0] == "asked": return _fork_open(int(parts[1])) and _asked.has(int(parts[1]))
	var level: int = int(parts[0])
	if level < 3: return true
	return _fork_open(int(parts[1]) >> (level - 3))


func _physics_process(delta: float) -> void:
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var region := ""
	if absf(p.y) < 1.5:
		for key in _plates:
			if not _visible_key(key): continue
			var at: Vector3 = (_plates[key] as MeshInstance3D).position
			# an ending counts only when stood on: two endings lie 0.62 m apart and a third way runs between them
			var reach: float = 0.22 if str(key).begins_with("4/") or str(key).begins_with("asked/") else 0.34
			if Vector2(p.x - at.x, p.z - at.z).length() < reach: region = str(key)
		if region == "":
			for plate in PLATES:
				var at2: Vector2 = plate["at"]
				if absf(p.x - at2.x) < PLATE * 0.5 and absf(p.z - at2.y) < PLATE * 0.5: region = str(plate["key"])
	var moved: float = Vector2(p.x - _last.x, p.z - _last.z).length()
	_last = p
	if region != _region or moved > 0.3 * delta:
		_still = 0.0
	elif _still >= 0.0:
		_still += delta
	var entered: bool = region != _region
	_region = region
	if entered and region.contains("/"):
		_at = region
		if region == "0/0": _armed = true
		elif (region.begins_with("4/") or region.begins_with("asked/")) and _armed: _arrive(region)
		_show()
	if _still >= 0.8 and region != "":
		_still = -99.0
		if region.begins_with("3/") and not _asked.has(int(region.get_slice("/", 1))): _ask(int(region.get_slice("/", 1)))
		elif region == "prune_a": _prune("pruned_a")
		elif region == "prune_b": _prune("pruned_b")
		elif region == "open": _prune("open")


func _ending_says(id: String) -> String:
	if id.begins_with("asked/"): return path(3, int(id.get_slice("/", 1))) + " +"
	return path(4, int(id.get_slice("/", 1)))


func _show() -> void:
	# the path from START to where the traveller is
	var lit := {}
	if _visible_key(_at):
		var parts := _at.split("/")
		var level: int = 3 if parts[0] == "asked" else int(parts[0])
		var i: int = int(parts[1])
		if parts[0] == "asked": lit[_at] = true
		while level >= 1:
			lit["%d/%d" % [level, i]] = true
			i >>= 1
			level -= 1
	for key in _plates:
		var seen: bool = _visible_key(key)
		(_plates[key] as MeshInstance3D).visible = seen
		if _edges.has(key):
			var tape: MeshInstance3D = _edges[key]
			tape.visible = seen
			(tape.material_override as StandardMaterial3D).albedo_color = LIT if lit.has(key) else (PINK if str(key).begins_with("asked/") else TAPE)
	for key in _gates:
		var shut: bool = _closed.has(key)
		(_gates[key]["node"] as Node3D).visible = shut
		(_gates[key]["shape"] as CollisionShape3D).disabled = not shut
	for id in _beads:
		var hung: int = int(_tally.get(id, 0)) if _visible_key(id) else 0
		var rod: Array = _beads[id]
		for b in rod.size(): (rod[b] as MeshInstance3D).visible = b < hung or (b == 0 and false)
	for i in PLATES.size():
		var key: String = str(PLATES[i]["key"])
		var on: bool = (key == "prune_a" and drawn_now() == "pruned_a") or (key == "prune_b" and drawn_now() == "pruned_b") or (key == "open" and drawn_now() == "open")
		(_plate_tiles[i].material_override as StandardMaterial3D).albedo_color = Color("f6cf93") if on else PALE
	var open: Array = endings()
	var arrivals := []
	var total := 0
	var places := 0
	for id in open:
		var n: int = int(_tally.get(id, 0))
		arrivals.append(n)
		total += n
		if n > 0: places += 1
	_count_words.text = "ENDINGS DRAWN:  %d" % open.size() + ("   (2 × 2 × 2 × 2)" if open.size() == 16 else "")
	_equal_words.text = "counted, as if each were equally likely:\nH = ln %d = %.2f nats" % [open.size(), equal_entropy(open.size())]
	_walked_words.text = ("as walked:  %d arrival%s at %d ending%s:\nH = %.2f nats" % [total, "" if total == 1 else "s", places, "" if places == 1 else "s", walked_entropy(arrivals)]) if total > 0 else "as walked:  nobody has arrived yet"
	var lines := PackedStringArray()
	if not _closed.is_empty():
		var shut := PackedStringArray()
		for key in _closed: shut.append(path(3, int(str(key).get_slice("/", 1))))
		shut.sort()
		lines.append("closed at:  " + ",  ".join(shut) + "   (%d endings behind them)" % (16 - _open_leaves()))
	if _lost > 0: lines.append("%d arrival%s hung behind gates when they closed.\nOPEN returns the endings, not the arrivals." % [_lost, "" if _lost == 1 else "s"])
	if not _asked.is_empty():
		var asks := PackedStringArray()
		for fork in _asked: asks.append(path(3, int(fork)))
		asks.sort()
		lines.append("asked for, and not in the first drawing:  " + ",  ".join(asks))
	_closed_words.text = "\n".join(lines)
	_here_words.text = ("you are at:  " + (_ending_says(_at) if _at.begins_with("4/") or _at.begins_with("asked/") else path(int(_at.get_slice("/", 0)), int(_at.get_slice("/", 1))))) if _visible_key(_at) else ""


func _open_leaves() -> int:
	var n := 0
	for fork in 8:
		if _fork_open(fork): n += 2
	return n


func drawn_now() -> String:
	if _closed.is_empty(): return "open"
	return "pruned_a" if _closed.has("3/1") else "pruned_b"


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["WHO DREW THE TREE?"])
	lines.append("Four forks of two: sixteen endings. Walk from START; your path lights, and a bead is hung at the ending you reach. The stand gives the entropy twice: counted, as if every ending were equally likely, and as walked.")
	lines.append("PRUNE A and PRUNE B each close four gates and leave eight endings. The same count, the same entropy, different endings. What lay beyond an amber gate is no longer drawn. OPEN takes the gates away: the endings come back, the beads that hung there do not.")
	lines.append("The fan cannot be asked to grow otherwise. Here you can, a little: stand still at one of the eight last forks and a third way is drawn, to an ending nobody specified. Only there - that is where I left room. The rest of the tree is still mine.")
	if _lost > 0 or not _asked.is_empty():
		lines.append("So far: %d arrival%s lost behind gates, %d branch%s asked for." % [_lost, "" if _lost == 1 else "s", _asked.size(), "" if _asked.size() == 1 else "es"])
	_board.text = "\n".join(lines)


## ---- building, once ----

func _box(parent: Node3D, at: Vector3, size: Vector3, paint: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = paint
	mesh.position = at
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	return mesh


func _disc(at: Vector3, radius: float, colour: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = 0.02
	mesh.mesh = shape
	mesh.material_override = _city.flat(colour, 0.8)
	mesh.position = at + Vector3(0, 0.02, 0)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	return mesh


func _tape(a: Vector3, b: Vector3, colour: Color, wide: float = 0.09) -> MeshInstance3D:
	var along := b - a
	var paint: StandardMaterial3D = _city.flat(colour, 0.8)
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED      # tape must read on the slab in the tower's own shadow
	var tape: MeshInstance3D = _box(self, (a + b) * 0.5 + Vector3(0, 0.012, 0), Vector3(wide, 0.008, along.length()), paint)
	tape.rotation.y = atan2(along.x, along.z)
	return tape


func _words(parent: Node3D, at: Vector3, size: int, pixel: float, colour: Color) -> Label3D:
	var label3d := Label3D.new()
	label3d.font_size = size
	label3d.pixel_size = pixel
	label3d.modulate = colour
	label3d.outline_size = 0
	label3d.double_sided = false
	label3d.position = at
	parent.add_child(label3d)
	return label3d


func _rod(id: String, at: Vector3) -> void:
	_box(self, at + Vector3(0, 0.45, -0.3), Vector3(0.012, 0.9, 0.012), _city.flat(DARK, 0.6))
	var rod := []
	for b in 8:
		var bead := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = 0.05
		ball.height = 0.1
		bead.mesh = ball
		bead.material_override = _city.flat(LIT, 0.4)
		bead.position = at + Vector3(0, 0.08 + 0.105 * float(b), -0.3)
		bead.visible = false
		add_child(bead)
		rod.append(bead)
	_beads[id] = rod


func _build_once() -> void:
	# the tree as it was first drawn
	for level in DEPTH + 1:
		for i in 1 << level:
			var key := "%d/%d" % [level, i]
			var at: Vector3 = node_at(level, i)
			if level > 0: _edges[key] = _tape(node_at(level - 1, i >> 1), at, TAPE)
			_plates[key] = _disc(at, 0.3 if level == 0 else (0.2 if level == DEPTH else 0.24), PALE if level < DEPTH else Color("9fe6ee"))
			if level == DEPTH: _rod(key, at)
	_city.floor_words(self, node_at(0, 0) + Vector3(0, 0.035, 0.55), "START", 50, PALE)
	_city.floor_words(self, node_at(1, 0) + Vector3(-0.6, 0.03, 0), "L", 44, PALE)
	_city.floor_words(self, node_at(1, 1) + Vector3(0.6, 0.03, 0), "R", 44, PALE)
	# what can be asked for: a third way at each last fork
	for fork in 8:
		var key := "asked/%d" % fork
		var at: Vector3 = asked_at(fork)
		_edges[key] = _tape(node_at(3, fork), at, PINK, 0.06)
		_plates[key] = _disc(at, 0.2, PINK)
		_rod(key, at)
	# the gates
	for fork in 8:
		var from: Vector3 = node_at(2, fork >> 1)
		var to: Vector3 = node_at(3, fork)
		var gate := Node3D.new()
		gate.position = from.lerp(to, 0.45)
		gate.rotation.y = atan2((to - from).x, (to - from).z)
		add_child(gate)
		_box(gate, Vector3(0, 0.5, 0), Vector3(0.9, 0.12, 0.06), _city.flat(AMBER, 0.6))
		_box(gate, Vector3(0, 0.9, 0), Vector3(0.9, 0.08, 0.06), _city.flat(AMBER, 0.6))
		for hand in [-1.0, 1.0]: _box(gate, Vector3(hand * 0.45, 0.5, 0), Vector3(0.06, 1.0, 0.06), _city.flat(AMBER, 0.6))
		var solid := StaticBody3D.new()
		gate.add_child(solid)
		var shape: CollisionShape3D = _city.wall(solid, Vector3.ZERO, Vector3(1.0, 1.2, 0.12))
		_gates["3/%d" % fork] = {"node": gate, "shape": shape}
	# the plates
	for plate in PLATES:
		var at: Vector2 = plate["at"]
		_plate_tiles.append(_box(self, Vector3(at.x, 0.012, at.y), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8)))
		_city.floor_words(self, Vector3(at.x, 0.035, at.y), str(plate["says"]), 34, DARK).outline_size = 0
	# the stand, behind the endings
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(-1.4, 0, ROOT_Z - float(DEPTH) * DZ - 1.5)
	add_child(stand)
	var solid2 := StaticBody3D.new()
	stand.add_child(solid2)
	_box(stand, Vector3(0, 1.55, -0.05), Vector3(2.9, 2.5, 0.06), _city.flat(DARK, 0.85))
	_city.wall(solid2, Vector3(0, 0, -0.05), Vector3(2.9, 2.8, 0.12))
	for hand in [-1.0, 1.0]: _box(stand, Vector3(hand * 1.3, 0.15, -0.05), Vector3(0.08, 0.3, 0.08), _city.flat(DARK, 0.85))
	_count_words = _words(stand, Vector3(0, 2.52, 0), 46, 0.003, Color("9fe6ee"))
	_equal_words = _words(stand, Vector3(0, 2.1, 0), 30, 0.003, PALE)
	_walked_words = _words(stand, Vector3(0, 1.62, 0), 30, 0.003, LIT)
	_closed_words = _words(stand, Vector3(0, 1.0, 0), 23, 0.003, AMBER)
	_here_words = _words(stand, Vector3(0, 0.48, 0), 26, 0.003, PALE)
	_board = _city.board(self, Vector3(-4.2, 0, 3.0), 3.2, 1.7)


## ---- for a test ----

func state() -> Dictionary:
	var open: Array = endings()
	var arrivals := []
	for id in open: arrivals.append(int(_tally.get(id, 0)))
	var gates := []
	for key in _gates:
		if (_gates[key]["node"] as Node3D).visible: gates.append(key)
	return {"drawn": drawn_now(), "endings": open, "count": open.size(), "equal_H": snappedf(equal_entropy(open.size()), 0.0001), "walked_H": snappedf(walked_entropy(arrivals), 0.0001), "tally": _tally.duplicate(),
		"lost": _lost, "asked": _asked.keys(), "gates": gates, "at": _at, "here": _here_words.text, "closed_words": _closed_words.text, "walked_words": _walked_words.text,
		"beads": _beads.keys().filter(func(id): return (_beads[id][0] as MeshInstance3D).visible).size(), "board": _board.text if _board != null else "", "build_ms": _build_ms}


func node_point(level: int, i: int) -> Vector3:
	return to_global(node_at(level, i))


func asked_point(fork: int) -> Vector3:
	return to_global(asked_at(fork))


func plate_point(key: String) -> Vector3:
	for plate in PLATES:
		if str(plate["key"]) == key: return to_global(Vector3((plate["at"] as Vector2).x, 0, (plate["at"] as Vector2).y))
	return global_position
