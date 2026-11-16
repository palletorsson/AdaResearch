extends Node3D
## ROOM TO TELL APART (floor CriticalAlgorithms_Algorithmic_Bias_Visualization; the pass, 2026-11-16)
##
## The hall, of its table of words: "The warm group compresses into a smaller region while the grey group spreads
## and moves away. The words themselves remain." "Presence in a representation is therefore different from being
## represented with useful distinctions." "The handle changes the represented geometry. Moving your head gives you
## another view of it. Those are two different changes." "Both groups were chosen." "Choose one distinction within
## a colour that you want the representation to retain." This is that operation at the size of a body - a
## PLAYGROUND form.
##
## Twenty-four posts in two fields of twelve; a band on each, warm or grey; a number and no word. A rail: walk
## along it and the warm twelve are pressed toward one place while the grey twelve spread. A stand counts three
## things for each colour: how many are PRESENT (always twelve), how many have ROOM ROUND THEM (a body's width to
## the nearest other post), and how many are HIDDEN behind another FROM WHERE YOU STAND. The rail changes the
## second. Your feet change the third. Nothing changes the first.
##
## Open, a body walks between the warm posts. Pressed, they are one thing to walk round. Stand still between two
## warm posts while the field is open and that pair is KEPT: a red tape, and those two stay where they were when
## the rest are pressed. LET GO releases them. OTHER GROUPING makes another twelve warm: someone chose both.
##
## `pressed` is the axis: open, half, pressed - where the rail is found. The same arithmetic is benched in
## tools/probes/room_to_tell_apart_bench.py.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const SPACING := 0.95
const POST := 0.14
const TALL := 1.3
const ROOM := 0.64                       # a body's width clear (0.5 m) between two posts, centre to centre
const TIGHT := 0.22
const LOOSE := 1.4
const FIELD := Vector2(2.3, -0.3)
const CLUMP := {"A": Vector2(-0.5, -0.3), "B": Vector2(0.0, 0.65)}
const HALF := 2.5                        # half the rail's length
const LANE := 0.5
const RAIL_Z := 2.8
const PRESSED := {"open": 0.0, "half": 0.5, "pressed": 1.0}
const PLATES := [
	{"key": "letgo", "says": "LET GO", "x": -3.6},
	{"key": "grouping", "says": "OTHER\nGROUPING", "x": 3.6},
]
const PLATE := 0.84
const CARD := Color("c4a070")
const DARK := Color("191e29")
const PALE := Color("efe9dc")
const WARM := Color(0.92, 0.32, 0.58)
const GREY := Color(0.55, 0.6, 0.68)
const TAPE := Color("d8262c")

@export_enum("open", "half", "pressed") var pressed := "open"

var _city = City.new()
var _c := 0.0                            # how far the rail has pressed: 0 open, 1 pressed
var _grouping := "A"
var _kept: Array[int] = []               # two warm posts that stay where they were
var _homes: Array[Vector2] = []
var _now: Array[Vector2] = []            # where each post stands this tick
var _posts: Array[StaticBody3D] = []
var _bands: Array[MeshInstance3D] = []
var _numbers: Array[Label3D] = []
var _warm_paint: StandardMaterial3D
var _grey_paint: StandardMaterial3D
var _tape: MeshInstance3D
var _puck: MeshInstance3D
var _plate_tiles: Array[MeshInstance3D] = []
var _cells := []                         # [row][column] Label3D
var _status: Label3D
var _foot: Label3D
var _board: Label3D
var _hidden := [0, 0]
var _settled := true
var _look := 0.0
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_pressed"): _take({"pressed": get_meta("config_pressed")})
	for i in 24: _homes.append(home(i))
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_found()


