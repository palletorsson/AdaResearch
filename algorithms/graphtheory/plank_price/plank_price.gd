extends Node3D
## THE PRICE OF ONE MORE ROUTE (floor GT_Spanning_Trees; the pass, 2026-11-13)
##
## The hall keeps the cheapest set of connections that reaches every vertex - a minimum spanning tree - and then says:
## now break one connection. This is that for a body, and the price is real. Seven lands lie in water: the south bank
## S, a near row of islands A1 B1 C1, a far row A2 B2 C2. Ten places can take a bridge, and a bridge is planks: the
## channels are exactly one, two or four metres wide, the lengths of the three plank prefabs, so a bridge costs its
## length. The cheapest set that reaches every land is six bridges and twelve metres of plank, with nothing spare:
## take any one away and between one and five lands are cut off. One more bridge costs its planks and buys the right
## to lose one.
##
## Built from the spatial lab's prefabs through the lab's own adapter (Palle, 2026-11-13): decks of five planks side by
## side let into the floor, plank rails on plank posts along the four-metre bridges, the blue DO NOT CROSS barrier on
## the shores and across the mouth of a place without a bridge, concrete barriers round the edge.
##
## Outside the way in lies THE MAP, the city at a fifth of its size: standing still on a bridge of the map lays that
## bridge or takes it away (never one a body is standing on). Then walk it. Each land lies on a mat: green when it can
## be reached from where the body stands (from S when the body is outside), grey when it is cut off.
##
## `planks` is the axis: tree = the cheapest set (shortest first, the lower number first among equals; a bridge is
## left out when its two ends are already joined - Kruskal); one_more = the tree and the four-metre bridge B1-B2;
## all = every bridge, twenty-four metres. After forty seconds without a body in the city it is again what its row
## says. Bench first: tools/probes/plank_price_bench.py.
##
## This graph is the work's own: the lesson's model (mst_visualization) grows a tree over ten generated points, which
## cannot be laid out as lands; what is shared is the rule and the question.
const Prefab := preload("res://commons/modular/lab_input.gd")
const HALF_X := 6.0
const HALF_Z := 6.5
const GAP := 1.0
const DWELL := 0.8
const EMPTY_SECONDS := 40.0
const PROUD := 0.014
const MAP_AT := Vector3(-2.9, 0.0, 8.25)
const MAP_SCALE := 0.2
const LAND_NAMES := ["S", "A1", "B1", "C1", "A2", "B2", "C2"]
const LANDS := [Rect2(-6.0, 4.5, 12.0, 2.0), Rect2(-6.0, 0.0, 3.0, 2.5), Rect2(-2.0, 0.0, 3.0, 2.5), Rect2(3.0, 0.0, 3.0, 2.5),
	Rect2(-6.0, -6.5, 3.0, 2.5), Rect2(-2.0, -6.5, 3.0, 2.5), Rect2(3.0, -6.5, 3.0, 2.5)]
## A point on each land a body can stand on (the tower's columns stand in the middle of A2 and C2).
const STAND := [Vector2(0.0, 5.7), Vector2(-4.5, 1.25), Vector2(-0.5, 1.25), Vector2(4.5, 1.25), Vector2(-3.9, -4.8), Vector2(-0.5, -5.25), Vector2(3.9, -4.8)]
## The places a bridge can take: the lands at its low end and at its high end along the way it runs, the channel it
## spans, and its length - its price.
const SLOTS := [
	{"ends": [1, 0], "rect": Rect2(-5.1, 2.5, 1.25, 2.0), "runs": "z", "metres": 2},
	{"ends": [2, 0], "rect": Rect2(-1.1, 2.5, 1.25, 2.0), "runs": "z", "metres": 2},
	{"ends": [3, 0], "rect": Rect2(3.9, 2.5, 1.25, 2.0), "runs": "z", "metres": 2},
	{"ends": [1, 2], "rect": Rect2(-3.0, 0.6, 1.0, 1.25), "runs": "x", "metres": 1},
	{"ends": [2, 3], "rect": Rect2(1.0, 0.6, 2.0, 1.25), "runs": "x", "metres": 2},
	{"ends": [4, 5], "rect": Rect2(-3.0, -5.9, 1.0, 1.25), "runs": "x", "metres": 1},
	{"ends": [5, 6], "rect": Rect2(1.0, -5.9, 2.0, 1.25), "runs": "x", "metres": 2},
	{"ends": [4, 1], "rect": Rect2(-5.1, -4.0, 1.25, 4.0), "runs": "z", "metres": 4},
	{"ends": [5, 2], "rect": Rect2(-1.1, -4.0, 1.25, 4.0), "runs": "z", "metres": 4},
	{"ends": [6, 3], "rect": Rect2(3.9, -4.0, 1.25, 4.0), "runs": "z", "metres": 4}]
