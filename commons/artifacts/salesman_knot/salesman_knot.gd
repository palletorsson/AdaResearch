# @identity
# essence: a floor plate carrying ONE closed tour of an even lattice, drawn at a stroke width that varies with a trefoil field — so the same geometry reads as a woven cord from across the room and as a single non-self-crossing path from directly above
# desire: that the reversal is discovered by WALKING and not by being told; that a visitor sees a knot, steps onto it, and finds there is no knot, only the places where one line got thin
# critical_parameter: stroke_max — the widest the line gets, as a fraction of the lattice pitch. At 1.0 adjacent runs of the tour touch and the near reading dies on the spot; the clamp at 0.85 is what guarantees a black gap survives everywhere, which is the only reason the thing is still one line when you are standing on it
# triggers: _ready() builds the serpentine Hamiltonian circuit, jitters the lattice inside a bound that provably cannot make the polyline touch itself, evaluates the trefoil field once per edge, and lays the whole tour down as ONE MultiMesh. Nothing moves afterwards and nothing needs to
# emerges: figure and ground trading places as a function of distance — a dark cord over a pale ground at six metres, a pale line on a dark ground at one, with no frame in between where it is both
# needs: a lit room with some ambient — an unlit hall flattens the plate to two greys and the near/far difference goes with it [the hall provides it]; floor a body can stand IN THE MIDDLE OF rather than in front of [spatial_needs asks for it, player_position "above"]; apply_grid_config [present]
# relationships: stands in GT_Pathfinding, whose blurb says "the route was always there, encoded in the topology" — this is the case where that sentence is exactly false, because on a full lattice every route is the same route by area; the corpus's first travelling salesman and first Hamiltonian circuit (`salesman` and `hamilton` both returned zero tokens across 2975 on 2026-09-09); built like walk_this_line_marking — a slab, never a quad, so the marks do not vanish edge-on — and like nothing else in claim
# truth: a tour that visits every point of a uniform lattice exactly once lays down the same length of line however it is routed. Coverage is stroke ÷ pitch and the salesman cannot move it. So nothing you can see in this picture was decided by the path — the knot is made of WIDTH, and of the gaps, and it is only a knot from far enough away that you cannot count the lines. Walk in and the cord turns out to be nothing: the places where the line got thin. Neither reading is the illusion. The distance is.

extends Node3D
class_name SalesmanKnot

