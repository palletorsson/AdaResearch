# @identity
# essence: eleven small spheres standing in a room at the positions that project, from one marked spot on the floor, into a cross — with nothing drawn between them and nothing ever to be drawn between them
# desire: that a visitor read a cross from the mark, walk toward it, arrive among eleven separate objects, and be unable to name the step at which the cross stopped being there
# critical_parameter: figure — "cross" is Wertheimer's demonstration, "square" is closure (twelve slots on a perimeter, eleven filled, and the eye shuts the gap anyway), "none" is the control. An experiment that cannot show its own null case is a claim, not an experiment
# triggers: _ready() solves each dot along the ray from the standing mark, so the figure is exact from there and sheared from everywhere else; nothing moves afterwards and nothing needs to
# emerges: a figure with no substrate — no line, no plane, no edge, no centre object. The cross is assembled behind the visitor's eyes, and it leaves with them
# needs: floor at y=0 under the origin [the grid provides it]; ~4 m of clear approach and nothing parked between the mark and the dots [spatial_needs.clearance.front]; a lit hall — eleven matte dots in the dark are ten dots and a hole [the hall provides it]
# relationships: the floor mark speaks walk_this_line_marking's vocabulary (a painted slab plus a stencil) but is rebuilt here rather than instanced, because the legend has to be DERIVED from the count or it lies the moment a map changes the number; argues with the point primitives next door, which teach a point as a location and stop there
# truth: eleven dots and a cross are the same eleven dots. Wertheimer's subjects reported the cross first and had to be asked twice before they counted. What you see is a fact about where you are standing — and this project already learned that from the other end, when five of the seven artifacts it had written down as INERT turned out to be alive from a standpoint nobody had tried.

extends Node3D
class_name ElevenDots

## ELEVEN DOTS — Wertheimer, Berlin, sometime in the 1910s. Shown an array of
## dots most subjects report A CROSS, not eleven dots, and Wertheimer took that
## as evidence that the whole arrives first and the parts are recovered from it
## afterwards — against Mach, for whom perception accumulates discrete atoms of
## sense-data, and alongside Ehrenfels, who had said the same about melody:
## transpose it and it is still the tune, because the tune is not its notes.
##
## The corpus's primitives open by claiming a point is position without
## extension. Nothing in the registry, before this, said gestalt. This is the
## objection: eleven positions without extension, and a cross that is nowhere.
##
## HOW IT IS BUILT, AND WHY THAT WAY. The dots are not coplanar. Each one is
## slid along the ray from the standing mark through its place in the figure,
## so from the mark the eleven land exactly on the cross and from anywhere else
## they are a scatter with a memory of one. That is an anamorphosis, and it is
## the mechanism that makes walking IN dissolve the figure rather than merely
## enlarging it.
##
## The default depth is small on purpose — see depth_m. A large one is the more
## interesting artifact and the wrong one to ship: every still this corpus takes
## is shot at yaw 0.62 rad, roughly 35 degrees off the approach, and an artifact
## whose whole argument is invisible from the only camera anyone points at it is
## an artifact that photographs as broken.
##
## THE ORIGIN IS THE FLOOR at the centre of the dot field, not the centre of the
## dots. Nothing sits below y=0 and the lowest dot is lifted clear of it, because
## an artifact centred on its own origin stands half-sunk everywhere
## auto-grounding is skipped — which is every map token carrying an explicit y.
## Place the token on the DOT cell; the mark eats floor at +Z, toward the
## approach.
##
## AND THE REGISTRY SETS auto_ground:false, which this artifact needs and most do
## not. _auto_ground_artifact snaps the AABB base to the cell in BOTH directions
## — its header still says "only ever lift up", but the code since then drops a
## floating artifact too (GridInteractablesComponent.gd:2196). With the mark on
## that is a no-op: the paint puts min_y at 0.006, inside the 0.01 tolerance. With
## `#mark:false` the lowest geometry is the lowest DOT at y=0.395, and the whole
## field would be dropped 0.395 m — swallowing FLOOR_CLEAR entirely, seating a
## dot on the floor, and moving the solved standpoint down out from under a
## standing visitor's eyes. Order matters and runs the wrong way: both calls are
## deferred and FIFO, and _apply_artifact_config is registered first (line 1296)
## and auto-ground second (line 1355), so the rebuild without the mark happens
## BEFORE the AABB is measured. Dots that float are the artifact.

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# ── constants that are decisions, not settings ────────────────────────────────

