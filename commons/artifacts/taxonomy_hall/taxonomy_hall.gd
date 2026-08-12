extends Node3D
class_name TaxonomyHall

## Taxonomy Hall — a SYNTHESIS artifact. One set of eight, arranged four ways, at once.
##
## @identity
## essence: eight specimens, generated once, standing simultaneously in four bays
##   as a table, a ladder, a stack and a heap — four incompatible claims about what
##   the same eight things have in common.
## desire: to be walked past until the visitor notices that the bay on the left never
##   moves when the sorting character changes, and works out why: it is the only one
##   of the four that does not claim an order, so it has no key to change.
## critical_parameter: `key` — the character the ordering is taken on. The eight
##   specimens never change: same eight bodies, same eight colours, same eight
##   volumes, in every frame of every variant. Only the claim about them changes.
## triggers: none. Nothing animates, nothing is grabbable, nothing is random. One
##   ordering computed per key at build time and read by all four bays.
## emerges: the four words are not four styles of display, they are two pairs and a
##   liar. table and ladder charge nothing to reach any member; stack and heap charge
##   exactly the same total, 28 handlings for eight objects, and are mirrors of each
##   other in WHO pays. And the heap yields its members in precisely the ladder's
##   order — a heap is a ladder that has not been written down yet.
## needs: the family's four words read live from a member's own const [has];
##   one rank array per key, read three ways [has]; a gauge with a ceiling fixed
##   across both axes [has]; no randf, no _process, no timer [has]
## relationships: synthesised from the seven registry names that declare `taxonomy`
##   — facade_grammar_demo, math_objects_gallery, combine_capsule, combine_portals,
##   combine_sphere, math_objects, grammar_totem_pole_rainbow_taper. It re-runs none
##   of their axes and replaces none of them. See dna.note in the registry.
## truth: an arrangement is an argument. Change what you sort on and three of the
##   four arguments rearrange themselves completely while the fourth does not move a
##   millimetre — because a table is the one claim that never said there was an order.


# ═══════════════════════════════════════════════════════════════════════════
# THE FAMILY WORD, READ AND NOT RETYPED — AND REFUSED AS AN AXIS, ON THE RECORD
# ═══════════════════════════════════════════════════════════════════════════
#
# `taxonomy` names the four BAYS of this hall. It is refused as this artifact's
# varying axis for the reason slack_yard refused `slack`: all seven members use the
# word to stand in ONE arrangement and forgo the other three, and in this hall all
# four are standing at once. That simultaneity IS the object. An axis whose every
# value demolishes three quarters of the exhibit is not a variation of it, and the
# large number it would produce would be a measurement of the hall being dismantled.
#
# THE FOUR VALUES SIT SIDE BY SIDE, NOT NESTED, and this was read out of the members'
# code rather than their prose. In combine_capsule.gd, combine_sphere.gd,
# math_objects_gallery.gd and facade_grammar_demo.gd the word is spent in a single
# `match taxonomy:` inside one placement function that returns ONE position per
# member — "ladder", "stack" and "heap" each DISCARD the cell the lattice computed
# and re-site the member from its index alone, and `_:` returns the untouched lattice.
# Four mutually exclusive returns from one switch: no value contains another, there
# is no "all at once" reading that is secretly the top rung, and so the parallel case
# applies. (grammar_totem_pole_rainbow_taper is the same switch over authored parts.)
#
# So the word is EXHIBITED rather than swept: it names the artifact, it names the four
# bays, it fixes their number and their order — and the list is PRELOADED out of a
# member so the two cannot drift. combine_sphere is the one read, because
# combine_capsule.gd and math_objects_gallery.gd both name it in their own comments as
# where they took the word from.
#
# THE ORDER THIS HALL TOOK, and the one it did not. Six of the seven members declare
# table | ladder | stack | heap, character for character, and they do so regardless of
# their own default — combine_portals defaults to "ladder" and still lists table first.
# grammar_totem_pole_rainbow_taper declares stack | ladder | table | heap. This hall
# takes the six-member order, because that is the const it preloads. The divergence
# has a threshold and it is worth stating: build_dna_gallery trims a value list from
# the TAIL, and BOTH orders end in `heap`, so at a cap leaving 3 values the two orders
# are measured on the SAME SET {table, ladder, stack} and differ only in tile order.
# Only at a cap of 2 do they part company — {table, ladder} against {stack, ladder}.
const TAX_SRC := preload("res://commons/primitives/combines/combine_sphere.gd")

