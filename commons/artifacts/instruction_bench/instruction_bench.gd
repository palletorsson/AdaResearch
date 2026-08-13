extends Node3D
class_name InstructionBench

## Instruction Bench — a SYNTHESIS artifact for the `tell` family. One assembly,
## part-way built, told four ways at once.
##
## @identity
## essence: the family's own chair plan, read live out of FurnitureAssemblyPuzzle,
##   standing four times over on one deck — once under a ghost, once under nothing,
##   once under marks, once beside a finished exemplar. The work already done is
##   identical in all four bays; only what the bay says about the rest changes.
## desire: to be walked along until the visitor notices that the fourth bay never
##   changes. A ghost shrinks as you build, a mark shrinks, silence stays silent —
##   but an exemplar is the same complete object at every stage of the work, because
##   it is the one telling that is not about YOUR chair.
## critical_parameter: `built` — how much of the assembly is already standing when
##   the telling is given. The four tellings are furthest apart when nothing is done
##   and converge as the work proceeds, because a part-built object is itself an
##   instruction.
## triggers: none. Nothing animates, nothing is grabbable, nothing is random, no
##   physics. One plan read once at build time and drawn six ways.
## emerges: the four values are not four amounts of the same substance. `none` and
##   `mark` and `ghost` describe the chair you have not built; `exemplar` describes a
##   different chair that is already finished. Three of them are about your work and
##   one of them is a rival to it — which is why only `exemplar` needs its own floor
##   space, and why only `exemplar` is blind to how far you have got.
## needs: the family's four words read live from a member's own const [has]; the
##   chair plan read from the family's own _setup_furniture_targets rather than
##   transcribed [has]; every fault derived from the family's own tolerances [has];
##   no randf, no _process, no timer, no tween [has]
## relationships: synthesis over the seven registry names that declare `tell` —
##   assembly_line_puzzle, chair_assembly_puzzle, shelf_assembly_puzzle,
##   stool_assembly_puzzle, table_assembly_puzzle, balance_puzzle,
##   configurable_portal. It re-runs none of their axes and replaces none of them.
## truth: instruction is not a quantity. Two tellings can disclose the same plan and
##   still be different theories of what a learner is — one filling in an outline,
##   one copying a finished thing.


# ═══════════════════════════════════════════════════════════════════════════
# THE FAMILY WORD, READ AND NOT RETYPED — AND EXHIBITED, NOT SWEPT
# ═══════════════════════════════════════════════════════════════════════════
#
# `tell` names the four BAYS of this bench. It is refused as this artifact's varying
# axis, on the record, for the reason taxonomy_hall refused `taxonomy`: every one of
# the seven members spends the word in a single mutually-exclusive `match`, standing
# in ONE telling and forgoing the other three, and on this bench all four are standing
# at once. That simultaneity IS the object.
#
# WHICH CASE THE FAMILY IS IN — MIXED, and it was read out of the members' CODE and
# not their prose.
#
#   * In furniture_assembly_puzzle.gd::_setup_ghost_guides() the word is spent in one
#     `match tell:` whose arms are `pass` / _tell_mark() / _tell_exemplar() / super(),
#     preceded by _clear_tell_nodes(). Four exclusive arms; no arm builds another
#     arm's geometry; values cannot stack. balance_puzzle.gd::_rebuild_tell() and
#     configurable_portal.gd are the same switch.
#   * assembly_line_puzzle.gd::_apply_tell() makes the mixture explicit, because all
#     four arms act on ONE mesh_instance: "none" sets `layers = 0` — it SUBTRACTS the
#     default; "mark" swaps the mesh for a small head; "exemplar" swaps the material
#     for an opaque one; ghost falls through untouched. One subtraction and two
#     parallel substitutions.
#
# So: `none` is the default MINUS itself, and `mark`, `ghost` and `exemplar` are three
# parallel apparatus. The DISCLOSURE partially nests where the APPARATUS does not —
# none's information is contained in mark's, and mark's in ghost's (the mark draws a
# footprint from target_scale.x/z and a head at the target point, so it gives plan
# position and plan footprint and withholds height and orientation, all of which the
# ghost box gives) — but not one node of the mark is a node of the ghost. And
# `exemplar` is not the top of that ladder at all: it discloses the same targets as
# `ghost` in a different modality, as a finished rival object rather than an outline
# to fill. A parallel set cannot be swept without demolishing three quarters of the
# exhibit, so it is exhibited instead.
#
# THE ORDER THIS BENCH TOOK, AND THE TWO IT DID NOT. Five of the seven declare
# ghost | none | mark | exemplar character for character (assembly_line_puzzle,
# chair_/shelf_/stool_/table_assembly_puzzle). balance_puzzle declares
# mark | none | ghost | exemplar. configurable_portal declares
# mark | ghost | exemplar | none. All three carry the SAME FOUR VALUES — the split is
# pure reordering, and each order hoists that member's own default to the front.
#
# This bench takes the five-member order, because those five are assembly puzzles and
# this is a bench of an assembly. What the divergence costs is arithmetic, and it is
# narrower than three orders sounds: build_dna_gallery trims from the TAIL, so a
# capped single-axis `tell` sweep drops
#     assembly order  -> exemplar first, then mark    (cap 3: ghost, none, mark)
#     balance order   -> exemplar first, then ghost   (cap 3: mark, none, ghost)
#     portal order    -> none first, then exemplar    (cap 3: mark, ghost, exemplar)
# At cap 3 the assembly and balance orders measure the SAME SET {ghost, none, mark}
# and differ only in tile order; the portal measures {mark, ghost, exemplar}, sharing
# two of three. At cap 2 the three sets are {ghost, none}, {mark, none}, {mark, ghost}
# — pairwise sharing exactly ONE value out of two. So a `tell` sweep at --max 3 or
# above compares like with like for six of the seven members, and only the portal
# stands apart; below that, nothing is comparable.
const FAM := preload("res://commons/primitives/furniture/furniture_assembly_puzzle.gd")

