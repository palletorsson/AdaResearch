extends Node3D
class_name RhizomeInside

## RHIZOME INSIDE — a body you are inside of, and the inside is a GRAPH.
##
## 2026-09-03, Palle: "use SDF iso surfaces to make a more complex form, not just
## a tunnel — morphogenic, animal machine architecture, radical inside, rhizomatic
## body."
##
## radial_inside.gd was the first answer and the objection to it is exact: it is a
## SPINE AND A SECTION. Every point of that building is (how far along, how far
## round), which is a corridor however much it wanders — one route, two ends, and
## a plan you could draw as a line. A rhizome is the refusal of that: no root, no
## single route, and no point from which the whole is ordered. Deleuze and Guattari
## are not decoration here, they are the DATA STRUCTURE. So this artifact's plan is
## a graph with CYCLES in it, asserted before a single triangle is marched, and the
## whole graph is handed to the field AT ONCE so that what comes back is one fused
## body rather than a set of joined pipes.
##
## WHAT MADE THIS AFFORDABLE (all of it measured by commons/testing/probe_iso_chunks.gd,
## none of it re-derived here):
##
##   Iso.shell_field(parts, q, blend, wall) = abs(field) - wall. The walkable void
##   is the solid's OWN INTERIOR. Marching it gives an outer skin and an inner skin
##   with the wall between, so the rhizome's topology IS the plan of the building
##   and nobody drew it. Every place two limbs smooth-unioned is a place you can
##   walk through.
##
##   Iso.mesh_rhizome chunks the march on a GLOBAL lattice, so neighbouring chunks
##   agree to 0.000007 m — the seam does not exist rather than being stitched — and
##   Iso.parts_near culls the field per chunk, which is what turns cells x parts
##   from a four-hour march into the number printed at the bottom of _build().
##
##   Every marched vertex carries its SUTURE in vertex COLOR: rgb is the nearest
##   part's own dealt hue, alpha is 1 at a tie with the runner-up. A tie is exactly
##   where two limbs fused. rhizome_surface.gdshader lights that, so you can read
##   the plan off the walls — colour says which limb you are in, light says where it
##   joins another. That is the wayfinding in a windowless anatomy.
##
## ── THE ENVELOPE IS THE PLAYER, AND EVERY RADIUS BELOW COMES OUT OF IT ─────────
##
## Measured from commons/scenes/desktop_player.tscn: CapsuleShape3D radius 0.30,
## height 1.80, the shape centred at y 0.90 so the two cap-sphere centres sit at
## 0.30 and 1.50 above the floor; eye at 1.60; floor_max_angle 45 degrees; and NO
## STEP HEIGHT AT ALL — Godot 4's CharacterBody3D has none and DesktopPlayer adds
## none, so any lip is a wall. The museum's own walked verdict (endless_museum.gd)
## is that 1 m doorways read as too small; every one was widened to 2 m.
##
## THE CAVITY RADIUS IS bulb_radius - wall. shell_field puts the inner skin where
## the solid field reads -wall, so for a sphere of SDF radius r the cavity radius is
## r - wall and the outer skin is at r + wall: the wall measures 2 x wall across,
## which is what the gate measured (0.560 m for wall 0.28).
##
## STANDING INSIDE A CYLINDER of cavity radius R, floor at the bottom: the head's
## cap centre is 1.50 above that floor, i.e. at distance |1.50 - R| from the axis,
## and it must clear the wall by the capsule radius, so |1.50 - R| + 0.30 <= R.
## For R < 1.50 that is R >= 0.90. So 0.90 m is the ABSOLUTE floor for a passage
## and it leaves the player scraping the ceiling with no room to step sideways.
##
## WALKING ON A CURVED FLOOR — there is no deck in this building, the floor is the
## inner skin and it is curved. On a cylinder of cavity radius R the surface tilt at
## horizontal offset x is asin(x / R), so it is under floor_max_angle 45 degrees
## only within R * sin(45) = 0.7071 R of the bottom. The walkable strip is therefore
## 1.4142 R wide. Requiring a 1.0 m strip gives R >= 0.707 m; requiring the standing
## envelope gives R >= 0.90. Both are cleared with margin by the number this file
## actually uses:
##
##   PASSAGE_CAVITY_MIN = 1.20 m  ->  walkable strip 1.4142 x 1.20 = 1.697 m
##                                    (a 0.60 m wide body with 0.548 m of play
##                                     either side)
##                                ->  centre-line headroom 2R = 2.40 m against a
##                                    1.80 m body
##
## Bulbs are wider still (BULB_CAVITY_MIN 1.50 -> a 2.121 m curved margin and 3.00 m
## of headroom) and they are ROUNDED BOXES rather than spheres, which is the
## "squashed sphere" the brief allows and is strictly better here: a rounded box of
## half-extent (hx, hy, hz) and round radius R has a FLAT floor plate 2hx by 2hz,
## plus the same 0.7071 R curved margin outside it. So a chamber's walkable floor is
## 2hx + 1.4142 R across and the middle of it is genuinely level, which a sphere's
## floor never is. The half-extents are kept small (<= 0.70) because they are not
## free: the surface area of a box dilated by R is 8(ab+bc+ca) + 4piR(a+b+c) +
## 4piR^2, so the flat plate buys its own perimeter band at 4piR per metre of
## (a+b+c) — and area is what this thing is billed in. See the cost note below.
##
## ── THE FLOOR IS THE ONE INVARIANT, AND IT IS WHAT STOPS THE STEPS ────────────
##
## A hollow body has a failure that a solid one cannot have: two cavities that meet
## at DIFFERENT heights leave a lip, and in an engine with no step height a 0.4 m
## lip is a wall that looks like a floor. A passage capsule whose axis sat at its
## bulb's centre height would have its floor (axis - R_pass) a full R_bulb - R_pass
## ABOVE the bulb's floor — a cliff in every doorway, and one that renders as a
## perfectly reasonable curve.
##
## So nothing here is positioned by its centre. Every part is positioned by ITS
## FLOOR: a terrace function floor_y(x, z) is evaluated first, and each part's axis
## or centre is lifted off it by exactly its own cavity radius. Consequences, all of
## them free:
##
##   a passage's trough and its bulb's floor plate meet at the same height,
##   two passages that cross meet at the same height (a level crossing, not a pit),
##   the outer skin's underside is one continuous surface at floor_y - wall,
##   and a passage that tapers stays level, because axis = floor + R and both the
##   axis and R are linear in the capsule parameter, so their difference is too.
##
## The terrace's wavelength is long against the bulb spacing on purpose: a straight
## capsule chord across a curved terrace sags away from it, and a short wavelength
## turns that sag into exactly the lip this scheme exists to avoid. _plan() measures
## the worst edge slope and prints it in degrees.
##
## ── WHAT THIS COSTS, MEASURED, BECAUSE THE OBVIOUS MODEL IS WRONG ────────────
##
## "cells x parts" says the march scales as cell^-3 and that the sampling grid is
## the bill. BOTH HALVES OF THAT ARE FALSE HERE. The first build measured it — 9
## bulbs at cell 0.20 gave 229 chunks, 941,294 triangles and 45,584 ms:
##
##   sampling grid          229 chunks x 18^3           = 1.34 M field evaluations
##   Iso._tri_shell         941,294 tris x 3 evals      = 2.82 M field evaluations
##                          (two for the winding test, one for the suture colour)
##   -> 9.3-11.0 us per field evaluation, and the TRIANGLES cost 2.1x the grid.
##
## So the dominant variable is SURFACE AREA, not volume, and shrinking the skin pays
## twice (fewer triangles AND fewer non-empty chunks) where coarsening the cell pays
## once and blurs the wall. That is why the bulbs are lozenges rather than boxes and
## why the passage radii were pulled in.
##
## AND COARSENING RUNS OUT, WHICH IS THE PART THAT LOOKS LIKE A FREE LUNCH AND IS
## NOT. Measured on this body at wall 0.34: cell 0.24 -> 595,372 tris / 25,149 ms;
## cell 0.26 -> 528,324 tris / 21,776 ms. That is a 1.13x triangle drop for a 1.08x
## coarser cell, i.e. tris ~ cell^-1.5, not cell^-2 — because mesh_chunk's one-cell
## overlap rim is duplicated on both sides of every chunk boundary and that rim is
## ~2 x cell / CHUNK_M of the whole surface, so a coarser cell throws away triangles
## with one hand and duplicates them with the other. At the shipped cell about a
## third of the triangles are rim duplicates. Retuning chunk_m does not help either:
## 5.0 m cuts duplicates to 26% but costs 29% more grid, and 2.0 m does the reverse;
## both land within 2% of Iso.CHUNK_M's 3.0, which is why the tested constant stays.
##
## Extrapolating the same model to what the brief hoped for, cell 0.09 is about 3.1
## minutes and 3.4 M triangles, cell 0.07 about 5.5 minutes and 5.4 M triangles.
## The minutes are survivable; 5.4 M triangles spread over ~195 concave colliders is
## not shippable geometry, so the ceiling here is the MESH, not the wait.
##
## ── WHY NOT A DNA FAMILY ──────────────────────────────────────────────────────
##
## Same reason radial_inside.gd gives: every rule in the artifact-DNA section
## assumes the evidence is one photograph from one standpoint, and for something you
## walk INSIDE every axis is anamorphic by construction. Its evidence is a walk.
## cavity_points() and graph_edges() exist so that a probe can flood-fill the cavity
## from the chambers and fail on a passage that is too narrow to pass — the two
## things a still cannot tell you.

