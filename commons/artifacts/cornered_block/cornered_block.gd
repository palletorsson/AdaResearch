extends Node3D
## THREE CORNERS AND YOU ARE HOME (floor NonEuclidean_Spaces; the pass, 2026-11-15)
##
## Palle, 2026-11-15: non-Euclidean playable spaces for the non-Euclidean maps. The hall's bench has a triangle with
## three right angles on its SPHERE stop, and the dome on this floor spreads that excess over a surface. This is the
## same excess gathered into ONE POINT, on a floor that is flat under every step - a PLAYGROUND form.
##
## A square block with a closed corridor round it and one door. Go in, keep the block on your left, count the
## corners: each is a right angle, drawn on the floor. After THREE you stand at the door again. A closed walk with
## three right angles is a triangle of 270 degrees; the 90 too many sit inside the block, as at the corner of a
## cube, where three squares meet instead of four. With `corners` five it takes five (450: the surplus of room a
## hyperbolic surface has, at one point); with four it is an ordinary block.
##
## How it is done, and it is said on the board: the space inside is three (or five) quarter-sectors glued round the
## block, and the building has four. The corridor's four sides are built alike; what tells them apart - the number
## on the block's face, the door - is lettered RELATIVE TO THE BODY: the side it is on, the next, the one before.
## The fourth side is always behind the block. When the body turns a corner onto a side that the glued space does
## not have, the body is turned about the block's middle by a quarter (or back), in the same frame as the faces
## are re-lettered: everything it can see is where it was. Desktop: the walker's transform. Headset: the player
## body's teleport(pose), as the wing's adapter does - NOT tried in a headset.
##
## `corners` is the axis: three, four, five. `board_east`: which side the board stands on (toward the floor).
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const H := 1.1                          # the block's half side
const W := 1.2                          # the corridor's width
const T := 0.08                         # a wall's thickness
const HIGH := 2.5
const DOOR := 1.0
const DOOR_HIGH := 2.1
const COUNT := {"three": 3, "four": 4, "five": 5}
## The side of the building (0 south, 1 east, 2 north, 3 west) on which each numbered side of the glued space is
## kept: the door's side is always the building's south.
const KEPT := {3: [0, 1, 2], 4: [0, 1, 2, 3], 5: [0, 1, 2, 3, 3]}
const CARD := Color("c4a070")
const BLOCK := Color("3a3d45")
const PINK := Color("ff5fa8")
const PALE := Color("efe9dc")

@export_enum("three", "four", "five") var corners := "three"
@export var board_east := true

var _city = City.new()
var _faces: Array[Label3D] = []
var _notes: Array[Label3D] = []
var _doors: Array[Node3D] = []           # per side: the look of the door from inside (south: the plug over the real one)
var _board: Label3D
var _sign: Label3D
var _body: Node3D
var _inside := false
var _side := 0                           # the building's side the body is on
var _count := 0                          # sides gone forward since the door (backward counts down)
var _quarters := 0                       # quarter turns given to the body, in all
var _last := ""
var _build_ms := 0


func _ready() -> void:
	for key in ["corners", "board_east"]:
		if has_meta("config_" + key): _take({key: get_meta("config_" + key)})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_letter()


func _take(config_data: Dictionary) -> void:
	if config_data.has("corners") and COUNT.has(str(config_data["corners"])): corners = str(config_data["corners"])
	if config_data.has("board_east"): board_east = str(config_data["board_east"]) in ["true", "True", "1"]


func apply_grid_config(config_data: Dictionary) -> void:
	var before := corners
	_take(config_data)
	if is_inside_tree() and _board != null and corners != before:
		_count = 0
		_last = ""
		_letter()


## ---- the rule ----

func n() -> int:
	return int(COUNT[corners])


## The number (1..n) of the side `offset` sides on from the one the body is on.
func label(offset: int = 0) -> int:
	return posmod(_count + offset, n()) + 1


## The building's side a place is on: by the block's diagonals.
static func side_at(x: float, z: float) -> int:
	if absf(x) > absf(z): return 1 if x > 0.0 else 3
	return 0 if z > 0.0 else 2


static func within(x: float, z: float) -> bool:
	return maxf(absf(x), absf(z)) < H + W and maxf(absf(x), absf(z)) > H - 0.05


func _letter() -> void:
	for s in 4:
		var offset: int = posmod(s - _side + 2, 4) - 2
		var number: int = label(offset)
		_faces[s].text = str(number)
		_notes[s].text = ("the door" if number == 1 else "") + ("\nhome after %d corners:  %d x 90° = %d°" % [absi(_count), absi(_count), absi(_count) * 90] if number == 1 and _count != 0 and posmod(_count, n()) == 0 else "")
		_doors[s].visible = (number != 1) if s == 0 else (number == 1)
	_tell()