## The bays this bench knows how to build. NOT the vocabulary — the vocabulary is
## FAM.TELLS. This exists only so _check_family_list can push_error in both directions.
const BAYS: PackedStringArray = ["ghost", "none", "mark", "exemplar"]


# ═══════════════════════════════════════════════════════════════════════════
# AXIS 1 — `built`: how much of the assembly is standing when the telling is given
# ═══════════════════════════════════════════════════════════════════════════
#
# The family varies WHAT it tells you and never varies WHEN. Every one of the seven
# hands its telling to an untouched puzzle: the ghosts are built in _ready before a
# single piece has moved. This axis is the other half — a telling given to work
# already under way, which is the only condition a real instruction is ever read in.
#
# It NESTS. The values are prefixes of one build order, so the set of standing pieces
# at each value contains the set at the value below it. That order is not invented:
# it is the order the family's own _setup_chair_targets() appends its six targets in
# — seat, then the four legs front-left, front-right, back-left, back-right, then the
# back — and this file reads that array rather than retyping it.
#
#   prop   2 standing: the seat and one leg. A plane on a single column, with four of
#          the six targets still to be told. THE DEFAULT — see below.
#   stood  5 standing: the seat and all four legs. It stands; only the back remains,
#          so every bay draws exactly one telling and the four are at their closest.
#   pair   3 standing: the seat and both front legs. Half the assembly. Both remaining
#          legs are at the back of the chair, which is the family's target order
#          speaking and not a staging choice.
#   plane  1 standing: the seat alone, floating. Five targets to be told, so the four
#          bays are at their furthest apart and the picture is almost all telling.
#
# WHY THE TAIL IS `plane`. build_dna_gallery trims a value list from the tail, and the
# closest pair on this axis is prop <-> plane (one leg apart, predicted floor 9.50%).
# Declaring plane last means a capped run drops that pair rather than the default. At
# cap 3 the surviving set is {prop, stood, pair} whose weakest pair is stood <-> pair
# at a predicted 9.71%; at cap 2 it is {prop, stood}, predicted 21.75-23.54%.
@export_enum("prop", "stood", "pair", "plane") var built: String = "prop"

# WHY `prop` AND NOT `plane` OR `stood`. A synthesis has no shipped placements, so the
# default is a free design choice with no preservation duty, and the freedom was spent
# on the strongest single reading rather than the emptiest or the fullest.
#   `stood` is the weakest: one target left means one mark per bay, and the four
#     theories of instruction shrink to four ways of pointing at the same missing back.
#     It is the CONVERGENCE claim and it is worth a tile, not the default tile.
#   `plane` is the loudest and the least honest as a default: a seat floating on
#     nothing is barely an assembly under way, and with five targets outstanding the
#     bench photographs as four diagrams rather than as four commentaries on a piece
#     of work. It is also the value where `none` is most obviously useless, which
#     stacks the argument.
#   `prop` is a plane resting on one column — unmistakably part-built, unmistakably
#     wrong-looking, with four targets still to tell and one of them (the front-right
#     leg) standing clear of the seat where every bay can draw it unoccluded. A
#     visitor who meets only the default meets the question.


