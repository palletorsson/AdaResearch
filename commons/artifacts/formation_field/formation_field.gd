extends Node3D
class_name FormationField

## Formation Field — a SYNTHESIS artifact. One population, standing five ways at once.
##
## @identity
## essence: twenty-seven bodies, generated ONCE from a hash, standing simultaneously in
##   five bays as a lattice, a shell, a ring, a column and a drift — the `formation`
##   family's five words, held side by side instead of chosen between.
## desire: to be read until the visitor notices that the lattice bay and the drift bay
##   carry the SAME four white bars, and that only the orange one tells them apart.
## critical_parameter: `vessel` — the shape of the container the five arrangements are
##   laid in. The family always uses a near-cube and never asks what its own box is
##   doing; an arrangement can only claim a force the container has not already applied.
## triggers: none. Nothing animates, nothing is grabbable, nothing is random. One
##   population computed at build time, arranged five ways, measured once, read twice.
## emerges: the five words are not five independent claims. Under an isotropic container
##   they are five distinct silhouettes; flatten the container and `column` collapses to
##   a knot no taller than the lattice's own cell, and the shell's one-radius claim
##   breaks (sigma_r 0.0004 m in the cube, 0.0420 m in the slab). And under the summary
##   the family would reach for first — the second moments — A LATTICE AND A DRIFT ARE
##   THE SAME POPULATION, agreeing to within 3.3 px of a 22.5 px bar.
## needs: the family's five words read live from a member's own const [has]; one
##   population generated once and shared by all five bays [has]; gauges with ceilings
##   fixed across both axes [has]; no randf, no _process, no timer [has]
## relationships: synthesised from the seven registry names that declare `formation` —
##   reactive_particle_field, reactive_particles, edge_particles, emergence_zone (four
##   tokens on one scene), rigid_sculpture, delaunay_triangulation_3d_cell, and
##   organic_space, whose `formation` is a different question under the same spelling.
##   See dna.kin in the registry.
## truth: an arrangement is a claim about the forces on a population, and it can only
##   claim what the container has left for it to claim.


# ═══════════════════════════════════════════════════════════════════════════
# THE FAMILY WORD — READ, NOT RETYPED — AND REFUSED AS AN AXIS, ON THE RECORD
# ═══════════════════════════════════════════════════════════════════════════
#
# `formation` names the five BAYS of this field. It is refused as this artifact's
# varying axis, and the refusal is the design.
#
# THE FIVE VALUES SIT SIDE BY SIDE, NOT NESTED, and that was read out of the members'
# CODE rather than their prose:
#
#   reactive_particle_field._calculate_grid_positions() opens with `match formation:`
#   in which "shell", "ring", "column" and "drift" each fill particle_targets and
#   RETURN, and `_:` falls through to the cubic-grid body below. Five mutually
#   exclusive exits from one switch.
#
#   rigid_sculpture._place_element() is the same shape: one `match formation:` whose
#   every branch assigns ONE position and ONE rotation to the element, `_:` being the
#   shipped ring.
#
#   DelaunayTriangulation3DCell._formation_points() likewise returns one site array,
#   handing "shell" and any unknown word straight back to generate_hierarchical_points().
#
# No value contains another; there is no all-at-once reading that is secretly the top
# rung. So the simultaneity is the object: hold all five standing and vary something
# else. An axis on the word would demolish four fifths of the exhibit at every turn,
# and the large number it produced would be a measurement of the field being taken down.
#
# WHY reactive_particle_field IS THE ONE PRELOADED. It carries four of the seven
# registry names on one scene, and its order (lattice first) is the order five of the
# six arrangement-vocabulary members declare. delaunay_triangulation_3d_cell rotates the
# same five words to put its own legacy value first, which is a default hoist, not a
# different vocabulary.
const FIELD_SRC := preload("res://commons/interfaces/qfep/reactive_particle_field.gd")