const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")
const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")
const RHIZ_SHADER: Shader = preload("res://commons/artifacts/radial_inside/rhizome_surface.gdshader")

## The surfaces in the SHADER'S OWN uniform order — index IS the mode, so this
## array and rhizome_surface.gdshader cannot drift apart. (science_screen shipped a
## hand-typed block whose names did not match its code's enum: the sweep set an
## invalid value, the artifact fell back to its default, sixteen identical frames
## were published and every stage was green.)
const SURFACES: Array[String] = ["wetflesh", "nacre", "chitin", "film", "lymph", "bone"]

# ── the envelope, from commons/scenes/desktop_player.tscn ─────────────────────
const CAPSULE_R: float = 0.30           # the body's half-width
const BODY_H: float = 1.80              # floor to crown
const HEAD_CAP_Y: float = 1.50          # the upper cap sphere's centre, floor-relative
## sin(45 deg) — floor_max_angle as a fraction of the cavity radius. See the header.
const WALK_FRAC: float = 0.70710678
## The narrowest passage cavity this builder will deal. 1.20 gives a 1.697 m
## walkable strip and 2.40 m of centre-line headroom; the hard limits are 0.707 m
## (a 1.0 m strip) and 0.90 m (standing at all).
const PASSAGE_CAVITY_MIN: float = 1.20
const PASSAGE_CAVITY_MAX: float = 1.55
const BULB_CAVITY_MIN: float = 1.50
const BULB_CAVITY_MAX: float = 1.95
## The chambers' flat floor plate, half-extents. Small on purpose: see the cost
## note in the header — a rounded box pays 4piR per metre of (hx + hy + hz) in skin,
## which at R around 2.1 m is 26 square metres per metre, and skin is the bill.
const BULB_PLATE_MIN: float = 0.15
const BULB_PLATE_MAX: float = 0.70

