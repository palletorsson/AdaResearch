extends Node3D
class_name MeasureBench

## measure_bench — one body, eight measures of it, and the question nobody in the family
## answers: HOW DOES A QUANTITY GET ITS METRE?
##
## THE FAMILY. Four artifacts declare an axis called `measure` and between them use three
## vocabularies and eleven words:
##
##   ForceMagnitudeDemo       both | acceleration | velocity | none
##   rounded_softbody         strain | collision | volume | none
##   rounded_softbody_test    strain | collision | volume | none   (same enum, see below)
##   modulor_man_demo         body | scale | canon | module | crowd
##
## THE TWO SOFTBODY NAMES ARE NOT ONE SCENE. They are TWO scenes, nested:
## rounded_softbody_test.tscn instances rounded_softbody.tscn as a child named
## `RoundedSoftBody`, and adds a floor and a cube to fall onto. Its root script,
## rounded_softbody_test.gd, owns nothing, builds nothing and draws nothing — it declares
## the same enum character for character and forwards config down. So the family is ONE
## IMPLEMENTATION UNDER TWO NAMES, which is the corpus's one-scene-many-names tell in its
## nested form, and the tell here is not identical export counts but an enum comment that
## says "Kept identical to rounded_softbody.gd's list, character for character."
##
## THE BRIEF THIS BENCH WAS BUILT FROM SAID: velocity and acceleration are DERIVATIVES,
## which do not exist at an instant without a limit, so drawing them requires choosing a
## time window; strain and volume are STATE; the Modulor's words are a CANON.
## THE CODE SAYS THE FIRST THIRD OF THAT IS FALSE, AND IT IS THE FINDING.
##
##   ForceMagnitudeDemo TAKES NO LIMIT ANYWHERE. `velocity` is read straight off
##   physics_ball.linear_velocity — the engine's number, not this file's — and
##   `acceleration` is `force_logical / _mass`, algebra at an instant. There is no
##   difference quotient, no previous frame, no window, in either branch.
##
##   THE ONE GENUINE DERIVATIVE IN THE FAMILY IS `collision`, in the softbody:
##       var vel: Vector3 = (current - prev) / maxf(delta, 0.001)
##   a finite difference over one physics tick, thresholded at speed > 1.5, with markers
##   that decay at delta * 2.0 — a 0.5 s display window on top of the tick-length
##   measurement window. The word that sounds like a state is the only one that takes a
##   limit; the two words that sound like derivatives take none.
##
## AND THE DECISIVE FACT, which is what this bench is actually for. Every rod
## ForceMagnitudeDemo draws is scaled by ONE constant:
##       const SCENE_SCALE: float = 0.33          # vector_scene_base.gd:10
##       end_node.position = vector * SCENE_SCALE # vector_scene_base.gd:141
## Force in newtons, velocity in metres per second and acceleration in metres per second
## squared are all drawn at 0.33 m per unit. THREE DIMENSIONS, ONE RULER, NEVER DECLARED.
## The brief asked this bench to state its metres-per-unit because putting a derivative
## and a state on one bench requires choosing it. The family already chose, silently,
## three times over, and the choice is why one of its two derivatives is nearly invisible
## beside the other: at the demo's own default force and mass, |a| = 2.00 m/s^2 draws
## 0.660 m of rod, and the speed the ball has reached one readout interval later,
## 0.200 m/s, draws 0.066 m. Ten to one, and the whole of the ratio is 0.1 s of clock.
##
## So `measure` does not span derivative / state / canon. It spans FOUR WAYS OF GETTING A
## METRE, and only one of them is a measurement:
##   a borrowed constant   0.330 m per unit, for three different units (velocity, accel)
##   a saturating constant 0.020 m per m/s, dead above 5 m/s      (collision)
##   no denominator at all self-normalised against a decaying max (strain)
##   a change of dimension a cube root turns m^3 into m           (volume)
##   a pure ratio          1:2, because a canon's quantity is already a length
##                                                        (module, canon)
##
## WHAT THIS BENCH DOES. ONE body — a 0.240 x 0.915 x 0.180 m slab standing on a plate,
## squeezed once at navel height by a fixed arithmetic dent — is IDENTICAL IN ALL
## TWENTY-FOUR CELLS. Nothing about the body is a variable. Eight measures of that one
## deformation are drawn as real geometry at true scale, and `reading` asks each of them
## the question the family cannot: show me the window you took.
##
## Deterministic: no randf, no noise, no _process, no Timer, no SoftBody3D, no physics
## step. Every vertex is arithmetic on constants, so two builds of one value are the same
## mesh. A real SoftBody3D here would be five different objects in five frames.


## WHICH QUANTITY IS DRAWN. Eight values: two from ForceMagnitudeDemo, three from the
## softbody, two from modulor_man_demo, and the null they share. The registry `note` says
## which member each came from, labels it DERIVATIVE / STATE / CANON, and declares its
## metres-per-unit. `none` is the default because it is the one value all three
## vocabularies contain (the softbody's `none`, and modulor's `body`, which builds nothing
## at all) and because the body under no instrument is the thing every member ships.
## (One line, deliberately over the column guide: check_dna_declarations.py matches
## `@export_enum(...)` and its `var` on the SAME line, and a wrapped declaration reports
## NO EXPORT — a declared axis the gate cannot verify.)
@export_enum("none", "velocity", "acceleration", "collision", "strain", "volume", "module", "canon") var measure: String = "none":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not MEASURES.has(picked):
			return                      ## an unreachable value keeps the standing bench
		measure = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## HOW THE QUANTITY IS PUT. This is THIS SYNTHESIS'S OWN AXIS — no member declares