## The wings this hall knows how to construct. NOT the vocabulary — the vocabulary is
## TAX_SRC.TAXONOMIES. This exists only so _check_family_list can push_error in both
## directions when the two disagree.
const BUILDERS: PackedStringArray = ["table", "ladder", "stack", "heap"]


# ═══════════════════════════════════════════════════════════════════════════
# AXIS 1 — `key`: the character the four claims are taken on
# ═══════════════════════════════════════════════════════════════════════════
#
# A taxonomy needs two decisions, and the family only ever varies the first. It picks
# an arrangement; it never says what the arrangement is an arrangement BY. This axis
# is the second decision, and its four values are four different KINDS of character,
# not four samples of one:
#
#   bulk   a magnitude. The specimens' volumes, computed from their own side count,
#          radius and height. The only value where a total order is honest: no ties,
#          nothing arbitrary, every member strictly greater than the last. THE
#          DEFAULT, because it is the case where the ordering machinery is beyond
#          reproach and every difference you can see between the four bays is a
#          difference between the CLAIMS rather than an artefact of a broken key.
#          (The two closest volumes differ by 0.80%: 0.001107386 against 0.001116300
#          cubic metres. Close, but not a tie, and far above float noise.)
#   made   provenance. The order the eight were accessioned in — a property of the
#          museum, not of the objects. It is in the list because it is what every
#          gallery in this corpus silently uses, and because of what it does to the
#          gauge: at `made` the rank rail of the TABLE bay becomes a perfect ascending
#          staircase identical to the ladder's and the heap's. An accession order
#          photographs exactly like a discovered one.
#   sides  a count, with TIES. Three of the eight side counts are shared by two
#          specimens each (3, 4 and 6), so six of the eight members are tied with
#          another. A total order over a tied character is a fiction, and the fiction
#          is visible: the tie is broken by accession, so the ladder's rungs 1-2, 3-4
#          and 6-7 are in the order the museum happened to receive them.
#   hue    a character on a CIRCLE. Hue has no smallest value; the ordering exists
#          only because this file cuts the circle at 0 degrees. Cut it at 180 and the
#          ladder inverts about a different point and the heap's apex changes. The
#          rank is real, its origin is not.
@export_enum("bulk", "made", "sides", "hue") var key: String = "bulk"

# ═══════════════════════════════════════════════════════════════════════════
# AXIS 2 — `gauge`: how much of the access discipline is drawn
# ═══════════════════════════════════════════════════════════════════════════
#
# A strictly additive ladder — each rung keeps every mark the last one drew — so this
# axis NESTS where `key` sits side by side. All three drawn rungs are read off ONE
# array, `_cost`, computed once per (bay, key) in _access(): how many OTHER members
# must be handled before this one is in your hand.
#
#   none   the four claims bare. You can see that the four bays differ. You cannot
#          say what any of them asserts, and you cannot check it.
#   rank   a rail of eight bars on the apron in front of each bay, one per member, in
#          the order that bay's claim yields its members, each bar's height being that
#          member's RANK under the current key. Ceiling 8 units, fixed everywhere. Now
#          every claim is checkable in one currency, and the four rails are the whole
#          argument in silhouette: the ladder's ascends, the stack's is its exact
#          mirror, the heap's ascends identically to the ladder's — and the table's is
#          scrambled, because a table does not claim an order to be checked against.
#   mouth  plus a bright collar at the foot of every member the claim will give you in
#          ONE step. table 8, ladder 8, stack 1 (the top), heap 1 (the smallest). THE
#          DEFAULT. Eighteen collars, and the pattern is the finding: the four words
#          are two pairs. Two of them hand you the whole set; two of them hand you one
#          thing and make you take the rest in an order you did not choose.
#   toll   plus, at the right-hand end of each rail, a column whose height is what the
#          whole claim charges to get all eight out: the sum of that bay's costs.
#          table 0, ladder 0, stack 28, heap 28. Two columns, identical to the
#          millimetre, and constant at every value of `key`.
@export_enum("mouth", "none", "rank", "toll") var gauge: String = "mouth"

