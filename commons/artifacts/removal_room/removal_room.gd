extends Node3D
class_name RemovalRoom

## Removal Room — a SYNTHESIS artifact. One cut, kept three ways, in a row.
##
## @identity
## essence: Three registers on one shell, each holding the SAME single subtraction
##   under a different account of what it left — gone, ghost, scar. The word six
##   artifacts each stand inside one value of, laid out as the comparison it never
##   got to be.
## desire: To be read left to right and then disbelieved. `gone` is what the
##   mathematics says. `ghost` is legible and false. `scar` is true about the
##   cutting and silent about both states. Nothing here is the honest one.
## critical_parameter: `subtraction` — WHICH rule made the hole. The three accounts
##   never move and never change their order; only the cut underneath them.
## triggers: none. Nothing animates, nothing is picked up, nothing is random. The
##   room is the standing record, which is the only part of this family a still
##   photograph was ever able to hold.
## emerges: the row would not fit. Three CELL cubes project 1.394920 m of screen
##   width each at the sweep's yaw and sat 0.927823 m apart, so each register hid
##   23.1% of its neighbour's footprint and the three photographed as one block.
##   Nothing in the drawing was wrong; the SPACING was. PITCH is now 1.75, which is
##   1.714 x CELL, the ratio at which a cube stops standing in front of the cube
##   behind it.
## needs: one cut computed once [has, _run]; three registers differing in nothing
##   but the account [has]; a ground that is fair to a pale mark AND a dark one
##   [has, 0.20042]; three registers that do not stand in each other's light
##   [has, PITCH/CELL = 1.75]; no random number anywhere [has]
## relationships: Synthesised from the six artifacts that declare `removal` — see
##   the registry block. The exact complement of [[retention_corridor]], which asks
##   what a MARK KEEPS where this asks what a CUT LEAVES.
## truth: A subtraction has no preferred record. Draw nothing and you have told the
##   truth about the set and lost the operation; draw the offcut and you have the
##   operation and a solid that the definition denies; draw the wound and you have
##   neither state, only the fact that somebody cut. The family has been choosing
##   one of these six times without ever having to say it was choosing.

