extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name WfcDungeonRoom

## @identity
## name: "WFC structures & rooms"
## tier: large
## truth: "ARCHITECTURE AS A SATISFIED CONSTRAINT" — you can walk this plan because
##   every wall, floor and door survived a hundred vetoes; the dungeon is the proof
##   that the rules are jointly satisfiable.
## essence: A room-scale 14x14 WFC dungeon on the 7x7 floor. Floor / wall / door
##   tiles collapse from adjacency rules into rooms and corridors; walls stand ~1.2m
##   tall over a walkable plan. The overhead truth names the move.

@export var grid: int = 14
@export var room_size: float = 6.4
@export var wall_h: float = 1.2
@export var floor_col: Color = Color(0.22, 0.23, 0.27)
@export var wall_col: Color = Color(0.50, 0.46, 0.42)
@export var door_col: Color = Color(0.95, 0.72, 0.22)
@export var rim_col: Color = Color(0.30, 0.55, 0.85)
@export var label_col: Color = Color(0.88, 0.92, 1.0)

const KIND_FLOOR := 0
const KIND_WALL := 1
const KIND_DOOR := 2
const T_SOCK := [
	[1, 1, 1, 1],  # floor (open all)
	[0, 0, 0, 0],  # wall  (solid all)
	[1, 0, 1, 0],  # door  (open N-S)
]
const OPP := [2, 3, 0, 1]
const DX := [0, 1, 0, -1]
const DZ := [-1, 0, 1, 0]


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("grid"):
		grid = clampi(int(config["grid"]), 6, 22)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _solve() -> Array:
	var n: int = grid
	var t: int = T_SOCK.size()
	var options: Array = []
	for _i in range(n * n):
		var row: Array = []
		for _k in range(t):
			row.append(true)
		options.append(row)

	# force the outer ring to be wall — a sealed room edge
	for i in range(n * n):
		var ex: int = i % n
		var ez: int = i / n
		if ex == 0 or ex == n - 1 or ez == 0 or ez == n - 1:
			for k in range(t):
				options[i][k] = (k == KIND_WALL)
	for i in range(n * n):
		var bx: int = i % n
		var bz: int = i / n
		if bx == 0 or bx == n - 1 or bz == 0 or bz == n - 1:
			_propagate(options, i, n, t)

	for _step in range(n * n):
		var best: int = -1
		var best_count: int = t + 1
		for i in range(n * n):
			var cnt: int = 0
			for k in range(t):
				if options[i][k]:
					cnt += 1
			if cnt > 1 and cnt < best_count:
				best_count = cnt
				best = i
		if best == -1:
			break
		var allowed: Array = []
		for k in range(t):
			if options[best][k]:
				allowed.append(k)
				if k == KIND_FLOOR:
					allowed.append(k)  # bias toward open floor so rooms form
		var chosen: int = allowed[_rng.randi_range(0, allowed.size() - 1)]
		for k in range(t):
			options[best][k] = (k == chosen)
		_propagate(options, best, n, t)

	var out: Array = []
	for i in range(n * n):
		var pick: int = 0
		for k in range(t):
			if options[i][k]:
				pick = k
				break
		out.append(pick)
	return out


func _propagate(options: Array, start: int, n: int, t: int) -> void:
	var stack: Array = [start]
	while stack.size() > 0:
		var idx: int = stack.pop_back()
		var cx: int = idx % n
		var cz: int = idx / n
		for e in range(4):
			var nx: int = cx + DX[e]
			var nz: int = cz + DZ[e]
			if nx < 0 or nx >= n or nz < 0 or nz >= n:
				continue
			var nidx: int = nz * n + nx
			var my_vals: Dictionary = {}
			for k in range(t):
				if options[idx][k]:
					my_vals[T_SOCK[k][e]] = true
			var changed: bool = false
			for k in range(t):
				if not options[nidx][k]:
					continue
				var facing: int = T_SOCK[k][OPP[e]]
				if not my_vals.has(facing):
					options[nidx][k] = false
					changed = true
			if changed:
				stack.append(nidx)


func _build() -> void:
	# room floor at y = -0.05 (7x7)
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), _matte_mat(Color(0.08, 0.08, 0.10), 0.9)))

	var solved: Array = _solve()
	var c: float = room_size / float(grid)
	var off: float = -room_size * 0.5 + c * 0.5
	for i in range(grid * grid):
		var gx: int = i % grid
		var gz: int = i / grid
		var kind: int = solved[i]
		var px: float = off + gx * c
		var pz: float = off + gz * c
		if kind == KIND_WALL:
			add_child(_box(Vector3(px, wall_h * 0.5, pz), Vector3(c * 0.98, wall_h, c * 0.98), _matte_mat(wall_col, 0.8)))
		elif kind == KIND_DOOR:
			add_child(_box(Vector3(px, 0.02, pz), Vector3(c * 0.96, 0.04, c * 0.96), _matte_mat(floor_col, 0.7)))
			add_child(_box(Vector3(px, 0.30, pz), Vector3(c * 0.30, 0.6, c * 0.30), _glow_mat(door_col, 1.6)))
		else:
			add_child(_box(Vector3(px, 0.02, pz), Vector3(c * 0.96, 0.04, c * 0.96), _matte_mat(floor_col, 0.7)))
			add_child(_box(Vector3(px, 0.05, pz), Vector3(c * 0.10, 0.02, c * 0.10), _glow_mat(rim_col, 0.8)))

	add_child(_billboard_label("WFC DUNGEON\narchitecture as a satisfied constraint", Vector3(0.0, 3.6, 0.0), 26, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