func _take(config_data: Dictionary) -> void:
	if config_data.has("pressed") and PRESSED.has(str(config_data["pressed"])): pressed = str(config_data["pressed"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := pressed
	_take(config_data)
	if is_inside_tree() and _board != null and pressed != before: _found()


func _found() -> void:
	_c = float(PRESSED[pressed])
	_grouping = "A"
	_kept.clear()
	_now = places(_grouping, _c, _kept)
	for i in 24: _posts[i].position = Vector3(_now[i].x, 0, _now[i].y)
	_settled = true
	_paint()
	_show()
	_tell()


## ---- the rule ----

## Where post i was put: two fields of three columns and four rows, each post a little off its place.
static func home(i: int) -> Vector2:
	var j: int = i % 12
	var x: float = (-FIELD.x if i < 12 else FIELD.x) + float(j % 3 - 1) * SPACING + 0.12 * sin(2.4 * float(i) + 0.7)
	var z: float = FIELD.y + (float(j / 3) - 1.5) * SPACING + 0.12 * cos(3.7 * float(i) + 1.9)
	return Vector2(x, z)


## Which twelve are warm. A: the west field. B: the two south rows of both fields. Someone chose each.
static func is_warm(i: int, grouping: String) -> bool:
	return i < 12 if grouping == "A" else (i % 12) / 3 >= 2


## Where all twenty-four stand when the rail has pressed by c: the warm twelve drawn toward one place, to TIGHT of
## their spread; the grey twelve spread to LOOSE of theirs; a kept post where it was.
static func places(grouping: String, c: float, kept: Array[int]) -> Array[Vector2]:
	var cw := Vector2.ZERO
	var cg := Vector2.ZERO
	for i in 24:
		if is_warm(i, grouping): cw += home(i) / 12.0
		else: cg += home(i) / 12.0
	var anchor: Vector2 = cw.lerp(CLUMP[grouping], c)
	var out: Array[Vector2] = []
	for i in 24:
		var h: Vector2 = home(i)
		if kept.has(i): out.append(h)
		elif is_warm(i, grouping): out.append(anchor + (h - cw) * lerpf(1.0, TIGHT, c))
		else: out.append(cg + (h - cg) * lerpf(1.0, LOOSE, c))
	return out


static func nearest(at: Array[Vector2], i: int) -> float:
	var best := 1e9
	for j in at.size():
		if j != i: best = minf(best, at[i].distance_to(at[j]))
	return best


## How many of one colour have a body's width to the nearest other post.
func room(warm: bool) -> int:
	var n := 0
	for i in 24:
		if is_warm(i, _grouping) == warm and nearest(_now, i) >= ROOM: n += 1
	return n


## How many of one colour have their middle behind a nearer post, seen from a place.
func hidden_from(eye: Vector2, warm: bool) -> int:
	var n := 0
	for i in 24:
		if is_warm(i, _grouping) != warm: continue
		var di: float = _now[i].distance_to(eye)
		var ai: float = atan2(_now[i].x - eye.x, _now[i].y - eye.y)
		for j in 24:
			if j == i: continue
			var dj: float = _now[j].distance_to(eye)
			if dj >= di: continue
			if absf(angle_difference(ai, atan2(_now[j].x - eye.x, _now[j].y - eye.y))) < atan(POST * 0.5 / dj):
				n += 1
				break
	return n


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _physics_process(delta: float) -> void:
	# the posts go to where the rule puts them, at a pace that can be watched
	if not _settled:
		var want: Array[Vector2] = places(_grouping, _c, _kept)
		var far := 0.0
		for i in 24:
			_now[i] = _now[i].move_toward(want[i], 2.2 * delta)
			far = maxf(far, _now[i].distance_to(want[i]))
			_posts[i].position = Vector3(_now[i].x, 0, _now[i].y)
		_settled = far < 0.0005
		_lay_tape()
		_show()
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	_look += delta
	if _look >= 0.2:
		_look = 0.0
		var eye := Vector2(p.x, p.z)
		var seen := [hidden_from(eye, true), hidden_from(eye, false)]
		if seen != _hidden:
			_hidden = seen
			_show()
	var region := ""
	if absf(p.y) < 1.5:
		if absf(p.x) <= HALF and absf(p.z - RAIL_Z) <= LANE: region = "rail"
		else:
			for plate in PLATES:
				if absf(p.x - float(plate["x"])) < PLATE * 0.5 and absf(p.z - RAIL_Z) < PLATE * 0.5: region = str(plate["key"])
			if region == "" and _c <= 0.1 and _settled:
				var pair: Array[int] = _pair_at(Vector2(p.x, p.z))
				if pair.size() == 2: region = "pair:%d:%d" % [pair[0], pair[1]]
	var moved: float = Vector2(p.x - _last.x, p.z - _last.z).length()
	var along: bool = absf(p.x - _last.x) > absf(p.z - _last.z) * 1.5 and moved > 0.002      # walking the rail, not crossing it
	_last = p
	if region != _region or moved > 0.3 * delta:
		_still = 0.0
	elif _still >= 0.0:
		_still += delta
	_region = region
	if region == "rail" and along:
		var value: float = clampf((p.x + HALF) / (HALF * 2.0), 0.0, 1.0)
		if absf(value - _c) > 0.0005:
			_c = value
			_settled = false
	if _still >= 0.8 and region != "" and region != "rail":
		_still = -99.0
		if region == "letgo": _kept.clear()
		elif region == "grouping":
			_grouping = "B" if _grouping == "A" else "A"
			_kept.clear()
			_paint()
		else:
			var parts: PackedStringArray = region.split(":")
			_kept = [int(parts[1]), int(parts[2])]
		_settled = false
		_lay_tape()
		_show()
		_tell()


## Two warm posts the place lies between: both near, and the place within 0.3 m of their middle.
func _pair_at(at: Vector2) -> Array[int]:
	var best: Array[int] = []
	var least := 0.3
	for i in 24:
		if not is_warm(i, _grouping): continue
		for j in range(i + 1, 24):
			if not is_warm(j, _grouping) or _now[i].distance_to(_now[j]) > 1.3: continue
			var d: float = at.distance_to((_now[i] + _now[j]) * 0.5)
			if d < least:
				least = d
				best = [i, j]
	return best


func _paint() -> void:
	for i in 24:
		_bands[i].material_override = _warm_paint if is_warm(i, _grouping) else _grey_paint
		_numbers[i].modulate = WARM.lightened(0.35) if is_warm(i, _grouping) else GREY.lightened(0.4)


func _lay_tape() -> void:
	_tape.visible = _kept.size() == 2
	if not _tape.visible: return
	var a: Vector2 = _now[_kept[0]]
	var b: Vector2 = _now[_kept[1]]
	_tape.position = Vector3((a.x + b.x) * 0.5, 1.05, (a.y + b.y) * 0.5)
	_tape.rotation.y = atan2(-(b.y - a.y), b.x - a.x)
	_tape.scale.x = maxf(a.distance_to(b), 0.01)


func kept_apart() -> float:
	return _now[_kept[0]].distance_to(_now[_kept[1]]) if _kept.size() == 2 else -1.0


func _status_text() -> String:
	if _kept.size() == 2 and _c > 0.5:
		return "YOU KEPT %d AND %d: STILL %.2f m APART.\nYOU CHOSE THAT ONE. THE OTHER TEN WERE NOT ASKED." % [_kept[0] + 1, _kept[1] + 1, kept_apart()]
	if _kept.size() == 2:
		return "KEPT: %d AND %d. NOW WALK THE RAIL." % [_kept[0] + 1, _kept[1] + 1]
	if _grouping == "B":
		return "ANOTHER GROUPING: THE SOUTH ROWS ARE WARM NOW.\nSOMEONE CHOSE THIS ONE TOO."
	if _c > 0.9:
		if room(true) == 0: return "ALL TWELVE ARE STILL PRESENT.\nNONE OF THEM HAS ROOM ROUND IT."
		return "ALL TWELVE ARE STILL PRESENT.\n%d OF THEM STILL HAVE ROOM ROUND THEM." % room(true)
	if _c > 0.1:
		return "THE RAIL MOVES THE POSTS. YOUR FEET MOVE THE VIEW.\nTHOSE ARE TWO DIFFERENT CHANGES."
	return "WALK ALONG THE RAIL, AND WATCH THE MIDDLE COLUMN."


func _show() -> void:
	_puck.position.x = _c * HALF * 2.0 - HALF
	var rows := [["12", str(room(true)), str(_hidden[0])], ["12", str(room(false)), str(_hidden[1])]]
	for r in 2:
		for col in 3: (_cells[r][col] as Label3D).text = str(rows[r][col])
	_status.text = _status_text()
	_foot.text = "pressed %.2f   ·   grouping %s (%s)   ·   kept: %s" % [_c, _grouping, "the west field is warm" if _grouping == "A" else "the south rows are warm",
		("%d and %d" % [_kept[0] + 1, _kept[1] + 1]) if _kept.size() == 2 else "none"]
	for i in PLATES.size():
		var key: String = str(PLATES[i]["key"])
		(_plate_tiles[i].material_override as StandardMaterial3D).albedo_color = Color("f6e39a") if (key == "grouping" and _grouping == "B") or (key == "letgo" and _kept.size() == 2) else PALE


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["ROOM TO TELL APART"])
	lines.append("Twenty-four posts, a number on each and no word. Twelve wear a warm band. Walk ALONG the rail: the warm twelve are pressed toward one place and the grey twelve spread. All of them are still here. Count on the stand how many still have room round them.")
	lines.append("Walk in among them while the field is open. Pressed, try again. Then walk round them and watch the last column: how many hide behind another from where you stand. The rail changed the posts. Your feet change only the view.")
	lines.append("Stand still between two warm posts while the field is open: that pair is kept, and stays when the rest are pressed. You chose it; the others were not asked. OTHER GROUPING makes another twelve warm. Someone chose that too - here, the one who built this.")
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
	_warm_paint = _plain(WARM)
	_grey_paint = _plain(GREY)
	var card: StandardMaterial3D = _city.flat(CARD, 0.95)
	# the posts: each a body, a band, a number
	for i in 24:
		var post := StaticBody3D.new()
		post.name = "Post%d" % (i + 1)
		add_child(post)
		_box(post, Vector3(0, (TALL - 0.3) * 0.5, 0), Vector3(POST, TALL - 0.3, POST), card)
		_bands.append(_box(post, Vector3(0, TALL - 0.15, 0), Vector3(POST + 0.02, 0.3, POST + 0.02), _grey_paint))
		_city.wall(post, Vector3.ZERO, Vector3(POST, TALL, POST))
		var number: Label3D = _words(post, Vector3(0, TALL + 0.16, 0), 56, 0.0035, PALE)
		number.text = str(i + 1)
		number.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		number.double_sided = true
		_numbers.append(number)
		_posts.append(post)
		_now.append(_homes[i])
	_tape = _box(self, Vector3.ZERO, Vector3(1.0, 0.05, 0.012), _plain(TAPE))
	_tape.visible = false
	# the rail and its puck
	_box(self, Vector3(0, 0.008, RAIL_Z), Vector3(HALF * 2.0 + 0.12, 0.014, LANE * 2.0 + 0.12), _city.flat(DARK, 0.9))
	_box(self, Vector3(0, 0.016, RAIL_Z), Vector3(HALF * 2.0, 0.008, LANE * 2.0), _city.flat(Color("3b4254"), 0.9))
	var marks := ["OPEN", "", "HALF", "", "PRESSED"]
	for i in 5:
		var x: float = -HALF + float(i) * HALF * 0.5
		_box(self, Vector3(x, 0.022, RAIL_Z), Vector3(0.04, 0.006, LANE * 2.0), _plain(PALE))
		if marks[i] != "": _city.floor_words(self, Vector3(x, 0.03, RAIL_Z + LANE + 0.24), marks[i], 44, PALE)
	_puck = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.16
	disc.bottom_radius = 0.16
	disc.height = 0.05
	_puck.mesh = disc
	_puck.material_override = _plain(WARM)
	_puck.position = Vector3(-HALF, 0.05, RAIL_Z - LANE + 0.2)
	add_child(_puck)
	_city.floor_words(self, Vector3(0, 0.03, RAIL_Z - LANE - 0.22), "walk along  →", 40, PALE)
	for plate in PLATES:
		_plate_tiles.append(_box(self, Vector3(float(plate["x"]), 0.012, RAIL_Z), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8)))
		_city.floor_words(self, Vector3(float(plate["x"]), 0.035, RAIL_Z), str(plate["says"]), 52, DARK).outline_size = 0
	# the stand: three counts for two colours, above the heads of the posts
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(-2.2, 0, -3.8)
	add_child(stand)
	var held := StaticBody3D.new()
	stand.add_child(held)
	_box(stand, Vector3(0, 2.3, -0.05), Vector3(3.9, 2.2, 0.06), _city.flat(DARK, 0.85))
	_city.wall(held, Vector3(0, 0, -0.05), Vector3(3.9, 3.4, 0.12))
	for hand in [-1.0, 1.0]: _box(stand, Vector3(hand * 1.85, 0.6, -0.05), Vector3(0.08, 1.2, 0.08), _city.flat(DARK, 0.85))
	var heads := [["PRESENT", PALE, -0.75], ["ROOM ROUND IT", Color("f6e39a"), 0.25], ["HIDDEN FROM\nWHERE YOU STAND", Color("9fe6ee"), 1.35]]
	for head in heads: _words(stand, Vector3(float(head[2]), 3.12, 0), 24, 0.005, head[1]).text = str(head[0])
	var names := [["WARM", WARM.lightened(0.2)], ["GREY", GREY.lightened(0.3)]]
	for r in 2:
		var y: float = 2.72 - 0.36 * float(r)
		_words(stand, Vector3(-1.5, y, 0), 34, 0.005, names[r][1]).text = str(names[r][0])
		var row := []
		for col in 3: row.append(_words(stand, Vector3(float(heads[col][2]), y, 0), 48, 0.005, heads[col][1]))
		_cells.append(row)
	_status = _words(stand, Vector3(0, 1.86, 0), 24, 0.005, Color("f2a23a"))
	_foot = _words(stand, Vector3(0, 1.42, 0), 20, 0.005, Color("b9c0cc"))
	_board = _city.board(self, Vector3(-5.2, 0, 4.7), 3.2, 1.7)


