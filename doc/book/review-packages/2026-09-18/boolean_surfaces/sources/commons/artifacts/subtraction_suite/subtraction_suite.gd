extends Node3D
class_name SubtractionSuite

# @identity
# essence: one subtraction, three institutions, on one bench. A cube minus an oversized sphere told as ART on a gallery plinth (the void that breaches every face, and nothing explained), as OPERATOR on a lectern in front of a board (the SAME carved solid, with A and B ghosted back into place so the operation is visible and not only its answer), and as CATALOGUE on a laboratory tray (five decompositions of one sphere, each held apart). The art station and the operator station are geometrically IDENTICAL at every value: what differs between them is the furniture and the palette, which is the exhibit's first claim.
# desire: it wants to find out whether a shared word survives translation. `breach` belongs to fontana_puncture, where its four values are four topologically distinct objects cut against the cube's own critical distances. This bench asks the same word of three framings at once and photographs the answer, including the answer where the word fails.
# critical_parameter: breach. Not a size knob and not a spread knob: at the plinth and the lectern it is the radius of the void as a fraction of the body, so the four values are the four surviving topologies; on the tray it is separation as a fraction of the specimen radius, because a partitioned sphere has no critical distances for the ratio to land on. Same number, two kinds of quantity.
# triggers: _ready builds all three stations and bakes the four CSG combiners to static meshes on the next idle frame; apply_grid_config rebuilds only when a config names `breach`, names a value fontana's own table holds, names a DIFFERENT one, and _ready has already built.
# emerges: that a vocabulary is not portable just because a word is. The cube has three critical distances (half-extent, edge-midpoint, corner) and the ladder's rungs are those distances; a sphere has one, a partition has none. Two of the three stations keep the rungs. The third keeps only the order — and seeing that beside two stations where the word does its full work is what makes the failure legible instead of theoretical.
# needs: a body with corners to survive in [the cube, present twice]; the operation shown as well as its result [ghosted operands, present]; a body without corners to fail on [the sphere tray, present]; three furnitures so the framings are read before the captions are [plinth, lectern-and-board, tray, present]
# relationships: synthesised from `fontana_puncture` (breach, strike), `csg_difference_demo` (workings, strike), `csg_compose_workbench` (algebra, strike) and `sphere_splitting_showcase` (comparison). It replaces none of them: each still argues alone in the maps that place it, and nothing here can be cut by a player. Kin to `exhibit_furniture`, whose `house` axis taught this corpus that a collection's furniture is an argument about the institution and not a mount.
# truth: a cut is not one thing. Called art it is a void that breaches every face and explains nothing; called an operator it is A minus B with both terms still on the table; called a catalogue it is five different answers to what a part is. The bench holds all three at one depth of cut, and the depth is measurable in two of the three because a measurement needs an edge to be measured against.
# @qfep_term: F.

## Subtraction suite — three stations, one cut, one axis.
##
## SERIES synthesis (doc/plans/ARTIFACT_SYNTHESIS_PLAN.md, "the subtraction suite").
## Built at bench scale from scratch: NOT an instancing of the four sources, which
## each carry their own room, their own labels and, in one case, its own
## WorldEnvironment. Everything here is procedural in _ready and deterministic.