# ═══════════════════════════════════════════════════════════════════════════
# AXIS 2 — `slip`: which of the three transformations the standing work gets wrong
# ═══════════════════════════════════════════════════════════════════════════
#
# The second thing an instruction does is let you find out that you are wrong. The
# family's identity block says a learner "discovers that scale, rotate, and translate
# together are sufficient to build any rectangular form"; this axis is those same three
# transformations, each in turn NOT satisfied by the standing work.
#
# It sits SIDE BY SIDE: translate, rotate and scale are the three generators, no one of
# them contains another, and `sound` is their common zero. The slip is always applied
# to the FIRST piece in the family's target order, the seat, which is therefore
# standing at every value of `built` — so this axis is never conditional on that one.
#
#   sound  the standing work is on its target. THE DEFAULT.
#   turn   the seat is tilted about Z by 1.5x the family's own rotation_tolerance,
#          read off the target itself: 15.0 deg -> 22.5 deg.
#   place  the seat is displaced along X by 1.5x the family's own position_tolerance,
#          read off the target itself: 0.08 m -> 0.12 m.
#   size   the seat is built ONE RUNG SMALL on the family's own scale ladder. This one
#          is not 1.5x a tolerance, and the asymmetry is a fact about the family rather
#          than a liberty taken here: grab_cube_scalable.gd quantises scale to
#          [0.05, 0.1, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0] times a
#          _mesh_base_scale of 0.1 m, and leaves position and rotation continuous. So
#          the smallest scale error a player can physically make is one rung — the
#          seat's 0.40 m is the 4.0 rung, and the rung below is 3.0 * 0.1 = 0.30 m —
#          while the smallest position and rotation errors are whatever the ruler will
#          not forgive. 0.10 m is 3.33x the seat's 0.03 scale_tolerance; there is no
#          smaller wrong answer available.
#
# WHY THE TAIL IS `size`. The closest pair on this axis is sound <-> size (predicted
# 10.16% mean, floor 9.75%), so a capped run drops it: cap 3 leaves {sound, turn,
# place} whose weakest pair is 16.02%, cap 2 leaves {sound, turn} at 18.77-19.26%.
#
# WHY NOT THE WORD `fault`. It is taken: impossible_trident declares
# fault: global | confessed | none | doubled, which asks where the contradiction in an
# impossible figure LIVES. Same word, different question, incompatible values — and a
# second `fault` with a different value list is exactly the ambiguity that makes two
# tools disagree about the same tokens. Refused, and named here so nobody reopens it.
@export_enum("sound", "turn", "place", "size") var slip: String = "sound"


# ═══════════════════════════════════════════════════════════════════════════
# THE BENCH — every dimension, and the arithmetic that fixed it
# ═══════════════════════════════════════════════════════════════════════════
#
# Z-STACK, read from the camera inward, because a frame is four rails and not a slab:
#
#   the deck    y 0.000 .. 0.060, z -0.280 .. +0.280. NOTHING is drawn in front of a
#               telling; the deck is UNDER everything.
#   the kerbs   y 0.060 .. 0.090 (mark bay only), lying on the deck at the remaining
#               targets' footprints
#   the work    y 0.085 .. 0.930, the chair itself
#
# The only thing that ever stands between the camera and a telling is a piece of the
# standing work, which is the argument. Checked: at built=prop the marks for the three
# back targets sit under the seat, and the camera pitches 14.9 deg down, so a ray from
# a kerb at y 0.090 rises 0.2571 m per metre travelled and needs 1.54 m of run to reach
# the seat's underside at 0.485 — the seat is 0.40 m deep, so the ray leaves from under
# it with 1.14 m to spare. You see under the seat; nothing is buried.
const BAY_PITCH: float = 0.64      ## bay centre to bay centre
const EX_DX: float = 0.60          ## exemplar bay: how far the finished chair stands aside
const DECK_T: float = 0.06
const DECK_Z0: float = -0.28
const DECK_Z1: float = 0.28
const DECK_MARGIN: float = 0.10
const CHAIR_HALF: float = 0.20     ## the chair plan's own half-width, 0.40 / 2
## The bench is recentred on x = 0 rather than on its middle bay, because the exemplar's
## extra chair makes the row asymmetric: four bays run -0.96 .. +0.96 and the finished
## chair stands 0.60 beyond the last of them, so the deck spans -1.26 .. +1.86 about a
## centre at +0.30. The shift that fixes that is EX_DX * 0.5 and NOT a hand-measured
## number, and the arithmetic is worth writing down because it does not depend on the
## bay count: with n bays at pitch P and shift s, x0 = -(n-1)/2 * P + s - CHAIR_HALF -
## DECK_MARGIN and x1 = +(n-1)/2 * P + s + EX_DX + CHAIR_HALF + DECK_MARGIN, so the
## centre is s + EX_DX/2 for every n. If the family ever declares a fifth telling this
## bench still lands on its own origin. Union AABB 3.12 x 0.934 x 0.56.
const ORIGIN_SHIFT: float = -EX_DX * 0.5

