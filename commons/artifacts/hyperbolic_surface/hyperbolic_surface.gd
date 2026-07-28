# hyperbolic_surface.gd
# Saddle-shaped surface demonstrating negative curvature

extends Node3D

class_name HyperbolicSurface

# @identity
# essence: y = K(x² - z²) — saddle surface with negative Gaussian curvature K < 0
# desire: touch a saddle and feel space curve outward — parallel lines diverge, triangles have angle sum < 180°
# critical_parameter: curvature — controls the severity of the saddle
# triggers: static geometry; the shape itself teaches by contradicting Euclidean intuition
# emerges: the realization that "straight" on a saddle looks curved from outside
# needs: VR controls [missing] — could add curvature_slider connection
# relationships: contrasts elliptic_surface (K>0, lines converge); depends on curvature_slider; paired with poincare_disk (same geometry, different model)
# truth: on a negatively curved surface, there are infinitely many parallel lines through any point — the fifth postulate fails spectacularly

@export var size: float = 0.5
@export var resolution: int = 20
@export var curvature: float = 1.0

## STAGE-2 DNA AXIS — what the surface is made to SHOW about the fifth postulate.
##
## The truth statement above says the postulate fails "spectacularly". Before this axis
## the failure existed on this object only as three lines of Label3D text under a blue
## saddle: no geodesic, no parallel pair, no triangle. `curvature` was declared the
## critical parameter but reached no geometry after _ready(), and sweeping it would have
## been the wrong move anyway — K=0.5 against K=1.5 is six centimetres of rise on a one
## metre sheet, and neither one draws a single straight line.
##
##   bare       the shipped saddle alone — the pre-promotion look, untouched
##   parallels  two geodesics crossing a common transversal at right angles, splaying
##   triangle   a closed geodesic triangle with its corner angles marked
##   net        an 8x8 geodesic net; the curvature read off the growth of the cells
##   euclid     the same build on a FLAT sheet — the control, where the postulate holds
##
## Same word, same five-value ladder, on hyperbolic / elliptic / riemann, so the three
## surfaces read as one family down a sweep sheet: three curvatures, one question.
##
## Every curve drawn here is INTEGRATED, not faked — RK4 on the geodesic equation of the
## Monge patch y = h(x,z). `euclid` is not a separate drawing routine; it is the same
## integrator running on h ≡ 0, where the equation degenerates to straight lines on its
## own. That is why the two cases can stand in one room honestly.
@export_enum("bare", "parallels", "triangle", "net", "euclid") var postulate: String = "bare"

## Allow-list for the axis. A token this artifact does not build has to land on the
## legacy look rather than on a half-recognised value that would strand a placement
## with a blank saddle and no caption.
const POSTULATES: PackedStringArray = ["bare", "parallels", "triangle", "net", "euclid"]

# ── Figure metrics, all in metres ───────────────────────────────────────────────
const RIBBON_RADIUS: float = 0.014   ## geodesic ribbon tube radius
const CROSS_RADIUS: float = 0.010    ## the transversal they both cross
const NET_RADIUS: float = 0.010      ## net line tube radius
const FILLET_RADIUS_TUBE: float = 0.008
const RIBBON_HALF_GAP: float = 0.05  ## 0.10 m apart where they cross the transversal
const NET_LINES: int = 8             ## 8 by 8
const TRI_CIRCUMRADIUS: float = 0.42 ## triangle vertices, inside the 0.5 m half-sheet
const FILLET_ARC: float = 0.05       ## geodesic radius of the corner angle marks
const PLATE_Y: float = -0.17
const PLATE_Z_OUT: float = 0.10      ## plate stands this far beyond the front rim
const TUBE_SIDES: int = 6
const GEO_STEPS: int = 56            ## RK4 steps per traced geodesic
const GEO_LENGTH: float = 0.85       ## generous arc budget; every trace clips at the rim

var _mesh_instance: MeshInstance3D
var _label: Label3D

## Only the nodes THIS script made. The grid adds label plates, packaging and tag
## markers as siblings after _ready(); freeing get_children() on a rebuild would
## destroy them.
var _owned: Array = []
var _built: bool = false