## AFTER Robert Bosch, "Knot?" (2006) — a continuous line computed from a
## 5000-city travelling-salesman tour. Across the room it is a black Celtic cord
## on grey. Up close the grey is a single white line on black that never crosses
## itself, and the cord was never there.
##
## HOW THIS ONE IS BUILT, AND WHY IT IS NOT BUILT THE OTHER WAY
##
## Bosch places 5000 cities by STIPPLING a target image — cities crowd where the
## picture is dark — and then solves the tour. The picture lives in where the
## points are. That route was rejected here for two reasons and one proof:
##
##   THE PROOF. On a Hamiltonian circuit through a UNIFORM lattice of N points at
##   pitch p, every point has degree 2 and every edge is one grid step, so the
##   total drawn length is exactly N·p no matter how the tour is routed. Ink area
##   is N·p·w over a panel of area N·p², i.e. coverage = w/p, CONSTANT and
##   independent of routing. A "controlled detour" therefore cannot darken
##   anything: reroute all you like, the tone does not move. Only two things can
##   make a picture — moving the points, or changing the stroke.
##
##   WHY NOT MOVE THE POINTS. A stipple plus a nearest-neighbour tour self-crosses
##   constantly; making it planar needs 2-opt run to convergence, which is minutes
##   of GDScript in a _ready() that has to return in one frame. And the artifact's
##   whole claim is "never crosses itself" — a claim it would then only mostly keep.
##
##   SO: STROKE. The lattice stays uniform and provably planar, and the width is
##   modulated by a knot field. Same optical result, exact, and defensible in one
##   line of arithmetic instead of a solver nobody can check.
##
## THE FIGURE is a real trefoil: the (2,3) torus knot
##     x = (2 + cos 3t)·cos 2t,  y = (2 + cos 3t)·sin 2t,  z = sin 3t
## projected to the panel, with z deciding which strand is over at each of its
## three crossings, and the under strand erased inside the over strand's halo —
## which is what an over-and-under actually IS in knotwork: a background gap of
## `KNOT_GAP` on each side of the strand that passes in front.
##
## Where the cord falls the stroke goes THIN, so the cord is dark. Where it does
## not, the stroke goes FAT, so the ground is pale.
##
## MEASURED AT THE SHIPPED DEFAULTS, in a Python mirror of this file (2026-09-09,
## 2.4 m panel, 28 cities a side, seed 2006):
##   tour            784 cities, each visited once, every edge one grid step,
##                   closes on (0,0) — and 0 self-crossings brute-forced over all
##                   307k edge pairs with the jitter applied
##   pitch           81.4 mm; stroke 11.4 mm in the cord, 53.7 mm on the ground
##   gap between runs never below 13.1 mm — every non-incident edge pair, caps
##                   included, WITH the jitter applied. The 27.7 mm this block
##                   claimed first is pitch·(1 − stroke_max), the same figure with
##                   jitter OFF; the shipped 0.55 takes 2·amp = 15.2 mm back out of
##                   it. Still black everywhere between runs, so the near reading
##                   survives — on half the margin the comment used to assert.
##   coverage        14% against 66%, mean 47.1%; 36.2% of edges read as cord
##   albedo          0.152 against 0.608, a ratio of 3.98:1
## Those are coverage and albedo arithmetic, not renders. A render adds a light,
## and the ratio it returns will not be this one.
##
## NOT A CAPTURE SWEEP. There is no dna.axes block here on purpose: the axis that
## matters (stroke_max) has never been swept and I will not hand-type a
## declaration the bite critic has not seen.


const PBR := preload("res://commons/render/pbr_kit.gd")

# ── The stack, in metres. Everything sits ABOVE y = 0. ────────────────
# The origin is the base: a plate centred on its own origin stands half in the
# floor everywhere auto-grounding is skipped, and it is skipped for any map token
# carrying an explicit y. prism_block was fixed for exactly this on 2026-09-08.
const SLAB_H := 0.008     # the ink plate. A slab, not a quad — see walk_this_line_marking:
                          # a PlaneMesh is one-sided and the piece vanishes edge-on.
const LINE_H := 0.004     # the stroke, proud of the plate, so it takes its own light
const NODE_H := 0.0025    # a city bead, proud of the stroke
const FRAME_W := 0.045
const FRAME_H := 0.016    # the tallest thing here. 16 mm is under any step threshold.

# ── The knot field, in panel-normalised units (the field is 0..1 square) ──
const KNOT_SAMPLES := 128 ## Polyline resolution. Distances are point-to-SEGMENT, not
                          ## point-to-sample, so this only has to resolve curvature:
                          ## chord error is spacing²/(8R) = 0.031²/(8·0.140) ≈ 0.0009,
                          ## about 2 mm on a 2.3 m panel. 128 is already past enough.
                          ## (Curve length 3.99 panel units at the shipped KNOT_FILL, so
                          ## spacing = 3.99/128; R is the inner-lobe radius, FILL/6.)
