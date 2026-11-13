extends Node3D
## THE ROUTE AFTER A STONE DISAPPEARS (floor GT_Pathfinding; the pass, 2026-11-13)
##
## The hall's lesson is a little river: a spark crosses it stone by stone, a button sinks a stone on its route, and the
## route is found again - or there is none. The hall says of the spark's hop that it is "not evidence that your body
## could make the crossing". This is the river where the body makes it.
##
## A river ten cells wide and six deep, a metre a cell, between the hall floor (the south bank) and a fenced north
## bank that can only be reached over the stones. A cell holds a stone when its seeded number is under 0.58: 34 stones
## at seed 40. A body steps from a stone to a stone that shares an edge with it; water holds it off.
## (Ten cells, not twelve: on its floor the top of the evidence wall of the hall below stands 0.8 m through the slab
## along x = -4, the whole depth of the river - found with tools/probes/rises_through.gd after the first build had the
## river run through it. That wall is now the river's west end, and the tape barrier stands only on the east end.)
## The balls lie on the shortest way from where the body stands to the bank it is making for - found with the
## tutorial's own search (find_path of the study's route.gd, breadth first: fewest stones), the code the lesson runs.
## Then the river takes a stone on that way (never the one a body stands on). Three stones can be down at once; the
## fourth sinking lets the oldest rise again - the lesson's rule. So sometimes there is no way, and waiting gives one
## back.
##
## `impatience` is the axis: still (a stone sinks only when a body stands still on a plate on either bank),
## patient (one every 20 s while a body is on the river), impatient (one every 8 s).
##
## Built from the tower's prefabs. Through the spatial lab's adapter: 1 x 1 m timber panels for the stones (let into
## the floor, not solid: the slab carries the body), trace balls for the way, concrete barriers round the north bank.
## From the wider catalogue, which the lab does not expose yet, built the way the catalogue says: the four-metre
## museum tape barrier along the river's two ends, the pink triangle sign at the south bank, tripod work lights on
## the north bank.
## Bench first (tools/probes/stone_river_bench.py): seed 40 needs seven stones for a crossing, and after any one of
## them sinks there is still a way, of seven or nine.
const Prefab := preload("res://commons/modular/lab_input.gd")
const Search := preload("res://doc/book/studies/graphs-through-the-hands/GT_Pathfinding/route.gd")
const CATALOGUE := "res://commons/void/primitive-prefabs.json"
const WIDE := 10
const DEEP := 6
const SHARE := 0.58
const BANK := 2.0                       # the north bank's depth
const DWELL := 0.8
const EMPTY_SECONDS := 40.0
const PROUD := 0.014
const WATER := Color("3f77b8")
const EVERY := {"still": 0.0, "patient": 20.0, "impatient": 8.0}

@export_enum("still", "patient", "impatient") var impatience := "patient"
@export var river_seed := 40
@export var west_end_fenced := true               ## false where something else already stands along the west end (GT_Pathfinding: the wall from the hall below)

static var _catalogue: Dictionary = {}

var _search = Search.new()
var _cells: Array[Vector2i] = []        # stone k stands on cell (x, z); its vertex is k + 2
var _index := {}                        # cell -> k
var _holders: Array[Node3D] = []
var _plugs: Array[CollisionShape3D] = []
var _sunk: Array[bool] = []
var _queue: Array[int] = []
var _balls: Array[Node3D] = []
var _plates: Array = []
var _board: Label3D
var _body: CharacterBody3D
var _node := 0                          # the vertex the body stands on: 0 south bank, 1 north bank, k + 2 a stone
var _going := true                      # making for the north bank
var _route: Array[int] = []
var _rng := RandomNumberGenerator.new()
var _since := 0.0
var _empty_for := 0.0
var _crossings := 0
var _sinkings := 0
var _parts := 0
var _build_ms := 0


func _ready() -> void:
	for key in ["impatience", "river_seed", "west_end_fenced"]:
		if has_meta("config_" + key): _take({key: get_meta("config_" + key)})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_rng.seed = river_seed
	_replan()


func _take(config_data: Dictionary) -> void:
	if config_data.has("impatience") and str(config_data["impatience"]) in ["still", "patient", "impatient"]: impatience = str(config_data["impatience"])
	if config_data.has("river_seed") and _holders.is_empty(): river_seed = int(float(str(config_data["river_seed"])))
	if config_data.has("west_end_fenced") and _holders.is_empty(): west_end_fenced = str(config_data["west_end_fenced"]).to_lower() in ["true", "1", "1.0"]


func apply_grid_config(config_data: Dictionary) -> void:
	_take(config_data)
	_since = 0.0
	if is_inside_tree() and _board != null: _show()


