extends RefCounted
## sea_forms — one monochrome walker from the sea-creature panorama.
##
## Reference: scratchpad/refs/sea_forms.png — a 2048x536 panorama of upright, striding
## sea-creature figurines: soft clay bodies with cartoon eyes, long swan necks and small
## beaked heads, segmented beaded tentacle arms (one raised, one trailing), and animal
## skins — zebra bands, honeycomb / giraffe cells, fine dot grids, chains of beads.
## Several of the bodies are pure black-and-white; this builder is the monochrome walker
## between the zebra one and the dotted one, carrying a beaded ball in its arms.
##
## Reproduced, and how:
##   1. The striding biped stance — two legs (CapsuleMesh thigh + shin, a knee sphere) in a
##      stride, flattened SphereMesh feet on the floor, a fat hip sphere. The seed picks the
##      stride length and which side the trailing tentacle and the raised one go.
##   2. The tapered clay torso leaning forward — a CylinderMesh frustum between the hip
##      sphere and a wide shoulder sphere; the lean is seeded.
##   3. The swan neck rising in an S — a chain of shrinking SphereMesh beads laid along a
##      Catmull-Rom spline (forward bow and sideways sway seeded), a head sphere on top with
##      a PrismMesh beak and two cartoon eyes (white sphere + black pupil), the head turned.
##   4. Four segmented tentacles — chains of shrinking beads on splines, spaced by their
##      own radius so they read as strings of beads: two cradle the ball from either
##      shoulder, one rises behind the neck and curls over the head, one trails from the hip
##      and coils on the floor behind as a tail.
##   5. The beaded ball the figures carry — a radiolarian lattice: seven TorusMesh rings
##      (four meridians, an equator and two parallels) tilted by the seed, a dark core
##      sphere, eight CylinderMesh cone spines pointing out through the rings.
##   6. The skins — three ImageTextures painted in code: irregular zebra bands, a fine dot
##      grid (sometimes staggered, sometimes inverted), Voronoi cells with light borders.
##      The seed deals them to torso/legs, neck/head and tentacles, so no two seeds wear
##      the same coat; every skin is black, white and grey only.
##   7. Fin flaps — thin PrismMesh fans: four to six dorsal flaps down the spine, three to
##      five on the crown of the head.
##
## Given up: the panorama's colour (violet, yellow, pink, blue — the brief and its
## strongest bodies are monochrome), the smooth clay blend between limbs (the joints here
## are overlapping primitives), the grass on the floor, and the other eleven bodies.


static func describe() -> String:
	return "A monochrome striding sea-creature: a striped-or-dotted clay body on two thick legs, a swan neck with a beaked two-eyed head, four beaded tentacles cradling a radiolarian lattice ball, fin flaps down its spine."


