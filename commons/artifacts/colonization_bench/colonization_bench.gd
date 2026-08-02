extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ColonizationBench

## @identity
## name: "Space colonization"
## tier: medium
## lineage: Runions et al. — the venation/branching algorithm where leaves (attractors) summon the vein
##   toward them. Growth is pulled, not pushed; the form is the negative of where the food was.
## essence: ~120 attractor points scatter in a volume above the bench. A single root grows upward: each
##   attractor tugs its nearest node, every tugged node sprouts one new node a step along the averaged
##   pull, and any attractor the tree reaches is consumed. ~150 nodes of branch fall out — a little tree
##   that drew itself toward what fed it. Built once (deterministic seed); rendered as tapering tubes.
## truth: branches grow toward what they feed on — the shape is the memory of a hunger answered.

@export var bench_seed: int = 7
@export var attractor_count: int = 120
@export var node_cap: int = 150
@export var influence_radius: float = 0.34
@export var kill_radius: float = 0.075
@export var step: float = 0.045
@export var cloud_size: Vector3 = Vector3(0.7, 0.62, 0.6)
@export var branch_col: Color = Color(0.55, 0.40, 0.26)
@export var tip_col: Color = Color(0.42, 0.72, 0.34)
@export var attractor_col: Color = Color(0.4, 0.78, 0.95)
@export var label_col: Color = Color(0.78, 0.95, 0.86)

## AXIS — WHAT THIS BENCH SHOWS OF THE WORK THAT PRODUCED THE TREE. Shared word for word
## with the other six procedural benches (mc_field, sdf_sculpt, wfc_tile, wfc_room,
## voronoi, slime): one kit, one vocabulary, so a room of generators can be set to argue
## the same thing about all of them at once.
##
##   result  the finished tree alone on a bare bench — the legacy lineage, byte for byte
##   rule    the two radii posted upright at the back: influence, which decides who pulls,
##           and kill, which decides who is consumed. The whole of Runions, drawn.
##   trial   five earlier growths racked along the front lip: this tree is a draw
##   reject  a scrap tray of the food it never reached — attractors outside every
##           influence radius, which is to say the shape of what this tree could not want
##
## The claim is whether a generated thing is a RESULT or a PROOF. This bench is already
## the most honest of the seven — it is the only one that keeps any evidence at all, up to
## thirty surviving attractors at 6 mm, so faint they read as dust. `reject` is that
## footnote promoted to a tray.
@export_enum("result", "rule", "trial", "reject") var workings: String = "result"
const WORKINGS: PackedStringArray = ["result", "rule", "trial", "reject"]

## RUN PIN. -1 = the live bench exactly as it has always been: the sway clock free. Any
## value >= 0 stops the clock (and seeds the shared RNG), so the bench holds one pose.
##
## Note this bench does NOT need pinning for its GROWTH — bench_seed already makes the
## tree deterministic, and it is the only one of the seven that got that right from the
## start. What it needs pinning for is the sway: _root swings on the wall clock, so two
## stills are two angles. bench_seed stays what it is and keeps meaning "which tree";
## run_pin is only about holding still, which is why it could not be folded into it —
## bench_seed defaults to 7, and gating the freeze on it would have frozen every live
## placement.
@export var run_pin: int = -1

const BASE_Y: float = 0.85

var _root: Node3D = null
var _t: float = 0.0


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
	if config.has("bench_seed"):
		bench_seed = int(config["bench_seed"])
	if config.has("attractor_count"):
		attractor_count = clampi(int(config["attractor_count"]), 20, 400)
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
	_root = null
	_build()


