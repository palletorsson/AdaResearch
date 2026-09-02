extends RefCounted

## dream_bodies / garet_still — one glossy toy figurine standing in a twist,
## with its own still life around its feet.
##
## Reference: scratchpad/refs/garet_wesselmann.png (2048x536 panorama) — a crowd
## of high-gloss plastic figurines on black: bodies wrapped in blue-and-white
## WAVE STRIPES, one in a hot pink FISHNET grid, one whose whole skin is a
## cluster of grey CAULIFLOWER BUMPS, a poured glossy purple figure and an
## orange one, and around every ankle a still life of green leaves, red
## cherries, pale yellow florets and dark vine tendrils.
##
## What is reproduced, and how:
##   1. The twist — the pelvis is pushed hard to one side, the shoulder line is
##      yawed 16-34 deg against it, the weight sits on the near leg and the far
##      foot is set back. Spine and every limb are Catmull-Rom curves sampled
##      into overlapping CapsuleMesh with tapering radii, so the body bends
##      without joints, the way moulded plastic does.
##   2. Toy proportions — a small egg head (7.6 cm radius), long thin limbs, and
##      an exaggerated hip: the fat first spine radius plus two flare spheres.
##   3. Three skins, one per seed. WAVES: bands displaced by three sines, blue
##      with a lighter core on near-white. FISHNET: thin pale lines on a rotated
##      lattice over a blushed hot pink ground. BUMPS: a jittered-cell mottle in
##      grey. All painted per pixel into ImageTextures in code and mapped with
##      WORLD triplanar, so the pattern runs unbroken across every capsule seam.
##   4. The bump skin is also geometry — 44-64 small spheres scattered on the
##      torso, hips, thighs and skull at their host capsules' own radii, so the
##      cauliflower body has a real silhouette and not a printed one.
##   5. A bare head — by seed the head, neck and hands drop out of the pattern
##      into flesh, the way the reference's fishnet body wears a plain face; a
##      swim-cap ellipsoid in the skin's accent colour sits on the skull.
##   6. The still life — 5-9 fruit spheres in cherry red and orange resting on
##      the slab, one cherry carried high on a three-segment arced stem; 2-4
##      florets, each a stalk under 8-12 pale yellow knobs scattered on a dome;
##      6-12 leaves as SurfaceTool blades (three-column strip, lobed edge,
##      cupped midrib) on thin stems; two dark vine tendrils spiralling up.
##   7. A poured purple gourd — three stacked spheres and a drip — for the
##      poured purple figure in the middle of the reference.
##   8. Plastic, not clay: every material clearcoat 1.0, roughness 0.10-0.16,
##      standing on a near-black glossy slab.
##
## Given up: the face (a nose only), fingers beyond two per hand, the crowd —
## the reference is a dozen figures leaning into one another and this is one of
## them alone — and the plain flesh figures the patterned ones stand among.

const TEX: int = 256
const TEX_S: int = 128
const SLAB: float = 0.032


