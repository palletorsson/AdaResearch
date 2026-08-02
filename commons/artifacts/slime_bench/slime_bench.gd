extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SlimeBench

## @identity
## name: Slime Bench
## tier: medium
## truth: agents that follow their own trail build a transport network
##
## A Physarum (slime mould) simulation on a bench. Hundreds of agents wander a
## grid, each sniffing the trail field at three points ahead — left, centre,
## right — and steering toward the strongest scent. They move, deposit a little
## trail, and the field diffuses and decays. Pre-run ~80 steps so the bench
## already shows the veins the colony has carved.

@export var grid_size: int = 64
@export var agent_count: int = 300
@export var prerun_steps: int = 80
@export var sense_dist: float = 3.0
@export var sense_angle: float = 0.6
@export var turn_speed: float = 0.5
@export var deposit: float = 0.22
@export var decay: float = 0.92
@export var low_color: Color = Color(0.08, 0.18, 0.22)
@export var high_color: Color = Color(0.4, 1.0, 0.7)

## AXIS — WHAT THIS BENCH SHOWS OF THE WORK THAT PRODUCED THE NETWORK. Shared word for
## word with the other six procedural benches (mc_field, sdf_sculpt, wfc_tile, wfc_room,
## voronoi, colonization): one kit, one vocabulary, so a room of generators can be set to
## argue the same thing about all of them at once.
##
##   result  the finished veins alone on a bare bench — the legacy lineage, byte for byte
##   rule    the agent's whole law posted upright at the back: sense three ways ahead,
##           turn to the strongest, deposit, and let the trail decay
##   trial   five earlier colonies racked along the front lip: this network is a draw
##   reject  a scrap tray of the paths that faded — nine tenths of everything laid down
##           here was decayed away, and the surviving veins are what is left of it
##
## The claim is whether a generated thing is a RESULT or a PROOF. A Physarum plate is the
## most seductive picture in this whole set — it looks like a photograph of an organism —
## and the four lines of arithmetic that make it are nowhere in the frame. `rule` puts
## them there, at the cost of admitting the organism is a rumour.
@export_enum("result", "rule", "trial", "reject") var workings: String = "result"
const WORKINGS: PackedStringArray = ["result", "rule", "trial", "reject"]

## RUN PIN. -1 = the live bench exactly as it has always been: agents seeded from entropy,
## a different colony every launch, and the sim advancing on the wall clock. Any value >= 0
## seeds the colony AND stops the clock, so the bench shows the pre-run state and holds it.
##
## THIS IS THE PRECONDITION FOR MEASURING ANYTHING HERE, twice over: the start positions
## are random AND the sim keeps stepping while the camera is deciding what to look at, so
## an unpinned capture is a photograph of an unrepeatable instant of an unrepeatable run.
@export var run_pin: int = -1

const BENCH_TOP: float = 0.85
const PLATE: float = 0.9
var _cell: float = 0.0

var _field_buf: PackedFloat32Array = PackedFloat32Array()
var _field_tmp: PackedFloat32Array = PackedFloat32Array()
var _agents: Array[Vector3] = []  # x, y, heading
var _field_mi: MultiMeshInstance3D
var _accum: float = 0.0


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


func _build() -> void:
	_cell = PLATE / float(grid_size)
	# housing — a bench with the simulation plate on top
	add_child(_box(Vector3(0.0, BENCH_TOP * 0.5, 0.0), Vector3(1.05, BENCH_TOP, 0.7), _matte_mat(Color(0.18, 0.2, 0.24))))
	add_child(_box(Vector3(0.0, BENCH_TOP + 0.01, 0.0), Vector3(PLATE + 0.05, 0.03, PLATE + 0.05), _matte_mat(Color(0.05, 0.07, 0.08))))
	add_child(_billboard_label("PHYSARUM", Vector3(0.0, 1.6, 0.0), 32, high_color))

	_init_sim()
	for _s in range(prerun_steps):
		_step_sim()
	_field_mi = _make_field()
	add_child(_field_mi)

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


