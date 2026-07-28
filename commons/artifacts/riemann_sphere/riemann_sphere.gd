# riemann_sphere.gd
# The Riemann sphere - compactified complex plane

extends Node3D

class_name RiemannSphere

# @identity
# essence: C ∪ {∞} — the complex plane plus a point at infinity, wrapped onto a sphere via stereographic projection
# desire: see the infinite complex plane folded onto a finite sphere — the north pole IS infinity
# critical_parameter: radius — the sphere that contains the entire complex plane plus its boundary
# triggers: static display; the glowing north pole and equator teach by geometry alone
# emerges: the intuition that infinity is not "far away" — it is a point you can see and almost touch
# needs: VR controls [missing] — could add interactive stereographic projection
# relationships: contrasts poincare_disk (compactification of hyperbolic vs complex plane); paired with elliptic_surface (both positive curvature)
# truth: infinity is not the absence of a boundary — it is a boundary that has been folded back into the space it bounds

@export var radius: float = 0.3

## Was declared and never read — the "projection lines" this artifact's stated desire
## depends on had no builder behind them. It now gates the `infinity:rays` correspondence
## rods, and nothing else. Default true, so the shipped look is untouched and a sweep
## that never sets it still gets the rays.
@export var show_projection_lines: bool = true

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA AXES
# ═══════════════════════════════════════════════════════════════════

## What the surface is made to SHOW about the fifth postulate. Not a style knob — the
## sphere IS a model of elliptic geometry, and this axis decides whether it says so.
##
##   bare       the shipped object: sphere, equator, pole, plate. No argument drawn.
##   parallels  two meridians 0.10 m apart at the equator that meet at both poles,
##              with their images on the plate — the "no parallels" demonstration
##   triangle   one octant outlined, three square corners, angle sum 270°
##   net        8 meridians x 8 parallels on the sphere AND their stereographic image
##              on the plate — the sphere's net and the plane's grid as one object
##   euclid     the flat control case: no sphere at all, a 1.80 m plane carrying two
##              rods that stay 0.10 m apart forever and a triangle summing to 180°
##
## `euclid` DOES NOT BUILD THE SPHERE, so all four `infinity` values render identically
## under it. Declared here rather than left for a sweep to discover as four blank tiles.
@export_enum("bare", "parallels", "triangle", "net", "euclid") var postulate: String = "bare"

## How the point at infinity is presented — the compactification's own question,
## separate from the postulate the surface models.
##
##   pole   the shipped treatment: red marker at the north pole plus an ∞ glyph
##   rays   pole marker plus 12 drawn stereographic correspondence rods running from
##          the pole through the sphere down to their landings on the plane
##   open   the sphere's top two rings of triangles are omitted — a 0.115 m puncture
##          where the pole was, glyph floating over the hole. Infinity as the MISSING
##          point, the hole the compactification exists to fill.
##   none   no marker, no glyph, no rods. A closed shell with no account of its
##          extra point.
@export_enum("pole", "rays", "open", "none") var infinity: String = "pole"

const POSTULATES: PackedStringArray = ["bare", "parallels", "triangle", "net", "euclid"]
const INFINITIES: PackedStringArray = ["pole", "rays", "open", "none"]

# ── sphere tessellation (shared by SphereMesh and the punctured build) ─────────
const SPHERE_SEGS: int = 32
const SPHERE_RINGS: int = 16
## `open` omits this many latitude bands from the north pole. 2 of 16 puts the rim at
## polar angle 22.5°, i.e. a hole of radius radius*sin(22.5°) = 0.115 m at radius 0.30.
const OPEN_RINGS_OMITTED: int = 2

# ── line weights, in metres ───────────────────────────────────────────────────
const MERIDIAN_TUBE: float = 0.012   # parallels / triangle: the argued lines
const NET_TUBE: float = 0.008        # net: the whole grid, thinner so it stays a net
const PLATE_ROD: float = 0.008       # anything drawn on the plane
const RAY_TUBE: float = 0.004        # correspondence rods — hairlines, not structure
const RAY_DOT: float = 0.012
const SURF_LIFT: float = 0.006       # keeps a tube ON the sphere rather than half in it
const TUBE_SIDES: int = 6

