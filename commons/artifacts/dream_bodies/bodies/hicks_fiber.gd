extends RefCounted

## dream_bodies / hicks_fiber — a white mannequin drowning in Sheila Hicks wool.
##
## Reference: scratchpad/refs/hicks.png (2048x536 panorama) — a wall of fat
## unspun roving heaped in dusty pink, mauve, plum, olive, sage, ochre, slate
## blue and cream, and standing half-buried in it a smooth white shop mannequin:
## bare bald head clear above the pile, one smooth white arm coming out of it,
## the shoulders and chest swallowed by coiled ropes, loose hanks at the base.
##
## Reproduced, and how:
##   1. Fibre IS the mass, the body only shows — 44..66 swept SurfaceTool tubes
##      of 30..56 mm radius carry almost the whole silhouette; the mannequin is
##      a thin core they bury, and only the head and one arm are left clear.
##   2. The mannequin core — featureless egg head (skull + cranium + jaw, no
##      face), an oval torso of 9 spheres on a contrapposto spine each scaled
##      non-uniformly to an oval section, capsule limbs, lacquered off-white
##      with a light clearcoat.
##   3. Three drapes, not a texture — a collar roll over both shoulders that
##      runs down the W arm, a bib heaped down the chest, a heap across the
##      back; ropes are sampled along each polyline with a per-station outward
##      direction, so the yarn sits ON the body instead of floating near it.
##   4. Three rope grammars — a closed ring in the plane perpendicular to the
##      drape (the shoulder roll and the arm sleeve), a closed lemniscate coil
##      lying in the surface tangent plane (the flat heaps), and an open helix
##      winding along a limb — all with per-point radial noise and a varying
##      tube radius, so no two ropes are the same object.
##   5. The sag — every ring is stretched downward below its own centre, so the
##      loops hang like wet wool instead of reading as tidy tori.
##   6. Coiled hanks — 6..14 flat Archimedean spirals wound as tubes, tilted a
##      few degrees, some stacked in a second layer, heaped around the feet so
##      the fibre reaches the ground and the mannequin is planted in it.
##   7. Falling strands — 4..8 open tubes dropping out of the chest heap, easing
##      outward and curling once flat on the floor.
##   8. Roving surface — a 128x128 ImageTexture painted in code: three wrapping
##      sine layers of fibre streak running along the rope (seamless around u)
##      plus a diagonal ply shadow, near-white so albedo_color dyes it,
##      roughness 0.95, zero metallic, no clearcoat. Matte all the way down.
##   9. Dye lot by seed — 5..7 colours drawn from a 14-entry palette (cream and
##      one dusty pink always in), dealt with random multiplicity into 4..6
##      zones per drape, so colour clumps the way a dyed batch clumps.
##
## Given up: the wall of fibre behind the figure (this is one body, not the
## installation), true yarn twist and fly-away fibres, the pink drawn-thread
## drawing at the right edge of the reference, and any suggestion of a face.

const TEX_SIZE: int = 128
const CORE_COLOR: String = "#F2EFE9"

# dusty pink, rose, mauve, plum, olive, sage, ochre, dark ochre,
# slate blue, pale slate, cream, warm grey, deep green, magenta
const PALETTE: Array = [
	"#E2C0BC", "#CFA2A4", "#B2879C", "#8D5F80",
	"#707548", "#A6B598", "#C69B4C", "#8C7038",
	"#7B8AA0", "#A0AEBF", "#EFE6D6", "#CDC4B4",
	"#4F5B41", "#A6417A",
]

const TORSO_R: Array = [0.128, 0.112, 0.100, 0.104, 0.118, 0.128, 0.126, 0.118]
const TORSO_SX: Array = [1.14, 1.14, 1.12, 1.14, 1.18, 1.24, 1.30, 1.32]
const TORSO_SZ: Array = [0.86, 0.84, 0.80, 0.78, 0.76, 0.74, 0.72, 0.70]