# WHY `mouth` AND NOT `toll`. A synthesis has no shipped placements, so the default is
# a free design choice, and the freedom was spent on the strongest reading rather than
# the fullest. `toll` is the most striking single frame and the most misleading one:
# its two columns are the same height, which says a stack and a heap are the same
# thing. They are not — one yields its members largest first and the other smallest
# first, which the rank rail shows and the scoreboard erases. `mouth` holds the rail
# AND the access marks and asserts nothing it cannot show. `none` is the emptiest rung
# by definition: four arrangements and no way to say what any of them claims.


# ═══════════════════════════════════════════════════════════════════════════
# THE SET — eight specimens, authored once, arranged four ways
# ═══════════════════════════════════════════════════════════════════════════
#
# Four parallel constant arrays rather than an array of dictionaries, so the table is
# readable as a table and so that nothing here is a constructor call. (`const X:
# PackedVector2Array = PackedVector2Array([...])` does NOT parse — the right-hand side
# is a constructor call and GDScript requires a constant expression there. It cost
# slack_yard a whole pass, and tools/check_dna_declarations.py did not catch it,
# because that gate reads @export_enum hints out of the source TEXT and never parses
# the file.)
#
# Every specimen differs from every other in ALL FOUR characters, so no two of the
# four keys can produce the same ordering by accident, and each body is identifiable
# on sight by its size and colour without a caption. There is no text anywhere in this
# artifact: at the framing this hall is captured at, 209 px per metre, a legible glyph
# would have to be about 8 cm tall, which is two thirds the height of the smallest
# specimen. Identity is carried by the body instead of by a label — which is the one
# place this hall departs from the combine benches, where the members are near
# identical capsules and the numbers exist only on the plates.
const SPEC_SIDES: Array[int] = [6, 3, 4, 8, 5, 6, 3, 4]
const SPEC_RADIUS: Array[float] = [0.052, 0.086, 0.061, 0.074, 0.045, 0.092, 0.038, 0.105]
const SPEC_HEIGHT: Array[float] = [0.190, 0.062, 0.150, 0.088, 0.230, 0.070, 0.120, 0.045]
const SPEC_HUE: Array[float] = [18.0, 205.0, 96.0, 320.0, 250.0, 55.0, 150.0, 285.0]
const SPEC_COUNT: int = 8


# ═══════════════════════════════════════════════════════════════════════════
# THE HALL — every dimension, and the arithmetic that fixed it
# ═══════════════════════════════════════════════════════════════════════════
#
# Z-STACK, read front to back from the camera, because a frame is four rails and not a
# slab (operations_gallery's bezel enclosed every mark the axis drew and photographed
# as one blank plate):
#
#   z = +0.230 .. +0.185   apron, front lip. nothing stands here
#   z = +0.185 .. +0.135   THE GAUGE RAIL: rank bars (0.038 deep) and the toll column
#                          (0.050 deep). Nothing is in front of these. Ever.
#   z = +0.100 .. -0.260   the bay plinths, top face at y 0.210
#   z = -0.080 +/- 0.275   the wings themselves, standing ON the plinth top
#
# The rail is the only thing in front of the bodies, and it stands on the APRON at
# y 0.030 while the bodies stand on the PLINTH at y 0.210. The tallest rank bar reaches
# y 0.302; from the capture camera (pitch -0.26, so screen-up = 0.9664*y - 0.2092*z)
# that hides body pixels below y = 0.302 - 0.2165 * 0.24 = 0.250 — the bottom 4 cm of a
# body, in an 8 px stripe. The plinth exists for exactly that reason: without it the
# rail would cross the wings at full height.
const APRON_TOP: float = 0.030
const PLINTH_TOP: float = 0.210      ## the bay deck. Wings stand here.
const BAY_PITCH: float = 0.760
const BAY_HALF: float = 0.340
const PLINTH_Z0: float = -0.260
const PLINTH_Z1: float = 0.100
const WING_Z: float = -0.080         ## the wings' own centre line
const APRON_Z0: float = -0.300
const APRON_Z1: float = 0.230
const APRON_MARGIN: float = 0.040

