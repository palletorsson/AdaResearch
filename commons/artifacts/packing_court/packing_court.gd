extends Node3D
class_name PackingCourt

# @identity
# essence: one word, two mechanisms — a similitude ratio on the left bench, a leaf dilation
#          on the right, both called `packing`, both moving from fused to dust
# desire: To be caught disagreeing — to make a reader see that the left bench's atoms move
#         and the right bench's atoms only shrink, and that no caption said so
# critical_parameter: packing — but the point is that it means two different things at once
# triggers: reading=gap at fused and at contact draws NOTHING on either bench, because both
#           mechanisms close their gap at exactly the same rung
# emerges: the two benches agree at `contact` and nowhere else
# relationships: synthesis of example_8_3_recursion_circles_vr and sierpinski_pyramid, the
#                corpus's only two-member `packing` family
# truth: A shared word is a hypothesis. These two artifacts hold it at different depths of
#        the same construction, and only one rung of the four is the same claim twice.

# ── DNA (synthesis) ──────────────────────────────────────────────────────────────────
# THE FAMILY IS TWO MEMBERS AND THE HYPOTHESIS IS THAT THEY ARE ABOUT THE SAME THING.
# Both declare packing = fused | contact | open | dust, character for character. Read from
# the code rather than from either registry, they are NOT the same question, and the
# difference is WHERE IN THE CONSTRUCTION THE VALUE IS CONSUMED:
#
#   example_8_3_recursion_circles_vr  PACKING_R at gd:70 becomes `radius_reduction`, which
#     _draw_circles reads INSIDE the recursion at gd:195 (`var new_radius := radius *
#     radius_reduction`) and again at gd:196 for the offset. So the value sets the
#     SIMILITUDE RATIO. Every value is a different attractor: with a 4-fold branch at ratio
#     r the similarity dimension is log(4)/log(1/r) = 2.714 | 2.000 | 1.321 | 1.000 for the
#     four rungs. `contact` is not a taste — 2*offset = 2*r solves to r = 0.5 exactly, the
#     one ratio at which two in-plane siblings are tangent, and it is also the ratio at
#     which the drawn measure is conserved (4r^2 = 1) and the dimension is exactly 2.
#
#   sierpinski_pyramid  PACKING_FILL at gd:52 is read in ONE place, _spawn_cube gd:206-207,
#     after the recursion has finished placing every leaf. The lattice, the census and the
#     recursion are untouched by it. The fractal is the same set in all four values; only
#     the ink on it changes. Its dimension does not move.
#
# SO THE WORD NAMES A GENERATIVE PARAMETER IN ONE MEMBER AND A RENDERING PARAMETER IN THE
# OTHER, and this court is built to photograph exactly that. Both benches stand in every
# frame; `packing` drives both at once, each with its own member's numbers, verbatim.
#
# WHAT THIS COURT REPAIRS, AND WHY IT IS A REPAIR AND NOT A REDESIGN. Three things in the
# sources are false to their own stated intent, all three checkable from the lines named:
#
#  1. sierpinski_pyramid makes SIX children per level, not five. _recursive_build calls
#     itself at gd:109 (top at +half_size) and AGAIN at gd:174 (top at +offset), plus four
#     bottoms at gd:177-180. Its @identity says `pyramid(depth) = 5 * pyramid(depth-1)` and
#     its registry says 625 cubes at the shipped depth. The code makes 6^4 = 1296 calls at
#     1236 distinct positions, and 6^5 = 7776 at `limit`, not 3125. The measurement already
#     in the registry proves it and nobody read it: aabb_size is [8.5, 12.25, 8.5]. A
#     five-child pyramid on that lattice is 8.5 cubed. The extra top is the 12.25.
#
#  2. Its `contact` is not contact. The header at gd:28-30 says `the recursion places leaves
#     on a lattice whose spacing is exactly size, and _spawn_cube then draws a cube of
#     exactly size — so the atoms touch`. The initial extent at gd:96 is
#     size * pow(2, depth - 1), which puts the finest offset at size/4 and the leaf pitch at
#     size/4, so a cube of edge `size` overlaps its nearest neighbour four to one. The file's
#     own comment at gd:198 names the fix — `Initial call size: size * pow(2, depth)` — in a
#     block of thinking-aloud that was never applied. This court uses LEAF * 2^depth, and the
#     measured minimum Chebyshev separation between leaves is then exactly LEAF, so `contact`
#     here is exact face tangency, which is what the word was supposed to mean.
#
#  3. example_8_3 never rotates its tori. _create_circle at gd:203-214 sets a position and no
#     rotation, and Godot's TorusMesh is generated around its local +Y, lying in XZ; the
#     offsets at gd:198-201 are in XY. So a planar circle-packing figure is drawn with every
#     ring standing perpendicular to the plane the packing happens in, and the tangency its
#     registry celebrates is arithmetic that the picture cannot show. Here the rings are
#     rotated into the plane of their own offsets.
#
# NO RANDOMNESS ANYWHERE: no RandomNumberGenerator, no randf, no randi, no FastNoiseLite. No
# _process, no Timer, no tween, no animation — every vertex is arithmetic on the constants
# below, so a variant is a fact and not a sample and no fixture is needed to freeze it.

