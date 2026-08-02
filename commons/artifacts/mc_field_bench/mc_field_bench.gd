extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name McFieldBench

## @identity
## name: Marching Cubes Field Bench
## tier: medium
## truth: 256 cases stitch a surface where inside meets outside.
##
## A 3D scalar field becomes a skin. We sample a sum-of-metaballs field on a ~14^3
## grid sitting on the bench, then place a little box only at the BOUNDARY cells —
## the ones that are inside (f > thr) but have at least one empty 6-neighbour. The
## crust the boxes draw is exactly the surface marching cubes would triangulate:
## the level set where the noise crosses the threshold, where inside meets outside.

@export var res: int = 14
@export var threshold: float = 1.0
@export var span: float = 0.6
@export var lo_color: Color = Color(0.35, 0.85, 0.5)
@export var hi_color: Color = Color(0.95, 0.98, 1.0)

## AXIS — WHAT THIS BENCH SHOWS OF THE WORK THAT PRODUCED THE SPECIMEN. Shared word for
## word with the other six procedural benches (sdf_sculpt, wfc_tile, wfc_room, voronoi,
## slime, colonization): one kit, one vocabulary, so a room of generators can be set to
## argue the same thing about all of them at once.
##
##   result  the finished thing alone on a bare bench — the legacy lineage, byte for byte
##   rule    the law posted upright at the back: the premise the specimen follows from
##   trial   five earlier runs racked along the front lip: this one is a draw, not a fact
##   reject  a scrap tray slung off the right side: what was struck out to leave this
##
## The claim is whether a generated thing is a RESULT or a PROOF. A bench that shows only
## its output asks to be admired; a bench that also shows its rule, its other runs, or its
## discards asks to be checked. Procedural generation's whole rhetorical trick is to
## present an output as if it were a finding, and `result` is that trick with the evidence
## swept off the table.
##
## THE AXIS IS CARRIED BY THE BENCH, NEVER THE SPECIMEN. The skin here re-forms every
## frame from a drifting field; an axis mounted on it would be measuring the weather.
## The bench is the part that holds still.
@export_enum("result", "rule", "trial", "reject") var workings: String = "result"
const WORKINGS: PackedStringArray = ["result", "rule", "trial", "reject"]

## RUN PIN. -1 = the live bench exactly as it has always been: entropy-seeded draws where
## there are any, and the drift clock free. Any value >= 0 seeds the stream AND stops the
## clock, so the bench shows one nameable, repeatable state.
##
## This is the precondition for measuring anything here at all. This bench rebuilds its
## skin every frame off a wall-clock phase, so two captures a second apart are two
## different objects and a sweep would score the drift as a confident result about
## whatever knob it happened to be turning. -1 keeps every live placement exactly as it
## is; the sweep sets it and gets an apparatus that stands still to be photographed.
@export var run_pin: int = -1

const BASE_Y := 0.85

var _t: float = 0.0
var _skin: MultiMeshInstance3D


func _ready() -> void:
	if run_pin < 0:
		_rng.randomize()
	else:
		_rng.seed = run_pin
		_t = float(posmod(run_pin, 211)) * 0.043
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("res"):
		res = int(config["res"])
	if config.has("threshold"):
		threshold = float(config["threshold"])
	if config.has("workings"):
		var _w: String = str(config["workings"]).strip_edges().to_lower()
		workings = _w if WORKINGS.has(_w) else workings
	if config.has("run_pin"):
		run_pin = int(str(config["run_pin"]))
	# Re-pin ONLY when pinned. An unconditional reseed here would randomize a stream that
	# today just carries on, which is a change to the legacy rebuild.
	if run_pin >= 0:
		_rng.seed = run_pin
		_t = float(posmod(run_pin, 211)) * 0.043
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	# bench
	add_child(_box(Vector3(0.0, BASE_Y - 0.1, 0.0), Vector3(1.1, 0.2, 1.1), _matte_mat(Color(0.15, 0.16, 0.2), 0.85)))
	add_child(_cylinder(Vector3(0.0, (BASE_Y - 0.2) * 0.5, 0.0), 0.09, BASE_Y - 0.2, _steel_mat(Color(0.3, 0.32, 0.38))))
	# the generated thing: the boundary skin, sitting ON TOP of the bench
	_skin = _make_skin()
	_skin.position = Vector3(0.0, BASE_Y + 0.06 + span * 0.5, 0.0)
	add_child(_skin)
	add_child(_billboard_label("MARCHING CUBES", Vector3(0.0, 1.6, 0.0), 24, hi_color.lerp(lo_color, 0.3)))

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