## Metres the paint floats above the floor, against z-fighting. walk_this_line
## _marking's number, repeated rather than re-derived.
const LIFT := 0.006
## Metres of air under the lowest dot. A dot resting on the floor has a contact
## shadow and a floor to be measured against, and stops being a free position.
const FLOOR_CLEAR := 0.12
## The scatter is SEEDED. An unseeded randf makes each capture a different
## artifact, and the control condition is worth nothing if it is not the same
## control twice. Date of the build, so the number is at least honest about
## being arbitrary.
const SCATTER_SEED := 20260909
## Low-discrepancy step for the depth offsets — deterministic, evenly spread,
## and uncorrelated with a dot's place in the figure. Correlated depths shear
## the cross into a legible skew when you step aside; uncorrelated ones shear
## it into nothing, which is the point.
const GOLDEN := 0.6180339887
## The mark: a short stripe, roughly a stance wide. Deliberately NOT a long line
## — walk_this_line_marking's stripe says follow me, and this one has to say
## stand on me, and the only thing separating those two sentences is length.
const MARK_LEN := 0.75
const MARK_W := 0.075
const MARK_H := 0.012
const MARK_COLOR := Color(0.88, 0.88, 0.85)

# ── the knobs ─────────────────────────────────────────────────────────────────

@export_category("The figure")
## "cross" · "square" · "none". The whole artifact.
##
## cross  — a plus, vertical arm longer. Wertheimer's array.
## square — the eleven sit on a twelve-slot perimeter and the twelfth is left
##          out. You see a square. That is closure, a different Gestalt law from
##          the cross's proximity and continuation, and it costs one line to
##          offer, so the artifact demonstrates two things instead of one.
## none   — the control. It is not "no figure": with eleven points the eye finds
##          one regardless, and THAT is the finding rather than a defect of the
##          scatter. What "none" withholds is a figure we put there.
@export var figure: String = "cross"
## Eleven, because eleven is the number in the experiment. It is a knob because
## the interesting question is which counts still carry a figure, and an
## artifact that cannot be asked is not an instrument.
@export_range(3, 24) var count: int = 11
## Total height of the figure in metres. 2.4 puts the dot pitch at 0.40 m for
## the default cross — far enough apart that standing in the middle of it there
## is no figure left to see, close enough that it closes into one at the mark.
@export var spread_m: float = 2.4
## Front-to-back scatter, metres. THE DEFAULT IS DELIBERATELY MODEST.
##
## 0.55 m across a 2.4 m figure puts about ±0.19 m of lateral shear into a view
## 35 degrees off-axis — a bit under half the 0.40 m dot pitch. The cross still
## reads as a cross and visibly is not flat, which is what invites the walk.
## At 1.8 m it is a cross from the mark and gravel from everywhere else. That is
## the better artifact and the worse default: this corpus captures at yaw 0.62,
## and an argument no camera can see gets written down as INERT.
##
## 0.0 is the literal Wertheimer array — genuinely coplanar, figure intact from
## every standpoint in front, dissolving only on approach.
@export var depth_m: float = 0.55
## Dot radius at the picture plane, metres. 0.05 gives 10 cm balls on a 40 cm
## pitch — a quarter of the gap, about what a printed dot is to its spacing.
## Bigger and they stop being dots and start being sculpture, and then the
## grouping is between objects rather than between positions.
@export var dot_radius_m: float = 0.05

@export_category("The standpoint")
## Metres from the dot field to the mark. The figure subtends ~41 degrees from
## here: the whole cross inside a comfortable glance, without the visitor having
## to sweep for it.
@export var stand_distance_m: float = 3.2
## Where the eyes are at the mark. NOT reachable from a map token, on purpose:
## `#height:` everywhere else in this corpus means "how tall is the thing", and
## a token that set this would nine times in ten mean the other one.
@export var eye_height_m: float = 1.6
## Paint the mark. Off, this is a field of dots with a standpoint and no way to
## find it — which is a legitimate placement (a hall whose doorway already sits
## on the axis needs no floor paint) and a bad default.
@export var show_mark: bool = true