# ── the graph ────────────────────────────────────────────────────────────────
## Half the footprint the chambers are scattered in. Centres live in
## [-FOOT, FOOT] on x and z; the skin reaches about 3.8 m further, so the body
## spans roughly 2 * (FOOT + 3.8).
const FOOT: float = 10.0
## Independent cycles beyond the spanning tree. TWO is the brief's floor; three
## leaves one to spare, because an extra edge can be refused for length.
const EXTRA_CYCLES: int = 3
## A passage longer than this is a corridor, which is the thing this artifact is
## an argument against. Only the spanning tree may exceed it, and only if it must.
const MAX_PASSAGE_M: float = 15.0
## Below this the two chambers' outer skins are already one lump and the "passage"
## between them says nothing. A hard floor, not taste.
const MIN_SEPARATION_M: float = 5.0

## Past this the editor visibly hangs, which is worse than a coarse body. _build()
## says so out loud rather than letting the next stage inherit the stall.
const BUDGET_MS: int = 25000

@export var seed: int = 1
## Which surface the whole body wears. INDEX IS THE SHADER MODE — see SURFACES.
@export_enum("wetflesh", "nacre", "chitin", "film", "lymph", "bone") var surface: String = "wetflesh"
## Marching cell, metres. The default was chosen by MEASURING against BUDGET_MS —
## 0.25 builds this body in about 23 s and puts 2.7 cells across the wall — and the
## header records the whole cost curve. Finer is available and honest; 0.09 is about
## three minutes and 3.4 M triangles. The print at the end of _build() is the only
## trustworthy source for what a given cell costs on a given machine.
@export_range(0.07, 0.26, 0.005) var cell: float = 0.25
## Half the shell thickness: the wall measures 2 x this across, and the cavity of a
## part of SDF radius r is r - this.
@export_range(0.18, 0.45, 0.01) var wall: float = 0.34
## The smooth-union fillet. Generous on purpose — this is what makes the graph ONE
## GROWN BODY instead of a set of joined pipes, and it is also what widens every
## junction into somewhere you can turn around.
@export_range(0.25, 1.20, 0.05) var blend: float = 0.60
@export_range(7, 12) var bulbs: int = 8

var _rng := RandomNumberGenerator.new()
var _built: bool = false
## [{c: Vector3 centre, hx/hy/hz: float half-extents, rcav: float cavity radius,
##   floor_y: float, hue: Color}]
var _bulbs: Array = []
## [[i, j], ...] into _bulbs.
var _edges: Array = []
var _parts: Array = []
var _stats: Dictionary = {}

# the terrace, set by _plan() and read by _floor_y()
var _t_amp: float = 1.1
var _t_kx: float = 0.12
var _t_kz: float = 0.12
var _t_px: float = 0.0
var _t_pz: float = 0.0


# ── what the probe and the camera are not allowed to guess ────────────────────

## The chambers' centres, in graph order.
##
## Each one is the DEEPEST point of its own cavity — the field there reads -(rcav
## + wall), so a flood fill seeded here is inside the void by more than a wall's
## thickness and cannot be sitting on a marching artefact. The standable floor is
## hy + rcav below it.
## THE MOUTH'S HALF-WIDTH, AND IT IS NOT THE DOORWAY WIDTH.
##
## 1.15 m looked right — a 2.30 m opening, over the museum's own walked verdict
## that a 1 m doorway reads as too small and every one was widened to 2 m. The
## probe blocked the player 2.70 m out anyway, and the arithmetic says why:
##
##   A SMOOTH SUBTRACTION SHRINKS THE HOLE IT BORES. field() carves with
##   -_smin(-d, cut_d, blend * 0.6), which rounds the lip inward by about that k.
##   At blend 0.60 that is 0.36 m off the radius, so a 1.15 m cutter leaves a
##   0.79 m bore.
##
##   AND A BORE IS A CYLINDER, SO ITS HEIGHT IS ITS RADIUS. The player is 1.80 m
##   tall, so the capsule needs half-height 0.90 plus its own 0.30 radius = 1.20 m
##   of clearance from the bore's axis — measured vertically, where a cylinder is
##   narrowest. 0.79 < 1.20, so the caps poked through the top and bottom of a
##   hole that was 1.58 m wide and looked ample in plan.
##
## So: 1.20 m needed, plus 0.36 m of rounding, plus margin. 1.75 leaves a bore of
## about 1.39 m against the 1.20 required. A doorway in a body is an ovoid three
## and a half metres across, which is also what the reference frames show.
const MOUTH_R: float = 1.75