## ---- for a test ----

func state() -> Dictionary:
	var near := 1e9
	for i in 24:
		if is_warm(i, _grouping) and not _kept.has(i): near = minf(near, nearest(_now, i))
	var middle := Vector2.ZERO
	var count := 0
	for i in 24:
		if is_warm(i, _grouping) and not _kept.has(i):
			middle += _now[i]
			count += 1
	return {"pressed": snappedf(_c, 0.001), "grouping": _grouping, "present": [12, 12], "room": [room(true), room(false)], "hidden": _hidden.duplicate(), "kept": _kept.map(func(i): return i + 1),
		"kept_apart_m": snappedf(kept_apart(), 0.001), "nearest_warm_m": snappedf(near, 0.001), "settled": _settled, "tape": _tape.visible, "warm": range(24).filter(func(i): return is_warm(i, _grouping)).map(func(i): return i + 1),
		"warm_middle": [snappedf(middle.x / maxf(count, 1), 0.001), snappedf(middle.y / maxf(count, 1), 0.001)], "status": _status.text, "foot": _foot.text, "board": _board.text if _board != null else "", "build_ms": _build_ms}


## A place on the rail's middle line at a value (0 west: open; 1 east: pressed).
func rail_point(value: float) -> Vector3:
	return to_global(Vector3(value * HALF * 2.0 - HALF, 0, RAIL_Z))


func plate_point(key: String) -> Vector3:
	for plate in PLATES:
		if str(plate["key"]) == key: return to_global(Vector3(float(plate["x"]), 0, RAIL_Z))
	return global_position


## The middle between two posts as they stand now (numbers as written on them).
func pair_point(a: int, b: int) -> Vector3:
	var m: Vector2 = (_now[a - 1] + _now[b - 1]) * 0.5
	return to_global(Vector3(m.x, 0, m.y))


func local_point(x: float, z: float) -> Vector3:
	return to_global(Vector3(x, 0, z))