func _build() -> void:
	# bench
	add_child(_box(Vector3(0.0, BASE_Y - 0.09, 0.0), Vector3(1.2, 0.18, 0.7), _matte_mat(Color(0.16, 0.17, 0.2), 0.85)))
	add_child(_cylinder(Vector3(0.0, (BASE_Y - 0.18) * 0.5, 0.0), 0.07, BASE_Y - 0.18, _steel_mat(Color(0.32, 0.34, 0.4))))
	add_child(_billboard_label("SPACE COLONIZATION\nbranches grow toward what they feed on", Vector3(0.0, BASE_Y + 0.95, 0.0), 17, label_col))

	# the tree grows in its own little holder above the bench top
	_root = Node3D.new()
	_root.position = Vector3(0.0, BASE_Y, 0.0)
	add_child(_root)

	# deterministic run
	var rng := RandomNumberGenerator.new()
	rng.seed = bench_seed

	# attractor cloud — a dome of food above the root
	var attractors: Array[Vector3] = []
	var alive: Array[bool] = []
	for _i in range(attractor_count):
		var p := Vector3(
			(rng.randf() - 0.5) * cloud_size.x,
			rng.randf() * cloud_size.y + 0.12,
			(rng.randf() - 0.5) * cloud_size.z
		)
		attractors.append(p)
		alive.append(true)

	# nodes — start with a single root at the bench top
	var nodes: Array[Vector3] = [Vector3(0.0, 0.02, 0.0)]
	var parents: Array[int] = [-1]
	var depths: Array[int] = [0]
	var edges: Array = []   # [from_index, to_index]

	var remaining: int = attractor_count
	var safety: int = 0
	while nodes.size() < node_cap and remaining > 0 and safety < node_cap * 4:
		safety += 1
		# accumulate pull per node from every attractor that owns it
		var pull := {}        # node_index -> Vector3 summed direction
		var pull_n := {}      # node_index -> count
		for ai in range(attractors.size()):
			if not alive[ai]:
				continue
			var a: Vector3 = attractors[ai]
			# nearest node within influence radius
			var best_i: int = -1
			var best_d: float = influence_radius
			for ni in range(nodes.size()):
				var d: float = a.distance_to(nodes[ni])
				if d < best_d:
					best_d = d
					best_i = ni
			if best_i >= 0:
				var dir: Vector3 = (a - nodes[best_i]).normalized()
				if pull.has(best_i):
					pull[best_i] += dir
					pull_n[best_i] += 1
				else:
					pull[best_i] = dir
					pull_n[best_i] = 1
		if pull.is_empty():
			break
		# grow a new node from each pulled node along the averaged direction
		for ni in pull.keys():
			if nodes.size() >= node_cap:
				break
			var avg: Vector3 = (pull[ni] as Vector3) / float(pull_n[ni])
			if avg.length() < 0.0001:
				continue
			var new_p: Vector3 = nodes[ni] + avg.normalized() * step
			var new_index: int = nodes.size()
			nodes.append(new_p)
			parents.append(ni)
			depths.append(depths[ni] + 1)
			edges.append([ni, new_index])
		# kill attractors the tree has reached
		for ai in range(attractors.size()):
			if not alive[ai]:
				continue
			for ni in range(nodes.size()):
				if attractors[ai].distance_to(nodes[ni]) < kill_radius:
					alive[ai] = false
					remaining -= 1
					break

	# render edges as tapering tubes — thicker at the root, greener at the tips
	var max_depth: int = 1
	for d in depths:
		max_depth = maxi(max_depth, d)
	var branch_mat := _matte_mat(branch_col, 0.85)
	for e in edges:
		var fi: int = e[0]
		var ti: int = e[1]
		var frac: float = float(depths[ti]) / float(max_depth)
		var radius: float = lerpf(0.012, 0.003, frac)
		var col: Color = branch_col.lerp(tip_col, clampf(frac, 0.0, 1.0))
		var mat: StandardMaterial3D = branch_mat if frac < 0.55 else _glow_mat(col, 0.5)
		_root.add_child(_cylinder_between(nodes[fi], nodes[ti], radius, mat))

	# a few faint surviving attractors, to show the food it never reached
	var glow := _glow_mat(attractor_col, 0.6)
	var shown: int = 0
	for ai in range(attractors.size()):
		if alive[ai] and shown < 30:
			_root.add_child(_sphere(attractors[ai], 0.006, glow))
			shown += 1

	# WORKINGS fittings, appended LAST so every child index and position above is
	# untouched on the legacy path. "result" falls through and adds nothing at all.
	# They are bolted to the BENCH, not to _root, so the tree keeps breathing over a
	# frame of apparatus that does not.
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
	if Engine.is_editor_hint() or _root == null:
		return
	# A pinned bench holds still — the sway turns the whole tree on the wall clock, so
	# without this two stills of one tree are two different silhouettes.
	if run_pin >= 0:
		return
	# gentle sway — the finished tree breathes
	_t += delta
	_root.rotation.y = sin(_t * 0.4) * 0.08


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
const W_HX: float = 0.60        # bench half-width (X)
const W_HZ: float = 0.35        # bench half-depth (Z)
const W_ANCHOR_Z: float = 0.32
const W_BOARD_Z: float = -0.34  # behind the attractor cloud, which reaches z -0.30
## How far right of centre the rule board stands — see _workings_board().
const W_BOARD_X: float = 0.16
const W_BOARD_W: float = 0.60
const W_BOARD_H: float = 0.36
## Five earlier growths kept as coupons — fixed 9-bit patterns, not draws. A rack that
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