# ═══════════════════════════════════════════════════════════════════════════
# SYNTHESIS DNA — `subtraction`
# ═══════════════════════════════════════════════════════════════════════════
#
# BORN PROMOTED. This artifact did not exist before the batches that promoted its
# sources. It is the comparison those batches left in six registry notes, built as
# a body.
#
# WHAT IT IS. A shell 5.35 m wide with three registers standing on it, left to
# right in the order all six members declare them:
#
#   gone    the survivors, and nothing where the rule cut. The shipped silence of
#           every one of the six, and the only account the mathematics endorses:
#           the removed part was never made
#   ghost   the survivors, plus every removed cell restored as a pale full-size
#           volume at alpha 0.16. The operation becomes legible and the object
#           becomes a lie about its own definition — at `cross`, `gasket` and
#           `figure` the ghost register is EXACTLY the original solid again
#   scar    the survivors, plus a dark core at 0.22 of the cell where each cell
#           used to be. Neither the part nor its absence: the wound. A fact about
#           the cutting rather than about either state
#
# `removal` IS REFUSED AS THIS ARTIFACT'S AXIS, on the record, and the ruling is
# retention_corridor's. Each of the six members uses the word to stand in ONE
# account and forgo the other two; on this shell all three stand at once, and that
# simultaneity is the whole object. An axis whose every value demolishes two
# thirds of the exhibit is not a variation of it.
#
# LAW 2 — NEST OR SIDE BY SIDE, answered from the members' CODE and not their
# prose. By EXTENT the three values nest: cantor_set._spawn_removed draws nothing,
# then a box at 0.22 of the section, then a box at 1.0 of it, so the drawn set is
# empty ⊂ scar ⊂ ghost, and a scar cube is 0.22^3 = 1.065% of its own ghost's
# volume. By MATERIAL and by CLAIM they are parallel: ghost is
# Color(0.86,0.88,0.96,0.16) unshaded with TRANSPARENCY_ALPHA, scar is
# Color(0.09,0.09,0.11) matte and opaque, and one says "the part was here, this
# big" while the other says "somebody cut here". The case is therefore MIXED, and
# it decides the shape of the room: because ghost passes 84% of what is behind it,
# a stacked all-at-once frame would show ghost's translucent shell WITH scar's dark
# core inside it and read as a single fourth value — three claims collapsed into
# one object. Side by side is the only arrangement in which the three stay three.
#
# `subtraction` IS THE FAMILY'S OWN CENSUS OF CUTS, plus one from its border. All
# six members were read; four scenes and three rules came out of them:
#
#   cross    menger_sponge — 27 cells, remove the 6 face centres and the body
#            centre. The removed set is an axial CROSS, and the 27 cells partition
#            the parent exactly, which is the precondition the whole family runs on
#   third    cantor_set, example_8_4_cantor_set_vr, and its two aliases
#            fractal_cantor_set and test_scene_3 — a span into thirds, the middle
#            deleted. FOUR OF THE SIX TOKENS. Drawn as cantor_set draws it, one row
#            per level, so this is the only value whose register is a HISTORY
#   figure   recursive_chair — 27 cells, remove 11, ONCE, and what is left is a
#            named object rather than a fractal. The one member of a family of
#            fractals of subtraction whose subtraction does not recurse
#   gasket   NOT A MEMBER, and declared as such. sierpinski_triangle asks this
#            family's exact question under a rival word — `excision`, five values,
#            absence | ghost | rubble | cast | negative — and its medial triangle
#            is a real disjoint complement. It is here so the room can hold the two
#            vocabularies against one cut instead of leaving them in two registries
#
# 4 + 1 + 1 = 6 for the three member values, and the fourth is named as an import.
# sierpinski_pyramid, which REFUSED `removal` because its five children's bounding
# volumes interpenetrate and there is no complement to draw, is deliberately NOT a
# value: at that cut ghost and scar would have nothing to draw and the register row
# would collapse to three copies of `gone`.
#
# WHY THAT DECLARED ORDER — cross, third, gasket, figure. build_dna_gallery trims
# value lists from the TAIL, so the default goes first and the rest run in
# DESCENDING separation from it. `figure` is last because it is the value nearest
# the default: cross and figure are the same 3x3x3 lattice in the same cube and
# agree on 13 of its 27 cells, which is why they are the predicted closest pair.
#
# ONE CUT, EVALUATED ONCE. _run() fills _keep_p/_keep_s and _cut_p/_cut_s at build
# time and all three registers read those four arrays. Nothing on this shell
# re-derives the cut, so there is nothing here that can drift out of agreement with
# anything else here. That is evidence_ladder's rule taken as a construction
# constraint rather than quoted.
#
# ── LAW 7, AND IT REBUILT THE ROOM THREE TIMES ─────────────────────────────
#
# The sweep camera stands at yaw 0.62, pitch -0.26. Write cy = cos(0.62) = 0.81388
# and sy = sin(0.62) = 0.58104. A point (x, y, z) then lands at
#
#     screen-x = cy*x - sy*z          depth = sy*x + cy*z   (larger = nearer)
#
# and a thing of depth d eats sy*d = 0.581 d of horizontal daylight while a gap of
# width g projects to only cy*g = 0.814 g. Four separate things in this room were
# standing in front of marks. Each was found by that arithmetic and then confirmed
# by rasterising the four values in Python at the sweep's own 760 px.
#
# (1) THE REGISTERS WERE STANDING IN EACH OTHER'S LIGHT, and this is the one that
#     rebuilt the shell. A CELL cube projects cy*CELL + sy*CELL = 1.394920 m of
#     screen width. At the first PITCH of 1.14 the register centres were cy*1.14 =
#     0.927823 m apart, so consecutive cubes OVERLAPPED by 0.467097 m — 33.5% of a
#     register's screen width. Of the middle register's 1 m2 footprint the part
#     hidden by its right-hand neighbour is {screen-x >= 0.230396}, a triangle of
#     area 0.230650 m2 = 23.1%, and 70% of its right-hand face. Rendered, the three
#     cubes merged into a single continuous block and the row stopped being a row.
#     PITCH must be at least 1.394920 / cy = 1.714 x CELL; it is 1.75 x CELL, which
#     leaves 0.029 m = 3.7 px of daylight between registers and zero occlusion.
#     THE COST IS PAID IN LEVELS, below, and it is paid knowingly.
#
# (2) THE PILASTERS. A 0.10 m fin standing 0.93 m deep casts a screen silhouette
#     sy*0.93 + cy*0.10 = 0.621 m wide — six times its own thickness. With its
#     front face at +0.30 that silhouette began at screen-x 0.248906 while a FLAT
#     register's marks reach cy*0.5 = 0.406940, so the right 0.158 m, 19.4% of the
#     width of `third` and of `gasket`, stood behind a pilaster. FIN_FRONT is now
#     -0.30: the fin's silhouette begins at 0.845690, clear of even the DEEP
#     registers' 0.697450 by 0.148 m.
#
# (3) THE LINTEL. The ray from a register's top-back corner (y 1.40, z -0.5) to the
#     camera rises 0.25708/0.78652 = 0.326857 in y per unit z. It crosses the lintel
#     soffit at y 1.50 when z = -0.194 and the lintel head at y 1.60 when z = +0.112,
#     so with the lintel front at +0.30 the whole of that interval lay inside it: a
#     wedge 0.1664 m deep at the back plane, 0.040800 m2 = 4.1% of the register's
#     side profile. The lintel and cornice now stop at -0.30 with the fins, where
#     the ray is 34.6 mm under the soffit as it leaves them.
#
# (4) THE GROUND PANEL DOES NOT REACH THE LEFT END, and this one is reported rather
#     than fixed. The wall sits 0.605 m behind the marks, which shifts its silhouette
#     sy*0.605 = 0.351529 m to screen-right, so its left edge lands at screen-x
#     -1.825600 while the leftmost marks reach -2.121750. The unbacked wedge is
#     0.092733 m2 = 9.3% of that register's footprint at the two DEEP values and
#     0.7 px at the two flat ones. Closing it needs 0.351529/cy = 0.432 m of extra
#     wall on the LEFT only, which is a camera-shaped shell and not a shell. It is
#     tolerable because of WHERE it falls: the leftmost register is `gone`, the one
#     account that draws neither a ghost nor a scar, so the computed ground below —
#     which exists to hold a pale mark and a dark one at equal distance — is not
#     touched by it. The middle and right registers are backed edge to edge.
#
# ── LEVELS ARE A CONSTANT PER VALUE, AND `tick` IS REFUSED AS A SECOND AXIS ──
#
# The union box is 5.41 x 1.64 x 1.145, so radius = 2.883952 and at dna.framing 0.55
# the camera stands 9.8575 m out, the visible frame is 6.027457 m and a 760 px still
# is 126.09 px per metre. Every mark in the room was gauged against that number:
#
#   cross   1 level.  scar = 0.22 * CELL/3    = 0.073333 m =  9.25 px
#   third   2 levels. scar = 0.22 * SEC_Y     = 0.035200 m =  4.44 px  (thinnest)
#   gasket  2 levels. scar = 0.22 * 0.25      = 0.055000 m =  6.93 px
#   figure  1 level.  scar = 0.22 * CELL/3    = 0.073333 m =  9.25 px
#
# THE ROOM CANNOT AFFORD MENGER'S OWN SHIPPED RUNG, and the arithmetic says so
# rather than taste. menger_sponge ships max_iterations 2. A second rung here puts
# the scar at 0.22 * CELL/9 = 0.024444 m = 3.08 px, inside the 1-3 px band law 4
# exists because of — and it is not a framing that can be tightened away, because
# the number is scale-free: three non-overlapping registers make the shell 5.4 x
# CELL wide whatever CELL is, so a cell is always about a fifth of the frame and a
# level-2 scar is always about 2.44% of a fifth. `once` is a rung menger_sponge
# itself declares, so rung 1 takes the family's ladder honestly instead of inventing
# a level. Rung 3 of `gasket` was dropped for the same reason (3.47 x 3.00 px) and
# `figure` cannot take a rung at all — recursive_chair subdivides ONCE and then
# deforms, so three rungs there would be three byte-identical frames. Crossing a
# depth ladder with this axis would therefore have shipped, for two of four values,
# rungs that exist in the enum and cannot be built.
#
# LAW 7 INSIDE A REGISTER, which is where the sections come from. `third` at two
# levels has a finest gap of CELL/9 = 0.111111 m; it projects to 0.090434 m and a
# section 0.06 deep eats 0.034862 m of it, leaving 0.055572 m = 7.01 px of daylight.
# cantor_set's own bar is square in section because a 9 m bar can afford to be — a
# square 0.16 section here would eat 0.092966 m and close a 0.090434 m gap
# completely, so the section is anisotropic: 0.16 tall, which is what carries the
# 4.44 px scar, and 0.06 deep, which is what keeps the holes open. `gasket` at two
# levels has a finest hole 0.25 wide projecting to 0.203470 m; sierpinski_triangle
# extrudes its relief per level and at its own 0.14 that would eat 0.081346 m, so
# the room draws the cut flat at 0.05 and leaves 0.174418 m = 21.99 px. `cross` at
# one level shows a face-centre recess 0.333333 wide, projecting to 0.271293 m
# against a neighbouring cell 0.333333 deep eating 0.193680 m: 0.077613 m = 9.79 px
# of daylight still open.
#
# THE GROUND IS COMPUTED, NOT PICKED, and it is the one thing this room can do for
# the family without touching the family's recipes. ghost is unshaded pale (Rec.709
# luminance 0.881524) at alpha 0.16; scar is matte dark (0.091444). Against a ground
# of luminance g the ghost composites to 0.16 * 0.881524 + 0.84 g and the scar sits
# at 0.091444, so the two marks are equally far from their ground when
#
#     0.1410438 - 0.16 g = g - 0.091444   →   g = 0.2004205,  |Δ| = 0.1089765
#
# Every member so far has drawn both marks against whatever darkness its map
# happened to supply, and dark grounds favour the pale mark. C_GROUND is that grey.
#
# Fully deterministic. Not one call to randf, randi or randomize, no _process, no
# timer, no physics; every build of a given value is the same object down to the
# vertex.
#
# Usage in map_data.json:
#   "removal_room"                        — the cross
#   "removal_room#subtraction:third"
#   "removal_room#subtraction:gasket"
#   "removal_room#subtraction:figure"

