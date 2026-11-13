extends Node3D
## SEVEN BRIDGES TO WALK (floor GT_Foundations; the pass, 2026-11-13)
##
## The hall opens graph theory with Euler's question: can one walk cross every bridge of Koenigsberg exactly once? On
## the tower that question stood as a model on a table (void_gt_bridge, a tenth of its size). This is the question at
## the size of a body: a city 12 x 14 m on the floor - a river, an island, three more lands, nine places for a bridge
## - where the walk is the visitor's own.
##
## BUILT FROM THE TOWER'S PREFABS (Palle, 2026-11-13: "integrate these examples with real prefab bridges, other fun
## elements and connections, a bit like in spatial-lab"). Every part is one of the spatial lab's ready inputs, set
## through the lab's own adapter (commons/modular/lab_input.gd): the shores are fenced with the blue DO NOT CROSS
## barrier, the city's edge with concrete barriers, and each bridge is its own construction over a channel exactly two
## metres wide, the length of a plank:
##   Kraemer-Bruecke    a 2 x 2 m panel between four crates (the merchants' stalls)
##   Schmiede-Bruecke   five planks between two concrete parapets
##   Holz-Bruecke       eight planks, plank rails on plank posts
##   Hohe Bruecke       two walkable wedges: up one metre and down again
##   Gruene Bruecke     a 2 x 2 m panel between two DO NOT CROSS barriers
##   Koettel-Bruecke    five planks, traffic pyramids at the corners
##   Honig-Bruecke      a 2 x 1 m panel between four bipyramids
##   Kneiphof-Steg      a footbridge ten metres long: five rows of planks, 4 + 4 + 2 m, joints staggered, plank rails
##   Zweite Gruene      two 2 x 1 m panels, traffic pyramids at the corners
## Decks lie let into the floor (their tops 14 mm proud) and are not solid: the tower's walker cannot take a plank's
## six centimetres as a step, so the slab carries the body. Only the wedges are climbed.
##
## The work has NO GRAPH OF ITS OWN. The bridges are the lesson's: `_bridge_table()` of konigsberg3d.gd for the
## axis `parity`, read from an instance of that script kept out of the tree. Each bridge of the table takes the next
## free place between its two lands (SLOTS below). So the model on the table and the city on the floor are one set.
##   blocked  the seven bridges of 1736: every land has an odd number, no walk crosses them all once
##   walk     one bridge more (Kneiphof-Vorstadt): two odd lands, a walk exists - from one of them to the other
##   circuit  a second bridge more: no odd land, a walk from anywhere that ends where it began
##   severed  Loebenicht cut loose: the bridges that are left can all be crossed once, and one land is never reached
## A place without a bridge is fenced like the shore beside it.
##
## A bridge counts a crossing when a body enters by one end and leaves by the other; the planks at its two mouths
## turn green when it has been crossed once, red twice. Water holds a body off. The city has one way in, on the south
## bank, and the High Bridge rises straight ahead of it. Standing still on a land's pink plate begins the count again
## there - where a walk has to begin is half of Euler's answer. The blue plate outside changes the city. (A plate
## answers a body that stands still: the first walker crossed the island's plate at a slow walk and began again
## mid-route.) When a bridge has been crossed twice, or all once, the lands show what Euler counted: the number of
## bridges at each, red where it is odd.
##
## Everything is built once; changing the city only takes bridges and fences in and out of the tree.
## Bench first (tools/probes/seven_bridges_bench.py): from the way in 6 of 7 (blocked), 7 of 8 (walk; 8 of 8 from
## Altstadt), 9 of 9 (circuit), 4 of 4 with Loebenicht never reached (severed).
const Lesson := preload("res://algorithms/graphtheory/graphspace3d/konigsberg3d.gd")
const Prefab := preload("res://commons/modular/lab_input.gd")
const HALF_X := 6.0
const HALF_Z := 7.0
const GAP := 1.0                         # half the way in, on the south side
const DWELL := 0.8                       # seconds a body stands STILL on a plate before it answers
const PROUD := 0.014                     # how far a deck's top stands over the floor
const LAND_NAMES := ["ALTSTADT", "LOEBENICHT", "KNEIPHOF", "VORSTADT"]      # the lesson's own order: A, B, C, D
## The lands as rectangles on the floor (x, z, wide, deep): the island, the east land, the north bank, the south bank.
const LANDS := [Rect2(-2.9, -2.8, 4.0, 5.6), Rect2(3.1, -2.8, 2.9, 5.6), Rect2(-6.0, -7.0, 12.0, 2.2), Rect2(-6.0, 4.8, 12.0, 2.2)]
## The places a bridge can take: the two lands it joins (as the lesson numbers them), the channel it spans, the way
## it runs, the land at its low end and at its high end along that way, how it is built, and how far from its middle
## the construction reaches along the way (the wedges of the High Bridge stand a metre onto each land).
const SLOTS := [
	{"pair": [0, 2], "rect": Rect2(-2.8, -4.8, 2.0, 2.0), "runs": "z", "ends": [2, 0], "built": "stalls", "reach": 1.0},
	{"pair": [0, 2], "rect": Rect2(-0.3, -4.8, 1.25, 2.0), "runs": "z", "ends": [2, 0], "built": "parapet", "reach": 1.0},
	{"pair": [0, 3], "rect": Rect2(-2.8, 2.8, 2.0, 2.0), "runs": "z", "ends": [0, 3], "built": "timber", "reach": 1.0},
	{"pair": [0, 3], "rect": Rect2(-0.3, 2.8, 1.25, 2.0), "runs": "z", "ends": [0, 3], "built": "high", "reach": 2.0},
	{"pair": [0, 1], "rect": Rect2(1.1, -2.5, 2.0, 2.0), "runs": "x", "ends": [0, 1], "built": "fenced", "reach": 1.0},
	{"pair": [1, 2], "rect": Rect2(3.2, -4.8, 1.25, 2.0), "runs": "z", "ends": [2, 1], "built": "planks", "reach": 1.0},
	{"pair": [1, 3], "rect": Rect2(3.2, 2.8, 1.25, 2.0), "runs": "z", "ends": [1, 3], "built": "panel", "reach": 1.0},
	{"pair": [2, 3], "rect": Rect2(-4.4, -4.8, 1.25, 9.6), "runs": "z", "ends": [2, 3], "built": "steg", "reach": 4.8},
	{"pair": [0, 1], "rect": Rect2(1.1, 0.5, 2.0, 2.0), "runs": "x", "ends": [0, 1], "built": "cones", "reach": 1.0}]
