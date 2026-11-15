extends Node3D
## A WEIGHT, A CHANGE, A PRODUCT (floor QFEP_Phi_Term; the pass, 2026-11-15)
##
## The hall: "A weight, a measured change and the resulting response are three separate quantities, even when a
## display uses one colour to connect them." "A positive weight does not make every change a positive
## contribution. A falling reading reverses the product's sign. Nor does the same difference tell us how quickly
## it occurred: that requires the interval between observations." "A snapshot loses that direction unless the
## representation preserves some history." And: "Does the upward movement feel different once it has been called
## an embrace?" This is those sentences with a body for the changing quantity - a PLAYGROUND form.
##
## A track five metres long. Where the visitor stands on it is a reading from 0 (west) to 1 (east), and it is
## looked at once a second. The stand keeps three numbers in three places: the weight phi, set by plates to -1, 0
## or +1 (it starts at 0, as the hall's rail does); the change since the last look; and their product, with an
## arrow up or down. Walk east: the reading rises. Walk back: it falls, and with a positive weight the product is
## negative. With a negative weight a falling reading gives a positive product - and the stand says the
## arithmetic does not say whether that is good.
##
## The last looks stay on the track as dots: a slow walk leaves them close, a fast one far apart, over the same
## stretch. SNAPSHOT keeps only the latest look: then there is no change to show, at any weight. EARLIER LABELS
## puts RESIST and EMBRACE over the two signs. Nothing else changes.
##
## It measures nothing: the reading is where a body stands. `labels` is the axis: hidden, shown.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const HALF := 2.6                        # half the track's length
const LANE := 0.7
const INTERVAL := 1.0                    # seconds between looks
const KEPT := 8
const NONE := -99.0
const PLATES := [
	{"key": "minus", "says": "φ −1", "at": Vector2(-2.2, 1.75), "phi": -1.0},
	{"key": "zero", "says": "φ 0", "at": Vector2(-1.1, 1.75), "phi": 0.0},
	{"key": "plus", "says": "φ +1", "at": Vector2(0.0, 1.75), "phi": 1.0},
	{"key": "labels", "says": "EARLIER\nLABELS", "at": Vector2(1.1, 1.75)},
	{"key": "history", "says": "SNAPSHOT\n/ HISTORY", "at": Vector2(2.2, 1.75)},
]
const PLATE := 0.84
const DARK := Color("191e29")
const PALE := Color("efe9dc")
const UP := Color("f2a23a")
const DOWN := Color("6fa8ff")
const LOOK := Color("40f2ff")

@export_enum("hidden", "shown") var labels := "hidden"

var _city = City.new()
var _phi := 0.0
var _history := true
var _looks: Array[float] = []            # the readings at the last looks, oldest first
var _look_n := 0
var _clock := 0.0
var _on := false
var _reading := NONE
var _dots: Array[MeshInstance3D] = []
var _plate_tiles: Array[MeshInstance3D] = []
var _weight: Label3D
var _weight_word: Label3D
var _change: Label3D
var _product: Label3D
var _arrow_up: MeshInstance3D
var _arrow_down: MeshInstance3D
var _status: Label3D
var _floor_words: Array[Label3D] = []
var _board: Label3D
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_labels"): _take({"labels": get_meta("config_labels")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_show()
	_tell()


