extends Node3D
class_name PhaseField

## phase_field — one surface, one standing point, and the derivative structure at that
## point built as real geometry. `phase` says WHERE YOU ARE STANDING; `reading` says HOW
## MUCH OF THE DERIVATIVE IS DRAWN. Nothing is printed and nothing moves.
##
## THE FAMILY, AND THE WORD THEY SHARE. Three artifacts in the `change` sequence carry an
## axis literally called `phase`, and all three begin it with the same word, `traverse`:
##
##   slope_tangent_demo         [traverse, crest, steepest, trough]
##   partial_derivative_terrain [traverse, agree, oppose, single]
##   velocity_arrow             [traverse, straight, bend, mirror]
##
## In all three, `traverse` is not a station at all — it is the SHIPPED SWEEP, the marker
## still running on _process, the value every placement carries. The other values stop it
## somewhere on purpose. So the shared word is the word for "no particular place", and the
## axis is a taxonomy of the places that are particular: `crest` and `trough` where the
## derivative vanishes, `steepest` where it is largest, `agree`/`oppose` for the sign
## pattern of the two partials, `bend`/`straight`/`mirror` for how a path is turning.
##
## THE THESIS, and it is disputable: those are all names for CRITICAL POINTS — the places
## where the derivative says something the function alone does not — and `traverse` is the
## null of the axis, the ordinary place, which is almost everywhere. The disagreement
## available: a physicist would say velocity_arrow's `bend` is not a critical point of
## anything, it is a maximum of CURVATURE, which is a fact about the second derivative; and
## partial_derivative_terrain's `agree` is not critical either, it is a sign pattern that
## holds on a whole open region. Both are true, and this bench answers them by building the
## first derivative and only the first derivative, so what the taxonomy costs is visible.
##
## THREE THINGS THE CODE CORRECTED IN THE BRIEF, all recorded in the registry `declines`:
##
##   1. slope_tangent_demo's `crest` and `trough` REALLY DO sit at a vanishing derivative.
##      PHASE_T = {crest: 0.75, steepest: 0.5, trough: 0.25}, x_curve = lerp(-PI, PI, t),
##      so crest is x = +PI/2 and trough is x = -PI/2, where cos(x) = 0 exactly. Checked,
##      not assumed.
##   2. partial_derivative_terrain's `crest`/`trough` DO NOT EXIST, and its own registry
##      says why: "every critical point of this f lies ON THE BOUNDARY of the drawn terrain
##      (at x=+-1 or y=+-1)". Measured on its f over its own [-1,1]^2: the smallest |grad|
##      anywhere is 0.0588, attained only on the edge. It could not borrow crest/trough, so
##      it named sign patterns instead. THIS SURFACE IS BUILT SO IT CAN: two maxima, two
##      minima and two saddles, all interior, all exact.
##   3. `traverse` cannot be inherited as a sweep. All three members' `traverse` depends on
##      how many _process frames the headless boot managed before the shutter — velocity_
##      arrow's registry says it outright: "two traverse frames are a clock, not a bite".
##      Here `traverse` is a FIXED ordinary point, chosen for having nothing to say.
##
## Deterministic: no randf, no noise, no _process, no Timer. Every vertex is arithmetic on
## six constants, so two builds of one value are the same mesh.


# ── the surface ────────────────────────────────────────────────────────────────────────
## f(x, z) = A sin(Wx) sin(Wz) + T x  over  x, z in [-R, R].
##
## The sin*sin term is a 2x2 checker of lobes — two hills and two hollows — and the T x
## term tilts the whole plate. THE TILT IS NOT DECORATION AND IT IS WHY THE SURFACE IS NOT
## SYMMETRIC: without it, sin*sin has the exact symmetry (x,z) -> (-x,-z), every hill has
## a matching hill and `mirror` would be a second photograph of `steepest`. With it, the
## two places that LOOK like the same piece of surface carry gradients of 1.075 and 0.645
## pointing opposite ways, which is velocity_arrow's `mirror` claim transposed onto a
## surface: two places which look symmetric are not behaving alike.
##
## T is exactly 0.25 * A * W, and that ratio is the whole shape. cos(Wx) = -T/(AW) = -0.25
## is what puts the crest and the trough at x = +-0.243781 rather than at +-R/2, and
## |grad| at the two ends of the flat centre line is AW +- T = 1.075 and 0.645, a ratio of
## 0.60 — the same 0.6 contrast velocity_arrow reports between its own straight (|v| 1.700)
## and mirror (|v| 1.100).
const R: float = 0.42
const W: float = 7.4799825085     ## PI / R, written out so no const expression is needed
const A: float = 0.115
const T: float = 0.2150494        ## 0.25 * A * W
## Height range over the patch: -0.163773 .. +0.163773, attained at the trough and crest.