@export_category("Finish")
## Bone rather than white. A pure 1.0 albedo clips and every dot loses its
## terminator at once, so eleven spheres become eleven discs — which sounds like
## what this artifact wants and is not: it wants them to read as the same KIND
## of thing, and clipping makes them read as a UI overlay instead.
@export var dot_color: Color = Color(0.90, 0.89, 0.85)
## Colliders on the dots. OFF by default and that is an argument, not laziness:
## a visitor has to be able to walk INTO the field for it to come apart, and a
## point is position without extension — a solid one would be a small hard fact
## in the air contradicting the sentence the primitives open with. When it IS
## on, each shape is a sphere of exactly the drawn radius, concentric with the
## mesh, so the thing is grabbable where it looks grabbable.
@export var solid_dots: bool = false


func _ready() -> void:
	_build()


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

	var kind: String = figure.strip_edges().to_lower()
	var pts: Array = _figure_points(count, kind)
	if pts.is_empty():
		return

	# Centre the figure on its own extents and scale it to spread_m. Extents,
	# not centroid: a centroid puts the cross off-centre because the vertical
	# arm has more dots in it, and the thing that has to be centred is the
	# SHAPE, which is what the visitor aligns themselves to.
	var min_u: float = INF
	var max_u: float = -INF
	var min_v: float = INF
	var max_v: float = -INF
	for fp in pts:
		min_u = minf(min_u, fp.x)
		max_u = maxf(max_u, fp.x)
		min_v = minf(min_v, fp.y)
		max_v = maxf(max_v, fp.y)
	var span_v: float = maxf(max_v - min_v, 0.001)
	var s: float = spread_m / span_v
	var cu: float = (max_u + min_u) * 0.5
	var cv: float = (max_v + min_v) * 0.5

	var sd: float = maxf(stand_distance_m, 0.6)
	var eye := Vector3(0.0, eye_height_m, sd)

	# Depth offsets, then the ray parameter that puts each dot there. A dot's
	# z is fixed first and t follows from it, rather than the other way round,
	# so depth_m means metres of room and not metres of some ray.
	#
	# THE SCATTER CANNOT EXCEED THE STANDING DISTANCE. z(t) = sd * (1 - t), so
	# t = 1 - z/sd, and half a span greater than sd puts a dot BEHIND the eye:
	# t goes negative, the figure inverts through the standpoint, and the dot
	# radius (dot_radius_m * t) goes negative with it — SphereMesh with a
	# negative radius, and a SphereShape3D to match when solid_dots is on.
	#
	# The earlier note here claimed the clamps made that impossible. They do not:
	# at the legal corner #outer:0.6 #depth:2.0, t measured -0.481 to 2.667 and
	# the smallest dot came out a -0.024 m sphere. Capping the span at sd holds
	# t in [0.5, 1.5] for every reachable setting, and the shipped default
	# (0.55 against 3.2) is nowhere near the cap — it is unchanged.
	var span: float = minf(depth_m, sd)
	var ts: Array = []
	var t_min: float = INF
	for i in range(pts.size()):
		var off: float = span * (fmod(float(i) * GOLDEN, 1.0) - 0.5)
		var t: float = 1.0 - off / sd
		ts.append(t)
		t_min = minf(t_min, t)

	# Lift the whole figure until the lowest dot clears the floor — by moving
	# the FIELD CENTRE and re-solving, not by translating the finished dots.
	# A rigid translation of an anamorph shears it: every dot moves the same
	# world distance but a different screen distance, because they are at
	# different depths. Re-solving from a raised centre is exact.
	var fc: float = eye_height_m
	var deficit: float = 0.0
	for i in range(pts.size()):
		var p := Vector3((pts[i].x - cu) * s, fc + (pts[i].y - cv) * s, 0.0)
		var q: Vector3 = eye + (p - eye) * float(ts[i])
		deficit = maxf(deficit, FLOOR_CLEAR - (q.y - dot_radius_m * float(ts[i])))
	if deficit > 0.0:
		# Each dot rises by deficit * t, so dividing by the smallest t is the
		# conservative correction that clears every one of them in one pass.
		fc += deficit / maxf(t_min, 0.05)

	var mat := _dot_material()

	var field := Node3D.new()
	field.name = "Dots"
	add_child(field)

	for i in range(pts.size()):
		var t: float = float(ts[i])
		var p := Vector3((pts[i].x - cu) * s, fc + (pts[i].y - cv) * s, 0.0)
		var q: Vector3 = eye + (p - eye) * t
		# Radius scales with t, so all eleven subtend the SAME angle from the
		# mark. The alternative — one world radius for all — leaves the near
		# dots visibly larger, which weights the figure unevenly and tells you
		# about the depth before you have walked anywhere. Measured across the
		# shipped depth: t runs 0.924 to 1.086, so 1.18x between the smallest
		# dot and the largest — invisible from the mark, plain at two metres.
		var r: float = dot_radius_m * t

		var mi := MeshInstance3D.new()
		mi.name = "Dot_%02d" % i
		var sphere := SphereMesh.new()
		sphere.radius = r
		sphere.height = r * 2.0
		# A 10 cm ball three metres away needs no more than this, and eleven of
		# them at Godot's 64/32 default is 40k triangles for a row of dots.
		sphere.radial_segments = 16
		sphere.rings = 8
		mi.mesh = sphere
		mi.material_override = mat
		mi.position = q
		field.add_child(mi)

		if solid_dots:
			var body := StaticBody3D.new()
			body.name = "Solid"
			var cs := CollisionShape3D.new()
			var shape := SphereShape3D.new()
			# Same r, and the mesh carries no node scale, so the shape is the
			# silhouette. A collider inherited from somewhere else is how
			# pink_gun ended up with 2 cm of grabbable under 30 cm of body.
			shape.radius = r
			cs.shape = shape
			body.add_child(cs)
			mi.add_child(body)

	if show_mark:
		_build_mark(pts.size())


