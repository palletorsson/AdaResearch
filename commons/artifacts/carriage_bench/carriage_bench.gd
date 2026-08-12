extends Node3D
class_name CarriageBench

## Carriage Bench — a SYNTHESIS artifact for the `travel` family.
##
## One body, six mounts, six times, on one deck.
##
## @identity
## essence: six identical cubes on one bench, each caught in a different one of the
##   `travel` family's six mountings, so that what a mounting CONCEDES can be read
##   across the rank instead of one specimen at a time.
## desire: to be walked from left to right until the visitor notices that the seat
##   and the armature — a bed with chocks and a clamp arm — concede exactly the same
##   nothing, and that the difference between them is not freedom but who chose the
##   position.
## critical_parameter: `reading` — what the bench counts as motion. The six mounts
##   never change; only what the instrument admits does.
## triggers: none. No _process, no Timer, no Tween, no physics, no random number.
##   The mounts are built by the family's own static builder at _ready and measured
##   against a table derived from its source.
## emerges: the family's docstring says a gimbal concedes orientation "entirely".
##   Its code builds TWO trunnion rings, which is two rotational degrees of freedom,
##   not three. The bench counts what the hardware has, not what the prose claims.
## needs: cube_bearing.gd's TRAVELS const and its build() [preloaded, not retyped];
##   nothing else — no shader, no registry lookup, no scene instance.
## relationships: synthesised from the seven registry names that declare `travel`,
##   which resolve to ONE script and one shared const. It replaces none of them and
##   re-runs none of their axes from the outside.
## truth: a mount cannot be photographed moving, but a mount that has been used can.
##   What CAN be photographed is the hardware, and hardware turns out to say almost
##   nothing about how much freedom is conceded: across the five mounted values,
##   material and degrees of freedom correlate at r = -0.31.

# ═══════════════════════════════════════════════════════════════════════════
# THE FAMILY WORD, READ AND NOT RETYPED
# ═══════════════════════════════════════════════════════════════════════════
#
# Seven registry names declare `travel`:
#
#   pickup_cube_combo · pickup_cube_rotating · pickup_cube_scaling
#   pickup_cube_static · pickup_cube_transforming · rotating_cube · transformation_cube
#
# THE ONE-SCENE-MANY-NAMES CLAIM IS TRUE, AND WAS VERIFIED RATHER THAN ASSUMED.
# All five pickup_cube_* scenes are byte-for-byte the same wrapper: the SAME script
# (pickup_wrapper.gd), the SAME three exports at the SAME values (rotation_speed 0,
# bob_height 0, bob_speed 0), the SAME Area3D at the SAME transform, the SAME
# BoxShape3D(0.52), the SAME half-scale Visuals slot, the SAME signal connection.
# The ONLY line that differs between them is which scene is dropped into that slot.
# rotating_cube.tscn and transformation_cube.tscn are the same body again —
# cube_scene.tscn — plus a tween node and a `Travel` child carrying cube_bearing.gd.
# So it is one wrapper wearing five names over one body wearing two more.
#
# `travel` IS REFUSED AS THIS ARTIFACT'S VARYING AXIS, on the record, for the reason
# retention_corridor refused `retention` and slack_yard refused `slack`: the six
# values sit SIDE BY SIDE and a body can be in exactly one of them at a time, so an
# axis over the word would demolish five sixths of the exhibit at every turn.
#
# THE EVIDENCE THAT THEY ARE PARALLEL AND NOT NESTED IS IN THE CODE, not the prose.
# cube_bearing.gd's five builders share NO geometry: _seat's ten meshes, _spindle's
# nine, _rail's nine, _gimbal's nine and _armature's eleven are five disjoint sets.
# Not one builder calls another; not one is another plus something. And the freedoms
# they concede do not form a chain either — rail's single translation and spindle's
# single rotation are incomparable, and seat and armature concede the same empty set
# through completely different hardware. There is no top value that contains the
# rest, so there is nothing for an "all at once" frame to collapse into.
#
# Therefore the word is EXHIBITED, not swept: six stations, six mounts, all standing,
# in the family's own declared order, built by the family's OWN static builder, and
# lettered from the family's own const. The bench varies what is SAID about them.
#
# A consequence worth stating because it is the opposite of the usual hazard: since
# `travel` is not an axis here, build_dna_gallery's tail-trimming can never drop
# `armature`. All six values are present in all nine tiles. "Sweep it whole" is
# satisfied by standing it whole.
const TRAVEL_SRC := preload("res://commons/primitives/cubes/cube_bearing.gd")