# --- DNA (stage: synthesis, born promoted 2026-08-06) ------------------------
#
# THE ONE AXIS, AND WHY IT IS ONE. `breach` is reused from [[fontana_puncture]]
# CHARACTER FOR CHARACTER — same word, same four values, same order — and it is
# not retyped: BREACHES below is read at load out of fontana_puncture.gd's own
# `const BREACH`, which is the slot_machine pattern. The vocabulary cannot drift
# from the family even if somebody edits the family, and the ratios cannot drift
# either, because the ratios are what is read.
#
# WHAT THE WORD MEANS AT EACH STATION, and this is the whole experiment:
#
#   ART       (gallery plinth). Void radius = ratio x body_size, exactly fontana's
#             construction. The ladder is SCALE-FREE, so at body_size 0.36 the four
#             values are the same four topological states they are at 0.5. Checked,
#             not assumed — the cube's three critical distances at 0.36 are
#             half-extent 0.1800, edge-midpoint 0.2546, corner 0.3118, and the four
#             void radii are 0.1944, 0.2448, 0.2664, 0.2880. So pierced breaches the
#             faces and stops (0.1944 > 0.1800), opened is still connected
#             (0.2448 < 0.2546), severed cuts the twelve edges into eight corner
#             pieces (0.2664 > 0.2546) and husk stops short of annihilation
#             (0.2880 < 0.3118). Four objects, not four sizes.
#
#   OPERATOR  (lectern and board). The SAME construction and the same numbers, so
#             the surviving solid is geometrically identical to the one on the
#             plinth — deliberately, because the exhibit's first claim is that the
#             difference between an artwork and a demonstration is not in the object.
#             What the station adds is A and B ghosted back in place, and that is
#             where breach becomes VISIBLE AS A QUANTITY rather than as a state: you
#             watch B outgrow A's half-extent. Same number, read as a proportion
#             because the operands are on the table.
#
#   CATALOGUE (laboratory tray). Here the word does NOT carry, and the exhibit is
#             built to show that rather than to hide it. A sphere has exactly one
#             critical distance, its radius; a partition of a sphere has none at all,
#             because a partition has no connectivity left to lose — every plate is
#             already in pieces at `pierced`. So the ratio is applied as SEPARATION,
#             d = ratio x specimen_radius, and what the four values give the tray is
#             an order without thresholds.
#             MEASURED, not asserted: for a radial explosion of a lat/lon partition,
#             the gap opened between two adjacent cells whose centroid directions
#             differ by an angle t is 2*d*sin(t/2), and the cell's own arc width is
#             t*R, so the RELATIVE opening is 2*sin(t/2)/t x d/R. That factor is
#             0.9003 at t = 90 degrees, 0.9745 at 45, 0.9886 at 30 — within ten per
#             cent of 1 for every division on this tray. Both the gap and the width
#             carry the same sin(v) factor away from the equator, so it holds at the
#             poles too. The consequence is exact and unwelcome: `breach` opens the
#             48-tile plate and the 8-wedge plate by the SAME fraction of themselves.
#             It cannot distinguish the five bases, which is the one thing a
#             catalogue exists to do. The single exception is the coarsest plate: two
#             hemispheres separate along a diameter, t = 180 degrees, so the gap is
#             2*d against a part depth of R and the planar plate opens about twice as
#             fast relative to itself as any other. Where the ladder distinguishes
#             anything on this tray it distinguishes the 2-part plate from the other
#             four, and nothing else.
#
# THE HONEST VERDICT, on the record: the shared word survives at two stations as a
# measured ratio and at the third only as an order. `breach` names a topological
# ladder that exists where the body has corners. Fontana chose a cube; that choice
# is doing more work than the word does.
#
# WHAT IS DECLINED, and why each refusal is the design.
#   strike (the family's most-shared word, on all three CSG sources, character for
#     character in each) — refused. The tray has no B to place. Two stations would
#     answer identically (they are the same geometry) and the third would be blank,
#     so the word would produce one repeated answer and one null cell. That is
#     [[sphere_splitting_showcase]]'s own refusal reason for its `exploded` axis —
#     an axis that is a null cell for part of the bench is a finished-looking
#     experiment about the rest — and a shared-word test is worth running only if
#     the stations are able to DISAGREE. Under breach they do; under strike they
#     cannot.
#   workings — refused twice over. [[csg_compose_workbench]] already declined it on
#     the ground that its sibling holds it, and the same fence stands here. Worse:
#     at workings=outcome the operator station would stop showing the operation and
#     become a second art station, so the value would delete one of the three
#     framings. A value that erases a station is an edit to the exhibit, not a turn
#     of an axis.
#   algebra — [[csg_compose_workbench]]'s word, and adding union and intersection
#     would change the subject from what a cut IS to what the operator set is. This
#     bench is about one operator told three ways.
#   comparison — [[sphere_splitting_showcase]]'s word. The tray always shows all
#     five bases, because it is one station of three: subsetting it would make the
#     catalogue argue with itself instead of with its neighbours.
#   THE OBVIOUS REPAIR IS REFUSED TOO. Making the specimens CUBES would give the
#     tray fontana's three critical distances and the word would transfer perfectly
#     to all three stations. That is fitting the exhibit to the vocabulary. The
#     catalogue's source is five ways to break a SPHERE; the sphere is why the word
#     fails, and the failure is the finding.
#
# CAPTURE. One still is a complete account: no _process, no timers, no physics, no
# randf, no seed needed because nothing is random. The four CSG combiners are baked
# to MeshInstance3D on the next idle frame (bake_static_mesh), because the capture
# AABB counts MeshInstance3D and a live CSGShape3D is invisible to it; a layers = 0
# extent anchor sized to the bench's own furniture holds the frame even if a bake
# returns null on an early headless frame, AND pins the camera across all four
# values so no part of a bite report is the camera moving. No combiner is nested in
# another combiner — a CSGCombiner3D inside a combiner is a shape, not a container.