## cantor_set is the ORIGIN of `removal` (promoted 2026-08-03) and owns the value
## list. Preloaded rather than retyped so the two cannot drift: if that file's
## REMOVALS ever changes or disappears, this line fails at PARSE time, which is a
## better failure mode than a room quietly exhibiting a stale vocabulary.
const CANTOR := preload("res://algorithms/fractals/cantorset/cantor_set.gd")

## The three accounts, left to right. Exhibited, never turned. Checked against
## CANTOR.REMOVALS in BOTH directions at _ready.
const REGISTERS: PackedStringArray = ["gone", "ghost", "scar"]

## THE AXIS — which rule made the hole. Default is the strongest single reading,
## not the emptiest: see dna.default.
@export_enum("cross", "third", "gasket", "figure") var subtraction: String = "cross"

## Allow-list. Checked against the @export_enum hint above in BOTH directions at
## _ready, by reading the hint back out of get_property_list() — an @export_enum
## literal cannot be derived from a const, so the only defence against the two
## drifting is to compare them at run time and shout.
const SUBTRACTIONS: PackedStringArray = ["cross", "third", "gasket", "figure"]

# ── the shell ────────────────────────────────────────────────────────────
const N_REG: int = 3
const CELL: float = 1.00              ## the cube every cut is drawn inside
## Register to register. NOT a style number: a CELL cube projects
## cos(0.62)*CELL + sin(0.62)*CELL = 1.394920 m of screen width and register centres
## are cos(0.62)*PITCH apart, so anything under 1.714 * CELL makes each register
## stand in front of the next. See LAW 7 (1) in the header.
const PITCH: float = 1.75
const FIN_W: float = 0.10             ## the pilaster between two registers
const SILL_Y: float = 0.40            ## plinth top, world
const PANEL_H: float = 1.10           ## the ground panel behind a register
const BACK_Z: float = -0.58           ## the panel's front face
const WALL_T: float = 0.05
## How far the fins, the lintel and the cornice stand proud of the drawing plane.
## NEGATIVE, and that is the fix for LAW 7 (2) and (3): everything structural
## returns BEHIND the marks, and only the plinth comes forward.
const FIN_FRONT: float = -0.30
const PLINTH_FRONT: float = 0.50
const LINTEL_H: float = 0.10
const CORNICE_H: float = 0.04
const CORNICE_OVER: float = 0.03
## 1.75 * 3 + 0.10 = 5.35. Written as a binary arithmetic expression over the two
## constants it comes from and NOT as float(N_REG) * PITCH: a numeric operator on
## two constants folds, and a type-constructor call in a constant expression is the
## trap law 16 records for PackedVector2Array. Nothing in the corpus does it, so
## this file was not going to be the first.
const SHELL_W: float = PITCH * N_REG + FIN_W               ## 5.35
const BAY_CY: float = SILL_Y + CELL * 0.5                  ## 0.90