static func build(root: Node3D, seed: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed

	# ---- palette: greys only ----
	var dk: float = rng.randf_range(0.04, 0.12)
	var lg: float = rng.randf_range(0.86, 0.96)
	var rough: float = rng.randf_range(0.42, 0.58)

	# ---- deal the three skins to torso/legs, neck/head, tentacles ----
	var pats: Array[int] = [0, 1, 2]
	for i in range(2, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = pats[i]
		pats[i] = pats[j]
		pats[j] = tmp
	var tex_body: ImageTexture = _tex_kind(pats[0], rng, dk, lg)
	var tex_neck: ImageTexture = _tex_kind(pats[1], rng, dk, lg)
	var tent_dark: float = rng.randf_range(0.30, 0.50)
	var tex_tent: ImageTexture = _tex_kind(pats[2], rng, tent_dark, 0.92)

	var mat_torso: StandardMaterial3D = _mat_tex(tex_body, 3.0, 1.25, rough)
	var mat_hip: StandardMaterial3D = _mat_tex(tex_body, 2.0, 1.0, rough)
	var mat_leg: StandardMaterial3D = _mat_tex(tex_body, 1.5, 1.5, rough)
	var mat_neck: StandardMaterial3D = _mat_tex(tex_neck, 2.0, 1.0, rough)
	var mat_tent: StandardMaterial3D = _mat_tex(tex_tent, 2.0, 1.0, minf(rough + 0.05, 0.6))
	var mat_white: StandardMaterial3D = _mat_plain(Color(lg, lg, lg), rough)
	var mat_black: StandardMaterial3D = _mat_plain(Color(dk, dk, dk), minf(rough + 0.1, 0.62))
	var mat_eye: StandardMaterial3D = _mat_plain(Color(0.97, 0.97, 0.97), 0.18)
	var mat_pupil: StandardMaterial3D = _mat_plain(Color(0.02, 0.02, 0.02), 0.25)

	# ---- the individual: pose numbers ----
	var side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var lean_x: float = rng.randf_range(-0.08, 0.08)
	var lean_z: float = rng.randf_range(-0.14, -0.04)
	var stride: float = rng.randf_range(0.18, 0.32)
	var body_r: float = rng.randf_range(0.15, 0.18)
	var neck_len: float = rng.randf_range(0.28, 0.36)
	var neck_bow: float = rng.randf_range(0.10, 0.20)
	var neck_sway: float = rng.randf_range(-0.08, 0.08)
	var head_turn: float = rng.randf_range(-40.0, 40.0)
	var ball_x: float = rng.randf_range(-0.08, 0.08)
	var ball_y: float = rng.randf_range(0.66, 0.74)

	var hip: Vector3 = Vector3(0.0, 0.54, 0.0)
	var shoulder: Vector3 = Vector3(lean_x, 0.92, lean_z)

	# ---- legs: left leg steps forward (-z), right leg trails ----
	var leg_x: Array[float] = [-1.0, 1.0]
	for li in range(2):
		var lx: float = leg_x[li]
		var fwd: float = -1.0 if li == 0 else 1.0
		var kz: float = stride * 0.45 if li == 0 else stride * 0.35
		var hj: Vector3 = Vector3(lx * 0.09, 0.47, 0.0)
		var knee: Vector3 = Vector3(lx * 0.10, 0.26, fwd * kz)
		var foot: Vector3 = Vector3(lx * 0.11, 0.045, fwd * stride * 0.5)
		var ankle: Vector3 = foot + Vector3(0.0, 0.03, 0.0)
		_capsule_between(root, hj, knee, 0.072, mat_leg)
		_capsule_between(root, knee, ankle, 0.056, mat_leg)
		_sphere(root, knee, 0.066, mat_leg)
		_mesh_basis(root, _sphere_mesh(0.075), mat_leg, foot, Basis.from_scale(Vector3(1.0, 0.55, 1.35)))

	# ---- hips, torso frustum, shoulders ----
	_sphere(root, hip, body_r, mat_hip)
	var torso: CylinderMesh = CylinderMesh.new()
	torso.bottom_radius = body_r * 0.95
	torso.top_radius = 0.10
	torso.height = hip.distance_to(shoulder)
	torso.radial_segments = 32
	torso.rings = 4
	var torso_b: Basis = _basis_y(shoulder - hip) * Basis.from_scale(Vector3(1.0, 1.0, 0.88))
	_mesh_basis(root, torso, mat_torso, (hip + shoulder) * 0.5, torso_b)
	_mesh_basis(root, _sphere_mesh(0.115), mat_hip, shoulder, Basis.from_scale(Vector3(1.15, 0.9, 0.95)))

	# ---- the swan neck: beads on a spline ----
	var n0: Vector3 = shoulder + Vector3(0.0, 0.05, -0.01)
	var n_pts: Array[Vector3] = [
		n0,
		n0 + Vector3(neck_sway * 0.3, 0.10, -neck_bow * 0.7),
		n0 + Vector3(neck_sway * 0.8, 0.22, -neck_bow),
		n0 + Vector3(neck_sway, neck_len, -neck_bow * 0.35),
	]
	_bead_chain(root, n_pts, 0.072, 0.048, mat_neck, 1.0, 14)
	var head: Vector3 = n_pts[3] + Vector3(neck_sway * 0.1, 0.055, -0.02)

	# ---- head: elongated sphere, prism beak, two cartoon eyes, a crest ----
	var hb: Basis = Basis(Vector3.UP, deg_to_rad(head_turn))
	_mesh_basis(root, _sphere_mesh(0.08), mat_neck, head, hb * Basis.from_scale(Vector3(0.95, 0.9, 1.15)))
	var beak: PrismMesh = PrismMesh.new()
	beak.size = Vector3(0.07, 0.10, 0.034)
	_mesh_basis(root, beak, mat_black, head + hb * Vector3(0.0, -0.012, -0.10), hb * Basis(Vector3.RIGHT, -PI * 0.5))
	for ex: float in [-1.0, 1.0]:
		var ec: Vector3 = head + hb * Vector3(ex * 0.058, 0.022, -0.042)
		_sphere(root, ec, 0.024, mat_eye)
		_sphere(root, ec + hb * Vector3(ex * 0.011, 0.002, -0.015), 0.012, mat_pupil)
	var crest_n: int = rng.randi_range(3, 5)
	var head_right: Vector3 = hb * Vector3.RIGHT
	for ci in range(crest_n):
		var cang: float = deg_to_rad(-30.0 + 100.0 * float(ci) / float(maxi(crest_n - 1, 1)))
		var cd: Vector3 = hb * Vector3(0.0, cos(cang), sin(cang))
		var cfin: PrismMesh = PrismMesh.new()
		var cfl: float = 0.07 - 0.012 * absf(float(ci) - float(crest_n - 1) * 0.5)
		cfin.size = Vector3(0.01, cfl, 0.03)
		_mesh_basis(root, cfin, mat_black, head + cd * 0.075, _basis_xy(head_right, cd))

	# ---- dorsal fin flaps down the spine (back is +z) ----
	var dorsal_n: int = rng.randi_range(4, 6)
	var fd: Vector3 = Vector3(0.0, 0.45, 1.0).normalized()
	for di in range(dorsal_n):
		var dt: float = 0.12 + 0.76 * float(di) / float(dorsal_n - 1)
		var axis_p: Vector3 = hip.lerp(shoulder, dt)
		var rad_t: float = lerpf(body_r * 0.95, 0.10, dt) * 0.88
		var fp: Vector3 = axis_p + Vector3(0.0, 0.0, rad_t - 0.01)
		var dfin: PrismMesh = PrismMesh.new()
		var dfl: float = lerpf(0.10, 0.06, dt)
		dfin.size = Vector3(0.012, dfl, 0.055)
		_mesh_basis(root, dfin, mat_black, fp + fd * dfl * 0.35, _basis_xy(Vector3.RIGHT, fd))

	# ---- the radiolarian ball, held in front of the belly ----
	var ball: Vector3 = Vector3(ball_x, ball_y, -0.34)
	var ball_r: float = 0.14
	var tilt: Basis = Basis(Vector3.RIGHT, deg_to_rad(rng.randf_range(-20.0, 20.0))) * Basis(Vector3.FORWARD, deg_to_rad(rng.randf_range(-25.0, 25.0)))
	var tube: float = 0.011
	var par_off: Array[float] = [0.0, 0.57, -0.57]
	for pl in range(3):
		var off: float = par_off[pl]
		var pr: float = ball_r * sqrt(1.0 - off * off)
		var tor_p: TorusMesh = TorusMesh.new()
		tor_p.inner_radius = pr - tube
		tor_p.outer_radius = pr + tube
		tor_p.rings = 48
		tor_p.ring_segments = 16
		_mesh_basis(root, tor_p, mat_white, ball + tilt * Vector3(0.0, ball_r * off, 0.0), tilt)
	for mi_i in range(4):
		var phi: float = float(mi_i) * PI * 0.25
		var tor_m: TorusMesh = TorusMesh.new()
		tor_m.inner_radius = ball_r - tube
		tor_m.outer_radius = ball_r + tube
		tor_m.rings = 48
		tor_m.ring_segments = 16
		_mesh_basis(root, tor_m, mat_white, ball, tilt * Basis(Vector3.UP, phi) * Basis(Vector3.RIGHT, PI * 0.5))
	_sphere(root, ball, ball_r * 0.36, mat_black)
	for si in range(8):
		var th: float = float(si) * TAU / 8.0 + rng.randf_range(-0.25, 0.25)
		var el: float = rng.randf_range(-0.55, 0.65)
		var sd: Vector3 = tilt * Vector3(cos(el) * cos(th), sin(el), cos(el) * sin(th))
		var spine: CylinderMesh = CylinderMesh.new()
		spine.top_radius = 0.0
		spine.bottom_radius = 0.007
		spine.height = 0.08
		spine.radial_segments = 8
		spine.rings = 1
		_mesh_basis(root, spine, mat_black, ball + sd * (ball_r + 0.035), _basis_y(sd))

	# ---- tentacle A: right shoulder, out, then around the ball and down ----
	var ra: Vector3 = shoulder + Vector3(0.10, -0.01, -0.03)
	var a_pts: Array[Vector3] = [
		ra,
		Vector3(0.30, 0.86, -0.18),
		ball + Vector3(0.18, 0.06, 0.0),
		ball + Vector3(0.0, 0.0, -0.18),
		ball + Vector3(-0.18, -0.06, 0.0),
		ball + Vector3(-0.10, -0.16, 0.10),
		ball + Vector3(0.02, -0.22, 0.04),
	]
	_bead_chain(root, a_pts, 0.055, 0.014, mat_tent, 1.45, 34)

	# ---- tentacle B: left shoulder, down the side, under the ball, curling up in front ----
	var lb: Vector3 = shoulder + Vector3(-0.10, -0.01, -0.03)
	var b_pts: Array[Vector3] = [
		lb,
		ball + Vector3(-0.26, 0.20, 0.14),
		ball + Vector3(-0.19, 0.02, -0.04),
		ball + Vector3(-0.04, -0.18, -0.06),
		ball + Vector3(0.16, -0.09, -0.13),
		ball + Vector3(0.12, 0.09, -0.20),
		ball + Vector3(-0.02, 0.14, -0.21),
	]
	_bead_chain(root, b_pts, 0.055, 0.014, mat_tent, 1.45, 34)

	# ---- tentacle C: the raised one, up behind the neck and over the head ----
	var c_pts: Array[Vector3] = [
		shoulder + Vector3(side * 0.05, 0.05, 0.07),
		shoulder + Vector3(side * 0.15, 0.28, 0.16),
		shoulder + Vector3(side * 0.13, 0.52, 0.02),
		shoulder + Vector3(side * 0.02, 0.60, -0.16),
		shoulder + Vector3(-side * 0.08, 0.52, -0.30),
		shoulder + Vector3(-side * 0.10, 0.40, -0.30),
	]
	_bead_chain(root, c_pts, 0.046, 0.012, mat_tent, 1.5, 32)

	# ---- tentacle D: the tail, lifting off the hip and coiling on the floor behind ----
	var d_pts: Array[Vector3] = [
		hip + Vector3(side * 0.04, -0.03, 0.10),
		Vector3(side * 0.16, 0.40, 0.30),
		Vector3(side * 0.27, 0.22, 0.42),
		Vector3(side * 0.16, 0.05, 0.48),
		Vector3(-side * 0.06, 0.045, 0.43),
		Vector3(-side * 0.15, 0.04, 0.28),
	]
	_bead_chain(root, d_pts, 0.06, 0.03, mat_tent, 1.4, 28)


# ----------------------------------------------------------------------------------------------
# skins
# ----------------------------------------------------------------------------------------------

static func _tex_kind(kind: int, rng: RandomNumberGenerator, dark: float, light: float) -> ImageTexture:
	if kind == 0:
		return _tex_stripes(rng, dark, light)
	if kind == 1:
		return _tex_dots(rng, dark, light)
	return _tex_cells(rng, dark, light)


## Irregular zebra bands: horizontal stripes whose edges wobble along u and whose
## width swells and thins, all periodic so the tile is seamless.
static func _tex_stripes(rng: RandomNumberGenerator, dark: float, light: float) -> ImageTexture:
	var w: int = 128
	var h: int = 128
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGB8)
	var bands: float = float(rng.randi_range(5, 8))
	var wob: float = rng.randf_range(1.5, 3.5)
	var wob2: float = float(rng.randi_range(1, 2))
	var phase: float = rng.randf_range(0.0, TAU)
	var duty: float = rng.randf_range(-0.15, 0.25)
	var swell: float = rng.randf_range(0.15, 0.35)
	for y in range(h):
		for x in range(w):
			var u: float = float(x) / float(w)
			var v: float = float(y) / float(h)
			var wave: float = sin(u * TAU + phase) * 0.35 + sin(u * TAU * 2.0 + v * TAU * wob2) * 0.2
			var s: float = sin(v * TAU * bands + wave * wob)
			var thr: float = duty + swell * sin(u * TAU * 2.0 + phase * 0.5)
			var g: float = light if s > thr else dark
			img.set_pixel(x, y, Color(g, g, g))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## A fine dot grid, 16 or 32 dots per tile, sometimes staggered, sometimes inverted.
static func _tex_dots(rng: RandomNumberGenerator, dark: float, light: float) -> ImageTexture:
	var w: int = 256
	var h: int = 256
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGB8)
	var cells: int = 16 if rng.randf() < 0.5 else 32
	var cell: float = float(w) / float(cells)
	var rad: float = cell * rng.randf_range(0.22, 0.34)
	var stagger: bool = rng.randf() < 0.6
	var invert: bool = rng.randf() < 0.3
	var ink: float = light if invert else dark
	var paper: float = dark if invert else light
	for y in range(h):
		for x in range(w):
			var fx: float = float(x) + 0.5
			var fy: float = float(y) + 0.5
			var row: int = int(floor(fy / cell))
			if stagger and (row % 2) == 1:
				fx += cell * 0.5
			var cx: float = fposmod(fx, cell) - cell * 0.5
			var cy: float = fposmod(fy, cell) - cell * 0.5
			var d: float = sqrt(cx * cx + cy * cy)
			var g: float = ink if d < rad else paper
			img.set_pixel(x, y, Color(g, g, g))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Voronoi cells with light borders on dark fill — the giraffe / honeycomb skin.
