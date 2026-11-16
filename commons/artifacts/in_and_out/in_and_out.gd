extends Node3D
## IN AND OUT, WALKED (floor Russell_Paradox; the pass, gone back to on 2026-11-16)
##
## The hall, of its workbench: "Choose IN. Follow what the readout requires. Now choose OUT. Neither button is
## broken. Each answer contradicts the rule that was supposed to make the collection." "The arrows turn around the
## same disc. Your hand has somewhere to go; the proposed set does not." And of cell 6: "One phrase has changed
## what can be built: within U." This is the two buttons as two gates on one corridor - a PLAYGROUND form.
##
## A corridor round an island, fenced with plank rails. Two gates stand across it: IN and OUT. Walk through IN:
## you have answered that R belongs to R, and the rule sends you on, to OUT. Walk through OUT: you have answered
## that it does not, and the rule sends you on, to IN. The stand counts the answers tried and the answers that
## settled: none. Walk out of the corridor the way you came: a body has somewhere to go.
##
## WITHIN U changes one phrase of the rule, and one rail: beside OUT a way opens out of the corridor. Under the
## rule that filters a collection that already exists, OUT holds, and nothing sends you on.
##
## `rule` is the axis: unrestricted, within_u.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const OUTER_X := 2.0
const OUTER_Z := 1.5
const ISLE_X := 1.0
const ISLE_Z := 0.3
const DOOR := 0.6                         # half the width of the way in, in the middle of the south side
const RULES := ["unrestricted", "within_u"]
const PLATE_AT := Vector2(1.7, 2.4)
const PLATE := 0.84
const DARK := Color("191e29")
const PALE := Color("efe9dc")
const HOT := Color("ff5a3c")
const CALM := Color("7af08a")

@export_enum("unrestricted", "within_u") var rule := "unrestricted"

var _city = City.new()
var _within := false
var _answers := 0
var _settled := 0
var _last := ""                           # "in", "out" or ""
var _left := false                        # the visitor has been in the corridor and walked out of it
var _side := 0                            # which side of the gates' line the visitor was on, last tick
var _was_inside := false
var _way_out: Node3D                      # the rail that closes the way out beside OUT
var _way_solid: CollisionShape3D
var _arrows := {}
var _plate_tile: MeshInstance3D
var _lines: Array[Label3D] = []
var _status: Label3D
var _board: Label3D
var _region := ""
var _still := 0.0
var _last_at := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_rule"): _take({"rule": get_meta("config_rule")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_found()


