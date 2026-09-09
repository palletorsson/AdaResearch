# @identity
# essence: a floor plate carrying a lattice of dots and the single closed line that goes round all of them without lifting — shipped at a lattice where one line is enough, and holding a knob that makes it not enough
# desire: that a visitor find the line's start bead, follow the cord with their eye all the way round the dots, arrive back at the bead, and only then be told that this was never guaranteed
# critical_parameter: rows x cols together, because the answer is a function of the pair and of nothing else. 5x3 draws in one line; 6x4 draws in two, and the second one arrives in a different colour with its own bead. Neither number alone predicts anything, which is the whole finding
# triggers: _ready() runs the 45-degree billiard once — every cell diagonal traversed exactly once, straight on through every crossing, reflecting only at the rim — and takes the number of closed lines from the trace rather than from the formula. Nothing moves afterwards and nothing needs to
# emerges: a count nobody chose. The lattice is set by hand, the line has no freedom at all, and how many times the finger must touch down falls out of the two numbers
# needs: floor at y=0 under the origin [the grid provides it]; a body that can stand IN THE MIDDLE of it, not in front of it [spatial_needs, player_position "above"]; a lit hall — a near-black plate in the dark is a hole [the hall provides it]; apply_grid_config [present]
# relationships: the Eulerian twin of salesman_knot, which stands in GT_Pathfinding — same 2.4 m plate, same near-black ground and bone ink, opposite theorem: that one visits every VERTEX once and finds the routing makes no difference, this one visits every EDGE once and finds the routing is the only thing there is. GT_Foundations already carries Euler, but as an impossibility: KonigsbergBridge has four odd vertices, so no walk, and its critical.md calls the proof "complete, elegant, devastating". The positive case is stated there only in prose (technical.md, line 68, a triangle) — no OBJECT in this corpus has been an Eulerian circuit, and nothing anywhere carries the count
# truth: a sona is not merely Eulerian. Every crossing here has degree four and every rim turn degree two, so all degrees are even and one closed trail over every edge ALWAYS exists — the finger could always do it, if it were allowed to turn where it crosses. It is not allowed. At a crossing the finger goes straight on, because a sand line that turned there would be a different figure. That one extra rule is about the hand and not about the graph, and it is what puts gcd(rows, cols) into the answer: 5x3 closes in one line, 6x4 needs two. The impossibility Euler proved at Konigsberg was in the structure. This one is in the discipline.

extends Node3D
class_name SonaFloor