## MARKS, RE-GAUGED TO THIS OBJECT AND NOT TRANSCRIBED. The family's mark apparatus is
## sized for a capture of ONE chair filling the frame. On a four-bay bench at 201.7
## px/m its numbers are illegible, and the arithmetic is:
##     family stake stem 0.007 m -> 1.2 px       here 0.030 m -> 5.0 px
##     family stake head 0.032 m -> 5.3 px       here 0.048 m -> 8.0 px wide, 9.4 tall
##     family outline bar 0.008 m -> 1.3 px      here 0.024 m -> 3.0 to 4.0 px
## A world displacement projects to screen at 0.8275 of its length along X, 0.9664
## along Y and 0.6176 along Z from this standpoint, which is where those px come from.
## The outline bar is still under 5 px ACROSS, so it is given a HEIGHT instead of lying
## flat as tape: 0.030 m of kerb reads 5.85 px in screen Y, which is the dimension that
## separates it from the deck. Making the bar wider instead was rejected — a leg
## footprint is 0.05 m, i.e. 8.35 px, and an outline of it drawn in 0.04 m bars is not
## an outline, it is a blob.
const BAR_T: float = 0.024
const BAR_H: float = 0.030
const STEM_W: float = 0.030
const HEAD_S: float = 0.048

## THE THREE SLIP MAGNITUDES ARE DERIVED AT BUILD TIME from the family's own target
## tolerances (see _slip_transform); these two are the multipliers and the one number
## the family quantises rather than tolerances.
const SLIP_TOL_MULT: float = 1.5
## grab_cube_scalable.gd's _mesh_base_scale. TRANSCRIBED, NOT PRELOADED, on the record:
## the ladder lives on an @export in a script whose base class is XRToolsPickable, so
## preloading it would drag the XR addon into the parse chain of a bench that has no
## business needing one. Cited instead: grab_cube_scalable.gd line 17 for the ladder
## and line 58 for the base scale.
const SNAP_BASE: float = 0.1
const SNAP_LADDER: Array[float] = [0.05, 0.1, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0]

## THE PALETTE IS THE FAMILY'S, and every entry was read out of a member rather than
## picked. The wood is the one substitution and it is stated: the family's final pieces
## use res://commons/resourses/shaders/wood.gdshader with light_color
## (0.952941, 0.858824, 0.74902) and dark_color (0.74902, 0.619608, 0.490196), and this
## bench draws their arithmetic mean as a flat StandardMaterial3D — because a headless
## sweep never reimports, so a .glsl/.gdshader edit does not reach the capture and a
## stale compiled shader photographs as an inert axis. A grain that cannot be trusted
## to be the same grain in every tile is worse than no grain.
const COL_WOOD := Color(0.85098, 0.739216, 0.619608)
## balance_puzzle.gd's platform_color, character for character.
const COL_DECK := Color(0.30, 0.30, 0.35)
## transform_puzzle_base.gd's ghost_color / ghost_alpha / ghost_emission_energy defaults.
const GHOST_RGB := Color(0.0, 0.8, 1.0)
const GHOST_ALPHA: float = 0.25
const GHOST_ENERGY: float = 0.8
## furniture_assembly_puzzle.gd::_tell_mark's stem_mat.
const COL_STEM := Color(0.10, 0.12, 0.15)

var _built_once: bool = false
var _bays: PackedStringArray = PackedStringArray()


# ═══════════════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_read_grid_config_meta()
	built = built if _is_built(built) else "prop"
	slip = slip if _is_slip(slip) else "sound"
	_bays = _family_tells()
	_check_family_list()
	_build()
	_built_once = true


