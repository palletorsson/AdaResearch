# FilledPocket.gd — free space that might as well be solid
#
# @identity
# essence: a tabletop grid with bad cells, a route found from x to y through the good ones, and every free cell the flood cannot reach drawn FILLED — open floor absorbed into the walls because reachability, not occupancy, is what the map answers to
# desire: learner stops reading a floor plan as where one can stand and meets it as where one can ARRIVE — the pocket is perfectly good floor, and it is wall
# critical_parameter: wall — what the bad cells form (open / u_bend / ring / split); under it door decides whether one removed cell drains the pocket or reconnects the world
# triggers: none; the flood fill and the route re-run whenever wall or door changes
# emerges: the recognition that a map's open cells are a claim about paths, so sealing a region and deleting it are the same act as far as any route is concerned
# relationships: the route-level member of the separation family — [[bridge_cut]] severs one edge, [[markov_blanket_room]] seals a volume; here the seal's inside is shown absorbed, which none of the others say out loud
# truth: unreachable and nonexistent are the same word to a path
extends Node3D
class_name FilledPocket

## FROM THE SOURCE FIGURE, kept faithful: "bad microcubes" grey, the "filled
## pocket" amber, "route in good cubes" blue, x on the left, y on the right.
## The pocket is DISCOVERED, never authored: a flood fill runs from x over free
## cells, the route is the flood's own parent chain to y, and any free cell the
## flood never touched is drawn filled. The layouts are hand-written character
## maps -- no RNG, so two placements of one token are the same argument.
##
## `door` names one or two specific cells per wall shape; where the layout has
## no wall at those cells the door changes nothing, and the axis is CONDITIONAL
## on wall exactly as every second axis in this family has turned out to be.

const WALLS := ["open", "u_bend", "ring", "split"]
const DOORS := ["sealed", "single", "double"]

@export_enum("open", "u_bend", "ring", "split") var wall: String = "ring":
	set(v):
		wall = v
		if is_inside_tree():
			_rebuild()

@export_enum("sealed", "single", "double") var door: String = "sealed":
	set(v):
		door = v
		if is_inside_tree():
			_rebuild()

@export var cell: float = 0.036
@export var show_readout: bool = true

@export var good_color: Color = Color(0.78, 0.78, 0.74)
@export var bad_color: Color = Color(0.42, 0.42, 0.46)
@export var pocket_color: Color = Color(0.95, 0.72, 0.35)
@export var route_color: Color = Color(0.13, 0.18, 0.72)
@export var mark_color: Color = Color(0.10, 0.10, 0.12)

const W := 11
const H := 9

var _grid: Array = []            # rows of characters
var _start := Vector2i.ZERO
var _goal := Vector2i.ZERO
var _route: Array[Vector2i] = []
var _pocket: Array[Vector2i] = []
var _reachable: int = 0
var _door_mattered: bool = false
var _built: Node3D


func _ready() -> void:
	_built = Node3D.new()
	_built.name = "Built"
	add_child(_built)
	_rebuild()


# ---------------------------------------------------------------- the layouts

func _layout() -> Array:
	match wall:
		"open": return [
			"...........",
			"..#....#...",
			"x....#....y",
			"...#.....#.",
			"...........",
			"..#...#....",
			".....#.....",
			".#.......#.",
			"...........",
		]
		"u_bend": return [
			"...........",
			"...........",
			"...#####...",
			"x..#...#..y",
			"...#...#...",
			"...#...#...",
			"...#####...",
			"...........",
			"...........",
		]
		"ring": return [
			"...........",
			"...........",
			"...#####...",
			"x..#...#..y",
			"...#...#...",
			"...#...#...",
			"...#####...",
			"...........",
			"...........",
		]
		"split": return [
			".....#.....",
			".....#.....",
			".....#.....",
			"x....#....y",
			".....#.....",
			".....#.....",
			".....#.....",
			".....#.....",
			".....#.....",
		]
	return []


## The cells a door removes from the wall, per shape. On `ring` the door is the
## mouth at the top; on `split` it is mid-wall, which reconnects x to y; on
## `open` and `u_bend` the named cells are already free and nothing changes.
func _door_cells() -> Array:
	var cells: Array = []
	if door == "sealed":
		return cells
	match wall:
		"ring", "u_bend", "open":
			cells.append(Vector2i(5, 2))
			if door == "double":
				cells.append(Vector2i(4, 2))
		"split":
			cells.append(Vector2i(5, 3))
			if door == "double":
				cells.append(Vector2i(5, 5))
	return cells


func _apply_layout() -> void:
	_grid.clear()
	var rows := _layout()
	# u_bend keeps its mouth open: the top side of the box never closes
	for r in range(rows.size()):
		var line: String = rows[r]
		if wall == "u_bend" and r == 2:
			line = "...#...#..."   # the mouth stays open: a U, not a ring
		_grid.append(line)
	_door_mattered = false
	for d in _door_cells():
		var row: String = _grid[d.y]
		if row[d.x] == "#":
			_grid[d.y] = row.substr(0, d.x) + "." + row.substr(d.x + 1)
			_door_mattered = true
	for r in range(_grid.size()):
		var line2: String = _grid[r]
		for c in range(line2.length()):
			if line2[c] == "x":
				_start = Vector2i(c, r)
			elif line2[c] == "y":
				_goal = Vector2i(c, r)


