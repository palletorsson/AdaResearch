## aftermath_grove — what remains of a growth, asked of four growths at once.
##
## THE FAMILY. Four artifacts run a growth and share one vocabulary for what survives it:
## form, field, envelope, apparatus, strata. Two members declare all five; two declare four
## and refuse `field`. That refusal is not noise — see THE FINDING below.
##
## LAW 16, ANSWERED FROM THE MEMBERS' CODE: THE VALUES NEST, so `aftermath` is the AXIS and
## the members are the exhibit. The dispatch says so, not the prose:
##   - recursive_tree.gd:570-584 — "envelope" draws `_growth_rings(boxes, deepest)`;
##     "apparatus" re-evaluates that exact expression and appends marks. STRICT SUPERSET.
##   - inverted_tree_cloud.gd:545-548 — the comment reads "envelope and apparatus both draw
##     the cage", then `_draw_envelope()` runs unconditionally and marks are added only at
##     apparatus.
##   - branching_growth_algorithm.gd:587-589 — three booleans, not a match:
##     marks := (_aft == "field" or _aft == "apparatus")
##     cage  := (_aft == "envelope" or _aft == "apparatus")
##     origin_mark := (_aft == "apparatus")
##     so `field` and `envelope` are siblings over `form`, and `apparatus` is their union.
##
## ── THE FINDING, AND IT IS WHY THE LAYOUT IS A 2x2 ──────────────────────────
##
## `envelope` DOES NOT MEAN ONE THING IN THIS FAMILY. It splits two and two, and the split is
## decided by WHETHER THE GROWTH HAD A TARGET.
##
##   PRIOR (top row) — branching_growth_algorithm and space_colonization_algorithm grow
##   TOWARD a scattered demand, and their envelope is the region that demand was SAMPLED
##   FROM. branching_growth draws a cage at FIELD_RADIUS := 3.0 (gd:72) — the same literal as
##   the attractor sampling radius at gd:203/209 — and its own comment says a cage at any
##   other radius would be a decoration rather than a boundary. space_colonization draws a
##   BoxMesh at cube_size = Vector3(4,4,4), the same box its attractors are sampled on.
##   For these two the envelope is PERMISSION: decided before anything grew, identical at
##   every seed forever, and NOT a bound on the result.
##
##   POSTERIOR (bottom row) — recursive_tree and inverted_tree_cloud have no demand to grow
##   toward. Their envelope is fitted to the branches AFTER the fact, so it moves when the
##   seed moves.
##
## THE PARTITION IS EXACT ON A SECOND SYMPTOM, which is what earns it the layout: the two
## prior-envelope members are precisely the two that declare `field` (bga:55, SpaceCol:65),
## and the two posterior-envelope members are precisely the two that refuse it (rt:60,
## itc:88). One cause, two visible consequences. A grower that aims at a scattered demand has
## a field to draw and a permission to draw; a grower that just branches has neither.
##
##   (In the `residue` family the same word means the opposite: an A-POSTERIORI HULL, fitted
##   backwards off a walk's own record. pipe_dream seeds an AABB at _points[0] with zero size
##   and grows it over every turn. Permission against hull — same five letters, opposite
##   direction in time.)
##
## THE SECOND AXIS IS THE INSTRUMENT THAT PROVES IT. `trial` is which run of the same seeded
## process you are looking at — fixture 20260802 (the seed both procgen members pin in
## dna.fixture), shipped 12345 (recursive_tree.tscn:20), default 42 (both tree scripts'
## export default), control 1. Every member of this family is stochastic and every one
## declares a seed export, so the family raises a question no single member can answer: is
## this residue a fact about the PROCESS or about THIS RUN? Re-running separates them, and it
## separates them along exactly the fault line above — A CONSTANT ENVELOPE CANNOT MOVE AND A
## MEASURED ONE MUST. Sweep `trial` and the top row's cages stand still while the bottom row's
## hulls breathe.
##
## LAW 1: NO BAR, NO SLAT, NO RACK, NO PAD. Each bay is its member's growth in its member's
## arithmetic. Furniture is one datum rim per bay — no plinth, because two of the four put
## half their aftermath BELOW their own datum and a slab would hide it.
extends Node3D
class_name AftermathGrove

@export_enum("form", "field", "envelope", "apparatus", "strata") var aftermath: String = "form"
const AFTERMATHS: PackedStringArray = ["form", "field", "envelope", "apparatus", "strata"]

## Declared SECOND: build_dna_gallery trims from the end of the later axis, and `control` is
## the only invented value, so it is placed last and is taken first.
@export_enum("fixture", "shipped", "default", "control") var trial: String = "fixture"
const TRIALS: PackedStringArray = ["fixture", "shipped", "default", "control"]