## ── MAKING IT A WORLD ────────────────────────────────────────────────────────
##
## 2026-09-03, Palle: "can we put it around the museum like the world, really
## big". The obvious move is to scale every layout constant up, and it is the
## wrong one: cost tracks SURFACE AREA (measured — the per-triangle field
## evaluations run 2.1x the whole sampling grid), so a 4x body at the same cell
## is 16x the area and about 9 million triangles. Unshippable.
##
## Scaling the finished NODE keeps the triangle count exactly where it is and
## turns the cell into a world-scale facet instead: 0.25 m becomes 1.0 m at 4x,
## the wall becomes 1.36 m, chambers become 12-16 m across, and the faceting
## reads as architecture rather than as error — which is what the reference
## frames look like anyway.
##
## THE PLAYER DOES NOT SCALE, and that is the whole point of doing it this way.
## Every clearance in this file was derived from a 0.30 x 1.80 m capsule; scaling
## the body up can only ever make those clearances more generous, so a body that
## walks at 1x cannot stop walking at 4x. The reverse would need re-deriving.
##
## WHAT HAS TO BE TESTED RATHER THAN ASSUMED is the collision. Godot's own docs
## are discouraging about scaled CollisionShape3D, and a trimesh that silently
## refuses to scale would leave the visible body four times the size of the thing
## you actually bump into — a failure that looks like nothing at all until you
## walk through a wall. probe_rhizome_world.gd measures the collider's own AABB
## against the mesh's at each scale rather than trusting either.
@export_range(1.0, 8.0, 0.25) var world_scale: float = 1.0

## Where the door is and which way it faces. A map placing this body has to know,
## or the player is put down beside a sealed lump.
var _mouth_at: Vector3 = Vector3.ZERO
var _mouth_dir: Vector3 = Vector3.RIGHT


## The point just inside the mouth, in the body's own space — where a visitor
## arrives. Plans lazily, like cavity_points().
func entrance_point() -> Vector3:
	if _bulbs.is_empty():
		_plan()
	return _mouth_at


## The outward direction of the mouth: stand back along this and you are outside
## the body, looking in.
func entrance_dir() -> Vector3:
	if _bulbs.is_empty():
		_plan()
	return _mouth_dir


func cavity_points() -> Array:
	if _bulbs.is_empty():
		_plan()
	var out: Array = []
	for b_v in _bulbs:
		out.append((b_v as Dictionary)["c"])
	return out


## Which pairs of chambers a passage was BUILT between — the claim a walk test can
## falsify. A pair listed here that a flood fill cannot get between is a passage
## that marched too narrow to pass, which is invisible in any still.
func graph_edges() -> Array:
	if _bulbs.is_empty():
		_plan()
	var out: Array = []
	for e_v in _edges:
		var e: Array = e_v
		out.append([int(e[0]), int(e[1])])
	return out


## Everything _build() printed, as data. A probe that re-derives the triangle count
## is measuring its own arithmetic, not the build.
func build_stats() -> Dictionary:
	return _stats.duplicate(true)


# ── the grid contract ────────────────────────────────────────────────────────

## COERCE, THEN READ BACK. Map config arrives as JSON Variants, and Object.set() on
## a typed property of the wrong type is refused IN SILENCE — the corpus lost a
## whole sweep to exactly that (an int handed to an @export_enum String, sixteen
## identical frames, every stage green). So every value is converted to the
## property's own type first, and the assignment is verified afterwards.
func apply_grid_config(config: Dictionary) -> void:
	var before: Dictionary = {}
	for k in ["seed", "surface", "cell", "wall", "blend", "bulbs", "world_scale"]:
		before[k] = get(k)
	if config.has("seed"):
		set("seed", int(config["seed"]))
	if config.has("bulbs"):
		set("bulbs", int(config["bulbs"]))
	for k in ["cell", "wall", "blend"]:
		if config.has(k):
			set(k, float(config[k]))
	if config.has("surface"):
		var s: Variant = config["surface"]
		# a token may carry the INDEX rather than the name; both are legitimate and
		# neither may fall through to a silent default
		if s is int or s is float:
			var i: int = clampi(int(s), 0, SURFACES.size() - 1)
			set("surface", SURFACES[i])
		else:
			var name: String = str(s)
			if SURFACES.has(name):
				set("surface", name)
			else:
				push_warning("[rhizome_inside] surface '%s' is not one of %s — keeping '%s'"
					% [name, str(SURFACES), surface])
	for k in before.keys():
		if config.has(k) and get(k) == before[k] and str(before[k]) != str(config[k]):
			push_warning("[rhizome_inside] config '%s' did not take: still %s after being handed %s"
				% [k, str(get(k)), str(config[k])])
	if is_inside_tree():
		_built = false
		_build()


func _ready() -> void:
	_build()


# ── the plan: a graph, and it is checked before anything is marched ───────────

## The terrace. Everything in this building is placed by its FLOOR, and this is the
## floor. Long wavelength against the chamber spacing on purpose: see the header.
func _floor_y(x: float, z: float) -> float:
	return _t_amp * sin(x * _t_kx + _t_px) * cos(z * _t_kz + _t_pz)