static func describe() -> String:
	return "A glossy plastic figurine standing in a twist on a black slab, skinned in blue wave stripes, pink fishnet or grey cauliflower bumps, with cherries, florets, leaves and vine tendrils around its feet."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# ---------------------------------------------------------------- skin --
	var kinds: Array = ["waves", "fishnet", "bumps"]
	var skin: String = kinds[rng.randi_range(0, 2)]
	var mat_skin: StandardMaterial3D = _plastic(Color(1.0, 1.0, 1.0), 0.15)
	var accent := Color("#0E56A8")
	var uvs: float = 1.6
	if skin == "waves":
		mat_skin.albedo_texture = _tex_waves(rng)
		uvs = rng.randf_range(1.25, 1.75)
		accent = Color("#0E56A8")
	elif skin == "fishnet":
		mat_skin.albedo_texture = _tex_fishnet(rng)
		uvs = rng.randf_range(2.20, 3.00)
		accent = Color("#B92C74")
	else:
		mat_skin.albedo_texture = _tex_bumps(rng)
		mat_skin.albedo_color = Color("#C4C5D2").lerp(Color("#B4BAC0"), rng.randf())
		uvs = rng.randf_range(1.80, 2.60)
		accent = Color("#9497A4")
	mat_skin.uv1_triplanar = true
	mat_skin.uv1_world_triplanar = true
	mat_skin.uv1_scale = Vector3(uvs, uvs, uvs)

	var mat_flesh: StandardMaterial3D = _plastic(Color("#F2C6A8").lerp(Color("#DEA184"), rng.randf()), 0.14)
	var mat_accent: StandardMaterial3D = _plastic(accent, 0.13)
	var bare: bool = rng.randf() < 0.5
	var mat_head: StandardMaterial3D = mat_flesh if bare else mat_skin

	# still-life materials
	var mat_slab: StandardMaterial3D = _plastic(Color("#121218"), 0.10)
	var mat_red: StandardMaterial3D = _plastic(Color("#CE1330"), 0.12)
	var mat_red2: StandardMaterial3D = _plastic(Color("#A5102A"), 0.12)
	var mat_orange: StandardMaterial3D = _plastic(Color("#F0871B"), 0.13)
	var mat_yellow: StandardMaterial3D = _plastic(Color("#EBDF9E"), 0.16)
	var mat_yellow2: StandardMaterial3D = _plastic(Color("#DACC7B"), 0.16)
	var mat_green: StandardMaterial3D = _plastic(Color("#2F8034"), 0.14)
	var mat_vine: StandardMaterial3D = _plastic(Color("#16311B"), 0.12)
	var mat_purple: StandardMaterial3D = _plastic(Color("#5A2E9E"), 0.10)
	var mat_leaf_a: StandardMaterial3D = _plastic(Color("#2E7D33"), 0.14)
	mat_leaf_a.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mat_leaf_b: StandardMaterial3D = _plastic(Color("#57A83F"), 0.14)
	mat_leaf_b.cull_mode = BaseMaterial3D.CULL_DISABLED

	# ------------------------------------------------------- the individual --
	var hip_side: float = -1.0 if rng.randf() < 0.5 else 1.0
	var hip_push: float = rng.randf_range(0.075, 0.115) * hip_side
	var twist: float = deg_to_rad(rng.randf_range(16.0, 34.0)) * -hip_side
	var lean: float = rng.randf_range(-0.03, 0.05)
	var head_tilt: float = rng.randf_range(-0.18, 0.24)
	var head_yaw: float = deg_to_rad(rng.randf_range(-26.0, 26.0)) - twist * 0.4
	var slim: float = rng.randf_range(0.92, 1.06)
	var hk: float = rng.randf_range(0.96, 1.04)
	var reach_up: float = rng.randf_range(0.06, 0.18)

	var y_pelvis: float = 0.80 * hk
	var y_waist: float = 0.99 * hk
	var y_chest: float = 1.17 * hk
	var y_neck: float = 1.30 * hk
	var y_head: float = 1.43 * hk
	var y_ankle: float = SLAB + 0.055

	var hosts: Array = []

	# ---------------------------------------------------------------- torso --
	var p_pelvis := Vector3(hip_push, y_pelvis, 0.0)
	var p_waist := Vector3(hip_push * 0.45, y_waist, 0.035 + lean * 0.3)
	var p_chest := Vector3(-hip_push * 0.55, y_chest, 0.010 - lean)
	var p_neck := Vector3(-hip_push * 0.35, y_neck, -0.015 - lean * 1.2)
	_tube(root, mat_skin, [p_pelvis, p_waist, p_chest, p_neck],
		[0.148 * slim, 0.086 * slim, 0.116 * slim, 0.052], 9, hosts)

	# the exaggerated hip: two flare spheres on the pelvis
	for k in range(2):
		var sgn: float = -1.0 if k == 0 else 1.0
		var flare := SphereMesh.new()
		flare.radius = 0.086 * slim
		flare.height = 0.086 * slim * 1.72
		flare.radial_segments = 16
		flare.rings = 9
		var fm: MeshInstance3D = _add(root, flare, mat_skin)
		fm.transform = Transform3D(Basis(), p_pelvis + Vector3(sgn * 0.082 * slim, -0.020, 0.0))
		hosts.append({"a": p_pelvis, "b": p_pelvis + Vector3(sgn * 0.082, -0.02, 0.0), "r": 0.086 * slim})

	# buttocks
	for k in range(2):
		var sgn: float = -1.0 if k == 0 else 1.0
		var glute := SphereMesh.new()
		glute.radius = 0.072 * slim
		glute.height = 0.072 * slim * 1.9
		glute.radial_segments = 16
		glute.rings = 9
		var gm: MeshInstance3D = _add(root, glute, mat_skin)
		gm.transform = Transform3D(Basis(), p_pelvis + Vector3(sgn * 0.056, 0.006, 0.078))

	# chest
	var chest_fwd := Vector3(0.0, 0.0, -1.0)
	for k in range(2):
		var sgn: float = -1.0 if k == 0 else 1.0
		var bust := SphereMesh.new()
		bust.radius = 0.052 * slim
		bust.height = 0.052 * slim * 1.8
		bust.radial_segments = 16
		bust.rings = 9
		var bm: MeshInstance3D = _add(root, bust, mat_skin)
		var bpos: Vector3 = p_chest + Vector3(sgn * 0.055, 0.010, 0.0) + chest_fwd * (0.076 * slim)
		bm.transform = Transform3D(Basis(Vector3(1.0, 0.0, 0.0), -0.5), bpos)

	# ------------------------------------------------------------ shoulders --
	var sb := Basis(Vector3.UP, twist)
	var sh_l: Vector3 = p_neck + sb * Vector3(-0.152 * slim, -0.046, 0.0)
	var sh_r: Vector3 = p_neck + sb * Vector3(0.152 * slim, -0.046, 0.0)
	_capsule_between(root, mat_skin, sh_l, sh_r, 0.058 * slim)
	hosts.append({"a": sh_l, "b": sh_r, "r": 0.058 * slim})

	# ----------------------------------------------------------------- head --
	var head_c: Vector3 = p_neck + Vector3(head_tilt * 0.055, y_head - y_neck, -0.022)
	_capsule_between(root, mat_head, p_neck + Vector3(0.0, 0.010, 0.0), head_c, 0.042)
	var hb: Basis = Basis(Vector3.UP, head_yaw) * Basis(Vector3(0.0, 0.0, 1.0), head_tilt)
	var r_head: float = 0.076 * slim
	var skull := SphereMesh.new()
	skull.radius = r_head
	skull.height = r_head * 2.0 * 1.24
	skull.radial_segments = 22
	skull.rings = 12
	var sm: MeshInstance3D = _add(root, skull, mat_head)
	sm.transform = Transform3D(hb, head_c)
	# swim cap
	var cap := SphereMesh.new()
	cap.radius = r_head * 1.035
	cap.height = r_head * 2.0 * 1.10
	cap.radial_segments = 20
	cap.rings = 11
	var cm2: MeshInstance3D = _add(root, cap, mat_accent)
	cm2.transform = Transform3D(hb, head_c + hb * Vector3(0.0, r_head * 0.30, 0.0))
	# nose, a profile and nothing more
	var face_fwd: Vector3 = (hb * Vector3(0.0, 0.0, -1.0)).normalized()
	_cone(root, head_c + face_fwd * (r_head * 0.86) + Vector3(0.0, -0.004, 0.0), face_fwd, 0.030, 0.013, mat_head)

	# ----------------------------------------------------------------- legs --
	var hip_w: Vector3 = p_pelvis + Vector3(hip_side * 0.086, -0.048, 0.0)
	var knee_w: Vector3 = Vector3(hip_side * 0.088 + hip_push * 0.10, 0.44 * hk, 0.022)
	var ank_w: Vector3 = Vector3(hip_side * 0.078, y_ankle, -0.008)
	var hip_f: Vector3 = p_pelvis + Vector3(-hip_side * 0.086, -0.048, 0.0)
	var knee_f: Vector3 = Vector3(-hip_side * 0.058, 0.428 * hk, -0.088)
	var ank_f: Vector3 = Vector3(-hip_side * 0.152, y_ankle, 0.082)
	_tube(root, mat_skin, [hip_w, knee_w, ank_w], [0.082 * slim, 0.053 * slim, 0.038], 8, hosts)
	_tube(root, mat_skin, [hip_f, knee_f, ank_f], [0.082 * slim, 0.053 * slim, 0.038], 8, hosts)
	_foot(root, mat_skin, ank_w, deg_to_rad(rng.randf_range(-18.0, 6.0)) + hip_side * 0.12)
	_foot(root, mat_skin, ank_f, deg_to_rad(rng.randf_range(-6.0, 30.0)) + hip_side * 0.12)

	# ----------------------------------------------------------------- arms --
	var sd_a: float = -hip_side
	var sh_a: Vector3 = sh_r if sd_a > 0.0 else sh_l
	var sh_b: Vector3 = sh_l if sd_a > 0.0 else sh_r
	# the raised arm: out, then up and across the front — the gesture
	var elb_a: Vector3 = sh_a + Vector3(sd_a * 0.168, -0.118, -0.048)
	var wri_a: Vector3 = elb_a + Vector3(-sd_a * 0.082, 0.150 + reach_up, -0.118)
	var mat_hand: StandardMaterial3D = mat_flesh if bare else mat_skin
	_tube(root, mat_skin, [sh_a, elb_a, wri_a], [0.055 * slim, 0.041 * slim, 0.031], 7, hosts)
	_hand(root, mat_hand, wri_a, (wri_a - elb_a).normalized(), sd_a)
	# the hanging arm: down and a little back, hand by the hip
	var elb_b: Vector3 = sh_b + Vector3(-sd_a * 0.112, -0.198, 0.058)
	var wri_b: Vector3 = elb_b + Vector3(-sd_a * 0.030, -0.182, -0.072)
	_tube(root, mat_skin, [sh_b, elb_b, wri_b], [0.055 * slim, 0.041 * slim, 0.031], 7, hosts)
	_hand(root, mat_hand, wri_b, (wri_b - elb_b).normalized(), -sd_a)

	# ------------------------------------------------- cauliflower geometry --
	if skin == "bumps":
		var mat_b1: StandardMaterial3D = _plastic(Color("#C8C9D4"), 0.15)
		var mat_b2: StandardMaterial3D = _plastic(Color("#B3B6C2"), 0.15)
		var mat_b3: StandardMaterial3D = _plastic(Color("#D5D6DE"), 0.15)
		var bump_mats: Array = [mat_b1, mat_b2, mat_b3]
		_bumps(root, bump_mats, hosts, rng, rng.randi_range(44, 60))
		if not bare:
			for k in range(4):
				var ang: float = rng.randf_range(0.0, TAU)
				var pit: float = rng.randf_range(0.1, 1.1)
				var nrm := Vector3(sin(pit) * cos(ang), cos(pit), sin(pit) * sin(ang))
				var br: float = rng.randf_range(0.018, 0.028)
				var knob := SphereMesh.new()
				knob.radius = br
				knob.height = br * 2.0
				knob.radial_segments = 8
				knob.rings = 5
				var km: MeshInstance3D = _add(root, knob, bump_mats[rng.randi_range(0, 2)])
				km.transform = Transform3D(Basis(), head_c + nrm * (r_head * 0.92))

	# ----------------------------------------------------------- the ground --
	var slab := BoxMesh.new()
	slab.size = Vector3(1.10, SLAB, 1.10)
	var slm: MeshInstance3D = _add(root, slab, mat_slab)
	slm.transform = Transform3D(Basis(), Vector3(0.0, SLAB * 0.5, 0.0))

	var a0: float = rng.randf_range(0.0, TAU)

	# fruit, resting
	var n_fruit: int = rng.randi_range(5, 9)
	for i in range(n_fruit):
		var ang: float = a0 + TAU * float(i) / float(n_fruit) + rng.randf_range(-0.26, 0.26)
		var rad: float = rng.randf_range(0.30, 0.44)
		var fr: float = rng.randf_range(0.042, 0.072)
		var mfr: StandardMaterial3D = mat_red
		var roll: float = rng.randf()
		if roll < 0.30:
			mfr = mat_orange
		elif roll < 0.55:
			mfr = mat_red2
		var sph := SphereMesh.new()
		sph.radius = fr
		sph.height = fr * 2.0 * rng.randf_range(0.90, 1.02)
		sph.radial_segments = 18
		sph.rings = 10
		var fm2: MeshInstance3D = _add(root, sph, mfr)
		fm2.transform = Transform3D(Basis(Vector3.UP, rng.randf_range(0.0, TAU)),
			Vector3(cos(ang) * rad, SLAB + fr * 0.94, sin(ang) * rad))

	# one cherry carried high on an arced stem
	var ch_ang: float = a0 + rng.randf_range(0.6, 2.6)
	var ch_rad: float = rng.randf_range(0.28, 0.36)
	var ch_top: float = rng.randf_range(0.50, 0.72)
	var stem_pts: Array = [
		Vector3(cos(ch_ang) * (ch_rad + 0.07), SLAB, sin(ch_ang) * (ch_rad + 0.07)),
		Vector3(cos(ch_ang) * (ch_rad + 0.10), ch_top * 0.55, sin(ch_ang) * (ch_rad + 0.10)),
		Vector3(cos(ch_ang) * ch_rad, ch_top, sin(ch_ang) * ch_rad),
	]
	var prev_s: Vector3 = _spline(stem_pts, 0.0)
	for i in range(3):
		var t1: float = float(i + 1) / 3.0
		var nxt: Vector3 = _spline(stem_pts, t1)
		var r0: float = lerpf(0.0095, 0.0065, float(i) / 3.0)
		var r1: float = lerpf(0.0095, 0.0065, t1)
		_taper(root, prev_s, nxt, r0, r1, mat_green)
		prev_s = nxt
	var cherry := SphereMesh.new()
	cherry.radius = 0.046
	cherry.height = 0.088
	cherry.radial_segments = 20
	cherry.rings = 11
	var chm: MeshInstance3D = _add(root, cherry, mat_red)
	chm.transform = Transform3D(Basis(), prev_s + Vector3(0.0, -0.040, 0.0))

	# florets — bunches of pale knobs
	var n_cl: int = rng.randi_range(2, 4)
	for i in range(n_cl):
		var ang: float = a0 + TAU * (float(i) + 0.5) / float(n_cl) + rng.randf_range(-0.30, 0.30)
		var rad: float = rng.randf_range(0.30, 0.42)
		var cx: float = cos(ang) * rad
		var cz: float = sin(ang) * rad
		var dome: float = rng.randf_range(0.055, 0.082)
		_taper(root, Vector3(cx, SLAB, cz), Vector3(cx, SLAB + dome * 0.55, cz), 0.024, 0.032, mat_green)
		var n_k: int = rng.randi_range(8, 12)
		for j in range(n_k):
			var th: float = rng.randf_range(0.0, TAU)
			var ph: float = acos(clampf(1.0 - rng.randf() * 0.85, -1.0, 1.0))
			var kr: float = rng.randf_range(0.020, 0.034)
			var kpos := Vector3(
				cx + dome * sin(ph) * cos(th),
				SLAB + dome * 0.52 + dome * cos(ph) * 0.85 + kr * 0.35,
				cz + dome * sin(ph) * sin(th))
			var knob := SphereMesh.new()
			knob.radius = kr
			knob.height = kr * 2.0 * rng.randf_range(0.88, 1.06)
			knob.radial_segments = 9
			knob.rings = 6
			var mk: StandardMaterial3D = mat_yellow if rng.randf() < 0.6 else mat_yellow2
			var km2: MeshInstance3D = _add(root, knob, mk)
			km2.transform = Transform3D(Basis(Vector3.UP, rng.randf_range(0.0, TAU)), kpos)

	# leaves — blades on thin stems
	var n_leaf: int = rng.randi_range(6, 12)
	for i in range(n_leaf):
		var ang: float = a0 + TAU * float(i) / float(n_leaf) + rng.randf_range(-0.35, 0.35)
		var rad: float = rng.randf_range(0.25, 0.32)
		var out_dir := Vector3(cos(ang), 0.0, sin(ang))
		var base_p: Vector3 = Vector3(cos(ang) * rad, SLAB, sin(ang) * rad)
		var stem_h: float = rng.randf_range(0.07, 0.16)
		var tip_p: Vector3 = base_p + Vector3(0.0, stem_h, 0.0) + out_dir * rng.randf_range(0.010, 0.045)
		_taper(root, base_p, tip_p, 0.0105, 0.0075, mat_green)
		var tilt: float = rng.randf_range(0.35, 1.00)
		var grow: Vector3 = (Vector3.UP * cos(tilt) + out_dir * sin(tilt)).normalized()
		var blade: ArrayMesh = _leaf_mesh(
			rng.randf_range(0.130, 0.180),
			rng.randf_range(0.034, 0.056),
			rng.randf_range(0.50, 1.10),
			rng.randf_range(0.010, 0.030))
		var ml: StandardMaterial3D = mat_leaf_a if rng.randf() < 0.55 else mat_leaf_b
		var lm: MeshInstance3D = _add(root, blade, ml)
		lm.transform = Transform3D(_frame(grow, out_dir), tip_p)

	# vine tendrils
	for k in range(2):
		var ang: float = a0 + PI * 0.75 * float(k) + rng.randf_range(0.4, 1.3)
		var rad: float = rng.randf_range(0.33, 0.45)
		var rise: float = rng.randf_range(0.26, 0.46)
		var turns: float = rng.randf_range(1.1, 1.9)
		var prev_t: Vector3 = Vector3(cos(ang) * rad, SLAB, sin(ang) * rad)
		for j in range(7):
			var t: float = float(j + 1) / 7.0
			var aa: float = ang + turns * TAU * t * 0.25
			var rr: float = rad * (1.0 - 0.32 * t) + 0.045 * sin(t * PI * 2.0)
			var np: Vector3 = Vector3(cos(aa) * rr, SLAB + rise * pow(t, 0.85), sin(aa) * rr)
			_taper(root, prev_t, np, 0.0105 - 0.0006 * float(j), 0.0095 - 0.0006 * float(j), mat_vine)
			prev_t = np

	# the poured purple gourd
	var pg_ang: float = a0 + rng.randf_range(3.0, 4.6)
	var pg_rad: float = rng.randf_range(0.26, 0.36)
	var pg_x: float = cos(pg_ang) * pg_rad
	var pg_z: float = sin(pg_ang) * pg_rad
	var pg_r: float = rng.randf_range(0.058, 0.082)
	var pg_lean: float = rng.randf_range(0.10, 0.30)
	for k in range(3):
		var f: float = float(k) / 2.0
		var rr: float = lerpf(pg_r, pg_r * 0.44, f)
		var blob := SphereMesh.new()
		blob.radius = rr
		blob.height = rr * 2.0 * lerpf(0.92, 1.16, f)
		blob.radial_segments = 18
		blob.rings = 10
		var bm2: MeshInstance3D = _add(root, blob, mat_purple)
		bm2.transform = Transform3D(Basis(), Vector3(
			pg_x + pg_lean * f * 0.16,
			SLAB + pg_r * 0.88 + f * pg_r * 1.30,
			pg_z - pg_lean * f * 0.10))
	_cone(root, Vector3(pg_x + pg_lean * 0.18, SLAB + pg_r * 2.36, pg_z - pg_lean * 0.11),
		Vector3(0.35, 1.0, -0.2).normalized(), pg_r * 0.9, pg_r * 0.30, mat_purple)

	# ------------------------------------------------- fit, centre, settle --
	var box: AABB = _union_aabb(root)
	var kx: float = 1.22 / maxf(box.size.x, 0.01)
	var kz: float = 1.22 / maxf(box.size.z, 0.01)
	var ky: float = 1.66 / maxf(box.size.y, 0.01)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cmi: MeshInstance3D = ch
			var tf: Transform3D = cmi.transform
			cmi.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), tf.origin * kfit)
		box = _union_aabb(root)
	var centre: Vector3 = box.position + box.size * 0.5
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cmi: MeshInstance3D = ch
		cmi.transform = Transform3D(cmi.transform.basis, cmi.transform.origin + Vector3(-centre.x, 0.0, -centre.z))

	# the measured settle: nothing may hang below the floor
	box = _union_aabb(root)
	if box.position.y < 0.0:
		var lift: float = -box.position.y
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cmi: MeshInstance3D = ch
			cmi.transform = Transform3D(cmi.transform.basis, cmi.transform.origin + Vector3(0.0, lift, 0.0))