const KNOT_FILL := 0.84   ## The raw curve spans exactly ±3, so the scale is FILL/6.
                          ## AND FILL IS THE CENTRE-LINE'S EXTENT, NOT THE FIGURE'S —
                          ## the cord has width, and this shipped at 0.94 as if it did
                          ## not. The three outer lobes sit at radius 3, i.e. FILL/2
                          ## from centre; the drawn cord reaches HW + FEATHER = 0.068
                          ## past that; and the outermost lattice run is at
                          ## (n − 0.5)/2n = 0.491, not 0.5, because cities are cell
                          ## CENTRES. So the figure fits only while
                          ## FILL ≤ 2·(0.491 − 0.068) = 0.846. At 0.94 the lobe pointing
                          ## at +x overshot the last run by 0.047 (107 mm) at its
                          ## feathered edge and by 0.031 (71 mm) at full opacity, out of
                          ## a 119 mm half-width — and rasterising the field showed it cut
                          ## flat against the frame while the other two closed, which
                          ## reads as damage rather than as cropping. No rotation saves
                          ## it: three lobes 120° apart always put one within 15° of an
                          ## axis, and an axis is where a square panel is nearest
                          ## (best case 0.454 + 0.068 = 0.522, still over). Found in
                          ## review 2026-09-09. 0.84 closes all three.
const KNOT_HW := 0.052    ## Cord half-width. The three inner lobes sit at radius
                          ## FILL/6 = 0.140 and 120° apart, so their chord is 0.243 —
                          ## clear of 2·HW + GAP = 0.128. Raise HW past ~0.07 and the
                          ## lobes fuse into a blob and the knot stops being a knot.
const KNOT_GAP := 0.024   ## The background break each side of the over strand. This
                          ## number IS the over-and-under.
                          ## AND IT IS DRAWN FINER THAN THE THING DRAWING IT. Walking
                          ## the centre line at 512 steps, each of the six breaks runs
                          ## 3 samples of a 3.99-unit curve = 53 mm on a 2.28 m field,
                          ## against a lattice pitch of 81 mm. A break shorter than one
                          ## cell survives only where a run happens to fall inside it,
                          ## so at the default `lattice` roughly two of the six vanish
                          ## and the rest show as ~3 fattened edges. The over-and-under
                          ## is therefore REAL BUT MARGINAL here; `lattice` is the lever
                          ## (cost n²), not this constant, which cannot grow without
                          ## eating the cord. Measured 2026-09-09, not estimated.
const KNOT_FEATHER := 0.016 ## Edge softening, ~half a lattice pitch at the default
                            ## count, so the cord boundary steps once instead of
                            ## staircasing at lattice resolution.

@export_category("The tour")
## Panel edge, metres. Big enough to stand in the middle of; small enough to take
## in from standing height at the rim.
@export var panel_m: float = 2.4
## Points per side. THE COUNT IS FORCED EVEN and an odd value is decremented,
## because the serpentine circuit only closes on an even row count — see _tour().
## Cost is 2n² box instances in one draw call: 28 gives 784 cities, 1568
## instances, ~18.8k triangles. Raising it buys a finer far reading and pays in
## triangles at n².
@export_range(4, 48, 2) var lattice: int = 28
## How far each city may wander off its cell centre, as a fraction of the safe
## maximum. THE SAFE MAXIMUM IS NOT TASTE, it is the inequality that keeps the
## claim true: two parallel runs one pitch apart, each of stroke w, touch when
## 2a + w ≥ p, so a < p(1 − stroke_max)/2. Under that bound every city stays
## strictly inside its own cell, the grid's combinatorial layout is preserved,
## and two tour edges still meet only where they share a vertex. The polyline
## cannot self-cross. Set 0 for the mechanical serpentine.
@export_range(0.0, 1.0, 0.01) var jitter: float = 0.55
## Seeds the jitter. Same seed, same panel, every boot — the alternative is an
## artifact whose evidence PNG is of a different object each time it is captured.
@export var tour_seed: int = 2006

@export_category("The stroke")
## The widest the line gets, as a fraction of the lattice pitch — and so, exactly,
## the pale ground's ink coverage. Clamped at 0.85: at 1.0 adjacent runs of the
## tour merge into a field and there is no longer one line to find.
@export_range(0.04, 0.85, 0.01) var stroke_max: float = 0.66
## The thinnest, where the cord falls. The distance between these two numbers is
## the whole far-field image; set them equal and the panel is a plain tour.
@export_range(0.02, 0.85, 0.01) var stroke_min: float = 0.14
## "knot" draws the trefoil. "flat" holds the stroke at the mean of the two above
## and shows the bare Hamiltonian circuit with nothing written on it — which is
## the honest teaching case, and the one that makes the proof visible: a tour with
## no figure in it looks like a tour with no figure in it.
@export_enum("knot", "flat") var figure: String = "knot"
## Raise a bead at every city. Off by default — Bosch's cities are invisible and
## the force of the piece is that you cannot see where the tour decided anything.
## On, it makes the Hamiltonian claim literal: every bead is on the string, once.
## Costs ~32 triangles per city in a second draw call.
@export var show_nodes: bool = false