static func describe() -> String:
	return "A smooth featureless white mannequin buried to the shoulders in fat ropes of dusty pink, olive, slate and cream wool roving, one bare arm coming clear, coiled hanks heaped at its feet."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# ---- the individual ----------------------------------------------------
	var body_k: float = rng.randf_range(0.95, 1.04)
	var w_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var b_side: float = -w_side
	var hip_shift: float = rng.randf_range(0.010, 0.028) * b_side
	var bow: float = rng.randf_range(-0.016, 0.016)
	var lean_z: float = rng.randf_range(-0.020, 0.014)
	var head_yaw: float = deg_to_rad(rng.randf_range(-24.0, 24.0))
	var head_tilt: float = deg_to_rad(rng.randf_range(-6.0, 11.0))
	var step_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var ply: float = float(rng.randi_range(2, 4))

	var y_hip: float = 0.860
	var y_neck: float = 1.345
	var hip_x: float = hip_shift
	var neck_x: float = -hip_shift * 0.55

	# ---- dye lot -----------------------------------------------------------
	var lot: Array = _dye_lot(rng)
	var deal: Array = []
	for lc in lot:
		var reps: int = rng.randi_range(1, 4)
		for k in range(reps):
			deal.append(lc)
	var cream_code: String = PALETTE[10]
	var cream := Color(cream_code)

	var roving: ImageTexture = _roving_texture(rng, ply)

	var mat_core := StandardMaterial3D.new()
	mat_core.albedo_color = Color(CORE_COLOR)
	mat_core.roughness = 0.32
	mat_core.metallic = 0.0
	mat_core.clearcoat_enabled = true
	mat_core.clearcoat = 0.45
	mat_core.clearcoat_roughness = 0.28

	# ---- the mannequin core ------------------------------------------------
	for i in range(9):
		var t: float = float(i) / 8.0
		var p: Vector3 = _spine(t, hip_x, neck_x, bow, lean_z, y_hip, y_neck)
		var r: float = _key(TORSO_R, t)
		var sph := SphereMesh.new()
		sph.radius = r
		sph.height = r * 2.0
		sph.radial_segments = 20
		sph.rings = 12
		var mi: MeshInstance3D = _add(root, sph, mat_core)
		var sc := Vector3(_key(TORSO_SX, t), 1.0, _key(TORSO_SZ, t))
		mi.transform = Transform3D(Basis().scaled(sc), p)

	var hip_p: Vector3 = _spine(0.0, hip_x, neck_x, bow, lean_z, y_hip, y_neck)
	var top_p: Vector3 = _spine(1.0, hip_x, neck_x, bow, lean_z, y_hip, y_neck)

	var sh_w: Vector3 = top_p + Vector3(w_side * 0.135, 0.022, -0.004)
	var sh_b: Vector3 = top_p + Vector3(b_side * 0.135, -0.008, -0.004)
	for sp in [sh_w, sh_b]:
		var sv: Vector3 = sp
		var sph := SphereMesh.new()
		sph.radius = 0.082
		sph.height = 0.164
		sph.radial_segments = 18
		sph.rings = 10
		var mi: MeshInstance3D = _add(root, sph, mat_core)
		mi.transform = Transform3D(Basis().scaled(Vector3(1.0, 0.86, 0.84)), sv)

	# pelvis blend
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var sph := SphereMesh.new()
		sph.radius = 0.078
		sph.height = 0.156
		sph.radial_segments = 18
		sph.rings = 10
		var mi: MeshInstance3D = _add(root, sph, mat_core)
		mi.transform = Transform3D(Basis().scaled(Vector3(1.0, 0.92, 0.82)), hip_p + Vector3(sd * 0.070, -0.030, 0.0))

	# neck
	_limb(root, Vector3(neck_x, 1.288, lean_z - 0.002), Vector3(neck_x * 0.92, 1.376, lean_z - 0.008), 0.046, mat_core)

	# head — smooth, blank
	var head_c := Vector3(neck_x * 0.88, 1.462, lean_z - 0.006)
	var hb: Basis = Basis(Vector3.UP, head_yaw) * Basis(Vector3.RIGHT, head_tilt)
	var skull := SphereMesh.new()
	skull.radius = 0.094
	skull.height = 0.238
	skull.radial_segments = 24
	skull.rings = 14
	var skull_mi: MeshInstance3D = _add(root, skull, mat_core)
	skull_mi.transform = Transform3D(hb * Basis().scaled(Vector3(0.98, 1.0, 1.06)), head_c)
	var cran := SphereMesh.new()
	cran.radius = 0.084
	cran.height = 0.168
	cran.radial_segments = 20
	cran.rings = 12
	var cran_mi: MeshInstance3D = _add(root, cran, mat_core)
	cran_mi.transform = Transform3D(hb * Basis().scaled(Vector3(0.98, 0.94, 1.0)), head_c + hb * Vector3(0.0, 0.024, 0.030))
	var jaw := SphereMesh.new()
	jaw.radius = 0.064
	jaw.height = 0.128
	jaw.radial_segments = 18
	jaw.rings = 10
	var jaw_mi: MeshInstance3D = _add(root, jaw, mat_core)
	jaw_mi.transform = Transform3D(hb * Basis().scaled(Vector3(0.92, 0.82, 1.02)), head_c + hb * Vector3(0.0, -0.064, -0.020))

	# the bare arm — hangs clear of the fibre
	var el_b := Vector3(b_side * 0.212, 1.020, -0.018)
	var wr_b := Vector3(b_side * 0.234, 0.812, -0.050)
	var hd_b := Vector3(b_side * 0.240, 0.736, -0.062)
	_limb(root, sh_b, el_b, 0.057, mat_core)
	_limb(root, el_b, wr_b, 0.045, mat_core)
	_limb(root, wr_b, hd_b, 0.038, mat_core)
	var hand_b := SphereMesh.new()
	hand_b.radius = 0.050
	hand_b.height = 0.100
	hand_b.radial_segments = 16
	hand_b.rings = 9
	var hb_mi: MeshInstance3D = _add(root, hand_b, mat_core)
	hb_mi.transform = Transform3D(_basis_y_to(hd_b - wr_b) * Basis().scaled(Vector3(0.70, 1.0, 0.46)), hd_b)

	# the buried arm — bent across the front, under the drape
	var el_w := Vector3(w_side * 0.238, 1.035, -0.030)
	var wr_w := Vector3(w_side * 0.150, 0.930, -0.152)
	var hd_w := Vector3(w_side * 0.096, 0.890, -0.192)
	_limb(root, sh_w, el_w, 0.057, mat_core)
	_limb(root, el_w, wr_w, 0.045, mat_core)
	_limb(root, wr_w, hd_w, 0.038, mat_core)
	var hand_w := SphereMesh.new()
	hand_w.radius = 0.048
	hand_w.height = 0.096
	hand_w.radial_segments = 16
	hand_w.rings = 9
	var hw_mi: MeshInstance3D = _add(root, hand_w, mat_core)
	hw_mi.transform = Transform3D(_basis_y_to(hd_w - wr_w) * Basis().scaled(Vector3(0.70, 1.0, 0.46)), hd_w)

	# legs
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var fwd: float = 0.030 if sd == step_side else -0.006
		var hp := hip_p + Vector3(sd * 0.078, -0.036, 0.0)
		var knee := Vector3(sd * 0.076 + hip_shift * 0.3, 0.452, -0.008 - fwd * 0.5)
		var ankle := Vector3(sd * 0.070, 0.116, 0.006 - fwd)
		_limb(root, hp, knee, 0.090, mat_core)
		_limb(root, knee, ankle, 0.062, mat_core)
		var foot := BoxMesh.new()
		foot.size = Vector3(0.086, 0.058, 0.206)
		var fm: MeshInstance3D = _add(root, foot, mat_core)
		fm.transform = Transform3D(Basis(Vector3.UP, sd * 0.16), Vector3(ankle.x, 0.030, ankle.z - 0.052))

	# ---- the three drapes --------------------------------------------------
	var wq: float = w_side
	var drape_a_p: Array = [
		Vector3(-wq * 0.176, 1.242, 0.012),
		Vector3(-wq * 0.118, 1.318, 0.000),
		Vector3(0.0, 1.312, -0.046),
		Vector3(wq * 0.120, 1.326, -0.010),
		Vector3(wq * 0.190, 1.288, -0.006),
		Vector3(wq * 0.234, 1.150, -0.016),
		Vector3(wq * 0.244, 1.030, -0.036),
		Vector3(wq * 0.184, 0.944, -0.126),
		Vector3(wq * 0.114, 0.898, -0.182),
	]
	var drape_a_o: Array = [
		Vector3(-wq * 0.95, 0.30, 0.06),
		Vector3(-wq * 0.55, 0.83, 0.06),
		Vector3(0.0, 0.75, -0.66),
		Vector3(wq * 0.55, 0.83, -0.06),
		Vector3(wq * 0.92, 0.38, -0.06),
		Vector3(wq * 0.97, 0.05, -0.22),
		Vector3(wq * 0.94, -0.06, -0.32),
		Vector3(wq * 0.70, -0.12, -0.70),
		Vector3(wq * 0.40, -0.26, -0.88),
	]
	var drape_a_r: Array = [0.108, 0.140, 0.152, 0.156, 0.148, 0.118, 0.108, 0.100, 0.090]

	var drape_b_p: Array = [
		Vector3(-wq * 0.072, 1.234, -0.096),
		Vector3(0.0, 1.150, -0.122),
		Vector3(wq * 0.056, 1.056, -0.126),
		Vector3(wq * 0.070, 0.964, -0.110),
		Vector3(wq * 0.040, 0.888, -0.084),
	]
	var drape_b_o: Array = [
		Vector3(-wq * 0.30, 0.36, -0.88),
		Vector3(0.0, 0.14, -0.99),
		Vector3(wq * 0.26, 0.0, -0.97),
		Vector3(wq * 0.30, -0.16, -0.94),
		Vector3(wq * 0.16, -0.36, -0.92),
	]
	var drape_b_r: Array = [0.095, 0.105, 0.105, 0.095, 0.078]

	var drape_c_p: Array = [
		Vector3(-wq * 0.116, 1.274, 0.070),
		Vector3(0.0, 1.194, 0.106),
		Vector3(wq * 0.096, 1.100, 0.100),
		Vector3(wq * 0.074, 1.008, 0.074),
	]
	var drape_c_o: Array = [
		Vector3(-wq * 0.40, 0.30, 0.86),
		Vector3(0.0, 0.10, 0.99),
		Vector3(wq * 0.34, 0.0, 0.94),
		Vector3(wq * 0.30, -0.20, 0.93),
	]
	var drape_c_r: Array = [0.090, 0.100, 0.096, 0.082]

	var n_a: int = rng.randi_range(22, 32)
	var n_b: int = rng.randi_range(12, 18)
	var n_c: int = rng.randi_range(10, 16)
	var zones_a: Array = _zones(rng, deal, rng.randi_range(4, 6))
	var zones_b: Array = _zones(rng, deal, rng.randi_range(3, 5))
	var zones_c: Array = _zones(rng, deal, rng.randi_range(3, 5))

	_lay_drape(root, rng, drape_a_p, drape_a_o, drape_a_r, n_a, zones_a, deal, cream, roving, 0.55, 0.62, true)
	_lay_drape(root, rng, drape_b_p, drape_b_o, drape_b_r, n_b, zones_b, deal, cream, roving, 0.0, 0.34, false)
	_lay_drape(root, rng, drape_c_p, drape_c_o, drape_c_r, n_c, zones_c, deal, cream, roving, 0.0, 0.30, false)

	# ---- falling strands ---------------------------------------------------
	var n_fall: int = rng.randi_range(4, 8)
	for i in range(n_fall):
		var u: float = clampf((float(i) + rng.randf_range(0.1, 0.9)) / float(n_fall), 0.0, 1.0)
		var from_bib: bool = rng.randf() < 0.65
		var src: Array = drape_b_p if from_bib else drape_a_p
		var sro: Array = drape_b_o if from_bib else drape_a_o
		var srr: Array = drape_b_r if from_bib else drape_a_r
		var sm: Array = _sample(src, sro, srr, clampf(0.45 + u * 0.5, 0.0, 1.0))
		var start: Vector3 = sm[0]
		var od: Vector3 = sm[1]
		var tube_r: float = rng.randf_range(0.032, 0.050)
		var reach: float = rng.randf_range(0.10, 0.24)
		var curl_r: float = rng.randf_range(0.075, 0.150)
		var path: Array = _fall_path(start + od * 0.06, od, tube_r * 1.10 + 0.004, tube_r, reach, curl_r, rng, 34)
		var col: Color = _dye(deal[rng.randi_range(0, deal.size() - 1)], rng, cream)
		var mesh: ArrayMesh = _tube_mesh(path[0], path[1], 8, false, 0.34)
		_add(root, mesh, _wool(col, roving))

	# ---- coiled hanks heaped at the feet -----------------------------------
	var n_hank: int = rng.randi_range(6, 14)
	for i in range(n_hank):
		var ang: float = TAU * (float(i) + rng.randf_range(-0.35, 0.35)) / float(n_hank)
		var dist: float = rng.randf_range(0.130, 0.320)
		var tube_r: float = rng.randf_range(0.032, 0.050)
		var turns: float = rng.randf_range(2.4, 4.0)
		var r0: float = rng.randf_range(0.030, 0.055)
		var r1: float = rng.randf_range(0.100, 0.150)
		var tilt: float = deg_to_rad(rng.randf_range(0.0, 11.0))
		var tilt_dir: float = rng.randf_range(0.0, TAU)
		var stacked: bool = rng.randf() < 0.28
		var lift: float = 0.052 if stacked else 0.0
		var y0: float = tube_r * 1.42 + r1 * sin(tilt) + 0.004 + lift
		var pts_n: int = int(clampf(turns * 17.0, 30.0, 72.0))
		var path: Array = _hank_path(turns, r0, r1, tube_r, rng, pts_n)
		var hb2: Basis = Basis(Vector3(cos(tilt_dir), 0.0, sin(tilt_dir)).normalized(), tilt) * Basis(Vector3.UP, rng.randf_range(0.0, TAU))
		var mesh: ArrayMesh = _tube_mesh(path[0], path[1], 8, false, 0.34)
		var col: Color = _dye(deal[rng.randi_range(0, deal.size() - 1)], rng, cream)
		var mi: MeshInstance3D = _add(root, mesh, _wool(col, roving))
		mi.transform = Transform3D(hb2, Vector3(cos(ang) * dist, y0, sin(ang) * dist))

	# ---- individual scale, then the measured settle ------------------------
	_scale_all(root, body_k)

	var box: AABB = _union_aabb(root)
	var kx: float = 1.20 / maxf(box.size.x, 0.0001)
	var kz: float = 1.20 / maxf(box.size.z, 0.0001)
	var ky: float = 1.68 / maxf(box.size.y, 0.0001)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		_scale_all(root, kfit)
		box = _union_aabb(root)
	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, -box.position.y, -centre.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + shift)