## The grid stamps `config_*` metadata BEFORE add_child, so this runs ahead of the
## build. No metadata, no change. An unrecognised word keeps the standing value rather
## than emptying the bench.
func _read_grid_config_meta() -> void:
	var n: Node = self
	var hops: int = 0
	while n != null and hops < 4:
		if n.has_meta("config_built"):
			var b: String = str(n.get_meta("config_built")).strip_edges().to_lower()
			if _is_built(b):
				built = b
		if n.has_meta("config_slip"):
			var s: String = str(n.get_meta("config_slip")).strip_edges().to_lower()
			if _is_slip(s):
				slip = s
		n = n.get_parent()
		hops += 1


## Rebuilds ONLY when a value actually changed AND _ready has already built once — the
## force_pad fault, which tore down every child and re-ran _ready on any call, including
## calls naming nothing it owned.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false
	if config_data.has("built"):
		var b: String = str(config_data["built"]).strip_edges().to_lower()
		if _is_built(b) and b != built:
			built = b
			changed = true
	if config_data.has("slip"):
		var s: String = str(config_data["slip"]).strip_edges().to_lower()
		if _is_slip(s) and s != slip:
			slip = s
			changed = true
	if changed and _built_once:
		_build()


func _is_built(v: String) -> bool:
	return v == "plane" or v == "prop" or v == "pair" or v == "stood"


func _is_slip(v: String) -> bool:
	return v == "sound" or v == "turn" or v == "place" or v == "size"


## HOW MANY OF THE SIX ARE STANDING. Prefixes of the family's own target order, so the
## sets nest by construction: plane's one piece is in prop's two, prop's two are in
## pair's three, pair's three are in stood's five. Written as a match rather than as a
## const Dictionary so nothing here depends on a constant-expression rule.
func _placed_count() -> int:
	match built:
		"plane":
			return 1
		"pair":
			return 3
		"stood":
			return 5
		_:
			return 2                     # "prop" — the default


## The family's four words, read live off the owning member's own const. Object.get()
## would return null — a const is not a property — and the bench would fall back
## silently to its own copy, which is the drift this preload exists to prevent.
## get_script_constant_map() is non-static and cannot be called on the class at all.
## FAM.TELLS is the corpus's idiom for this (taxonomy_hall reads TAX_SRC.TAXONOMIES,
## noise_quarry reads READOUT_SRC.READOUTS) and it has the better failure mode: if
## furniture_assembly_puzzle ever drops the const, this file stops PARSING and the
## compile gate says so, rather than quietly measuring the wrong vocabulary.
func _family_tells() -> PackedStringArray:
	var src: Variant = FAM.TELLS
	if src is PackedStringArray and (src as PackedStringArray).size() > 0:
		return src as PackedStringArray
	push_error("instruction_bench: furniture_assembly_puzzle.gd no longer exposes TELLS; " +
		"falling back to this bench's own bay list, which may have drifted from the family.")
	return BAYS


## Both directions: a word the family declares that this bench has no bay for, and a bay
## this bench builds that the family has dropped.
func _check_family_list() -> void:
	for t in _bays:
		if not BAYS.has(t):
			push_error("instruction_bench: the family declares '%s' and this bench has no bay for it." % t)
	for b in BAYS:
		if not _bays.has(b):
			push_error("instruction_bench: this bench builds '%s' and the family no longer declares it." % b)