## fontana_puncture's own table, preloaded rather than transcribed. Its keys ARE the
## value list and its floats ARE the ratios, so neither can drift from the family.
const FONTANA_SOURCE := preload("res://commons/primitives/fontana_puncture/fontana_puncture.gd")

## sphere_splitting_showcase.BENCH_ALL, in its shipped order. Written out rather than
## preloaded: that script extends a vector_scene_base and preloads five destructible
## scenes, so pulling it in for a five-element order would drag a whole test scene
## behind one array. An ORDER is not a vocabulary — the axis vocabulary is the thing
## held by preload above.
const PLATES: PackedStringArray = ["planar", "octree", "sectored", "csg", "segmented"]

# Bench geometry. Every literal here is furniture, not argument.
const BASE_H: float = 0.04
const BENCH_D: float = 1.00
const PLINTH_H: float = 0.92
const TABLE_H: float = 0.70
const POST_H: float = 0.14
const CAB_H: float = 0.66
const TRAY_H: float = 0.045
const ANCHOR_H: float = 1.58
const LABEL_Y: float = 1.46

# Palettes, each its source's own.
const FONTANA_RED: Color = Color(0.70, 0.07, 0.07)      # fontana_puncture.cube_color
const DEPTH_COLOR: Color = Color(0.98, 0.92, 0.70)      # fontana_puncture.depth_color
const DEMO_BODY: Color = Color(0.70, 0.60, 0.95)        # csg_difference_demo.body_color
const CUT_COLOR: Color = Color(1.00, 0.55, 0.35)        # csg_difference_demo.CUT_COLOR
const WHITE_CUBE: Color = Color(0.90, 0.89, 0.86)
const SLATE: Color = Color(0.20, 0.23, 0.26)
const STEEL: Color = Color(0.62, 0.65, 0.68)
const BONE: Color = Color(0.86, 0.85, 0.80)
const BASE_COLOR: Color = Color(0.24, 0.24, 0.25)

@export_group("Form")
@export_enum("pierced", "opened", "severed", "husk") var breach: String = "opened"
## Metres between station centres. The base slab is three of these wide.
@export var station_pitch: float = 0.96
## Edge of the cube at BOTH the art station and the operator station. They are the
## same body on purpose.
@export var body_size: float = 0.36
## Radius of one tray specimen before its parts are displaced.
@export var specimen_radius: float = 0.075

## The vocabulary and the ratios, read from the family rather than retyped.
var _breach_table: Dictionary = FONTANA_SOURCE.BREACH

