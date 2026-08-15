extends Node3D
class_name PostulateBench

## postulate_bench — the parallel postulate is not a fact about lines, it is a claim about
## a SURFACE.
##
## THE FAMILY. Three artifacts declare an axis called `postulate` and all three carry the
## same five words in the same order — bare · parallels · triangle · net · euclid — and all
## three default to `bare` (3 of 3): elliptic_surface (an orange SphereMesh, R 0.40, sunk
## 0.12), hyperbolic_surface (a blue Monge patch y = K(x² - z²)/2, 1.0 m square, K 1.0) and
## riemann_sphere (a translucent ball, R 0.30, with a projection plate). Three separate
## scenes, three separate scripts; no two are one scene under two names. Their kin carry
## the same question under another word: angle_sum_triangle and curvature_slider declare
## `opening` = flat · hyperbolic · elliptic.
##
## WHAT THE MEMBERS' CODE DOES FOR EACH VALUE — read, not guessed:
##   bare       the surface alone, no marks. All three.
##   parallels  two geodesics 0.10 m apart where they cross a common transversal at right
##              angles. elliptic: two meridians 0.10 apart at the equator meeting at the pole
##              (gd:174-196); hyperbolic: two RK4 geodesics launched from (±0.05, 0) both ways
##              (gd:185-193); riemann: two meridians pole to pole (gd:318-345). 0.10 is the
##              one number all three share.
##   triangle   a closed geodesic triangle with its corner angles marked by an arc at
##              geodesic radius 0.05 (elliptic gd:205-244, hyperbolic gd:202-231; riemann
##              draws an octant, 90+90+90).
##   net        8 x 8. elliptic and riemann draw meridians and latitude circles (a globe
##              grid); hyperbolic draws two families of GEODESICS launched at equal arc
##              spacing (gd:284-299) and reads the curvature off the growth of the cells.
##   euclid     IN ALL THREE THE CURVATURE IS REMOVED. elliptic replaces the sphere with a
##              flat disc (gd:140-156); hyperbolic sets h ≡ 0 and runs the same integrator
##              (gd:369-376); riemann builds no sphere at all and a 1.80 m plane (gd:429-446).
##              On the flat surface each then draws BOTH the parallels and the triangle. So
##              the members' `euclid` is not "a flat diagram on the curved surface" — it is
##              "the flat surface, with the diagram on it".
##
## THE ARGUMENT. Take that literally and factor it. The members had one knob and hid two
## variables in it: WHAT is drawn (nothing, a pair, a triangle, a net, Euclid's page) and
## WHERE it is drawn (a sphere, a plane, a saddle). Here they are two axes. The construction
## is ONE — a base point P, a transversal geodesic T through P, two geodesics perpendicular
## to T at ±0.05 m from P, an equilateral geodesic triangle of circumradius 0.36 m centred
## on P with its corner angles built as filled wedges, an 8 x 8 net of geodesics launched
## 0.125 m apart along T and its perpendicular — and it is drawn on three REAL surfaces:
## a sphere of R 0.50 (Gauss curvature K = +4), a flat plate (K = 0) and the saddle
## y = x² - z² (K = -4 at the saddle point). Same construction, three surfaces: on the
## sphere the parallels meet at both poles and the corners open to 75° each (sum 225°);
## on the plate they stay 0.10 apart for ever and the corners are 60° (180°); on the saddle
## they splay and the corners close (sum about 157°). Nothing is printed. The angle sum is
## the wedges' own area.
##
## AND `euclid`. Under two axes the members' meaning ("flatten the surface") is not
## available to a postulate value — flatness is the other axis. So `euclid` here means what
## it says: EUCLID'S OWN DIAGRAM, the flat page — a 0.80 m sheet tangent to the surface at
## P carrying straight rods 0.10 apart, a straight-sided triangle and three 60° wedges. On
## the plane the page lies ON the surface and every rod on it is a geodesic: the members'
## `euclid` tile is exactly this artifact's (euclid, plane). On the sphere the page touches
## at P and floats off the ball everywhere else; on the saddle the ridge comes up through
## it and swallows one corner. It is the same object at all three curvatures and it is TRUE
## on exactly one of them. That is the whole thesis, as a thing you can walk around.

## WHAT IS DRAWN. The family's five words, the family's order, the family's default.
##   bare       the surface alone — a ball, a plate, a saddle.
##   parallels  transversal T through P and the two geodesics perpendicular to it 0.10 m
##              apart, traced to the rim; on the sphere they are meridians and end in a
##              junction ball where they meet, at both poles.
##   triangle   the geodesic triangle of circumradius 0.36 m centred on P, sides integrated
##              (saddle, plane) or great-circle arcs (sphere), corner angles as filled wedges
##              of geodesic radius 0.10 m.
##   net        8 + 8 geodesics perpendicular to T and to T' (the geodesic through P
##              perpendicular to T), launched 0.125 m of arc apart. Cells collapse toward
##              four points on the sphere, hold on the plate, grow toward the rim on the
##              saddle. Junction balls where a family meets.
##   euclid     Euclid's page: a flat sheet tangent at P with the flat construction on it.
@export_enum("bare", "parallels", "triangle", "net", "euclid") var postulate: String = "bare":
	set(v):
		postulate = v
		if is_inside_tree():
			_rebuild()