# ---------------------------------------------------------------- the body --

static func _foot(root: Node3D, mat: Material, ankle: Vector3, yaw: float) -> void:
	var fwd := Vector3(sin(yaw), 0.0, -cos(yaw))
	var toe: Vector3 = ankle + fwd * 0.128 + Vector3(0.0, -0.022, 0.0)
	_capsule_between(root, mat, ankle, toe, 0.034)
	var ball := SphereMesh.new()
	ball.radius = 0.036
	ball.height = 0.052
	ball.radial_segments = 14
	ball.rings = 8
	var bm: MeshInstance3D = _add(root, ball, mat)
	bm.transform = Transform3D(Basis(Vector3.UP, yaw), toe + fwd * 0.018)


static func _hand(root: Node3D, mat: Material, wrist: Vector3, dir: Vector3, splay: float) -> void:
	var palm := SphereMesh.new()
	palm.radius = 0.040
	palm.height = 0.062
	palm.radial_segments = 14
	palm.rings = 8
	var pm: MeshInstance3D = _add(root, palm, mat)
	pm.transform = Transform3D(_basis_y_to(dir), wrist + dir * 0.026)
	var side: Vector3 = dir.cross(Vector3.UP)
	if side.length() < 0.05:
		side = dir.cross(Vector3(0.0, 0.0, 1.0))
	side = side.normalized()
	for k in range(2):
		var sgn: float = -1.0 if k == 0 else 1.0
		var fd: Vector3 = (dir + side * (sgn * 0.34 * signf(splay))).normalized()
		_taper(root, wrist + dir * 0.046, wrist + dir * 0.046 + fd * 0.052, 0.014, 0.009, mat)