func _init_sim() -> void:
	var n: int = grid_size * grid_size
	_field_buf = PackedFloat32Array()
	_field_buf.resize(n)
	_field_tmp = PackedFloat32Array()
	_field_tmp.resize(n)
	_agents.clear()
	var centre: float = float(grid_size) * 0.5
	for _i in range(agent_count):
		# start clustered in a ring near the middle
		var ang: float = _rng.randf() * TAU
		var rad: float = _rng.randf() * float(grid_size) * 0.2
		var x: float = centre + cos(ang) * rad
		var y: float = centre + sin(ang) * rad
		_agents.append(Vector3(x, y, _rng.randf() * TAU))


func _idx(gx: int, gy: int) -> int:
	return wrapi(gy, 0, grid_size) * grid_size + wrapi(gx, 0, grid_size)


func _sample(fx: float, fy: float) -> float:
	return _field_buf[_idx(int(floor(fx)), int(floor(fy)))]


func _step_sim() -> void:
	# 1. agents sense, turn, move, deposit
	for i in range(_agents.size()):
		var a: Vector3 = _agents[i]
		var head: float = a.z
		var fc: float = _sample(a.x + cos(head) * sense_dist, a.y + sin(head) * sense_dist)
		var fl: float = _sample(a.x + cos(head - sense_angle) * sense_dist, a.y + sin(head - sense_angle) * sense_dist)
		var fr: float = _sample(a.x + cos(head + sense_angle) * sense_dist, a.y + sin(head + sense_angle) * sense_dist)
		if fc >= fl and fc >= fr:
			pass
		elif fc < fl and fc < fr:
			head += (turn_speed if _rng.randf() < 0.5 else -turn_speed)
		elif fl > fr:
			head -= turn_speed
		else:
			head += turn_speed
		var nx: float = wrapf(a.x + cos(head), 0.0, float(grid_size))
		var ny: float = wrapf(a.y + sin(head), 0.0, float(grid_size))
		_agents[i] = Vector3(nx, ny, head)
		var di: int = _idx(int(floor(nx)), int(floor(ny)))
		_field_buf[di] = minf(_field_buf[di] + deposit, 1.0)
	# 2. diffuse (3x3 box blur) + decay into tmp, then swap
	for gy in range(grid_size):
		for gx in range(grid_size):
			var acc: float = 0.0
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					acc += _field_buf[_idx(gx + ox, gy + oy)]
			_field_tmp[gy * grid_size + gx] = (acc / 9.0) * decay
	var swap: PackedFloat32Array = _field_buf
	_field_buf = _field_tmp
	_field_tmp = swap


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


func _make_field() -> MultiMeshInstance3D:
	var n: int = grid_size * grid_size
	var mi := _field(n)
	var mm: MultiMesh = mi.multimesh
	var box := mm.mesh as BoxMesh
	box.size = Vector3(_cell * 0.95, 1.0, _cell * 0.95)
	_paint_field(mm)
	return mi


func _paint_field(mm: MultiMesh) -> void:
	var top: float = BENCH_TOP + 0.03
	var half: float = PLATE * 0.5
	for gy in range(grid_size):
		for gx in range(grid_size):
			var i: int = gy * grid_size + gx
			var v: float = clampf(_field_buf[i], 0.0, 1.0)
			var h: float = 0.004 + v * 0.07
			var px: float = -half + (float(gx) + 0.5) * _cell
			var pz: float = -half + (float(gy) + 0.5) * _cell
			var xf := Transform3D(Basis().scaled(Vector3(1.0, h, 1.0)), Vector3(px, top + h * 0.5, pz))
			mm.set_instance_transform(i, xf)
			mm.set_instance_color(i, low_color.lerp(high_color, v))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# A pinned bench holds still: the colony stays at the pre-run state it was built with.
	# Without this the plate advances while the camera is still deciding where to stand,
	# and a still of the network is a still of HOW LONG the capture took to set up.
	if run_pin >= 0:
		return
	# keep the colony alive — advance and repaint at a calm cadence
	_accum += delta
	if _accum < 0.12:
		return
	_accum = 0.0
	_step_sim()
	if _field_mi != null:
		_paint_field(_field_mi.multimesh)