func _turn_body(quarters: int) -> void:
	var theta: float = float(quarters) * PI * 0.5
	var pose: Transform3D = _body.global_transform
	var middle: Vector3 = global_position
	pose.origin = middle + (pose.origin - middle).rotated(Vector3.UP, theta)
	pose.basis = Basis(Vector3.UP, theta) * pose.basis
	var game: Node = get_tree().get_first_node_in_group("void_game")
	if game != null and bool(game.get("vr")) and _body.has_method("teleport"):
		_body.call("teleport", pose)
	else:
		_body.global_transform = pose
		if "velocity" in _body: _body.set("velocity", (_body.get("velocity") as Vector3).rotated(Vector3.UP, theta))
	if game != null and game.has_method("rebase_player_motion"): game.call("rebase_player_motion")
	_quarters += quarters


func _physics_process(_delta: float) -> void:
	if _body == null or not is_instance_valid(_body):
		_inside = false
		return
	var p := to_local(_body.global_position)
	var now: bool = within(p.x, p.z) and absf(p.y) < 2.0
	if now and not _inside:
		_inside = true
		_side = side_at(p.x, p.z)
		_count = 0
		_letter()
		return
	if not now:
		if _inside:
			_inside = false
			_last = "Last walk: %d corner%s, and out by the door." % [absi(_count), "" if absi(_count) == 1 else "s"]
			_side = 0
			_count = 0
			_letter()
		return
	# on which side now? (a hand's width of slack on the diagonal, so that standing on it does not flicker)
	var side: int = side_at(p.x, p.z)
	if side == _side or absf(absf(p.x) - absf(p.z)) < 0.04: return
	var step: int = posmod(side - _side + 2, 4) - 2
	if absi(step) != 1: return
	_count += step
	_side = side
	var kept: int = int((KEPT[n()] as Array)[label() - 1])
	if kept != side:
		var quarters: int = posmod(kept - side + 2, 4) - 2
		_turn_body(quarters)
		_side = kept
	_letter()


func _tell() -> void:
	if _board == null: return
	var count: int = n()
	var lines := PackedStringArray()
	if count == 4:
		lines.append("FOUR CORNERS AND YOU ARE HOME")
		lines.append("Go in. Keep the block on your left and count the corners. After four you are at the door again: 360°, an ordinary block on an ordinary floor.")
	else:
		lines.append("%s CORNERS AND YOU ARE HOME" % ("THREE" if count == 3 else "FIVE"))
		lines.append("Go in. Keep the block on your left and count the corners: each is a right angle, drawn on the floor. After %s you are at the door again." % ("three" if count == 3 else "five"))
		if count == 3:
			lines.append("A closed walk with three right angles is a triangle of 270°. The floor was flat under every step. The 90° too many sit at one point inside the block, as at the corner of a cube, where three squares meet instead of four. The dome spreads the same excess over its surface; here a walk that does not go round the block still gets 180°.")
		else:
			lines.append("A closed walk with five right angles: 450° round a point that a floor gives 360°. The room too much sits at one point inside the block. Spread over a surface it is the disk's geometry, where a pentagon can have five right angles.")
		lines.append("Out here the block has four sides: walk round it and count. Inside, the space has %s. When you turn onto a side it does not have, you are turned about the block's middle by a quarter, and the numbers on the block are lettered from where you stand. Nothing you can see moves." % ("three" if count == 3 else "five"))
	if _last != "": lines.append(_last)
	_board.text = "\n".join(lines)
	_sign.text = "%d corners\nIN" % count


## ---- building, once ----

func _box(parent: Node3D, solid: StaticBody3D, at: Vector3, size: Vector3, paint: Material) -> void:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = paint
	mesh.position = at
	parent.add_child(mesh)
	if solid != null: _city.wall(solid, at, size)


