extends Node3D
class_name RecursionObservatory

# @identity
# essence: four recursions held at one rung — a ladder's length is set by which wall arrives first, COUNT or THICKNESS
# desire: To be read across rather than walked around — the row exists so four rules can be held against each other
# critical_parameter: tick — the rung every plinth is built at. Four rungs, because four is where the second wall arrives and both are biting at once
# triggers: tick -> every plinth rebuilds at rung n, and the last line of each plaque restates its own count, or names the wall that stopped it and the count it would have needed
# emerges: Menger stops at fine, Koch stops at dense, Cantor and Sierpinski walk past both — exhaustion arriving at different times, in order, on one axis
# needs: nothing supplied — no clock, no physics, no randf; it is built for a still by construction
# relationships: synthesis of cantor_set, koch_curve_3d, sierpinski_pyramid and menger_sponge, the four artifacts that share `tick`
# truth: A fractal is endless and its picture is not. Every ladder stops, and the rung it stops on is a fact about the drawing, not about the set.

# ─────────────────────────────────────────────────────────────────────
#  SYNTHESIS DNA — born promoted 2026-08-06. Sources: cantor_set,
#  koch_curve_3d, sierpinski_pyramid, menger_sponge.
#
#  WHAT THE FOUR SOURCES LEARNED, and why it needed one more object.
#  Each of them declared `tick` — how many times the rule has been
#  applied — and each stopped its ladder at a different rung, on the
#  record, for a reason it gave in its own registry entry:
#
#    cantor_set        5 rungs, ends at 32 bars. Stops because a sixth
#                      row is 12 mm of segment against the bar's own
#                      300 mm depth: a picture of the mesh's minimum
#                      feature rather than of Cantor.
#    koch_curve_3d     3 rungs, ends at n=4 (and SKIPS 3). Stops
#                      because the bump added at generation n has
#                      amplitude (4.71 / 3^n) * sqrt(3)/2 * 0.5, which
#                      at n=3 is 0.076 m against a drawing tube of
#                      radius 0.2 m. Measured: iterations 3, 4, 5 and 6
#                      are one photograph.
#    sierpinski_pyramid 5 rungs, ends at the 3125 its own @identity
#                      names. Stops on COUNT — every leaf is a
#                      cube_scene carrying a StaticBody3D.
#    menger_sponge     3 rungs, ends at 8000. Stops on COUNT: each tick
#                      multiplies by 20, so a fourth rung is 160,000.
#
#  So the ladders run 5, 3, 5, 3 against branching factors 2, 4, 5, 20,
#  and THE LENGTHS ARE NOT ORDERED BY THE BRANCHING FACTOR. Sierpinski
#  branches faster than Koch and reaches two more rungs. What actually
#  ends a ladder is whichever of TWO walls arrives first:
#
#    COUNT      N^n exceeds what can be instanced.        (5^5, 20^4)
#    THICKNESS  the detail added at rung n falls below
#               the pen that draws it: extent/s^n < r.    (Cantor, Koch)
#
#  That claim lives in four registry notes and nowhere a person can
#  stand in front of. This row is where it stands. Four plinths in
#  ascending D = log(N)/log(s) — 0.63, 1.26, 2.32, 2.73 — each etched
#  with its branching factor, its dimension, the rung its own ladder
#  ends on, and which wall ends it.
#
#  tick — the one axis, and the only word the four of them share. FOUR
#         RUNGS since 2026-08-11: once | coarse | fine | dense, all four
#         names taken character for character from cantor_set's and
#         sierpinski_pyramid's five-rung table.
#
#  WHY THE LADDER GREW, and why the original three-rung argument was
#  half right. That argument said three is the INTERSECTION — the deepest
#  rung every member can honestly be shown at — and that declaring
#  `dense` would be a rung two members cannot reach. But the row was
#  ALREADY doing that at `fine`: Menger's third rung is 8000 leaves, so
#  the Menger plinth is held at n=2 and its plaque reads HELD. The `room`
#  cap and the HELD line were built for exactly that case. A rung a member
#  cannot reach is example_8_4's fault only when the object falls back
#  SILENTLY; here the plinth stands at its cap and prints the number it
#  would have needed, which is the opposite of a silent fallback. It is
#  the exhibit.
#
#  AND THAT IS WHAT `dense` IS FOR. Read across the four rungs, the row
#  stops being a picture of four fractals and becomes a picture of four
#  LADDERS ENDING:
#
#    once    all four climbing
#    coarse  all four climbing
#    fine    Menger held on COUNT at n=2 (8000)
#    dense   Menger still held; Koch now held on THICKNESS at n=3, because
#            a fourth-rung segment is 0.020 m long against a 0.024 m pen;
#            Cantor and Sierpinski, whose own ladders are five rungs, are
#            still climbing past both of them
#
#  So at `dense` BOTH walls are biting at once, on two different plinths,
#  while the two long ladders walk past them — which is precisely the
#  claim sitting in four registry notes ("the lengths are not ordered by
#  the branching factor") and which no object has ever shown. Three rungs
#  could only assert it on a plaque.
#
#  `limit` (n=5) IS DECLINED, on the record. At five rungs only Cantor is
#  still moving: Koch held at 3, Sierpinski held at 4 (5^5 is 3125 leaves
#  on top of Menger's 400, past this row's own budget), Menger held at 2.
#  Three quarters of the object would stop answering the axis, and an
#  exhibit that makes its point by ceasing to be an exhibit has made a
#  different point. The COUNT wall arriving at the ROOM rather than at a
#  member is worth this paragraph and is not worth a rung.
#
#  NO FIXTURE AND NO SEED. cantor_set and menger_sponge both needed
#  dna.fixture build_mode=instant before a still could see anything,
#  because one grows on a 2 s clock and drops its bars with unfrozen
#  physics and the other subdivides once a second. This object has no
#  clock, no RigidBody3D and no randf() anywhere: _ready() lays the
#  finished row out in one frame and it never moves again. There is
#  nothing for a fixture to supply.
#
#  THE LADDER LENGTHS ARE READ OUT OF THE SOURCES, NOT TYPED IN HERE.
#  `LADDER n RUNGS` on each plaque is TICK_LEVELS.size() off that
#  artifact's own script, so the four cannot drift from what this row
#  claims about them. It is slot_machine's pattern: preload the table,
#  never copy it.
# ─────────────────────────────────────────────────────────────────────