# --- field -------------------------------------------------------------------

func _field_value(p: Vector3, balls: Array) -> float:
	# sum-of-metaballs: each ball contributes r^2 / d^2, surface where the sum == threshold
	var s: float = 0.0
	for b in balls:
		var c: Vector3 = b[0]
		var r: float = b[1]
		var d2: float = maxf(p.distance_squared_to(c), 1e-5)
		s += (r * r) / d2
	return s


func _make_balls() -> Array:
	# three drifting blobs inside the cube
	var balls: Array = []
	balls.append([Vector3(sin(_t) * 0.12, 0.0, cos(_t * 0.8) * 0.1), 0.20])
	balls.append([Vector3(0.14, sin(_t * 1.1) * 0.1, -0.1), 0.16])
	balls.append([Vector3(-0.13, cos(_t * 0.9) * 0.12, 0.12), 0.15])
	return balls


func _make_skin() -> MultiMeshInstance3D:
	var g: int = clampi(res, 6, 22)
	# pass 1: mark which cells are inside
	var balls: Array = _make_balls()
	var inside := PackedByteArray()
	inside.resize(g * g * g)
	var step: float = span / float(g - 1)
	var origin: float = -span * 0.5
	for ix in range(g):
		for iy in range(g):
			for iz in range(g):
				var p := Vector3(origin + ix * step, origin + iy * step, origin + iz * step)
				inside[_idx(ix, iy, iz, g)] = 1 if _field_value(p, balls) > threshold else 0
	# pass 2: keep only boundary cells (inside, but a 6-neighbour is empty/out of bounds)
	var cells: Array = []
	for ix in range(g):
		for iy in range(g):
			for iz in range(g):
				if inside[_idx(ix, iy, iz, g)] == 0:
					continue
				if _is_boundary(inside, ix, iy, iz, g):
					cells.append(Vector3i(ix, iy, iz))
	var mi := _field(maxi(cells.size(), 1))
	var mm: MultiMesh = mi.multimesh
	mm.instance_count = maxi(cells.size(), 1)
	var s: float = step * 0.95
	var i: int = 0
	for cell in cells:
		var ix: int = cell.x
		var iy: int = cell.y
		var iz: int = cell.z
		var pos := Vector3(origin + ix * step, origin + iy * step, origin + iz * step)
		var t: float = clampf(float(iy) / float(g - 1), 0.0, 1.0)
		var col: Color = lo_color.lerp(hi_color, t)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), pos))
		mm.set_instance_color(i, col)
		i += 1
	if cells.is_empty():
		mm.set_instance_transform(0, Transform3D(Basis().scaled(Vector3(0.001, 0.001, 0.001)), Vector3.ZERO))
		mm.set_instance_color(0, lo_color)
	return mi


func _is_boundary(inside: PackedByteArray, ix: int, iy: int, iz: int, g: int) -> bool:
	var dirs := [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]
	for d in dirs:
		var nx: int = ix + d.x
		var ny: int = iy + d.y
		var nz: int = iz + d.z
		if nx < 0 or ny < 0 or nz < 0 or nx >= g or ny >= g or nz >= g:
			return true
		if inside[_idx(nx, ny, nz, g)] == 0:
			return true
	return false


func _idx(ix: int, iy: int, iz: int, g: int) -> int:
	return (ix * g + iy) * g + iz


func _field(n: int) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.16 if emissive else 0.0
	mi.material_override = mat
	return mi


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# A pinned bench holds still. The skin here is rebuilt from a wall-clock phase, so
	# without this a still of the bench is a still of WHEN you looked.
	if run_pin >= 0:
		return
	# gentle sway — the field breathes, the skin re-forms slowly
	_t += delta * 0.35
	if _skin != null:
		remove_child(_skin)
		_skin.queue_free()
	_skin = _make_skin()
	_skin.position = Vector3(0.0, BASE_Y + 0.06 + span * 0.5, 0.0)
	add_child(_skin)