# ---------------------------------------------------------------------------
# drape laying

static func _lay_drape(root: Node3D, rng: RandomNumberGenerator, ps: Array, os: Array, rs: Array,
		count: int, zones: Array, deal: Array, cream: Color, roving: ImageTexture,
		helix_bias: float, ring_bias: float, arm: bool) -> void:
	for i in range(count):
		var u: float = clampf((float(i) + rng.randf_range(-0.42, 0.42)) / float(maxi(count - 1, 1)), 0.0, 1.0)
		var sm: Array = _sample(ps, os, rs, u)
		var c: Vector3 = sm[0]
		var od: Vector3 = sm[1]
		var rad: float = sm[2]
		var tg: Vector3 = sm[3]

		var layer: int = 0
		var roll: float = rng.randf()
		if roll > 0.56:
			layer = 1
		if roll > 0.86:
			layer = 2
		var lay_f: float = float(layer)
		var centre: Vector3 = c + od * (0.020 + lay_f * 0.040)
		var loop_r: float = rad + lay_f * 0.014 + rng.randf_range(-0.018, 0.016)
		var tube_r: float = rng.randf_range(0.031, 0.056)
		if arm and u > 0.62:
			tube_r = rng.randf_range(0.030, 0.046)

		var zi: int = clampi(int(u * float(zones.size())), 0, zones.size() - 1)
		var base_c: Color = zones[zi]
		if rng.randf() < 0.16:
			base_c = deal[rng.randi_range(0, deal.size() - 1)]
		var col: Color = _dye(base_c, rng, cream)

		var kind: float = rng.randf()
		var path: Array = []
		var closed: bool = true
		if arm and u > 0.58 and kind < helix_bias:
			var turns: float = rng.randf_range(1.15, 2.60)
			var span: float = rng.randf_range(0.090, 0.210)
			path = _helix_path(centre, tg, od, loop_r, tube_r, turns, span, rng, 30)
			closed = false
		elif kind < ring_bias:
			var sag: float = rng.randf_range(0.16, 0.46)
			var drift: float = rng.randf_range(0.010, 0.052)
			# the loop HANGS: drop its centre so the mass falls below the drape line
			var hung: Vector3 = centre - Vector3(0.0, loop_r * 0.30, 0.0)
			path = _ring_path(hung, tg, od, loop_r, tube_r, sag, drift, rng, 22)
		else:
			path = _coil_path(centre, tg, od, loop_r, tube_r, rng, 26)

		var mesh: ArrayMesh = _tube_mesh(path[0], path[1], 8, closed, 0.34)
		_add(root, mesh, _wool(col, roving))