## WHERE YOU ARE STANDING. Six values, every one of them a member's own word, and the
## (x, z) of each is DERIVED from the surface rather than chosen:
##
##   traverse  (+0.248000, -0.126000)  grad (+0.4102, +0.4853)  |grad| 0.6355
##             The shared default. Not a critical point of anything: it is the place picked
##             for having NOTHING to say, and it was found by asking for the point whose
##             |grad| is closest to the patch mean (0.607) while staying furthest from
##             every one of the eleven special points. Its two partials happen to agree in
##             sign — that is not a station, it is what an arbitrary point looks like.
##   crest     (+0.243781, +0.210000)  grad (0, 0)              slope_tangent_demo's word
##             A true interior local maximum. AW cos(Wx) sin(Wz) + T = 0 with sin(Wz) = 1,
##             so cos(Wx) = -0.25; the Hessian there is -Aww * I, negative definite.
##   trough    (-0.243781, +0.210000)  grad (0, 0)              slope_tangent_demo's word
##             The matching interior local minimum, same z, mirrored x, Hessian positive
##             definite. crest and trough differ in height by 0.327546 m.
##   steepest  ( 0.000000, +0.210000)  grad (+1.0752, 0)        slope_tangent_demo's word
##             The unique INTERIOR maximum of |grad| over the patch. |grad| ties this value
##             at the corner (-R, -R/2), which is excluded on partial_derivative_terrain's
##             own grounds: a station on the boundary pins the furniture off the edge of
##             the mesh it measures.
##   oppose    (-0.122000, +0.088000)  grad (+0.5369, -0.5383)  partial_derivative_terrain's
##             The two partials in opposite sign and near-equal size — "the 2D-only case",
##             the thing a 1D demo cannot have at all. It is that member's own fixture.
##   mirror    ( 0.000000, -0.210000)  grad (-0.6451, 0)        velocity_arrow's word
##             The point diametrically opposite `steepest` through the patch centre: the
##             image of it under the untilted field's own symmetry, so the same lobe, the
##             same shape, the same flat centre line — and a gradient of 0.645 pointing
##             the other way instead of 1.075 pointing this way.
##
## THE THREE STATIONS slope_tangent_demo NAMES ARE COLLINEAR HERE, and that is not a
## coincidence: dF/dz vanishes identically along z = +0.21, so that line is a 1-D curve
## carrying its own ordinary derivative — trough at a quarter of the way across, steepest
## dead centre, crest at three quarters, in exactly the order its PHASE_T puts them.
## slope_tangent_demo's whole artifact is a slice of this one.
@export_enum("traverse", "crest", "trough", "steepest", "oppose", "mirror") var phase: String = "traverse":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not PHASES.has(picked):
			return                      ## an unreachable value keeps the current figure
		phase = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## HOW MUCH OF THE DERIVATIVE STANDS AT THAT POINT. Three values, and they are this
## synthesis's own words, not a member's — recorded as such in the registry note.
##
##   point     the surface, and the standing point marked: a white ring lying ON the
##             surface at (x, z) and a bead on a stem above it. No derivative at all.
##   tangent   adds the TANGENT PLANE, as a real 0.26 m plate lying in it, and the GRADIENT
##             as a rod whose LENGTH IS THE MAGNITUDE — 0.2688 m at steepest, 0.1613 at
##             mirror, and NOTHING AT ALL at crest and trough, where the gradient is zero.
##             A rod that is not there is the reading.
##   partials  drops the plate and the gradient and draws the two partial derivatives
##             separately: a red rod along x of length |dF/dx| * K and a green rod along z
##             of length |dF/dz| * K, each lying along its own slice's tangent and each
##             placed on THE SIDE ITS SIGN POINTS TO. That is partial_derivative_terrain's
##             own subject and its own 2026-08-05 repair — it had always drawn abs(dx) on
##             the +x side, so a negative partial had never been distinguishable.
##
## THE NULL THIS BUILDS, and it is the thesis in its sharpest form: at crest and at trough
## BOTH partials are exactly zero, so `partials` draws no rod, and the tile is the `point`
## tile TO THE BYTE. The reading that shows only the partial derivatives shows exactly what
## the reading that shows no derivative shows. `tangent` at those two stations still says
## something — the plate is horizontal — which is the honest asymmetry between the two.
@export_enum("point", "tangent", "partials") var reading: String = "tangent":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not READINGS.has(picked):
			return
		reading = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One station, or all six in a row. NOT PART OF EITHER AXIS. capture_config_sweep unions
