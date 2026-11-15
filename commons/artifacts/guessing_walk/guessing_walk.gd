extends Node3D
## WHOSE EXPECTATION MEETS IT? (floor QFEP_F_Term; the pass, 2026-11-15)
##
## The hall: "Press EXPECT 0. Each amber underline marks a bit that refuses that guess ... The source is no more
## uncertain; this predictor is less suited to it." And at its end: "Here you can change the expectation with one
## button. Elsewhere a system might insist that the world change instead. Keep that difference with you." This is
## that study with a body for a predictor - a PLAYGROUND form.
##
## Twelve rows under card, two lanes. The south lane is EXPECT 0, the north lane EXPECT 1. A stand shows what the
## source gave before: forty-eight bits. Form an expectation from them, then walk. Each row is uncovered as you
## step into it: its bit lies in its own lane, and where you stood on the other one there is an amber bar - a bit
## that refused your guess. At the end the stand counts the misses.
##
## AGAIN covers the row and leaves it as it is. Walk it in the other lane: the same twelve bits, other misses. The
## row did not get easier; the expectation changed. The plates p 0.1, 0.5, 0.9 set the source: 0.1 and 0.9 are
## equally uncertain (H 0.47 bit) and ask for opposite lanes.
##
## And one plate does what the hall warns of: CHANGE THE WORLD INSTEAD. Every bit that refused you is rewritten to
## where you walked, and stamped. No misses. The stand says how many bits were changed, and that the row is no
## longer a sample of its source: it is a record of one walker.
##
## The row is the first twelve of the hall workbench's own stored draws (seed 1234, bit = draw < p), the evidence
## the next forty-eight. Nothing learns here but whoever walks. `source` is the axis: the p the walk starts with.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const SOURCE := {"tenth": 0.1, "half": 0.5, "nine_tenths": 0.9}
const N := 12
const ROW := 0.8                         # a row, along the walk (east)
const LANE := 1.2                        # a lane, across it
const X0 := -4.8
const SEED := 1234                       # the workbench's draw_seed
const EVIDENCE := 48
const PLATES := [
	{"key": "p1", "says": "p 0.1", "at": Vector2(-5.9, 2.2), "p": 0.1},
	{"key": "p5", "says": "p 0.5", "at": Vector2(-4.95, 2.2), "p": 0.5},
	{"key": "p9", "says": "p 0.9", "at": Vector2(-4.0, 2.2), "p": 0.9},
	{"key": "again", "says": "AGAIN", "at": Vector2(3.8, 2.2)},
	{"key": "change", "says": "CHANGE\nTHE WORLD\nINSTEAD", "at": Vector2(4.9, 2.2)},
]
const PLATE := 0.84
const COVER := Color("8d8172")
const ZERO := Color("27304a")            # the workbench's zero is near black; lifted here so that it shows on the dark strip
const ONE := Color("40f2ff")             # the workbench's one
const AMBER := Color("f2a23a")
const RED := Color("e01a29")
const DARK := Color("191e29")
const PALE := Color("efe9dc")

@export_enum("tenth", "half", "nine_tenths") var source := "nine_tenths"

var _city = City.new()
var _draws: Array[float] = []
var _p := 0.9
var _bits: Array[int] = []               # the row as it lies now
var _given: Array[int] = []              # the row as the source gave it
var _guess: Array[int] = []              # -1: still under card
var _changed: Array[bool] = []
var _walks: Array[int] = []              # misses of each finished walk of this row
var _counted := false
var _tiles := []                         # per row: [tile of lane 0, tile of lane 1]
var _bars: Array[MeshInstance3D] = []
var _stamps: Array[Label3D] = []
var _digits: Array[Label3D] = []
var _plate_tiles: Array[MeshInstance3D] = []
var _cells: Array[MeshInstance3D] = []
var _evidence_words: Label3D
var _source_words: Label3D
var _walk_words: Label3D
var _expect_words: Label3D
var _status: Label3D
var _board: Label3D
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_source"): _take({"source": get_meta("config_source")})
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for i in N + EVIDENCE: _draws.append(rng.randf())
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_set_source(float(SOURCE[source]))


