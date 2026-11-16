extends Node3D
## THE SEAT YOU TAKE (floor CriticalAlgorithms_Applied_Ethics; the pass, 2026-11-16)
##
## The hall, of its two miniature rooms: "Who does this room make easiest to address?" "Equal spacing is what this
## loop guarantees. Equal opportunity to speak would require another kind of evidence." "A designated interpreter,
## a speaker who needs a clear sightline or someone who cannot easily turn towards every other participant can
## complicate the familiar good-circle story." "A future version could compare actual sightlines and turn-taking
## across the two plans ... which participant gained access, which difficulty remained, and what change should
## follow?" This is that future version for sightlines, at full size - a PLAYGROUND form. Nobody speaks in it.
##
## Two plans a body can sit in. A long table: a head seat at the west end, six along its sides, facing across. A
## round table: six seats on a ring, facing the centre. A seat FACES another when the other lies within a turn of
## the neck either side of where the seat points. At eye height run tapes: red between two seats that face each
## other; a half tape, ochre, from a seat that faces one that does not face it back.
##
## Stand on a seat's disc and the tapes that are yours light: yellow to those you face, blue from those who face
## you. NECK changes how far a neck turns: 30, 60, 90 degrees. ANGLE THE CHAIRS turns the six side seats toward
## the head. The stand counts, for each plan, the pairs who face each other, and for the seat you took, whom you
## face and who faces you.
##
## `neck` is the axis: thirty, sixty, ninety. The same arithmetic is benched in tools/probes/seat_you_take_bench.py.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const TABLE := Vector2(-2.5, 0.0)
const RING := Vector2(2.6, 0.0)
const RING_R := 1.1
const SIDE_Z := 0.85
const ANGLED := 40.0
const NECKS := {"thirty": 30.0, "sixty": 60.0, "ninety": 90.0}
const ORDER := ["thirty", "sixty", "ninety"]
const EYE := 1.15
const PLATES := [
	{"key": "neck", "says": "NECK  →", "x": -0.55},
	{"key": "angle", "says": "ANGLE\nTHE CHAIRS", "x": 0.55},
]
const PLATE_Z := 2.5
const PLATE := 0.84
const CARD := Color("c4a070")
const DARK := Color("191e29")
const PALE := Color("efe9dc")
const BOTH := Color("d8262c")
const ONE := Color("c9a15a")
const MINE := Color("ffe14a")
const THEIRS := Color("40f2ff")

@export_enum("thirty", "sixty", "ninety") var neck := "sixty"

var _city = City.new()
var _angled := false
var _seat := -1                          # the seat the visitor is on, or -1
var _seats := []                         # {plan, name, at: Vector2, facing: float (degrees from +x toward +z), head}
var _backs: Array[Node3D] = []
var _discs: Array[MeshInstance3D] = []
var _halves := []                        # {from, to, mesh}
var _paint := {}
var _plate_tiles: Array[MeshInstance3D] = []
var _lines: Array[Label3D] = []
var _status: Label3D
var _board: Label3D
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_neck"): _take({"neck": get_meta("config_neck")})
	var began := Time.get_ticks_msec()
	_seats = seats(false)
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_found()


