extends Node3D
## WHAT THE HAND OFFERS, WHAT THE BODY USES (floor QFEP_Sandbox; the pass, 2026-11-15)
##
## The hall: "A number displayed on a control becomes a system parameter only when the system uses it in its next
## calculation." "Cut the route again. Move the handle back. The receiver keeps its last inputs, including the one
## you were trying to undo. Disconnection has left a memory of your action. It has not restored an innocent
## beginning." "A useful record keeps both sides of that difference: what the hand offers and what the body still
## uses." "The name of the parameter did not decide that consequence. Someone wrote this mapping." This is that
## wiring study with a receiver a body can test with itself - a PLAYGROUND form.
##
## A rail five metres long: where the visitor last walked along it is the value OFFERED, 0 to 1, and a puck stays
## there (crossing the rail on the way to the gate offers nothing). North of it a gate of two sliding panels: the value it USES sets how far it stands open. Between them a
## strip on the floor: the route. At first it is cut. Walk the rail: the puck follows, the gate does not, and the
## gate is too narrow to pass.
##
## CONNECT / CUT lights the route and the gate takes what the rail offers. Open it, walk through. Close it, cut
## the route, and walk the rail back to open: the gate stays shut. It kept the last value it was given. OTHER
## MAPPING turns the consequence round - the same number now closes what it opened - and the stand says someone
## wrote both. Beside it a second gate opens and closes on its own; no route leads to it.
##
## The stand always shows both sides: offered at the rail, used at the gate. `route` is the axis: cut, connected.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const HALF := 2.6                        # half the rail's length
const LANE := 0.55
const RAIL_Z := 1.0
const GATE_Z := -1.6
const WIDE := 2.4                        # the gate fully open
const NEIGHBOUR_X := 4.2
const PLATES := [
	{"key": "route", "says": "CONNECT\n/ CUT", "at": Vector2(-0.7, 2.6)},
	{"key": "mapping", "says": "OTHER\nMAPPING", "at": Vector2(0.7, 2.6)},
]
const PLATE := 0.84
const CARD := Color("c4a070")
const DARK := Color("191e29")
const PALE := Color("efe9dc")
const LIVE := Color("40f2ff")
const DEAD := Color("4a4f5c")

@export_enum("cut", "connected") var route := "cut"

var _city = City.new()
var _offered := 0.5
var _used := 0.1                         # 0.24 m of opening: a body does not pass (0.48 m let the tower's walker through)
var _connected := false
var _wider := true                       # the mapping: more opens it; or, the other way, more closes it
var _clock := 0.0
var _puck: MeshInstance3D
var _strip: MeshInstance3D
var _panels: Array[Node3D] = []          # the gate's two, then the neighbour's two
var _plate_tiles: Array[MeshInstance3D] = []
var _lines: Array[Label3D] = []
var _status: Label3D
var _board: Label3D
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_route"): _take({"route": get_meta("config_route")})
	_connected = route == "connected"
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	if _connected: _used = _offered
	_show()
	_tell()