const BEGIN_AT := [Vector2(-0.9, 0.0), Vector2(5.3, 0.0), Vector2(2.1, -6.2), Vector2(-5.2, 6.2)]      # a plate on each land, off the bridge mouths
const ENTRANCE_LAND := 3
const WATER := Color("3f77b8")
const PLATE := Color("f5a9b8")
const CITY := Color("5bcefa")
const FRESH := Color("d9c9a3")
const ONCE := Color("5fd08a")
const TWICE := Color("e0524d")

@export_enum("blocked", "walk", "circuit", "severed") var parity := "blocked"

var _built := false
var _active: Array[int] = []
var _names := {}
var _crossed := {}
var _entry := {}
var _bridges := {}                      # slot -> Node3D, in the tree while the bridge stands
var _closed := {}                       # slot -> Node3D, in the tree while the place has no bridge: fences across its mouths
var _plugs := {}                        # slot -> Array of CollisionShape3D: water under a place without a bridge
var _marks := {}                        # slot -> Array of MeshInstance3D: the strips at its mouths that take the colour
var _name_tags := {}                    # slot -> Array of Label3D
var _degree_signs: Array[Label3D] = []
var _board: Label3D
var _plates: Array = []                 # {"area": Area3D, "what": String, "land": int, "time": float, "done": bool, "off": float}
var _at_land := ENTRANCE_LAND
var _began_at := ENTRANCE_LAND
var _visited := {}
var _revealed := false
var _parts := 0
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_parity"): _take({"parity": get_meta("config_parity")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_set_city()