func _ready() -> void:
	_build_all()
	_built = true


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

func _build_all() -> void:
	_create_surface()
	_create_label()
	match postulate:
		"parallels":
			_build_transversal()
			_build_parallel_pair()
			_build_plate("MANY PARALLELS", 0.20, 0.06)
		"triangle":
			_build_triangle_figure()
			_build_plate("SUM UNDER 180", 0.16, 0.06)
		"net":
			_build_net()
		"euclid":
			_build_transversal()
			_build_parallel_pair()
			_build_triangle_figure()
			_build_plate("SUM = 180", 0.16, 0.06)
		_:
			pass


func _create_surface() -> void:
	_mesh_instance = MeshInstance3D.new()
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var step: float = size * 2.0 / resolution

	for i in range(resolution):
		for j in range(resolution):
			var x1: float = -size + i * step
			var z1: float = -size + j * step
			var x2: float = x1 + step
			var z2: float = z1 + step

			# Saddle shape: y = x² - z² (negative Gaussian curvature)
			# _h() is the same expression; it returns 0.0 only for `euclid`.
			var y11: float = _h(x1, z1)
			var y12: float = _h(x1, z2)
			var y21: float = _h(x2, z1)
			var y22: float = _h(x2, z2)

			# Triangle 1
			surface_tool.add_vertex(Vector3(x1, y11, z1))
			surface_tool.add_vertex(Vector3(x2, y21, z1))
			surface_tool.add_vertex(Vector3(x1, y12, z2))

			# Triangle 2
			surface_tool.add_vertex(Vector3(x2, y21, z1))
			surface_tool.add_vertex(Vector3(x2, y22, z2))
			surface_tool.add_vertex(Vector3(x1, y12, z2))

	surface_tool.generate_normals()
	_mesh_instance.mesh = surface_tool.commit()

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.5, 0.8)
	mat.metallic = 0.2
	mat.roughness = 0.6
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)
	_owned.append(_mesh_instance)


func _create_label() -> void:
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 12
	# The one caption that must change: "Negative curvature / K < 0" printed under a
	# flat sheet is simply false, and the euclid tile exists to be the honest control.
	if _flat():
		_label.text = "HYPERBOLIC SURFACE\nEuclidean control\nK = 0"
	else:
		_label.text = "HYPERBOLIC SURFACE\nNegative curvature\nK < 0"
	_label.position = Vector3(0, -size - 0.1, 0)
	add_child(_label)
	_owned.append(_label)


# ── parallels ──────────────────────────────────────────────────────────────────

## The transversal: the curve z = 0. It is a genuine geodesic (a plane of symmetry of
## the saddle), which is what makes "both cross it at right angles" a real claim and
## not a drafting convenience. Spans the full 1.0 m footprint.
func _build_transversal() -> void:
	var params: PackedVector2Array = PackedVector2Array()
	var steps: int = 48
	for i in range(steps + 1):
		var x: float = -size + 2.0 * size * float(i) / float(steps)
		params.append(Vector2(x, 0.0))
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_tube(st, _lift(params, CROSS_RADIUS + 0.002), CROSS_RADIUS)
	_commit(st, Color(0.88, 0.90, 0.94), 0.10)


## Two geodesics, launched from (±0.05, 0) perpendicular to the transversal — 0.10 m
## apart where they cross it — and traced BOTH ways to the rim. On the saddle they
## splay; on the flat sheet the same integrator holds them at 0.10 m all the way.
func _build_parallel_pair() -> void:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s in [-1.0, 1.0]:
		var start: Vector2 = Vector2(RIBBON_HALF_GAP * s, 0.0)
		var fwd: PackedVector2Array = _trace(start, Vector2(0.0, 1.0), GEO_LENGTH, GEO_STEPS, true)
		var back: PackedVector2Array = _trace(start, Vector2(0.0, -1.0), GEO_LENGTH, GEO_STEPS, true)
		_add_tube(st, _lift(_join(back, fwd), RIBBON_RADIUS + 0.002), RIBBON_RADIUS)
	_commit(st, Color(0.98, 0.72, 0.22), 0.35)