func _plan() -> void:
	_rng.seed = seed
	_bulbs.clear()
	_edges.clear()
	_stats.clear()

	# THE TERRACE'S GRADIENT IS BOUNDED BY ARITHMETIC, NOT BY HOPE.
	# |grad| <= amp * sqrt(kx^2 + kz^2), so with amp <= 1.4 and a wavelength of at
	# least 46 m the steepest the ground can ever tilt is 1.4 * 0.1932 = 0.270,
	# i.e. 15.1 degrees — comfortably inside floor_max_angle 45 and, more to the
	# point, gentle enough that a straight passage chord does not sag away from the
	# terrace and leave a lip where two passages cross.
	_t_amp = _rng.randf_range(0.8, 1.4)
	_t_kx = TAU / _rng.randf_range(46.0, 62.0)
	_t_kz = TAU / _rng.randf_range(46.0, 62.0)
	_t_px = _rng.randf_range(0.0, TAU)
	_t_pz = _rng.randf_range(0.0, TAU)

	var n: int = clampi(bulbs, 7, 12)

	# BEST-CANDIDATE SCATTER, NOT A LATTICE. A jittered grid always succeeds and
	# always reads as a grid from above, which is the corridor plan wearing a
	# different hat. Dart throwing can fail to place the last point. Best-candidate
	# (draw 64, keep the most isolated) always succeeds AND gives blue noise, and
	# the separation it actually achieved is measured below rather than assumed.
	var flat: Array = []
	for i in range(n):
		var best := Vector2.ZERO
		var best_d: float = -1.0
		for _k in range(64):
			var cand := Vector2(_rng.randf_range(-FOOT, FOOT), _rng.randf_range(-FOOT, FOOT))
			var d: float = 1.0e9
			for q_v in flat:
				d = minf(d, cand.distance_to(q_v))
			if flat.is_empty():
				d = 1.0                       # nothing to be far from yet
			if d > best_d:
				best_d = d
				best = cand
		flat.append(best)

	var min_sep: float = 1.0e9
	for i in range(n):
		for j in range(i + 1, n):
			min_sep = minf(min_sep, (flat[i] as Vector2).distance_to(flat[j] as Vector2))
	if min_sep < MIN_SEPARATION_M:
		# Not fatal — two chambers merging into one lobe is a legitimate rhizome —
		# but it means one of the printed "passages" is a bulge, so it is said.
		push_warning("[rhizome_inside] closest chambers are %.2f m apart (want %.1f) — that passage will read as a bulge"
			% [min_sep, MIN_SEPARATION_M])

	for i in range(n):
		var f: Vector2 = flat[i]
		var rcav: float = _rng.randf_range(BULB_CAVITY_MIN, BULB_CAVITY_MAX)
		var hx: float = _rng.randf_range(BULB_PLATE_MIN, BULB_PLATE_MAX)
		var hz: float = _rng.randf_range(BULB_PLATE_MIN, BULB_PLATE_MAX)
		var hy: float = _rng.randf_range(0.0, 0.20)
		var fl: float = _floor_y(f.x, f.y)
		# placed by its FLOOR: centre = floor + hy + rcav, so the flat plate at the
		# bottom of the rounded box lands exactly on the terrace
		_bulbs.append({
			"c": Vector3(f.x, fl + hy + rcav, f.y),
			"hx": hx, "hy": hy, "hz": hz,
			"rcav": rcav,
			"floor_y": fl,
			"hue": Gloss.queer_colour(_rng),
		})

	_wire(n)

	# ── the assertions, BEFORE anything is marched ───────────────────────────
	var comp: int = _components(n)
	var rank: int = _edges.size() - n + comp        # first Betti number
	var connected: bool = comp == 1
	if not connected:
		# assert() is STRIPPED FROM RELEASE BUILDS, so it cannot be the gate — it is
		# the editor-time stop and push_error is the one that survives an export.
		push_error("[rhizome_inside] the plan is not a rhizome: %d bulbs fall into %d components"
			% [n, comp])
	if rank < 2:
		push_error("[rhizome_inside] the plan is a TREE (%d edges, %d bulbs, cycle rank %d) — one route through, which is the corridor this artifact argues against"
			% [_edges.size(), n, rank])
	assert(connected, "rhizome_inside: disconnected plan")
	assert(rank >= 2, "rhizome_inside: no cycles, the plan is a tree")

	# the worst floor slope any passage asks the player to climb
	var worst_deg: float = 0.0
	var longest: float = 0.0
	for e_v in _edges:
		var e: Array = e_v
		var a: Vector3 = (_bulbs[int(e[0])] as Dictionary)["c"]
		var b: Vector3 = (_bulbs[int(e[1])] as Dictionary)["c"]
		var run: float = Vector2(a.x - b.x, a.z - b.z).length()
		longest = maxf(longest, run)
		var rise: float = absf(float((_bulbs[int(e[0])] as Dictionary)["floor_y"])
			- float((_bulbs[int(e[1])] as Dictionary)["floor_y"]))
		worst_deg = maxf(worst_deg, rad_to_deg(atan2(rise, maxf(run, 0.001))))
	if worst_deg > 30.0:
		push_warning("[rhizome_inside] a passage floor climbs at %.1f degrees — floor_max_angle is 45, so this is walkable but it is a ramp, not a room"
			% worst_deg)

	_stats = {
		"bulbs": n,
		"passages": _edges.size(),
		"cycle_rank": rank,
		"components": comp,
		"min_separation_m": min_sep,
		"longest_passage_m": longest,
		"worst_floor_deg": worst_deg,
		"walk_strip_m": 2.0 * WALK_FRAC * PASSAGE_CAVITY_MIN,
		"headroom_m": 2.0 * PASSAGE_CAVITY_MIN,
	}
	print("[rhizome_inside] plan: %d bulbs, %d passages, cycle rank %d (%d component) | closest pair %.2f m, longest passage %.2f m, worst floor %.1f deg | narrowest cavity %.2f m -> walkable strip %.2f m, headroom %.2f m"
		% [n, _edges.size(), rank, comp, min_sep, longest, worst_deg,
			PASSAGE_CAVITY_MIN, 2.0 * WALK_FRAC * PASSAGE_CAVITY_MIN, 2.0 * PASSAGE_CAVITY_MIN])


