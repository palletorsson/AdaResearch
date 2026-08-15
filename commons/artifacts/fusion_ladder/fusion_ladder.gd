extends Node3D
class_name FusionLadder

## fusion_ladder — four names hung on one dial, and only two of the three gaps hide an event.
##
## THE FAMILY. Four artifacts share the axis `fusion` with the values distinct necked lobed
## single: metaballs, raymarched_metaballs, implicit_surface_modeling (three registry names on
## ONE scene, metaballs.tscn, which folds sphere SDFs with smin(a, b, k) and turns k) and
## csg_union_demo (a hard CSG union of a box and a sphere, which turns the offset). Three of
## the four default to `distinct` — a k too small to reach the gaps, so the picture is
## separate spheres — and csg_union_demo defaults to `lobed`. Both promotions say the word
## names STATES OF THE RESULT, how many bodies you see. Neither says what sits BETWEEN the
## states.
##
## THE ARGUMENT. Take the family's own field — two sphere SDFs of radius R folded by the very
## smin() metaball.gdshader carries, k held fixed — and turn the one thing csg_union_demo
## turns: the separation d of the two centres. Then distinct / necked / lobed / single are
## four stations on ONE number, F(midpoint) = d/2 - R - k/6, and along that dial exactly TWO
## things happen that are not smooth deformation:
##
##   d = 2R + k/3   the surface becomes one connected component. F(mid) crosses zero, the
##                  saddle of the field at the midpoint crosses the isovalue, and two bodies
##                  are one body. A change of TOPOLOGY. It sits between distinct and necked.
##   d ~ 0.204      the waist vanishes. The midplane stops being a local minimum of the
##                  profile — F_xx on the surface at the midplane changes sign — and the body
##                  goes from two lobes under one skin to a single ovoid. Not topology; a
##                  change of the surface's curvature class. It sits between lobed and single.
##
## Between necked and lobed NOTHING happens except that the neck widens. The vocabulary
## spaces its four names as if evenly, and it puts an event in two of its three gaps and none
## in the third; the pair with no event between them should be the closest-looking pair on
## the whole ladder, and that is registered as the prediction. csg_union_demo's note already
## half-says this — "there necked is a smooth bridge, here it is a crease" — and this bench
## is the smooth side of that sentence built out. And the corpus critic's finding that
## csg_union_demo's `join` axis is CONDITIONAL on fusion (at distinct there is no seam because
## nothing joined) is the same fact from the other end: the seam is born at the first event.
##
## THE BODY, NOT A GAUGE. No number is plotted. The skin IS the isosurface, root-found on the
## field; the `section` reading cuts it and lays the field's own level sets in the cut, so the
## dial can be read a second way — as isovalue instead of separation — in the same picture.
## The two dials are one: a level set at c is connected iff F(mid) <= c, so every rung of the
## section shows both regimes, separated by the level the midpoint field happens to sit at.
##
## HOW THE SURFACE IS MADE, said plainly so nobody mistakes it for a shader. Two centres on the
## x-axis make the field axisymmetric, so the isosurface is a surface of revolution about x:
## the profile rho(x) at F(x, rho) = c is found by bisection on each radial ray (F is monotone
## in rho — smin is monotone in each argument), the poles by bisection on F(x, 0) = c, and each
## connected run of the axis where F(x, 0) < c is lathed as its own closed body. Component
## count is not asserted; it falls out of how many runs the axis has. Normals are the field
## gradient. Nothing is random; every value is a fixed pair of centres.

## How far apart the two centres stand, in the family's four words and the family's order.
## The default is `distinct`, the default of three of the four members. Separations, in metres,
## against R = 0.18 and k = 0.24 (2R + k = 0.60 is where smin first touches the skin, 2R + k/3
## = 0.44 is where the surface connects, ~0.204 is where the waist vanishes):
##   distinct — d = 0.62. The gap of 0.26 is wider than k, so smin never engages: the skin is
##              two exact spheres of radius 0.18, which is precisely what the metaball members'
##              shipped `distinct` is (k = 0.4 against gaps of one to three metres). F(mid) =
##              +0.09. Two components.
##   necked   — d = 0.42, two hundredths inside the connect threshold. F(mid) = -0.010; the neck
##              at the midplane has radius 0.066, about a third of R. One component, and the
##              first rung on which that is true.
##   lobed    — d = 0.34. F(mid) = -0.050; waist radius 0.140 against a lobe radius of 0.180, a
##              22% dip. Same topology as necked, wider neck, nothing between them.
##   single   — d = 0.16, past the waist threshold. F(mid) = -0.140; the profile is widest at the
##              midplane (0.205) and falls monotonically to the poles: one ovoid, 0.52 long by
##              0.41 wide, with two centres inside it and no outward sign of either.
@export_enum("distinct", "necked", "lobed", "single") var fusion: String = "distinct":
	set(v):
		fusion = v
		if is_inside_tree() and not _suspend:
			_rebuild()

