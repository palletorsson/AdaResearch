extends RefCounted

## dream_bodies / hokusai_kimono — one ukiyo-e kimono figure, caught mid-turn.
##
## Reference: scratchpad/refs/hokusai.png (2048x536 panorama) — a frieze of
## kabuki figures in flowing kimono, painted flat and graphic: robes covered in
## indigo-on-white patterns (Hokusai wave combs, seigaiha arcs, peony scatter,
## big rounded blobs, key-fret meander) and one figure in bold red-and-white
## stripes; white mask faces with black lacquer hair and red kumadori brush
## lines; wide furisode sleeves flying out sideways as the bodies twist.
##
## Reproduced, and how:
##   1. The robe as one wrapped cloth — a SurfaceTool loft, 20 levels x 24
##      angles, superelliptical cross-section (|cos|^0.82, so the silhouette is
##      graphic rather than round), square kimono shoulders, cinched waist,
##      flaring to the floor. Vertical fold ridges grow with depth down the
##      skirt, and the whole section YAWS as it descends, so the skirt trails
##      the turn of the shoulders.
##   2. The cloth pattern, painted in code and chosen by seed — six 128x128
##      ImageTextures: wave combs (ink bands with a white spine), seigaiha
##      (nearest-lower-centre arc lattice), peony scatter (lobed R(theta)
##      flowers with ink outlines), key-fret meander (mirrored spiral cells),
##      red-and-white curved stripes, and rounded indigo blobs (metaball field).
##      All tile seamlessly; explicit UVs on the lofts, triplanar on the tubes.
##   3. Two wide furisode sleeves — SurfaceTool slabs (two offset sheets plus a
##      rim) with a drop profile that rounds the outer bottom corner, a bulge
##      ripple and one gaussian CREASE running down the panel. One sleeve is
##      thrown out and up on the turn; the other hangs and trails.
##   4. The crossed collar — two four-segment bands laid over the chest in a V
##      down to the obi, each with indigo piping boxes on both edges, the
##      leading side offset forward so the crossing reads.
##   5. The obi — ten boxes wrapped round the waist ellipse, a three-box knot at
##      the back, and a twelve-bead obi-jime cord, in a seeded sash colour.
##   6. The mask face — a flattened white sphere, slit black eyes and brows, a
##      small red mouth, and four red kumadori strokes swept up off the nose.
##   7. Lacquer hair — a cap of ~26 small spheres over the back and crown, two
##      flattened side wings (tabo), a four-sphere mage bun and two kanzashi
##      pins.
##   8. A hem lining band — sixteen boxes riding the rippled hem ring, so the
##      contrasting under-cloth shows at the floor.
##
## Given up: hands and fingers past a sphere and a knuckle box, the second and
## third figures of the frieze, the pine and maple ground, the gold obi
## brocade's own woven pattern, and the paper's visible tooth.

const TEX: int = 128