func _take(config_data: Dictionary) -> void:
	if config_data.has("source") and SOURCE.has(str(config_data["source"])): source = str(config_data["source"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := source
	_take(config_data)
	if is_inside_tree() and _board != null and source != before: _set_source(float(SOURCE[source]))


## ---- the rule ----

## The hall workbench's own H(p) (shannon_workbench._binary_entropy).
static func entropy(p: float) -> float:
	if p <= 0.0 or p >= 1.0: return 0.0
	return -p * (log(p) / log(2.0)) - (1.0 - p) * (log(1.0 - p) / log(2.0))


func _set_source(p: float) -> void:
	_p = p
	_given.clear()
	for i in N: _given.append(1 if _draws[i] < _p else 0)
	_bits = _given.duplicate()
	_changed.clear()
	_changed.resize(N)
	_changed.fill(false)
	_walks.clear()
	_cover()


func _cover() -> void:
	_guess.clear()
	_guess.resize(N)
	_guess.fill(-1)
	_counted = false
	_show()
	_tell()


func stepped() -> int:
	return _guess.filter(func(g): return g >= 0).size()


func misses() -> int:
	var count := 0
	for i in N:
		if _guess[i] >= 0 and _guess[i] != _bits[i]: count += 1
	return count


func changed() -> int:
	return _changed.count(true)


func _step(row: int, lane: int) -> void:
	_guess[row] = lane
	if stepped() == N and not _counted:
		_counted = true
		_walks.append(misses())
		_tell()
	_show()


## What the hall warns of: the bits that refused the walker are rewritten to where the walker stood.
func _change_the_world() -> void:
	for i in N:
		if _guess[i] >= 0 and _guess[i] != _bits[i]:
			_bits[i] = _guess[i]
			_changed[i] = true
	_show()
	_tell()


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _physics_process(delta: float) -> void:
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var region := ""
	if absf(p.y) < 1.5:
		var row: int = int(floor((p.x - X0) / ROW))
		if row >= 0 and row < N and absf(p.z) < LANE:
			region = "row"
			if _guess[row] < 0: _step(row, 0 if p.z > 0.0 else 1)
		else:
			for plate in PLATES:
				var at: Vector2 = plate["at"]
				if absf(p.x - at.x) < PLATE * 0.5 and absf(p.z - at.y) < PLATE * 0.5: region = str(plate["key"])
	var moved: float = Vector2(p.x - _last.x, p.z - _last.z).length()
	_last = p
	if region != _region or moved > 0.3 * delta:
		_still = 0.0
	elif _still >= 0.0:
		_still += delta
	_region = region
	if _still >= 0.8 and region != "" and region != "row":
		_still = -99.0
		_press(region)


func _press(key: String) -> void:
	for plate in PLATES:
		if str(plate["key"]) != key: continue
		if plate.has("p"): _set_source(float(plate["p"]))
		elif key == "again": _cover()
		else: _change_the_world()


func _status_text() -> String:
	if changed() > 0:
		return "%d OF %d BITS WERE CHANGED TO FIT ONE WALKER.\nTHIS ROW IS NO LONGER A SAMPLE OF p %.1f." % [changed(), N, _p]
	if _walks.size() >= 2 and _walks[-1] < _walks[-2]:
		return "THE SAME TWELVE BITS. THE ROW DID NOT GET EASIER:\nYOUR EXPECTATION CHANGED."
	if _walks.size() >= 2 and _walks[-1] > _walks[-2]:
		return "THE SAME TWELVE BITS. THE ROW DID NOT GET HARDER:\nYOUR EXPECTATION CHANGED."
	return ""


func _show() -> void:
	for i in N:
		var open: bool = _guess[i] >= 0
		for lane in 2:
			var tile: MeshInstance3D = _tiles[i][lane]
			tile.visible = not open or lane == _bits[i]
			(tile.material_override as StandardMaterial3D).albedo_color = COVER if not open else (ONE if _bits[i] == 1 else ZERO)
		_digits[i].visible = open
		_digits[i].text = str(_bits[i])
		_digits[i].modulate = DARK if _bits[i] == 1 else PALE
		_digits[i].position.z = (0.5 if _bits[i] == 0 else -0.5) * LANE + 0.28
		_bars[i].visible = open and _guess[i] != _bits[i]
		if _bars[i].visible: _bars[i].position.z = (0.5 if _guess[i] == 0 else -0.5) * LANE
		_stamps[i].visible = open and _changed[i]
		if _stamps[i].visible: _stamps[i].position.z = (0.5 if _bits[i] == 0 else -0.5) * LANE
	var ones := 0
	for j in EVIDENCE:
		var bit: bool = _draws[N + j] < _p
		if bit: ones += 1
		(_cells[j].material_override as StandardMaterial3D).albedo_color = ONE if bit else ZERO
	_evidence_words.text = "WHAT THE SOURCE GAVE BEFORE:  %d ones in %d" % [ones, EVIDENCE]
	_source_words.text = "p(1) = %.1f
H = %.2f bit" % [_p, entropy(_p)]
	_walk_words.text = "this walk:  %d of %d rows,  %d missed" % [stepped(), N, misses()] + ("\nwalks of this row:  " + ", ".join(_walks.map(func(m): return str(m))) + " missed" if not _walks.is_empty() else "")
	_expect_words.text = "the south lane would expect %.1f misses,\nthe north lane %.1f. Counted, they need not agree." % [float(N) * _p, float(N) * (1.0 - _p)]
	_status.text = _status_text()
	_status.modulate = RED if changed() > 0 else AMBER
	for i in PLATES.size():
		var plate: Dictionary = PLATES[i]
		(_plate_tiles[i].material_override as StandardMaterial3D).albedo_color = Color("9fe6ee") if plate.has("p") and is_equal_approx(float(plate["p"]), _p) else PALE


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["WHOSE EXPECTATION MEETS IT?"])
	lines.append("Twelve bits lie under card. The south lane is EXPECT 0, the north lane EXPECT 1. The stand shows what this source gave before. Form an expectation, then walk: each row is uncovered as you step into it, and an amber bar marks a bit that refused your guess.")
	lines.append("AGAIN covers the same twelve bits. Walk the other lane and count again: the row did not change, the misses did. The plates set the source. p 0.1 and p 0.9 are equally uncertain, and ask for opposite lanes.")
	lines.append("CHANGE THE WORLD INSTEAD does what the hall warns of: every bit that refused you is rewritten to where you walked. No misses - and the row is no longer a sample of anything but you.")
	lines.append("The row is the first twelve of the workbench's own draws. Nothing here learns but you.")
	if not _walks.is_empty():
		lines.append("This row (p %.1f): %s missed%s." % [_p, ", ".join(_walks.map(func(m): return str(m))), ("; %d bits changed to fit" % changed()) if changed() > 0 else ""])
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


func _build_once() -> void:
	# the row: twelve rows, two lanes
	_box(self, Vector3(0, 0.006, 0), Vector3(float(N) * ROW + 0.12, 0.01, LANE * 2.0 + 0.12), _city.flat(DARK, 0.9))
	for i in N:
		var x: float = X0 + (float(i) + 0.5) * ROW
		var pair := []
		for lane in 2:
			pair.append(_box(self, Vector3(x, 0.016, (0.5 if lane == 0 else -0.5) * LANE), Vector3(ROW - 0.05, 0.02, LANE - 0.05), _city.flat(COVER, 0.9)))
		_tiles.append(pair)
		_bars.append(_box(self, Vector3(x, 0.03, 0), Vector3(ROW - 0.12, 0.02, 0.14), _plain(AMBER)))
		var stamp: Label3D = _city.floor_words(self, Vector3(x, 0.04, 0), "changed", 30, RED)
		stamp.rotation_degrees.y = 18.0
		_stamps.append(stamp)
		var digit: Label3D = _city.floor_words(self, Vector3(x, 0.04, 0), "", 70, PALE)
		digit.outline_size = 0
		_digits.append(digit)
		_city.floor_words(self, Vector3(x, 0.03, LANE + 0.22), str(i + 1), 32, PALE)
	_city.floor_words(self, Vector3(X0 - 1.0, 0.03, LANE * 0.5), "EXPECT 0  →", 50, PALE)
	_city.floor_words(self, Vector3(X0 - 1.0, 0.03, -LANE * 0.5), "EXPECT 1  →", 50, PALE)
	# the plates
	for plate in PLATES:
		var at: Vector2 = plate["at"]
		_plate_tiles.append(_box(self, Vector3(at.x, 0.012, at.y), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8)))
		var words: Label3D = _city.floor_words(self, Vector3(at.x, 0.035, at.y), str(plate["says"]), 50 if plate.has("p") else 26, RED if str(plate["key"]) == "change" else DARK)
		words.outline_size = 0
	# the stand on the north side: the evidence, and the count
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(0, 0, -LANE - 0.9)
	add_child(stand)
	var solid := StaticBody3D.new()
	stand.add_child(solid)
	_box(stand, Vector3(0, 1.55, -0.05), Vector3(3.3, 2.5, 0.06), _city.flat(DARK, 0.85))
	_city.wall(solid, Vector3(0, 0, -0.05), Vector3(3.3, 2.8, 0.12))
	for hand in [-1.0, 1.0]: _box(stand, Vector3(hand * 1.5, 0.15, -0.05), Vector3(0.08, 0.3, 0.08), _city.flat(DARK, 0.85))
	_evidence_words = _words(stand, Vector3(-0.78, 2.55, 0), 28, 0.003, PALE)
	for j in EVIDENCE:
		var cell: MeshInstance3D = _box(stand, Vector3(-1.34 + 0.16 * float(j % 8), 2.3 - 0.16 * float(j / 8), 0), Vector3(0.14, 0.14, 0.01), _plain(ZERO))
		_cells.append(cell)
	_source_words = _words(stand, Vector3(0.82, 2.38, 0), 46, 0.003, Color("9fe6ee"))
	_walk_words = _words(stand, Vector3(0.82, 1.86, 0), 27, 0.003, PALE)
	_expect_words = _words(stand, Vector3(0.82, 1.42, 0), 24, 0.003, Color("b9c0cc"))
	_status = _words(stand, Vector3(0, 0.82, 0), 34, 0.003, AMBER)
	_board = _city.board(self, Vector3(-6.2, 0, -1.9), 3.2, 1.7)