## The mark: where the figure exists. walk_this_line_marking's grammar — a matte
## slab plus a baked stencil — rebuilt rather than instanced, because the legend
## has to carry the count and an instanced marking would need a second config
## path to be told what number to say.
func _build_mark(n: int) -> void:
	var mark := Node3D.new()
	mark.name = "Mark"
	add_child(mark)

	var paint := StandardMaterial3D.new()
	paint.albedo_color = MARK_COLOR
	# Floor paint takes no highlight from the hall's key light, or it becomes a
	# puddle. Pinned rather than inherited from a kit finish, for that reason.
	paint.roughness = 1.0
	paint.metallic = 0.0

	var stripe := MeshInstance3D.new()
	stripe.name = "Stripe"
	var slab := BoxMesh.new()
	# A slab, not a quad: a quad is one-sided and disappears edge-on, so the
	# mark would only exist for someone already looking down at it.
	slab.size = Vector3(MARK_LEN, MARK_H, MARK_W)
	stripe.mesh = slab
	stripe.material_override = paint
	stripe.position = Vector3(0.0, LIFT + MARK_H * 0.5, stand_distance_m)
	mark.add_child(stripe)

	# DERIVED, never typed. n is what was actually built, not what `count` asked
	# for — the scatter can come up short against its own separation test, and a
	# floor that lies about its own count is worse than a bare floor in a room
	# whose entire subject is counting.
	var legend: MeshInstance3D = HangarKit.stencil(
		"STAND HERE - %d DOTS" % n, Vector2(0.9, 0.11), MARK_COLOR)
	if legend:
		legend.name = "Legend"
		# -90 about X lays the text flat with its up-vector pointing to -Z, so
		# it reads for a body facing the dots. Standing off toward +Z puts the
		# words in front of the feet, the way walk_this_line_marking does it.
		legend.rotation_degrees.x = -90.0
		legend.position = Vector3(0.0, LIFT, stand_distance_m + 0.24)
		mark.add_child(legend)


