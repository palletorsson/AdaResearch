extends Node3D
## TWO REPORTS (floor SpeculativeComputation_Paraconsistent_Engineering; the pass, 2026-11-16)
##
## The hall, of its two branches: "Must one account disappear before two accounts can share a system?" "One report
## says a door is open; another says it is closed. Adding times may reconcile the reports. Adding the door's
## identity may reveal that they concern different doors." "In a paraconsistent logic, a contradiction need not
## license an arbitrary conclusion. It does not mean accepting every claim." "The next useful addition would expose
## a small rule table: after entering both a proposition and its negation, which consequences remain available,
## and which unrelated conclusion still cannot be derived?" This is that rule table - a ROBOT STATION form.
##
## Two report slips: A, the door is open; B, the door is closed. Two reasoners stand at the back and are told what
## the visitor tells them (TELL A, TELL B; standing on a plate again takes the report back). CLASSICAL: every
## statement is true or false. PARACONSISTENT (the Logic of Paradox): a statement may be true, false or both.
## Each answers seven questions with a lamp: does this follow from what I was told?
##
## Tell both. The classical reasoner lights every row, the lamp on the post between the doors among them - on, and
## off - though nobody reported on the lamp. The paraconsistent one keeps both reports and lights four rows; the
## lamp is not among them. It pays for that: the last row (from 'A or B' and 'not A', B) no longer follows there.
##
## And there are two doors on this floor: one stands open, one is shut. WHERE FROM? gives each report its source,
## its hour and its door. Then they are about different doors, and neither reasoner has a contradiction.
##
## `told` is the axis: nothing, one, both. The same table is benched in tools/probes/two_reports_bench.py.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const ROW_Z := 1.2                        # the doors and the slips
const CABINET_Z := -4.2
const LAMP := Vector2(0.0, -1.4)
const DOOR_X := 2.7
const TOLD := {"nothing": [false, false], "one": [true, false], "both": [true, true]}
const PLATES := [
	{"key": "a", "says": "TELL A", "x": -1.3},
	{"key": "from", "says": "WHERE\nFROM?", "x": 0.0},
	{"key": "b", "says": "TELL B", "x": 1.3},
]
const PLATE_Z := 3.6
const PLATE := 0.84
const CARD := Color("c4a070")
const DARK := Color("191e29")
const PALE := Color("efe9dc")
const YES := Color("6ff08a")
const BOOM := Color("ff5a3c")
const OFF := Color("3a4050")

@export_enum("nothing", "one", "both") var told := "nothing"

var _city = City.new()
var _told := [false, false]
var _sourced := false
var _slips: Array[Label3D] = []
var _slip_cards: Array[MeshInstance3D] = []
var _names: Array[Label3D] = []           # the boards over the two doors
var _rows := []                           # [cabinet][row] {lamp: MeshInstance3D, text: Label3D}
var _foots: Array[Label3D] = []
var _bulb: MeshInstance3D
var _bulb_says: Label3D
var _plate_tiles: Array[MeshInstance3D] = []
var _board: Label3D
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_told"): _take({"told": get_meta("config_told")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_found()


