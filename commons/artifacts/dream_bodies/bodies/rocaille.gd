extends RefCounted

## ROCAILLE - one body from refs/rocaille.png, the 2048x536 panorama of glazed
## porcelain figurines: blue-and-white wave stripes at the left, a pale green
## figure carrying raised white filigree scrolls, a mauve scale-lattice tangle
## in the middle, teal with black flowing lines, a plain yellow figure at the
## right. All of them boneless, bending, one leaning into the next.
##
## What is reproduced, and with what:
##   1. Two entwined bodies - a standing figure in contrapposto leaning over a
##      kneeling one; the stander's hand rests on the kneeler's far shoulder,
##      the kneeler's arm wraps the stander's hips. Spine and every limb are
##      Catmull-Rom curves sampled into chains of overlapping CapsuleMesh with
##      tapering radii, so there are no elbows or knees - the bodies bend like
##      the clay in the picture.
##   2. Wide hips, a tipped head, a shoulder line: fat first capsule of the
##      spine, SphereMesh ellipsoids (height != 2 * radius) with a z-rotation,
##      one capsule between the shoulders.
##   3. Blue-and-white wave stripes - an ImageTexture painted per pixel (rows
##      of stripes displaced by three sines), tiled by world-space triplanar
##      mapping so the stripes run unbroken across the capsule seams.
##   4. Mauve scale lattice - a fish-scale tiling with concentric bands and a
##      dark rim, painted by finding the top-most scale disc for each pixel.
##   5. Pale green with white filigree - volutes, comma flicks and pearls
##      stamped into the texture, AND raised white scrolls: SurfaceTool tubes
##      swept along a volute spiral projected onto the host limb's surface,
##      with a bead at the eye and loose pearls (small SphereMesh).
##   6. Teal with black flowing lines, and plain yellow - the two other skins.
##   7. Glaze - StandardMaterial3D, clearcoat 1.0, roughness 0.26.
##   8. A seed is an individual: which two skins (the stander is always
##      patterned), the lean, the hip sway, the head tilt, the plumpness of
##      each body, the stripe phase, the band width, where the scrolls sit.
##
## Given up: faces and fingers (the reference has none either), the third and
## fourth bodies of the mauve tangle, and true relief for the small filigree -
## only the large scrolls stand off the glaze, the fine ones are painted.

const TEX: int = 256


static func describe() -> String:
	return "Two glazed Rocaille figurines, boneless and entwined - a standing body leaning into a kneeling one - their porcelain skins painted with wave stripes, a scale lattice or raised white filigree."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	# --- skins: the stander is always patterned, the kneeler wears anything else
	var patterned: Array = ["filigree", "scales", "waves"]
	var everything: Array = ["filigree", "scales", "waves", "flow", "plain"]
	var skin_a: String = patterned[rng.randi_range(0, patterned.size() - 1)]
	var rest: Array = []
	for k: String in everything:
		if k != skin_a:
			rest.append(k)
	var skin_b: String = rest[rng.randi_range(0, rest.size() - 1)]
	var mat_a: StandardMaterial3D = _skin(skin_a, rng)
	var mat_b: StandardMaterial3D = _skin(skin_b, rng)
	var relief: StandardMaterial3D = _glaze(null, Color(0.97, 0.96, 0.92), 1.0)
	relief.cull_mode = BaseMaterial3D.CULL_DISABLED
	# --- the individual
	var lean: float = rng.randf_range(0.14, 0.26)
	var sway: float = rng.randf_range(0.02, 0.08)
	var plump_a: float = rng.randf_range(0.92, 1.10)
	var plump_b: float = rng.randf_range(0.92, 1.10)
	var tilt: float = rng.randf_range(-0.02, 0.06)
	var twist: float = rng.randf_range(0.0, 0.08)
	var ox: float = 0.06
	var hosts_a: Array = []
	var hosts_b: Array = []
	_stander(root, mat_a, lean, sway, plump_a, tilt, ox, hosts_a)
	_kneeler(root, mat_b, plump_b, twist, ox, hosts_b)
	if skin_a == "filigree":
		_relief(root, relief, hosts_a, rng)
	if skin_b == "filigree":
		_relief(root, relief, hosts_b, rng)


