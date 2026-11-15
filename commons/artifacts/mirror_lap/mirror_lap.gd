extends Node3D
## ONE LAP AND YOUR LEFT IS YOUR RIGHT (floor NonEuclidean_Spaces; the pass, 2026-11-15)
##
## Palle, 2026-11-15: non-Euclidean playable spaces for the non-Euclidean maps. The dome bends, the disk measures
## differently, the wing's door glues, the three-cornered block glues with a turn. This one glues with a FLIP: a
## band of corridor joined to itself the other way up - a Moebius band laid on a floor. A PLAYGROUND form.
##
## Go in. Ahead on your left stands the word LEFT. Walk on, turning left at every corner, until you come to it
## again: it stands on your right and reads backwards, and from now every corner turns right. No stretch of the
## corridor is anything but an ordinary corridor and every triangle in it still has 180 degrees; what the lap
## changed is which way round the world is, or you are - there is no telling which. The door does not let you out
## then: outside nothing is mirrored. A second lap puts everything back.
##
## How it is done, and the board says so: an unmirrored body cannot walk its own mirror image, so the second lap
## is BUILT as the mirror image of the first. Two blocks, north and south of one shared stretch of corridor. Lap
## one goes round the north block (four left turns), lap two round the south block (four right turns), and the
## shared stretch is walked both times. Its word, its skirtings and the lettering on the door are turned over in
## the plane of the corridor's middle - and the two openings at each end of the stretch change places - while the
## body is on the far side of a block, where none of it can be seen. The body is never moved or turned.
##
## `lap` is the axis: first (the door opens onto the plain sheet), second (onto the mirrored one).
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const FACE := "res://commons/font/static/Roboto_Condensed-ExtraBold.ttf"
const H := 0.9                          # a block's half side
const W := 1.2                          # the corridor's width
const T := 0.08
const HIGH := 2.5
const DOOR := 1.0
const DOOR_HIGH := 2.1
const X_OUT := H + W                    # the inner face of the east and west walls
const Z_OUT := W * 0.5 + H * 2.0 + W    # the inner face of the north and south walls
const CARD := Color("c4a070")
const BLOCK := Color("3a3d45")
const RED := Color("c1121c")
const PINK := Color("ff5fa8")
const BLUE := Color("3f6fd0")
const PALE := Color("efe9dc")

@export_enum("first", "second") var lap := "first"

var _city = City.new()
var _content: Node3D                     # everything that has a handedness: turned over with the sheet
var _plugs := {}                         # "east_north" ... : [visual, shape]
var _door_shape: CollisionShape3D
var _door_closed: Node3D
var _board: Label3D
var _body: Node3D
var _inside := false
var _laps := 0
var _last_x := 0.0
var _last := ""
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_lap"): _take({"lap": get_meta("config_lap")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_show()