func _take(config_data: Dictionary) -> void:
	if config_data.has("route") and str(config_data["route"]) in ["cut", "connected"]: route = str(config_data["route"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := route
	_take(config_data)
	if is_inside_tree() and _board != null and route != before:
		_offered = 0.5
		_used = 0.1
		_wider = true
		_connected = route == "connected"
		if _connected: _used = _offered
		_show()
		_tell()


## ---- the rule ----

## How far the gate stands open for the value it uses, under the mapping somebody wrote.
static func opening(used: float, wider: bool) -> float:
	return (used if wider else 1.0 - used) * WIDE


func neighbour_opening() -> float:
	return 1.2 + 1.1 * sin(_clock * 0.5)


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _physics_process(delta: float) -> void:
	_clock += delta
	_slide(2, NEIGHBOUR_X, neighbour_opening())
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var region := ""
	if absf(p.y) < 1.5:
		if absf(p.x) <= HALF and absf(p.z - RAIL_Z) <= LANE: region = "rail"
		else:
			for plate in PLATES:
				var at: Vector2 = plate["at"]
				if absf(p.x - at.x) < PLATE * 0.5 and absf(p.z - at.y) < PLATE * 0.5: region = str(plate["key"])
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
		if absf(value - _offered) > 0.0005:
			_offered = value
			if _connected: _used = _offered          # the system uses it in its next calculation: only when the route is made
			_show()
	if _still >= 0.8 and region != "" and region != "rail":
		_still = -99.0
		if region == "route":
			_connected = not _connected
			if _connected: _used = _offered
		else:
			_wider = not _wider
		_show()
		_tell()


func _slide(first: int, middle: float, open: float) -> void:
	(_panels[first] as Node3D).position.x = middle - open * 0.5 - 0.6
	(_panels[first + 1] as Node3D).position.x = middle + open * 0.5 + 0.6


func _status_text() -> String:
	if not _wider: return "THE SAME NUMBER, THE OTHER CONSEQUENCE.\nSOMEONE WROTE BOTH MAPPINGS."
	if _connected: return "THE GATE TAKES WHAT THE RAIL OFFERS."
	if absf(_offered - _used) > 0.02: return "THE HAND HAS MOVED. THE GATE HAS NOT.\nIT KEEPS THE LAST VALUE IT WAS GIVEN."
	return "THE ROUTE IS CUT. OFFERED AND USED HAPPEN TO AGREE."


func _show() -> void:
	_puck.position.x = _offered * HALF * 2.0 - HALF
	(_strip.material_override as StandardMaterial3D).albedo_color = LIVE if _connected else DEAD
	_slide(0, 0.0, opening(_used, _wider))
	_lines[0].text = "OFFERED at the rail:   %.2f" % _offered
	_lines[1].text = "USED at the gate:   %.2f" % _used
	_lines[2].text = "the route is %s" % ("CONNECTED" if _connected else "CUT")
	_lines[3].text = "the gate stands %.2f m open   (%s)" % [opening(_used, _wider), "more opens it" if _wider else "more closes it"]
	_status.text = _status_text()
	for i in PLATES.size():
		var key: String = str(PLATES[i]["key"])
		(_plate_tiles[i].material_override as StandardMaterial3D).albedo_color = Color("f6e39a") if (key == "route" and _connected) or (key == "mapping" and not _wider) else PALE


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["WHAT THE HAND OFFERS, WHAT THE BODY USES"])
	lines.append("Walk ALONG the rail: where you stop is the value OFFERED, and the puck stays there (crossing the rail offers nothing). The gate north of it stands open by the value it USES. The strip between them is the route, and at first it is cut. Walk the rail: the puck follows you. The gate does not.")
	lines.append("CONNECT / CUT makes the route. Open the gate with your feet and walk through it. Then close it, cut the route, and walk the rail back to open. The gate is still shut: it kept the last value it was given. Cutting has left a memory of what you did.")
	lines.append("OTHER MAPPING turns the consequence round. The number did not decide it; someone wrote both. The second gate moves by itself: no route leads to it. Being near is not being connected.")
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


## A gate: a frame 3.6 m wide, and two panels that slide apart inside it. Each panel is a body.
func _gate(middle: float, name: String) -> void:
	var frame: StandardMaterial3D = _city.flat(Color("6b4a32"), 0.9)
	var held := StaticBody3D.new()
	add_child(held)
	for hand in [-1.0, 1.0]:
		_box(self, Vector3(middle + hand * 2.45, 1.15, GATE_Z), Vector3(0.1, 2.3, 0.1), frame)
		_city.wall(held, Vector3(middle + hand * 2.45, 0, GATE_Z), Vector3(0.1, 2.3, 0.1))
	_box(self, Vector3(middle, 2.35, GATE_Z), Vector3(5.0, 0.1, 0.1), frame)
	for hand in 2:
		var panel := StaticBody3D.new()
		panel.position = Vector3(middle, 0, GATE_Z)
		add_child(panel)
		_box(panel, Vector3(0, 1.1, 0), Vector3(1.2, 2.2, 0.05), _city.flat(CARD, 0.95))
		_city.wall(panel, Vector3.ZERO, Vector3(1.2, 2.2, 0.1))
		_panels.append(panel)
	_city.floor_words(self, Vector3(middle, 0.03, GATE_Z + 0.55), name, 30, PALE)


func _build_once() -> void:
	# the rail and its puck
	_box(self, Vector3(0, 0.008, RAIL_Z), Vector3(HALF * 2.0 + 0.12, 0.014, LANE * 2.0 + 0.12), _city.flat(DARK, 0.9))
	_box(self, Vector3(0, 0.016, RAIL_Z), Vector3(HALF * 2.0, 0.008, LANE * 2.0), _city.flat(Color("3b4254"), 0.9))
	for i in 5:
		var x: float = -HALF + float(i) * HALF * 0.5
		_box(self, Vector3(x, 0.022, RAIL_Z), Vector3(0.04, 0.006, LANE * 2.0), _plain(PALE))
		_city.floor_words(self, Vector3(x, 0.03, RAIL_Z + LANE + 0.22), ["0", "¼", "½", "¾", "1"][i], 40, PALE)
	_puck = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.16
	disc.bottom_radius = 0.16
	disc.height = 0.05
	_puck.mesh = disc
	_puck.material_override = _plain(PALE)
	_puck.position = Vector3(0, 0.05, RAIL_Z - LANE + 0.2)
	add_child(_puck)
	# the route
	_strip = _box(self, Vector3(0, 0.02, (RAIL_Z - LANE + GATE_Z) * 0.5), Vector3(0.14, 0.01, RAIL_Z - LANE - GATE_Z - 0.3), _plain(DEAD))
	_city.floor_words(self, Vector3(0.75, 0.03, (RAIL_Z - LANE + GATE_Z) * 0.5), "the route", 28, PALE)
	_city.floor_words(self, Vector3(-HALF - 0.9, 0.03, RAIL_Z), "walk along  →", 30, PALE)
	# the gate that can be reached, and the one that cannot
	_gate(0.0, "this gate uses what the route brings")
	_gate(NEIGHBOUR_X + 1.3, "no route leads to this one")
	# the plates
	for plate in PLATES:
		var at: Vector2 = plate["at"]
		_plate_tiles.append(_box(self, Vector3(at.x, 0.012, at.y), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8)))
		_city.floor_words(self, Vector3(at.x, 0.035, at.y), str(plate["says"]), 30, DARK).outline_size = 0
	# the stand: both sides, always
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(-4.1, 0, GATE_Z)
	add_child(stand)
	var solid := StaticBody3D.new()
	stand.add_child(solid)
	_box(stand, Vector3(0, 1.5, -0.05), Vector3(2.9, 2.3, 0.06), _city.flat(DARK, 0.85))
	_city.wall(solid, Vector3(0, 0, -0.05), Vector3(2.9, 2.7, 0.12))
	for hand in [-1.0, 1.0]: _box(stand, Vector3(hand * 1.3, 0.18, -0.05), Vector3(0.08, 0.36, 0.08), _city.flat(DARK, 0.85))
	var colours := [PALE, LIVE, Color("f6e39a"), Color("d9b990")]
	var heights := [2.36, 2.02, 1.66, 1.34]
	var sizes := [40, 40, 34, 26]
	for i in 4: _lines.append(_words(stand, Vector3(0, float(heights[i]), 0), int(sizes[i]), 0.003, colours[i]))
	_status = _words(stand, Vector3(0, 0.86, 0), 26, 0.003, Color("f2a23a"))
	_board = _city.board(self, Vector3(-4.6, 0, 2.5), 3.2, 1.7)