func _free(p: Vector2i) -> bool:
	if p.x < 0 or p.y < 0 or p.x >= W or p.y >= H:
		return false
	return (_grid[p.y] as String)[p.x] != "#"


# ---------------------------------------------------------- flood and route

func _flood() -> void:
	var came := {_start: _start}
	var queue: Array[Vector2i] = [_start]
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nxt := cur + d
			if came.has(nxt) or not _free(nxt):
				continue
			came[nxt] = cur
			queue.append(nxt)
	_reachable = came.size()

	_route.clear()
	if came.has(_goal):
		var walk := _goal
		while walk != _start:
			_route.append(walk)
			walk = came[walk]
		_route.append(_start)
		_route.reverse()

	_pocket.clear()
	for r in range(H):
		for c in range(W):
			var p := Vector2i(c, r)
			if _free(p) and not came.has(p):
				_pocket.append(p)


# ----------------------------------------------------------------- the body

func _mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = emit
	return m


func _at(p: Vector2i, y: float) -> Vector3:
	return Vector3(
		(float(p.x) - float(W - 1) * 0.5) * cell, y,
		(float(p.y) - float(H - 1) * 0.5) * cell)


func _rebuild() -> void:
	if _built == null:
		return
	for c in _built.get_children():
		c.queue_free()

	_apply_layout()
	_flood()

	var good_m := _mat(good_color, 0.05)
	var bad_m := _mat(bad_color, 0.08)
	var pocket_m := _mat(pocket_color, 0.4)
	var route_m := _mat(route_color, 0.5)
	var mark_m := _mat(mark_color, 0.3)

	for r in range(H):
		for c in range(W):
			var p := Vector2i(c, r)
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			if not _free(p):
				bm.size = Vector3(cell * 0.96, 0.030, cell * 0.96)
				mi.material_override = bad_m
				mi.position = _at(p, 0.015)
			elif p in _pocket:
				# the figure's move: perfectly good floor, drawn absorbed
				bm.size = Vector3(cell * 0.96, 0.014, cell * 0.96)
				mi.material_override = pocket_m
				mi.position = _at(p, 0.007)
			else:
				bm.size = Vector3(cell * 0.92, 0.004, cell * 0.92)
				mi.material_override = good_m
				mi.position = _at(p, 0.002)
			mi.mesh = bm
			_built.add_child(mi)

	for i in range(_route.size() - 1):
		var a := _at(_route[i], 0.014)
		var b := _at(_route[i + 1], 0.014)
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.004
		cyl.bottom_radius = 0.004
		cyl.height = a.distance_to(b) * 1.05
		cyl.radial_segments = 6
		var mi2 := MeshInstance3D.new()
		mi2.mesh = cyl
		mi2.material_override = route_m
		var mid := (a + b) * 0.5
		mi2.position = mid
		var dir := (b - a).normalized()
		if absf(dir.dot(Vector3.UP)) < 0.999:
			mi2.look_at_from_position(mid, mid + dir, Vector3.UP)
			mi2.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		_built.add_child(mi2)

	for e in [_start, _goal]:
		var sph := SphereMesh.new()
		sph.radius = 0.009
		sph.height = 0.018
		sph.radial_segments = 10
		sph.rings = 5
		var mi3 := MeshInstance3D.new()
		mi3.mesh = sph
		mi3.material_override = mark_m
		mi3.position = _at(e, 0.016)
		_built.add_child(mi3)

	if show_readout:
		var plate := Label3D.new()
		plate.text = _verdict()
		plate.font_size = 40
		plate.pixel_size = 0.00040
		plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		plate.modulate = pocket_color if (not _pocket.is_empty() or _route.is_empty()) else route_color
		plate.position = Vector3(0, 0.13, 0)
		_built.add_child(plate)

	var anchor := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(float(W) * cell * 1.08, 0.18, float(H) * cell * 1.15)
	anchor.mesh = am
	anchor.layers = 0
	anchor.name = "ExtentAnchor"
	anchor.position = Vector3(0, 0.05, 0)
	_built.add_child(anchor)


func _verdict() -> String:
	if _route.is_empty():
		return "NO ROUTE\n%d free cells beyond reach" % _pocket.size()
	if _pocket.is_empty():
		var base := "ROUTE: %d steps\nevery free cell reachable" % (_route.size() - 1)
		# bridge_cut's lesson: an artifact whose answer to an undefined question
		# is to look unchanged cannot be told apart from a broken one
		if door != "sealed" and not _door_mattered:
			base += "\n(the door names open floor)"
		return base
	return "ROUTE: %d steps\nPOCKET: %d cells sealed -- filled" \
		% [_route.size() - 1, _pocket.size()]


# ------------------------------------------------------------- the map's hand

func apply_grid_config(config_data: Dictionary) -> void:
	var dirty := false
	if config_data.has("wall"):
		var w := str(config_data["wall"]).to_lower().strip_edges()
		if WALLS.has(w):
			wall = w
			dirty = true
	if config_data.has("door"):
		var d := str(config_data["door"]).to_lower().strip_edges()
		if DOORS.has(d):
			door = d
			dirty = true
	if config_data.has("show_readout"):
		show_readout = bool(config_data["show_readout"])
		dirty = true
	if dirty and is_inside_tree():
		_rebuild()


## Readable by a probe, so the claim is testable without reading pixels.
func route_steps() -> int:
	return _route.size() - 1 if not _route.is_empty() else -1


func pocket_cells() -> int:
	return _pocket.size()


func reachable_cells() -> int:
	return _reachable
