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

## AXIS — WHAT THIS BENCH SHOWS OF THE WORK THAT PRODUCED THE PLAN. Shared word for word
## with the other six procedural benches (mc_field, sdf_sculpt, wfc_tile, voronoi, slime,
## colonization): one kit, one vocabulary, so a room of generators can be set to argue the
## same thing about all of them at once.
##
##   result  the finished plan alone on a bare bench — the legacy lineage, byte for byte
##   rule    the three kinds posted upright at the back with their sockets, and the joins
##           that survive: architecture as a satisfied constraint, with the constraint shown
##   trial   five earlier plans racked along the front lip: this dungeon is a draw
##   reject  a scrap tray of kinds struck out — every placement propagation forbade
##
## The claim is whether a generated thing is a RESULT or a PROOF. This bench's own truth
## line says a corridor meets a door because the rules forbid otherwise — and then it
## shows you only the corridor. `result` is that omission; the other three repair it.
@export_enum("result", "rule", "trial", "reject") var workings: String = "result"
const WORKINGS: PackedStringArray = ["result", "rule", "trial", "reject"]

## RUN PIN. -1 = the live bench exactly as it has always been: the collapse seeded from
## entropy, a different plan every launch, and the sway clock free. Any value >= 0 seeds
## the solver AND stops the clock, so the bench shows one nameable, repeatable plan.
##
## THIS IS THE PRECONDITION FOR MEASURING ANYTHING HERE. Left at -1, five variants of this
## bench are five DIFFERENT dungeons, and a sweep would score that noise as a confident
## result about whatever knob it was turning.
@export var run_pin: int = -1

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


## The colour this bench paints a kind in. Read from the same exports the plan uses, so
## the board cannot drift away from the thing it claims to explain.
func _workings_kind_color(k: int) -> Color:
	if k == KIND_WALL:
		return wall_col
	if k == KIND_DOOR:
		return door_col
	return floor_col


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


## RULE — the law posted. Top row: the three kinds, each with a nub standing on every edge
## its socket declares OPEN. Bottom row: three joins tested, drawn as two cells brought
## edge to edge with their facing sockets showing, and a verdict above — a bright bar where
## the join survives, a red cross where it is struck out. Read straight off T_SOCK, so the
## board is the solver's own table and not an illustration of it.
func _workings_rule() -> void:
	var bd: Node3D = _workings_board()
	var by: float = W_TOP + 0.08 + W_BOARD_H * 0.5
	var fz: float = -W_HZ + 0.11 + 0.014
	var nub: StandardMaterial3D = _glow_mat(Color(0.62, 0.90, 0.98), 1.3)
	var ok: StandardMaterial3D = _glow_mat(Color(0.45, 0.92, 0.55), 1.4)
	var no: StandardMaterial3D = _glow_mat(Color(0.92, 0.30, 0.24), 1.4)
	# the alphabet: three kinds and the edges they open
	var ks: float = 0.086
	for k in range(T_SOCK.size()):
		var kx: float = -0.17 + float(k) * 0.17
		var ky: float = by + 0.095
		bd.add_child(_box(Vector3(kx, ky, fz), Vector3(ks, ks, 0.014), _matte_mat(_workings_kind_color(k), 0.75)))
		var sock: Array = T_SOCK[k]
		if int(sock[0]) == 1:
			bd.add_child(_box(Vector3(kx, ky + ks * 0.5 + 0.009, fz + 0.004), Vector3(0.028, 0.018, 0.012), nub))
		if int(sock[1]) == 1:
			bd.add_child(_box(Vector3(kx + ks * 0.5 + 0.009, ky, fz + 0.004), Vector3(0.018, 0.028, 0.012), nub))
		if int(sock[2]) == 1:
			bd.add_child(_box(Vector3(kx, ky - ks * 0.5 - 0.009, fz + 0.004), Vector3(0.028, 0.018, 0.012), nub))
		if int(sock[3]) == 1:
			bd.add_child(_box(Vector3(kx - ks * 0.5 - 0.009, ky, fz + 0.004), Vector3(0.018, 0.028, 0.012), nub))
	# three joins tested left-to-right: A's EAST socket must equal B's WEST socket
	var pairs: Array = [
		[KIND_FLOOR, KIND_FLOOR], [KIND_FLOOR, KIND_WALL], [KIND_WALL, KIND_DOOR],
	]
	var ps: float = 0.052
	for i in range(pairs.size()):
		var pc: float = -0.19 + float(i) * 0.19
		var py: float = by - 0.095
		var a: int = int(pairs[i][0])
		var b: int = int(pairs[i][1])
		bd.add_child(_box(Vector3(pc - 0.028, py, fz), Vector3(ps, ps, 0.014), _matte_mat(_workings_kind_color(a), 0.75)))
		bd.add_child(_box(Vector3(pc + 0.028, py, fz), Vector3(ps, ps, 0.014), _matte_mat(_workings_kind_color(b), 0.75)))
		# the facing sockets, shown at the seam
		if int(T_SOCK[a][1]) == 1:
			bd.add_child(_box(Vector3(pc - 0.008, py, fz + 0.006), Vector3(0.014, 0.026, 0.012), nub))
		if int(T_SOCK[b][3]) == 1:
			bd.add_child(_box(Vector3(pc + 0.008, py, fz + 0.006), Vector3(0.014, 0.026, 0.012), nub))
		# the verdict
		if int(T_SOCK[a][1]) == int(T_SOCK[b][3]):
			bd.add_child(_box(Vector3(pc, by - 0.026, fz + 0.006), Vector3(0.046, 0.015, 0.010), ok))
		else:
			for ang in [38.0, -38.0]:
				var x: MeshInstance3D = _box(Vector3(pc, by - 0.026, fz + 0.006), Vector3(0.046, 0.014, 0.010), no)
				x.rotation_degrees = Vector3(0.0, 0.0, float(ang))
				bd.add_child(x)


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
## 3x3 miniature of an EARLIER plan from this same rule set, and a tick under each marks
## its place in the order. The dungeon behind them stops being the building and becomes
## the fifth building.
func _workings_trial() -> void:
	var sz: float = _workings_shelf()
	var plate: StandardMaterial3D = _matte_mat(Color(0.16, 0.17, 0.21), 0.85)
	var tick: StandardMaterial3D = _glow_mat(door_col, 1.3)
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
			var kind: int = (b + i) % 3
			var mark: StandardMaterial3D = _matte_mat(_workings_kind_color(kind), 0.7)
			var m: MeshInstance3D = _box(
				Vector3(cx + ox, cy + oy * 0.95 + 0.006, sz + 0.008 + oy * 0.31),
				Vector3(0.034, 0.034, 0.008), mark)
			m.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
			add_child(m)
		add_child(_box(Vector3(cx, W_TOP + 0.010, sz + 0.105), Vector3(0.020, 0.020, 0.014), tick))


## REJECT — the deletions. A scrap tray hangs off the right flank heaped with kinds that
## were struck out: two of the three possibilities died in every cell on that plan, and
## this tray is the only place in the artifact where the vetoes appear at all. The tray
## sits BELOW the working surface, so the plan is not touched — only the claim about it.
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
		var junk: StandardMaterial3D = _matte_mat(_workings_kind_color(i % 3).darkened(0.45), 0.92)
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