## The bays this field knows how to construct. NOT the vocabulary — the vocabulary is
## FIELD_SRC.FORMATIONS. This exists only so _check_family_list can push_error in BOTH
## directions when the two disagree.
const BUILDERS: PackedStringArray = ["lattice", "shell", "ring", "column", "drift"]


# ═══════════════════════════════════════════════════════════════════════════
# AXIS 1 — `vessel`: the container, which is the force nobody in the family names
# ═══════════════════════════════════════════════════════════════════════════
#
# Every member lays its formation inside a box and never varies the box. Five of the
# seven inherit reactive_particle_field's field_size of (2.0, 1.5, 2.0) — near-isotropic
# — and delaunay uses a cell_radius, which is a sphere. So the family's five claims have
# only ever been made in a container that applies no force of its own.
#
# That is the missing half of the argument. `lattice` says the positions are imposed
# from outside; `shell` says everything is pushed to a boundary; `ring` says there is one
# centre and one preferred radius; `column` says there is an axis; `drift` says there is
# no rule, only history. Each is a claim about a force — and a container is a force.
#
#   cube   0.340 x 0.340 x 0.340. Isotropic: the box asserts nothing, so whatever the
#          five arrangements differ by is theirs. THE DEFAULT, for that reason.
#   slab   0.482 x 0.169 x 0.482. The container has a plane. `column` loses its axis and
#          collapses into a knot (sigma_y 0.1019 m in the cube, 0.0506 m here — the box
#          is now the shorter of the two), and the shell stops being one radius
#          (sigma_r 0.0004 m -> 0.0420 m), because a flattened boundary is a boundary at
#          many radii.
#   shaft  0.279 x 0.506 x 0.279. The container has an axis, so every arrangement now
#          has one, and `column` is no longer saying anything the box has not said: the
#          drift's sigma_y is 0.1575 m against the column's 0.1516, so the SCATTER is
#          now the taller of the two.
#
# EQUAL VOLUME, NOT EQUAL EXTENT: 0.039304, 0.039263 and 0.039388 cubic metres, a spread
# of 0.318%. The three vessels differ in SHAPE and not in how much room they give, so a
# bay that looks emptier is not a bay with fewer bodies in it.
@export_enum("cube", "slab", "shaft") var vessel: String = "cube"

# ═══════════════════════════════════════════════════════════════════════════
# AXIS 2 — `summary`: how much of the population is summarised beside it
# ═══════════════════════════════════════════════════════════════════════════
#
# A strictly additive ladder — each rung keeps every mark the last one drew, in the same
# six slots — so this axis NESTS where `vessel` sits side by side. Every bar is read off
# ONE statistics array computed once per bay in _measure(), from the very positions the
# bodies were placed at.
#
#   none     the five arrangements bare. You can see that the bays differ. You cannot
#            say what any of them claims, and you cannot check it.
#   spread   four white bars per bay: sigma_x, sigma_y, sigma_z and sigma_r, in METRES,
#            ceiling 0.200 m fixed everywhere. This is the summary a physicist reaches
#            for first, and the finding is that IT CANNOT TELL A LATTICE FROM A DRIFT:
#            at the cube the two bays read 22.5/22.5/22.5/10.3 px against
#            22.3/25.8/21.9/12.8 px — the same rail, to within 3.3 px.
#   nearest  plus two orange bars: the mean nearest-neighbour distance (metres, ceiling
#            0.120 m) and its coefficient of variation (dimensionless, ceiling 0.60).
#            THE DEFAULT. The second bar is the one that sees order: it is 0.000 for the
#            lattice, the ring and the column BY CONSTRUCTION — every body in those three
#            has its neighbour at exactly the same distance as every other — 0.028 for
#            the shell's Fibonacci quasi-lattice, and 0.492 for the drift. At the cube
#            that is an empty socket beside a 39.9 px bar.
#
# ORDER OF THE VALUES IS LAW 15, NOT TASTE. build_dna_gallery trims a value list from the
# TAIL, so the ladder is declared default-first rather than in its reading order: a
# capped run keeps [nearest, none], which is the ladder's top rung against its floor and
# the most informative two-value truncation available. Declared [none, spread, nearest]
# it would have kept [none, spread] and thrown away the only rung that answers anything.
#
# WHY `nearest` AND NOT `spread`. A synthesis has no shipped placements, so the default
# is a free design choice and it was spent on the strongest single reading rather than
# the emptiest. `nearest` is the only rung where the whole finding is in ONE frame: the
# four white bars of the lattice bay and the drift bay agree, and the orange bar beside
# them does not. A visitor who meets only `spread` leaves believing those two bays hold
# the same thing; a visitor who meets only `none` cannot check anything at all.
#
# TWO GAUGES, TWO CEILINGS, BOTH FIXED ACROSS BOTH AXES, and that is why the orange bars
# are a different colour: they are not on the white bars' scale and must not be read
# against them. Normalising any of them per-vessel was rejected — a ceiling that moves
# with the tile is a frame-relative gauge, and it would have hidden the one thing the
# vessel axis is for, which is that a slab's spread genuinely is wider than a cube's.
@export_enum("nearest", "none", "spread") var summary: String = "nearest"