## Spanning tree by Kruskal, then the cycles.
##
## Kruskal on the complete graph cannot fail to connect, which is why the check
## afterwards is a gate on THIS CODE rather than a repair path — if it ever fires,
## something in here is wrong and the body should not be built at all.
func _wire(n: int) -> void:
	var pairs: Array = []
	for i in range(n):
		for j in range(i + 1, n):
			var a: Vector3 = (_bulbs[i] as Dictionary)["c"]
			var b: Vector3 = (_bulbs[j] as Dictionary)["c"]
			pairs.append([Vector2(a.x - b.x, a.z - b.z).length(), i, j])
	pairs.sort_custom(func(x, y): return float(x[0]) < float(y[0]))

	var parent: Array = []
	for i in range(n):
		parent.append(i)
	var deg: Array = []
	for i in range(n):
		deg.append(0)

	for p_v in pairs:
		var p: Array = p_v
		var i: int = int(p[1])
		var j: int = int(p[2])
		if _find(parent, i) == _find(parent, j):
			continue
		parent[_find(parent, i)] = _find(parent, j)
		_edges.append([i, j])
		deg[i] += 1
		deg[j] += 1

	# THE CYCLES. Not decoration: a spanning tree has exactly one route between any
	# two chambers, so a tree-shaped rhizome is a branching corridor and the whole
	# claim collapses. The extras are the shortest non-tree pairs that stay under
	# MAX_PASSAGE_M and do not turn one chamber into a hub — a degree cap keeps the
	# cycles spread through the body instead of all hanging off the middle.
	var added: int = 0
	for p_v in pairs:
		if added >= EXTRA_CYCLES:
			break
		var p: Array = p_v
		var i: int = int(p[1])
		var j: int = int(p[2])
		if float(p[0]) > MAX_PASSAGE_M:
			break                                  # sorted, so nothing later is shorter
		if _has_edge(i, j) or deg[i] >= 4 or deg[j] >= 4:
			continue
		_edges.append([i, j])
		deg[i] += 1
		deg[j] += 1
		added += 1
	if added < 2:
		push_warning("[rhizome_inside] only %d extra passage(s) could be placed under %.0f m — the plan is nearly a tree"
			% [added, MAX_PASSAGE_M])


func _find(parent: Array, i: int) -> int:
	while int(parent[i]) != i:
		parent[i] = parent[int(parent[i])]
		i = int(parent[i])
	return i


func _has_edge(i: int, j: int) -> bool:
	for e_v in _edges:
		var e: Array = e_v
		if (int(e[0]) == i and int(e[1]) == j) or (int(e[0]) == j and int(e[1]) == i):
			return true
	return false


## Connected components of the FINAL edge list, walked independently of the
## union-find that built it — a check that reuses the structure under test proves
## nothing about it.
func _components(n: int) -> int:
	var seen: Array = []
	for i in range(n):
		seen.append(false)
	var comps: int = 0
	for s in range(n):
		if bool(seen[s]):
			continue
		comps += 1
		var stack: Array = [s]
		seen[s] = true
		while not stack.is_empty():
			var cur: int = int(stack.pop_back())
			for e_v in _edges:
				var e: Array = e_v
				var other: int = -1
				if int(e[0]) == cur:
					other = int(e[1])
				elif int(e[1]) == cur:
					other = int(e[0])
				if other >= 0 and not bool(seen[other]):
					seen[other] = true
					stack.append(other)
	return comps


# ── the field: ONE parts array, so the graph comes back as ONE body ───────────