## SONA_FLOOR — after the Chokwe *lusona* of Angola and northwestern Zambia, and
## the Tamil *kolam*. A field of sand is smoothed, a lattice of dots is pressed
## into it with the fingertips, and then one continuous line is drawn around the
## dots — traditionally while telling the story the figure belongs to — without
## lifting the finger and without retracing any part of the line.
##
## The mathematics is not decoration on that practice, it IS that practice: the
## drawer must know, before starting, how many dots to set out, because the wrong
## lattice cannot be drawn in one line however clever the route. Paulus Gerdes
## reconstructed the rule from the surviving figures. For the plaited-mat class of
## sona on an m x n lattice the count of closed lines is gcd(m, n).
##
## WHAT IS ACTUALLY BEING COUNTED, AND WHY IT IS NOT EULER'S THEOREM
##
## Take the drawing as a graph: vertices where the line crosses itself or turns,
## edges the pieces of line between them. Every crossing has degree 4 and every
## rim turn degree 2, so every degree is even, and by Euler's theorem a single
## closed walk using every edge exactly once exists. Always. For every m and n.
## So "can it be drawn in one line" is, as a question about the GRAPH, boring:
## yes, trivially, forever.
##
## The sona rule is stronger and it is not a rule about the graph. At a crossing
## the finger goes STRAIGHT ON. It does not turn. (A line that turned at a
## crossing would leave a cusp in the sand and would be, to anyone reading the
## figure, a different figure.) That constraint is a *transition system* on the
## vertices, and under it the edge set decomposes into exactly gcd(m, n) closed
## trails.
##
## Nothing else in this project makes that distinction. GT_Foundations proves the
## Konigsberg impossibility from vertex parity and stops; its technical.md states
## the positive case in one sentence about a triangle, and no artifact has ever
## been one. The COUNT — how many lines a given lattice takes — is nowhere at all.
##
## HOW IT IS BUILT, AND WHY NOT THE OTHER WAY
##
## The line is a 45-degree billiard. Work in HALF-PITCH units: the rim is the
## rectangle [0, W] x [0, H] with W = 2*cols and H = 2*rows, the dots sit at the
## points with both coordinates odd, and the line runs through the points with
## coordinate sum ODD, stepping (+-1, +-1) and reflecting specularly off the rim.
## Each of the W*H unit cells then admits exactly one legal diagonal — the one
## that misses the cell's dot — so the drawing is complete when every cell has
## been used once, and each crossing point is where a "/" and a "\" meet.
##
##   THE CORNERS CANNOT BITE. W and H are both even, so all four corners have an
##   EVEN coordinate sum and the line can never reach one. Reflection therefore
##   always flips exactly one component and there is no ambiguous case to handle.
##   This is not luck, it is what doubling the lattice buys.
##
## The alternative was to hard-code a named lusona (the lion's stomach, the
## chased-antelope) as a point list. Rejected: a transcribed figure has no
## failure case, and the failure case is half of what the object is for. Traced,
## the count is DERIVED and 6x4 is one token away.
##
## MEASURED, in a Python mirror of this file (2026-09-09, scratchpad sona_mirror.py):
##   trace vs gcd   all 64 lattices with rows, cols in 1..8 agree exactly:
##                  closed lines traced == gcd(rows, cols), every time
##   completeness   segments traversed == W*H == 4*rows*cols in every case, with
##                  an assert that no cell diagonal is ever used twice
##   rim turns      wall points == 2*(rows + cols) in every case
##   runs           3744 runs over rows, cols in 1..12: every one a proper
##                  45-degree chord, |dx| == |dy| >= 1, none degenerate
##   the two named cases
##                  5 x 3 dots -> 1 closed line, 16 runs, 60 cell diagonals
##                  6 x 4 dots -> 2 closed lines, 10 runs each, 96 diagonals
##   layout (shipped defaults, 2.4 m panel)
##                  unit 0.2222 m, dot pitch 0.4444 m, cord 40.0 mm wide,
##                  dot radius 48.9 mm, 274 mm of black between parallel cords,
##                  88 mm of clearance between any dot and any cord
##   instances      48 at the default (16 runs + 16 rim caps + 15 dots + 1 bead)
## Those are geometry, not renders. A render adds a light and will not return them.
##
## NOT A CAPTURE SWEEP. There is no dna.axes block here on purpose: the axis that
## matters is the rows x cols PAIR, no sweep has seen it, and this file will not
## hand-type a declaration the bite critic has not measured.
##
## NOT COMPILED OR CAPTURED in the session that wrote it — the owner had the
## editor open, and a second Godot instance dies on the user:// lock.

const PBR := preload("res://commons/render/pbr_kit.gd")
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# ── The stack, in metres. EVERYTHING SITS ABOVE y = 0. ────────────────────────
# The origin is the base. A plate centred on its own origin stands half in the
# floor everywhere auto-grounding is skipped, and it is skipped for any map token
# carrying an explicit y. salesman_knot and prism_block were both fixed for this.
const SLAB_H := 0.012        ## the sand bed. A slab, never a quad: a PlaneMesh is
                             ## one-sided and the piece vanishes edge-on.
const CORD_H := 0.010        ## the drawn line, as a low ribbon
const SINK := 0.002          ## how far the ribbon's underside sits INSIDE the bed.
                             ## Not decoration: a ribbon whose bottom face were
                             ## coplanar with the bed's top face is two surfaces at
                             ## one depth, which is a z-fight. Sunk, that face is
                             ## inside solid geometry and can never be seen.
const WEAVE_DY := 0.001      ## THE ONLY REASON THE CROSSINGS RENDER. The line
                             ## crosses itself at every interior point, and two
                             ## flat-topped ribbons meeting at 45 degrees at the
                             ## same height share a coplanar top over the whole
                             ## overlap. One millimetre of separation between the
                             ## two diagonal families removes every such pair.
                             ## Chosen as the smallest step that is unarguably
                             ## outside depth-buffer precision at a few metres and
                             ## still under a tenth of the ribbon's own thickness,
                             ## so what it reads as at standing distance is a
                             ## faint over-and-under — which is what a plaited mat
                             ## looks like anyway.
                             ##
                             ## THE ALTERNATIVE WAS REJECTED ON THE CLAIM. Proper
                             ## knotwork breaks the under strand with a gap at each
                             ## crossing (salesman_knot's halo does exactly that).
                             ## Here that would chop every line into dashes at the
                             ## crossings, and CONTINUITY IS THE ENTIRE ARGUMENT.