## Chalk, not plastic. A specular highlight is most of what tells you a sphere
## is a sphere, and a printed dot has none — so the roughness is pinned at 1.0
## and F0 pulled down to 0.15. That is the OPPOSITE of the near-black recipe
## fetish_portal carries, and deliberately: killing Fresnel on a dark body turns
## it into a hole, and a light body loses nothing when its limb goes quiet.
##
## The small emission is not a glow, it is a floor. It lifts each dot's dark
## side so all eleven hold roughly one value from the mark, because a dot that
## falls into shadow drops out of the figure and leaves a cross with a gap in
## it — and a gap the room made is not a gap the artifact is arguing about.
func _dot_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = dot_color
	m.roughness = 1.0
	m.metallic = 0.0
	m.metallic_specular = 0.15
	m.emission_enabled = true
	m.emission = dot_color
	m.emission_energy_multiplier = 0.30
	return m


# ── figures, in lattice units (pitch 1) ───────────────────────────────────────

func _figure_points(n: int, kind: String) -> Array:
	var c: int = clampi(n, 3, 24)
	match kind:
		"cross", "":
			return _cross_points(c)
		"square":
			return _square_points(c)
		"none", "scatter", "control":
			return _scatter_points(c)
		_:
			push_warning("eleven_dots: figure '%s' is not one of cross/square/none; building the cross" % kind)
			return _cross_points(c)


## A plus with the vertical arm longer. At 11 the split is 3 out from centre
## vertically and 2 horizontally, which is Wertheimer's array exactly: 1 + 6 + 4.
## Three fifths of the arms go vertical, and the guard below stops small counts
## collapsing the horizontal arm to nothing and leaving a vertical line — which
## would still be reported, correctly, as a line and not a cross.
##
## THE SPLIT IS INTEGER ARITHMETIC, and that is not fussiness. `ceil(half * 0.6)`
## sits on a float cliff: 5 * 0.6 lands one ulp below 3.0 and rounds back up to
## exactly 3.0, so at eleven it happens to be right, but 4 * 0.6 does not, and a
## count whose figure depends on which side of an ulp a double falls is a bug
## waiting for a different Godot build. (6 * half + 5) / 10 in ints is the same
## rounding with none of the cliff.
func _cross_points(n: int) -> Array:
	var pts: Array = [Vector2.ZERO]
	if n <= 1:
		return pts
	var half: int = (n - 1) / 2
	var spare: int = (n - 1) % 2
	var v_side: int = (6 * half + 5) / 10
	var h_side: int = half - v_side
	if half >= 2 and h_side < 1:
		h_side = 1
		v_side = half - 1
	for k in range(1, v_side + 1):
		pts.append(Vector2(0.0, float(k)))
		pts.append(Vector2(0.0, float(-k)))
	for k in range(1, h_side + 1):
		pts.append(Vector2(float(k), 0.0))
		pts.append(Vector2(float(-k), 0.0))
	if spare == 1:
		# An even count cannot be a symmetric plus. The odd dot extends the top
		# of the vertical arm, which makes a Latin cross rather than breaking
		# the symmetry somewhere the eye would read as an error.
		pts.append(Vector2(0.0, float(v_side + 1)))
	return pts


## n dots spaced evenly around a square perimeter cut into n+1 slots, filling
## all but the last. The GAP IS THE ARTIFACT: at eleven you get every corner,
## two dots on three sides, one missing from the fourth, and the square closes
## itself. Corners are never the one omitted — the parameterisation starts at a
## corner and walks clockwise, so the empty slot always lands mid-edge, which is
## the only place closure works. A missing corner reads as damage.
func _square_points(n: int) -> Array:
	var pts: Array = []
	var slots: int = n + 1
	for i in range(n):
		pts.append(_square_at(8.0 * float(i) / float(slots)))
	return pts


func _square_at(t: float) -> Vector2:
	if t < 2.0:
		return Vector2(-1.0, -1.0 + t)
	if t < 4.0:
		return Vector2(-1.0 + (t - 2.0), 1.0)
	if t < 6.0:
		return Vector2(1.0, 1.0 - (t - 4.0))
	return Vector2(1.0 - (t - 6.0), -1.0)


