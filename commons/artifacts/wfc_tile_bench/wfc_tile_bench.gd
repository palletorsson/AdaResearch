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

## AXIS — WHAT THIS BENCH SHOWS OF THE WORK THAT PRODUCED THE TILING. Shared word for word
## with the other six procedural benches (mc_field, sdf_sculpt, wfc_room, voronoi, slime,
## colonization): one kit, one vocabulary, so a room of generators can be set to argue the
## same thing about all of them at once.
##
##   result  the finished tiling alone on a bare bench — the legacy lineage, byte for byte
##   rule    the alphabet posted upright at the back: eight tiles and the sockets they
##           present, which is the ENTIRE constraint the picture satisfies
##   trial   five earlier collapses racked along the front lip: this tiling is a draw
##   reject  a scrap tray of options struck out — every tile propagation forbade
##
## The claim is whether a generated thing is a RESULT or a PROOF, and a solver is where
## that question is sharpest. Wave function collapse does not draw a picture; it deletes
## every picture that breaks a rule and shows you what is left. `result` presents the
## survivor as a composition. `rule` posts the premise. `reject` shows the deletions —
## which are, quantitatively, almost the whole of what the algorithm did.
@export_enum("result", "rule", "trial", "reject") var workings: String = "result"
const WORKINGS: PackedStringArray = ["result", "rule", "trial", "reject"]

## RUN PIN. -1 = the live bench exactly as it has always been: the collapse seeded from
## entropy, a different tiling every launch, and the sway clock free. Any value >= 0 seeds
## the solver AND stops the clock, so the bench shows one nameable, repeatable tiling.
##
## THIS IS THE PRECONDITION FOR MEASURING ANYTHING HERE. Left at -1, five variants of this
## bench are five DIFFERENT tilings, and a sweep would score that noise as a confident
## result about whatever knob it was turning. -1 keeps every live placement exactly as it
## is — a generator that always generated the same world would be a poor advertisement for
## generation — so the pin is what the bench is set to when it is being photographed, not
## what it is set to when it is being lived in.
@export var run_pin: int = -1

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
	if run_pin < 0:
		_rng.randomize()
	else:
		_rng.seed = run_pin
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("grid"):
		grid = clampi(int(config["grid"]), 4, 16)
	if config.has("workings"):
		var _w: String = str(config["workings"]).strip_edges().to_lower()
		workings = _w if WORKINGS.has(_w) else workings
	if config.has("run_pin"):
		run_pin = int(str(config["run_pin"]))
	# Re-pin ONLY when pinned. An unconditional reseed here would randomize a stream that
	# today just carries on, which is a change to the legacy rebuild.
	if run_pin >= 0:
		_rng.seed = run_pin
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

	# WORKINGS fittings, appended LAST so every child index and position above is
	# untouched on the legacy path. "result" falls through and adds nothing at all.
	match workings:
		"rule":
			_workings_rule()
		"trial":
			_workings_trial()
		"reject":
			_workings_reject()
		_:
			pass                                  # "result" — the legacy lineage


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# A pinned bench holds still — the sway is a wall-clock rotation of the WHOLE body,
	# so without this every still of the bench is taken at a different angle.
	if run_pin >= 0:
		return
	rotation.y = sin(Time.get_ticks_msec() * 0.0002) * 0.04


# ── WORKINGS ─────────────────────────────────────────────────────────────────
# The three fittings that turn a display into an apparatus. Built only from
# EmbodiedProp primitives so the seven benches stay one kit, and fully deterministic
# (no draw from _rng, no clock) so a variant is a variant and not another lottery.
#
# Each value grows the bench in a DIFFERENT direction — rule upward at the back, trial
# forward off the front lip, reject sideways off the right — so no two of them compete
# for the same pixels, and all three land at nearly the same bounding radius, which
# keeps their pairwise comparison free of any framing shift.

const W_TOP: float = 0.86       # the working surface these fittings mount to
const W_HX: float = 0.55        # bench half-width (X)
const W_HZ: float = 0.55        # bench half-depth (Z)
## How far right of centre the rule board stands — see _workings_board().
const W_BOARD_X: float = 0.0
const W_BOARD_W: float = 0.60
const W_BOARD_H: float = 0.36
## Five earlier collapses kept as coupons — fixed 9-bit patterns, not draws. A rack that
## re-rolled every boot would be a lottery, not a record.
const W_TRIALS: Array = [0b101101110, 0b011010101, 0b110011011, 0b010111010, 0b111001101]
## Where the discards lie in the tray. Fixed, for the same reason.
const W_HEAP: Array = [
	Vector2(-0.09, -0.15), Vector2(0.02, -0.17), Vector2(0.10, -0.11),
	Vector2(-0.11, -0.04), Vector2(-0.01, -0.06), Vector2(0.09, -0.01),
	Vector2(-0.08, 0.05), Vector2(0.03, 0.04), Vector2(0.11, 0.09),
	Vector2(-0.10, 0.14), Vector2(0.00, 0.16), Vector2(0.08, 0.18),
	Vector2(-0.04, 0.10), Vector2(0.05, -0.14),
]


