extends Node3D
## THREE CORNERS ON ONE STRAIGHT LINE (floor Euclid_Parallel; the pass, gone back to on 2026-11-16)
##
## The hall: "Draw the gold line through C in the direction of AB. Euclid's triangle-sum argument makes a related
## construction: a parallel through a vertex lets the angles be compared along a straight line. ... A display of
## the construction can help us follow the argument; a collection of successful measurements cannot replace it."
## And: "Move C, hide the guide, bring it back." This is that construction with the body as C - a PLAYGROUND form.
##
## A and B stand on the floor with the base between them. Step into the field and you are C: two edges run from
## your feet to A and to B, and a gold line runs through you in the direction of AB. Three wedges lie at your
## feet along the gold line: your own corner in the middle, and at either side a wedge in the colour of the
## corner at A and of the corner at B. With the line parallel, those two ARE the corners at A and B, wherever
## you stand, and the three fill the line: a straight angle.
##
## The plate turns THE GUIDE. Tilted eight degrees, the three wedges at your feet still fill the line - any line
## through C is filled - but the outer two are no longer the corners at A and B: they are off by eight degrees
## each way. What the parallel gives is the equality, and that it gives it is granted, not measured. Hidden,
## there are three numbers and a sum, and a count of the places measured.
##
## Stand nearly in a row with A and B and the reading is withheld: under TOLERANCE degrees the instrument does
## not call three positions a triangle (the hall: "The threshold belongs to the instrument").
##
## `guide` is the axis: parallel, tilted, hidden. The rule was benched first: tools/probes/three_wedges_bench.py.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const A := Vector2(-2.3, 1.5)
const B := Vector2(2.3, 1.5)
const REST := Vector2(0.7, -1.3)          # where C is when nobody stands in the field
const FIELD := Rect2(-3.0, -2.5, 6.0, 3.8)
const TILT := 8.0
const TOLERANCE := 10.0
const GUIDES := ["parallel", "tilted", "hidden"]
const PLATE_AT := Vector2(3.65, -0.2)
const PLATE := 0.84
const DARK := Color("191e29")
const PALE := Color("efe9dc")
const GOLD := Color("e2b33c")
const AT_A := Color("3fb6c9")
const AT_B := Color("e0569a")
const AT_C := Color("f1ead8")
const HOT := Color("ff5a3c")

@export_enum("parallel", "tilted", "hidden") var guide := "parallel"

var _city = City.new()
var _c := REST
var _visitor_is_c := false
var _withheld := false
var _places := 0
var _last_place := Vector2(99, 99)
var _spot: Node3D                         # at C: the line through it and the three wedges along it
var _line: MeshInstance3D
var _ghost: Node3D                        # the ball that is C when nobody is
var _edges: Array[MeshInstance3D] = []
var _wedges := {}                         # "a", "b" at the corners; "left", "middle", "right" at C
var _tags := {}
var _plate_tile: MeshInstance3D
var _lines: Array[Label3D] = []
var _status: Label3D
var _board: Label3D
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_guide"): _take({"guide": get_meta("config_guide")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_found()