## AXIS — PACKING. How much of the space it is given each atom claims.
##
## Taken word for word and value for value from BOTH members, and driving both benches at
## once from each member's own table. The two tables are transcribed from the sources and
## are the only numbers in this file that were not derived here.
##
##   fused    r 0.60 / fill 1.35 — past the closing point in both mechanisms. On the ratio
##            bench the in-plane siblings overlap by 0.2 of the parent radius; on the fill
##            bench each leaf overflows its cell by 0.175 of an edge and the finest holes
##            close into carved rock. This is example_8_3's shipped value.
##   contact  r 0.50 / fill 1.00 — THE ONE RUNG WHERE THE TWO MECHANISMS AGREE, and they
##            agree exactly: 2*offset = 2*r gives siblings tangent at r = 0.5, and fill = 1.0
##            gives leaves tangent face to face on a lattice of pitch LEAF. Both clear gaps
##            are 0.000 m. This is sierpinski_pyramid's shipped value.
##   open     r 0.35 / fill 0.60 — daylight between the atoms in both. The ratio bench stops
##            being a texture and reads as a branching tree; the fill bench's mountain opens.
##   dust     r 0.25 / fill 0.28 — atoms small and far. On the ratio bench this is the
##            length-conserving rung (4r = 1: every generation contributes exactly the same
##            total centreline, 0.44 m of it) and the dimension is exactly 1. On the fill
##            bench it removes 97.8 percent of the drawn volume (0.28^3 = 0.0220) and the
##            dimension does not move at all. THAT ASYMMETRY IS THE WHOLE EXHIBIT.
@export_enum("fused", "contact", "open", "dust") var packing: String = "contact":
	set(value):
		if value == packing:
			return
		packing = value
		if _built and not _applying:
			_rebuild()

## AXIS — READING. Which part of the packing is made of matter.
##
## Not a style. Each value draws a DIFFERENT SET, and the three sets are disjoint: the atoms,
## the clear space between the atoms, and the incidences. None of them is the union of the
## others — `gap` is a solid where `kept` is empty and empty where `kept` is solid, and `web`
## is size-blind by construction, marking only positions and touchings with a fixed gauge.
##
##   kept  the survivors. Rings on the ratio bench, cubes on the fill bench. This is what
##         both sources draw and the only reading either of them has.
##   gap   THE CLEAR SPACE, DRAWN AS SOLID. On the ratio bench a cross of two bars per parent
##         spanning the clear distance between its opposed siblings, 2R(1 - 2r) long. On the
##         fill bench the exact prism between each face-adjacent leaf pair, (1-fill)*LEAF
##         long and (fill*LEAF) square. BOTH VANISH AT contact AND AT fused, because
##         1 - 2r and 1 - fill cross zero at exactly the same rung. Two empty courts, and
##         they are this artifact's designed null.
##   web   the incidences, at a fixed gauge that ignores how big anything is. A dot at every
##         atom centre and a rod wherever two atoms touch or overlap. It isolates POSITION,
##         and it is where the two mechanisms are caught: the fill bench's 125 dots never
##         move at any value, because the lattice is packing-independent; the ratio bench's
##         21 dots move at every value, because there the ratio IS the recursion.
@export_enum("kept", "gap", "web") var reading: String = "kept":
	set(value):
		if value == reading:
			return
		reading = value
		if _built and not _applying:
			_rebuild()