var _built: bool = false
## Combiners waiting for their one idle frame before they can be baked.
var _pending: Array = []


func _ready() -> void:
	if has_meta("config_breach"):
		var m: String = str(get_meta("config_breach")).strip_edges().to_lower()
		if _breach_table.has(m):
			breach = m
	_build()


## Guarded three ways, which is the trap that cost force_pad a batch: rebuild only
## when the config NAMES this axis, names a value the family's own table holds, names
## a DIFFERENT one than the bench is already standing at, and _ready has built once.
## A config that names nothing here reaches no assignment and tears nothing down.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("breach"):
		return
	var want: String = str(config_data["breach"]).strip_edges().to_lower()
	if not _breach_table.has(want):
		return
	if want == breach:
		return
	breach = want
	set_meta("config_breach", want)
	if not _built:
		return
	for c in get_children():
		c.queue_free()
	_pending.clear()
	_built = false
	_build()


## fontana's ratio for a value. Falls back to the shipped default and then to its
## literal, so a rename upstream degrades to the family's own default rather than to
## zero — a void of radius 0 would render an uncut cube and read as an inert axis.
func _ratio(which: String) -> float:
	if _breach_table.has(which):
		return float(_breach_table[which])
	if _breach_table.has("opened"):
		return float(_breach_table["opened"])
	return 0.68


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	var ratio: float = _ratio(breach)
	_build_base()
	_build_art(-station_pitch, ratio)
	_build_operator(0.0, ratio)
	_build_catalogue(station_pitch, ratio)
	_build_anchor()
	_built = true
	call_deferred("_bake_pending")


func _build_base() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Base"
	var bm := BoxMesh.new()
	bm.size = Vector3(station_pitch * 3.0, BASE_H, BENCH_D)
	mi.mesh = bm
	mi.material_override = _mat(BASE_COLOR, 0.85, 0.0)
	mi.position.y = BASE_H * 0.5
	add_child(mi)


## Station one. A white plinth, the object, and nothing else — the gallery's whole
## apparatus is elevation and silence.
func _build_art(x: float, ratio: float) -> void:
	var plinth := MeshInstance3D.new()
	plinth.name = "GalleryPlinth"
	var pm := BoxMesh.new()
	pm.size = Vector3(0.44, PLINTH_H, 0.44)
	plinth.mesh = pm
	plinth.material_override = _mat(WHITE_CUBE, 0.90, 0.0)
	plinth.position = Vector3(x, BASE_H + PLINTH_H * 0.5, 0.0)
	add_child(plinth)

	var top: float = BASE_H + PLINTH_H
	var seat: float = top + body_size * 0.5

	# fontana's material, term for term: matte painted matter, culling off so the
	# carved inner walls are visible through the face-mouths.
	var art_mat: StandardMaterial3D = _mat(FONTANA_RED, 0.85, 0.0)
	art_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var carved: CSGCombiner3D = _carved_body(ratio, art_mat)
	carved.name = "ArtCube"
	carved.position = Vector3(x, seat, 0.0)
	add_child(carved)
	_pending.append(carved)

	# The point that carved the void, suspended in the hollow it made. 0.06 of the
	# body, which is fontana's 0.03 centre against its 0.5 cube.
	var glint := MeshInstance3D.new()
	glint.name = "ArtPoint"
	var gm := SphereMesh.new()
	gm.radius = body_size * 0.06
	gm.height = gm.radius * 2.0
	gm.radial_segments = 12
	gm.rings = 8
	glint.mesh = gm
	glint.material_override = _glow(DEPTH_COLOR, 2.6)
	glint.position = Vector3(x, seat, 0.0)
	add_child(glint)

	_label("ART", Vector3(x, LABEL_Y, 0.34), WHITE_CUBE)