## The four sources, preloaded so their own ladders can be read rather than
## transcribed. Nothing is instanced from them: their scenes are the wrong
## shape for a still (menger_sponge and cantor_set grow on a clock, and
## menger's leaves carry collision), so this row draws the four rules itself.
const SRC_CANTOR := preload("res://algorithms/fractals/cantorset/cantor_set.gd")
const SRC_KOCH := preload("res://algorithms/fractals/koshcurve/KochCurve3D.gd")
const SRC_PYRAMID := preload("res://algorithms/cellularautomata/sierpinski_pyramid/SierpinskiPyramid.gd")
const SRC_MENGER := preload("res://algorithms/fractals/mengersponge/menger_sponge.gd")

## This row's ladder. FOUR rungs since 2026-08-11 — see the header note on `dense`.
const TICK_LEVELS := {"once": 1, "coarse": 2, "fine": 3, "dense": 4}

@export_enum("once", "coarse", "fine", "dense") var tick: String = "fine"

# ── The row, in metres ───────────────────────────────────────────────
const SPAN: float = 1.02        ## every fractal's characteristic width
const PITCH: float = 1.40       ## plinth centre spacing
const COL_W: float = 0.44       ## plinth column
const COL_H: float = 0.64
const CAP_W: float = 1.10       ## the fascia slab, which carries the plaque
const CAP_T: float = 0.22
const BASE_T: float = 0.08
const BASE_PAD: float = 0.30
const BASE_D: float = 1.34
const DECK: float = BASE_T + COL_H + CAP_T   ## the surface each fractal stands on
## The Cantor ladder's TOTAL height, held constant while the number of rows changes —
## the row pitch is CANTOR_STACK / rung, so at rung 3 it is exactly the 0.30 m this
## artifact shipped with and the default is untouched. The source uses a fixed pitch
## and lets the stack grow taller with every rung; here the envelope is held and only
## the texture inside it changes, which is what this row already does for the pyramid
## (leaf pitch SPAN / 2^d) and for Menger. It also keeps the union AABB identical at
## every rung, so the fixed camera fits all four variants equally and no value is
## photographed from further away than another.
const CANTOR_STACK: float = 0.90
const KOCH_R: float = 0.012     ## half-thickness of a Koch segment
const RAIL_TOP_D: float = 3.0   ## the dimension rail runs 0 -> 3