static func _tube(root: Node3D, mat: Material, pts: Array, radii: Array, n: int, hosts: Array) -> void:
	for i in range(n):
		var t0: float = float(i) / float(n)
		var t1: float = float(i + 1) / float(n)
		var a: Vector3 = _spline(pts, t0)
		var b: Vector3 = _spline(pts, t1)
		var r: float = _ramp(radii, (t0 + t1) * 0.5)
		_capsule_between(root, mat, a, b, r)
		hosts.append({"a": a, "b": b, "r": r})


static func _bumps(root: Node3D, mats: Array, hosts: Array, rng: RandomNumberGenerator, count: int) -> void:
	if hosts.is_empty():
		return
	for k in range(count):
		var h: Dictionary = hosts[rng.randi_range(0, hosts.size() - 1)]
		var a: Vector3 = h["a"]
		var b: Vector3 = h["b"]
		var r: float = h["r"]
		var axis: Vector3 = b - a
		if axis.length() < 0.0005:
			axis = Vector3.UP
		axis = axis.normalized()
		var e1: Vector3 = axis.cross(Vector3.UP)
		if e1.length() < 0.08:
			e1 = axis.cross(Vector3(1.0, 0.0, 0.0))
		e1 = e1.normalized()
		var e2: Vector3 = axis.cross(e1).normalized()
		var ang: float = rng.randf_range(0.0, TAU)
		var nrm: Vector3 = (e1 * cos(ang) + e2 * sin(ang)).normalized()
		var c: Vector3 = a.lerp(b, rng.randf())
		var br: float = r * rng.randf_range(0.24, 0.42)
		var sph := SphereMesh.new()
		sph.radius = br
		sph.height = br * 2.0 * rng.randf_range(0.86, 1.10)
		sph.radial_segments = 8
		sph.rings = 5
		var mb: StandardMaterial3D = mats[rng.randi_range(0, mats.size() - 1)]
		var mi: MeshInstance3D = _add(root, sph, mb)
		mi.transform = Transform3D(Basis(Vector3.UP, ang), c + nrm * (r * 0.84))