## THE PLAN, READ FROM THE FAMILY AND NOT TRANSCRIBED. A bare .new() builds the puzzle
## node WITHOUT entering the tree, so _ready never runs: no ghosts, no spawned pieces,
## no tween, no signal connections, no piece_scene needed. _setup_furniture_targets()
## then fills piece_targets from _setup_chair_targets(), and the six targets are copied
## out as plain Dictionaries before the probe is freed. If the chair plan ever changes,
## this bench changes with it and cannot photograph a chair the family no longer builds.
##
## Returns one Dictionary per target: id, pos, rot (degrees), size, and the three
## tolerances the slip axis is derived from.
func _family_plan() -> Array:
	var out: Array = []
	var probe: Node = FAM.new()
	if probe == null:
		push_error("instruction_bench: could not construct FurnitureAssemblyPuzzle; no plan to draw.")
		return out
	probe.call("_setup_furniture_targets")
	var raw: Variant = probe.get("piece_targets")
	if not (raw is Array):
		push_error("instruction_bench: FurnitureAssemblyPuzzle has no piece_targets to read.")
		probe.free()
		return out
	var targets: Array = raw
	if targets.is_empty():
		push_error("instruction_bench: FurnitureAssemblyPuzzle produced no chair targets.")
		probe.free()
		return out
	for t in targets:
		var tp: Vector3 = t.target_position
		var tr: Vector3 = t.target_rotation
		var ts: Vector3 = t.target_scale
		out.append({
			"id": str(t.piece_id),
			"pos": tp,
			"rot": tr,
			"size": ts,
			"pos_tol": float(t.position_tolerance),
			"rot_tol": float(t.rotation_tolerance),
			"scale_tol": float(t.scale_tolerance),
		})
	probe.free()
	return out


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

	# ONE COPY OF THE ARITHMETIC, evaluated once here and read six ways: by the standing
	# solids, by the ghost fills, by the ghost shells, by the kerbs, by the stakes and by
	# the exemplar. Nothing below recomputes a target.
	var plan: Array = _family_plan()
	if plan.is_empty():
		return
	var n: int = _bays.size()
	var placed: int = mini(_placed_count(), plan.size())

	var x0: float = _bay_x(0) - CHAIR_HALF - DECK_MARGIN
	var x1: float = _bay_x(n - 1) + EX_DX + CHAIR_HALF + DECK_MARGIN
	_slab("Deck", Vector3(x1 - x0, DECK_T, DECK_Z1 - DECK_Z0),
		Vector3((x0 + x1) * 0.5, DECK_T * 0.5, (DECK_Z0 + DECK_Z1) * 0.5),
		COL_DECK, self, 0.0)

	for b in range(n):
		var tell: String = _bays[b]
		var bx: float = _bay_x(b)
		var bay := Node3D.new()
		bay.name = "Bay_" + tell
		add_child(bay)

		# ── THE WORK ALREADY STANDING. Identical in every bay, at every value of
		#    `tell`: the axis this bench exhibits changes what is SAID about the chair,
		#    never the chair.
		for k in range(placed):
			var tgt: Dictionary = plan[k]
			var xf: Array = _slip_transform(tgt, k)
			var at: Vector3 = xf[0]
			var sz: Vector3 = xf[1]
			_slab("Work_" + str(tgt["id"]), sz,
				Vector3(bx, DECK_T, 0.0) + at, COL_WOOD, bay, float(xf[2]))

		# ── THE TELLING OF WHAT REMAINS.
		match tell:
			"none":
				pass                                   # the bench, and nothing else
			"mark":
				_bay_mark(bay, bx, plan, placed)
			"exemplar":
				_bay_exemplar(bay, bx, plan)
			_:
				_bay_ghost(bay, bx, plan, placed)      # "ghost" — the assembly lineage


func _bay_x(i: int) -> float:
	return (float(i) - float(_bays.size() - 1) * 0.5) * BAY_PITCH + ORIGIN_SHIFT


# ═══════════════════════════════════════════════════════════════════════════
# THE SLIP — one transform, three ways of being wrong, derived from the family
# ═══════════════════════════════════════════════════════════════════════════

## Where piece k actually stands. Returns [offset, size, z-rotation-degrees]. Only the
## FIRST piece in the family's target order can slip — it is the one standing at every
## value of `built`, so this axis is never conditional on that one.
func _slip_transform(tgt: Dictionary, k: int) -> Array:
	var pos: Vector3 = tgt["pos"]
	var size: Vector3 = tgt["size"]
	if k != 0 or slip == "sound":
		return [pos, size, 0.0]
	match slip:
		"place":
			# 1.5x the family's OWN position_tolerance for this target: 0.08 -> 0.12 m.
			return [pos + Vector3(float(tgt["pos_tol"]) * SLIP_TOL_MULT, 0.0, 0.0), size, 0.0]
		"turn":
			# 1.5x the family's OWN rotation_tolerance for this target: 15 -> 22.5 deg.
			return [pos, size, float(tgt["rot_tol"]) * SLIP_TOL_MULT]
		"size":
			# ONE RUNG DOWN the family's own scale ladder, in the two axes the seat is
			# wide in. Not a multiple of scale_tolerance, because scale is the one
			# transformation the family QUANTISES: the smallest wrong answer available
			# to a player is a rung, and for the seat's 0.40 (the 4.0 rung) that is
			# 0.30. 0.10 m happens to be 3.33x the 0.03 scale_tolerance, which is why
			# `size` is a real failure and not a near miss.
			return [pos, Vector3(_rung_below(size.x), size.y, _rung_below(size.z)), 0.0]
		_:
			return [pos, size, 0.0]