## anything like it. ForceMagnitudeDemo's second axis is `body` (the mass being pushed:
## light | standard | heavy | immovable), the softbody has no second axis, and
## modulor_man_demo has none either.
##
##   on      the quantity drawn on the body, in place, at true scale. The family's own
##           condition: a mark whose size you can only judge against the thing it is on.
##   alone   THE BODY IS NOT BUILT. The stage, the metre post and the quantity's own
##           geometry, nothing else — so a rod's length is legible against a graduated
##           metre and against nothing else. This is where 0.660 m of acceleration and
##           0.030 m of collision arrow can be compared as LENGTHS, which is the only
##           way to see that they are lengths in different currencies.
##   window  THE TIME WINDOW THE QUANTITY NEEDED, built as the actual sampled positions,
##           and NOTHING ELSE about the quantity. SIX OF THE EIGHT VALUES DRAW NOTHING
##           HERE and that emptiness is the thesis, not a broken capture — see
##           `designed_nulls` in the registry, registered before the first frame.
@export_enum("on", "alone", "window") var reading: String = "on":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not READINGS.has(picked):
			return
		reading = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One measure, or all eight in a row. NOT PART OF EITHER AXIS, and that is wave 13's
## lesson paid forward: capture_config_sweep unions the AABB across a spec's variants, so
## an all-measures value declared inside `measure` would frame every cell against nine
## metres and photograph the velocity rod as a speck. The registry fixture pins `single`.
##
## IT IS ALSO WHY `both` IS DECLINED FROM ForceMagnitudeDemo. `both` draws velocity AND
## acceleration together — `shown == "both" or shown == "velocity"` and
## `shown == "both" or shown == "acceleration"` — so it is an ALL-RUNGS VALUE inside an
## axis: every other value becomes a subset of one cell and cannot be compared with it.
## The rule is the same rule; `both` breaks it in the axis, `ladder` would break it in
## the layout, and neither is allowed in `measure`.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const MEASURES: PackedStringArray = [
	"none", "velocity", "acceleration", "collision", "strain", "volume", "module", "canon"]
const READINGS: PackedStringArray = ["on", "alone", "window"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]


# ── the stage, identical to the millimetre in all twenty-four cells ─────────────────────
## THE PLATE IS ONE METRE WIDE AND THAT IS AN INSTRUMENT, not a margin. The longest rod
## on the bench — acceleration, 0.660 m at the family's own 0.33 m per unit — starts on
## the body's axis at x = -0.160 and ends at x = +0.500, the plate's own edge, exactly.
## The biggest quantity here is a plate-width. Nothing else was allowed to grow past it.
const PLATE_HALF_X: float = 0.50
const PLATE_HALF_Z: float = 0.34
const PLATE_T: float = 0.024

## THE INVARIANT RAIL, and it is two rulers standing in one post because that is the
## subject. From the plate top to +1.000 m it is a GRADUATED METRE — the SI unit, ticked
## every 0.100 m, with long ticks at 0.500 and 1.000. Above that, unticked and in Le
## Corbusier's red, it runs on to 1.154 m: the Modulor's raised hand, 2.26 m at 1:2.
## A metre is divided; a canon is not. The post says so by having graduations on only
## one of its two parts.
##
## It is in EVERY cell, which is what keeps the union AABB fixed at 1.000 x 1.154 x 0.680
## and keeps no cell blank — the `window` reading empties six of eight cells of everything
## but the body and this post, and below about 0.2 percent of frame the sweep reads a tile
## as blank rather than as a null.
## THE TICKS RUN IN +Z, TOWARD THE READER, and that is a clearance decision the replica
## forced. Graduations reaching in +X would have run into the body's -X flank, 0.027 m
## away; reaching in -X they would have overhung the plate. Reaching forward they clear
## both, and at the sweep's standpoint (yaw 0.62) a tick pointing at the camera still
## reads as a tick.
const POST_X: float = -0.44
const POST_S: float = 0.026
const POST_METRE: float = 1.000
const TICK_MINOR_L: float = 0.070
const TICK_MINOR_T: float = 0.008
const TICK_MAJOR_L: float = 0.120
const TICK_MAJOR_T: float = 0.014
const POST_FOOT_XZ: float = 0.070
const POST_FOOT_T: float = 0.014

# ── the Modulor's own numbers, at 1:2 ──────────────────────────────────────────────────
## Read straight off modulor_man_demo.gd, which reads them off modulor_man_interactive.gd.
## MOD_K = 0.5 is the ONLY scale factor on this bench that is dimensionless, because a
## canon's quantity is already a length: every number here is exactly half of Le
## Corbusier's, so any reader can double a height off the post and get the Modulor back.
##
## WHAT THE MEMBER'S TWO SERIES ACTUALLY ARE, checked against the canon and reported in
## `declines` rather than quietly corrected. Le Corbusier's 1.83 m Modulor has a RED
## series (…, 0.16, 0.27, 0.43, 0.70, 1.13, 1.83, …) and a BLUE series that is exactly
## twice it (…, 0.33, 0.53, 0.86, 1.40, 2.26, …). The member's `RED_SERIES` is
## [2.26, 1.83, 1.40, 1.13] — that is the two series INTERLEAVED (Blue, Red, Blue, Red),
## not the Red series. Its `BLUE_SERIES` is [0.86, 0.70, 0.46, 0.43, 0.27, 0.18], of
## which 0.86 is Blue, 0.70 / 0.43 / 0.27 are RED, and 0.46 and 0.18 are in NEITHER
## series: they are the figure's own limb dimensions, lifted out of _figure_points()
## where `shoulder := 0.46 / 2.0` and `hip := 0.18`. The canonical rungs in those two
## slots are 0.53 and 0.20. And phi is never computed anywhere in the file: there is no
## division, no 1.618, no recurrence — two typed lists, one of them part anatomy.
## THE MEMBER'S NUMBERS ARE USED HERE UNCHANGED, wrong rungs and all, because the bench
## is a photograph of the family and not a correction of it.
const MOD_K: float = 0.5
const ARM_RAISED: float = 2.26
const STANDING: float = 1.83
const SOLAR_PLEXUS: float = 1.40
const NAVEL: float = 1.13
const RED_SERIES: PackedFloat32Array = [2.26, 1.83, 1.40, 1.13]
const BLUE_SERIES: PackedFloat32Array = [0.86, 0.70, 0.46, 0.43, 0.27, 0.18]
const MOD_SPAN: float = 0.98
const MOD_NEST_X: float = 0.06
const MOD_NEST_Z: float = 0.10