func _take(config_data: Dictionary) -> void:
	if config_data.has("labels") and str(config_data["labels"]) in ["hidden", "shown"]: labels = str(config_data["labels"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := labels
	_take(config_data)
	if is_inside_tree() and _board != null and labels != before: _show()


## ---- the rule ----

## The change between the last two looks, or NONE when there are not two (or only a snapshot is kept).
func change() -> float:
	if not _history or _looks.size() < 2: return NONE
	return _looks[-1] - _looks[-2]


## The hall's product: the weight times the change.
static func product(phi: float, delta: float) -> float:
	return phi * delta


static func says(phi: float, delta: float) -> String:
	if is_equal_approx(delta, NONE): return "ONE LOOK HAS NO CHANGE IN IT."
	if absf(delta) < 0.005: return "NO CHANGE SINCE THE LAST LOOK:\nTHE PRODUCT IS ZERO AT ANY WEIGHT."
	if is_zero_approx(phi): return "ZERO WEIGHT: THE CHANGE IS THERE,\nAND NOTHING IS MADE OF IT."
	if phi > 0.0 and delta > 0.0: return "POSITIVE WEIGHT, RISING READING:\nA POSITIVE PRODUCT."
	if phi > 0.0: return "POSITIVE WEIGHT, FALLING READING:\nTHE PRODUCT IS NEGATIVE."
	if delta > 0.0: return "NEGATIVE WEIGHT, RISING READING:\nTHE PRODUCT IS NEGATIVE."
	return "NEGATIVE TIMES NEGATIVE IS POSITIVE.\nWHETHER THAT IS GOOD, THE ARITHMETIC DOES NOT SAY."


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _physics_process(delta: float) -> void:
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var region := ""
	if absf(p.y) < 1.5:
		if absf(p.x) <= HALF and absf(p.z) <= LANE: region = "track"
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
	var now_on: bool = region == "track"
	if now_on:
		_reading = (p.x + HALF) / (HALF * 2.0)
		if not _on:
			_looks.clear()                      # a look made before the visitor left is not 'the last look' now
			_clock = INTERVAL                   # and the first look is made on stepping on
		_clock += delta
		if _clock >= INTERVAL:
			_clock -= INTERVAL
			_looks.append(_reading)
			if _looks.size() > KEPT: _looks.pop_front()
			_look_n += 1
			_show()
	elif _on:
		_reading = NONE
		_show()
	_on = now_on
	if _still >= 0.8 and region != "" and region != "track":
		_still = -99.0
		_press(region)


func _press(key: String) -> void:
	for plate in PLATES:
		if str(plate["key"]) != key: continue
		if plate.has("phi"): _phi = float(plate["phi"])
		elif key == "labels": labels = "hidden" if labels == "shown" else "shown"
		else: _history = not _history
	_show()
	_tell()


static func _signed(v: float) -> String:
	if absf(v) < 0.005: return "0.00"
	return ("+%.2f" if v > 0.0 else "−%.2f") % absf(v)


func _show() -> void:
	var delta: float = change()
	var named: bool = labels == "shown"
	_weight.text = "0" if is_zero_approx(_phi) else ("+1" if _phi > 0.0 else "−1")
	_weight_word.text = ("EMBRACE" if _phi > 0.0 else ("RESIST" if _phi < 0.0 else "")) if named else ""
	_change.text = "—" if is_equal_approx(delta, NONE) else _signed(delta)
	var out: float = NONE if is_equal_approx(delta, NONE) else product(_phi, delta)
	_product.text = "—" if is_equal_approx(out, NONE) else _signed(out)
	_arrow_up.visible = not is_equal_approx(out, NONE) and out > 0.005
	_arrow_down.visible = not is_equal_approx(out, NONE) and out < -0.005
	_status.text = "WALK ALONG THE TRACK.\nIT IS LOOKED AT ONCE A SECOND." if _looks.is_empty() else says(_phi, delta)
	for i in _dots.size():
		var k: int = _looks.size() - 1 - i          # 0: the latest look
		var seen: bool = k >= 0 and (_history or i == 0)
		_dots[i].visible = seen
		if seen:
			_dots[i].position.x = _looks[k] * HALF * 2.0 - HALF
			(_dots[i].material_override as StandardMaterial3D).albedo_color = LOOK.lerp(Color("2b3a4a"), float(i) / float(KEPT))
	for word in _floor_words: word.visible = named
	for i in PLATES.size():
		var plate: Dictionary = PLATES[i]
		var lit: bool = (plate.has("phi") and is_equal_approx(float(plate["phi"]), _phi)) or (str(plate["key"]) == "labels" and named) or (str(plate["key"]) == "history" and not _history)
		(_plate_tiles[i].material_override as StandardMaterial3D).albedo_color = Color("f6e39a") if lit else PALE


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["A WEIGHT, A CHANGE, A PRODUCT"])
	lines.append("Where you stand on the track is a reading, from 0 at this end to 1 at the far end. It is looked at once a second. The stand keeps three numbers apart: the weight φ, the change since the last look, and their product.")
	lines.append("The plates set the weight. It starts at 0: then whatever you do, nothing is made of it. With +1, walk east and then back: a falling reading makes the product negative. With −1, fall again.")
	lines.append("The looks stay on the track as dots. Walk the same stretch slowly, then fast: the same difference, more looks. SNAPSHOT keeps only the latest: one look has no change in it.")
	lines.append("EARLIER LABELS puts RESIST and EMBRACE over the two signs. Nothing else changes. It measures nothing: the reading is where you stand.")
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
	# the track
	_box(self, Vector3(0, 0.008, 0), Vector3(HALF * 2.0 + 0.12, 0.014, LANE * 2.0 + 0.12), _city.flat(DARK, 0.9))
	_box(self, Vector3(0, 0.016, 0), Vector3(HALF * 2.0, 0.008, LANE * 2.0), _city.flat(Color("3b4254"), 0.9))
	for i in 5:
		var x: float = -HALF + float(i) * HALF * 0.5
		_box(self, Vector3(x, 0.022, 0), Vector3(0.04, 0.006, LANE * 2.0), _plain(PALE))
		_city.floor_words(self, Vector3(x, 0.03, LANE + 0.24), ["0", "¼", "½", "¾", "1"][i], 40, PALE)
	_city.floor_words(self, Vector3(0, 0.03, -LANE - 0.26), "the reading rises to the east  →", 30, PALE)
	for i in KEPT:
		var dot := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.11
		disc.bottom_radius = 0.11
		disc.height = 0.012
		dot.mesh = disc
		dot.material_override = _plain(LOOK)
		dot.position = Vector3(0, 0.03, -LANE + 0.2)
		dot.visible = false
		dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(dot)
		_dots.append(dot)
	# the plates
	for plate in PLATES:
		var at: Vector2 = plate["at"]
		_plate_tiles.append(_box(self, Vector3(at.x, 0.012, at.y), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8)))
		_city.floor_words(self, Vector3(at.x, 0.035, at.y), str(plate["says"]), 46 if plate.has("phi") else 26, DARK).outline_size = 0
	_floor_words.append(_city.floor_words(self, Vector3(-2.2, 0.035, 1.05), "RESIST", 40, PALE))
	_floor_words.append(_city.floor_words(self, Vector3(0.0, 0.035, 1.05), "EMBRACE", 40, PALE))
	# the stand: three numbers in three places
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(0, 0, -2.0)
	add_child(stand)
	var solid := StaticBody3D.new()
	stand.add_child(solid)
	_box(stand, Vector3(0, 1.6, -0.05), Vector3(4.3, 2.6, 0.06), _city.flat(DARK, 0.85))
	_city.wall(solid, Vector3(0, 0, -0.05), Vector3(4.3, 2.95, 0.12))
	for hand in [-1.0, 1.0]: _box(stand, Vector3(hand * 2.0, 0.15, -0.05), Vector3(0.08, 0.3, 0.08), _city.flat(DARK, 0.85))
	for i in 2: _box(stand, Vector3(-0.7 + 1.4 * float(i), 2.0, 0.0), Vector3(0.012, 1.3, 0.01), _plain(Color("5b6274")))
	var captions := [["THE WEIGHT  φ", "set by a plate"], ["THE CHANGE", "since the last look, 1 s ago"], ["THE PRODUCT", "weight × change"]]
	for i in 3:
		var x: float = -1.4 + 1.4 * float(i)
		_words(stand, Vector3(x, 2.68, 0), 30, 0.003, PALE).text = str(captions[i][0])
		_words(stand, Vector3(x, 1.52, 0), 22, 0.003, Color("b9c0cc")).text = str(captions[i][1])
	_weight = _words(stand, Vector3(-1.4, 2.12, 0), 170, 0.0032, PALE)
	_weight_word = _words(stand, Vector3(-1.4, 1.3, 0), 40, 0.003, Color("f6e39a"))
	_change = _words(stand, Vector3(0.0, 2.12, 0), 120, 0.0032, LOOK)
	_product = _words(stand, Vector3(1.25, 2.12, 0), 120, 0.0032, PALE)
	var prism := PrismMesh.new()
	prism.size = Vector3(0.26, 0.3, 0.02)
	_arrow_up = MeshInstance3D.new()
	_arrow_up.mesh = prism
	_arrow_up.material_override = _plain(UP)
	_arrow_up.position = Vector3(1.92, 2.14, 0.012)
	stand.add_child(_arrow_up)
	_arrow_down = MeshInstance3D.new()
	_arrow_down.mesh = prism
	_arrow_down.material_override = _plain(DOWN)
	_arrow_down.position = Vector3(1.92, 2.1, 0.012)
	_arrow_down.rotation.z = PI
	stand.add_child(_arrow_down)
	_status = _words(stand, Vector3(0, 0.95, 0), 32, 0.003, Color("f6e39a"))
	_words(stand, Vector3(0, 0.5, 0), 22, 0.003, Color("b9c0cc")).text = "It measures nothing: the reading is where you stand."
	_board = _city.board(self, Vector3(-3.5, 0, -0.2), 3.2, 1.6)
	(_board.get_parent().get_parent() as Node3D).rotation.y = -PI * 0.5       # turned west, to whoever comes from the arrival