const TAB_COL: float = 0.150         ## table: column pitch (x)
const TAB_ROW: float = 0.200         ## table: row pitch (z)
const LAD_DX: float = 0.062          ## ladder: step aside
const LAD_DY: float = 0.072          ## ladder: step up
const RISER_W: float = 0.020
const HEAP_R: float = 0.170          ## heap: scatter radius
const HEAP_APEX: float = 0.115       ## heap: how high the smallest sits on the pile
const HEAP_TIP_MIN: float = 62.0     ## heap: degrees of tip, from a hash of the index
const HEAP_TIP_SPAN: float = 34.0

const RAIL_Z: float = 0.160
const RAIL_SLOT: float = 0.062
const BAR_W: float = 0.038
## GAUGE, at 209.09 px/m: a rank bar is 0.038 m = 7.9 px wide, and 8 * 0.034 = 0.272 m
## = 56.9 px at rank 8, 7.1 px at rank 1. The CEILING IS FIXED ACROSS BOTH AXES — it is
## 8 units in every bay, at every key, at every gauge value, so a bar's height is
## comparable across the whole sheet and not to its own frame.
const RANK_UNIT: float = 0.034
## The toll's ceiling is likewise fixed: 28 = the largest toll any of the four claims
## can charge for eight members, n*(n-1)/2. 0.440 m = 92.0 px at 28.
const TOLL_CEILING: float = 0.440
const TOLL_MAX: int = 28
const TOLL_SLOT: float = 0.320
const TOLL_W: float = 0.110
const TOLL_D: float = 0.050
const COLLAR: float = 0.024          ## mouth collar: half-width = radius + this
const COLLAR_T: float = 0.012

const COL_APRON := Color(0.30, 0.30, 0.32)
const COL_PLINTH := Color(0.42, 0.42, 0.45)
const COL_RISER := Color(0.24, 0.24, 0.26)
const COL_BAR := Color(0.86, 0.86, 0.88)
const COL_TOLL := Color(0.98, 0.86, 0.30)
const COL_COLLAR := Color(0.28, 0.86, 0.92)

var _built: bool = false
var _wings: PackedStringArray = PackedStringArray()


# ═══════════════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_read_grid_config_meta()
	key = key if _is_key(key) else "bulk"
	gauge = gauge if _is_gauge(gauge) else "mouth"
	_wings = _family_wings()
	_check_family_list()
	_build()
	_built = true


## The grid stamps `config_*` metadata BEFORE add_child, so this runs ahead of the
## build. No metadata, no change. An unrecognised word keeps the standing value rather
## than emptying the hall.
func _read_grid_config_meta() -> void:
	var n: Node = self
	var hops: int = 0
	while n != null and hops < 4:
		if n.has_meta("config_key"):
			var k: String = str(n.get_meta("config_key")).strip_edges().to_lower()
			if _is_key(k):
				key = k
		if n.has_meta("config_gauge"):
			var g: String = str(n.get_meta("config_gauge")).strip_edges().to_lower()
			if _is_gauge(g):
				gauge = g
		n = n.get_parent()
		hops += 1


## Rebuilds ONLY when a value actually changed AND _ready has already built once —
## the force_pad fault, which tore down every child and re-ran _ready on any call,
## including calls naming nothing it owned.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false
	if config_data.has("key"):
		var k: String = str(config_data["key"]).strip_edges().to_lower()
		if _is_key(k) and k != key:
			key = k
			changed = true
	if config_data.has("gauge"):
		var g: String = str(config_data["gauge"]).strip_edges().to_lower()
		if _is_gauge(g) and g != gauge:
			gauge = g
			changed = true
	if changed and _built:
		_build()


func _is_key(v: String) -> bool:
	return v == "bulk" or v == "made" or v == "sides" or v == "hue"


func _is_gauge(v: String) -> bool:
	return v == "none" or v == "rank" or v == "mouth" or v == "toll"