# ---------------------------------------------------------------------------
# rope paths

static func _ring_path(c: Vector3, tg: Vector3, od: Vector3, rad: float, tube_r: float,
		sag: float, drift: float, rng: RandomNumberGenerator, n: int) -> Array:
	var e1: Vector3 = _perp(od, tg)
	var e2: Vector3 = tg.cross(e1).normalized()
	var p1: float = rng.randf_range(0.0, TAU)
	var p2: float = rng.randf_range(0.0, TAU)
	var p3: float = rng.randf_range(0.0, TAU)
	var p4: float = rng.randf_range(0.0, TAU)
	var w1: float = rng.randf_range(0.08, 0.20)
	var w2: float = rng.randf_range(0.05, 0.13)
	var pts: Array = []
	var radii: Array = []
	for j in range(n):
		var th: float = TAU * float(j) / float(n)
		var rr: float = rad * (1.0 + w1 * sin(2.0 * th + p1) + w2 * sin(3.0 * th + p2))
		var p: Vector3 = c + e1 * (rr * cos(th)) + e2 * (rr * sin(th)) + tg * (drift * sin(th + p3))
		if p.y < c.y:
			p = Vector3(p.x, c.y + (p.y - c.y) * (1.0 + sag), p.z)
		pts.append(p)
		radii.append(tube_r * (0.86 + 0.26 * sin(th + p4)))
	return [pts, radii]