const CAP_LIFT := 0.0008     ## rim caps clear the upper family by this, same reason
const DOT_H := 0.016         ## the pressed dots, proud of the line
const DOT_R_FRAC := 0.11     ## dot radius as a fraction of the dot pitch. A
                             ## decision, not a setting: the line passes 0.3536
                             ## pitch from every dot, so at 0.11 there are 88 mm of
                             ## clear ground between a dot and the nearest cord at
                             ## the shipped scale. Push it past ~0.28 and the dots
                             ## touch the line, and a sona whose dots touch the line
                             ## is not a sona.
const FRAME_W := 0.050
const FRAME_H := 0.045       ## the tallest thing here, and deliberately: the rim is
                             ## what gives a dark floor plate a silhouette in a
                             ## still, and it keeps the collider to one number.
const EDGE_CLEAR := 0.010    ## bare bed between the rim and the drawing
const LABEL_BAND := 0.320    ## depth reserved at +Z for the label, so the drawing
                             ## never has to be clamped out of the way of it

## The lattice — stone, not chalk. The dots are the GIVEN and the line is the
## ANSWER, so they must not read as the same substance; a bright dot the colour of
## the cord reads as part of the drawing and the figure loses its subject.
const DOT_COLOR := Color(0.430, 0.418, 0.392)
## Near-black, never black — a zero albedo reads as a hole cut in the floor rather
## than as a dark body. salesman_knot's ground, repeated rather than re-derived.
const GROUND_COLOR := Color(0.031, 0.030, 0.036)

@export_category("The lattice")
## Rows of dots, running back into the room (+Z is depth). THE PAIR IS THE POINT.
@export_range(1, 16) var rows: int = 3
## Columns of dots, running across (X is width). Ships coprime with `rows`, so the
## figure closes in ONE line. Set rows 4 / cols 6 from a map token and it does not:
## gcd 2, two lines, two colours, two beads. That is not a defect to be avoided,
## it is the other half of the lesson and the reason both numbers are knobs.
##
## `rows` and `cols` are also the two keys that CARRY the lesson, and they are two
## of the safe ones — both sit in GridInteractablesComponent.CONFIG_PARAM_NAMES, so
## `#rows:4 #cols:6` arrives here as values. An unlisted numeric key would have been
## eaten as the tutorial's positional shorthand and set the artifact's yaw instead,
## silently, with the map file looking entirely correct.
@export_range(1, 16) var cols: int = 5

@export_category("The plate")
## Panel edge, metres. Big enough to stand in the middle of.
@export var panel_m: float = 2.4
## Line width as a fraction of the DOT PITCH. Parallel runs of the line sit
## 0.7071 pitch apart, so the cords touch at 0.7071 and the drawing turns into a
## field with no line left in it; the clamp stops well short. At the shipped 0.09
## the cord is 40 mm on a 444 mm pitch and there is 274 mm of black between runs.
@export_range(0.03, 0.30, 0.005) var cord_frac: float = 0.09

@export_category("What it says")
## The floor label — the lattice, the gcd, and the number of lines TRACED. On by
## default because the arithmetic is the payload; off for a hall that says it on
## the wall instead, and the drawing then takes the reserved band back.
@export var show_plaque: bool = true
## A body under the plate, matching what is SEEN — the rim is 45 mm and the shape
## is 45 mm. A visitor is meant to stand on this; a plate you fall through is a
## picture of a plate.
@export var solid_collider: bool = true

@export_category("Ink")
## The line. Not pure white: a clipped albedo has nothing left to shade with.
@export var line_color: Color = Color(0.905, 0.900, 0.882)
## The colour of the SECOND line, and of every line after the first. It only ever
## appears when the lattice fails to close, which is why it is a leftover colour
## rather than a partner to the first — the ochre line is what the bone one could
## not reach.
@export var second_color: Color = Color(0.847, 0.451, 0.196)