static func describe() -> String:
	return "An ukiyo-e kimono figure caught mid-turn, one wide furisode sleeve thrown out, the robe a single flaring cloth printed in code-painted indigo pattern, above a white mask face with red kumadori strokes."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- individual -----------------------------------------------------------
	var kind: int = rng.randi_range(0, 5)
	var hk: float = rng.randf_range(0.97, 1.045)
	var bk: float = rng.randf_range(0.97, 1.04)
	var turn: float = deg_to_rad(rng.randf_range(-26.0, 26.0))
	var swing: float = deg_to_rad(rng.randf_range(-34.0, 34.0))
	var thrown: float = 1.0 if rng.randf() < 0.5 else -1.0
	var fold_amp: float = rng.randf_range(0.030, 0.058)
	var n_folds: int = rng.randi_range(7, 11)
	var fold_ph: float = rng.randf_range(0.0, TAU)
	var sway_x: float = rng.randf_range(-0.035, 0.035)
	var sway_z: float = rng.randf_range(-0.030, 0.030)
	var hem_wave: float = rng.randf_range(0.010, 0.026)
	var head_yaw: float = turn * 1.5 + deg_to_rad(rng.randf_range(-10.0, 10.0))
	var head_pitch: float = deg_to_rad(rng.randf_range(-9.0, 5.0))
	var head_roll: float = deg_to_rad(rng.randf_range(-7.0, 7.0))
	var crease_u: float = rng.randf_range(0.34, 0.58)

	# --- palette --------------------------------------------------------------
	var cloth_tex: ImageTexture = _pattern(kind, rng)
	var obi_set: Array = [Color("#C0A263"), Color("#8B2A2A"), Color("#1C1B24"), Color("#6F7F62"), Color("#2A3F86")]
	var col_obi: Color = obi_set[rng.randi_range(0, obi_set.size() - 1)]
	var col_lining: Color = Color("#8E2A26") if kind != 4 else Color("#22357A")
	var col_hair := Color("#12111A")
	var col_skin := Color("#F7F2E6")
	var col_red := Color("#BE372C")
	var col_collar := Color("#FBF7ED")
	var col_pipe := Color("#22357A")

	var mat_cloth := StandardMaterial3D.new()
	mat_cloth.albedo_color = Color(1.0, 1.0, 1.0)
	mat_cloth.albedo_texture = cloth_tex
	mat_cloth.roughness = 0.74
	mat_cloth.metallic = 0.0
	mat_cloth.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mat_cloth_tri := StandardMaterial3D.new()
	mat_cloth_tri.albedo_color = Color(1.0, 1.0, 1.0)
	mat_cloth_tri.albedo_texture = cloth_tex
	mat_cloth_tri.roughness = 0.74
	mat_cloth_tri.uv1_triplanar = true
	mat_cloth_tri.uv1_scale = Vector3(5.3, 5.3, 5.3)

	var mat_obi: StandardMaterial3D = _flat(col_obi, 0.52)
	mat_obi.clearcoat_enabled = true
	mat_obi.clearcoat = 0.30
	var mat_lining: StandardMaterial3D = _flat(col_lining, 0.62)
	var mat_collar: StandardMaterial3D = _flat(col_collar, 0.66)
	var mat_pipe: StandardMaterial3D = _flat(col_pipe, 0.55)
	var mat_skin: StandardMaterial3D = _flat(col_skin, 0.52)
	mat_skin.clearcoat_enabled = true
	mat_skin.clearcoat = 0.22
	var mat_hair: StandardMaterial3D = _flat(col_hair, 0.18)
	mat_hair.clearcoat_enabled = true
	mat_hair.clearcoat = 0.85
	mat_hair.clearcoat_roughness = 0.12
	var mat_red: StandardMaterial3D = _flat(col_red, 0.45)
	var mat_ink: StandardMaterial3D = _flat(Color("#100F16"), 0.30)
	var mat_bone: StandardMaterial3D = _flat(Color("#E8DEC6"), 0.42)
	var mat_under: StandardMaterial3D = _flat(Color("#5A5764"), 0.80)

	# --- body frame -----------------------------------------------------------
	var up := Vector3.UP
	var rgt := Vector3(cos(turn), 0.0, -sin(turn))
	var bck := Vector3(sin(turn), 0.0, cos(turn))

	var y_hem: float = 0.008
	var y_top: float = 1.262 * hk
	var y_waist: float = 0.925 * hk
	var y_neck: float = 1.252 * hk
	var y_head: float = 1.428 * hk
	var y_hip: float = 0.800 * hk

	# --- the robe: a lofted wrapped cloth -------------------------------------
	var kx: Array = [0.150, 0.214, 0.212, 0.202, 0.190, 0.188, 0.200, 0.232, 0.278, 0.330, 0.372]
	var kz: Array = [0.092, 0.132, 0.132, 0.126, 0.120, 0.120, 0.130, 0.156, 0.196, 0.234, 0.266]
	var lev: Array = [0.0, 0.02, 0.045, 0.075, 0.11, 0.15, 0.20, 0.25, 0.31, 0.37, 0.43, 0.49, 0.55, 0.61, 0.67, 0.73, 0.79, 0.86, 0.93, 1.0]
	var n_ang: int = 24
	var hem_yaw: float = turn + swing

	var rings: Array = []
	for k in range(lev.size()):
		var t: float = float(lev[k])
		var yy: float = lerpf(y_top, y_hem, t)
		var rxx: float = _profile(t, kx) * bk
		var rzz: float = _profile(t, kz) * bk
		var yw: float = lerpf(turn, hem_yaw, pow(t, 1.15))
		var cs: float = cos(yw)
		var sn: float = sin(yw)
		var ox: float = sway_x * sin(PI * t * 0.85)
		var oz: float = sway_z * sin(PI * t * 0.70)
		var row: Array = []
		for j in range(n_ang):
			var th: float = TAU * float(j) / float(n_ang)
			var ripple: float = 1.0 + fold_amp * pow(t, 1.5) * sin(float(n_folds) * th + fold_ph)
			var ripz: float = 1.0 + fold_amp * pow(t, 1.5) * sin(float(n_folds) * th + fold_ph + 1.15)
			var lx: float = rxx * ripple * _sgnpow(cos(th), 0.82)
			var lz: float = rzz * ripz * _sgnpow(sin(th), 0.82)
			var px: float = ox + lx * cs + lz * sn
			var pz: float = oz - lx * sn + lz * cs
			var py: float = yy + hem_wave * pow(t, 3.0) * sin(2.0 * th + fold_ph * 0.4)
			row.append(Vector3(px, py, pz))
		rings.append(row)

	var robe: ArrayMesh = _loft_mesh(rings, lev, 6.0, 6.5)
	var robe_mi: MeshInstance3D = _add(root, robe, mat_cloth)
	robe_mi.transform = Transform3D(Basis(), Vector3.ZERO)

	# hem lining band riding the rippled hem ring
	var hem_row: Array = rings[rings.size() - 1]
	var hem_c: Vector3 = _row_centre(hem_row)
	var hem_per: float = 0.0
	for j in range(n_ang):
		var pa: Vector3 = hem_row[j]
		var pb: Vector3 = hem_row[(j + 1) % n_ang]
		hem_per += pa.distance_to(pb)
	var band_w: float = hem_per / 16.0 * 1.30
	for j in range(16):
		var jf: float = float(j) / 16.0 * float(n_ang)
		var ja: int = int(floor(jf)) % n_ang
		var jb: int = (ja + 1) % n_ang
		var fmix: float = jf - floor(jf)
		var pa2: Vector3 = hem_row[ja]
		var pb2: Vector3 = hem_row[jb]
		var pm: Vector3 = pa2.lerp(pb2, fmix)
		var radial := Vector3(pm.x - hem_c.x, 0.0, pm.z - hem_c.z)
		if radial.length() < 0.001:
			radial = Vector3.BACK
		var zv: Vector3 = radial.normalized()
		var xv: Vector3 = up.cross(zv).normalized()
		var ring_p: Vector3 = hem_c + radial * 1.014
		_box(root, Vector3(ring_p.x, 0.058, ring_p.z), xv, up, zv, Vector3(band_w, 0.100, 0.020), mat_lining)

	# --- body under the cloth -------------------------------------------------
	_capsule(root, Vector3(0.0, y_hip - 0.02, 0.0), Vector3(0.0, y_top - 0.06, 0.0) + bck * 0.01, 0.125 * bk, mat_under)
	_capsule(root, Vector3(0.0, y_hip - 0.10, 0.0), Vector3(0.0, y_waist, 0.0), 0.135 * bk, mat_under)
	_capsule(root, rgt * (-0.06) + Vector3(0.0, y_hip, 0.0), rgt * (-0.05) + Vector3(0.0, 0.10, 0.0), 0.055, mat_under)
	_capsule(root, rgt * 0.06 + Vector3(0.0, y_hip, 0.0), rgt * 0.05 + Vector3(0.0, 0.10, 0.0), 0.055, mat_under)
	for si in range(2):
		var sfoot: float = -1.0 if si == 0 else 1.0
		var fp: Vector3 = rgt * (sfoot * 0.055) - bck * 0.235 + Vector3(0.0, 0.026, 0.0)
		_box(root, fp, rgt, up, bck, Vector3(0.078, 0.052, 0.130), mat_collar)

	# neck
	_capsule(root, Vector3(0.0, y_neck - 0.02, 0.0) - bck * 0.012, Vector3(0.0, y_neck + 0.082, 0.0) - bck * 0.020, 0.042 * bk, mat_skin)

	# --- sleeves --------------------------------------------------------------
	var sh_half: float = 0.205 * bk
	var y_sh: float = y_top - 0.030
	var dkeys: Array = [0.34, 0.66, 0.88, 0.98, 1.0, 1.0, 0.97, 0.86, 0.62]
	for si in range(2):
		var sd: float = -1.0 if si == 0 else 1.0
		var is_out: bool = (sd == thrown)
		var sh_pt: Vector3 = Vector3(0.0, y_sh, 0.0) + rgt * (sd * sh_half) - bck * 0.010
		var along: Vector3
		var drop: Vector3
		var len_a: float
		var len_d: float
		if is_out:
			along = (rgt * (sd * 0.90) + up * 0.34 - bck * 0.20).normalized()
			drop = (rgt * (sd * 0.34) - up * 0.88 + bck * 0.30).normalized()
			len_a = 0.250 * bk
			len_d = 0.470 * hk
		else:
			along = (rgt * (sd * 0.80) - up * 0.36 + bck * 0.14).normalized()
			drop = (rgt * (sd * 0.07) - up * 0.99 + bck * 0.06).normalized()
			len_a = 0.230 * bk
			len_d = 0.560 * hk
		var nrm: Vector3 = along.cross(drop).normalized()
		var bulge: float = 0.030 if is_out else 0.022
		var sleeve: ArrayMesh = _sleeve_mesh(sh_pt, along, drop, nrm, len_a, len_d, dkeys, 0.026, bulge, crease_u, 1.4, 2.7)
		var sm: MeshInstance3D = _add(root, sleeve, mat_cloth)
		sm.transform = Transform3D(Basis(), Vector3.ZERO)

		# the arm inside the sleeve, a cuff and a hand at its mouth
		var wrist: Vector3 = sh_pt + along * (len_a * 0.94)
		_taper(root, sh_pt, wrist, 0.062 * bk, 0.040 * bk, mat_cloth_tri)
		var cuff := TorusMesh.new()
		cuff.inner_radius = 0.036
		cuff.outer_radius = 0.050
		cuff.rings = 10
		cuff.ring_segments = 8
		var cm: MeshInstance3D = _add(root, cuff, mat_lining)
		cm.transform = Transform3D(_basis_y_to(along), wrist)
		var hand := SphereMesh.new()
		hand.radius = 0.036
		hand.height = 0.072
		hand.radial_segments = 12
		hand.rings = 8
		var hm: MeshInstance3D = _add(root, hand, mat_skin)
		var hand_pt: Vector3 = sh_pt + along * (len_a * 1.03)
		hm.transform = Transform3D(Basis().scaled(Vector3(1.0, 0.82, 1.15)), hand_pt)
		var kn_y: Vector3 = along
		var kn_z: Vector3 = (up - kn_y * up.dot(kn_y)).normalized()
		var kn_x: Vector3 = kn_y.cross(kn_z).normalized()
		_box(root, hand_pt + along * 0.030 - up * 0.012, kn_x, kn_y, kn_z, Vector3(0.048, 0.052, 0.024), mat_skin)

	# --- crossed collar -------------------------------------------------------
	for si in range(2):
		var sd2: float = -1.0 if si == 0 else 1.0
		var lead: float = -0.010 if sd2 == thrown else 0.0
		var pl: Array = [
			Vector3(sd2 * 0.052, y_neck + 0.048, 0.082),
			Vector3(sd2 * 0.120, y_neck + 0.012, -0.022),
			Vector3(sd2 * 0.126, y_neck - 0.105, -0.145 + lead),
			Vector3(sd2 * 0.086, y_neck - 0.220, -0.152 + lead),
			Vector3(sd2 * 0.030, y_neck - 0.312, -0.140 + lead),
		]
		for k in range(4):
			var la: Vector3 = pl[k]
			var lb: Vector3 = pl[k + 1]
			var wa: Vector3 = Vector3(0.0, la.y, 0.0) + rgt * (la.x * bk) + bck * (la.z * bk)
			var wb: Vector3 = Vector3(0.0, lb.y, 0.0) + rgt * (lb.x * bk) + bck * (lb.z * bk)
			var mid_w: Vector3 = (wa + wb) * 0.5
			var out_d := Vector3(mid_w.x, 0.0, mid_w.z)
			if out_d.length() < 0.001:
				out_d = -bck
			_seg_box(root, wa, wb, out_d.normalized(), 0.058 * bk, 0.020, mat_collar)
			_seg_box(root, wa, wb, out_d.normalized(), 0.013, 0.022, mat_pipe, 0.030 * bk)
			_seg_box(root, wa, wb, out_d.normalized(), 0.013, 0.022, mat_pipe, -0.030 * bk)

	# --- obi ------------------------------------------------------------------
	var obi_rx: float = 0.200 * bk
	var obi_rz: float = 0.136 * bk
	var obi_w: float = (TAU * (obi_rx + obi_rz) * 0.5) / 10.0 * 1.32
	for j in range(10):
		var th2: float = TAU * float(j) / 10.0
		var lxo: float = obi_rx * cos(th2)
		var lzo: float = obi_rz * sin(th2)
		var wpt: Vector3 = Vector3(0.0, y_waist, 0.0) + rgt * lxo + bck * lzo
		var nlo := Vector3(cos(th2) / obi_rx, 0.0, sin(th2) / obi_rz)
		nlo = nlo.normalized()
		var zvo: Vector3 = (rgt * nlo.x + bck * nlo.z).normalized()
		var xvo: Vector3 = up.cross(zvo).normalized()
		_box(root, wpt, xvo, up, zvo, Vector3(obi_w, 0.158 * hk, 0.032), mat_obi)
	# obi-jime cord
	for j in range(12):
		var th3: float = TAU * float(j) / 12.0
		var cpt: Vector3 = Vector3(0.0, y_waist + 0.022, 0.0) + rgt * (obi_rx * 1.06 * cos(th3)) + bck * (obi_rz * 1.06 * sin(th3))
		var bead := SphereMesh.new()
		bead.radius = 0.016
		bead.height = 0.032
		bead.radial_segments = 10
		bead.rings = 6
		var bm2: MeshInstance3D = _add(root, bead, mat_red)
		bm2.transform = Transform3D(Basis().scaled(Vector3(1.4, 0.8, 1.0)), cpt)
	# knot at the back
	var knot_c: Vector3 = Vector3(0.0, y_waist + 0.030, 0.0) + bck * (obi_rz + 0.070)
	_box(root, knot_c, rgt, up, bck, Vector3(0.150, 0.130, 0.090), mat_obi)
	_box(root, knot_c + rgt * 0.115 + up * 0.020, rgt, up, bck, Vector3(0.110, 0.086, 0.062), mat_obi)
	_box(root, knot_c - rgt * 0.115 - up * 0.012, rgt, up, bck, Vector3(0.110, 0.086, 0.062), mat_obi)

	# --- head -----------------------------------------------------------------
	var hb: Basis = Basis(Vector3.UP, head_yaw) * Basis(Vector3.RIGHT, head_pitch) * Basis(Vector3.FORWARD, head_roll)
	var h_org := Vector3(0.0, y_head, 0.0) - bck * 0.026
	var face := SphereMesh.new()
	face.radius = 0.098 * bk
	face.height = 0.196 * bk
	face.radial_segments = 20
	face.rings = 12
	var fm: MeshInstance3D = _add(root, face, mat_skin)
	fm.transform = Transform3D(hb * Basis().scaled(Vector3(1.0, 1.13, 0.94)), h_org)

	var rf: float = 0.098 * bk
	# slit eyes and brows
	for si in range(2):
		var se: float = -1.0 if si == 0 else 1.0
		var eb: Basis = hb * Basis(Vector3.FORWARD, se * deg_to_rad(11.0))
		var ep: Vector3 = h_org + hb * Vector3(se * rf * 0.40, rf * 0.10, -rf * 0.87)
		var em := BoxMesh.new()
		em.size = Vector3(rf * 0.34, rf * 0.062, rf * 0.055)
		var emi: MeshInstance3D = _add(root, em, mat_ink)
		emi.transform = Transform3D(eb, ep)
		var bb: Basis = hb * Basis(Vector3.FORWARD, se * deg_to_rad(17.0))
		var bp: Vector3 = h_org + hb * Vector3(se * rf * 0.42, rf * 0.34, -rf * 0.86)
		var bm3 := BoxMesh.new()
		bm3.size = Vector3(rf * 0.38, rf * 0.055, rf * 0.050)
		var bmi: MeshInstance3D = _add(root, bm3, mat_ink)
		bmi.transform = Transform3D(bb, bp)
		# kumadori: two red strokes per side sweeping up off the nose
		for kk in range(2):
			var kf: float = float(kk)
			var kb: Basis = hb * Basis(Vector3.FORWARD, se * deg_to_rad(26.0 + kf * 16.0)) * Basis(Vector3.UP, se * deg_to_rad(-24.0))
			var kp: Vector3 = h_org + hb * Vector3(se * rf * (0.42 + kf * 0.13), rf * (0.02 - kf * 0.30), -rf * (0.86 - kf * 0.06))
			var km := BoxMesh.new()
			km.size = Vector3(rf * (0.62 - kf * 0.10), rf * 0.085, rf * 0.055)
			var kmi: MeshInstance3D = _add(root, km, mat_red)
			kmi.transform = Transform3D(kb, kp)
	# nose and mouth
	var nose := SphereMesh.new()
	nose.radius = rf * 0.10
	nose.height = rf * 0.20
	nose.radial_segments = 10
	nose.rings = 6
	var nmi: MeshInstance3D = _add(root, nose, mat_skin)
	nmi.transform = Transform3D(hb * Basis().scaled(Vector3(0.6, 1.1, 1.0)), h_org + hb * Vector3(0.0, -rf * 0.12, -rf * 0.96))
	var mouth := BoxMesh.new()
	mouth.size = Vector3(rf * 0.22, rf * 0.10, rf * 0.06)
	var mmi: MeshInstance3D = _add(root, mouth, mat_red)
	mmi.transform = Transform3D(hb, h_org + hb * Vector3(0.0, -rf * 0.46, -rf * 0.86))

	# lacquer hair: a cap of small spheres over crown and nape
	var r_hair: float = rf * 1.07
	for row_i in range(5):
		var pf: float = float(row_i) / 4.0
		var phi: float = lerpf(0.10, 1.42, pf)
		for col_i in range(8):
			var tf: float = float(col_i) / 8.0
			var tht: float = TAU * tf + 0.19
			var hdir := Vector3(sin(phi) * sin(tht), cos(phi), -sin(phi) * cos(tht))
			if hdir.y < 0.62 and hdir.z < -0.20:
				continue
			var hs := SphereMesh.new()
			hs.radius = rf * (0.32 - 0.05 * pf)
			hs.height = rf * (0.64 - 0.10 * pf)
			hs.radial_segments = 10
			hs.rings = 6
			var hmi: MeshInstance3D = _add(root, hs, mat_hair)
			hmi.transform = Transform3D(hb * Basis().scaled(Vector3(1.0, 0.9, 1.0)), h_org + hb * (hdir * r_hair))
	# side wings (tabo)
	for si in range(2):
		var sw: float = -1.0 if si == 0 else 1.0
		var wg := SphereMesh.new()
		wg.radius = rf * 0.52
		wg.height = rf * 1.04
		wg.radial_segments = 12
		wg.rings = 8
		var wmi: MeshInstance3D = _add(root, wg, mat_hair)
		wmi.transform = Transform3D(hb * Basis(Vector3.UP, sw * deg_to_rad(22.0)) * Basis().scaled(Vector3(0.85, 0.62, 1.45)), h_org + hb * Vector3(sw * rf * 1.02, -rf * 0.18, rf * 0.30))
	# mage bun and kanzashi pins
	for k in range(4):
		var kf2: float = float(k)
		var bs := SphereMesh.new()
		bs.radius = rf * (0.40 - 0.04 * kf2)
		bs.height = rf * (0.80 - 0.08 * kf2)
		bs.radial_segments = 12
		bs.rings = 8
		var bsi: MeshInstance3D = _add(root, bs, mat_hair)
		var bl := Vector3(lerpf(-0.30, 0.30, kf2 / 3.0) * rf, rf * (0.72 - 0.10 * absf(kf2 - 1.5)), rf * (0.86 + 0.10 * absf(kf2 - 1.5)))
		bsi.transform = Transform3D(hb * Basis().scaled(Vector3(1.0, 0.78, 1.0)), h_org + hb * bl)
	for si in range(2):
		var sp: float = -1.0 if si == 0 else 1.0
		var pin := CylinderMesh.new()
		pin.top_radius = rf * 0.030
		pin.bottom_radius = rf * 0.030
		pin.height = rf * 1.55
		pin.radial_segments = 8
		var pmi: MeshInstance3D = _add(root, pin, mat_bone)
		var pin_b: Basis = hb * Basis(Vector3.FORWARD, deg_to_rad(90.0)) * Basis(Vector3.UP, sp * deg_to_rad(16.0))
		pmi.transform = Transform3D(pin_b, h_org + hb * Vector3(0.0, rf * (0.68 + sp * 0.16), rf * 0.80))

	# --- settle: floor, width, height -----------------------------------------
	var box: AABB = _union_aabb(root)
	var kfit: float = 1.0
	var wide: float = maxf(box.size.x, box.size.z)
	if wide > 1.2:
		kfit = minf(kfit, 1.2 / wide)
	if box.size.y > 1.68:
		kfit = minf(kfit, 1.68 / box.size.y)
	if kfit < 1.0:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cmi: MeshInstance3D = ch
			var tf: Transform3D = cmi.transform
			cmi.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), tf.origin * kfit)
		box = _union_aabb(root)
	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, 0.0, -centre.z)
	if box.position.y < 0.0:
		shift.y = -box.position.y
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cmi2: MeshInstance3D = ch
		cmi2.transform = Transform3D(cmi2.transform.basis, cmi2.transform.origin + shift)