## the AABB across a spec's variants, so an all-stations value declared inside `phase`
## would frame every single against five and a quarter metres and photograph the bead as a
## speck — wave 13's lesson. The registry fixture pins `single`; the frame does the rest.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const PHASES: PackedStringArray = [
	"traverse", "crest", "trough", "steepest", "oppose", "mirror"]
const READINGS: PackedStringArray = ["point", "tangent", "partials"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

## The stations, in the field's own coordinates. Vector2(x, z).
const STATIONS: Dictionary = {
	"traverse": Vector2(0.248000, -0.126000),
	"crest": Vector2(0.243781, 0.210000),
	"trough": Vector2(-0.243781, 0.210000),
	"steepest": Vector2(0.000000, 0.210000),
	"oppose": Vector2(-0.122000, 0.088000),
	"mirror": Vector2(0.000000, -0.210000),
}

# ── the frame, and it is the whole answer to the extent trap ───────────────────────────
## The terrain block is the same 0.84 x 0.84 slab in all eighteen variants, but the
## FURNITURE is not: the bead stands at y = +0.269 on the crest and at y = -0.059 in the
## trough, and the gradient rod reaches y = +0.302 at steepest and does not exist at all at
## crest. An AABB fitted to what is drawn would move by a third of a metre across the sheet
## and the camera would refit between tiles. The base plate, the four posts and the four
## top rails are drawn IDENTICALLY in all eighteen and enclose everything, so the union
## AABB is 0.90 x 0.56 x 0.90 in every cell BY CONSTRUCTION and the camera never moves.
const FLOOR_Y: float = -0.20          ## the underside of the terrain slab
const BASE_T: float = 0.02
const BASE_HALF: float = 0.45
const POST: float = 0.020
const POST_TOP: float = 0.34
const GRID: int = 44                  ## quads per side of the terrain patch

# ── the mark, and the derivative furniture ─────────────────────────────────────────────
## The ring lies on the surface and is the PLACE. The bead is the same place raised, and
## everything about the derivative is drawn AT THE BEAD rather than on the surface.
##
## THAT LIFT IS NOT COSMETIC, it is forced, and finding out cost a whole measurement pass:
## a tangent plane drawn ON a surface is BURIED BY THAT SURFACE wherever the surface is
## convex, because the tangent is below the curve there by definition. Drawn flush, the
## `trough` tile measured 0.00% against `point` in all three readings — a perfect INERT
## verdict about geometry that had been built correctly and was simply underground.
## partial_derivative_terrain already knew: `var lift := Vector3(0, 0.05, 0)` in
## _update_arrows, and lift = 0.014 on its slice ribbons.
const MARK_R_OUT: float = 0.100
const MARK_R_IN: float = 0.062
const MARK_LIFT: float = 0.006
const BEAD_R: float = 0.050
const BEAD_LIFT: float = 0.105        ## the standing point, raised so it can be seen
const STEM_R: float = 0.013
const PLATE_HALF: float = 0.13        ## the tangent plate is 0.26 m square
const PLATE_T: float = 0.016
## Metres of rod per unit of slope. THE ROD IS THE MAGNITUDE, so the sheet reads
## 0.2688 (steepest) / 0.1901 (oppose) / 0.1613 (mirror) / 0.1589 (traverse) / 0 / 0, and
## the two ends of that list are the argument.
const K_ROD: float = 0.25
const ROD_R: float = 0.034
const HEAD_R: float = 0.066
const HEAD_L: float = 0.090
const MIN_ROD: float = 0.004          ## below this the derivative is drawn as nothing
const LADDER_PITCH: float = 1.05

# ── colour, and every one of them is a member's ────────────────────────────────────────
## Not a palette. Six of the seven colours here are taken character for character from the
## three sources, so a room holding this bench beside them is reading one vocabulary.
const C_TERRAIN: Color = Color(0.30, 0.50, 0.40)   ## partial_derivative_terrain.terrain_color
const C_FRAME: Color = Color(0.30, 0.35, 0.45)     ## velocity_arrow.track_color
const C_MARK: Color = Color(1.00, 1.00, 1.00)      ## slope_tangent_demo.marker_color
const C_PLATE: Color = Color(1.00, 0.55, 0.25)     ## slope_tangent_demo.tangent_color
const C_GRAD: Color = Color(1.00, 0.92, 0.45)      ## partial_derivative_terrain's gradient arrow
const C_DX: Color = Color(1.00, 0.40, 0.45)        ## partial_derivative_terrain.dx_arrow_color
const C_DZ: Color = Color(0.50, 1.00, 0.55)        ## partial_derivative_terrain.dy_arrow_color
const E_MARK: Color = Color(0.42, 0.42, 0.40)
const E_PLATE: Color = Color(0.46, 0.24, 0.10)
const E_GRAD: Color = Color(0.48, 0.44, 0.18)
const E_DX: Color = Color(0.48, 0.16, 0.18)
const E_DZ: Color = Color(0.18, 0.48, 0.20)

const SIDES: int = 10                 ## faces on a rod or an arrow head
## Iterated rather than written as a literal array, so no loop variable is untyped.
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
	if config_data.has("phase"):
		phase = str(config_data["phase"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
	_bulk = false
	_rebuild()


# ── the field ──────────────────────────────────────────────────────────────────────────

func _height(x: float, z: float) -> float:
	return A * sin(W * x) * sin(W * z) + T * x


## dF/dx, analytically. Not a finite difference: the artifact's subject is the exact local
## derivative, and a difference quotient would put a step size into the picture that no
## still could report.
func _dfdx(x: float, z: float) -> float:
	return A * W * cos(W * x) * sin(W * z) + T


## dF/dz, analytically.
func _dfdz(x: float, z: float) -> float:
	return A * W * sin(W * x) * cos(W * z)


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
		names = PHASES.duplicate()
	else:
		names.append(_pick(phase, PHASES, "traverse"))
	var which: String = _pick(reading, READINGS, "tangent")
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Phase_" + names[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_frame(holder)
		_build_figure(holder, names[i], which)


# ── the frame ──────────────────────────────────────────────────────────────────────────

func _build_frame(holder: Node3D) -> void:
	var land := SurfaceTool.new()
	land.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step: float = 2.0 * R / float(GRID)
	for i in range(GRID):
		var x0: float = -R + float(i) * step
		var x1: float = x0 + step
		for j in range(GRID):
			var z0: float = -R + float(j) * step
			var z1: float = z0 + step
			_quad(land,
				Vector3(x0, _height(x0, z0), z0),
				Vector3(x1, _height(x1, z0), z0),
				Vector3(x1, _height(x1, z1), z1),
				Vector3(x0, _height(x0, z1), z1))
	# The skirt. The rim of the patch is the plane y = T x exactly, because sin(Wx) or
	# sin(Wz) is zero on every edge, so the four walls are four straight-edged trapezoids
	# and the block reads as a cut slab rather than a floating sheet.
	for i in range(GRID):
		var sx0: float = -R + float(i) * step
		var sx1: float = sx0 + step
		_quad(land,
			Vector3(sx0, _height(sx0, R), R), Vector3(sx1, _height(sx1, R), R),
			Vector3(sx1, FLOOR_Y, R), Vector3(sx0, FLOOR_Y, R))
		_quad(land,
			Vector3(sx1, _height(sx1, -R), -R), Vector3(sx0, _height(sx0, -R), -R),
			Vector3(sx0, FLOOR_Y, -R), Vector3(sx1, FLOOR_Y, -R))
		var sz0: float = -R + float(i) * step
		var sz1: float = sz0 + step
		_quad(land,
			Vector3(R, _height(R, sz1), sz1), Vector3(R, _height(R, sz0), sz0),
			Vector3(R, FLOOR_Y, sz0), Vector3(R, FLOOR_Y, sz1))
		_quad(land,
			Vector3(-R, _height(-R, sz0), sz0), Vector3(-R, _height(-R, sz1), sz1),
			Vector3(-R, FLOOR_Y, sz1), Vector3(-R, FLOOR_Y, sz0))
	_commit(holder, "Land", land, C_TERRAIN, Color.BLACK)

	var cage := SurfaceTool.new()
	cage.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(cage, Vector3(0.0, FLOOR_Y - BASE_T * 0.5, 0.0),
		Vector3(BASE_HALF * 2.0, BASE_T, BASE_HALF * 2.0))
	var off: float = BASE_HALF - POST * 0.5
	var span: float = BASE_HALF * 2.0 - POST * 2.0
	for sx in SIGNS:
		for sz in SIGNS:
			_add_box(cage, Vector3(sx * off, (FLOOR_Y + POST_TOP) * 0.5, sz * off),
				Vector3(POST, POST_TOP - FLOOR_Y, POST))
	for sz2 in SIGNS:
		_add_box(cage, Vector3(0.0, POST_TOP - POST * 0.5, sz2 * off),
			Vector3(span, POST, POST))
	for sx2 in SIGNS:
		_add_box(cage, Vector3(sx2 * off, POST_TOP - POST * 0.5, 0.0),
			Vector3(POST, POST, span))
	_commit(holder, "Frame", cage, C_FRAME, Color.BLACK)


# ── the figure ─────────────────────────────────────────────────────────────────────────

func _build_figure(holder: Node3D, which_phase: String, which_reading: String) -> void:
	var station: Vector2 = STATIONS[which_phase]
	var x0: float = station.x
	var z0: float = station.y
	var y0: float = _height(x0, z0)
	var gx: float = _dfdx(x0, z0)
	var gz: float = _dfdz(x0, z0)
	var base: Vector3 = Vector3(x0, y0 + BEAD_LIFT, z0)

	var mark := SurfaceTool.new()
	mark.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_ring(mark, x0, z0)
	_add_rod(mark, Vector3(x0, y0 + MARK_LIFT, z0), Vector3(0.0, 1.0, 0.0),
		BEAD_LIFT, STEM_R)
	_add_sphere(mark, base, BEAD_R, 10, 14)
	_commit(holder, "Mark", mark, C_MARK, E_MARK)

	if which_reading == "tangent":
		var plate := SurfaceTool.new()
		plate.begin(Mesh.PRIMITIVE_TRIANGLES)
		_add_plate(plate, base, gx, gz)
		_commit(holder, "TangentPlane", plate, C_PLATE, E_PLATE)
		var mag: float = sqrt(gx * gx + gz * gz)
		if mag * K_ROD >= MIN_ROD:
			# The steepest-ascent direction: horizontal part is grad / |grad|, and it rises
			# with slope |grad|, so the rod lies IN the tangent plane and points uphill.
			var dir: Vector3 = Vector3(gx / mag, mag, gz / mag).normalized()
			var arrow := SurfaceTool.new()
			arrow.begin(Mesh.PRIMITIVE_TRIANGLES)
			_add_arrow(arrow, base, dir, mag * K_ROD)
			_commit(holder, "Gradient", arrow, C_GRAD, E_GRAD)
		# When mag is zero NOTHING IS COMMITTED, and that is the reading, not an omission.
		# SurfaceTool.commit() on a tool that was begun and never given a vertex is an
		# error in the log rather than an empty mesh, so the tool is never begun at all.
		return

	if which_reading == "partials":
		if absf(gx) * K_ROD >= MIN_ROD:
			var sx: float = -1.0 if gx < 0.0 else 1.0
			var dx_dir: Vector3 = Vector3(sx, gx * sx, 0.0).normalized()
			var bar_x := SurfaceTool.new()
			bar_x.begin(Mesh.PRIMITIVE_TRIANGLES)
			_add_arrow(bar_x, base, dx_dir, absf(gx) * K_ROD)
			_commit(holder, "PartialX", bar_x, C_DX, E_DX)
		if absf(gz) * K_ROD >= MIN_ROD:
			var sz: float = -1.0 if gz < 0.0 else 1.0
			var dz_dir: Vector3 = Vector3(0.0, gz * sz, sz).normalized()
			var bar_z := SurfaceTool.new()
			bar_z.begin(Mesh.PRIMITIVE_TRIANGLES)
			_add_arrow(bar_z, base, dz_dir, absf(gz) * K_ROD)
			_commit(holder, "PartialZ", bar_z, C_DZ, E_DZ)


# ── mesh primitives ────────────────────────────────────────────────────────────────────

## The place, drawn on the ground it is a place ON: an annulus of the surface itself,
## lifted 6 mm. An annulus rather than a disc because the bead stands directly in front of
## its own mark at this camera and a filled disc is invisible behind it.
func _add_ring(st: SurfaceTool, x0: float, z0: float) -> void:
	var rings: int = 2
	var segs: int = 24
	for i in range(rings):
		var r0: float = MARK_R_IN + (MARK_R_OUT - MARK_R_IN) * float(i) / float(rings)
		var r1: float = MARK_R_IN + (MARK_R_OUT - MARK_R_IN) * float(i + 1) / float(rings)
		for j in range(segs):
			var t0: float = TAU * float(j) / float(segs)
			var t1: float = TAU * float(j + 1) / float(segs)
			_quad(st, _on_surface(x0, z0, r0, t0), _on_surface(x0, z0, r0, t1),
				_on_surface(x0, z0, r1, t1), _on_surface(x0, z0, r1, t0))


func _on_surface(x0: float, z0: float, rr: float, tt: float) -> Vector3:
	var xx: float = x0 + rr * cos(tt)
	var zz: float = z0 + rr * sin(tt)
	return Vector3(xx, _height(xx, zz) + MARK_LIFT, zz)


## The tangent plane, as a plate. Its two edge directions are the tangent vectors of the
## two slices — (1, dF/dx, 0) and (0, dF/dz, 1) — which is the same statement as the
## `partials` reading made in one object instead of two. At a critical point both are
## horizontal and the plate is flat, which is what "critical point" means.
func _add_plate(st: SurfaceTool, centre: Vector3, gx: float, gz: float) -> void:
	var n: Vector3 = Vector3(-gx, 1.0, -gz).normalized()
	var ex: Vector3 = Vector3(1.0, gx, 0.0).normalized()
	var ez: Vector3 = Vector3(0.0, gz, 1.0).normalized()
	var c0: Vector3 = centre - ex * PLATE_HALF - ez * PLATE_HALF
	var c1: Vector3 = centre + ex * PLATE_HALF - ez * PLATE_HALF
	var c2: Vector3 = centre + ex * PLATE_HALF + ez * PLATE_HALF
	var c3: Vector3 = centre - ex * PLATE_HALF + ez * PLATE_HALF
	var lift: Vector3 = n * (PLATE_T * 0.5)
	_quad(st, c0 + lift, c1 + lift, c2 + lift, c3 + lift)
	_quad(st, c3 - lift, c2 - lift, c1 - lift, c0 - lift)
	_quad(st, c0 - lift, c1 - lift, c1 + lift, c0 + lift)
	_quad(st, c1 - lift, c2 - lift, c2 + lift, c1 + lift)
	_quad(st, c2 - lift, c3 - lift, c3 + lift, c2 + lift)
	_quad(st, c3 - lift, c0 - lift, c0 + lift, c3 + lift)


## A rod plus a head, whose TOTAL length is the number being reported. The head is a
## fraction of that length rather than a fixed size, so a short derivative is a short arrow
## and not a stub with a disproportionate point on it.
func _add_arrow(st: SurfaceTool, from_pt: Vector3, dir: Vector3, length: float) -> void:
	if length < MIN_ROD:
		return
	var head_l: float = minf(HEAD_L, length * 0.42)
	var head_r: float = minf(HEAD_R, maxf(ROD_R * 1.5, length * 0.30))
	var shaft: float = length - head_l
	if shaft > 0.001:
		_add_rod(st, from_pt, dir, shaft, ROD_R)
	_add_cone(st, from_pt + dir * shaft, dir, head_l, head_r)


func _basis_for(dir: Vector3) -> Array:
	var d: Vector3 = dir.normalized()
	var up := Vector3(0.0, 1.0, 0.0)
	if absf(d.dot(up)) > 0.9:
		up = Vector3(1.0, 0.0, 0.0)
	var right: Vector3 = d.cross(up).normalized()
	var fwd: Vector3 = right.cross(d).normalized()
	return [right, fwd]


func _add_rod(st: SurfaceTool, from_pt: Vector3, dir: Vector3, length: float,
		radius: float) -> void:
	if length < 0.0005:
		return
	var d: Vector3 = dir.normalized()
	var fr: Array = _basis_for(d)
	var right: Vector3 = fr[0]
	var fwd: Vector3 = fr[1]
	var to_pt: Vector3 = from_pt + d * length
	for s in range(SIDES):
		var a0: float = TAU * float(s) / float(SIDES)
		var a1: float = TAU * float(s + 1) / float(SIDES)
		var o0: Vector3 = (right * cos(a0) + fwd * sin(a0)) * radius
		var o1: Vector3 = (right * cos(a1) + fwd * sin(a1)) * radius
		_quad(st, from_pt + o0, to_pt + o0, to_pt + o1, from_pt + o1)
		# The end cap, so a rod seen down its own axis is not a hole.
		_tri(st, from_pt, from_pt + o1, from_pt + o0)


func _add_cone(st: SurfaceTool, base_pt: Vector3, dir: Vector3, length: float,
		radius: float) -> void:
	var d: Vector3 = dir.normalized()
	var fr: Array = _basis_for(d)
	var right: Vector3 = fr[0]
	var fwd: Vector3 = fr[1]
	var apex: Vector3 = base_pt + d * length
	for s in range(SIDES):
		var a0: float = TAU * float(s) / float(SIDES)
		var a1: float = TAU * float(s + 1) / float(SIDES)
		var o0: Vector3 = (right * cos(a0) + fwd * sin(a0)) * radius
		var o1: Vector3 = (right * cos(a1) + fwd * sin(a1)) * radius
		_tri(st, base_pt + o0, apex, base_pt + o1)
		_tri(st, base_pt, base_pt + o1, base_pt + o0)


func _add_sphere(st: SurfaceTool, centre: Vector3, r: float, rings: int,
		segs: int) -> void:
	var pts: Array = []
	for i in range(rings + 1):
		var th: float = PI * float(i) / float(rings)
		var ring: PackedVector3Array = PackedVector3Array()
		for j in range(segs):
			var ph: float = TAU * float(j) / float(segs)
			ring.append(centre + Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph)) * r)
		pts.append(ring)
	for i in range(rings):
		var r0: PackedVector3Array = pts[i]
		var r1: PackedVector3Array = pts[i + 1]
		for j in range(segs):
			var k: int = (j + 1) % segs
			_quad(st, r0[j], r1[j], r1[k], r0[k])


## An axis-aligned box, twelve triangles, wound outward with explicit per-face normals.
func _add_box(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var p: PackedVector3Array = PackedVector3Array([
		at + Vector3(-h.x, -h.y, h.z), at + Vector3(h.x, -h.y, h.z),
		at + Vector3(h.x, h.y, h.z), at + Vector3(-h.x, h.y, h.z),
		at + Vector3(-h.x, -h.y, -h.z), at + Vector3(h.x, -h.y, -h.z),
		at + Vector3(h.x, h.y, -h.z), at + Vector3(-h.x, h.y, -h.z)])
	_quad(st, p[0], p[1], p[2], p[3])
	_quad(st, p[5], p[4], p[7], p[6])
	_quad(st, p[3], p[2], p[6], p[7])
	_quad(st, p[4], p[5], p[1], p[0])
	_quad(st, p[1], p[5], p[6], p[2])
	_quad(st, p[4], p[0], p[3], p[7])


## Two triangles wound a -> b -> c -> d with the normal taken from the winding, and every
## material is CULL_DISABLED besides. A height field is the case that makes that mandatory:
## seen from below, a one-sided sheet is indistinguishable from a sheet that was never
## built, and the trough of this surface is exactly where a low camera looks up at it.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, b, c)
	_tri(st, a, c, d)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	var tri: PackedVector3Array = PackedVector3Array([a, b, c])
	for v in tri:
		st.set_normal(n)
		st.add_vertex(v)


func _commit(holder: Node3D, mesh_name: String, st: SurfaceTool, c: Color,
		emission: Color) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = _mat(c, emission)
	holder.add_child(mi)


func _mat(c: Color, emission: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.05
	m.roughness = 0.62
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 0.55
	return m
