extends RefCounted

## dream_bodies / ceramic_puppet — one glazed ball-jointed ceramic puppet, arms raised and curling.
##
## Reference: scratchpad/refs/sistine_robot.png (2048x536 panorama) — a crowd of
## glossy ceramic puppets standing under the Sistine ceiling. Their limbs are long
## CHAINS of smooth glazed capsule segments in pale pink, mint green and gold, each
## segment strung on a white sphere ball joint with a thin chrome collar at either
## end; the heads are small featureless eggs; the torso is hidden under a stiff
## cloth printed with a bold black-and-white maze / key-fret pattern.
##
## Reproduced, and how:
##   1. The limb is a CHAIN, not a limb — `_chain()` lays capsule segments between
##      node points, a white glazed sphere at every node, and a chrome cylinder
##      collar tucked against both ends of every segment, so an arm of 6-8 links
##      reads as jointed hardware rather than an arm.
##   2. Arms raised and curling — each arm integrates a lean angle from ~100 deg
##      (straight out from the shoulder) easing to ~-25 deg (curling back inward
##      over the head), with a forward drift, so the chain sweeps out, up and
##      round. The two arms get different angles and easings: the gesture is
##      asymmetric.
##   3. The maze cloth — a randomised spanning-tree maze is carved on a torus grid
##      and painted into a 240x240 ImageTexture as thick black strokes on paper
##      white, then wrapped on a SurfaceTool shell of 7 rings x 14 sides lofted
##      from the shoulders to a hem at the knee, tapering, leaning forward, with
##      per-side fold amplitudes for stiff vertical creases and one raised collar
##      corner (a QuadMesh flap) at a seed-chosen shoulder.
##   4. Ceramic glaze — every body material is roughness 0.08, metallic 0,
##      clearcoat 1.0, clearcoat_roughness 0.05; ball joints a warmer white, the
##      collars true chrome (metallic 1.0, roughness 0.14).
##   5. The palette by seed — pale pink, mint green, gold and warm white; a main
##      and an alternate colour that swap along a chain, as the reference's puppets
##      mix gold and mint segments on one arm.
##   6. Brush linework — on some seeds a second code-painted texture of thick black
##      wandering strokes rides the glazed segments with world triplanar UVs, so
##      the drawing runs unbroken across a chain of separate primitives, as it does
##      on the mint figure at the right of the panorama.
##   7. Small featureless egg head — a prolate SphereMesh on a two-link neck, one
##      dark glaze dot on ONE side only, a chrome nub at the nape; tilted toward
##      whichever arm curls harder, over a contrapposto lean and a seeded yaw.
##
## Given up: the Sistine ceiling behind them, the crowd (this is one puppet, not a
## rank of them), the drilled screw holes and cable ports moulded into the shells,
## the fingers as anything more than three short nubs, and the way the reference's
## cloth hangs as a genuinely thin sheet with a visible cut edge.
##
## AXES — two, swept as a gallery:
##   stringing — what the jointed chain is MADE of. strung = today's glazed capsule
##     links on white ball joints; swarmed = every link dissolved into a cloud of
##     small beads, the joints left standing in the fog; unstrung = the links shoved
##     off their joints and hovering apart, the ball armature bare beneath them;
##     wired = the glaze gone, a thin chrome rod threaded through fat collar rings;
##     swollen = the links inflated into bulbs that swallow their own joints.
##   vestment — what the maze cloth BECOMES. maze_cloth = today's stiff printed
##     shell with its raised collar corner; flooded = a solid glaze pour risen in
##     tongues up the legs and drowned the hem; unravelled = the shell come apart
##     into a fringe of hanging printed threads; bloomed = the hem flared into
##     scalloped petals, with petals opening from both hands as well.

const TEX_SIZE: int = 240

const COL_PINK: String = "#F2C3C6"
const COL_MINT: String = "#A5DCCB"
const COL_GOLD: String = "#E2B048"
const COL_WHITE: String = "#F4F0E9"


static func describe() -> String:
	return "A glossy ceramic ball-jointed puppet standing with both long segmented arms raised and curling, its torso wrapped in a stiff cloth printed with a black-and-white maze."