@export_category("The plate")
## Ink. Not pure white: a clipped albedo has nothing left to shade with.
@export var line_color: Color = Color(0.905, 0.900, 0.882)
## Ground. Near-black, never black — a zero albedo reads as a hole cut in the
## floor rather than as a dark body.
@export var ground_color: Color = Color(0.030, 0.029, 0.036)
## A metal rail round the edge. It gives the plate a silhouette against a floor
## of a similar value, which is most of what makes it read as an object in a still.
@export var show_frame: bool = true
## A body under the plate, matching what is SEEN — the stack is 16 mm tall and the
## shape is 16 mm tall. A visitor is meant to stand on this; a plate you fall
## through is a picture of a plate.
@export var solid_collider: bool = true

var _kp: PackedVector2Array = PackedVector2Array()
var _kz: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	_build()


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

	var panel: float = clampf(panel_m, 0.8, 8.0)
	var n: int = clampi(lattice, 4, 48)
	if n % 2 == 1:
		n -= 1
	var inset: float = (FRAME_W + 0.015) if show_frame else 0.03
	var field: float = maxf(panel - 2.0 * inset, panel * 0.4)
	var half: float = field * 0.5
	var pitch: float = field / float(n)

	var s_max: float = clampf(stroke_max, 0.04, 0.85)
	var s_min: float = clampf(minf(stroke_min, s_max), 0.02, 0.85)
	var w_max: float = s_max * pitch
	var w_min: float = s_min * pitch

	# ── the cities ────────────────────────────────────────────────
	# Cell centres, not cell corners: the outermost run then sits half a pitch
	# inside the field edge instead of on it, and the frame does not clip it.
	var amp: float = clampf(jitter, 0.0, 1.0) * pitch * (1.0 - s_max) * 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = tour_seed
	var pos := PackedVector2Array()
	pos.resize(n * n)
	for r in n:
		for c in n:
			pos[r * n + c] = Vector2(
				-half + (float(c) + 0.5) * pitch + rng.randf_range(-amp, amp),
				-half + (float(r) + 0.5) * pitch + rng.randf_range(-amp, amp))

	var seq: PackedInt32Array = _tour(n)
	var count: int = seq.size()

	# ── the stroke width, one evaluation per edge ─────────────────
	# Per EDGE and not per point: the caps take the wider of their two edges, so
	# the field is sampled n² times rather than 2n², and the join is never the
	# thinner of the two.
	var flat: bool = (figure != "knot")
	if not flat:
		_build_curve()
	var w := PackedFloat32Array()
	w.resize(count)
	for i in count:
		if flat:
			w[i] = (w_max + w_min) * 0.5
		else:
			var mid: Vector2 = (pos[seq[i]] + pos[seq[(i + 1) % count]]) * 0.5
			var q := Vector2((mid.x + half) / field, (mid.y + half) / field)
			w[i] = lerpf(w_max, w_min, _darkness(q))

	# ── the plate ─────────────────────────────────────────────────
	var slab := MeshInstance3D.new()
	slab.name = "Plate"
	var slab_mesh := BoxMesh.new()
	slab_mesh.size = Vector3(panel, SLAB_H, panel)
	slab.mesh = slab_mesh
	slab.material_override = _ground_mat()
	slab.position = Vector3(0.0, SLAB_H * 0.5, 0.0)
	add_child(slab)

	if show_frame:
		var rail: StandardMaterial3D = PBR.worn_metal(PBR.GUNMETAL, 0.35)
		var edge: float = panel * 0.5 - FRAME_W * 0.5
		var span: float = panel - 2.0 * FRAME_W
		var long_rail := Vector3(panel, FRAME_H, FRAME_W)
		var side_rail := Vector3(FRAME_W, FRAME_H, span)
		var y_rail: float = FRAME_H * 0.5
		add_child(PBR.box(Vector3(0.0, y_rail, -edge), long_rail, rail))
		add_child(PBR.box(Vector3(0.0, y_rail, edge), long_rail, rail))
		add_child(PBR.box(Vector3(-edge, y_rail, 0.0), side_rail, rail))
		add_child(PBR.box(Vector3(edge, y_rail, 0.0), side_rail, rail))

	# ── the tour ──────────────────────────────────────────────────
	# ONE MultiMesh of scaled BoxMesh instances, not a hand-written ribbon.
	# A SurfaceTool ribbon would be one mesh too, but it would put ~19k faces of
	# Godot's clockwise front-face winding in my hands; a primitive BoxMesh has
	# correct winding, normals and tangents by construction, and 2n² instances of
	# it still cost exactly one draw call.
	var unit := BoxMesh.new()
	unit.size = Vector3.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = unit
	mm.instance_count = count * 2
	var y_line: float = SLAB_H + LINE_H * 0.5
	for i in count:
		var a: Vector2 = pos[seq[i]]
		var b: Vector2 = pos[seq[(i + 1) % count]]
		var d: Vector2 = b - a
		var seg_len: float = maxf(d.length(), 0.0001)
		# Rotation about +Y maps local +X to (cos θ, 0, −sin θ), so aligning the
		# box's long axis with (dx, dz) needs θ = atan2(−dz, dx).
		# Not named `basis`: Node3D already has a property of that name, and the local
		# would shadow it (SHADOWED_VARIABLE_BASE_CLASS — a warning, not an error, but
		# free to avoid).
		var edge_basis := Basis(Vector3.UP, atan2(-d.y, d.x)) \
			* Basis.from_scale(Vector3(seg_len, LINE_H, w[i]))
		var mid2: Vector2 = (a + b) * 0.5
		mm.set_instance_transform(i, Transform3D(edge_basis, Vector3(mid2.x, y_line, mid2.y)))
		# The cap. Two edges meeting at a city leave a notch in the outer corner and
		# a step wherever the width changes; a square of the WIDER of the two fills
		# both. Axis-aligned is enough: jitter tilts an edge by at most
		# atan(2a/p) ≈ 10°, and the tilted end-face corners sit at 0.5w·cos10° from
		# the city, inside the square's half-width.
		var wc: float = maxf(w[i], w[(i + count - 1) % count])
		mm.set_instance_transform(count + i, Transform3D(
			Basis.from_scale(Vector3(wc, LINE_H, wc)), Vector3(a.x, y_line, a.y)))

	var tour := MultiMeshInstance3D.new()
	tour.name = "Tour"
	tour.multimesh = mm
	tour.material_override = _ink_mat()
	# A MultiMesh reports no useful AABB to the capture harness — every artifact
	# built from one has measured as a 1 m box. The plate above already spans the
	# panel, but this is stated rather than inherited.
	tour.custom_aabb = AABB(Vector3(-panel * 0.5, 0.0, -panel * 0.5),
		Vector3(panel, 0.05, panel))
	add_child(tour)

	# ── the cities, if asked ──────────────────────────────────────
	if show_nodes:
		var bead := CylinderMesh.new()
		bead.top_radius = 0.5
		bead.bottom_radius = 0.5
		bead.height = 1.0
		bead.radial_segments = 8
		bead.rings = 1
		var nm := MultiMesh.new()
		nm.transform_format = MultiMesh.TRANSFORM_3D
		nm.mesh = bead
		nm.instance_count = count
		var y_bead: float = SLAB_H + LINE_H + NODE_H * 0.5
		for i in count:
			var v2: Vector2 = pos[seq[i]]
			# 1.25x the local stroke, capped below the pitch: a bead wider than the
			# gap would weld two runs together and cost the near reading, which is
			# the only thing this artifact has.
			var dia: float = minf(maxf(w[i], w[(i + count - 1) % count]) * 1.25,
				pitch * 0.82)
			nm.set_instance_transform(i, Transform3D(
				Basis.from_scale(Vector3(dia, NODE_H, dia)),
				Vector3(v2.x, y_bead, v2.y)))
		var cities := MultiMeshInstance3D.new()
		cities.name = "Cities"
		cities.multimesh = nm
		cities.material_override = _ink_mat()
		cities.custom_aabb = tour.custom_aabb
		add_child(cities)

	# ── the body ──────────────────────────────────────────────────
	if solid_collider:
		# The tallest thing actually present, not the tallest thing possible: with the
		# rail off AND beads on, the beads top out at SLAB_H + LINE_H + NODE_H and a
		# shape stopping at SLAB_H + LINE_H would leave them 2.5 mm proud of the body a
		# visitor stands on.
		var top: float = FRAME_H if show_frame else \
			(SLAB_H + LINE_H + (NODE_H if show_nodes else 0.0))
		var body := StaticBody3D.new()
		body.name = "Body"
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(panel, top, panel)
		shape.shape = box
		shape.position = Vector3(0.0, top * 0.5, 0.0)
		body.add_child(shape)
		add_child(body)