## WHERE IT IS DRAWN. Named by the body, not the adjective (curvature_slider's `opening`
## says flat/hyperbolic/elliptic; the thing you walk around is a sphere, a plate, a saddle).
##   sphere   R = 0.50 m, K = +4. elliptic_surface's colour. P is on the equator at the
##            front (FRONT_BEARING); T is the equator.
##   plane    a 1.0 m plate, K = 0. P at its centre; T along its x axis.
##   saddle   y = x² - z², 1.0 m square, K = -4 at P. hyperbolic_surface's colour, its
##            integrator, twice its curvature so the deficit is legible. T along the ridge.
@export_enum("sphere", "plane", "saddle") var curvature: String = "sphere":
	set(v):
		curvature = v
		if is_inside_tree():
			_rebuild()

## One surface, or all three in a row (sphere · plane · saddle) at the same postulate. NOT
## PART OF EITHER AXIS — wave 13 learned that an all-rungs value declared inside an axis
## makes capture_config_sweep union the row's AABB with every single and photograph the
## singles as specks. The registry fixture pins `single`.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		layout = v
		if is_inside_tree():
			_rebuild()

const POSTULATES: PackedStringArray = ["bare", "parallels", "triangle", "net", "euclid"]
const CURVATURES: PackedStringArray = ["sphere", "plane", "saddle"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the three surfaces, metres ─────────────────────────────────────────────────────────
const RADIUS: float = 0.50        ## sphere; K = 1/R² = +4
const HALF: float = 0.50          ## plate and saddle half-width: 1.0 m square
const SADDLE_K: float = 1.0       ## y = SADDLE_K (x² - z²); K at the saddle point = -4 SADDLE_K²
const CENTRE_Y: float = 0.50      ## height of P on the plate and saddle, and of the ball's centre
## The sphere's base point P sits on the equator at this bearing (from +X toward +Z), which
## is the horizontal bearing of capture_config_sweep's standpoint (YAW 0.62 → dir
## (sin 0.62, ·, cos 0.62)). Every artifact has a front; this one's front is where the sweep
## stands, so all three corner wedges and the top junction are in the still.
const FRONT_BEARING: float = PI * 0.5 - 0.62

# ── the one construction, metres ───────────────────────────────────────────────────────
const GAP: float = 0.10           ## the family's number: parallels 0.10 apart at T
const TRI_RHO: float = 0.36       ## geodesic circumradius of the triangle
const TRI_BEARINGS: PackedFloat32Array = [90.0, 210.0, 330.0]  ## hyperbolic_surface gd:204
const WEDGE_R: float = 0.13       ## geodesic radius of each corner wedge
const WEDGE_RINGS: int = 3
const WEDGE_SEGS: int = 14
const NET_LINES: int = 8
const NET_PITCH: float = 0.125    ## arc spacing of the net's launch points along T and T'
const SHEET: float = 0.80         ## Euclid's page, square, tangent at P
const LADDER_PITCH: float = 1.30

# ── marks ─────────────────────────────────────────────────────────────────────────────
const TUBE_MAIN: float = 0.018    ## parallels, triangle sides: 36 mm bars, 3.6% of a 1.0 m body (the members' 0.014 on 0.80 m)
const TUBE_CROSS: float = 0.012   ## the transversal
const TUBE_NET: float = 0.010
const TUBE_SIDES: int = 6
const JUNCTION_R: float = 0.035   ## elliptic_surface's JUNCTION_R, scaled to the body
const LIFT_FRAC: float = 0.7      ## tube centreline stands this many radii proud of the surface
const WEDGE_LIFT: float = 0.006
const SHEET_LIFT: float = 0.002
const GEO_STEPS: int = 64
const GEO_LENGTH: float = 1.30    ## generous arc budget; every trace clips at the rim

const SPHERE_COLOR: Color = Color(0.80, 0.50, 0.30)      ## elliptic_surface gd:131
const SADDLE_COLOR: Color = Color(0.30, 0.50, 0.80)      ## hyperbolic_surface gd:142
const PLANE_COLOR: Color = Color(0.46, 0.47, 0.52)
const PARALLEL_COLOR: Color = Color(0.96, 0.94, 0.86)    ## elliptic_surface LINE_COLOR
const CROSS_COLOR: Color = Color(0.88, 0.90, 0.94)       ## hyperbolic_surface gd:179
const TRIANGLE_COLOR: Color = Color(0.98, 0.72, 0.22)    ## hyperbolic_surface gd:216
const WEDGE_COLOR: Color = Color(1.00, 0.45, 0.18)       ## hyperbolic_surface gd:231
const NET_COLOR: Color = Color(0.94, 0.96, 1.00)         ## hyperbolic_surface gd:299
const SHEET_COLOR: Color = Color(0.96, 0.94, 0.86, 0.30)

var _built: Array[Node3D] = []


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("layout"):
		layout = _pick(str(config_data["layout"]), LAYOUTS, layout)
	if config_data.has("postulate"):
		postulate = _pick(str(config_data["postulate"]), POSTULATES, postulate)
	if config_data.has("curvature"):
		curvature = _pick(str(config_data["curvature"]), CURVATURES, curvature)
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
	var names: Array = []
	if layout == "ladder":
		for c in CURVATURES:
			names.append(c)
	else:
		names.append(_pick(curvature, CURVATURES, "sphere"))
	var n: int = names.size()
	for i in range(n):
		var holder := Node3D.new()
		holder.name = str(names[i])
		holder.position = Vector3((float(i) - float(n - 1) * 0.5) * LADDER_PITCH, 0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_variant(holder, str(names[i]))


## One surface, with whatever the postulate axis asks drawn on it.
func _build_variant(holder: Node3D, curv: String) -> void:
	_add_surface(holder, curv)
	var p: String = _pick(postulate, POSTULATES, "bare")
	match p:
		"parallels":
			_add_transversal(holder, curv)
			_add_parallels(holder, curv)
		"triangle":
			_add_triangle(holder, curv)
		"net":
			_add_net(holder, curv)
		"euclid":
			_add_euclid(holder, curv)
		_:
			pass


# ── the surfaces ────────────────────────────────────────────────────────────────────────

func _add_surface(holder: Node3D, curv: String) -> void:
	if curv == "sphere":
		var ball := MeshInstance3D.new()
		ball.name = "Sphere"
		var sm := SphereMesh.new()
		sm.radius = RADIUS
		sm.height = RADIUS * 2.0
		sm.radial_segments = 48
		sm.rings = 24
		ball.mesh = sm
		ball.position = _sphere_centre()
		ball.material_override = _surface_mat(SPHERE_COLOR)
		holder.add_child(ball)
		return
	# The plate and the saddle are one builder: a 24 x 24 Monge-patch grid with analytic
	# normals, h ≡ 0 for the plate. CULL_DISABLED because a saddle shows both faces.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var res: int = 24
	var step: float = HALF * 2.0 / float(res)
	for i in range(res):
		for j in range(res):
			var x1: float = -HALF + float(i) * step
			var z1: float = -HALF + float(j) * step
			var x2: float = x1 + step
			var z2: float = z1 + step
			var a: Vector2 = Vector2(x1, z1)
			var b: Vector2 = Vector2(x2, z1)
			var c: Vector2 = Vector2(x1, z2)
			var d: Vector2 = Vector2(x2, z2)
			var quad: Array = [a, b, c, b, d, c]
			for k in range(quad.size()):
				var q: Vector2 = quad[k]
				st.set_normal(_nrm(q, curv))
				st.add_vertex(_p3(q, curv))
	var mi := MeshInstance3D.new()
	mi.name = "Saddle" if curv == "saddle" else "Plate"
	mi.mesh = st.commit()
	mi.material_override = _surface_mat(SADDLE_COLOR if curv == "saddle" else PLANE_COLOR)
	holder.add_child(mi)


func _surface_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.2
	m.roughness = 0.6
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


# ── the base point P and its frame ──────────────────────────────────────────────────────
# On the plate and saddle P is the centre, T runs along +X (e1) and e2 = n × e1 = -Z. On the
# sphere P is on the equator at FRONT_BEARING, e1 is the equator's tangent there (screen-
# right from the sweep standpoint) and e2 = n × e1 = +Y, up the front meridian.

func _sphere_centre() -> Vector3:
	return Vector3(0.0, CENTRE_Y, 0.0)


## Unit outward direction of the sphere's base point.
func _sp_P() -> Vector3:
	return Vector3(cos(FRONT_BEARING), 0.0, sin(FRONT_BEARING))


func _sp_e1() -> Vector3:
	return Vector3(sin(FRONT_BEARING), 0.0, -cos(FRONT_BEARING))


func _sp_e2() -> Vector3:
	return Vector3.UP


## Point on the marking shell at unit direction d, `off` metres proud of the sphere.
func _sp_lift(d: Vector3, off: float) -> Vector3:
	return _sphere_centre() + d * (RADIUS + off)


## Great-circle arc from unit direction a along unit tangent t (t ⊥ a), angles ang0..ang1.
func _sp_arc(a: Vector3, t: Vector3, ang0: float, ang1: float, steps: int) -> PackedVector3Array:
	var out: PackedVector3Array = PackedVector3Array()
	for i in range(steps + 1):
		var ang: float = lerpf(ang0, ang1, float(i) / float(steps))
		out.append((a * cos(ang) + t * sin(ang)).normalized())
	return out


func _sp_tube(dirs: PackedVector3Array, r: float, c: Color, emit: float, label: String) -> MeshInstance3D:
	var pts: PackedVector3Array = PackedVector3Array()
	for d in dirs:
		pts.append(_sp_lift(d, r * LIFT_FRAC))
	return _tube(pts, r, c, emit, label)


# ── the Monge patch y = h(x, z), plate and saddle ───────────────────────────────────────

func _h(x: float, z: float, curv: String) -> float:
	if curv == "plane":
		return 0.0
	return SADDLE_K * (x * x - z * z)


func _hx(x: float, curv: String) -> float:
	if curv == "plane":
		return 0.0
	return 2.0 * SADDLE_K * x


func _hz(z: float, curv: String) -> float:
	if curv == "plane":
		return 0.0
	return -2.0 * SADDLE_K * z


func _p3(p: Vector2, curv: String) -> Vector3:
	return Vector3(p.x, CENTRE_Y + _h(p.x, p.y, curv), p.y)


func _nrm(p: Vector2, curv: String) -> Vector3:
	return Vector3(-_hx(p.x, curv), 1.0, -_hz(p.y, curv)).normalized()


## Geodesic equation of a Monge patch (hyperbolic_surface gd:395-407):
##     u'' = -h_u (h_uu u'² + 2 h_uv u'v' + h_vv v'²) / (1 + h_u² + h_v²)
## With h = K(x² - z²): h_uu = 2K, h_vv = -2K, h_uv = 0, so the numerator is 2K(x'² - z'²).
## On the plate it vanishes and the integrator draws straight lines on its own.
func _accel(p: Vector2, v: Vector2, curv: String) -> Vector2:
	if curv == "plane":
		return Vector2.ZERO
	var gx: float = _hx(p.x, curv)
	var gz: float = _hz(p.y, curv)
	var num: float = 2.0 * SADDLE_K * (v.x * v.x - v.y * v.y)
	var den: float = 1.0 + gx * gx + gz * gz
	var k: float = num / den
	return Vector2(-k * gx, -k * gz)


func _deriv(s: Vector4, curv: String) -> Vector4:
	var a: Vector2 = _accel(Vector2(s.x, s.y), Vector2(s.z, s.w), curv)
	return Vector4(s.z, s.w, a.x, a.y)


func _rk4(s: Vector4, ds: float, curv: String) -> Vector4:
	var k1: Vector4 = _deriv(s, curv)
	var k2: Vector4 = _deriv(s + k1 * (ds * 0.5), curv)
	var k3: Vector4 = _deriv(s + k2 * (ds * 0.5), curv)
	var k4: Vector4 = _deriv(s + k3 * ds, curv)
	return s + (k1 + k2 * 2.0 + k3 * 2.0 + k4) * (ds / 6.0)


## Scale a parameter-space direction so the traced curve is unit speed in 3D — that is
## what makes 0.10 m, 0.36 m and 0.125 m mean metres ON the surface.
func _unit_param_dir(p: Vector2, d: Vector2, curv: String) -> Vector2:
	var dy: float = _hx(p.x, curv) * d.x + _hz(p.y, curv) * d.y
	var l: float = sqrt(d.x * d.x + dy * dy + d.y * d.y)
	if l < 1e-9:
		return Vector2(1.0, 0.0)
	return d / l


## RK4 trace of a geodesic from p0 in direction dir for `length` metres of arc.
func _trace(p0: Vector2, dir: Vector2, length: float, steps: int, clip_rim: bool, curv: String) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var v: Vector2 = _unit_param_dir(p0, dir, curv)
	var s: Vector4 = Vector4(p0.x, p0.y, v.x, v.y)
	out.append(p0)
	var ds: float = length / float(steps)
	for i in range(steps):
		var ns: Vector4 = _rk4(s, ds, curv)
		var np: Vector2 = Vector2(ns.x, ns.y)
		if clip_rim and (absf(np.x) > HALF or absf(np.y) > HALF):
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
	if absf(b.x) > HALF and absf(b.x - a.x) > 1e-9:
		var bx: float = HALF if b.x > 0.0 else -HALF
		t = minf(t, (bx - a.x) / (b.x - a.x))
	if absf(b.y) > HALF and absf(b.y - a.y) > 1e-9:
		var bz: float = HALF if b.y > 0.0 else -HALF
		t = minf(t, (bz - a.y) / (b.y - a.y))
	return clampf(t, 0.0, 1.0)


## Reverse the backward half and stitch it to the forward half: one ribbon, no seam.
func _join(back: PackedVector2Array, fwd: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for i in range(back.size() - 1, 0, -1):
		out.append(back[i])
	for p in fwd:
		out.append(p)
	return out


## Shooting solve for the geodesic from a to b (hyperbolic_surface gd:478-500): scan launch
## bearings around the chord, keep the nearest miss, bisect. Deterministic.
func _geodesic_between(a: Vector2, b: Vector2, curv: String) -> PackedVector2Array:
	var chord: float = _p3(a, curv).distance_to(_p3(b, curv))
	var length: float = chord * 1.35 + 0.05
	var base: float = atan2(b.y - a.y, b.x - a.x)
	var span: float = 0.35
	var best_th: float = base
	var best_d: float = INF
	for i in range(25):
		var th: float = base - span + 2.0 * span * float(i) / 24.0
		var d: float = _shoot_miss(a, b, th, length, 48, curv)
		if d < best_d:
			best_d = d
			best_th = th
	var lo: float = best_th - 0.032
	var hi: float = best_th + 0.032
	for i in range(22):
		var m1: float = lo + (hi - lo) * 0.4
		var m2: float = lo + (hi - lo) * 0.6
		if _shoot_miss(a, b, m1, length, 80, curv) < _shoot_miss(a, b, m2, length, 80, curv):
			hi = m2
		else:
			lo = m1
	return _shoot_path(a, b, (lo + hi) * 0.5, length, 130, curv)


func _shoot_miss(a: Vector2, b: Vector2, theta: float, length: float, steps: int, curv: String) -> float:
	var pts: PackedVector2Array = _trace(a, Vector2(cos(theta), sin(theta)), length, steps, false, curv)
	var target: Vector3 = _p3(b, curv)
	var best: float = INF
	var prev: Vector3 = _p3(pts[0], curv)
	for i in range(1, pts.size()):
		var cur: Vector3 = _p3(pts[i], curv)
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


func _shoot_path(a: Vector2, b: Vector2, theta: float, length: float, steps: int, curv: String) -> PackedVector2Array:
	var pts: PackedVector2Array = _trace(a, Vector2(cos(theta), sin(theta)), length, steps, false, curv)
	var target: Vector3 = _p3(b, curv)
	var best: float = INF
	var idx: int = pts.size() - 1
	var prev: Vector3 = _p3(pts[0], curv)
	for i in range(1, pts.size()):
		var cur: Vector3 = _p3(pts[i], curv)
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


## Direction a side leaves (or arrives at) a vertex, measured over 0.04 m of arc rather than
## one integration step (hyperbolic_surface gd:238-259).
func _edge_dir(path: PackedVector2Array, from_end: bool, dist: float, curv: String) -> Vector2:
	var n: int = path.size()
	if n < 2:
		return Vector2(1.0, 0.0)
	var anchor: Vector2 = path[n - 1] if from_end else path[0]
	var target: Vector2 = anchor
	var prev: Vector3 = _p3(anchor, curv)
	var acc: float = 0.0
	var i: int = (n - 2) if from_end else 1
	var stepdir: int = -1 if from_end else 1
	while i >= 0 and i < n:
		var cur: Vector3 = _p3(path[i], curv)
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


## Parameter x at arc length s from P along the transversal z = 0 (y = K x²), by marching.
## On the plate it is s. Along x = 0 the saddle is y = -K z², the same integral, so the same
## function serves T'.
func _param_at_arc(s: float, curv: String) -> float:
	if curv == "plane":
		return s
	var sgn: float = 1.0 if s >= 0.0 else -1.0
	var target: float = absf(s)
	var x: float = 0.0
	var acc: float = 0.0
	var dx: float = 0.0005
	while acc < target and x < HALF:
		var slope: float = _hx(x + dx * 0.5, curv)
		acc += dx * sqrt(1.0 + slope * slope)
		x += dx
	return sgn * x


## Lift a parameter-space curve onto the surface and push it out along the normal.
func _lift(params: PackedVector2Array, offset: float, curv: String) -> PackedVector3Array:
	var out: PackedVector3Array = PackedVector3Array()
	for p in params:
		out.append(_p3(p, curv) + _nrm(p, curv) * offset)
	return out


func _patch_tube(params: PackedVector2Array, r: float, c: Color, emit: float, label: String, curv: String) -> MeshInstance3D:
	return _tube(_lift(params, r * LIFT_FRAC, curv), r, c, emit, label)


# ── postulate: parallels ────────────────────────────────────────────────────────────────

## The transversal T: a geodesic through P. On the plate and saddle the line z = 0 (a plane
## of symmetry of the saddle, so a true geodesic); on the sphere the equator, whole.
func _add_transversal(holder: Node3D, curv: String) -> void:
	if curv == "sphere":
		var dirs: PackedVector3Array = PackedVector3Array()
		for i in range(97):
			var a: float = TAU * float(i) / 96.0
			dirs.append(Vector3(cos(a), 0.0, sin(a)))
		holder.add_child(_sp_tube(dirs, TUBE_CROSS, CROSS_COLOR, 0.10, "Transversal"))
		return
	var params: PackedVector2Array = PackedVector2Array()
	for i in range(49):
		params.append(Vector2(-HALF + 2.0 * HALF * float(i) / 48.0, 0.0))
	holder.add_child(_patch_tube(params, TUBE_CROSS, CROSS_COLOR, 0.10, "Transversal", curv))


## Two geodesics perpendicular to T at ±GAP/2 from P along T, both ways. On the plate they
## hold 0.10 for ever; on the saddle they splay; on the sphere they are meridians and meet
## at both poles, where a junction ball marks the event.
func _add_parallels(holder: Node3D, curv: String) -> void:
	for si in range(2):
		var sgn: float = -1.0 if si == 0 else 1.0
		if curv == "sphere":
			var lon: float = FRONT_BEARING + sgn * (GAP * 0.5) / RADIUS
			var eq: Vector3 = Vector3(cos(lon), 0.0, sin(lon))
			# Front semicircle: south pole, up the front, north pole.
			var dirs: PackedVector3Array = _sp_arc(eq, Vector3.UP, -PI * 0.5, PI * 0.5, 48)
			holder.add_child(_sp_tube(dirs, TUBE_MAIN, PARALLEL_COLOR, 0.30, "Parallel"))
		else:
			var start: Vector2 = Vector2(_param_at_arc(sgn * GAP * 0.5, curv), 0.0)
			var fwd: PackedVector2Array = _trace(start, Vector2(0.0, 1.0), GEO_LENGTH, GEO_STEPS, true, curv)
			var back: PackedVector2Array = _trace(start, Vector2(0.0, -1.0), GEO_LENGTH, GEO_STEPS, true, curv)
			holder.add_child(_patch_tube(_join(back, fwd), TUBE_MAIN, PARALLEL_COLOR, 0.30, "Parallel", curv))
	if curv == "sphere":
		holder.add_child(_ball(_sp_lift(Vector3.UP, 0.0), JUNCTION_R, PARALLEL_COLOR, "JunctionN"))
		holder.add_child(_ball(_sp_lift(Vector3.DOWN, 0.0), JUNCTION_R, PARALLEL_COLOR, "JunctionS"))


# ── postulate: triangle ─────────────────────────────────────────────────────────────────

## Vertices at geodesic distance TRI_RHO from P at bearings 90 · 210 · 330 in the (e1, e2)
## frame; sides are geodesics; each corner carries a filled wedge of geodesic radius WEDGE_R
## between its two sides. The wedges ARE the angle sum.
func _add_triangle(holder: Node3D, curv: String) -> void:
	if curv == "sphere":
		var P: Vector3 = _sp_P()
		var e1: Vector3 = _sp_e1()
		var e2: Vector3 = _sp_e2()
		var ang: float = TRI_RHO / RADIUS
		var verts: Array = []
		for b in TRI_BEARINGS:
			var br: float = deg_to_rad(float(b))
			var t: Vector3 = (e1 * cos(br) + e2 * sin(br)).normalized()
			verts.append((P * cos(ang) + t * sin(ang)).normalized())
		for i in range(3):
			var a: Vector3 = verts[i]
			var c: Vector3 = verts[(i + 1) % 3]
			var dirs: PackedVector3Array = PackedVector3Array()
			for s in range(29):
				dirs.append(a.slerp(c, float(s) / 28.0).normalized())
			holder.add_child(_sp_tube(dirs, TUBE_MAIN, TRIANGLE_COLOR, 0.30, "Side"))
		for i in range(3):
			_add_sphere_wedge(holder, verts[i], verts[(i + 1) % 3], verts[(i + 2) % 3])
		return
	# Plate and saddle: vertices by tracing TRI_RHO from P, sides by shooting.
	var pverts: Array = []
	for b in TRI_BEARINGS:
		var br: float = deg_to_rad(float(b))
		var d: Vector2 = Vector2(cos(br), -sin(br))  # e2 = -Z in parameter space
		var path: PackedVector2Array = _trace(Vector2.ZERO, d, TRI_RHO, 24, false, curv)
		pverts.append(path[path.size() - 1])
	var sides: Array = []
	for i in range(3):
		sides.append(_geodesic_between(pverts[i], pverts[(i + 1) % 3], curv))
	for i in range(3):
		holder.add_child(_patch_tube(sides[i], TUBE_MAIN, TRIANGLE_COLOR, 0.30, "Side", curv))
	for i in range(3):
		var out_path: PackedVector2Array = sides[i]
		var in_path: PackedVector2Array = sides[(i + 2) % 3]
		var d1: Vector2 = _edge_dir(out_path, false, 0.04, curv)
		var d2: Vector2 = _edge_dir(in_path, true, 0.04, curv)
		_add_patch_wedge(holder, pverts[i], d1, d2, curv)


## Sphere corner wedge at unit vertex v between the great circles to a and b: rings of points
## at geodesic radii WEDGE_R * j / WEDGE_RINGS swept from the tangent toward a to the tangent
## toward b, filled as a fan and lifted WEDGE_LIFT off the ball.
func _add_sphere_wedge(holder: Node3D, v: Vector3, a: Vector3, b: Vector3) -> void:
	var t1: Vector3 = (a - v * v.dot(a)).normalized()
	var t2: Vector3 = (b - v * v.dot(b)).normalized()
	var sweep: float = acos(clampf(t1.dot(t2), -1.0, 1.0))
	var axis: Vector3 = t1.cross(t2)
	if axis.length() < 1e-5:
		return
	axis = axis.normalized()
	var rings: Array = []
	var ring_normals: Array = []
	for j in range(1, WEDGE_RINGS + 1):
		var fa: float = (WEDGE_R * float(j) / float(WEDGE_RINGS)) / RADIUS
		var ring: PackedVector3Array = PackedVector3Array()
		var nrms: PackedVector3Array = PackedVector3Array()
		for k in range(WEDGE_SEGS + 1):
			var u: Vector3 = t1.rotated(axis, sweep * float(k) / float(WEDGE_SEGS))
			var d: Vector3 = (v * cos(fa) + u * sin(fa)).normalized()
			ring.append(_sp_lift(d, WEDGE_LIFT))
			nrms.append(d)
		rings.append(ring)
		ring_normals.append(nrms)
	holder.add_child(_fan(_sp_lift(v, WEDGE_LIFT), v, rings, ring_normals, WEDGE_COLOR, "Wedge"))


## Plate/saddle corner wedge at parameter vertex v between side directions d1 and d2: each
## sampled direction is its own short geodesic, so the arc lands on both sides.
func _add_patch_wedge(holder: Node3D, v: Vector2, d1: Vector2, d2: Vector2, curv: String) -> void:
	var sweep: float = d1.angle_to(d2)  # signed, the interior turn from d1 to d2
	var rings: Array = []
	var ring_normals: Array = []
	for j in range(WEDGE_RINGS):
		rings.append(PackedVector3Array())
		ring_normals.append(PackedVector3Array())
	for k in range(WEDGE_SEGS + 1):
		var d: Vector2 = d1.rotated(sweep * float(k) / float(WEDGE_SEGS))
		var path: PackedVector2Array = _trace(v, d, WEDGE_R, WEDGE_RINGS * 3, false, curv)
		for j in range(WEDGE_RINGS):
			var idx: int = mini((j + 1) * 3, path.size() - 1)
			var q: Vector2 = path[idx]
			var ring: PackedVector3Array = rings[j]
			var nrms: PackedVector3Array = ring_normals[j]
			ring.append(_p3(q, curv) + _nrm(q, curv) * WEDGE_LIFT)
			nrms.append(_nrm(q, curv))
			rings[j] = ring
			ring_normals[j] = nrms
	holder.add_child(_fan(_p3(v, curv) + _nrm(v, curv) * WEDGE_LIFT, _nrm(v, curv), rings, ring_normals, WEDGE_COLOR, "Wedge"))


# ── postulate: net ──────────────────────────────────────────────────────────────────────

## Family A: geodesics perpendicular to T, launched at arc offsets ±0.0625 · ±0.1875 ·
## ±0.3125 · ±0.4375 along T from P. Family B: the same along T'. On the plate an 8 x 8 grid;
## on the saddle the cells grow toward the rim (hyperbolic_surface's own net); on the sphere
## family A are meridians meeting at the poles and family B are great circles through the two
## equator points 90° from P, so the cells collapse toward four points. Junction balls at each.
func _add_net(holder: Node3D, curv: String) -> void:
	for k in range(NET_LINES):
		var s: float = (float(k) + 0.5 - float(NET_LINES) * 0.5) * NET_PITCH
		if curv == "sphere":
			var lon: float = FRONT_BEARING + s / RADIUS
			var eq: Vector3 = Vector3(cos(lon), 0.0, sin(lon))
			holder.add_child(_sp_tube(_sp_arc(eq, Vector3.UP, -PI * 0.5, PI * 0.5, 48),
					TUBE_NET, NET_COLOR, 0.22, "NetA"))
			var q: Vector3 = (_sp_P() * cos(s / RADIUS) + Vector3.UP * sin(s / RADIUS)).normalized()
			holder.add_child(_sp_tube(_sp_arc(q, _sp_e1(), -PI * 0.5, PI * 0.5, 48),
					TUBE_NET, NET_COLOR, 0.22, "NetB"))
		else:
			var o: float = _param_at_arc(s, curv)
			var a0: Vector2 = Vector2(o, 0.0)
			var af: PackedVector2Array = _trace(a0, Vector2(0.0, 1.0), GEO_LENGTH, GEO_STEPS, true, curv)
			var ab: PackedVector2Array = _trace(a0, Vector2(0.0, -1.0), GEO_LENGTH, GEO_STEPS, true, curv)
			holder.add_child(_patch_tube(_join(ab, af), TUBE_NET, NET_COLOR, 0.22, "NetA", curv))
			var b0: Vector2 = Vector2(0.0, o)
			var bf: PackedVector2Array = _trace(b0, Vector2(1.0, 0.0), GEO_LENGTH, GEO_STEPS, true, curv)
			var bb: PackedVector2Array = _trace(b0, Vector2(-1.0, 0.0), GEO_LENGTH, GEO_STEPS, true, curv)
			holder.add_child(_patch_tube(_join(bb, bf), TUBE_NET, NET_COLOR, 0.22, "NetB", curv))
	if curv == "sphere":
		holder.add_child(_ball(_sp_lift(Vector3.UP, 0.0), JUNCTION_R, NET_COLOR, "JunctionN"))
		holder.add_child(_ball(_sp_lift(Vector3.DOWN, 0.0), JUNCTION_R, NET_COLOR, "JunctionS"))
		holder.add_child(_ball(_sp_lift(_sp_e1(), 0.0), JUNCTION_R, NET_COLOR, "JunctionE"))
		holder.add_child(_ball(_sp_lift(-_sp_e1(), 0.0), JUNCTION_R, NET_COLOR, "JunctionW"))


# ── postulate: euclid ───────────────────────────────────────────────────────────────────

## Euclid's page: a SHEET x SHEET flat sheet tangent to the surface at P, carrying the flat
## construction — T as a straight rod, two straight rods GAP apart, a straight-sided triangle
## of circumradius TRI_RHO, three 60° wedges. Built in the frame (P, e1, e2, n) so it is one
## object at every curvature: on the plate it lies on the surface, on the sphere it is a
## vertical page touching the ball at P, on the saddle the ridge comes up through it.
func _add_euclid(holder: Node3D, curv: String) -> void:
	var P: Vector3
	var e1: Vector3
	var e2: Vector3
	var n: Vector3
	if curv == "sphere":
		n = _sp_P()
		e1 = _sp_e1()
		e2 = _sp_e2()
		P = _sphere_centre() + n * RADIUS
	else:
		P = Vector3(0.0, CENTRE_Y, 0.0)
		e1 = Vector3.RIGHT
		e2 = Vector3.FORWARD  # -Z: n × e1 with n = +Y
		n = Vector3.UP
	var h: float = SHEET * 0.5
	# The sheet.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c0: Vector3 = P + n * SHEET_LIFT
	var corners: Array = [
		c0 - e1 * h - e2 * h, c0 + e1 * h - e2 * h, c0 - e1 * h + e2 * h,
		c0 + e1 * h - e2 * h, c0 + e1 * h + e2 * h, c0 - e1 * h + e2 * h]
	for k in range(corners.size()):
		var q: Vector3 = corners[k]
		st.set_normal(n)
		st.add_vertex(q)
	var sheet := MeshInstance3D.new()
	sheet.name = "Sheet"
	sheet.mesh = st.commit()
	sheet.material_override = _mat(SHEET_COLOR, 0.15, true)
	holder.add_child(sheet)
	# T, straight.
	var lc: float = SHEET_LIFT + TUBE_CROSS * LIFT_FRAC
	holder.add_child(_tube(PackedVector3Array([P + n * lc - e1 * h, P + n * lc + e1 * h]),
			TUBE_CROSS, CROSS_COLOR, 0.10, "FlatTransversal"))
	# The two rods, GAP apart for ever.
	var lm: float = SHEET_LIFT + TUBE_MAIN * LIFT_FRAC
	for si in range(2):
		var sgn: float = -1.0 if si == 0 else 1.0
		var x0: Vector3 = P + n * lm + e1 * (sgn * GAP * 0.5)
		holder.add_child(_tube(PackedVector3Array([x0 - e2 * h, x0 + e2 * h]),
				TUBE_MAIN, PARALLEL_COLOR, 0.30, "FlatParallel"))
	# The straight-sided triangle and its 60° wedges.
	var verts: Array = []
	for b in TRI_BEARINGS:
		var br: float = deg_to_rad(float(b))
		verts.append(P + n * lm + (e1 * cos(br) + e2 * sin(br)) * TRI_RHO)
	for i in range(3):
		holder.add_child(_tube(PackedVector3Array([verts[i], verts[(i + 1) % 3]]),
				TUBE_MAIN, TRIANGLE_COLOR, 0.30, "FlatSide"))
	for i in range(3):
		var v: Vector3 = verts[i] + n * (SHEET_LIFT + WEDGE_LIFT - lm)
		var ta: Vector3 = (verts[(i + 1) % 3] - verts[i]).normalized()
		var tb: Vector3 = (verts[(i + 2) % 3] - verts[i]).normalized()
		var sweep: float = acos(clampf(ta.dot(tb), -1.0, 1.0))
		var axis: Vector3 = ta.cross(tb).normalized()
		var rings: Array = []
		var ring_normals: Array = []
		for j in range(1, WEDGE_RINGS + 1):
			var r: float = WEDGE_R * float(j) / float(WEDGE_RINGS)
			var ring: PackedVector3Array = PackedVector3Array()
			var nrms: PackedVector3Array = PackedVector3Array()
			for k in range(WEDGE_SEGS + 1):
				var u: Vector3 = ta.rotated(axis, sweep * float(k) / float(WEDGE_SEGS))
				ring.append(v + u * r)
				nrms.append(n)
			rings.append(ring)
			ring_normals.append(nrms)
		holder.add_child(_fan(v, n, rings, ring_normals, WEDGE_COLOR, "FlatWedge"))


# ── mesh helpers ────────────────────────────────────────────────────────────────────────

## A filled fan: centre point, then rings of points at increasing radius (each ring the same
## sample count), triangulated centre→ring 0 and ring j→ring j+1. Normals given per point.
func _fan(centre: Vector3, cn: Vector3, rings: Array, ring_normals: Array, c: Color, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	if rings.is_empty():
		return mi
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r0: PackedVector3Array = rings[0]
	var n0: PackedVector3Array = ring_normals[0]
	for k in range(r0.size() - 1):
		st.set_normal(cn)
		st.add_vertex(centre)
		st.set_normal(n0[k])
		st.add_vertex(r0[k])
		st.set_normal(n0[k + 1])
		st.add_vertex(r0[k + 1])
	for j in range(rings.size() - 1):
		var ra: PackedVector3Array = rings[j]
		var rb: PackedVector3Array = rings[j + 1]
		var na: PackedVector3Array = ring_normals[j]
		var nb: PackedVector3Array = ring_normals[j + 1]
		for k in range(ra.size() - 1):
			st.set_normal(na[k])
			st.add_vertex(ra[k])
			st.set_normal(nb[k])
			st.add_vertex(rb[k])
			st.set_normal(nb[k + 1])
			st.add_vertex(rb[k + 1])
			st.set_normal(na[k])
			st.add_vertex(ra[k])
			st.set_normal(nb[k + 1])
			st.add_vertex(rb[k + 1])
			st.set_normal(na[k + 1])
			st.add_vertex(ra[k + 1])
	mi.mesh = st.commit()
	mi.material_override = _mat(c, 0.35, false)
	return mi


## A round tube along a polyline, six sides, rotation-minimising frames, normals set outward
## per vertex, capped at both ends; culling is off. regime_threshold's tube plus caps.
func _tube(pts: PackedVector3Array, r: float, c: Color, emit: float, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var count: int = pts.size()
	if count < 2:
		return mi
	var rings: Array = []
	var n1: Vector3 = Vector3.ZERO
	for i in range(count):
		var prev: Vector3 = pts[maxi(i - 1, 0)]
		var next: Vector3 = pts[mini(i + 1, count - 1)]
		var tangent: Vector3 = (next - prev).normalized()
		if tangent.length_squared() < 0.5:
			tangent = Vector3.RIGHT
		if i == 0:
			var seed_axis: Vector3 = Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
			n1 = tangent.cross(seed_axis).normalized()
		else:
			n1 = n1 - tangent * n1.dot(tangent)
			if n1.length_squared() < 1e-8:
				var seed_again: Vector3 = Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
				n1 = tangent.cross(seed_again)
			n1 = n1.normalized()
		var n2: Vector3 = tangent.cross(n1).normalized()
		var ring: Array = []
		for k in range(TUBE_SIDES):
			var a: float = TAU * float(k) / float(TUBE_SIDES)
			var normal: Vector3 = n1 * cos(a) + n2 * sin(a)
			ring.append([pts[i] + normal * r, normal])
		rings.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(count - 1):
		var ra: Array = rings[i]
		var rb: Array = rings[i + 1]
		for k in range(TUBE_SIDES):
			var k2: int = (k + 1) % TUBE_SIDES
			var a0: Array = ra[k]
			var a1: Array = ra[k2]
			var b0: Array = rb[k]
			var b1: Array = rb[k2]
			var order: Array = [a0, b0, a1, a1, b0, b1]
			for j in range(order.size()):
				var v: Array = order[j]
				var vpos: Vector3 = v[0]
				var vnrm: Vector3 = v[1]
				st.set_normal(vnrm)
				st.add_vertex(vpos)
	# Caps, so a rod that ends at a rim reads as a rod and not a pipe.
	for e in range(2):
		var ci: int = 0 if e == 0 else count - 1
		var ring: Array = rings[ci]
		var cap_n: Vector3 = (pts[0] - pts[1]).normalized() if e == 0 else (pts[count - 1] - pts[count - 2]).normalized()
		for k in range(TUBE_SIDES):
			var k2: int = (k + 1) % TUBE_SIDES
			var p0: Array = ring[k]
			var p1: Array = ring[k2]
			st.set_normal(cap_n)
			st.add_vertex(pts[ci])
			st.set_normal(cap_n)
			st.add_vertex(p0[0])
			st.set_normal(cap_n)
			st.add_vertex(p1[0])
	mi.mesh = st.commit()
	mi.material_override = _mat(c, emit, false)
	return mi


func _ball(at: Vector3, r: float, c: Color, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm
	mi.position = at
	mi.material_override = _mat(c, 0.30, false)
	return mi


func _mat(c: Color, emit: float, translucent: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.0
	m.roughness = 0.45
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if translucent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	return m