## The upright the rule board stands on, and the board itself. Shared shape across the
## seven; only what is DRAWN on the face is this bench's own law.
##
## Returns a HOLDER, not a height, so the whole diagram can be slid sideways in one place.
## That matters: the sweep camera sits at yaw 0.62 / pitch -0.26, and on the benches whose
## specimen is a tall object floating over the working surface, a board centred behind it
## loses 36% of its width — the LEFT 36%, which is where a diagram's densest content
## naturally lands. W_BOARD_X carries it clear.
func _workings_board() -> Node3D:
	var bd := Node3D.new()
	bd.position = Vector3(W_BOARD_X, 0.0, 0.0)
	add_child(bd)
	var post: StandardMaterial3D = _steel_mat(Color(0.34, 0.36, 0.42))
	var face: StandardMaterial3D = _matte_mat(Color(0.10, 0.11, 0.14), 0.88)
	var edge: StandardMaterial3D = _matte_mat(Color(0.32, 0.34, 0.40), 0.55)
	var bz: float = -W_HZ + 0.11
	var by: float = W_TOP + 0.08 + W_BOARD_H * 0.5
	for sx in [-0.26, 0.26]:
		var px: float = float(sx)
		bd.add_child(_cylinder(Vector3(px, W_TOP + 0.04, bz), 0.014, 0.08, post))
	bd.add_child(_box(Vector3(0.0, by, bz - 0.014), Vector3(W_BOARD_W + 0.05, W_BOARD_H + 0.05, 0.020), edge))
	bd.add_child(_box(Vector3(0.0, by, bz), Vector3(W_BOARD_W, W_BOARD_H, 0.016), face))
	return bd


## RULE — the alphabet posted. All eight tiles, each with a nub standing on every edge
## whose socket is a path. That IS the constraint: two tiles may sit side by side exactly
## when the nubs meet across the join, and nothing else in the solver is a rule. Read from
## TILE_SOCK and TILE_COL, so the board cannot drift away from what the solver enforces.
func _workings_rule() -> void:
	var bd: Node3D = _workings_board()
	var by: float = W_TOP + 0.08 + W_BOARD_H * 0.5
	var fz: float = -W_HZ + 0.11 + 0.014
	var nub: StandardMaterial3D = _glow_mat(Color(0.96, 0.92, 0.62), 1.4)
	var ts: float = 0.072
	for k in range(TILE_NAMES.size()):
		var col: int = k % 4
		var row: int = k / 4
		var tx: float = -0.195 + float(col) * 0.130
		var ty: float = by + 0.075 - float(row) * 0.150
		var tcol: Color = TILE_COL[k]
		var tmat: Material = _glow_mat(tcol, 0.9) if k != 0 else _matte_mat(tcol.lightened(0.10), 0.85)
		bd.add_child(_box(Vector3(tx, ty, fz), Vector3(ts, ts, 0.014), tmat))
		var sock: Array = TILE_SOCK[k]
		# [N, E, S, W] — a nub stands wherever the socket is a path edge
		if int(sock[0]) == 1:
			bd.add_child(_box(Vector3(tx, ty + ts * 0.5 + 0.010, fz + 0.004), Vector3(0.026, 0.020, 0.012), nub))
		if int(sock[1]) == 1:
			bd.add_child(_box(Vector3(tx + ts * 0.5 + 0.010, ty, fz + 0.004), Vector3(0.020, 0.026, 0.012), nub))
		if int(sock[2]) == 1:
			bd.add_child(_box(Vector3(tx, ty - ts * 0.5 - 0.010, fz + 0.004), Vector3(0.026, 0.020, 0.012), nub))
		if int(sock[3]) == 1:
			bd.add_child(_box(Vector3(tx - ts * 0.5 - 0.010, ty, fz + 0.004), Vector3(0.020, 0.026, 0.012), nub))


## The shelf and rack that carry the earlier runs, cantilevered off the front lip on two
## struts. Shared shape across the seven; the coupons carry this bench's own palette.
func _workings_shelf() -> float:
	var steel: StandardMaterial3D = _steel_mat(Color(0.34, 0.36, 0.42))
	var sz: float = W_HZ + 0.13
	add_child(_box(Vector3(0.0, W_TOP - 0.012, sz), Vector3(0.88, 0.026, 0.26), _matte_mat(Color(0.20, 0.21, 0.25), 0.8)))
	for sx in [-0.34, 0.34]:
		var px: float = float(sx)
		add_child(_cylinder_between(Vector3(px, W_TOP - 0.26, W_HZ - 0.02), Vector3(px, W_TOP - 0.03, sz + 0.10), 0.013, steel))
	return sz