## Distances wrap toroidally so the tile is seamless.
static func _tex_cells(rng: RandomNumberGenerator, dark: float, light: float) -> ImageTexture:
	var w: int = 96
	var h: int = 96
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGB8)
	var n: int = rng.randi_range(18, 28)
	var seeds: Array[Vector2] = []
	for i in range(n):
		seeds.append(Vector2(rng.randf() * float(w), rng.randf() * float(h)))
	var border: float = rng.randf_range(2.0, 3.4)
	var fw: float = float(w)
	var fh: float = float(h)
	for y in range(h):
		for x in range(w):
			var px: float = float(x) + 0.5
			var py: float = float(y) + 0.5
			var d1: float = 1.0e9
			var d2: float = 1.0e9
			for s: Vector2 in seeds:
				var dx: float = absf(px - s.x)
				var dy: float = absf(py - s.y)
				dx = minf(dx, fw - dx)
				dy = minf(dy, fh - dy)
				var d: float = sqrt(dx * dx + dy * dy)
				if d < d1:
					d2 = d1
					d1 = d
				elif d < d2:
					d2 = d
			var g: float = light if (d2 - d1) < border else dark
			img.set_pixel(x, y, Color(g, g, g))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# ----------------------------------------------------------------------------------------------
# materials
# ----------------------------------------------------------------------------------------------