func _take(config_data: Dictionary) -> void:
	if config_data.has("rule") and RULES.has(str(config_data["rule"])): rule = str(config_data["rule"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := rule
	_take(config_data)
	if is_inside_tree() and _board != null and rule != before: _found()


func _found() -> void:
	_within = rule == "within_u"
	_answers = 0
	_settled = 0
	_last = ""
	_left = false
	_show()
	_tell()


## ---- the rule ----

## What the rule answers to an answer: {"says": ..., "sends": "in" | "out" | ""}. Under the unrestricted rule
## each answer is sent to the other; within U, OUT holds and IN is simply wrong.
static func reply(answer: String, within: bool) -> Dictionary:
	if not within:
		if answer == "in": return {"says": "THEN R FAILS ITS OWN CONDITION. IT IS NOT IN R.", "sends": "out"}
		return {"says": "THEN R MEETS ITS OWN CONDITION. IT IS IN R.", "sends": "in"}
	if answer == "in": return {"says": "NO: U IS NOT ONE OF 0, 1, 2, 3.", "sends": "out"}
	return {"says": "IT HOLDS. R IS U, AND U IS NOT ONE OF ITS FOUR MEMBERS.", "sends": ""}


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _physics_process(delta: float) -> void:
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var level: bool = absf(p.y) < 1.5
	var inside: bool = level and absf(p.x) < OUTER_X and absf(p.z) < OUTER_Z
	# a gate is passed when the body goes from one side of the gates' line to the other inside an end of the corridor
	var side: int = 1 if p.z > 0.0 else -1
	if inside and _was_inside and side != _side and absf(p.x) > ISLE_X:
		_last = "in" if p.x < 0.0 else "out"
		_answers += 1
		_left = false
		if str(reply(_last, _within)["sends"]) == "": _settled += 1
		_show()
	if _was_inside and not inside and _answers > 0 and not _left:
		_left = true
		_show()
	_side = side
	_was_inside = inside
	var region := "plate" if level and absf(p.x - PLATE_AT.x) < PLATE * 0.5 and absf(p.z - PLATE_AT.y) < PLATE * 0.5 else ""
	var moved: float = Vector2(p.x - _last_at.x, p.z - _last_at.z).length()
	_last_at = p
	if region != _region or moved > 0.3 * delta:
		_still = 0.0
	elif _still >= 0.0:
		_still += delta
	_region = region
	if _still >= 0.8 and region != "":
		_still = -99.0
		_within = not _within
		rule = "within_u" if _within else "unrestricted"
		_answers = 0
		_settled = 0
		_last = ""
		_left = false
		_show()
		_tell()


func _show() -> void:
	_way_out.visible = not _within
	_way_solid.disabled = _within
	_lines[0].text = "R  =  the members of U that are not members of themselves\nU  =  { 0, 1, 2, 3 }" if _within else "R  =  all sets that are not members of themselves"
	if _last == "":
		_lines[1].text = "DOES R BELONG TO R?   WALK THROUGH A GATE."
		_lines[2].text = ""
	else:
		var r: Dictionary = reply(_last, _within)
		_lines[1].text = "YOUR ANSWER:   R IS %s R." % ("IN" if _last == "in" else "NOT IN")
		_lines[2].text = "THE RULE:   %s%s" % [str(r["says"]), ("\nGO TO %s." % str(r["sends"]).to_upper()) if str(r["sends"]) != "" else ""]
	_lines[2].modulate = CALM if _within and _last == "out" else HOT
	_lines[3].text = "answers tried:  %d     ·     answers that settled:  %d" % [_answers, _settled]
	if _left and _settled == 0: _status.text = "YOU WALKED OUT. A BODY HAS SOMEWHERE TO GO.\nTHE PROPOSED SET DOES NOT."
	elif _left: _status.text = "YOU WALKED OUT WITH AN ANSWER THAT HELD.\nONE PHRASE CHANGED WHAT COULD BE BUILT: WITHIN U."
	elif _within: _status.text = "THE RULE NOW FILTERS A COLLECTION THAT ALREADY EXISTS.\nA WAY HAS OPENED BESIDE OUT."
	else: _status.text = "NEITHER GATE IS BROKEN.\nEACH ANSWER IS SENT TO THE OTHER."
	var sends: String = str(reply(_last, _within)["sends"]) if _last != "" else ""
	for key in _arrows: (_arrows[key] as Label3D).modulate = HOT if key == sends else Color("5b6274")
	(_plate_tile.material_override as StandardMaterial3D).albedo_color = Color("f6e39a") if _within else PALE


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["IN AND OUT, WALKED"])
	lines.append("The workbench by the arrival has two buttons. Here they are two gates on one corridor. Go in at the middle of the south side and walk through IN: you have said that R belongs to R. Read the stand, and go where it sends you. Then again.")
	lines.append("Neither gate is broken. The corridor is not a difficulty in deciding: it is what the rule does to either decision. You can walk out the way you came. The set the rule asks for cannot.")
	lines.append("WITHIN U changes one phrase of the rule and takes away one rail. Walk through OUT again, and look to your side.")
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


## A plank on edge as a rail, 0.9 m up: `metres` long (1, 2 or 4), along x (yaw 0) or along z (yaw 90).
func _rail(parent: Node3D, at: Vector3, yaw: float, metres: int) -> void:
	var bar: Node3D = _city.part(parent, "timber_plank_%dm" % metres, at + Vector3(0, 0.9, 0), yaw, Vector3.ZERO, false)
	bar.rotation_degrees.x = 90.0


func _post(at: Vector3) -> void:
	var post: Node3D = _city.part(self, "timber_plank_1m", at + Vector3(0, 0.5, 0), 0.0, Vector3.ZERO, false)
	post.rotation_degrees.z = 90.0


## A gate: two tall posts, a board across them with its name on both faces.
func _gate(x: float, says: String) -> void:
	var wood: StandardMaterial3D = _city.flat(Color("6b4a32"), 0.9)
	for hand in [-0.5, 0.5]: _box(self, Vector3(x + hand, 1.1, 0), Vector3(0.08, 2.2, 0.08), wood)
	_box(self, Vector3(x, 2.35, 0), Vector3(1.1, 0.42, 0.05), _city.flat(DARK, 0.85))
	for face in [1.0, -1.0]:
		var name_board: Label3D = _words(self, Vector3(x, 2.35, 0.03 * face), 64, 0.005, PALE)
		name_board.text = says
		name_board.rotation.y = 0.0 if face > 0.0 else PI


func _build_once() -> void:
	var solid := StaticBody3D.new()
	solid.name = "Rails"
	add_child(solid)
	# the outer fence: north, west, east, and the south side in two parts with the way in between them
	_rail(self, Vector3(0, 0, -OUTER_Z), 0.0, 4)
	_city.wall(solid, Vector3(0, 0, -OUTER_Z), Vector3(OUTER_X * 2.0, 1.1, 0.08))
	_rail(self, Vector3(-OUTER_X, 0, -0.5), 90.0, 2)
	_rail(self, Vector3(-OUTER_X, 0, 1.0), 90.0, 1)
	_city.wall(solid, Vector3(-OUTER_X, 0, 0), Vector3(0.08, 1.1, OUTER_Z * 2.0))
	_rail(self, Vector3(OUTER_X, 0, -0.5), 90.0, 2)
	_city.wall(solid, Vector3(OUTER_X, 0, -0.5), Vector3(0.08, 1.1, 2.0))
	for hand in [-1.0, 1.0]:
		_rail(self, Vector3(hand * (DOOR + 0.7), 0, OUTER_Z), 0.0, 1)
		_city.wall(solid, Vector3(hand * (DOOR + 0.7), 0, OUTER_Z), Vector3(1.4, 1.1, 0.08))
	for corner in [Vector3(-OUTER_X, 0, -OUTER_Z), Vector3(OUTER_X, 0, -OUTER_Z), Vector3(-OUTER_X, 0, OUTER_Z), Vector3(OUTER_X, 0, OUTER_Z), Vector3(-DOOR, 0, OUTER_Z), Vector3(DOOR, 0, OUTER_Z)]: _post(corner)
	# the rail beside OUT that the phrase `within U` takes away
	_way_out = Node3D.new()
	_way_out.name = "WayOut"
	add_child(_way_out)
	_rail(_way_out, Vector3(OUTER_X, 0, 1.0), 90.0, 1)
	_way_solid = _city.wall(solid, Vector3(OUTER_X, 0, 1.0), Vector3(0.08, 1.1, 1.0))
	_city.floor_words(self, Vector3(OUTER_X + 0.75, 0.03, 1.0), "within U:\na way out", 34, PALE)
	# the island
	for hand in [-1.0, 1.0]: _rail(self, Vector3(0, 0, hand * ISLE_Z), 0.0, 2)
	_city.wall(solid, Vector3(0, 0, 0), Vector3(ISLE_X * 2.0, 1.1, ISLE_Z * 2.0 + 0.08))
	_city.floor_words(self, Vector3(0, 0.03, 0), "R", 120, HOT)
	# the two gates across the ends of the corridor, and what the rule points at
	_gate(-(OUTER_X + ISLE_X) * 0.5, "IN")
	_gate((OUTER_X + ISLE_X) * 0.5, "OUT")
	_arrows["out"] = _city.floor_words(self, Vector3(0, 0.03, -(OUTER_Z + ISLE_Z) * 0.5), "the rule sends you to OUT  →", 40, HOT)
	_arrows["in"] = _city.floor_words(self, Vector3(0, 0.03, (OUTER_Z + ISLE_Z) * 0.5), "←  the rule sends you to IN", 40, HOT)
	_city.floor_words(self, Vector3(0, 0.03, OUTER_Z + 0.45), "the way in, and the way out", 34, PALE)
	# the plate that changes one phrase
	_plate_tile = _box(self, Vector3(PLATE_AT.x, 0.012, PLATE_AT.y), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8))
	_city.floor_words(self, Vector3(PLATE_AT.x, 0.035, PLATE_AT.y), "WITHIN U", 50, DARK).outline_size = 0
	# the stand, raised behind the corridor
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(0, 0, -OUTER_Z - 0.75)
	add_child(stand)
	var held := StaticBody3D.new()
	stand.add_child(held)
	_box(stand, Vector3(0, 3.7, -0.05), Vector3(5.2, 2.0, 0.06), _city.flat(DARK, 0.85))
	for hand in [-1.0, 1.0]:
		_box(stand, Vector3(hand * 2.5, 1.35, -0.05), Vector3(0.08, 2.7, 0.08), _city.flat(DARK, 0.85))
		_city.wall(held, Vector3(hand * 2.5, 0, -0.05), Vector3(0.1, 4.7, 0.1))
	var heights := [4.42, 4.02, 3.62, 3.28]
	var sizes := [24, 28, 24, 22]
	var colours := [Color("f6e39a"), PALE, HOT, Color("b9c0cc")]
	for i in 4: _lines.append(_words(stand, Vector3(0, float(heights[i]), 0), int(sizes[i]), 0.006, colours[i]))
	_status = _words(stand, Vector3(0, 2.95, 0), 20, 0.006, Color("f2a23a"))
	_board = _city.board(self, Vector3(4.6, 0, 2.4), 3.0, 1.6)


## ---- for a test ----

func state() -> Dictionary:
	return {"rule": "within_u" if _within else "unrestricted", "answers": _answers, "settled": _settled, "last": _last, "left": _left, "way_out_open": _way_solid.disabled,
		"sends": str(reply(_last, _within)["sends"]) if _last != "" else "", "lines": _lines.map(func(l): return l.text), "status": _status.text, "board": _board.text if _board != null else "", "build_ms": _build_ms}


func plate_point() -> Vector3:
	return to_global(Vector3(PLATE_AT.x, 0, PLATE_AT.y))


func local_point(x: float, z: float) -> Vector3:
	return to_global(Vector3(x, 0, z))