## The family's list, read live. Falls back to this hall's own builder list only if the
## preload were ever to lose the const, and says so out loud rather than silently.
func _family_wings() -> PackedStringArray:
	# READ THE CONST OFF THE PRELOAD DIRECTLY. Object.get() would return null — a const
	# is not a property — and the hall would quietly fall back to its own copy, which is
	# the exact drift this preload exists to prevent. get_script_constant_map() was tried
	# and does not parse: it is a NON-STATIC method, so it cannot be called on the class,
	# only on an instance. TAX_SRC.TAXONOMIES is the family's own idiom (noise_quarry
	# reads READOUT_SRC.READOUTS the same way) and it has a better failure mode than
	# either: if combine_sphere ever drops the const, this file stops PARSING rather than
	# falling back at runtime, and the compile gate says so on the spot.
	var src: Variant = TAX_SRC.TAXONOMIES
	if src is PackedStringArray and (src as PackedStringArray).size() > 0:
		return src as PackedStringArray
	push_error("taxonomy_hall: combine_sphere.gd no longer exposes TAXONOMIES; " +
		"falling back to this hall's own builder list, which may have drifted from the family.")
	return BUILDERS


## Both directions, per slack_yard: a word the family declares that this hall cannot
## build, and a wing this hall builds that the family has dropped.
func _check_family_list() -> void:
	for w in _wings:
		if not BUILDERS.has(w):
			push_error("taxonomy_hall: the family declares '%s' and this hall has no bay for it." % w)
	for b in BUILDERS:
		if not _wings.has(b):
			push_error("taxonomy_hall: this hall builds '%s' and the family no longer declares it." % b)


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

	var n: int = _wings.size()
	var apron_half: float = float(n - 1) * 0.5 * BAY_PITCH + BAY_HALF + APRON_MARGIN
	_slab("Apron", Vector3(apron_half * 2.0, APRON_TOP, APRON_Z1 - APRON_Z0),
		Vector3(0.0, APRON_TOP * 0.5, (APRON_Z0 + APRON_Z1) * 0.5), COL_APRON, self)

	# ONE COPY OF THE ARITHMETIC. The rank of every member under the current key is
	# computed here, once, and read by all four bays and by all three drawn rungs.
	var rank: Array[int] = _ranks()

	for b in range(n):
		var wing: String = _wings[b]
		var bx: float = (float(b) - float(n - 1) * 0.5) * BAY_PITCH
		var bay := Node3D.new()
		bay.name = "Bay_" + wing
		add_child(bay)
		_slab("Plinth", Vector3(BAY_HALF * 2.0, PLINTH_TOP - APRON_TOP, PLINTH_Z1 - PLINTH_Z0),
			Vector3(bx, (APRON_TOP + PLINTH_TOP) * 0.5, (PLINTH_Z0 + PLINTH_Z1) * 0.5),
			COL_PLINTH, bay)

		var cost: Array[int] = _cost_for(wing, rank)
		var yields: Array[int] = _yield_order(wing, rank)
		var seat: Array[Vector3] = _seats(wing, bx, rank)
		var tip: Array[float] = _tips(wing, rank)

		if wing == "ladder":
			for p in range(1, SPEC_COUNT):
				var rx: float = bx + (float(p) - float(SPEC_COUNT - 1) * 0.5) * LAD_DX
				var rh: float = float(p) * LAD_DY
				_slab("Riser_%d" % p, Vector3(RISER_W, rh, RISER_W),
					Vector3(rx, PLINTH_TOP + rh * 0.5, WING_Z), COL_RISER, bay)

		for i in range(SPEC_COUNT):
			var mi := MeshInstance3D.new()
			mi.name = "Member_%d" % i
			mi.mesh = _prism_mesh(SPEC_SIDES[i], SPEC_RADIUS[i], SPEC_HEIGHT[i])
			mi.material_override = _matte(Color.from_hsv(SPEC_HUE[i] / 360.0, 0.62, 0.86), true)
			mi.position = seat[i]
			mi.rotation.x = deg_to_rad(tip[i])
			bay.add_child(mi)

		if gauge != "none":
			for j in range(SPEC_COUNT):
				var member: int = yields[j]
				var h: float = float(rank[member]) * RANK_UNIT
				var cx: float = bx + (float(j) - float(SPEC_COUNT - 1) * 0.5) * RAIL_SLOT
				_slab("Rank_%d" % j, Vector3(BAR_W, h, BAR_W),
					Vector3(cx, APRON_TOP + h * 0.5, RAIL_Z), COL_BAR, bay)

		if gauge == "mouth" or gauge == "toll":
			for i in range(SPEC_COUNT):
				if cost[i] != 0:
					continue
				var w: float = SPEC_RADIUS[i] + COLLAR
				var foot: float = seat[i].y - _half_extent(i, tip[i])
				_slab("Collar_%d" % i, Vector3(w * 2.0, COLLAR_T, w * 2.0),
					Vector3(seat[i].x, foot + COLLAR_T * 0.5, seat[i].z), COL_COLLAR, bay)

		if gauge == "toll":
			var total: int = 0
			for i in range(SPEC_COUNT):
				total += cost[i]
			if total > 0:
				var th: float = float(total) / float(TOLL_MAX) * TOLL_CEILING
				_slab("Toll", Vector3(TOLL_W, th, TOLL_D),
					Vector3(bx + TOLL_SLOT, APRON_TOP + th * 0.5, RAIL_Z), COL_TOLL, bay)


