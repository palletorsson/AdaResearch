extends Node3D
## WHAT FOLLOWS? (floor Florensky_Paraconsistent; the pass, 2026-11-15)
##
## The hall keeps two reports about one door - P: open, not-P: closed - and reads a last line off its display:
## "Q: alarm triggered = NO SUPPORT." In classical logic, it says, "if both P and not-P are available as premises,
## any proposition Q follows. This is called explosion: the premises cease to constrain the conclusion." And:
## "A system can preserve conflicting descriptions and still have to decide who gets through."
## This is that decision at body size - a PLAYGROUND form: seven doors, each with a sentence over it, and the rule
## that opens them.
##
## Stand still on a plate to give a report or take it back: P (the door is open), not-P (the door is closed).
## Every door whose sentence FOLLOWS swings open, and a body can walk through it. Behind the door "the alarm rang"
## hangs a bell. Under the rule the hall's working copy uses (four values: told true, told false, both, neither)
## you may hold both reports and five doors open - the bell's stays shut: no support. Stand on RULE to read the
## same two reports classically: all seven open, and you can walk in and ring an alarm nobody reported.
## With no reports at all the four-valued rule opens nothing, not even "P or not-P"; the classical one opens that.
##
## The classical rule is done by looking: a sentence follows when no way of making P and Q true or false fits the
## reports and fails the sentence (with both reports no way fits, so nothing fails). The four-valued one is the
## fragment the hall's tutorial states: negation swaps the two supports, "and" needs both told true and either
## told false, "or" the other way round; a door opens when its sentence is told true.
##
## `rule` is the axis: four, classical.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const DOORS := [["p", "P\nthe door is open"], ["np", "not-P\nthe door is closed"], ["both", "P and not-P"], ["either", "P or not-P"], ["p_or_q", "P, or the alarm rang"], ["q", "Q\nthe alarm rang"],
	["nq", "not-Q\nthe alarm did not ring"]]
const PITCH := 1.25
const LEAF := 0.95
const HIGH := 2.15
const BAY := 1.3
const PLATES := {"p": Vector3(-1.2, 0, 2.8), "np": Vector3(0.0, 0, 2.8), "rule": Vector3(1.4, 0, 2.8), "clear": Vector3(2.6, 0, 2.8)}
const CARD := Color("c4a070")
const BLUE := Color("3f6fd0")
const RED := Color("c1121c")
const INK := Color("191e29")

@export_enum("four", "classical") var rule := "four"

var _city = City.new()
var _p := false
var _np := false
var _leaves: Array[Node3D] = []
var _shapes: Array[CollisionShape3D] = []
var _open: Array[bool] = []
var _marks := {}
var _bell: Node3D
var _bell_tag: Label3D
var _board: Label3D
var _rung := 0
var _in_bay := false
var _on := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_rule"): _take({"rule": get_meta("config_rule")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_judge()