# ═══════════════════════════════════════════════════════════════════════════
# THE POPULATION — generated ONCE, in normalised coordinates, shared by five bays
# ═══════════════════════════════════════════════════════════════════════════
#
# 27 bodies, identical in size and shape, each carrying a fixed hue from its index so a
# reader can follow body 7 from bay to bay and see that it is the same population and not
# five populations. Same count, same bodies, same seed in all nine tiles: the arrangement
# is the only thing that changes.
#
# 27 AND NOT 100: the count is a perfect cube, so `lattice` is a complete and symmetric
# 3 x 3 x 3 rather than the family's truncated fill (reactive_particle_field asks for 100
# and lays a 5 x 5 x 5 grid, filling 100 of 125 slots, so its lattice is four fifths of a
# cube with a bite out of one corner). It is also what keeps the bodies apart: at 27 the
# tightest gap anywhere in the fifteen bays is 0.0292 m against a body diameter of
# 0.0280 m — the ring in the shaft, and it is the binding constraint on the whole layout.
#
# THE HASH IS THE CORPUS'S OWN, character for character from combine_sphere.gd and
# math_objects_gallery.gd. rigid_sculpture's per-index reseed of a RandomNumberGenerator
# is the FAMILY's determinism idiom and would have been the closer borrow, but its PCG32
# stream cannot be reproduced outside Godot — and reproducing this population in Python
# is what made it possible to predict the closest pair before any capture, which the
# promotion brief now requires. A hash of sin() agrees between GDScript and Python to the
# last bit, because both evaluate it in doubles.
const N: int = 27
const GOLDEN_ANGLE: float = 2.399963229728653

## Iterated when the apron is sized. A const PackedStringArray rather than an inline
## array literal so the loop variable is a String and not a Variant.
const VESSELS: PackedStringArray = ["cube", "slab", "shaft"]