func _take(config_data: Dictionary) -> void:
	if config_data.has("parity") and str(config_data["parity"]) in ["blocked", "walk", "circuit", "severed"]: parity = str(config_data["parity"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := parity
	_take(config_data)
	if is_inside_tree() and _built and parity != before: _set_city()


func _process(delta: float) -> void:
	for plate in _plates:
		var area: Area3D = plate["area"]
		var someone := false
		var still := false
		for b in area.get_overlapping_bodies():
			if b is CharacterBody3D:
				var off: Vector3 = (b as CharacterBody3D).global_position - area.global_position
				if Vector2(off.x, off.z).length() > 0.3: continue      # its middle is not on the plate: a body stopped by a fence beside one is not standing on it
				someone = true
				var v: Vector3 = (b as CharacterBody3D).velocity
				if Vector2(v.x, v.z).length() < 0.3: still = true
		if not someone:
			plate["time"] = 0.0
			plate["off"] = float(plate["off"]) + delta
			if float(plate["off"]) > 0.3: plate["done"] = false
			continue
		plate["off"] = 0.0
		plate["time"] = float(plate["time"]) + delta if still else 0.0
		if float(plate["time"]) >= DWELL and not bool(plate["done"]):
			plate["done"] = true
			if str(plate["what"]) == "begin": begin_at(int(plate["land"]))
			else: next_city()


## ---- the lesson's bridges ----

func _read_the_city() -> void:
	var lesson: Node = Lesson.new()      # never enters the tree: only its bridge table is read
	lesson.set("parity", parity)
	var table: Array = lesson.call("_bridge_table")
	lesson.free()
	_active.clear()
	_names.clear()
	var taken := {}
	for row in table:
		var pair := [mini(int(row["from"]), int(row["to"])), maxi(int(row["from"]), int(row["to"]))]
		var placed := false
		for i in SLOTS.size():
			if taken.has(i) or SLOTS[i]["pair"] != pair: continue
			taken[i] = true
			_active.append(i)
			_names[i] = str(row.get("name", ""))
			placed = true
			break
		if not placed: push_warning("seven_bridges: the lesson names a bridge between lands %s that this city has no place for" % str(pair))


func degrees() -> Array[int]:
	var out: Array[int] = [0, 0, 0, 0]
	for i in _active:
		out[int(SLOTS[i]["pair"][0])] += 1
		out[int(SLOTS[i]["pair"][1])] += 1
	return out


## The city the axis names: bridges and the fences of bridgeless places go in and out of the tree; nothing is rebuilt.
func _set_city() -> void:
	_read_the_city()
	for i in SLOTS.size():
		var stands: bool = _active.has(i)
		_in_tree(_bridges[i], stands)
		_in_tree(_closed[i], not stands)
		for shape in _plugs[i]: (shape as CollisionShape3D).disabled = stands
		for tag in _name_tags[i]:
			(tag as Label3D).visible = stands
			(tag as Label3D).text = str(_names.get(i, ""))
	begin_at(ENTRANCE_LAND)


func _in_tree(node: Node3D, wanted: bool) -> void:
	if wanted and node.get_parent() == null: add_child(node)
	elif not wanted and node.get_parent() != null: remove_child(node)


func _exit_tree() -> void:
	for group in [_bridges, _closed]:
		for i in group:
			var node: Node3D = group[i]
			if is_instance_valid(node) and node.get_parent() == null: node.free()


## ---- building, once ----

## One of the lab's ready prefabs. `fit`: its own meshes fitted to that envelope, with a box solid (the lab adapter's
## fit_box), standing on `at`. Without `fit` it keeps its authored size, base on `at`; `solid` false takes its own
## colliders away (a deck let into the floor must not be a step).
func _part(parent: Node3D, token: String, at: Vector3, yaw_degrees: float = 0.0, fit: Vector3 = Vector3.ZERO, solid: bool = true) -> Node3D:
	var part: Node3D = Prefab.new()
	part.set("token", token)
	if fit != Vector3.ZERO:
		part.set("fit_box", fit)
		at.y += fit.y * 0.5
	part.position = at
	part.rotation_degrees.y = yaw_degrees
	parent.add_child(part)
	if not solid:
		for body in part.find_children("*", "CollisionObject3D", true, false):
			(body as CollisionObject3D).collision_layer = 0
			(body as CollisionObject3D).collision_mask = 0
	_parts += 1
	return part


## A fence of one prefab from a to b: as many as fit their own length best, each fitted to its share.
func _fence(parent: Node3D, a: Vector3, b: Vector3, token: String, unit: float, high: float, deep: float) -> void:
	var length: float = a.distance_to(b)
	if length < 0.7: return
	var n: int = maxi(1, roundi(length / unit))
	var along: Vector3 = (b - a) / float(n)
	var yaw: float = 0.0 if absf(along.x) > absf(along.z) else 90.0
	for k in n:
		_part(parent, token, a + along * (float(k) + 0.5), yaw, Vector3(along.length() - 0.04, high, deep))


func _flat(colour: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = rough
	return m


func _build_once() -> void:
	var ground := Node3D.new()
	ground.name = "Ground"
	add_child(ground)
	# water: every cell the lands and the bridge places cut the city into that is not land; under a bridge place it
	# is a plug, solid only while that place has no bridge
	var xs := [-HALF_X, HALF_X]
	var zs := [-HALF_Z, HALF_Z]
	var rects: Array[Rect2] = []
	for r in LANDS: rects.append(r)
	for slot in SLOTS: rects.append(slot["rect"])
	for r in rects:
		for v in [r.position.x, r.end.x]:
			if not xs.any(func(a): return absf(a - v) < 0.001): xs.append(v)
		for v in [r.position.y, r.end.y]:
			if not zs.any(func(a): return absf(a - v) < 0.001): zs.append(v)
	xs.sort()
	zs.sort()
	var solid := StaticBody3D.new()
	solid.name = "Water"
	ground.add_child(solid)
	var tiles: Array[Transform3D] = []
	for i in SLOTS.size(): _plugs[i] = []
	for j in zs.size() - 1:
		for i in xs.size() - 1:
			var w: float = float(xs[i + 1]) - float(xs[i])
			var d: float = float(zs[j + 1]) - float(zs[j])
			var mid := Vector3((float(xs[i]) + float(xs[i + 1])) * 0.5, 0, (float(zs[j]) + float(zs[j + 1])) * 0.5)
			var on_land := false
			for r in LANDS:
				if (r as Rect2).has_point(Vector2(mid.x, mid.z)): on_land = true
			if on_land: continue
			tiles.append(Transform3D(Basis().scaled(Vector3(w, 0.006, d)), mid + Vector3(0, 0.003, 0)))
			var shape := CollisionShape3D.new()
			var block := BoxShape3D.new()
			block.size = Vector3(w, 1.3, d)
			shape.shape = block
			shape.position = mid + Vector3(0, 0.65, 0)
			solid.add_child(shape)
			for s in SLOTS.size():
				if (SLOTS[s]["rect"] as Rect2).has_point(Vector2(mid.x, mid.z)): (_plugs[s] as Array).append(shape)
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	var unit := BoxMesh.new()
	unit.size = Vector3(1, 1, 1)
	many.mesh = unit
	many.instance_count = tiles.size()
	for i in tiles.size(): many.set_instance_transform(i, tiles[i])
	var water := MultiMeshInstance3D.new()
	water.name = "WaterTiles"
	water.multimesh = many
	water.material_override = _flat(WATER, 0.2)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ground.add_child(water)
	# the city's edge: concrete barriers, one way in on the south side, and a solid behind them
	var sides := [[Vector3(-HALF_X, 0, -HALF_Z), Vector3(HALF_X, 0, -HALF_Z)], [Vector3(-HALF_X, 0, -HALF_Z), Vector3(-HALF_X, 0, HALF_Z)], [Vector3(HALF_X, 0, -HALF_Z), Vector3(HALF_X, 0, HALF_Z)],
		[Vector3(-HALF_X, 0, HALF_Z), Vector3(-GAP, 0, HALF_Z)], [Vector3(GAP, 0, HALF_Z), Vector3(HALF_X, 0, HALF_Z)]]
	for side in sides:
		var a: Vector3 = side[0]
		var b: Vector3 = side[1]
		_fence(ground, a, b, "barrier", 2.0, 0.9, 0.5)
		var shape := CollisionShape3D.new()
		var block := BoxShape3D.new()
		block.size = Vector3(absf(b.x - a.x) + 0.08, 1.3, absf(b.z - a.z) + 0.08)
		shape.shape = block
		shape.position = (a + b) * 0.5 + Vector3(0, 0.65, 0)
		solid.add_child(shape)
	# the shores: the blue barrier between the mouths; across a mouth only while its place has no bridge
	for i in SLOTS.size():
		var shut := Node3D.new()
		shut.name = "Closed%d" % i
		add_child(shut)      # in the tree while it is filled: a prefab builds itself when it enters the tree
		_closed[i] = shut
	for k in LANDS.size():
		var land: Rect2 = LANDS[k]
		var edges := [[Vector2(land.position.x, land.position.y), Vector2(land.end.x, land.position.y)], [Vector2(land.position.x, land.end.y), Vector2(land.end.x, land.end.y)],
			[Vector2(land.position.x, land.position.y), Vector2(land.position.x, land.end.y)], [Vector2(land.end.x, land.position.y), Vector2(land.end.x, land.end.y)]]
		for edge in edges:
			var a: Vector2 = edge[0]
			var b: Vector2 = edge[1]
			var along_x: bool = absf(a.y - b.y) < 0.001
			if along_x and absf(absf(a.y) - HALF_Z) < 0.001: continue      # the city's own edge
			if not along_x and absf(absf(a.x) - HALF_X) < 0.001: continue
			var mouths := []      # [from, to, slot] along the edge
			for s in SLOTS.size():
				var r: Rect2 = SLOTS[s]["rect"]
				if along_x and (absf(r.position.y - a.y) < 0.001 or absf(r.end.y - a.y) < 0.001) and r.position.x >= a.x - 0.001 and r.end.x <= b.x + 0.001: mouths.append([r.position.x, r.end.x, s])
				if not along_x and (absf(r.position.x - a.x) < 0.001 or absf(r.end.x - a.x) < 0.001) and r.position.y >= a.y - 0.001 and r.end.y <= b.y + 0.001: mouths.append([r.position.y, r.end.y, s])
			mouths.sort_custom(func(p, q): return float(p[0]) < float(q[0]))
			var at: float = a.x if along_x else a.y
			var end: float = b.x if along_x else b.y
			for mouth in mouths:
				_shore(ground, a, along_x, at, float(mouth[0]))
				_shore(_closed[int(mouth[2])], a, along_x, float(mouth[0]), float(mouth[1]))
				at = float(mouth[1])
			_shore(ground, a, along_x, at, end)
	# the bridges, each its own construction
	for i in SLOTS.size(): _bridges[i] = _bridge(i)
	# the lands: what Euler counted, and a plate to begin on
	for k in LANDS.size():
		var plate_at := Vector3((BEGIN_AT[k] as Vector2).x, 0, (BEGIN_AT[k] as Vector2).y)
		var sign_post := Label3D.new()
		sign_post.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sign_post.pixel_size = 0.0032
		sign_post.font_size = 40
		sign_post.outline_size = 8
		sign_post.outline_modulate = Color(0, 0, 0, 1)
		sign_post.position = plate_at + Vector3(0, 1.95, 0)
		ground.add_child(sign_post)
		_degree_signs.append(sign_post)
		_plate(ground, "begin", k, plate_at, PLATE, "BEGIN\nHERE")
	_plate(ground, "city", -1, Vector3(-1.8, 0, HALF_Z + 2.1), CITY, "ANOTHER\nCITY")
	# the board: outside, east of the way in, turned to the arrival
	var stand := Node3D.new()
	stand.name = "Board"
	stand.position = Vector3(3.1, 0, HALF_Z + 0.75)
	ground.add_child(stand)
	var panel := MeshInstance3D.new()
	var face := BoxMesh.new()
	face.size = Vector3(3.2, 1.0, 0.05)
	panel.mesh = face
	panel.material_override = _flat(Color(0.11, 0.115, 0.13), 0.85)
	panel.position = Vector3(0, 0.66, 0)
	panel.rotation.x = -0.5
	stand.add_child(panel)
	_board = Label3D.new()
	_board.pixel_size = 0.0021
	_board.font_size = 30
	_board.line_spacing = 2.0
	_board.modulate = Color(0.88, 0.94, 1.0)
	_board.outline_size = 4
	_board.outline_modulate = Color(0, 0, 0, 1)
	_board.width = 1440
	_board.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_board.position = Vector3(0, 0.035, 0.03)
	panel.add_child(_board)
	_built = true


## A stretch of shore from `from` to `to` along an edge that begins at `a`, fenced with the blue barrier.
func _shore(parent: Node3D, a: Vector2, along_x: bool, from: float, to: float) -> void:
	if to - from < 0.7: return
	var p := Vector3(from, 0, a.y) if along_x else Vector3(a.x, 0, from)
	var q := Vector3(to, 0, a.y) if along_x else Vector3(a.x, 0, to)
	_fence(parent, p, q, "do_not_cross_barrier", 2.2, 1.1, 0.45)


## One bridge place, built in its own frame: +x along the way from the low end to the high end, +z across.
func _bridge(i: int) -> Node3D:
	var slot: Dictionary = SLOTS[i]
	var rect: Rect2 = slot["rect"]
	var runs_z: bool = str(slot["runs"]) == "z"
	var root := Node3D.new()
	root.name = "Bridge%d" % i
	root.position = Vector3(rect.get_center().x, 0, rect.get_center().y)
	if runs_z: root.rotation.y = -PI * 0.5      # the frame's +x lies along the city's +z
	add_child(root)      # in the tree while it is filled, for the same reason
	var length: float = rect.size.y if runs_z else rect.size.x
	var wide: float = rect.size.x if runs_z else rect.size.y
	var half: float = length * 0.5
	var plank_y: float = PROUD - 0.06
	var panel_y: float = PROUD - 0.045
	match str(slot["built"]):
		"stalls":
			_part(root, "timber_panel_2x2", Vector3(0, panel_y, 0), 0, Vector3.ZERO, false)
			for u in [-0.5, 0.5]:
				for v in [-0.7, 0.7]: _part(root, "crate", Vector3(u, 0, v), 0, Vector3(0.6, 0.7, 0.6))
		"parapet":
			_planks(root, half, wide, plank_y)
			for v in [-1.0, 1.0]: _part(root, "barrier", Vector3(0, 0, v * (wide * 0.5 + 0.12)), 0, Vector3(2.0, 0.7, 0.22))
		"timber":
			_planks(root, half, wide, plank_y)
			_plank_rails(root, [0.0], [-0.85, 0.85], wide * 0.5 - 0.06, "timber_plank_2m")
		"high":
			_part(root, "wp", Vector3(-1.0, 0, 0), 90)       # low on the low land, a metre high over the middle of the channel
			_part(root, "wp", Vector3(1.0, 0, 0), -90)
			for u in [-2.15, 2.15]:
				for v in [-0.85, 0.85]: _part(root, "traffic_pyramid_5", Vector3(u, 0, v), 0, Vector3.ZERO, false)
		"fenced":
			_part(root, "timber_panel_2x2", Vector3(0, panel_y, 0), 0, Vector3.ZERO, false)
			for v in [-1.0, 1.0]: _part(root, "do_not_cross_barrier", Vector3(0, 0, v * (wide * 0.5 + 0.14)), 0, Vector3(2.0, 1.0, 0.26))
		"planks":
			_planks(root, half, wide, plank_y)
			for u in [-0.85, 0.85]:
				for v in [-0.85, 0.85]: _part(root, "traffic_pyramid_5", Vector3(u, 0, v), 0, Vector3.ZERO, false)
		"panel":
			_part(root, "timber_panel_2x1", Vector3(0, panel_y, 0), 0, Vector3.ZERO, false)
			for u in [-0.6, 0.6]:
				for v in [-1.0, 1.0]: _part(root, "pentagonal_bipyramid_7", Vector3(u, 0, v), 0, Vector3.ZERO, false)
		"steg":
			# five rows, each 4 + 4 + 2 m or 2 + 4 + 4 m, so the joints of neighbouring rows do not meet
			var rows: int = roundi(wide / 0.25)
			for r in rows:
				var v: float = (float(r) - float(rows - 1) * 0.5) * 0.25
				var pieces := [4.0, 4.0, 2.0] if r % 2 == 0 else [2.0, 4.0, 4.0]
				var at := -5.0
				for piece in pieces:
					_part(root, "timber_plank_%dm" % int(piece), Vector3(at + float(piece) * 0.5, plank_y, v), 0, Vector3.ZERO, false)
					at += float(piece)
			_plank_rails(root, [-2.0, 2.0], [-4.0, 0.0, 4.0], wide * 0.5 - 0.02, "timber_plank_4m")
		"cones":
			for v in [-0.5, 0.5]: _part(root, "timber_panel_2x1", Vector3(0, panel_y, v), 0, Vector3.ZERO, false)
			for u in [-0.85, 0.85]:
				for v in [-1.2, 1.2]: _part(root, "traffic_pyramid_5", Vector3(u, 0, v), 0, Vector3.ZERO, false)
	# the two mouths: a strip that takes the colour of the count, and the bridge's name to read on the way onto it
	var marks := []
	var tags := []
	var reach: float = float(slot["reach"])
	for side in [-1.0, 1.0]:
		var strip := MeshInstance3D.new()
		var bar := BoxMesh.new()
		bar.size = Vector3(0.22, 0.012, wide)
		strip.mesh = bar
		strip.material_override = _flat(FRESH, 0.7)
		strip.position = Vector3(side * (reach + 0.13), 0.006, 0)
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(strip)
		marks.append(strip)
		var tag := Label3D.new()
		tag.pixel_size = 0.0018
		tag.font_size = 40
		tag.modulate = Color(0.95, 0.95, 0.98)
		tag.outline_size = 6
		tag.outline_modulate = Color(0, 0, 0, 1)
		tag.rotation_degrees = Vector3(-90, 90.0 * side, 0)      # to be read by a body walking onto the bridge
		tag.position = Vector3(side * (reach + 0.5), 0.012, 0)
		root.add_child(tag)
		tags.append(tag)
	_marks[i] = marks
	_name_tags[i] = tags
	# the sensor: the channel itself
	var sensor := Area3D.new()
	sensor.name = "Crossing"
	sensor.collision_layer = 0
	sensor.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(length - 0.1, 2.4, wide - 0.1)
	var reach_shape := CollisionShape3D.new()
	reach_shape.shape = room
	reach_shape.position = Vector3(0, 1.2, 0)
	sensor.add_child(reach_shape)
	root.add_child(sensor)
	sensor.body_entered.connect(_on_bridge.bind(i, true))
	sensor.body_exited.connect(_on_bridge.bind(i, false))
	return root


## A deck of two-metre planks side by side, let into the floor.
func _planks(root: Node3D, _half: float, wide: float, y: float) -> void:
	var rows: int = roundi(wide / 0.25)
	for r in rows:
		_part(root, "timber_plank_2m", Vector3(0, y, (float(r) - float(rows - 1) * 0.5) * 0.25), 0, Vector3.ZERO, false)


## Rails of planks on edge, 85 cm up, carried by one-metre planks set upright.
func _plank_rails(root: Node3D, rail_at: Array, post_at: Array, v: float, rail: String) -> void:
	for side in [-1.0, 1.0]:
		for u in rail_at:
			var bar := _part(root, rail, Vector3(float(u), 0.85, side * v), 0, Vector3.ZERO, false)
			bar.rotation_degrees.x = 90.0
		for u in post_at:
			var post := _part(root, "timber_plank_1m", Vector3(float(u), 0.5, side * v), 0, Vector3.ZERO, false)
			post.rotation_degrees.z = 90.0


func _plate(parent: Node3D, what: String, land: int, at: Vector3, colour: Color, words: String) -> void:
	var area := Area3D.new()
	area.name = "Plate_%s_%d" % [what, land]
	area.collision_layer = 0
	area.collision_mask = 0xFFFFFFFF
	area.position = at
	var reach := CollisionShape3D.new()
	var room := BoxShape3D.new()
	room.size = Vector3(0.7, 1.2, 0.7)
	reach.shape = room
	reach.position = Vector3(0, 0.6, 0)
	area.add_child(reach)
	var slab := MeshInstance3D.new()
	var tile := BoxMesh.new()
	tile.size = Vector3(0.8, 0.014, 0.8)
	slab.mesh = tile
	slab.material_override = _flat(colour, 0.6)
	slab.position = Vector3(0, 0.007, 0)
	slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	area.add_child(slab)
	var text := Label3D.new()
	text.text = words
	text.pixel_size = 0.002
	text.font_size = 40
	text.modulate = Color(0.1, 0.1, 0.12)
	text.outline_size = 0
	text.rotation_degrees = Vector3(-90, 0, 0)
	text.position = Vector3(0, 0.018, 0)
	area.add_child(text)
	parent.add_child(area)
	_plates.append({"area": area, "what": what, "land": land, "time": 0.0, "done": false, "off": 0.0})


## ---- the walk ----

func _side(slot: int, body: Node3D) -> int:
	var rect: Rect2 = SLOTS[slot]["rect"]
	var here: Vector3 = to_local(body.global_position)
	var along: float = here.z - rect.get_center().y if str(SLOTS[slot]["runs"]) == "z" else here.x - rect.get_center().x
	return 0 if along < 0.0 else 1


func _on_bridge(body: Node, slot: int, entering: bool) -> void:
	if not body is CharacterBody3D or not _crossed.has(slot): return
	if entering:
		_entry[slot] = _side(slot, body as Node3D)
		return
	if not _entry.has(slot): return
	var left_by: int = _side(slot, body as Node3D)
	if left_by != int(_entry[slot]):
		_crossed[slot] = int(_crossed[slot]) + 1
		_at_land = int(SLOTS[slot]["ends"][left_by])
		_visited[_at_land] = true
		if int(_crossed[slot]) >= 2: _revealed = true
		if is_done(): _revealed = true
		_show()
	_entry.erase(slot)


## Begin the count again, the walk starting on this land.
func begin_at(land: int) -> void:
	_crossed.clear()
	for i in _active: _crossed[i] = 0
	_entry.clear()
	_at_land = land
	_began_at = land
	_visited = {land: true}
	_revealed = false
	_show()


func next_city() -> void:
	var order := ["blocked", "walk", "circuit", "severed"]
	parity = order[(order.find(parity) + 1) % order.size()]
	_set_city()


func is_done() -> bool:
	if _active.is_empty(): return false
	for i in _active:
		if int(_crossed.get(i, 0)) != 1: return false
	return true


func _show() -> void:
	var once := 0
	var more := 0
	for i in _active:
		var n: int = int(_crossed.get(i, 0))
		if n == 1: once += 1
		elif n > 1: more += 1
		for strip in _marks[i]: (strip as MeshInstance3D).material_override = _flat(FRESH if n == 0 else (ONCE if n == 1 else TWICE), 0.7)
	var counts := degrees()
	var odd := 0
	for k in counts.size():
		if counts[k] % 2 == 1: odd += 1
		var sign_post: Label3D = _degree_signs[k]
		sign_post.text = "%s\n%d %s" % [LAND_NAMES[k], counts[k], "bridge" if counts[k] == 1 else "bridges"]
		sign_post.modulate = Color(1, 1, 1) if not _revealed else (TWICE if counts[k] % 2 == 1 else ONCE)
	if _board == null: return
	var lines := PackedStringArray(["CROSS EVERY BRIDGE EXACTLY ONCE"])
	lines.append("%d bridges.  Crossed once: %d.  Twice or more: %d.  Not yet: %d." % [_active.size(), once, more, _active.size() - once - more])
	if is_done():
		var never := PackedStringArray()
		for k in counts.size():
			if not _visited.has(k): never.append(LAND_NAMES[k])
		lines.append("Done: every bridge once, from %s to %s.%s" % [LAND_NAMES[_began_at], LAND_NAMES[_at_land], "" if never.is_empty() else "  Never reached: %s." % ", ".join(never)])
	elif _revealed:
		lines.append("Count the bridges at each land. One walk over every bridge exists only where no land, or exactly two, has an odd number. Here %d are odd.%s" % [odd, "  Begin on one of the two." if odd == 2 else ""])
	else:
		lines.append("The way in is beside this board. The strips at a bridge's mouths turn green when you have crossed it; crossed again, red.")
	lines.append("Stand still on a pink plate to begin again there.  The blue plate changes the city (now: %s)." % parity)
	_board.text = "\n".join(lines)


## ---- for a test ----

func state() -> Dictionary:
	var crossed := {}
	for i in _active: crossed[i] = int(_crossed.get(i, 0))
	var once := 0
	var more := 0
	for i in _active:
		if int(crossed[i]) == 1: once += 1
		elif int(crossed[i]) > 1: more += 1
	var standing := 0
	for i in _bridges:
		if (_bridges[i] as Node3D).get_parent() != null: standing += 1
	return {"parity": parity, "bridges": _active.duplicate(), "names": _names.duplicate(), "degrees": degrees(), "crossed": crossed, "once": once, "twice_or_more": more,
		"not_yet": _active.size() - once - more, "done": is_done(), "revealed": _revealed, "at_land": _at_land, "began_at": _began_at, "visited": _visited.keys(),
		"prefab_parts": _parts, "build_ms": _build_ms, "bridges_standing": standing}


## The two ends of a bridge, as points on the land a body stands on before and after: [low end, high end], global.
func bridge_ends(slot: int) -> Array:
	var rect: Rect2 = SLOTS[slot]["rect"]
	var c := rect.get_center()
	var out: float = float(SLOTS[slot]["reach"]) + 0.45
	if str(SLOTS[slot]["runs"]) == "z":
		return [to_global(Vector3(c.x, 0, c.y - out)), to_global(Vector3(c.x, 0, c.y + out))]
	return [to_global(Vector3(c.x - out, 0, c.y)), to_global(Vector3(c.x + out, 0, c.y))]


func plate_of(land: int) -> Vector3:
	return to_global(Vector3((BEGIN_AT[land] as Vector2).x, 0, (BEGIN_AT[land] as Vector2).y))


func city_plate() -> Vector3:
	return to_global(Vector3(-1.8, 0, HALF_Z + 2.1))


## The way in: a point outside it and a point inside, on the south bank beside the foot of the High Bridge.
func way_in() -> Array:
	return [to_global(Vector3(0, 0, HALF_Z + 1.2)), to_global(Vector3(-0.75, 0, HALF_Z - 0.6))]