## key, plaque title, branching factor N, scale divisor s, which wall ends the
## ladder, what the leaves are called, and the deepest rung THIS ROOM will build
## for that member.
##
## `room` IS THE EXHIBIT'S OWN DEVICE AND NOT A CONVENIENCE. It is the rung at which
## this room's drawing of that rule hits the same wall the source hit, and each of the
## three caps below is a different arrival:
##
##   cantor  5  never binds inside this ladder. 2^5 is 32 bars and each is still
##             thicker than it is short.
##   koch    3  THICKNESS, arriving here rather than at the source's own n=4. A Koch
##             segment at rung n is 1.602 / 3^n m long against a 0.024 m box: 0.059 m
##             at n=3 and 0.020 m at n=4, where the segment is SHORTER THAN THE PEN IS
##             WIDE and the arch becomes a lumpy sausage. The source declares 3 rungs
##             ending at n=4 because it draws 4.71 m with a 0.2 m tube; the wall is a
##             property of the drawing, which is this row's whole thesis, so the row
##             hits it in a different place and says so on the plaque.
##   pyramid 4  COUNT. 5^4 = 625 leaves; 5^5 is 3125 on top of Menger's 400, which is
##             past this row's own budget. The source's ladder declares that fifth
##             rung and this room cannot draw it.
##   menger  2  COUNT. 20^3 is 8000 and the source stops there itself.
##
## So at `dense` two of the four are held and the two walls are both biting at once,
## which is the claim the four registry notes make and no object has ever shown.
const MEMBERS := [
	{"key": "cantor", "title": "CANTOR SET", "n": 2, "s": 3, "wall": "THICKNESS", "unit": "BARS", "room": 5},
	{"key": "koch", "title": "KOCH CURVE 3D", "n": 4, "s": 3, "wall": "THICKNESS", "unit": "SEGMENTS", "room": 3},
	{"key": "pyramid", "title": "SIERPINSKI PYRAMID", "n": 5, "s": 2, "wall": "COUNT", "unit": "CUBES", "room": 4},
	{"key": "menger", "title": "MENGER SPONGE", "n": 20, "s": 3, "wall": "COUNT", "unit": "CUBES", "room": 2},
]

var _built: bool = false
var _mat_stone: StandardMaterial3D
var _mat_base: StandardMaterial3D
var _mat_rail: StandardMaterial3D
var _mat_mark: StandardMaterial3D
var _mat_koch: StandardMaterial3D
var _mat_pyramid: StandardMaterial3D
var _mat_menger: StandardMaterial3D


func _ready() -> void:
	_make_materials()
	_rebuild()


## The rung every plinth is held at. Default "fine" = 3, the top of this row.
func _rung() -> int:
	return int(TICK_LEVELS.get(tick, 3))


