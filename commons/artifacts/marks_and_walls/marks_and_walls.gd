extends Node3D
## MARKS AND WALLS (floor SpeculativeComputation_Collective_Knowledge; the pass, 2026-11-16)
##
## The hall, of its growing helix: "When many marks accumulate, what makes the result knowledge rather than a
## pile?" "A contribution may repeat an error, correct an earlier claim, supply a missing case or disagree with an
## accepted account. Those actions can add little to a simple count while changing the usefulness of the shared
## result dramatically." "Does the shape preserve a reason for accepting that contribution, or only the fact that
## something arrived?" "What would have to survive for someone else to understand why you changed that piece?"
## This is a shared record a body can check - a PLAYGROUND form.
##
## A field of five by four cells. Between some cells stand walls that cannot be seen. On the floor lie the marks
## of six earlier sources, each saying: a wall here. Each mark keeps who made it and how: FELT (a body was
## stopped) or only TOLD. Some repeat one another. Three are wrong. Three walls nobody marked.
##
## The visitor's body is the test. Stopped where a mark says: that mark is checked. Stopped where nobody marked:
## a mark is added, VISITOR, felt. Walked through where a mark says wall: the mark is struck, and stays on the
## floor with who said it and how it was found wrong. SIGN EVERYTHING adds a told mark of the visitor's to every
## marked edge: many more marks, one more source, nothing checked.
##
## The stand counts marks and sources, felt and told, the edges this body has tested - and how many of the 31
## edges the marks are wrong about. `record` is the axis: found, signed, checked. The same arithmetic is benched
## in tools/probes/marks_and_walls_bench.py.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const COLS := 5
const ROWS := 4
const CELL := 1.2
const WALLS := ["H:2:2", "H:3:2", "V:0:3", "H:1:1", "V:1:1", "H:2:0", "V:3:0", "H:4:1"]
const FOUND := [["P1", "H:2:2", "felt"], ["P2", "H:2:2", "told"], ["P4", "H:2:2", "told"], ["P1", "H:1:1", "felt"], ["P3", "V:1:1", "felt"], ["P3", "H:2:0", "felt"], ["P5", "H:2:0", "told"],
	["P2", "V:0:3", "felt"], ["P6", "V:1:2", "told"], ["P4", "V:1:2", "told"], ["P5", "H:3:1", "told"]]
const RECORDS := ["found", "signed", "checked"]
const PLATE_AT := Vector2(2.4, 3.3)
const PLATE := 0.84
const DARK := Color("191e29")
const PALE := Color("efe9dc")
const CHALK := Color("f4f1e8")
const DIM := Color("a9adb8")
const MINE := Color("ffe14a")
const RED := Color("ff5a3c")

@export_enum("found", "signed", "checked") var record := "found"

var _city = City.new()
var _marks: Array = []                    # {source, edge, kind, struck, note}
var _tested := {}                         # edges this body has been stopped at or walked through
var _signed := false
var _last_event := ""
var _cell := Vector2i(-1, -1)
var _floor_marks: Node3D
var _panes := {}                          # edge -> the pane that shows for a moment when a wall is felt
var _flash := {}                          # edge -> seconds left
var _plate_tile: MeshInstance3D
var _lines: Array[Label3D] = []
var _status: Label3D
var _board: Label3D
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_record"): _take({"record": get_meta("config_record")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_found()