## The control, inside the CROSS'S OWN BOUNDING BOX so the comparison is between
## two arrangements of one volume and not between a figure and a different-sized
## cloud. Rejection-sampled to a minimum separation of 0.55 pitch: two dots that
## touch are one dot, and the count is the thing under discussion.
func _scatter_points(n: int) -> Array:
	var frame: Array = _cross_points(n)
	var bx: float = 0.0
	var by: float = 0.0
	for p in frame:
		bx = maxf(bx, absf(p.x))
		by = maxf(by, absf(p.y))
	bx = maxf(bx, 1.0)
	by = maxf(by, 1.0)

	var rng := RandomNumberGenerator.new()
	rng.seed = SCATTER_SEED
	var pts: Array = []
	var guard: int = 0
	while pts.size() < n and guard < 6000:
		guard += 1
		var p := Vector2(rng.randf_range(-bx, bx), rng.randf_range(-by, by))
		var ok: bool = true
		for q in pts:
			if p.distance_to(q) < 0.55:
				ok = false
				break
		if ok:
			pts.append(p)
	return pts


## Per-cell configuration from a map token. Keys honoured:
##
##   #figure:cross | #figure:square | #figure:none
##   #count:11            the number of dots
##   #size:2.4            figure height, metres   (alias: #width)
##   #depth:0.55          front-to-back scatter, metres. 0 = coplanar
##   #radius:0.05         dot radius, metres
##   #outer:3.2           metres from the dots to the standing mark
##   #mark:false          hide the floor mark
##   #solid:true          give the dots colliders
##   #color1:e6e4dc       dot colour, NO leading # (alias: #color)
##
## THE COLOUR TAKES NO HASH. _parse_config_token splits the whole token on "#"
## (GridInteractablesComponent.gd:1643), so `#color1:#e6e4dc` arrives as two
## parts — the key becomes the literal string "color1:" with value `true`, and
## "e6e4dc" becomes a second key — and config_data.has("color1") is then false.
## String.is_valid_html_color() and Color() both accept the bare six hex digits,
## so the hash was never needed. salesman_knot documents it the same way.
##
## EVERY NUMERIC KEY ABOVE IS IN CONFIG_PARAM_NAMES, and that is not decoration.
## GridInteractablesComponent.gd:1705 reads `#key:<number>` on an UNLISTED key as
## the tutorial's positional shorthand, so `#spread:2.4` never arrives here — it
## becomes a 2.4-degree rotation and the artifact keeps its default while looking
## like it was configured. `outer` is the standing distance for exactly that
## reason: it is the only safe key left that means "how far out", and a clearer
## name would silently not work.
##
## The same trap runs the other way for the booleans: `#solid:0` is a lone
## numeric on an unlisted key, so it is eaten as a rotation. Write `#solid:true`
## and `#mark:false` — and note that those arrive as the STRINGS "true"/"false",
## and bool("false") is TRUE in GDScript, which is what _flag() is for.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("figure"):
		figure = str(config_data["figure"]).strip_edges().to_lower()
	if config_data.has("count"):
		count = clampi(int(str(config_data["count"]).to_float()), 3, 24)
	for k in ["size", "width", "spread_m"]:
		if config_data.has(k):
			spread_m = clampf(float(config_data[k]), 0.4, 12.0)
	if config_data.has("depth"):
		depth_m = clampf(float(config_data["depth"]), 0.0, 6.0)
	if config_data.has("radius"):
		dot_radius_m = clampf(float(config_data["radius"]), 0.01, 0.4)
	for k in ["outer", "stand_distance_m"]:
		if config_data.has(k):
			stand_distance_m = clampf(float(config_data[k]), 0.6, 20.0)
	if config_data.has("mark"):
		show_mark = _flag(config_data["mark"])
	if config_data.has("solid"):
		solid_dots = _flag(config_data["solid"])
	for k in ["color1", "color", "dot_color"]:
		if config_data.has(k):
			dot_color = _as_color(config_data[k], dot_color)
	if is_inside_tree():
		_build()


## Config values arrive as strings, and bool("0") and bool("false") are both
## true. The same helper fetish_portal and do_not_cross_barrier carry, for the
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
	if raw.is_valid_html_color():
		return Color(raw)
	push_warning("eleven_dots: '%s' is not a colour; keeping %s" % [raw, fallback.to_html(false)])
	return fallback