# ---------------------------------------------------------------------------
# geometry helpers

static func _profile(t: float, keys: Array) -> float:
	var n: int = keys.size() - 1
	var f: float = clampf(t, 0.0, 1.0) * float(n)
	var i: int = int(floor(f))
	if i >= n:
		return float(keys[n])
	var u: float = f - float(i)
	var va: float = float(keys[i])
	var vb: float = float(keys[i + 1])
	return lerpf(va, vb, u)


static func _sgnpow(v: float, e: float) -> float:
	var s: float = 1.0 if v >= 0.0 else -1.0
	return s * pow(absf(v), e)


static func _flat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _basis_y_to(d_in: Vector3) -> Basis:
	var d: Vector3 = d_in.normalized()
	var dot_up: float = d.dot(Vector3.UP)
	if dot_up > 0.9999:
		return Basis()
	if dot_up < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	var ax: Vector3 = Vector3.UP.cross(d).normalized()
	var ang: float = acos(clampf(dot_up, -1.0, 1.0))
	return Basis(ax, ang)


static func _capsule(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.02)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = ln + r * 2.0
	cap.radial_segments = 12
	cap.rings = 4
	var mi: MeshInstance3D = _add(root, cap, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _taper(root: Node3D, a: Vector3, b: Vector3, r0: float, r1: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.01)
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r0
	cyl.top_radius = r1
	cyl.height = ln
	cyl.radial_segments = 14
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _box(root: Node3D, ctr: Vector3, ax: Vector3, ay: Vector3, az: Vector3, sz: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = sz
	var mi: MeshInstance3D = _add(root, bm, mat)
	mi.transform = Transform3D(Basis(ax.normalized(), ay.normalized(), az.normalized()), ctr)
	return mi


static func _seg_box(root: Node3D, a: Vector3, b: Vector3, out_d: Vector3, w: float, thick: float, mat: StandardMaterial3D, side_off: float = 0.0) -> void:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.005)
	var yv: Vector3 = d / ln
	var zv: Vector3 = out_d - yv * out_d.dot(yv)
	if zv.length() < 0.0001:
		zv = Vector3.BACK
	zv = zv.normalized()
	var xv: Vector3 = yv.cross(zv).normalized()
	var ctr: Vector3 = (a + b) * 0.5 + xv * side_off
	_box(root, ctr, xv, yv, zv, Vector3(w, ln * 1.08, thick), mat)


static func _row_centre(row: Array) -> Vector3:
	var acc := Vector3.ZERO
	for v in row:
		var p: Vector3 = v
		acc += p
	return acc / float(row.size())


static func _tri(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, t0: Vector2, t1: Vector2, t2: Vector2) -> void:
	st.set_uv(t0)
	st.add_vertex(p0)
	st.set_uv(t1)
	st.add_vertex(p1)
	st.set_uv(t2)
	st.add_vertex(p2)


static func _tri_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ta: Vector2, tb: Vector2, tc: Vector2, inside: Vector3) -> void:
	var n_front: Vector3 = (c - a).cross(b - a)
	var centroid: Vector3 = (a + b + c) / 3.0
	if n_front.dot(centroid - inside) >= 0.0:
		_tri(st, a, b, c, ta, tb, tc)
	else:
		_tri(st, a, c, b, ta, tc, tb)