## Station two. The same solid, on a post, in front of a board, with A and B ghosted
## back into place. The textbook's apparatus is the operands.
func _build_operator(x: float, ratio: float) -> void:
	var table := MeshInstance3D.new()
	table.name = "Lectern"
	var tm := BoxMesh.new()
	tm.size = Vector3(0.86, TABLE_H, 0.50)
	table.mesh = tm
	table.material_override = _mat(SLATE.lightened(0.18), 0.70, 0.05)
	table.position = Vector3(x, BASE_H + TABLE_H * 0.5, 0.0)
	add_child(table)

	var top: float = BASE_H + TABLE_H

	var board := MeshInstance3D.new()
	board.name = "Board"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.86, 0.62, 0.035)
	board.mesh = bm
	board.material_override = _mat(SLATE, 0.95, 0.0)
	board.position = Vector3(x, top + 0.31, -0.30)
	add_child(board)

	var post := MeshInstance3D.new()
	post.name = "Post"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.018
	cm.bottom_radius = 0.018
	cm.height = POST_H
	cm.radial_segments = 12
	post.mesh = cm
	post.material_override = _mat(STEEL, 0.4, 0.6)
	post.position = Vector3(x, top + POST_H * 0.5, -0.06)
	add_child(post)

	var mid: Vector3 = Vector3(x, top + POST_H + body_size * 0.5, -0.06)

	# csg_difference_demo's material, term for term.
	var demo_mat: StandardMaterial3D = _mat(DEMO_BODY, 0.5, 0.3)
	demo_mat.emission_enabled = true
	demo_mat.emission = DEMO_BODY
	demo_mat.emission_energy_multiplier = 0.3

	var carved: CSGCombiner3D = _carved_body(ratio, demo_mat)
	carved.name = "OperatorResult"
	carved.position = mid
	add_child(carved)
	_pending.append(carved)

	# A, faint and in place: the uncut box the result came out of.
	var ghost_a := MeshInstance3D.new()
	ghost_a.name = "OperandA"
	var am := BoxMesh.new()
	am.size = Vector3(body_size, body_size, body_size)
	ghost_a.mesh = am
	ghost_a.material_override = _ghost(DEMO_BODY, 0.16)
	ghost_a.position = mid
	add_child(ghost_a)

	# B, at the void's true radius. This is where breach stops being a state and
	# becomes a quantity: you watch B outgrow A's half-extent.
	var ghost_b := MeshInstance3D.new()
	ghost_b.name = "OperandB"
	var sm := SphereMesh.new()
	sm.radius = ratio * body_size
	sm.height = sm.radius * 2.0
	sm.radial_segments = 24
	sm.rings = 12
	ghost_b.mesh = sm
	ghost_b.material_override = _ghost(CUT_COLOR, 0.22)
	ghost_b.position = mid
	add_child(ghost_b)

	_label("OPERATOR", Vector3(x, LABEL_Y, 0.34), DEMO_BODY)


