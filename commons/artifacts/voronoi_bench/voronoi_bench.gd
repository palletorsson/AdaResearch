extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name VoronoiBench

## @identity
## name: Voronoi Bench
## tier: medium
## truth: every point claims the territory nearest it
##
## A Voronoi diagram on a bench. A dozen sites are scattered across a plate; an
## ~40x40 grid of flat tiles is coloured by whichever site is nearest. The
## boundaries are not drawn — they emerge where two claims meet. Small bright
## spheres mark the sites themselves so you can see the seeds of each cell.

@export var grid_size: int = 40
@export var site_count: int = 12
@export var plate: float = 0.9

## AXIS — WHAT THIS BENCH SHOWS OF THE WORK THAT PRODUCED THE DIAGRAM. Shared word for
## word with the other six procedural benches (mc_field, sdf_sculpt, wfc_tile, wfc_room,
## slime, colonization): one kit, one vocabulary, so a room of generators can be set to
## argue the same thing about all of them at once.
##
##   result  the finished territories alone on a bare bench — the legacy lineage
##   rule    the metric posted upright at the back: two sites, equidistance, and the
##           bisector that falls out of them — the boundary nobody drew
##   trial   five earlier scatters racked along the front lip: this partition is a draw
##   reject  a scrap tray of claims that lost — every cell has eleven sites that did not
##           get it, and they are otherwise nowhere in this artifact
##
## The claim is whether a generated thing is a RESULT or a PROOF. This bench's own truth
## line says the boundaries are not drawn, they emerge — and a still of a Voronoi diagram
## looks exactly like a picture somebody drew. `rule` is the difference.
@export_enum("result", "rule", "trial", "reject") var workings: String = "result"
const WORKINGS: PackedStringArray = ["result", "rule", "trial", "reject"]

## RUN PIN. -1 = the live bench exactly as it has always been: the sites scattered from
## entropy, a different partition every launch, and the sway clock free. Any value >= 0
## seeds the scatter AND stops the clock, so the bench shows one nameable partition.
##
## THIS IS THE PRECONDITION FOR MEASURING ANYTHING HERE, and this bench is the worst case
## of the seven: the field is 1600 saturated tiles across the whole plate, so a re-scatter
## repaints most of the coloured pixels in the frame. Five unpinned variants would differ
## enormously and for no reason connected to any axis.
@export var run_pin: int = -1

const BENCH_TOP: float = 0.85
var _cell: float = 0.0
var _sites: Array[Vector2] = []
var _site_colors: Array[Color] = []


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
	_cell = plate / float(grid_size)
	# housing — bench + plate
	add_child(_box(Vector3(0.0, BENCH_TOP * 0.5, 0.0), Vector3(1.05, BENCH_TOP, 0.7), _matte_mat(Color(0.2, 0.18, 0.22))))
	add_child(_box(Vector3(0.0, BENCH_TOP + 0.01, 0.0), Vector3(plate + 0.05, 0.03, plate + 0.05), _matte_mat(Color(0.06, 0.05, 0.07))))
	add_child(_billboard_label("VORONOI", Vector3(0.0, 1.6, 0.0), 32, Color(1.0, 0.85, 0.55)))

	_scatter_sites()
	add_child(_make_field())
	_mark_sites()

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


func _scatter_sites() -> void:
	_sites.clear()
	_site_colors.clear()
	var half: float = plate * 0.5
	var margin: float = plate * 0.08
	for i in range(site_count):
		var sx: float = _rng.randf_range(-half + margin, half - margin)
		var sz: float = _rng.randf_range(-half + margin, half - margin)
		_sites.append(Vector2(sx, sz))
		var hue: float = float(i) / float(site_count)
		_site_colors.append(Color.from_hsv(hue, 0.65, 0.95))


func _nearest_site(p: Vector2) -> int:
	var best: int = 0
	var best_d: float = INF
	for i in range(_sites.size()):
		var d: float = p.distance_squared_to(_sites[i])
		if d < best_d:
			best_d = d
			best = i
	return best


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
	box.size = Vector3(_cell * 0.96, 0.012, _cell * 0.96)
	var top: float = BENCH_TOP + 0.035
	var half: float = plate * 0.5
	for gy in range(grid_size):
		for gx in range(grid_size):
			var idx: int = gy * grid_size + gx
			var px: float = -half + (float(gx) + 0.5) * _cell
			var pz: float = -half + (float(gy) + 0.5) * _cell
			var owner: int = _nearest_site(Vector2(px, pz))
			mm.set_instance_transform(idx, Transform3D(Basis(), Vector3(px, top, pz)))
			mm.set_instance_color(idx, _site_colors[owner])
	return mi