## THE RATIO BENCH'S TABLE, from example_8_3_recursion_circles_vr.gd:70, unchanged.
const PACKING_R: Dictionary = {"fused": 0.6, "contact": 0.5, "open": 0.35, "dust": 0.25}
## THE FILL BENCH'S TABLE, from SierpinskiPyramid.gd:52, unchanged.
const PACKING_FILL: Dictionary = {"fused": 1.35, "contact": 1.0, "open": 0.6, "dust": 0.28}

const C_RATIO: Vector3 = Vector3(-0.60, 0.58, 0.0)
const C_FILL: Vector3 = Vector3(0.60, 0.58, 0.0)
const R0: float = 0.44
const RATIO_DEPTH: int = 3
const GAUGE: float = 0.016
const LEAF: float = 0.125
const FILL_DEPTH: int = 3
const DOT_R: float = 0.024
const ROD_R: float = 0.008
const MIN_R: float = 0.01

const FLOOR_SIZE: Vector3 = Vector3(2.40, 0.05, 1.15)
const PAD_SIZE: Vector3 = Vector3(1.10, 0.012, 1.02)
const DIVIDER_SIZE: Vector3 = Vector3(0.026, 0.014, 1.02)

var _body: Node3D
var _built: bool = false
## Held true while apply_grid_config is assigning, so that a token setting BOTH axes rebuilds
## ONCE at the end instead of once per key. Without it the first setter fires a full rebuild
## against the other axis's old value, and a two-key token pays for three courts to see one.
var _applying: bool = false
var _leaves: Array[Vector3] = []
var _mat_floor: StandardMaterial3D
var _mat_pad: StandardMaterial3D
var _mat_ring: StandardMaterial3D
var _mat_cube: StandardMaterial3D
var _mat_gap: StandardMaterial3D
var _mat_web: StandardMaterial3D


func _ready() -> void:
	_read_dna()
	_make_materials()
	_make_leaves()
	_rebuild()
	_built = true


## The grid writes config_* metadata on the artifact ROOT before add_child, so this runs
## before a single mesh exists. An unknown word keeps the value already held.
func _read_dna() -> void:
	if has_meta("config_packing"):
		var p: String = str(get_meta("config_packing")).strip_edges().to_lower()
		if PACKING_R.has(p):
			packing = p
	if has_meta("config_reading"):
		var d: String = str(get_meta("config_reading")).strip_edges().to_lower()
		if d in ["kept", "gap", "web"]:
			reading = d


## GUARDED. Returns on an empty dict, assigns only on a value that is both legal AND
## different, and rebuilds only after _ready has built once.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	var changed: bool = false
	_applying = true
	if config.has("packing"):
		var p: String = str(config["packing"]).strip_edges().to_lower()
		if PACKING_R.has(p) and p != packing:
			packing = p
			changed = true
	if config.has("reading"):
		var d: String = str(config["reading"]).strip_edges().to_lower()
		if d in ["kept", "gap", "web"] and d != reading:
			reading = d
			changed = true
	_applying = false
	if not changed or not _built:
		return
	_rebuild()


func _make_materials() -> void:
	_mat_floor = _flat(Color(0.220, 0.224, 0.243))
	_mat_pad = _flat(Color(0.337, 0.345, 0.369))
	# The two benches are matched in LUMINANCE and separated in hue, deliberately. The critic
	# measures a luminance difference by default, so a court whose halves differ in weight
	# would let the heavier bench set every number in the sheet.
	_mat_ring = _flat(Color(0.922, 0.420, 0.620))
	_mat_cube = _flat(Color(0.302, 0.620, 0.722))
	_mat_gap = _flat(Color(0.980, 0.659, 0.161))
	_mat_web = _flat(Color(0.878, 0.878, 0.902))