static func hash01(key: Array) -> float:
	var h := 2166136261
	for v in key:
		h = ((h ^ (int(v) & 0xffffffff)) * 16777619) & 0xffffffff
		h ^= h >> 13
		h = (h * 1274126177) & 0xffffffff
	h ^= h >> 16
	return float(h & 0xffffff) / 16777216.0


func _centre(cell: Vector2i) -> Vector3:
	return Vector3(-float(WIDE) * 0.5 + 0.5 + float(cell.x), 0, -float(DEEP) * 0.5 + 0.5 + float(cell.y))


func _process(delta: float) -> void:
	# where the body is
	var now := _node
	if is_instance_valid(_body):
		var here: Vector3 = to_local(_body.global_position)
		var half_z: float = float(DEEP) * 0.5
		if here.z >= half_z: now = 0
		elif here.z <= -half_z: now = 1
		else:
			var cell := Vector2i(clampi(int(floor(here.x + float(WIDE) * 0.5)), 0, WIDE - 1), clampi(int(floor(here.z + half_z)), 0, DEEP - 1))
			if _index.has(cell) and not _sunk[int(_index[cell])]: now = int(_index[cell]) + 2
	if now != _node:
		if now == 1 and _going:
			_going = false
			_crossings += 1
		elif now == 0 and not _going:
			_going = true
			_crossings += 1
		_node = now
		_replan()
	# the river's impatience
	var every: float = float(EVERY[impatience])
	if every > 0.0 and is_instance_valid(_body) and _node >= 2:
		_since += delta
		if _since >= every:
			_since = 0.0
			sink()
	# the plates
	for plate in _plates:
		var area: Area3D = plate["area"]
		var someone := false
		var still := false
		for b in area.get_overlapping_bodies():
			if b is CharacterBody3D:
				var off: Vector3 = (b as CharacterBody3D).global_position - area.global_position
				if Vector2(off.x, off.z).length() > 0.3: continue
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
			sink()
	# nobody here: after a while every stone stands again
	if not is_instance_valid(_body) and not _queue.is_empty():
		_empty_for += delta
		if _empty_for >= EMPTY_SECONDS: rise_all()
	else:
		_empty_for = 0.0


## ---- the search and the sinking ----

func _replan() -> void:
	_search.neighbours.clear()
	_search.neighbours.append([])       # 0 the south bank
	_search.neighbours.append([])       # 1 the north bank
	for k in _cells.size():
		var cell: Vector2i = _cells[k]
		var around: Array = []
		for step in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]:
			if _index.has(cell + step): around.append(int(_index[cell + step]) + 2)
		if cell.y == 0:
			around.append(1)
			(_search.neighbours[1] as Array).append(k + 2)
		if cell.y == DEEP - 1:
			around.append(0)
			(_search.neighbours[0] as Array).append(k + 2)
		_search.neighbours.append(around)
	var blocked: Array[int] = []
	for k in _sunk.size():
		if _sunk[k]: blocked.append(k + 2)
	_route = _search.find_path(_node, 1 if _going else 0, blocked)
	var used := 0
	for vertex in _route:
		if vertex < 2 or vertex == _node or used >= _balls.size(): continue      # the stones ahead, not the one underfoot
		_balls[used].position = _centre(_cells[vertex - 2]) + Vector3(0, PROUD, 0)
		_balls[used].visible = true
		used += 1
	for i in range(used, _balls.size()): _balls[i].visible = false
	_show()


## The river takes a stone on the way (never the one a body stands on); with three down, the oldest rises.
func sink() -> int:
	var candidates: Array[int] = []
	for vertex in _route:
		if vertex >= 2 and vertex != _node and not _sunk[vertex - 2]: candidates.append(vertex - 2)
	if candidates.is_empty():
		for k in _cells.size():
			if not _sunk[k] and k + 2 != _node: candidates.append(k)
	if candidates.is_empty(): return -1
	var pick: int = candidates[_rng.randi_range(0, candidates.size() - 1)]
	_set_stone(pick, false)
	_queue.append(pick)
	_sinkings += 1
	if _queue.size() > 3: _set_stone(_queue.pop_front(), true)
	_replan()
	return pick


func rise_all() -> void:
	for k in _queue: _set_stone(k, true)
	_queue.clear()
	_going = true
	_empty_for = 0.0
	_rng.seed = river_seed
	_replan()


func _set_stone(k: int, stands: bool) -> void:
	_sunk[k] = not stands
	_plugs[k].disabled = stands
	var holder := _holders[k]
	if stands and holder.get_parent() == null: add_child(holder)
	elif not stands and holder.get_parent() != null: remove_child(holder)