# ═══════════════════════════════════════════════════════════════════════════
# THE KEY — four characters, four orderings of one set
# ═══════════════════════════════════════════════════════════════════════════

## The sorting value of member i under the current key. `made` returns the index
## itself, which is the honest statement that accession is not a property of the
## object; `hue` returns the angle, whose zero is this file's cut of the circle and
## nothing more.
func _character(i: int) -> float:
	match key:
		"bulk":
			# The volume of a right prism: n/2 * r^2 * sin(2pi/n) * h. Derived from the
			# specimen's own three numbers, never transcribed as a fifth column that
			# could fall out of step with them.
			var s: float = float(SPEC_SIDES[i])
			return 0.5 * s * SPEC_RADIUS[i] * SPEC_RADIUS[i] * sin(TAU / s) * SPEC_HEIGHT[i]
		"sides":
			return float(SPEC_SIDES[i])
		"hue":
			return SPEC_HUE[i]
		_:
			return float(i)


## rank[i] = 1 .. 8 under the current key. Ties are broken by accession, which is what
## every catalogue in the world does and is exactly the arbitrariness `sides` exists to
## expose. The comparison is total — (value, index) — so the sort is deterministic even
## though Godot's sort_custom is not stable.
func _ranks() -> Array[int]:
	var vals: Array[float] = []
	for i in range(SPEC_COUNT):
		vals.append(_character(i))
	# A hand-rolled selection sort over eight elements rather than sort_custom: the
	# comparison is (value, index) and therefore TOTAL, so the result does not depend
	# on the stability of the sort, and there is nothing here a lambda's capture rules
	# could change under the file.
	var idx: Array[int] = []
	var taken: Array[bool] = []
	for i in range(SPEC_COUNT):
		taken.append(false)
	for _p in range(SPEC_COUNT):
		var best: int = -1
		for i in range(SPEC_COUNT):
			if taken[i]:
				continue
			if best < 0 or vals[i] < vals[best] or (vals[i] == vals[best] and i < best):
				best = i
		taken[best] = true
		idx.append(best)
	var out: Array[int] = []
	out.resize(SPEC_COUNT)
	for p in range(SPEC_COUNT):
		out[idx[p]] = p + 1
	return out


# ═══════════════════════════════════════════════════════════════════════════
# THE ACCESS DISCIPLINE — one cost array per bay, read three ways
# ═══════════════════════════════════════════════════════════════════════════
#
# cost[i] = how many OTHER members must be handled before member i is in your hand.
# It is a COUNT OF HANDLINGS, not of comparisons: a binary heap finds its minimum in
# log n comparisons, but you still have to take k-1 members off it before the k-th
# smallest is exposed, and it is the taking that this hall draws.
#
#   table   0 for all eight. A table's cells are independently addressable; that is
#           what commensurability means and it is the whole of the claim.
#   ladder  0 for all eight. A ranked file leaves every rung exposed — the ladder
#           claims an ORDER, not a gate. This is the one reading a viewer may want to
#           argue with, and the hall is stating it plainly rather than inventing a
#           toll to make the picture livelier: table and ladder therefore measure
#           ALIKE at `mouth` and at `toll`, and the difference between them shows up
#           only in the rank rail. If the two bays look the same in the collar
#           pattern, that is the finding and not a fault.
#   stack   the members above it. Pushed in ascending key order, so the largest is on
#           top and cost = 8 - rank.
#   heap    the members smaller than it. A heap yields its minimum and nothing else,
#           so cost = rank - 1.
#
# Which makes stack and heap exact mirrors, with the SAME total, 28 = 8*7/2 — and the
# heap's yield order identical to the ladder's, every time, at every key.
func _cost_for(wing: String, rank: Array[int]) -> Array[int]:
	var c: Array[int] = []
	c.resize(SPEC_COUNT)
	for i in range(SPEC_COUNT):
		match wing:
			"stack":
				c[i] = SPEC_COUNT - rank[i]
			"heap":
				c[i] = rank[i] - 1
			_:
				c[i] = 0
	return c