# Derived per build; kept as fields only so the small builders can read them.
var _W: int = 0
var _H: int = 0
var _unit: float = 0.1
var _z0: float = 0.0
var _cord_w: float = 0.04


func _ready() -> void:
	_build()


func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var m: int = clampi(rows, 1, 16)
	var n: int = clampi(cols, 1, 16)
	_W = 2 * n
	_H = 2 * m
	var panel: float = clampf(panel_m, 0.8, 8.0)

	# ── the field, sized so nothing can reach the rim ──────────────────────
	# The rim caps are squares of side `cord_w` sitting ON the boundary with their
	# sides along the two run directions, so each one reaches 0.7071 * cord_w
	# OUTSIDE the field. Sizing the field to the bare space and then adding caps
	# put them 9 mm inside the rail at the shipped defaults. The cap overhang is a
	# fixed multiple of the unit, so the correction is closed-form: measure a
	# provisional unit, take the overhang it implies, and re-fit inside the
	# remainder. The second unit is never larger than the first, so the second
	# overhang is never larger than the one subtracted — the result is safe by
	# construction rather than by a fudge factor.
	var avail_w: float = maxf(panel - 2.0 * (FRAME_W + EDGE_CLEAR), panel * 0.3)
	var avail_d: float = avail_w - (LABEL_BAND if show_plaque else 0.0)
	avail_d = maxf(avail_d, avail_w * 0.35)
	var frac: float = clampf(cord_frac, 0.03, 0.30)
	var unit0: float = minf(avail_w / float(_W), avail_d / float(_H))
	var over0: float = 0.70711 * (frac * 2.0 * unit0)
	_unit = maxf(minf((avail_w - 2.0 * over0) / float(_W),
		(avail_d - 2.0 * over0) / float(_H)), 0.005)
	var pitch: float = 2.0 * _unit
	_cord_w = frac * pitch
	# The drawing is centred in what is left after the label band, so a lattice as
	# deep as it is wide still leaves the label its own floor instead of standing
	# on the outermost run.
	_z0 = (-LABEL_BAND * 0.5) if show_plaque else 0.0

	# ── the bed ───────────────────────────────────────────────────────────
	var slab := MeshInstance3D.new()
	slab.name = "Plate"
	var slab_mesh := BoxMesh.new()
	slab_mesh.size = Vector3(panel, SLAB_H, panel)
	slab.mesh = slab_mesh
	slab.material_override = _ground_mat()
	slab.position = Vector3(0.0, SLAB_H * 0.5, 0.0)
	add_child(slab)

	var rail: StandardMaterial3D = PBR.worn_metal(PBR.GUNMETAL, 0.35)
	var edge: float = panel * 0.5 - FRAME_W * 0.5
	var span: float = panel - 2.0 * FRAME_W
	var y_rail: float = FRAME_H * 0.5
	add_child(PBR.box(Vector3(0.0, y_rail, -edge), Vector3(panel, FRAME_H, FRAME_W), rail))
	add_child(PBR.box(Vector3(0.0, y_rail, edge), Vector3(panel, FRAME_H, FRAME_W), rail))
	add_child(PBR.box(Vector3(-edge, y_rail, 0.0), Vector3(FRAME_W, FRAME_H, span), rail))
	add_child(PBR.box(Vector3(edge, y_rail, 0.0), Vector3(FRAME_W, FRAME_H, span), rail))

	# ── the line, traced ──────────────────────────────────────────────────
	var curves: Array = _trace()
	var n_curves: int = curves.size()
	_self_check(curves, m, n)

	var box_unit := BoxMesh.new()
	box_unit.size = Vector3.ONE
	var aabb := AABB(Vector3(-panel * 0.5, 0.0, -panel * 0.5), Vector3(panel, 0.06, panel))

	for k in range(n_curves):
		var walls: Array = curves[k]
		var col: Color = _curve_color(k)
		# ONE MultiMesh per closed line, and the node count is therefore the answer:
		# a probe that wants to know how many lines this lattice takes can count
		# children called Curve_* without reading a pixel or trusting the label.
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = box_unit
		mm.instance_count = walls.size() * 2
		for i in range(walls.size()):
			var a: Vector2i = walls[i]
			var b: Vector2i = walls[(i + 1) % walls.size()]
			var pa: Vector3 = _to_world(a)
			var pb: Vector3 = _to_world(b)
			var dx: float = pb.x - pa.x
			var dz: float = pb.z - pa.z
			var seg_len: float = maxf(sqrt(dx * dx + dz * dz), 0.0001)
			# The two diagonal families ride at different heights. Which one is
			# over is decided by the run's own slope, not by which curve it belongs
			# to, so a single closed line weaves with ITSELF and stays continuous.
			var over: bool = (b.x - a.x) * (b.y - a.y) < 0
			var y_line: float = SLAB_H - SINK + CORD_H * 0.5 + (WEAVE_DY if over else 0.0)
			# Rotation about +Y maps local +X to (cos t, 0, -sin t), so aligning the
			# box's long axis with (dx, dz) needs t = atan2(-dz, dx).
			var run_basis := Basis(Vector3.UP, atan2(-dz, dx)) \
				* Basis.from_scale(Vector3(seg_len, CORD_H, _cord_w))
			mm.set_instance_transform(i, Transform3D(run_basis,
				Vector3((pa.x + pb.x) * 0.5, y_line, (pa.z + pb.z) * 0.5)))
			# The rim cap. Two runs meet at 90 degrees here and leave a notch in the
			# outer corner plus a 1 mm step between the two families; the exact
			# miter for a right-angle join of two bands of width w is the square of
			# side w with its sides along the two directions, which is a box yawed
			# 45 degrees. It spans both families and clears the upper one, so no top
			# face anywhere is coplanar with any other.
			var cap_h: float = CORD_H + WEAVE_DY + CAP_LIFT
			mm.set_instance_transform(walls.size() + i, Transform3D(
				Basis(Vector3.UP, PI * 0.25)
					* Basis.from_scale(Vector3(_cord_w, cap_h, _cord_w)),
				Vector3(pa.x, SLAB_H - SINK + cap_h * 0.5, pa.z)))

		var node := MultiMeshInstance3D.new()
		node.name = "Curve_%02d" % k
		node.multimesh = mm
		node.material_override = _ink_mat(col)
		# A MultiMesh reports no useful AABB to the capture harness — every artifact
		# built from one has measured as a 1 m box. The plate already spans the
		# panel, but this is stated rather than inherited.
		node.custom_aabb = aabb
		add_child(node)

		# WHERE THE FINGER GOES DOWN. One bead per closed line, in that line's
		# colour, so the count of beads IS the number of times the drawer must
		# start again — the claim made as geometry rather than as a caption. At the
		# shipped lattice there is exactly one, and following the cord from it
		# returns you to it having passed every dot.
		var bead := MeshInstance3D.new()
		bead.name = "Start_%02d" % k
		var stud := CylinderMesh.new()
		# Real radii and a real height, not a scaled unit cylinder: a non-uniform
		# basis on a curved mesh skews its normals, and this is the one part here
		# whose shading is a dome rather than a flat face.
		stud.bottom_radius = _cord_w * 0.75
		stud.top_radius = _cord_w * 0.52
		stud.height = 0.034
		stud.radial_segments = 12
		stud.rings = 1
		bead.mesh = stud
		bead.material_override = _ink_mat(col)
		var w0: Vector3 = _to_world(walls[0])
		bead.position = Vector3(w0.x, SLAB_H - SINK + 0.017, w0.z)
		add_child(bead)

	# ── the dots ──────────────────────────────────────────────────────────
	# No toggle. A sona without its lattice is a line with nothing to be about.
	var dot := CylinderMesh.new()
	dot.bottom_radius = DOT_R_FRAC * pitch
	dot.top_radius = DOT_R_FRAC * pitch * 0.86
	dot.height = DOT_H
	dot.radial_segments = 14
	dot.rings = 1
	var dm := MultiMesh.new()
	dm.transform_format = MultiMesh.TRANSFORM_3D
	dm.mesh = dot
	dm.instance_count = m * n
	var i_dot: int = 0
	for rr in range(m):
		for cc in range(n):
			# Both coordinates odd — the points the line is forbidden to touch.
			var p: Vector3 = _to_world(Vector2i(2 * cc + 1, 2 * rr + 1))
			# Identity basis, translation only, so the dots carry no scale at all
			# and their normals are exactly the mesh's.
			dm.set_instance_transform(i_dot, Transform3D(Basis(),
				Vector3(p.x, SLAB_H - SINK + DOT_H * 0.5, p.z)))
			i_dot += 1
	var dots := MultiMeshInstance3D.new()
	dots.name = "Dots"
	dots.multimesh = dm
	dots.material_override = _dot_mat()
	dots.custom_aabb = aabb
	add_child(dots)

	# ── what it says ──────────────────────────────────────────────────────
	# text_screen.gd and nothing else. Label3D does not render in this project's
	# capture and neither does a baked-albedo quad — both were verified blank
	# twice, at a cost of seven captures, and this component is the one that came
	# back legible. PAD is its own reclined-on-a-surface mode, so the tilt is the
	# component's, not a rotation invented here; and nothing is turned about Y,
	# because an artifact that faces its text away from +Z photographs bare.
	var plaque_z: float = panel * 0.5 - FRAME_W - LABEL_BAND * 0.5
	if show_plaque:
		var screen := TextScreenScript.new()
		screen.name = "Label"
		screen.mode = 2
		screen.width_m = 0.52
		screen.title = "LUSONA"
		screen.body = _label_body(n_curves, m, n)
		screen.bg_color = Color(0.07, 0.07, 0.08)
		screen.frame_color = Color(0.17, 0.17, 0.19)
		screen.title_color = line_color
		screen.body_color = Color(0.88, 0.87, 0.84)
		screen.post_color = Color(0.19, 0.19, 0.21)
		screen.position = Vector3(0.0, SLAB_H, plaque_z)
		add_child(screen)

	# ── the body ──────────────────────────────────────────────────────────
	if solid_collider:
		var body := StaticBody3D.new()
		body.name = "Body"
		var shape := CollisionShape3D.new()
		var plate_box := BoxShape3D.new()
		# The rim is the tallest thing on the plate by construction (45 mm against
		# the bead's 34 mm and the dots' 16 mm), so one number covers the deck.
		plate_box.size = Vector3(panel, FRAME_H, panel)
		shape.shape = plate_box
		shape.position = Vector3(0.0, FRAME_H * 0.5, 0.0)
		body.add_child(shape)
		if show_plaque:
			# The label is 60 x 22 x 30 cm of visible object standing on the deck.
			# Without this a visitor walks through a solid-looking thing, which is
			# the pink_gun fault in the other direction: geometry with no body.
			var lab := CollisionShape3D.new()
			var lab_box := BoxShape3D.new()
			lab_box.size = Vector3(0.60, 0.22, 0.30)
			lab.shape = lab_box
			lab.position = Vector3(0.0, SLAB_H + 0.11, plaque_z)
			body.add_child(lab)
		add_child(body)