func _mark_sites() -> void:
	var top: float = BENCH_TOP + 0.05
	for i in range(_sites.size()):
		var s: Vector2 = _sites[i]
		var mat := _glow_mat(_site_colors[i].lightened(0.3), 1.4)
		add_child(_sphere(Vector3(s.x, top + 0.02, s.y), 0.018, mat))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# A pinned bench holds still — the sway is a wall-clock rotation of the WHOLE body,
	# so without this every still of the bench is taken at a different angle.
	if run_pin >= 0:
		return
	# static diagram — a barely-there sway so it feels alive on the bench
	rotation.y = sin(Time.get_ticks_msec() * 0.0004) * 0.02


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
## Five earlier scatters kept as coupons — fixed 9-bit patterns, not draws. A rack that
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


## A ring lying in the board plane — a torus turned to face the reader.
func _workings_ring(x: float, y: float, z: float, r: float, tube: float, mat: Material) -> MeshInstance3D:
	var t: MeshInstance3D = _torus(Vector3(x, y, z), r, tube, mat)
	t.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	return t


## RULE — the metric posted. Two sites, rings of equal distance around the left one, and
## the bisector standing exactly where the two claims are tied. That line is the ONLY
## thing this algorithm computes; every border on the plate is one of them. Drawn rather
## than written, because the point of the bench is that nobody drew the borders.
func _workings_rule() -> void:
	var bd: Node3D = _workings_board()
	var by: float = W_TOP + 0.08 + W_BOARD_H * 0.5
	var fz: float = W_BOARD_Z + 0.014
	var ca: Color = Color.from_hsv(0.08, 0.65, 0.95)
	var cb: Color = Color.from_hsv(0.55, 0.65, 0.95)
	# the two territories, as flat washes — what the metric decides
	bd.add_child(_box(Vector3(-0.145, by, fz), Vector3(0.28, 0.30, 0.010), _matte_mat(ca.darkened(0.55), 0.9)))
	bd.add_child(_box(Vector3(0.145, by, fz), Vector3(0.28, 0.30, 0.010), _matte_mat(cb.darkened(0.55), 0.9)))
	# equidistance around the left site — the rings the claim is measured on
	var ring: StandardMaterial3D = _matte_mat(ca.lightened(0.15), 0.6)
	for r in [0.045, 0.082, 0.119]:
		bd.add_child(_workings_ring(-0.16, by, fz + 0.008, float(r), 0.0045, ring))
	# the two sites themselves
	var da: MeshInstance3D = _sphere(Vector3(-0.16, by, fz + 0.014), 0.021, _glow_mat(ca.lightened(0.3), 1.5))
	da.scale = Vector3(1.0, 1.0, 0.22)
	bd.add_child(da)
	var db: MeshInstance3D = _sphere(Vector3(0.16, by, fz + 0.014), 0.021, _glow_mat(cb.lightened(0.3), 1.5))
	db.scale = Vector3(1.0, 1.0, 0.22)
	bd.add_child(db)
	# the bisector — the border that emerges, not one that was drawn
	bd.add_child(_box(Vector3(0.0, by, fz + 0.016), Vector3(0.013, 0.320, 0.014), _glow_mat(Color(0.98, 0.96, 0.88), 1.6)))
	# the tie, marked: two equal spans meeting on the line
	for sx in [-0.08, 0.08]:
		var px: float = float(sx)
		bd.add_child(_box(Vector3(px, by - 0.128, fz + 0.012), Vector3(0.155, 0.011, 0.010), _matte_mat(Color(0.80, 0.82, 0.88), 0.6)))


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


## TRIAL — the scatter as a series. Five coupons stand leaning back on the shelf, each a
## 3x3 miniature of an EARLIER scatter, and a tick under each marks its place in the
## order. The partition behind them stops being the map and becomes the fifth map.
func _workings_trial() -> void:
	var sz: float = _workings_shelf()
	var plate_mat: StandardMaterial3D = _matte_mat(Color(0.16, 0.17, 0.21), 0.85)
	var tick: StandardMaterial3D = _glow_mat(Color(1.0, 0.85, 0.55), 1.3)
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
			# each surviving cell wears a territory hue, so a coupon reads as a partition
			var hue: float = float((b * 5 + i * 3) % 12) / 12.0
			var mark: StandardMaterial3D = _matte_mat(Color.from_hsv(hue, 0.65, 0.85), 0.7)
			var m: MeshInstance3D = _box(
				Vector3(cx + ox, cy + oy * 0.95 + 0.006, sz + 0.008 + oy * 0.31),
				Vector3(0.034, 0.034, 0.008), mark)
			m.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
			add_child(m)
		add_child(_box(Vector3(cx, W_TOP + 0.010, sz + 0.105), Vector3(0.020, 0.020, 0.014), tick))


## REJECT — the claims that lost. A scrap tray hangs off the right flank heaped with the
## losing bids: every one of the 1600 cells on the plate was claimed by ONE site and
## refused by eleven, and those eleven refusals are otherwise invisible here. The tray
## sits BELOW the plate, so the diagram is not touched — only the claim about it.
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
		# a losing claim keeps its hue and loses its light
		var hue: float = float(i) / float(W_HEAP.size())
		var junk: StandardMaterial3D = _matte_mat(Color.from_hsv(hue, 0.5, 0.42), 0.92)
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