# ── the parallels demonstration ───────────────────────────────────────────────
const PARALLEL_GAP: float = 0.10     # arc length between the two meridians at the equator
## Azimuth spread of the plate image at the south pole. The TRUE stereographic image of
## two meridians is two straight rays that meet only at the origin and at infinity; a
## 0.90 m plate cannot draw infinity, so the pole's image is put at the plate rim and
## both rays are closed onto it. The bow IS the finite plate telling the truth about
## where the two rays are heading.
const PARALLEL_SPREAD_DEG: float = 26.0

# ── the octant triangle ───────────────────────────────────────────────────────
const FILLET_ARC: float = 0.04       # geodesic leg of each right-angle marker

# ── the net ───────────────────────────────────────────────────────────────────
const NET_LINES: int = 8
## Latitudes of the 8 parallels, as fractions of radius. Through _proj_radius these
## come out at plate radii 0.060, 0.121, 0.178, 0.234, 0.289, 0.343, 0.396, 0.449 m.
const NET_Y_LOW: float = -0.775
const NET_Y_HIGH: float = 0.995

# ── the correspondence rays ───────────────────────────────────────────────────
const RAY_COUNT: int = 12
const RAY_R_MIN: float = 0.12
const RAY_R_MAX: float = 0.85

# ── the euclidean control case ────────────────────────────────────────────────
const EUCLID_PLANE: float = 1.80
const EUCLID_ROD_LEN: float = 1.60
const EUCLID_ROD_GAP: float = 0.10

## Radial compression of the projection. True stereographic sends the north pole to
## infinity, which no finite plate can carry, so the RADIUS is compressed monotonically
## while the azimuth is left alone: angular order and the sense of crowding survive, the
## metric does not. Calibrated so the 8 net parallels land on 0.06 .. 0.45 m.
const PROJ_GAMMA: float = 0.92

var _sphere: MeshInstance3D
var _north_pole: MeshInstance3D
var _projection_plane: MeshInstance3D
var _label: Label3D

## Only nodes THIS script created. Freeing get_children() would take the grid's own
## label plates, packaging and tag markers with it.
var _spawned: Array[Node] = []
var _built: bool = false


func _ready() -> void:
	_build_all()
	_built = true


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

## Child order matches the shipped script exactly (sphere, equator, pole, glyph, plane,
## label) so transparency sorting of the default look is unchanged.
func _build_all() -> void:
	_build_surface()
	_build_infinity_marks()
	_build_projection_plane()
	_build_postulate_figure()
	_build_label()


func _build_surface() -> void:
	if postulate == "euclid":
		return  # the flat control case has no sphere to build

	_sphere = MeshInstance3D.new()
	if infinity == "open":
		_sphere.mesh = _punctured_sphere_mesh()
	else:
		var mesh: SphereMesh = SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		mesh.radial_segments = SPHERE_SEGS
		mesh.rings = SPHERE_RINGS
		_sphere.mesh = mesh

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.6, 0.9, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.3
	mat.roughness = 0.4
	if infinity == "open":
		# a puncture has to show its own inside, or the hole reads as a highlight
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_sphere.material_override = mat
	_track(_sphere)

	var equator: MeshInstance3D = _create_circle(radius, Color(1, 1, 0, 0.8))
	equator.rotation_degrees.x = 90
	_track(equator)


## A UV sphere with the top OPEN_RINGS_OMITTED latitude bands left out. Normals are set
## from the position rather than generated, so winding cannot flip the shading.
func _punctured_sphere_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(OPEN_RINGS_OMITTED, SPHERE_RINGS):
		var th0: float = float(i) / float(SPHERE_RINGS) * PI
		var th1: float = float(i + 1) / float(SPHERE_RINGS) * PI
		for j in range(SPHERE_SEGS):
			var p0: float = TAU * float(j) / float(SPHERE_SEGS)
			var p1: float = TAU * float(j + 1) / float(SPHERE_SEGS)
			var a: Vector3 = _sph(th0, p0)
			var b: Vector3 = _sph(th1, p0)
			var c: Vector3 = _sph(th1, p1)
			var d: Vector3 = _sph(th0, p1)
			_push_vert(st, a)
			_push_vert(st, c)
			_push_vert(st, b)
			_push_vert(st, a)
			_push_vert(st, d)
			_push_vert(st, c)
	return st.commit()


func _push_vert(st: SurfaceTool, p: Vector3) -> void:
	st.set_normal(p.normalized())
	st.add_vertex(p)