## What is drawn.
##   skin    — the isosurface F = 0 alone, opaque. The reading in which the four stations are
##             four silhouettes and nothing else.
##   sources — the skin at half opacity with the two spheres it was blended from standing inside
##             it as three great-circle rings each, radius R exactly. At `distinct` the rings sit
##             ON the skin, because the skin is the sources; from `necked` on the skin lifts off
##             them wherever the blend engages, and the rings show where the two bodies are that
##             the one skin no longer admits.
##   section — the near half of the skin cut away at the plane through both centres, the cut
##             filled dark, and the field's level sets laid in the cut: c = -0.16 to +0.08 in
##             steps of 0.04, the c = 0 line drawn heavier because it is the skin. Some levels are
##             two loops and some are one, and the level that switches is F(mid).
@export_enum("skin", "sources", "section") var reading: String = "skin":
	set(v):
		reading = v
		if is_inside_tree() and not _suspend:
			_rebuild()

## Whether the four rungs stand together or one at a time. NOT PART OF THE AXIS, for the reason
## frequency_shell learned at the cost of a sweep: an all-rungs value inside the ladder axis
## makes the sweep union its AABB with every single rung and photograph the singles as specks.
## The registry fixture pins `single` for the sweep; the artifact stands as the whole
## comparison by default, which is what it is for. The ladder stacks vertically, `distinct`
## at the bottom and `single` at the top, the direction the family's own note says the ladder
## runs.
@export_enum("ladder", "single") var layout: String = "ladder":
	set(v):
		layout = v
		if is_inside_tree() and not _suspend:
			_rebuild()

## Radius of each source sphere and the smin k, both fixed. Exports so a scene can retune them;
## the four separations are ratios of these two numbers only in the sense that the thresholds
## are (2R + k/3 and the waist root), so retuning moves the stations off their glossed events.
@export var radius: float = 0.18
@export var blend: float = 0.24
## Vertical pitch of the ladder rungs. 0.56 clears the section reading's outer level (+/-0.26).
@export var rung_pitch: float = 0.56

const FUSIONS: PackedStringArray = ["distinct", "necked", "lobed", "single"]
## The separation behind each word. See the export doc for what each number is against.
const SEPARATION := {"distinct": 0.62, "necked": 0.42, "lobed": 0.34, "single": 0.16}
## Level sets drawn in the section, in metres of the SDF-like field. 0 is the skin.
const LEVELS: Array = [-0.16, -0.12, -0.08, -0.04, 0.0, 0.04, 0.08]
## Rings of the lathe per body (cosine-spaced in x, so the poles are sampled to a fraction of a
## millimetre and the middle to about 5 mm) and segments around.
const N_RINGS: int = 220
const N_AROUND: int = 44
## Step of the axis scan that finds where each body begins and ends.
const AXIS_STEP: float = 0.002
## Radial bisection ceiling. Nothing here reaches past R + k/6 + the outermost level.
const RHO_MAX: float = 0.6

const SKIN_COLOR := Color(0.78, 0.74, 0.66)
const RING_COLOR := Color(0.88, 0.62, 0.30)
const CUT_COLOR := Color(0.15, 0.17, 0.21)
const INSIDE_COLOR := Color(0.36, 0.60, 0.74)
const OUTSIDE_COLOR := Color(0.62, 0.56, 0.48)