func _flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.62
	m.metallic = 0.0
	return m


## THE LEAF SET IS COMPUTED ONCE AND NEVER RECOMPUTED, and that is not an optimisation — it
## is the finding, written as code. sierpinski_pyramid's `packing` cannot reach this function;
## the lattice is the same 125 points at every value of the axis.
func _make_leaves() -> void:
	_leaves.clear()
	_recurse_leaves(C_FILL, LEAF * pow(2.0, float(FILL_DEPTH)), FILL_DEPTH)


## SierpinskiPyramid.gd:99-180 with both of its faults repaired: FIVE children, which is what
## its own @identity says it makes, and the initial extent its own comment at gd:198 names.
func _recurse_leaves(pos: Vector3, current_size: float, current_depth: int) -> void:
	if current_depth == 0:
		_leaves.append(pos)
		return
	var half_size: float = current_size / 2.0
	var off: float = half_size / 2.0
	_recurse_leaves(pos + Vector3(0.0, off, 0.0), half_size, current_depth - 1)
	_recurse_leaves(pos + Vector3(-off, -off, -off), half_size, current_depth - 1)
	_recurse_leaves(pos + Vector3(off, -off, -off), half_size, current_depth - 1)
	_recurse_leaves(pos + Vector3(-off, -off, off), half_size, current_depth - 1)
	_recurse_leaves(pos + Vector3(off, -off, off), half_size, current_depth - 1)


func _rebuild() -> void:
	if is_instance_valid(_body):
		remove_child(_body)
		_body.queue_free()
	_body = Node3D.new()
	_body.name = "Court"
	add_child(_body)
	_build_court()
	var r: float = float(PACKING_R[packing])
	var f: float = float(PACKING_FILL[packing])
	match reading:
		"kept":
			_ratio_kept(r)
			_fill_kept(f)
		"gap":
			_ratio_gap(r)
			_fill_gap(f)
		"web":
			_ratio_web(r)
			_fill_web(f)


## THE COURT ITSELF, drawn before either axis is consulted and identical in all twelve cells.
## It is the reason the AABB is a constant and the reason the two null frames are a picture
## of an empty court rather than a blank plate.
func _build_court() -> void:
	_box(Vector3(0.0, -FLOOR_SIZE.y * 0.5, 0.0), FLOOR_SIZE, _mat_floor)
	_box(Vector3(C_RATIO.x, PAD_SIZE.y * 0.5, 0.0), PAD_SIZE, _mat_pad)
	_box(Vector3(C_FILL.x, PAD_SIZE.y * 0.5, 0.0), PAD_SIZE, _mat_pad)
	_box(Vector3(0.0, DIVIDER_SIZE.y * 0.5, 0.0), DIVIDER_SIZE, _mat_pad)


# ── THE RATIO BENCH — example_8_3's rule, where `packing` is the similitude ratio ─────────

func _ratio_kept(r: float) -> void:
	var stack: Array = [[C_RATIO, R0, RATIO_DEPTH]]
	while not stack.is_empty():
		var item: Array = stack.pop_back()
		var c: Vector3 = item[0]
		var big: float = item[1]
		var lvl: int = item[2]
		if lvl <= 0 or big < MIN_R:
			continue
		_ring(c, big)
		var small: float = big * r
		var off: float = big - small
		stack.append([c + Vector3(off, 0.0, 0.0), small, lvl - 1])
		stack.append([c + Vector3(-off, 0.0, 0.0), small, lvl - 1])
		stack.append([c + Vector3(0.0, off, 0.0), small, lvl - 1])
		stack.append([c + Vector3(0.0, -off, 0.0), small, lvl - 1])