static func _coil_path(c: Vector3, tg: Vector3, od: Vector3, rad: float, tube_r: float,
		rng: RandomNumberGenerator, n: int) -> Array:
	var e1: Vector3 = _perp(tg, od)
	var e2: Vector3 = od.cross(e1).normalized()
	var rx: float = rad * rng.randf_range(0.85, 1.30)
	var ry: float = rad * rng.randf_range(0.42, 0.82)
	var lift: float = tube_r * rng.randf_range(0.6, 1.6)
	var ph: float = rng.randf_range(0.0, TAU)
	var p4: float = rng.randf_range(0.0, TAU)
	var pts: Array = []
	var radii: Array = []
	for j in range(n):
		var th: float = TAU * float(j) / float(n)
		var a: float = th + ph
		var p: Vector3 = c + e1 * (rx * sin(a)) + e2 * (ry * sin(2.0 * a)) + od * (lift * (0.55 + 0.45 * cos(2.0 * th)))
		pts.append(p)
		radii.append(tube_r * (0.88 + 0.22 * sin(2.0 * th + p4)))
	return [pts, radii]


static func _helix_path(c: Vector3, tg: Vector3, od: Vector3, rad: float, tube_r: float,
		turns: float, span: float, rng: RandomNumberGenerator, n: int) -> Array:
	var e1: Vector3 = _perp(od, tg)
	var e2: Vector3 = tg.cross(e1).normalized()
	var ph: float = rng.randf_range(0.0, TAU)
	var wob: float = rng.randf_range(0.06, 0.18)
	var pts: Array = []
	var radii: Array = []
	for j in range(n):
		var f: float = float(j) / float(n - 1)
		var th: float = TAU * turns * f + ph
		var rr: float = rad * (1.0 + wob * sin(3.0 * th))
		var p: Vector3 = c + tg * ((f - 0.5) * span) + e1 * (rr * cos(th)) + e2 * (rr * sin(th))
		pts.append(p)
		radii.append(tube_r * (0.90 + 0.20 * sin(1.0 * th)))
	return [pts, radii]