func _take(config_data: Dictionary) -> void:
	if config_data.has("neck") and NECKS.has(str(config_data["neck"])): neck = str(config_data["neck"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := neck
	_take(config_data)
	if is_inside_tree() and _board != null and neck != before: _found()


func _found() -> void:
	_angled = false
	_seats = seats(false)
	_turn_backs()
	_show()
	_tell()


## ---- the rule ----

## The thirteen seats: where each is and which way it points.
static func seats(angled: bool) -> Array:
	var out := [{"plan": "table", "name": "the head", "at": TABLE + Vector2(-1.75, 0.0), "facing": 0.0, "head": true}]
	var n := 0
	for side in [-1.0, 1.0]:                                     # the north side, then the south
		for x in [-0.8, 0.0, 0.8]:
			n += 1
			var across: float = 90.0 if side < 0.0 else -90.0   # toward the table
			var toward_head: float = wrapf(180.0 - across, -180.0, 180.0)
			var turn: float = signf(toward_head) * minf(ANGLED, absf(toward_head)) if angled else 0.0
			out.append({"plan": "table", "name": "side %d" % n, "at": TABLE + Vector2(x, side * SIDE_Z), "facing": across + turn, "head": false})
	for k in 6:
		var a: float = deg_to_rad(30.0 + 60.0 * float(k))
		var at: Vector2 = RING + Vector2(cos(a), sin(a)) * RING_R
		out.append({"plan": "ring", "name": "ring %d" % (k + 1), "at": at, "facing": rad_to_deg(atan2(RING.y - at.y, RING.x - at.x)), "head": false})
	return out


## How far seat a must turn to face seat b, in degrees.
func turn_to(a: int, b: int) -> float:
	var d: Vector2 = _seats[b]["at"] - _seats[a]["at"]
	return absf(wrapf(rad_to_deg(atan2(d.y, d.x)) - float(_seats[a]["facing"]), -180.0, 180.0))


func faces(a: int, b: int) -> bool:
	return a != b and _seats[a]["plan"] == _seats[b]["plan"] and turn_to(a, b) <= float(NECKS[neck]) + 0.5


## [how many it faces, how many face it, how many others sit in its plan]
func counts(a: int) -> Array:
	var out := [0, 0, 0]
	for b in _seats.size():
		if b == a or _seats[b]["plan"] != _seats[a]["plan"]: continue
		out[2] += 1
		if faces(a, b): out[0] += 1
		if faces(b, a): out[1] += 1
	return out


## [pairs who face each other, pairs] in a plan.
func mutual(plan: String) -> Array:
	var out := [0, 0]
	for a in _seats.size():
		for b in range(a + 1, _seats.size()):
			if _seats[a]["plan"] != plan or _seats[b]["plan"] != plan: continue
			out[1] += 1
			if faces(a, b) and faces(b, a): out[0] += 1
	return out


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _physics_process(delta: float) -> void:
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var on := -1
	var region := ""
	if absf(p.y) < 1.5:
		for i in _seats.size():
			if Vector2(p.x, p.z).distance_to(_seats[i]["at"]) < 0.26: on = i
		for plate in PLATES:
			if absf(p.x - float(plate["x"])) < PLATE * 0.5 and absf(p.z - PLATE_Z) < PLATE * 0.5: region = str(plate["key"])
	if on != _seat:
		_seat = on
		_show()
	var moved: float = Vector2(p.x - _last.x, p.z - _last.z).length()
	_last = p
	if region != _region or moved > 0.3 * delta:
		_still = 0.0
	elif _still >= 0.0:
		_still += delta
	_region = region
	if _still >= 0.8 and region != "":
		_still = -99.0
		if region == "neck": neck = ORDER[(ORDER.find(neck) + 1) % 3]
		else:
			_angled = not _angled
			_seats = seats(_angled)
			_turn_backs()
		_show()
		_tell()


func _turn_backs() -> void:
	for i in _seats.size(): _backs[i].rotation.y = -deg_to_rad(float(_seats[i]["facing"]))


func _status_text() -> String:
	var head: Array = counts(0)
	if _angled:
		return "THE CHAIRS ARE TURNED TO THE HEAD: %d OF 6 FACE IT NOW.\nAT THE LONG TABLE %d OF 21 PAIRS FACE EACH OTHER." % [head[1], mutual("table")[0]]
	match neck:
		"thirty": return "A NECK THAT TURNS 30°: IN THE RING, THE TWO BESIDE YOU\nARE OUT OF REACH. THE CIRCLE DID NOT SOLVE THAT."
		"sixty": return "THE HEAD FACES ALL SIX. %d OF THE SIX FACE THE HEAD.\nTHE REST MUST TURN FURTHER TO ANSWER." % head[1]
	return "TURN FAR ENOUGH AND EVERYONE FACES EVERYONE.\nTHE ROOM DECIDES HOW FAR EACH MUST TURN."


func _show() -> void:
	var table: Array = mutual("table")
	var ring: Array = mutual("ring")
	var head: Array = counts(0)
	_lines[0].text = "A NECK TURNS %d° EITHER WAY%s" % [int(NECKS[neck]), "   ·   CHAIRS ANGLED" if _angled else ""]
	_lines[1].text = "LONG TABLE:   %d of %d pairs face each other" % [table[0], table[1]]
	_lines[2].text = "ROUND TABLE:   %d of %d pairs face each other" % [ring[0], ring[1]]
	_lines[3].text = "the head faces %d of 6   ·   %d of 6 face the head" % [head[0], head[1]]
	if _seat >= 0:
		var mine: Array = counts(_seat)
		_lines[4].text = "YOU SIT AT %s:  you face %d of %d   ·   %d of %d face you" % [str(_seats[_seat]["name"]).to_upper(), mine[0], mine[2], mine[1], mine[2]]
	else:
		_lines[4].text = "TAKE A SEAT: STAND ON ITS DISC."
	_status.text = _status_text()
	for half in _halves:
		var a: int = half["from"]
		var b: int = half["to"]
		var mesh: MeshInstance3D = half["mesh"]
		mesh.visible = faces(a, b)
		if not mesh.visible: continue
		var both: bool = faces(b, a)
		var key := "both" if both else "one"
		if a == _seat: key = "mine"
		elif b == _seat: key = "theirs"
		mesh.material_override = _paint[key]
		mesh.scale = Vector3(1, 2.2, 2.2) if key in ["mine", "theirs"] else Vector3.ONE
	for i in _discs.size(): (_discs[i].material_override as StandardMaterial3D).albedo_color = MINE if i == _seat else PALE
	for i in PLATES.size():
		var lit: bool = str(PLATES[i]["key"]) == "angle" and _angled
		(_plate_tiles[i].material_override as StandardMaterial3D).albedo_color = Color("f6e39a") if lit else PALE


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["THE SEAT YOU TAKE"])
	lines.append("The two plans from the pedestal, at the size of a body: a long table with a head, and a ring of six. Stand on a seat's disc. The tapes at eye height are sightlines: red where two seats face each other, a half tape where one faces a seat that does not face it back. Yours light yellow; blue ones come from those who face you.")
	lines.append("NECK changes how far a neck turns: 30, 60, 90 degrees either way. Sit at the head with a short neck: you face four, and none faces you. Sit in the ring: the two beside you are out of reach. ANGLE THE CHAIRS turns the sides toward the head: count who gained, and what the sides lost.")
	lines.append("Every seat is empty. This counts where a neck can reach, not who is listened to, nor whose turn it is. That would take people.")
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


func _round(parent: Node3D, at: Vector3, radius: float, tall: float, paint: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = tall
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
	_paint = {"both": _plain(BOTH), "one": _plain(ONE), "mine": _plain(MINE), "theirs": _plain(THEIRS)}
	var card: StandardMaterial3D = _city.flat(CARD, 0.95)
	var wood: StandardMaterial3D = _city.flat(Color("6b4a32"), 0.9)
	var solid := StaticBody3D.new()
	add_child(solid)
	# the long table
	_box(self, Vector3(TABLE.x, 0.72, TABLE.y), Vector3(2.6, 0.05, 0.9), card)
	for hand in [-1.0, 1.0]: _box(self, Vector3(TABLE.x + hand * 0.95, 0.35, TABLE.y), Vector3(0.45, 0.7, 0.45), wood)
	_city.wall(solid, Vector3(TABLE.x, 0, TABLE.y), Vector3(2.6, 0.75, 0.9))
	_city.floor_words(self, Vector3(TABLE.x + 0.4, 0.03, TABLE.y + 1.75), "a long table: one head, six sides", 40, PALE)
	# the round table
	_round(self, Vector3(RING.x, 0.72, RING.y), 0.55, 0.05, card)
	_round(self, Vector3(RING.x, 0.35, RING.y), 0.16, 0.7, wood)
	_city.wall(solid, Vector3(RING.x, 0, RING.y), Vector3(0.78, 0.75, 0.78))
	_city.floor_words(self, Vector3(RING.x, 0.03, RING.y + 1.95), "a ring of six", 40, PALE)
	# the seats: a disc to stand on, and a back that shows which way the seat points
	for i in _seats.size():
		var seat: Dictionary = _seats[i]
		var at: Vector2 = seat["at"]
		_discs.append(_round(self, Vector3(at.x, 0.012, at.y), 0.23, 0.02, _city.flat(PALE, 0.8)))
		var back := Node3D.new()
		back.name = "Back_%s" % str(seat["name"]).replace(" ", "_")
		back.position = Vector3(at.x, 0, at.y)
		add_child(back)
		var tall: float = 1.3 if bool(seat["head"]) else 0.9
		var wide: float = 0.62 if bool(seat["head"]) else 0.46
		_box(back, Vector3(-0.38, tall * 0.5, 0), Vector3(0.04, tall, wide), card)
		var held := StaticBody3D.new()
		back.add_child(held)
		_city.wall(held, Vector3(-0.38, 0, 0), Vector3(0.06, tall, wide))
		_backs.append(back)
	# the sightlines: a half tape from each seat toward each other seat of its plan
	for a in _seats.size():
		for b in _seats.size():
			if a == b or _seats[a]["plan"] != _seats[b]["plan"]: continue
			var from: Vector2 = _seats[a]["at"]
			var to: Vector2 = _seats[b]["at"]
			var mesh: MeshInstance3D = _box(self, Vector3(lerpf(from.x, to.x, 0.25), EYE, lerpf(from.y, to.y, 0.25)), Vector3(from.distance_to(to) * 0.5, 0.012, 0.012), _paint["both"])
			mesh.rotation.y = atan2(-(to.y - from.y), to.x - from.x)
			_halves.append({"from": a, "to": b, "mesh": mesh})
	# the plates
	for plate in PLATES:
		_plate_tiles.append(_box(self, Vector3(float(plate["x"]), 0.012, PLATE_Z), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8)))
		_city.floor_words(self, Vector3(float(plate["x"]), 0.035, PLATE_Z), str(plate["says"]), 52, DARK).outline_size = 0
	# the stand
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(-0.5, 0, -3.9)
	add_child(stand)
	var held2 := StaticBody3D.new()
	stand.add_child(held2)
	_box(stand, Vector3(0, 2.15, -0.05), Vector3(3.8, 2.3, 0.06), _city.flat(DARK, 0.85))
	_city.wall(held2, Vector3(0, 0, -0.05), Vector3(3.8, 3.3, 0.12))
	for hand in [-1.0, 1.0]: _box(stand, Vector3(hand * 1.8, 0.5, -0.05), Vector3(0.08, 1.0, 0.08), _city.flat(DARK, 0.85))
	var colours := [PALE, BOTH.lightened(0.35), BOTH.lightened(0.35), ONE.lightened(0.2), MINE]
	var heights := [3.08, 2.74, 2.44, 2.12, 1.78]
	var sizes := [32, 34, 34, 28, 28]
	for i in 5: _lines.append(_words(stand, Vector3(0, float(heights[i]), 0), int(sizes[i]), 0.0045, colours[i]))
	_status = _words(stand, Vector3(0, 1.36, 0), 24, 0.0045, Color("f2a23a"))
	_board = _city.board(self, Vector3(-5.3, 0, 3.4), 3.2, 1.7)


## ---- for a test ----

func state() -> Dictionary:
	var shown := 0
	for half in _halves:
		if (half["mesh"] as MeshInstance3D).visible: shown += 1
	return {"neck": int(NECKS[neck]), "angled": _angled, "seat": str(_seats[_seat]["name"]) if _seat >= 0 else "", "mine": counts(_seat) if _seat >= 0 else [], "table_pairs": mutual("table"), "ring_pairs": mutual("ring"),
		"head": counts(0), "ring_1": counts(7), "half_tapes": shown, "status": _status.text, "lines": _lines.map(func(l): return l.text), "board": _board.text if _board != null else "", "build_ms": _build_ms}


func seat_point(seat_name: String) -> Vector3:
	for seat in _seats:
		if str(seat["name"]) == seat_name: return to_global(Vector3((seat["at"] as Vector2).x, 0, (seat["at"] as Vector2).y))
	return global_position


func plate_point(key: String) -> Vector3:
	for plate in PLATES:
		if str(plate["key"]) == key: return to_global(Vector3(float(plate["x"]), 0, PLATE_Z))
	return global_position


func local_point(x: float, z: float) -> Vector3:
	return to_global(Vector3(x, 0, z))