# ═══════════════════════════════════════════════════════════════════════════
# AXIS 1 — `permit`: how much of what the mount concedes is drawn
# ═══════════════════════════════════════════════════════════════════════════
#
# A STRICTLY ADDITIVE LADDER. Each rung keeps every mark the last one drew, so this
# axis NESTS where `reading` does not. Both cases are named in the registry because
# they want opposite handling under trimming: a nested axis is a sequence and must be
# swept in order, a parallel one is a set and loses a case if you drop one.
#
#   bare      the six mounts, the six bodies, and the graduations the chosen reading
#             measures against. You can see that the hardware differs. You cannot say
#             what any of it concedes. This is the state every one of the family's
#             placements ships in: a mounting, and nothing said about it.
#   swept     plus one glyph per freedom the reading admits, drawn AT the bearing
#             that provides it — a 240 degree double-headed arc concentric with a
#             rotation axis, a double-headed arrow along a translation axis. Bounded
#             travel gets stop discs; unbounded travel gets a dashed shaft and open
#             arrowheads. The rail is the only bounded freedom in the whole family,
#             and it is the only glyph in the bench that has stops on it.
#   counted   plus a tally on the deck skirt: six slots, a FIXED ceiling, filled for
#             every freedom the reading counts and HOLLOW for every freedom the mount
#             concedes that the reading refuses. This is the rung where the bench
#             stops showing freedom and starts showing a number, and the hollow slots
#             are there so the number cannot be read without its own shortfall.
@export_enum("swept", "bare", "counted") var permit: String = "swept"

# ═══════════════════════════════════════════════════════════════════════════
# AXIS 2 — `reading`: what the bench counts as motion
# ═══════════════════════════════════════════════════════════════════════════
#
# NOT A LADDER AND NOT A SET — A LATTICE. `motion` is the union of the other two and
# dominates both; `pose` and `place` are INCOMPARABLE, neither containing the other.
# Stated precisely because it decides the declaration order: the default is the top
# of the lattice, and the two incomparable values follow it, so a trim to two keeps
# the top and one of the pair rather than beheading the axis.
#
#   motion    every degree of freedom counts. The faithful reading, and the only one
#             that gets every station right.
#   pose      only rotation counts. A bench that reads orientation reports the RAIL —
#             a guide post, a carriage, two hard stops and a rubbed bright stripe —
#             as conceding nothing at all.
#   place     only translation counts. A bench that reads position reports the
#             SPINDLE and the GIMBAL as rigid, and the wear ring that proves the
#             spindle has turned is standing right there in the same frame.
#
# THIS IS THE ARTIFACT. Every one of those readings is a defensible instrument, all
# three are in daily use, and the ranking of the six mounts changes completely
# between them: at `motion` the rank runs 6,0,1,1,2,0; at `pose` 3,0,1,0,2,0; at
# `place` 3,0,0,1,0,0. Which mount is the most permissive is a property of the
# instrument and not of the mount.
@export_enum("motion", "pose", "place") var reading: String = "motion"


# ═══════════════════════════════════════════════════════════════════════════
# WHAT EACH MOUNT CONCEDES — DERIVED FROM cube_bearing.gd, WITH THE EVIDENCE
# ═══════════════════════════════════════════════════════════════════════════
#
# Read off the hardware each builder actually constructs, not off its docstring.
# The line references are to cube_bearing.gd.
#
#   none      3 rotations + 3 translations, all unbounded. build() returns before
#             creating a node (l.205): there is no hardware, so there is nothing to
#             constrain. THE SHIPPED LOOK of all 31 placements in the family.
#   seat      nothing. A pad under it, four chocks driven into the lower corners at
#             +/-1.02h (l.244), two posts and a keeper bar pinned across the top
#             (l.248-251). Restrained in all six.
#   spindle   one rotation, about Y. A pin on the vertical axis through the body
#             centre with a collar and a thrust washer (l.271-275). The annular wear
#             ring (l.268) is about that same axis.
#   rail      one translation, along Y, and it is the ONLY BOUNDED FREEDOM IN THE
#             FAMILY. Hard stops at c.y +/- 1.6h (l.296-298), carriage 0.46h tall
#             (l.300), so the carriage centre runs +/-(1.6 - 0.08 - 0.23) = +/-1.29h.
#             Cross-check: the bright stripe rubbed into the slot is 1.6h tall
#             (l.294), i.e. the carriage has used +/-0.8h of its +/-1.29h. The wear
#             is INSIDE the stops, which is consistent, and the bench draws the STOPS
#             because the axis is what the mount PERMITS, not what it has done.
#   gimbal    TWO rotations, about X and Z. And this is where the family's own prose
#             is wrong: the docstring says "orientation conceded entirely" (l.60) and
#             "orientation given away entirely" (l.306), which is a claim of three.
#             The code builds two trunnion rings and two pairs of pins — yoke to
#             outer on X at +/-1.87h (l.331-334), outer to inner on Z at +/-1.645h
#             (l.325-328). There is no third ring and no yaw bearing. Two.
#   armature  nothing, and that is the interesting nothing. A column, a ball knuckle,
#             a cranked arm, jaws closed on the +X face and THE LOCK HANDLE THROWN
#             (l.373-374). Its instantaneous freedom is zero, identical to the seat's
#             — the two stations that measure the same are the two whose hardware
#             looks least alike, and the difference between them is not how much
#             motion is permitted but who put the body where it is.
const ROT_AXES: Dictionary = {
	"none": "XYZ", "seat": "", "spindle": "Y",
	"rail": "", "gimbal": "XZ", "armature": "",
}
const TRA_AXES: Dictionary = {
	"none": "XYZ", "seat": "", "spindle": "",
	"rail": "Y", "gimbal": "", "armature": "",
}
## Half-travel in units of H for the bounded translations. A mount absent from this
## table has UNBOUNDED translations (only `none` does), and those are drawn dashed.
const TRA_HALF: Dictionary = {"rail": 1.29}