func _grow_parts() -> Array:
	var parts: Array = []

	# the chambers. A rounded box, not a sphere: the flat plate is the only level
	# floor in the building and it is where you actually stand.
	for b_v in _bulbs:
		var b: Dictionary = b_v
		parts.append(_hued(Iso.box(b["c"],
			Vector3(float(b["hx"]), float(b["hy"]), float(b["hz"])),
			float(b["rcav"]) + wall), b["hue"]))

	# the passages. TWO capsules through a bowed midpoint, not one straight tube:
	#   a straight chord sags away from a curved terrace, and the sag is exactly the
	#     lip that two crossing passages would step over;
	#   a bowed midpoint makes the passage BEND, which is the difference between a
	#     rhizome and a wiring diagram;
	#   and the midpoint is placed on the terrace like everything else, so the kink
	#     is horizontal only and the floor stays a straight ramp on each half.
	for e_v in _edges:
		var e: Array = e_v
		var bi: Dictionary = _bulbs[int(e[0])]
		var bj: Dictionary = _bulbs[int(e[1])]
		var ci: Vector3 = bi["c"]
		var cj: Vector3 = bj["c"]
		var fi := Vector2(ci.x, ci.z)
		var fj := Vector2(cj.x, cj.z)
		var dir2: Vector2 = (fj - fi).normalized()
		var nrm2 := Vector2(-dir2.y, dir2.x)
		var span: float = fi.distance_to(fj)
		var bow: float = _rng.randf_range(-0.16, 0.16) * span
		var fm: Vector2 = (fi + fj) * 0.5 + nrm2 * bow

		# cavity radii at the three nodes: a pinch or a swell, never below the
		# standing minimum
		var r0: float = _rng.randf_range(PASSAGE_CAVITY_MIN, PASSAGE_CAVITY_MAX)
		var r1: float = _rng.randf_range(PASSAGE_CAVITY_MIN, PASSAGE_CAVITY_MAX)
		var r2: float = _rng.randf_range(PASSAGE_CAVITY_MIN, PASSAGE_CAVITY_MAX)

		# EVERY NODE IS AXIS = FLOOR + CAVITY RADIUS. A tapering capsule stays level
		# because Iso.capsule lerps its radius linearly in the same parameter the
		# axis is linear in, so floor = axis - (r - wall) is linear too. Position a
		# taper by its centre line instead and one end of every passage lifts off
		# the ground.
		var p0 := Vector3(fi.x, float(bi["floor_y"]) + r0, fi.y)
		var p1 := Vector3(fm.x, _floor_y(fm.x, fm.y) + r1, fm.y)
		var p2 := Vector3(fj.x, float(bj["floor_y"]) + r2, fj.y)

		var hi: Color = bi["hue"]
		var hj: Color = bj["hue"]
		parts.append(_hued(Iso.capsule(p0, p1, r0 + wall, r1 + wall), hi.lerp(hj, 0.35)))
		parts.append(_hued(Iso.capsule(p1, p2, r1 + wall, r2 + wall), hi.lerp(hj, 0.65)))

	# ── THE MOUTH ────────────────────────────────────────────────────────────
	#
	# A HOLLOW BODY IS SEALED, AND THAT IS NOT A DETAIL. abs(f) - wall gives a
	# CLOSED shell: an outer skin, an inner skin, and no way between them. Every
	# measurement this thing has passed — 8 of 8 chambers standable, 10 of 10
	# passages passable, 8 of 8 reachable — was taken by a probe that started
	# INSIDE, so all of them were true and none of them noticed that a visitor
	# standing on the floor outside has no door. The probe measured the building
	# and never asked how you get in.
	#
	# So one chamber is bored. The cut runs horizontally from well outside the
	# body's own extent into the chamber's cavity, at the WALKING level — the
	# chamber's floor plus its cavity radius, which is where the axis of a
	# passage sits — so the mouth's sill is the floor you are already standing on
	# and there is no lip. There is no step height in this engine, so a sill of
	# any size would be a wall.
	#
	# 1.15 m of radius gives a 2.30 m opening, over the museum's own walked
	# verdict that 1 m doorways read as too small and every one was widened to 2.
	if not _bulbs.is_empty():
		var b0: Dictionary = _bulbs[_mouth_bulb()]
		var c0: Vector3 = b0["c"]
		var stand: float = float(b0["floor_y"]) + float(b0["rcav"])
		# outward along whichever horizontal axis reaches open air soonest
		var out_dir: Vector3 = Vector3(c0.x, 0.0, c0.z)
		if out_dir.length_squared() < 0.01:
			out_dir = Vector3.RIGHT
		out_dir = out_dir.normalized()
		var inner: Vector3 = c0 + Vector3(0.0, stand - c0.y, 0.0)
		var outer: Vector3 = inner + out_dir * (float(b0["hx"]) + float(b0["hz"]) + float(b0["rcav"]) + wall * 4.0 + 3.0)
		_mouth_at = inner
		_mouth_dir = out_dir
		parts.append(Iso.cut(Iso.capsule(inner, outer, MOUTH_R, MOUTH_R)))
	return parts


## Which chamber gets the door: the one furthest from the body's own centre, so
## the mouth opens on open air rather than boring through a neighbour on its way
## out. Measured per seed rather than assumed, because the graph is dealt.
func _mouth_bulb() -> int:
	var mid := Vector3.ZERO
	for b_v in _bulbs:
		mid += (b_v as Dictionary)["c"] as Vector3
	mid /= float(maxi(_bulbs.size(), 1))
	var best: int = 0
	var far: float = -1.0
	for i in range(_bulbs.size()):
		var c: Vector3 = (_bulbs[i] as Dictionary)["c"]
		var d: float = Vector2(c.x - mid.x, c.z - mid.z).length()
		if d > far:
			far = d
			best = i
	return best


## A part's dealt hue, which dream_iso bakes into every vertex it marches near it.
## Without this every limb is the shader's fallback grey and the suture has nothing
## to attribute — the wall stops being able to say which limb you are in.
func _hued(part: Dictionary, col: Color) -> Dictionary:
	part["hue"] = col
	return part


# ── the build ────────────────────────────────────────────────────────────────