func _build_infinity_marks() -> void:
	if postulate == "euclid":
		# DECLARED INTERACTION: no sphere exists, so there is nothing to say about the
		# point at infinity. All four `infinity` values render identically under euclid.
		return

	match infinity:
		"pole":
			_build_pole_marker()
			_build_glyph()
		"rays":
			_build_pole_marker()
			_build_glyph()
			if show_projection_lines:
				_build_correspondence_rays()
		"open":
			# no marker: the pole is the point that is MISSING. The glyph stays, hanging
			# over the hole, naming an absence instead of labelling a dot.
			_build_glyph()
		"none":
			pass


func _build_pole_marker() -> void:
	_north_pole = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	_north_pole.mesh = sphere
	_north_pole.position.y = radius

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.3, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.2, 0.2)
	mat.emission_energy_multiplier = 0.5
	_north_pole.material_override = mat
	_track(_north_pole)


func _build_glyph() -> void:
	var pole_label: Label3D = Label3D.new()
	pole_label.text = "∞"
	pole_label.pixel_size = 0.002
	pole_label.font_size = 24
	pole_label.position = Vector3(0, radius + 0.05, 0)
	_track(pole_label)


## The stereographic correspondence, drawn. Each rod runs from the north pole to a
## landing on the plane; by construction it crosses the sphere at exactly the point that
## landing corresponds to, so the fold from plane to sphere becomes traceable by finger.
## Landings spiral outward from 0.12 m to 0.85 m — the outer ones fall well beyond the
## drawn 0.90 m plate, which is the point: the plane does not stop where we stopped
## drawing it.
func _build_correspondence_rays() -> void:
	var north: Vector3 = Vector3(0.0, radius, 0.0)
	var plate_y: float = -radius + 0.010
	var col: Color = Color(0.85, 0.92, 1.0)
	for k in range(RAY_COUNT):
		var frac: float = float(k) / float(RAY_COUNT - 1)
		var r: float = lerp(RAY_R_MIN, RAY_R_MAX, frac)
		var az: float = TAU * float(k) / float(RAY_COUNT)
		var landing: Vector3 = Vector3(cos(az) * r, plate_y, sin(az) * r)
		_track(_tube(PackedVector3Array([north, landing]), RAY_TUBE, col, true))

		var dot: MeshInstance3D = MeshInstance3D.new()
		var dm: SphereMesh = SphereMesh.new()
		dm.radius = RAY_DOT
		dm.height = RAY_DOT * 2.0
		dm.radial_segments = 12
		dm.rings = 6
		dot.mesh = dm
		dot.position = landing
		dot.material_override = _line_mat(col, true)
		_track(dot)


func _build_projection_plane() -> void:
	_projection_plane = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	if postulate == "euclid":
		plane.size = Vector2(EUCLID_PLANE, EUCLID_PLANE)
	else:
		plane.size = Vector2(radius * 3, radius * 3)
	_projection_plane.mesh = plane
	if postulate == "euclid":
		_projection_plane.position.y = 0.0
	else:
		_projection_plane.position.y = -radius
	_projection_plane.rotation_degrees.x = 0

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.3, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_projection_plane.material_override = mat
	_track(_projection_plane)


func _build_postulate_figure() -> void:
	match postulate:
		"parallels":
			_build_parallels()
		"triangle":
			_build_octant_triangle()
		"net":
			_build_net()
		"euclid":
			_build_euclid()
		_:
			pass  # bare — the shipped object argues nothing


## Two meridian great circles 0.10 m apart at the equator, meeting at both poles, plus
## their images on the plate. Two lines, everywhere locally "parallel", that cross twice.
func _build_parallels() -> void:
	var col: Color = Color(0.35, 1.0, 0.6)
	var half_sep: float = (PARALLEL_GAP / radius) * 0.5  # radians of longitude

	for si in range(2):
		var s: float = -1.0 if si == 0 else 1.0
		var pts: PackedVector3Array = PackedVector3Array()
		for i in range(49):
			var theta: float = float(i) / 48.0 * PI
			pts.append(_sph_lift(theta, half_sep * s, SURF_LIFT))
		_track(_tube(pts, MERIDIAN_TUBE, col, true))

	# The images on the plate: both rods leave the plate centre (the south pole's image),
	# bow apart to ~0.107 m, and close again on the rim (the north pole's image).
	var spread: float = deg_to_rad(PARALLEL_SPREAD_DEG)
	var plate_y: float = -radius + 0.012
	for si in range(2):
		var s: float = -1.0 if si == 0 else 1.0
		var pts: PackedVector3Array = PackedVector3Array()
		for i in range(41):
			var u: float = float(i) / 40.0
			var y: float = -radius + u * 2.0 * radius
			var rr: float = _proj_radius(y)
			var az: float = s * spread * (1.0 - u)
			pts.append(Vector3(cos(az) * rr, plate_y, sin(az) * rr))
		_track(_tube(pts, PLATE_ROD, col, true))

	_track(_plate("NO PARALLELS", 0.20, 0.06, Vector3(0.0, -radius + 0.05, 0.50), col))