# ═══════════════════════════════════════════════════════════════════════════
# THE FIELD — every dimension, and the arithmetic that fixed it
# ═══════════════════════════════════════════════════════════════════════════
#
# Z-STACK, front to back from the capture camera, because a frame is four rails and not
# a slab (operations_gallery's bezel enclosed every mark its axis drew and photographed
# as one blank plate):
#
#   z = +0.310 .. +0.275   apron, front lip. nothing stands here
#   z = +0.275 .. +0.225   THE GAUGE RAIL: sockets and bars, 0.050 deep. Nothing is in
#                          front of these, ever, at any vessel
#   z = +0.071 .. -0.471   the bay decks (the widest, slab; the cube's is +0.000 ..
#                          -0.400), top face at y 0.240
#   z = -0.200 +/- hz      the population, standing IN the vessel above that deck
#
# NOTHING OCCLUDES A BODY, and it is MEASURED rather than claimed: the three vessels were
# rasterised twice each, once with only the bodies and once complete, and of the 3914 /
# 3661 / 3888 pixels a body owns in the bare frame, the apron, the decks and the full
# six-bar rail change ZERO. The two numbers that make that true are the deck height and
# the rail distance. The tallest possible bar tops out at y 0.260 standing at z 0.250;
# the camera pitches 0.26 rad down and yaws 0.62, so screen-up = 0.9664*y - 0.1494*x -
# 0.2092*z and that bar top sits at 0.2241 minus its x term, while the LOWEST body in the
# widest vessel — the slab's front edge, y 0.254, z +0.041 — sits at 0.2369 minus its own.
# Clear, but only just: pulling the rail in to z 0.130 breaks the slab, and dropping the
# deck to 0.150 breaks all three.
const APRON_TOP: float = 0.030
const APRON_MARGIN: float = 0.040
const PLINTH_TOP: float = 0.240      ## the bay deck. Vessels stand here.
const PLINTH_MARGIN: float = 0.030   ## deck overhang beyond the vessel, per side
## Fixed for every vessel, so the population's centre never moves between tiles.
const PLINTH_CZ: float = -0.200
const BAY_PITCH: float = 0.600

## THE GAUGE, SIZED TO THE FRAME IT IS READ IN (law 4). At dna.framing 0.56 the sweep
## shows 3.4322 m across 760 px, which is 221.43 px per metre. The first cut of this rail
## used a 0.034 m bar on a 0.054 m slot — 7.5 px wide, at the edge of legibility for a
## visitor and under four samples once the critic downsamples its crop to 160 x 160. Now
## 0.072 m on a 0.084 m slot: 15.9 px wide, 18.6 px pitch. Six slots span 0.504 m, which
## clears the 0.600 m bay pitch by 0.096 m, and the outermost socket edge stands at
## x 1.432 inside the apron's 1.511.
##
## Rasterised both ways, this is also what lifts the `summary` axis's closest pair from
## 5.0% to 8.1% focus — over the critic's 6.0% twin bar. That is a consequence and not
## the reason: nothing about what the bars MEAN changed, only how wide the mark is, and
## a 7.5 px mark was already failing law 4 on its own.
const RAIL_Z: float = 0.250
const BAR_W: float = 0.072
const BAR_D: float = 0.050
## Six slots always: the rung ADDS marks, it never moves the four already standing.
const SLOT: float = 0.084
const SLOTS: int = 6
const BAR_MAX: float = 0.220
const SOCK_W: float = 0.082
const SOCK_H: float = 0.010
const SOCK_D: float = 0.058

## THE THREE CEILINGS. Fixed across every value of both axes — no bar anywhere is scaled
## to its own tile. Chosen to clear the largest reading in all fifteen bays without
## clipping any of them: largest sigma 0.1575 m (drift in the shaft), largest mean
## nearest-neighbour 0.1133 m (lattice in the cube), largest CV 0.5396 (drift, shaft).
const SPREAD_CEIL: float = 0.200
const NN_CEIL: float = 0.120
const CV_CEIL: float = 0.60

## A reading this small is under a tenth of a pixel and is drawn as an EMPTY SOCKET
## rather than a sliver, so a true zero is visible as a zero. Three readings are exactly
## 0.0000 by construction — the ring's sigma_y and sigma_r, and the CV of the lattice,
## the ring and the column — and the shell's sigma_r in the cube is 0.0004 m, a bar of
## 0.1 px. The socket is always drawn, so the slot is never merely absent.
const BAR_MIN: float = 0.0005

const BODY_R: float = 0.014          ## 0.0280 diameter = 6.2 px at the capture framing