# ---------------------------------------------------------------- the bodies

static func _stander(root: Node3D, mat: Material, lean: float, sway: float, plump: float, tilt: float, ox: float, hosts: Array) -> void:
	var o := Vector3(ox, 0.0, 0.0)
	var pelvis: Vector3 = Vector3(0.12 + sway, 0.79, 0.0) + o
	var waist: Vector3 = Vector3(0.10 + sway * 0.5, 0.97, 0.02) + o
	var chest: Vector3 = Vector3(0.06 - lean * 0.5, 1.15, 0.05) + o
	var neck: Vector3 = Vector3(0.12 - lean, 1.32, 0.06) + o
	var head_c: Vector3 = neck + Vector3(-0.05 - tilt, 0.13, 0.03)
	# spine: one bending tube from the fat hips to the neck
	_tube(root, mat, [pelvis, waist, chest, neck], [0.15 * plump, 0.10 * plump, 0.12 * plump, 0.06], 8, hosts)
	# shoulders
	var sh_l: Vector3 = neck + Vector3(-0.15, -0.04, 0.02)
	var sh_r: Vector3 = neck + Vector3(0.15, -0.04, -0.02)
	_capsule_between(root, mat, sh_l, sh_r, 0.065 * plump)
	hosts.append({"a": sh_l, "b": sh_r, "r": 0.065 * plump})
	# neck and head, tipped toward the kneeler
	_capsule_between(root, mat, neck, head_c, 0.05)
	_ellipsoid(root, mat, head_c, 0.085, 1.15, Basis(Vector3(0.0, 0.0, 1.0), 0.22 + tilt * 2.0))
	# legs: the right bears the weight under the pushed hip, the left knee drifts forward
	var hip_l: Vector3 = pelvis + Vector3(-0.07, -0.03, 0.0)
	var hip_r: Vector3 = pelvis + Vector3(0.07, -0.03, 0.0)
	var knee_l: Vector3 = Vector3(0.02, 0.43, 0.08) + o
	var ankle_l: Vector3 = Vector3(0.0, 0.075, 0.06) + o
	var knee_r: Vector3 = Vector3(0.26 + sway, 0.43, -0.03) + o
	var ankle_r: Vector3 = Vector3(0.26 + sway, 0.075, -0.06) + o
	_tube(root, mat, [hip_l, knee_l, ankle_l], [0.085 * plump, 0.062 * plump, 0.045], 7, hosts)
	_tube(root, mat, [hip_r, knee_r, ankle_r], [0.085 * plump, 0.062 * plump, 0.045], 7, hosts)
	_foot(root, mat, ankle_l, Vector3(-0.2, 0.0, 1.0))
	_foot(root, mat, ankle_r, Vector3(0.25, 0.0, 1.0))
	# left arm drapes behind the kneeler's head and rests on the far shoulder
	var elbow_l: Vector3 = Vector3(-0.30 - lean * 0.3, 1.14, 0.02) + o
	var wrist_l: Vector3 = Vector3(-0.43, 1.02, 0.06) + o
	_tube(root, mat, [sh_l, elbow_l, wrist_l], [0.058 * plump, 0.046, 0.036], 6, hosts)
	_capsule_between(root, mat, wrist_l, Vector3(-0.45, 0.99, 0.10) + o, 0.036)
	# right hand on the pushed hip
	var elbow_r: Vector3 = Vector3(0.32 + sway, 1.08, -0.04) + o
	var wrist_r: Vector3 = Vector3(0.26 + sway, 0.88, 0.07) + o
	_tube(root, mat, [sh_r, elbow_r, wrist_r], [0.058 * plump, 0.046, 0.036], 6, hosts)
	_capsule_between(root, mat, wrist_r, Vector3(0.23 + sway, 0.84, 0.12) + o, 0.036)