static func _hank_path(turns: float, r0: float, r1: float, tube_r: float,
		rng: RandomNumberGenerator, n: int) -> Array:
	var ph: float = rng.randf_range(0.0, TAU)
	var pts: Array = []
	var radii: Array = []
	for j in range(n):
		var f: float = float(j) / float(n - 1)
		var th: float = TAU * turns * f + ph
		var rr: float = lerpf(r0, r1, f) * (1.0 + 0.07 * sin(3.0 * th))
		var yy: float = tube_r * (0.22 * sin(1.7 * th) + 0.14 * sin(0.6 * th))
		pts.append(Vector3(cos(th) * rr, yy, sin(th) * rr))
		radii.append(tube_r * (0.90 + 0.18 * sin(0.8 * th)))
	return [pts, radii]


static func _fall_path(a: Vector3, od: Vector3, floor_y: float, tube_r: float, reach: float,
		curl_r: float, rng: RandomNumberGenerator, n: int) -> Array:
	var ph: float = rng.randf_range(0.0, TAU)
	var ph2: float = rng.randf_range(0.0, TAU)
	var land := Vector3(a.x + od.x * reach, floor_y, a.z + od.z * reach)
	var drop: int = int(float(n) * 0.58)
	var pts: Array = []
	var radii: Array = []
	for j in range(drop):
		# f never reaches 1.0 — the last drop point must not coincide with `land`,
		# or the ring after it degenerates into zero-area triangles
		var f: float = float(j) / float(maxi(drop, 1))
		var e: float = f * f * 0.55 + f * 0.45
		var p: Vector3 = a.lerp(land, e)
		p.x += 0.014 * sin(f * 7.0 + ph)
		p.z += 0.014 * cos(f * 6.0 + ph)
		p.y = maxf(p.y, floor_y)
		pts.append(p)
		radii.append(tube_r * (0.92 + 0.12 * sin(f * 9.0 + ph)))
	var anchor: Vector3 = Vector3(cos(ph2) * 0.02, 0.0, sin(ph2) * 0.02)
	for j in range(n - drop):
		var f: float = float(j) / float(maxi(n - drop - 1, 1))
		var th: float = TAU * 1.35 * f + ph2
		var rr: float = lerpf(0.02, curl_r, f)
		var p: Vector3 = land + Vector3(cos(th) * rr, 0.0, sin(th) * rr) - anchor
		p.y = floor_y
		pts.append(p)
		radii.append(tube_r * (0.92 + 0.10 * sin(f * 6.0 + ph2)))
	return [pts, radii]


static func _perp(v: Vector3, axis: Vector3) -> Vector3:
	var p: Vector3 = v - axis * v.dot(axis)
	if p.length() < 0.0005:
		p = axis.cross(Vector3.UP)
	if p.length() < 0.0005:
		p = axis.cross(Vector3.RIGHT)
	return p.normalized()


# ---------------------------------------------------------------------------
# swept tube