## THE CANARY. Each mount's own AABB in units of H, relative to the body centre, as
## [lo.x, lo.y, lo.z, hi.x, hi.y, hi.z] — computed from cube_bearing.gd's literals in
## a Python replica of its five builders. _check_hardware() measures what the family
## ACTUALLY built at _ready and push_errors on any face that has moved more than
## CANARY_TOL. The freedom table above is a reading of those same literals, so if the
## family's hardware changes and this table does not, the reading is stale and the
## bench would go on drawing arcs for bearings that are no longer there. This is the
## only thing in the file that can catch that.
const MOUNT_BOX: Dictionary = {
	"seat": [-1.500, -1.240, -1.500, 1.500, 1.440, 1.500],
	"spindle": [-1.740, -1.370, -1.740, 1.740, 1.880, 1.740],
	"rail": [-2.070, -1.750, -0.450, -0.330, 1.750, 0.450],
	"gimbal": [-2.250, -1.860, -1.815, 2.250, 1.860, 1.815],
	"armature": [0.605, -1.225, -0.600, 2.600, 2.060, 0.600],
}
const CANARY_TOL: float = 0.005


# ═══════════════════════════════════════════════════════════════════════════
# LAYOUT. Every length is a multiple of H, so the bench is one shape at any size.
# ═══════════════════════════════════════════════════════════════════════════
#
# H is the body's half-extent: the six bodies are 2H cubes, exactly what
# cube_bearing.measure() would hand its builders for cube_scene.tscn.
const H: float = 0.10

## STATION PITCH, and it is derived rather than chosen. Two constraints:
##   (a) hardware. In the family's declared order the tightest adjacency is
##       spindle -> rail: spindle reaches +1.740H and rail reaches -2.070H, so any
##       pitch under 3.810H puts one mount inside the other.
##   (b) glyphs. A rotation arc is drawn at R_ARC with a GLYPH_R tube, so it reaches
##       2.450 + 0.140 = 2.590H from its station centre. Two neighbours both drawing
##       arcs would need 5.180H.
## 5.400H clears (b) with 0.220H (22 mm, 4.6 px) of air. Worth noting: in the
## family's own order NO TWO ADJACENT STATIONS BOTH DRAW ARCS — the arcs fall on
## none, spindle and gimbal, which sit at positions 0, 2 and 4. The declared order
## alternates freedom-rich and freedom-poor, which is luck rather than design, and it
## is why the rank reads as cleanly as it does.
const P: float = 5.40 * H
const CELL_X: float = 2.70 * H
const CELL_Z: float = 2.20 * H
const CELL_HI: float = 2.70 * H
const CELL_LO: float = -1.84 * H

## Body centre above the deck. Set by the LOWEST point of any mount: the gimbal's
## outer ring bottoms out at -1.860H, below its own base plate at -1.700H, so 1.900H
## seats every mount on the deck with 0.040H to spare and no mount buried in it.
const CY: float = 1.90 * H

## Every rotation arc is drawn concentric with the BODY at ONE radius, and 2.450H is
## the only radius that clears all five mounts: it is outside the gimbal's base plate
## half-width (2.250H, the largest thing in the family), outside its outer ring
## (1.860H), outside the spindle's base plate (1.740H) and outside the seat's pad
## (1.500H). Every smaller candidate collides with something — the window between the
## gimbal's two rings is 1.58H..1.70H, only 0.12H wide, and a 0.28H tube does not fit
## in it. The arcs span 240 degrees about +Y (or about +Z for the horizontal one), so
## their lowest point is 2.450 * cos(120) = -1.225H, which is 0.675H clear of the deck.
const R_ARC: float = 2.45 * H
const ARC_SPAN: float = 240.0
const ARC_SEGS: int = 20

## The rail's travel arrow stands in FRONT of the guide post it measures, at the
## post's own x (-1.620H, cube_bearing l.287) and at z +1.05H, clear of the rail
## hardware's own +/-0.45H depth. Its length is the derived stop-to-stop travel and
## nothing else, 1:1 in metres, with a stop disc at each end.
const RAIL_X: float = -1.62 * H
const RAIL_Z: float = 1.05 * H

## MARKS, GAUGED TO THIS OBJECT AT THIS FRAMING (LAW 4). dna.framing 0.56 on the
## union box (3.325 x 0.732 x 0.5704, radius 1.72603) puts the camera at 6.0069 m,
## the frame at 3.6730 m and the scale at 206.9 px/m:
##     body 2H          200 mm -> 41.4 px
##     arc tube         28 mm  ->  5.8 px
##     arrowhead        64 mm  -> 13.2 px
##     stop disc        52 mm  -> 10.8 px
##     protractor tube  24 mm  ->  5.0 px
##     rule strip       28 mm  ->  5.8 px
##     body edge bar    20 mm  ->  4.1 px
##     tally slot       72 x 105 mm -> 14.9 x 21.7 px
##     tally divider    20 mm  ->  4.1 px
## The tally slot is gauged against the CRITIC as well as the frame. It crops to the
## pair's subject box — 629 x 269 px here — and resizes to 160 x 160 before diffing,
## so a screen pixel is 0.2544 samples across and 0.5948 down. A slot is therefore
## 3.8 x 12.9 samples, which is 49 samples of ink; sorting_hall's three-pixel gauge
## was three samples in BOTH directions. Marks were widened from 0.09H to 0.14H for
## this reason and no other: at 0.09H the arc tube was 3.7 px and 0.95 samples.
const GLYPH_R: float = 0.140 * H
const HEAD_R: float = 0.32 * H
const HEAD_L: float = 0.52 * H
const STOP_R: float = 0.26 * H
const STOP_L: float = 0.10 * H
const EDGE_R: float = 0.10 * H
const DASHES: int = 9