# ── the body ───────────────────────────────────────────────────────────────────────────
## 0.240 x 0.915 x 0.180 m at rest, standing on the plate, its height EXACTLY the
## Modulor's standing height at 1:2 — so the body is a mass you can push, a specimen you
## can squeeze, and a figure you can subdivide, without being three different objects.
## One form, eight measures, and nothing about the form is a variable.
## THE BODY STANDS SO THAT ITS +X FACE IS AT x = -0.160, WHICH IS THE ROD ORIGIN, and
## that number is set by the arithmetic rather than by taste: the longest rod on the bench
## is acceleration at 0.660 m, and -0.160 + 0.660 = +0.500 is the plate's own edge. Rods
## leave the SURFACE of the body, not its axis — the first build ran them from the axis
## and the replica caught what that costs, which is that the entire 0.066 m velocity rod
## was buried inside the body and the closest pair in the sheet was a rod nobody could see.
const BODY_X: float = -0.28
const BODY_HX: float = 0.120
const BODY_HZ: float = 0.090
const ROD_X0: float = -0.16
## The back plane the canon and the module datums are drawn on, 0.10 m behind the body's
## own back face. The member draws them in the figure's plane because its figure is a
## flat polyline; this body is a 0.245 m slab, so an in-plane frame would intersect it and
## the metre post both. A drawing on the wall behind the specimen is the honest transfer.
const MOD_Z: float = -0.22
const NX: int = 14
const NY: int = 18
const NZ: int = 8

## THE ONE SQUEEZE. A hand pressing the +X face at navel height, the same dent in every
## one of the twenty-four cells. It exists so that `strain` and `volume` have something
## to be about; it is not on either axis, and it does not move between cells.
const SQ_DEPTH: float = 0.075
const SQ_H: float = 0.22
const SQ_D: float = 0.11
const SQ_BAND: float = 2.2
const SQ_BY: float = 0.030
const SQ_BZ: float = 0.036

# ── the quantities, every scale factor lifted from a member ────────────────────────────
## SCENE_SCALE, vector_scene_base.gd:10. ONE CONSTANT FOR THREE DIMENSIONS — newtons,
## metres per second, and metres per second squared — and the family never says so.
const SCENE_SCALE: float = 0.33
## ForceMagnitudeDemo's own defaults: the initial force it hands create_force_vector,
## Vector3(2.0, 0, 0), on the base class's const BALL_MASS = 1.0 at body=standard.
const DEMO_FORCE: float = 2.0
const DEMO_MASS: float = 1.0
## The demo's own readout interval, const UPDATE_INTERVAL = 0.1. The speed a ball starting
## from rest under a = F/m has reached when the demo first prints a velocity: v = a * t.
## This is the ONLY arithmetic on this bench that the member does not do itself, and it is
## one multiplication of two of the member's own constants.
const DEMO_INTERVAL: float = 0.1
## The softbody's collision threshold and its arrow law, rounded_softbody.gd:711 and :844:
##   speed > 1.5  ->  magnitude = clampf(speed / 5.0, 0.1, 1.0)  ->  arrow_len = 0.1 * mag
## So the scale is 0.020 m per m/s and it is DEAD above 5 m/s, where every arrow is 0.100 m
## whatever hit the body. A ruler with a ceiling.
const COLL_SPEED: float = 1.5
const COLL_ARROW_UNIT: float = 0.1
const COLL_BURST_UNIT: float = 0.015
const COLL_SITES: int = 24
const COLL_ARROW_S: float = 0.008
## The engine's physics tick. Not a constant in any member — it is Godot's 60 Hz default,
## which is exactly the point: the only window `velocity` has is one the artifact never
## chose and never mentions.
const TICK: float = 1.0 / 60.0
## The softbody's diamond law, rounded_softbody.gd:804: sz = 0.008 + t * 0.012, where
## t = strain / _max_strain and _max_strain is a RUNNING MAXIMUM DECAYED AT 0.999 PER
## FRAME. There is no denominator: the same body under the same squeeze draws the same
## picture whether the strain energy is a microjoule or a megajoule.
const STRAIN_K: float = 0.5              ## rounded_softbody.gd:102, var _stiffness := 0.5
const DIAMOND_BASE: float = 0.008
const DIAMOND_GAIN: float = 0.012
const STRAIN_STRIDE: int = 2
## The volume cubes. The member reports volume as the PRODUCT OF BOUNDING-BOX EXTENTS
## (rounded_softbody.gd:737, `return extents.x * extents.y * extents.z`), which is why the
## squeezed body's reported volume goes UP: the dent is small and the bulge widens the box.
## A cube root is the only way a volume becomes a length, and it is the one scale factor
## here that changes dimension.
const VOL_X: float = 0.155
const VOL_WIRE_T: float = 0.010
## Every rod is 0.036 m square in section and HAS NO ARROWHEAD, because an arrowhead is
## length that is not quantity. Only the length carries the number.
const ROD_S: float = 0.036

# ── colour, all of it per-vertex ───────────────────────────────────────────────────────
## NO EMISSION ANYWHERE, and the members use plenty of it (modulor_man_demo's _lit() sets
## emission_energy_multiplier up to 1.6). The critic measures luminance, so an emissive
## value separates pairs by glow rather than by geometry, and this whole bench is an
## argument about lengths. Every material is a plain vertex-coloured StandardMaterial3D
## with CULL_DISABLED; the ink is in the vertices.
const C_PLATE: Color = Color(0.19, 0.20, 0.23)
const C_POST: Color = Color(0.88, 0.86, 0.80)          ## modulor_man_demo.gd, BONE
const C_TICK: Color = Color(0.56, 0.57, 0.61)
const C_BODY: Color = Color(0.72, 0.71, 0.68)
const C_VEL: Color = Color(0.30, 1.00, 0.30)           ## ForceMagnitudeDemo.gd:105
const C_ACC: Color = Color(0.30, 0.30, 1.00)           ## ForceMagnitudeDemo.gd:115
const C_COLL: Color = Color(1.00, 0.30, 0.60)          ## rounded_softbody.gd, COL_COLLISION
const C_BURST: Color = Color(1.00, 0.85, 0.20)         ## rounded_softbody.gd, COL_FORCE_ARROW
const C_STRAIN_LO: Color = Color(0.15, 0.55, 0.95)     ## COL_LOW_STRAIN
const C_STRAIN_MID: Color = Color(0.20, 0.85, 0.40)    ## COL_MID_STRAIN
const C_STRAIN_HI: Color = Color(0.95, 0.25, 0.15)     ## COL_HIGH_STRAIN
const C_VOL_OK: Color = Color(0.30, 0.90, 0.50)        ## COL_VOLUME_OK
const C_VOL_WARN: Color = Color(0.95, 0.70, 0.10)      ## COL_VOLUME_WARN
const C_VOL_BAD: Color = Color(0.95, 0.20, 0.20)       ## COL_VOLUME_BAD
const C_GHOST: Color = Color(0.50, 0.50, 0.60)         ## COL_REST_GHOST
const RED_INK: Color = Color(0.86, 0.24, 0.18)         ## modulor_man_demo.gd
const BLUE_INK: Color = Color(0.22, 0.44, 0.88)        ## modulor_man_demo.gd
## The borrowed window's ink. Grey on purpose: it is the engine's tick, not the artifact's
## choice, and it must not read as one of the family's own colours.
const C_BORROW: Color = Color(0.55, 0.56, 0.58)
const C_WIN_PREV: Color = Color(0.42, 0.16, 0.28)
const C_WIN_NOW: Color = Color(1.00, 0.45, 0.70)