static func _tube_mesh(pts: Array, radii: Array, sides: int, closed: bool, v_period: float) -> ArrayMesh:
	var n: int = pts.size()
	if n < 3:
		return ArrayMesh.new()

	var tang: Array = []
	for i in range(n):
		var ia: int = posmod(i - 1, n) if closed else maxi(i - 1, 0)
		var ib: int = posmod(i + 1, n) if closed else mini(i + 1, n - 1)
		var pa: Vector3 = pts[ia]
		var pb: Vector3 = pts[ib]
		var d: Vector3 = pb - pa
		if d.length() < 0.00002:
			d = Vector3.UP
		tang.append(d.normalized())

	var nrm: Array = []
	var bnm: Array = []
	var ref: Vector3 = Vector3.UP
	var t0: Vector3 = tang[0]
	if absf(t0.dot(ref)) > 0.9:
		ref = Vector3.RIGHT
	for i in range(n):
		var t: Vector3 = tang[i]
		var pr: Vector3 = _perp(ref, t)
		ref = pr
		nrm.append(pr)
		bnm.append(t.cross(pr).normalized())

	if closed:
		var na: Vector3 = nrm[n - 1]
		var tz: Vector3 = tang[0]
		var pn: Vector3 = na - tz * na.dot(tz)
		if pn.length() > 0.0005:
			pn = pn.normalized()
			var n0: Vector3 = nrm[0]
			var ang: float = atan2(tz.dot(pn.cross(n0)), pn.dot(n0))
			for i in range(n):
				var f: float = float(i) / float(n)
				var ti: Vector3 = tang[i]
				var ni: Vector3 = nrm[i]
				var rot := Basis(ti, ang * f)
				var nv: Vector3 = (rot * ni).normalized()
				nrm[i] = nv
				bnm[i] = ti.cross(nv).normalized()

	var arc: Array = [0.0]
	var acc: float = 0.0
	for i in range(1, n):
		var pa: Vector3 = pts[i]
		var pb: Vector3 = pts[i - 1]
		acc += (pa - pb).length()
		arc.append(acc)
	var p_first: Vector3 = pts[0]
	var p_last: Vector3 = pts[n - 1]
	var wrap_len: float = acc + (p_first - p_last).length()

	var rings: Array = []
	for i in range(n):
		var row: Array = []
		var ct: Vector3 = pts[i]
		var rr: float = radii[i]
		var ni: Vector3 = nrm[i]
		var bi: Vector3 = bnm[i]
		for j in range(sides):
			var a: float = TAU * float(j) / float(sides)
			row.append(ct + ni * (rr * cos(a)) + bi * (rr * sin(a)))
		rings.append(row)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs: int = n if closed else n - 1
	for i in range(segs):
		var i2: int = (i + 1) % n
		var va: float = float(arc[i]) / v_period
		var vb: float = (float(arc[i2]) / v_period) if i2 > i else (wrap_len / v_period)
		var row0: Array = rings[i]
		var row1: Array = rings[i2]
		var qa: Vector3 = pts[i]
		var qb: Vector3 = pts[i2]
		var inside: Vector3 = (qa + qb) * 0.5
		for j in range(sides):
			var j2: int = (j + 1) % sides
			var ua: float = float(j) / float(sides)
			var ub: float = float(j + 1) / float(sides)
			_quad_uv(st, row0[j], row0[j2], row1[j2], row1[j],
				Vector2(ua, va), Vector2(ub, va), Vector2(ub, vb), Vector2(ua, vb), inside)
	if not closed:
		var e0: Vector3 = pts[0]
		var e1: Vector3 = pts[n - 1]
		var d0: Vector3 = tang[0]
		var d1: Vector3 = tang[n - 1]
		_cap(st, rings[0], e0, e0 - d0 * 0.02)
		_cap(st, rings[n - 1], e1, e1 + d1 * 0.02)
	st.generate_normals()
	return st.commit()


static func _quad_uv(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2, inside: Vector3) -> void:
	var n_front: Vector3 = (c - a).cross(b - a)
	var centroid: Vector3 = (a + b + c + d) * 0.25
	if n_front.dot(centroid - inside) >= 0.0:
		st.set_uv(ua)
		st.add_vertex(a)
		st.set_uv(ub)
		st.add_vertex(b)
		st.set_uv(uc)
		st.add_vertex(c)
		st.set_uv(ua)
		st.add_vertex(a)
		st.set_uv(uc)
		st.add_vertex(c)
		st.set_uv(ud)
		st.add_vertex(d)
	else:
		st.set_uv(ua)
		st.add_vertex(a)
		st.set_uv(uc)
		st.add_vertex(c)
		st.set_uv(ub)
		st.add_vertex(b)
		st.set_uv(ua)
		st.add_vertex(a)
		st.set_uv(ud)
		st.add_vertex(d)
		st.set_uv(uc)
		st.add_vertex(c)


static func _cap(st: SurfaceTool, ring: Array, ctr: Vector3, outside: Vector3) -> void:
	var m: int = ring.size()
	for j in range(m):
		var j2: int = (j + 1) % m
		var b: Vector3 = ring[j]
		var c: Vector3 = ring[j2]
		var n_front: Vector3 = (c - ctr).cross(b - ctr)
		if n_front.dot(outside - ctr) >= 0.0:
			st.set_uv(Vector2(0.5, 0.5))
			st.add_vertex(ctr)
			st.set_uv(Vector2(float(j) / float(m), 0.0))
			st.add_vertex(b)
			st.set_uv(Vector2(float(j + 1) / float(m), 0.0))
			st.add_vertex(c)
		else:
			st.set_uv(Vector2(0.5, 0.5))
			st.add_vertex(ctr)
			st.set_uv(Vector2(float(j + 1) / float(m), 0.0))
			st.add_vertex(c)
			st.set_uv(Vector2(float(j) / float(m), 0.0))
			st.add_vertex(b)


# ---------------------------------------------------------------------------
# colour, surface, small helpers