# ── the trace ─────────────────────────────────────────────────────────────────

## Run the billiard until every cell diagonal has been used once. Returns one
## Array of rim points per closed line, in traversal order.
##
## The state is (point, direction) and the step map is a bijection on a finite
## set, so every orbit is a cycle and the walk always comes home. Turns happen
## ONLY at the rim — at a crossing the finger goes straight on, which is the sona
## rule and the whole reason the count is not always 1 — so consecutive rim points
## are the endpoints of one straight run and the list is all the geometry needs.
##
## Starting a curve on the lower-left endpoint of an unused cell can start it mid-
## run, and that is harmless: the list is cyclic, and the closing run from the last
## rim point back to the first passes straight through the arbitrary start.
func _trace() -> Array:
	var used: Dictionary = {}
	var curves: Array = []
	var budget: int = 8 * _W * _H + 64
	for a in range(_W):
		for b in range(_H):
			if used.has(a * _H + b):
				continue
			# Each cell admits exactly ONE diagonal whose endpoints have odd
			# coordinate sums — the other joins two even-sum points, which are the
			# dot and the cell-square centre, and is not on the line's lattice at
			# all. Which one it is falls out of the cell's own parity.
			var p := Vector2i(a, b)
			var d := Vector2i(1, 1)
			if (a + b) % 2 == 0:
				p = Vector2i(a, b + 1)
				d = Vector2i(1, -1)
			var p0: Vector2i = p
			var d0: Vector2i = d
			var walls: Array = []
			var guard: int = 0
			while true:
				guard += 1
				used[mini(p.x, p.x + d.x) * _H + mini(p.y, p.y + d.y)] = true
				p = p + d
				var turned: bool = false
				# W and H are both even, so a corner has an even coordinate sum and
				# the line can never stand on one. Exactly one of these fires.
				if p.x == 0 or p.x == _W:
					d.x = -d.x
					turned = true
				if p.y == 0 or p.y == _H:
					d.y = -d.y
					turned = true
				if turned:
					walls.append(p)
				if p == p0 and d == d0:
					break
				if guard > budget:
					push_error("sona_floor: billiard did not close at %dx%d" % [rows, cols])
					break
			if not walls.is_empty():
				curves.append(walls)
	return curves