static func _kneeler(root: Node3D, mat: Material, plump: float, twist: float, ox: float, hosts: Array) -> void:
	var o := Vector3(ox, 0.0, 0.0)
	var bx: float = -0.32
	var pelvis: Vector3 = Vector3(bx, 0.44, 0.0) + o
	var waist: Vector3 = Vector3(bx - 0.01, 0.62, 0.05 + twist * 0.5) + o
	var chest: Vector3 = Vector3(bx + 0.02, 0.80, 0.10 + twist) + o
	var neck: Vector3 = Vector3(bx + 0.06, 0.96, 0.12 + twist) + o
	var head_c: Vector3 = neck + Vector3(0.03, 0.11, 0.03)
	_tube(root, mat, [pelvis, waist, chest, neck], [0.14 * plump, 0.095 * plump, 0.115 * plump, 0.055], 8, hosts)
	var sh_l: Vector3 = neck + Vector3(-0.14, -0.03, -0.04)
	var sh_r: Vector3 = neck + Vector3(0.14, -0.03, 0.04)
	_capsule_between(root, mat, sh_l, sh_r, 0.06 * plump)
	hosts.append({"a": sh_l, "b": sh_r, "r": 0.06 * plump})
	_capsule_between(root, mat, neck, head_c, 0.045)
	_ellipsoid(root, mat, head_c, 0.08, 1.1, Basis(Vector3(0.0, 0.0, 1.0), -0.3))
	# kneeling legs: thigh down to a knee on the floor, shin back along it
	var hip_r: Vector3 = pelvis + Vector3(0.08, -0.02, 0.02)
	var hip_l: Vector3 = pelvis + Vector3(-0.08, -0.02, -0.02)
	var knee_r: Vector3 = Vector3(bx + 0.12, 0.10, 0.22) + o
	var ankle_r: Vector3 = Vector3(bx + 0.09, 0.10, -0.10) + o
	var knee_l: Vector3 = Vector3(bx - 0.18, 0.10, 0.12) + o
	var ankle_l: Vector3 = Vector3(bx - 0.21, 0.10, -0.20) + o
	_tube(root, mat, [hip_r, knee_r, ankle_r], [0.08 * plump, 0.065 * plump, 0.05], 7, hosts)
	_tube(root, mat, [hip_l, knee_l, ankle_l], [0.08 * plump, 0.065 * plump, 0.05], 7, hosts)
	_foot(root, mat, ankle_r, Vector3(-0.1, 0.0, -1.0))
	_foot(root, mat, ankle_l, Vector3(-0.15, 0.0, -1.0))
	# right arm wraps the stander's hips
	var elbow_r: Vector3 = Vector3(bx + 0.30, 0.86, 0.26) + o
	var wrist_r: Vector3 = Vector3(bx + 0.46, 0.87, 0.21) + o
	_tube(root, mat, [sh_r, elbow_r, wrist_r], [0.055 * plump, 0.044, 0.035], 6, hosts)
	_capsule_between(root, mat, wrist_r, Vector3(bx + 0.52, 0.85, 0.17) + o, 0.035)
	# left hand rests on the own thigh
	var elbow_l: Vector3 = Vector3(bx - 0.22, 0.72, 0.08) + o
	var wrist_l: Vector3 = Vector3(bx - 0.16, 0.48, 0.20) + o
	_tube(root, mat, [sh_l, elbow_l, wrist_l], [0.055 * plump, 0.044, 0.035], 6, hosts)
	_capsule_between(root, mat, wrist_l, Vector3(bx - 0.11, 0.33, 0.14) + o, 0.035)


# ------------------------------------------------------------ raised filigree