## THE CIRCUIT. Boustrophedon, and it is a proof rather than a heuristic.
##
##   Row 0 runs the full width, columns 0 .. n-1.
##   Rows 1 .. n-1 serpentine through columns 1 .. n-1 only, turning at each end.
##   Column 0 is the return spine, rows n-1 .. 1, closing on (0,0).
##
## It CLOSES only on an even row count. Odd rows run right-to-left and end at
## column 1; even rows end at column n-1. The last row must end at column 1 to
## reach the spine, so n-1 must be odd, so n must be even. An odd `lattice` is
## decremented rather than accepted, because the alternative is a tour with a
## visible break in it and a claim that is no longer true.
##
## Count: n + (n-1)² + (n-1) = n². Every city once. Every edge is one grid step,
## every city has degree 2, and grid edges meet only at cities — so the polyline
## does not cross itself, before jitter or after it.
func _tour(n: int) -> PackedInt32Array:
	var seq := PackedInt32Array()
	for c in n:
		seq.append(c)
	for r in range(1, n):
		if r % 2 == 1:
			for c in range(n - 1, 0, -1):
				seq.append(r * n + c)
		else:
			for c in range(1, n):
				seq.append(r * n + c)
	for r in range(n - 1, 0, -1):
		seq.append(r * n)
	return seq


