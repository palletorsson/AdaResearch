extends Node3D
## A JOINT MORE (floor AdvancedLaboratory_Lab_Equipment_Simulation; the pass, 2026-11-16)
##
## The hall, of its amber-jointed body: "You can revise a position, then a neighbour. The two operations change
## different parts of the description. What other part would have to become available for the body you want to
## make?" "A list of positions would miss what happened. To reconstruct this body, we also need to know which
## points have been made neighbours." "The catalogue beside it has spare parts. This body cannot yet take one.
## Perhaps the next desire is another joint, another connection, more room. The useful question is which
## operation would let that desire take form."
##
## This is that operation, with more room - a PLAYGROUND form. The same body, thirteen joints and twelve
## connections, drawn on the floor six metres tall. The visitor's feet can ADD to it:
##   stand still on bare floor: a joint is planted there, joined to the nearest joint (the rule chose the
##     neighbour);
##   stand still on a joint: it is HELD, and a line follows you; stand still on bare floor: a joint is planted
##     there, joined to the one you held (you chose the neighbour);
##   hold a joint and stand still on another: a connection between the two (and, perhaps, a loop).
## The authored joints and connections cannot be taken away; CLEAR takes away what was added.
##
## A stand keeps the two lists apart - positions, neighbours - and counts connected parts and loops. The names
## stay: the source still calls it l_hand. `figure` is the axis: authored, limb, loop.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const NAMES := ["head", "chest", "l_shoulder", "r_shoulder", "l_elbow", "r_elbow", "l_hand", "r_hand", "hips", "l_knee", "r_knee", "l_foot", "r_foot"]
const PLACES := [Vector2(0, -2.6), Vector2(0, -1.7), Vector2(-0.8, -1.7), Vector2(0.8, -1.7), Vector2(-1.5, -0.9), Vector2(1.5, -0.9), Vector2(-2.0, 0.0), Vector2(2.0, 0.0), Vector2(0, 0.2),
	Vector2(-0.6, 1.4), Vector2(0.6, 1.4), Vector2(-0.7, 2.7), Vector2(0.7, 2.7)]
const PAIRS := [Vector2i(0, 1), Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 4), Vector2i(4, 6), Vector2i(3, 5), Vector2i(5, 7), Vector2i(1, 8), Vector2i(8, 9), Vector2i(9, 11), Vector2i(8, 10), Vector2i(10, 12)]
const FIGURES := ["authored", "limb", "loop"]
const HALF_X := 3.2
const NORTH := -5.2
const SOUTH := 4.6
const REACH := 0.35                       # how near a joint a body must stand to be on it
const MOST := 12                          # joints a visitor may add
const PLATE_AT := Vector2(2.6, 5.2)
const PLATE := 0.84
const DARK := Color("191e29")
const PALE := Color("efe9dc")
const AMBER := Color("f2a23a")
const STRAW := Color("d9c58a")
const MINE := Color("40e0d0")

@export_enum("authored", "limb", "loop") var figure := "authored"

var _city = City.new()
var _joints: Array = []                   # {name, at: Vector2, mine}
var _pairs: Array = []                    # {a, b, mine}
var _held := -1
var _last_event := ""
var _wait_from := Vector2(999, 999)       # after an act, nothing more until the body has moved away from here
var _drawn: Node3D
var _lead: MeshInstance3D                 # the line from a held joint to the visitor
var _plate_tile: MeshInstance3D
var _lines: Array[Label3D] = []
var _status: Label3D
var _board: Label3D
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_figure"): _take({"figure": get_meta("config_figure")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_found()