# ── WORKINGS ─────────────────────────────────────────────────────────────────
# The three fittings that turn a display into an apparatus. Built only from
# EmbodiedProp primitives so the seven benches stay one kit, and fully deterministic
# (no draw from _rng, no clock) so a variant is a variant and not another lottery.
#
# Each value grows the bench in a DIFFERENT direction — rule upward at the back, trial
# forward off the front lip, reject sideways off the right — so no two of them compete
# for the same pixels, and all three land at nearly the same bounding radius, which
# keeps their pairwise comparison free of any framing shift.
#
# NOTE the two anchor constants: on this bench the plate OVERHANGS the body in Z, so a
# strut anchored at the plate rim would start in mid-air. W_ANCHOR_Z is the body face.

const W_TOP: float = 0.875      # the plate surface these fittings mount to
const W_HX: float = 0.525       # bench half-width (X)
const W_HZ: float = 0.475       # plate half-depth (Z) — the front lip
const W_ANCHOR_Z: float = 0.33  # body half-depth — where a strut can actually land
const W_BOARD_Z: float = -0.43  # back rim of the plate
## How far right of centre the rule board stands — see _workings_board().
const W_BOARD_X: float = 0.0
const W_BOARD_W: float = 0.60
const W_BOARD_H: float = 0.36
## Five earlier colonies kept as coupons — fixed 9-bit patterns, not draws. A rack that
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
	var by: float = W_TOP + 0.08 + W_BOARD_H * 0.5
	for sx in [-0.26, 0.26]:
		var px: float = float(sx)
		bd.add_child(_cylinder(Vector3(px, W_TOP + 0.04, W_BOARD_Z), 0.014, 0.08, post))
	bd.add_child(_box(Vector3(0.0, by, W_BOARD_Z - 0.014), Vector3(W_BOARD_W + 0.05, W_BOARD_H + 0.05, 0.020), edge))
	bd.add_child(_box(Vector3(0.0, by, W_BOARD_Z), Vector3(W_BOARD_W, W_BOARD_H, 0.016), face))
	return bd


## RULE — the whole law posted, and it is short. LEFT: one agent, three sensors fanned at
## sense_angle either side of its heading, and it turns toward whichever pad reads
## strongest — that is the entire behaviour, there is no plan and no map. RIGHT: the decay
## ramp, a trail losing a fixed fraction each tick, which is why only the reinforced paths
## survive as veins. Between them they generate everything on the plate.
func _workings_rule() -> void:
	var bd: Node3D = _workings_board()
	var by: float = W_TOP + 0.08 + W_BOARD_H * 0.5
	var fz: float = W_BOARD_Z + 0.014
	var trim: StandardMaterial3D = _matte_mat(Color(0.46, 0.48, 0.54), 0.7)
	var whisk: StandardMaterial3D = _matte_mat(high_color.darkened(0.35), 0.6)
	var pad_dim: StandardMaterial3D = _matte_mat(low_color.lightened(0.22), 0.8)
	var pad_hot: StandardMaterial3D = _glow_mat(high_color, 1.6)
	# the agent
	var ax: float = -0.25
	var ay: float = by + 0.02
	var dot: MeshInstance3D = _sphere(Vector3(ax, ay, fz + 0.012), 0.022, _glow_mat(high_color.lightened(0.2), 1.4))
	dot.scale = Vector3(1.0, 1.0, 0.22)
	bd.add_child(dot)
	# three sensors, fanned at the real sense_angle either side of straight ahead
	var reach: float = 0.155
	for k in range(3):
		var ang: float = float(k - 1) * sense_angle
		var tipx: float = ax + cos(ang) * reach
		var tipy: float = ay + sin(ang) * reach
		bd.add_child(_cylinder_between(Vector3(ax, ay, fz + 0.006), Vector3(tipx, tipy, fz + 0.006), 0.006, whisk))
		var hot: bool = (k == 2)
		bd.add_child(_box(Vector3(tipx, tipy, fz + 0.010), Vector3(0.034, 0.034, 0.012), pad_hot if hot else pad_dim))
	# ...and it turns to the strongest: a short step arrow off the winning sensor
	var wa: float = sense_angle
	bd.add_child(_box(Vector3(ax + cos(wa) * (reach + 0.055), ay + sin(wa) * (reach + 0.055), fz + 0.012),
		Vector3(0.048, 0.016, 0.010), pad_hot))
	# the divider — two halves of one law
	bd.add_child(_box(Vector3(-0.005, by, fz), Vector3(0.010, 0.290, 0.012), trim))
	# the decay ramp: what is not reinforced is gone within a few ticks
	var base: float = by - 0.145
	for i in range(6):
		var h: float = 0.255 * pow(0.72, float(i))
		var bx: float = 0.055 + float(i) * 0.044
		bd.add_child(_box(Vector3(bx, base + h * 0.5, fz + 0.008), Vector3(0.030, h, 0.012),
			_matte_mat(low_color.lerp(high_color, 1.0 - float(i) * 0.17), 0.65)))
	bd.add_child(_box(Vector3(0.165, base - 0.014, fz + 0.006), Vector3(0.250, 0.010, 0.010), trim))