# ------------------------------------------------------------- primitives --

static func _add(root: Node3D, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _plastic(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	m.clearcoat_enabled = true
	m.clearcoat = 1.0
	m.clearcoat_roughness = 0.05
	return m


static func _capsule_between(root: Node3D, mat: Material, a: Vector3, b: Vector3, r: float) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.004)
	var capm := CapsuleMesh.new()
	capm.radius = r
	capm.height = ln + r * 2.0
	capm.radial_segments = 14
	capm.rings = 5
	var mi: MeshInstance3D = _add(root, capm, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _taper(root: Node3D, a: Vector3, b: Vector3, r0: float, r1: float, mat: Material) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.004)
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = maxf(r0, 0.0005)
	cyl.top_radius = maxf(r1, 0.0005)
	cyl.height = ln
	cyl.radial_segments = 10
	cyl.rings = 1
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _cone(root: Node3D, base_p: Vector3, dir: Vector3, h: float, r: float, mat: Material) -> MeshInstance3D:
	var d: Vector3 = dir.normalized()
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r
	cyl.top_radius = 0.0
	cyl.height = h
	cyl.radial_segments = 10
	cyl.rings = 1
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), base_p + d * (h * 0.5))
	return mi


static func _basis_y_to(dir: Vector3) -> Basis:
	var d: Vector3 = dir.normalized()
	var dot_up: float = d.dot(Vector3.UP)
	if dot_up > 0.9999:
		return Basis()
	if dot_up < -0.9999:
		return Basis(Vector3(1.0, 0.0, 0.0), PI)
	var ax: Vector3 = Vector3.UP.cross(d).normalized()
	var ang: float = acos(clampf(dot_up, -1.0, 1.0))
	return Basis(ax, ang)