func _exit_tree() -> void:
	for holder in _holders:
		if is_instance_valid(holder) and holder.get_parent() == null: holder.free()


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


## A prefab of the tower's catalogue that the lab does not expose: built the way its entry says - a modular term through
## composite.tscn, or a scene with its config - and marked like a lab input.
func _catalogue_part(parent: Node3D, id: String, at: Vector3, yaw_degrees: float = 0.0) -> Node3D:
	if _catalogue.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
		if data is Dictionary:
			for entry in (data as Dictionary).get("prefabs", []): _catalogue[str(entry.id)] = entry
	var found: Dictionary = _catalogue.get(id, {})
	var path := str(found.get("scene", ""))
	if not path.ends_with(".tscn") or not ResourceLoader.exists(path):
		push_warning("stone_river: the catalogue has no scene for " + id)
		return null
	var node: Node3D = (load(path) as PackedScene).instantiate()
	var config: Variant = found.get("config")
	if path.ends_with("composite.tscn"): node.set("term", str(found.get("token", "")).trim_prefix("mod_"))
	elif config is Dictionary:
		for key in config: node.set_meta("config_" + str(key), config[key])
	node.position = at
	node.rotation_degrees.y = yaw_degrees
	parent.add_child(node)
	if config is Dictionary and node.has_method("apply_grid_config"): node.apply_grid_config(config)
	node.set_meta("prefab", id)
	node.set_meta("source_scene", path)
	_parts += 1
	return node


