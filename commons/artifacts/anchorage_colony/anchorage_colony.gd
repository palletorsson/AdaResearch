extends Node3D
class_name AnchorageColony

## anchorage_colony — the colony does not choose its shape. The ANCHORAGE chooses it.
##
## THE FAMILY. FOUR registry names, TWO scenes. `ant_colony_v2` and `AntColonyV2` both
## point at res://algorithms/swarmintelligence/ants_v2/AntColonyV2.tscn (uid
## hgbhr48651so); `physarum_colony` and `PhysarumColony` both point at
## res://algorithms/swarmintelligence/physarum/PhysarumColony.tscn (uid ptqav8cu4wdp).
## Two bodies wearing four names — the fifth time this corpus has found the pattern.
## All four declare an axis `anchorage`; all four carry the same four words; both SCENES
## declare them in the same order in code, `pair | triad | ring | scattered`, and the
## registry blocks agree on the SET but not the order (physarum's two names list `triad`
## first, which is its default, not its enum).
##
## WHAT THE MEMBERS' CODE DOES FOR EACH VALUE — read from the source, not the comments:
##   pair       ants: (15,0,15) and (-15,0,-10), radii 21.21 m and 18.03 m — UNEQUAL, so
##              the two arms of the road are not the same road twice. physarum: (-20,0,0)
##              and (20,0,0), symmetric, and its own note says a third attractor was
##              DELETED from this value so that pair would stop being a twin of triad.
##   triad      ants: (18,0,0), (-9,0,15.6), (-9,0,-15.6) — three anchors at 18 m, 120°
##              apart. physarum: (0,0,0), (15,0,15), (-15,0,-15) — three anchors that are
##              COLLINEAR, all on the line z = x. Its docstring calls that "a three-armed
##              Y"; three collinear points cannot make a Y. Their cheapest join is the
##              straight segment, and the Fermat point degenerates onto the middle one.
##              So the family disagrees about what `triad` MEANS, and only the ants' triad
##              is a Steiner problem at all. This artifact takes the ants' — see declines.
##   ring       ants: 6 anchors on a 36 m circle, rotated by RING_PHASE = 30° precisely so
##              that no ring anchor lands on a triad spoke. physarum: 8 anchors on a 40 m
##              circle at phase 0. Six is taken, with the phase, because the phase is a
##              considered constraint and eight without one is not.
##   scattered  BOTH ARE SEEDED, and with the SAME constant: SCATTER_SEED = 20260730 in
##              both files, 5 anchors in both, rejection-sampled to a minimum separation
##              (ants 10 m in a ±20 m box, physarum 8 m). The corpus's unseeded-generative
##              trap is already closed in this family; nothing here had to fix it.
##
## THE ARGUMENT. `anchorage` is where the food sits, and the members treat it as set
## dressing — a knob for the look of the level. It is not. It is the BOUNDARY CONDITION,
## and it is the entire input to the algorithm: two anchors admit exactly one road; three
## at 120° pose a Steiner problem whose answer is a Y and not a triangle; six on a circle
## pose a many-body problem whose cheapest network is not the ring; five at fixed random
## positions pose a problem with no symmetry to exploit. The colony's celebrated
## "self-organisation" is a search over a solution set the anchorage has already fixed.
## The `anchors` reading is the whole thesis in one frame: it shows the input alone, and
## the input is already the answer.
##
## AND THE SHARPEST CASE IS THE ONE THE FAMILY SHIPPED WITHOUT NOTICING. The ants put
## three anchors at 120° and the nest at the centre — which puts the NEST EXACTLY ON THE
## FERMAT POINT of its own food. The Steiner solve below runs at `triad` and comes back
## 0.15 mm from the home marker, so it declines to insert anything. The boundary condition
## solved the Steiner problem before the first ant walked.
##
## WHAT IS COMPUTED, EXACTLY. There is no agent simulation here and nothing animates.
##   network  the Euclidean MINIMUM SPANNING TREE over {nest} ∪ anchors, by Prim from the
##            nest, ties broken lexicographically on (in-tree index, outside index); then
##            ONE Steiner pass: for each terminal of tree-degree ≥ 2, take the neighbour
##            pair subtending the smallest angle at it, solve the Fermat point of that
##            triangle by 2000 Weiszfeld iterations from the centroid, and if the answer
##            lands more than 1 mm away, replace the two edges with three through a new
##            junction. One pass; vertices in index order; junctions are never revisited.
##            This is a spanning-tree heuristic, NOT a Steiner minimal tree: it splits a
##            vertex at most once, so at `ring` it leaves five of six spokes unimproved.
##   field    the members' own medium: deposit at every anchor, decay ×0.95, then a
##            4-neighbour in-place lerp at 0.5 — PhysarumGrid.process_step, on a 64 × 64
##            grid, 100 fixed iterations, no agents. ONE DEVIATION, declared: both members
##            guard the blur with `if cell > 0.001`, so a cell at zero is skipped and the
##            field can never spread into empty ground on its own. With agents that guard
##            is a speed optimisation; without them it freezes the field inside the deposit
##            discs. It is removed here. (The guard is worth reading twice: in BOTH members
##            the medium only blurs where a walker has already been, so the "self-written
##            map" is written by the walkers and not by the chemistry.)
## Both are deterministic to the last decimal. The `scattered` draw is a fixed 32-bit LCG
## seeded with the members' own 20260730 — an integer generator rather than
## RandomNumberGenerator so a Python replica can reproduce the constellation exactly, which
## is what the pre-registered prediction in the registry was computed from.