## ---- for a test ----

func state() -> Dictionary:
	return {"route": "connected" if _connected else "cut", "offered": snappedf(_offered, 0.001), "used": snappedf(_used, 0.001), "wider": _wider, "open_m": snappedf(opening(_used, _wider), 0.001),
		"neighbour_open_m": snappedf(neighbour_opening(), 0.001), "strip_lit": (_strip.material_override as StandardMaterial3D).albedo_color.is_equal_approx(LIVE), "puck_x": snappedf(_puck.position.x, 0.001),
		"status": _status.text, "lines": _lines.map(func(l): return l.text), "board": _board.text if _board != null else "", "build_ms": _build_ms}


## A place on the rail's middle line at a value (0 west, 1 east).
func rail_point(value: float) -> Vector3:
	return to_global(Vector3(value * HALF * 2.0 - HALF, 0, RAIL_Z))


## A place on the line through the middle of the gate: `south` metres on the rail's side of it (negative: beyond).
func gate_point(south: float) -> Vector3:
	return to_global(Vector3(0, 0, GATE_Z + south))


func plate_point(key: String) -> Vector3:
	for plate in PLATES:
		if str(plate["key"]) == key: return to_global(Vector3((plate["at"] as Vector2).x, 0, (plate["at"] as Vector2).y))
	return global_position