func _flat(colour: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = rough
	return m


func _wall(solid: StaticBody3D, a: Vector3, b: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var block := BoxShape3D.new()
	block.size = Vector3(absf(b.x - a.x) + 0.08, 1.3, absf(b.z - a.z) + 0.08)
	shape.shape = block
	shape.position = (a + b) * 0.5 + Vector3(0, 0.65, 0)
	solid.add_child(shape)


func _build_once() -> void:
	var ground := Node3D.new()
	ground.name = "River"
	add_child(ground)
	var half_x: float = float(WIDE) * 0.5
	var half_z: float = float(DEEP) * 0.5
	var solid := StaticBody3D.new()
	solid.name = "Water"
	ground.add_child(solid)
	# the water: every cell a tile and a solid; under a stone the solid is a plug, on only while that stone is down
	var tiles: Array[Transform3D] = []
	for z in DEEP:
		for x in WIDE:
			var cell := Vector2i(x, z)
			var mid := _centre(cell)
			tiles.append(Transform3D(Basis().scaled(Vector3(1.0, 0.006, 1.0)), mid + Vector3(0, 0.003, 0)))
			var shape := CollisionShape3D.new()
			var block := BoxShape3D.new()
			block.size = Vector3(1.0, 1.3, 1.0)
			shape.shape = block
			shape.position = mid + Vector3(0, 0.65, 0)
			solid.add_child(shape)
			if hash01([river_seed, x, z]) < SHARE:
				_index[cell] = _cells.size()
				_cells.append(cell)
				_sunk.append(false)
				shape.disabled = true
				_plugs.append(shape)
				var holder := Node3D.new()
				holder.name = "Stone_%d_%d" % [x, z]
				add_child(holder)
				_part(holder, "timber_panel_1x1", mid + Vector3(0, PROUD - 0.045, 0), 0, Vector3.ZERO, false)
				_holders.append(holder)
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
	# the north bank: concrete barriers behind it, and nothing but the stones leads there
	var north: float = -half_z - BANK
	for k in WIDE / 2: _part(ground, "barrier", Vector3(-half_x + 1.0 + float(k) * 2.0, 0, north), 0, Vector3(1.96, 0.9, 0.5))
	_wall(solid, Vector3(-half_x, 0, north), Vector3(half_x, 0, north))
	# the river's two ends, from the north bank's corner to the south bank: the four-metre museum tape barrier
	for side in [-1.0, 1.0]:
		if side > 0.0 or west_end_fenced:
			for k in 2: _catalogue_part(ground, "museum_tape_barrier", Vector3(side * half_x, 0, north + 2.0 + float(k) * 4.0), 90)
		_wall(solid, Vector3(side * half_x, 0, north), Vector3(side * half_x, 0, half_z))
		_catalogue_part(ground, "work_light", Vector3(side * (half_x - 0.9), 0, north + 0.8), 180.0 + side * 35.0)
		_catalogue_part(ground, "pink_triangle_sign", Vector3(side * (half_x - 0.3), 0, half_z + 0.6), 0)
	# the way: a ball for each stone of it
	for i in 16:
		var ball := _part(ground, "trace_point_ball", Vector3.ZERO, 0, Vector3.ZERO, false)
		ball.visible = false
		_balls.append(ball)
	# the body: one sensor over the river and both banks
	var sensor := Area3D.new()
	sensor.name = "Reach"
	sensor.collision_layer = 0
	sensor.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(float(WIDE), 2.4, float(DEEP) + BANK * 2.0 + 1.0)
	var shape2 := CollisionShape3D.new()
	shape2.shape = room
	shape2.position = Vector3(0, 1.2, 0.5)
	sensor.add_child(shape2)
	ground.add_child(sensor)
	sensor.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _body = b)
	sensor.body_exited.connect(func(b: Node) -> void:
		if b == _body:
			_body = null
			if _node >= 2: _node = 0
			_replan())
	# a plate on each bank: stand still on it and the river takes a stone
	_plate(ground, Vector3(-half_x + 1.5, 0, half_z + 1.1))
	_plate(ground, Vector3(half_x - 1.5, 0, -half_z - 1.0))
	# the board: on the south bank, east of the middle, turned to the arrival
	var stand := Node3D.new()
	stand.name = "Board"
	stand.position = Vector3(2.6, 0, half_z + 1.9)
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


func _plate(parent: Node3D, at: Vector3) -> void:
	var area := Area3D.new()
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
	slab.material_override = _flat(Color("f5a9b8"), 0.6)
	slab.position = Vector3(0, 0.007, 0)
	slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	area.add_child(slab)
	var text := Label3D.new()
	text.text = "SINK A\nSTONE"
	text.pixel_size = 0.002
	text.font_size = 40
	text.modulate = Color(0.1, 0.1, 0.12)
	text.outline_size = 0
	text.rotation_degrees = Vector3(-90, 0, 0)
	text.position = Vector3(0, 0.018, 0)
	area.add_child(text)
	parent.add_child(area)
	_plates.append({"area": area, "time": 0.0, "done": false, "off": 0.0})


func _show() -> void:
	if _board == null: return
	var down := 0
	for s in _sunk:
		if s: down += 1
	var stones_on_the_way := 0
	for vertex in _route:
		if vertex >= 2 and vertex != _node: stones_on_the_way += 1
	var where := "on the south bank" if _node == 0 else ("on the north bank" if _node == 1 else "on a stone")
	var lines := PackedStringArray(["THE ROUTE AFTER A STONE DISAPPEARS"])
	lines.append("Cross to the far bank over the stones. The balls lie on the shortest way from where you stand - fewest stones, breadth first.")
	lines.append("You are %s, making for the %s bank.  %s" % [where, "north" if _going else "south", "The way: %d stones." % stones_on_the_way if not _route.is_empty() else "NO WAY - wait: a stone will rise."])
	lines.append("Stones standing: %d.  Down: %d (three at most; the fourth sinking lets the oldest rise).  Crossings made: %d." % [_cells.size() - down, down, _crossings])
	lines.append("The river takes a stone on your way %s" % ("only when someone stands still on a pink plate." if impatience == "still" else "every %d seconds while you are on it." % int(EVERY[impatience])))
	_board.text = "\n".join(lines)


## ---- for a test ----

func state() -> Dictionary:
	var down := []
	for k in _sunk.size():
		if _sunk[k]: down.append([_cells[k].x, _cells[k].y])
	var way := []
	for vertex in _route: way.append(vertex)
	return {"impatience": impatience, "seed": river_seed, "stones": _cells.size(), "down": down, "node": _node, "going_north": _going, "route": way, "stones_on_the_way": way.filter(func(v): return v >= 2).size(),
		"crossings": _crossings, "sinkings": _sinkings, "prefab_parts": _parts, "build_ms": _build_ms}


## The way as points a body walks: the stones' middles, then a point on the bank it leads to. Global.
func route_points() -> Array:
	var out := []
	var last := Vector3.ZERO
	if _node >= 2: last = _centre(_cells[_node - 2])
	for vertex in _route:
		if vertex >= 2 and vertex != _node:
			last = _centre(_cells[vertex - 2])
			out.append(to_global(last))
	if not _route.is_empty():
		var goal: int = _route[_route.size() - 1]
		if goal == 1: out.append(to_global(Vector3(last.x, 0, -float(DEEP) * 0.5 - 0.9)))
		elif goal == 0: out.append(to_global(Vector3(last.x, 0, float(DEEP) * 0.5 + 0.9)))
	return out


func stone_point(cell: Vector2i) -> Vector3:
	return to_global(_centre(cell))