static func _quad_uv(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ta: Vector2, tb: Vector2, tc: Vector2, td: Vector2, inside: Vector3) -> void:
	# emit a quad whose Godot front face points away from `inside`
	var n_front: Vector3 = (c - a).cross(b - a)
	var centroid: Vector3 = (a + b + c + d) * 0.25
	if n_front.dot(centroid - inside) >= 0.0:
		_tri(st, a, b, c, ta, tb, tc)
		_tri(st, a, c, d, ta, tc, td)
	else:
		_tri(st, a, c, b, ta, tc, tb)
		_tri(st, a, d, c, ta, td, tc)


static func _loft_mesh(rings: Array, lev: Array, urep: float, vrep: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n_lev: int = rings.size()
	var first_row: Array = rings[0]
	var n_ang: int = first_row.size()
	for k in range(n_lev - 1):
		var ra: Array = rings[k]
		var rb: Array = rings[k + 1]
		var ca: Vector3 = _row_centre(ra)
		var cb: Vector3 = _row_centre(rb)
		var mid_c: Vector3 = (ca + cb) * 0.5
		var va: float = float(lev[k]) * vrep
		var vb: float = float(lev[k + 1]) * vrep
		for j in range(n_ang):
			var j2: int = (j + 1) % n_ang
			var ua: float = float(j) / float(n_ang) * urep
			var ub: float = float(j + 1) / float(n_ang) * urep
			var p0: Vector3 = ra[j]
			var p1: Vector3 = ra[j2]
			var p2: Vector3 = rb[j2]
			var p3: Vector3 = rb[j]
			_quad_uv(st, p0, p1, p2, p3, Vector2(ua, va), Vector2(ub, va), Vector2(ub, vb), Vector2(ua, vb), mid_c)
	# caps: shoulder plate on top, floor plate at the hem
	var top_row: Array = rings[0]
	var top_c: Vector3 = _row_centre(top_row)
	var top_in: Vector3 = top_c - Vector3(0.0, 0.12, 0.0)
	for j in range(n_ang):
		var j2: int = (j + 1) % n_ang
		var q0: Vector3 = top_row[j]
		var q1: Vector3 = top_row[j2]
		_tri_out(st, top_c, q0, q1, Vector2(0.5 * urep, 0.0), Vector2(float(j) / float(n_ang) * urep, 0.0), Vector2(float(j + 1) / float(n_ang) * urep, 0.0), top_in)
	var bot_row: Array = rings[n_lev - 1]
	var bot_c: Vector3 = _row_centre(bot_row)
	var bot_in: Vector3 = bot_c + Vector3(0.0, 0.12, 0.0)
	for j in range(n_ang):
		var j2: int = (j + 1) % n_ang
		var q0: Vector3 = bot_row[j]
		var q1: Vector3 = bot_row[j2]
		_tri_out(st, bot_c, q0, q1, Vector2(0.5 * urep, vrep), Vector2(float(j) / float(n_ang) * urep, vrep), Vector2(float(j + 1) / float(n_ang) * urep, vrep), bot_in)
	st.generate_normals()
	return st.commit()


static func _sleeve_mesh(sh: Vector3, along: Vector3, drop: Vector3, nrm: Vector3, len_a: float, len_d: float, dkeys: Array, thick: float, fold_amp: float, crease_u: float, urep: float, vrep: float) -> ArrayMesh:
	var nu: int = 10
	var nv: int = 9
	var grid: Array = []
	for i in range(nu + 1):
		var u: float = float(i) / float(nu)
		var col: Array = []
		for j in range(nv + 1):
			var v: float = float(j) / float(nv)
			var dp: float = _profile(u, dkeys)
			var swellv: float = sin(PI * v) * sin(2.1 * PI * u + 0.4) * 0.35
			var cz: float = (u - crease_u) / 0.15
			var crease: float = exp(-cz * cz) * v * 0.9
			var off: float = fold_amp * (swellv - crease)
			col.append(sh + along * (len_a * u) + drop * (len_d * dp * v) + nrm * off)
		grid.append(col)
	var mid_col: Array = grid[int(floor(float(nu) * 0.5))]
	var sc: Vector3 = mid_col[int(floor(float(nv) * 0.5))]
	var half: float = thick * 0.5

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side_i in range(2):
		var sgn: float = 1.0 if side_i == 0 else -1.0
		for i in range(nu):
			var ca: Array = grid[i]
			var cb: Array = grid[i + 1]
			for j in range(nv):
				var m00: Vector3 = ca[j]
				var m01: Vector3 = ca[j + 1]
				var m10: Vector3 = cb[j]
				var m11: Vector3 = cb[j + 1]
				var a: Vector3 = m00 + nrm * (sgn * half)
				var b: Vector3 = m10 + nrm * (sgn * half)
				var c: Vector3 = m11 + nrm * (sgn * half)
				var d: Vector3 = m01 + nrm * (sgn * half)
				var ins: Vector3 = (m00 + m01 + m10 + m11) * 0.25
				var ua: float = float(i) / float(nu) * urep
				var ub: float = float(i + 1) / float(nu) * urep
				var va: float = float(j) / float(nv) * vrep
				var vb: float = float(j + 1) / float(nv) * vrep
				_quad_uv(st, a, b, c, d, Vector2(ua, va), Vector2(ub, va), Vector2(ub, vb), Vector2(ua, vb), ins)
	# rim: bottom edge (v = 1), outer edge (u = 1), inner edge (u = 0)
	var last_col: Array = grid[nu]
	var first_col: Array = grid[0]
	for i in range(nu):
		var ca2: Array = grid[i]
		var cb2: Array = grid[i + 1]
		var ma: Vector3 = ca2[nv]
		var mb: Vector3 = cb2[nv]
		var ins2: Vector3 = ((ma + mb) * 0.5).lerp(sc, 0.10)
		_quad_uv(st, ma + nrm * half, mb + nrm * half, mb - nrm * half, ma - nrm * half, Vector2(0.0, vrep), Vector2(0.2, vrep), Vector2(0.2, vrep + 0.1), Vector2(0.0, vrep + 0.1), ins2)
	for j in range(nv):
		var ma2: Vector3 = last_col[j]
		var mb2: Vector3 = last_col[j + 1]
		var ins3: Vector3 = ((ma2 + mb2) * 0.5).lerp(sc, 0.10)
		_quad_uv(st, ma2 + nrm * half, mb2 + nrm * half, mb2 - nrm * half, ma2 - nrm * half, Vector2(urep, 0.0), Vector2(urep, 0.2), Vector2(urep + 0.1, 0.2), Vector2(urep + 0.1, 0.0), ins3)
		var ma3: Vector3 = first_col[j]
		var mb3: Vector3 = first_col[j + 1]
		var ins4: Vector3 = ((ma3 + mb3) * 0.5).lerp(sc, 0.10)
		_quad_uv(st, ma3 + nrm * half, mb3 + nrm * half, mb3 - nrm * half, ma3 - nrm * half, Vector2(0.0, 0.0), Vector2(0.0, 0.2), Vector2(0.1, 0.2), Vector2(0.1, 0.0), ins4)
	st.generate_normals()
	return st.commit()


static func _union_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		if cm.mesh == null:
			continue
		var local: AABB = cm.mesh.get_aabb()
		var wb: AABB = cm.transform * local
		if first:
			box = wb
			first = false
		else:
			box = box.merge(wb)
	return box


# ---------------------------------------------------------------------------
# cloth patterns, painted in code

static func _grain(fx: float, fy: float) -> float:
	var h: float = sin(fx * 12.9898 + fy * 78.233) * 43758.5453
	return 0.972 + 0.028 * fposmod(h, 1.0)


static func _put(img: Image, x: int, y: int, c: Color) -> void:
	var g: float = _grain(float(x), float(y))
	img.set_pixel(x, y, Color(clampf(c.r * g, 0.0, 1.0), clampf(c.g * g, 0.0, 1.0), clampf(c.b * g, 0.0, 1.0)))


static func _pattern(kind: int, rng: RandomNumberGenerator) -> ImageTexture:
	var gc := Color(0.949, 0.933, 0.890)
	var ink: Color = Color(0.114, 0.184, 0.478).lerp(Color(0.055, 0.086, 0.267), rng.randf_range(0.0, 0.65))
	var mid := Color(0.518, 0.612, 0.812)
	var red := Color(0.749, 0.196, 0.169)
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	if kind == 0:
		_paint_waves(img, rng, gc, ink, mid)
	elif kind == 1:
		_paint_seigaiha(img, rng, gc, ink, mid)
	elif kind == 2:
		_paint_peony(img, rng, gc, ink, mid)
	elif kind == 3:
		_paint_keyfret(img, rng, gc, ink, mid)
	elif kind == 4:
		_paint_stripes(img, rng, gc, red)
	else:
		_paint_blobs(img, rng, gc, ink, mid)
	return ImageTexture.create_from_image(img)


static func _paint_waves(img: Image, rng: RandomNumberGenerator, gc: Color, ink: Color, mid: Color) -> void:
	var ph: float = rng.randf_range(0.0, TAU)
	var span: float = float(TEX) / 4.0
	var f1: float = float(rng.randi_range(1, 2))
	var tf: float = float(TEX)
	for y in range(TEX):
		for x in range(TEX):
			var fx: float = float(x)
			var fy: float = float(y)
			var wav: float = 7.2 * sin(TAU * f1 * fx / tf + ph) + 3.2 * sin(TAU * 3.0 * fx / tf + ph * 1.7)
			var dy: float = fposmod(fy - wav + span * 0.5, span) - span * 0.5
			var ad: float = absf(dy)
			var w_ink: float = 4.4 + 2.2 * sin(TAU * 2.0 * fx / tf + ph * 0.5)
			var c: Color = gc
			if ad < 1.25:
				c = gc
			elif ad < w_ink:
				c = ink
			elif ad < w_ink + 3.2:
				c = mid
			elif absf(ad - (w_ink + 6.8)) < 0.9:
				c = mid
			_put(img, x, y, c)


static func _paint_seigaiha(img: Image, rng: RandomNumberGenerator, gc: Color, ink: Color, mid: Color) -> void:
	var rad: float = 32.0
	var sx: float = 32.0
	var sy: float = 16.0
	var rw: float = 7.6
	var jit: float = rng.randf_range(0.0, 3.0)
	for y in range(TEX):
		for x in range(TEX):
			var fx: float = float(x)
			var fy: float = float(y) + jit
			var owner_d: float = -1.0
			var r0: int = int(floor((fy + rad) / sy))
			var r1: int = int(floor((fy - rad) / sy)) - 1
			for r in range(r0, r1, -1):
				var cy: float = float(r) * sy
				var off: float = 0.0
				if posmod(r, 2) == 1:
					off = sx * 0.5
				var c0: int = int(round((fx - off) / sx))
				var best: float = -1.0
				for cc in range(c0 - 1, c0 + 2):
					var cx: float = float(cc) * sx + off
					var ddx: float = fx - cx
					var ddy: float = fy - cy
					var dd: float = sqrt(ddx * ddx + ddy * ddy)
					if dd <= rad:
						if best < 0.0 or dd < best:
							best = dd
				if best >= 0.0:
					owner_d = best
					break
			var c: Color = gc
			if owner_d >= 0.0:
				var fr: float = fposmod(owner_d, rw) / rw
				if fr < 0.36:
					c = ink
				elif fr < 0.50:
					c = mid
				if rad - owner_d < 1.6:
					c = ink
			_put(img, x, y, c)


static func _paint_peony(img: Image, rng: RandomNumberGenerator, gc: Color, ink: Color, mid: Color) -> void:
	var n: int = 7
	var cxs: Array = []
	var cys: Array = []
	var rrs: Array = []
	var rots: Array = []
	var lobes: Array = []
	var tf: float = float(TEX)
	for i in range(n):
		cxs.append(rng.randf_range(0.0, tf))
		cys.append(rng.randf_range(0.0, tf))
		rrs.append(rng.randf_range(15.0, 25.0))
		rots.append(rng.randf_range(0.0, TAU))
		lobes.append(float(rng.randi_range(5, 7)))
	var dn: int = 16
	var dxs: Array = []
	var dys: Array = []
	for i in range(dn):
		dxs.append(rng.randf_range(0.0, tf))
		dys.append(rng.randf_range(0.0, tf))
	for y in range(TEX):
		for x in range(TEX):
			var fx: float = float(x)
			var fy: float = float(y)
			var c: Color = gc
			for i in range(dn):
				var ddx: float = fposmod(fx - float(dxs[i]) + tf * 0.5, tf) - tf * 0.5
				var ddy: float = fposmod(fy - float(dys[i]) + tf * 0.5, tf) - tf * 0.5
				if ddx * ddx + ddy * ddy < 7.0:
					c = mid
			for i in range(n):
				var dx: float = fposmod(fx - float(cxs[i]) + tf * 0.5, tf) - tf * 0.5
				var dy: float = fposmod(fy - float(cys[i]) + tf * 0.5, tf) - tf * 0.5
				var d: float = sqrt(dx * dx + dy * dy)
				var r_base: float = float(rrs[i])
				if d > r_base * 1.05:
					continue
				var th: float = atan2(dy, dx)
				var rt: float = r_base * (0.70 + 0.30 * absf(sin(float(lobes[i]) * 0.5 * (th - float(rots[i])))))
				if d > rt:
					continue
				if rt - d < 2.4:
					c = ink
				elif d < rt * 0.26:
					c = ink
				elif d < rt * 0.38:
					c = gc
				elif absf(d - rt * 0.62) < 1.4:
					c = ink
				elif d < rt * 0.62:
					c = mid
				else:
					c = mid.lerp(gc, 0.45)
			_put(img, x, y, c)


static func _paint_keyfret(img: Image, rng: RandomNumberGenerator, gc: Color, ink: Color, mid: Color) -> void:
	var cell: float = 32.0
	var pitch: float = rng.randf_range(5.0, 6.0)
	var half: float = cell * 0.5 - 0.5
	for y in range(TEX):
		for x in range(TEX):
			var fx: float = float(x)
			var fy: float = float(y)
			var cxi: int = int(floor(fx / cell))
			var cyi: int = int(floor(fy / cell))
			var lx: float = fposmod(fx, cell)
			var ly: float = fposmod(fy, cell)
			if posmod(cxi + cyi, 2) == 1:
				lx = cell - 1.0 - lx
			var ex: float = absf(lx - half)
			var ey: float = absf(ly - half)
			var d: float = maxf(ex, ey)
			var fr: float = fposmod(d, pitch)
			var on: bool = fr < 2.1
			if on and (ly - half) > 0.0 and ex < 1.7:
				on = false
			var c: Color = gc
			if on:
				c = ink
			elif fr < 2.9:
				c = mid.lerp(gc, 0.55)
			_put(img, x, y, c)


static func _paint_stripes(img: Image, rng: RandomNumberGenerator, gc: Color, red: Color) -> void:
	var period: float = 16.0
	var amp: float = rng.randf_range(3.0, 7.0)
	var f1: float = float(rng.randi_range(1, 2))
	var ph: float = rng.randf_range(0.0, TAU)
	var vertical: bool = rng.randf() < 0.45
	var edge: Color = red.darkened(0.38)
	var tf: float = float(TEX)
	for y in range(TEX):
		for x in range(TEX):
			var fx: float = float(x)
			var fy: float = float(y)
			var v: float = 0.0
			if vertical:
				v = fx + amp * sin(TAU * f1 * fy / tf + ph)
			else:
				v = fy + amp * sin(TAU * f1 * fx / tf + ph)
			var f: float = fposmod(v, period)
			var c: Color = gc
			if f < period * 0.52:
				c = red
			if f < 1.0 or absf(f - period * 0.52) < 1.0:
				c = edge
			_put(img, x, y, c)


static func _paint_blobs(img: Image, rng: RandomNumberGenerator, gc: Color, ink: Color, mid: Color) -> void:
	var n: int = 8
	var cxs: Array = []
	var cys: Array = []
	var rrs: Array = []
	var tf: float = float(TEX)
	for i in range(n):
		cxs.append(rng.randf_range(0.0, tf))
		cys.append(rng.randf_range(0.0, tf))
		rrs.append(rng.randf_range(12.0, 22.0))
	for y in range(TEX):
		for x in range(TEX):
			var fx: float = float(x)
			var fy: float = float(y)
			var fsum: float = 0.0
			for i in range(n):
				var dx: float = fposmod(fx - float(cxs[i]) + tf * 0.5, tf) - tf * 0.5
				var dy: float = fposmod(fy - float(cys[i]) + tf * 0.5, tf) - tf * 0.5
				var ri: float = float(rrs[i])
				fsum += (ri * ri) / (dx * dx + dy * dy + 1.0)
			var c: Color = gc
			if fsum > 1.0:
				c = ink
			elif fsum > 0.82:
				c = mid
			if fsum > 1.30 and fsum < 1.52:
				c = mid.lerp(gc, 0.30)
			_put(img, x, y, c)