## Every ring that HAS children, with its own radius — the denominators of the ratio bench.
func _ratio_parents(r: float) -> Array:
	var out: Array = []
	var stack: Array = [[C_RATIO, R0, RATIO_DEPTH]]
	while not stack.is_empty():
		var item: Array = stack.pop_back()
		var c: Vector3 = item[0]
		var big: float = item[1]
		var lvl: int = item[2]
		if lvl <= 1 or big < MIN_R:
			continue
		var small: float = big * r
		if small < MIN_R:
			continue
		out.append([c, big])
		var off: float = big - small
		stack.append([c + Vector3(off, 0.0, 0.0), small, lvl - 1])
		stack.append([c + Vector3(-off, 0.0, 0.0), small, lvl - 1])
		stack.append([c + Vector3(0.0, off, 0.0), small, lvl - 1])
		stack.append([c + Vector3(0.0, -off, 0.0), small, lvl - 1])
	return out


## THE CLEAR SPAN BETWEEN OPPOSED SIBLINGS, drawn as a solid cross. Two children sit at
## +-R(1-r) with radius rR, so the daylight between them is 2R(1-r) - 2rR = 2R(1 - 2r).
## At r = 0.5 that is exactly 0.0 and at r = 0.6 it is negative: NOTHING IS DRAWN, which is
## half of this artifact's designed null.
func _ratio_gap(r: float) -> void:
	if r >= 0.5:
		return
	for item: Array in _ratio_parents(r):
		var c: Vector3 = item[0]
		var big: float = item[1]
		var clear: float = 2.0 * big * (1.0 - 2.0 * r)
		if clear <= 0.0001:
			continue
		var h: float = 0.55 * 2.0 * r * big
		_box(c, Vector3(clear, h, h), _mat_gap)
		_box(c, Vector3(h, clear, h), _mat_gap)


func _ratio_web(r: float) -> void:
	var stack: Array = [[C_RATIO, R0, RATIO_DEPTH]]
	while not stack.is_empty():
		var item: Array = stack.pop_back()
		var c: Vector3 = item[0]
		var big: float = item[1]
		var lvl: int = item[2]
		if lvl <= 0 or big < MIN_R:
			continue
		_dot(c)
		var small: float = big * r
		if lvl <= 1 or small < MIN_R:
			continue
		var off: float = big - small
		var kids: Array[Vector3] = [
			c + Vector3(off, 0.0, 0.0), c + Vector3(-off, 0.0, 0.0),
			c + Vector3(0.0, off, 0.0), c + Vector3(0.0, -off, 0.0)]
		for k: Vector3 in kids:
			# PARENT TO CHILD IS ALWAYS AN INCIDENCE and never breaks: the child is exactly
			# internally tangent to its parent at every ratio, because offset + rR = R(1-r) +
			# rR = R identically. Containment survives every value of the axis; only
			# neighbourhood does not.
			_rod(c, k)
			stack.append([k, small, lvl - 1])
		# SIBLING TO SIBLING ONLY WHERE THE DISCS MEET. Opposed siblings are 2R(1-r) apart
		# and diagonal ones R(1-r)*sqrt(2); both clear 2rR only at r >= 0.5, so this loop
		# draws six rods per parent at fused and contact and none at open and dust.
		for a: int in range(kids.size()):
			for b: int in range(a + 1, kids.size()):
				if kids[a].distance_to(kids[b]) <= 2.0 * small + 0.000001:
					_rod(kids[a], kids[b])


# ── THE FILL BENCH — sierpinski's rule, where `packing` never reaches the recursion ───────

func _fill_kept(f: float) -> void:
	var e: float = LEAF * f
	var s: Vector3 = Vector3(e, e, e)
	for p: Vector3 in _leaves:
		_box(p, s, _mat_cube)