## The four seeds, each read off a member rather than invented — except `control`.
const TRIAL_SEED: Dictionary = {"fixture": 20260802, "shipped": 12345, "default": 42, "control": 1}

# ── the 2x2, and the row is the finding ──────────────────────────────────────
# TOP ROW  (+z back)  = PRIOR envelopes:     A branching_growth, D space_colonization
# BOTTOM ROW          = POSTERIOR envelopes: B recursive_tree,   C inverted_tree_cloud
const BAY_X: Array = [-1.20, 1.20, -1.20, 1.20]
const BAY_Z: Array = [-1.20, -1.20, 1.20, 1.20]
const BAY_PRIOR: Array = [true, true, false, false]     ## is this bay's envelope permission?
const BAY_FIELD: Array = [true, true, false, false]     ## does this member declare `field`?
const BAY_NAME: PackedStringArray = ["branching_growth_algorithm", "space_colonization_algorithm",
		"recursive_tree", "inverted_tree_cloud"]

const RIM: float = 1.10          ## half the datum rim, so each bay owns 2.20 x 2.20 m
const CAGE_R: float = 0.62       ## bay A's permission — FIELD_RADIUS 3.0 scaled by 0.2063
const CAGE_BOX: float = 0.55     ## bay D's permission — cube_size 4.0 scaled, half-extent
const ATTRACTORS: int = 120
const MARK_R: float = 0.022

const HAIR: float = 0.006
const TREE_DEPTH: int = 6

# Palettes from the members. Bay A freezes pale near-white with a faint rainbow tint, which
# is what its own sparkle lerp produces at the freeze frame — not saturated colours.
const BUSH_PALE := Color(0.93, 0.92, 0.96)
const BUSH_TINT := Color(0.62, 0.78, 0.95)
const COL_TINT := Color(0.98, 0.72, 0.42)
const TREE_TINT := Color(0.58, 0.92, 0.62)
const INV_TINT := Color(0.80, 0.62, 0.98)
const CAGE_TINT := Color(0.35, 0.72, 1.0)       ## PRIOR: cold, constant
const HULL_TINT := Color(1.0, 0.60, 0.22)       ## POSTERIOR: warm, and it moves
const MARK_KEPT := Color(0.25, 0.95, 0.55)
const MARK_LEFT := Color(1.0, 0.32, 0.52)
const RIM_TINT := Color(0.42, 0.45, 0.55)

var _rng := RandomNumberGenerator.new()
var _owned: Array[Node] = []


func _ready() -> void:
	_check_hints()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("aftermath"):
		var a: String = str(config_data["aftermath"]).strip_edges().to_lower()
		if AFTERMATHS.has(a):
			aftermath = a
	if config_data.has("trial"):
		var t: String = str(config_data["trial"]).strip_edges().to_lower()
		if TRIALS.has(t):
			trial = t
	_rebuild()


func _check_hints() -> void:
	for pair in [["aftermath", AFTERMATHS], ["trial", TRIALS]]:
		var key: String = pair[0]
		var want: PackedStringArray = pair[1]
		for p in get_property_list():
			if String(p.get("name", "")) != key:
				continue
			var got := PackedStringArray()
			for part in String(p.get("hint_string", "")).split(",", false):
				got.append(part.split(":")[0].strip_edges())
			if got != want:
				push_error("aftermath_grove: '%s' hint %s != const %s" % [key, got, want])
			break


func _rebuild() -> void:
	for n in _owned:
		if is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	_owned.clear()
	_build()


func _own(n: Node3D) -> void:
	add_child(n)
	_owned.append(n)


func _seed() -> int:
	return int(TRIAL_SEED.get(trial, 20260802))


## The three booleans branching_growth_algorithm uses, lifted verbatim. `field` and
## `envelope` are SIBLINGS over `form`; `apparatus` is their union; `strata` re-colours.
func _wants_marks() -> bool:
	return aftermath == "field" or aftermath == "apparatus"


func _wants_cage() -> bool:
	return aftermath == "envelope" or aftermath == "apparatus"


func _wants_origin() -> bool:
	return aftermath == "apparatus"


func _wants_strata() -> bool:
	return aftermath == "strata"


func _build() -> void:
	for i in 4:
		var bay := Node3D.new()
		bay.name = "bay_%d" % i
		bay.position = Vector3(BAY_X[i], 0.0, BAY_Z[i])
		_own(bay)
		_rim(bay)
		if i == 0:
			_build_bush(bay, BUSH_PALE, BUSH_TINT)
		elif i == 1:
			_build_colonizer(bay)
		elif i == 2:
			_build_tree(bay, TREE_TINT, 1.0)
		else:
			_build_tree(bay, INV_TINT, -1.0)