## THE DECK, AND THE Z-STACK (LAW 7). Written out because operations_gallery
## photographed a blank slab and its numbers looked exactly like an honest axis.
## Distances are from the deck's top face at y = 0, camera at +X +Y +Z.
##     deck slab      y [-0.042, 0.000]   z [-0.235, +0.295]
##     front skirt    y [-0.272, -0.042]  z [+0.275, +0.295]
##     tally dividers y [-0.272, -0.042]  z [+0.275, +0.301]
##     tally slots    y [-0.272, -0.062]  z [+0.295, +0.307]
##     rule strip     y [ 0.000, +0.006]  z [+0.256, +0.284]
##     protractors    y [ 0.000, +0.006]  radius 0.216..0.240 about each station
##     mounts         y [+0.020, +0.396]  z [-0.182, +0.182]
##     bodies         y [+0.090, +0.290]  z [-0.100, +0.100]
##     arcs           y [+0.068, +0.449]  |z| <= 0.259
## NOTHING OPAQUE STANDS BETWEEN THE CAMERA AND A MOUNT, and it was checked by ray
## rather than by eye: the graduations lie FLAT on the deck at y = 0.006 and the
## skirt hangs BELOW it at y < -0.042, while every mount starts at y = 0.020. A ray
## from the lowest mount pixel (y 0.020, z 0.180) toward the camera has risen to
## y = 0.049 by the time it reaches the rule strip at z = 0.270 and to y = 0.059 at
## the skirt at z = 0.300. This is why the graduations are inlaid and not stood up:
## the first version put a plumb index bar at every station and six white posts stood
## in front of six mounts.
const DECK_T: float = 0.42 * H
const SKIRT: float = 2.30 * H
const DECK_ZB: float = -2.35 * H
const DECK_ZF: float = 2.95 * H
const DATUM_Z: float = 2.70 * H
const DATUM_W: float = 0.28 * H
const DATUM_T: float = 0.06 * H
const RULE_STEP: float = 0.90 * H
const PROT_IN: float = 2.16 * H
const PROT_OUT: float = 2.40 * H
const PROT_TICKS: int = 8
const SLOT_W: float = 0.72 * H
const SLOT_H: float = 1.05 * H
const SLOT_P: float = 0.82 * H
const SLOT_N: int = 6
const DIV_W: float = 0.20 * H

## The body is drawn as cube_scene.tscn READS rather than as it is built: a near-black
## box (0.0688 grey, the Grid shader's own modelColor) inside twelve magenta edge bars
## (1, 0, 1, its wireframeColor). The shader itself is deliberately NOT used. Two
## reasons, both measured elsewhere in this project: a headless capture never
## reimports, so a shader edit does not reach the sweep and a six-month-stale
## compiled shader reads as INERT; and the family's mounting materials are matte shop
## hardware, so a body that reads as a different order of thing is the whole point.
const C_DECK := Color(0.205, 0.200, 0.196)
const C_BODY := Color(0.0688, 0.0688, 0.0688)
const C_EDGE := Color(0.95, 0.20, 0.95)
const C_ROT := Color(0.36, 0.78, 0.92)
const C_TRA := Color(0.42, 0.90, 0.55)
const C_DATUM := Color(0.80, 0.80, 0.84)
const C_FILL := Color(0.40, 0.84, 0.74)
const C_HOLLOW := Color(0.86, 0.32, 0.10)
const C_SLOT := Color(0.135, 0.132, 0.130)
const C_DIV := Color(0.30, 0.295, 0.29)
const C_TEXT := Color(0.84, 0.85, 0.87)

var _built: bool = false
var _root: Node3D = null

## THE ONE COPY OF THE ARITHMETIC (LAW 3). Filled once per build. The glyphs, the
## tally and the canary all read these; nothing recomputes them. So a slot a visitor
## counts and an arc they count it against cannot disagree.
var _names: PackedStringArray = PackedStringArray()
var _rot: Array = []          ## per station: Array[String] of rotation axis letters
var _tra: Array = []          ## per station: Array[String] of translation axis letters
var _seen: PackedInt32Array = PackedInt32Array()    ## counted under this reading
var _held: PackedInt32Array = PackedInt32Array()    ## conceded by the hardware


func _ready() -> void:
	_read_grid_config_meta()
	_check_family_list()
	_rebuild()
	_built = true