## The (2,3) torus knot, sampled into the panel's 0..1 square. z is kept because
## it is the only thing that knows which strand is in front.
func _build_curve() -> void:
	_kp.resize(KNOT_SAMPLES)
	_kz.resize(KNOT_SAMPLES)
	var s: float = KNOT_FILL / 6.0
	for i in KNOT_SAMPLES:
		var t: float = TAU * float(i) / float(KNOT_SAMPLES)
		var r: float = 2.0 + cos(3.0 * t)
		_kp[i] = Vector2(0.5 + r * cos(2.0 * t) * s, 0.5 + r * sin(2.0 * t) * s)
		_kz[i] = sin(3.0 * t)


## 1 where the cord is (draw the stroke THIN), 0 on open ground (draw it FAT).
##
## THE TWO PASSES ARE THE TWO HALVES OF t. The curve's angular position is 2t, so
## t ∈ [0,π) sweeps every angle once and t ∈ [π,2π) sweeps every angle a second
## time: at any point of the plane the two strands that could be there are one
## from each half. Splitting the scan that way turns a two-pass
## nearest-neighbour search into ONE pass over 128 segments.
##
## AND THE SEAM IS NOT FREE, which is the part I got wrong first. The halves join
## at t = 0 and t = π, and a point sitting there is closest to the SAME strand in
## both halves — so the over/under test compares a strand against itself, the
## "under" copy is erased in the "over" copy's halo, and a break opens where no
## crossing exists. Walking the centre-line at 512 steps found 8 breaks against
## the 3 crossings a trefoil has: six real ones (two slivers each, one per side of
## the over strand) plus spurious breaks at (0.668, 0.565) and (0.964, 0.443) —
## 0.207 and 0.374 from the nearest crossing, i.e. exactly the two seams. The
## first draft of this comment asserted the seam was harmless. It measured 8.
##
## The guard: two candidates less than SEP apart in index are one strand seen
## twice, so take the nearer and skip the over/under test entirely. SEP is K/8,
## which is 45° of t — 0.50 in panel units along the curve, six and a half times
## KNOT_HW + KNOT_GAP, while a real crossing separates its two strands by K/2.
## There is no third case to get wrong. With the guard: 6 breaks, all three
## crossings, none spurious.
func _darkness(q: Vector2) -> float:
	if _kp.is_empty():
		return 0.0
	var half_k: int = KNOT_SAMPLES / 2
	var d_a: float = 1e9
	var d_b: float = 1e9
	var i_a: int = 0
	var i_b: int = half_k
	for i in KNOT_SAMPLES:
		var d: float = _seg_dist(q, _kp[i], _kp[(i + 1) % KNOT_SAMPLES])
		if i < half_k:
			if d < d_a:
				d_a = d
				i_a = i
		elif d < d_b:
			d_b = d
			i_b = i

	var idx: int = absi(i_a - i_b)
	idx = mini(idx, KNOT_SAMPLES - idx)
	if idx < KNOT_SAMPLES / 8:
		return _band(minf(d_a, d_b), KNOT_HW, KNOT_FEATHER)

	var over_d: float = d_a
	var under_d: float = d_b
	if _kz[i_a] < _kz[i_b]:
		over_d = d_b
		under_d = d_a

	# The over strand is drawn whole. The under strand is drawn EXCEPT inside the
	# over strand's halo — a background break of KNOT_GAP on each side. That break
	# is the entire over-and-under: without it two strands crossing are a plus sign.
	var in_over: float = _band(over_d, KNOT_HW, KNOT_FEATHER)
	var in_under: float = _band(under_d, KNOT_HW, KNOT_FEATHER)
	var halo: float = _band(over_d, KNOT_HW + KNOT_GAP, KNOT_FEATHER)
	return clampf(maxf(in_over, in_under * (1.0 - halo)), 0.0, 1.0)