func _take(config_data: Dictionary) -> void:
	if config_data.has("lap") and str(config_data["lap"]) in ["first", "second"]: lap = str(config_data["lap"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := lap
	_take(config_data)
	if is_inside_tree() and _board != null and lap != before and not _inside: _show()


## ---- the rule ----

## Which sheet the shared stretch shows: 0 plain, 1 turned over.
func sheet() -> int:
	return posmod(_laps + (1 if lap == "second" else 0), 2)


static func within(x: float, z: float) -> bool:
	return absf(x) < X_OUT and absf(z) < Z_OUT


func _show() -> void:
	var q: int = sheet()
	_content.scale = Vector3(1, 1, -1.0 if q == 1 else 1.0)
	# on the plain sheet the stretch's east end opens north and its west end south; turned over, the other way
	var open := {"east_north": q == 0, "east_south": q == 1, "west_north": q == 1, "west_south": q == 0}
	for key in _plugs:
		(_plugs[key][0] as Node3D).visible = not bool(open[key])
		(_plugs[key][1] as CollisionShape3D).set_deferred("disabled", bool(open[key]))
	# the door lets a body out only as it came in: after an odd number of laps the tower outside would be mirrored
	var odd: bool = posmod(_laps, 2) == 1
	_door_closed.visible = odd
	_door_shape.set_deferred("disabled", not odd)
	_tell()


func _physics_process(_delta: float) -> void:
	if _body == null or not is_instance_valid(_body):
		_inside = false
		return
	var p := to_local(_body.global_position)
	var now: bool = within(p.x, p.z) and absf(p.y) < 2.0
	if now and not _inside:
		_inside = true
		_laps = 0
		_last_x = p.x
		_show()
		return
	if not now:
		if _inside:
			_inside = false
			_last = "Last walk: %d lap%s." % [absi(_laps), "" if absi(_laps) == 1 else "s"]
			_laps = 0
			_show()
		return
	# a lap is counted on the far side of a block, at its middle: forward is westward there, round either block
	if absf(p.z) > W * 0.5 + H * 2.0:
		if _last_x > 0.03 and p.x < -0.03:
			_laps += 1
			_last_x = p.x
			_show()
		elif _last_x < -0.03 and p.x > 0.03:
			_laps -= 1
			_last_x = p.x
			_show()
		elif absf(p.x) > 0.03 and signf(p.x) == signf(_last_x): _last_x = p.x
		elif absf(_last_x) <= 0.03: _last_x = p.x
	else:
		_last_x = p.x


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["ONE LAP AND YOUR LEFT IS YOUR RIGHT"])
	lines.append("Go in. Ahead on your left stands the word LEFT. Walk on, turning left at every corner, until you come to it again. It stands on your right and reads backwards, and from now every corner turns right.")
	lines.append("Nothing in there is bent and every triangle keeps 180°. The corridor is a band joined to itself the other way up: a Moebius band laid on a floor. You came back as your mirror image, or the world did - there is no telling which. The door will not let you out then: out here nothing is mirrored. A second lap puts it back.")
	lines.append("How: you cannot walk your own mirror image, so lap two is built as the mirror of lap one, round a second block. The stretch between the blocks is walked both times, and its word is turned over while a block hides it.")
	if _last != "": lines.append(_last)
	_board.text = "\n".join(lines)


## ---- building, once ----

func _box(parent: Node3D, solid: StaticBody3D, at: Vector3, size: Vector3, paint: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = paint
	mesh.position = at
	parent.add_child(mesh)
	if solid != null: _city.wall(solid, at - Vector3(0, size.y * 0.5, 0), size)   # wall() takes the base of the box
	return mesh


func _words(parent: Node3D, text: String, at: Vector3, yaw: float, size: int, pixel: float, colour: Color) -> Label3D:
	var label3d := Label3D.new()
	label3d.text = text
	label3d.font_size = size
	label3d.pixel_size = pixel
	label3d.modulate = colour
	label3d.outline_size = 0
	label3d.double_sided = true          # turned over with the sheet, it is read from what was its back
	label3d.position = at
	label3d.rotation.y = yaw
	parent.add_child(label3d)
	return label3d


func _plug(key: String, at: Vector3, paint: Material) -> void:
	var body := StaticBody3D.new()
	body.name = "Plug_" + key
	add_child(body)
	var size := Vector3(W, HIGH, T)
	var visual: MeshInstance3D = _box(body, null, at, size, paint)
	var shape: CollisionShape3D = _city.wall(body, at - Vector3(0, size.y * 0.5, 0), size)
	_plugs[key] = [visual, shape]


func _build_once() -> void:
	var solid := StaticBody3D.new()
	solid.name = "Walls"
	add_child(solid)
	var card: StandardMaterial3D = _city.flat(CARD, 0.95)
	var dark: StandardMaterial3D = _city.flat(BLOCK, 0.9)
	var pale: StandardMaterial3D = _city.flat(PALE, 0.9)
	var wide: float = (X_OUT + T) * 2.0
	var deep: float = (Z_OUT + T) * 2.0
	_city.sheet(self, Vector3(0, 0.006, 0), Vector2(wide, deep), Color("d9d2c2"))
	_box(self, null, Vector3(0, HIGH + 0.03, 0), Vector3(wide, 0.06, deep), card)
	# two blocks, the south one the mirror of the north one
	for hand in [-1.0, 1.0]:
		_box(self, solid, Vector3(0, HIGH * 0.5, hand * (W * 0.5 + H)), Vector3(H * 2.0, HIGH, H * 2.0), dark)
		_box(self, solid, Vector3(0, HIGH * 0.5, hand * (Z_OUT + T * 0.5)), Vector3(wide, HIGH, T), card)
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0, HIGH - 0.35, hand * (Z_OUT - W * 0.5))
		lamp.omni_range = 4.2
		lamp.light_energy = 1.2
		lamp.shadow_enabled = false
		add_child(lamp)
	_box(self, solid, Vector3(X_OUT + T * 0.5, HIGH * 0.5, 0), Vector3(T, HIGH, deep), card)
	# the west wall, with the door in it at the end of the shared stretch
	var piece: float = (deep - DOOR) * 0.5
	for hand in [-1.0, 1.0]: _box(self, solid, Vector3(-X_OUT - T * 0.5, HIGH * 0.5, hand * (DOOR + piece) * 0.5), Vector3(T, HIGH, piece), card)
	_box(self, solid, Vector3(-X_OUT - T * 0.5, (HIGH + DOOR_HIGH) * 0.5, 0), Vector3(T, HIGH - DOOR_HIGH, DOOR), card)
	var mid := OmniLight3D.new()
	mid.position = Vector3(0, HIGH - 0.35, 0)
	mid.omni_range = 4.2
	mid.light_energy = 1.2
	mid.shadow_enabled = false
	add_child(mid)
	# the openings at the two ends of the shared stretch: one of each pair is walled at any time
	for end in [["east", 1.0], ["west", -1.0]]:
		for way in [["north", -1.0], ["south", 1.0]]:
			_plug("%s_%s" % [end[0], way[0]], Vector3(float(end[1]) * (H + W * 0.5), HIGH * 0.5, float(way[1]) * W * 0.5), card)
	# what has a handedness, all under one node that is turned over in the plane of the corridor's middle
	_content = Node3D.new()
	_content.name = "Handed"
	add_child(_content)
	var word := MeshInstance3D.new()
	var letters := TextMesh.new()
	letters.font = load(FACE)
	letters.text = "LEFT"
	letters.font_size = 96
	letters.pixel_size = 1.0 / 96.0
	letters.depth = 0.05
	word.mesh = letters
	var red: StandardMaterial3D = _city.flat(RED, 0.6)
	red.cull_mode = BaseMaterial3D.CULL_DISABLED
	word.material_override = red
	var box: AABB = letters.get_aabb()
	var size: float = 0.55 / maxf(0.01, box.size.y)
	word.scale = Vector3.ONE * size
	word.position = Vector3(-(box.position.x + box.size.x * 0.5) * size, 1.25 - box.position.y * size, -W * 0.5 + 0.03)
	word.name = "Word"
	_content.add_child(word)
	_words(_content, "it stands on your left", Vector3(0, 1.05, -W * 0.5 + 0.012), 0.0, 44, 0.0022, PINK.lightened(0.3))
	for skirting in [[-1.0, PINK], [1.0, BLUE]]:
		var strip := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = Vector3(H * 2.0, 0.16, 0.012)
		strip.mesh = shape
		strip.material_override = _city.flat(skirting[1], 0.5)
		strip.position = Vector3(0, 0.1, float(skirting[0]) * (W * 0.5 - 0.008))
		_content.add_child(strip)
	# the door from inside: a paper screen with OUT on it; and what closes it after an odd number of laps
	var paper := MeshInstance3D.new()
	var sheet_mesh := QuadMesh.new()
	sheet_mesh.size = Vector2(DOOR, DOOR_HIGH)
	paper.mesh = sheet_mesh
	paper.material_override = pale
	paper.position = Vector3(-X_OUT + 0.004, DOOR_HIGH * 0.5, 0)
	paper.rotation.y = PI * 0.5
	_content.add_child(paper)
	_words(_content, "OUT", Vector3(-X_OUT + 0.012, 1.55, 0), PI * 0.5, 90, 0.003, BLOCK)
	_door_closed = Node3D.new()
	_door_closed.name = "DoorClosed"
	_content.add_child(_door_closed)
	var shut := MeshInstance3D.new()
	var shut_mesh := QuadMesh.new()
	shut_mesh.size = Vector2(DOOR, 0.95)
	shut.mesh = shut_mesh
	var shut_paint: StandardMaterial3D = _city.flat(RED, 0.6)
	shut_paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	shut.material_override = shut_paint
	shut.position = Vector3(-X_OUT + 0.016, 0.62, 0)
	shut.rotation.y = PI * 0.5
	_door_closed.add_child(shut)
	_words(_door_closed, "out there nothing\nis mirrored.\none more lap.", Vector3(-X_OUT + 0.024, 0.62, 0), PI * 0.5, 44, 0.0022, PALE)
	var door_body := StaticBody3D.new()
	door_body.name = "DoorShut"
	add_child(door_body)
	_door_shape = _city.wall(door_body, Vector3(-X_OUT - T * 0.5, 0, 0), Vector3(T, DOOR_HIGH, DOOR))
	# the door from outside: a paper screen that is walked through
	var front := MeshInstance3D.new()
	front.mesh = sheet_mesh
	front.material_override = pale
	front.position = Vector3(-X_OUT - T - 0.004, DOOR_HIGH * 0.5, 0)
	front.rotation.y = -PI * 0.5
	add_child(front)
	var door_sign: Label3D = _words(self, "one lap\nIN", Vector3(-X_OUT - T - 0.012, 1.35, 0), -PI * 0.5, 90, 0.003, BLOCK)
	door_sign.double_sided = false
	# the body, and the board beside the door, turned to the floor
	var sensor := Area3D.new()
	sensor.name = "Reach"
	sensor.collision_layer = 0
	sensor.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(wide + 5.0, 3.4, deep + 3.0)
	var area := CollisionShape3D.new()
	area.shape = room
	area.position = Vector3(0, 1.7, 0)
	sensor.add_child(area)
	add_child(sensor)
	sensor.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _body = b)
	sensor.body_exited.connect(func(b: Node) -> void:
		if b == _body: _body = null)
	_board = _city.board(self, Vector3(-X_OUT - 1.15, 0, 2.0), 2.6, 1.5)
	(_board.get_parent().get_parent() as Node3D).rotation.y = -PI * 0.5