func _take(config_data: Dictionary) -> void:
	if config_data.has("record") and RECORDS.has(str(config_data["record"])): record = str(config_data["record"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := record
	_take(config_data)
	if is_inside_tree() and _board != null and record != before: _found()


func _found() -> void:
	_marks.clear()
	for m in FOUND: _marks.append({"source": m[0], "edge": m[1], "kind": m[2], "struck": false, "note": ""})
	_tested.clear()
	_signed = false
	_last_event = ""
	_cell = Vector2i(-1, -1)
	if record == "signed": _sign(true)
	elif record == "checked":
		for edge in edges():
			_tested[edge] = true
			if WALLS.has(edge):
				if not _marked(edge): _marks.append({"source": "VISITOR", "edge": edge, "kind": "felt", "struck": false, "note": ""})
			else:
				_strike(edge)
	_lay_marks()
	_show()
	_tell()


## ---- the rule ----

static func edges() -> Array:
	var out: Array = []
	for c in COLS - 1:
		for r in ROWS: out.append("V:%d:%d" % [c, r])
	for c in COLS:
		for r in ROWS - 1: out.append("H:%d:%d" % [c, r])
	return out


## The edge between two neighbouring cells, or "" when they are not neighbours.
static func between(a: Vector2i, b: Vector2i) -> String:
	if a.y == b.y and absi(a.x - b.x) == 1: return "V:%d:%d" % [mini(a.x, b.x), a.y]
	if a.x == b.x and absi(a.y - b.y) == 1: return "H:%d:%d" % [a.x, mini(a.y, b.y)]
	return ""


## The middle of an edge on the floor, and whether it runs north to south.
static func edge_at(edge: String) -> Dictionary:
	var parts: PackedStringArray = edge.split(":")
	var c: int = int(parts[1])
	var r: int = int(parts[2])
	if parts[0] == "V": return {"at": Vector2(-1.8 + CELL * float(c), -1.8 + CELL * float(r)), "upright": true}
	return {"at": Vector2(-2.4 + CELL * float(c), -1.2 + CELL * float(r)), "upright": false}


static func cell_middle(cell: Vector2i) -> Vector2:
	return Vector2(-2.4 + CELL * float(cell.x), -1.8 + CELL * float(cell.y))


func _marked(edge: String) -> bool:
	for m in _marks:
		if m["edge"] == edge and not m["struck"]: return true
	return false


## How many of the 31 edges the marks are wrong about: a live mark where no wall stands, or a wall with none.
func wrong_about() -> int:
	var n := 0
	for edge in edges():
		if _marked(edge) != WALLS.has(edge): n += 1
	return n


func _strike(edge: String) -> int:
	var n := 0
	for m in _marks:
		if m["edge"] == edge and not m["struck"]:
			m["struck"] = true
			m["note"] = "VISITOR walked through"
			n += 1
	return n


## The visitor's told mark on every edge somebody else marked; or those marks taken away again.
func _sign(on: bool) -> void:
	_signed = on
	var kept: Array = []
	for m in _marks:
		if not (m["source"] == "VISITOR" and m["kind"] == "told"): kept.append(m)
	_marks = kept
	if on:
		var done := {}
		for m in kept:
			if m["source"] != "VISITOR" and not m["struck"] and not done.has(m["edge"]):
				done[m["edge"]] = true
				_marks.append({"source": "VISITOR", "edge": m["edge"], "kind": "told", "struck": false, "note": ""})


## A body was stopped at a wall.
func _felt(edge: String) -> void:
	_tested[edge] = true
	_flash[edge] = 1.6
	(_panes[edge] as MeshInstance3D).visible = true
	var others := false
	for m in _marks:
		if m["edge"] == edge and m["source"] != "VISITOR" and not m["struck"]:
			others = true
			m["note"] = "VISITOR was stopped here too"
	for m in _marks:
		if m["edge"] == edge and m["source"] == "VISITOR" and m["kind"] == "felt": return
	_marks.append({"source": "VISITOR", "edge": edge, "kind": "felt", "struck": false, "note": ""})
	_last_event = "confirmed" if others else "added"


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _physics_process(delta: float) -> void:
	for edge in _flash.keys():
		_flash[edge] -= delta
		if _flash[edge] <= 0.0:
			(_panes[edge] as MeshInstance3D).visible = false
			_flash.erase(edge)
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var at := Vector2(p.x, p.z)
	var level: bool = absf(p.y) < 1.5
	var inside: bool = level and absf(at.x) < CELL * 2.5 and absf(at.y) < CELL * 2.0
	# walking from one cell into the next is a test of the edge between them
	var cell := Vector2i(int(floor((at.x + CELL * 2.5) / CELL)), int(floor((at.y + CELL * 2.0) / CELL))) if inside else Vector2i(-1, -1)
	if cell != _cell:
		if inside and _cell.x >= 0:
			var crossed: String = between(_cell, cell)
			if crossed != "":
				_tested[crossed] = true
				var struck: int = _strike(crossed)
				if struck > 0:
					_last_event = "struck:%d" % struck
					_lay_marks()
				_show()
		_cell = cell
	var region := ""
	if level and absf(p.x - PLATE_AT.x) < PLATE * 0.5 and absf(p.z - PLATE_AT.y) < PLATE * 0.5: region = "sign"
	elif inside:
		for edge in WALLS:
			var e: Dictionary = edge_at(edge)
			var mid: Vector2 = e["at"]
			var along: float = absf(at.y - mid.y) if e["upright"] else absf(at.x - mid.x)
			var off: float = absf(at.x - mid.x) if e["upright"] else absf(at.y - mid.y)
			if along <= CELL * 0.5 and off < 0.36: region = "wall:" + edge
	var moved: float = Vector2(p.x - _last.x, p.z - _last.z).length()
	_last = p
	if region != _region or moved > 0.3 * delta:
		_still = 0.0
	elif _still >= 0.0:
		_still += delta
	_region = region
	if _still >= 0.8 and region != "":
		_still = -99.0
		if region == "sign":
			_sign(not _signed)
			_last_event = "signed" if _signed else ""
		else:
			_felt(region.trim_prefix("wall:"))
		_lay_marks()
		_show()
		_tell()


func counts() -> Dictionary:
	var sources := {}
	var out := {"marks": _marks.size(), "struck": 0, "felt": 0, "told": 0}
	for m in _marks:
		sources[m["source"]] = true
		out[m["kind"]] += 1
		if m["struck"]: out["struck"] += 1
	out["sources"] = sources.size()
	out["tested"] = _tested.size()
	out["wrong_about"] = wrong_about()
	return out


func _status_text(c: Dictionary) -> String:
	if int(c["wrong_about"]) == 0:
		return "THE MARKS NOW AGREE WITH THE WALLS.\nTHE COUNT OF MARKS HARDLY MOVED: %d THEN, %d NOW." % [FOUND.size(), int(c["marks"])]
	if _last_event == "signed":
		return "YOU SIGNED EVERYTHING: %d MORE MARKS, ONE MORE SOURCE.\nNOTHING WAS CHECKED. THE MARKS ARE AS WRONG AS BEFORE." % (int(c["marks"]) - FOUND.size())
	if _last_event == "added":
		return "YOU WERE STOPPED WHERE NOBODY HAD MARKED A WALL.\nONE MARK ADDED: VISITOR, FELT."
	if _last_event == "confirmed":
		return "A SECOND BODY WAS STOPPED WHERE THE MARK SAYS.\nTHAT MARK IS NOW CHECKED, NOT ONLY COUNTED."
	if _last_event.begins_with("struck"):
		return "YOU WALKED THROUGH A MARKED WALL. %s STRUCK, AND KEPT ON THE FLOOR:\nWHO SAID IT, AND HOW IT WAS FOUND WRONG." % ("1 MARK" if _last_event == "struck:1" else _last_event.trim_prefix("struck:") + " MARKS")
	return "ELEVEN MARKS SAY: A WALL HERE. SOME WERE FELT, SOME ONLY TOLD.\nWALK IN. BE STOPPED, OR WALK THROUGH."


func _show() -> void:
	var c: Dictionary = counts()
	_lines[0].text = "MARKS ON THE FLOOR:  %d     ·     SOURCES:  %d" % [int(c["marks"]), int(c["sources"])]
	_lines[1].text = "felt by a body:  %d     ·     only told:  %d     ·     struck:  %d" % [int(c["felt"]), int(c["told"]), int(c["struck"])]
	_lines[2].text = "edges your own body has tested:  %d of 31" % int(c["tested"])
	_lines[3].text = "THE MARKS ARE WRONG ABOUT  %d  OF 31 EDGES" % int(c["wrong_about"])
	_lines[3].modulate = Color("7af08a") if int(c["wrong_about"]) == 0 else RED
	_status.text = _status_text(c)
	(_plate_tile.material_override as StandardMaterial3D).albedo_color = Color("f6e39a") if _signed else PALE


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["MARKS AND WALLS"])
	lines.append("Some of the lines between these cells are walls you cannot see. Six others were here before you and left marks: a wall here. A solid mark was FELT: a body was stopped. A broken mark was only TOLD. Some marks repeat one another. Some are wrong. Some walls nobody marked.")
	lines.append("Walk in. Where you are stopped, the floor takes your mark: VISITOR, felt. Where you walk through a marked wall, the mark is struck and stays, with who said it and how it was found wrong. SIGN EVERYTHING adds your name to every marked edge without your body going near one.")
	lines.append("The stand counts the marks. It also counts how many edges the marks are wrong about. Watch which of the two numbers your walking moves.")
	_board.text = "\n".join(lines)


## ---- building ----

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


func _plain(colour: Color) -> StandardMaterial3D:
	var paint: StandardMaterial3D = _city.flat(colour, 0.9)
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return paint


## The marks as they lie now: a chalk stroke along the edge (solid: felt; broken: told), a tag with the source,
## a red stroke across a struck one.
func _lay_marks() -> void:
	for child in _floor_marks.get_children(): child.queue_free()
	var stacked := {}
	for m in _marks:
		var edge: String = m["edge"]
		var e: Dictionary = edge_at(edge)
		var k: int = int(stacked.get(edge, 0))
		stacked[edge] = k + 1
		var holder := Node3D.new()
		var mid: Vector2 = e["at"]
		var shift: float = 0.1 + 0.11 * float(k)
		holder.position = Vector3(mid.x + (shift if e["upright"] else 0.0), 0.0, mid.y + (0.0 if e["upright"] else shift))
		holder.rotation.y = PI * 0.5 if e["upright"] else 0.0
		_floor_marks.add_child(holder)
		var mine: bool = m["source"] == "VISITOR"
		var ink: StandardMaterial3D = _plain(MINE if mine else (CHALK if m["kind"] == "felt" else DIM))
		if m["kind"] == "felt":
			_box(holder, Vector3(0, 0.02, 0), Vector3(0.9, 0.008, 0.06), ink)
		else:
			for part in [-0.33, 0.0, 0.33]: _box(holder, Vector3(part, 0.02, 0), Vector3(0.2, 0.008, 0.05), ink)
		if m["struck"]: _box(holder, Vector3(0, 0.026, 0), Vector3(1.0, 0.008, 0.025), _plain(RED)).rotation.y = 0.35
		var tag: Label3D = _city.floor_words(holder, Vector3(0.0, 0.03, 0.0), "%s %s" % [m["source"], m["kind"]], 22, RED if m["struck"] else (MINE if mine else PALE))
		tag.position = Vector3(-0.28 + 0.28 * float(k % 3), 0.032, 0.0)
		tag.outline_size = 4


func _build_once() -> void:
	# the cells: faint lines, a number in each, the two ways in named
	var faint: StandardMaterial3D = _plain(Color("4a5062"))
	for c in COLS + 1: _box(self, Vector3(-3.0 + CELL * float(c), 0.01, 0), Vector3(0.02, 0.006, CELL * float(ROWS)), faint)
	for r in ROWS + 1: _box(self, Vector3(0, 0.01, -2.4 + CELL * float(r)), Vector3(CELL * float(COLS), 0.006, 0.02), faint)
	_city.floor_words(self, Vector3(0, 0.03, 2.75), "the way in", 44, PALE)
	_city.floor_words(self, Vector3(0, 0.03, -2.75), "the way out", 44, PALE)
	# the walls that cannot be seen, and the pane each shows for a moment when a body meets it
	var glass: StandardMaterial3D = _plain(Color(0.6, 0.9, 1.0, 0.28))
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var solid := StaticBody3D.new()
	add_child(solid)
	for edge in WALLS:
		var e: Dictionary = edge_at(edge)
		var mid: Vector2 = e["at"]
		var size := Vector3(0.08, 2.0, CELL) if e["upright"] else Vector3(CELL, 2.0, 0.08)
		_city.wall(solid, Vector3(mid.x, 0, mid.y), size)
		var pane: MeshInstance3D = _box(self, Vector3(mid.x, 1.0, mid.y), size * Vector3(0.5, 1.0, 1.0) if e["upright"] else size * Vector3(1.0, 1.0, 0.5), glass)
		pane.visible = false
		_panes[edge] = pane
	_floor_marks = Node3D.new()
	_floor_marks.name = "Marks"
	add_child(_floor_marks)
	# the plate
	_plate_tile = _box(self, Vector3(PLATE_AT.x, 0.012, PLATE_AT.y), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8))
	_city.floor_words(self, Vector3(PLATE_AT.x, 0.035, PLATE_AT.y), "SIGN\nEVERYTHING", 46, DARK).outline_size = 0
	# the stand
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(3.3, 0, -3.3)
	add_child(stand)
	var held := StaticBody3D.new()
	stand.add_child(held)
	_box(stand, Vector3(0, 3.2, -0.05), Vector3(5.2, 2.1, 0.06), _city.flat(DARK, 0.85))
	for hand in [-1.0, 1.0]:
		_box(stand, Vector3(hand * 2.5, 1.1, -0.05), Vector3(0.08, 2.2, 0.08), _city.flat(DARK, 0.85))
		_city.wall(held, Vector3(hand * 2.5, 0, -0.05), Vector3(0.1, 4.2, 0.1))
	var heights := [4.0, 3.68, 3.38, 3.04]
	var sizes := [32, 24, 24, 34]
	var colours := [PALE, Color("b9c0cc"), MINE, RED]
	for i in 4: _lines.append(_words(stand, Vector3(0, float(heights[i]), 0), int(sizes[i]), 0.005, colours[i]))
	_status = _words(stand, Vector3(0, 2.52, 0), 22, 0.005, Color("f2a23a"))
	_board = _city.board(self, Vector3(4.9, 0, -0.4), 3.2, 1.7)


## ---- for a test ----

func state() -> Dictionary:
	var c: Dictionary = counts()
	c["signed"] = _signed
	c["cell"] = [_cell.x, _cell.y]
	c["last_event"] = _last_event
	c["status"] = _status.text
	c["lines"] = _lines.map(func(l): return l.text)
	c["visitor_marks"] = _marks.filter(func(m): return m["source"] == "VISITOR").map(func(m): return "%s %s" % [m["edge"], m["kind"]])
	c["struck_marks"] = _marks.filter(func(m): return m["struck"]).map(func(m): return "%s %s: %s" % [m["source"], m["edge"], m["note"]])
	c["panes_showing"] = _flash.size()
	c["board"] = _board.text if _board != null else ""
	c["build_ms"] = _build_ms
	return c


func cell_point(c: int, r: int) -> Vector3:
	var m: Vector2 = cell_middle(Vector2i(c, r))
	return to_global(Vector3(m.x, 0, m.y))


func plate_point() -> Vector3:
	return to_global(Vector3(PLATE_AT.x, 0, PLATE_AT.y))


func local_point(x: float, z: float) -> Vector3:
	return to_global(Vector3(x, 0, z))