## The measurement this file is willing to be wrong in public about.
##
## The number of lines is taken from the TRACE, never from gcd — the label prints
## what was actually drawn. This compares the two anyway, because a silent
## agreement is worth nothing and a disagreement is worth the whole artifact: it
## would mean either the billiard or the theorem is not what this file says it is.
## Verified equal for all 64 lattices with rows, cols in 1..8 before shipping.
func _self_check(curves: Array, m: int, n: int) -> void:
	var g: int = _gcd(m, n)
	if curves.size() != g:
		push_warning("sona_floor: traced %d closed lines at %dx%d but gcd is %d"
			% [curves.size(), m, n, g])
	var turns: int = 0
	for c in curves:
		turns += (c as Array).size()
	if turns != 2 * (m + n):
		push_warning("sona_floor: %d rim turns at %dx%d, expected %d"
			% [turns, m, n, 2 * (m + n)])


func _gcd(a: int, b: int) -> int:
	var x: int = absi(a)
	var y: int = absi(b)
	while y != 0:
		var t: int = y
		y = x % y
		x = t
	return maxi(x, 1)


## Half-pitch lattice coordinates to the plate's own frame. Y is always 0 here;
## the callers put the geometry at its own height.
func _to_world(p: Vector2i) -> Vector3:
	return Vector3((float(p.x) - float(_W) * 0.5) * _unit, 0.0,
		(float(p.y) - float(_H) * 0.5) * _unit + _z0)