## One octant: three quarter-great-circles meeting at three right angles. 90 + 90 + 90.
func _build_octant_triangle() -> void:
	var col: Color = Color(1.0, 0.55, 0.25)
	var vx: Vector3 = Vector3(1, 0, 0)
	var vz: Vector3 = Vector3(0, 0, 1)
	var vy: Vector3 = Vector3(0, 1, 0)

	var arcs: Array = [[vx, vz], [vz, vy], [vy, vx]]
	for arc in arcs:
		var p0: Vector3 = arc[0]
		var p1: Vector3 = arc[1]
		var pts: PackedVector3Array = PackedVector3Array()
		for i in range(25):
			var t: float = float(i) / 24.0 * PI * 0.5
			var d: Vector3 = (p0 * cos(t) + p1 * sin(t)).normalized()
			pts.append(d * (radius + SURF_LIFT))
		_track(_tube(pts, MERIDIAN_TUBE, col, true))

	# Right-angle fillets: a 0.04 m geodesic leg down each edge, closed by a spherical
	# arc. Three square corners on a curved surface is the whole claim.
	var ang: float = FILLET_ARC / radius
	var corners: Array = [[vx, vz, vy], [vz, vx, vy], [vy, vx, vz]]
	for corner in corners:
		var v: Vector3 = corner[0]
		var e1: Vector3 = corner[1]
		var e2: Vector3 = corner[2]
		var a1: Vector3 = (v * cos(ang) + e1 * sin(ang)).normalized()
		var a2: Vector3 = (v * cos(ang) + e2 * sin(ang)).normalized()
		var pts: PackedVector3Array = PackedVector3Array()
		for i in range(13):
			var t: float = float(i) / 12.0
			pts.append(a1.slerp(a2, t).normalized() * (radius + SURF_LIFT * 1.8))
		_track(_tube(pts, PLATE_ROD, col, true))

	_track(_plate("SUM = 270", 0.16, 0.06, Vector3(0.0, -radius + 0.05, 0.50), col))


## The sphere's net and the plane's grid drawn as ONE object: 8 meridians and 8 parallels
## up top, 8 radial rods and 8 concentric rings below, each ring the image of the
## parallel directly above it.
func _build_net() -> void:
	var col: Color = Color(0.55, 0.85, 1.0)
	var plate_y: float = -radius + 0.012

	for k in range(NET_LINES):
		var phi: float = TAU * float(k) / float(NET_LINES)
		var pts: PackedVector3Array = PackedVector3Array()
		for i in range(49):
			var theta: float = float(i) / 48.0 * PI
			pts.append(_sph_lift(theta, phi, SURF_LIFT))
		_track(_tube(pts, NET_TUBE, col, true))

	for k in range(NET_LINES):
		var y: float = lerp(NET_Y_LOW * radius, NET_Y_HIGH * radius,
			float(k) / float(NET_LINES - 1))
		var rho: float = sqrt(maxf(radius * radius - y * y, 0.0))
		var lift: float = (radius + SURF_LIFT) / radius
		var pts: PackedVector3Array = PackedVector3Array()
		for i in range(49):
			var a: float = TAU * float(i) / 48.0
			pts.append(Vector3(cos(a) * rho * lift, y * lift, sin(a) * rho * lift))
		_track(_tube(pts, NET_TUBE, col, true))

		var rr: float = _proj_radius(y)
		var ring: PackedVector3Array = PackedVector3Array()
		for i in range(49):
			var a2: float = TAU * float(i) / 48.0
			ring.append(Vector3(cos(a2) * rr, plate_y, sin(a2) * rr))
		_track(_tube(ring, NET_TUBE, col, true))

	for k in range(NET_LINES):
		var phi2: float = TAU * float(k) / float(NET_LINES)
		_track(_tube(PackedVector3Array([
			Vector3(0.0, plate_y, 0.0),
			Vector3(cos(phi2) * _plane_half(), plate_y, sin(phi2) * _plane_half())
		]), NET_TUBE, col, true))