func _take(config_data: Dictionary) -> void:
	if config_data.has("guide") and GUIDES.has(str(config_data["guide"])): guide = str(config_data["guide"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := guide
	_take(config_data)
	if is_inside_tree() and _board != null and guide != before: _found()


func _found() -> void:
	_places = 0
	_last_place = Vector2(99, 99)
	_draw()
	_tell()


## ---- the rule ----

## The triangle's corners at A, at B and at `c`, in degrees, each measured on its own.
static func corners(c: Vector2) -> Array:
	return [rad_to_deg(absf((B - A).angle_to(c - A))), rad_to_deg(absf((A - B).angle_to(c - B))), rad_to_deg(absf((A - c).angle_to(B - c)))]


## The three angles at `c` along a line through it turned `tilt` degrees from the direction of AB: between the
## line and the edge to A, between the two edges, between the edge to B and the line.
static func along(c: Vector2, tilt: float) -> Array:
	var d: Vector2 = (B - A).normalized().rotated(deg_to_rad(tilt))
	return [rad_to_deg(absf((-d).angle_to(A - c))), rad_to_deg(absf((A - c).angle_to(B - c))), rad_to_deg(absf(d.angle_to(B - c)))]


## Three whole numbers of degrees that add to what the three angles add to, rounded: the display's own rounding.
static func whole(three: Array) -> Array:
	var total: int = roundi(float(three[0]) + float(three[1]) + float(three[2]))
	var shown := [int(floor(float(three[0]))), int(floor(float(three[1]))), int(floor(float(three[2])))]
	var order := [0, 1, 2]
	order.sort_custom(func(i, j): return fposmod(float(three[i]), 1.0) > fposmod(float(three[j]), 1.0))
	var k := 0
	while shown[0] + shown[1] + shown[2] < total and k < 3:
		shown[order[k]] += 1
		k += 1
	return shown


func _turn() -> float:
	return TILT if guide == "tilted" else 0.0


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _physics_process(delta: float) -> void:
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var level: bool = absf(p.y) < 1.5
	var here := Vector2(p.x, p.z)
	var inside: bool = level and FIELD.has_point(here)
	var c: Vector2 = here if inside else REST
	if inside and here.distance_to(_last_place) > 0.5:
		_last_place = here
		if minf(float(corners(here)[0]), minf(float(corners(here)[1]), float(corners(here)[2]))) >= TOLERANCE: _places += 1
	if inside != _visitor_is_c or c.distance_to(_c) > 0.015:
		_visitor_is_c = inside
		_c = c
		_draw()
	var region := "plate" if level and absf(p.x - PLATE_AT.x) < PLATE * 0.5 and absf(p.z - PLATE_AT.y) < PLATE * 0.5 else ""
	var moved: float = Vector2(p.x - _last.x, p.z - _last.z).length()
	_last = p
	if region != _region or moved > 0.3 * delta:
		_still = 0.0
	elif _still >= 0.0:
		_still += delta
	_region = region
	if _still >= 0.8 and region != "":
		_still = -99.0
		guide = GUIDES[(GUIDES.find(guide) + 1) % 3]
		_draw()
		_tell()


## ---- drawing: every time C moves ----

func _sector(key: String, u: Vector2, v: Vector2, radius: float, tag_radius: float, says: String) -> void:
	var wedge: MeshInstance3D = _wedges[key]
	var mesh := wedge.mesh as ImmediateMesh
	mesh.clear_surfaces()
	var start: float = u.angle()
	var sweep: float = u.angle_to(v)
	var tag: Label3D = _tags[key]
	tag.text = says
	tag.position = Vector3(cos(start + sweep * 0.5), 0, sin(start + sweep * 0.5)) * tag_radius + Vector3(0, tag.position.y, 0)
	if absf(sweep) < 0.004 or not wedge.visible: return
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps: int = maxi(2, int(ceil(absf(sweep) / 0.1)))
	for i in steps:
		var from: float = start + sweep * float(i) / float(steps)
		var to: float = start + sweep * float(i + 1) / float(steps)
		mesh.surface_add_vertex(Vector3.ZERO)
		mesh.surface_add_vertex(Vector3(cos(from), 0, sin(from)) * radius)
		mesh.surface_add_vertex(Vector3(cos(to), 0, sin(to)) * radius)
	mesh.surface_end()


func _edge(edge: MeshInstance3D, from: Vector2, to: Vector2) -> void:
	var middle: Vector2 = (from + to) * 0.5
	edge.position = Vector3(middle.x, 0.011, middle.y)
	edge.rotation.y = -(to - from).angle()
	edge.scale = Vector3(maxf(from.distance_to(to), 0.01), 1, 1)


func _draw() -> void:
	var cs: Array = corners(_c)
	var al: Array = along(_c, _turn())
	_withheld = minf(float(cs[0]), minf(float(cs[1]), float(cs[2]))) < TOLERANCE
	var shown: Array = whole(cs)
	var lain: Array = whole(al)
	_spot.position = Vector3(_c.x, 0, _c.y)
	_ghost.visible = not _visitor_is_c
	_edge(_edges[0], A, _c)
	_edge(_edges[1], B, _c)
	_line.visible = guide != "hidden"
	_line.rotation.y = -deg_to_rad(_turn())
	(_line.material_override as StandardMaterial3D).albedo_color = GOLD if guide == "parallel" else PALE
	var d: Vector2 = (B - A).normalized().rotated(deg_to_rad(_turn()))
	for key in _wedges:
		var outer: bool = key in ["left", "right"]
		(_wedges[key] as MeshInstance3D).visible = not _withheld and not (outer and guide == "hidden")
		(_tags[key] as Label3D).visible = (_wedges[key] as MeshInstance3D).visible
	_sector("a", B - A, _c - A, 0.75, 1.05, "A  %d°" % shown[0])
	_sector("b", A - B, _c - B, 0.75, 1.05, "B  %d°" % shown[1])
	_sector("left", -d, A - _c, 0.95, 1.3, "%d°" % lain[0])
	_sector("middle", A - _c, B - _c, 0.95, 1.3, "C  %d°" % lain[1])
	_sector("right", B - _c, d, 0.95, 1.3, "%d°" % lain[2])
	(_plate_tile.material_override as StandardMaterial3D).albedo_color = PALE if guide == "parallel" else Color("f6e39a")
	var who := "YOU ARE C." if _visitor_is_c else "C IS THE BALL. STEP INTO THE FIELD AND YOU ARE C."
	if _withheld:
		_lines[0].text = who
		_lines[1].text = "THREE POSITIONS NEARLY IN A ROW"
		_lines[2].text = "the reading is withheld"
		_status.text = "UNDER %d° THIS INSTRUMENT DOES NOT CALL IT A TRIANGLE.\nTHE THRESHOLD BELONGS TO THE INSTRUMENT, NOT TO GEOMETRY." % int(TOLERANCE)
		return
	_lines[0].text = "%s     CORNERS:   A  %d°     B  %d°     C  %d°" % ["YOU ARE C." if _visitor_is_c else "C IS THE BALL.", shown[0], shown[1], shown[2]]
	match guide:
		"parallel":
			_lines[1].text = "ALONG THE GOLD LINE:   %d°  +  %d°  +  %d°   =   %d°" % [lain[0], lain[1], lain[2], lain[0] + lain[1] + lain[2]]
			_lines[2].text = "wedge %d°  =  corner A %d°          wedge %d°  =  corner B %d°" % [lain[0], shown[0], lain[2], shown[1]]
			_status.text = "THE OUTER WEDGES ARE THE CORNERS AT A AND B, BECAUSE THE GOLD LINE IS PARALLEL TO AB.\nTHAT IS GRANTED, NOT MEASURED.   places you have measured:  %d" % _places
		"tilted":
			_lines[1].text = "ALONG THE TILTED LINE:   %d°  +  %d°  +  %d°   =   %d°" % [lain[0], lain[1], lain[2], lain[0] + lain[1] + lain[2]]
			_lines[2].text = "wedge %d°  IS NOT  corner A %d°          wedge %d°  IS NOT  corner B %d°" % [lain[0], shown[0], lain[2], shown[1]]
			_status.text = "ANY LINE THROUGH C IS FILLED BY THREE WEDGES. FILLING IT SHOWS NOTHING.\nONLY THE PARALLEL MAKES THE OUTER TWO THE CORNERS AT A AND B."
		_:
			_lines[1].text = "A  +  B  +  C   =   %d°     (measured, here)" % (shown[0] + shown[1] + shown[2])
			_lines[2].text = "the guide is hidden"
			_status.text = "THREE NUMBERS AND A SUM.   places you have measured:  %d\nA PILE OF MEASUREMENTS IS NOT A PROOF. BRING THE GUIDE BACK." % _places


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["THREE CORNERS ON ONE STRAIGHT LINE"])
	lines.append("A and B stand on the floor. Step into the field: you are C. A gold line runs through you in the direction of AB, and three wedges lie along it at your feet. The outer two have the colours of the corners at A and B. Walk: they stay the corners at A and B, and the three fill the line.")
	lines.append("THE GUIDE, on the plate, tilts the line eight degrees, then hides it. Tilted, the line is still filled. Look at what stopped being true.")
	lines.append("Stand nearly in a row with A and B and the reading is withheld. That edge is this instrument's.")
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
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	return paint


func _wedge(parent: Node3D, key: String, colour: Color, lift: float, tag_high: float) -> void:
	var wedge := MeshInstance3D.new()
	wedge.mesh = ImmediateMesh.new()
	wedge.material_override = _plain(colour)
	wedge.position = Vector3(0, lift, 0)
	wedge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wedge.extra_cull_margin = 2.0
	parent.add_child(wedge)
	_wedges[key] = wedge
	var tag: Label3D = _words(parent, Vector3(0, tag_high, 0), 40, 0.0035, colour)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.outline_size = 8
	tag.outline_modulate = DARK
	_tags[key] = tag


func _build_once() -> void:
	# the field: its edge in thin pale lines, and the base AB
	for side in [[Vector3(0, 0.008, FIELD.position.y), Vector3(FIELD.size.x, 0.006, 0.02)], [Vector3(0, 0.008, FIELD.end.y), Vector3(FIELD.size.x, 0.006, 0.02)],
			[Vector3(FIELD.position.x, 0.008, FIELD.get_center().y), Vector3(0.02, 0.006, FIELD.size.y)], [Vector3(FIELD.end.x, 0.008, FIELD.get_center().y), Vector3(0.02, 0.006, FIELD.size.y)]]:
		_box(self, side[0], side[1], _plain(Color("8a8f9c")))
	_box(self, Vector3(0, 0.011, A.y), Vector3(B.x - A.x, 0.01, 0.05), _plain(PALE))
	_city.floor_words(self, Vector3(FIELD.end.x - 0.35, 0.02, -0.9), "step in: you are C", 34, PALE).rotation_degrees.y = 90.0
	for corner in [A, B]:
		_city.part(self, "traffic_pyramid_5", Vector3(corner.x, 0, corner.y + 0.32), 0.0, Vector3(0.3, 0.46, 0.3), false)
	# the two edges from C, drawn again whenever C moves
	for k in 2:
		var edge: MeshInstance3D = _box(self, Vector3.ZERO, Vector3(1, 0.01, 0.035), _plain(PALE))
		_edges.append(edge)
	# the corners at A and B
	var at_a := Node3D.new()
	at_a.position = Vector3(A.x, 0, A.y)
	add_child(at_a)
	_wedge(at_a, "a", AT_A, 0.013, 0.75)
	var at_b := Node3D.new()
	at_b.position = Vector3(B.x, 0, B.y)
	add_child(at_b)
	_wedge(at_b, "b", AT_B, 0.013, 0.75)
	# C: the line through it and the three wedges along it
	_spot = Node3D.new()
	_spot.name = "C"
	add_child(_spot)
	_line = _box(_spot, Vector3(0, 0.017, 0), Vector3(6.0, 0.008, 0.06), _plain(GOLD))
	_wedge(_spot, "left", AT_A, 0.013, 0.32)
	_wedge(_spot, "middle", AT_C, 0.014, 0.32)
	_wedge(_spot, "right", AT_B, 0.015, 0.32)
	_ghost = _city.part(_spot, "trace_point_ball", Vector3(0, 0.0, 0), 0.0, Vector3(0.24, 0.24, 0.24), false)
	# the plate
	_plate_tile = _box(self, Vector3(PLATE_AT.x, 0.012, PLATE_AT.y), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8))
	var plate_words: Label3D = _city.floor_words(self, Vector3(PLATE_AT.x, 0.035, PLATE_AT.y), "THE\nGUIDE", 46, DARK)
	plate_words.outline_size = 0
	plate_words.rotation_degrees.y = 180.0
	# the stand, raised behind the base and read from the field
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(0, 0, A.y + 1.05)
	stand.rotation_degrees.y = 180.0
	add_child(stand)
	var held := StaticBody3D.new()
	stand.add_child(held)
	_box(stand, Vector3(0, 3.05, -0.05), Vector3(5.0, 1.8, 0.06), _city.flat(DARK, 0.85))
	for hand in [-1.0, 1.0]:
		_box(stand, Vector3(hand * 2.4, 1.08, -0.05), Vector3(0.08, 2.16, 0.08), _city.flat(DARK, 0.85))
		_city.wall(held, Vector3(hand * 2.4, 0, -0.05), Vector3(0.1, 3.95, 0.1))
	var heights := [3.68, 3.36, 3.06]
	var sizes := [22, 26, 19]
	var colours := [PALE, GOLD, Color("b9c0cc")]
	for i in 3: _lines.append(_words(stand, Vector3(0, float(heights[i]), 0), int(sizes[i]), 0.006, colours[i]))
	_status = _words(stand, Vector3(0, 2.6, 0), 16, 0.006, Color("f2a23a"))
	_board = _city.board(self, Vector3(3.6, 0, A.y + 0.5), 2.3, 1.5)
	(_board.get_parent() as Node3D).rotation_degrees.y = 180.0


## ---- for a test ----

func state() -> Dictionary:
	var cs: Array = corners(_c)
	var al: Array = along(_c, _turn())
	return {"guide": guide, "who": "visitor" if _visitor_is_c else "example", "c": [_c.x, _c.y], "corners": cs, "sum": float(cs[0]) + float(cs[1]) + float(cs[2]),
		"along": al, "along_sum": float(al[0]) + float(al[1]) + float(al[2]), "withheld": _withheld, "places": _places,
		"wedges_shown": _wedges.values().filter(func(w): return w.visible).size(), "line_shown": _line.visible,
		"lines": _lines.map(func(l): return l.text), "status": _status.text, "board": _board.text if _board != null else "", "build_ms": _build_ms}


func plate_point() -> Vector3:
	return to_global(Vector3(PLATE_AT.x, 0, PLATE_AT.y))


func local_point(x: float, z: float) -> Vector3:
	return to_global(Vector3(x, 0, z))