## LAW 1's validation half. The six station names are READ from the preloaded const,
## so they cannot drift from the family — but the freedom table above is keyed by
## literal strings, and a member adding or renaming a value would silently leave a
## station with no entry. This is the only place that can catch it, and it errors in
## both directions.
func _check_family_list() -> void:
	var fam: PackedStringArray = TRAVEL_SRC.TRAVELS
	for v in fam:
		if not ROT_AXES.has(v) or not TRA_AXES.has(v):
			push_error("carriage_bench: the family declares '%s' and this bench has no freedom entry for it." % v)
	for k in ROT_AXES.keys():
		if not fam.has(str(k)):
			push_error("carriage_bench: this bench holds a station for '%s' and the family no longer declares it." % str(k))


## THE CANARY (see MOUNT_BOX). Measures what the family's builder actually produced,
## in the station's own local space, and compares it to the table the freedom reading
## was derived from.
func _check_hardware(value: String, holder: Node3D) -> void:
	if holder == null or not MOUNT_BOX.has(value):
		return
	var lo := Vector3(1e9, 1e9, 1e9)
	var hi := Vector3(-1e9, -1e9, -1e9)
	var stack: Array[Node] = [holder]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
		if n is MeshInstance3D:
			var mi: MeshInstance3D = n as MeshInstance3D
			if mi.mesh == null:
				continue
			# Relative to the HOLDER, not to the mesh's own parent. cube_bearing adds
			# its meshes as direct children today, but a nested one would otherwise be
			# measured in the wrong space and the canary would fire on a phantom.
			var rel: Transform3D = holder.global_transform.affine_inverse() * mi.global_transform
			var ab: AABB = mi.mesh.get_aabb()
			for i in range(8):
				var p: Vector3 = rel * ab.get_endpoint(i)
				lo = lo.min(p)
				hi = hi.max(p)
	if lo.x > hi.x:
		return
	var want: Array = MOUNT_BOX[value]
	var got: Array = [lo.x, lo.y, lo.z, hi.x, hi.y, hi.z]
	for i in range(6):
		var w: float = float(want[i]) * H
		var g: float = float(got[i])
		if absf(w - g) > CANARY_TOL:
			push_error("carriage_bench: '%s' hardware face %d measured %.4f, table says %.4f. cube_bearing has moved and the freedom table may be stale." % [value, i, g, w])
			return


# ═══════════════════════════════════════════════════════════════════════════
# THE BUILD
# ═══════════════════════════════════════════════════════════════════════════

func _rebuild() -> void:
	if is_instance_valid(_root):
		remove_child(_root)
		_root.queue_free()
	_root = Node3D.new()
	_root.name = "Bench_%s_%s" % [permit, reading]
	add_child(_root)

	_names = TRAVEL_SRC.TRAVELS
	var n: int = _names.size()
	var count_rot: bool = reading != "place"
	var count_tra: bool = reading != "pose"

	_rot = []
	_tra = []
	_seen = PackedInt32Array()
	_held = PackedInt32Array()
	for i in range(n):
		var v: String = _names[i]
		var ra: Array = _letters(str(ROT_AXES.get(v, "")))
		var ta: Array = _letters(str(TRA_AXES.get(v, "")))
		_rot.append(ra)
		_tra.append(ta)
		_held.append(ra.size() + ta.size())
		var s: int = 0
		if count_rot:
			s += ra.size()
		if count_tra:
			s += ta.size()
		_seen.append(s)

	var half: float = float(n - 1) * 0.5
	var xs: PackedFloat32Array = PackedFloat32Array()
	for i in range(n):
		xs.append((float(i) - half) * P)
	var dhx: float = float(n - 1) * P * 0.5 + CELL_X + 0.4 * H

	_deck(dhx, xs)
	if count_tra:
		_rule(dhx)
	if count_rot:
		for i in range(n):
			_protractor(xs[i])

	for i in range(n):
		_station(i, xs[i], count_rot, count_tra)


func _deck(dhx: float, xs: PackedFloat32Array) -> void:
	var deck := _matte(C_DECK)
	_box(_root, Vector3(2.0 * dhx, DECK_T, DECK_ZF - DECK_ZB),
		Vector3(0.0, -DECK_T * 0.5, (DECK_ZF + DECK_ZB) * 0.5), deck)
	_box(_root, Vector3(2.0 * dhx, SKIRT, 0.20 * H),
		Vector3(0.0, -DECK_T - SKIRT * 0.5, DECK_ZF - 0.10 * H), deck)
	# One divider per station boundary. Without them the tally rows read as shifted
	# left of their stations: the skirt sits 0.27 m in front of the mounts and the
	# capture camera stands at yaw 0.62, so that offset projects to 0.16 m of screen
	# width — about a third of a station. The dividers are not decoration, they are
	# what makes a row belong to a station from an oblique standpoint.
	var div := _matte(C_DIV)
	for k in range(xs.size() + 1):
		_box(_root, Vector3(DIV_W, SKIRT, 0.26 * H),
			Vector3(xs[0] + (float(k) - 0.5) * P, -DECK_T - SKIRT * 0.5, DECK_ZF - 0.07 * H), div)