func _take(config_data: Dictionary) -> void:
	if config_data.has("figure") and FIGURES.has(str(config_data["figure"])): figure = str(config_data["figure"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := figure
	_take(config_data)
	if is_inside_tree() and _board != null and figure != before: _found()


func _found() -> void:
	_joints.clear()
	_pairs.clear()
	for i in NAMES.size(): _joints.append({"name": NAMES[i], "at": PLACES[i], "mine": false})
	for pair in PAIRS: _pairs.append({"a": pair.x, "b": pair.y, "mine": false})
	_held = -1
	_last_event = ""
	if figure == "limb":
		_joints.append({"name": "joint_14", "at": Vector2(1.9, -3.2), "mine": true})
		_pairs.append({"a": 1, "b": 13, "mine": true})
	elif figure == "loop":
		_pairs.append({"a": 6, "b": 0, "mine": true})
	_draw()
	_show()
	_tell()


## ---- the rule ----

func _joined(a: int, b: int) -> int:
	for i in _pairs.size():
		var p: Dictionary = _pairs[i]
		if (int(p["a"]) == a and int(p["b"]) == b) or (int(p["a"]) == b and int(p["b"]) == a): return i
	return -1


## How many connected parts the joints fall into under the connections.
func parts() -> int:
	var group: Array = []
	for i in _joints.size(): group.append(i)
	for p in _pairs:
		var a: int = group[int(p["a"])]
		var b: int = group[int(p["b"])]
		if a == b: continue
		for i in group.size():
			if group[i] == b: group[i] = a
	var seen := {}
	for g in group: seen[g] = true
	return seen.size()


## Loops: connections that close a circuit (connections - joints + parts).
func loops() -> int:
	return _pairs.size() - _joints.size() + parts()


func _nearest(at: Vector2, skip: int = -1) -> int:
	var best := -1
	var least := 1e9
	for i in _joints.size():
		if i == skip: continue
		var d: float = at.distance_to(_joints[i]["at"])
		if d < least:
			least = d
			best = i
	return best


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _physics_process(delta: float) -> void:
	var body := _visitor()
	if body == null:
		_lead.visible = false
		return
	var p := to_local(body.global_position)
	var at := Vector2(p.x, p.z)
	var level: bool = absf(p.y) < 1.5
	# the line a held joint keeps to the visitor
	_lead.visible = _held >= 0 and level
	if _lead.visible:
		var from: Vector2 = _joints[_held]["at"]
		_lead.position = Vector3((from.x + at.x) * 0.5, 0.05, (from.y + at.y) * 0.5)
		_lead.rotation.y = atan2(-(at.y - from.y), at.x - from.x)
		_lead.scale.x = maxf(from.distance_to(at), 0.01)
	var on_plate: bool = level and absf(p.x - PLATE_AT.x) < PLATE * 0.5 and absf(p.z - PLATE_AT.y) < PLATE * 0.5
	var in_field: bool = level and absf(at.x) <= HALF_X and at.y >= NORTH and at.y <= SOUTH
	var moved: float = Vector2(p.x - _last.x, p.z - _last.z).length()
	_last = p
	if at.distance_to(_wait_from) > 0.5: _wait_from = Vector2(999, 999)
	if moved > 0.3 * delta or not (on_plate or in_field) or _wait_from.x < 900.0:
		_still = 0.0
		return
	_still += delta
	if _still < 0.8: return
	_still = 0.0
	_wait_from = at
	if on_plate: _clear()
	else: _act(at)
	_draw()
	_show()
	_tell()


## What standing still at a place does.
func _act(at: Vector2) -> void:
	var on: int = _nearest(at)
	if on >= 0 and at.distance_to(_joints[on]["at"]) > REACH: on = -1
	if on >= 0:
		if _held < 0:
			_held = on
			_last_event = "held"
		elif _held == on:
			_held = -1
			_last_event = "let go"
		else:
			var existing: int = _joined(_held, on)
			if existing < 0:
				_pairs.append({"a": _held, "b": on, "mine": true})
				_last_event = "connected:%s:%s" % [_joints[_held]["name"], _joints[on]["name"]]
			elif bool(_pairs[existing]["mine"]):
				_pairs.remove_at(existing)
				_last_event = "disconnected:%s:%s" % [_joints[_held]["name"], _joints[on]["name"]]
			else:
				_last_event = "authored:%s:%s" % [_joints[_held]["name"], _joints[on]["name"]]
			_held = -1
		return
	var added: int = 0
	for j in _joints:
		if j["mine"]: added += 1
	if added >= MOST:
		_last_event = "full"
		return
	var chosen: bool = _held >= 0
	var neighbour: int = _held if chosen else _nearest(at)
	_joints.append({"name": "joint_%d" % (_joints.size() + 1), "at": at, "mine": true})
	_pairs.append({"a": neighbour, "b": _joints.size() - 1, "mine": true})
	_last_event = "%s:%s" % ["planted_chosen" if chosen else "planted_nearest", _joints[neighbour]["name"]]
	_held = -1


func _clear() -> void:
	var kept_j: Array = []
	for j in _joints:
		if not j["mine"]: kept_j.append(j)
	var kept_p: Array = []
	for p in _pairs:
		if not p["mine"]: kept_p.append(p)
	_joints = kept_j
	_pairs = kept_p
	_held = -1
	_last_event = "cleared"


func counts() -> Dictionary:
	var mine_j := 0
	var mine_p := 0
	for j in _joints:
		if j["mine"]: mine_j += 1
	for p in _pairs:
		if p["mine"]: mine_p += 1
	return {"joints": _joints.size(), "added_joints": mine_j, "connections": _pairs.size(), "added_connections": mine_p, "parts": parts(), "loops": loops()}


func _status_text() -> String:
	if _held >= 0:
		return "YOU HOLD %s. STAND STILL ON BARE FLOOR FOR A NEW JOINT THERE,\nOR ON ANOTHER JOINT TO CONNECT THE TWO." % str(_joints[_held]["name"])
	var parts_of: PackedStringArray = _last_event.split(":")
	match parts_of[0]:
		"planted_nearest": return "A JOINT MORE. THE RULE GAVE IT A NEIGHBOUR: THE NEAREST, %s.\nYOU CHOSE THE POSITION. YOU DID NOT CHOOSE THE NEIGHBOUR." % parts_of[1]
		"planted_chosen": return "A JOINT MORE, JOINED TO %s BECAUSE YOU HELD IT.\nA POSITION AND A NEIGHBOUR: TWO ENTRIES, IN TWO LISTS." % parts_of[1]
		"connected": return "%s AND %s ARE NEIGHBOURS NOW. NO POINT MOVED.\nLOOPS: %d." % [parts_of[1], parts_of[2], loops()]
		"disconnected": return "THAT CONNECTION WAS YOURS, AND IS TAKEN AWAY."
		"authored": return "%s AND %s WERE JOINED BY THE ONE WHO DREW THIS BODY.\nTHAT CONNECTION IS NOT YOURS TO TAKE AWAY." % [parts_of[1], parts_of[2]]
		"full": return "TWELVE JOINTS ADDED: THIS FLOOR'S LIMIT. SOMEONE SUPPLIED IT."
		"cleared": return "WHAT YOU ADDED IS GONE. THE AUTHORED BODY IS AS IT WAS."
	return "STAND STILL ON BARE FLOOR: A JOINT MORE.\nSTAND STILL ON A JOINT: YOU HOLD IT, AND CHOOSE ITS NEW NEIGHBOUR."


func _show() -> void:
	var c: Dictionary = counts()
	_lines[0].text = "POSITIONS:   13 authored  +  %d yours" % int(c["added_joints"])
	_lines[1].text = "NEIGHBOURS:   12 authored  +  %d yours" % int(c["added_connections"])
	_lines[2].text = "connected parts:  %d     ·     loops:  %d" % [int(c["parts"]), int(c["loops"])]
	_status.text = _status_text()
	(_plate_tile.material_override as StandardMaterial3D).albedo_color = Color("f6e39a") if int(c["added_joints"]) + int(c["added_connections"]) > 0 else PALE


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["A JOINT MORE"])
	lines.append("The body from the workshop, drawn on the floor: thirteen joints, twelve connections. In the workshop you can move a joint and reroute a connection. Its catalogue has spare parts, and that body cannot take one. Here it can, and there is more room.")
	lines.append("Stand still on bare floor: a joint is planted, and a rule joins it to the nearest joint. Stand still on a joint first: you hold it, a line follows you, and the joint you plant is joined to that one. Hold a joint and stand still on another: the two become neighbours. Watch the loop count.")
	lines.append("A list of positions would miss half of what you do here. The names stay where they were: the source still calls it l_hand. What you add, CLEAR takes away. What was drawn before you came, it does not.")
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


## The body as it is now: a line for each connection, a disc and a name for each joint.
func _draw() -> void:
	for child in _drawn.get_children(): child.queue_free()
	for p in _pairs:
		var a: Vector2 = _joints[int(p["a"])]["at"]
		var b: Vector2 = _joints[int(p["b"])]["at"]
		var line: MeshInstance3D = _box(_drawn, Vector3((a.x + b.x) * 0.5, 0.02 if not p["mine"] else 0.026, (a.y + b.y) * 0.5), Vector3(a.distance_to(b), 0.008, 0.09), _plain(MINE if p["mine"] else STRAW))
		line.rotation.y = atan2(-(b.y - a.y), b.x - a.x)
	for i in _joints.size():
		var j: Dictionary = _joints[i]
		var at: Vector2 = j["at"]
		var disc := MeshInstance3D.new()
		var shape := CylinderMesh.new()
		shape.top_radius = 0.2 if i != _held else 0.27
		shape.bottom_radius = shape.top_radius
		shape.height = 0.03
		disc.mesh = shape
		disc.material_override = _plain(MINE if j["mine"] else AMBER)
		disc.position = Vector3(at.x, 0.03, at.y)
		_drawn.add_child(disc)
		var tag: Label3D = _city.floor_words(_drawn, Vector3(at.x, 0.05, at.y + 0.36), str(j["name"]), 30, MINE if j["mine"] else PALE)
		tag.outline_size = 4


func _build_once() -> void:
	# the field: its edge, drawn faintly
	var edge: StandardMaterial3D = _plain(Color("4a5062"))
	for hand in [-1.0, 1.0]: _box(self, Vector3(hand * HALF_X, 0.01, (NORTH + SOUTH) * 0.5), Vector3(0.03, 0.006, SOUTH - NORTH), edge)
	for z in [NORTH, SOUTH]: _box(self, Vector3(0, 0.01, z), Vector3(HALF_X * 2.0, 0.006, 0.03), edge)
	_drawn = Node3D.new()
	_drawn.name = "Body"
	add_child(_drawn)
	_lead = _box(self, Vector3.ZERO, Vector3(1.0, 0.01, 0.05), _plain(MINE))
	_lead.visible = false
	# the plate
	_plate_tile = _box(self, Vector3(PLATE_AT.x, 0.012, PLATE_AT.y), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8))
	_city.floor_words(self, Vector3(PLATE_AT.x, 0.035, PLATE_AT.y), "CLEAR WHAT\nI ADDED", 44, DARK).outline_size = 0
	# the stand: the two lists, kept apart
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(0, 0, -5.8)
	add_child(stand)
	var held := StaticBody3D.new()
	stand.add_child(held)
	_box(stand, Vector3(0, 2.2, -0.05), Vector3(4.8, 2.0, 0.06), _city.flat(DARK, 0.85))
	_city.wall(held, Vector3(0, 0, -0.05), Vector3(4.8, 3.2, 0.12))
	for hand in [-1.0, 1.0]: _box(stand, Vector3(hand * 2.3, 0.6, -0.05), Vector3(0.08, 1.2, 0.08), _city.flat(DARK, 0.85))
	var heights := [2.92, 2.58, 2.26]
	var sizes := [34, 34, 26]
	var colours := [AMBER, STRAW, PALE]
	for i in 3: _lines.append(_words(stand, Vector3(0, float(heights[i]), 0), int(sizes[i]), 0.005, colours[i]))
	_status = _words(stand, Vector3(0, 1.68, 0), 22, 0.005, MINE)
	_board = _city.board(self, Vector3(-0.6, 0, 6.0), 3.2, 1.7)


## ---- for a test ----

func state() -> Dictionary:
	var c: Dictionary = counts()
	c["held"] = str(_joints[_held]["name"]) if _held >= 0 else ""
	c["last_event"] = _last_event
	c["names"] = _joints.map(func(j): return j["name"])
	c["added"] = _pairs.filter(func(p): return p["mine"]).map(func(p): return "%s-%s" % [_joints[int(p["a"])]["name"], _joints[int(p["b"])]["name"]])
	c["status"] = _status.text
	c["lines"] = _lines.map(func(l): return l.text)
	c["lead_shown"] = _lead.visible
	c["board"] = _board.text if _board != null else ""
	c["build_ms"] = _build_ms
	return c


func joint_point(joint_name: String) -> Vector3:
	for j in _joints:
		if str(j["name"]) == joint_name: return to_global(Vector3((j["at"] as Vector2).x, 0, (j["at"] as Vector2).y))
	return global_position


func plate_point() -> Vector3:
	return to_global(Vector3(PLATE_AT.x, 0, PLATE_AT.y))


func local_point(x: float, z: float) -> Vector3:
	return to_global(Vector3(x, 0, z))