static func _frame(y_dir: Vector3, hint: Vector3) -> Basis:
	var ya: Vector3 = y_dir.normalized()
	var za: Vector3 = hint - ya * hint.dot(ya)
	if za.length() < 0.001:
		var alt := Vector3(0.0, 0.0, -1.0)
		za = alt - ya * alt.dot(ya)
	za = za.normalized()
	var xa: Vector3 = ya.cross(za).normalized()
	return Basis(xa, ya, za)


static func _spline(pts: Array, t: float) -> Vector3:
	var m: int = pts.size()
	if m == 1:
		return pts[0]
	var f: float = clampf(t, 0.0, 1.0) * float(m - 1)
	var i: int = clampi(int(floor(f)), 0, m - 2)
	var u: float = f - float(i)
	var p0: Vector3 = pts[maxi(i - 1, 0)]
	var p1: Vector3 = pts[i]
	var p2: Vector3 = pts[i + 1]
	var p3: Vector3 = pts[mini(i + 2, m - 1)]
	var u2: float = u * u
	var u3: float = u2 * u
	return 0.5 * ((p1 * 2.0)
		+ (p2 - p0) * u
		+ (p0 * 2.0 - p1 * 5.0 + p2 * 4.0 - p3) * u2
		+ (p1 * 3.0 - p0 - p2 * 3.0 + p3) * u3)