static func axes() -> Dictionary:
	return {
		"stringing": ["strung", "swarmed", "unstrung", "wired", "swollen"],
		"vestment": ["maze_cloth", "flooded", "unravelled", "bloomed"],
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- axes ---------------------------------------------------------------
	var stringing: String = str(opts.get("stringing", "strung"))
	var vestment: String = str(opts.get("vestment", "maze_cloth"))
	# how the chain mode rescales the parts that hang off the chains
	var head_k: float = 1.0
	var foot_k: float = 1.0
	var fin_k: float = 1.0
	var joint_k: float = 1.0
	if stringing == "swollen":
		head_k = 1.32
		foot_k = 1.34
		fin_k = 1.70
		joint_k = 0.64
	elif stringing == "wired":
		head_k = 0.80
		foot_k = 0.78
		fin_k = 0.55
		joint_k = 0.58
	elif stringing == "swarmed":
		joint_k = 0.74

	# --- palette ------------------------------------------------------------
	var swatch: Array = [Color(COL_PINK), Color(COL_MINT), Color(COL_GOLD), Color(COL_WHITE)]
	var i_main: int = rng.randi_range(0, 3)
	var i_alt: int = (i_main + rng.randi_range(1, 3)) % 4
	var col_main: Color = swatch[i_main]
	var col_alt: Color = swatch[i_alt]
	var two_tone: bool = rng.randf() < 0.55
	if not two_tone:
		col_alt = col_main.lerp(Color(1.0, 1.0, 1.0), 0.16)

	# --- textures -----------------------------------------------------------
	var cell_opts: Array = [8, 10, 12]
	var maze_cells: int = int(cell_opts[rng.randi_range(0, 2)])
	var maze_tex: ImageTexture = _maze_texture(rng, maze_cells, 0.23)
	var has_lines: bool = rng.randf() < 0.45
	var line_tex: ImageTexture = null
	if has_lines:
		line_tex = _brush_texture(rng, rng.randi_range(5, 8))

	# --- materials ----------------------------------------------------------
	var mat_ball: StandardMaterial3D = _glaze(Color("#FBFAF7"), null)
	mat_ball.roughness = 0.11
	var mat_chrome := StandardMaterial3D.new()
	mat_chrome.albedo_color = Color("#D6DADE")
	mat_chrome.metallic = 1.0
	mat_chrome.metallic_specular = 0.85
	mat_chrome.roughness = 0.14
	var mat_dark: StandardMaterial3D = _glaze(Color("#22242A"), null)
	var mat_cloth := StandardMaterial3D.new()
	mat_cloth.albedo_color = Color("#FFFFFF")
	mat_cloth.albedo_texture = maze_tex
	mat_cloth.roughness = 0.34
	mat_cloth.metallic = 0.0
	mat_cloth.clearcoat_enabled = true
	mat_cloth.clearcoat = 0.35
	mat_cloth.clearcoat_roughness = 0.3
	mat_cloth.cull_mode = BaseMaterial3D.CULL_DISABLED

	# --- individual parameters ---------------------------------------------
	var lean_x: float = rng.randf_range(-0.045, 0.045)
	var lean_z: float = rng.randf_range(-0.030, 0.020)
	var hip_drop: float = rng.randf_range(0.012, 0.038)
	var drop_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var stance: float = rng.randf_range(0.098, 0.132)
	var foot_fwd: float = rng.randf_range(0.02, 0.09)
	var toe_out: float = rng.randf_range(0.14, 0.42)
	var n_arm: int = rng.randi_range(6, 8)
	var n_ring: int = rng.randi_range(6, 8)
	var n_side: int = 14
	if vestment == "bloomed":
		n_side = 20
	var yaw: float = deg_to_rad(rng.randf_range(-16.0, 16.0))
	var head_tilt: float = deg_to_rad(rng.randf_range(-13.0, 13.0))
	var head_yaw: float = deg_to_rad(rng.randf_range(-24.0, 24.0))
	var y_hip: float = rng.randf_range(0.820, 0.870)
	var y_shoulder: float = y_hip + rng.randf_range(0.455, 0.500)

	# --- legs ---------------------------------------------------------------
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var fwd: float = foot_fwd if sd == drop_side else -foot_fwd * 0.6
		var drop: float = hip_drop if sd == drop_side else 0.0
		var ax: float = sd * stance
		var y_shin: float = lerpf(0.100, y_hip, 0.245)
		var y_knee: float = lerpf(0.100, y_hip, 0.490)
		var y_thigh: float = lerpf(0.100, y_hip, 0.735)
		var ankle := Vector3(ax, 0.100, -fwd)
		var shin := Vector3(ax + sd * 0.006, y_shin, -fwd * 0.72 - 0.012)
		var knee := Vector3(ax + sd * 0.010, y_knee, -fwd * 0.40 - 0.020)
		var thigh := Vector3(ax + sd * 0.020, y_thigh, -fwd * 0.16 + 0.004)
		var hip := Vector3(sd * 0.118 + lean_x * 0.25, y_hip - drop, lean_z * 0.25)
		var pts: Array = [ankle, shin, knee, thigh, hip]
		var radii: Array = [0.050, 0.056, 0.060, 0.066, 0.074]
		var mats: Array = []
		for k in range(4):
			var pick: Color = col_main if (k % 3) != 2 else col_alt
			mats.append(_glaze(pick, line_tex))
		_chain(root, pts, radii, mats, mat_ball, mat_chrome, stringing)
		# foot: a capsule lying along the toe direction, sole exactly on y = 0
		var toe_dir := Vector3(sd * toe_out, 0.0, -1.0).normalized()
		var foot := CapsuleMesh.new()
		foot.radius = 0.046 * foot_k
		foot.height = 0.205 * foot_k
		foot.radial_segments = 16
		foot.rings = 4
		var mat_foot: StandardMaterial3D = _glaze(col_main, line_tex)
		var fm: MeshInstance3D = _add(root, foot, mat_foot)
		fm.transform = Transform3D(_basis_y_to(toe_dir), Vector3(ax, 0.046 * foot_k, -fwd) + toe_dir * (0.048 * foot_k))

	# --- torso column (mostly under the cloth) ------------------------------
	var tn0 := Vector3(lean_x * 0.2, y_hip + 0.020, lean_z * 0.2)
	var tn1 := Vector3(lean_x * 0.6, lerpf(y_hip, y_shoulder, 0.36), lean_z * 0.6)
	var tn2 := Vector3(lean_x * 0.9, lerpf(y_hip, y_shoulder, 0.70), lean_z * 0.9)
	var tn3 := Vector3(lean_x, y_shoulder, lean_z)
	var torso_pts: Array = [tn0, tn1, tn2, tn3]
	var torso_radii: Array = [0.098, 0.088, 0.092, 0.086]
	var torso_mats: Array = []
	for k in range(3):
		torso_mats.append(_glaze(col_main, line_tex))
	_chain(root, torso_pts, torso_radii, torso_mats, mat_ball, mat_chrome, stringing)

	# --- shoulders ----------------------------------------------------------
	var sh_half: float = rng.randf_range(0.175, 0.198)
	var shoulder_pts: Array = []
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var sp: Vector3 = tn3 + Vector3(sd * sh_half, rng.randf_range(-0.012, 0.016), 0.004)
		shoulder_pts.append(sp)
		var ball := SphereMesh.new()
		ball.radius = 0.062 * joint_k
		ball.height = 0.124 * joint_k
		ball.radial_segments = 22
		ball.rings = 11
		var bm: MeshInstance3D = _add(root, ball, mat_ball)
		bm.transform = Transform3D(Basis(), sp)
		var ring := TorusMesh.new()
		ring.inner_radius = 0.055
		ring.outer_radius = 0.068
		ring.rings = 20
		ring.ring_segments = 10
		var rm: MeshInstance3D = _add(root, ring, mat_chrome)
		rm.transform = Transform3D(_basis_y_to(Vector3(sd, 0.18, 0.0).normalized()), sp)

	# --- arms: raised, curling ----------------------------------------------
	var curl_hard: float = 0.0
	for side_i in range(2):
		var sd: float = -1.0 if side_i == 0 else 1.0
		var phi0: float = deg_to_rad(rng.randf_range(88.0, 108.0))
		var phi1: float = deg_to_rad(rng.randf_range(-44.0, -6.0))
		var ease_k: float = rng.randf_range(1.05, 1.75)
		var arm_len: float = rng.randf_range(0.590, 0.665)
		var seg_len: float = arm_len / float(n_arm)
		var drift: float = rng.randf_range(0.16, 0.44)
		if absf(phi1) > curl_hard:
			curl_hard = absf(phi1)
			if phi1 < 0.0:
				head_yaw = absf(head_yaw) * sd * 0.7
		var start: Vector3 = shoulder_pts[side_i]
		var pts: Array = [start]
		var p: Vector3 = start
		var last_dir := Vector3(sd, 0.0, 0.0)
		for i in range(n_arm):
			var t: float = (float(i) + 0.5) / float(n_arm)
			var phi: float = lerpf(phi0, phi1, pow(t, ease_k))
			var d: Vector3 = Vector3(sd * sin(phi), cos(phi), -drift * t - 0.04).normalized()
			last_dir = d
			p = p + d * seg_len
			pts.append(p)
		var radii: Array = []
		for i in range(n_arm + 1):
			var tt: float = float(i) / float(n_arm)
			# a longer chain has shorter links, so the glaze must get slimmer or
			# the segments swallow the ball joints and the chain stops reading
			var r_arm: float = minf(lerpf(0.050, 0.029, pow(tt, 0.85)), seg_len * 0.46)
			radii.append(r_arm)
		var mats: Array = []
		for i in range(n_arm):
			var alt: bool = (i % 3) == 2 or (two_tone and i == n_arm - 1)
			var pick: Color = col_alt if alt else col_main
			mats.append(_glaze(pick, line_tex))
		_chain(root, pts, radii, mats, mat_ball, mat_chrome, stringing)
		# three short finger nubs at the end of the chain
		var hand: Vector3 = pts[n_arm]
		var up_ish: Vector3 = Vector3(0.0, 1.0, 0.0)
		var side_v: Vector3 = last_dir.cross(up_ish)
		if side_v.length() < 0.01:
			side_v = Vector3(1.0, 0.0, 0.0)
		side_v = side_v.normalized()
		var norm_v: Vector3 = side_v.cross(last_dir).normalized()
		var mat_finger: StandardMaterial3D = _glaze(col_main, line_tex)
		var n_fin: int = 3
		if vestment == "bloomed":
			n_fin = 5
		for f in range(n_fin):
			var a_f: float = (float(f) - float(n_fin - 1) * 0.5) * 0.62
			var fd: Vector3 = (last_dir * 0.72 + side_v * sin(a_f) * 0.55 - norm_v * 0.42).normalized()
			if vestment == "bloomed":
				# the hand opens: a flat printed petal instead of a nub
				var petal := QuadMesh.new()
				petal.size = Vector2(0.082, 0.148)
				var pmi: MeshInstance3D = _add(root, petal, mat_cloth)
				pmi.transform = Transform3D(_basis_y_to(fd), hand + fd * 0.082)
				continue
			var fin := CapsuleMesh.new()
			fin.radius = 0.0155 * fin_k
			fin.height = 0.068 * fin_k
			fin.radial_segments = 10
			fin.rings = 3
			var fim: MeshInstance3D = _add(root, fin, mat_finger)
			fim.transform = Transform3D(_basis_y_to(fd), hand + fd * (0.036 * fin_k))

	# --- neck and egg head --------------------------------------------------
	var n0: Vector3 = tn3 + Vector3(0.0, 0.010, 0.0)
	var n1: Vector3 = n0 + Vector3(sin(head_yaw) * 0.012, 0.052, -0.006)
	var n2: Vector3 = n1 + Vector3(sin(head_yaw) * 0.016, 0.052, -0.008)
	var neck_pts: Array = [n0, n1, n2]
	var neck_radii: Array = [0.048, 0.042, 0.040]
	var neck_mats: Array = [_glaze(col_alt, null), _glaze(col_main, null)]
	_chain(root, neck_pts, neck_radii, neck_mats, mat_ball, mat_chrome, stringing)

	var hb: Basis = Basis(Vector3.UP, head_yaw) * Basis(Vector3.RIGHT, head_tilt)
	var head_org: Vector3 = n2 + hb * Vector3(0.0, 0.098 * head_k, 0.0)
	var egg := SphereMesh.new()
	egg.radius = 0.083 * head_k
	egg.height = 0.216 * head_k
	egg.radial_segments = 26
	egg.rings = 14
	var mat_head: StandardMaterial3D = _glaze(col_main, null)
	if stringing == "wired":
		mat_head = mat_chrome
	var hm: MeshInstance3D = _add(root, egg, mat_head)
	hm.transform = Transform3D(hb, head_org)
	# one dark glaze dot, on one side only — the only feature on the face
	var dot_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var dot := SphereMesh.new()
	dot.radius = 0.014
	dot.height = 0.028
	dot.radial_segments = 12
	dot.rings = 6
	var dm: MeshInstance3D = _add(root, dot, mat_dark)
	dm.transform = Transform3D(Basis(), head_org + hb * (Vector3(dot_side * 0.060, 0.024, -0.052) * head_k))
	var nub := CylinderMesh.new()
	nub.bottom_radius = 0.020
	nub.top_radius = 0.016
	nub.height = 0.018
	nub.radial_segments = 14
	var nm: MeshInstance3D = _add(root, nub, mat_chrome)
	nm.transform = Transform3D(hb * _basis_y_to(Vector3(0.0, 0.25, 1.0).normalized()), head_org + hb * (Vector3(0.0, 0.010, 0.078) * head_k))

	# --- the vestment: stiff maze cloth, or what it has become ---------------
	# every branch draws the same numbers in the same order, so the axis is the
	# only thing that differs between two frames of this seed
	var y_top: float = y_shoulder + 0.020
	var y_hem: float = lerpf(y_hip, 0.0, rng.randf_range(0.24, 0.32))
	var rx_top: float = rng.randf_range(0.215, 0.240)
	var rx_hem: float = rng.randf_range(0.165, 0.190)
	var rz_top: float = rng.randf_range(0.128, 0.148)
	var rz_hem: float = rng.randf_range(0.108, 0.126)
	var u_tiles: float = rng.randf_range(1.5, 2.1)
	var v_tiles: float = rng.randf_range(1.7, 2.4)
	var petals: int = 0
	var petal_amp: float = 0.0
	var flare: float = 0.0
	var curl: float = 0.0
	if vestment == "bloomed":
		petals = 5
		petal_amp = 0.72
		flare = 0.58
		curl = 0.15
	var cloth_mesh: ArrayMesh = _cloth(
		rng, y_top, y_hem,
		rx_top, rx_hem, rz_top, rz_hem,
		lean_x, lean_z, n_ring, n_side,
		u_tiles, v_tiles,
		petals, petal_amp, flare, curl
	)
	if vestment != "unravelled":
		var cm_node: MeshInstance3D = _add(root, cloth_mesh, mat_cloth)
		cm_node.transform = Transform3D(Basis(), Vector3.ZERO)
	# the raised collar corner, folded stiffly up over one shoulder
	var flap_side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var flap := QuadMesh.new()
	flap.size = Vector2(rng.randf_range(0.19, 0.26), rng.randf_range(0.17, 0.24))
	var flap_b: Basis = Basis(Vector3.UP, flap_side * rng.randf_range(0.5, 1.0)) * Basis(Vector3.RIGHT, rng.randf_range(0.5, 1.0))
	if vestment != "unravelled":
		var fpm: MeshInstance3D = _add(root, flap, mat_cloth)
		fpm.transform = Transform3D(flap_b, Vector3(flap_side * 0.140 + lean_x, y_top + 0.052, 0.088 + lean_z))

	if vestment == "unravelled":
		# the shell has come apart: the print now hangs as loose threads
		var n_thread: int = rng.randi_range(20, 28)
		var thread_mesh: ArrayMesh = _threads(rng, y_top, y_hem, rx_top, rx_hem, rz_top, rz_hem, lean_x, lean_z, n_thread)
		var th_node: MeshInstance3D = _add(root, thread_mesh, mat_cloth)
		th_node.transform = Transform3D(Basis(), Vector3.ZERO)
	elif vestment == "flooded":
		# the glaze ran off the kiln shelf and set: the lower body is drowned
		var y_pour: float = y_hip * rng.randf_range(0.74, 0.98)
		var pour_r: float = rng.randf_range(0.34, 0.44)
		var pour_mesh: ArrayMesh = _pour(rng, y_pour, pour_r, lean_x, lean_z)
		var mat_pour: StandardMaterial3D = _glaze(col_alt.lerp(Color(1.0, 1.0, 1.0), 0.22), null)
		var pr_node: MeshInstance3D = _add(root, pour_mesh, mat_pour)
		pr_node.transform = Transform3D(Basis(), Vector3.ZERO)

	# --- a seeded quarter-turn in the stance --------------------------------
	var spin := Basis(Vector3.UP, yaw)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var mi: MeshInstance3D = ch
		var tf: Transform3D = mi.transform
		mi.transform = Transform3D(spin * tf.basis, spin * tf.origin)

	# --- measured settle: fit, centre on x/z, stand on the floor ------------
	var box: AABB = _union_aabb(root)
	var kx: float = 1.20 / maxf(box.size.x, 0.001)
	var kz: float = 1.20 / maxf(box.size.z, 0.001)
	var ky: float = 1.68 / maxf(box.size.y, 0.001)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var mi: MeshInstance3D = ch
			var tf: Transform3D = mi.transform
			mi.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), tf.origin * kfit)
		box = _union_aabb(root)
	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, -box.position.y, -centre.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var mi: MeshInstance3D = ch
		mi.transform = Transform3D(mi.transform.basis, mi.transform.origin + shift)