func _panel(parent: Node3D, size: Vector2, paint: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = size
	mesh.mesh = quad
	mesh.material_override = paint
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


func _build_once() -> void:
	var solid := StaticBody3D.new()
	solid.name = "Walls"
	add_child(solid)
	var card: StandardMaterial3D = _city.flat(CARD, 0.95)
	var dark: StandardMaterial3D = _city.flat(BLOCK, 0.9)
	var pale: StandardMaterial3D = _city.flat(PALE, 0.9)
	var out: float = H + W + T * 0.5
	var span: float = (H + W + T) * 2.0
	_city.sheet(self, Vector3(0, 0.006, 0), Vector2(span, span), Color("d9d2c2"))
	_box(self, solid, Vector3(0, HIGH * 0.5, 0), Vector3(H * 2.0, HIGH, H * 2.0), dark)
	_box(self, null, Vector3(0, HIGH + 0.03, 0), Vector3(span, 0.06, span), card)
	# four sides, built alike: side 0 is the south; each is the south's, turned
	for s in 4:
		var turned := Node3D.new()
		turned.name = "Side%d" % s
		turned.rotation.y = float(s) * PI * 0.5
		add_child(turned)
		var bodies := StaticBody3D.new()
		turned.add_child(bodies)
		if s == 0:
			var piece: float = (span - DOOR) * 0.5
			for hand in [-1.0, 1.0]: _box(turned, bodies, Vector3(hand * (DOOR + piece) * 0.5, HIGH * 0.5, out), Vector3(piece, HIGH, T), card)
			_box(turned, bodies, Vector3(0, (HIGH + DOOR_HIGH) * 0.5, out), Vector3(DOOR, HIGH - DOOR_HIGH, T), card)
		else:
			_box(turned, bodies, Vector3(0, HIGH * 0.5, out), Vector3(span, HIGH, T), card)
		# the number on the block's face, and a line under it
		var face: Label3D = _words(turned, Vector3(0, 1.55, H + 0.012), 256, 0.003, PALE)
		_faces.append(face)
		var note: Label3D = _words(turned, Vector3(0, 0.95, H + 0.012), 40, 0.0022, PINK.lightened(0.3))
		_notes.append(note)
		# the door as it looks from inside: a paper screen with OUT on it. On the south it is the real way out and
		# what stands here is the plug that hides it; on the other sides it is the look of a door that is not there.
		var look := Node3D.new()
		look.position = Vector3(0, 0, H + W - 0.004)
		look.rotation.y = PI
		turned.add_child(look)
		if s == 0:
			_panel(look, Vector2(DOOR + 0.02, DOOR_HIGH + 0.02), card).position = Vector3(0, DOOR_HIGH * 0.5, 0.004)
		else:
			_panel(look, Vector2(DOOR, DOOR_HIGH), pale).position = Vector3(0, DOOR_HIGH * 0.5, 0)
			_words(look, Vector3(0, 1.5, 0.006), 90, 0.003, BLOCK).text = "OUT"
		_doors.append(look)
		# a right angle drawn on the floor of the corner this side ends in
		for arm in [Vector3(H + W * 0.5, 0.012, H + W * 0.28), Vector3(H + W * 0.28, 0.012, H + W * 0.5)]:
			var mark := MeshInstance3D.new()
			var strip := BoxMesh.new()
			strip.size = Vector3(W * 0.5, 0.006, 0.05) if is_equal_approx(arm.z, H + W * 0.28) else Vector3(0.05, 0.006, W * 0.5)
			mark.mesh = strip
			mark.material_override = _city.flat(PINK, 0.5)
			mark.position = arm
			turned.add_child(mark)
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(H + W * 0.5, HIGH - 0.35, H + W * 0.5)
		lamp.omni_range = 3.6
		lamp.light_energy = 1.3
		lamp.shadow_enabled = false
		turned.add_child(lamp)
	# the real door's paper screen: walked through, read from both sides
	var screen := Node3D.new()
	screen.name = "Screen"
	screen.position = Vector3(0, 0, H + W + T * 0.5)
	add_child(screen)
	_panel(screen, Vector2(DOOR, DOOR_HIGH), pale).position = Vector3(0, DOOR_HIGH * 0.5, 0.045)
	var inner: MeshInstance3D = _panel(screen, Vector2(DOOR, DOOR_HIGH), pale)
	inner.position = Vector3(0, DOOR_HIGH * 0.5, -0.045)
	inner.rotation.y = PI
	var out_word: Label3D = _words(screen, Vector3(0, 1.5, -0.052), 90, 0.003, BLOCK)
	out_word.rotation.y = PI
	out_word.text = "OUT"
	_sign = _words(screen, Vector3(0, 1.35, 0.052), 90, 0.003, BLOCK)
	# the body, and the board beside the door, turned to the floor
	var sensor := Area3D.new()
	sensor.name = "Reach"
	sensor.collision_layer = 0
	sensor.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(span + 5.0, 3.4, span + 5.0)
	var area := CollisionShape3D.new()
	area.shape = room
	area.position = Vector3(0, 1.7, 0)
	sensor.add_child(area)
	add_child(sensor)
	sensor.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _body = b)
	sensor.body_exited.connect(func(b: Node) -> void:
		if b == _body: _body = null)
	var hand: float = 1.0 if board_east else -1.0
	_board = _city.board(self, Vector3(hand * (H + W + 1.15), 0, 1.5), 3.4, 1.5)
	(_board.get_parent().get_parent() as Node3D).rotation.y = hand * PI * 0.5


## ---- for a test ----

func state() -> Dictionary:
	var shown := []
	for s in 4: shown.append(int(_faces[s].text) if _faces[s].text != "" else 0)
	var doors := []
	for s in 4: doors.append(_doors[s].visible)
	return {"corners": corners, "n": n(), "inside": _inside, "side": _side, "count": _count, "label": label(), "quarter_turns": _quarters, "faces": shown, "door_looks": doors,
		"home": _count != 0 and posmod(_count, n()) == 0, "board": _board.text if _board != null else "", "half": H + W, "block": H, "prefab_parts": int(_city.parts), "build_ms": _build_ms}


## The middle of a side of the building's corridor (0 south, 1 east, 2 north, 3 west), or with `corner` the middle
## of the corner cell that side ends in going round with the block on the left.
func ring_point(side: int, corner: bool = false) -> Vector3:
	var at := Vector3(H + W * 0.5, 0, H + W * 0.5) if corner else Vector3(0, 0, H + W * 0.5)
	return to_global(at.rotated(Vector3.UP, float(side) * PI * 0.5))


func door_point(outside_by: float) -> Vector3:
	return to_global(Vector3(0, 0, H + W + T * 0.5 + outside_by))