const WATER := Color("3f77b8")
const TIMBER := Color("c9a978")
const REACHED := Color("5fd08a")
const CUT_OFF := Color("8a8f98")

@export_enum("tree", "one_more", "all") var planks := "tree"

var _given := "tree"
var _laid: Array[bool] = []
var _bridges := {}
var _closed := {}
var _plugs := {}
var _on_bridge := {}
var _in_land := {}
var _mats: Array[MeshInstance3D] = []
var _signs: Array[Label3D] = []
var _map_plates: Array = []             # {"area": Area3D, "slot": int, "time": float, "done": bool, "off": float, "tile": MeshInstance3D}
var _board: Label3D
var _land := -1                         # the land the body stands on; -1 = outside
var _visited := {}
var _touched := false
var _empty_for := 0.0
var _parts := 0
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_planks"): _take({"planks": get_meta("config_planks")})
	_given = planks
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_lay_set(planks)


func _take(config_data: Dictionary) -> void:
	if config_data.has("planks") and str(config_data["planks"]) in ["tree", "one_more", "all"]: planks = str(config_data["planks"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := planks
	_take(config_data)
	_given = planks
	if is_inside_tree() and not _bridges.is_empty() and planks != before: _lay_set(planks)


func _process(delta: float) -> void:
	for plate in _map_plates:
		var area: Area3D = plate["area"]
		var someone := false
		var still := false
		for b in area.get_overlapping_bodies():
			if b is CharacterBody3D:
				var off: Vector3 = (b as CharacterBody3D).global_position - area.global_position
				if Vector2(off.x, off.z).length() > 0.2: continue
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
			toggle(int(plate["slot"]))
	if _touched and _land == -1:
		_empty_for += delta
		if _empty_for >= EMPTY_SECONDS: _lay_set(_given)
	else:
		_empty_for = 0.0


## ---- the count ----

## The lands grouped by what the laid bridges join.
func pieces(laid: Array = _laid) -> Array:
	var group: Array[int] = []
	for i in LANDS.size(): group.append(i)
	for s in SLOTS.size():
		if not bool(laid[s]): continue
		var a: int = group[int(SLOTS[s]["ends"][0])]
		var b: int = group[int(SLOTS[s]["ends"][1])]
		if a == b: continue
		for i in group.size():
			if group[i] == a: group[i] = b
	var out := {}
	for i in group.size():
		if not out.has(group[i]): out[group[i]] = []
		(out[group[i]] as Array).append(i)
	return out.values()


## The cheapest set that reaches every land: shortest first, the lower number first among equals; a bridge is left
## out when its two ends are already joined.
func cheapest() -> Array[bool]:
	var laid: Array[bool] = []
	for s in SLOTS.size(): laid.append(false)
	var order: Array = range(SLOTS.size())
	order.sort_custom(func(a, b): return [int(SLOTS[a]["metres"]), a] < [int(SLOTS[b]["metres"]), b])
	for s in order:
		var joined := false
		for g in pieces(laid):
			if (g as Array).has(int(SLOTS[s]["ends"][0])) and (g as Array).has(int(SLOTS[s]["ends"][1])): joined = true
		if not joined: laid[s] = true
	return laid


func metres(laid: Array = _laid) -> int:
	var total := 0
	for s in SLOTS.size():
		if bool(laid[s]): total += int(SLOTS[s]["metres"])
	return total


func reached_from(land: int) -> Array:
	for g in pieces():
		if (g as Array).has(land): return g
	return [land]


func spare() -> int:
	var count := 0
	for s in SLOTS.size():
		if _laid[s]: count += 1
	return count - LANDS.size() + pieces().size()


func _lay_set(which: String) -> void:
	planks = which
	_laid = cheapest()
	if which == "one_more": _laid[8] = true
	elif which == "all":
		for s in SLOTS.size(): _laid[s] = true
	_touched = false
	_empty_for = 0.0
	_apply()


## Lay a bridge or take it away; never one a body stands on.
func toggle(slot: int) -> bool:
	if int(_on_bridge.get(slot, 0)) > 0: return false
	_laid[slot] = not _laid[slot]
	_touched = true
	_empty_for = 0.0
	_apply()
	return true


func _in_tree(node: Node3D, wanted: bool) -> void:
	if wanted and node.get_parent() == null: add_child(node)
	elif not wanted and node.get_parent() != null: remove_child(node)


func _apply() -> void:
	for s in SLOTS.size():
		_in_tree(_bridges[s], _laid[s])
		_in_tree(_closed[s], not _laid[s])
		for shape in _plugs[s]: (shape as CollisionShape3D).disabled = _laid[s]
	_show()


func _exit_tree() -> void:
	for group in [_bridges, _closed]:
		for i in group:
			var node: Node3D = group[i]
			if is_instance_valid(node) and node.get_parent() == null: node.free()


## ---- building, once ----

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


func _sheet(parent: Node3D, at: Vector3, size: Vector2, colour: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size.x, 0.01, size.y)
	mesh.mesh = box
	mesh.material_override = _flat(colour, 0.6)
	mesh.position = at
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	return mesh


func _sensor(parent: Node3D, at: Vector3, size: Vector3, entered: Callable, exited: Callable) -> Area3D:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = size
	var shape := CollisionShape3D.new()
	shape.shape = room
	shape.position = Vector3(0, size.y * 0.5, 0)
	area.add_child(shape)
	area.position = at
	parent.add_child(area)
	area.body_entered.connect(entered)
	area.body_exited.connect(exited)
	return area


func _build_once() -> void:
	var ground := Node3D.new()
	ground.name = "Ground"
	add_child(ground)
	# water: the cells the lands and the bridge places cut the city into that are not land; under a bridge place a plug
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
	for s in SLOTS.size(): _plugs[s] = []
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
	# the edge: concrete barriers, one way in on the south side, a solid behind them
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
	# the shores: the blue barrier between the mouths, and across a mouth while its place has no bridge
	for s in SLOTS.size():
		var shut := Node3D.new()
		shut.name = "Closed%d" % s
		add_child(shut)
		_closed[s] = shut
	for k in LANDS.size():
		var land: Rect2 = LANDS[k]
		var edges := [[Vector2(land.position.x, land.position.y), Vector2(land.end.x, land.position.y)], [Vector2(land.position.x, land.end.y), Vector2(land.end.x, land.end.y)],
			[Vector2(land.position.x, land.position.y), Vector2(land.position.x, land.end.y)], [Vector2(land.end.x, land.position.y), Vector2(land.end.x, land.end.y)]]
		for edge in edges:
			var a: Vector2 = edge[0]
			var b: Vector2 = edge[1]
			var along_x: bool = absf(a.y - b.y) < 0.001
			if along_x and absf(absf(a.y) - HALF_Z) < 0.001: continue
			if not along_x and absf(absf(a.x) - HALF_X) < 0.001: continue
			var mouths := []
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
	# the bridges: five planks side by side, as long as the channel is wide
	for s in SLOTS.size(): _bridges[s] = _bridge(s)
	# the lands: a mat, a name, a sensor
	for k in LANDS.size():
		var land: Rect2 = LANDS[k]
		var middle := Vector3(land.get_center().x, 0, land.get_center().y)
		_mats.append(_sheet(ground, middle + Vector3(0, 0.005, 0), Vector2(minf(land.size.x, 4.0) - 1.0, land.size.y - 0.9), REACHED))
		var sign_post := Label3D.new()
		sign_post.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sign_post.pixel_size = 0.0032
		sign_post.font_size = 40
		sign_post.outline_size = 8
		sign_post.outline_modulate = Color(0, 0, 0, 1)
		sign_post.position = middle + Vector3(0, 2.0, 0)
		ground.add_child(sign_post)
		_signs.append(sign_post)
		_sensor(ground, middle, Vector3(land.size.x - 0.1, 2.2, land.size.y - 0.1), _on_land.bind(k, 1), _on_land.bind(k, -1))
	_build_map(ground)
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


func _shore(parent: Node3D, a: Vector2, along_x: bool, from: float, to: float) -> void:
	if to - from < 0.7: return
	var p := Vector3(from, 0, a.y) if along_x else Vector3(a.x, 0, from)
	var q := Vector3(to, 0, a.y) if along_x else Vector3(a.x, 0, to)
	_fence(parent, p, q, "do_not_cross_barrier", 2.2, 1.1, 0.45)


## One bridge place, built in its own frame: +x along the way from the low end to the high end, +z across.
func _bridge(s: int) -> Node3D:
	var slot: Dictionary = SLOTS[s]
	var rect: Rect2 = slot["rect"]
	var runs_z: bool = str(slot["runs"]) == "z"
	var root := Node3D.new()
	root.name = "Bridge%d" % s
	root.position = Vector3(rect.get_center().x, 0, rect.get_center().y)
	if runs_z: root.rotation.y = -PI * 0.5
	add_child(root)
	var length: int = int(slot["metres"])
	var wide: float = rect.size.x if runs_z else rect.size.y
	var rows: int = roundi(wide / 0.25)
	for r in rows:
		_part(root, "timber_plank_%dm" % length, Vector3(0, PROUD - 0.06, (float(r) - float(rows - 1) * 0.5) * 0.25), 0, Vector3.ZERO, false)
	if length == 4:
		for side in [-1.0, 1.0]:
			var rail := _part(root, "timber_plank_4m", Vector3(0, 0.85, side * (wide * 0.5 - 0.02)), 0, Vector3.ZERO, false)
			rail.rotation_degrees.x = 90.0
			for u in [-1.7, 1.7]:
				var post := _part(root, "timber_plank_1m", Vector3(u, 0.5, side * (wide * 0.5 - 0.02)), 0, Vector3.ZERO, false)
				post.rotation_degrees.z = 90.0
	for side in [-1.0, 1.0]:
		var tag := Label3D.new()
		tag.text = "%d m" % length
		tag.pixel_size = 0.0022
		tag.font_size = 44
		tag.modulate = Color(0.95, 0.95, 0.98)
		tag.outline_size = 6
		tag.outline_modulate = Color(0, 0, 0, 1)
		tag.rotation_degrees = Vector3(-90, 90.0 * side, 0)
		tag.position = Vector3(side * (float(length) * 0.5 + 0.32), 0.012, 0)
		root.add_child(tag)
	var along: float = float(length)
	_sensor(root, Vector3.ZERO, Vector3(along - 0.1, 2.4, wide - 0.1), _on_deck.bind(s, 1), _on_deck.bind(s, -1))
	return root


## The map: the city at a fifth of its size, outside the way in. Its bridges are plates.
func _build_map(parent: Node3D) -> void:
	var map := Node3D.new()
	map.name = "Map"
	map.position = MAP_AT
	parent.add_child(map)
	_sheet(map, Vector3(0, 0.004, 0), Vector2(HALF_X * 2.0 * MAP_SCALE + 0.1, HALF_Z * 2.0 * MAP_SCALE + 0.1), WATER)
	for k in LANDS.size():
		var land: Rect2 = LANDS[k]
		_sheet(map, Vector3(land.get_center().x * MAP_SCALE, 0.008, land.get_center().y * MAP_SCALE), land.size * MAP_SCALE, Color("d8d4c8"))
		var letters := Label3D.new()
		letters.text = LAND_NAMES[k]
		letters.pixel_size = 0.0018
		letters.font_size = 36
		letters.modulate = Color(0.15, 0.15, 0.18)
		letters.outline_size = 0
		letters.rotation_degrees = Vector3(-90, 0, 0)
		letters.position = Vector3(land.get_center().x * MAP_SCALE, 0.02, land.get_center().y * MAP_SCALE)
		map.add_child(letters)
	for s in SLOTS.size():
		var rect: Rect2 = SLOTS[s]["rect"]
		var at := Vector3(rect.get_center().x * MAP_SCALE, 0, rect.get_center().y * MAP_SCALE)
		var tile := _sheet(map, at + Vector3(0, 0.012, 0), Vector2(maxf(rect.size.x * MAP_SCALE, 0.3), maxf(rect.size.y * MAP_SCALE, 0.3)), TIMBER)
		var area := Area3D.new()
		area.name = "MapBridge%d" % s
		area.collision_layer = 0
		area.collision_mask = 0xFFFFFFFF
		var room := BoxShape3D.new()
		room.size = Vector3(0.5, 1.2, 0.5)
		var shape := CollisionShape3D.new()
		shape.shape = room
		shape.position = Vector3(0, 0.6, 0)
		area.add_child(shape)
		area.position = at
		map.add_child(area)
		_map_plates.append({"area": area, "slot": s, "time": 0.0, "done": false, "off": 0.0, "tile": tile})
	var title := Label3D.new()
	title.text = "THE MAP\nstand still on a bridge to lay it or take it away"
	title.pixel_size = 0.002
	title.font_size = 36
	title.modulate = Color(0.95, 0.95, 0.98)
	title.outline_size = 6
	title.outline_modulate = Color(0, 0, 0, 1)
	title.rotation_degrees = Vector3(-90, 0, 0)
	title.position = Vector3(0, 0.02, HALF_Z * MAP_SCALE + 0.22)
	map.add_child(title)


## ---- where the body is ----

func _on_land(body: Node, land: int, change: int) -> void:
	if not body is CharacterBody3D: return
	_in_land[land] = maxi(0, int(_in_land.get(land, 0)) + change)
	var now := -1
	for k in LANDS.size():
		if int(_in_land.get(k, 0)) > 0: now = k
	if now != _land:
		_land = now
		if now >= 0: _visited[now] = true
		_show()


func _on_deck(body: Node, slot: int, change: int) -> void:
	if body is CharacterBody3D: _on_bridge[slot] = maxi(0, int(_on_bridge.get(slot, 0)) + change)


func _show() -> void:
	var from: int = _land if _land >= 0 else 0
	var here := reached_from(from)
	for k in LANDS.size():
		var ok: bool = here.has(k)
		_mats[k].material_override = _flat(REACHED if ok else CUT_OFF, 0.6)
		_signs[k].text = "%s\n%s" % [LAND_NAMES[k], "you are here" if k == _land else ("reached" if ok else "cut off")]
		_signs[k].modulate = REACHED.lightened(0.3) if ok else CUT_OFF.lightened(0.4)
	for plate in _map_plates:
		(plate["tile"] as MeshInstance3D).material_override = _flat(TIMBER if _laid[int(plate["slot"])] else Color("27507f"), 0.6)
	if _board == null: return
	var count := 0
	for s in SLOTS.size():
		if _laid[s]: count += 1
	var lines := PackedStringArray(["THE PRICE OF ONE MORE ROUTE"])
	lines.append("A bridge costs its length in planks.  Laid now: %d bridges, %d m.  The least that reaches every land: %d m." % [count, metres(), metres(cheapest())])
	lines.append("From %s a body reaches %d of %d lands.  Spare bridges - take one away and nothing is cut off: %d." % [LAND_NAMES[from], here.size(), LANDS.size(), spare()])
	lines.append("The map lies to your left: stand still on one of its bridges to lay it or take it away. Then walk the city and see what you can still reach.")
	_board.text = "\n".join(lines)


## ---- for a test ----

func state() -> Dictionary:
	var laid := []
	for s in SLOTS.size():
		if _laid[s]: laid.append(s)
	var names := []
	for k in reached_from(_land if _land >= 0 else 0): names.append(LAND_NAMES[k])
	var seen := []
	for k in _visited: seen.append(LAND_NAMES[k])
	return {"planks": planks, "laid": laid, "metres": metres(), "least": metres(cheapest()), "reached": names, "spare": spare(), "land": LAND_NAMES[_land] if _land >= 0 else "outside",
		"visited": seen, "prefab_parts": _parts, "build_ms": _build_ms}


## The two ends of a bridge, as points on the lands: [low end, high end], global.
func bridge_ends(slot: int) -> Array:
	var rect: Rect2 = SLOTS[slot]["rect"]
	var c := rect.get_center()
	var out: float = float(SLOTS[slot]["metres"]) * 0.5 + 0.45
	if str(SLOTS[slot]["runs"]) == "z":
		return [to_global(Vector3(c.x, 0, c.y - out)), to_global(Vector3(c.x, 0, c.y + out))]
	return [to_global(Vector3(c.x - out, 0, c.y)), to_global(Vector3(c.x + out, 0, c.y))]


func map_plate(slot: int) -> Vector3:
	var rect: Rect2 = SLOTS[slot]["rect"]
	return to_global(MAP_AT + Vector3(rect.get_center().x * MAP_SCALE, 0, rect.get_center().y * MAP_SCALE))


func way_in() -> Array:
	return [to_global(Vector3(0, 0, HALF_Z + 1.2)), to_global(Vector3(0, 0, HALF_Z - 0.8))]