static func _dye_lot(rng: RandomNumberGenerator) -> Array:
	var idx: Array = []
	for i in range(PALETTE.size()):
		idx.append(i)
	for i in range(idx.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var keep: int = idx[i]
		idx[i] = idx[j]
		idx[j] = keep
	var want: int = rng.randi_range(5, 7)
	var warm: int = 0 if rng.randf() < 0.5 else 1
	var picked: Array = [10, warm]
	for v in idx:
		if picked.size() >= want:
			break
		if picked.has(v):
			continue
		picked.append(v)
	var lot: Array = []
	for v in picked:
		var code: String = PALETTE[v]
		lot.append(Color(code))
	return lot


static func _zones(rng: RandomNumberGenerator, deal: Array, n: int) -> Array:
	var zs: Array = []
	for i in range(n):
		zs.append(deal[rng.randi_range(0, deal.size() - 1)])
	return zs


static func _dye(base: Color, rng: RandomNumberGenerator, cream: Color) -> Color:
	var t: float = rng.randf_range(-0.11, 0.16)
	var c: Color = base.lerp(cream, t) if t > 0.0 else base.darkened(-t)
	var g: float = rng.randf_range(0.95, 1.06)
	return Color(clampf(c.r * g, 0.0, 1.0), clampf(c.g * g, 0.0, 1.0), clampf(c.b * g, 0.0, 1.0))


static func _wool(c: Color, tex: ImageTexture) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = tex
	m.roughness = 0.95
	m.metallic = 0.0
	return m


static func _roving_texture(rng: RandomNumberGenerator, ply: float) -> ImageTexture:
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	var ph1: float = rng.randf_range(0.0, TAU)
	var ph2: float = rng.randf_range(0.0, TAU)
	var ph3: float = rng.randf_range(0.0, TAU)
	for y in range(TEX_SIZE):
		var v: float = float(y) / float(TEX_SIZE)
		for x in range(TEX_SIZE):
			var u: float = float(x) / float(TEX_SIZE)
			var fib: float = 0.070 * sin(TAU * (u * 6.0 + 0.10 * sin(TAU * v + ph1)))
			fib += 0.050 * sin(TAU * (u * 11.0 - 0.14 * sin(TAU * v * 2.0 + ph2)))
			fib += 0.032 * sin(TAU * (u * 19.0 + 0.08 * sin(TAU * v * 3.0 + ph3)))
			var band: float = 0.085 * sin(TAU * (u + v * ply))
			var grain: float = rng.randf_range(-0.022, 0.022)
			var s: float = clampf(0.855 + fib + band + grain, 0.52, 1.0)
			img.set_pixel(x, y, Color(s, s * 0.994, s * 0.982))
	return ImageTexture.create_from_image(img)


static func _spine(t: float, hip_x: float, neck_x: float, bow: float, lean_z: float,
		y0: float, y1: float) -> Vector3:
	var x: float = lerpf(hip_x, neck_x, t) + bow * sin(PI * t)
	var y: float = lerpf(y0, y1, t)
	var z: float = lean_z * t - 0.018 * sin(PI * t)
	return Vector3(x, y, z)


static func _key(keys: Array, t: float) -> float:
	var m: int = keys.size() - 1
	var f: float = clampf(t, 0.0, 1.0) * float(m)
	var i: int = int(floor(f))
	if i >= m:
		return float(keys[m])
	var s: float = f - float(i)
	return lerpf(float(keys[i]), float(keys[i + 1]), s)


static func _sample(ps: Array, os: Array, rs: Array, u: float) -> Array:
	var n: int = ps.size()
	var f: float = clampf(u, 0.0, 0.99999) * float(n - 1)
	var i: int = int(floor(f))
	var i2: int = mini(i + 1, n - 1)
	var s: float = f - float(i)
	var pa: Vector3 = ps[i]
	var pb: Vector3 = ps[i2]
	var oa: Vector3 = os[i]
	var ob: Vector3 = os[i2]
	var p: Vector3 = pa.lerp(pb, s)
	var o: Vector3 = (oa.lerp(ob, s)).normalized()
	var r: float = lerpf(float(rs[i]), float(rs[i2]), s)
	var d: Vector3 = pb - pa
	if d.length() < 0.0005:
		var pc: Vector3 = ps[mini(i + 2, n - 1)]
		d = pc - pa
	if d.length() < 0.0005:
		d = Vector3.RIGHT
	return [p, o, r, d.normalized()]


static func _basis_y_to(dir: Vector3) -> Basis:
	var d: Vector3 = dir.normalized()
	var dot_up: float = d.dot(Vector3.UP)
	if dot_up > 0.9999:
		return Basis()
	if dot_up < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	var ax: Vector3 = Vector3.UP.cross(d).normalized()
	var ang: float = acos(clampf(dot_up, -1.0, 1.0))
	return Basis(ax, ang)


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _limb(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.01)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = ln + r * 2.0
	cap.radial_segments = 16
	cap.rings = 5
	var mi: MeshInstance3D = _add(root, cap, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _scale_all(root: Node3D, k: float) -> void:
	if absf(k - 1.0) < 0.0001:
		return
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		var tf: Transform3D = cm.transform
		cm.transform = Transform3D(tf.basis.scaled(Vector3(k, k, k)), tf.origin * k)


static func _union_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		if cm.mesh == null:
			continue
		var wb: AABB = cm.transform * cm.mesh.get_aabb()
		if first:
			box = wb
			first = false
		else:
			box = box.merge(wb)
	return box