func _build() -> void:
	if _built:
		return
	_built = true
	for c in get_children():
		c.queue_free()
	# uniform only: a non-uniform scale on a collision shape is unsupported and
	# would deform the walls away from the geometry you can see
	var k: float = maxf(world_scale, 0.01)
	scale = Vector3(k, k, k)

	_plan()
	if _stats.get("components", 1) != 1:
		# a disconnected plan already pushed an error; marching it would produce a
		# convincing-looking body that is not the thing that was asked for
		return
	_parts = _grow_parts()

	var cell_c: float = clampf(cell, 0.07, 0.26)
	# THE WALL HAS TO BE RESOLVABLE OR THE TWO SKINS MERGE INTO ONE LUMP. The shell
	# occupies -wall..+wall of field, so it is 2 * wall / cell cells thick; under
	# about two and a half the marcher starts joining the inner skin to the outer
	# one across a single cell and the cavity closes in patches — which looks like
	# an interestingly lumpy interior and is actually a body you cannot walk
	# through. Said out loud because nothing downstream can tell the difference.
	var wall_cells: float = 2.0 * wall / cell_c
	if wall_cells < 2.5:
		push_warning("[rhizome_inside] the wall is only %.1f cells thick (wall %.2f at cell %.3f) — raise wall or lower cell before trusting the cavity"
			% [wall_cells, wall, cell_c])
	var t0: int = Time.get_ticks_msec()
	var chunks: Array = Iso.mesh_rhizome(_parts, cell_c, blend, wall, Iso.CHUNK_M, 0.35)
	var t_march: int = Time.get_ticks_msec() - t0

	var t1: int = Time.get_ticks_msec()
	var mat: ShaderMaterial = _skin()
	var tris: int = 0
	var lo := Vector3(1.0e9, 1.0e9, 1.0e9)
	var hi := Vector3(-1.0e9, -1.0e9, -1.0e9)
	for i in range(chunks.size()):
		var ch: Dictionary = chunks[i]
		var mesh: ArrayMesh = ch["mesh"]
		var mi := MeshInstance3D.new()
		# "Chunk<N>" IS THE CONTRACT — a probe finds the body by this name, so it is
		# not a label, it is an interface.
		mi.name = "Chunk%d" % i
		mi.mesh = mesh
		# ONE material for every chunk. A ShaderMaterial per chunk would be ~250
		# copies of the same pipeline state for no visual difference.
		mi.material_override = mat
		add_child(mi)

		# THE COLLIDER IS THE INNER SKIN, AND ITS FACING IS LOAD-BEARING.
		# ConcavePolygonShape3D has backface_collision off by default: it only
		# resolves from the FRONT side. dream_iso winds every shell triangle away
		# from the material, so the inner skin's front faces point into the cavity —
		# which is where the player is. Get that backwards and the player falls
		# through a floor that renders perfectly.
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		cs.shape = mesh.create_trimesh_shape()
		body.add_child(cs)
		mi.add_child(body)

		# COUNT WITHOUT COPYING THE VERTEX ARRAY. surface_get_arrays() would hand
		# back every position, normal and colour of ~250 chunks just to divide by
		# three; the lengths are metadata. Index length first, because a mesh that
		# ever gains an index array would otherwise be counted by its vertex count
		# and report a triangle total that is quietly wrong.
		var il: int = mesh.surface_get_array_index_len(0)
		tris += (il if il > 0 else mesh.surface_get_array_len(0)) / 3

		var ab: AABB = mesh.get_aabb()
		lo = Vector3(minf(lo.x, ab.position.x), minf(lo.y, ab.position.y), minf(lo.z, ab.position.z))
		var e: Vector3 = ab.position + ab.size
		hi = Vector3(maxf(hi.x, e.x), maxf(hi.y, e.y), maxf(hi.z, e.z))
	var t_nodes: int = Time.get_ticks_msec() - t1
	var total: int = t_march + t_nodes

	if chunks.is_empty():
		# A BODY THAT DOES NOT EXIST LOOKS EXACTLY LIKE AN EMPTY MAP CELL. Every
		# fallback downstream of here is silent by design, so this is the only place
		# it can be said.
		push_error("[rhizome_inside] marched NOTHING from %d part(s) at cell %.3f, wall %.2f, blend %.2f — check that wall is smaller than the narrowest cavity radius"
			% [_parts.size(), cell_c, wall, blend])

	_stats["parts"] = _parts.size()
	_stats["chunks"] = chunks.size()
	_stats["triangles"] = tris
	_stats["march_ms"] = t_march
	_stats["nodes_ms"] = t_nodes
	_stats["build_ms"] = total
	_stats["cell"] = cell_c
	_stats["wall"] = wall
	_stats["blend"] = blend
	_stats["aabb_lo"] = lo
	_stats["aabb_hi"] = hi
	_stats["surface"] = surface

	print("[rhizome_inside] %d part(s) -> %d chunk(s), %d triangle(s) | march %d ms + nodes %d ms = %d ms | cell %.3f, wall %.2f, blend %.2f, surface '%s' | span %.1f x %.1f x %.1f m"
		% [_parts.size(), chunks.size(), tris, t_march, t_nodes, total, cell_c, wall, blend,
			surface, hi.x - lo.x, hi.y - lo.y, hi.z - lo.z])
	if total > BUDGET_MS:
		push_warning("[rhizome_inside] the build took %d ms against a %d ms budget — raise `cell` (cost goes as cell^-3) or drop a bulb before this ships"
			% [total, BUDGET_MS])


## The surface. ONE ShaderMaterial for the whole body, because the limb identity is
## already carried per-vertex by the marcher — the shader reads COLOR, not a
## material per chunk.
func _skin() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = RHIZ_SHADER
	var mode: int = SURFACES.find(surface)
	if mode < 0:
		push_warning("[rhizome_inside] surface '%s' is not in SURFACES — falling back to '%s'"
			% [surface, SURFACES[0]])
		mode = 0
	# EVERY NAME HERE EXISTS IN rhizome_surface.gdshader. A shader parameter that
	# does not exist is DISCARDED and still reads back the value you set, so a typo
	# is invisible from GDScript and shows up only as a surface that ignores you.
	m.set_shader_parameter("mode", mode)
	m.set_shader_parameter("tint", Color(1.0, 1.0, 1.0, 1.0))
	# the suture reads as the fusion it is: a hot line, not a panel gap
	m.set_shader_parameter("suture_color", Color(1.0, 0.30, 0.62, 1.0))
	m.set_shader_parameter("limb_mix", 0.85)
	# THE SUTURE FLOOR HAS TO SCALE WITH THE BLEND, and 0.55 was measured wrong.
	#
	# COLOR.a is 1 where the nearest and second-nearest parts are tied and falls
	# to 0 a BLEND-WIDTH away. At blend 0.60 on a body whose parts are metres
	# apart, almost every point on the skin is within a blend-width of a second
	# part, so alpha is high nearly everywhere and a floor of 0.55 lit the entire
	# interior pink — a seam everywhere is the same as no seam, and the surfaces
	# underneath could not be seen at all. 0.88 keeps only a genuine fusion.
	m.set_shader_parameter("suture_floor", 0.88)
	m.set_shader_parameter("suture_energy", 1.5)
	m.set_shader_parameter("grain", 1.0)
	m.set_shader_parameter("glow", 0.35)
	m.set_shader_parameter("seed_offset", float(seed % 997) * 0.31)
	return m