static func _ramp(vals: Array, t: float) -> float:
	var m: int = vals.size()
	if m == 1:
		return float(vals[0])
	var f: float = clampf(t, 0.0, 1.0) * float(m - 1)
	var i: int = clampi(int(floor(f)), 0, m - 2)
	var u: float = f - float(i)
	var va: float = float(vals[i])
	var vb: float = float(vals[i + 1])
	return lerpf(va, vb, u)


static func _leaf_mesh(ln: float, half_w: float, bend: float, cup: float) -> ArrayMesh:
	# a blade growing along +Y and curling toward +Z; three columns so the
	# midrib can sit lower than the edges, lobed outline, tapered tip
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 9
	var pts: Array = []
	var nrms: Array = []
	var wid: Array = []
	var p := Vector3.ZERO
	for i in range(n + 1):
		var t: float = float(i) / float(n)
		var a: float = bend * t
		var d := Vector3(0.0, cos(a), sin(a))
		if i > 0:
			p = p + d * (ln / float(n))
		pts.append(p)
		nrms.append(Vector3(0.0, -sin(a), cos(a)))
		# never let the tip reach zero width — a zero-area triangle poisons
		# generate_normals() and the blade shades black
		var shape: float = maxf(pow(sin(PI * clampf(t * 0.92 + 0.08, 0.0, 1.0)), 0.62), 0.10)
		var lobe: float = 1.0 + 0.13 * sin(t * PI * 5.0)
		wid.append(half_w * shape * lobe)
	for i in range(n):
		var c0: Vector3 = pts[i]
		var c1: Vector3 = pts[i + 1]
		var n0: Vector3 = nrms[i]
		var n1: Vector3 = nrms[i + 1]
		var w0: float = wid[i]
		var w1: float = wid[i + 1]
		var side := Vector3(1.0, 0.0, 0.0)
		var l0: Vector3 = c0 - side * w0 + n0 * (cup * w0 / maxf(half_w, 0.001))
		var r0: Vector3 = c0 + side * w0 + n0 * (cup * w0 / maxf(half_w, 0.001))
		var l1: Vector3 = c1 - side * w1 + n1 * (cup * w1 / maxf(half_w, 0.001))
		var r1: Vector3 = c1 + side * w1 + n1 * (cup * w1 / maxf(half_w, 0.001))
		# left half
		st.add_vertex(l0)
		st.add_vertex(c1)
		st.add_vertex(c0)
		st.add_vertex(l0)
		st.add_vertex(l1)
		st.add_vertex(c1)
		# right half
		st.add_vertex(c0)
		st.add_vertex(c1)
		st.add_vertex(r0)
		st.add_vertex(r0)
		st.add_vertex(c1)
		st.add_vertex(r1)
	st.generate_normals()
	return st.commit()