# ── triangle ───────────────────────────────────────────────────────────────────

## A closed three-arc geodesic triangle, each side found by shooting from one vertex
## and keeping the direction whose geodesic passes closest to the other. Its arcs bow
## toward the centroid — the pinch is measured, not drawn — and its corners carry
## 0.05 m geodesic fillets so the angles can be read off the still.
func _build_triangle_figure() -> void:
	var verts: Array = []
	for deg in [90.0, 210.0, 330.0]:
		var a: float = deg_to_rad(deg)
		verts.append(Vector2(TRI_CIRCUMRADIUS * cos(a), TRI_CIRCUMRADIUS * sin(a)))

	var sides: Array = []
	for i in range(3):
		sides.append(_geodesic_between(verts[i], verts[(i + 1) % 3]))

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for path in sides:
		_add_tube(st, _lift(path, RIBBON_RADIUS + 0.002), RIBBON_RADIUS)
	_commit(st, Color(0.98, 0.72, 0.22), 0.35)

	# Corner fillets. At vertex i the two adjacent directions are the outgoing tangent
	# of side i and the REVERSED incoming tangent of side i-1, both taken from the
	# integrated paths rather than from the straight chords.
	var fs: SurfaceTool = SurfaceTool.new()
	fs.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(3):
		var out_path: PackedVector2Array = sides[i]
		var in_path: PackedVector2Array = sides[(i + 2) % 3]
		if out_path.size() < 2 or in_path.size() < 2:
			continue
		var d1: Vector2 = _edge_dir(out_path, false, 0.04)
		var d2: Vector2 = _edge_dir(in_path, true, 0.04)
		_add_tube(fs, _lift(_fillet_arc(verts[i], d1, d2), FILLET_RADIUS_TUBE + 0.002), FILLET_RADIUS_TUBE)
	_commit(fs, Color(1.0, 0.45, 0.18), 0.45)


## Direction a side leaves (or arrives at) a vertex, measured over a real 0.04 m of arc
## rather than over one integration step. Reading two adjacent samples would be fragile:
## the last segment of a shot side is a short closing stub onto the exact vertex, and its
## direction is meaningless.
func _edge_dir(path: PackedVector2Array, from_end: bool, dist: float) -> Vector2:
	var n: int = path.size()
	if n < 2:
		return Vector2(1.0, 0.0)
	var anchor: Vector2 = path[n - 1] if from_end else path[0]
	var target: Vector2 = anchor
	var prev: Vector3 = _p3(anchor)
	var acc: float = 0.0
	var i: int = (n - 2) if from_end else 1
	var stepdir: int = -1 if from_end else 1
	while i >= 0 and i < n:
		var cur: Vector3 = _p3(path[i])
		acc += cur.distance_to(prev)
		prev = cur
		target = path[i]
		if acc >= dist:
			break
		i += stepdir
	var d: Vector2 = target - anchor
	if d.length() < 1e-6:
		return Vector2(1.0, 0.0)
	return d.normalized()


## Points at exactly FILLET_ARC of geodesic distance from the vertex, sweeping from one
## side to the other. Each sample is its own short geodesic, so the arc lands on both
## sides instead of near them.
func _fillet_arc(v: Vector2, d1: Vector2, d2: Vector2) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var samples: int = 12
	for k in range(samples + 1):
		var t: float = float(k) / float(samples)
		var d: Vector2 = d1.lerp(d2, t)
		if d.length() < 1e-6:
			continue
		var arc: PackedVector2Array = _trace(v, d.normalized(), FILLET_ARC, 8, false)
		out.append(arc[arc.size() - 1])
	return out


# ── net ────────────────────────────────────────────────────────────────────────