# ── the cuts ─────────────────────────────────────────────────────────────
## Menger's deleted indices in a 3x3x3 addressed x + 3y + 9z: the six face centres
## and the body centre. menger_sponge's keep_positions table, read as its
## complement so the seven are stated once rather than inferred from twenty.
const MENGER_CUT: PackedInt32Array = [4, 10, 12, 13, 14, 16, 22]

## Depth per value, a CONSTANT and not an axis — see the header. The number after
## each is the width in px of that value's finest scar at 126.09 px per metre,
## which is what chose it.
const LEVELS := {
	"cross": 1,      # 9.25 px — rung 2 would be 3.08 px, inside law 4's band
	"third": 2,      # 4.44 px, and rung 3 closes its own gaps (law 7, header)
	"gasket": 2,     # 6.93 px — rung 3 would be 3.47 x 3.00 px
	"figure": 1,     # 9.25 px — recursive_chair subdivides once and stops
}

## cantor_set's bar is square in section because a 9 m bar can afford to be. At
## CELL = 1.00 a square 0.16 section eats 92.97 mm of a 90.43 mm gap, so the section
## here is anisotropic: tall enough for a 0.22 scar to reach 4.44 px, shallow enough
## to leave 55.57 mm of daylight between two thirds.
const CANTOR_SEC_Y: float = 0.16
const CANTOR_SEC_Z: float = 0.06
## sierpinski_triangle extrudes its relief per level; at 0.14 that would eat 81.3 mm
## of a 203.5 mm hole at this yaw. Flat at 0.05 it eats 29.1 mm.
const GASKET_DEPTH: float = 0.05

## cantor_set._spawn_removed, character for character.
const SCAR_RATIO: float = 0.22
const C_GHOST := Color(0.86, 0.88, 0.96, 0.16)
const C_SCAR := Color(0.09, 0.09, 0.11)

## The computed ground — the grey at which the family's ghost and its scar are
## equally far from what they stand on. Arithmetic in the header.
const C_GROUND := Color(0.20042, 0.20042, 0.20042)
const C_SURV := Color(0.62, 0.55, 0.46)
const C_STONE := Color(0.30, 0.29, 0.30)
const C_FIN := Color(0.255, 0.247, 0.255)
const C_CHALK := Color(0.88, 0.90, 0.95)

var _root: Node3D = null
var _built: bool = false