static func _relief(root: Node3D, mat: Material, hosts: Array, rng: RandomNumberGenerator) -> void:
	var big: Array = []
	for h: Dictionary in hosts:
		var r: float = h["r"]
		if r >= 0.055:
			big.append(h)
	if big.is_empty():
		return
	for _k: int in range(6):
		var hs: Dictionary = big[rng.randi_range(0, big.size() - 1)]
		_relief_stroke(root, mat, hs, rng, rng.randf_range(0.035, 0.06), rng.randf_range(1.2, 1.7), 24, 0.008, 0.005, 0.76, true)
	for _k: int in range(5):
		var hc: Dictionary = big[rng.randi_range(0, big.size() - 1)]
		_relief_stroke(root, mat, hc, rng, rng.randf_range(0.03, 0.045), rng.randf_range(0.28, 0.45), 8, 0.009, 0.002, 0.2, false)
	for _k: int in range(8):
		var hd: Dictionary = big[rng.randi_range(0, big.size() - 1)]
		_dot(root, mat, _surface_point(hd, rng, 0.002), rng.randf_range(0.007, 0.011))


## One white stroke standing proud of a host capsule: a volute (turns > 1,
## strong shrink) or a comma flick (a short arc, tapering to nothing).
static func _relief_stroke(root: Node3D, mat: Material, h: Dictionary, rng: RandomNumberGenerator, size_m: float, turns: float, steps: int, w0: float, w1: float, shrink: float, bead: bool) -> void:
	var a: Vector3 = h["a"]
	var b: Vector3 = h["b"]
	var r: float = h["r"]
	var anchor: Vector3 = _surface_point(h, rng, 0.0)
	var nrm: Vector3 = _outward(anchor, a, b)
	var tu: Vector3 = nrm.cross(Vector3.UP)
	if tu.length_squared() < 1.0e-4:
		tu = nrm.cross(Vector3.RIGHT)
	tu = tu.normalized()
	var tv: Vector3 = nrm.cross(tu).normalized()
	var spin: float = rng.randf_range(0.0, TAU)
	var flip: float = 1.0 if rng.randf() < 0.5 else -1.0
	var sz: float = minf(size_m, r * 0.95)
	var pts: Array = []
	var radii: Array = []
	for k: int in range(steps + 1):
		var f: float = float(k) / float(steps)
		var th: float = spin + flip * f * turns * TAU
		var rad: float = sz * (1.0 - shrink * f)
		var p: Vector3 = anchor + (tu * cos(th) + tv * sin(th)) * rad
		pts.append(_project_to_capsule(p, a, b, r + 0.004))
		radii.append(lerpf(w0, w1, f))
	var swept: ArrayMesh = _sweep_mesh(pts, radii, 8)
	_mesh(root, swept, mat, Transform3D.IDENTITY)
	if bead:
		var eye: Vector3 = pts[steps]
		_dot(root, mat, eye, w0 * 1.15)


## A random point on the surface of a host capsule (a == b makes it a sphere).
static func _surface_point(h: Dictionary, rng: RandomNumberGenerator, lift: float) -> Vector3:
	var a: Vector3 = h["a"]
	var b: Vector3 = h["b"]
	var r: float = h["r"]
	var axis: Vector3 = b - a
	var nrm: Vector3
	var q: Vector3
	if axis.length_squared() < 1.0e-8:
		var th: float = rng.randf_range(0.0, TAU)
		var z: float = rng.randf_range(-0.7, 0.9)
		var s: float = sqrt(maxf(0.0, 1.0 - z * z))
		nrm = Vector3(s * cos(th), z, s * sin(th))
		q = a
	else:
		var t: float = rng.randf_range(0.15, 0.85)
		q = a + axis * t
		var an: Vector3 = axis.normalized()
		var u: Vector3 = an.cross(Vector3.RIGHT)
		if u.length_squared() < 1.0e-4:
			u = an.cross(Vector3.FORWARD)
		u = u.normalized()
		var v: Vector3 = an.cross(u).normalized()
		var phi: float = rng.randf_range(0.0, TAU)
		nrm = u * cos(phi) + v * sin(phi)
	return q + nrm * (r + lift)