## THE EXACT COMPLEMENT PRISM between each face-adjacent leaf pair. Two neighbours are LEAF
## apart centre to centre and each face is (fill*LEAF) square, so the daylight between them is
## a (fill*LEAF, fill*LEAF, (1-fill)*LEAF) box. At fill = 1.0 that is zero thick and at
## fill = 1.35 it is negative: NOTHING IS DRAWN, the other half of the designed null.
##
## NOTE THE DIRECTION THIS RUNS IN, because it is counter-intuitive and correct: `open` draws
## MORE gap than `dust` (0.144 against 0.056 of a leaf volume per pair), since the prism is
## as wide as the faces it joins, and by dust the atoms are too small to bound much of
## anything. The gap is a relation, not a remainder.
func _fill_gap(f: float) -> void:
	if f >= 1.0:
		return
	var g: float = (1.0 - f) * LEAF
	var s: float = f * LEAF
	var n: int = _leaves.size()
	for i: int in range(n):
		for j: int in range(i + 1, n):
			var delta: Vector3 = _leaves[j] - _leaves[i]
			var ax: int = _face_axis(delta)
			if ax < 0:
				continue
			var size: Vector3 = Vector3(s, s, s)
			size[ax] = g
			_box((_leaves[i] + _leaves[j]) * 0.5, size, _mat_gap)


## -1 unless the two leaves differ along exactly ONE axis and by exactly one lattice pitch.
func _face_axis(delta: Vector3) -> int:
	var hit: int = -1
	for k: int in range(3):
		var v: float = absf(delta[k])
		if v <= 0.000001:
			continue
		if absf(v - LEAF) > 0.000001:
			return -1
		if hit >= 0:
			return -1
		hit = k
	return hit


func _fill_web(f: float) -> void:
	for p: Vector3 in _leaves:
		_dot(p)
	# Chebyshev distance, because these are axis-aligned cubes: two leaves of edge fill*LEAF
	# touch or overlap exactly when max|d| <= fill*LEAF. The lattice minimum is LEAF, so there
	# is no incidence at all below fill = 1.0 — and the SAME 406 incidences at 1.0 and at
	# 1.35, because no pair sits between those two distances. The contact graph of a lattice
	# cannot tell fused from contact. That is a fact about the fill mechanism, and the ratio
	# bench beside it is what makes it legible.
	var reach: float = f * LEAF
	if reach < LEAF - 0.000001:
		return
	var n: int = _leaves.size()
	for i: int in range(n):
		for j: int in range(i + 1, n):
			var delta: Vector3 = _leaves[j] - _leaves[i]
			var cheb: float = maxf(absf(delta.x), maxf(absf(delta.y), absf(delta.z)))
			if cheb <= reach + 0.000001:
				_rod(_leaves[i], _leaves[j])


# ── primitives ───────────────────────────────────────────────────────────────────────────

func _box(centre: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = centre
	_body.add_child(mi)


## A ring of constant GAUGE, rotated into the plane its own offsets live in. The gauge is the
## PEN and is not the axis: holding it fixed is what stops `packing` from moving the ink
## weight as well as the geometry. TorusMesh is generated around its local +Y (it lies in
## XZ), so +90 degrees about X puts the hole along +Z and the ring in XY.
func _ring(centre: Vector3, radius: float) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = maxf(radius - GAUGE * 0.5, 0.002)
	tm.outer_radius = radius + GAUGE * 0.5
	tm.rings = 40
	tm.ring_segments = 10
	mi.mesh = tm
	mi.material_override = _mat_ring
	mi.transform = Transform3D(Basis(Vector3.RIGHT, PI * 0.5), centre)
	_body.add_child(mi)


func _dot(centre: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = DOT_R
	sm.height = DOT_R * 2.0
	sm.radial_segments = 10
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = _mat_web
	mi.position = centre
	_body.add_child(mi)


func _rod(a: Vector3, b: Vector3) -> void:
	var delta: Vector3 = b - a
	var h: float = delta.length()
	if h < 0.001:
		return
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = ROD_R
	cm.bottom_radius = ROD_R
	cm.height = h
	cm.radial_segments = 6
	cm.rings = 0
	mi.mesh = cm
	mi.material_override = _mat_web
	var up: Vector3 = delta / h
	var ref: Vector3 = Vector3.RIGHT
	if absf(up.x) > 0.9:
		ref = Vector3.FORWARD
	var xax: Vector3 = ref.cross(up).normalized()
	var zax: Vector3 = xax.cross(up).normalized()
	mi.transform = Transform3D(Basis(xax, up, zax), (a + b) * 0.5)
	_body.add_child(mi)