## Eight geodesics perpendicular to the z = 0 axis and eight perpendicular to the x = 0
## axis, launched at EQUAL ARC SPACING along those axes. The lines start 0.130 m apart
## and cannot stay that way: on a saddle neighbouring geodesics diverge, so the cells
## grow toward the rim. No caption — the curvature is read off the cells.
func _build_net() -> void:
	var offsets: PackedFloat32Array = _equal_arc_offsets(NET_LINES)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for o in offsets:
		# family A — perpendicular to the transversal z = 0
		var a0: Vector2 = Vector2(o, 0.0)
		var af: PackedVector2Array = _trace(a0, Vector2(0.0, 1.0), GEO_LENGTH, GEO_STEPS, true)
		var ab: PackedVector2Array = _trace(a0, Vector2(0.0, -1.0), GEO_LENGTH, GEO_STEPS, true)
		_add_tube(st, _lift(_join(ab, af), NET_RADIUS + 0.002), NET_RADIUS)
		# family B — perpendicular to the ridge x = 0
		var b0: Vector2 = Vector2(0.0, o)
		var bf: PackedVector2Array = _trace(b0, Vector2(1.0, 0.0), GEO_LENGTH, GEO_STEPS, true)
		var bb: PackedVector2Array = _trace(b0, Vector2(-1.0, 0.0), GEO_LENGTH, GEO_STEPS, true)
		_add_tube(st, _lift(_join(bb, bf), NET_RADIUS + 0.002), NET_RADIUS)
	_commit(st, Color(0.94, 0.96, 1.0), 0.22)


## Launch offsets spaced by equal ARC LENGTH along a central geodesic, not by equal x.
## Spacing by x would bake the cell growth in by hand; spacing by arc lets the surface
## produce whatever growth it actually has.
func _equal_arc_offsets(count: int) -> PackedFloat32Array:
	var samples: int = 240
	var xs: PackedFloat32Array = PackedFloat32Array()
	var acc: PackedFloat32Array = PackedFloat32Array()
	var total: float = 0.0
	var prev: Vector3 = _p3(Vector2(-size, 0.0))
	xs.append(-size)
	acc.append(0.0)
	for i in range(1, samples + 1):
		var x: float = -size + 2.0 * size * float(i) / float(samples)
		var cur: Vector3 = _p3(Vector2(x, 0.0))
		total += cur.distance_to(prev)
		prev = cur
		xs.append(x)
		acc.append(total)

	var out: PackedFloat32Array = PackedFloat32Array()
	for k in range(count):
		var target: float = total * (float(k) + 0.5) / float(count)
		out.append(_lookup(acc, xs, target))
	return out


func _lookup(acc: PackedFloat32Array, xs: PackedFloat32Array, target: float) -> float:
	for i in range(1, acc.size()):
		if acc[i] >= target:
			var span: float = acc[i] - acc[i - 1]
			var t: float = 0.0 if span < 1e-9 else (target - acc[i - 1]) / span
			return lerpf(xs[i - 1], xs[i], t)
	return xs[xs.size() - 1]


# ── plate ──────────────────────────────────────────────────────────────────────

func _build_plate(text: String, w: float, hgt: float) -> void:
	var body: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(w, hgt, 0.006)
	body.mesh = box
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = Color(0.10, 0.11, 0.13)
	m.roughness = 0.5
	body.material_override = m
	body.position = Vector3(0.0, PLATE_Y, size + PLATE_Z_OUT)
	add_child(body)
	_owned.append(body)

	var lbl: Label3D = Label3D.new()
	lbl.text = text
	lbl.font_size = 64
	var chars: int = maxi(text.length(), 1)
	lbl.pixel_size = clampf((w * 0.86) / (float(chars) * 64.0 * 0.5), 0.00018, 0.0012)
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lbl.modulate = Color(0.97, 0.95, 0.90)
	lbl.position = Vector3(0.0, 0.0, 0.005)
	body.add_child(lbl)


# ═══════════════════════════════════════════════════════════════════
# SURFACE + GEODESICS  (Monge patch y = h(x, z))
# ═══════════════════════════════════════════════════════════════════

## `euclid` is the flat control. Every builder below reads the surface only through
## these four functions, so one flag changes the geometry the whole figure lives on.
func _flat() -> bool:
	return postulate == "euclid"


func _h(x: float, z: float) -> float:
	if _flat():
		return 0.0
	return curvature * (x * x - z * z) * 0.5


func _hx(x: float, _z: float) -> float:
	return 0.0 if _flat() else curvature * x