## THE ONE CUT. Filled once in _run(), read by all three registers and by nothing
## else. Positions are register-local, centred on the CELL cube.
var _keep_p: PackedVector3Array = PackedVector3Array()
var _keep_s: PackedVector3Array = PackedVector3Array()
var _cut_p: PackedVector3Array = PackedVector3Array()
var _cut_s: PackedVector3Array = PackedVector3Array()
## `gasket` is the one cut whose atoms are triangles; its removed medial triangle
## is the same prism turned through PI about z.
var _prism: bool = false


func _ready() -> void:
	_check_vocabularies()
	_read_grid_config_meta()
	_rebuild()
	_built = true


## LAW 1, BOTH DIRECTIONS, at run time, because neither list can be derived from
## the other at parse time. REGISTERS must be cantor_set's REMOVALS exactly, and
## SUBTRACTIONS must be the @export_enum hint exactly. A push_error here means the
## room is exhibiting a vocabulary that is no longer the family's.
func _check_vocabularies() -> void:
	var owner_list: Array = CANTOR.REMOVALS
	for word in REGISTERS:
		if not owner_list.has(word):
			push_error("RemovalRoom: '%s' is not in cantor_set.REMOVALS %s" % [word, str(owner_list)])
	for word2 in owner_list:
		if not REGISTERS.has(str(word2)):
			push_error("RemovalRoom: cantor_set declares '%s' and this room has no register for it" % str(word2))
	var hint: String = ""
	for p in get_property_list():
		if str(p.get("name", "")) == "subtraction":
			hint = str(p.get("hint_string", ""))
	var declared: PackedStringArray = hint.split(",", false)
	for word3 in declared:
		if not SUBTRACTIONS.has(word3):
			push_error("RemovalRoom: export declares '%s', SUBTRACTIONS does not" % word3)
	for word4 in SUBTRACTIONS:
		if not declared.has(word4):
			push_error("RemovalRoom: SUBTRACTIONS has '%s', the export hint does not" % word4)


# ═══════════════════════════════════════════════════════════════════════════
# THE CUT — one rule per value, and the only place each is written
# ═══════════════════════════════════════════════════════════════════════════

## Fill the four arrays once. Every register reads them; nothing re-derives a cut.
func _run() -> void:
	_keep_p.clear()
	_keep_s.clear()
	_cut_p.clear()
	_cut_s.clear()
	_prism = false
	var n: int = int(LEVELS.get(subtraction, 1))
	match subtraction:
		"third":
			_cut_third(n)
		"gasket":
			_cut_gasket(n)
		"figure":
			_cut_figure()
		_:
			_cut_cross(n)


## CROSS — menger_sponge. Subdivide into 27, delete the six face centres and the
## body centre, recurse on the twenty. The 27 cells partition the parent exactly,
## which is why the complement is a real set and can be drawn at all —
## sierpinski_pyramid refused this same word for the want of it.
##
## Survivors are the FINAL level only. Every level's deletions are drawn, and they
## are disjoint across levels by construction (a level-2 deletion sits inside a
## level-1 survivor), so at this value survivors ∪ deletions is exactly the
## original cube and the ghost register is that cube, solid.
func _cut_cross(n: int) -> void:
	var pos: PackedVector3Array = PackedVector3Array([Vector3.ZERO])
	var size: float = CELL
	for _level in range(n):
		var third: float = size / 3.0
		var next: PackedVector3Array = PackedVector3Array()
		for p in pos:
			for i in range(27):
				var x: int = i % 3
				var y: int = (i / 3) % 3
				var z: int = i / 9
				var off: Vector3 = p + Vector3(
					float(x - 1) * third, float(y - 1) * third, float(z - 1) * third)
				if MENGER_CUT.has(i):
					_cut_p.append(off)
					_cut_s.append(Vector3(third, third, third))
				else:
					next.append(off)
		pos = next
		size = third
	for p2 in pos:
		_keep_p.append(p2)
		_keep_s.append(Vector3(size, size, size))


## FIGURE — recursive_chair. Subdivide into 27 ONCE, keep sixteen: the four corner
## cells of the bottom layer (legs), all nine of the middle layer (seat), and one
## row of the top layer (back). Eleven are deleted, and what is left is a chair
## rather than a fractal. That non-recursion is the reason `tick` is not an axis
## here, and it is a fact about the member, not a limitation of the room.
##
## THE CHAIR IS TURNED TO FACE THE ROOM. recursive_chair puts its back row at
## z == 2, which at the canonical yaw is the layer NEAREST the camera, so the six
## deleted top-layer cells would have stood behind their own backrest. The room
## keeps the back row at z == 0 instead. Turning an exhibit toward the visitor is
## what a room is for; the cut is untouched and the kept count is still sixteen.
func _cut_figure() -> void:
	var third: float = CELL / 3.0
	for y in range(3):
		for x in range(3):
			for z in range(3):
				var off: Vector3 = Vector3(
					float(x - 1) * third, float(y - 1) * third, float(z - 1) * third)
				var keep: bool = false
				if y == 0:
					keep = (x == 0 or x == 2) and (z == 0 or z == 2)
				elif y == 1:
					keep = true
				else:
					keep = (z == 0)
				if keep:
					_keep_p.append(off)
					_keep_s.append(Vector3(third, third, third))
				else:
					_cut_p.append(off)
					_cut_s.append(Vector3(third, third, third))