## The next value down the family's snap ladder, in metres. Falls back to the value
## itself if it is already at the bottom rung, which for the chair cannot happen — its
## smallest dimension is 0.05, the 0.5 rung, and there are two rungs below it.
func _rung_below(metres: float) -> float:
	var want: float = metres / SNAP_BASE
	var best: int = -1
	for i in range(SNAP_LADDER.size()):
		if absf(SNAP_LADDER[i] - want) < 0.001:
			best = i
			break
	if best <= 0:
		return metres
	return SNAP_LADDER[best - 1] * SNAP_BASE


# ═══════════════════════════════════════════════════════════════════════════
# THE FOUR TELLINGS
# ═══════════════════════════════════════════════════════════════════════════

## GHOST — the assembly lineage, material for material. transform_puzzle_base.gd builds
## each guide as a fill at ghost_alpha * 0.5 with emission at ghost_emission_energy *
## 0.3, plus a "wireframe edge" box at target_scale * 1.02 with CULL_FRONT at full
## ghost_alpha and full emission. THE EDGE IS NOT AN EDGE, and this is arithmetic, not
## an opinion: 1.02 of a 0.05 m leg is a 0.25 mm shell, which at this bench's 201.7 px/m
## is 0.08 px, and at the family's own single-chair framing is still under a fifth of a
## pixel. It has never drawn an outline anywhere. What it actually contributes is a
## second translucent layer, i.e. more alpha. It is built here exactly as the family
## builds it, because this bench exists to show the family's ghost and not an improved
## one — see the registry's dna.declines.
func _bay_ghost(bay: Node3D, bx: float, plan: Array, placed: int) -> void:
	var fill := StandardMaterial3D.new()
	fill.albedo_color = Color(GHOST_RGB.r, GHOST_RGB.g, GHOST_RGB.b, GHOST_ALPHA * 0.5)
	fill.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fill.emission_enabled = true
	fill.emission = Color(GHOST_RGB.r, GHOST_RGB.g, GHOST_RGB.b, 1.0)
	fill.emission_energy_multiplier = GHOST_ENERGY * 0.3
	fill.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill.cull_mode = BaseMaterial3D.CULL_DISABLED

	var edge := StandardMaterial3D.new()
	edge.albedo_color = Color(GHOST_RGB.r, GHOST_RGB.g, GHOST_RGB.b, GHOST_ALPHA)
	edge.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	edge.emission_enabled = true
	edge.emission = GHOST_RGB
	edge.emission_energy_multiplier = GHOST_ENERGY
	edge.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	edge.cull_mode = BaseMaterial3D.CULL_FRONT

	for k in range(placed, plan.size()):
		var tgt: Dictionary = plan[k]
		var p: Vector3 = tgt["pos"]
		var sz: Vector3 = tgt["size"]
		var at: Vector3 = Vector3(bx, DECK_T, 0.0) + p
		_mesh("Ghost_" + str(tgt["id"]), sz, at, fill, bay, 0.0)
		_mesh("GhostEdge_" + str(tgt["id"]), sz * 1.02, at, edge, bay, 0.0)