static func _outward(p: Vector3, a: Vector3, b: Vector3) -> Vector3:
	var axis: Vector3 = b - a
	var q: Vector3 = a
	var l2: float = axis.length_squared()
	if l2 > 1.0e-8:
		var t: float = clampf((p - a).dot(axis) / l2, 0.0, 1.0)
		q = a + axis * t
	var n: Vector3 = p - q
	if n.length_squared() < 1.0e-8:
		return Vector3.UP
	return n.normalized()


static func _project_to_capsule(p: Vector3, a: Vector3, b: Vector3, rr: float) -> Vector3:
	var axis: Vector3 = b - a
	var q: Vector3 = a
	var l2: float = axis.length_squared()
	if l2 > 1.0e-8:
		var t: float = clampf((p - a).dot(axis) / l2, 0.0, 1.0)
		q = a + axis * t
	return q + _outward(p, a, b) * rr


## A tube swept along a polyline with a radius per point, closed with fans.
## Clockwise winding seen from outside, which is Godot's front face.
static func _sweep_mesh(pts: Array, radii: Array, ring_n: int) -> ArrayMesh:
	var n: int = pts.size()
	var rings: Array = []
	var ref_n: Vector3 = Vector3.UP
	for i: int in range(n):
		var p: Vector3 = pts[i]
		var tng: Vector3
		if i == 0:
			var p_next: Vector3 = pts[1]
			tng = p_next - p
		elif i == n - 1:
			var p_prev: Vector3 = pts[n - 2]
			tng = p - p_prev
		else:
			var pa: Vector3 = pts[i + 1]
			var pb: Vector3 = pts[i - 1]
			tng = pa - pb
		tng = tng.normalized()
		var nn: Vector3 = ref_n - tng * ref_n.dot(tng)
		if nn.length_squared() < 1.0e-6:
			nn = tng.cross(Vector3.RIGHT)
			if nn.length_squared() < 1.0e-6:
				nn = tng.cross(Vector3.FORWARD)
		nn = nn.normalized()
		ref_n = nn
		var bb: Vector3 = tng.cross(nn).normalized()
		var rad: float = radii[i]
		var ring := PackedVector3Array()
		for j: int in range(ring_n):
			var th: float = TAU * float(j) / float(ring_n)
			ring.append(p + (nn * cos(th) + bb * sin(th)) * rad)
		rings.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	for i: int in range(n - 1):
		var r0: PackedVector3Array = rings[i]
		var r1: PackedVector3Array = rings[i + 1]
		for j: int in range(ring_n):
			var j1: int = (j + 1) % ring_n
			st.add_vertex(r0[j])
			st.add_vertex(r1[j])
			st.add_vertex(r1[j1])
			st.add_vertex(r0[j])
			st.add_vertex(r1[j1])
			st.add_vertex(r0[j1])
	var c0: Vector3 = pts[0]
	var ring0: PackedVector3Array = rings[0]
	var c1: Vector3 = pts[n - 1]
	var ring1: PackedVector3Array = rings[n - 1]
	for j: int in range(ring_n):
		var j1: int = (j + 1) % ring_n
		st.add_vertex(c0)
		st.add_vertex(ring0[j])
		st.add_vertex(ring0[j1])
		st.add_vertex(c1)
		st.add_vertex(ring1[j1])
		st.add_vertex(ring1[j])
	st.generate_normals()
	return st.commit()


# ------------------------------------------------------------- limb geometry