## THIRD — cantor_set, drawn the way cantor_set draws it: one ROW per level, the
## survivors of that level laid out at its own y, and the middle each of them lost
## drawn in the SAME row, between the two thirds it separates. That is
## _build_static's arithmetic line for line — offset = L/3, new_length = L/3, and
## _spawn_removed called at the child's level index, not the parent's.
##
## THE ONE VALUE WHOSE REGISTER IS A HISTORY, and the one whose ghost is NOT the
## original solid. Row k shows 2^k survivors and the 2^(k-1) middles that step
## removed; the middles removed at earlier steps are not redrawn, so row k sums to
## 1.5 * (2/3)^k of the span and only row 1 comes back to a full bar. Claiming
## otherwise would be claiming a picture this drawing does not make.
func _cut_third(n: int) -> void:
	var rows: int = n + 1
	var row_pitch: float = CELL / float(rows)
	var top: float = float(rows - 1) * row_pitch * 0.5
	# (centre_x, length) of the segments alive at the current level
	var segs: Array[Vector2] = [Vector2(0.0, CELL)]
	for level in range(rows):
		var y: float = top - float(level) * row_pitch
		for seg in segs:
			_keep_p.append(Vector3(seg.x, y, 0.0))
			_keep_s.append(Vector3(seg.y, CANTOR_SEC_Y, CANTOR_SEC_Z))
		if level == rows - 1:
			break
		var y2: float = top - float(level + 1) * row_pitch
		var next: Array[Vector2] = []
		for seg2 in segs:
			var third: float = seg2.y / 3.0
			next.append(Vector2(seg2.x - third, third))
			next.append(Vector2(seg2.x + third, third))
			_cut_p.append(Vector3(seg2.x, y2, 0.0))
			_cut_s.append(Vector3(third, CANTOR_SEC_Y, CANTOR_SEC_Z))
		segs = next


## GASKET — sierpinski_triangle's cut, and the one value that is not a member of
## this family. Keep the three corner triangles, delete the inverted medial one,
## recurse. Declared as an import in the header and in the registry.
##
## Flat, not extruded. Its source raises each level by extrusion_height, and 0.14 m
## of relief would eat 81.3 mm of a 203.5 mm hole at this yaw; at 0.05 it eats
## 29.1 mm. The room draws the cut, not the relief.
##
## At two levels the union of survivors and deletions is exactly the seed triangle,
## which is the precondition that lets ghost draw anything at all. In areas, with a
## triangle of width w taking w^2 of the seed: nine survivors at w = 1/4 give 9/16;
## the deletions are one at w = 1/2 and three at w = 1/4, so 4/16 + 3/16. And
## 9/16 + 4/16 + 3/16 = 1.
func _cut_gasket(n: int) -> void:
	_prism = true
	# (centre_x, centre_y, width) of the upward triangles alive at this level
	var tris: Array[Vector3] = [Vector3(0.0, 0.0, CELL)]
	for _level in range(n):
		var next: Array[Vector3] = []
		for t in tris:
			var w: float = t.z
			var h: float = w * sqrt(3.0) * 0.5
			_cut_p.append(Vector3(t.x, t.y - h * 0.25, 0.0))
			_cut_s.append(Vector3(w * 0.5, h * 0.5, GASKET_DEPTH))
			next.append(Vector3(t.x - w * 0.25, t.y - h * 0.25, w * 0.5))
			next.append(Vector3(t.x + w * 0.25, t.y - h * 0.25, w * 0.5))
			next.append(Vector3(t.x, t.y + h * 0.25, w * 0.5))
		tris = next
	for t2 in tris:
		var w2: float = t2.z
		_keep_p.append(Vector3(t2.x, t2.y, 0.0))
		_keep_s.append(Vector3(w2, w2 * sqrt(3.0) * 0.5, GASKET_DEPTH))


## THE FAMILY HAS TWO SCAR IMPLEMENTATIONS AND NOBODY HAS SAID SO. cantor_set and
## example_8_4 thin the SECTION and keep the removed part's LENGTH — the wound has
## the extent of the thing that went. menger_sponge and recursive_chair take 0.22
## in all three dimensions, so their wound loses the extent too. Both are in the
## corpus, both were copied "value for value" from the same origin, and they are
## not the same rule. Each cut gets the one its own member wrote.
func _scar_size(s: Vector3) -> Vector3:
	if subtraction == "third":
		return Vector3(s.x, s.y * SCAR_RATIO, s.z * SCAR_RATIO)
	return s * SCAR_RATIO


# ═══════════════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════════════