## COLUMN: helix radius as a fraction of the vessel's half-width.
##
## NOT delaunay's girth, and the difference is measured. DelaunayTriangulation3DCell
## draws its column at cell_radius / 12 = 0.0833 of the radius; at 27 bodies on this
## helix that puts consecutive bodies 0.0170 m apart in the cube, 0.0167 in the slab and
## 0.0214 in the shaft, against a body DIAMETER of 0.0280 — every one of them
## interpenetrating. 0.12 and 0.18 also touch. 0.22 is the smallest of the values tried
## at which no two bodies overlap in any of the three vessels: the step is
## sqrt(chord^2 + dy^2) = sqrt(0.02862^2 + 0.01308^2) = 0.0315 m in the cube, 0.0411 in
## the slab and 0.0305 in the shaft. Delaunay's proportion is honest for its own artifact
## because its sites are 0.08 m spheres in a much larger ball; it is not transferable.
const COL_R: float = 0.22

const COL_APRON := Color(0.30, 0.30, 0.32)
const COL_PLINTH := Color(0.42, 0.42, 0.45)
const COL_SOCKET := Color(0.19, 0.19, 0.21)
const COL_SPREAD := Color(0.86, 0.86, 0.88)
const COL_NEAR := Color(0.98, 0.60, 0.22)

var _built: bool = false
var _bays: PackedStringArray = PackedStringArray()


# ═══════════════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_read_grid_config_meta()
	vessel = vessel if _is_vessel(vessel) else "cube"
	summary = summary if _is_summary(summary) else "nearest"
	_bays = _family_formations()
	_check_family_list()
	_build()
	_built = true


## The grid stamps `config_*` metadata BEFORE add_child, so this runs ahead of the build.
## No metadata, no change. An unrecognised word keeps the standing value rather than
## emptying the field — an axis must never be able to blank an artifact by typo.
func _read_grid_config_meta() -> void:
	var n: Node = self
	var hops: int = 0
	while n != null and hops < 4:
		if n.has_meta("config_vessel"):
			var v: String = str(n.get_meta("config_vessel")).strip_edges().to_lower()
			if _is_vessel(v):
				vessel = v
		if n.has_meta("config_summary"):
			var s: String = str(n.get_meta("config_summary")).strip_edges().to_lower()
			if _is_summary(s):
				summary = s
		n = n.get_parent()
		hops += 1


## Rebuilds ONLY when a value actually changed AND _ready has already built once — the
## force_pad fault, which tore down every child and re-ran _ready on any call at all,
## including calls naming nothing it owned.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false
	if config_data.has("vessel"):
		var v: String = str(config_data["vessel"]).strip_edges().to_lower()
		if _is_vessel(v) and v != vessel:
			vessel = v
			changed = true
	if config_data.has("summary"):
		var s: String = str(config_data["summary"]).strip_edges().to_lower()
		if _is_summary(s) and s != summary:
			summary = s
			changed = true
	if changed and _built:
		_build()


func _is_vessel(v: String) -> bool:
	return v == "cube" or v == "slab" or v == "shaft"


func _is_summary(v: String) -> bool:
	return v == "none" or v == "spread" or v == "nearest"


## The family's list, read live off the preload.
##
## READ THE CONST DIRECTLY. Object.get() would return null — a const is not a property —
## and this field would quietly fall back to its own copy, which is the exact drift the
## preload exists to prevent. get_script_constant_map() was tried and does NOT parse: it
## is a non-static method and cannot be called on the class, only on an instance.
## FIELD_SRC.FORMATIONS has the better failure mode than either, because if
## reactive_particle_field ever drops the const this file stops PARSING rather than
## falling back at runtime, and the compile gate says so on the spot.
func _family_formations() -> PackedStringArray:
	var src: Variant = FIELD_SRC.FORMATIONS
	if src is PackedStringArray and (src as PackedStringArray).size() > 0:
		return src as PackedStringArray
	push_error("formation_field: reactive_particle_field.gd no longer exposes FORMATIONS; " +
		"falling back to this field's own builder list, which may have drifted from the family.")
	return BUILDERS