func _take(config_data: Dictionary) -> void:
	if config_data.has("told") and TOLD.has(str(config_data["told"])): told = str(config_data["told"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := told
	_take(config_data)
	if is_inside_tree() and _board != null and told != before: _found()


func _found() -> void:
	_told = (TOLD[told] as Array).duplicate()
	_sourced = false
	_show()
	_tell()


## ---- the rule ----

## A statement's value in a case: 0 false, 1 both, 2 true. A statement is a name, or ["not", s], ["and", s, t], ["or", s, t].
static func value(statement: Variant, case: Dictionary) -> int:
	if statement is String: return int(case[statement])
	var parts: Array = statement
	match str(parts[0]):
		"not": return 2 - value(parts[1], case)
		"and": return mini(value(parts[1], case), value(parts[2], case))
	return maxi(value(parts[1], case), value(parts[2], case))


static func _names_in(statement: Variant, into: Array) -> void:
	if statement is String:
		if not into.has(statement): into.append(statement)
		return
	var parts: Array = statement
	for i in range(1, parts.size()): _names_in(parts[i], into)


## Does the conclusion hold (true, or both) in every case where everything told holds? `both_allowed`: the
## paraconsistent reasoner's third value; without it, the classical one's two.
static func follows(told_things: Array, conclusion: Variant, both_allowed: bool) -> bool:
	var names: Array = []
	for thing in told_things: _names_in(thing, names)
	_names_in(conclusion, names)
	var values: Array = [0, 1, 2] if both_allowed else [0, 2]
	var cases: int = int(pow(values.size(), names.size()))
	for n in cases:
		var case := {}
		var rest: int = n
		for name in names:
			case[name] = values[rest % values.size()]
			rest /= values.size()
		var holds := true
		for thing in told_things:
			if value(thing, case) < 1: holds = false
		if holds and value(conclusion, case) < 1: return false
	return true


## What has been told, and the seven questions, as statements. With sources the two reports name two doors.
func _statements() -> Dictionary:
	var a: String = "W" if _sourced else "P"
	var b: String = "E" if _sourced else "P"
	var premises: Array = []
	if _told[0]: premises.append(a)
	if _told[1]: premises.append(["not", b])
	return {"told": premises, "asked": [a, ["not", b], ["and", a, ["not", a]], ["or", a, "Q"], "Q", ["not", "Q"]], "also": ["or", b, "Q"]}


## Seven answers of one reasoner.
func answers(both_allowed: bool) -> Array:
	var s: Dictionary = _statements()
	var out: Array = []
	for asked in s["asked"]: out.append(follows(s["told"], asked, both_allowed))
	out.append(follows((s["told"] as Array) + [s["also"]], "Q", both_allowed))
	return out


func _row_texts() -> Array:
	var west: String = "the west door" if _sourced else "the door"
	var east: String = "the east door" if _sourced else "the door"
	return ["%s is open" % west, "%s is closed" % east, "%s is open and closed" % west, "%s is open, or the lamp is on" % west, "the lamp is on", "the lamp is off",
		"and told '%s open, or lamp on':  the lamp is on" % ("east door" if _sourced else "door")]


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _physics_process(delta: float) -> void:
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var region := ""
	if absf(p.y) < 1.5:
		for plate in PLATES:
			if absf(p.x - float(plate["x"])) < PLATE * 0.5 and absf(p.z - PLATE_Z) < PLATE * 0.5: region = str(plate["key"])
	var moved: float = Vector2(p.x - _last.x, p.z - _last.z).length()
	_last = p
	if region != _region or moved > 0.3 * delta:
		_still = 0.0
	elif _still >= 0.0:
		_still += delta
	_region = region
	if _still >= 0.8 and region != "":
		_still = -99.0
		match region:
			"a": _told[0] = not _told[0]
			"b": _told[1] = not _told[1]
			"from": _sourced = not _sourced
		_show()
		_tell()


func _foot(both_allowed: bool, got: Array) -> String:
	var count: int = got.count(true)
	var both: bool = _told[0] and _told[1]
	if not _told[0] and not _told[1]: return "TOLD NOTHING. NOTHING FOLLOWS."
	if both and _sourced: return "TWO REPORTS ABOUT TWO DOORS. NO CONTRADICTION.\n%d FOLLOW." % count
	if both and not both_allowed: return "EXPLOSION: ALL SEVEN FOLLOW,\nAND ANYTHING ELSE WOULD."
	if both: return "BOTH REPORTS KEPT. %d FOLLOW.\nTHE LAMP IS NOT AMONG THEM." % count
	if both_allowed and _told[1]: return "ONE REPORT. %d FOLLOWS.\nTHE PRICE: THE LAST ROW DOES NOT FOLLOW HERE." % count
	return "ONE REPORT. %d FOLLOW." % count


func lamp_lit() -> bool:
	return answers(false)[4]


func _show() -> void:
	var texts: Array = _row_texts()
	for c in 2:
		var got: Array = answers(c == 1)
		var boom: bool = c == 0 and _told[0] and _told[1] and not _sourced
		for r in 7:
			var row: Dictionary = _rows[c][r]
			(row["text"] as Label3D).text = str(texts[r])
			(row["text"] as Label3D).modulate = PALE if got[r] else Color("8a90a0")
			((row["lamp"] as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = (BOOM if boom else YES) if got[r] else OFF
		_foots[c].text = _foot(c == 1, got)
		_foots[c].modulate = BOOM if boom else Color("f2a23a")
	_slips[0].text = "REPORT A\nthe WEST door is open\nnight porter  ·  21:40" if _sourced else "REPORT A\nthe door is open"
	_slips[1].text = "REPORT B\nthe EAST door is closed\ncleaner  ·  06:10" if _sourced else "REPORT B\nthe door is closed"
	for i in 2: (_slip_cards[i].material_override as StandardMaterial3D).albedo_color = Color("f6e39a") if _told[i] else PALE
	_names[0].text = "THE WEST DOOR" if _sourced else "A DOOR"
	_names[1].text = "THE EAST DOOR" if _sourced else "A DOOR"
	var lit: bool = lamp_lit()
	(_bulb.material_override as StandardMaterial3D).albedo_color = Color("fff2a0") if lit else Color("2a2e3a")
	_bulb_says.text = "THE CLASSICAL REASONER:\nTHE LAMP IS ON. AND OFF." if lit else "a lamp.\nnobody reported on it."
	_bulb_says.modulate = BOOM if lit else PALE
	for i in PLATES.size():
		var key: String = str(PLATES[i]["key"])
		var lit_plate: bool = (key == "a" and _told[0]) or (key == "b" and _told[1]) or (key == "from" and _sourced)
		(_plate_tiles[i].material_override as StandardMaterial3D).albedo_color = Color("f6e39a") if lit_plate else PALE


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["TWO REPORTS"])
	lines.append("Report A: the door is open. Report B: the door is closed. Two reasoners stand at the back. Stand on TELL A, then TELL B: each lights a lamp beside whatever follows from what it was told. Stand on a plate again to take a report back.")
	lines.append("CLASSICAL holds every statement true or false. Told both, it lights everything: the lamp on the post is on, and off, though nobody reported on it. PARACONSISTENT lets a statement be both. It keeps the two reports, and the lamp does not follow. It pays: the last row is a rule it gave up.")
	lines.append("Now look at the doors. One stands open; one is shut. WHERE FROM? gives each report its source, its hour and its door. Neither account had to disappear. Neither reasoner has a contradiction left.")
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


## A door: a timber frame, a cardboard leaf that is a body, a name over it. `open`: the leaf stands swung north.
func _door(x: float, open: bool) -> void:
	var wood: StandardMaterial3D = _city.flat(Color("6b4a32"), 0.9)
	var held := StaticBody3D.new()
	add_child(held)
	for hand in [-1.0, 1.0]:
		_box(self, Vector3(x + hand * 0.55, 1.05, ROW_Z), Vector3(0.1, 2.1, 0.1), wood)
		_city.wall(held, Vector3(x + hand * 0.55, 0, ROW_Z), Vector3(0.1, 2.1, 0.1))
	_box(self, Vector3(x, 2.15, ROW_Z), Vector3(1.2, 0.1, 0.1), wood)
	var hinge := Node3D.new()
	hinge.position = Vector3(x - 0.5, 0, ROW_Z)
	hinge.rotation.y = deg_to_rad(85.0) if open else 0.0
	add_child(hinge)
	var leaf := StaticBody3D.new()
	hinge.add_child(leaf)
	_box(leaf, Vector3(0.5, 1.02, 0), Vector3(0.98, 2.0, 0.05), _city.flat(CARD, 0.95))
	_city.wall(leaf, Vector3(0.5, 0, 0), Vector3(0.98, 2.0, 0.06))
	_box(self, Vector3(x, 2.5, ROW_Z), Vector3(1.5, 0.34, 0.04), _city.flat(DARK, 0.85))
	var name_board: Label3D = _words(self, Vector3(x, 2.5, ROW_Z + 0.03), 36, 0.004, PALE)
	_names.append(name_board)


func _build_once() -> void:
	# the two doors: one stands open, one is shut
	_door(-DOOR_X, true)
	_door(DOOR_X, false)
	# the two report slips, on posts
	var wood: StandardMaterial3D = _city.flat(Color("6b4a32"), 0.9)
	var held := StaticBody3D.new()
	add_child(held)
	for i in 2:
		var x: float = -1.0 if i == 0 else 1.0
		_box(self, Vector3(x, 0.42, ROW_Z - 0.04), Vector3(0.07, 0.84, 0.07), wood)
		_city.wall(held, Vector3(x, 0, ROW_Z - 0.04), Vector3(0.9, 1.5, 0.08))
		_slip_cards.append(_box(self, Vector3(x, 1.14, ROW_Z), Vector3(0.9, 0.62, 0.03), _city.flat(PALE, 0.9)))
		_slips.append(_words(self, Vector3(x, 1.14, ROW_Z + 0.02), 30, 0.003, DARK))
	# the lamp nobody reported on
	_box(self, Vector3(LAMP.x, 0.75, LAMP.y), Vector3(0.07, 1.5, 0.07), _city.flat(DARK, 0.8))
	_city.wall(held, Vector3(LAMP.x, 0, LAMP.y), Vector3(0.12, 1.7, 0.12))
	_bulb = MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.2
	ball.height = 0.4
	_bulb.mesh = ball
	_bulb.material_override = _plain(Color("2a2e3a"))
	_bulb.position = Vector3(LAMP.x, 1.68, LAMP.y)
	add_child(_bulb)
	_bulb_says = _city.floor_words(self, Vector3(LAMP.x, 0.03, LAMP.y + 0.7), "", 40, PALE)
	# the two reasoners: seven questions each, a lamp beside each answer
	var heads := ["CLASSICAL", "PARACONSISTENT"]
	var notes := ["every statement is true or false", "a statement may be true, false, or both"]
	for c in 2:
		var cabinet := Node3D.new()
		cabinet.name = heads[c].capitalize()
		cabinet.position = Vector3(-1.75 if c == 0 else 1.75, 0, CABINET_Z)
		add_child(cabinet)
		var solid := StaticBody3D.new()
		cabinet.add_child(solid)
		_box(cabinet, Vector3(0, 2.9, -0.05), Vector3(3.4, 3.1, 0.06), _city.flat(DARK, 0.85))
		_city.wall(solid, Vector3(0, 0, -0.05), Vector3(3.4, 4.45, 0.12))
		for hand in [-1.0, 1.0]: _box(cabinet, Vector3(hand * 1.55, 0.68, -0.05), Vector3(0.08, 1.36, 0.08), _city.flat(DARK, 0.85))
		_words(cabinet, Vector3(0, 4.14, 0), 40, 0.0055, PALE).text = heads[c]
		_words(cabinet, Vector3(0, 3.86, 0), 22, 0.0055, Color("b9c0cc")).text = notes[c]
		var rows := []
		for r in 7:
			var y: float = 3.5 - 0.27 * float(r)
			var lamp := MeshInstance3D.new()
			var disc := CylinderMesh.new()
			disc.top_radius = 0.095
			disc.bottom_radius = 0.095
			disc.height = 0.02
			lamp.mesh = disc
			lamp.material_override = _plain(OFF)
			lamp.rotation.x = PI * 0.5
			lamp.position = Vector3(-1.52, y, 0.0)
			cabinet.add_child(lamp)
			var text: Label3D = _words(cabinet, Vector3(-1.36, y, 0), 22 if r == 6 else 26, 0.0055, PALE)
			text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			rows.append({"lamp": lamp, "text": text})
		_rows.append(rows)
		_foots.append(_words(cabinet, Vector3(0, 1.62, 0), 20, 0.0055, Color("f2a23a")))
	# the plates
	for plate in PLATES:
		_plate_tiles.append(_box(self, Vector3(float(plate["x"]), 0.012, PLATE_Z), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8)))
		_city.floor_words(self, Vector3(float(plate["x"]), 0.035, PLATE_Z), str(plate["says"]), 52, DARK).outline_size = 0
	_board = _city.board(self, Vector3(0.0, 0, 6.0), 3.2, 1.7)


## ---- for a test ----

func state() -> Dictionary:
	var classical: Array = answers(false)
	var para: Array = answers(true)
	return {"told": _told.duplicate(), "sourced": _sourced, "classical": classical, "paraconsistent": para, "classical_count": classical.count(true), "paraconsistent_count": para.count(true), "lamp_lit": lamp_lit(),
		"feet": _foots.map(func(l): return l.text), "slips": _slips.map(func(l): return l.text), "door_names": _names.map(func(l): return l.text), "rows": _row_texts(),
		"board": _board.text if _board != null else "", "build_ms": _build_ms}


func plate_point(key: String) -> Vector3:
	for plate in PLATES:
		if str(plate["key"]) == key: return to_global(Vector3(float(plate["x"]), 0, PLATE_Z))
	return global_position


## A place on the line through the middle of a door: `south` metres on the plates' side of it (negative: beyond).
func door_point(west: bool, south: float) -> Vector3:
	return to_global(Vector3(-DOOR_X if west else DOOR_X, 0, ROW_Z + south))


func local_point(x: float, z: float) -> Vector3:
	return to_global(Vector3(x, 0, z))