func _hz(_x: float, z: float) -> float:
	return 0.0 if _flat() else -curvature * z


func _p3(p: Vector2) -> Vector3:
	return Vector3(p.x, _h(p.x, p.y), p.y)


func _surface_normal(p: Vector2) -> Vector3:
	return Vector3(-_hx(p.x, p.y), 1.0, -_hz(p.x, p.y)).normalized()


## Geodesic equation of a Monge patch:
##     u'' = -h_u (h_uu u'² + 2 h_uv u'v' + h_vv v'²) / (1 + h_u² + h_v²)
## With h = K(x² - z²)/2 the second-fundamental numerator collapses to K(x'² - z'²),
## and on the flat sheet it vanishes entirely — straight lines, for free.
func _accel(p: Vector2, v: Vector2) -> Vector2:
	if _flat():
		return Vector2.ZERO
	var gx: float = _hx(p.x, p.y)
	var gz: float = _hz(p.x, p.y)
	var num: float = curvature * (v.x * v.x - v.y * v.y)
	var den: float = 1.0 + gx * gx + gz * gz
	var k: float = num / den
	return Vector2(-k * gx, -k * gz)


func _deriv(s: Vector4) -> Vector4:
	var a: Vector2 = _accel(Vector2(s.x, s.y), Vector2(s.z, s.w))
	return Vector4(s.z, s.w, a.x, a.y)


func _rk4(s: Vector4, ds: float) -> Vector4:
	var k1: Vector4 = _deriv(s)
	var k2: Vector4 = _deriv(s + k1 * (ds * 0.5))
	var k3: Vector4 = _deriv(s + k2 * (ds * 0.5))
	var k4: Vector4 = _deriv(s + k3 * ds)
	return s + (k1 + k2 * 2.0 + k3 * 2.0 + k4) * (ds / 6.0)


## Scale a parameter-space direction so the traced curve is unit speed in 3D — that is
## what makes "equal arc spacing" and "0.05 m fillet radius" mean metres on the surface.
func _unit_param_dir(p: Vector2, d: Vector2) -> Vector2:
	var dy: float = _hx(p.x, p.y) * d.x + _hz(p.x, p.y) * d.y
	var l: float = sqrt(d.x * d.x + dy * dy + d.y * d.y)
	if l < 1e-9:
		return Vector2(1.0, 0.0)
	return d / l


func _trace(p0: Vector2, dir: Vector2, length: float, steps: int, clip_rim: bool) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var v: Vector2 = _unit_param_dir(p0, dir)
	var s: Vector4 = Vector4(p0.x, p0.y, v.x, v.y)
	out.append(p0)
	var ds: float = length / float(steps)
	for i in range(steps):
		var ns: Vector4 = _rk4(s, ds)
		var np: Vector2 = Vector2(ns.x, ns.y)
		if clip_rim and (absf(np.x) > size or absf(np.y) > size):
			var pp: Vector2 = Vector2(s.x, s.y)
			var t: float = _rim_fraction(pp, np)
			if t > 0.002:
				out.append(pp.lerp(np, t))
			break
		out.append(np)
		s = ns
	return out


func _rim_fraction(a: Vector2, b: Vector2) -> float:
	var t: float = 1.0
	if absf(b.x) > size and absf(b.x - a.x) > 1e-9:
		var bx: float = size if b.x > 0.0 else -size
		t = minf(t, (bx - a.x) / (b.x - a.x))
	if absf(b.y) > size and absf(b.y - a.y) > 1e-9:
		var bz: float = size if b.y > 0.0 else -size
		t = minf(t, (bz - a.y) / (b.y - a.y))
	return clampf(t, 0.0, 1.0)