## WHERE THE FIXED POINTS ARE. The family's four words, the family's order (both scenes'
## @export_enum, character for character).
##   pair       two anchors on one diagonal at UNEQUAL radii, 0.440 and 0.374 — the ants'
##              (15,15) and (-15,-10) scaled so the farther sits on the canonical circle.
##              The nest lies between them at 168.69°, so the network is one road with a
##              kink in it, and the Fermat solve declines to straighten it.
##   triad      three anchors on the circle, 120° apart. The nest is their Fermat point.
##   ring       six anchors on the circle, phase 30° (the ants' RING_PHASE) so that no ring
##              anchor sits on a triad spoke. Radius equals side, so nest-to-anchor and
##              anchor-to-anchor cost the SAME: 31 candidate edges tie, and the minimum
##              spanning tree is not unique. The tie-break picks the star.
##   scattered  five anchors from the fixed draw: radii 0.222 · 0.231 · 0.236 · 0.253 ·
##              0.303, minimum separation 0.231. Accepted at the first five candidates.
##              Not re-seeded to make a nicer picture; this is the draw the seed gives.
@export_enum("pair", "triad", "ring", "scattered") var anchorage: String = "pair":
	set(v):
		anchorage = v
		if is_inside_tree() and not _suspend:
			_rebuild()

## WHAT IS READ OFF IT. The ground, the nest and the anchor posts stand in all three; each
## reading adds one layer, so the constellation is the constant and the answer is what
## moves.
##   anchors  the boundary condition alone. No network, no field. The thesis frame.
##   network  the cheapest roads, as raised causeways, with a junction dome wherever the
##            Steiner pass inserted one: none at pair, none at triad, one at ring, two at
##            scattered.
##   field    the medium as a built relief — physarum's own vertex shader
##            (VERTEX.y += slime) made real geometry instead of a displacement.
@export_enum("anchors", "network", "field") var reading: String = "network":
	set(v):
		reading = v
		if is_inside_tree() and not _suspend:
			_rebuild()

## One anchorage, or all four in a row at the same reading. NOT PART OF EITHER AXIS — an
## all-rungs value declared inside an axis makes capture_config_sweep union the row's AABB
## with every single and photograph the singles as specks. The registry fixture pins
## `single`.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		layout = v
		if is_inside_tree() and not _suspend:
			_rebuild()