func _take(config_data: Dictionary) -> void:
	if config_data.has("rule") and str(config_data["rule"]) in ["four", "classical"]: rule = str(config_data["rule"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := rule
	_take(config_data)
	if is_inside_tree() and _board != null and rule != before: _judge()


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


## ---- the two rules ----

## Is the sentence true when P and Q are simply true or false?
static func holds(id: String, p: bool, q: bool) -> bool:
	match id:
		"p": return p
		"np": return not p
		"both": return p and not p
		"either": return p or not p
		"p_or_q": return p or q
		"q": return q
		"nq": return not q
	return false


## Classically: no way of settling P and Q fits the reports and fails the sentence.
static func follows_classically(id: String, told_p: bool, told_np: bool) -> bool:
	for p in [false, true]:
		for q in [false, true]:
			if (told_p and not p) or (told_np and p): continue
			if not holds(id, p, q): return false
	return true


## Four values: a claim is a pair [told true, told false]. A sentence is designated when it is told true.
static func told(id: String, told_p: bool, told_np: bool) -> Array:
	var p := [told_p, told_np]
	var q := [false, false]
	var not_p := [p[1], p[0]]
	match id:
		"p": return p
		"np": return not_p
		"both": return [p[0] and not_p[0], p[1] or not_p[1]]
		"either": return [p[0] or not_p[0], p[1] and not_p[1]]
		"p_or_q": return [p[0] or q[0], p[1] and q[1]]
		"q": return q
		"nq": return [q[1], q[0]]
	return [false, false]


func follows(id: String) -> bool:
	if rule == "classical": return follows_classically(id, _p, _np)
	return bool(told(id, _p, _np)[0])


func _judge() -> void:
	for i in DOORS.size():
		_open[i] = follows(str(DOORS[i][0]))
		_shapes[i].set_deferred("disabled", _open[i])
	(_marks["p"] as MeshInstance3D).material_override = _city.flat(BLUE if _p else BLUE.darkened(0.6), 0.5)
	(_marks["np"] as MeshInstance3D).material_override = _city.flat(RED if _np else RED.darkened(0.6), 0.5)
	_tell()


func _process(delta: float) -> void:
	for i in _leaves.size():
		var want: float = 1.75 if _open[i] else 0.0      # into its bay, along the partition
		_leaves[i].rotation.y = move_toward(_leaves[i].rotation.y, want, delta * 4.0)
	if _bell != null: _bell.rotation.z = 0.5 * sin(Time.get_ticks_msec() * 0.012) * clampf(1.0 - (Time.get_ticks_msec() - int(_bell.get_meta("rung_at", -99999))) / 2500.0, 0.0, 1.0)


func _physics_process(delta: float) -> void:
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var moved: float = p.distance_to(_last)
	_last = p
	# in the alarm's bay?
	var bay_x: float = (5.0 - 3.0) * PITCH
	var inside: bool = absf(p.x - bay_x) < PITCH * 0.5 - 0.1 and p.z < -0.25 and p.z > -BAY and absf(p.y) < 1.0
	if inside and not _in_bay:
		_rung += 1
		_bell.set_meta("rung_at", Time.get_ticks_msec())
		_bell_tag.text = "RUNG x %d" % _rung
		_tell()
	_in_bay = inside
	var on := ""
	if absf(p.y) < 0.6:
		for key in PLATES:
			if Vector2(p.x - (PLATES[key] as Vector3).x, p.z - (PLATES[key] as Vector3).z).length() < 0.32: on = key
	if on != _on or moved > 0.004:
		_on = on
		_still = 0.0
		return
	if on == "": return
	_still += delta
	if _still >= 0.8:
		_still = -99.0
		press(on)


func press(key: String) -> void:
	match key:
		"p": _p = not _p
		"np": _np = not _np
		"rule": rule = "classical" if rule == "four" else "four"
		"clear":
			_p = false
			_np = false
	_judge()


func _tell() -> void:
	if _board == null: return
	var count := 0
	for o in _open:
		if o: count += 1
	var reports := "none" if not _p and not _np else ("P and not-P, both" if _p and _np else ("P" if _p else "not-P"))
	var lines := PackedStringArray(["WHAT FOLLOWS?"])
	lines.append("Seven doors, a sentence over each. Stand still on a plate to give a report about one door or take it back: P, it is open; not-P, it is closed. Every door whose sentence follows from your reports swings open.")
	lines.append("Reports held: %s.   Rule: %s.   Doors open: %d of 7." % [reports, "FOUR VALUES (told true / told false / both / neither)" if rule == "four" else "CLASSICAL (true or false, nothing else)", count])
	if _p and _np:
		if rule == "four": lines.append("You hold both, and the room stands. Five doors open. The alarm's does not: your two reports say nothing about an alarm. No support - which is not 'it did not ring'; that door is shut too.")
		else: lines.append("You hold both, read classically: nothing can fit both reports, so nothing can fail. Every door is open. Go in and ring the alarm nobody reported. This is explosion.")
	elif not _p and not _np:
		if rule == "four": lines.append("Nothing told, nothing opens - not even 'P or not-P'. Under this rule a sentence needs a report behind it.")
		else: lines.append("Nothing told, and 'P or not-P' is open already: classically it needs no report.")
	if _rung > 0: lines.append("The alarm has been rung %d time%s. No report ever mentioned it." % [_rung, "" if _rung == 1 else "s"])
	lines.append("Holding two reports that disagree is easy: two places in memory. The work is in the rule that says which doors that opens - and somebody chose the rule. RULE is the third plate.")
	_board.text = "\n".join(lines)


## ---- building, once ----

func _block(parent: Node3D, solid: StaticBody3D, at: Vector3, size: Vector3, paint: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = paint
	mesh.position = at
	parent.add_child(mesh)
	if solid != null: _city.wall(solid, at - Vector3(0, size.y * 0.5, 0), size)
	return mesh


func _label(parent: Node3D, at: Vector3, text: String, size: int, colour: Color, wide: float = 0.0) -> Label3D:
	var words := Label3D.new()
	words.text = text
	words.font_size = size
	words.pixel_size = 0.0024
	words.modulate = colour
	words.outline_size = 0
	words.double_sided = false
	if wide > 0.0:
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.width = wide / 0.0024
	words.position = at
	parent.add_child(words)
	return words


func _build_once() -> void:
	var solid := StaticBody3D.new()
	add_child(solid)
	var card: StandardMaterial3D = _city.flat(CARD, 0.95)
	var dark: StandardMaterial3D = _city.flat(INK, 0.8)
	var n: int = DOORS.size()
	var span: float = PITCH * float(n)
	_block(self, solid, Vector3(0, HIGH * 0.5 + 0.2, -BAY - 0.04), Vector3(span + 0.16, HIGH + 0.4, 0.08), card)
	_block(self, null, Vector3(0, HIGH + 0.44, -BAY * 0.5), Vector3(span + 0.16, 0.08, BAY + 0.1), card)
	for i in n + 1:
		var x: float = (float(i) - float(n) * 0.5) * PITCH
		_block(self, solid, Vector3(x, HIGH * 0.5 + 0.2, -BAY * 0.5), Vector3(0.08, HIGH + 0.4, BAY), card)
		_block(self, solid, Vector3(x, HIGH * 0.5, 0), Vector3(PITCH - LEAF, HIGH, 0.12), dark)
	_block(self, null, Vector3(0, HIGH + 0.2, 0), Vector3(span + 0.16, 0.4, 0.12), dark)
	for i in n:
		var x: float = (float(i) - float(n - 1) * 0.5) * PITCH
		_label(self, Vector3(x, HIGH + 0.2, 0.066), str(DOORS[i][1]), 30, Color("efe9dc"), PITCH - 0.12)
		var hinge := Node3D.new()
		hinge.position = Vector3(x - LEAF * 0.5, 0, 0)
		add_child(hinge)
		var paint: StandardMaterial3D = _city.flat(Color("d9d2c2") if str(DOORS[i][0]) != "q" else Color("e8b04a"), 0.8)
		_block(hinge, null, Vector3(LEAF * 0.5, HIGH * 0.5, 0), Vector3(LEAF, HIGH, 0.05), paint)
		_leaves.append(hinge)
		var stop := StaticBody3D.new()
		add_child(stop)
		_shapes.append(_city.wall(stop, Vector3(x, 0, 0), Vector3(LEAF, HIGH, 0.1)))
		_open.append(false)
	# behind the alarm's door, the bell; behind the others, a line on the wall
	var bell_x: float = (5.0 - float(n - 1) * 0.5) * PITCH
	_bell = Node3D.new()
	_bell.position = Vector3(bell_x, 1.75, -BAY + 0.45)
	add_child(_bell)
	var cup := CylinderMesh.new()
	cup.top_radius = 0.06
	cup.bottom_radius = 0.24
	cup.height = 0.34
	var cup_node := MeshInstance3D.new()
	cup_node.mesh = cup
	cup_node.material_override = _city.flat(Color("e8b04a"), 0.25)
	cup_node.position = Vector3(0, -0.24, 0)
	_bell.add_child(cup_node)
	_bell_tag = _label(self, Vector3(bell_x, 1.05, -BAY + 0.01), "the alarm.\nno report mentions it.", 28, INK, PITCH - 0.2)
	var why := ["told so", "told so", "both were told", "one of them was told", "P was told", "", "nobody was told this either"]
	for i in n:
		if why[i] == "": continue
		_label(self, Vector3((float(i) - float(n - 1) * 0.5) * PITCH, 1.4, -BAY + 0.01), why[i], 28, INK, PITCH - 0.2)
	# the plates
	var names := {"p": ["P", BLUE], "np": ["not-P", RED], "rule": ["RULE", Color("5a5d66")], "clear": ["CLEAR", Color("5a5d66")]}
	for key in PLATES:
		var mark := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.3
		disc.bottom_radius = 0.3
		disc.height = 0.012
		mark.mesh = disc
		mark.material_override = _city.flat(names[key][1], 0.5)
		mark.position = (PLATES[key] as Vector3) + Vector3(0, 0.008, 0)
		mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mark)
		_marks[key] = mark
		_city.floor_words(self, (PLATES[key] as Vector3) + Vector3(0, 0.02, 0), str(names[key][0]), 40, Color(0.98, 0.97, 0.94))
	_board = _city.board(self, Vector3(-3.4, 0, 3.4), 3.4, 1.6)


## ---- for a test ----

func state() -> Dictionary:
	var open := []
	for i in DOORS.size():
		if _open[i]: open.append(str(DOORS[i][0]))
	return {"rule": rule, "p": _p, "not_p": _np, "open": open, "rung": _rung, "doors": DOORS.size(), "board": _board.text if _board != null else "", "prefab_parts": int(_city.parts), "build_ms": _build_ms}


func plate_point(key: String) -> Vector3:
	return to_global(PLATES[key])


## In front of door i (from 0), `by` metres south of it; negative: inside its bay.
func door_point(i: int, by: float) -> Vector3:
	return to_global(Vector3((float(i) - float(DOORS.size() - 1) * 0.5) * PITCH, 0, by))