## ---- for a test ----

func state() -> Dictionary:
	var delta: float = change()
	return {"phi": _phi, "labels": labels, "history": _history, "on_track": _on, "reading": snappedf(_reading, 0.001), "change": snappedf(delta, 0.001), "product": snappedf(product(_phi, delta), 0.001) if not is_equal_approx(delta, NONE) else NONE,
		"looks": _looks.duplicate(), "look_n": _look_n, "dots": _dots.filter(func(d): return d.visible).size(), "status": _status.text, "weight_word": _weight_word.text, "shown": [_weight.text, _change.text, _product.text],
		"arrow": "up" if _arrow_up.visible else ("down" if _arrow_down.visible else "none"), "floor_words": _floor_words.filter(func(w): return w.visible).size(), "board": _board.text if _board != null else "", "build_ms": _build_ms}


## A place on the track's middle line at a reading (0 west, 1 east); beyond 0..1 is off its ends.
func track_point(reading: float) -> Vector3:
	return to_global(Vector3(reading * HALF * 2.0 - HALF, 0, 0))


func plate_point(key: String) -> Vector3:
	for plate in PLATES:
		if str(plate["key"]) == key: return to_global(Vector3((plate["at"] as Vector2).x, 0, (plate["at"] as Vector2).y))
	return global_position