## The sequence the claim hands its members over in. The rank rail is drawn in THIS
## order, which is why the rails differ between bays that share a rank array.
func _yield_order(wing: String, rank: Array[int]) -> Array[int]:
	var out: Array[int] = []
	out.resize(SPEC_COUNT)
	match wing:
		"table":
			# No order to yield in, so it yields in accession order. At key=made that
			# makes the table's rail an ascending staircase identical to the ladder's,
			# which is the most useful accident in this artifact.
			for i in range(SPEC_COUNT):
				out[i] = i
		"stack":
			for i in range(SPEC_COUNT):
				out[SPEC_COUNT - rank[i]] = i
		_:
			# ladder and heap: ascending by rank, and identically so.
			for i in range(SPEC_COUNT):
				out[rank[i] - 1] = i
	return out


# ═══════════════════════════════════════════════════════════════════════════
# THE FOUR ARRANGEMENTS
# ═══════════════════════════════════════════════════════════════════════════

## Where each member's CENTRE sits — a MeshInstance3D holding a prism is centred on its
## body, so every seat is the body centre and the resting arithmetic is done here once.
func _seats(wing: String, bx: float, rank: Array[int]) -> Array[Vector3]:
	var s: Array[Vector3] = []
	s.resize(SPEC_COUNT)
	match wing:
		"ladder":
			# One ascending file, rung p carrying the p-th ranked member.
			for i in range(SPEC_COUNT):
				var p: int = rank[i] - 1
				s[i] = Vector3(bx + (float(p) - float(SPEC_COUNT - 1) * 0.5) * LAD_DX,
					PLINTH_TOP + float(p) * LAD_DY + SPEC_HEIGHT[i] * 0.5, WING_Z)
		"stack":
			# One column on one footprint, each member RESTING on the one below, so the
			# column's height is the sum of the bodies and not a decorative pitch.
			var lift: float = PLINTH_TOP
			for p in range(SPEC_COUNT):
				var m: int = _member_at_rank(rank, p + 1)
				s[m] = Vector3(bx, lift + SPEC_HEIGHT[m] * 0.5, WING_Z)
				lift += SPEC_HEIGHT[m]
		"heap":
			# The pile is the ACCESSION pile — a hash of the made index, never randf(),
			# so it is the same pile every boot, every machine. Only the SMALLEST under
			# the current key is lifted out of it to the apex, and whoever held the apex
			# slot takes the vacated place. A heap has no order; it has a mouth.
			var apex: int = _member_at_rank(rank, 1)
			for i in range(SPEC_COUNT):
				var slot: int = i
				if i == apex:
					slot = -1
				elif i == 0:
					slot = apex
				if slot < 0:
					s[i] = Vector3(bx, PLINTH_TOP + HEAP_APEX + SPEC_HEIGHT[i] * 0.5, WING_Z)
				else:
					var a: float = _index_hash(slot * 2 + 1) * TAU
					var rr: float = HEAP_R * sqrt(_index_hash(slot * 2 + 2))
					s[i] = Vector3(bx + cos(a) * rr,
						PLINTH_TOP + _half_extent(i, _tip_for_slot(slot)),
						WING_Z + sin(a) * rr)
		_:
			# "table": a 4 x 2 lattice in accession order. THE ONE ARRANGEMENT THAT DOES
			# NOT READ THE KEY, because it is the one claim that does not assert an
			# order — so this bay is pixel-identical across all four values of `key`.
			for i in range(SPEC_COUNT):
				var c: int = i % 4
				var rw: int = i / 4
				s[i] = Vector3(bx + (float(c) - 1.5) * TAB_COL,
					PLINTH_TOP + SPEC_HEIGHT[i] * 0.5,
					WING_Z + (float(rw) - 0.5) * TAB_ROW)
	return s