## The first line keeps `line_color`, whatever the count. The rest are the
## leftover, hue-rotated so that three lines are three colours rather than a bone
## one and two shades of the same ochre — a lerp toward one second colour puts the
## middle members close enough to the first to read as lighting.
func _curve_color(k: int) -> Color:
	if k <= 0:
		return line_color
	var h: float = fposmod(second_color.h + float(k - 1) * 0.13, 1.0)
	return Color.from_hsv(h, second_color.s, second_color.v, 1.0)


## DERIVED, never typed. `n_curves` is what the billiard actually drew, not what
## the theorem promised — a floor that lied about its own count would be worse
## than a bare floor in a room whose entire subject is counting. Lines are kept
## under 27 characters, which is what text_screen fits at width 0.52 before it
## reflows them.
func _label_body(n_curves: int, m: int, n: int) -> String:
	var head: String = "%d x %d dots.   gcd %d." % [n, m, _gcd(m, n)]
	var mid: String = "%d lines, %d touches." % [n_curves, n_curves]
	if n_curves == 1:
		mid = "one line, one touch."
	elif n_curves == 2:
		mid = "two lines, two touches."
	return head + "\n" + mid + "\none line only if coprime."


# ── surfaces ──────────────────────────────────────────────────────────────────

## Dry pigment on sand: matte, no metal, a modest F0 so the ribbon's edge still
## has a Fresnel limb. No roughness texture and no triplanar — both would be
## sampled in a space this file has not verified for a MultiMesh instance, and a
## 40 mm cord has no grain worth seeing at arm's length. salesman_knot pins its
## numbers for the same reason.
func _ink_mat(c: Color) -> StandardMaterial3D:
	var mt := StandardMaterial3D.new()
	mt.albedo_color = c
	mt.metallic = 0.0
	mt.metallic_specular = 0.45
	mt.roughness = 0.68
	mt.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mt


## The pressed dots. Rougher and darker than the line, because they are the thing
## the line is drawn AROUND and must not compete with it for the eye.
func _dot_mat() -> StandardMaterial3D:
	var mt := StandardMaterial3D.new()
	mt.albedo_color = DOT_COLOR
	mt.metallic = 0.0
	mt.metallic_specular = 0.40
	mt.roughness = 0.86
	mt.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mt