## How many rungs THAT artifact declares, read off its own script.
func _ladder_rungs(key: String) -> int:
	match key:
		"cantor":
			return SRC_CANTOR.TICK_LEVELS.size()
		"koch":
			return SRC_KOCH.TICK_LEVELS.size()
		"pyramid":
			return SRC_PYRAMID.TICK_LEVELS.size()
		"menger":
			return SRC_MENGER.TICK_LEVELS.size()
	return 0


## Tear down and build. Only ever reached from _ready() and from
## apply_grid_config once a declared value ACTUALLY changed after the first
## build — an unguarded rebuild here would re-run the whole row on any
## placement that passes any config key at all.
func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_build_row()
	_built = true


func _make_materials() -> void:
	_mat_stone = _flat(Color(0.16, 0.16, 0.18))
	_mat_base = _flat(Color(0.10, 0.10, 0.115))
	_mat_rail = _flat(Color(0.52, 0.54, 0.58))
	_mat_mark = _flat(Color(0.90, 0.72, 0.30))
	# The pale emissive line koch_curve_3d draws itself with, unchanged.
	_mat_koch = _flat(Color(0.90, 0.95, 1.0))
	_mat_koch.emission_enabled = true
	_mat_koch.emission = Color(0.60, 0.80, 1.0)
	_mat_koch.emission_energy_multiplier = 1.5
	_mat_pyramid = _flat(Color(0.70, 0.74, 0.80))
	_mat_menger = _flat(Color(0.82, 0.76, 0.62))