## BOTH DIRECTIONS: a word the family declares that this field has no bay for, and a bay
## this field builds that the family has dropped.
func _check_family_list() -> void:
	for w in _bays:
		if not BUILDERS.has(w):
			push_error("formation_field: the family declares '%s' and this field has no bay for it." % w)
	for b in BUILDERS:
		if not _bays.has(b):
			push_error("formation_field: this field builds '%s' and the family no longer declares it." % b)


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

	# ONE POPULATION, MADE ONCE, handed to every bay.
	var pop: Array[Vector3] = _population()

	var size: Vector3 = _vessel_size(vessel)
	var half: Vector3 = size * 0.5
	var pw: float = size.x + 2.0 * PLINTH_MARGIN
	var pd: float = size.z + 2.0 * PLINTH_MARGIN
	var n: int = _bays.size()

	# The apron is sized for the WIDEST vessel and never changes, so the hall is the
	# constant and the vessel is the variable. A slab tile is not a bigger photograph.
	var max_w: float = 0.0
	var max_d: float = 0.0
	for v in VESSELS:
		max_w = maxf(max_w, _vessel_size(v).x + 2.0 * PLINTH_MARGIN)
		max_d = maxf(max_d, _vessel_size(v).z + 2.0 * PLINTH_MARGIN)
	var ax: float = float(n - 1) * 0.5 * BAY_PITCH + max_w * 0.5 + APRON_MARGIN
	var az0: float = PLINTH_CZ - max_d * 0.5 - APRON_MARGIN
	var az1: float = RAIL_Z + BAR_D * 0.5 + 0.035
	_slab("Apron", Vector3(ax * 2.0, APRON_TOP, az1 - az0),
		Vector3(0.0, APRON_TOP * 0.5, (az0 + az1) * 0.5), COL_APRON, self)

	for b in range(n):
		var word: String = _bays[b]
		var bx: float = (float(b) - float(n - 1) * 0.5) * BAY_PITCH
		var bay := Node3D.new()
		bay.name = "Bay_" + word
		add_child(bay)
		_slab("Deck", Vector3(pw, PLINTH_TOP - APRON_TOP, pd),
			Vector3(bx, (APRON_TOP + PLINTH_TOP) * 0.5, PLINTH_CZ), COL_PLINTH, bay)

		# ONE COPY OF THE ARITHMETIC: the bodies are placed from `pts`, and every bar is
		# measured from that same `pts`. There is no second table of numbers to fall out
		# of step with where the bodies actually are.
		var pts: Array[Vector3] = _seats(word, pop, bx, half)
		for i in range(N):
			var mi := MeshInstance3D.new()
			mi.name = "Body_%d" % i
			var sm := SphereMesh.new()
			sm.radius = BODY_R
			sm.height = BODY_R * 2.0
			sm.radial_segments = 12
			sm.rings = 6
			mi.mesh = sm
			mi.material_override = _matte(Color.from_hsv(float(i) / float(N), 0.55, 0.86))
			mi.position = pts[i]
			bay.add_child(mi)

		if summary == "none":
			continue
		var bars: Array[float] = _measure(pts)
		var drawn: int = 4 if summary == "spread" else SLOTS
		for k in range(drawn):
			var cx: float = bx + (float(k) - float(SLOTS - 1) * 0.5) * SLOT
			_slab("Socket_%d" % k, Vector3(SOCK_W, SOCK_H, SOCK_D),
				Vector3(cx, APRON_TOP + SOCK_H * 0.5, RAIL_Z), COL_SOCKET, bay)
			var h: float = bars[k]
			if h <= BAR_MIN:
				continue
			_slab("Bar_%d" % k, Vector3(BAR_W, h, BAR_D),
				Vector3(cx, APRON_TOP + SOCK_H + h * 0.5, RAIL_Z),
				COL_NEAR if k >= 4 else COL_SPREAD, bay)


# ═══════════════════════════════════════════════════════════════════════════
# THE POPULATION AND THE FIVE ARRANGEMENTS
# ═══════════════════════════════════════════════════════════════════════════