## The datum each member calls y = 0. Four bars, no slab: two of the four put half their
## aftermath below this plane and a plinth would hide it.
func _rim(bay: Node3D) -> void:
	var pts := [Vector3(-RIM, 0, -RIM), Vector3(RIM, 0, -RIM), Vector3(RIM, 0, RIM),
			Vector3(-RIM, 0, RIM)]
	for i in 4:
		_line(bay, pts[i], pts[(i + 1) % 4], 0.015, RIM_TINT, 0.25)


# ═══════════════════════════════════════════════════════════════════════════
# BAY A — branching_growth_algorithm. A dense OFF-CENTRE radial bush that does
# not grow upward: `Branch.direction` is never read, so the seed's Vector3.UP
# has no effect. The parent stays active, so the population doubles and the run
# ends on the branch cap rather than on exhausting attractors — which is why
# only a handful of the demand is ever consumed.
# ═══════════════════════════════════════════════════════════════════════════
func _build_bush(bay: Node3D, pale: Color, tint: Color) -> void:
	_rng.seed = _seed()
	var targets := PackedVector3Array()
	for i in ATTRACTORS:
		var th: float = _rng.randf() * TAU
		var ph: float = acos(1.0 - 2.0 * _rng.randf())
		var rr: float = CAGE_R * pow(_rng.randf(), 0.33)
		var p := Vector3(sin(ph) * cos(th), cos(ph), sin(ph) * sin(th)) * rr
		if p.length() > 0.10:
			targets.append(p)

	var tips := PackedVector3Array([Vector3.ZERO])
	var gens := PackedInt32Array([0])
	var segs := []
	var consumed := {}
	for step in 9:
		var next := PackedVector3Array()
		var next_g := PackedInt32Array()
		for ti in tips.size():
			var from: Vector3 = tips[ti]
			var best: int = -1
			var bd: float = 1e9
			for k in targets.size():
				if consumed.has(k):
					continue
				var dd: float = from.distance_to(targets[k])
				if dd < bd:
					bd = dd
					best = k
			if best < 0:
				continue
			var dir: Vector3 = (targets[best] - from).normalized()
			dir += Vector3(_rng.randf_range(-0.15, 0.15), _rng.randf_range(-0.15, 0.15),
					_rng.randf_range(-0.15, 0.15))
			var to: Vector3 = from + dir.normalized() * 0.072
			segs.append([from, to, gens[ti]])
			if bd < 0.075:
				consumed[best] = true
			# THE PARENT STAYS ACTIVE — the population doubles rather than advancing.
			next.append(from)
			next_g.append(gens[ti])
			next.append(to)
			next_g.append(gens[ti] + 1)
			if next.size() > 220:
				break
		if next.is_empty():
			break
		tips = next
		gens = next_g

	_draw_segments(bay, segs, pale, tint, HAIR)
	if _wants_marks() and BAY_FIELD[0]:
		_draw_marks(bay, targets, consumed)
	if _wants_cage():
		# PERMISSION: a sphere at the sampling radius. Constant at every trial.
		_sphere_cage(bay, CAGE_R)
	if _wants_origin():
		_ball(bay, Vector3.ZERO, 0.028, MARK_KEPT, 2.2)