# ----------------------------------------------------------------- skins ---

static func _tex_waves(rng: RandomNumberGenerator) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var ph1: float = rng.randf_range(0.0, TAU)
	var ph2: float = rng.randf_range(0.0, TAU)
	var ph3: float = rng.randf_range(0.0, TAU)
	var periods: int = rng.randi_range(4, 6)
	var duty: float = rng.randf_range(0.40, 0.50)
	var amp: float = rng.randf_range(0.035, 0.065)
	var blue := Color("#1573D6")
	var blue_d := Color("#0B4D9E")
	var white := Color("#F3F5F7")
	var edge: float = 0.020
	for y in range(TEX):
		var v: float = float(y) / float(TEX)
		for x in range(TEX):
			var u: float = float(x) / float(TEX)
			var wob: float = amp * sin(TAU * u + ph1) + amp * 0.55 * sin(TAU * 2.0 * u + ph2) + amp * 0.30 * sin(TAU * 3.0 * u + ph3)
			var s: float = fposmod((v + wob) * float(periods), 1.0)
			var m0: float = clampf(s / edge, 0.0, 1.0)
			var m1: float = clampf((duty - s) / edge, 0.0, 1.0)
			var mask: float = minf(m0, m1)
			var core: float = sin(PI * clampf(s / duty, 0.0, 1.0))
			var band: Color = blue_d.lerp(blue, 0.20 + 0.80 * core)
			var pale: Color = white.darkened(0.04 * (1.0 - core))
			img.set_pixel(x, y, pale.lerp(band, mask))
	return ImageTexture.create_from_image(img)


static func _tex_fishnet(rng: RandomNumberGenerator) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var cells: int = rng.randi_range(14, 22)
	var thick: float = rng.randf_range(0.070, 0.110)
	var ph: float = rng.randf_range(0.0, TAU)
	var base := Color("#DE4A93")
	var deep := Color("#B12A70")
	var line := Color("#FBDCE9")
	for y in range(TEX):
		var v: float = float(y) / float(TEX)
		for x in range(TEX):
			var u: float = float(x) / float(TEX)
			var a: float = fposmod((u + v) * float(cells), 1.0)
			var b: float = fposmod((u - v) * float(cells), 1.0)
			var da: float = minf(a, 1.0 - a)
			var db: float = minf(b, 1.0 - b)
			var dm: float = minf(da, db)
			var lm: float = clampf((thick - dm) / 0.022, 0.0, 1.0)
			var blush: float = 0.5 + 0.5 * sin(TAU * u + ph) * sin(PI * v)
			var ground: Color = deep.lerp(base, 0.30 + 0.70 * blush)
			img.set_pixel(x, y, ground.lerp(line, lm * 0.92))
	return ImageTexture.create_from_image(img)


static func _tex_bumps(rng: RandomNumberGenerator) -> ImageTexture:
	# jittered-cell mottle: each pixel takes the nearest cell centre, bright at
	# the centre and dark at the seam, so the skin reads as packed knobs
	var img: Image = Image.create(TEX_S, TEX_S, false, Image.FORMAT_RGB8)
	var n: int = 8
	var cell: float = float(TEX_S) / float(n)
	var jx: Array = []
	var jy: Array = []
	var tint: Array = []
	for k in range(n * n):
		jx.append(rng.randf_range(0.18, 0.82))
		jy.append(rng.randf_range(0.18, 0.82))
		tint.append(rng.randf_range(0.88, 1.06))
	for y in range(TEX_S):
		var py: float = float(y) + 0.5
		var ry: int = int(floor(py / cell))
		for x in range(TEX_S):
			var px: float = float(x) + 0.5
			var rx: int = int(floor(px / cell))
			var best: float = 1.0e9
			var best_i: int = 0
			for oy in range(ry - 1, ry + 2):
				for ox in range(rx - 1, rx + 2):
					var wx: int = posmod(ox, n)
					var wy: int = posmod(oy, n)
					var idx: int = wy * n + wx
					var cxp: float = (float(ox) + float(jx[idx])) * cell
					var cyp: float = (float(oy) + float(jy[idx])) * cell
					var dx: float = px - cxp
					var dy: float = py - cyp
					var dd: float = dx * dx + dy * dy
					if dd < best:
						best = dd
						best_i = idx
			var dn: float = clampf(sqrt(best) / (cell * 0.72), 0.0, 1.0)
			var shade: float = 1.0 - 0.46 * pow(dn, 1.35)
			var g: float = clampf(shade * float(tint[best_i]), 0.0, 1.0)
			img.set_pixel(x, y, Color(g * 0.99, g * 0.99, g))
	return ImageTexture.create_from_image(img)


static func _union_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cmi: MeshInstance3D = ch
		if cmi.mesh == null:
			continue
		var wb: AABB = cmi.transform * cmi.mesh.get_aabb()
		if first:
			box = wb
			first = false
		else:
			box = box.merge(wb)
	return box