func _rebuild() -> void:
	if is_instance_valid(_root):
		remove_child(_root)
		_root.queue_free()
	_root = Node3D.new()
	_root.name = "Room_%s" % subtraction
	add_child(_root)

	_run()
	_shell(_root)

	for i in range(N_REG):
		var reg := Node3D.new()
		reg.name = "Register_%s" % REGISTERS[i]
		reg.position = Vector3(_reg_x(i), BAY_CY, 0.0)
		_root.add_child(reg)
		_fill_register(reg, REGISTERS[i])


func _reg_x(i: int) -> float:
	return (float(i) - 0.5 * float(N_REG - 1)) * PITCH


## The shell — plinth, three ground panels, four pilasters, lintel, cornice. It is
## identical at every value of the axis and identical between registers, so the
## drawing is the only thing that varies, both across the row and across a sweep.
##
## THE Z-STACK, written out because law 7 is not satisfied by intending to obey it.
## Everything structural except the plinth returns BEHIND the drawing plane:
##   ground panels  z -0.630 .. -0.580
##   pilasters      z -0.630 .. -0.300      (front face 0.30 m behind the marks)
##   lintel         z -0.630 .. -0.300
##   cornice        z -0.645 .. -0.285
##   plinth         z -0.630 .. +0.500      (below the marks, y 0.00 .. 0.40)
##   the marks      z -0.500 .. +0.500 (cross, figure), ±0.030 (third), ±0.025 (gasket)
## Nothing opaque stands between the camera and a mark. Every mesh here is a
## MeshInstance3D box and the shell encloses every MultiMesh in the artifact, so no
## layers = 0 extent anchor is needed and the capture AABB is the real body:
## 5.41 x 1.64 x 1.145, centre (0, 0.82, -0.0725).
func _shell(root: Node3D) -> void:
	var stone: StandardMaterial3D = _matte(C_STONE)
	var fin: StandardMaterial3D = _matte(C_FIN)
	var ground: StandardMaterial3D = _matte(C_GROUND)

	var depth: float = FIN_FRONT - (BACK_Z - WALL_T)
	var mid_z: float = (FIN_FRONT + BACK_Z - WALL_T) * 0.5

	root.add_child(_box(Vector3(0.0, SILL_Y * 0.5, (PLINTH_FRONT + BACK_Z - WALL_T) * 0.5),
		Vector3(SHELL_W, SILL_Y, PLINTH_FRONT - BACK_Z + WALL_T), stone))

	for i in range(N_REG + 1):
		var x: float = (float(i) - 0.5 * float(N_REG)) * PITCH
		root.add_child(_box(Vector3(x, SILL_Y + PANEL_H * 0.5, mid_z),
			Vector3(FIN_W, PANEL_H, depth), fin))

	root.add_child(_box(Vector3(0.0, SILL_Y + PANEL_H + LINTEL_H * 0.5, mid_z),
		Vector3(SHELL_W, LINTEL_H, depth), fin))
	root.add_child(_box(
		Vector3(0.0, SILL_Y + PANEL_H + LINTEL_H + CORNICE_H * 0.5, mid_z),
		Vector3(SHELL_W + CORNICE_OVER * 2.0, CORNICE_H, depth + CORNICE_OVER), stone))

	for j in range(N_REG):
		# THE COMPUTED GROUND, one panel per register, all three the same grey.
		# Giving each account the ground that suits it would have destroyed the
		# comparison; giving all three the grey that is equally fair to a pale mark
		# and a dark one is the only correction available that is not a thumb on
		# the scale.
		root.add_child(_box(Vector3(_reg_x(j), SILL_Y + PANEL_H * 0.5, BACK_Z - WALL_T * 0.5),
			Vector3(PITCH - FIN_W, PANEL_H, WALL_T), ground))
		# ON the plinth's front face, 12 mm PROUD of it. A Label3D at z inside the
		# box it names is a label nobody sees, which is what the first version of
		# this line shipped.
		#
		# Label3D hangs from its origin with HORIZONTAL_ALIGNMENT_CENTER, which is
		# both the class default and what _text sets explicitly — these are hung
		# from the register's own centre line, so a centred block is right here and
		# a left-aligned one would run off toward the neighbouring register.
		root.add_child(_text(REGISTERS[j],
			Vector3(_reg_x(j), SILL_Y - 0.13, PLINTH_FRONT + 0.012), 50, 0.0018, C_CHALK))

	# THE HEADER DOES NOT NAME THE AXIS VALUE, deliberately. A caption carrying
	# `cross` or `third` would let a measurement of the drawing be padded by a
	# measurement of the label; every pixel that moves across this axis is a mark
	# the cut made. It sits above the cornice, in open air, occluding nothing.
	root.add_child(_text("one cut  ·  three records",
		Vector3(0.0, SILL_Y + PANEL_H + LINTEL_H + CORNICE_H + 0.07,
			mid_z + (depth + CORNICE_OVER) * 0.5 + 0.01),
		44, 0.0018, C_CHALK))