## Near-black, and the two numbers that keep it a body rather than a hole:
##   metallic 0        — a dielectric with nothing on it, which is what earth is.
##   metallic_specular — F0 = 0.08 x this. At 0 there is no Fresnel, and Fresnel at
##                       grazing incidence is the whole of a dark surface's limb.
##                       You almost never look at a floor except at a grazing
##                       angle, so this is the term doing the work.
## Repeated from salesman_knot rather than re-derived: the two plates stand in the
## same sequence and arguing opposite theorems is worth more when the ground under
## them is identical.
func _ground_mat() -> StandardMaterial3D:
	var mt := StandardMaterial3D.new()
	mt.albedo_color = GROUND_COLOR
	mt.metallic = 0.0
	mt.metallic_specular = 0.50
	mt.roughness = 0.94
	mt.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mt


## Per-cell configuration from a map token. Keys honoured:
##
##   #rows:<n>        dot rows, 1..16          — THE LESSON
##   #cols:<n>        dot columns, 1..16       — THE LESSON
##   #size:<m>        panel edge, metres
##   #width:<0.03..0.30>  line width as a fraction of the dot pitch
##   #plaque:off      hide the floor label (the drawing then takes its band back)
##   #solid:off       drop the collider
##   #color1:<html>   the first line      #color2:<html>  every line after it
##
## `#rows:4 #cols:6` is the failing lattice, and it is one token.
##
## EVERY NUMERIC KEY ABOVE IS IN CONFIG_PARAM_NAMES (GridInteractablesComponent.gd
## :16), and that is not decoration. Line 1705 reads `#key:<number>` on an UNLISTED
## key as the tutorial's positional shorthand, so a better-named `#lattice_rows:4`
## would set this artifact's yaw to 4 degrees, leave the lattice at its default,
## and look entirely correct in the map file. That fault has been found in this
## corpus at least four times and it is silent every time.
##
## THE SAME TRAP RUNS THE OTHER WAY FOR THE FLAGS. `plaque` and `solid` are NOT on
## the list, so `#solid:0` never reaches this method at all — it is read as
## shorthand, sets yaw to 0, and leaves the collider ON. Write `#solid:off`. Word
## values are safe under any key name; numeric ones are not.
##
## AND THE COLOURS TAKE NO HASH. _parse_config_token splits the whole token on "#"
## (line 1643), so `#color1:#e6e4dc` arrives as two broken parts. The bare six hex
## digits are what Color() and is_valid_html_color() both want anyway — but note
## that an all-digit colour like `#color1:030303` is only safe because `color1` is
## on the list; on an unlisted key it would parse as a number and vanish.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("rows"):
		rows = clampi(int(str(config_data["rows"]).to_float()), 1, 16)
	if config_data.has("cols"):
		cols = clampi(int(str(config_data["cols"]).to_float()), 1, 16)
	if config_data.has("size"):
		panel_m = clampf(float(config_data["size"]), 0.8, 8.0)
	if config_data.has("width"):
		cord_frac = clampf(float(config_data["width"]), 0.03, 0.30)
	if config_data.has("plaque"):
		show_plaque = _flag(config_data["plaque"])
	if config_data.has("solid"):
		solid_collider = _flag(config_data["solid"])
	if config_data.has("color1"):
		line_color = _as_color(config_data["color1"], line_color)
	if config_data.has("color2"):
		second_color = _as_color(config_data["color2"], second_color)
	if is_inside_tree():
		_build()


## `#plaque:0` arrives as the STRING "0", and bool("0") is TRUE in GDScript. The
## same helper fetish_portal, salesman_knot and do_not_cross_barrier carry, for the
## same reason.
func _flag(v) -> bool:
	if typeof(v) == TYPE_BOOL:
		return bool(v)
	return str(v).strip_edges().to_lower() in ["true", "1", "yes", "on"]


func _as_color(v, fallback: Color) -> Color:
	if v is Color:
		return v
	if v is Array and (v as Array).size() >= 3:
		var a: Array = v
		return Color(float(a[0]), float(a[1]), float(a[2]))
	var raw: String = str(v).strip_edges()
	if raw != "" and raw.is_valid_html_color():
		return Color(raw)
	push_warning("sona_floor: '%s' is not a colour; keeping %s"
		% [raw, fallback.to_html(false)])
	return fallback