# ---------------------------------------------------------------------------
# the jointed chain — the whole grammar of this puppet

static func _chain(root: Node3D, pts: Array, radii: Array, seg_mats: Array, mat_ball: StandardMaterial3D, mat_chrome: StandardMaterial3D, mode: String = "strung") -> void:
	var n: int = pts.size()
	# the chain's own centre, so "unstrung" can shove each link off it
	var cen := Vector3.ZERO
	for i in range(n):
		var pv: Vector3 = pts[i]
		cen += pv
	cen = cen / float(n)
	for i in range(n - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var delta: Vector3 = b - a
		var ln: float = maxf(delta.length(), 0.02)
		var dir: Vector3 = delta / ln
		var r: float = (float(radii[i]) + float(radii[i + 1])) * 0.5
		var ball_r: float = float(radii[i]) * 1.16
		var inset: float = ball_r * 0.70
		var ca: Vector3 = a + dir * inset
		var cb: Vector3 = b - dir * (float(radii[i + 1]) * 1.16 * 0.70)
		var seg_len: float = maxf((cb - ca).length(), 0.02)
		var mat_i: StandardMaterial3D = seg_mats[mini(i, seg_mats.size() - 1)]
		if mode == "swarmed":
			# the link is gone; a cloud of its own beads stands where it was
			_swarm(root, ca, cb, dir, r, i, mat_i, mat_ball)
			continue
		var pa: Vector3 = ca
		var pb: Vector3 = cb
		var rr: float = r
		var collar_r: float = r * 1.07
		var seg_mat: StandardMaterial3D = mat_i
		if mode == "wired":
			# the glaze fired away: a bare rod through fat chrome rings
			rr = maxf(r * 0.20, 0.005)
			collar_r = r * 1.14
			seg_mat = mat_chrome
		elif mode == "swollen":
			# the link inflates until it swallows its own joints
			rr = r * 1.85
			var mid_s: Vector3 = (ca + cb) * 0.5
			pa = mid_s - dir * (seg_len * 0.27)
			pb = mid_s + dir * (seg_len * 0.27)
			collar_r = r * 0.50
		elif mode == "unstrung":
			# the link hovers off the armature, along its own outward normal
			var away: Vector3 = (ca + cb) * 0.5 - cen
			if away.length() < 0.004:
				away = dir.cross(Vector3.UP)
			if away.length() < 0.004:
				away = Vector3.RIGHT
			var mid_u: Vector3 = (ca + cb) * 0.5 + away.normalized() * (r * 2.3) + Vector3(0.0, r * 0.85, 0.0)
			pa = mid_u - dir * (seg_len * 0.29)
			pb = mid_u + dir * (seg_len * 0.29)
		var body_len: float = maxf((pb - pa).length(), 0.02)
		var cap := CapsuleMesh.new()
		cap.radius = rr
		cap.height = body_len + rr * 2.0
		cap.radial_segments = 18
		cap.rings = 5
		var mi: MeshInstance3D = _add(root, cap, seg_mat)
		mi.transform = Transform3D(_basis_y_to(dir), (pa + pb) * 0.5)
		_collar(root, pa + dir * (r * 0.30), dir, collar_r, mat_chrome)
		_collar(root, pb - dir * (r * 0.30), dir, collar_r, mat_chrome)
	for i in range(n):
		var rb: float = float(radii[mini(i, radii.size() - 1)]) * 1.16
		if mode == "wired" or mode == "swollen":
			rb *= 0.58
		elif mode == "swarmed":
			rb *= 0.70
		var ball := SphereMesh.new()
		ball.radius = rb
		ball.height = rb * 2.0
		ball.radial_segments = 22
		ball.rings = 11
		var bm: MeshInstance3D = _add(root, ball, mat_ball)
		bm.transform = Transform3D(Basis(), pts[i])


# a link dissolved into a handful of small glazed beads — the swarm is made of
# copies of the puppet's own ball joints, scattered off the link's axis
static func _swarm(root: Node3D, a: Vector3, b: Vector3, dir: Vector3, r: float, salt: int, mat_seg: StandardMaterial3D, mat_ball: StandardMaterial3D) -> void:
	var side: Vector3 = dir.cross(Vector3.UP)
	if side.length() < 0.01:
		side = Vector3.RIGHT
	side = side.normalized()
	var nrm: Vector3 = side.cross(dir).normalized()
	for q in range(5):
		var t: float = (float(q) + 0.5) / 5.0
		var ang: float = float(q) * 2.39996 + float(salt) * 1.37
		var swing: float = r * (1.05 + 0.80 * sin(float(salt) * 0.71 + float(q) * 1.93))
		var p: Vector3 = a.lerp(b, t) + side * (cos(ang) * swing) + nrm * (sin(ang) * swing)
		var br: float = r * (0.30 + 0.24 * absf(sin(float(q) * 2.11 + float(salt) * 0.83)))
		var bead := SphereMesh.new()
		bead.radius = br
		bead.height = br * 2.0
		bead.radial_segments = 12
		bead.rings = 6
		var mat_q: StandardMaterial3D = mat_seg if (q % 2) == 0 else mat_ball
		var bm: MeshInstance3D = _add(root, bead, mat_q)
		bm.transform = Transform3D(Basis(), p)


static func _collar(root: Node3D, at: Vector3, dir: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r
	cyl.top_radius = r
	cyl.height = 0.012
	cyl.radial_segments = 18
	cyl.rings = 1
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(dir), at)
	return mi


# ---------------------------------------------------------------------------
# the cloth shell

static func _cloth(rng: RandomNumberGenerator, y_top: float, y_hem: float, rx_top: float, rx_hem: float, rz_top: float, rz_hem: float, lean_x: float, lean_z: float, n_ring: int, n_side: int, u_tiles: float, v_tiles: float, petals: int = 0, petal_amp: float = 0.0, flare: float = 0.0, curl: float = 0.0) -> ArrayMesh:
	var folds: Array = []
	var lifts: Array = []
	for j in range(n_side):
		folds.append(rng.randf_range(-0.085, 0.085))
		lifts.append(rng.randf_range(-0.012, 0.018))
	var peak_j: int = rng.randi_range(0, n_side - 1)
	lifts[peak_j] = rng.randf_range(0.070, 0.110)
	var peak_k: int = posmod(peak_j + 1, n_side)
	lifts[peak_k] = rng.randf_range(0.030, 0.060)

	var grid: Array = []
	var axis: Array = []
	for k in range(n_ring):
		var t: float = float(k) / float(n_ring - 1)
		var s: float = _ease(t)
		var cy: float = lerpf(y_top, y_hem, t)
		var cx: float = lean_x * (1.0 - t) - lean_x * 0.4 * t
		var cz: float = lean_z * (1.0 - t) - 0.045 * t
		var rx: float = lerpf(rx_top, rx_hem, s)
		var rz: float = lerpf(rz_top, rz_hem, s)
		if k == n_ring - 1:
			rx += 0.012
			rz += 0.010
		# the bloom: the whole skirt swells outward toward the hem
		var open_k: float = 1.0 + flare * s * s
		rx = rx * open_k
		rz = rz * open_k
		var ring: Array = []
		for j in range(n_side):
			var th: float = TAU * float(j) / float(n_side)
			# the petal lobe — zero unless this vestment blooms
			var lobe: float = 0.0
			if petals > 0:
				lobe = pow(0.5 + 0.5 * cos(float(petals) * th), 1.7)
			var fold: float = 1.0 + float(folds[j]) * (0.35 + 0.65 * t) + petal_amp * lobe * s
			var py: float = cy
			if k == 0:
				py += float(lifts[j])
			if k == n_ring - 1:
				py += 0.026 * sin(th * 3.0 + float(folds[j]) * 8.0) + curl * lobe
			ring.append(Vector3(cx + rx * fold * cos(th), py, cz + rz * fold * sin(th)))
		grid.append(ring)
		axis.append(Vector3(cx, cy, cz))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for k in range(n_ring - 1):
		var v0: float = float(k) / float(n_ring - 1) * v_tiles
		var v1: float = float(k + 1) / float(n_ring - 1) * v_tiles
		var row0: Array = grid[k]
		var row1: Array = grid[k + 1]
		var ax0: Vector3 = axis[k]
		var ax1: Vector3 = axis[k + 1]
		for j in range(n_side):
			var j2: int = posmod(j + 1, n_side)
			var u0: float = float(j) / float(n_side) * u_tiles
			var u1: float = float(j + 1) / float(n_side) * u_tiles
			var pa: Vector3 = row0[j]
			var pb: Vector3 = row0[j2]
			var pc: Vector3 = row1[j2]
			var pd: Vector3 = row1[j]
			var inside: Vector3 = (ax0 + ax1) * 0.5
			_quad_uv(st, pa, Vector2(u0, v0), pb, Vector2(u1, v0), pc, Vector2(u1, v1), pd, Vector2(u0, v1), inside)
	st.generate_normals()
	return st.commit()


static func _quad_uv(st: SurfaceTool, a: Vector3, ua: Vector2, b: Vector3, ub: Vector2, c: Vector3, uc: Vector2, d: Vector3, ud: Vector2, inside: Vector3) -> void:
	var n_front: Vector3 = (c - a).cross(b - a)
	var centroid: Vector3 = (a + b + c + d) * 0.25
	if n_front.dot(centroid - inside) >= 0.0:
		_v(st, a, ua)
		_v(st, b, ub)
		_v(st, c, uc)
		_v(st, a, ua)
		_v(st, c, uc)
		_v(st, d, ud)
	else:
		_v(st, a, ua)
		_v(st, c, uc)
		_v(st, b, ub)
		_v(st, a, ua)
		_v(st, d, ud)
		_v(st, c, uc)


static func _v(st: SurfaceTool, p: Vector3, uv: Vector2) -> void:
	st.set_uv(uv)
	st.add_vertex(p)


# the unravelled vestment — the shell come apart into hanging printed threads,
# each a narrow ribbon that spirals off the shoulder line and swings free of the
# body. One mesh, so a hundred threads cost one MeshInstance3D.
static func _threads(rng: RandomNumberGenerator, y_top: float, y_hem: float, rx_top: float, rx_hem: float, rz_top: float, rz_hem: float, lean_x: float, lean_z: float, count: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var steps: int = 9
	for s in range(count):
		var th0: float = TAU * float(s) / float(count) + rng.randf_range(-0.12, 0.12)
		var sway: float = rng.randf_range(-0.70, 0.70)
		var drop: float = rng.randf_range(0.0, 1.0)
		var y_end: float = lerpf(y_hem, 0.015, clampf(0.18 + 0.78 * drop, 0.0, 1.0))
		var halfw: float = rng.randf_range(0.005, 0.015)
		var bow: float = rng.randf_range(0.01, 0.11)
		var kink: float = rng.randf_range(0.0, 0.045)
		var prev_a := Vector3.ZERO
		var prev_b := Vector3.ZERO
		var prev_t: float = 0.0
		for k in range(steps + 1):
			var t: float = float(k) / float(steps)
			var th: float = th0 + sway * t * t
			var yy: float = lerpf(y_top, y_end, _ease(t)) + kink * sin(t * 11.0 + float(s))
			var rx: float = lerpf(rx_top, rx_hem, t) + bow * t * t
			var rz: float = lerpf(rz_top, rz_hem, t) + bow * t * t
			var cx: float = lean_x * (1.0 - t)
			var cz: float = lean_z * (1.0 - t) - 0.045 * t
			var p := Vector3(cx + rx * cos(th), yy, cz + rz * sin(th))
			var tang: Vector3 = Vector3(-sin(th), 0.0, cos(th)) * halfw
			var pa: Vector3 = p - tang
			var pb: Vector3 = p + tang
			if k > 0:
				_v(st, prev_a, Vector2(0.0, prev_t * 2.6))
				_v(st, prev_b, Vector2(1.0, prev_t * 2.6))
				_v(st, pb, Vector2(1.0, t * 2.6))
				_v(st, prev_a, Vector2(0.0, prev_t * 2.6))
				_v(st, pb, Vector2(1.0, t * 2.6))
				_v(st, pa, Vector2(0.0, t * 2.6))
			prev_a = pa
			prev_b = pb
			prev_t = t
	st.generate_normals()
	return st.commit()


# the flooded vestment — a solid pour of set glaze standing on the floor, risen
# in uneven tongues up the legs until it drowns the hem of the cloth
static func _pour(rng: RandomNumberGenerator, y_pour: float, base_r: float, lean_x: float, lean_z: float) -> ArrayMesh:
	var sides: int = 22
	var rings: int = 7
	var tongues: Array = []
	var wobs: Array = []
	for j in range(sides):
		tongues.append(rng.randf_range(0.34, 0.92))
		wobs.append(rng.randf_range(-0.12, 0.16))
	for i in range(3):
		tongues[rng.randi_range(0, sides - 1)] = rng.randf_range(1.02, 1.34)

	var grid: Array = []
	var axis: Array = []
	for k in range(rings):
		var t: float = float(k) / float(rings - 1)
		var s: float = _ease(t)
		var cx: float = lean_x * t * 0.4
		var cz: float = lean_z * t * 0.4
		var ring: Array = []
		var y_sum: float = 0.0
		for j in range(sides):
			var th: float = TAU * float(j) / float(sides)
			var top_j: float = y_pour * clampf(float(tongues[j]), 0.2, 1.4)
			var yy: float = lerpf(0.0, top_j, t)
			var rr: float = lerpf(base_r * (1.0 + float(wobs[j])), 0.118, s)
			ring.append(Vector3(cx + rr * cos(th), yy, cz + rr * 0.86 * sin(th)))
			y_sum += yy
		grid.append(ring)
		axis.append(Vector3(cx, y_sum / float(sides), cz))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for k in range(rings - 1):
		var row0: Array = grid[k]
		var row1: Array = grid[k + 1]
		var ax0: Vector3 = axis[k]
		var ax1: Vector3 = axis[k + 1]
		var v0: float = float(k) / float(rings - 1) * 1.3
		var v1: float = float(k + 1) / float(rings - 1) * 1.3
		for j in range(sides):
			var j2: int = posmod(j + 1, sides)
			var u0: float = float(j) / float(sides) * 2.0
			var u1: float = float(j + 1) / float(sides) * 2.0
			var pa: Vector3 = row0[j]
			var pb: Vector3 = row0[j2]
			var pc: Vector3 = row1[j2]
			var pd: Vector3 = row1[j]
			_quad_uv(st, pa, Vector2(u0, v0), pb, Vector2(u1, v0), pc, Vector2(u1, v1), pd, Vector2(u0, v1), (ax0 + ax1) * 0.5)
	# close the top, so the pour reads as a solid and not a shell
	var top_row: Array = grid[rings - 1]
	var cap_c: Vector3 = axis[rings - 1]
	for j in range(sides):
		var j2: int = posmod(j + 1, sides)
		var ta: Vector3 = top_row[j]
		var tb: Vector3 = top_row[j2]
		_v(st, cap_c, Vector2(0.5, 0.5))
		_v(st, tb, Vector2(0.5, 0.5))
		_v(st, ta, Vector2(0.5, 0.5))
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------------------
# code-painted textures

static func _maze_texture(rng: RandomNumberGenerator, cells: int, stroke_frac: float) -> ImageTexture:
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	var ink := Color(0.055, 0.055, 0.065)
	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			var mottle: float = 0.975 + 0.025 * sin(float(x) * 0.31) * cos(float(y) * 0.27)
			img.set_pixel(x, y, Color(0.945 * mottle, 0.936 * mottle, 0.910 * mottle))

	# a spanning tree carved on a torus grid, so the pattern tiles
	var total: int = cells * cells
	var visited: Array = []
	var links: Array = []
	for i in range(total):
		visited.append(false)
		links.append([])
	var dxs: Array = [1, 0, -1, 0]
	var dys: Array = [0, 1, 0, -1]
	var sx: int = rng.randi_range(0, cells - 1)
	var sy: int = rng.randi_range(0, cells - 1)
	visited[sy * cells + sx] = true
	var stack: Array = [Vector2i(sx, sy)]
	while stack.size() > 0:
		var cur: Vector2i = stack[stack.size() - 1]
		var order: Array = [0, 1, 2, 3]
		for a in range(3, 0, -1):
			var ai: int = a
			var bi: int = rng.randi_range(0, ai)
			var tmp: int = int(order[ai])
			order[ai] = order[bi]
			order[bi] = tmp
		var moved: bool = false
		for k in range(4):
			var d: int = int(order[k])
			var nx: int = posmod(cur.x + int(dxs[d]), cells)
			var ny: int = posmod(cur.y + int(dys[d]), cells)
			var ni: int = ny * cells + nx
			if not bool(visited[ni]):
				visited[ni] = true
				var here: Array = links[cur.y * cells + cur.x]
				here.append(d)
				stack.append(Vector2i(nx, ny))
				moved = true
				break
		if not moved:
			stack.pop_back()
	# braid a few extra links so the drawing has loops, not only a tree
	var extra: int = maxi(2, int(float(cells) * 1.2))
	for i in range(extra):
		var bx: int = rng.randi_range(0, cells - 1)
		var by: int = rng.randi_range(0, cells - 1)
		var bd: int = rng.randi_range(0, 3)
		var lst: Array = links[by * cells + bx]
		if not lst.has(bd):
			lst.append(bd)

	var cs: int = floori(float(TEX_SIZE) / float(cells))
	var sw: int = maxi(2, floori(float(cs) * stroke_frac))
	for cy2 in range(cells):
		for cx2 in range(cells):
			var px: int = cx2 * cs + floori(float(cs) * 0.5)
			var py: int = cy2 * cs + floori(float(cs) * 0.5)
			_ink_rect(img, px - sw, py - sw, px + sw, py + sw, ink)
			var lst2: Array = links[cy2 * cells + cx2]
			for m in range(lst2.size()):
				var d2: int = int(lst2[m])
				var ex: int = px + int(dxs[d2]) * cs
				var ey: int = py + int(dys[d2]) * cs
				_ink_rect(img, mini(px, ex) - sw, mini(py, ey) - sw, maxi(px, ex) + sw, maxi(py, ey) + sw, ink)
	return ImageTexture.create_from_image(img)


static func _brush_texture(rng: RandomNumberGenerator, strokes: int) -> ImageTexture:
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			var mottle: float = 0.985 + 0.015 * sin(float(x) * 0.19 + float(y) * 0.11)
			img.set_pixel(x, y, Color(mottle, mottle, mottle))
	var ink := Color(0.07, 0.07, 0.08)
	for s in range(strokes):
		var px: float = rng.randf_range(0.0, float(TEX_SIZE))
		var py: float = rng.randf_range(0.0, float(TEX_SIZE))
		var head: float = rng.randf_range(0.0, TAU)
		var turn: float = rng.randf_range(0.10, 0.26)
		var rad: float = rng.randf_range(3.6, 6.4)
		var steps: int = rng.randi_range(46, 84)
		for i in range(steps):
			head += rng.randf_range(-turn, turn)
			px += cos(head) * 3.2
			py += sin(head) * 3.2
			_ink_disc(img, px, py, rad, ink)
	return ImageTexture.create_from_image(img)


static func _ink_rect(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			img.set_pixel(posmod(int(x), TEX_SIZE), posmod(int(y), TEX_SIZE), c)


static func _ink_disc(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	var ri: int = int(ceil(r))
	var ix: int = int(floor(cx))
	var iy: int = int(floor(cy))
	for dy in range(-ri, ri + 1):
		for dx in range(-ri, ri + 1):
			var fx: float = float(dx)
			var fy: float = float(dy)
			if fx * fx + fy * fy <= r * r:
				img.set_pixel(posmod(ix + int(dx), TEX_SIZE), posmod(iy + int(dy), TEX_SIZE), c)


# ---------------------------------------------------------------------------
# small helpers

static func _ease(t: float) -> float:
	var u: float = clampf(t, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)


static func _glaze(c: Color, tex: ImageTexture) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.08
	m.metallic = 0.0
	m.clearcoat_enabled = true
	m.clearcoat = 1.0
	m.clearcoat_roughness = 0.05
	if tex != null:
		m.albedo_texture = tex
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(0.85, 0.85, 0.85)
	return m


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


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


static func _union_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var mi: MeshInstance3D = ch
		if mi.mesh == null:
			continue
		var local: AABB = mi.mesh.get_aabb()
		var wb: AABB = mi.transform * local
		if first:
			box = wb
			first = false
		else:
			box = box.merge(wb)
	return box
