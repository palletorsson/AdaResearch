extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name WfcTileBench

## @identity
## name: "Wave function collapse"
## tier: medium
## truth: "THE TILES AGREE ON A WORLD NONE CHOSE ALONE" — each cell keeps every
##   possibility open until a neighbour forces its hand; the picture is the fixed
##   point where no socket lies against its opposite.
## essence: A 10x10 bench grid. Lowest-entropy cell collapses to a random allowed
##   tile, then propagation drops every neighbour option whose facing edge socket
##   mismatches. Chosen tiles render as small coloured shapes raised by type.

@export var grid: int = 10
@export var cell: float = 0.072
@export var body_col: Color = Color(0.16, 0.17, 0.21)
@export var top_col: Color = Color(0.78, 0.78, 0.74)
@export var label_col: Color = Color(0.84, 0.90, 0.98)

# Tile sockets per edge, order = [N, E, S, W]. 0 = empty edge, 1 = path edge.
# empty / straight-h / straight-v / corner-NE / corner-NW / corner-SE / corner-SW / cross
const TILE_NAMES := ["empty", "h", "v", "ne", "nw", "se", "sw", "cross"]
const TILE_SOCK := [
	[0, 0, 0, 0],  # empty
	[0, 1, 0, 1],  # straight horizontal (E-W)
	[1, 0, 1, 0],  # straight vertical   (N-S)
	[1, 1, 0, 0],  # corner N-E
	[1, 0, 0, 1],  # corner N-W
	[0, 1, 1, 0],  # corner S-E
	[0, 0, 1, 1],  # corner S-W
	[1, 1, 1, 1],  # cross
]
const TILE_COL := [
	Color(0.20, 0.22, 0.26),
	Color(0.30, 0.65, 0.95),
	Color(0.95, 0.55, 0.25),
	Color(0.45, 0.85, 0.55),
	Color(0.55, 0.80, 0.50),
	Color(0.85, 0.45, 0.70),
	Color(0.80, 0.50, 0.75),
	Color(0.95, 0.85, 0.30),
]
# Opposite-edge index for propagation: my edge e meets neighbour edge OPP[e].
const OPP := [2, 3, 0, 1]
# Neighbour offsets matching edge order [N, E, S, W].
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
	var t: int = TILE_NAMES.size()
	# options[i] = array of bool over tile ids
	var options: Array = []
	for _i in range(n * n):
		var row: Array = []
		for _k in range(t):
			row.append(true)
		options.append(row)

	for _step in range(n * n):
		# find lowest-entropy uncollapsed cell
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
		# collapse to a random still-allowed tile
		var allowed: Array = []
		for k in range(t):
			if options[best][k]:
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
			# collect which sockets the current cell can still present on edge e
			var my_vals: Dictionary = {}
			for k in range(t):
				if options[idx][k]:
					my_vals[TILE_SOCK[k][e]] = true
			var changed: bool = false
			for k in range(t):
				if not options[nidx][k]:
					continue
				var facing: int = TILE_SOCK[k][OPP[e]]
				if not my_vals.has(facing):
					options[nidx][k] = false
					changed = true
			if changed:
				stack.append(nidx)


func _build() -> void:
	var span: float = grid * cell
	# bench base ~1.1 x 0.2, top at y 0.85
	add_child(_box(Vector3(0.0, 0.40, 0.0), Vector3(1.1, 0.8, 1.1), _matte_mat(body_col, 0.7, 0.1)))
	add_child(_box(Vector3(0.0, 0.84, 0.0), Vector3(span + 0.06, 0.04, span + 0.06), _matte_mat(top_col, 0.5)))

	var solved: Array = _solve()
	var off: float = -span * 0.5 + cell * 0.5
	for i in range(grid * grid):
		var gx: int = i % grid
		var gz: int = i / grid
		var tid: int = solved[i]
		var px: float = off + gx * cell
		var pz: float = off + gz * cell
		var h: float = 0.010 + tid * 0.006
		var mat: Material = _glow_mat(TILE_COL[tid], 1.0) if tid != 0 else _matte_mat(TILE_COL[tid], 0.8)
		add_child(_box(Vector3(px, 0.86 + h * 0.5, pz), Vector3(cell * 0.86, h, cell * 0.86), mat))

	add_child(_billboard_label("WFC TILES", Vector3(0.0, 1.6, 0.0), 22, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	rotation.y = sin(Time.get_ticks_msec() * 0.0002) * 0.04