## The uncompactified plane the sphere exists to close. No sphere, no equator, no pole,
## no glyph — a 1.80 m plate carrying two rods that stay 0.10 m apart along their whole
## 1.60 m and a triangle whose three straight sides sum to 180.
func _build_euclid() -> void:
	var col: Color = Color(0.35, 1.0, 0.6)
	var y: float = 0.012
	var half: float = EUCLID_ROD_LEN * 0.5
	for si in range(2):
		var z: float = -0.42 + float(si) * EUCLID_ROD_GAP
		_track(_tube(PackedVector3Array([
			Vector3(-half, y, z), Vector3(half, y, z)]), PLATE_ROD, col, true))

	var tcol: Color = Color(1.0, 0.55, 0.25)
	var a: Vector3 = Vector3(-0.35, y, 0.52)
	var b: Vector3 = Vector3(0.35, y, 0.52)
	var c: Vector3 = Vector3(0.0, y, -0.06)
	_track(_tube(PackedVector3Array([a, b]), PLATE_ROD, tcol, true))
	_track(_tube(PackedVector3Array([b, c]), PLATE_ROD, tcol, true))
	_track(_tube(PackedVector3Array([c, a]), PLATE_ROD, tcol, true))

	_track(_plate("SUM = 180", 0.20, 0.06, Vector3(0.0, 0.09, 0.72), tcol))


func _build_label() -> void:
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 12
	if postulate == "euclid":
		_label.text = "EUCLIDEAN PLANE\nno point at infinity"
		_label.position = Vector3(0, -0.20, 0)
	else:
		_label.text = "RIEMANN SPHERE\nComplex plane + ∞"
		_label.position = Vector3(0, -radius - 0.2, 0)
	_track(_label)


# ═══════════════════════════════════════════════════════════════════
# GEOMETRY HELPERS
# ═══════════════════════════════════════════════════════════════════

func _create_circle(r: float, color: Color) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = r - 0.005
	torus.outer_radius = r + 0.005
	torus.rings = 48
	torus.ring_segments = 8
	mesh_instance.mesh = torus

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	return mesh_instance


## theta measured from the NORTH pole, phi east from +X.
func _sph(theta: float, phi: float) -> Vector3:
	return Vector3(
		radius * sin(theta) * cos(phi),
		radius * cos(theta),
		radius * sin(theta) * sin(phi))


func _sph_lift(theta: float, phi: float, lift: float) -> Vector3:
	var d: Vector3 = Vector3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi))
	return d * (radius + lift)


func _plane_half() -> float:
	return radius * 1.5


## Plate radius of the image of a sphere point at height y. Monotone, 0 at the south
## pole, the plate rim at the north pole. See PROJ_GAMMA for why it is compressed.
func _proj_radius(y: float) -> float:
	var u: float = clampf((y + radius) / (2.0 * radius), 0.0, 1.0)
	return _plane_half() * pow(u, PROJ_GAMMA)