## Catmull-Rom through pts, sampled into segs capsules; radii interpolate
## point to point. Every segment is recorded in hosts for the relief.
static func _tube(root: Node3D, mat: Material, pts: Array, radii: Array, segs: int, hosts: Array) -> void:
	var span: float = float(pts.size() - 1)
	var prev: Vector3 = _spline(pts, 0.0)
	for k: int in range(1, segs + 1):
		var u: float = span * float(k) / float(segs)
		var um: float = span * (float(k) - 0.5) / float(segs)
		var cur: Vector3 = _spline(pts, u)
		var r: float = _radius_at(radii, um)
		_capsule_between(root, mat, prev, cur, r)
		hosts.append({"a": prev, "b": cur, "r": r})
		prev = cur


static func _spline(pts: Array, u: float) -> Vector3:
	var n: int = pts.size()
	var i: int = clampi(int(floor(u)), 0, n - 2)
	var t: float = clampf(u - float(i), 0.0, 1.0)
	var p0: Vector3 = pts[maxi(i - 1, 0)]
	var p1: Vector3 = pts[i]
	var p2: Vector3 = pts[i + 1]
	var p3: Vector3 = pts[mini(i + 2, n - 1)]
	var t2: float = t * t
	var t3: float = t2 * t
	return (p1 * 2.0 + (p2 - p0) * t + (p0 * 2.0 - p1 * 5.0 + p2 * 4.0 - p3) * t2 + (p1 * 3.0 - p0 - p2 * 3.0 + p3) * t3) * 0.5


static func _radius_at(radii: Array, u: float) -> float:
	var n: int = radii.size()
	var i: int = clampi(int(floor(u)), 0, n - 2)
	var t: float = clampf(u - float(i), 0.0, 1.0)
	var r0: float = radii[i]
	var r1: float = radii[i + 1]
	return lerpf(r0, r1, t)


static func _capsule_between(root: Node3D, mat: Material, a: Vector3, b: Vector3, r: float) -> MeshInstance3D:
	var d: Vector3 = b - a
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = d.length() + 2.0 * r
	cap.radial_segments = 24
	cap.rings = 6
	return _mesh(root, cap, mat, Transform3D(_basis_y_to(d), (a + b) * 0.5))


static func _ellipsoid(root: Node3D, mat: Material, c: Vector3, r: float, h_scale: float, rot: Basis) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = 2.0 * r * h_scale
	sph.radial_segments = 32
	sph.rings = 16
	return _mesh(root, sph, mat, Transform3D(rot, c))


static func _dot(root: Node3D, mat: Material, c: Vector3, r: float) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = 2.0 * r
	sph.radial_segments = 12
	sph.rings = 6
	return _mesh(root, sph, mat, Transform3D(Basis.IDENTITY, c))


## A foot: a capsule lying on the floor, from just behind the ankle forward
## along dir (the kneeler's point backward).
static func _foot(root: Node3D, mat: Material, ankle: Vector3, dir: Vector3) -> void:
	var d: Vector3 = Vector3(dir.x, 0.0, dir.z).normalized()
	var fr: float = 0.046
	var a: Vector3 = Vector3(ankle.x, fr + 0.001, ankle.z) - d * 0.03
	var b: Vector3 = a + d * 0.15
	_capsule_between(root, mat, a, b, fr)


static func _basis_y_to(d: Vector3) -> Basis:
	var dn: Vector3 = d.normalized()
	if dn.length_squared() < 0.5:
		return Basis.IDENTITY
	var dotv: float = clampf(Vector3.UP.dot(dn), -1.0, 1.0)
	var axis: Vector3 = Vector3.UP.cross(dn)
	if axis.length_squared() < 1.0e-8:
		if dotv > 0.0:
			return Basis.IDENTITY
		return Basis(Vector3.RIGHT, PI)
	return Basis(axis.normalized(), acos(dotv))