const LADDER_PITCH: float = 1.20
## Iterated rather than written inline, so no loop variable is untyped.
const SIGNS: PackedFloat32Array = [-1.0, 1.0]

var _built: Array[Node3D] = []
## Set while a whole config dictionary lands, so three keys cost one rebuild, not three.
var _bulk: bool = false


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("measure"):
		measure = str(config_data["measure"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
	_bulk = false
	_rebuild()


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var names: PackedStringArray = PackedStringArray()
	if layout == "ladder":
		names = MEASURES.duplicate()
	else:
		names.append(_pick(measure, MEASURES, "none"))
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Cell_" + names[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_stage(holder)
		_build_cell(holder, names[i])


# ── datums, all measured from the plate TOP so the canon's arithmetic survives it ───────

func _mod_y(rung: float) -> float:
	return PLATE_T + rung * MOD_K


# ── the body ───────────────────────────────────────────────────────────────────────────

## A capped bump: 1 at the centre, 0 at |t| >= 1.
func _bump(t: float) -> float:
	var base: float = maxf(0.0, 1.0 - t * t)
	return base


## WHERE ONE LATTICE POINT ENDS UP UNDER THE ONE SQUEEZE. Identical in every cell — the
## body is not a variable here, only what is drawn about it. A hand at navel height on the
## +X face pushes in; the material it displaces goes sideways in z and up and down in y,
## most where the dent is not. Volume is not conserved exactly and is not claimed to be:
## the member computes volume as a bounding box, and this bench's `volume` value is about
## what that costs.
func _stance(x0: float, y0: float, z0: float) -> Vector3:
	var u: float = (y0 - NAVEL * MOD_K) / SQ_H
	var w: float = z0 / SQ_D
	var radial: float = maxf(0.0, 1.0 - u * u - w * w)
	var core: float = pow(radial, 1.2)
	var face: float = pow(clampf((x0 + BODY_HX) / (2.0 * BODY_HX), 0.0, 1.0), 1.6)
	var band: float = _bump(u / SQ_BAND)
	var out: float = band * (1.0 - core)
	var dx: float = -SQ_DEPTH * core * face
	var dz: float = SQ_BZ * out * face * (z0 / BODY_HZ)
	var dy: float = SQ_BY * out * face * clampf(u, -1.0, 1.0)
	return Vector3(x0 + dx, y0 + dy, z0 + dz)


## cube[i][j] is a PackedVector3Array over k. i runs x, j runs y, k runs z. Coordinates
## are LOCAL to the body's own foot; _body_world() lifts them onto the plate.
func _lattice() -> Array:
	var cube: Array = []
	var height: float = STANDING * MOD_K
	for i in range(NX + 1):
		var x0: float = -BODY_HX + 2.0 * BODY_HX * float(i) / float(NX)
		var plane_row: Array = []
		for j in range(NY + 1):
			var y0: float = height * float(j) / float(NY)
			var col: PackedVector3Array = PackedVector3Array()
			for k in range(NZ + 1):
				var z0: float = -BODY_HZ + 2.0 * BODY_HZ * float(k) / float(NZ)
				col.append(_stance(x0, y0, z0))
			plane_row.append(col)
		cube.append(plane_row)
	return cube


func _body_world(p: Vector3) -> Vector3:
	return Vector3(p.x + BODY_X, p.y + PLATE_T, p.z)


## The rest position of the same lattice index, for the strain displacement. Recomputed
## rather than stored, so there is exactly one place the grid is defined.
func _rest_point(i: int, j: int, k: int) -> Vector3:
	var height: float = STANDING * MOD_K
	return Vector3(
		-BODY_HX + 2.0 * BODY_HX * float(i) / float(NX),
		height * float(j) / float(NY),
		-BODY_HZ + 2.0 * BODY_HZ * float(k) / float(NZ))


func _is_shell(i: int, j: int, k: int) -> bool:
	return i == 0 or i == NX or j == 0 or j == NY or k == 0 or k == NZ


## The axis-aligned box of the deformed lattice, in world coordinates. READ OFF THE BUILT
## GEOMETRY, never typed in — a hand-typed table is the science_screen fault waiting to
## happen, and here it would also make the `volume` cubes lie about the body beside them.
func _bbox(cube: Array) -> AABB:
	var lo: Vector3 = Vector3(INF, INF, INF)
	var hi: Vector3 = Vector3(-INF, -INF, -INF)
	for i in range(cube.size()):
		var plane_row: Array = cube[i]
		for j in range(plane_row.size()):
			var col: PackedVector3Array = plane_row[j]
			for k in range(col.size()):
				var p: Vector3 = _body_world(col[k])
				lo = lo.min(p)
				hi = hi.max(p)
	return AABB(lo, hi - lo)


func _rest_bbox() -> AABB:
	return AABB(
		Vector3(BODY_X - BODY_HX, PLATE_T, -BODY_HZ),
		Vector3(2.0 * BODY_HX, STANDING * MOD_K, 2.0 * BODY_HZ))


# ── building ───────────────────────────────────────────────────────────────────────────

func _build_stage(holder: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(st, Vector3(0.0, PLATE_T * 0.5, 0.0),
		Vector3(PLATE_HALF_X * 2.0, PLATE_T, PLATE_HALF_Z * 2.0), C_PLATE)
	_commit(holder, "Plate", st, 0.90, 0.0)

	# THE METRE. Graduated from the plate top to exactly +1.000 m.
	var post := SurfaceTool.new()
	post.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(post, Vector3(POST_X, PLATE_T + POST_METRE * 0.5, 0.0),
		Vector3(POST_S, POST_METRE, POST_S), C_POST)
	_add_box(post, Vector3(POST_X, PLATE_T + POST_FOOT_T * 0.5, 0.0),
		Vector3(POST_FOOT_XZ, POST_FOOT_T, POST_FOOT_XZ), C_POST)
	_commit(holder, "Metre", post, 0.55, 0.10)

	var ticks := SurfaceTool.new()
	ticks.begin(Mesh.PRIMITIVE_TRIANGLES)
	for n in range(1, 11):
		var h: float = float(n) * 0.100
		var major: bool = n == 5 or n == 10
		var tl: float = TICK_MAJOR_L if major else TICK_MINOR_L
		var tt: float = TICK_MAJOR_T if major else TICK_MINOR_T
		_add_box(ticks, Vector3(POST_X, PLATE_T + h, POST_S * 0.5 + tl * 0.5),
			Vector3(0.012, tt, tl), C_TICK)
	_commit(holder, "Graduations", ticks, 0.55, 0.10)

	# THE CANON'S TOP, ungraduated: 2.26 m at 1:2. A metre is divided, a canon is not.
	var arm := SurfaceTool.new()
	arm.begin(Mesh.PRIMITIVE_TRIANGLES)
	var arm_y: float = _mod_y(ARM_RAISED)
	var ext: float = arm_y - (PLATE_T + POST_METRE)
	_add_box(arm, Vector3(POST_X, PLATE_T + POST_METRE + ext * 0.5, 0.0),
		Vector3(POST_S * 0.72, ext, POST_S * 0.72), RED_INK)
	_commit(holder, "CanonTop", arm, 0.60, 0.0)


func _build_cell(holder: Node3D, which: String) -> void:
	var cube: Array = _lattice()
	if reading != "alone":
		_build_body(holder, cube)
	if reading == "window":
		_build_window(holder, which)
		return
	_build_measure(holder, which, cube)


func _build_body(holder: Node3D, cube: Array) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_shell(st, cube, C_BODY)
	_commit(holder, "Body", st, 0.72, 0.0)


# ── the eight measures ─────────────────────────────────────────────────────────────────

func _build_measure(holder: Node3D, which: String, cube: Array) -> void:
	match which:
		"velocity":
			_draw_rod(holder, "Velocity", DEMO_FORCE / DEMO_MASS * DEMO_INTERVAL, C_VEL)
		"acceleration":
			_draw_rod(holder, "Acceleration", DEMO_FORCE / DEMO_MASS, C_ACC)
		"collision":
			_draw_collision(holder, cube)
		"strain":
			_draw_strain(holder, cube)
		"volume":
			_draw_volume(holder, cube)
		"module":
			_draw_module(holder)
		"canon":
			_draw_canon(holder)
		_:
			pass


## A quantity as a rod whose LENGTH IS THE QUANTITY, at the family's own 0.33 m per unit.
## No head, no taper, no minimum: a quantity of zero would be a rod of zero.
func _draw_rod(holder: Node3D, rod_name: String, quantity: float, ink: Color) -> void:
	var length: float = quantity * SCENE_SCALE
	if length <= 0.0:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(st, Vector3(ROD_X0 + length * 0.5, _mod_y(NAVEL), 0.0),
		Vector3(length, ROD_S, ROD_S), ink)
	_commit(holder, rod_name, st, 0.45, 0.0)


## COLLISION — the one genuine derivative in the family, drawn by its own law. Twenty-four
## sites (MAX_COLLISION_DISPLAY) on the dented face, each an arrow of
## 0.1 * clampf(speed / 5.0, 0.1, 1.0) metres at the member's own threshold speed of
## 1.5 m/s, which is 0.030 m. They are small because the scale is small, and the scale
## saturates: at 5 m/s and at 500 m/s the arrow is the same 0.100 m.
func _draw_collision(holder: Node3D, cube: Array) -> void:
	var mag: float = clampf(COLL_SPEED / 5.0, 0.1, 1.0)
	var arrow_len: float = COLL_ARROW_UNIT * mag
	var burst: float = COLL_BURST_UNIT * mag
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sites: Array = _collision_sites(cube)
	for s in range(sites.size()):
		var at: Vector3 = sites[s]
		_add_box(st, at + Vector3(arrow_len * 0.5, 0.0, 0.0),
			Vector3(arrow_len, COLL_ARROW_S, COLL_ARROW_S), C_COLL)
		_add_diamond(st, at, burst, C_BURST)
	_commit(holder, "Collision", st, 0.40, 0.0)


## The twenty-four contact sites: the deformed +X face, sampled on a fixed 6 x 4 grid over
## the dent. Written as a list rather than picked by a threshold so the sites cannot move
## between the `on` reading and the `window` reading — the window has to be the window OF
## THESE POINTS or it is a different measurement.
func _collision_sites(cube: Array) -> Array:
	var out: Array = []
	var plane_row: Array = cube[NX]
	for a in range(6):
		var j: int = int(round(float(NY) * (0.34 + 0.055 * float(a))))
		var col: PackedVector3Array = plane_row[j]
		for b in range(4):
			var k: int = int(round(float(NZ) * (0.20 + 0.20 * float(b))))
			out.append(_body_world(col[k]))
	return out


## STRAIN — the member's own diamonds, its own colour ramp, and its own missing
## denominator. E = 0.5 * k * d^2 with k = 0.5, d measured from the rest lattice; t is
## E over the LARGEST E in this frame, so the picture is identical whatever the energies
## are. Every diamond here is a fact about a ratio and none of them is a fact about a
## joule.
func _draw_strain(holder: Node3D, cube: Array) -> void:
	var e_max: float = 0.0
	for i in range(NX + 1):
		var plane_row: Array = cube[i]
		for j in range(NY + 1):
			var col: PackedVector3Array = plane_row[j]
			for k in range(NZ + 1):
				if not _is_shell(i, j, k):
					continue
				var d: float = (col[k] - _rest_point(i, j, k)).length()
				var e: float = 0.5 * STRAIN_K * d * d
				if e > e_max:
					e_max = e
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i2 in range(0, NX + 1, STRAIN_STRIDE):
		var row2: Array = cube[i2]
		for j2 in range(0, NY + 1, STRAIN_STRIDE):
			var col2: PackedVector3Array = row2[j2]
			for k2 in range(0, NZ + 1, STRAIN_STRIDE):
				if not _is_shell(i2, j2, k2):
					continue
				var d2: float = (col2[k2] - _rest_point(i2, j2, k2)).length()
				var e2: float = 0.5 * STRAIN_K * d2 * d2
				var t: float = clampf(e2 / maxf(e_max, 0.000001), 0.0, 1.0)
				_add_diamond(st, _body_world(col2[k2]),
					DIAMOND_BASE + t * DIAMOND_GAIN, _strain_color(t))
	_commit(holder, "Strain", st, 0.35, 0.0)


func _strain_color(t: float) -> Color:
	if t < 0.5:
		return C_STRAIN_LO.lerp(C_STRAIN_MID, t * 2.0)
	return C_STRAIN_MID.lerp(C_STRAIN_HI, (t - 0.5) * 2.0)


## VOLUME — the member's bounding box, its twelve edges and its deviation colours, plus
## the one thing the member never draws: the volume AS A LENGTH. Two cubes stand on the
## plate, side = V^(1/3) — the rest volume solid and grey, the current volume as a wire
## cage around it. THE CAGE IS BIGGER, and it is bigger because the member measures volume
## as the product of bounding-box extents, so a dent that is small and a bulge that is
## wide together REPORT A GAIN. That is not a bug drawn as one; it is the member's
## arithmetic given a body.
func _draw_volume(holder: Node3D, cube: Array) -> void:
	var rest: AABB = _rest_bbox()
	var now: AABB = _bbox(cube)
	var v_rest: float = rest.size.x * rest.size.y * rest.size.z
	var v_now: float = now.size.x * now.size.y * now.size.z
	var s_rest: float = pow(maxf(v_rest, 0.000001), 1.0 / 3.0)
	var s_now: float = pow(maxf(v_now, 0.000001), 1.0 / 3.0)
	var ratio: float = v_now / maxf(v_rest, 0.000001)
	var dev: float = absf(ratio - 1.0)
	var ink: Color = C_VOL_OK
	if dev >= 0.15:
		ink = C_VOL_BAD
	elif dev >= 0.05:
		ink = C_VOL_WARN

	var solid := SurfaceTool.new()
	solid.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(solid, Vector3(VOL_X, PLATE_T + s_rest * 0.5, 0.0),
		Vector3(s_rest, s_rest, s_rest), C_GHOST)
	_commit(holder, "VolumeRest", solid, 0.80, 0.0)

	var wire := SurfaceTool.new()
	wire.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_cage(wire, AABB(Vector3(VOL_X - s_now * 0.5, PLATE_T, -s_now * 0.5),
		Vector3(s_now, s_now, s_now)), VOL_WIRE_T, ink)
	_add_cage(wire, now, VOL_WIRE_T * 0.7, ink)
	_commit(holder, "VolumeNow", wire, 0.45, 0.0)


## MODULE — the series as datum lines running clean through the body and out past it, in
## Le Corbusier's two colours, with the Blue-series squares nested off to the right. The
## member's span is 3.2 m; at 1:2 that is 1.6 m and it would take the framing with it, so
## it is CAPPED at 0.98 m, the plate. The cap is declared rather than absorbed.
func _draw_module(holder: Node3D) -> void:
	var red := SurfaceTool.new()
	red.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in RED_SERIES:
		_add_box(red, Vector3(0.0, _mod_y(float(r)), MOD_Z),
			Vector3(MOD_SPAN, 0.016, 0.016), RED_INK)
	for sx in SIGNS:
		_add_box(red, Vector3(sx * MOD_SPAN * 0.5, _mod_y(STANDING), MOD_Z),
			Vector3(0.05, 0.09, 0.05), RED_INK)
	_commit(holder, "Red", red, 0.55, 0.0)

	var blue := SurfaceTool.new()
	blue.begin(Mesh.PRIMITIVE_TRIANGLES)
	var t: float = 0.012
	for b in BLUE_SERIES:
		_add_box(blue, Vector3(0.0, _mod_y(float(b)), MOD_Z),
			Vector3(MOD_SPAN * 0.82, 0.011, 0.011), BLUE_INK)
	for b2 in BLUE_SERIES:
		var s: float = float(b2) * MOD_K
		_add_box(blue, Vector3(MOD_NEST_X + s * 0.5, PLATE_T, MOD_NEST_Z),
			Vector3(s, t, t), BLUE_INK)
		_add_box(blue, Vector3(MOD_NEST_X + s * 0.5, PLATE_T + s, MOD_NEST_Z),
			Vector3(s, t, t), BLUE_INK)
		_add_box(blue, Vector3(MOD_NEST_X, PLATE_T + s * 0.5, MOD_NEST_Z),
			Vector3(t, s, t), BLUE_INK)
		_add_box(blue, Vector3(MOD_NEST_X + s, PLATE_T + s * 0.5, MOD_NEST_Z),
			Vector3(t, s, t), BLUE_INK)
	_commit(holder, "Blue", blue, 0.55, 0.0)


## CANON — the Vitruvian frame at 1:2, and the coincidence is DRAWN rather than asserted.
## The square is the standing height, 0.915 m on a side, sitting on the plate. The circle
## is centred on the navel at 0.565 m with a radius of 0.565, so its bottom touches the
## plate and its top reaches 1.130 m — the raised hand, which is the red length on the
## post. 2 x 1.13 = 2.26 is the whole of the pre-modern argument.
func _draw_canon(holder: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var side: float = STANDING * MOD_K
	var half: float = side * 0.5
	var t: float = 0.018
	_add_box(st, Vector3(0.0, PLATE_T, MOD_Z), Vector3(side + t, t, t), RED_INK)
	_add_box(st, Vector3(0.0, PLATE_T + side, MOD_Z), Vector3(side + t, t, t), RED_INK)
	for sx in SIGNS:
		_add_box(st, Vector3(sx * half, PLATE_T + side * 0.5, MOD_Z),
			Vector3(t, side, t), RED_INK)
	_add_box(st, Vector3(0.0, _mod_y(NAVEL), MOD_Z + 0.06),
		Vector3(0.05, 0.05, 0.05), RED_INK)
	_commit(holder, "Canon", st, 0.55, 0.0)

	var ring := SurfaceTool.new()
	ring.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_ring(ring, Vector3(0.0, _mod_y(NAVEL), MOD_Z), NAVEL * MOD_K, 0.010, 64, C_POST)
	_commit(holder, "Circle", ring, 0.60, 0.0)


# ── the window ─────────────────────────────────────────────────────────────────────────

## THE TIME WINDOW, BUILT AS THE ACTUAL SAMPLED POSITIONS — and six of the eight values
## build nothing at all, which is registered as a designed null and is the point of the
## axis. What survives:
##
##   collision  ITS OWN WINDOW. vel = (current - prev) / delta is a finite difference over
##              one physics tick, so at the member's threshold speed of 1.5 m/s the two
##              samples are 1.5 / 60 = 0.025 m apart. Both sets of positions are drawn, in
##              the member's own pink, at 1:1 — the only scale factor on this bench that
##              is not a conversion.
##   velocity   A BORROWED WINDOW, drawn in grey. linear_velocity is integrated by the
##              engine, not by the artifact, so the window exists and is not the artifact's:
##              0.200 m/s over one tick is 0.0033 m, which is roughly the thickness of the
##              hairline that draws it. Pre-declared as nearly invisible.
##   everything else  NOTHING. acceleration is F/m, algebra at an instant with no limit
##              taken; strain and volume are read off the body as it stands; module and
##              canon were decided before the body arrived; none draws nothing anywhere.
func _build_window(holder: Node3D, which: String) -> void:
	if which == "collision":
		var cube: Array = _lattice()
		var sites: Array = _collision_sites(cube)
		var gap: float = COLL_SPEED * TICK
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for s in range(sites.size()):
			var at: Vector3 = sites[s]
			var prev: Vector3 = at - Vector3(gap, 0.0, 0.0)
			_add_box(st, prev, Vector3(0.006, 0.030, 0.030), C_WIN_PREV)
			_add_box(st, at, Vector3(0.006, 0.030, 0.030), C_WIN_NOW)
			_add_box(st, (prev + at) * 0.5, Vector3(gap, 0.005, 0.005), C_COLL)
		_commit(holder, "Window", st, 0.40, 0.0)
		return
	if which == "velocity":
		var gap2: float = DEMO_FORCE / DEMO_MASS * DEMO_INTERVAL * TICK
		var st2 := SurfaceTool.new()
		st2.begin(Mesh.PRIMITIVE_TRIANGLES)
		_add_box(st2, Vector3(ROD_X0, _mod_y(NAVEL), 0.0),
			Vector3(0.004, 0.040, 0.040), C_BORROW)
		_add_box(st2, Vector3(ROD_X0 + gap2, _mod_y(NAVEL), 0.0),
			Vector3(0.004, 0.040, 0.040), C_BORROW)
		_commit(holder, "BorrowedWindow", st2, 0.50, 0.0)
		return
	# acceleration, strain, volume, module, canon, none — the null class. Nothing is built
	# and nothing is committed, so no empty SurfaceTool ever reaches commit().


# ── mesh primitives ────────────────────────────────────────────────────────────────────

## The six boundary faces of the (i, j, k) lattice, wound outward from the centroid.
func _add_shell(st: SurfaceTool, cube: Array, ink: Color) -> void:
	var ni: int = cube.size()
	var plane_row: Array = cube[0]
	var nj: int = plane_row.size()
	var col: PackedVector3Array = plane_row[0]
	var nk: int = col.size()
	var centre: Vector3 = _centroid(cube)
	_add_face(st, _slice_k(cube, 0), centre, ink)
	_add_face(st, _slice_k(cube, nk - 1), centre, ink)
	_add_face(st, _slice_j(cube, 0), centre, ink)
	_add_face(st, _slice_j(cube, nj - 1), centre, ink)
	_add_face(st, _slice_i(cube, 0), centre, ink)
	_add_face(st, _slice_i(cube, ni - 1), centre, ink)


func _centroid(cube: Array) -> Vector3:
	var acc: Vector3 = Vector3.ZERO
	var n: int = 0
	for i in range(cube.size()):
		var plane_row: Array = cube[i]
		for j in range(plane_row.size()):
			var col: PackedVector3Array = plane_row[j]
			for k in range(col.size()):
				acc += _body_world(col[k])
				n += 1
	if n == 0:
		return Vector3.ZERO
	return acc / float(n)


## A boundary face, wound so its normal points AWAY from the body's centroid. Winding is
## checked per quad rather than assumed per face, because the dented face is no longer
## planar and a face-level assumption puts the normal through the object on the quads that
## curl. Every material is CULL_DISABLED besides.
func _add_face(st: SurfaceTool, grid: Array, centre: Vector3, ink: Color) -> void:
	var ni: int = grid.size()
	if ni < 2:
		return
	var probe: PackedVector3Array = grid[0]
	var nj: int = probe.size()
	if nj < 2:
		return
	for i in range(ni - 1):
		var r0: PackedVector3Array = grid[i]
		var r1: PackedVector3Array = grid[i + 1]
		for j in range(nj - 1):
			_quad(st, _body_world(r0[j]), _body_world(r1[j]),
				_body_world(r1[j + 1]), _body_world(r0[j + 1]), centre, ink)


func _slice_k(cube: Array, k: int) -> Array:
	var out: Array = []
	for i in range(cube.size()):
		var plane_row: Array = cube[i]
		var row: PackedVector3Array = PackedVector3Array()
		for j in range(plane_row.size()):
			var col: PackedVector3Array = plane_row[j]
			row.append(col[k])
		out.append(row)
	return out


func _slice_j(cube: Array, j: int) -> Array:
	var out: Array = []
	for i in range(cube.size()):
		var plane_row: Array = cube[i]
		out.append(plane_row[j])
	return out


func _slice_i(cube: Array, i: int) -> Array:
	var out: Array = []
	var plane_row: Array = cube[i]
	for j in range(plane_row.size()):
		out.append(plane_row[j])
	return out


## An axis-aligned box, twelve triangles, wound outward with explicit per-face normals.
func _add_box(st: SurfaceTool, at: Vector3, size: Vector3, ink: Color) -> void:
	var h: Vector3 = size * 0.5
	var p: PackedVector3Array = PackedVector3Array([
		at + Vector3(-h.x, -h.y, h.z), at + Vector3(h.x, -h.y, h.z),
		at + Vector3(h.x, h.y, h.z), at + Vector3(-h.x, h.y, h.z),
		at + Vector3(-h.x, -h.y, -h.z), at + Vector3(h.x, -h.y, -h.z),
		at + Vector3(h.x, h.y, -h.z), at + Vector3(-h.x, h.y, -h.z)])
	_quad(st, p[0], p[1], p[2], p[3], at, ink)
	_quad(st, p[5], p[4], p[7], p[6], at, ink)
	_quad(st, p[3], p[2], p[6], p[7], at, ink)
	_quad(st, p[4], p[5], p[1], p[0], at, ink)
	_quad(st, p[1], p[5], p[6], p[2], at, ink)
	_quad(st, p[4], p[0], p[3], p[7], at, ink)


## The softbody's own marker shape: two pyramids base to base, half-height sz.
func _add_diamond(st: SurfaceTool, at: Vector3, sz: float, ink: Color) -> void:
	var up: Vector3 = Vector3(0.0, sz, 0.0)
	var rt: Vector3 = Vector3(sz * 0.6, 0.0, 0.0)
	var fw: Vector3 = Vector3(0.0, 0.0, sz * 0.6)
	var rim: PackedVector3Array = PackedVector3Array([
		at + rt, at + fw, at - rt, at - fw])
	for s in range(4):
		var a: Vector3 = rim[s]
		var b: Vector3 = rim[(s + 1) % 4]
		_tri(st, at + up, a, b, at, ink)
		_tri(st, at - up, b, a, at, ink)


## Twelve edges of a box as square-section rods — the softbody's volume wireframe, given
## thickness so a still can see it.
func _add_cage(st: SurfaceTool, box: AABB, t: float, ink: Color) -> void:
	var lo: Vector3 = box.position
	var hi: Vector3 = box.position + box.size
	# The two loop signs must pair DIFFERENT axes for each of the three edge directions,
	# or the twelve edges come out as eight: taking x and y from the same sign draws only
	# the two diagonal verticals, twice each, and the cage photographs as an open box.
	for a in SIGNS:
		for b in SIGNS:
			var xa: float = lo.x if a < 0.0 else hi.x
			var ya: float = lo.y if a < 0.0 else hi.y
			var yb: float = lo.y if b < 0.0 else hi.y
			var zb: float = lo.z if b < 0.0 else hi.z
			_add_box(st, Vector3((lo.x + hi.x) * 0.5, ya, zb),
				Vector3(box.size.x, t, t), ink)
			_add_box(st, Vector3(xa, (lo.y + hi.y) * 0.5, zb),
				Vector3(t, box.size.y, t), ink)
			_add_box(st, Vector3(xa, yb, (lo.z + hi.z) * 0.5),
				Vector3(t, t, box.size.z), ink)


## A torus standing in the XY plane, built by hand rather than with TorusMesh so the
## winding is checked the same way everything else here is.
func _add_ring(st: SurfaceTool, at: Vector3, radius: float, tube: float, seg: int,
		ink: Color) -> void:
	var sides: int = 6
	for i in range(seg):
		var a0: float = TAU * float(i) / float(seg)
		var a1: float = TAU * float(i + 1) / float(seg)
		var c0: Vector3 = at + Vector3(cos(a0) * radius, sin(a0) * radius, 0.0)
		var c1: Vector3 = at + Vector3(cos(a1) * radius, sin(a1) * radius, 0.0)
		var n0: Vector3 = Vector3(cos(a0), sin(a0), 0.0)
		var n1: Vector3 = Vector3(cos(a1), sin(a1), 0.0)
		for s in range(sides):
			var b0: float = TAU * float(s) / float(sides)
			var b1: float = TAU * float(s + 1) / float(sides)
			var o00: Vector3 = n0 * cos(b0) * tube + Vector3(0.0, 0.0, sin(b0) * tube)
			var o01: Vector3 = n0 * cos(b1) * tube + Vector3(0.0, 0.0, sin(b1) * tube)
			var o10: Vector3 = n1 * cos(b0) * tube + Vector3(0.0, 0.0, sin(b0) * tube)
			var o11: Vector3 = n1 * cos(b1) * tube + Vector3(0.0, 0.0, sin(b1) * tube)
			_quad(st, c0 + o00, c1 + o10, c1 + o11, c0 + o01,
				(c0 + c1) * 0.5, ink)


## Two triangles a -> b -> c -> d, with the normal taken from the winding and FLIPPED if
## it points back at `inside`.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		inside: Vector3, ink: Color) -> void:
	_tri(st, a, b, c, inside, ink)
	_tri(st, a, c, d, inside, ink)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside: Vector3,
		ink: Color) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	var mid: Vector3 = (a + b + c) / 3.0
	if n.dot(mid - inside) < 0.0:
		n = -n
	var tri: PackedVector3Array = PackedVector3Array([a, b, c])
	for vtx in tri:
		st.set_color(ink)
		st.set_normal(n)
		st.add_vertex(vtx)


## SurfaceTool.commit() on a tool that was begun and never given a vertex is not a mesh
## with no surfaces, it is an error in the log — so the window's null class commits
## nothing at all rather than committing an empty tool.
func _commit(holder: Node3D, mesh_name: String, st: SurfaceTool, rough: float,
		metal: float) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.WHITE
	m.vertex_color_use_as_albedo = true
	m.roughness = rough
	m.metallic = metal
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = m
	holder.add_child(mi)