## A tube swept along a polyline with a parallel-transported frame. Deterministic —
## no randomness anywhere in this file, so two builds of one value are pixel-identical.
func _tube(points: PackedVector3Array, tube_r: float, col: Color, emissive: bool) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var n: int = points.size()
	if n < 2:
		return mi

	var tangents: Array = []
	for i in range(n):
		var t: Vector3
		if i == 0:
			t = points[1] - points[0]
		elif i == n - 1:
			t = points[n - 1] - points[n - 2]
		else:
			t = points[i + 1] - points[i - 1]
		if t.length() < 0.000001:
			t = Vector3(0, 0, 1)
		tangents.append(t.normalized())

	var seed_up: Vector3 = Vector3(0, 1, 0)
	var t0: Vector3 = tangents[0]
	if absf(t0.dot(seed_up)) > 0.9:
		seed_up = Vector3(1, 0, 0)
	var nrm: Vector3 = (seed_up - t0 * seed_up.dot(t0)).normalized()

	var rings: Array = []
	for i in range(n):
		var tng: Vector3 = tangents[i]
		nrm = nrm - tng * nrm.dot(tng)
		if nrm.length() < 0.000001:
			var alt: Vector3 = Vector3(0, 1, 0)
			if absf(tng.dot(alt)) > 0.9:
				alt = Vector3(1, 0, 0)
			nrm = alt - tng * alt.dot(tng)
		nrm = nrm.normalized()
		var bin: Vector3 = tng.cross(nrm).normalized()
		var ring: Array = []
		for s in range(TUBE_SIDES):
			var ang: float = TAU * float(s) / float(TUBE_SIDES)
			ring.append(points[i] + (nrm * cos(ang) + bin * sin(ang)) * tube_r)
		rings.append(ring)

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(n - 1):
		for s in range(TUBE_SIDES):
			var s2: int = (s + 1) % TUBE_SIDES
			var a0: Vector3 = rings[i][s]
			var a1: Vector3 = rings[i][s2]
			var b0: Vector3 = rings[i + 1][s]
			var b1: Vector3 = rings[i + 1][s2]
			var axis0: Vector3 = points[i]
			var axis1: Vector3 = points[i + 1]
			_push_tube_vert(st, a0, axis0)
			_push_tube_vert(st, b0, axis1)
			_push_tube_vert(st, b1, axis1)
			_push_tube_vert(st, a0, axis0)
			_push_tube_vert(st, b1, axis1)
			_push_tube_vert(st, a1, axis0)

	mi.mesh = st.commit()
	mi.material_override = _line_mat(col, emissive)
	return mi


func _push_tube_vert(st: SurfaceTool, p: Vector3, axis_point: Vector3) -> void:
	var nv: Vector3 = p - axis_point
	if nv.length() < 0.000001:
		nv = Vector3(0, 1, 0)
	st.set_normal(nv.normalized())
	st.add_vertex(p)


func _line_mat(col: Color, emissive: bool) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emissive:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 0.6
	return mat


## A small captioned plate. Deliberately plain — the caption is evidence that the figure
## above it was built, not decoration.
func _plate(text: String, w: float, h: float, pos: Vector3, col: Color) -> Node3D:
	var root: Node3D = Node3D.new()
	root.position = pos

	var body: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(w, h, 0.008)
	body.mesh = box
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.09, 0.12)
	mat.roughness = 0.8
	body.material_override = mat
	root.add_child(body)

	var lab: Label3D = Label3D.new()
	lab.text = text
	lab.pixel_size = 0.0006
	lab.font_size = 40
	lab.modulate = col
	lab.position = Vector3(0.0, 0.0, 0.007)
	root.add_child(lab)
	return root


func _track(n: Node) -> Node:
	add_child(n)
	_spawned.append(n)
	return n


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

## Accept an axis value only if it names something we actually build. A typo in a map
## token falls back to the value already in place rather than stranding the placement.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Called via call_deferred by GridInteractablesComponent, AFTER _ready(). Also called by
## curation_station with {"emissive": false} one line after it has darkened and un-
## billboarded the labels — so a rebuild here MUST be conditional, or that framing is
## thrown away and every curated shelf silently reverts.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_postulate: String = postulate
	var before_infinity: String = infinity
	var before_radius: float = radius
	var before_lines: bool = show_projection_lines

	# Pre-existing behaviour: any property named in the dict is set straight through.
	# The two axes are excluded so they can go through the allow-list instead of taking
	# an unrecognised string raw.
	for key in config_data:
		if key == "postulate" or key == "infinity":
			continue
		if key in self:
			set(key, config_data[key])

	if config_data.has("postulate"):
		postulate = _pick_axis(str(config_data["postulate"]), POSTULATES, postulate)
	if config_data.has("infinity"):
		infinity = _pick_axis(str(config_data["infinity"]), INFINITIES, infinity)

	if not _built:
		return
	if (postulate == before_postulate
			and infinity == before_infinity
			and is_equal_approx(radius, before_radius)
			and show_projection_lines == before_lines):
		return  # nothing geometric moved — touch nothing, say nothing

	_rebuild_now()
	print("[RiemannSphere] Config applied — postulate=%s, infinity=%s" % [postulate, infinity])


## Synchronous. A deferred rebuild would leave the node empty when _auto_ground_artifact
## measures the AABB, and the artifact would never be grounded.
func _rebuild_now() -> void:
	for n in _spawned:
		if is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	_spawned.clear()
	_sphere = null
	_north_pole = null
	_projection_plane = null
	_label = null
	_build_all()