## The shelf and rack that carry the earlier runs, cantilevered off the front lip on two
## struts anchored to the BODY, not the overhanging plate.
func _workings_shelf() -> float:
	var steel: StandardMaterial3D = _steel_mat(Color(0.34, 0.36, 0.42))
	var sz: float = W_HZ + 0.13
	add_child(_box(Vector3(0.0, W_TOP - 0.012, sz), Vector3(0.88, 0.026, 0.26), _matte_mat(Color(0.20, 0.21, 0.25), 0.8)))
	for sx in [-0.34, 0.34]:
		var px: float = float(sx)
		add_child(_cylinder_between(Vector3(px, W_TOP - 0.28, W_ANCHOR_Z), Vector3(px, W_TOP - 0.03, sz + 0.10), 0.013, steel))
	return sz


## TRIAL — the colony as a series. Five coupons stand leaning back on the shelf, each a
## 3x3 miniature of an EARLIER colony from the same rule, and a tick under each marks its
## place in the order. The network behind them stops being the organism and becomes the
## fifth organism, which is a harder thing to be moved by and a truer one.
func _workings_trial() -> void:
	var sz: float = _workings_shelf()
	var plate_mat: StandardMaterial3D = _matte_mat(Color(0.16, 0.17, 0.21), 0.85)
	var tick: StandardMaterial3D = _glow_mat(high_color, 1.3)
	for i in range(5):
		var cx: float = -0.32 + float(i) * 0.16
		var cy: float = W_TOP + 0.075
		var coupon: MeshInstance3D = _box(Vector3(cx, cy, sz), Vector3(0.132, 0.150, 0.010), plate_mat)
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
			# trail strength varies cell to cell, as it does on the plate
			var v: float = 0.35 + float((b * 3 + i) % 5) * 0.16
			var mark: StandardMaterial3D = _matte_mat(low_color.lerp(high_color, v), 0.7)
			var m: MeshInstance3D = _box(
				Vector3(cx + ox, cy + oy * 0.95 + 0.006, sz + 0.008 + oy * 0.31),
				Vector3(0.034, 0.034, 0.008), mark)
			m.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
			add_child(m)
		add_child(_box(Vector3(cx, W_TOP + 0.010, sz + 0.105), Vector3(0.020, 0.020, 0.014), tick))


## REJECT — what decayed. A scrap tray hangs off the right flank heaped with the trail
## that did not survive: every tick multiplies the whole field by `decay`, so the veins
## you can see are the small remainder of everything three hundred agents ever laid down.
## The tray sits BELOW the plate, so the network is not touched — only the claim about it.
func _workings_reject() -> void:
	var steel: StandardMaterial3D = _steel_mat(Color(0.32, 0.34, 0.40))
	var tray: StandardMaterial3D = _matte_mat(Color(0.19, 0.20, 0.24), 0.85)
	var tx: float = W_HX + 0.17
	var ty: float = W_TOP - 0.14
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
		# faded trail: the colour the plate uses, run most of the way down to nothing
		var junk: StandardMaterial3D = _matte_mat(low_color.lerp(high_color, 0.10 + float(i % 3) * 0.07), 0.92)
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