func _fill_register(reg: Node3D, account: String) -> void:
	# The survivors stand in all three registers, from the same two arrays, so the
	# only difference down the row is what is done with what went.
	_cloud(reg, _keep_p, _keep_s, _matte(C_SURV), false)
	match account:
		"gone":
			# NOTHING, and that is the value rather than an omission. The removed
			# cells were never made, which is what all six members ship and what
			# the mathematics actually says. Identical at every value of
			# `subtraction` except for the survivors it shares with the other two.
			pass
		"ghost":
			_cloud(reg, _cut_p, _cut_s, _ghost_mat(), _prism)
		"scar":
			var scars: PackedVector3Array = PackedVector3Array()
			for i in range(_cut_s.size()):
				scars.append(_scar_size(_cut_s[i]))
			_cloud(reg, _cut_p, scars, _scar_mat(), _prism)


## One MultiMesh over a position/size pair. The ATOM is chosen by _prism, which is
## a property of the cut; `flip` turns each atom through PI about z, which is what
## makes a Sierpinski medial triangle the inverse of the three it sits between. For
## the box cuts flip is a no-op on an axis-aligned box and is passed false.
func _cloud(reg: Node3D, pos: PackedVector3Array, size: PackedVector3Array,
		mat: Material, flip: bool) -> void:
	if pos.is_empty():
		return
	var atom: Mesh = _unit_box()
	if _prism:
		atom = _unit_prism()
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Cloud"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = atom
	mm.instance_count = pos.size()
	var turn: Basis = Basis(Vector3(0.0, 0.0, 1.0), PI) if flip else Basis.IDENTITY
	for i in range(pos.size()):
		mm.set_instance_transform(i, Transform3D(turn.scaled(size[i]), pos[i]))
	mmi.multimesh = mm
	mmi.material_override = mat
	reg.add_child(mmi)


func _unit_box() -> BoxMesh:
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	return bm


## A unit triangular prism: base at y = -0.5 the full width, apex edge at y = +0.5,
## extruded through z. left_to_right = 0.5 is the isoceles case.
func _unit_prism() -> PrismMesh:
	var pm := PrismMesh.new()
	pm.size = Vector3.ONE
	pm.left_to_right = 0.5
	return pm


# ═══════════════════════════════════════════════════════════════════════════
# MATERIALS — the two mark recipes are cantor_set's, unchanged
# ═══════════════════════════════════════════════════════════════════════════

## cantor_set._spawn_removed's ghost branch, property for property. Unshaded, so
## this is the one mark in the room that does not scale with the host map's light —
## which is the family's own choice, inherited rather than revisited.
func _ghost_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = C_GHOST
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


## cantor_set._spawn_removed's scar branch, property for property. LEFT LIT ON
## PURPOSE: making it unshaded would have pinned it at 0.091444 and made the ground
## arithmetic exact under any light, at the cost of the one property that keeps the
## six members photographing alike. The room reports the asymmetry instead of
## editing the recipe — see dna.declines.
func _scar_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = C_SCAR
	m.metallic = 0.0
	m.roughness = 1.0
	return m


func _matte(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.88
	m.metallic = 0.0
	return m


func _box(p: Vector3, s: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = s
	mi.mesh = bm
	mi.material_override = m
	mi.position = p
	return mi


## Non-billboard on purpose. LabelFramer frames HANGING labels and leaves text that
## already lies on a body alone — these lie on the plinth and above the cornice, so
## they keep their place and add no plate to the capture. Four labels in the whole
## artifact and not one of them names the axis value.
func _text(content: String, p: Vector3, size: int, px: float, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = content
	l.font_size = size
	l.pixel_size = px
	l.outline_size = 0
	l.modulate = c
	l.position = p
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return l


# ═══════════════════════════════════════════════════════════════════════════
# CONFIG
# ═══════════════════════════════════════════════════════════════════════════

## Grid config arrives twice and by two routes: GridInteractablesComponent sets
## config_<key> metadata on the instantiated root and then calls apply_grid_config,
## and the capture harness calls apply_grid_config before the scene enters the
## tree. Reading the metadata on the way in means the room is built once, correctly,
## instead of built as `cross` and then torn down.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_subtraction"):
			var want: String = _clean(str(node.get_meta("config_subtraction")))
			if SUBTRACTIONS.has(want):
				subtraction = want
		node = node.get_parent()


## Tokens: #subtraction:third · #subtraction:gasket · #subtraction:figure
##
## GUARDED FOUR WAYS — the key must be present, the value must be one the code can
## build, it must differ from the one already standing, and _ready must have built
## once. This artifact has no placements today, so none of these guards is
## protecting a shipped map; they are here because the grid reaches this twice for
## one placement and an unguarded rebuild would raise three registers twice for
## nothing.
func apply_grid_config(config: Dictionary) -> void:
	if not config.has("subtraction"):
		return
	var want: String = _clean(str(config["subtraction"]))
	if not SUBTRACTIONS.has(want):
		return
	if want == subtraction:
		return
	subtraction = want
	if not _built:
		return          # _ready has not built yet and will build this value itself
	_rebuild()


func _clean(raw: String) -> String:
	return raw.strip_edges().to_lower()


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