## THE RULE — the graduation a TRANSLATION is measured against, inlaid along the
## deck's front edge. Present at `motion` and `place`, absent at `pose`.
func _rule(dhx: float) -> void:
	var mat := _glow(C_DATUM, 0.22)
	_box(_root, Vector3(2.0 * dhx, DATUM_T, DATUM_W),
		Vector3(0.0, DATUM_T * 0.5, DATUM_Z), mat)
	var n: int = int(2.0 * dhx / RULE_STEP)
	for k in range(n + 1):
		_box(_root, Vector3(0.10 * H, DATUM_T * 1.6, RULE_STEP),
			Vector3(-dhx + float(k) * RULE_STEP, DATUM_T * 0.8, DATUM_Z - 0.68 * H), mat)


## THE PROTRACTOR — the graduation a ROTATION is measured against, inlaid in the deck
## around each station. Present at `motion` and `pose`, absent at `place`.
func _protractor(x: float) -> void:
	var mat := _glow(C_DATUM, 0.22)
	var mesh := TorusMesh.new()
	mesh.inner_radius = PROT_IN
	mesh.outer_radius = PROT_OUT
	mesh.rings = 40
	mesh.ring_segments = 8
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = Vector3(x, DATUM_T * 0.5, 0.0)
	_root.add_child(mi)
	for k in range(PROT_TICKS):
		var a: float = TAU * float(k) / float(PROT_TICKS)
		var s: float = sin(a)
		var c: float = cos(a)
		_rod(_root, Vector3(x + 1.94 * H * s, DATUM_T * 0.5, 1.94 * H * c),
			Vector3(x + PROT_IN * s, DATUM_T * 0.5, PROT_IN * c), 0.05 * H, mat)


func _station(i: int, x: float, count_rot: bool, count_tra: bool) -> void:
	var v: String = _names[i]
	var st := Node3D.new()
	st.name = "Station_%d_%s" % [i, v]
	st.position = Vector3(x, CY, 0.0)
	_root.add_child(st)

	# THE FAMILY'S OWN HARDWARE, BUILT BY THE FAMILY'S OWN BUILDER. Not re-drawn
	# here. `none` returns null before creating a node, which is exactly the shipped
	# look and exactly what the first station should be.
	var holder: Node3D = TRAVEL_SRC.build(st, v, Vector3.ZERO, H)
	_check_hardware(v, holder)

	_body(st)
	_tab(st, v)

	if permit != "bare":
		if count_rot:
			for a in _rot[i]:
				_arc(st, str(a))
		if count_tra:
			for a in _tra[i]:
				var letter: String = str(a)
				if TRA_HALF.has(v):
					_bounded(st, letter, float(TRA_HALF[v]) * H)
				else:
					_unbounded(st, letter)
	if permit == "counted":
		_tally(x, _seen[i], _held[i])


## The body: the family's cube, drawn as it reads. Identical at every station, at
## every value of both axes. It is the control, and the only thing in the frame that
## does not change is the thing being held.
func _body(st: Node3D) -> void:
	_box(st, Vector3(2.0 * H, 2.0 * H, 2.0 * H), Vector3.ZERO, _matte(C_BODY))
	var edge := _glow(C_EDGE, 0.55)
	for a in [-1.0, 1.0]:
		var sa: float = a
		for b in [-1.0, 1.0]:
			var sb: float = b
			_rod(st, Vector3(-H, sa * H, sb * H), Vector3(H, sa * H, sb * H), EDGE_R, edge)
			_rod(st, Vector3(sa * H, -H, sb * H), Vector3(sa * H, H, sb * H), EDGE_R, edge)
			_rod(st, Vector3(sa * H, sb * H, -H), Vector3(sa * H, sb * H, H), EDGE_R, edge)


## The station's name, lettered from the family's const.
##
## NO TILE CONTAINS A WORD NAMING ITS OWN VARIANT. These six words are values of
## `travel`, which is exhibited and never swept, so all six are present in all nine
## frames. Billboard is left DISABLED — LabelFramer treats a billboarded Label3D as a
## hanging sign and would bolt a panel and a bezel behind each one, six slabs this
## bench did not ask for. Label3D is not a MeshInstance3D and does not enter the
## capture AABB. HORIZONTAL_ALIGNMENT_CENTER is set explicitly because a LEFT-aligned
## Label3D hangs from its origin and runs right, which is how operations_gallery put
## a 0.467 m block 0.157 m past the edge of its own panel.
func _tab(st: Node3D, value: String) -> void:
	var lbl := Label3D.new()
	lbl.text = value
	# The clear band on the skirt runs y -0.145 to -0.042, so 0.103 m, and the tab is
	# centred in it at -0.110. 96 x 0.00060 = 0.0576 m of line height fits with 0.023 m
	# to spare and reads at 11.9 px in the tile; the longest word, "armature", is about
	# 0.25 m wide against a 0.540 m station pitch.
	lbl.font_size = 96
	lbl.pixel_size = 0.00060
	lbl.modulate = C_TEXT
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = Vector3(0.0, -CY - DECK_T - SKIRT + 1.62 * H, DECK_ZF + 0.09 * H)
	st.add_child(lbl)