## TRIAL — the collapse as a series. Five coupons stand leaning back on the shelf, each a
## 3x3 miniature of an EARLIER collapse of this same tile set, and a tick under each marks
## its place in the order. The tiling behind them stops being the arrangement and becomes
## the fifth arrangement, no more chosen than the four on the rack.
func _workings_trial() -> void:
	var sz: float = _workings_shelf()
	var plate: StandardMaterial3D = _matte_mat(Color(0.16, 0.17, 0.21), 0.85)
	var tick: StandardMaterial3D = _glow_mat(TILE_COL[7], 1.2)
	for i in range(5):
		var cx: float = -0.32 + float(i) * 0.16
		var cy: float = W_TOP + 0.075
		var coupon: MeshInstance3D = _box(Vector3(cx, cy, sz), Vector3(0.132, 0.150, 0.010), plate)
		coupon.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
		add_child(coupon)
		var bits: int = int(W_TRIALS[i])
		for b in range(9):
			if (bits >> b) & 1 == 0:
				continue
			var gx: int = b % 3
			var gy: int = b / 3
			var ox: float = (float(gx) - 1.0) * 0.040
			var oy: float = (1.0 - float(gy)) * 0.040
			# each surviving cell wears one of the real tile colours, so a coupon reads
			# as a small tiling and not as an abstract pattern
			var mark: StandardMaterial3D = _glow_mat(TILE_COL[1 + (b + i) % 7], 0.9)
			var m: MeshInstance3D = _box(
				Vector3(cx + ox, cy + oy * 0.95 + 0.006, sz + 0.008 + oy * 0.31),
				Vector3(0.034, 0.034, 0.008), mark)
			m.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
			add_child(m)
		add_child(_box(Vector3(cx, W_TOP + 0.010, sz + 0.105), Vector3(0.020, 0.020, 0.014), tick))


## REJECT — the deletions. A scrap tray hangs off the right flank heaped with tiles that
## were struck out: for every cell on the bench, propagation eliminated seven of the eight
## possibilities, and this tray is the only place in the artifact where that work appears
## at all. The tray sits BELOW the working surface, so the tiling is not touched — only
## the claim about it is.
func _workings_reject() -> void:
	var steel: StandardMaterial3D = _steel_mat(Color(0.32, 0.34, 0.40))
	var tray: StandardMaterial3D = _matte_mat(Color(0.19, 0.20, 0.24), 0.85)
	var tx: float = W_HX + 0.17
	var ty: float = W_TOP - 0.12
	for sz2 in [-0.16, 0.16]:
		var pz: float = float(sz2)
		add_child(_box(Vector3(W_HX + 0.08, ty + 0.01, pz), Vector3(0.22, 0.026, 0.048), steel))
	add_child(_box(Vector3(tx, ty, 0.0), Vector3(0.32, 0.022, 0.44), tray))
	add_child(_box(Vector3(tx, ty + 0.026, -0.22), Vector3(0.32, 0.052, 0.016), tray))
	add_child(_box(Vector3(tx, ty + 0.026, 0.22), Vector3(0.32, 0.052, 0.016), tray))
	add_child(_box(Vector3(tx - 0.16, ty + 0.026, 0.0), Vector3(0.016, 0.052, 0.44), tray))
	add_child(_box(Vector3(tx + 0.16, ty + 0.026, 0.0), Vector3(0.016, 0.052, 0.44), tray))
	for i in range(W_HEAP.size()):
		var o: Vector2 = W_HEAP[i]
		var s: float = 0.030 + float(i % 4) * 0.008
		# a struck-out tile keeps its identity but loses its light — these were candidates
		var junk: StandardMaterial3D = _matte_mat(TILE_COL[1 + i % 7].darkened(0.45), 0.9)
		var p: MeshInstance3D = _box(Vector3(tx + o.x, ty + 0.024 + float(i % 3) * 0.011, o.y), Vector3(s, s, s), junk)
		p.rotation_degrees = Vector3(float(i * 17 % 40), float(i * 29 % 90), float(i * 11 % 35))
		add_child(p)
	# The tag stands UP, which on this camera (pitch -0.26, so 15 degrees above the
	# horizon) is the only cheap silhouette a tray has: every horizontal surface here
	# is foreshortened to a quarter of its area, and a vertical plate is not.
	add_child(_box(Vector3(tx, ty + 0.125, -0.20), Vector3(0.25, 0.18, 0.012), _matte_mat(Color(0.14, 0.14, 0.17), 0.9)))
	var strike: MeshInstance3D = _box(Vector3(tx, ty + 0.125, -0.19), Vector3(0.26, 0.030, 0.010), _glow_mat(Color(0.90, 0.32, 0.22), 1.3))
	strike.rotation_degrees = Vector3(0.0, 0.0, 26.0)
	add_child(strike)