## MARK — where, not what. The family's construction: the target's footprint drawn on
## the deck as four bars, and a dark stake standing to a small bright head at the exact
## target point. Position and plan-footprint are disclosed; height extent and
## orientation are withheld, which is why the holder carries no rotation here either —
## that is the family's behaviour and it is the honest half of "where, not what".
func _bay_mark(bay: Node3D, bx: float, plan: Array, placed: int) -> void:
	var lit := StandardMaterial3D.new()
	lit.albedo_color = Color(GHOST_RGB.r, GHOST_RGB.g, GHOST_RGB.b, 1.0)
	lit.emission_enabled = true
	lit.emission = Color(GHOST_RGB.r, GHOST_RGB.g, GHOST_RGB.b, 1.0)
	lit.emission_energy_multiplier = GHOST_ENERGY * 1.6
	lit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var stem := StandardMaterial3D.new()
	stem.albedo_color = COL_STEM
	stem.roughness = 0.85

	for k in range(placed, plan.size()):
		var tgt: Dictionary = plan[k]
		var p: Vector3 = tgt["pos"]
		var sz: Vector3 = tgt["size"]
		var fx: float = maxf(sz.x, 0.03)
		var fz: float = maxf(sz.z, 0.03)
		var ky: float = DECK_T + BAR_H * 0.5
		var cx: float = bx + p.x
		_mesh_box("Kerb_%s_f" % str(tgt["id"]), Vector3(fx + BAR_T, BAR_H, BAR_T),
			Vector3(cx, ky, p.z + fz * 0.5), lit, bay)
		_mesh_box("Kerb_%s_b" % str(tgt["id"]), Vector3(fx + BAR_T, BAR_H, BAR_T),
			Vector3(cx, ky, p.z - fz * 0.5), lit, bay)
		_mesh_box("Kerb_%s_r" % str(tgt["id"]), Vector3(BAR_T, BAR_H, fz + BAR_T),
			Vector3(cx + fx * 0.5, ky, p.z), lit, bay)
		_mesh_box("Kerb_%s_l" % str(tgt["id"]), Vector3(BAR_T, BAR_H, fz + BAR_T),
			Vector3(cx - fx * 0.5, ky, p.z), lit, bay)
		var h: float = maxf(p.y, 0.02)
		_mesh_box("Stake_" + str(tgt["id"]), Vector3(STEM_W, h, STEM_W),
			Vector3(cx, DECK_T + h * 0.5, p.z), stem, bay)
		_mesh_box("Head_" + str(tgt["id"]), Vector3(HEAD_S, HEAD_S, HEAD_S),
			Vector3(cx, DECK_T + h, p.z), lit, bay)


## EXEMPLAR — the whole answer, standing BESIDE the work rather than on top of it. The
## family is split on this and the split is not a disagreement, it is a consequence of
## where the puzzle is in its own life: furniture_assembly_puzzle stands its exemplar AT
## the targets, which is unambiguous when nothing has been built yet and impossible
## here, because at every value of `built` at least one solid piece already occupies a
## target and an exemplar drawn there would be a second box in the same millimetres —
## the operations_gallery fault exactly, four photographs of one slab. balance_puzzle
## already solves it the other way, on a pad beside the platform, and this bench takes
## that reading: EX_DX = 0.60 m puts 0.14 m of clear deck between the two chairs at
## every value of both axes, and 0.08 m at slip=place where the standing seat leans
## 0.12 m toward it.
##
## THE EXEMPLAR IS DRAWN AT THE PLAN, NEVER AT THE SLIP. It is the correct answer, so a
## slipped bench shows a true chair beside a wrong one — which is the whole of what an
## exemplar is for. It follows that this bay is the ONLY telling that does not change
## with `built`: a ghost shrinks as you build and a mark shrinks with it, but a finished
## chair is the same finished chair at one piece standing or at five. Stated in the
## registry's dna.still_note so a reader does not mistake it for a dead bay.
func _bay_exemplar(bay: Node3D, bx: float, plan: Array) -> void:
	for k in range(plan.size()):
		var tgt: Dictionary = plan[k]
		var p: Vector3 = tgt["pos"]
		var sz: Vector3 = tgt["size"]
		_slab("Exemplar_" + str(tgt["id"]), sz,
			Vector3(bx + EX_DX, DECK_T, 0.0) + p, COL_WOOD, bay, 0.0)


# ═══════════════════════════════════════════════════════════════════════════
# GEOMETRY HELPERS
# ═══════════════════════════════════════════════════════════════════════════

## Signatures are kept on ONE LINE each. A parenthesised continuation is valid GDScript
## and Godot parses it, but tools/check_dna_declarations.py reads source TEXT line by
## line, and a wrapped @export_enum has already cost this corpus a pass by reporting
## NO EXPORT on a perfectly good file. The habit is cheap; the failure is silent.
func _slab(nm: String, size: Vector3, centre: Vector3, col: Color, host: Node, rot_z_deg: float) -> MeshInstance3D:
	return _mesh(nm, size, centre, _matte(col), host, rot_z_deg)


func _mesh_box(nm: String, size: Vector3, centre: Vector3, mat: Material, host: Node) -> MeshInstance3D:
	return _mesh(nm, size, centre, mat, host, 0.0)


func _mesh(nm: String, size: Vector3, centre: Vector3, mat: Material, host: Node, rot_z_deg: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = centre
	if not is_zero_approx(rot_z_deg):
		mi.rotation_degrees = Vector3(0.0, 0.0, rot_z_deg)
	host.add_child(mi)
	return mi


func _matte(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = 0.0
	m.roughness = 0.62
	return m