func _flat(albedo: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = albedo
	m.metallic = 0.0
	m.roughness = 1.0
	return m


# ── The room ─────────────────────────────────────────────────────────

func _build_row() -> void:
	var count: int = MEMBERS.size()
	var row_w: float = float(count - 1) * PITCH + CAP_W
	var rung: int = _rung()

	_add_box(Vector3(row_w + 2.0 * BASE_PAD, BASE_T, BASE_D),
		Vector3(0.0, BASE_T * 0.5, 0.0), _mat_base)
	_add_rail(row_w)

	for i in range(count):
		var m: Dictionary = MEMBERS[i]
		var x: float = (float(i) - float(count - 1) * 0.5) * PITCH
		_add_plinth(x)
		_add_plaque(m, x, rung)
		# ONE cap, applied to all four. Cantor and Koch used to be built at the raw
		# rung because within a three-rung ladder neither ever bound; at four rungs
		# Koch does, and a per-member exception is how a held plinth quietly becomes
		# an unheld one that draws garbage.
		var shown: int = mini(rung, int(m["room"]))
		var origin: Vector3 = Vector3(x, DECK, 0.0)
		match str(m["key"]):
			"cantor":
				_build_cantor(origin, shown)
			"koch":
				_build_koch(origin, shown)
			"pyramid":
				_build_pyramid(origin, shown)
			"menger":
				_build_menger(origin, shown)


func _add_plinth(x: float) -> void:
	_add_box(Vector3(COL_W, COL_H, COL_W),
		Vector3(x, BASE_T + COL_H * 0.5, 0.0), _mat_stone)
	_add_box(Vector3(CAP_W, CAP_T, CAP_W),
		Vector3(x, BASE_T + COL_H + CAP_T * 0.5, 0.0), _mat_stone)


## The dimension rail: D from 0 to 3 laid across the same width as the row, with
## a marker under each member's actual D. The plinths are evenly spaced and the
## markers are not, which is the row's second reading — Sierpinski and Menger are
## near neighbours in dimension while Cantor sits below one.
func _add_rail(row_w: float) -> void:
	var z: float = BASE_D * 0.5 - 0.17
	var y: float = BASE_T + 0.010
	_add_box(Vector3(row_w, 0.016, 0.030), Vector3(0.0, y, z), _mat_rail)
	for step in range(4):
		var tx: float = (float(step) / RAIL_TOP_D - 0.5) * row_w
		_add_box(Vector3(0.016, 0.048, 0.040), Vector3(tx, y + 0.024, z), _mat_rail)
	for m in MEMBERS:
		var d: float = _dimension(m)
		var mx: float = (d / RAIL_TOP_D - 0.5) * row_w
		_add_box(Vector3(0.034, 0.110, 0.052), Vector3(mx, y + 0.055, z), _mat_mark)
	var caption: Label3D = Label3D.new()
	caption.text = "D = log N / log s"
	caption.font_size = 40
	caption.pixel_size = 0.0009
	caption.modulate = Color(0.72, 0.74, 0.80)
	caption.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	caption.position = Vector3(0.0, BASE_T + 0.004, BASE_D * 0.5 - 0.07)
	add_child(caption)


func _dimension(m: Dictionary) -> float:
	return log(float(m["n"])) / log(float(m["s"]))


func _add_plaque(m: Dictionary, x: float, rung: int) -> void:
	var shown: int = mini(rung, int(m["room"]))
	var leaves: int = 1
	for k in range(shown):
		leaves *= int(m["n"])

	var lines: Array[String] = []
	lines.append(str(m["title"]))
	lines.append("N %d   s %d   D %.2f" % [int(m["n"]), int(m["s"]), _dimension(m)])
	lines.append("LADDER %d RUNGS - STOPS ON %s"
		% [_ladder_rungs(str(m["key"])), str(m["wall"])])
	var tail: String = "n=%d   %d %s" % [shown, leaves, str(m["unit"])]
	if shown < rung:
		# The count at the rung the ROW is standing at, however far above the cap it
		# is — computed rather than one multiply, which was only ever right when the
		# gap was exactly one rung. At tick=dense the Menger plinth now says 160000.
		var would: int = 1
		for k in range(rung):
			would *= int(m["n"])
		tail += "   HELD ON %s - n=%d IS %d" % [str(m["wall"]), rung, would]
	lines.append(tail)

	var label: Label3D = Label3D.new()
	label.text = "\n".join(lines)
	label.font_size = 34
	label.pixel_size = 0.0009
	label.line_spacing = 2.0
	label.modulate = Color(0.90, 0.91, 0.95)
	label.position = Vector3(x, BASE_T + COL_H + CAP_T * 0.5, CAP_W * 0.5 + 0.006)
	add_child(label)


# ── The four rules, drawn ────────────────────────────────────────────

## cantor_set's thirds rule, line for line: a segment of length L becomes two of
## L/3 offset by +/- L/3 and the middle L/3 is deleted. Row `level` sits at
## y = (rung - level) * pitch, which is the source's own layout
## (vertical_spacing * (max_iterations - level)), so the finest row rests on the
## deck and the original bar stands highest. The hue law is the source's too:
## Color.from_hsv(level / max_iterations, 0.8, 0.9).
##
## ONE DEPARTURE, and it is the same departure the pyramid makes. The source's pitch is
## a fixed number, so its stack grows taller with every rung; here the pitch is
## CANTOR_STACK / rung, so the stack is always 0.90 m and it is the ROW COUNT inside it
## that changes. At rung 3 that is 0.30 m and identical to what this artifact shipped.
## The reason is the row's own thesis: every member's envelope is held constant so that
## only its texture varies, which is also what keeps the union AABB the same at every
## rung and stops one value being photographed from further away than another.
##
## `removal` is NOT declared here — see the registry. Its middles are drawn as
## the source's default `gone` draws them: not at all.
func _build_cantor(origin: Vector3, rung: int) -> void:
	var thick: float = SPAN * 0.034
	var row_pitch: float = CANTOR_STACK / float(maxi(rung, 1))
	var segs: Array[Vector2] = [Vector2(0.0, SPAN)]
	for level in range(rung + 1):
		var y: float = float(rung - level) * row_pitch
		var hue: float = float(level) / float(maxi(rung, 1))
		var mat: StandardMaterial3D = _flat(Color.from_hsv(hue, 0.8, 0.9))
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(segs[0].y, thick, thick)
		for seg in segs:
			var mi: MeshInstance3D = MeshInstance3D.new()
			mi.mesh = mesh
			mi.material_override = mat
			mi.position = origin + Vector3(seg.x, y + thick * 0.5, 0.0)
			add_child(mi)
		if level == rung:
			break
		var nxt: Array[Vector2] = []
		for seg in segs:
			var third: float = seg.y / 3.0
			nxt.append(Vector2(seg.x - third, third))
			nxt.append(Vector2(seg.x + third, third))
		segs = nxt


## koch_curve_3d's arch: the identical Koch point list mapped onto a semicircle
## of radius SPAN/2, with the fractal's z displacement thrown radially at
## point.z * 0.5 — the source's `head = arch` branch, which is the value three
## live maps already draw.
##
## THE LEGS ARE NOT BUILT, deliberately. The source draws two, and it draws them
## at `iterations - 1`; one plinth carrying two different rungs is the single
## thing this row cannot afford. Its three parallel depth_layers are dropped for
## the same reason they would be here: volume, not argument.
func _build_koch(origin: Vector3, rung: int) -> void:
	var pts: Array[Vector3] = _koch_points(rung)
	var arch: Array[Vector3] = _map_to_arch(pts)
	for i in range(arch.size() - 1):
		_add_segment(origin + arch[i], origin + arch[i + 1])


func _koch_points(iter: int) -> Array[Vector3]:
	var curve_length: float = PI * SPAN / 2.0
	var pts: Array[Vector3] = []
	pts.append(Vector3(-curve_length / 2.0, 0.0, 0.0))
	pts.append(Vector3(curve_length / 2.0, 0.0, 0.0))
	for i in range(iter):
		pts = _koch_iteration(pts)
	return pts


func _koch_iteration(points: Array[Vector3]) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for i in range(points.size() - 1):
		var p1: Vector3 = points[i]
		var p2: Vector3 = points[i + 1]
		var segment: Vector3 = p2 - p1
		var third: Vector3 = segment / 3.0
		var b: Vector3 = p1 + third
		var d: Vector3 = p1 + 2.0 * third
		var mid: Vector3 = (b + d) / 2.0
		var height_vec: Vector3 = Vector3(-segment.z, 0.0, segment.x).normalized()
		if height_vec.length() < 0.001:
			height_vec = Vector3(0.0, 0.0, 1.0)
		var height: float = third.length() * sqrt(3.0) / 2.0
		out.append(p1)
		out.append(b)
		out.append(mid + height_vec * height)
		out.append(d)
	out.append(points[points.size() - 1])
	return out


func _map_to_arch(points: Array[Vector3]) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var start_x: float = points[0].x
	var total: float = points[points.size() - 1].x - start_x
	var radius: float = SPAN / 2.0
	for point in points:
		var t: float = (point.x - start_x) / total
		var angle: float = PI * (1.0 - t)
		var radial: float = point.z * 0.5
		out.append(Vector3(cos(angle) * (radius + radial),
			sin(angle) * (radius + radial), 0.0))
	return out


## sierpinski_pyramid's rule as its @identity states it: five copies at half
## scale, an apex plus four base corners. At depth d that is 5^d leaves filling a
## cube of edge u * 2^d, so a leaf pitch of u = SPAN / 2^d holds the silhouette
## constant across the rungs — which is the family's own claim, that the outline
## does not change while the texture inside it does.
##
## The source's SCRIPT makes SIX recursive calls, not five: an extra top child at
## +half_size alongside the one at +half_size/2. Its live leaf count is therefore
## 6^d, not 5^d, and its own measured AABB (12.25 m tall at depth 4, where five
## children give 8.5) proves it. Reported in the registry, not repaired here —
## repairing it changes what six live placements draw. This plinth draws the rule
## the artifact ARGUES.
func _build_pyramid(origin: Vector3, rung: int) -> void:
	var u: float = SPAN / pow(2.0, float(rung))
	var pts: Array[Vector3] = [Vector3.ZERO]
	for level in range(rung):
		var o: float = u * pow(2.0, float(rung - 2 - level))
		var nxt: Array[Vector3] = []
		for p in pts:
			nxt.append(p + Vector3(0.0, o, 0.0))
			nxt.append(p + Vector3(-o, -o, -o))
			nxt.append(p + Vector3(o, -o, -o))
			nxt.append(p + Vector3(-o, -o, o))
			nxt.append(p + Vector3(o, -o, o))
		pts = nxt
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(u, u, u)
	var lift: Vector3 = origin + Vector3(0.0, SPAN * 0.5, 0.0)
	for p in pts:
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = _mat_pyramid
		mi.position = lift + p
		add_child(mi)


## menger_sponge's rule, stated rather than tabulated: subdivide 3x3x3 and drop
## every sub-cube with TWO OR MORE centre coordinates — the six face centres and
## the body centre. That is exactly the source's keep_positions table, which
## removes {4, 10, 12, 13, 14, 16, 22}, derived instead of copied.
##
## The lattice index is built from three nested loops on purpose. The source
## computed it as i % 3, (i / 3) % 3 and i / 9.0 — and that last float divide
## smeared twenty sub-cubes along z at ninth-of-a-cell offsets, so for as long as
## it shipped the object was not a Menger sponge. One character. Three loops
## cannot make that mistake.
func _build_menger(origin: Vector3, rung: int) -> void:
	var cells: Array[Vector3] = [Vector3.ZERO]
	var edge: float = SPAN
	for level in range(rung):
		var child_edge: float = edge / 3.0
		var nxt: Array[Vector3] = []
		for c in cells:
			for iz in range(3):
				for iy in range(3):
					for ix in range(3):
						var centres: int = 0
						if ix == 1:
							centres += 1
						if iy == 1:
							centres += 1
						if iz == 1:
							centres += 1
						if centres >= 2:
							continue
						nxt.append(c + Vector3(float(ix - 1), float(iy - 1),
							float(iz - 1)) * child_edge)
		cells = nxt
		edge = child_edge
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(edge, edge, edge)
	var lift: Vector3 = origin + Vector3(0.0, SPAN * 0.5, 0.0)
	for c in cells:
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = _mat_menger
		mi.position = lift + c
		add_child(mi)


# ── Primitives ───────────────────────────────────────────────────────

func _add_box(size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	add_child(mi)


## One Koch segment as an oriented box. The basis is built by hand rather than
## with look_at, which needs the node inside the tree and would make the geometry
## depend on when it was parented.
func _add_segment(a: Vector3, b: Vector3) -> void:
	var delta: Vector3 = b - a
	var length: float = delta.length()
	if length < 0.0005:
		return
	var forward: Vector3 = delta / length
	var up: Vector3 = Vector3.UP
	if absf(forward.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var right: Vector3 = up.cross(forward).normalized()
	var real_up: Vector3 = forward.cross(right)
	var mi: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(KOCH_R * 2.0, KOCH_R * 2.0, length)
	mi.mesh = mesh
	mi.material_override = _mat_koch
	mi.transform = Transform3D(Basis(right, real_up, forward), (a + b) * 0.5)
	add_child(mi)


## Reads the one declared axis.
##
## GUARDED TWICE, deliberately. A value is taken only when it validates against
## this row's own table AND differs from what is already set, and _rebuild()
## fires only after _ready has built once. A placement passing no key reaches no
## assignment and never rebuilds.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	var changed: bool = false
	if config.has("tick"):
		var v: String = str(config["tick"]).to_lower()
		if TICK_LEVELS.has(v) and v != tick:
			tick = v
			changed = true
	if not changed:
		return
	if not _built:
		return
	_rebuild()