# ═══════════════════════════════════════════════════════════════════════════
# BAY D — space_colonization_algorithm. Same demand-driven law, but its
# permission is a BOX, because its attractors are sampled on a cube.
# ═══════════════════════════════════════════════════════════════════════════
func _build_colonizer(bay: Node3D) -> void:
	_rng.seed = _seed() + 17
	var targets := PackedVector3Array()
	for i in ATTRACTORS:
		targets.append(Vector3(_rng.randf_range(-CAGE_BOX, CAGE_BOX),
				_rng.randf_range(-CAGE_BOX * 0.5, CAGE_BOX),
				_rng.randf_range(-CAGE_BOX, CAGE_BOX)))
	var tips := PackedVector3Array([Vector3(0, -0.45, 0)])
	var gens := PackedInt32Array([0])
	var segs := []
	var consumed := {}
	for step in 11:
		var next := PackedVector3Array()
		var next_g := PackedInt32Array()
		for ti in tips.size():
			var from: Vector3 = tips[ti]
			var pull := Vector3.ZERO
			var n: int = 0
			for k in targets.size():
				if consumed.has(k):
					continue
				var dd: float = from.distance_to(targets[k])
				if dd < 0.42:
					pull += (targets[k] - from).normalized()
					n += 1
					if dd < 0.09:
						consumed[k] = true
			if n == 0:
				continue
			var dir: Vector3 = (pull / float(n)).normalized()
			var to: Vector3 = from + dir * 0.075
			segs.append([from, to, gens[ti]])
			next.append(to)
			next_g.append(gens[ti] + 1)
			if next.size() > 200:
				break
		if next.is_empty():
			break
		tips = next
		gens = next_g

	_draw_segments(bay, segs, COL_TINT.lightened(0.35), COL_TINT, HAIR)
	if _wants_marks() and BAY_FIELD[1]:
		_draw_marks(bay, targets, consumed)
	if _wants_cage():
		# PERMISSION: the sampling box. Constant at every trial.
		_box_cage(bay, Vector3(-CAGE_BOX, -CAGE_BOX * 0.5, -CAGE_BOX),
				Vector3(CAGE_BOX, CAGE_BOX, CAGE_BOX))
	if _wants_origin():
		_ball(bay, Vector3(0, -0.45, 0), 0.028, MARK_KEPT, 2.2)


# ═══════════════════════════════════════════════════════════════════════════
# BAYS B and C — recursive_tree and inverted_tree_cloud. No demand, so no field
# and no permission. Their envelope is FITTED to the branches after the fact,
# and it therefore MOVES when trial moves. `up` is +1 for the tree and -1 for
# the cloud, which is the whole difference between the two members.
# ═══════════════════════════════════════════════════════════════════════════
func _build_tree(bay: Node3D, tint: Color, up: float) -> void:
	_rng.seed = _seed() + (29 if up > 0.0 else 43)
	var segs := []
	_branch(segs, Vector3(0, -0.55 * up, 0), Vector3(0, up, 0), 0.42, 0, TREE_DEPTH)
	_draw_segments(bay, segs, tint.lightened(0.35), tint, HAIR)

	if _wants_cage():
		# MEASURED: an AABB fitted to what actually grew. Nothing decided this in advance,
		# and it is a different box at every trial — which is the experiment.
		var lo := Vector3(1e9, 1e9, 1e9)
		var hi := Vector3(-1e9, -1e9, -1e9)
		for s in segs:
			for p in [s[0], s[1]]:
				lo = Vector3(minf(lo.x, p.x), minf(lo.y, p.y), minf(lo.z, p.z))
				hi = Vector3(maxf(hi.x, p.x), maxf(hi.y, p.y), maxf(hi.z, p.z))
		_box_cage(bay, lo, hi, HULL_TINT)
	if _wants_origin():
		_ball(bay, Vector3(0, -0.55 * up, 0), 0.028, MARK_KEPT, 2.2)


func _branch(segs: Array, from: Vector3, dir: Vector3, len_m: float, gen: int, left: int) -> void:
	if left <= 0 or len_m < 0.02:
		return
	var to: Vector3 = from + dir.normalized() * len_m
	segs.append([from, to, gen])
	var n: int = 2 if _rng.randf() < 0.78 else 3
	for i in n:
		var ax := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.25, 0.25),
				_rng.randf_range(-1, 1))
		if ax.length() < 0.001:
			ax = Vector3.RIGHT
		var nd: Vector3 = dir.normalized().rotated(ax.normalized(), _rng.randf_range(0.35, 0.75))
		_branch(segs, to, nd, len_m * _rng.randf_range(0.62, 0.76), gen + 1, left - 1)


# ── drawing ──────────────────────────────────────────────────────────────────

## One MultiMesh per bay body. `strata` re-colours by generation instead of by radius —
## the same geometry, read as layers rather than as a shape.
func _draw_segments(bay: Node3D, segs: Array, pale: Color, tint: Color, r: float) -> void:
	if segs.is_empty():
		return
	var maxg: int = 1
	for s in segs:
		maxg = maxi(maxg, int(s[2]))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = 1.0
	cyl.radial_segments = 5
	cyl.rings = 1
	mm.mesh = cyl
	mm.instance_count = segs.size()
	for i in segs.size():
		var a: Vector3 = segs[i][0]
		var b: Vector3 = segs[i][1]
		mm.set_instance_transform(i, _between(a, b))
		var c: Color
		if _wants_strata():
			var f: float = float(segs[i][2]) / float(maxg)
			c = tint.lerp(Color(1, 1, 1), f)
		else:
			# the source's own sparkle: brighter outward, faint tint
			var sp: float = clampf(b.length() * 1.4, 0.0, 1.0)
			c = pale.lerp(tint, 1.0 - sp)
		mm.set_instance_color(i, c)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = 0.7
	mat.roughness = 0.5
	mmi.material_override = mat
	bay.add_child(mmi)
	_anchor(bay, Vector3(RIM * 2.0, 1.5, RIM * 2.0), Vector3(0, 0.1, 0))