# ── WORKINGS ─────────────────────────────────────────────────────────────────
# The three fittings that turn a display into an apparatus. Built only from
# EmbodiedProp primitives so the seven benches stay one kit, and fully deterministic
# (no draw from _rng, no clock) so a variant is a variant and not another lottery.
#
# Each value grows the bench in a DIFFERENT direction — rule upward at the back, trial
# forward off the front lip, reject sideways off the right — so no two of them compete
# for the same pixels, and all three land at nearly the same bounding radius, which
# keeps their pairwise comparison free of any framing shift.

const W_TOP: float = 0.85       # the working surface these fittings mount to
const W_HX: float = 0.55        # bench half-width (X)
const W_HZ: float = 0.55        # bench half-depth (Z)
## How far right of centre the rule board stands — see _workings_board().
const W_BOARD_X: float = 0.16
const W_BOARD_W: float = 0.60
const W_BOARD_H: float = 0.36
## Five earlier runs kept as coupons — fixed 9-bit patterns, not draws. A rack that
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


## RULE — the law posted. Two lines of this algorithm, drawn: a field-value axis with the
## threshold notched bright on it (inside is f > thr), and the boundary test as a 3x3
## stencil where the lit centre cell keeps its box ONLY because a neighbour is empty.
## The skin on the bench is a consequence of exactly this and nothing else.
func _workings_rule() -> void:
	var bd: Node3D = _workings_board()
	var by: float = W_TOP + 0.08 + W_BOARD_H * 0.5
	var fz: float = -W_HZ + 0.11 + 0.014
	var dim: StandardMaterial3D = _matte_mat(lo_color.darkened(0.45), 0.7)
	var hot: StandardMaterial3D = _glow_mat(hi_color, 1.6)
	var mid: StandardMaterial3D = _matte_mat(lo_color, 0.6)
	# the field axis, lo -> hi, with the threshold notched
	bd.add_child(_box(Vector3(-0.06, by + 0.095, fz), Vector3(0.40, 0.034, 0.012), dim))
	bd.add_child(_box(Vector3(-0.19, by + 0.095, fz + 0.007), Vector3(0.10, 0.034, 0.012), mid))
	bd.add_child(_box(Vector3(0.04, by + 0.095, fz + 0.010), Vector3(0.024, 0.084, 0.012), hot))
	bd.add_child(_box(Vector3(0.21, by + 0.095, fz + 0.007), Vector3(0.055, 0.014, 0.012), _matte_mat(Color(0.42, 0.44, 0.50), 0.7)))
	# the boundary test, drawn: a 3x3 neighbourhood where the lit centre is INSIDE and the
	# cell to its right is EMPTY. That pair, and only that pair, is why a box is placed.
	var cs: float = 0.058
	var gap: StandardMaterial3D = _matte_mat(Color(0.46, 0.48, 0.54), 0.7)
	var rowy: float = by - 0.055
	for gy in range(3):
		for gx in range(3):
			var px: float = -0.20 + float(gx) * (cs + 0.014)
			var py: float = rowy - float(gy) * (cs + 0.014) + (cs + 0.014)
			if gx == 2 and gy == 1:
				# EMPTY — a hollow outline, so the absence is a drawn thing
				bd.add_child(_box(Vector3(px, py + cs * 0.5, fz), Vector3(cs, 0.009, 0.012), gap))
				bd.add_child(_box(Vector3(px, py - cs * 0.5, fz), Vector3(cs, 0.009, 0.012), gap))
				bd.add_child(_box(Vector3(px - cs * 0.5, py, fz), Vector3(0.009, cs, 0.012), gap))
				bd.add_child(_box(Vector3(px + cs * 0.5, py, fz), Vector3(0.009, cs, 0.012), gap))
			elif gx == 1 and gy == 1:
				bd.add_child(_box(Vector3(px, py, fz + 0.008), Vector3(cs, cs, 0.016), hot))
			else:
				bd.add_child(_box(Vector3(px, py, fz), Vector3(cs, cs, 0.012), dim))
	# ...therefore: an arrow to the box that gets placed. The whole cull in one line.
	bd.add_child(_box(Vector3(0.035, rowy, fz + 0.010), Vector3(0.080, 0.018, 0.010), gap))
	bd.add_child(_box(Vector3(0.086, rowy, fz + 0.012), Vector3(0.026, 0.040, 0.010), gap))
	bd.add_child(_box(Vector3(0.175, rowy, fz + 0.012), Vector3(0.075, 0.075, 0.016), hot))


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