## Station three. A shallow tray, five specimens, every one of them already in
## pieces. The laboratory's apparatus is the grid and the rim.
func _build_catalogue(x: float, ratio: float) -> void:
	var cab := MeshInstance3D.new()
	cab.name = "LabCabinet"
	var cbm := BoxMesh.new()
	cbm.size = Vector3(0.92, CAB_H, 0.62)
	cab.mesh = cbm
	cab.material_override = _mat(STEEL.darkened(0.35), 0.75, 0.15)
	cab.position = Vector3(x, BASE_H + CAB_H * 0.5, 0.0)
	add_child(cab)

	var tray_y: float = BASE_H + CAB_H + TRAY_H * 0.5
	var tray := MeshInstance3D.new()
	tray.name = "Tray"
	var tm := BoxMesh.new()
	tm.size = Vector3(0.92, TRAY_H, 0.62)
	tray.mesh = tm
	tray.material_override = _mat(STEEL, 0.45, 0.35)
	tray.position = Vector3(x, tray_y, 0.0)
	add_child(tray)

	var surface: float = tray_y + TRAY_H * 0.5
	var rim_mat: StandardMaterial3D = _mat(STEEL.darkened(0.15), 0.45, 0.35)
	_rim(Vector3(x, surface + 0.01, -0.30), Vector3(0.92, 0.02, 0.02), rim_mat)
	_rim(Vector3(x, surface + 0.01, 0.30), Vector3(0.92, 0.02, 0.02), rim_mat)
	_rim(Vector3(x - 0.45, surface + 0.01, 0.0), Vector3(0.02, 0.02, 0.62), rim_mat)
	_rim(Vector3(x + 0.45, surface + 0.01, 0.0), Vector3(0.02, 0.02, 0.62), rim_mat)

	var r: float = specimen_radius
	var d: float = ratio * r
	# Held at a fixed height across every value, so the tray reads as an exploded
	# view rather than as five objects that grew. At husk the lowest fragment just
	# touches the tray surface: 1.8 x r is the largest reach the axis can produce.
	var y: float = surface + r * 1.8
	var spec: StandardMaterial3D = _mat(BONE, 0.62, 0.0)
	spec.cull_mode = BaseMaterial3D.CULL_DISABLED
	spec.emission_enabled = true
	spec.emission = BONE
	spec.emission_energy_multiplier = 0.12

	# Back row, then front row: the shipped order of PLATES read left to right, then
	# left to right again.
	var slots: Array = [
		Vector3(x - 0.28, y, -0.14),
		Vector3(x, y, -0.14),
		Vector3(x + 0.28, y, -0.14),
		Vector3(x - 0.14, y, 0.16),
		Vector3(x + 0.14, y, 0.16),
	]
	for i in PLATES.size():
		var holder := Node3D.new()
		holder.name = "Plate_" + PLATES[i]
		holder.position = slots[i]
		add_child(holder)
		_plate(holder, PLATES[i], r, d, spec)

	_label("CATALOGUE", Vector3(x, LABEL_Y, 0.34), BONE)