var _built: Array[Node3D] = []
## True only inside apply_grid_config, while several exports are being assigned at once.
var _suspend: bool = false


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	# The setters each rebuild when in the tree; hold them so a config with three keys
	# builds once, not four times.
	_suspend = true
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("fusion"):
		fusion = str(config_data["fusion"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
	if config_data.has("radius"):
		radius = float(config_data["radius"])
	if config_data.has("blend"):
		blend = float(config_data["blend"])
	_suspend = false
	_rebuild()


func _rebuild() -> void:
	for old in _built:
		if is_instance_valid(old):
			# Out of the tree NOW, not at end of frame, so a capture measured in the same
			# frame as a rebuild does not union the old rung's meshes into the new one's box.
			if old.get_parent() != null:
				old.get_parent().remove_child(old)
			old.queue_free()
	_built.clear()
	var rungs: Array = []
	if layout == "ladder":
		for i in range(FUSIONS.size()):
			rungs.append(FUSIONS[i])
	else:
		rungs.append(fusion if SEPARATION.has(fusion) else "distinct")
	var n: int = rungs.size()
	for i in range(n):
		var holder := Node3D.new()
		holder.name = str(rungs[i])
		holder.position = Vector3(0.0, (float(i) - float(n - 1) * 0.5) * rung_pitch, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_rung(holder, float(SEPARATION[rungs[i]]))


## One pair of blobs at separation d, in whichever reading is set.
func _build_rung(holder: Node3D, d: float) -> void:
	if reading == "section":
		_add_lathe(holder, d, 0.0, PI, TAU, _mat(SKIN_COLOR, 0.0, 1.0, true), "SkinBack")
		_add_cut(holder, d)
		for i in range(LEVELS.size()):
			_add_contour(holder, d, float(LEVELS[i]))
	elif reading == "sources":
		_add_sources(holder, d)
		_add_lathe(holder, d, 0.0, 0.0, TAU, _mat(SKIN_COLOR, 0.0, 0.5, false), "Skin")
	else:
		_add_lathe(holder, d, 0.0, 0.0, TAU, _mat(SKIN_COLOR, 0.0, 1.0, false), "Skin")


# ── The field ─────────────────────────────────────────────────────────────

## metaball.gdshader's smin, character for character: polynomial, acts only where |a - b| < k.
func _smin(a: float, b: float, k: float) -> float:
	var h: float = maxf(k - absf(a - b), 0.0) / k
	return minf(a, b) - h * h * h * k * (1.0 / 6.0)


## The field at axial position x and radial distance rho, for centres at -d/2 and +d/2.
func _field(x: float, rho: float, d: float) -> float:
	var half: float = d * 0.5
	var a: float = sqrt((x + half) * (x + half) + rho * rho) - radius
	var b: float = sqrt((x - half) * (x - half) + rho * rho) - radius
	return _smin(a, b, blend)


## rho at which F(x, rho) = level, by bisection. F is monotone in rho, so this is exact to the
## iteration count. Assumes F(x, 0) < level (the caller checks).
func _rho_at(x: float, d: float, level: float) -> float:
	var lo: float = 0.0
	var hi: float = RHO_MAX
	for i in range(40):
		var mid: float = (lo + hi) * 0.5
		if _field(x, mid, d) < level:
			lo = mid
		else:
			hi = mid
	return (lo + hi) * 0.5


## Where F(x, 0) = level between an outside sample and an inside one.
func _pole_between(x_out: float, x_in: float, d: float, level: float) -> float:
	var a: float = x_out
	var b: float = x_in
	for i in range(40):
		var mid: float = (a + b) * 0.5
		if _field(mid, 0.0, d) < level:
			b = mid
		else:
			a = mid
	return (a + b) * 0.5


## The runs of the axis on which F(x, 0) < level — one per connected body of that level set.
## Returns an Array of [x_start, x_end]. Component count is this array's size.
func _bodies(d: float, level: float) -> Array:
	var out: Array = []
	var span: float = d * 0.5 + radius + blend + 0.2
	var x: float = -span
	var prev_in: bool = false
	var prev_x: float = x
	var start: float = 0.0
	while x <= span:
		var inside: bool = _field(x, 0.0, d) < level
		if inside and not prev_in:
			start = _pole_between(prev_x, x, d, level)
		elif prev_in and not inside:
			out.append([start, _pole_between(x, prev_x, d, level)])
		prev_in = inside
		prev_x = x
		x += AXIS_STEP
	return out


## The profile of one body: Array of Vector2(x, rho), pole to pole, cosine-spaced so the poles
## are dense. First and last entries have rho = 0.
func _profile(x0: float, x1: float, d: float, level: float) -> Array:
	var pts: Array = []
	var span: float = x1 - x0
	for i in range(N_RINGS + 1):
		var t: float = float(i) / float(N_RINGS)
		var x: float = x0 + span * (1.0 - cos(PI * t)) * 0.5
		if i == 0 or i == N_RINGS:
			pts.append(Vector2(x, 0.0))
		else:
			pts.append(Vector2(x, _rho_at(x, d, level)))
	return pts


## Outward normal of the level set in the (x, rho) half-plane at a profile point.
func _profile_normal(x: float, rho: float, d: float) -> Vector2:
	var e: float = 0.0005
	var gx: float = _field(x + e, rho, d) - _field(x - e, rho, d)
	var gr: float = _field(x, rho + e, d) - _field(x, rho - e, d)
	var g := Vector2(gx, gr)
	if g.length() < 1e-9:
		return Vector2(0.0, 1.0)
	return g.normalized()


# ── The skin ──────────────────────────────────────────────────────────────

## Lathe every body of the level set F = level about the x-axis, from angle a0 to a1 (0..TAU is
## the whole skin; PI..TAU is the half with z <= 0, the far half from the sweep's camera).
func _add_lathe(holder: Node3D, d: float, level: float, a0: float, a1: float,
		mat: StandardMaterial3D, label: String) -> void:
	var bodies: Array = _bodies(d, level)
	if bodies.is_empty():
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg: int = N_AROUND if a1 - a0 > PI * 1.5 else int(N_AROUND / 2.0)
	# cos/sin once per angle, not once per vertex.
	var cs: Array = []
	var sn: Array = []
	for j in range(seg + 1):
		var t: float = a0 + (a1 - a0) * float(j) / float(seg)
		cs.append(cos(t))
		sn.append(sin(t))
	for bi in range(bodies.size()):
		var prof: Array = _profile(float(bodies[bi][0]), float(bodies[bi][1]), d, level)
		var normals: Array = []
		for pi_ in range(prof.size()):
			var pv: Vector2 = prof[pi_]
			normals.append(_profile_normal(pv.x, pv.y, d))
		for i in range(prof.size() - 1):
			var p0: Vector2 = prof[i]
			var p1: Vector2 = prof[i + 1]
			var n0: Vector2 = normals[i]
			var n1: Vector2 = normals[i + 1]
			for j in range(seg):
				var c0: float = float(cs[j])
				var s0: float = float(sn[j])
				var c1: float = float(cs[j + 1])
				var s1: float = float(sn[j + 1])
				var v00 := Vector3(p0.x, p0.y * c0, p0.y * s0)
				var v01 := Vector3(p0.x, p0.y * c1, p0.y * s1)
				var v10 := Vector3(p1.x, p1.y * c0, p1.y * s0)
				var v11 := Vector3(p1.x, p1.y * c1, p1.y * s1)
				var m00 := Vector3(n0.x, n0.y * c0, n0.y * s0)
				var m01 := Vector3(n0.x, n0.y * c1, n0.y * s1)
				var m10 := Vector3(n1.x, n1.y * c0, n1.y * s0)
				var m11 := Vector3(n1.x, n1.y * c1, n1.y * s1)
				if p0.y < 1e-6:
					# Pole fan at the start of the body.
					_tri(st, v00, v10, v11, m00, m10, m11)
				elif p1.y < 1e-6:
					# Pole fan at the end of the body.
					_tri(st, v00, v10, v01, m00, m10, m01)
				else:
					_tri(st, v00, v10, v11, m00, m10, m11)
					_tri(st, v00, v11, v01, m00, m11, m01)
	var mi := MeshInstance3D.new()
	mi.name = label
	mi.mesh = st.commit()
	mi.material_override = mat
	holder.add_child(mi)


## One triangle, WOUND OUTWARD: the field gradient at the centroid is the outward normal by
## definition, so the winding is flipped whenever the cross product disagrees with it. Deriving
## the surface from a lathe says nothing about orientation on its own — frequency_shell's
## icosahedron photographed as a ball with a bite out of it for exactly this omission.
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		na: Vector3, nb: Vector3, nc: Vector3) -> void:
	var outward: Vector3 = (na + nb + nc)
	if (b - a).cross(c - a).dot(outward) < 0.0:
		st.set_normal(na)
		st.add_vertex(a)
		st.set_normal(nc)
		st.add_vertex(c)
		st.set_normal(nb)
		st.add_vertex(b)
	else:
		st.set_normal(na)
		st.add_vertex(a)
		st.set_normal(nb)
		st.add_vertex(b)
		st.set_normal(nc)
		st.add_vertex(c)


# ── sources ───────────────────────────────────────────────────────────────

## The two spheres the skin is a blend of, as three great-circle rings each at radius R exactly.
## Rings rather than surfaces because at `distinct` the source IS the skin and a second surface
## there would be coplanar with it — the coincident_face fault. A ring of finite tube radius
## straddles the skin instead of fighting it.
func _add_sources(holder: Node3D, d: float) -> void:
	var half: float = d * 0.5
	for si in range(2):
		var cx: float = -half if si == 0 else half
		var centre := Vector3(cx, 0.0, 0.0)
		# Plane x = cx: torus axis along X.
		holder.add_child(_ring(centre, Vector3(0.0, 0.0, PI * 0.5), "RingX"))
		# Plane y = 0: torus axis along Y (TorusMesh's own orientation).
		holder.add_child(_ring(centre, Vector3.ZERO, "RingY"))
		# Plane z = 0: torus axis along Z.
		holder.add_child(_ring(centre, Vector3(PI * 0.5, 0.0, 0.0), "RingZ"))


func _ring(centre: Vector3, rot: Vector3, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var tm := TorusMesh.new()
	tm.inner_radius = radius - 0.003
	tm.outer_radius = radius + 0.003
	tm.rings = 64
	tm.ring_segments = 8
	mi.mesh = tm
	mi.material_override = _mat(RING_COLOR, 0.45, 1.0, false)
	mi.position = centre
	mi.rotation = rot
	return mi


# ── section ───────────────────────────────────────────────────────────────

## The cut face: the region F < 0 in the plane z = 0, filled dark, one strip per body between
## the top and bottom profiles. Sits a millimetre in front of the half-skin's rim so nothing is
## coplanar.
func _add_cut(holder: Node3D, d: float) -> void:
	var bodies: Array = _bodies(d, 0.0)
	if bodies.is_empty():
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var z: float = 0.001
	for bi in range(bodies.size()):
		var prof: Array = _profile(float(bodies[bi][0]), float(bodies[bi][1]), d, 0.0)
		for i in range(prof.size() - 1):
			var p0: Vector2 = prof[i]
			var p1: Vector2 = prof[i + 1]
			var a := Vector3(p0.x, p0.y, z)
			var b := Vector3(p0.x, -p0.y, z)
			var c := Vector3(p1.x, p1.y, z)
			var e := Vector3(p1.x, -p1.y, z)
			var fwd := Vector3(0.0, 0.0, 1.0)
			_tri(st, a, c, e, fwd, fwd, fwd)
			_tri(st, a, e, b, fwd, fwd, fwd)
	var mi := MeshInstance3D.new()
	mi.name = "Cut"
	mi.mesh = st.commit()
	mi.material_override = _mat(CUT_COLOR, 0.0, 1.0, true)
	holder.add_child(mi)


## One level set of the field in the plane z = 0, as a flat ribbon following the closed curve of
## every body it has at that level. The c = 0 line is the skin and is drawn heavier; levels
## inside are cool, levels outside warm and faint. Ribbons sit 3 mm proud of the cut face.
func _add_contour(holder: Node3D, d: float, level: float) -> void:
	var bodies: Array = _bodies(d, level)
	if bodies.is_empty():
		return
	var is_skin: bool = absf(level) < 1e-6
	var w: float = 0.0045 if is_skin else 0.0025
	var z: float = 0.004 if is_skin else 0.003
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fwd := Vector3(0.0, 0.0, 1.0)
	for bi in range(bodies.size()):
		var prof: Array = _profile(float(bodies[bi][0]), float(bodies[bi][1]), d, level)
		# Walk the closed loop: top profile forward, bottom profile back.
		var loop: Array = []
		for i in range(prof.size()):
			var p: Vector2 = prof[i]
			loop.append(Vector2(p.x, p.y))
		for i in range(prof.size() - 2, 0, -1):
			var p: Vector2 = prof[i]
			loop.append(Vector2(p.x, -p.y))
		var m: int = loop.size()
		for i in range(m):
			var p0: Vector2 = loop[i]
			var p1: Vector2 = loop[(i + 1) % m]
			var dir: Vector2 = p1 - p0
			if dir.length() < 1e-7:
				continue
			var side: Vector2 = Vector2(-dir.y, dir.x).normalized() * w
			var a := Vector3(p0.x + side.x, p0.y + side.y, z)
			var b := Vector3(p0.x - side.x, p0.y - side.y, z)
			var c := Vector3(p1.x + side.x, p1.y + side.y, z)
			var e := Vector3(p1.x - side.x, p1.y - side.y, z)
			_tri(st, a, c, e, fwd, fwd, fwd)
			_tri(st, a, e, b, fwd, fwd, fwd)
	var mi := MeshInstance3D.new()
	mi.name = "Level" + str(int(round(level * 100.0)))
	mi.mesh = st.commit()
	var col: Color = SKIN_COLOR
	var emit: float = 0.55
	if level < -1e-6:
		# Deeper inside, darker: -0.04 is close to the skin's own tone, -0.16 is the deep colour.
		col = INSIDE_COLOR.lerp(INSIDE_COLOR.darkened(0.45), clampf(-level / 0.16, 0.0, 1.0))
		emit = 0.35
	elif level > 1e-6:
		col = OUTSIDE_COLOR
		emit = 0.15
	mi.material_override = _mat(col, emit, 1.0, true)
	holder.add_child(mi)


# ── Materials ─────────────────────────────────────────────────────────────

func _mat(c: Color, emit: float, alpha: float, two_sided: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.roughness = 0.55
	if alpha < 0.999:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if two_sided:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m