## TRIAL — the run as a series. Five coupons stand leaning back on the shelf, each a
## 3x3 miniature of an EARLIER run of this same bench, and a tick under each marks its
## place in the order. The specimen behind them stops being the answer and becomes the
## fifth draw from a process that could as easily have handed you any of the others.
func _workings_trial() -> void:
	var sz: float = _workings_shelf()
	var plate: StandardMaterial3D = _matte_mat(Color(0.16, 0.17, 0.21), 0.85)
	var mark: StandardMaterial3D = _matte_mat(lo_color, 0.6)
	var tick: StandardMaterial3D = _glow_mat(hi_color, 1.2)
	for i in range(5):
		var cx: float = -0.32 + float(i) * 0.16
		var cy: float = W_TOP + 0.075
		var coupon: MeshInstance3D = _box(Vector3(cx, cy, sz), Vector3(0.132, 0.150, 0.010), plate)
		coupon.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
		add_child(coupon)
		# the miniature: this run's 3x3, read off a fixed pattern
		var bits: int = int(W_TRIALS[i])
		for b in range(9):
			if (bits >> b) & 1 == 0:
				continue
			var gx: int = b % 3
			var gy: int = b / 3
			var ox: float = (float(gx) - 1.0) * 0.040
			var oy: float = (1.0 - float(gy)) * 0.040
			var m: MeshInstance3D = _box(
				Vector3(cx + ox, cy + oy * 0.95 + 0.006, sz + 0.008 + oy * 0.31),
				Vector3(0.034, 0.034, 0.008), mark)
			m.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
			add_child(m)
		# the index tick: which run in the order this coupon is
		add_child(_box(Vector3(cx, W_TOP + 0.010, sz + 0.105), Vector3(0.020, 0.020, 0.014), tick))


## REJECT — the discards. A scrap tray hangs off the right flank on two brackets, heaped
## with what the cull threw away: cells that were inside the surface but had no empty
## neighbour, so nothing was drawn for them. The tray sits BELOW the working surface, so
## the specimen is not touched — only the claim about it is.
func _workings_reject() -> void:
	var steel: StandardMaterial3D = _steel_mat(Color(0.32, 0.34, 0.40))
	var tray: StandardMaterial3D = _matte_mat(Color(0.19, 0.20, 0.24), 0.85)
	var junk: StandardMaterial3D = _matte_mat(lo_color.darkened(0.55).lerp(Color(0.30, 0.30, 0.32), 0.5), 0.9)
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
		var p: MeshInstance3D = _box(Vector3(tx + o.x, ty + 0.024 + float(i % 3) * 0.011, o.y), Vector3(s, s, s), junk)
		p.rotation_degrees = Vector3(float(i * 17 % 40), float(i * 29 % 90), float(i * 11 % 35))
		add_child(p)
	# the tag: a plate struck through, so the tray reads as refused and not as stock
	# The tag stands UP, which on this camera (pitch -0.26, so 15 degrees above the
	# horizon) is the only cheap silhouette a tray has: every horizontal surface here
	# is foreshortened to a quarter of its area, and a vertical plate is not.
	add_child(_box(Vector3(tx, ty + 0.125, -0.20), Vector3(0.25, 0.18, 0.012), _matte_mat(Color(0.14, 0.14, 0.17), 0.9)))
	var strike: MeshInstance3D = _box(Vector3(tx, ty + 0.125, -0.19), Vector3(0.26, 0.030, 0.010), _glow_mat(Color(0.90, 0.32, 0.22), 1.3))
	strike.rotation_degrees = Vector3(0.0, 0.0, 26.0)
	add_child(strike)