## Deterministic 0..1 from an integer. No randf, no randi, no randomize, no seed to pin:
## there is no generator in this file at all.
func _hash01(n: int) -> float:
	var s: float = sin(float(n) * 12.9898 + 78.233) * 43758.5453
	return s - floor(s)


## The one population, in normalised [-1,1]^3 — which is exactly the box
## reactive_particle_field scatters its own units in (randf_range(-field_size/2,
## +field_size/2) on each axis).
func _population() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for i in range(N):
		out.append(Vector3(
			2.0 * _hash01(3 * i) - 1.0,
			2.0 * _hash01(3 * i + 1) - 1.0,
			2.0 * _hash01(3 * i + 2) - 1.0))
	return out


func _vessel_size(v: String) -> Vector3:
	match v:
		"slab":
			return Vector3(0.482, 0.169, 0.482)
		"shaft":
			return Vector3(0.279, 0.506, 0.279)
		_:
			return Vector3(0.340, 0.340, 0.340)


## Where the bodies stand: the arrangement's normalised targets, scaled by the vessel and
## seated on the bay's deck.
func _seats(word: String, pop: Array[Vector3], bx: float, half: Vector3) -> Array[Vector3]:
	var t: Array[Vector3] = _targets(word, pop)
	var cy: float = PLINTH_TOP + BODY_R + half.y
	var out: Array[Vector3] = []
	for i in range(N):
		out.append(Vector3(bx + t[i].x * half.x, cy + t[i].y * half.y, PLINTH_CZ + t[i].z * half.z))
	return out


## THE FIVE ARRANGEMENTS, in the family's own formulas, in normalised [-1,1] space.
##
## `lattice`, `shell` and `ring` are reactive_particle_field's, line for line, with
## field_size expressed as its own half-extents: its lattice spacing is size/grid and its
## first slot (u - grid/2 + 0.5)*spacing, which at grid 3 is exactly (u-1)*2/3; its shell
## is the same Fibonacci sphere with the same golden angle; its ring is the same
## TAU*i/count at 0.45*size, which is 0.9 of a half-extent. `drift` is its
## `_targets_drift` — each unit's target is where it already is, so the drift bay IS the
## population, unmoved, and history is the only thing arranging it.
##
## `column` IS THE ONE PLACE THE FAMILY DISAGREES WITH ITSELF, and this field takes the
## majority. rigid_sculpture stacks its elements ON the Y axis at x = z = 0 under a fixed
## quarter-turn screw, and delaunay's own comment calls its value "a narrow shaft up Y,
## full height" — two members reading `column` as A SHAFT. reactive_particle_field instead
## lays five plates of twenty at 0.72 of the box, which is STRATA — and strata at this
## count are a lattice: a 3 x 3 x 3 grid IS three stacked plates of nine, so that reading
## would have made two of the five bays the same picture. So the shaft wins: a helix
## turned a quarter-turn per body, which is rigid_sculpture's screw given the only radius
## at which 27 bodies of this size do not interpenetrate (see COL_R). The degeneracy in
## the strata reading is a finding about the vocabulary, not a bug to hide; it is recorded
## in dna.note.
func _targets(word: String, pop: Array[Vector3]) -> Array[Vector3]:
	var out: Array[Vector3] = []
	match word:
		"shell":
			for i in range(N):
				var t: float = (float(i) + 0.5) / float(N)
				var yy: float = 1.0 - 2.0 * t
				var rad: float = sqrt(maxf(0.0, 1.0 - yy * yy))
				var th: float = GOLDEN_ANGLE * float(i)
				out.append(Vector3(cos(th) * rad, yy, sin(th) * rad))
		"ring":
			for i in range(N):
				var a: float = TAU * float(i) / float(N)
				out.append(Vector3(cos(a) * 0.9, 0.0, sin(a) * 0.9))
		"column":
			for i in range(N):
				var th2: float = float(i) * PI * 0.25
				out.append(Vector3(cos(th2) * COL_R,
					(float(i) / float(N - 1)) * 2.0 - 1.0, sin(th2) * COL_R))
		"drift":
			for i in range(N):
				out.append(pop[i])
		"lattice":
			out = _lattice()
		_:
			push_error("formation_field: no bay builder for '%s'; standing a lattice." % word)
			out = _lattice()
	return out