## A ROTATION the reading admits: a 240 degree double-headed arc concentric with the
## bearing's axis, at the one radius that clears every mount in the family.
##
## The span is 240 and not 360 on purpose. A rotational bearing in this family is
## unbounded, and a closed ring would say the opposite — it would read as a limit.
## Two open arrowheads say "continues"; only the rail gets stops.
func _arc(st: Node3D, axis: String) -> void:
	var mat := _glow(C_ROT, 0.50)
	var u := Vector3.ZERO
	var w := Vector3.ZERO
	if axis == "Y":
		# The horizontal arc starts at +X so its 120 degree GAP is centred on -X. The
		# first version started it at +Z and put the gap behind the station, where the
		# canonical camera cannot see it — and an arc whose break is hidden reads as a
		# closed ring, which is the one thing it must not say, because a closed ring
		# means a limit and a bearing in this family has none.
		u = Vector3(1.0, 0.0, 0.0)
		w = Vector3(0.0, 0.0, 1.0)
	elif axis == "X":
		u = Vector3(0.0, 1.0, 0.0)
		w = Vector3(0.0, 0.0, 1.0)
	else:
		u = Vector3(0.0, 1.0, 0.0)
		w = Vector3(1.0, 0.0, 0.0)
	var a0: float = deg_to_rad(-ARC_SPAN * 0.5)
	var step: float = deg_to_rad(ARC_SPAN) / float(ARC_SEGS)
	var pts: Array[Vector3] = []
	for k in range(ARC_SEGS + 1):
		var t: float = a0 + step * float(k)
		pts.append((u * cos(t) + w * sin(t)) * R_ARC)
	for k in range(ARC_SEGS):
		_rod(st, pts[k], pts[k + 1], GLYPH_R, mat)
	_head(st, pts[0], pts[0] - pts[1], mat)
	_head(st, pts[ARC_SEGS], pts[ARC_SEGS] - pts[ARC_SEGS - 1], mat)


## A BOUNDED TRANSLATION: the true stop-to-stop travel, 1:1 in metres, with a stop
## disc at each end, drawn in front of the guide that provides it.
##
## NO FRAME-RELATIVE NORMALISATION (LAW 5). This arrow is 2.58H long because the
## carriage runs 2.58H, and it would be the same length in a frame containing a mount
## that ran ten times as far. There is exactly one bounded freedom in this family so
## there is nothing here to normalise against, which is precisely when a bench is
## most tempted to invent a scale.
func _bounded(st: Node3D, axis: String, half: float) -> void:
	var mat := _glow(C_TRA, 0.50)
	var d := _unit(axis)
	var base := Vector3(RAIL_X, 0.0, RAIL_Z)
	var p0: Vector3 = base - d * half
	var p1: Vector3 = base + d * half
	_rod(st, p0, p1, GLYPH_R, mat)
	for q in [p0, p1]:
		var pt: Vector3 = q
		_disc(st, pt, d, mat)


## AN UNBOUNDED TRANSLATION: a dashed shaft through the body centre, cut at the
## station's own cell, with an open arrowhead at each cut.
##
## The dash is the whole claim. A solid shaft with stops would state a distance this
## mount does not have, and `none` has no hardware at all to have it with. The cell
## bound is the BENCH's, not the mount's, and saying so is the difference between
## drawing an unbounded set and inventing a bounded one.
func _unbounded(st: Node3D, axis: String) -> void:
	var mat := _glow(C_TRA, 0.50)
	var d := _unit(axis)
	var lo: float = -CELL_X
	var hi: float = CELL_X
	if axis == "Y":
		lo = CELL_LO
		hi = CELL_HI
	elif axis == "Z":
		lo = -CELL_Z
		hi = CELL_Z
	var p0: Vector3 = d * lo
	var p1: Vector3 = d * hi
	for k in range(DASHES):
		if k % 2 != 0:
			continue
		var t0: float = float(k) / float(DASHES)
		var t1: float = (float(k) + 0.58) / float(DASHES)
		_rod(st, p0.lerp(p1, t0), p0.lerp(p1, t1), GLYPH_R, mat)
	_head(st, p1, d, mat)
	_head(st, p0, -d, mat)


## THE TALLY. Six slots, always six, always drawn — the ceiling is the number of
## degrees of freedom a rigid body has, which is 6 whatever this bench is showing.
## That is the fixed scale (LAW 5): a filled slot means the same thing in every tile
## of every variant.
##
## COUNT THE THING YOU CLAIM TO COUNT (LAW 6). `seen` is the number of freedoms the
## chosen reading admits; `held` is the number the hardware concedes. The slots
## between them are drawn HOLLOW rather than left dark, so a reading that undercounts
## carries its own shortfall in the same mark. Without that, `place` would report the
## gimbal as 0 and the seat as 0 in identical dark rows, and the bench would be
## stating that a two-axis gimbal and a chocked pad are the same thing.
func _tally(x: float, seen: int, held: int) -> void:
	var fill := _glow(C_FILL, 0.50)
	var hollow := _glow(C_HOLLOW, 0.30)
	var dark := _matte(C_SLOT)
	var y0: float = -DECK_T - SKIRT + 0.22 * H
	for k in range(SLOT_N):
		var mat: Material = dark
		var shrink: float = 0.04 * H
		if k < held:
			shrink = 0.0
			mat = fill if k < seen else hollow
		_box(_root, Vector3(SLOT_W, SLOT_H - 2.0 * shrink, 0.12 * H),
			Vector3(x + (float(k) - float(SLOT_N) * 0.5 + 0.5) * SLOT_P,
				y0 + SLOT_H * 0.5, DECK_ZF + 0.06 * H), mat)