const ANCHORAGES: PackedStringArray = ["pair", "triad", "ring", "scattered"]
const READINGS: PackedStringArray = ["anchors", "network", "field"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the ground, metres ────────────────────────────────────────────────────────────────
const BASE_R: float = 0.50          ## the terrain: the members' 50 m plane, at 1 m
const BASE_H: float = 0.012
const BASE_SEGS: int = 72
const LADDER_PITCH: float = 1.20

# ── the constellation ─────────────────────────────────────────────────────────────────
const ANCH_R: float = 0.44          ## the canonical circle: the members' 18-20 m
## The ants' pair, scaled so its FARTHER anchor lands on the circle: 0.44 / |(15,15)|.
## The near one then sits at 0.374, and the 21.21 : 18.03 inequality survives the scaling.
const PAIR_SCALE: float = 0.0207395
const RING_COUNT: int = 6
const RING_PHASE: float = PI / 6.0  ## the ants' 30°, so ring shares no ground with triad

const SCATTER_COUNT: int = 5
const SCATTER_SEED: int = 20260730  ## the members' own seed, in both files
const SCATTER_MIN_SEP: float = 0.22 ## 0.5 of ANCH_R — the ants' 10 m in ±20 m, exactly
## The nest is a fixed body in every frame; an anchor pad through it would make
## `scattered`'s COUNT unreadable, which is the one thing the axis is about. The members
## have no such guard because their 2 m nest sphere is tiny against a 50 m field.
const SCATTER_HOME_CLEAR: float = 0.12
const SCATTER_MAX_DRAWS: int = 500
## Used only if the bounded draw fails to place five. Hand-checked: every pair at least
## 0.24 apart, every point between 0.15 and 0.42 of the nest. Guarantees the COUNT is 5.
const SCATTER_FALLBACK: Array = [
	Vector2(0.30, -0.12), Vector2(-0.05, 0.32), Vector2(-0.33, -0.02),
	Vector2(0.06, -0.34), Vector2(-0.19, 0.19)]

# ── bodies ────────────────────────────────────────────────────────────────────────────
# An anchor STANDS. The ants' promotion note is the reason: their anchors were flat
# alpha-0.3 discs, the sweep camera looks down at 15°, and three, five and six of them
# painted one picture — ring==triad at 0.81%, scattered==triad at 1.03%. The difference
# between the two members was never the geometry, it was whether the geometry had a body.
const PAD_R: float = 0.055          ## the ants' 9 m disc; its rim stays 0.055 inside BASE_R
const PAD_H: float = 0.006
const PAD_SIDES: int = 20
const POST_H: float = 0.16          ## the ants' 4 m mast, freed of their caption ceiling
const POST_R0: float = 0.032
const POST_R1: float = 0.021
const POST_SIDES: int = 12
const HOME_R: float = 0.045         ## the nest — identical at every value, as in both members
const HOME_H: float = 0.030
const ROAD_HALF: float = 0.034      ## a causeway, triangular in section, not a painted line
const ROAD_H: float = 0.065
const JUNCT_R: float = 0.050        ## a Steiner junction, seated on the ridge top
const DOME_RINGS: int = 6
const DOME_SEGS: int = 18

# ── the network solve ─────────────────────────────────────────────────────────────────
const STEINER_ITERS: int = 2000     ## Weiszfeld; at triad it lands 0.15 mm from the nest
const STEINER_DROP: float = 0.001   ## a junction this close to a terminal is that terminal
const TIE_EPS: float = 1e-9

# ── the field, PhysarumGrid's own numbers ─────────────────────────────────────────────
const FIELD_RES: int = 64
const FIELD_ITERS: int = 100
const FIELD_DECAY: float = 0.95     ## PhysarumGrid.decay_rate
const FIELD_DIFFUSE: float = 0.5    ## PhysarumGrid.diffuse_rate
const FIELD_DEPOSIT_R: float = 0.09
const FIELD_DEPOSIT: float = 1.0
const FIELD_CLAMP: float = 10.0     ## PhysarumGrid.add_slime's own cap
## The measured steady state of a lone anchor under this kernel at these iterations, so
## the relief's PEAK is 0.09 m at every anchor of every value and the axis moves its
## FOOTPRINT, never its height.
const FIELD_CAP: float = 9.5
const FIELD_H: float = 0.09
const FIELD_MIN: float = 0.12       ## below this no relief is built: the sand shows through

# ── colour, from the members' own shaders ─────────────────────────────────────────────
const C_BASE: Color = Color(0.80, 0.70, 0.50)    ## ant_valley.gdshader ground_color
const C_PAD: Color = Color(0.20, 0.62, 0.22)     ## the ants' food disc, opaque
const C_POST: Color = Color(0.07, 0.30, 0.10)    ## AntColonyV2 MAST_COLOR
const C_HOME: Color = Color(0.62, 0.72, 0.95)    ## the ants' home emission, as albedo
## mix(ground_color, vec3(1.0, 0.1, 0.1), 1.0) — ant_valley's food trail at full strength.
const C_ROAD: Color = Color(0.96, 0.22, 0.18)
const C_JUNCT: Color = Color(0.95, 0.90, 0.30)   ## physarum's marker yellow
const C_FIELD: Color = Color(0.80, 1.00, 0.10)   ## physarum_veins.gdshader vein_color

var _built: Array[Node3D] = []
## Three setters that each rebuild would build the field grid up to three times for one
## config call. The flag holds them off; apply_grid_config rebuilds once at the end.
var _suspend: bool = false


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	_suspend = true
	if config_data.has("layout"):
		layout = _pick(str(config_data["layout"]), LAYOUTS, layout)
	if config_data.has("anchorage"):
		anchorage = _pick(str(config_data["anchorage"]), ANCHORAGES, anchorage)
	if config_data.has("reading"):
		reading = _pick(str(config_data["reading"]), READINGS, reading)
	_suspend = false
	_rebuild()


## A token outside the allow-list is a typo and falls back to the shipped look rather than
## leaving the colony with no anchors at all — both members' rule, both members' reason.
func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var names: Array = []
	if layout == "ladder":
		for a in ANCHORAGES:
			names.append(a)
	else:
		names.append(_pick(anchorage, ANCHORAGES, "pair"))
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = str(names[i])
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH, 0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_variant(holder, str(names[i]))


func _build_variant(holder: Node3D, value: String) -> void:
	var anchors: Array[Vector2] = _anchor_positions(value)
	var top: float = BASE_H
	_add_base(holder)
	var r: String = _pick(reading, READINGS, "network")
	if r == "field":
		_add_field(holder, anchors, top)
	elif r == "network":
		_add_network(holder, anchors, top)
	_add_dome(holder, Vector2.ZERO, top, HOME_R, HOME_H, C_HOME, "Nest")
	_add_anchors(holder, anchors, top)


# ── the constellations ────────────────────────────────────────────────────────────────

## The whole axis in one table. Every branch returns a different COUNT and a different
## point set; none of them no-ops.
func _anchor_positions(value: String) -> Array[Vector2]:
	var out: Array[Vector2] = []
	match value:
		"triad":
			for i in range(3):
				var a: float = TAU * float(i) / 3.0
				out.append(Vector2(cos(a), sin(a)) * ANCH_R)
		"ring":
			for i in range(RING_COUNT):
				var a2: float = TAU * float(i) / float(RING_COUNT) + RING_PHASE
				out.append(Vector2(cos(a2), sin(a2)) * ANCH_R)
		"scattered":
			out = _scatter_positions()
		_:
			out.append(Vector2(15.0, 15.0) * PAIR_SCALE)
			out.append(Vector2(-15.0, -10.0) * PAIR_SCALE)
	return out


## Five anchors from a fixed 32-bit LCG seeded with the members' own constant, uniform in
## the disc of radius ANCH_R (r = R√u), rejected while any two would sit closer than
## SCATTER_MIN_SEP or an anchor would sit on the nest. Bounded twice over: the draw counter
## cannot exceed SCATTER_MAX_DRAWS, and the hand-checked fallback is used WHOLE if it ever
## ran out, so the count is 5 at every build.
##
## The members draw uniformly in a SQUARE ±20 m; the disc is this artifact's one change,
## and it is the similar-extent rule: an anchor flung past ANCH_R would make `scattered`
## a bigger object than `ring` and the axis would be measuring size instead of arrangement.
func _scatter_positions() -> Array[Vector2]:
	var state: int = SCATTER_SEED
	var out: Array[Vector2] = []
	var draws: int = 0
	while out.size() < SCATTER_COUNT and draws < SCATTER_MAX_DRAWS:
		draws += 1
		state = (state * 1664525 + 1013904223) & 0xFFFFFFFF
		var u1: float = float(state) / 4294967296.0
		state = (state * 1664525 + 1013904223) & 0xFFFFFFFF
		var u2: float = float(state) / 4294967296.0
		var rad: float = ANCH_R * sqrt(u1)
		var ang: float = TAU * u2
		if rad < SCATTER_HOME_CLEAR:
			continue
		var p: Vector2 = Vector2(cos(ang), sin(ang)) * rad
		var ok: bool = true
		for q in out:
			if p.distance_to(q) < SCATTER_MIN_SEP:
				ok = false
				break
		if ok:
			out.append(p)
	if out.size() < SCATTER_COUNT:
		out.clear()
		for i in range(SCATTER_FALLBACK.size()):
			out.append(SCATTER_FALLBACK[i])
	return out


# ── the network ───────────────────────────────────────────────────────────────────────

## Prim from the nest (index 0). Among edges of equal length the lexicographically smallest
## (in-tree index, outside index) wins — which matters, because at `ring` the radius equals
## the side and 31 candidate edges tie across the six rounds. The tree this returns is one
## of many of identical length; the tie-break, not the geometry, chooses which.
func _mst(pts: Array[Vector2]) -> Array:
	var n: int = pts.size()
	var intree: Array[bool] = []
	for i in range(n):
		intree.append(false)
	intree[0] = true
	var edges: Array = []
	for _step in range(n - 1):
		var best_d: float = INF
		var best_i: int = -1
		var best_j: int = -1
		for i in range(n):
			if not intree[i]:
				continue
			for j in range(n):
				if intree[j]:
					continue
				var d: float = pts[i].distance_to(pts[j])
				if d < best_d - TIE_EPS:
					best_d = d
					best_i = i
					best_j = j
				elif absf(d - best_d) <= TIE_EPS and (i < best_i or (i == best_i and j < best_j)):
					best_d = d
					best_i = i
					best_j = j
		if best_j < 0:
			break
		edges.append(Vector2i(best_i, best_j))
		intree[best_j] = true
	return edges


## ONE Steiner pass over the terminals, in index order. For a vertex of tree-degree ≥ 2,
## the neighbour pair subtending the smallest angle is the only pair worth splitting; the
## Fermat point of that triangle is where the two edges should meet instead. If the solve
## returns the vertex itself — which happens exactly when the angle is 120° or more — there
## is nothing to insert, and the DECLINE is the result, not a skipped branch: at `triad` the
## solve runs and lands 0.15 mm from the nest, which is the proof that the ants' three
## anchors put their own nest on the Fermat point.
func _steiner(pts: Array[Vector2], edges: Array) -> Array:
	var terminals: int = pts.size()
	for t in range(terminals):
		var nb: Array[int] = []
		for e in edges:
			var ed: Vector2i = e
			if ed.x == t:
				nb.append(ed.y)
			elif ed.y == t:
				nb.append(ed.x)
		if nb.size() < 2:
			continue
		var best_ang: float = INF
		var bu: int = -1
		var bv: int = -1
		for i in range(nb.size()):
			for j in range(i + 1, nb.size()):
				var du: Vector2 = pts[nb[i]] - pts[t]
				var dv: Vector2 = pts[nb[j]] - pts[t]
				if du.length() < 1e-9 or dv.length() < 1e-9:
					continue
				var ang: float = absf(du.angle_to(dv))
				if ang < best_ang:
					best_ang = ang
					bu = nb[i]
					bv = nb[j]
		if bu < 0:
			continue
		var s: Vector2 = _fermat(pts[t], pts[bu], pts[bv])
		if s.distance_to(pts[t]) < STEINER_DROP:
			continue
		pts.append(s)
		var si: int = pts.size() - 1
		var kept: Array = []
		for e2 in edges:
			var ed2: Vector2i = e2
			var a: int = mini(ed2.x, ed2.y)
			var b: int = maxi(ed2.x, ed2.y)
			if (a == mini(t, bu) and b == maxi(t, bu)) or (a == mini(t, bv) and b == maxi(t, bv)):
				continue
			kept.append(ed2)
		kept.append(Vector2i(si, t))
		kept.append(Vector2i(si, bu))
		kept.append(Vector2i(si, bv))
		edges = kept
	return [pts, edges, terminals]


## The point minimising the sum of distances to three points, by Weiszfeld from the
## centroid. Deterministic, no early exit, fixed iteration count — two builds of one value
## return the same point to the bit.
func _fermat(a: Vector2, b: Vector2, c: Vector2) -> Vector2:
	var p: Vector2 = (a + b + c) / 3.0
	for _i in range(STEINER_ITERS):
		var acc: Vector2 = Vector2.ZERO
		var wsum: float = 0.0
		for q in [a, b, c]:
			var qv: Vector2 = q
			var d: float = maxf(p.distance_to(qv), 1e-6)
			var w: float = 1.0 / d
			acc += qv * w
			wsum += w
		p = acc / wsum
	return p


func _add_network(holder: Node3D, anchors: Array[Vector2], top: float) -> void:
	var pts: Array[Vector2] = [Vector2.ZERO]
	for a in anchors:
		pts.append(a)
	var solved: Array = _steiner(pts, _mst(pts))
	var vpts: Array[Vector2] = solved[0]
	var edges: Array = solved[1]
	var terminals: int = solved[2]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for e in edges:
		var ed: Vector2i = e
		_road(st, vpts[ed.x], vpts[ed.y], top)
	var roads := MeshInstance3D.new()
	roads.name = "Roads"
	roads.mesh = st.commit()
	roads.material_override = _mat(C_ROAD)
	holder.add_child(roads)
	for i in range(terminals, vpts.size()):
		_add_dome(holder, vpts[i], top + ROAD_H, JUNCT_R, JUNCT_R, C_JUNCT, "Junction")


## A causeway: triangular in section, apex on the centreline, so it has a silhouette from
## a camera 15° above the ground rather than being a stripe of paint the pitch flattens.
func _road(st: SurfaceTool, a: Vector2, b: Vector2, y0: float) -> void:
	var d: Vector2 = b - a
	var l: float = d.length()
	if l < 1e-6:
		return
	var nrm: Vector2 = Vector2(-d.y, d.x) / l
	var pa: Vector3 = Vector3(a.x + nrm.x * ROAD_HALF, y0, a.y + nrm.y * ROAD_HALF)
	var pb: Vector3 = Vector3(a.x - nrm.x * ROAD_HALF, y0, a.y - nrm.y * ROAD_HALF)
	var pc: Vector3 = Vector3(b.x + nrm.x * ROAD_HALF, y0, b.y + nrm.y * ROAD_HALF)
	var pd: Vector3 = Vector3(b.x - nrm.x * ROAD_HALF, y0, b.y - nrm.y * ROAD_HALF)
	var ta: Vector3 = Vector3(a.x, y0 + ROAD_H, a.y)
	var tb: Vector3 = Vector3(b.x, y0 + ROAD_H, b.y)
	_face(st, pa, pc, tb)
	_face(st, pa, tb, ta)
	_face(st, pb, tb, pd)
	_face(st, pb, ta, tb)
	_face(st, pa, ta, pb)
	_face(st, pc, pd, tb)


# ── the field ─────────────────────────────────────────────────────────────────────────

## PhysarumGrid.process_step, with the deposit of process_attractors in front of it and no
## agents behind it: deposit at every anchor, decay, then a 4-neighbour in-place lerp over
## the interior, row-major, for FIELD_ITERS fixed iterations. The in-place order makes the
## blur slightly anisotropic; that is the members' blur, kept.
##
## THE ONE DEVIATION: the members guard the blur with `if cell > 0.001`, so a cell holding
## zero is never written and the field cannot leave the deposit discs on its own. That is
## sound when agents are laying trail everywhere; with no agents it would make this reading
## a duplicate of `anchors`. Removed, and declared.
func _field_grid(anchors: Array[Vector2]) -> PackedFloat64Array:
	var n: int = FIELD_RES
	var g := PackedFloat64Array()
	g.resize(n * n)
	g.fill(0.0)
	var step: float = 2.0 * BASE_R / float(n)
	var deposit: PackedInt32Array = PackedInt32Array()
	for j in range(n):
		var z: float = -BASE_R + (float(j) + 0.5) * step
		for i in range(n):
			var x: float = -BASE_R + (float(i) + 0.5) * step
			for a in anchors:
				var av: Vector2 = a
				if Vector2(x, z).distance_squared_to(av) <= FIELD_DEPOSIT_R * FIELD_DEPOSIT_R:
					deposit.append(j * n + i)
					break
	for _it in range(FIELD_ITERS):
		for k in range(deposit.size()):
			var idx: int = deposit[k]
			g[idx] = minf(g[idx] + FIELD_DEPOSIT, FIELD_CLAMP)
		for m in range(g.size()):
			var v: float = g[m] * FIELD_DECAY
			g[m] = 0.0 if v < 0.001 else v
		for y in range(1, n - 1):
			for x2 in range(1, n - 1):
				var c: int = y * n + x2
				var avg: float = (g[c - 1] + g[c + 1] + g[c - n] + g[c + n]) * 0.25
				g[c] += (avg - g[c]) * FIELD_DIFFUSE
	return g


func _add_field(holder: Node3D, anchors: Array[Vector2], top: float) -> void:
	var n: int = FIELD_RES
	var g: PackedFloat64Array = _field_grid(anchors)
	var step: float = 2.0 * BASE_R / float(n)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(n - 1):
		for i in range(n - 1):
			var v00: float = g[j * n + i]
			var v10: float = g[j * n + i + 1]
			var v01: float = g[(j + 1) * n + i]
			var v11: float = g[(j + 1) * n + i + 1]
			if maxf(maxf(v00, v10), maxf(v01, v11)) < FIELD_MIN:
				continue
			var x0: float = -BASE_R + (float(i) + 0.5) * step
			var x1: float = -BASE_R + (float(i) + 1.5) * step
			var z0: float = -BASE_R + (float(j) + 0.5) * step
			var z1: float = -BASE_R + (float(j) + 1.5) * step
			var p00: Vector3 = Vector3(x0, _field_y(top, v00), z0)
			var p10: Vector3 = Vector3(x1, _field_y(top, v10), z0)
			var p11: Vector3 = Vector3(x1, _field_y(top, v11), z1)
			var p01: Vector3 = Vector3(x0, _field_y(top, v01), z1)
			# The disc test is on the GROUND radius, not the 3D length — a mound 0.09 m
			# tall near the rim is inside the ground, and its own height must not evict it.
			var rr: float = maxf(maxf(Vector2(x0, z0).length(), Vector2(x1, z0).length()),
					maxf(Vector2(x1, z1).length(), Vector2(x0, z1).length()))
			if rr > BASE_R:
				continue
			_face(st, p00, p11, p10)
			_face(st, p00, p01, p11)
	var relief := MeshInstance3D.new()
	relief.name = "Field"
	relief.mesh = st.commit()
	relief.material_override = _mat(C_FIELD)
	holder.add_child(relief)


func _field_y(top: float, v: float) -> float:
	return top + 0.001 + FIELD_H * minf(v / FIELD_CAP, 1.0)


# ── bodies ────────────────────────────────────────────────────────────────────────────

func _add_base(holder: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cylinder(st, Vector2.ZERO, 0.0, BASE_H, BASE_R, BASE_R, BASE_SEGS)
	var mi := MeshInstance3D.new()
	mi.name = "Ground"
	mi.mesh = st.commit()
	mi.material_override = _mat(C_BASE)
	holder.add_child(mi)


func _add_anchors(holder: Node3D, anchors: Array[Vector2], top: float) -> void:
	var pads := SurfaceTool.new()
	pads.begin(Mesh.PRIMITIVE_TRIANGLES)
	var posts := SurfaceTool.new()
	posts.begin(Mesh.PRIMITIVE_TRIANGLES)
	for a in anchors:
		var av: Vector2 = a
		_cylinder(pads, av, top, top + PAD_H, PAD_R, PAD_R, PAD_SIDES)
		_cylinder(posts, av, top + PAD_H, top + PAD_H + POST_H, POST_R0, POST_R1, POST_SIDES)
	var mp := MeshInstance3D.new()
	mp.name = "Pads"
	mp.mesh = pads.commit()
	mp.material_override = _mat(C_PAD)
	holder.add_child(mp)
	var mo := MeshInstance3D.new()
	mo.name = "Posts"
	mo.mesh = posts.commit()
	mo.material_override = _mat(C_POST)
	holder.add_child(mo)


func _add_dome(holder: Node3D, at: Vector2, y0: float, r: float, h: float,
		c: Color, label: String) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(DOME_RINGS):
		var t0: float = (float(i) / float(DOME_RINGS)) * PI * 0.5
		var t1: float = (float(i + 1) / float(DOME_RINGS)) * PI * 0.5
		for k in range(DOME_SEGS):
			var a0: float = TAU * float(k) / float(DOME_SEGS)
			var a1: float = TAU * float(k + 1) / float(DOME_SEGS)
			var q00: Vector3 = _dome_point(at, y0, r, h, t0, a0)
			var q01: Vector3 = _dome_point(at, y0, r, h, t0, a1)
			var q10: Vector3 = _dome_point(at, y0, r, h, t1, a0)
			var q11: Vector3 = _dome_point(at, y0, r, h, t1, a1)
			_face(st, q00, q11, q01)
			_face(st, q00, q10, q11)
	var mi := MeshInstance3D.new()
	mi.name = label
	mi.mesh = st.commit()
	mi.material_override = _mat(c)
	holder.add_child(mi)


func _dome_point(at: Vector2, y0: float, r: float, h: float, t: float, a: float) -> Vector3:
	return Vector3(at.x + cos(t) * r * cos(a), y0 + sin(t) * h, at.y + cos(t) * r * sin(a))


## Sides plus a top cap. No bottom cap: everything here stands on the ground or on a pad.
func _cylinder(st: SurfaceTool, at: Vector2, y0: float, y1: float, r0: float, r1: float,
		sides: int) -> void:
	for k in range(sides):
		var a0: float = TAU * float(k) / float(sides)
		var a1: float = TAU * float(k + 1) / float(sides)
		var p00: Vector3 = Vector3(at.x + cos(a0) * r0, y0, at.y + sin(a0) * r0)
		var p10: Vector3 = Vector3(at.x + cos(a1) * r0, y0, at.y + sin(a1) * r0)
		var p01: Vector3 = Vector3(at.x + cos(a0) * r1, y1, at.y + sin(a0) * r1)
		var p11: Vector3 = Vector3(at.x + cos(a1) * r1, y1, at.y + sin(a1) * r1)
		_face(st, p00, p11, p10)
		_face(st, p00, p01, p11)
		_face(st, Vector3(at.x, y1, at.y), p11, p01)


## One triangle with its own face normal. Culling is off on every material here, so a
## wound-the-wrong-way face is shaded rather than missing.
func _face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length_squared() > 1e-18:
		n = n.normalized()
	else:
		n = Vector3.UP
	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(b)
	st.set_normal(n)
	st.add_vertex(c)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.0
	m.roughness = 0.75
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