func _rim(at: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Rim"
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = at
	add_child(mi)


## One specimen. Four of the five are lat/lon partitions of the solid ball and are
## built by the same generator with different division counts — which is itself the
## catalogue's claim, that these are answers to one question. The fifth is the
## family's own operator, built with real CSG.
func _plate(holder: Node3D, kind: String, r: float, d: float, mat: StandardMaterial3D) -> void:
	match kind:
		"planar":
			_cells(holder, r, d, 1, 2, mat)        # one cut plane: two hemispheres
		"octree":
			_cells(holder, r, d, 4, 2, mat)        # the three coordinate planes: eight octants
		"sectored":
			_cells(holder, r, d, 8, 1, mat)        # orange peel: eight full-height wedges
		"segmented":
			_cells(holder, r, d, 8, 6, mat)        # the source's 6 x 8 mesh: 48 cells
		"csg":
			_csg_plate(holder, r, d, mat)


## A lat/lon partition of the ball, each cell displaced along its own centroid
## direction. Deterministic: every position is a trigonometric function of the cell
## indices, so five variants are five states of one object rather than five objects.
func _cells(holder: Node3D, r: float, d: float, n_lon: int, n_lat: int, mat: StandardMaterial3D) -> void:
	var nu: int = clampi(int(round(24.0 / float(n_lon))), 3, 16)
	var nv: int = clampi(int(round(12.0 / float(n_lat))), 3, 10)
	for i in n_lon:
		var u0: float = TAU * float(i) / float(n_lon)
		var u1: float = TAU * float(i + 1) / float(n_lon)
		for j in n_lat:
			var v0: float = PI * float(j) / float(n_lat)
			var v1: float = PI * float(j + 1) / float(n_lat)
			var mi := MeshInstance3D.new()
			mi.name = "Cell_%d_%d" % [i, j]
			mi.mesh = _cell_mesh(r, u0, u1, v0, v1, nu, nv)
			mi.material_override = mat
			mi.position = _cell_direction(u0, u1, v0, v1, n_lon) * d
			holder.add_child(mi)


## The direction a cell moves. A cell that spans the FULL ring of longitude has its
## centroid on the Y axis, and taking the mid-angle would send a hemisphere sideways.
func _cell_direction(u0: float, u1: float, v0: float, v1: float, n_lon: int) -> Vector3:
	var vm: float = (v0 + v1) * 0.5
	if n_lon <= 1:
		if absf(vm - PI * 0.5) < 0.001:
			return Vector3.ZERO
		var s: float = 1.0
		if vm > PI * 0.5:
			s = -1.0
		return Vector3(0.0, s, 0.0)
	var um: float = (u0 + u1) * 0.5
	var dir: Vector3 = Vector3(sin(vm) * cos(um), cos(vm), sin(vm) * sin(um))
	if dir.length() < 0.0001:
		return Vector3.ZERO
	return dir.normalized()


## A solid cell of the ball: the outer patch, plus the walls that close it back to
## the centre. Unindexed triangle soup so generate_normals gives flat facets, which
## is what a fragment should look like.
func _cell_mesh(r: float, u0: float, u1: float, v0: float, v1: float, nu: int, nv: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var full_ring: bool = (u1 - u0) > (TAU - 0.001)

	for i in nu:
		var ua: float = lerpf(u0, u1, float(i) / float(nu))
		var ub: float = lerpf(u0, u1, float(i + 1) / float(nu))
		for j in nv:
			var va: float = lerpf(v0, v1, float(j) / float(nv))
			var vb: float = lerpf(v0, v1, float(j + 1) / float(nv))
			_tri(st, _sph(r, ua, va), _sph(r, ub, va), _sph(r, ub, vb))
			_tri(st, _sph(r, ua, va), _sph(r, ub, vb), _sph(r, ua, vb))

	# Meridional walls. Skipped on a full ring, where they would be interior faces.
	if not full_ring:
		for j in nv:
			var va2: float = lerpf(v0, v1, float(j) / float(nv))
			var vb2: float = lerpf(v0, v1, float(j + 1) / float(nv))
			_tri(st, Vector3.ZERO, _sph(r, u0, vb2), _sph(r, u0, va2))
			_tri(st, Vector3.ZERO, _sph(r, u1, va2), _sph(r, u1, vb2))

	# Latitude caps. Skipped at the poles, where the patch already closes itself.
	if v0 > 0.001:
		for i in nu:
			var ua3: float = lerpf(u0, u1, float(i) / float(nu))
			var ub3: float = lerpf(u0, u1, float(i + 1) / float(nu))
			_tri(st, Vector3.ZERO, _sph(r, ua3, v0), _sph(r, ub3, v0))
	if v1 < PI - 0.001:
		for i in nu:
			var ua4: float = lerpf(u0, u1, float(i) / float(nu))
			var ub4: float = lerpf(u0, u1, float(i + 1) / float(nu))
			_tri(st, Vector3.ZERO, _sph(r, ub4, v1), _sph(r, ua4, v1))

	st.generate_normals()
	return st.commit()


func _sph(r: float, u: float, v: float) -> Vector3:
	return Vector3(r * sin(v) * cos(u), r * cos(v), r * sin(v) * sin(u))


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


## The fifth base: a real boolean cut, and the only plate whose parts were not
## enumerated in advance. Two combiners side by side under a plain Node3D — never
## nested, because a CSGCombiner3D inside a combiner is a shape and the bitten body
## would be unioned back into the piece bitten out of it.
func _csg_plate(holder: Node3D, r: float, d: float, mat: StandardMaterial3D) -> void:
	var bite_r: float = r * 0.62
	var bite_at: Vector3 = Vector3(r * 0.85, 0.0, 0.0)

	var body := CSGCombiner3D.new()
	body.name = "CsgBody"
	body.add_child(_csg_ball(r, CSGShape3D.OPERATION_UNION, Vector3.ZERO))
	body.add_child(_csg_ball(bite_r, CSGShape3D.OPERATION_SUBTRACTION, bite_at))
	body.material_override = mat
	body.position = Vector3(-d, 0.0, 0.0)
	holder.add_child(body)
	_pending.append(body)

	var lens := CSGCombiner3D.new()
	lens.name = "CsgRemoved"
	lens.add_child(_csg_ball(r, CSGShape3D.OPERATION_UNION, Vector3.ZERO))
	lens.add_child(_csg_ball(bite_r, CSGShape3D.OPERATION_INTERSECTION, bite_at))
	lens.material_override = mat
	lens.position = Vector3(d, 0.0, 0.0)
	holder.add_child(lens)
	_pending.append(lens)


func _csg_ball(r: float, op: int, at: Vector3) -> CSGSphere3D:
	var s := CSGSphere3D.new()
	s.radius = r
	s.radial_segments = 20
	s.rings = 12
	s.operation = op
	s.position = at
	return s


## The cube minus its oversized sphere. fontana's segment counts, fontana's ratio,
## and the caller's material — the same construction at both stations that use it.
func _carved_body(ratio: float, mat: StandardMaterial3D) -> CSGCombiner3D:
	var comb := CSGCombiner3D.new()
	var box := CSGBox3D.new()
	box.name = "A"
	box.size = Vector3(body_size, body_size, body_size)
	comb.add_child(box)
	var sph := CSGSphere3D.new()
	sph.name = "B"
	sph.radius = ratio * body_size
	sph.radial_segments = 28
	sph.rings = 18
	sph.operation = CSGShape3D.OPERATION_SUBTRACTION
	comb.add_child(sph)
	comb.material_override = mat
	return comb


## Invisible to every camera, present to the framing. It is the BENCH's box, not an
## inflated one: the furniture is identical at all four values, so the anchor also
## pins the camera across the sweep and no part of a bite report can be the camera
## moving. It reaches to the labels, which the capture AABB cannot see at all.
func _build_anchor() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "ExtentAnchor"
	var bm := BoxMesh.new()
	bm.size = Vector3(station_pitch * 3.0, ANCHOR_H, BENCH_D)
	mi.mesh = bm
	mi.position.y = ANCHOR_H * 0.5
	mi.layers = 0
	add_child(mi)


func _label(txt: String, at: Vector3, col: Color) -> void:
	var lab := Label3D.new()
	lab.name = "Caption_" + txt
	lab.text = txt
	lab.font_size = 26
	lab.outline_size = 5
	lab.modulate = col
	lab.position = at
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(lab)


# ── Bake ──────────────────────────────────────────────────────────────

## CSG needs one tick to resolve, and a live CSGShape3D is not a MeshInstance3D, so
## the capture AABB cannot see it. Bake each combiner into a mesh in its own parent,
## at its own transform. A bake that returns null leaves the live CSG standing.
func _bake_pending() -> void:
	for c in _pending:
		if c == null or not is_instance_valid(c):
			continue
		var comb: CSGCombiner3D = c
		var baked: ArrayMesh = comb.bake_static_mesh()
		if baked == null:
			continue
		var parent: Node = comb.get_parent()
		if parent == null:
			continue
		var mi := MeshInstance3D.new()
		mi.name = str(comb.name) + "Baked"
		mi.mesh = baked
		mi.material_override = comb.material_override
		parent.add_child(mi)
		mi.transform = comb.transform
		comb.queue_free()
	_pending.clear()


# ── Materials ─────────────────────────────────────────────────────────

func _mat(col: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	return m


func _glow(col: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	m.roughness = 0.2
	return m


## csg_difference_demo._ghost_material, term for term — alpha on the albedo, alpha
## transparency, culling off, unshaded, emission at 0.35 — so the operands here look
## like the operands there.
func _ghost(col: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col.r, col.g, col.b, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 0.35
	return m