## Degrees of tip. Only the heap tips its members; the apex member stands up, which is
## how you can tell which one the heap will give you before you read a single mark.
func _tips(wing: String, rank: Array[int]) -> Array[float]:
	var t: Array[float] = []
	t.resize(SPEC_COUNT)
	for i in range(SPEC_COUNT):
		t[i] = 0.0
	if wing != "heap":
		return t
	var apex: int = _member_at_rank(rank, 1)
	for i in range(SPEC_COUNT):
		var slot: int = i
		if i == apex:
			continue
		elif i == 0:
			slot = apex
		t[i] = _tip_for_slot(slot)
	return t


func _tip_for_slot(slot: int) -> float:
	return HEAP_TIP_MIN + _index_hash(slot * 3 + 5) * HEAP_TIP_SPAN


## Half the vertical extent of member i once tipped by t degrees, which is what it has
## to be lifted by to rest on a deck: a body of half-height h/2 and radius r, turned
## about x, reaches (h/2)|cos t| + r|sin t| below its own centre.
func _half_extent(i: int, tip_deg: float) -> float:
	var t: float = deg_to_rad(tip_deg)
	return SPEC_HEIGHT[i] * 0.5 * absf(cos(t)) + SPEC_RADIUS[i] * absf(sin(t))


func _member_at_rank(rank: Array[int], r: int) -> int:
	for i in range(SPEC_COUNT):
		if rank[i] == r:
			return i
	return 0


# ═══════════════════════════════════════════════════════════════════════════
# GEOMETRY HELPERS
# ═══════════════════════════════════════════════════════════════════════════

## A right prism with FLAT facets, centred on its own body. CylinderMesh would smooth
## the sides and a three-sided specimen would stop reading as a triangle from the one
## standpoint these tiles are shot from. Cull is disabled on the material rather than
## trusting a winding order this file cannot test.
func _prism_mesh(sides: int, radius: float, height: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hy: float = height * 0.5
	var ring: Array[Vector3] = []
	for k in range(sides):
		var a: float = TAU * float(k) / float(sides) + PI / float(sides)
		ring.append(Vector3(cos(a) * radius, 0.0, sin(a) * radius))
	for k in range(sides):
		var p0: Vector3 = ring[k]
		var p1: Vector3 = ring[(k + 1) % sides]
		var nrm: Vector3 = ((p0 + p1) * 0.5).normalized()
		var a0 := Vector3(p0.x, -hy, p0.z)
		var a1 := Vector3(p1.x, -hy, p1.z)
		var b1 := Vector3(p1.x, hy, p1.z)
		var b0 := Vector3(p0.x, hy, p0.z)
		var quad: Array[Vector3] = [a0, a1, b1, a0, b1, b0]
		for v in quad:
			st.set_normal(nrm)
			st.add_vertex(v)
	for k in range(1, sides - 1):
		var cap_up: Array[Vector3] = [
			Vector3(ring[0].x, hy, ring[0].z),
			Vector3(ring[k].x, hy, ring[k].z),
			Vector3(ring[k + 1].x, hy, ring[k + 1].z)]
		for v in cap_up:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
		var cap_dn: Array[Vector3] = [
			Vector3(ring[0].x, -hy, ring[0].z),
			Vector3(ring[k + 1].x, -hy, ring[k + 1].z),
			Vector3(ring[k].x, -hy, ring[k].z)]
		for v in cap_dn:
			st.set_normal(Vector3.DOWN)
			st.add_vertex(v)
	return st.commit()


func _slab(nm: String, size: Vector3, centre: Vector3, col: Color, host: Node) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _matte(col, false)
	mi.position = centre
	host.add_child(mi)
	return mi


func _matte(col: Color, two_sided: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = 0.0
	m.roughness = 0.62
	if two_sided:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## Deterministic 0..1 from an integer — the family's own hash, character for character
## from combine_sphere.gd and math_objects_gallery.gd. Same pile every boot, every
## frame, every machine, so the critic measures the axis and not the noise.
func _index_hash(n: int) -> float:
	var s: float = sin(float(n) * 12.9898 + 78.233) * 43758.5453
	return s - floor(s)