## The demand, and the honest ratio: a handful consumed, the rest standing.
func _draw_marks(bay: Node3D, targets: PackedVector3Array, consumed: Dictionary) -> void:
	for k in targets.size():
		var c: Color = MARK_KEPT if consumed.has(k) else MARK_LEFT
		var p: Vector3 = targets[k]
		for ax in [Vector3.RIGHT, Vector3.UP, Vector3.FORWARD]:
			_line(bay, p - ax * MARK_R, p + ax * MARK_R, 0.0025, c, 1.4)


## PERMISSION as a sphere: great circles and parallels, at the sampling radius.
func _sphere_cage(bay: Node3D, radius: float) -> void:
	var steps: int = 34
	for m in 8:
		var a0: float = TAU * float(m) / 8.0
		var pts := PackedVector3Array()
		for i in steps + 1:
			var t: float = PI * float(i) / float(steps)
			pts.append(Vector3(sin(t) * cos(a0), cos(t), sin(t) * sin(a0)) * radius)
		_polyline(bay, pts, 0.0035, CAGE_TINT, 1.3)
	for r_i in 5:
		var yy: float = -0.72 + 0.36 * float(r_i)
		var rr: float = radius * sqrt(maxf(1.0 - yy * yy, 0.0))
		var pts2 := PackedVector3Array()
		for i in steps + 1:
			var a: float = TAU * float(i) / float(steps)
			pts2.append(Vector3(cos(a) * rr, yy * radius, sin(a) * rr))
		_polyline(bay, pts2, 0.0035, CAGE_TINT, 1.3)


func _box_cage(bay: Node3D, lo: Vector3, hi: Vector3, tint: Color = CAGE_TINT) -> void:
	var v := []
	for ix in 2:
		for iy in 2:
			for iz in 2:
				v.append(Vector3(lo.x if ix == 0 else hi.x, lo.y if iy == 0 else hi.y,
						lo.z if iz == 0 else hi.z))
	var edges := [[0, 1], [0, 2], [0, 4], [1, 3], [1, 5], [2, 3], [2, 6],
			[3, 7], [4, 5], [4, 6], [5, 7], [6, 7]]
	for ed in edges:
		_line(bay, v[ed[0]], v[ed[1]], 0.0045, tint, 1.5)


func _mat(c: Color, e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.5
	if e > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = e
	return m


func _line(parent: Node3D, a: Vector3, b: Vector3, r: float, c: Color, e: float) -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = 1.0
	cyl.radial_segments = 5
	cyl.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.transform = _between(a, b)
	mi.material_override = _mat(c, e)
	parent.add_child(mi)


func _polyline(parent: Node3D, pts: PackedVector3Array, r: float, c: Color, e: float) -> void:
	if pts.size() < 2:
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = 1.0
	cyl.radial_segments = 5
	cyl.rings = 1
	mm.mesh = cyl
	mm.instance_count = pts.size() - 1
	for i in range(pts.size() - 1):
		mm.set_instance_transform(i, _between(pts[i], pts[i + 1]))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _mat(c, e)
	parent.add_child(mmi)


## Explicit basis rather than look_at: a growth segment parallel to UP is common here and
## look_at is undefined there.
func _between(a: Vector3, b: Vector3) -> Transform3D:
	var d := b - a
	var len_m: float = d.length()
	if len_m < 0.00001:
		return Transform3D(Basis().scaled(Vector3(1, 0.00001, 1)), a)
	var up := d / len_m
	var ref := Vector3.RIGHT if absf(up.dot(Vector3.UP)) > 0.9 else Vector3.UP
	var side := ref.cross(up).normalized()
	var fwd := up.cross(side).normalized()
	return Transform3D(Basis(side, up * len_m, fwd), (a + b) * 0.5)


func _ball(parent: Node3D, at: Vector3, r: float, c: Color, e: float) -> void:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 10
	s.rings = 6
	var mi := MeshInstance3D.new()
	mi.mesh = s
	mi.position = at
	mi.material_override = _mat(c, e)
	parent.add_child(mi)


func _anchor(parent: Node3D, size: Vector3, at: Vector3) -> void:
	var b := BoxMesh.new()
	b.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = b
	mi.position = at
	mi.layers = 0
	parent.add_child(mi)