## A dot lying in the board plane — a sphere flattened in Z.
func _workings_dot(x: float, y: float, z: float, r: float, mat: Material) -> MeshInstance3D:
	var d: MeshInstance3D = _sphere(Vector3(x, y, z), r, mat)
	d.scale = Vector3(1.0, 1.0, 0.22)
	return d


## RULE — the two radii posted. LEFT: a node with its influence ring (every attractor
## inside it pulls) and its kill ring (every attractor inside THAT is consumed and stops
## pulling). RIGHT: the consequence — one new node, one `step` along the averaged pull,
## and the attractor it reached struck out. That is the entire algorithm; the tree on the
## bench is this picture applied about a hundred and fifty times.
func _workings_rule() -> void:
	var bd: Node3D = _workings_board()
	var by: float = W_TOP + 0.08 + W_BOARD_H * 0.5
	var fz: float = W_BOARD_Z + 0.014
	var faint: StandardMaterial3D = _matte_mat(attractor_col.darkened(0.35), 0.7)
	var keen: StandardMaterial3D = _glow_mat(tip_col, 1.4)
	var food: StandardMaterial3D = _glow_mat(attractor_col, 1.3)
	var gone: StandardMaterial3D = _matte_mat(Color(0.26, 0.27, 0.31), 0.95)
	var wood: StandardMaterial3D = _matte_mat(branch_col.lightened(0.10), 0.7)
	var nx: float = -0.155
	var ny: float = by + 0.005
	# influence: who is allowed to pull on this node at all
	bd.add_child(_workings_ring(nx, ny, fz + 0.006, 0.122, 0.0045, faint))
	# kill: who has been reached, and therefore stops pulling on anything
	bd.add_child(_workings_ring(nx, ny, fz + 0.010, 0.040, 0.0055, keen))
	# the food in range
	bd.add_child(_workings_dot(nx + 0.075, ny + 0.072, fz + 0.014, 0.016, food))
	bd.add_child(_workings_dot(nx + 0.095, ny - 0.038, fz + 0.014, 0.016, food))
	bd.add_child(_workings_dot(nx - 0.048, ny + 0.088, fz + 0.014, 0.016, food))
	# the food already consumed, inside the kill radius — retired, no longer pulling
	bd.add_child(_workings_dot(nx + 0.022, ny + 0.014, fz + 0.016, 0.014, gone))
	# the node itself
	bd.add_child(_workings_dot(nx, ny, fz + 0.018, 0.019, wood))
	# the averaged pull, and the step taken along it
	bd.add_child(_cylinder_between(Vector3(nx, ny, fz + 0.012),
		Vector3(nx + 0.088, ny + 0.040, fz + 0.012), 0.006, keen))
	# the divider — premise on the left, consequence on the right
	bd.add_child(_box(Vector3(0.015, by, fz), Vector3(0.010, 0.290, 0.012), _matte_mat(Color(0.46, 0.48, 0.54), 0.7)))
	# ...therefore a new node, one step further on, and the reached food struck out
	var ox: float = 0.150
	bd.add_child(_cylinder_between(Vector3(ox, by - 0.075, fz + 0.012),
		Vector3(ox + 0.055, by + 0.010, fz + 0.012), 0.008, wood))
	bd.add_child(_cylinder_between(Vector3(ox + 0.055, by + 0.010, fz + 0.012),
		Vector3(ox + 0.098, by + 0.088, fz + 0.012), 0.005, keen))
	bd.add_child(_workings_dot(ox + 0.098, by + 0.088, fz + 0.016, 0.015, keen))
	bd.add_child(_workings_dot(ox + 0.030, by + 0.115, fz + 0.014, 0.015, gone))
	var struck: MeshInstance3D = _box(Vector3(ox + 0.030, by + 0.115, fz + 0.020),
		Vector3(0.046, 0.010, 0.008), _glow_mat(Color(0.90, 0.32, 0.22), 1.2))
	struck.rotation_degrees = Vector3(0.0, 0.0, 34.0)
	bd.add_child(struck)