## ---- for a test ----

func state() -> Dictionary:
	var ones := 0
	for j in EVIDENCE:
		if _draws[N + j] < _p: ones += 1
	return {"source": source, "p": _p, "H": snappedf(entropy(_p), 0.0001), "bits": _bits.duplicate(), "given": _given.duplicate(), "guess": _guess.duplicate(), "stepped": stepped(), "misses": misses(), "walks": _walks.duplicate(), "changed": changed(),
		"expects": [snappedf(float(N) * _p, 0.01), snappedf(float(N) * (1.0 - _p), 0.01)], "evidence_ones": ones, "status": _status.text, "first_draws": _draws.slice(0, 4),
		"bars": _bars.filter(func(b): return b.visible).size(), "stamps": _stamps.filter(func(s): return s.visible).size(), "board": _board.text if _board != null else "", "build_ms": _build_ms}


## The middle of a row's tile in a lane (0 south, 1 north); row -1 and N are the places before and after the row.
func tile_point(row: int, lane: int) -> Vector3:
	return to_global(Vector3(X0 + (float(row) + 0.5) * ROW, 0, (0.5 if lane == 0 else -0.5) * LANE))


func plate_point(key: String) -> Vector3:
	for plate in PLATES:
		if str(plate["key"]) == key: return to_global(Vector3((plate["at"] as Vector2).x, 0, (plate["at"] as Vector2).y))
	return global_position