## ---- for a test ----

func state() -> Dictionary:
	var q: int = sheet()
	var word: Node3D = _content.get_node("Word")
	return {"lap": lap, "inside": _inside, "laps": _laps, "sheet": q, "turned_over": _content.scale.z < 0.0, "word_z": snappedf(to_local(word.global_position).z, 0.01),
		"east_opens": "north" if not (_plugs["east_north"][0] as Node3D).visible else "south", "west_opens": "north" if not (_plugs["west_north"][0] as Node3D).visible else "south",
		"door_shut": _door_closed.visible, "board": _board.text if _board != null else "", "x_out": X_OUT, "z_out": Z_OUT, "prefab_parts": int(_city.parts), "build_ms": _build_ms}


## Places to walk to. s: the middle of the shared stretch; e, w: its ends; then round the north block (n...) and
## the south block (s...): ne, n, nw, se, s_far, sw; e_n, w_n, e_s, w_s the middles of the side corridors.
func place(name: String) -> Vector3:
	var a: float = H + W * 0.5
	var far: float = Z_OUT - W * 0.5
	var side: float = W * 0.5 + H
	var places := {"s": Vector3.ZERO, "e": Vector3(a, 0, 0), "w": Vector3(-a, 0, 0), "ne": Vector3(a, 0, -far), "n": Vector3(0, 0, -far), "nw": Vector3(-a, 0, -far),
		"se": Vector3(a, 0, far), "s_far": Vector3(0, 0, far), "sw": Vector3(-a, 0, far), "e_n": Vector3(a, 0, -side), "w_n": Vector3(-a, 0, -side), "e_s": Vector3(a, 0, side), "w_s": Vector3(-a, 0, side),
		"out": Vector3(-X_OUT - 1.5, 0, 0)}
	return to_global(places.get(name, Vector3.ZERO))