static func _mat_tex(tex: Texture2D, su: float, sv: float, rough: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 1.0, 1.0)
	m.albedo_texture = tex
	m.uv1_scale = Vector3(su, sv, 1.0)
	m.roughness = rough
	m.metallic = 0.0
	m.clearcoat_enabled = true
	m.clearcoat = 0.25
	m.clearcoat_roughness = 0.4
	return m


static func _mat_plain(col: Color, rough: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = 0.0
	m.clearcoat_enabled = true
	m.clearcoat = 0.2
	m.clearcoat_roughness = 0.4
	return m


# ----------------------------------------------------------------------------------------------
# curves and bead chains
# ----------------------------------------------------------------------------------------------

## Catmull-Rom through pts, t in [0, 1] over the whole chain, ends clamped.
static func _spline(pts: Array[Vector3], t: float) -> Vector3:
	var n: int = pts.size()
	if n == 0:
		return Vector3.ZERO
	if n == 1:
		return pts[0]
	var seg_count: int = n - 1
	var ft: float = clampf(t, 0.0, 0.9999) * float(seg_count)
	var i: int = int(floor(ft))
	var u: float = ft - float(i)
	var p0: Vector3 = pts[maxi(i - 1, 0)]
	var p1: Vector3 = pts[i]
	var p2: Vector3 = pts[mini(i + 1, n - 1)]
	var p3: Vector3 = pts[mini(i + 2, n - 1)]
	var a: Vector3 = p1 * 2.0
	var b: Vector3 = (p2 - p0) * u
	var c: Vector3 = (p0 * 2.0 - p1 * 5.0 + p2 * 4.0 - p3) * (u * u)
	var d: Vector3 = (p1 * 3.0 - p0 - p2 * 3.0 + p3) * (u * u * u)
	return (a + b + c + d) * 0.5


## Walks the spline and returns the t of each bead: a bead is dropped whenever the arc
## since the last one reaches k times the bead's own radius (radius shrinks r0 -> r1).
static func _chain_ts(pts: Array[Vector3], r0: float, r1: float, k: float) -> Array[float]:
	var ts: Array[float] = []
	var steps: int = 720
	var last: Vector3 = _spline(pts, 0.0)
	var acc: float = 0.0
	ts.append(0.0)
	for i in range(1, steps + 1):
		var t: float = float(i) / float(steps)
		var p: Vector3 = _spline(pts, t)
		acc += p.distance_to(last)
		last = p
		var r: float = lerpf(r0, r1, t)
		if acc >= r * k:
			ts.append(t)
			acc = 0.0
	return ts


## A string of shrinking sphere beads along a spline. If the chain would need more than
## max_beads, the spacing is widened until it fits, so the mesh budget holds for any seed.
## No bead sinks below the floor.
static func _bead_chain(root: Node3D, pts: Array[Vector3], r0: float, r1: float, mat: Material, k: float, max_beads: int) -> void:
	var kk: float = k
	var ts: Array[float] = _chain_ts(pts, r0, r1, kk)
	var guard: int = 0
	while ts.size() > max_beads and guard < 6:
		kk *= float(ts.size()) / float(max_beads) * 1.06
		ts = _chain_ts(pts, r0, r1, kk)
		guard += 1
	for t: float in ts:
		var r: float = lerpf(r0, r1, t)
		var p: Vector3 = _spline(pts, t)
		p.y = maxf(p.y, r)
		_sphere(root, p, r, mat)


# ----------------------------------------------------------------------------------------------
# primitives and placement
# ----------------------------------------------------------------------------------------------

static func _sphere_mesh(r: float) -> SphereMesh:
	var sm: SphereMesh = SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 24
	sm.rings = 12
	return sm


static func _sphere(root: Node3D, pos: Vector3, r: float, mat: Material) -> MeshInstance3D:
	return _mesh(root, _sphere_mesh(r), mat, pos, Vector3.ZERO)


static func _capsule_between(root: Node3D, a: Vector3, b: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var cm: CapsuleMesh = CapsuleMesh.new()
	cm.radius = r
	cm.height = a.distance_to(b) + r * 2.0
	cm.radial_segments = 24
	cm.rings = 8
	return _mesh_basis(root, cm, mat, (a + b) * 0.5, _basis_y(b - a))


## A right-handed basis whose y axis points along dir; x and z are any perpendicular pair.
static func _basis_y(dir: Vector3) -> Basis:
	var d: Vector3 = dir.normalized()
	var helper: Vector3 = Vector3.UP if absf(d.y) < 0.98 else Vector3.RIGHT
	var xa: Vector3 = helper.cross(d).normalized()
	var za: Vector3 = xa.cross(d).normalized()
	return Basis(xa, d, za)


## A right-handed basis from a wanted x axis and a wanted y axis (x is re-squared to y).
static func _basis_xy(xa: Vector3, ya: Vector3) -> Basis:
	var ay: Vector3 = ya.normalized()
	var az: Vector3 = xa.normalized().cross(ay).normalized()
	var ax: Vector3 = ay.cross(az).normalized()
	return Basis(ax, ay, az)


static func _mesh(root: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot_deg: Vector3) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	root.add_child(mi)
	return mi


static func _mesh_basis(root: Node3D, mesh: Mesh, mat: Material, pos: Vector3, b: Basis) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = Transform3D(b, pos)
	root.add_child(mi)
	return mi