# ═══════════════════════════════════════════════════════════════════════════
# GRID CONFIG
# ═══════════════════════════════════════════════════════════════════════════

## Tokens: #permit:bare · #permit:counted · #reading:pose · #reading:place
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_permit"):
			var p: String = _clean(str(node.get_meta("config_permit")))
			if _is_permit(p):
				permit = p
		if node.has_meta("config_reading"):
			var r: String = _clean(str(node.get_meta("config_reading")))
			if _is_reading(r):
				reading = r
		node = node.get_parent()


## Guarded four ways — a key must be present, its value must be one this code can
## build, it must differ from what is standing, and _ready must have built once. The
## grid reaches this twice for one placement, and an unguarded rebuild would tear
## down and re-raise six stations on the second call for nothing. That is force_pad's
## fault, and it is the reason this method checks _built.
func apply_grid_config(config: Dictionary) -> void:
	var changed: bool = false
	if config.has("permit"):
		var p: String = _clean(str(config["permit"]))
		if _is_permit(p) and p != permit:
			permit = p
			changed = true
	if config.has("reading"):
		var r: String = _clean(str(config["reading"]))
		if _is_reading(r) and r != reading:
			reading = r
			changed = true
	if not changed:
		return
	if not _built:
		return
	_rebuild()


func _is_permit(v: String) -> bool:
	return v == "bare" or v == "swept" or v == "counted"


func _is_reading(v: String) -> bool:
	return v == "motion" or v == "pose" or v == "place"


func _clean(raw: String) -> String:
	return raw.strip_edges().to_lower()


func _letters(s: String) -> Array:
	var out: Array = []
	for i in range(s.length()):
		out.append(s.substr(i, 1))
	return out


func _unit(axis: String) -> Vector3:
	if axis == "X":
		return Vector3(1.0, 0.0, 0.0)
	if axis == "Z":
		return Vector3(0.0, 0.0, 1.0)
	return Vector3(0.0, 1.0, 0.0)


# ═══════════════════════════════════════════════════════════════════════════
# SMALL BUILDERS
# ═══════════════════════════════════════════════════════════════════════════

func _matte(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.84
	m.metallic = 0.0
	return m


func _glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.34
	m.metallic = 0.0
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


## A tube from p0 to p1. The basis is built by hand rather than with look_at, because
## look_at needs the node in the tree and this runs before add_child.
func _rod(parent: Node3D, p0: Vector3, p1: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var d: Vector3 = p1 - p0
	var l: float = d.length()
	if l < 0.0001:
		return null
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = l
	mesh.radial_segments = 10
	mesh.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = Transform3D(_basis_along(d / l), (p0 + p1) * 0.5)
	parent.add_child(mi)
	return mi


## A cone whose APEX is at `tip`, pointing along `dir`.
func _head(parent: Node3D, tip: Vector3, dir: Vector3, mat: Material) -> MeshInstance3D:
	var d: Vector3 = dir.normalized()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = HEAD_R
	mesh.height = HEAD_L
	mesh.radial_segments = 14
	mesh.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = Transform3D(_basis_along(d), tip - d * HEAD_L * 0.5)
	parent.add_child(mi)
	return mi


## A hard stop at the end of a bounded run.
func _disc(parent: Node3D, pos: Vector3, dir: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = STOP_R
	mesh.bottom_radius = STOP_R
	mesh.height = STOP_L
	mesh.radial_segments = 16
	mesh.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = Transform3D(_basis_along(dir.normalized()), pos)
	parent.add_child(mi)
	return mi


## An orthonormal basis whose Y axis is `d`. Cylinder and cone meshes are built along
## Y in Godot, so this is the one place the glyph geometry meets the engine's
## convention.
##
## THE THIRD COLUMN IS xv.cross(d) AND NOT d.cross(xv), AND THE DIFFERENCE IS NOT
## COSMETIC. Basis(x, y, z) is right-handed exactly when x cross y = z. The first
## version returned Basis(xv, d, d.cross(xv)), whose determinant is -1: a mirror.
## Every rod, arrowhead and stop disc on the bench would have been built with
## inverted winding, so their normals would face inward and the key light would land
## on the wrong side of every glyph the axes draw. A cylinder is rotationally
## symmetric, so the mirror is invisible in the silhouette and would only have shown
## up as glyphs that were mysteriously darker than the hardware around them.
func _basis_along(d: Vector3) -> Basis:
	var up := Vector3(0.0, 1.0, 0.0)
	if absf(d.y) > 0.9:
		up = Vector3(1.0, 0.0, 0.0)
	var xv: Vector3 = up.cross(d).normalized()
	var zv: Vector3 = xv.cross(d)
	return Basis(xv, d, zv)