func _lattice() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for i in range(N):
		var gx: int = i / 9
		var gy: int = (i / 3) % 3
		var gz: int = i % 3
		out.append(Vector3(float(gx - 1), float(gy - 1), float(gz - 1)) * (2.0 / 3.0))
	return out


# ═══════════════════════════════════════════════════════════════════════════
# THE SUMMARY — six numbers, measured off the bodies themselves
# ═══════════════════════════════════════════════════════════════════════════

## Six bar HEIGHTS in metres, from the population's own world positions.
##
## COUNT THE THING YOU CLAIM TO COUNT. Each of these is the plain definition and not a
## proxy: sigma_x/y/z are the population standard deviations about its own centroid,
## sigma_r the standard deviation of the distance from that centroid, and the last two
## the mean nearest-neighbour distance and ITS coefficient of variation. The CV and not
## the raw spread of neighbour distances, because an absolute spread shrinks with the
## container and would report a flat vessel as more ordered than a cube; the CV is
## dimensionless and says only what it means, which is whether there is a rule.
##
## The first four are what a second-moment summary sees, and a lattice and a uniform
## scatter of the same 27 bodies are INDISTINGUISHABLE to it. The last one is what sees
## order: it is exactly 0 for any arrangement whose every body has its neighbour at the
## same distance — the lattice, the ring and the helix — and 0.49 for the drift.
func _measure(pts: Array[Vector3]) -> Array[float]:
	var c := Vector3.ZERO
	for p in pts:
		c += p
	c /= float(N)
	var v := Vector3.ZERO
	var mr: float = 0.0
	for p in pts:
		var d: Vector3 = p - c
		v += Vector3(d.x * d.x, d.y * d.y, d.z * d.z)
		mr += d.length()
	v /= float(N)
	mr /= float(N)
	var vr: float = 0.0
	for p in pts:
		var e: float = (p - c).length() - mr
		vr += e * e
	vr /= float(N)

	var nn: Array[float] = []
	var mn: float = 0.0
	for i in range(N):
		var best: float = INF
		for j in range(N):
			if j == i:
				continue
			best = minf(best, pts[i].distance_to(pts[j]))
		nn.append(best)
		mn += best
	mn /= float(N)
	var vn: float = 0.0
	for d2 in nn:
		vn += (d2 - mn) * (d2 - mn)
	vn /= float(N)
	var cv: float = (sqrt(vn) / mn) if mn > 0.0 else 0.0

	# Appended into a TYPED local rather than returned as an array literal. An untyped
	# `[a, b, c]` literal returned from a function declared `-> Array[float]` is a
	# construct with no committed precedent anywhere in this repository, and this file
	# cannot be run before it ships (captures are serialised centrally), so the one
	# idiom the corpus uses everywhere is the one used here.
	var out: Array[float] = []
	out.append(minf(sqrt(v.x) / SPREAD_CEIL, 1.0) * BAR_MAX)
	out.append(minf(sqrt(v.y) / SPREAD_CEIL, 1.0) * BAR_MAX)
	out.append(minf(sqrt(v.z) / SPREAD_CEIL, 1.0) * BAR_MAX)
	out.append(minf(sqrt(vr) / SPREAD_CEIL, 1.0) * BAR_MAX)
	out.append(minf(mn / NN_CEIL, 1.0) * BAR_MAX)
	out.append(minf(cv / CV_CEIL, 1.0) * BAR_MAX)
	return out


# ═══════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════

func _slab(nm: String, size: Vector3, centre: Vector3, col: Color, host: Node) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _matte(col)
	mi.position = centre
	host.add_child(mi)
	return mi


func _matte(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = 0.0
	m.roughness = 0.62
	return m