static func _mesh(root: Node3D, mesh: Mesh, mat: Material, xf: Transform3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xf
	root.add_child(mi)
	return mi


# ------------------------------------------------------------------- skins

static func _skin(kind: String, rng: RandomNumberGenerator) -> StandardMaterial3D:
	match kind:
		"waves":
			var blue: Color = Color(0.15, 0.30, 0.74).lerp(Color(0.10, 0.22, 0.60), rng.randf())
			return _glaze(_tex_waves(rng, blue, Color(0.95, 0.94, 0.89)), Color.WHITE, 5.0)
		"filigree":
			var green: Color = Color(0.66, 0.84, 0.60).lerp(Color(0.74, 0.86, 0.66), rng.randf())
			return _glaze(_tex_filigree(rng, Color(0.97, 0.97, 0.93), green), Color.WHITE, 3.5)
		"scales":
			return _glaze(_tex_scales(rng, Color(0.31, 0.21, 0.40), Color(0.58, 0.44, 0.68), Color(0.91, 0.86, 0.92)), Color.WHITE, 5.0)
		"flow":
			return _glaze(_tex_flow(rng, Color(0.24, 0.62, 0.64), Color(0.10, 0.11, 0.13), Color(0.55, 0.82, 0.80)), Color.WHITE, 3.0)
	return _glaze(null, Color(0.93, 0.71, 0.24), 1.0)


## Porcelain glaze. A pattern texture is tiled in WORLD space by triplanar
## projection so it runs unbroken across the capsule seams of a limb.
static func _glaze(tex: ImageTexture, tint: Color, tiles: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	if tex != null:
		m.albedo_texture = tex
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_triplanar_sharpness = 6.0
		m.uv1_scale = Vector3(tiles, tiles, tiles)
	m.roughness = 0.26
	m.metallic = 0.0
	m.metallic_specular = 0.7
	m.clearcoat_enabled = true
	m.clearcoat = 1.0
	m.clearcoat_roughness = 0.1
	return m


## Blue-and-white: horizontal stripes wobbled by three sines, tileable.
static func _tex_waves(rng: RandomNumberGenerator, ink: Color, paper: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var ph1: float = rng.randf_range(0.0, TAU)
	var ph2: float = rng.randf_range(0.0, TAU)
	var ph3: float = rng.randf_range(0.0, TAU)
	var period: float = 16.0
	var half: float = 0.5 + rng.randf_range(-0.06, 0.06)
	for y: int in range(TEX):
		for x: int in range(TEX):
			var fx: float = float(x) / float(TEX)
			var fy: float = float(y) / float(TEX)
			var wob: float = 3.0 * sin(TAU * 4.0 * fx + ph1) + 1.5 * sin(TAU * 9.0 * fx + TAU * 2.0 * fy + ph2) + 1.0 * sin(TAU * 17.0 * fx + TAU * 3.0 * fy + ph3)
			var v: float = fposmod(float(y) + wob, period) / period
			var d: float = (absf(v - half * 0.5) - half * 0.5) * period
			var mix: float = clampf(d / 1.2 + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, ink.lerp(paper, mix))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Pale green with white filigree: volutes, comma flicks and pearls.
static func _tex_filigree(rng: RandomNumberGenerator, ink: Color, paper: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	img.fill(paper)
	for _k: int in range(9):
		var cx: float = rng.randf_range(0.0, float(TEX))
		var cy: float = rng.randf_range(0.0, float(TEX))
		var sz: float = rng.randf_range(11.0, 22.0)
		var turns: float = rng.randf_range(1.3, 2.0)
		var spin: float = rng.randf_range(0.0, TAU)
		var flip: float = 1.0 if rng.randf() < 0.5 else -1.0
		var steps: int = int(sz * turns * 3.0)
		for i: int in range(steps + 1):
			var f: float = float(i) / float(steps)
			var th: float = spin + flip * f * turns * TAU
			var rad: float = sz * (1.0 - 0.8 * f)
			var w: float = lerpf(2.6, 1.1, f)
			_stamp(img, cx + cos(th) * rad, cy + sin(th) * rad, w, ink)
	for _k: int in range(14):
		var cx: float = rng.randf_range(0.0, float(TEX))
		var cy: float = rng.randf_range(0.0, float(TEX))
		var rad: float = rng.randf_range(6.0, 13.0)
		var spin: float = rng.randf_range(0.0, TAU)
		var sweep: float = rng.randf_range(0.25, 0.45) * TAU
		var steps: int = int(rad * 2.5)
		for i: int in range(steps + 1):
			var f: float = float(i) / float(steps)
			var th: float = spin + f * sweep
			var w: float = lerpf(2.8, 0.6, f)
			_stamp(img, cx + cos(th) * rad, cy + sin(th) * rad, w, ink)
	for _k: int in range(26):
		_stamp(img, rng.randf_range(0.0, float(TEX)), rng.randf_range(0.0, float(TEX)), rng.randf_range(1.2, 2.6), ink)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Mauve scale lattice: fish-scale tiling, concentric bands, dark rim.
static func _tex_scales(rng: RandomNumberGenerator, ink: Color, mid: Color, paper: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var cell_w: float = 32.0
	var row_h: float = 16.0
	var rad: float = 17.6
	var band: float = rng.randf_range(4.2, 5.4)
	var rim: float = 1.5
	for y: int in range(TEX):
		for x: int in range(TEX):
			var col: Color = paper
			var row0: int = int(floor(float(y) / row_h))
			var done: bool = false
			for rr: int in range(row0 + 2, row0 - 3, -1):
				if done:
					break
				var dy: float = float(y) - float(rr) * row_h
				if absf(dy) > rad:
					continue
				var offx: float = 0.0 if posmod(rr, 2) == 0 else cell_w * 0.5
				var c0: int = int(floor((float(x) - offx) / cell_w))
				for cc: int in range(c0, c0 + 2):
					var dx: float = float(x) - ((float(cc) + 0.5) * cell_w + offx)
					var d: float = sqrt(dx * dx + dy * dy)
					if d <= rad:
						done = true
						var edge: float = rad - d
						if edge < rim:
							col = ink
						else:
							var q: float = fposmod(d, band) / band
							if q < 0.42:
								col = mid
							else:
								col = paper
						break
			img.set_pixel(x, y, col)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Teal with black flowing lines: six lanes bent by two sines, a pale halo.
static func _tex_flow(rng: RandomNumberGenerator, base_col: Color, ink: Color, light: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var ph1: float = rng.randf_range(0.0, TAU)
	var ph2: float = rng.randf_range(0.0, TAU)
	var ph3: float = rng.randf_range(0.0, TAU)
	var period: float = float(TEX) / 6.0
	for y: int in range(TEX):
		for x: int in range(TEX):
			var fx: float = float(x) / float(TEX)
			var fy: float = float(y) / float(TEX)
			var f: float = float(x) + 26.0 * sin(TAU * 2.0 * fy + ph1) + 9.0 * sin(TAU * 5.0 * fy + TAU * fx + ph2)
			var v: float = fposmod(f, period)
			var thick: float = 2.2 + 1.4 * sin(TAU * 3.0 * fy + TAU * fx + ph3)
			var col: Color = base_col
			if v < thick:
				col = ink
			elif v < thick + 7.0:
				col = base_col.lerp(light, 0.55 * (1.0 - (v - thick) / 7.0))
			img.set_pixel(x, y, col)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## A filled disc stamped into the image, wrapping at the edges (tileable).
static func _stamp(img: Image, cx: float, cy: float, rad: float, col: Color) -> void:
	var n: int = img.get_width()
	var ir: int = int(ceil(rad))
	var xi: int = int(round(cx))
	var yi: int = int(round(cy))
	for dy: int in range(-ir, ir + 1):
		for dx: int in range(-ir, ir + 1):
			var dd: float = sqrt(float(dx * dx + dy * dy))
			if dd <= rad:
				img.set_pixel(posmod(xi + dx, n), posmod(yi + dy, n), col)