## Reverse the backward half and stitch it to the forward half so a two-way trace is
## one continuous ribbon rather than two tubes meeting at a seam.
func _join(back: PackedVector2Array, fwd: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for i in range(back.size() - 1, 0, -1):
		out.append(back[i])
	for p in fwd:
		out.append(p)
	return out


## Shooting solve for the geodesic from a to b: scan launch directions around the chord
## bearing, keep the one whose curve passes nearest b, then bisect. Deterministic — no
## random restarts, so two builds of the same value are the same mesh.
func _geodesic_between(a: Vector2, b: Vector2) -> PackedVector2Array:
	var chord: float = _p3(a).distance_to(_p3(b))
	var length: float = chord * 1.35 + 0.05
	var base: float = atan2(b.y - a.y, b.x - a.x)
	var span: float = 0.35
	var best_th: float = base
	var best_d: float = INF
	for i in range(25):
		var th: float = base - span + 2.0 * span * float(i) / 24.0
		var d: float = _shoot_miss(a, b, th, length, 48)
		if d < best_d:
			best_d = d
			best_th = th
	var lo: float = best_th - 0.032
	var hi: float = best_th + 0.032
	for i in range(22):
		var m1: float = lo + (hi - lo) * 0.4
		var m2: float = lo + (hi - lo) * 0.6
		if _shoot_miss(a, b, m1, length, 80) < _shoot_miss(a, b, m2, length, 80):
			hi = m2
		else:
			lo = m1
	return _shoot_path(a, b, (lo + hi) * 0.5, length, 130)


## Miss distance measured against the SEGMENTS of the shot curve, not its samples.
## Sampling the vertices instead put a floor of half a step (~4 mm) under the objective,
## and the bisection below then stalled on quantisation rather than on geometry.
func _shoot_miss(a: Vector2, b: Vector2, theta: float, length: float, steps: int) -> float:
	var pts: PackedVector2Array = _trace(a, Vector2(cos(theta), sin(theta)), length, steps, false)
	var target: Vector3 = _p3(b)
	var best: float = INF
	var prev: Vector3 = _p3(pts[0])
	for i in range(1, pts.size()):
		var cur: Vector3 = _p3(pts[i])
		var d: float = _segment_distance(target, prev, cur)
		if d < best:
			best = d
		prev = cur
	return best


func _segment_distance(p: Vector3, s0: Vector3, s1: Vector3) -> float:
	var seg: Vector3 = s1 - s0
	var l2: float = seg.length_squared()
	if l2 < 1e-18:
		return p.distance_to(s0)
	var u: float = clampf((p - s0).dot(seg) / l2, 0.0, 1.0)
	return p.distance_to(s0 + seg * u)


## Trace the winning direction and cut the curve at the segment that passes closest to
## the far vertex, then close on the vertex exactly — so the three sides meet at a point
## instead of overshooting into a hook.
func _shoot_path(a: Vector2, b: Vector2, theta: float, length: float, steps: int) -> PackedVector2Array:
	var pts: PackedVector2Array = _trace(a, Vector2(cos(theta), sin(theta)), length, steps, false)
	var target: Vector3 = _p3(b)
	var best: float = INF
	var idx: int = pts.size() - 1
	var prev: Vector3 = _p3(pts[0])
	for i in range(1, pts.size()):
		var cur: Vector3 = _p3(pts[i])
		var d: float = _segment_distance(target, prev, cur)
		if d < best:
			best = d
			idx = i - 1
		prev = cur
	var out: PackedVector2Array = PackedVector2Array()
	for i in range(idx + 1):
		out.append(pts[i])
	out.append(b)
	return out


# ═══════════════════════════════════════════════════════════════════
# TUBE MESHING
# ═══════════════════════════════════════════════════════════════════

## Lift a parameter-space curve onto the surface and push it out along the normal by
## `offset`, so a tube of that radius sits ON the saddle instead of half inside it.
func _lift(params: PackedVector2Array, offset: float) -> PackedVector3Array:
	var out: PackedVector3Array = PackedVector3Array()
	for p in params:
		out.append(_p3(p) + _surface_normal(p) * offset)
	return out


## Normals are written explicitly (outward from the centreline) rather than generated
## from winding, and the material culls nothing — so a flipped ring can never turn into
## a black tube in a capture.
func _add_tube(st: SurfaceTool, pts: PackedVector3Array, radius: float) -> void:
	var count: int = pts.size()
	if count < 2:
		return
	var rings: Array = []
	for i in range(count):
		var t: Vector3
		if i == 0:
			t = pts[1] - pts[0]
		elif i == count - 1:
			t = pts[i] - pts[i - 1]
		else:
			t = pts[i + 1] - pts[i - 1]
		if t.length() < 1e-7:
			t = Vector3.FORWARD
		t = t.normalized()
		var ref: Vector3 = Vector3.UP
		if absf(t.dot(ref)) > 0.95:
			ref = Vector3.RIGHT
		var bi: Vector3 = t.cross(ref).normalized()
		var no: Vector3 = bi.cross(t).normalized()
		var ring: PackedVector3Array = PackedVector3Array()
		for k in range(TUBE_SIDES):
			var ang: float = TAU * float(k) / float(TUBE_SIDES)
			ring.append(pts[i] + (no * cos(ang) + bi * sin(ang)) * radius)
		rings.append(ring)

	for i in range(count - 1):
		var r0: PackedVector3Array = rings[i]
		var r1: PackedVector3Array = rings[i + 1]
		for k in range(TUBE_SIDES):
			var k2: int = (k + 1) % TUBE_SIDES
			_emit_vertex(st, r0[k], pts[i])
			_emit_vertex(st, r0[k2], pts[i])
			_emit_vertex(st, r1[k2], pts[i + 1])
			_emit_vertex(st, r0[k], pts[i])
			_emit_vertex(st, r1[k2], pts[i + 1])
			_emit_vertex(st, r1[k], pts[i + 1])

	_add_cap(st, rings[0], pts[0])
	_add_cap(st, rings[count - 1], pts[count - 1])


func _emit_vertex(st: SurfaceTool, v: Vector3, centre: Vector3) -> void:
	st.set_normal((v - centre).normalized())
	st.add_vertex(v)


func _add_cap(st: SurfaceTool, ring: PackedVector3Array, centre: Vector3) -> void:
	var n: int = ring.size()
	for k in range(n):
		var k2: int = (k + 1) % n
		var nrm: Vector3 = (ring[k] - centre).normalized()
		st.set_normal(nrm)
		st.add_vertex(centre)
		st.set_normal(nrm)
		st.add_vertex(ring[k])
		st.set_normal(nrm)
		st.add_vertex(ring[k2])


func _commit(st: SurfaceTool, col: Color, emit_energy: float) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.0
	mat.roughness = 0.35
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emit_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = emit_energy
	mi.material_override = mat
	add_child(mi)
	_owned.append(mi)


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

## Contract: resolve, then rebuild ONLY if something that reaches geometry changed.
## curation_station calls this with {"emissive": false} one line after it has framed and
## dimmed the instance; an unconditional rebuild there would throw that framing away.
##
## This is also where `curvature` finally becomes live. It was the declared critical
## parameter and, before this, set() landed it on a variable whose geometry had already
## been built in _ready() — so it changed nothing at all from a map.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_postulate: String = postulate
	var before_size: float = size
	var before_resolution: int = resolution
	var before_curvature: float = curvature

	for key in config_data:
		if key == "postulate":
			continue
		if key in self:
			set(key, config_data[key])

	if config_data.has("postulate"):
		postulate = _pick_axis(str(config_data["postulate"]), POSTULATES, postulate)

	if not _built:
		return
	if postulate == before_postulate \
			and is_equal_approx(size, before_size) \
			and resolution == before_resolution \
			and is_equal_approx(curvature, before_curvature):
		return

	_rebuild_now()
	print("[HyperbolicSurface] Config applied — postulate=%s, size=%.3f, resolution=%d, curvature=%.3f" % [
		postulate, size, resolution, curvature])


## Accept an axis value only if it names something this artifact actually builds. A typo
## in a map token falls back to the legacy look rather than to a blank saddle.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Synchronous teardown. remove_child() first so the old mesh leaves the tree in this
## frame — a deferred rebuild would let _auto_ground_artifact measure a zero AABB and
## drop the artifact through the floor.
func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			if c.get_parent() == self:
				remove_child(c)
			c.queue_free()
	_owned.clear()
	_mesh_instance = null
	_label = null
	_build_all()