## The shelf and rack that carry the earlier runs, cantilevered off the front lip on two
## struts. Shared shape across the seven; the coupons carry this bench's own palette.
func _workings_shelf() -> float:
	var steel: StandardMaterial3D = _steel_mat(Color(0.34, 0.36, 0.42))
	var sz: float = W_HZ + 0.13
	add_child(_box(Vector3(0.0, W_TOP - 0.012, sz), Vector3(0.88, 0.026, 0.26), _matte_mat(Color(0.20, 0.21, 0.25), 0.8)))
	for sx in [-0.34, 0.34]:
		var px: float = float(sx)
		add_child(_cylinder_between(Vector3(px, W_TOP - 0.28, W_ANCHOR_Z), Vector3(px, W_TOP - 0.03, sz + 0.10), 0.013, steel))
	return sz


## TRIAL — the growth as a series. Five coupons stand leaning back on the shelf, each a
## 3x3 miniature of an EARLIER growth from a different seed, and a tick under each marks
## its place in the order. bench_seed is a knob on this artifact and always was; the rack
## is that knob admitted in the silhouette instead of hidden in the inspector.
func _workings_trial() -> void:
	var sz: float = _workings_shelf()
	var plate: StandardMaterial3D = _matte_mat(Color(0.16, 0.17, 0.21), 0.85)
	var tick: StandardMaterial3D = _glow_mat(tip_col, 1.3)
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
			# root brown at the bottom of a coupon, tip green at the top, as on the tree
			var frac: float = 1.0 - float(gy) * 0.5
			var mark: StandardMaterial3D = _matte_mat(branch_col.lerp(tip_col, frac), 0.7)
			var m: MeshInstance3D = _box(
				Vector3(cx + ox, cy + oy * 0.95 + 0.006, sz + 0.008 + oy * 0.31),
				Vector3(0.034, 0.034, 0.008), mark)
			m.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
			add_child(m)
		add_child(_box(Vector3(cx, W_TOP + 0.010, sz + 0.105), Vector3(0.020, 0.020, 0.014), tick))


## REJECT — the food it never reached. A scrap tray hangs off the right flank heaped with
## attractors that fell outside every influence radius the tree ever grew: they pulled on
## nothing, were consumed by nothing, and are the shape of what this tree could not want.
## The bench already draws up to thirty of these at 6 mm, so faint they read as dust; this
## takes the same fact and gives it a container. The tray sits BELOW the working surface,
## so the tree is not touched — only the claim about it.
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
	# uneaten food, at the size it would have been eaten at — spheres, not scrap cubes,
	# because these are not offcuts: they are whole attractors that nothing ever came for
	var cold: StandardMaterial3D = _matte_mat(attractor_col.darkened(0.42), 0.9)
	for i in range(W_HEAP.size()):
		var o: Vector2 = W_HEAP[i]
		var r: float = 0.017 + float(i % 4) * 0.004
		add_child(_sphere(Vector3(tx + o.x, ty + 0.030 + float(i % 3) * 0.010, o.y), r, cold))
	# The tag stands UP, which on this camera (pitch -0.26, so 15 degrees above the
	# horizon) is the only cheap silhouette a tray has: every horizontal surface here
	# is foreshortened to a quarter of its area, and a vertical plate is not.
	add_child(_box(Vector3(tx, ty + 0.125, -0.20), Vector3(0.25, 0.18, 0.012), _matte_mat(Color(0.14, 0.14, 0.17), 0.9)))
	var strike: MeshInstance3D = _box(Vector3(tx, ty + 0.125, -0.19), Vector3(0.26, 0.030, 0.010), _glow_mat(Color(0.90, 0.32, 0.22), 1.3))
	strike.rotation_degrees = Vector3(0.0, 0.0, 26.0)
	add_child(strike)