## 1 inside `edge - f`, 0 outside `edge + f`, smoothstepped between. Written out
## rather than calling smoothstep() with a reversed range, which works but reads
## as a typo at every future glance.
func _band(d: float, edge: float, f: float) -> float:
	if f <= 0.0:
		return 1.0 if d <= edge else 0.0
	var t: float = clampf((edge + f - d) / (2.0 * f), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var l2: float = ab.length_squared()
	if l2 < 0.000000001:
		return p.distance_to(a)
	return p.distance_to(a + ab * clampf((p - a).dot(ab) / l2, 0.0, 1.0))


## Raised ink: matte, but LESS matte than the ground under it. The differential is
## deliberate and it is what carries the far reading — the stroke catches the
## room's key light and fuses into tone at a distance, while the ground gives
## almost nothing back.
##
## No roughness texture, no triplanar. Both would be sampled in a space I have not
## verified for a MultiMesh instance, and a painted line has no grain worth seeing
## at arm's length anyway — walk_this_line_marking's stripe pins its numbers for
## the same reason.
func _ink_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = line_color
	m.metallic = 0.0
	m.metallic_specular = 0.45
	m.roughness = 0.55
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


## Near-black, and the two numbers that keep it a body:
##   metallic 0        — a dielectric with nothing on it, which is what ink is.
##   metallic_specular — F0 = 0.08 × this. At 0 there is no Fresnel, and Fresnel at
##                       grazing incidence is the whole of a dark surface's limb.
##                       You almost never look at a floor except at a grazing
##                       angle, so this is the term doing the work: drop it and
##                       the plate is a hole cut in the room, not a plate.
## Roughness stays near 1 so that sheen is a broad dim wash rather than a mirror —
## a ground bright enough to compete would flatten the contrast the stroke is for.
func _ground_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = ground_color
	m.metallic = 0.0
	m.metallic_specular = 0.50
	m.roughness = 0.94
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


## Per-cell configuration from the grid. Keys honoured:
##
##   #size:<m>            panel edge, metres
##   #rows:<n> #cols:<n>  cities per side (forced even)
##   #width:<0..0.85>     the WIDEST stroke, as a fraction of the lattice pitch
##   #inner:<0..0.85>     the THINNEST stroke, same units
##   #mode:knot|flat      draw the trefoil, or hold the stroke flat
##   #intensity:<0..1>    lattice jitter
##   #generation_seed:<n> seeds it
##   #nodes:on|off        raise a bead at every city
##   #frame:on|off        the metal rail
##   #solid:on|off        the collider
##   #color1:<html>       ink        #color2:<html>  ground
##
## THE TWO STROKE KEYS ARE NOT THE NAMES I WOULD CHOOSE. `width` and `inner` are
## the two numeric keys in GridInteractablesComponent.CONFIG_PARAM_NAMES that fit;
## a key that is NOT on that list is read as the tutorial's positional shorthand,
## so `#stroke_max:0.66` would set this artifact's yaw to 0.66 degrees, leave the
## stroke at its default, and look entirely correct in the map file. That fault
## has been found in the corpus at least three times (six walkers in VFM_09_Legs,
## the catalyst ring, tentacle_placer) and it is silent every time.
##
## AND A KEY IS SAFE UNDER ANY NAME ONLY WHILE ITS VALUE IS A WORD — the shorthand
## branch fires on `key:<number>` whatever the key is. Of the keys above, `solid` is
## the only one absent from CONFIG_PARAM_NAMES (checked 2026-09-09; `frame`, `nodes`,
## `mode`, `color1`, `color2` are all on it). So `#solid:0` never reaches this method
## as a value: it is read as shorthand, sets yaw to 0, and arrives here as
## `solid = true` — i.e. it turns the collider ON. Write `#solid:off`. `#frame:0` DOES
## arrive, as the string "0", which is what _flag() below exists for.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("size"):
		panel_m = clampf(float(config_data["size"]), 0.8, 8.0)
	for k in ["rows", "cols"]:
		if config_data.has(k):
			lattice = clampi(int(config_data[k]), 4, 48)
	if config_data.has("width"):
		stroke_max = clampf(float(config_data["width"]), 0.04, 0.85)
	if config_data.has("inner"):
		stroke_min = clampf(float(config_data["inner"]), 0.02, 0.85)
	if config_data.has("mode"):
		figure = "flat" if str(config_data["mode"]).strip_edges().to_lower() == "flat" else "knot"
	if config_data.has("intensity"):
		jitter = clampf(float(config_data["intensity"]), 0.0, 1.0)
	if config_data.has("generation_seed"):
		tour_seed = int(config_data["generation_seed"])
	if config_data.has("nodes"):
		show_nodes = _flag(config_data["nodes"])
	if config_data.has("frame"):
		show_frame = _flag(config_data["frame"])
	if config_data.has("solid"):
		solid_collider = _flag(config_data["solid"])
	if config_data.has("color1"):
		line_color = _as_color(config_data["color1"], line_color)
	if config_data.has("color2"):
		ground_color = _as_color(config_data["color2"], ground_color)
	if is_inside_tree():
		_build()


## `#frame:0` arrives as the STRING "0", and bool("0") is TRUE in GDScript. The
## same helper fetish_portal and do_not_cross_barrier carry, for the same reason.
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
	if v is String and str(v) != "" and str(v).is_valid_html_color():
		return Color(str(v))
	return fallback
