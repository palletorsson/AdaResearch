extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name WfcRoomBench

## @identity
## name: "WFC structures & rooms"
## tier: medium
## truth: "A CORRIDOR MEETS A DOOR MEETS A ROOM BECAUSE THE RULES FORBID OTHERWISE"
##   — floor, wall and door are not placed, they are what remains once every illegal
##   adjacency has been struck out.
## essence: WFC over floor / wall / door tiles on a bench yields a small dungeon —
##   walls rise, floors drop, doors are marked. The plan is the only arrangement no
##   constraint vetoes.

@export var grid: int = 10
@export var cell: float = 0.072
@export var body_col: Color = Color(0.17, 0.16, 0.20)
@export var floor_col: Color = Color(0.32, 0.34, 0.40)
@export var wall_col: Color = Color(0.62, 0.58, 0.52)
@export var door_col: Color = Color(0.95, 0.75, 0.25)
@export var label_col: Color = Color(0.86, 0.90, 0.98)

# Tile kinds. Sockets per edge [N,E,S,W]: 0=solid (wall face), 1=open (floor face).
# floor opens on all sides; wall is solid all sides; door opens N/S only (a threshold).
const KIND_FLOOR := 0
const KIND_WALL := 1
const KIND_DOOR := 2
const T_SOCK := [
	[1, 1, 1, 1],  # floor
	[0, 0, 0, 0],  # wall
	[1, 0, 1, 0],  # door (open N-S, solid E-W)
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
		grid = clampi(int(config["grid"]), 4, 16)
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
		# weight floors and walls over doors so doors stay rare
		for k in range(t):
			if options[best][k]:
				allowed.append(k)
				if k != KIND_DOOR:
					allowed.append(k)
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
	var span: float = grid * cell
	add_child(_box(Vector3(0.0, 0.40, 0.0), Vector3(1.1, 0.8, 1.1), _matte_mat(body_col, 0.7, 0.1)))
	add_child(_box(Vector3(0.0, 0.84, 0.0), Vector3(span + 0.06, 0.04, span + 0.06), _matte_mat(Color(0.10, 0.10, 0.12), 0.6)))

	var solved: Array = _solve()
	var off: float = -span * 0.5 + cell * 0.5
	for i in range(grid * grid):
		var gx: int = i % grid
		var gz: int = i / grid
		var kind: int = solved[i]
		var px: float = off + gx * cell
		var pz: float = off + gz * cell
		if kind == KIND_WALL:
			add_child(_box(Vector3(px, 0.86 + 0.05, pz), Vector3(cell * 0.92, 0.10, cell * 0.92), _matte_mat(wall_col, 0.8)))
		elif kind == KIND_DOOR:
			add_child(_box(Vector3(px, 0.865, pz), Vector3(cell * 0.92, 0.01, cell * 0.92), _matte_mat(floor_col, 0.7)))
			add_child(_box(Vector3(px, 0.90, pz), Vector3(cell * 0.30, 0.08, cell * 0.30), _glow_mat(door_col, 1.6)))
		else:
			add_child(_box(Vector3(px, 0.865, pz), Vector3(cell * 0.92, 0.01, cell * 0.92), _matte_mat(floor_col, 0.7)))

	add_child(_billboard_label("WFC ROOMS", Vector3(0.0, 1.6, 0.0), 22, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	rotation.y = sin(Time.get_ticks_msec() * 0.0002) * 0.04
